import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/core/theme/app_typography.dart';
import 'package:cashpilot/features/ml/services/ab_testing_service.dart';
import 'package:cashpilot/features/ml/providers/ab_testing_providers.dart';
import 'package:cashpilot/ui/widgets/common/glass_card.dart';
import 'widgets/create_test_dialog.dart';
import 'ab_test_details_screen.dart';

/// A/B Testing Dashboard Screen - Phase 3
/// Admin screen for managing A/B tests and comparing model performance
class ABTestingScreen extends ConsumerWidget {
  const ABTestingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('A/B Testing Dashboard'),
        backgroundColor: isDark ? Colors.grey.shade900 : const Color(0xFF6750A4),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeTestsProvider);
          ref.invalidate(completedTestsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildActiveTestsSection(ref),
            const SizedBox(height: 24),
            _buildCompletedTestsSection(ref),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTestDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Test'),
      ),
    );
  }

  Widget _buildActiveTestsSection(WidgetRef ref) {
    final activeTestsAsync = ref.watch(activeTestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Tests',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        activeTestsAsync.when(
          data: (tests) {
            if (tests.isEmpty) return _buildEmptyState('No active tests');
            return Column(
              children: tests.map((test) => _buildTestCard(ref, test, context: null)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildCompletedTestsSection(WidgetRef ref) {
    final completedTestsAsync = ref.watch(completedTestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completed Tests',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        completedTestsAsync.when(
          data: (tests) {
            if (tests.isEmpty) return _buildEmptyState('No completed tests yet');
            return Column(
              children: tests.map((test) => _buildCompletedTestItem(ref, test)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildTestCard(WidgetRef ref, ABTest test, {BuildContext? context}) {
    // Note: context is not needed for internal logic anymore, but kept implementation structure
    return Consumer(
      builder: (context, ref, _) {
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      test.testName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Started: ${_formatDate(test.startDate)}',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              // Performance comparison
              Row(
                children: [
                  Expanded(
                    child: _buildModelStats(
                      'Control (${test.controlVersion})',
                      test.controlStats,
                      false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModelStats(
                      'Treatment (${test.treatmentVersion})',
                      test.treatmentStats,
                      _isWinning(test.controlStats, test.treatmentStats),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _showTestDetails(context, test),
                    icon: const Icon(Icons.analytics),
                    label: const Text('View Details'),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _endTest(context, ref, test),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                    ),
                    icon: const Icon(Icons.stop),
                    label: const Text('End Test'),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildModelStats(String label, ModelStats stats, bool isWinning) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWinning
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: isWinning
            ? Border.all(color: Colors.green, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isWinning)
                Icon(Icons.star, size: 16, color: Colors.green.shade700),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${(stats.acceptanceRate * 100).toInt()}% accept',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${stats.totalScans} scans',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTestItem(WidgetRef ref, ABTest test) {
    final improvement = test.results?['improvement'] as double? ?? 0.0;
    final isImprovement = improvement > 0;

    return Consumer(
      builder: (context, ref, _) {
        return ListTile(
          leading: Icon(
            isImprovement ? Icons.trending_up : Icons.trending_down,
            color: isImprovement ? Colors.green : Colors.red,
          ),
          title: Text(test.testName),
          subtitle: Text(
            'Ended: ${_formatDate(test.endDate ?? test.startDate)}',
          ),
          trailing: Text(
            '${improvement > 0 ? '+' : ''}${(improvement * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: isImprovement ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () => _showTestDetails(context, test),
        );
      }
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.science, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isWinning(ModelStats control, ModelStats treatment) {
    return treatment.acceptanceRate > control.acceptanceRate;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30} ${difference.inDays ~/ 30 == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _showCreateTestDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const CreateTestDialog(),
    );
  }

  Future<void> _showTestDetails(BuildContext context, ABTest test) async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ABTestDetailsScreen(test: test)),
    );
  }

  Future<void> _endTest(BuildContext context, WidgetRef ref, ABTest test) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End A/B Test?'),
        content: Text('Are you sure you want to end "${test.testName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('End Test'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(abTestingServiceProvider);
        await service.endTest(test.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test ended successfully')),
          );
          // Refresh lists
          ref.invalidate(activeTestsProvider);
          ref.invalidate(completedTestsProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to end test: $e')),
          );
        }
      }
    }
  }
}
