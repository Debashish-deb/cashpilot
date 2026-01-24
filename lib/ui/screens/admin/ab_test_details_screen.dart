import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/ml/services/ab_testing_service.dart';
import '../../../../core/theme/app_typography.dart';

class ABTestDetailsScreen extends ConsumerWidget {
  final ABTest test;

  const ABTestDetailsScreen({super.key, required this.test});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final improvement = test.results?['improvement'] as double? ?? 0.0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(test.testName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(context),
            const SizedBox(height: 24),
            Text('Comparison', style: AppTypography.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard(
                  context, 
                  'Control (A)', 
                  test.controlVersion, 
                  test.controlStats,
                  false
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard(
                  context, 
                  'Treatment (B)', 
                  test.treatmentVersion, 
                  test.treatmentStats,
                  improvement > 0
                )),
              ],
            ),
            const SizedBox(height: 24),
            Text('Details', style: AppTypography.titleLarge),
            const SizedBox(height: 16),
            _buildDetailRow('Model Name', test.modelName),
            _buildDetailRow('Test ID', test.id),
            _buildDetailRow('Start Date', test.startDate.toString().split('.')[0]),
            if (test.endDate != null)
              _buildDetailRow('End Date', test.endDate.toString().split('.')[0]),
            _buildDetailRow('Treatment Ratio', '${(test.treatmentRatio * 100).toInt()}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final isCompleted = test.status == 'completed';
    final color = isCompleted 
        ? (test.results?['improvement'] ?? 0) > 0 ? Colors.green : Colors.grey
        : Colors.blue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.science,
            color: color,
            size: 32,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCompleted ? 'Test Completed' : 'Test Running',
                style: AppTypography.titleMedium.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              if (isCompleted && test.results != null)
                Text(
                  'Improvement: ${((test.results!['improvement'] ?? 0) * 100).toStringAsFixed(2)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String version, ModelStats stats, bool isWinner) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWinner ? Colors.green.withValues(alpha: 0.1) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner ? Colors.green : Theme.of(context).dividerColor,
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.labelMedium),
          Text(version, style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
          const SizedBox(height: 12),
          _buildMetric('Acceptance', '${(stats.acceptanceRate * 100).toStringAsFixed(1)}%'),
          _buildMetric('Total Scans', '${stats.totalScans}'),
          _buildMetric('Accepted', '${stats.acceptedScans}'),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Monospace'))),
        ],
      ),
    );
  }
}
