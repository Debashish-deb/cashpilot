/// Barcode Scan Screen
/// Advanced camera-based barcode scanning with product lookup
library;
import 'dart:async';
import 'dart:ui';
import 'package:cashpilot/core/theme/app_colors.dart' show AppColors;
import 'package:cashpilot/core/theme/app_typography.dart' show AppTypography;
import 'package:cashpilot/features/barcode/models/scan_state.dart' show ScanState;
import 'package:cashpilot/features/barcode/services/barcode_validator.dart' show BarcodeValidator;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, HapticFeedback, SystemSound, SystemSoundType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../features/barcode/models/barcode_scan_result.dart';
import '../../../features/barcode/providers/barcode_providers.dart';
import '../../../features/barcode/viewmodels/barcode_scan_viewmodel.dart';

import '../../../core/managers/managers.dart';
import '../../../services/analytics_tracking_service.dart';
class BarcodeScanScreen extends ConsumerStatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _flashOn = false;
  bool _zoomIn = false;
  bool _showHelp = false;
  bool _isConnected = true;
  double _zoomLevel = 1.0;
  
  int _scanCount = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectionSubscription;

  final List<String> _recentScans = [];
  final FocusNode _manualFocusNode = FocusNode();
  final TextEditingController _manualController = TextEditingController();

  // Camera controller
  final ms.MobileScannerController _cameraController = ms.MobileScannerController(
    detectionSpeed: ms.DetectionSpeed.normal,
    facing: ms.CameraFacing.back,
    torchEnabled: false,
    returnImage: false,
  );

  late AnimationController _laserController;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    Future.microtask(() {
      ref.read(barcodeScanViewModelProvider.notifier).initialize();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _cameraController.stop();
    } else if (state == AppLifecycleState.resumed) {
      _checkConnection();
      _cameraController.start();
      final scanState = ref.read(barcodeScanViewModelProvider);
      if (scanState.status == ScanState.scanning) {
        ref.read(barcodeScanViewModelProvider.notifier).initialize();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _laserController.dispose();
    _connectionSubscription?.cancel();
    _manualController.dispose();
    _manualFocusNode.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _initializeConnectivity() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    _updateConnectionStatus(result);
    
    _connectionSubscription = connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
     setState(() {
       _isConnected = !results.contains(ConnectivityResult.none);
     });
     final scanState = ref.read(barcodeScanViewModelProvider);
     if (_isConnected && scanState.lastResult?.productInfo == null) {
        ref.read(barcodeScanViewModelProvider.notifier).retryProductLookup();
     }
  }

  void _checkConnection() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }
  


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scanState = ref.watch(barcodeScanViewModelProvider);
    final recentHistory = ref.watch(scanHistoryProvider);
    final recentScans = recentHistory.take(5).map((r) => r.rawValue).toList();

    // Side effects listener
    ref.listen(barcodeScanViewModelProvider, (previous, next) async {
      if (previous?.status != next.status) {
        if (next.status == ScanState.detecting) {
          HapticFeedback.mediumImpact();
          try {
            await ref.read(deviceManagerProvider).vibrateSuccess();
            await ref.read(deviceManagerProvider).playClickSound();
          } catch (_) {
            SystemSound.play(SystemSoundType.click);
          }
        }
        if (next.status == ScanState.failed) {
          HapticFeedback.heavyImpact();
          try {
            await ref.read(deviceManagerProvider).vibrateError();
          } catch (_) {}
        }
        if (next.status == ScanState.completed) {
          setState(() => _scanCount++);
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Camera preview
            _buildCameraPreview(),
            
            // Scan overlay
            _buildScanOverlay(scanState.status),
            
            // Top controls
            _buildTopBar(l10n),
            
            // Network status indicator
            if (!_isConnected) _buildNetworkIndicator(l10n),
            
            // Timeout/Error UI
            if (scanState.status == ScanState.timeout || scanState.status == ScanState.failed)
              _buildErrorOverlay(l10n, scanState.status),

            // Processing indicator
            if (scanState.status == ScanState.validating) _buildProcessingOverlay(),
            
            // Bottom panel
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showHelp ? -300 : 0,
              left: 0,
              right: 0,
              child: _buildBottomPanel(l10n, scanState),
            ),
            
            // Recent scans quick access
            if (recentScans.isNotEmpty && !_showHelp) _buildRecentScansPanel(recentScans),
            
            // Help overlay
            if (_showHelp) _buildHelpOverlay(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      children: [
        ms.MobileScanner(
          controller: _cameraController,
          onDetect: _onDetect,
          overlayBuilder: (context, constraints) {
            return const SizedBox.shrink(); // Using custom overlay
          },
        ),
        
        // Grid overlay for better alignment
        CustomPaint(
          painter: GridOverlayPainter(),
          child: const SizedBox.expand(),
        ),
      ],
    );
  }

  void _onDetect(ms.BarcodeCapture capture) {
    ref.read(barcodeScanViewModelProvider.notifier).onDetect(capture);
  }



  Widget _buildScanOverlay(ScanState state) {
    return AnimatedBuilder(
      animation: _laserController,
      builder: (context, child) {
        Color frameColor;
        switch (state) {
          case ScanState.detecting:
            frameColor = AppColors.warning;
            break;
          case ScanState.validating:
            frameColor = Theme.of(context).primaryColor;
            break;
          case ScanState.completed:
            frameColor = AppColors.success;
            break;
          case ScanState.failed:
            frameColor = AppColors.error;
            break;
          case ScanState.timeout:
            frameColor = Colors.grey;
            break;
          default:
            frameColor = Colors.white.withValues(alpha: 0.5);
        }

        return CustomPaint(
          painter: ScanOverlayPainter(
            frameColor: frameColor,
            isScanning: state == ScanState.scanning || state == ScanState.detecting,
            scanProgress: _laserController.value,
            state: state,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button
                _buildIconButton(
                  icon: Icons.close,
                  onPressed: () => _confirmExit(l10n),
                  tooltip: l10n.cancel,
                ),
                
                // Title with scan counter
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.scanBarcode,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_scanCount > 0)
                      Text(
                        '$_scanCount ${l10n.scans}',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
                
                // Action buttons
                Row(
                  children: [
                    // Zoom toggle
                    _buildIconButton(
                      icon: _zoomIn ? Icons.zoom_out : Icons.zoom_in,
                      onPressed: _toggleZoom,
                      tooltip: _zoomIn 
                          ? 'Zoom Out' 
                          : 'Zoom In',
                    ),
                    
                    const SizedBox(width: 8),
                    
                      // Flash toggle
                    _buildIconButton(
                      icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                      onPressed: _toggleFlash,
                      tooltip: _flashOn 
                          ? 'Flash Off' 
                          : 'Flash On',
                      color: _flashOn ? AppColors.warning : Colors.white,
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Help toggle
                    _buildIconButton(
                      icon: Icons.help_outline,
                      onPressed: _toggleHelp,
                      tooltip: l10n.help,
                    ),
                  ],
                ),
              ],
            ),
            
            // Zoom slider
            if (_zoomIn)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Icon(Icons.remove, color: Colors.white, size: 20),
                    Expanded(
                      child: Slider.adaptive(
                        value: _zoomLevel,
                        min: 1.0,
                        max: 3.0,
                        divisions: 20,
                        activeColor: Theme.of(context).primaryColor,
                        inactiveColor: Colors.white.withValues(alpha: 0.3),
                        onChanged: (value) {
                          setState(() => _zoomLevel = value);
                          _adjustZoom(value);
                        },
                      ),
                    ),
                    Icon(Icons.add, color: Colors.white, size: 20),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: IconButton(
            icon: Icon(icon, color: color ?? Colors.white, size: 22),
            onPressed: onPressed,
            tooltip: tooltip,
            splashRadius: 22,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkIndicator(AppLocalizations l10n) {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Offline Mode', // Placeholder if generic string missing
                style: AppTypography.bodySmall.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(AppLocalizations l10n, ScanState state) {
    String title;
    String message;
    IconData icon;

    if (state == ScanState.timeout) {
      title = 'Scan Timeout';
      message = 'No barcode detected. Try holding the device closer or adjusting the light.';
      icon = Icons.timer_outlined;
    } else {
      title = 'Scan Failed';
      message = 'Failed to decode barcode. Please try again.';
      icon = Icons.error_outline;
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 64),
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTypography.titleLarge.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => ref.read(barcodeScanViewModelProvider.notifier).resetScanner(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Looking up product...',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Checking database and online sources',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(AppLocalizations l10n, BarcodeScanViewState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Apple-style drag indicator
                Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Instructions or result
                      if (state.lastResult != null)
                        _buildResultCard(state.lastResult!, l10n, state.status)
                      else
                        _buildInstructions(l10n),
                      
                      const SizedBox(height: 24),
                      
                      // Apple-style action buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildAppleButton(
                              label: l10n.enterManually,
                              icon: Icons.keyboard_rounded,
                              onPressed: _enterManually,
                              isPrimary: false,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAppleButton(
                              label: 'Use',
                              icon: Icons.check_rounded,
                              onPressed: state.lastResult != null ? () => _useResult(state.lastResult) : null,
                              isPrimary: true,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      
                      // Batch scan option
                      if (state.lastResult != null) ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => ref.read(barcodeScanViewModelProvider.notifier).startBatchScan(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 20,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Scan Another',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAppleButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isPrimary,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;
    
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary 
              ? (isEnabled ? theme.primaryColor : theme.primaryColor.withValues(alpha: 0.5))
              : isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: isPrimary ? null : Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary 
                  ? Colors.white
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: isPrimary 
                    ? Colors.white
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions(AppLocalizations l10n) {
    return Column(
      children: [
        Icon(
          Icons.qr_code_scanner_rounded,
          size: 48,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.scanBarcode,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildChip('QR Code', Icons.qr_code),
            _buildChip('EAN-13', Icons.barcode_reader),
            _buildChip('UPC', Icons.tag),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Chip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      labelStyle: AppTypography.labelSmall,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildResultCard(BarcodeScanResult result, AppLocalizations l10n, ScanState state) {
    final isValid = result.isValid;
    final statusColor = isValid ? AppColors.success : AppColors.warning;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.15),
            statusColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isValid ? Icons.check_circle_rounded : Icons.warning_rounded,
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isValid ? 'Barcode Detected' : 'Invalid Format',
                      style: AppTypography.labelMedium.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Format badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.format.name.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Barcode value with copy option
          GestureDetector(
            onTap: () => _copyToClipboard(result.rawValue),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      result.rawValue,
                      style: AppTypography.titleMedium.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Product info with loading/error states
          if (result.productInfo != null) ...[
            const SizedBox(height: 16),
            _buildProductInfo(result.productInfo!, l10n),
          ] else if (state == ScanState.validating) ...[
            const SizedBox(height: 16),
            _buildProductInfoShimmer(),
          ],
        ],
      ),
    );
  }
  


  Widget _buildProductInfo(ProductInfo info, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info.name != null)
          Text(
            info.name!,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        
        if (info.brand != null)
          Text(
            info.brand!,
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        
        if (info.price != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${info.currency ?? '€'}${info.price!.toStringAsFixed(2)}',
                style: AppTypography.titleMedium.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProductInfoShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 20,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRecentScansPanel(List<String> recentScans) {
    return Positioned(
      bottom: 200, // Above bottom panel
      left: 0,
      right: 0,
      child: SizedBox(
        height: 50,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: recentScans.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final scan = recentScans[index];
            return ActionChip(
              avatar: const Icon(Icons.history, size: 16),
              label: Text(scan),
              onPressed: () => _useRecentScan(scan),
              backgroundColor: Colors.black.withValues(alpha: 0.6),
              labelStyle: const TextStyle(color: Colors.white),
              side: BorderSide.none,
            );
          },
        ),
      ),
    );
  }

  Widget _buildHelpOverlay(AppLocalizations l10n) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 500,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(
                   l10n.help, // Assuming l10n.help exists, or use 'Help & Tips'
                   style: AppTypography.titleLarge,
                 ),
                 IconButton(
                   icon: const Icon(Icons.close),
                   onPressed: () => setState(() => _showHelp = false),
                 ),
               ],
             ),
             const SizedBox(height: 16),
             Expanded(
               child: ListView(
                 children: [
                   _buildHelpItem(
                     Icons.lightbulb_outline,
                     'Ensure Good Lighting', 
                     'Hold the barcode steady in a well-lit area for best results.',
                   ),
                   _buildHelpItem(
                     Icons.straighten,
                     'Keep Steady',
                     'Avoid shaking the device while scanning.',
                   ),
                   _buildHelpItem(
                     Icons.crop_free,
                     'Align in Frame',
                     'Position the barcode within the scan frame.',
                   ),
                   _buildHelpItem(
                     Icons.speed,
                     'Batch Scanning',
                     'Scan multiple items quickly by tapping "Scan Another".',
                   ),
                   _buildHelpItem(
                     Icons.wifi_off,
                     'Offline Mode',
                     'Scans are saved locally when offline and synced later.',
                   ),
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Methods
  void _toggleFlash() async {
    setState(() => _flashOn = !_flashOn);
    await ref.read(deviceManagerProvider).vibrateLight();
    analyticsService.trackEvent(AnalyticsEventType.featureUsed, {'feature': 'toggle_flash', 'state': _flashOn});
    _cameraController.toggleTorch();
  }

  void _toggleZoom() {
    setState(() {
      _zoomIn = !_zoomIn;
      _zoomLevel = _zoomIn ? 1.5 : 1.0;
    });
    analyticsService.trackEvent(AnalyticsEventType.featureUsed, {'feature': 'toggle_zoom', 'state': _zoomIn});
    _cameraController.setZoomScale(_zoomLevel);
  }

  void _adjustZoom(double level) {
    _cameraController.setZoomScale(level);
    analyticsService.trackEvent(AnalyticsEventType.featureUsed, {'feature': 'adjust_zoom', 'level': level});
  }

  void _toggleHelp() {
    setState(() => _showHelp = !_showHelp);
    analyticsService.trackEvent(AnalyticsEventType.featureUsed, {'feature': 'toggle_help', 'state': _showHelp});
  }

  void _enterManually() {
    final recentHistory = ref.read(scanHistoryProvider);
    final recentScans = recentHistory.take(5).map((r) => r.rawValue).toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManualEntrySheet(
        recentScans: recentScans,
        onSubmit: (barcode) {
          ref.read(barcodeScanViewModelProvider.notifier).onManualEntry(barcode);
        },
      ),
    );
    analyticsService.trackEvent(AnalyticsEventType.featureUsed, {'feature': 'manual_entry_opened'});
  }

  void _useResult(BarcodeScanResult? result) {
    if (result == null) return;
    context.pop(result);
  }

  void _useRecentScan(String barcode) {
    ref.read(barcodeScanViewModelProvider.notifier).onManualEntry(barcode);
    analyticsService.trackEvent(AnalyticsEventType.featureUsed, {'feature': 'recent_scan_used'});
  }

  void _confirmExit(AppLocalizations translations) {
    if (_scanCount > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(translations.unsavedChanges),
          content: Text(translations.exitScanConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(translations.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              child: Text(translations.discard),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                final scanState = ref.read(barcodeScanViewModelProvider);
                _useResult(scanState.lastResult);
              },
              child: Text(translations.saveAndExit),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }

  void _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
    await ref.read(deviceManagerProvider).vibrateSelection();
    analyticsService.trackEvent(AnalyticsEventType.featureUsed, {'feature': 'barcode_copied'});
  }
}

/// Enhanced Manual Entry Sheet
class _ManualEntrySheet extends StatefulWidget {
  final List<String> recentScans;
  final void Function(String barcode) onSubmit;

  const _ManualEntrySheet({
    required this.recentScans,
    required this.onSubmit,
  });

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _validationMessage = '';
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _controller.addListener(_validateBarcode);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _validateBarcode() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _validationMessage = '');
      return;
    }

    setState(() => _isValidating = true);
    await Future.delayed(const Duration(milliseconds: 300));
    
    final format = _detectFormat(value);
    final validation = BarcodeValidator.validate(value, format: format);
    final isValid = validation.isValid;
    
    setState(() {
      _validationMessage = isValid 
          ? '✓ Valid ${format.name.toUpperCase()} barcode'
          : '⚠ Check barcode format and length';
      _isValidating = false;
    });
  }

  BarcodeFormat _detectFormat(String value) {
    if (RegExp(r'^[0-9]{12,13}$').hasMatch(value)) return BarcodeFormat.ean13;
    if (value.startsWith('http')) return BarcodeFormat.qr;
    return BarcodeFormat.unknown;
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  translations.enterManually,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Recent scans quick selection
            if (widget.recentScans.isNotEmpty) ...[
              Text(
                'Recent scans:',
                style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.recentScans.map((scan) => InputChip(
                  label: Text(scan),
                  onPressed: () {
                    _controller.text = scan;
                    _validateBarcode();
                  },
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: translations.barcodeExample,
                prefixIcon: const Icon(Icons.qr_code),
                suffixIcon: _isValidating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _validationMessage.isNotEmpty
                        ? Icon(
                            _validationMessage.startsWith('✓') 
                                ? Icons.check_circle 
                                : Icons.warning,
                            color: _validationMessage.startsWith('✓')
                                ? AppColors.success
                                : AppColors.warning,
                          )
                        : null,
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 20,
              onSubmitted: _submit,
            ),
            
            if (_validationMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 8),
                child: Text(
                  _validationMessage,
                  style: AppTypography.labelSmall.copyWith(
                    color: _validationMessage.startsWith('✓')
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _submit(_controller.text),
                child: const Text('Look Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      Navigator.pop(context);
      widget.onSubmit(trimmed);
    }
  }
}

/// Enhanced Scan Overlay Painter with animation
class ScanOverlayPainter extends CustomPainter {
  final Color frameColor;
  final bool isScanning;
  final double scanProgress;
  final ScanState state;

  ScanOverlayPainter({
    required this.frameColor,
    required this.isScanning,
    required this.scanProgress,
    required this.state,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final frameSize = size.width * 0.7;
    final frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.35),
      width: frameSize,
      height: frameSize,
    );

    // Draw dark overlay with cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(16)));
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Animated scanning line
    if (isScanning) {
      final linePaint = Paint()
        ..color = frameColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          colors: [
            frameColor.withValues(alpha: 0.1),
            frameColor,
            frameColor.withValues(alpha: 0.1),
          ],
        ).createShader(Rect.fromLTRB(
          frameRect.left,
          frameRect.top + frameRect.height * scanProgress,
          frameRect.right,
          frameRect.top + frameRect.height * scanProgress + 4,
        ));

      canvas.drawRect(
        Rect.fromLTRB(
          frameRect.left + 10,
          frameRect.top + frameRect.height * scanProgress,
          frameRect.right - 10,
          frameRect.top + frameRect.height * scanProgress + 4,
        ),
        linePaint,
      );
    }

    // Draw frame border with gradient
    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = LinearGradient(
        colors: [
          frameColor.withValues(alpha: 0.3),
          frameColor,
          frameColor.withValues(alpha: 0.3),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(frameRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(16)),
      framePaint,
    );

    // Draw animated corner accents
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Corner coordinates
    final corners = [
      frameRect.topLeft,
      frameRect.topRight,
      frameRect.bottomRight,
      frameRect.bottomLeft,
    ];

    for (final corner in corners) {
      // Draw corner lines
      canvas.drawLine(
        corner + const Offset(0, 16),
        corner + Offset(0, 16 + cornerLength),
        cornerPaint,
      );
      canvas.drawLine(
        corner + const Offset(16, 0),
        corner + Offset(16 + cornerLength, 0),
        cornerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ScanOverlayPainter oldDelegate) {
    return oldDelegate.frameColor != frameColor ||
        oldDelegate.isScanning != isScanning ||
        oldDelegate.scanProgress != scanProgress;
  }
}

/// Grid overlay for better alignment
class GridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double i = 0; i <= size.width; i += size.width / 10) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }

    // Draw horizontal lines
    for (double i = 0; i <= size.height; i += size.height / 10) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Center crosshair
    final center = Offset(size.width / 2, size.height / 2);
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(center.dx - 20, center.dy),
      Offset(center.dx + 20, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 20),
      Offset(center.dx, center.dy + 20),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}