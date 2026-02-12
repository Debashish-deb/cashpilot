/// Receipt Scan Screen
/// Apple-themed premium camera interface for scanning receipts
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/constants/subscription.dart';
import '../../../services/receipt_scanner_service.dart';
import '../../../services/analytics_tracking_service.dart';
import '../../../features/subscription/providers/subscription_providers.dart';

class ReceiptScanScreen extends ConsumerStatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  ConsumerState<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends ConsumerState<ReceiptScanScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  ReceiptScanResult? _scanResult;
  String? _error;
  late AnimationController _pulseController;

  bool get _hasLowConfidence =>
      _scanResult != null && _scanResult!.overallConfidence < 0.45;

  bool get _hasMediumConfidence =>
      _scanResult != null &&
      _scanResult!.overallConfidence >= 0.45 &&
      _scanResult!.overallConfidence < 0.75;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: _scanResult != null
              ? _buildResultView()
              : _buildScanOptions(),
        ),
      ),
    );
  }

  // ===========================================================================
  // APPLE-STYLE SCAN OPTIONS VIEW
  // ===========================================================================

  Widget _buildScanOptions() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Apple-style navigation bar
        _buildAppleNavBar(l10n, isDark),

        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 20.0;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Animated scan icon
                _buildAnimatedScanIcon(theme),

                const SizedBox(height: 32),

                // Title
                Text(
                  l10n.scanTitle,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.scanSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 48),

                // Premium glass-style action buttons
                _buildAppleActionButton(
                  icon: Icons.camera_alt_rounded,
                  title: l10n.scanTakePhoto,
                  subtitle: 'Take a photo of your receipt',
                  onTap: _isScanning ? null : _scanFromCamera,
                  isPrimary: true,
                  isDark: isDark,
                ),

                const SizedBox(height: 16),

                _buildAppleActionButton(
                  icon: Icons.photo_library_rounded,
                  title: l10n.scanGallery,
                  subtitle: 'Choose from your photo library',
                  onTap: _isScanning ? null : _scanFromGallery,
                  isPrimary: false,
                  isDark: isDark,
                ),

                // Loading state
                if (_isScanning) ...[
                  const SizedBox(height: 40),
                  _buildLoadingIndicator(),
                ],

                // Error message
                if (_error != null) ...[
                  const SizedBox(height: 32),
                  _buildAppleErrorCard(),
                ],

                const SizedBox(height: 40),

                // Tips section
                _buildTipsSection(isDark),

                const SizedBox(height: 32),
              ],
            ),
            );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppleNavBar(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.5)
            : Colors.white.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          
          // Title
          Text(
            l10n.scanTitle,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          // Spacer for alignment
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildAnimatedScanIcon(ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                theme.primaryColor.withOpacity(0.15 + (_pulseController.value * 0.1)),
                theme.primaryColor.withOpacity(0.05),
                Colors.transparent,
              ],
              stops: const [0.3, 0.7, 1.0],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppleActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required bool isPrimary,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPrimary
              ? theme.primaryColor
              : isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08),
                ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.white.withOpacity(0.2)
                    : theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isPrimary ? Colors.white : theme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isPrimary ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isPrimary
                          ? Colors.white.withOpacity(0.8)
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: isPrimary
                  ? Colors.white.withOpacity(0.8)
                  : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.scanScanning,
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildAppleErrorCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.danger.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _error = null),
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.danger,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.scanTipsTitle,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem(l10n.scanTipLighting),
          _buildTipItem(l10n.scanTipSteady),
          _buildTipItem(l10n.scanTipEntire),
          _buildTipItem(l10n.scanTipShadows),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // APPLE-STYLE RESULT VIEW
  // ===========================================================================

  Widget _buildResultView() {
    final result = _scanResult!;
    final currency = ref.watch(currencyProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        _buildAppleNavBar(l10n, isDark),
        
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 20.0;
              return ListView(
                padding: EdgeInsets.all(horizontalPadding),
            children: [
              // DUPLICATE WARNING BANNER (NEW!)
              if (result.duplicateWarning != null)
                _buildDuplicateWarningBanner(result.duplicateWarning!, isDark),
                
              if (result.duplicateWarning != null)
                const SizedBox(height: 16),
              
              // Confidence indicator
              _buildAppleConfidenceCard(result.overallConfidence),

              const SizedBox(height: 24),

              // Extracted data cards with confidence badges
              if (result.hasAmount)
                _buildAppleDataCard(
                  icon: Icons.payments_rounded,
                  label: l10n.scanTotalAmount,
                  value: _formatCurrency(context, result.extractedAmount!, currency),
                  color: AppColors.success,
                  isDark: isDark,
                  confidence: result.extraction?.total?.confidence,
                ),

              if (result.hasMerchant) ...[
                const SizedBox(height: 12),
                _buildAppleDataCard(
                  icon: Icons.store_rounded,
                  label: l10n.scanMerchant,
                  value: result.merchantName!,
                  color: AppColors.info,
                  isDark: isDark,
                  confidence: result.extraction?.merchant?.confidence,
                ),
              ],

              if (result.hasDate) ...[
                const SizedBox(height: 12),
                _buildAppleDataCard(
                  icon: Icons.calendar_today_rounded,
                  label: l10n.scanDate,
                  value: '${result.transactionDate!.day}/${result.transactionDate!.month}/${result.transactionDate!.year}',
                  color: AppColors.warning,
                  isDark: isDark,
                  confidence: result.extraction?.date?.confidence,
                ),
              ],

              const SizedBox(height: 24),

              // Raw text expandable
              _buildRawTextExpansion(result, isDark),

              const SizedBox(height: 32),

              // Action buttons
              _buildAppleActionButtons(result),
            ],
          );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppleConfidenceCard(double confidence) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final color = confidence < 0.45
        ? AppColors.danger
        : confidence < 0.75
            ? AppColors.warning
            : AppColors.success;
    
    final label = confidence < 0.45
        ? 'Low'
        : confidence < 0.75
            ? 'Medium'
            : 'High';

    final icon = confidence < 0.45
        ? Icons.warning_rounded
        : confidence < 0.75
            ? Icons.info_rounded
            : Icons.check_circle_rounded;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(confidence * 100).toInt()}%',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppleDataCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    double? confidence, // ML Enhancement: Confidence badge
  }) {
    // Determine confidence color
    final confidenceColor = confidence != null
        ? (confidence > 0.85 
            ? Colors.green 
            : confidence > 0.65 
                ? Colors.orange 
                : Colors.red)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    // ML Enhancement: Confidence Badge
                    if (confidence != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: confidenceColor!.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(confidence * 100).toInt()}%',
                          style: AppTypography.labelSmall.copyWith(
                            color: confidenceColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      if (confidence < 0.65)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: Colors.orange.shade700,
                          ),
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawTextExpansion(ReceiptScanResult result, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        collapsedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        title: Row(
          children: [
            const Icon(Icons.article_outlined, size: 20),
            const SizedBox(width: 12),
            Text(
              l10n.scanRawText,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              result.rawText,
              style: AppTypography.bodySmall.copyWith(
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppleActionButtons(ReceiptScanResult result) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: MediaQuery.textScalerOf(context).scale(120).clamp(120.0, 160.0),
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _scanResult = null),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.scanAgain, maxLines: 1, overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: MediaQuery.textScalerOf(context).scale(180).clamp(180.0, 240.0),
            child: FilledButton.icon(
              onPressed: result.hasAmount
                  ? () => _createExpenseFromResult(result)
                  : null,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.expensesAddExpense, maxLines: 1, overflow: TextOverflow.ellipsis),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCANNING FUNCTIONS
  // ===========================================================================

  Future<void> _scanFromCamera() async {
    await _performScan(true);
  }

  Future<void> _scanFromGallery() async {
    await _performScan(false);
  }

  Future<void> _performScan(bool fromCamera) async {
    // Get current subscription tier
    final currentTierAsync = ref.watch(currentTierProvider);
    final currentTier = currentTierAsync.value ?? SubscriptionTier.free;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      final scanner = ref.read(receiptScannerProvider);
      final result = fromCamera
          ? await scanner.scanFromCamera(tier: currentTier)
          : await scanner.scanFromGallery(tier: currentTier);

      if (result != null) {
        // Check if gated (user doesn't have access)
        if (result.gated) {
          setState(() {
            _error = result.gatedReason ?? 'OCR scanning requires a Pro subscription';
          });
          return;
        }
        
        // Track usage
        analyticsService.trackEvent(
          AnalyticsEventType.ocrScan,
          {'success': true, 'confidence': result.overallConfidence},
        );

        setState(() {
          _scanResult = result;
        });
      }
    } catch (e) {
      analyticsService.trackEvent(AnalyticsEventType.ocrScan, {'success': false});
      setState(() {
        _error = 'Failed to scan receipt: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _createExpenseFromResult(ReceiptScanResult result) async {
    // Navigate to expense form with OCR data
    final created = await context.push<bool>(
      AppRoutes.addExpense,
      extra: {
        'amount': result.extractedAmount,
        'merchant': result.merchantName,
        'date': result.transactionDate,
        'categoryKey': result.suggestedCategoryKey,
        'currency': result.currencyCode,
        'fromOCR': true, // Flag to indicate OCR source
        'receiptMeta': result.extraction, // Pass typed metadata for learning
      },
    );
    
    // If expense was created successfully
    if (created == true && mounted) {
      // Show success confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Expense created successfully!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Reset to scan another or return to previous screen
      if (mounted) {
        // Option 1: Reset to scan another receipt
        setState(() {
          _scanResult = null;
          _error = null;
        });
        
        // Option 2: Uncomment to close scanner after successful creation
        // Future.delayed(const Duration(milliseconds: 500), () {
        //   if (mounted) context.pop();
        // });
      }
    }
  }

  // ===========================================================================
  // ML ENHANCEMENTS - DUPLICATE WARNING (Phase 1)
  // ===========================================================================

  Widget _buildDuplicateWarningBanner(String warning, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.orange.shade900.withValues(alpha: 0.2)
            : Colors.orange.shade50,
        border: Border.all(
          color: Colors.orange.shade700,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Possible Duplicate',
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  warning,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark 
                        ? Colors.orange.shade200 
                        : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.info_outline,
            color: Colors.orange.shade600,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  String _formatCurrency(BuildContext context, int amountInCents, String currency) {
    final amount = amountInCents / 100;
    return NumberFormat.currency(
      locale: AppLocalizations.of(context)!.localeName,
      symbol: currency == 'EUR' ? '€' : currency,
      decimalDigits: 2,
    ).format(amount);
  }
}
