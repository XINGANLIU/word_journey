import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/study_controller.dart';
import 'models/study_models.dart';
import 'pages/add_words_page.dart';
import 'pages/dictation_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/word_detail_page.dart';
import 'services/pronunciation_service.dart';

class WordJourneyHome extends StatefulWidget {
  const WordJourneyHome({super.key});

  @override
  State<WordJourneyHome> createState() => _WordJourneyHomeState();
}

class _WordJourneyHomeState extends State<WordJourneyHome> {
  final StudyController _controller = StudyController();
  final PronunciationService _pronunciation = PronunciationService();
  late final Future<void> _loadFuture;
  int _currentIndex = 0;

  static const _titles = ['今日复习', '词书总览', '我的收藏', '听写模式', '拼写测试', '学习统计', '学习设置'];

  @override
  void initState() {
    super.initState();
    _loadFuture = _controller.load();
  }

  @override
  void dispose() {
    _pronunciation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在装载你的背词节奏...'),
                ],
              ),
            ),
          );
        }

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('词旅背单词'),
                    Text(
                      _titles[_currentIndex],
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: '从词库添加单词',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddWordsPage(
                            controller: _controller,
                            pronunciation: _pronunciation,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: SafeArea(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    ReviewTab(
                      controller: _controller,
                      currentItem: _controller.currentItem,
                      pronunciation: _pronunciation,
                    ),
                    WordbookTab(
                      controller: _controller,
                      pronunciation: _pronunciation,
                    ),
                    BookmarksTab(
                      controller: _controller,
                      pronunciation: _pronunciation,
                    ),
                    DictationPage(
                      controller: _controller,
                      pronunciation: _pronunciation,
                    ),
                    SpellingTestTab(
                      controller: _controller,
                      pronunciation: _pronunciation,
                    ),
                    StatsTab(controller: _controller),
                    SettingsTab(controller: _controller),
                  ],
                ),
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    _currentIndex = value;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.auto_stories_outlined),
                    selectedIcon: Icon(Icons.auto_stories),
                    label: '复习',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    selectedIcon: Icon(Icons.menu_book),
                    label: '词书',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bookmark_outline),
                    selectedIcon: Icon(Icons.bookmark),
                    label: '收藏',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.hearing_outlined),
                    selectedIcon: Icon(Icons.hearing),
                    label: '听写',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.spellcheck_outlined),
                    selectedIcon: Icon(Icons.spellcheck),
                    label: '拼写',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.query_stats_outlined),
                    selectedIcon: Icon(Icons.query_stats),
                    label: '统计',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.tune_outlined),
                    selectedIcon: Icon(Icons.tune),
                    label: '设置',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ReviewTab extends StatefulWidget {
  const ReviewTab({
    super.key,
    required this.controller,
    required this.currentItem,
    required this.pronunciation,
  });

  final StudyController controller;
  final StudyQueueItem? currentItem;
  final PronunciationService pronunciation;

  @override
  State<ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<ReviewTab> {
  bool _showMeaning = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoPronounce(widget.currentItem);
    });
  }

  @override
  void didUpdateWidget(covariant ReviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentItem?.word.id != widget.currentItem?.word.id) {
      _showMeaning = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeAutoPronounce(widget.currentItem);
      });
    }
  }

  void _toggleMeaning() {
    setState(() {
      _showMeaning = !_showMeaning;
    });
  }

  void _maybeAutoPronounce(StudyQueueItem? item) {
    if (!mounted || item == null || !widget.controller.autoPronounce) {
      return;
    }
    widget.pronunciation.speak(item.word.word);
  }

  Future<void> _submit(RecallRating rating) async {
    final item = widget.currentItem;
    if (item == null || _submitting) {
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _submitting = true;
    });

    await widget.controller.answer(item, rating);

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
    });
  }

  Widget _buildWordCard(ThemeData theme, StudyQueueItem currentItem) {
    final isBookmarked = widget.controller.isBookmarked(currentItem.word.id);
    return _SectionCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatusChip(progress: currentItem.progress),
                _MetricPill(
                  icon: Icons.timer_outlined,
                  label: currentItem.isNew
                      ? '新词引入'
                      : '上次复习 ${_timeAgoLabel(currentItem.progress?.lastReviewedAt)}',
                ),
                if (widget.controller.autoPronounce)
                  const _PlainPill(
                    icon: Icons.volume_up_outlined,
                    label: '自动发音已开启',
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    currentItem.word.word,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _BookmarkButton(
                  isBookmarked: isBookmarked,
                  onTap: () => widget.controller.toggleBookmark(currentItem.word.id),
                ),
                const SizedBox(width: 8),
                _PronunciationButton(
                  pronunciation: widget.pronunciation,
                  word: currentItem.word.word,
                  size: 56,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${currentItem.word.phonetic} · ${currentItem.word.level}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 22),
            _SectionTint(
              child: _ExamplesPanel(examples: currentItem.word.examples),
            ),
            const SizedBox(height: 18),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _showMeaning
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      currentItem.word.meaning,
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: _toggleMeaning,
                                    icon: const Icon(Icons.visibility_off_outlined, size: 18),
                                    label: const Text('收起'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (currentItem.word.definition.isNotEmpty)
                                Text(
                                  currentItem.word.definition,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.55,
                                  ),
                                ),
                              if (currentItem.word.note.isNotEmpty &&
                                  currentItem.word.note != currentItem.word.definition) ...[
                                const SizedBox(height: 8),
                                Text(
                                  currentItem.word.note,
                                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: currentItem.word.tags
                                    .map((tag) => Chip(
                                          label: Text(tag),
                                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: _toggleMeaning,
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('显示释义和提示'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.currentItem;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        _HeroPanel(controller: widget.controller),
        const SizedBox(height: 18),
        if (currentItem == null)
          _SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今天的复习先告一段落',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '你已经完成了今天该出现的单词。接下来可以去词书页搜索和回顾，或者调整每天的新词量。',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetricPill(
                        icon: Icons.bolt,
                        label: '今日完成 ${widget.controller.reviewedToday}',
                      ),
                      _MetricPill(
                        icon: Icons.local_fire_department,
                        label: '连续学习 ${widget.controller.studyStreak} 天',
                      ),
                      _MetricPill(
                        icon: Icons.upcoming,
                        label: '明日待复习 ${widget.controller.tomorrowCount}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          else ...[
            _buildWordCard(theme, currentItem),
          const SizedBox(height: 16),
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (_submitting) return;
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -500) {
                _submit(RecallRating.forgot);
              } else if (velocity > 500) {
                _submit(RecallRating.know);
              }
            },
            child: _SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '这次感觉如何？',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '← 忘记 | 认识 →',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _AnswerButton(
                          title: '不认识',
                          subtitle: '10 分钟后再见',
                          color: const Color(0xFFBC4D39),
                          icon: Icons.refresh,
                          onPressed: _submitting
                              ? null
                              : () => _submit(RecallRating.forgot),
                        ),
                        _AnswerButton(
                          title: '有点模糊',
                          subtitle: '明天继续巩固',
                          color: const Color(0xFFCC8A2D),
                          icon: Icons.hourglass_bottom,
                          onPressed: _submitting
                              ? null
                              : () => _submit(RecallRating.hesitant),
                        ),
                        _AnswerButton(
                          title: '认识',
                          subtitle: '拉长复习间隔',
                          color: const Color(0xFF1F7A65),
                          icon: Icons.check_circle,
                          onPressed: _submitting
                              ? null
                              : () => _submit(RecallRating.know),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

enum _WordbookFilter { all, newWord, learning, mastered, bookmarked }

class WordbookTab extends StatefulWidget {
  const WordbookTab({
    super.key,
    required this.controller,
    required this.pronunciation,
  });

  final StudyController controller;
  final PronunciationService pronunciation;

  @override
  State<WordbookTab> createState() => _WordbookTabState();
}

class _WordbookTabState extends State<WordbookTab> {
  final TextEditingController _searchController = TextEditingController();
  _WordbookFilter _filter = _WordbookFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddWordDialog() {
    final wordController = TextEditingController();
    final meaningController = TextEditingController();
    final phoneticController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('添加新单词'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: wordController,
                  decoration: const InputDecoration(
                    labelText: '英文单词 *',
                    hintText: '例: hello',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入英文单词';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: meaningController,
                  decoration: const InputDecoration(
                    labelText: '中文释义 *',
                    hintText: '例: 你好',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入中文释义';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneticController,
                  decoration: const InputDecoration(
                    labelText: '音标 (可选)',
                    hintText: '例: həˈloʊ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  widget.controller.addWord(
                    word: wordController.text,
                    meaning: meaningController.text,
                    phonetic: phoneticController.text,
                  );
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已添加: ${wordController.text}'),
                    ),
                  );
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items =
        widget.controller.words
            .where(_matchesQuery)
            .where(_matchesFilter)
            .toList()
          ..sort(
            (left, right) => _rankWord(
              widget.controller.progressFor(right.id),
            ).compareTo(_rankWord(widget.controller.progressFor(left.id))),
          );

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricPill(
                      icon: Icons.stars_outlined,
                      label:
                          '已接触 ${widget.controller.seenWordsCount}/${widget.controller.words.length}',
                    ),
                    _MetricPill(
                      icon: Icons.school_outlined,
                      label: '学习中 ${widget.controller.learningCount}',
                    ),
                    _MetricPill(
                      icon: Icons.workspace_premium_outlined,
                      label: '已掌握 ${widget.controller.masteredCount}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                      _query = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: '搜索单词、中文释义、标签',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                    filled: true,
                    fillColor: const Color(0xFFF6F1E9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _WordbookFilter.values
                      .map(
                        (filter) => FilterChip(
                          label: Text(_filterLabel(filter)),
                          selected: _filter == filter,
                          onSelected: (_) {
                            setState(() {
                              _filter = filter;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  '匹配到 ${items.length} 个词',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '词书总览',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '现在可以按英文、中文释义或标签搜索，词量扩起来以后会非常顺手。',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          _SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '没有匹配到结果，可以试试换个关键词或筛选条件。',
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
        ...items.map((word) {
          final progress = widget.controller.progressFor(word.id);
          final isBookmarked = widget.controller.isBookmarked(word.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WordDetailPage(
                      word: word,
                      controller: widget.controller,
                      pronunciation: widget.pronunciation,
                    ),
                  ),
                );
              },
              child: _SectionCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFE7F0EE),
                            child: Text(
                              word.word.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  word.word,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                word.phonetic,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _BookmarkButton(
                          isBookmarked: isBookmarked,
                          onTap: () => widget.controller.toggleBookmark(word.id),
                        ),
                        const SizedBox(width: 8),
                        _PronunciationButton(
                          pronunciation: widget.pronunciation,
                          word: word.word,
                          size: 44,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${word.meaning}\n${_exampleSummary(word)}\n${_progressLine(progress)}',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: word.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              backgroundColor: const Color(0xFFF2ECE3),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    _StatusChip(progress: progress),
                  ],
                ),
              ),
              ),
            ),
          );
        }),
      ],
    ),
      Positioned(
        right: 16,
        bottom: 16,
        child: FloatingActionButton(
          onPressed: _showAddWordDialog,
          child: const Icon(Icons.add),
        ),
      ),
      ],
    );
  }

  bool _matchesFilter(VocabWord word) {
    final progress = widget.controller.progressFor(word.id);
    switch (_filter) {
      case _WordbookFilter.all:
        return true;
      case _WordbookFilter.newWord:
        return progress == null;
      case _WordbookFilter.learning:
        return progress?.isLearning ?? false;
      case _WordbookFilter.mastered:
        return progress?.isMastered ?? false;
      case _WordbookFilter.bookmarked:
        return widget.controller.isBookmarked(word.id);
    }
  }

  bool _matchesQuery(VocabWord word) {
    if (_query.isEmpty) {
      return true;
    }

    final haystack = [
      word.word,
      word.meaning,
      word.definition,
      word.level,
      ...word.tags,
      ...word.examples.map((item) => item.en),
      ...word.examples.map((item) => item.zh),
    ].join(' ').toLowerCase();

    return haystack.contains(_query);
  }
}

class BookmarksTab extends StatelessWidget {
  const BookmarksTab({
    super.key,
    required this.controller,
    required this.pronunciation,
  });

  final StudyController controller;
  final PronunciationService pronunciation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookmarkedWords = controller.words
        .where((w) => controller.isBookmarked(w.id))
        .toList();

    if (bookmarkedWords.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_outline, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              '还没有收藏任何单词',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '在词书页或复习页点击书签图标即可收藏',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '我的收藏 (${bookmarkedWords.length})',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ...bookmarkedWords.map((word) {
          final progress = controller.progressFor(word.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WordDetailPage(
                      word: word,
                      controller: controller,
                      pronunciation: pronunciation,
                    ),
                  ),
                );
              },
              child: _SectionCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFFFF3E0),
                            child: Text(
                              word.word.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: const Color(0xFFCC8A2D),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  word.word,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  word.meaning,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          _BookmarkButton(
                            isBookmarked: true,
                            onTap: () => controller.toggleBookmark(word.id),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(progress: progress),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class StatsTab extends StatelessWidget {
  const StatsTab({super.key, required this.controller});

  final StudyController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recentStats = controller.recentStats;
    final peak = math.max<int>(
      1,
      recentStats.map((item) => item.reviewed).fold(0, math.max),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              title: '今日复习',
              value: '${controller.reviewedToday}',
              caption: '新词 ${controller.newTodayCount}',
              accent: const Color(0xFF1F7A65),
            ),
            _StatCard(
              title: '今日保留率',
              value: '${(controller.retentionRateToday * 100).round()}%',
              caption: '忘记 ${controller.todayStats.forgotten}',
              accent: const Color(0xFFCC6B3D),
            ),
            _StatCard(
              title: '学习连击',
              value: '${controller.studyStreak}',
              caption: '连续天数',
              accent: const Color(0xFF4E7C90),
            ),
            _StatCard(
              title: '掌握单词',
              value: '${controller.masteredCount}',
              caption: '总接触 ${controller.seenWordsCount}',
              accent: const Color(0xFF7B694D),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最近 7 天节奏',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: recentStats
                        .map(
                          (item) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: _DayBar(
                                label: _compactDate(item.dayKey),
                                value: item.reviewed,
                                maxValue: peak,
                                caption:
                                    '${(item.retentionRate * 100).round()}%',
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '接下来',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _InsightRow(
                  icon: Icons.today_outlined,
                  title: '当前待复习',
                  value: '${controller.dueCount}',
                ),
                _InsightRow(
                  icon: Icons.sunny_snowing,
                  title: '明日待复习',
                  value: '${controller.tomorrowCount}',
                ),
                _InsightRow(
                  icon: Icons.calendar_month_outlined,
                  title: '未来排队',
                  value: '${controller.futureReviewCount}',
                ),
                _InsightRow(
                  icon: Icons.fiber_new_outlined,
                  title: '未引入新词',
                  value: '${controller.backlogCount}',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SpellingTestTab extends StatefulWidget {
  const SpellingTestTab({
    super.key,
    required this.controller,
    required this.pronunciation,
  });

  final StudyController controller;
  final PronunciationService pronunciation;

  @override
  State<SpellingTestTab> createState() => _SpellingTestTabState();
}

class _SpellingTestTabState extends State<SpellingTestTab> {
  final TextEditingController _inputController = TextEditingController();
  VocabWord? _currentWord;
  bool _showResult = false;
  bool _isCorrect = false;
  int _correctCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _nextWord();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _nextWord() {
    final words = widget.controller.words;
    if (words.isEmpty) return;

    final random = math.Random();
    setState(() {
      _currentWord = words[random.nextInt(words.length)];
      _showResult = false;
      _isCorrect = false;
      _inputController.clear();
    });

    if (widget.controller.autoPronounce) {
      widget.pronunciation.speak(_currentWord!.word);
    }
  }

  void _checkSpelling() {
    if (_currentWord == null) return;

    final input = _inputController.text.trim().toLowerCase();
    final correct = _currentWord!.word.toLowerCase();

    setState(() {
      _showResult = true;
      _isCorrect = input == correct;
      _totalCount++;
      if (_isCorrect) _correctCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_currentWord == null) {
      return const Center(child: Text('词库为空'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        _SectionCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '拼写测试',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '根据中文释义和发音，拼写出正确的英文单词。',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricPill(
                      icon: Icons.check_circle_outline,
                      label: '正确 $_correctCount',
                    ),
                    _MetricPill(
                      icon: Icons.format_list_numbered,
                      label: '共 $_totalCount',
                    ),
                    if (_totalCount > 0)
                      _MetricPill(
                        icon: Icons.percent,
                        label: '${(_correctCount / _totalCount * 100).round()}%',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentWord!.meaning,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentWord!.phonetic,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _PronunciationButton(
                      pronunciation: widget.pronunciation,
                      word: _currentWord!.word,
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '点击喇叭听发音',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    hintText: '输入英文单词',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _inputController.clear(),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _checkSpelling(),
                ),
                const SizedBox(height: 16),
                if (_showResult) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isCorrect
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isCorrect ? Colors.green : Colors.red,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isCorrect ? '正确!' : '错误',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _isCorrect ? Colors.green : Colors.red,
                          ),
                        ),
                        if (!_isCorrect) ...[
                          const SizedBox(height: 8),
                          Text(
                            '正确答案: ${_currentWord!.word}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _showResult ? _nextWord : _checkSpelling,
                        icon: Icon(_showResult ? Icons.arrow_forward : Icons.check),
                        label: Text(_showResult ? '下一个' : '检查'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_currentWord!.examples.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _ExamplesPanel(examples: _currentWord!.examples),
            ),
          ),
        ],
      ],
    );
  }
}

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key, required this.controller});

  final StudyController controller;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String? _customDictPath;

  @override
  void initState() {
    super.initState();
    _loadCustomDictPath();
  }

  Future<void> _loadCustomDictPath() async {
    final path = await widget.controller.getCustomDictPath();
    setState(() {
      _customDictPath = path;
    });
  }

  Future<void> _changeBooks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('更换词书'),
        content: const Text('更换词书会回到词书选择页面，不会丢失学习记录。是否继续？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认')),
        ],
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('word_journey.onboarded', false);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B6B62))),
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('正在返回词书选择...'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => OnboardingPage(
                              onComplete: () {},
                            )),
                            (route) => false,
                          );
                        },
                        child: const Text('点击重新选择'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          (route) => false,
        );
      }
    }
  }

  Future<void> _exportData() async {
    final json = await widget.controller.exportData();
    // Save to file
    final directory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择备份保存位置',
    );
    if (directory == null) return;
    final file = File('$directory/word_journey_backup.json');
    await file.writeAsString(json);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('备份已保存到 $directory')),
      );
    }
  }

  Future<void> _importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      dialogTitle: '选择备份文件',
    );
    if (result == null || result.files.isEmpty) return;
    final file = File(result.files.first.path!);
    final json = await file.readAsString();
    await widget.controller.importData(json);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份恢复成功！请重启应用。')),
      );
    }
  }

  Future<void> _importDictionary() async {
    try {
      final path = await widget.controller.pickAndImportDictionary();
      if (path != null) {
        setState(() => _customDictPath = path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('词库导入成功！重启应用后生效。')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<void> _resetToDefault() async {
    await widget.controller.resetToDefaultDictionary();
    setState(() => _customDictPath = null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已恢复默认词库，重启应用后生效。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        _SectionCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '每日新词上限',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '控制每天第一次出现的新词数量，避免一开始冲太猛导致第二天复习雪崩。',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                Text(
                  '${widget.controller.dailyNewLimit} 个',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Slider(
                  value: widget.controller.dailyNewLimit.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 25,
                  label: '${widget.controller.dailyNewLimit}',
                  onChanged: (value) {
                    widget.controller.setDailyNewLimit(value.round());
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          child: SwitchListTile(
            value: widget.controller.autoPronounce,
            onChanged: widget.controller.setAutoPronounce,
            secondary: const Icon(Icons.volume_up_outlined),
            title: const Text('自动播放发音'),
            subtitle: const Text('每次切到新的复习单词时，自动播放英文读音。'),
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('更换词书'),
                subtitle: const Text('重新选择要学习的词库（四级、考研等）'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changeBooks,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('导出备份'),
                subtitle: const Text('备份学习记录到本地文件'),
                onTap: _exportData,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('恢复备份'),
                subtitle: const Text('从备份文件恢复学习记录'),
                onTap: _importData,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.book_outlined),
                    const SizedBox(width: 12),
                    Text(
                      '自定义词库',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_customDictPath != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '当前使用自定义词库',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _customDictPath!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _importDictionary,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('更换词库'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetToDefault,
                          icon: const Icon(Icons.restore),
                          label: const Text('恢复默认'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    '导入自定义词库（JSON格式），词库需包含 "words" 字段。',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _importDictionary,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('导入词库'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          child: Column(
            children: const [
              ListTile(
                leading: Icon(Icons.search_outlined),
                title: Text('词书搜索已加入'),
                subtitle: Text('现在可以按英文、中文释义、标签和例句内容快速查词。'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.record_voice_over_outlined),
                title: Text('发音功能可调节'),
                subtitle: Text('手动点击喇叭依旧可用，自动发音可以在这里按习惯开关。'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.storage_outlined),
                title: Text('当前数据存储'),
                subtitle: Text('学习记录和设置都保存在本地 SharedPreferences 中。'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.tonalIcon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text('重置学习记录？'),
                  content: const Text('会清空当前设备上的复习进度和统计数据，但不会删除词库。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('确认重置'),
                    ),
                  ],
                );
              },
            );

            if (confirmed == true) {
              await widget.controller.resetAllProgress();
            }
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text('清空本地学习记录'),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.controller});

  final StudyController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dailyProgress = controller.dailyNewLimit > 0
        ? (controller.newTodayCount / controller.dailyNewLimit).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF184F4A), Color(0xFF2B776A), Color(0xFF6E9E96)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '先把今天该出现的词，稳稳记住。',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: dailyProgress,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 4,
                    ),
                    Text(
                      '${(dailyProgress * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '今日新词进度 ${controller.newTodayCount}/${controller.dailyNewLimit}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(
                icon: Icons.schedule,
                label: '待复习 ${controller.dueCount}',
                dark: true,
              ),
              _MetricPill(
                icon: Icons.fiber_new,
                label: '新词余量 ${controller.remainingNewToday}',
                dark: true,
              ),
              _MetricPill(
                icon: Icons.local_fire_department,
                label: '连击 ${controller.studyStreak} 天',
                dark: true,
              ),
            ],
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
    return Card(child: child);
  }
}

class _SectionTint extends StatelessWidget {
  const _SectionTint({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0E8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    this.dark = false,
  });

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final foreground = dark
        ? Colors.white
        : Theme.of(context).colorScheme.primary;
    final background = dark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE8F1EF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PlainPill extends StatelessWidget {
  const _PlainPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECE3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.progress});

  final WordProgress? progress;

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel(progress);
    final color = _statusColor(progress);
    return Chip(
      label: Text(status),
      avatar: Icon(_statusIcon(progress), size: 18, color: color),
      side: BorderSide.none,
      backgroundColor: color.withValues(alpha: 0.14),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
    );
  }
}

class _ExamplesPanel extends StatelessWidget {
  const _ExamplesPanel({required this.examples});

  final List<WordExample> examples;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (examples.isEmpty) {
      return Text(
        '这个词暂时还没有配套例句。',
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '学习例句',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...examples.map(
          (example) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    example.en,
                    style: theme.textTheme.titleMedium?.copyWith(height: 1.5),
                  ),
                  if (example.zh.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      example.zh,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '来源：${example.source}',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PronunciationButton extends StatelessWidget {
  const _PronunciationButton({
    required this.pronunciation,
    required this.word,
    required this.size,
  });

  final PronunciationService pronunciation;
  final String word;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pronunciation,
      builder: (context, child) {
        final speaking = pronunciation.isSpeaking(word);
        return Tooltip(
          message: speaking ? '停止发音' : '播放发音',
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => pronunciation.speakOrStop(word),
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: speaking
                    ? const Color(0xFF155C55)
                    : const Color(0xFFE5EFEC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                color: speaking ? Colors.white : const Color(0xFF155C55),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  const _BookmarkButton({
    required this.isBookmarked,
    required this.onTap,
  });

  final bool isBookmarked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isBookmarked ? '取消收藏' : '收藏',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isBookmarked
                ? const Color(0xFFFFF3E0)
                : const Color(0xFFE5EFEC),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
            color: isBookmarked
                ? const Color(0xFFCC8A2D)
                : const Color(0xFF155C55),
          ),
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        onPressed: onPressed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.accent,
  });

  final String title;
  final String value;
  final String caption;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 170),
      child: _SectionCard(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(caption, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.caption,
  });

  final String label;
  final int value;
  final int maxValue;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final heightFactor = value == 0
        ? 0.08
        : (value / maxValue).clamp(0.08, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$value', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: heightFactor,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F7A65), Color(0xFFCC8A2D)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(caption, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

String _filterLabel(_WordbookFilter filter) {
  switch (filter) {
    case _WordbookFilter.all:
      return '全部';
    case _WordbookFilter.newWord:
      return '新词';
    case _WordbookFilter.learning:
      return '复习中';
    case _WordbookFilter.mastered:
      return '已掌握';
    case _WordbookFilter.bookmarked:
      return '已收藏';
  }
}

String _statusLabel(WordProgress? progress) {
  if (progress == null) {
    return '新词';
  }
  if (progress.isMastered) {
    return '已掌握';
  }
  return '复习中';
}

Color _statusColor(WordProgress? progress) {
  if (progress == null) {
    return const Color(0xFFCC8A2D);
  }
  if (progress.isMastered) {
    return const Color(0xFF1F7A65);
  }
  return const Color(0xFF4E7C90);
}

IconData _statusIcon(WordProgress? progress) {
  if (progress == null) {
    return Icons.fiber_new;
  }
  if (progress.isMastered) {
    return Icons.workspace_premium;
  }
  return Icons.refresh;
}

int _rankWord(WordProgress? progress) {
  if (progress == null) {
    return 0;
  }
  if (progress.isMastered) {
    return 3;
  }
  return 2;
}

String _progressLine(WordProgress? progress) {
  if (progress == null) {
    return '尚未开始，等待今日新词配额引入。';
  }
  final nextReview = _nextReviewLabel(progress.nextReviewAt);
  return '已复习 ${progress.totalReviews} 次，下一次 $nextReview。';
}

String _exampleSummary(VocabWord word) {
  if (word.examples.isEmpty) {
    return '暂无例句';
  }
  return '例句 ${word.examples.length} 条';
}

String _timeAgoLabel(DateTime? value) {
  if (value == null) {
    return '刚刚加入计划';
  }
  final delta = DateTime.now().difference(value);
  if (delta.inDays >= 1) {
    return '${delta.inDays} 天前';
  }
  if (delta.inHours >= 1) {
    return '${delta.inHours} 小时前';
  }
  if (delta.inMinutes >= 1) {
    return '${delta.inMinutes} 分钟前';
  }
  return '刚刚';
}

String _nextReviewLabel(DateTime value) {
  final now = DateTime.now();
  final today = startOfDay(now);
  final target = startOfDay(value);
  final delta = target.difference(today).inDays;
  if (delta <= 0) {
    return '今天';
  }
  if (delta == 1) {
    return '明天';
  }
  return '$delta 天后';
}

String _compactDate(String dayKey) {
  final parsed = DateTime.parse(dayKey);
  return '${parsed.month}/${parsed.day}';
}
