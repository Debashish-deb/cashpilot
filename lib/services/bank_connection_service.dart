import 'dart:async';
import 'package:cashpilot/core/constants/subscription.dart' show Feature, SubscriptionManager;
import '../core/logging/logger.dart';
import '../data/drift/app_database.dart';
import 'auth_service.dart';
import 'subscription_service.dart';
import 'bank_transaction_processing_service.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class BankConnectionService {
  final _logger = Loggers.sync;
  static final BankConnectionService _instance = BankConnectionService._internal();
  factory BankConnectionService() => _instance;
  BankConnectionService._internal();

  final _client = authService.client;
  
  // MOCK MODE FLAG
  // Set to true if backend features are unavailable or for testing
  bool _useMock = true; 
  
  // In-memory mock storage
  final List<BankAccount> _mockAccounts = [];
  final _mockAccountsController = StreamController<List<BankAccount>>.broadcast();

  /// Get available banks for a country
  Future<List<BankInstitution>> getInstitutions(String countryCode) async {
    if (_useMock) return _getMockInstitutions(countryCode);

    try {
      final response = await _client.functions.invoke(
        'bank-list-institutions',
        body: {'country': countryCode},
      );

      if (response.status != 200) {
        throw Exception('Failed to fetch institutions');
      }

      final responseData = response.data as Map<String, dynamic>;
      final institutions = responseData['institutions'] as List;
      return institutions.map((e) => BankInstitution.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch institutions', error: e, stackTrace: stackTrace);
      // Fallback to mock on error
      _logger.info('Falling back to mock institutions due to error');
      return _getMockInstitutions(countryCode);
    }
  }

  /// Initiate bank connection
  Future<BankConnectionInit> initiateConnection({
    required String institutionId,
    required String redirectUrl,
  }) async {
    if (_useMock) return _mockInitiateConnection(institutionId);

    // 1. Verify bank connectivity feature is enabled
    if (!subscriptionService.canUseFeature(Feature.bankConnectivity)) {
      throw Exception('Bank connectivity is not available on your current plan');
    }

    // 2. Enforce tiered limits
    final accountsResponse = await _client
        .from('bank_accounts')
        .select('id')
        .eq('is_active', true)
        .eq('user_id', authService.currentUser?.id ?? '');
    
    final currentCount = (accountsResponse as List).length;
    final maxAllowed = SubscriptionManager.maxBankAccounts(subscriptionService.currentTier);
    
    if (maxAllowed != -1 && currentCount >= maxAllowed) {
      throw Exception(
        'Limit reached: Your ${subscriptionService.currentTier.displayName} plan allows up to $maxAllowed bank accounts. '
        'Please upgrade to link more.'
      );
    }

    try {
      final response = await _client.functions.invoke(
        'bank/connect/start',
        body: {
          'institution_id': institutionId,
          'callback_url': redirectUrl,
          'user_id': authService.currentUser?.id,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to initiate connection: ${response.data}');
      }

      return BankConnectionInit.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _logger.warning('Failed to initiate real connection, falling back to mock: $e');
      return _mockInitiateConnection(institutionId);
    }
  }

  /// Finalize bank connection (Step 4 of Nordigen Plan)
  Future<void> finalizeConnection(String requisitionId) async {
    if (_useMock || requisitionId.startsWith('mock_req_')) {
      await _mockFinalizeConnection(requisitionId);
      return;
    }

    final response = await _client.functions.invoke(
      'bank/connect/complete',
      body: {'requisition_id': requisitionId},
    );
    
    if (response.status != 200) {
      final error = response.data is Map ? response.data['error'] : 'Unknown error';
      throw Exception('Failed to finalize connection: $error');
    }
  }

  /// Sync accounts (Legacy/Internal)
  Future<void> syncAccounts(String requisitionId) async {
    await finalizeConnection(requisitionId);
  }

  /// Get user's connected accounts
  Stream<List<BankAccount>> watchBankAccounts() {
    if (_useMock) {
      // Return combined stream of mock accounts
      // Initialize with current list
      Future.delayed(Duration.zero, () {
        _mockAccountsController.add(_mockAccounts);
      });
      return _mockAccountsController.stream;
    }

    return _client
        .from('bank_accounts')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((e) => e['is_active'] == true)
            .map((e) => BankAccount.fromJson(e))
            .toList());
  }

  /// Get transactions for an account
  Future<List<BankTransaction>> getTransactions(String accountId, {int days = 90}) async {
    if (_useMock || accountId.startsWith('mock_acc_')) {
      return _getMockTransactions(accountId, days);
    }

    final response = await _client
        .from('bank_transactions')
        .select()
        .eq('account_id', accountId)
        .gte('booking_date', DateTime.now().subtract(Duration(days: days)).toIso8601String())
        .order('booking_date', ascending: false);

    return (response as List).map((e) => BankTransaction.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Toggle account active status
  Future<void> toggleAccountActive(String accountId, bool isActive) async {
    if (_useMock || accountId.startsWith('mock_acc_')) {
      final index = _mockAccounts.indexWhere((a) => a.id == accountId);
      if (index != -1) {
        final updated = _mockAccounts[index].copyWith(isActive: isActive);
        _mockAccounts[index] = updated;
        _mockAccountsController.add(_mockAccounts);
      }
      return;
    }

    await _client
        .from('bank_accounts')
        .update({'is_active': isActive})
        .eq('id', accountId);
  }

  /// Disconnect a bank connection
  Future<void> disconnect(String connectionId) async {
    if (_useMock || connectionId.startsWith('mock_conn_') || connectionId.startsWith('mock_acc_')) { // Assuming connectionId roughly maps to account id/mock id for simplicity in mock mode
       _mockAccounts.removeWhere((a) => a.id == connectionId || a.accountId == connectionId);
       _mockAccountsController.add(_mockAccounts);
       return;
    }

    await _client
        .from('bank_connections')
        .update({'status': 'expired'})
        .eq('id', connectionId);
  }

  /// Trigger auto-sync if window is open (72-96 hours)
  Future<void> triggerAutoSync(AppDatabase db) async {
    if (_useMock) {
      // Auto-sync mock data occasionally
      await _invokeSync(db);
      return;
    }

    final lastSyncStr = await _client
        .from('bank_accounts')
        .select('last_sync_at')
        .order('last_sync_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (lastSyncStr != null && lastSyncStr['last_sync_at'] != null) {
      final lastSyncAt = DateTime.parse(lastSyncStr['last_sync_at'] as String);
      final nextSyncAt = lastSyncAt.add(const Duration(hours: 72));
      
      if (DateTime.now().isAfter(nextSyncAt)) {
        await _invokeSync(db);
      }
    } else {
      // Never synced, trigger first sync
      await _invokeSync(db);
    }
  }

  /// Manual sync with 1-hour cooldown
  Future<void> triggerManualSync(AppDatabase db) async {
    await _invokeSync(db);
  }

  Future<void> _invokeSync(AppDatabase db) async {
    try {
      List<BankAccount> bankAccounts;

      if (_useMock) {
        // MOCK SYNC
        // 1. Simulate network delay
        await Future.delayed(const Duration(seconds: 2));
        bankAccounts = List.from(_mockAccounts);
      } else {
        // REAL SYNC
        // 1. Trigger backend ingestion (Edge Function)
        final response = await _client.functions.invoke('bank/sync');
        if (response.status != 200) {
          throw Exception('Sync failed: ${response.data}');
        }

        // 2. Fetch latest data from Supabase to process locally
        final accounts = await _client.from('bank_accounts').select().eq('is_active', true);
        bankAccounts = (accounts as List).map((e) => BankAccount.fromJson(e)).toList();
      }

      final userId = authService.currentUser?.id ?? 'mock_user';
      
      // GET or CREATE Default Budget for incoming transactions
      final activeBudgets = await db.getActiveBudgets(userId);
      String budgetId;
      
      if (activeBudgets.isEmpty) {
        // Create a default budget if none exists (common in fresh installs)
         if (_useMock) {
           // Ensure we have a budget to sync to
           final newBudgetId = const Uuid().v4();
           final now = DateTime.now();
           final startOfMonth = DateTime(now.year, now.month, 1);
           final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

           await db.into(db.budgets).insert(BudgetsCompanion.insert(
             id: newBudgetId,
             ownerId: userId,
             title: 'Personal Budget',
             type: 'monthly',
             startDate: startOfMonth,
             endDate: endOfMonth,
             currency: const Value('USD'),
             createdAt: Value(now),
             updatedAt: Value(now),
           ));
           budgetId = newBudgetId;
         } else {
           _logger.warning('No active budget found for bank sync. Skipping persistence.');
           return;
         }
      } else {
        budgetId = activeBudgets.first.id;
      }

      for (final account in bankAccounts) {
        // 3. Fetch recent transactions for this account
        final rawTransactions = await getTransactions(account.accountId, days: 30);
        
        // 4. Process (Normalize, Categorize)
        final processed = await bankTransactionProcessingService.processTransactions(
          rawTransactions,
          accountType: account.accountType,
        );
        
        // 5. Persist to local Drift DB (with Deduplication)
        final addedCount = await bankTransactionProcessingService.persistTransactions(
          db, 
          processed,
          userId: userId,
          budgetId: budgetId,
        );
        
        _logger.info('Synced ${processed.length} transactions for ${account.accountName}. Added $addedCount new.');
        
        // Update last sync time for mock account
        if (_useMock) {
             final index = _mockAccounts.indexWhere((a) => a.id == account.id);
             if (index != -1) {
               _mockAccounts[index] = _mockAccounts[index].copyWith(lastSyncAt: DateTime.now());
               _mockAccountsController.add(_mockAccounts);
             }
        }
      }

    } catch (e, stackTrace) {
      _logger.error('Bank sync failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==============================================================================
  // MOCK IMPLEMENTATION
  // ==============================================================================

  List<BankInstitution> _getMockInstitutions(String countryCode) {
    return [
      BankInstitution(
        id: 'mock_bank_uk',
        name: 'Mock Bank UK',
        countryCode: 'GB',
        logo: 'https://placehold.co/100x100?text=UK',
      ),
      BankInstitution(
        id: 'mock_revolut',
        name: 'Mock Revolut',
        countryCode: 'GB',
        logo: 'https://placehold.co/100x100?text=Rev',
      ),
      BankInstitution(
        id: 'mock_monzo',
        name: 'Mock Monzo',
        countryCode: 'GB',
        logo: 'https://placehold.co/100x100?text=Monzo',
      ),
      BankInstitution(
        id: 'mock_chase',
        name: 'Mock Chase',
        countryCode: 'US',
        logo: 'https://placehold.co/100x100?text=Chase',
      ),
    ];
  }

  BankConnectionInit _mockInitiateConnection(String institutionId) {
    // Generate a mock requisition ID
    final reqId = 'mock_req_${DateTime.now().millisecondsSinceEpoch}';
    
    // Return a special mock URL that the WebView will intercept
    return BankConnectionInit(
      requisitionId: reqId,
      authLink: 'mock://authenticate?inst=$institutionId&req=$reqId',
    );
  }

  Future<void> _mockFinalizeConnection(String requisitionId) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    
    // Create a new mock account
    final newAccount = BankAccount(
      id: 'mock_acc_${DateTime.now().millisecondsSinceEpoch}',
      accountId: 'mock_acc_id_${DateTime.now().millisecondsSinceEpoch}',
      accountName: 'Mock Current Account',
      currency: 'USD',
      balanceAmount: 2450.50,
      accountType: 'CHECKING',
      isActive: true,
      lastSyncAt: DateTime.now(),
      consentExpiry: DateTime.now().add(const Duration(days: 90)),
      iban: 'US89370400440532013000',
    );

    _mockAccounts.add(newAccount);
    _mockAccountsController.add(_mockAccounts);
  }

  Future<List<BankTransaction>> _getMockTransactions(String accountId, int days) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate latency
    final rng = DateTime.now();
    
    // Generate some realistic transactions
    return [
      BankTransaction(
        id: 'mock_tx_${rng.millisecondsSinceEpoch}_1',
        accountId: accountId,
        amount: -4.50,
        currency: 'USD',
        bookingDate: DateTime.now().subtract(const Duration(hours: 2)),
        description: 'Starbucks Coffee',
        creditorName: 'Starbucks',
        isReconciled: false,
      ),
      BankTransaction(
        id: 'mock_tx_${rng.millisecondsSinceEpoch}_2',
        accountId: accountId,
        amount: -15.20,
        currency: 'USD',
        bookingDate: DateTime.now().subtract(const Duration(days: 1)),
        description: 'Uber Ride',
        creditorName: 'Uber',
        isReconciled: true,
      ),
      BankTransaction(
        id: 'mock_tx_${rng.millisecondsSinceEpoch}_3',
        accountId: accountId,
        amount: -89.99,
        currency: 'USD',
        bookingDate: DateTime.now().subtract(const Duration(days: 2)),
        description: 'Grocery Shopping',
        creditorName: 'Whole Foods',
        isReconciled: true,
      ),
      BankTransaction(
        id: 'mock_tx_${rng.millisecondsSinceEpoch}_4',
        accountId: accountId,
        amount: 2500.00,
        currency: 'USD',
        bookingDate: DateTime.now().subtract(const Duration(days: 5)),
        description: 'Salary Payment',
        creditorName: 'Employer Inc',
        isReconciled: true,
      ),
      BankTransaction(
        id: 'mock_tx_${rng.millisecondsSinceEpoch}_5',
        accountId: accountId,
        amount: -12.99,
        currency: 'USD',
        bookingDate: DateTime.now().subtract(const Duration(days: 6)),
        description: 'Netflix Subscription',
        creditorName: 'Netflix',
        isReconciled: true,
      ),
    ];
  }
}

final bankConnectionService = BankConnectionService();

// Models
class BankInstitution {
  final String id;
  final String name;
  final String? logo;
  final String countryCode;

  BankInstitution({
    required this.id,
    required this.name,
    this.logo,
    required this.countryCode,
  });

  factory BankInstitution.fromJson(Map<String, dynamic> json) => BankInstitution(
        id: json['id'] as String,
        name: json['name'] as String,
        logo: json['logo'] as String?,
        countryCode: (json['countries'] as List?)?.isNotEmpty == true 
            ? json['countries'][0] as String 
            : 'GB',
      );
}

class BankConnectionInit {
  final String requisitionId;
  final String authLink;

  BankConnectionInit({required this.requisitionId, required this.authLink});

  factory BankConnectionInit.fromJson(Map<String, dynamic> json) =>
      BankConnectionInit(
        requisitionId: json['requisition_id'] as String,
        authLink: json['auth_link'] as String,
      );
}

class BankAccount {
  final String id;
  final String accountId;
  final String? iban;
  final String? accountName;
  final String currency;
  final double? balanceAmount;
  final DateTime? lastSyncAt;
  final DateTime? consentExpiry;
  final String? accountType;
  final bool isActive;

  BankAccount({
    required this.id,
    required this.accountId,
    this.iban,
    this.accountName,
    required this.currency,
    this.balanceAmount,
    this.lastSyncAt,
    this.consentExpiry,
    this.accountType,
    this.isActive = true,
  });

  BankAccount copyWith({
    String? id,
    String? accountId,
    String? iban,
    String? accountName,
    String? currency,
    double? balanceAmount,
    DateTime? lastSyncAt,
    DateTime? consentExpiry,
    String? accountType,
    bool? isActive,
  }) {
    return BankAccount(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      iban: iban ?? this.iban,
      accountName: accountName ?? this.accountName,
      currency: currency ?? this.currency,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      consentExpiry: consentExpiry ?? this.consentExpiry,
      accountType: accountType ?? this.accountType,
      isActive: isActive ?? this.isActive,
    );
  }

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
        id: json['id'] as String,
        accountId: json['account_id'] as String,
        iban: json['iban'] as String?,
        accountName: json['account_name'] as String?,
        currency: json['currency'] as String,
        balanceAmount: json['balance_amount'] != null 
            ? (json['balance_amount'] as num).toDouble() 
            : null,
        lastSyncAt: json['last_sync_at'] != null 
            ? DateTime.parse(json['last_sync_at'] as String) 
            : null,
        consentExpiry: json['consent_expiry'] != null 
            ? DateTime.parse(json['consent_expiry'] as String) 
            : null,
        accountType: json['account_type'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );
}

class BankTransaction {
  final String id;
  final String accountId;
  final double amount;
  final String currency;
  final DateTime bookingDate;
  final String? description;
  final String? creditorName;
  final bool isReconciled;

  BankTransaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.currency,
    required this.bookingDate,
    this.description,
    this.creditorName,
    required this.isReconciled,
  });

  factory BankTransaction.fromJson(Map<String, dynamic> json) => BankTransaction(
        id: json['id'] as String,
        accountId: json['account_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
        bookingDate: DateTime.parse(json['booking_date'] as String),
        description: json['description'] as String?,
        creditorName: json['creditor_name'] as String?,
        isReconciled: json['is_reconciled'] as bool? ?? false,
      );
}
