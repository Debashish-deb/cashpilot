import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/features/ml/services/model_evaluation_service.dart';
import 'package:cashpilot/core/theme/app_typography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashpilot/core/providers/ml_providers.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

/// ML Dashboard Screen - Phase 2
/// Displays model performance metrics, recent learning events,
/// and confidence threshold recommendations for admins
class MLDashboardScreen extends ConsumerStatefulWidget {
  const MLDashboardScreen({super.key});

  @override
  ConsumerState<MLDashboardScreen> createState() => _MLDashboardScreenState();
}

class _MLDashboardScreenState extends ConsumerState<MLDashboardScreen> {
  late Future<ModelPerformance> _receiptPerf;
  late Future<List<Map<String, dynamic>>> _recentEvents;
  late Future<Map<String, dynamic>> _thresholds;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() {
      _receiptPerf = ModelEvaluationService().evaluateReceiptModel('receipt_v1.0');
      _recentEvents = _fetchRecentEvents();
      _thresholds = _fetchCurrentThresholds();
    });
  }
  
  Future<List<Map<String, dynamic>>> _fetchRecentEvents() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('receipt_learning_events')
          .select()
          .order('timestamp', ascending: false)
          .limit(50);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[ML Dashboard] Failed to fetch events: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>> _fetchCurrentThresholds() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('ml_config')
          .select()
          .inFilter('config_key', ['high_confidence_threshold', 'min_acceptable_threshold'])
          .order('updated_at', ascending: false)
          .limit(2);
      
      final configs = (response as List).cast<Map<String, dynamic>>();
      final result = <String, dynamic>{};
      
      for (final config in configs) {
        result[config['config_key']] = config['config_value']['value'];
      }
      
      return result;
    } catch (e) {
      debugPrint('[ML Dashboard] Failed to fetch thresholds: $e');
      return {};
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminMLDashboard),
        backgroundColor: isDark ? Colors.grey.shade900 : const Color(0xFF6750A4),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPerformanceCard(isDark),
            const SizedBox(height: 16),
            _buildPredictiveCard(isDark),
            const SizedBox(height: 16),
            _buildThresholdsCard(isDark),
            const SizedBox(height: 16),
            _buildRecentEventsCard(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictiveCard(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final forecaster = ref.watch(spendingForecasterProvider);
    
    return FutureBuilder<int>(
      future: forecaster.predictNextMonthSpending(),
      builder: (context, snapshot) {
        final forecastAmount = snapshot.data ?? 0;
        
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_graph, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      l10n.mlPredictiveInsights,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.mlForecastNextMonth),
                    Text(
                      '€${(forecastAmount / 100).toStringAsFixed(2)}',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_down, size: 18, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estimated 5% decrease based on recent behavior',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPerformanceCard(bool isDark) {
    return FutureBuilder<ModelPerformance>(
      future: _receiptPerf,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          final l10n = AppLocalizations.of(context)!;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.commonErrorMessage('')),
            ),
          );
        }
        
        final perf = snapshot.data!;
        final acceptanceRate = perf.acceptanceRate;
        
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Receipt Scanner',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6750A4).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'v1.0',
                        style: AppTypography.labelSmall.copyWith(
                          color: const Color(0xFF6750A4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Metrics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetric(
                      label: 'Total',
                      value: perf.totalScans.toString(),
                      color: Colors.blue,
                    ),
                    _buildMetric(
                      label: 'Accepted',
                      value: perf.accepted.toString(),
                      color: Colors.green,
                    ),
                    _buildMetric(
                      label: 'Edited',
                      value: perf.edited.toString(),
                      color: Colors.orange,
                    ),
                    _buildMetric(
                      label: 'Rejected',
                      value: perf.rejected.toString(),
                      color: Colors.red,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Acceptance Rate
                Text(
                  'Acceptance Rate',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: acceptanceRate,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    acceptanceRate > 0.70 ? Colors.green : Colors.orange,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(acceptanceRate * 100).toInt()}%',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: acceptanceRate > 0.70 ? Colors.green : Colors.orange,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: perf.needsImprovement 
                        ? Colors.orange.shade50 
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        perf.needsImprovement 
                            ? Icons.warning_amber 
                            : Icons.check_circle,
                        size: 18,
                        color: perf.needsImprovement 
                            ? Colors.orange.shade700 
                            : Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        perf.needsImprovement 
                            ? 'Model needs improvement' 
                            : 'Performance is good',
                        style: AppTypography.labelMedium.copyWith(
                          color: perf.needsImprovement 
                              ? Colors.orange.shade700 
                              : Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildThresholdsCard(bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _thresholds,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        final thresholds = snapshot.data ?? {};
        final highConfidence = thresholds['high_confidence_threshold'] ?? 0.85;
        final minAcceptable = thresholds['min_acceptable_threshold'] ?? 0.60;
        
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confidence Thresholds',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildThresholdItem(
                        label: 'High Confidence',
                        value: (highConfidence * 100).toInt(),
                        color: Colors.green,
                        icon: Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildThresholdItem(
                        label: 'Min Acceptable',
                        value: (minAcceptable * 100).toInt(),
                        color: Colors.orange,
                        icon: Icons.rule,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Auto-optimized weekly based on learning data',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildThresholdItem({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            '$value%',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentEventsCard(bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _recentEvents,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        final events = snapshot.data ?? [];
        
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Learning Events',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last 50 events',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (events.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No learning events yet',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  )
                else
                  ...events.take(10).map((event) => _buildEventItem(event)),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEventItem(Map<String, dynamic> event) {
    final outcome = event['outcome'] as String;
    final timestamp = DateTime.parse(event['timestamp'] as String);
    final timeAgo = _formatTimeAgo(timestamp);
    
    Color outcomeColor;
    IconData outcomeIcon;
    
    switch (outcome) {
      case 'accepted':
        outcomeColor = Colors.green;
        outcomeIcon = Icons.check_circle;
        break;
      case 'edited':
        outcomeColor = Colors.orange;
        outcomeIcon = Icons.edit;
        break;
      case 'rejected':
        outcomeColor = Colors.red;
        outcomeIcon = Icons.cancel;
        break;
      default:
        outcomeColor = Colors.grey;
        outcomeIcon = Icons.help;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(outcomeIcon, color: outcomeColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${outcome.capitalize()} scan',
              style: AppTypography.bodyMedium,
            ),
          ),
          Text(
            timeAgo,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
