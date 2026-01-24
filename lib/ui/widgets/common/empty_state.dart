import 'package:flutter/material.dart';
import '../../widgets/common/glass_card.dart';
import '../../../core/theme/app_typography.dart';

/// Empty State Widget
/// 
/// Replaces generic empty lists with friendly, illustration-based placeholders.
/// Follows UI Polish guide: Icon + Friendly Sentence + Clear Action.
class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback? onAction;
  final IconData icon;
  final bool useGlass;

  const EmptyState({
    super.key,
    this.title = 'It\'s quiet here',
    required this.message,
    this.buttonLabel = 'Get Started',
    this.onAction,
    this.icon = Icons.inbox_outlined,
    this.useGlass = true,
  });

  @override
  Widget build(BuildContext context) {
    if (useGlass) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        borderRadius: 24,
        child: _buildContent(context),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Circle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 16),
          
          // Friendly Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          
          // Clear Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          
          // Clear Action
          if (onAction != null)
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
