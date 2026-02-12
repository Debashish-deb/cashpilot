import 'package:cashpilot/l10n/app_localizations.dart' show AppLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/core/theme/app_typography.dart';
import 'package:cashpilot/features/notifications/models/app_notification.dart';
import 'package:cashpilot/features/notifications/providers/notification_providers.dart';
import 'package:cashpilot/ui/widgets/common/glass_card.dart';
import 'package:cashpilot/core/theme/tokens.g.dart';

class NotificationDialog extends ConsumerWidget {
  const NotificationDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(notificationsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        borderRadius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.notifTitle, style: AppTypography.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: notificationsAsync.when(
                  data: (notifications) {
                    if (notifications.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.notifications_none, size: 48, color: Theme.of(context).hintColor),
                            const SizedBox(height: 16),
                            Text(l10n.notifEmpty, textAlign: TextAlign.center),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _NotificationItem(notification: notifications[index]);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text(AppLocalizations.of(context)!.commonError)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInvite = notification.type == 'budget_invite';
    final l10n = AppLocalizations.of(context)!;
    final accentColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead 
              ? Colors.transparent 
              : accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isInvite ? Icons.mail_outline_rounded : Icons.info_outline_rounded,
                size: 20,
                color: isInvite ? AppTokens.brandSecondary : accentColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  notification.title,
                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: AppTokens.semanticDanger, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(notification.body, style: AppTypography.bodySmall),
          
          if (isInvite && notification.data.containsKey('budget_id')) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    try {
                      final budgetId = notification.data['budget_id'];
                      await NotificationActions.declineBudgetInvite(budgetId);
                      await NotificationActions.markAsRead(notification.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.notifInvitationDeclined)));
                      }
                    } catch (e) {
                      debugPrint('Error declining: $e');
                    }
                  },
                  child: Text(l10n.notifDecline, style: const TextStyle(color: AppTokens.semanticDanger)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    try {
                      final budgetId = notification.data['budget_id'];
                      await NotificationActions.acceptBudgetInvite(budgetId);
                      await NotificationActions.markAsRead(notification.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.notifWelcomeToBudget)));
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      debugPrint('Error accepting: $e');
                      if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.commonError)));
                      }
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: accentColor, visualDensity: VisualDensity.compact),
                  child: Text(l10n.notifAccept),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
