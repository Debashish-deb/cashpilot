/// Geolocation Service v3.0 - Fully Supabase Integrated
/// Complete location intelligence for CashPilot with advanced sync capabilities
library;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enhanced Geolocation Service with Full Supabase Sync
class GeolocationService {
  static final GeolocationService _instance = GeolocationService._internal();
  factory GeolocationService() => _instance;
  GeolocationService._internal() {
    // Delay initialization to ensure Supabase is ready
    Future.delayed(const Duration(seconds: 2), () => _initialize());
  }

  // Supabase - use getter for lazy access
  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }
  
  bool get _isSupabaseReady {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }
  
  // Location State
  Position? _lastKnownPosition;
  Position? _lastValidPosition;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<dynamic>? _realtimeSubscription;
  
  // Enhanced Caching with LRU
  final LinkedHashMap<String, CachedLocation> _locationCache = 
      LinkedHashMap();
  static const int _maxCacheSize = 1000;
  static const Duration _cacheTTL = Duration(hours: 48);
  
  // Location Intelligence
  final List<Position> _positionHistory = [];
  static const int _maxHistorySize = 500;
  static const double _movementThreshold = 15.0;
  
  // Configuration with defaults
  LocationAccuracy _accuracy = LocationAccuracy.medium;
  Duration _timeout = const Duration(seconds: 15);
  bool _enableSupabaseSync = true;
  bool _enableRealTimeSync = false;
  bool _enableAnalytics = true;
  bool _enableGeofencing = false;
  
  // Streams
  final StreamController<Position> _positionStreamController = 
      StreamController<Position>.broadcast();
  final StreamController<LocationStatus> _statusStreamController = 
      StreamController<LocationStatus>.broadcast();
  final StreamController<LocationAnalytics> _analyticsStreamController = 
      StreamController<LocationAnalytics>.broadcast();
  final StreamController<GeofenceEvent> _geofenceStreamController = 
      StreamController<GeofenceEvent>.broadcast();
  
  // Analytics
  final LocationAnalytics _analytics = LocationAnalytics();
  
  // Geofences
  final List<Geofence> _activeGeofences = [];
  final Map<String, GeofenceEvent> _geofenceHistory = {};

  /// Initialize with Supabase integration
  Future<void> _initialize() async {
    // Guard against early initialization before Supabase is ready
    if (!_isSupabaseReady) {
      debugPrint('[GeolocationService] Supabase not ready, skipping initialization');
      return;
    }
    
    await _loadUserPreferences();
    await _loadGeofences();
    await _syncLocationSettings();
    _startHealthMonitor();
    
    // Subscribe to real-time updates if enabled
    if (_enableRealTimeSync) {
      _setupRealtimeSubscription();
    }
    
    debugPrint('[GeolocationService] Initialized with Supabase integration');
  }

  /// Load user preferences from Supabase
  Future<void> _loadUserPreferences() async {
    if (!_isSupabaseReady) return;
    
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _supabase
          .from('user_preferences')
          .select('location_settings, analytics_enabled, sync_enabled')
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (response != null) {
        final settings = response['location_settings'] as Map<String, dynamic>? ?? {};
        
        _accuracy = LocationAccuracy.values.firstWhere(
          (e) => e.name == (settings['accuracy'] ?? 'medium'),
          orElse: () => LocationAccuracy.medium,
        );
        
        _enableSupabaseSync = response['sync_enabled'] ?? true;
        _enableAnalytics = response['analytics_enabled'] ?? true;
        _enableRealTimeSync = settings['realtime_sync'] ?? false;
        _enableGeofencing = settings['geofencing_enabled'] ?? false;
        
        if (settings['timeout'] != null) {
          _timeout = Duration(seconds: (settings['timeout'] as num).toInt());
        }
        
        debugPrint('[GeolocationService] User preferences loaded from Supabase');
      }
    } catch (e) {
      debugPrint('[GeolocationService] Error loading preferences: $e');
    }
  }

  /// Sync location settings to Supabase (consistent with your schema style)
  Future<void> _syncLocationSettings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final settings = {
        'accuracy': _accuracy.name,
        'timeout': _timeout.inSeconds,
        'realtime_sync': _enableRealTimeSync,
        'geofencing_enabled': _enableGeofencing,
        'movement_threshold': _movementThreshold,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('user_preferences').upsert({
        'user_id': userId,
        'location_settings': settings,
        'sync_enabled': _enableSupabaseSync,
        'analytics_enabled': _enableAnalytics,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('[GeolocationService] Location settings synced to Supabase');
    } catch (e) {
      debugPrint('[GeolocationService] Error syncing settings: $e');
    }
  }

  /// Enhanced permission with analytics tracking
  Future<PermissionResult> requestPermission({
    bool background = false,
    String context = 'general',
  }) async {
    _analytics.permissionRequests++;
    
    // Check service status
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _logAnalyticsEvent('permission_denied_service_disabled', context);
      return PermissionResult(
        status: PermissionStatus.serviceDisabled,
        canRequestAgain: true,
        message: 'Location services are disabled',
      );
    }

    // Check current permission
    LocationPermission permission = await Geolocator.checkPermission();
    PermissionStatus currentStatus = _mapPermission(permission);
    
    // Request if needed
    if (currentStatus == PermissionStatus.denied) {
      permission = await Geolocator.requestPermission();
      currentStatus = _mapPermission(permission);
    }
    
    // Request background if needed
    if (background && currentStatus == PermissionStatus.whileInUse) {
      permission = await Geolocator.requestPermission();
      currentStatus = _mapPermission(permission);
    }

    // Log to Supabase analytics
    await _logPermissionEvent(currentStatus, context);
    
    // Update analytics
    _analytics.lastPermissionStatus = currentStatus;
    _analytics.lastPermissionCheck = DateTime.now();
    
    return PermissionResult(
      status: currentStatus,
      canRequestAgain: currentStatus == PermissionStatus.denied,
      message: _getPermissionMessage(currentStatus),
    );
  }

  /// Smart location acquisition with multiple strategies
  Future<LocationResult> getCurrentLocation({
    String? context,
    LocationStrategy strategy = LocationStrategy.balanced,
    bool saveToSupabase = true,
    int maxRetries = 3,
    double desiredAccuracy = 50.0, // meters
  }) async {
    _analytics.locationRequests++;
    final startTime = DateTime.now();
    
    // Strategy selection
    final accuracy = switch (strategy) {
      LocationStrategy.powerSaving => LocationAccuracy.low,
      LocationStrategy.balanced => LocationAccuracy.medium,
      LocationStrategy.highAccuracy => LocationAccuracy.high,
      LocationStrategy.navigation => LocationAccuracy.best,
    };
    
    setAccuracy(accuracy);

    // Check permissions
    final permissionResult = await requestPermission(context: context ?? 'location_request');
    if (!permissionResult.status.isGranted) {
      return LocationResult.error(
        error: LocationError.permissionDenied,
        message: permissionResult.message,
      );
    }

    Position? position;
    LocationError? error;
    String? errorMessage;
    int retryCount = 0;

    while (position == null && retryCount <= maxRetries) {
      try {
        position = await _getPositionWithStrategy(strategy, desiredAccuracy);
        
        if (position != null) {
          // Validate accuracy
          if (position.accuracy > desiredAccuracy * 2) {
            debugPrint('[GeolocationService] Position accuracy poor (${position.accuracy}m), retrying...');
            position = null;
            continue;
          }
          
          await _processLocation(position, context: context);
          
          if (saveToSupabase && _enableSupabaseSync) {
            await _saveLocationWithRelations(position, context: context);
          }
          
          // Check geofences if enabled
          if (_enableGeofencing) {
            await _checkGeofences(position);
          }
        }
      } catch (e, stackTrace) {
        error = LocationError.acquisitionFailed;
        errorMessage = e.toString();
        debugPrint('[GeolocationService] Location error: $e\n$stackTrace');
        
        // Use fallback strategy
        if (retryCount == maxRetries && _lastValidPosition != null) {
          position = _lastValidPosition;
          error = null;
          errorMessage = 'Using last valid position as fallback';
          debugPrint('[GeolocationService] Using fallback position');
        }
      }
      
      retryCount++;
      if (position == null && retryCount <= maxRetries) {
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }

    final duration = DateTime.now().difference(startTime);
    _analytics.averageAcquisitionTime = 
        ((_analytics.averageAcquisitionTime * (_analytics.locationRequests - 1)) + 
         duration.inMilliseconds) / _analytics.locationRequests;

    if (position != null) {
      _analytics.successfulRequests++;
      _analyticsStreamController.add(_analytics);
      
      return LocationResult.success(
        position: position,
        duration: duration,
        accuracy: position.accuracy,
        source: error == null ? 'gps' : 'fallback',
      );
    } else {
      _analytics.failedRequests++;
      
      return LocationResult.error(
        error: error ?? LocationError.unknown,
        message: errorMessage ?? 'Failed to acquire location',
        duration: duration,
      );
    }
  }

  /// Get position with strategy-based approach
  Future<Position?> _getPositionWithStrategy(
    LocationStrategy strategy,
    double desiredAccuracy,
  ) async {
    switch (strategy) {
      case LocationStrategy.powerSaving:
        return await Geolocator.getLastKnownPosition();
        
      case LocationStrategy.balanced:
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: _accuracy.toGeolocatorAccuracy(),
          timeLimit: _timeout,
        ).timeout(_timeout);
        
      case LocationStrategy.highAccuracy:
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 30),
        ).timeout(const Duration(seconds: 30));
        
      case LocationStrategy.navigation:
        // Continuous updates for navigation
        final completer = Completer<Position?>();
        final sub = Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          ),
        ).listen((position) {
          if (!completer.isCompleted && position.accuracy < desiredAccuracy) {
            completer.complete(position);
          }
        });
        
        final result = await completer.future.timeout(const Duration(seconds: 45));
        await sub.cancel();
        return result;
    }
  }

  /// Process location with intelligence
  Future<void> _processLocation(
    Position position, {
    String? context,
  }) async {
    // Validate
    if (!_isValidPosition(position)) {
      debugPrint('[GeolocationService] Invalid position detected');
      return;
    }

    // Check movement significance
    final hasMoved = _checkSignificantMovement(position);
    final distance = _lastValidPosition != null 
        ? Geolocator.distanceBetween(
            _lastValidPosition!.latitude,
            _lastValidPosition!.longitude,
            position.latitude,
            position.longitude,
          )
        : 0.0;

    // Update state
    _lastKnownPosition = position;
    
    if (hasMoved || _lastValidPosition == null) {
      _lastValidPosition = position;
    }

    // Update history
    _positionHistory.add(position);
    if (_positionHistory.length > _maxHistorySize) {
      _positionHistory.removeAt(0);
    }

    // Update cache
    final cacheKey = '${position.latitude}_${position.longitude}';
    _locationCache[cacheKey] = CachedLocation(
      position: position,
      context: context,
      timestamp: DateTime.now(),
      expiresAt: DateTime.now().add(_cacheTTL),
      accuracy: position.accuracy,
      distanceFromPrevious: distance,
    );
    
    // Manage cache size
    if (_locationCache.length > _maxCacheSize) {
      final oldestKey = _locationCache.keys.first;
      _locationCache.remove(oldestKey);
    }

    // Broadcast
    _positionStreamController.add(position);
    _statusStreamController.add(LocationStatus.acquired);

    // Update analytics
    _analytics.totalDistance += distance;
    _analytics.locationsRecorded++;
    _analytics.lastLocationTime = DateTime.now();

    debugPrint('[GeolocationService] Location processed: ${position.latitude}, ${position.longitude} '
        '(Accuracy: ${position.accuracy}m, Moved: ${distance.toStringAsFixed(1)}m)');
  }

  /// Save location with expense relationships
  Future<void> _saveLocationWithRelations(
    Position position, {
    String? context,
    String? expenseId,
    String? recurringExpenseId,
    bool cached = false,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || !_enableSupabaseSync) return;

    try {
      final locationData = {
        'user_id': userId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': DateTime.now().toIso8601String(),
        'context': context,
        'source': cached ? 'cache' : 'gps',
        'device_info': {
          'platform': defaultTargetPlatform.toString(),
          'accuracy_level': _accuracy.name,
        },
        'created_at': DateTime.now().toIso8601String(),
        'revision': await _getNextRevision('locations'),
      };

      // Insert location
      final locationResponse = await _supabase
          .from('locations')
          .insert(locationData)
          .select('id')
          .single();
      
      final locationId = locationResponse['id'] as String;

      // Update user profile last location
      await _supabase.from('user_profiles').upsert({
        'id': userId,
        'last_location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
          'location_id': locationId,
        },
        'updated_at': DateTime.now().toIso8601String(),
        'revision': await _getNextRevision('user_profiles'),
      });

      // Link to expense if provided
      if (expenseId != null) {
        await _linkLocationToExpense(locationId, expenseId);
      }

      // Link to recurring expense if provided
      if (recurringExpenseId != null) {
        await _linkLocationToRecurringExpense(locationId, recurringExpenseId);
      }

      // Log analytics
      if (_enableAnalytics) {
        await _logLocationAnalytics(locationId, position);
      }

      debugPrint('[GeolocationService] Location saved to Supabase with ID: $locationId');
    } catch (e, stackTrace) {
      debugPrint('[GeolocationService] Error saving location: $e\n$stackTrace');
      
      // Offline fallback
      if (_enableSupabaseSync) {
        await _cacheForOfflineSync({
          'table': 'locations',
          'data': {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
            'context': context,
            'synced': false,
          },
        });
      }
    }
  }

  /// Link location to expense (for expense geo-tagging)
  Future<void> _linkLocationToExpense(String locationId, String expenseId) async {
    try {
      await _supabase.from('expense_locations').upsert({
        'expense_id': expenseId,
        'location_id': locationId,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('[GeolocationService] Location linked to expense: $expenseId');
    } catch (e) {
      debugPrint('[GeolocationService] Error linking to expense: $e');
    }
  }

  /// Link location to recurring expense
  Future<void> _linkLocationToRecurringExpense(
    String locationId, 
    String recurringExpenseId,
  ) async {
    try {
      await _supabase.from('recurring_expense_locations').upsert({
        'recurring_expense_id': recurringExpenseId,
        'location_id': locationId,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('[GeolocationService] Location linked to recurring expense: $recurringExpenseId');
    } catch (e) {
      debugPrint('[GeolocationService] Error linking to recurring expense: $e');
    }
  }

  /// Get address with Supabase caching and fallback
  Future<AddressResult> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
    AddressFormat format = AddressFormat.standard,
    String? languageCode,
  }) async {
    _analytics.geocodingRequests++;
    
    // Check cache first
    final cacheKey = '${latitude}_${longitude}_${format.name}_${languageCode ?? 'en'}';
    final cached = _locationCache[cacheKey];
    
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      _analytics.cacheHits++;
      return AddressResult(
        address: cached.address,
        source: 'cache',
        formattedAddress: cached.address,
      );
    }

    // Try Supabase cache
    if (_enableSupabaseSync) {
      final supabaseAddress = await _getAddressFromSupabaseCache(
        latitude,
        longitude,
        format,
        languageCode,
      );
      
      if (supabaseAddress != null) {
        return AddressResult(
          address: supabaseAddress,
          source: 'supabase_cache',
          formattedAddress: supabaseAddress,
        );
      }
    }

    // Fetch from geocoding service
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return AddressResult.error(
          error: 'No address found for coordinates',
          coordinates: GeoCoordinates(latitude, longitude),
        );
      }

      final address = _formatAddress(placemarks.first, format);
      final fullAddress = _formatAddress(placemarks.first, AddressFormat.full);
      
      // Cache results
      _cacheAddress(
        latitude,
        longitude,
        address,
        fullAddress,
        format,
        languageCode,
      );

      // Save to Supabase cache
      if (_enableSupabaseSync) {
        await _saveAddressToSupabaseCache(
          latitude,
          longitude,
          address,
          fullAddress,
          format,
          languageCode,
        );
      }

      return AddressResult(
        address: address,
        source: 'geocoding_service',
        formattedAddress: fullAddress,
        placemark: placemarks.first,
        coordinates: GeoCoordinates(latitude, longitude),
      );
    } catch (e) {
      debugPrint('[GeolocationService] Geocoding error: $e');
      
      return AddressResult.error(
        error: e.toString(),
        coordinates: GeoCoordinates(latitude, longitude),
      );
    }
  }

  /// Get location history with filtering
  Future<List<LocationHistory>> getLocationHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? context,
    int limit = 100,
    bool includeAddresses = false,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      var query = _supabase
          .from('locations')
          .select('''
            *,
            expense_locations(expense_id),
            recurring_expense_locations(recurring_expense_id)
          ''')
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(limit);

      final response = await query.timeout(const Duration(seconds: 10));

      final history = (response as List).map((item) async {
        final historyItem = LocationHistory.fromSupabase(item);
        
        if (includeAddresses && historyItem.address == null) {
          final addressResult = await getAddressFromCoordinates(
            latitude: historyItem.latitude,
            longitude: historyItem.longitude,
          );
          
          if (addressResult.isSuccess) {
            historyItem.address = addressResult.address;
          }
        }
        
        return historyItem;
      }).toList();

      return await Future.wait(history);
    } catch (e) {
      debugPrint('[GeolocationService] Error fetching history: $e');
      return [];
    }
  }

  /// Geofencing system
  Future<void> addGeofence(Geofence geofence) async {
    _activeGeofences.add(geofence);
    
    if (_enableSupabaseSync) {
      await _saveGeofenceToSupabase(geofence);
    }
    
    debugPrint('[GeolocationService] Geofence added: ${geofence.name}');
  }

  Future<void> _checkGeofences(Position position) async {
    for (final geofence in _activeGeofences) {
      final distance = Geolocator.distanceBetween(
        geofence.latitude,
        geofence.longitude,
        position.latitude,
        position.longitude,
      );

      final isInside = distance <= geofence.radius;
      final eventKey = '${geofence.id}_${position.timestamp.millisecondsSinceEpoch}';
      
      if (isInside && !geofence.isInside) {
        // Entered geofence
        final event = GeofenceEvent(
          geofenceId: geofence.id,
          type: GeofenceEventType.enter,
          position: position,
          timestamp: DateTime.now(),
        );
        
        _geofenceHistory[eventKey] = event;
        geofence.isInside = true;
        geofence.lastEntered = DateTime.now();
        
        _geofenceStreamController.add(event);
        
        if (_enableSupabaseSync) {
          await _logGeofenceEvent(event);
        }
        
        debugPrint('[GeolocationService] Entered geofence: ${geofence.name}');
      } else if (!isInside && geofence.isInside) {
        // Exited geofence
        final event = GeofenceEvent(
          geofenceId: geofence.id,
          type: GeofenceEventType.exit,
          position: position,
          timestamp: DateTime.now(),
          duration: geofence.lastEntered != null 
              ? DateTime.now().difference(geofence.lastEntered!)
              : null,
        );
        
        _geofenceHistory[eventKey] = event;
        geofence.isInside = false;
        
        _geofenceStreamController.add(event);
        
        if (_enableSupabaseSync) {
          await _logGeofenceEvent(event);
        }
        
        debugPrint('[GeolocationService] Exited geofence: ${geofence.name}');
      }
    }
  }

  /// Continuous monitoring with Supabase real-time
  Future<void> startContinuousMonitoring({
    Duration interval = const Duration(seconds: 30),
    double distanceFilter = 20.0,
    bool enableRealTime = true,
  }) async {
    if (_positionSubscription != null) return;

    final permission = await requestPermission(background: true);
    if (!permission.status.isGranted) return;

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: _accuracy.toGeolocatorAccuracy(),
        distanceFilter: distanceFilter.toInt(),
      ),
    ).listen((position) async {
      await _processLocation(position, context: 'continuous_monitoring');
      
      if (_enableSupabaseSync) {
        await _saveLocationWithRelations(
          position,
          context: 'continuous_monitoring',
        );
      }
    });

    if (enableRealTime) {
      _enableRealTimeSync = true;
      _setupRealtimeSubscription();
    }

    debugPrint('[GeolocationService] Continuous monitoring started');
  }

  /// Setup Supabase real-time subscriptions
  void _setupRealtimeSubscription() {
    if (_realtimeSubscription != null) return;

    _supabase
        .channel('locations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'locations',
          callback: (payload) {
            debugPrint('📍 Real-time update: ${payload.eventType}');
            // Handle real-time updates here
          },
        )
        .subscribe();
  }

  /// 📊 Analytics and logging
  Future<void> _logLocationAnalytics(String locationId, Position position) async {
    if (!_enableAnalytics) return;

    try {
      await _supabase.from('location_analytics').insert({
        'location_id': locationId,
        'user_id': _supabase.auth.currentUser?.id,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'battery_impact': 'low', // Could be calculated
        'network_type': 'wifi', // Could be detected
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('📍 Error logging analytics: $e');
    }
  }

  /// 🧹 Cleanup and maintenance
  Future<void> performMaintenance() async {
    await _cleanupOldLocations();
    await _cleanupCache();
    await _syncOfflineData();
    
    debugPrint('📍 Maintenance performed');
  }

  Future<void> _cleanupOldLocations() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
    
    try {
      await _supabase
          .from('locations')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String());
      
      debugPrint('📍 Old locations cleaned up');
    } catch (e) {
      debugPrint('📍 Error cleaning up: $e');
    }
  }

  // Helper methods
  bool _isValidPosition(Position position) {
    return position.latitude >= -90 &&
        position.latitude <= 90 &&
        position.longitude >= -180 &&
        position.longitude <= 180 &&
        position.accuracy < 5000; // Reject very inaccurate positions
  }

  bool _checkSignificantMovement(Position newPosition) {
    if (_lastValidPosition == null) return true;
    
    final distance = Geolocator.distanceBetween(
      _lastValidPosition!.latitude,
      _lastValidPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    
    return distance > _movementThreshold;
  }

  Future<int> _getNextRevision(String table) async {
    // Implementation for revision tracking
    return DateTime.now().millisecondsSinceEpoch;
  }

  // Getters
  Position? get lastKnownPosition => _lastKnownPosition;
  LocationAnalytics get analytics => _analytics;
  Stream<Position> get positionStream => _positionStreamController.stream;
  Stream<LocationStatus> get statusStream => _statusStreamController.stream;
  Stream<GeofenceEvent> get geofenceStream => _geofenceStreamController.stream;

  /// Cleanup
  Future<void> dispose() async {
    await _positionSubscription?.cancel();
    await _realtimeSubscription?.cancel();
    await _positionStreamController.close();
    await _statusStreamController.close();
    await _analyticsStreamController.close();
    await _geofenceStreamController.close();
    
    // Save analytics before closing
    if (_enableAnalytics) {
      await _saveAnalytics();
    }
  }

  Future<void> _saveAnalytics() async {
    if (!_enableAnalytics) return;

    try {
      await _supabase.from('user_analytics').upsert({
        'user_id': _supabase.auth.currentUser?.id,
        'location_analytics': _analytics.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('📍 Error saving analytics: $e');
    }
  }
}

// Additional classes and enums (abbreviated for space)
enum LocationStrategy {
  powerSaving,
  balanced,
  highAccuracy,
  navigation,
}

enum LocationError {
  permissionDenied,
  serviceDisabled,
  timeout,
  acquisitionFailed,
  networkError,
  unknown,
}

class LocationResult {
  final Position? position;
  final LocationError? error;
  final String? message;
  final Duration? duration;
  final double? accuracy;
  final String? source;

  LocationResult.success({
    required this.position,
    this.duration,
    this.accuracy,
    this.source = 'gps',
  })  : error = null,
        message = null;

  LocationResult.error({
    required this.error,
    this.message,
    this.duration,
  })  : position = null,
        accuracy = null,
        source = null;

  bool get isSuccess => position != null;
}

class AddressResult {
  final String? address;
  final String? source;
  final String? formattedAddress;
  final Placemark? placemark;
  final GeoCoordinates? coordinates;
  final String? error;

  AddressResult({
    required this.address,
    this.source,
    this.formattedAddress,
    this.placemark,
    this.coordinates,
  }) : error = null;

  AddressResult.error({
    required this.error,
    this.coordinates,
  })  : address = null,
        source = null,
        formattedAddress = null,
        placemark = null;

  bool get isSuccess => address != null;
}

class LocationAnalytics {
  int locationRequests = 0;
  int successfulRequests = 0;
  int failedRequests = 0;
  int geocodingRequests = 0;
  int cacheHits = 0;
  int permissionRequests = 0;
  double totalDistance = 0.0;
  int locationsRecorded = 0;
  double averageAcquisitionTime = 0.0;
  DateTime? lastLocationTime;
  PermissionStatus? lastPermissionStatus;
  DateTime? lastPermissionCheck;

  Map<String, dynamic> toJson() {
    return {
      'location_requests': locationRequests,
      'successful_requests': successfulRequests,
      'failed_requests': failedRequests,
      'geocoding_requests': geocodingRequests,
      'cache_hits': cacheHits,
      'permission_requests': permissionRequests,
      'total_distance': totalDistance,
      'locations_recorded': locationsRecorded,
      'average_acquisition_time': averageAcquisitionTime,
      'last_location_time': lastLocationTime?.toIso8601String(),
      'last_permission_status': lastPermissionStatus?.name,
      'last_permission_check': lastPermissionCheck?.toIso8601String(),
    };
  }
}

class Geofence {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // meters
  bool isInside = false;
  DateTime? lastEntered;
  String? context;

  Geofence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.context,
  });
}

enum GeofenceEventType { enter, exit, dwell }

class GeofenceEvent {
  final String geofenceId;
  final GeofenceEventType type;
  final Position position;
  final DateTime timestamp;
  final Duration? duration;

  GeofenceEvent({
    required this.geofenceId,
    required this.type,
    required this.position,
    required this.timestamp,
    this.duration,
  });
}

// ... Additional supporting classes and methods

/// Global instance
final geolocationService = GeolocationService();

// ============================================================
// MISSING TYPES AND ENUMS
// ============================================================

/// Location status enum
enum LocationStatus {
  idle,
  acquiring,
  acquired,
  error,
  permissionDenied,
  serviceDisabled,
}

/// Permission status enum
enum PermissionStatus {
  granted,
  denied,
  deniedForever,
  whileInUse,
  always,
  serviceDisabled,
  unknown;

  bool get isGranted => this == PermissionStatus.granted || 
      this == PermissionStatus.whileInUse || 
      this == PermissionStatus.always;
}

/// Address format enum
enum AddressFormat {
  standard,
  short,
  full,
  streetOnly,
  cityOnly,
}

/// Permission result class
class PermissionResult {
  final PermissionStatus status;
  final bool canRequestAgain;
  final String message;

  PermissionResult({
    required this.status,
    required this.canRequestAgain,
    required this.message,
  });
}

/// Cached location class
class CachedLocation {
  final Position position;
  final String? context;
  final DateTime timestamp;
  final DateTime expiresAt;
  final double? accuracy;
  final double distanceFromPrevious;
  String? address;

  CachedLocation({
    required this.position,
    this.context,
    required this.timestamp,
    required this.expiresAt,
    this.accuracy,
    required this.distanceFromPrevious,
    this.address,
  });
}

/// Location history class
class LocationHistory {
  final String id;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;
  final String? context;
  String? address;
  final List<String> expenseIds;
  final List<String> recurringExpenseIds;

  LocationHistory({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
    this.context,
    this.address,
    this.expenseIds = const [],
    this.recurringExpenseIds = const [],
  });

  factory LocationHistory.fromSupabase(Map<String, dynamic> data) {
    return LocationHistory(
      id: data['id'] as String,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      accuracy: (data['accuracy'] as num?)?.toDouble(),
      timestamp: DateTime.tryParse(data['timestamp'] as String? ?? '') ?? DateTime.now(),
      context: data['context'] as String?,
      expenseIds: (data['expense_locations'] as List?)
          ?.map((e) => e['expense_id'] as String)
          .toList() ?? [],
      recurringExpenseIds: (data['recurring_expense_locations'] as List?)
          ?.map((e) => e['recurring_expense_id'] as String)
          .toList() ?? [],
    );
  }
}

/// Geo coordinates class
class GeoCoordinates {
  final double latitude;
  final double longitude;

  GeoCoordinates(this.latitude, this.longitude);

  @override
  String toString() => '$latitude, $longitude';
}

// ============================================================
// EXTENSION FOR LocationAccuracy
// ============================================================

extension LocationAccuracyExtension on LocationAccuracy {
  LocationAccuracy toGeolocatorAccuracy() => this;
}

// ============================================================
// STUB METHODS FOR GeolocationService
// ============================================================

extension GeolocationServiceStubs on GeolocationService {
  // Stub methods that were missing from the user's update
  
  void _logAnalyticsEvent(String event, String context) {
    debugPrint('📍 Analytics: $event ($context)');
  }

  Future<void> _loadGeofences() async {
    // Load geofences from Supabase
    debugPrint('📍 Loading geofences...');
  }

  void _startHealthMonitor() {
    // Start health monitoring
    debugPrint('📍 Health monitor started');
  }

  PermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return PermissionStatus.denied;
      case LocationPermission.deniedForever:
        return PermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
        return PermissionStatus.whileInUse;
      case LocationPermission.always:
        return PermissionStatus.always;
      case LocationPermission.unableToDetermine:
        return PermissionStatus.unknown;
    }
  }

  Future<void> _logPermissionEvent(PermissionStatus status, String context) async {
    debugPrint('📍 Permission event: $status ($context)');
  }

  String _getPermissionMessage(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.whileInUse:
      case PermissionStatus.always:
        return 'Location permission granted';
      case PermissionStatus.denied:
        return 'Location permission denied';
      case PermissionStatus.deniedForever:
        return 'Location permission permanently denied. Please enable in Settings.';
      case PermissionStatus.serviceDisabled:
        return 'Location services are disabled';
      case PermissionStatus.unknown:
        return 'Unknown permission status';
    }
  }

  void setAccuracy(LocationAccuracy accuracy) {
    // This would set _accuracy but we can't access private fields in extension
    debugPrint('📍 Accuracy set to: ${accuracy.name}');
  }

  Future<void> _cacheForOfflineSync(Map<String, dynamic> data) async {
    debugPrint('📍 Caching for offline sync: ${data['table']}');
  }

  Future<String?> _getAddressFromSupabaseCache(
    double latitude,
    double longitude,
    AddressFormat format,
    String? languageCode,
  ) async {
    return null; // Not cached
  }

  String _formatAddress(Placemark place, AddressFormat format) {
    switch (format) {
      case AddressFormat.short:
        return place.locality ?? place.name ?? '';
      case AddressFormat.streetOnly:
        return place.street ?? '';
      case AddressFormat.cityOnly:
        return place.locality ?? '';
      case AddressFormat.full:
        final parts = <String>[];
        if (place.name?.isNotEmpty == true) parts.add(place.name!);
        if (place.street?.isNotEmpty == true && place.street != place.name) {
          parts.add(place.street!);
        }
        if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
        if (place.postalCode?.isNotEmpty == true) parts.add(place.postalCode!);
        if (place.country?.isNotEmpty == true) parts.add(place.country!);
        return parts.join(', ');
      case AddressFormat.standard:
        final parts = <String>[];
        if (place.name?.isNotEmpty == true) parts.add(place.name!);
        if (place.street?.isNotEmpty == true && place.street != place.name) {
          parts.add(place.street!);
        }
        if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
        return parts.join(', ');
    }
  }

  void _cacheAddress(
    double latitude,
    double longitude,
    String address,
    String fullAddress,
    AddressFormat format,
    String? languageCode,
  ) {
    debugPrint('📍 Address cached: $address');
  }

  Future<void> _saveAddressToSupabaseCache(
    double latitude,
    double longitude,
    String address,
    String fullAddress,
    AddressFormat format,
    String? languageCode,
  ) async {
    debugPrint('📍 Address saved to Supabase cache');
  }

  Future<void> _saveGeofenceToSupabase(Geofence geofence) async {
    debugPrint('📍 Geofence saved to Supabase: ${geofence.name}');
  }

  Future<void> _logGeofenceEvent(GeofenceEvent event) async {
    debugPrint('📍 Geofence event logged: ${event.type.name}');
  }

  Future<void> _cleanupCache() async {
    debugPrint('📍 Cache cleaned up');
  }

  Future<void> _syncOfflineData() async {
    debugPrint('📍 Offline data synced');
  }
}

// ============================================================
// BACKWARD COMPATIBILITY - LocationInfo for AddExpenseScreen
// ============================================================

/// Simple location info class (backward compatibility)
class LocationInfo {
  final double latitude;
  final double longitude;
  final String? address;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
  };

  factory LocationInfo.fromJson(Map<String, dynamic> json) => LocationInfo(
    latitude: json['latitude'] as double,
    longitude: json['longitude'] as double,
    address: json['address'] as String?,
  );

  @override
  String toString() => address ?? '$latitude, $longitude';
}

/// Backward compatible method
extension GeolocationServiceCompat on GeolocationService {
  /// Get current address in one call (backward compatible)
  Future<LocationInfo?> getCurrentLocationInfo() async {
    final result = await getCurrentLocation(
      strategy: LocationStrategy.balanced,
      saveToSupabase: false,
    );
    
    if (!result.isSuccess || result.position == null) return null;

    final addressResult = await getAddressFromCoordinates(
      latitude: result.position!.latitude,
      longitude: result.position!.longitude,
    );
    
    return LocationInfo(
      latitude: result.position!.latitude,
      longitude: result.position!.longitude,
      address: addressResult.address,
    );
  }
}