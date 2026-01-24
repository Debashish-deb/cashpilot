import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/expenses/providers/expense_providers.dart';
import '../../../../features/budgets/providers/budget_providers.dart';

class InsightStory {
  final String id;
  final String title;
  final String icon;
  final Color color;
  final List<StoryPage> pages;

  InsightStory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.pages,
  });
}

class StoryPage {
  final String text;
  final String? subtext;
  final List<double>? chartData;
  final String bigValue;
  final Gradient? backgroundGradient; // Changed to Gradient

  StoryPage({
    required this.text,
    this.subtext,
    this.chartData,
    required this.bigValue,
    this.backgroundGradient,
  });
}

class SpendingStoriesList extends ConsumerWidget {
  const SpendingStoriesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We compute stories reactively from providers
    final expensesAsync = ref.watch(recentExpensesProvider);
    final budgetsAsync = ref.watch(activeBudgetsProvider);
    final monthSpendingAsync = ref.watch(thisMonthSpendingProvider);
    final budgetStats = ref.watch(budgetStatisticsProvider);

    final expenses = expensesAsync.value ?? [];
    final budgets = budgetsAsync.value ?? [];
    final monthSpent = monthSpendingAsync.value ?? 0;

    // Always show something if data exists, or mocked placeholders for "Day 1" vibe
    if (expenses.isEmpty) return const SizedBox.shrink(); 

    final stories = _generateStories(expenses, budgets, monthSpent, budgetStats);

    return SizedBox(
      height: 125, // Increased from 110 to prevent bottom overflow
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final story = stories[index];
          return _StoryBubble(story: story);
        },
      ),
    );
  }

  List<InsightStory> _generateStories(
      List<dynamic> expenses, 
      List<dynamic> budgets, 
      int monthSpent,
      BudgetStatistics stats
  ) {
    // 1. Weekly Recap
    final weeklySpend = expenses.fold(0.0, (sum, e) => sum + (e.amount as int)); 
    
    // 2. Forecast Logic
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyAvg = monthSpent / now.day;
    final projected = dailyAvg * daysInMonth; // Projected total for month
    final totalBudget = stats.totalBudget; // Total limit of all active budgets
    
    String forecastStatus = "Stable";
    String forecastSubtext = "You are spending at a normal pace.";
    Color forecastColor = AppColors.primaryGreen;

    if (totalBudget > 0) {
      if (projected > totalBudget) {
        forecastStatus = "Tight";
        forecastSubtext = "Pacing to exceed budget by €${((projected - totalBudget) / 100).toStringAsFixed(0)}.";
        forecastColor = AppColors.warning;
      } else if (projected < totalBudget * 0.8) {
         forecastStatus = "Great";
         forecastSubtext = "On track to save ~€${((totalBudget - projected) / 100).toStringAsFixed(0)}!";
      }
    }

    return [
      InsightStory(
        id: 'weekly',
        title: 'Recap',
        icon: '📊',
        color: Colors.purple,
        pages: [
          StoryPage(
            text: 'This Week',
            bigValue: '€${(weeklySpend / 100).toStringAsFixed(0)}',
            subtext: 'Total spent recently.',
          ),
        ],
      ),
      InsightStory(
        id: 'forecast',
        title: 'Forecast',
        icon: '🔮',
        color: forecastColor,
        pages: [
          StoryPage(
            text: 'Projection',
            bigValue: forecastStatus,
            subtext: forecastSubtext,
            backgroundGradient: forecastStatus == "Tight" 
                ? AppColors.sunsetOrangeGradient 
                : AppColors.greenGradient,
          ),
           StoryPage(
            text: 'Month End',
            bigValue: '€${(projected / 100).toStringAsFixed(0)}',
            subtext: 'Estimated total if you keep this up.',
          ),
        ],
      ),
       InsightStory(
        id: 'tips',
        title: 'Insights',
        icon: '✨',
        color: AppColors.primaryGold,
        pages: [
          StoryPage(
            text: 'Little Win',
            bigValue: 'Save €5',
            subtext: 'Skipping one treat today keeps you green.',
          ),
        ],
      ),
    ];
  }
}

class _StoryBubble extends StatelessWidget {
  final InsightStory story;
  const _StoryBubble({required this.story});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => StoryViewer(story: story),
        ));
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [story.color, story.color.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.primaryGold, width: 2), // Ring status
              boxShadow: [
                BoxShadow(
                  color: story.color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            alignment: Alignment.center,
            child: Text(story.icon, style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 6),
          Text(
            story.title,
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class StoryViewer extends StatefulWidget {
  final InsightStory story;
  const StoryViewer({super.key, required this.story});

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 5)
    );
    
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextPage();
      }
    });
    
    _animController.forward();
  }

  void _nextPage() {
    if (_currentIndex < widget.story.pages.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _animController.reset();
      _animController.forward();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.story.pages[_currentIndex];

    // Determine background decoration: Gradient OR simple color
    final decoration = page.backgroundGradient != null
        ? BoxDecoration(gradient: page.backgroundGradient)
        : BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.story.color.withValues(alpha: 0.8),
                Colors.black,
              ],
            ),
          );

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
             // Previous
             if (_currentIndex > 0) {
               setState(() => _currentIndex--);
               _pageController.jumpToPage(_currentIndex);
               _animController.reset();
               _animController.forward();
             }
          } else {
             _nextPage();
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            Navigator.of(context).pop(); // Swipe down to close
          }
        },
        child: Stack(
          children: [
            // Background
            Container(decoration: decoration),
            
            // Content
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.story.pages.length,
              itemBuilder: (context, index) {
                final p = widget.story.pages[index];
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p.bigValue,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        p.text,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      if (p.subtext != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          p.subtext!,
                          textAlign: TextAlign.center,
                            style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white54,
                          ),
                        ),
                      ]
                    ],
                  ),
                );
              },
            ),

            // Progress Indicators
            Positioned(
              top: 50,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(widget.story.pages.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: SizedBox(
                          height: 4,
                          child: Stack(
                            children: [
                              Container(color: Colors.white.withValues(alpha: 0.3)),
                              if (index < _currentIndex)
                                Container(color: Colors.white)
                              else if (index == _currentIndex)
                                AnimatedBuilder(
                                  animation: _animController,
                                  builder: (context, child) {
                                    return FractionallySizedBox(
                                      widthFactor: _animController.value,
                                      child: Container(color: Colors.white),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // Close Button
            Positioned(
              top: 60,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
