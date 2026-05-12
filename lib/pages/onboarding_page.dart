import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dictionary_repository.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final Set<String> _selectedBooks = {};
  Map<String, int> _bookWordCounts = {};
  bool _loading = true;

  static final _wordBooks = [
    WordBookInfo(
      id: 'gaokao',
      name: '高考词汇',
      description: '高考英语必备词汇',
      icon: Icons.edit_note,
    ),
    WordBookInfo(
      id: 'cet4',
      name: '四级核心词',
      description: 'CET-4 高频词汇',
      icon: Icons.school,
    ),
    WordBookInfo(
      id: 'cet6',
      name: '六级核心词',
      description: 'CET-6 高频词汇',
      icon: Icons.cast_for_education,
    ),
    WordBookInfo(
      id: 'kaoyan',
      name: '考研词汇',
      description: '考研英语大纲词汇',
      icon: Icons.menu_book,
    ),
    WordBookInfo(
      id: 'ielts',
      name: '雅思词汇',
      description: 'IELTS 核心词汇',
      icon: Icons.flight,
    ),
    WordBookInfo(
      id: 'toefl',
      name: '托福词汇',
      description: 'TOEFL 核心词汇',
      icon: Icons.public,
    ),
    WordBookInfo(
      id: 'common_10000',
      name: '常见10000词',
      description: '高频通用词汇词典',
      icon: Icons.book,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadWordCounts();
  }

  Future<void> _loadWordCounts() async {
    final repo = DictionaryRepository();
    final counts = await repo.getBookWordCounts();
    setState(() {
      _bookWordCounts = counts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                '欢迎使用词旅',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '选择你想学习的词书，可以选多本，之后随时可以更换。',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: _wordBooks.length,
                        itemBuilder: (context, index) {
                          final book = _wordBooks[index];
                          final selected = _selectedBooks.contains(book.id);
                          return _WordBookCard(
                            book: book,
                            selected: selected,
                            wordCount: _bookWordCounts[book.id] ?? 0,
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  _selectedBooks.remove(book.id);
                                } else {
                                  _selectedBooks.add(book.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _selectedBooks.isEmpty
                      ? null
                      : () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setStringList(
                            'word_journey.selected_books',
                            _selectedBooks.toList(),
                          );
                          await prefs.setBool('word_journey.onboarded', true);
                          widget.onComplete();
                        },
                  child: Text(
                    _selectedBooks.isEmpty
                        ? '请选择至少一本词书'
                        : '开始学习 (${_selectedBooks.length}本)',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordBookCard extends StatelessWidget {
  const _WordBookCard({
    required this.book,
    required this.selected,
    required this.onTap,
    required this.wordCount,
  });

  final WordBookInfo book;
  final bool selected;
  final VoidCallback onTap;
  final int wordCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  book.icon,
                  size: 28,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                if (selected)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 24,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              book.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              wordCount > 0 ? '$wordCount词' : '加载中...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WordBookInfo {
  const WordBookInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
}
