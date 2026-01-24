import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_routes.dart';
// for RecurringExpense
import '../../../../features/expenses/providers/expense_providers.dart';
import '../../../../core/managers/format_manager.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../common/glass_card.dart';

class UpcomingBillsCard extends ConsumerWidget {
  const UpcomingBillsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(upcomingBillsProvider);
    final formatManager = ref.watch(formatManagerProvider);
    final currency = ref.watch(currencyProvider);
    final l10n = AppLocalizations.of(context)!;

    return billsAsync.when(
      data: (bills) {
        if (bills.isEmpty) {
          // Hide card if no bills? Or show 'No upcoming bills' placeholder?
          // User request implies "make them truly sync", if empty show nothing or empty state.
          // Usually a card taking space with empty state is better than disappearing if it's a main dashboard widget.
          return const SizedBox.shrink(); 
        }

        // Sort by due date (already sorted by provider but safe to ensure)
        // Provider: orderBy: [(t) => OrderingTerm.asc(t.nextDueDate)]
        
        // Take next 5 bills
        final upcoming = bills.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.budgetsUpcoming, style: AppTypography.titleSmall),
                TextButton(
                  onPressed: () => context.push(AppRoutes.recurringExpenses),
                  child: Text(l10n.homeSeeAll),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: upcoming.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final bill = upcoming[index];
                  final now = DateTime.now();
                  // Reset time components for accurate day diff
                  final today = DateTime(now.year, now.month, now.day);
                  final due = DateTime(bill.nextDueDate.year, bill.nextDueDate.month, bill.nextDueDate.day);
                  final daysLeft = due.difference(today).inDays;
                  
                  final isOverdue = daysLeft < 0;
                  final isDueToday = daysLeft == 0;
                  
                  final String dayText = isOverdue 
                      ? '${formatManager.formatNumber(daysLeft.abs())}d ago' 
                      : isDueToday 
                          ? l10n.homeToday 
                          : '${formatManager.formatNumber(daysLeft)} days';

                  final color = _getColor(bill.title);
                  final icon = _getIcon(bill.title);

                  return GlassCard(
                    width: 130,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 18),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (daysLeft <= 3 && !isOverdue) 
                                    ? AppColors.warning.withValues(alpha: 0.2) 
                                    : isOverdue 
                                        ? AppColors.error.withValues(alpha: 0.2)
                                        : AppColors.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                dayText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: (daysLeft <= 3 && !isOverdue)
                                      ? AppColors.warning
                                      : isOverdue 
                                          ? AppColors.error
                                          : AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          bill.title,
                          style: AppTypography.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatManager.formatCurrency(bill.amount / 100, currencyCode: currency),
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
      error: (e, s) => SizedBox(height: 0), // Use minimal specific handling, or hide
    );
  }

  Color _getColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('netflix') || t.contains('youtube') || t.contains('movie')) return Colors.red;
    if (t.contains('spotify') || t.contains('music')) return Colors.green;
    if (t.contains('prime') || t.contains('amazon')) return Colors.blueAccent;
    if (t.contains('internet') || t.contains('wifi')) return Colors.cyan;
    if (t.contains('rent') || t.contains('house')) return Colors.orange;
    return Colors.purple; // Default
  }

  IconData _getIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('netflix') || t.contains('movie')) return Icons.movie;
    if (t.contains('music') || t.contains('spotify')) return Icons.music_note;
    if (t.contains('rent') || t.contains('house')) return Icons.home;
    if (t.contains('wifi') || t.contains('internet')) return Icons.wifi;
    if (t.contains('electric') || t.contains('power')) return Icons.bolt;
    return Icons.receipt_long;
  }
}
