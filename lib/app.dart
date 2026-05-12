import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static const _titles = ['学习', '选词', '统计', '我的'];

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

  void _openDictionary(String word) async {
    final uri = Uri.parse('https://dictionary.cambridge.org/zhs/%E8%AF%8D%E5%85%B8/%E8%8B%B1%E8%AF%AD-%E6%B1%89%E8%AF%AD-%E7%AE%80%E4%BD%93/${Uri.encodeComponent(word)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(), SizedBox(height: 16), Text('正在加载词库...'),
              ]),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('加载失败', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('${snapshot.error}', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(onPressed: () { setState(() { _loadFuture = _controller.load(); }); }, icon: const Icon(Icons.refresh), label: const Text('重试')),
              ])),
            ),
          );
        }

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Scaffold(
              appBar: AppBar(
                title: Text('词旅背单词 · ${_titles[_currentIndex]}'),
                centerTitle: false,
                actions: _currentIndex == 0
                    ? [
                        IconButton(
                          icon: const Icon(Icons.language),
                          tooltip: '剑桥词典查词',
                          onPressed: () {
                            if (_controller.currentItem != null) {
                              _openDictionary(_controller.currentItem!.word.word);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: '添加单词',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddWordsPage(
                                  controller: _controller,
                                  pronunciation: _pronunciation,
                                ),
                              ),
                            );
                          },
                        ),
                      ]
                    : null,
              ),
              body: SafeArea(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    StudyTab(
                      controller: _controller,
                      pronunciation: _pronunciation,
                      openDictionary: _openDictionary,
                    ),
                    _WordSelectTab(
                      controller: _controller,
                      pronunciation: _pronunciation,
                    ),
                    StatsTab(controller: _controller),
                    _MeTab(
                      controller: _controller,
                      pronunciation: _pronunciation,
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (v) => setState(() => _currentIndex = v),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: '学习'),
                  NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: '选词'),
                  NavigationDestination(icon: Icon(Icons.query_stats_outlined), selectedIcon: Icon(Icons.query_stats), label: '统计'),
                  NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// 学习页
// ============================================================
class StudyTab extends StatefulWidget {
  const StudyTab({required this.controller, required this.pronunciation, required this.openDictionary, super.key});
  final StudyController controller;
  final PronunciationService pronunciation;
  final void Function(String word) openDictionary;

  @override
  State<StudyTab> createState() => _StudyTabState();
}

class _StudyTabState extends State<StudyTab> {
  bool _showMeaning = false;
  bool _submitting = false;
  String _statusText = '请回忆发音和释义';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoPronounce();
    });
  }

  @override
  void didUpdateWidget(covariant StudyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.currentItem?.word.id != widget.controller.currentItem?.word.id) {
      setState(() {
        _showMeaning = false;
        _statusText = '请回忆发音和释义';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeAutoPronounce();
      });
    }
  }

  void _maybeAutoPronounce() {
    final item = widget.controller.currentItem;
    if (!mounted || item == null || !widget.controller.autoPronounce) return;
    widget.pronunciation.speak(item.word.word);
  }

  Future<void> _submit(RecallRating rating) async {
    final item = widget.controller.currentItem;
    if (item == null || _submitting) return;
    HapticFeedback.lightImpact();
    setState(() => _submitting = true);
    await widget.controller.answer(item, rating);
    if (!mounted) return;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.controller.currentItem;
    final theme = Theme.of(context);

    if (item == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _HeroCard(controller: widget.controller),
          const SizedBox(height: 24),
          _Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('今天的复习已完成', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('可以去选词页添加新单词，或在统计页查看进度', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AddWordsPage(controller: widget.controller, pronunciation: widget.pronunciation),
                      ));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('去添加单词'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        _HeroCard(controller: widget.controller),
        const SizedBox(height: 24),
        // Word card
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Word
                  Text(
                    item.word.word,
                    style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 40),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                // Phonetic + speaker
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.word.phonetic,
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => widget.pronunciation.speak(item.word.word),
                      child: Icon(Icons.volume_up, color: theme.colorScheme.primary, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Divider
                const Divider(),
                const SizedBox(height: 16),
                // Status text or meaning area
                GestureDetector(
                  onTap: () => setState(() {
                    _showMeaning = !_showMeaning;
                    if (_showMeaning) _statusText = item.word.meaning;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _showMeaning
                          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        if (_showMeaning) ...[
                          Text(
                            item.word.meaning,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                          if (item.word.definition.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              item.word.definition,
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                          // Examples
                          if (item.word.examples.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            ...item.word.examples.take(2).map((ex) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '"${ex.en}"',
                                style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            )),
                          ],
                          // Tags
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: item.word.tags.map((t) => Chip(label: Text(t), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)).toList(),
                          ),
                          const SizedBox(height: 12),
                          // Dictionary lookup
                          TextButton.icon(
                            onPressed: () => widget.openDictionary(item.word.word),
                            icon: const Icon(Icons.language, size: 16),
                            label: const Text('剑桥词典'),
                          ),
                        ] else
                          Text(
                            _statusText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
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
        const SizedBox(height: 20),
        // Answer buttons
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _AnswerBtn(
                    label: '不认识',
                    sub: '稍后再来',
                    color: const Color(0xFFBC4D39),
                    icon: Icons.refresh,
                    onTap: _submitting ? null : () => _submit(RecallRating.forgot),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AnswerBtn(
                    label: '有点模糊',
                    sub: '明天再巩固',
                    color: const Color(0xFFCC8A2D),
                    icon: Icons.hourglass_bottom,
                    onTap: _submitting ? null : () => _submit(RecallRating.hesitant),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AnswerBtn(
                    label: '认识',
                    sub: '过几天再复习',
                    color: const Color(0xFF1F7A65),
                    icon: Icons.check_circle,
                    onTap: _submitting ? null : () => _submit(RecallRating.know),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 选词页
// ============================================================
class _WordSelectTab extends StatefulWidget {
  const _WordSelectTab({required this.controller, required this.pronunciation});
  final StudyController controller;
  final PronunciationService pronunciation;

  @override
  State<_WordSelectTab> createState() => _WordSelectTabState();
}

class _WordSelectTabState extends State<_WordSelectTab> {
  final _searchCtl = TextEditingController();
  String _query = '';
  final Set<String> _selected = {};
  int _filterMode = 0; // 0=全部 1=未选 2=已选

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    setState(() => _query = v.trim().toLowerCase());
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) { _selected.remove(id); } else { _selected.add(id); }
    });
  }

  void _addSelected() {
    final toAdd = _selected.where((id) => !widget.controller.studyWordIds.contains(id)).toList();
    if (toAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('所选单词已全部添加')));
      return;
    }
    widget.controller.addWordsToStudy(toAdd);
    setState(() => _selected.clear());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已添加 ${toAdd.length} 个单词')));
  }

  void _addAllVisible() {
    final all = widget.controller.words;
    final toAdd = all.where((w) => !widget.controller.studyWordIds.contains(w.id)).map((w) => w.id).toList();
    if (toAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('全部单词已添加')));
      return;
    }
    widget.controller.addWordsToStudy(toAdd);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已添加全部 ${toAdd.length} 个单词')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allWords = widget.controller.words;
    final studyIds = widget.controller.studyWordIds;

    final filtered = allWords.where((w) {
      final added = studyIds.contains(w.id);
      if (_filterMode == 1 && added) return false; // 未选：排除已添加
      if (_filterMode == 2 && !added) return false; // 已选：只要已添加
      if (_query.isEmpty) return true;
      final h = '${w.word} ${w.meaning} ${w.phonetic} ${w.level}'.toLowerCase();
      return h.contains(_query);
    }).toList()..sort((a, b) {
      final aIn = studyIds.contains(a.id) ? 1 : 0;
      final bIn = studyIds.contains(b.id) ? 1 : 0;
      return aIn.compareTo(bIn);
    });

    final notAdded = filtered.where((w) => !studyIds.contains(w.id)).toList();

    return Stack(
      children: [
        Column(
          children: [
            // Filter tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  _FilterTab(label: '未选', count: allWords.where((w) => !studyIds.contains(w.id)).length, active: _filterMode == 1, onTap: () => setState(() => _filterMode = _filterMode == 1 ? 0 : 1)),
                  const SizedBox(width: 8),
                  _FilterTab(label: '已选', count: studyIds.length, active: _filterMode == 2, onTap: () => setState(() => _filterMode = _filterMode == 2 ? 0 : 2)),
                  const SizedBox(width: 8),
                  _FilterTab(label: '全部', count: allWords.length, active: _filterMode == 0, onTap: () => setState(() => _filterMode = 0)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtl,
                      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: '搜索英文或中文...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtl.clear(); setState(() => _query = ''); })
                            : null,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  if (_query.isEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _addAllVisible,
                      icon: const Icon(Icons.add_circle, size: 18),
                      label: Text('全部(${notAdded.length})', style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text('共 ${allWords.length} 词', style: theme.textTheme.bodySmall),
                  const Spacer(),
                  Text('待背 ${studyIds.length} 词', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                  if (_selected.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text('已选 ${_selected.length}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(12, 0, 12, _selected.isNotEmpty ? 80 : 16),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final w = filtered[i];
                  final added = studyIds.contains(w.id);
                  final sel = _selected.contains(w.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _Card(
                      child: InkWell(
                        onTap: () => _toggleSelect(w.id),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              // Checkbox circle
                              if (added)
                                const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.check_circle, color: Color(0xFF1F7A65), size: 28),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: sel ? theme.colorScheme.primary : Colors.transparent,
                                      border: Border.all(
                                        color: sel ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: sel ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                                  ),
                                ),
                              const SizedBox(width: 4),
                              // Word info
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => WordDetailPage(word: w, controller: widget.controller, pronunciation: widget.pronunciation),
                                    ));
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(w.word, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                      Text('${w.phonetic}  ${w.meaning}',
                                        style: theme.textTheme.bodySmall,
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ),
                              // Speaker
                              IconButton(
                                icon: const Icon(Icons.volume_up, size: 20),
                                onPressed: () => widget.pronunciation.speak(w.word),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        // Bottom bar for batch add
        if (_selected.isNotEmpty)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _selected.clear()),
                    child: const Text('取消'),
                  ),
                  const Spacer(),
                  Text('已选 ${_selected.length} 个', style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _addSelected,
                    icon: const Icon(Icons.add),
                    label: const Text('添加'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// 统计页 (保持原有)
// ============================================================
class StatsTab extends StatelessWidget {
  const StatsTab({super.key, required this.controller});
  final StudyController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recentStats = controller.recentStats;
    final peak = math.max<int>(1, recentStats.map((i) => i.reviewed).fold(0, math.max));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Wrap(spacing: 12, runSpacing: 12, children: [
          _StatCard(title: '今日复习', value: '${controller.reviewedToday}', caption: '新词 ${controller.newTodayCount}', accent: const Color(0xFF1F7A65)),
          _StatCard(title: '保留率', value: '${(controller.retentionRateToday * 100).round()}%', caption: '忘记 ${controller.todayStats.forgotten}', accent: const Color(0xFFCC6B3D)),
          _StatCard(title: '连击', value: '${controller.studyStreak} 天', caption: '连续学习天数', accent: const Color(0xFF4E7C90)),
          _StatCard(title: '已掌握', value: '${controller.masteredCount}', caption: '总接触 ${controller.seenWordsCount}', accent: const Color(0xFF7B694D)),
        ]),
        const SizedBox(height: 18),
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('最近 7 天', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: recentStats.map((i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Text('${i.reviewed}', style: theme.textTheme.labelLarge),
                          const SizedBox(height: 6),
                          Expanded(child: Align(alignment: Alignment.bottomCenter, child: FractionallySizedBox(
                            heightFactor: i.reviewed == 0 ? 0.08 : math.max(0.08, i.reviewed / peak),
                            child: Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF1F7A65), Color(0xFFCC8A2D)], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
                            ),
                          ))),
                          const SizedBox(height: 6),
                          Text('${DateTime.parse(i.dayKey).month}/${DateTime.parse(i.dayKey).day}', style: theme.textTheme.labelSmall),
                          Text('${(i.retentionRate * 100).round()}%', style: theme.textTheme.labelSmall),
                        ]),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('接下来', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _InsightRow(icon: Icons.today_outlined, title: '当前待复习', value: '${controller.dueCount}'),
          _InsightRow(icon: Icons.sunny_snowing, title: '明日待复习', value: '${controller.tomorrowCount}'),
          _InsightRow(icon: Icons.calendar_month_outlined, title: '未来排队', value: '${controller.futureReviewCount}'),
          _InsightRow(icon: Icons.fiber_new_outlined, title: '未引入新词', value: '${controller.backlogCount}'),
        ]))),
      ],
    );
  }
}

// ============================================================
// 我的页
// ============================================================
class _MeTab extends StatefulWidget {
  const _MeTab({required this.controller, required this.pronunciation});
  final StudyController controller;
  final PronunciationService pronunciation;

  @override
  State<_MeTab> createState() => _MeTabState();
}

class _MeTabState extends State<_MeTab> {
  final _limitCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _limitCtl.text = '${widget.controller.dailyNewLimit}';
  }

  @override
  void dispose() {
    _limitCtl.dispose();
    super.dispose();
  }

  Future<void> _changeBooks() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('更换词书'), content: const Text('不会丢失学习记录，继续？'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认'))],
    ));
    if (ok == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('word_journey.onboarded', false);
      if (mounted) {
        // Restart to show onboarding
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => OnboardingPage(
            onComplete: () {
              // Re-trigger app root rebuild
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WordJourneyHome()),
                (route) => false,
              );
            },
          )),
          (route) => false,
        );
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: '选择保存位置');
      if (dir == null) return;
      final json = await widget.controller.exportData();
      await File('$dir/word_journey_backup.json').writeAsString(json);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已保存到 $dir')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e')));
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, dialogTitle: '选择备份文件');
      if (result == null || result.files.isEmpty) return;
      final p = result.files.first.path;
      if (p == null) return;
      final json = await File(p).readAsString();
      await widget.controller.importData(json);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('恢复成功，请重启')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('恢复失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookmarkedCount = widget.controller.words.where((w) => widget.controller.isBookmarked(w.id)).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        // Section: 学习
        _SectionTitle(title: '学习功能'),
        const SizedBox(height: 8),
        _Card(
          child: Column(
            children: [
              _MeItem(icon: Icons.bookmark, title: '我的收藏', subtitle: '$bookmarkedCount 个单词', onTap: () {
                showModalBottomSheet(context: context, builder: (_) => _BookmarkSheet(controller: widget.controller, pronunciation: widget.pronunciation));
              }),
              const _Divider(),
              _MeItem(icon: Icons.hearing, title: '听写模式', subtitle: '听发音拼写单词', onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => DictationPage(controller: widget.controller, pronunciation: widget.pronunciation)));
              }),
              const _Divider(),
              _MeItem(icon: Icons.spellcheck, title: '拼写测试', subtitle: '看中文拼写单词', onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => _SpellingPage(controller: widget.controller, pronunciation: widget.pronunciation)));
              }),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Section: 设置
        _SectionTitle(title: '学习设置'),
        const SizedBox(height: 8),
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('每日新词上限', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _limitCtl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          isDense: true,
                        ),
                        onEditingComplete: () {
                          final n = int.tryParse(_limitCtl.text)?.clamp(1, 999);
                          if (n != null) {
                            widget.controller.setDailyNewLimit(n);
                            _limitCtl.text = '$n';
                          } else {
                            _limitCtl.text = '${widget.controller.dailyNewLimit}';
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入1-999的数字')));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('个/天 (1-999)', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: const Text('自动发音'),
            subtitle: const Text('切换单词时自动播放读音'),
            value: widget.controller.autoPronounce,
            onChanged: widget.controller.setAutoPronounce,
          ),
        ),
        const SizedBox(height: 18),
        // Section: 数据管理
        _SectionTitle(title: '数据管理'),
        const SizedBox(height: 8),
        _Card(
          child: Column(
            children: [
              _MeItem(icon: Icons.swap_horiz, title: '更换词书', subtitle: '重新选择要学习的词库', onTap: _changeBooks),
              const _Divider(),
              _MeItem(icon: Icons.upload_file, title: '导出备份', subtitle: '保存学习记录到文件', onTap: _exportData),
              const _Divider(),
              _MeItem(icon: Icons.download, title: '恢复备份', subtitle: '从备份文件恢复记录', onTap: _importData),
              const _Divider(),
              _MeItem(icon: Icons.restart_alt, title: '重置学习记录', subtitle: '清空进度和统计数据', onTap: () async {
                final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('确认重置？'), content: const Text('将清空所有学习记录'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认'))],
                ));
                if (ok == true) await widget.controller.resetAllProgress();
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Shared widgets
// ============================================================
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: child);
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.controller});
  final StudyController controller;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF184F4A), Color(0xFF2B776A), Color(0xFF6E9E96)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Wrap(spacing: 12, runSpacing: 12, children: [
        _Pill(icon: Icons.schedule, label: '待复习 ${controller.dueCount}', dark: true),
        _Pill(icon: Icons.fiber_new, label: '新词余量 ${controller.remainingNewToday}', dark: true),
        _Pill(icon: Icons.local_fire_department, label: '连击 ${controller.studyStreak} 天', dark: true),
        _Pill(icon: Icons.checklist, label: '已学 ${controller.seenWordsCount}/${controller.totalWordsInBooks}', dark: true),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, this.dark = false});
  final IconData icon;
  final String label;
  final bool dark;
  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : Theme.of(context).colorScheme.primary;
    final bg = dark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE8F1EF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: fg), const SizedBox(width: 6), Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13))]),
    );
  }
}

class _AnswerBtn extends StatelessWidget {
  const _AnswerBtn({required this.label, required this.sub, required this.color, required this.icon, this.onTap});
  final String label, sub;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      onPressed: onTap,
      child: Column(children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(sub, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700));
}

class _MeItem extends StatelessWidget {
  const _MeItem({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall), trailing: const Icon(Icons.chevron_right), onTap: onTap);
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 16, endIndent: 16);
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title, value;
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon), title: Text(title), trailing: Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)));
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.caption, required this.accent});
  final String title, value, caption;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(constraints: const BoxConstraints(minWidth: 160), child: _Card(child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(6))),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(caption, style: Theme.of(context).textTheme.bodySmall),
      ]),
    )));
  }
}

// ============================================================
// Bookmark bottom sheet
// ============================================================
class _BookmarkSheet extends StatelessWidget {
  const _BookmarkSheet({required this.controller, required this.pronunciation});
  final StudyController controller;
  final PronunciationService pronunciation;
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
    final theme = Theme.of(context);
    final words = controller.words.where((w) => controller.isBookmarked(w.id)).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scrollCtl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('我的收藏 (${words.length})', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: words.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bookmark_outline, size: 48, color: theme.colorScheme.onSurfaceVariant), const SizedBox(height: 8), Text('暂无收藏', style: theme.textTheme.bodyLarge)]))
                : ListView.builder(
                    controller: scrollCtl,
                    itemCount: words.length,
                    itemBuilder: (_, i) {
                      final w = words[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text(w.word.isNotEmpty ? w.word[0].toUpperCase() : '?')),
                        title: Text(w.word, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(w.meaning, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(icon: Icon(Icons.bookmark, color: theme.colorScheme.primary), onPressed: () => controller.toggleBookmark(w.id)),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => WordDetailPage(word: w, controller: controller, pronunciation: pronunciation)));
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
      },
    );
  }
}

// ============================================================
// Spelling test page (moved from tab to "我的")
// ============================================================
class _SpellingPage extends StatefulWidget {
  const _SpellingPage({required this.controller, required this.pronunciation});
  final StudyController controller;
  final PronunciationService pronunciation;
  @override
  State<_SpellingPage> createState() => _SpellingPageState();
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({required this.label, required this.count, required this.active, required this.onTap});
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: active ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface)),
              Text(label, style: TextStyle(fontSize: 12, color: active ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpellingPageState extends State<_SpellingPage> {
  final _inputCtl = TextEditingController();
  late List<VocabWord> _pool;
  VocabWord? _word;
  bool _shown = false, _correct = false;
  int _ok = 0, _total = 0;

  @override
  void initState() {
    super.initState();
    _pool = List.from(widget.controller.studyWords)..shuffle();
    _next();
  }

  @override
  void dispose() {
    _inputCtl.dispose();
    super.dispose();
  }

  void _next() {
    if (_pool.isEmpty) {
      _pool = List.from(widget.controller.studyWords.isEmpty ? widget.controller.words : widget.controller.studyWords)..shuffle();
    }
    if (_pool.isEmpty) return;
    setState(() {
      _word = _pool.removeLast();
      _shown = false;
      _inputCtl.clear();
    });
  }

  void _check() {
    if (_word == null) return;
    final ok = _inputCtl.text.trim().toLowerCase() == _word!.word.toLowerCase();
    setState(() { _shown = true; _correct = ok; _total++; if (ok) _ok++; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.controller.studyWords.isEmpty && widget.controller.words.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('拼写测试')), body: const Center(child: Text('没有可拼写的单词，请先去选词页添加')));
    }
    if (_word == null) return Scaffold(appBar: AppBar(title: const Text('拼写测试')), body: const Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('拼写测试'), actions: [Text('$_ok/$_total'), const SizedBox(width: 16)]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          Text(_word!.meaning, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(_word!.phonetic, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 12),
          IconButton.filled(icon: const Icon(Icons.volume_up), onPressed: () => widget.pronunciation.speak(_word!.word)),
        ]))),
        const SizedBox(height: 16),
        _Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          TextField(controller: _inputCtl, decoration: InputDecoration(hintText: '输入英文单词', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), onSubmitted: (_) => _shown ? _next() : _check(), enabled: !_shown),
          const SizedBox(height: 16),
          if (_shown) ...[
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: (_correct ? Colors.green : Colors.red).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _correct ? Colors.green : Colors.red)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_correct ? '正确!' : '错误', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: _correct ? Colors.green : Colors.red)),
                if (!_correct) Text('正确答案: ${_word!.word}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _shown ? _next : _check, icon: Icon(_shown ? Icons.arrow_forward : Icons.check), label: Text(_shown ? '下一个' : '检查'))),
        ]))),
      ]),
    );
  }
}
