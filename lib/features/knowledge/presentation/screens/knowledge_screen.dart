import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/knowledge_providers.dart';
import '../../domain/entities/knowledge_article.dart';
import '../widgets/daily_tip_card.dart';

class KnowledgeScreen extends ConsumerStatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  String _selectedTopic = 'For You';
  final List<String> _topics = ['For You', 'All', 'Budgeting', 'Investing', 'Savings', 'Debt'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // 1. Get current language code for filtering
    final languageCode = Localizations.localeOf(context).languageCode;

    final normalizedTopic = switch (_selectedTopic) {
      'For You' => 'for_you',
      'All' => 'budgeting',
      _ => _selectedTopic.toLowerCase(),
    };

    final suggestedArticlesAsync = ref.watch(suggestedArticlesProvider(
      topic: normalizedTopic,
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.knowledgeTitle),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Daily Tip Section
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: DailyTipCard(),
            ),
          ),

          // 2. Topics Filter
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _topics.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final topic = _topics[index];
                  final isSelected = topic == _selectedTopic;
                  
                  // Localize topic label
                  final localizedLabel = switch (topic) {
                    'For You' => l10n.knowledgeTopicForYou,
                    'All' => l10n.knowledgeTopicAll,
                    'Budgeting' => l10n.knowledgeTopicBudgeting,
                    'Investing' => l10n.knowledgeTopicInvesting,
                    'Savings' => l10n.knowledgeTopicSavings,
                    'Debt' => l10n.knowledgeTopicDebt,
                    _ => topic,
                  };

                  return ChoiceChip(
                    label: Text(localizedLabel),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTopic = topic;
                        });
                      }
                    },
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: suggestedArticlesAsync.when(
              data: (articles) {
                if (articles.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              LucideIcons.library,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.knowledgeNoArticles(_selectedTopic),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverList.separated(
                  itemCount: articles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return _ArticleListTile(article: article);
                  },
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $err')),
              ),
            ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

class _ArticleListTile extends StatelessWidget {
  final KnowledgeArticle article;

  const _ArticleListTile({required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.pushNamed(
            'knowledge-article',
            pathParameters: {'id': article.id},
            extra: article,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  image: article.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(article.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: article.imageUrl == null
                    ? Icon(LucideIcons.bookOpen, color: Theme.of(context).colorScheme.onSurfaceVariant)
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.topic.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.summary,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(LucideIcons.clock, size: 12, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.knowledgeReadTime(article.readTimeMinutes),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
