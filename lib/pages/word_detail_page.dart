import 'package:flutter/material.dart';

import '../controllers/study_controller.dart';
import '../data/word_analysis.dart';
import '../models/study_models.dart';
import '../services/pronunciation_service.dart';

class WordDetailPage extends StatelessWidget {
  const WordDetailPage({
    super.key,
    required this.word,
    required this.controller,
    required this.pronunciation,
  });

  final VocabWord word;
  final StudyController controller;
  final PronunciationService pronunciation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = controller.progressFor(word.id);
    final roots = analyzeWordRoots(word.word);
    final synonyms = getSynonyms(word.word);
    final antonyms = getAntonyms(word.word);

    return Scaffold(
      appBar: AppBar(
        title: Text(word.word),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () => pronunciation.speak(word.word),
          ),
          IconButton(
            icon: Icon(
              controller.isBookmarked(word.id)
                  ? Icons.bookmark
                  : Icons.bookmark_outline,
            ),
            onPressed: () => controller.toggleBookmark(word.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Word header card
          _SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              word.word,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              word.phonetic,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => pronunciation.speak(word.word),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primaryContainer,
                          ),
                          child: Icon(
                            Icons.volume_up,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    word.meaning,
                    style: theme.textTheme.titleLarge,
                  ),
                  if (word.definition.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      word.definition,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: word.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor: theme.colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Learning progress
          if (progress != null)
            _SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '学习进度',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ProgressItem(
                          label: '复习次数',
                          value: '${progress.totalReviews}',
                          icon: Icons.repeat,
                        ),
                        _ProgressItem(
                          label: '熟练度',
                          value: '${progress.familiarity}',
                          icon: Icons.trending_up,
                        ),
                        _ProgressItem(
                          label: '间隔天数',
                          value: '${progress.intervalDays}',
                          icon: Icons.calendar_today,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (progress != null) const SizedBox(height: 16),

          // Examples
          if (word.examples.isNotEmpty)
            _SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '例句',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...word.examples.map(
                      (example) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                example.en,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  height: 1.5,
                                ),
                              ),
                              if (example.zh.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  example.zh,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (word.examples.isNotEmpty) const SizedBox(height: 16),

          // Word roots and affixes
          if (roots.isNotEmpty)
            _SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_tree,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '词根词缀分析',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...roots.map(
                      (root) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.arrow_right,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                root,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (roots.isNotEmpty) const SizedBox(height: 16),

          // Synonyms
          if (synonyms.isNotEmpty)
            _SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '同义词',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: synonyms
                          .map(
                            (syn) => ActionChip(
                              label: Text('${syn['word']} - ${syn['meaning']}'),
                              backgroundColor: Colors.blue.withValues(alpha: 0.1),
                              onPressed: () {
                                pronunciation.speak(syn['word']!);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          if (synonyms.isNotEmpty) const SizedBox(height: 16),

          // Antonyms
          if (antonyms.isNotEmpty)
            _SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.compare_arrows,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '反义词',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: antonyms
                          .map(
                            (ant) => ActionChip(
                              label: Text('${ant['word']} - ${ant['meaning']}'),
                              backgroundColor: Colors.orange.withValues(alpha: 0.1),
                              onPressed: () {
                                pronunciation.speak(ant['word']!);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}

class _ProgressItem extends StatelessWidget {
  const _ProgressItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
