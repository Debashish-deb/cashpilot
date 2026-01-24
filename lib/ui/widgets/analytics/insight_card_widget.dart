import 'package:flutter/material.dart';

class InsightCardWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final String? actionLabel;

  const InsightCardWidget({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.color = Colors.blue,
    this.onAction,
    this.onDismiss,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Safer, stable key (prevents duplicate-title crashes)
    final dismissKey = ValueKey('$title-$message');

    final dismissibleEnabled = onDismiss != null;

    return Semantics(
      label: 'Insight: $title',
      hint: message,
      child: Dismissible(
        key: dismissKey,
        direction: dismissibleEnabled
            ? DismissDirection.endToStart
            : DismissDirection.none,
        onDismissed: dismissibleEnabled ? (_) => onDismiss?.call() : null,
        background: _buildDismissBackground(context),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
                ),
                if (onAction != null) ...[
                  const SizedBox(height: 12),
                  _buildAction(theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (onDismiss != null)
          IconButton(
            tooltip: 'Dismiss insight',
            icon: const Icon(Icons.close, size: 20),
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildAction(ThemeData theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onAction,
        icon: const Icon(Icons.arrow_forward, size: 16),
        label: Text(actionLabel ?? 'Take action'),
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: theme.textTheme.labelLarge,
        ),
      ),
    );
  }

  Widget _buildDismissBackground(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}
