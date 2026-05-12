import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dictionary_repository.dart';
import '../models/study_models.dart';

const _progressStorageKey = 'word_journey.progress.v1';
const _statsStorageKey = 'word_journey.stats.v1';
const _dailyLimitStorageKey = 'word_journey.daily_limit.v1';
const _autoPronounceStorageKey = 'word_journey.auto_pronounce.v1';
const _bookmarksStorageKey = 'word_journey.bookmarks.v1';
const _studyWordsStorageKey = 'word_journey.study_words.v1';

class StudyController extends ChangeNotifier {
  StudyController({DictionaryRepository? repository})
    : _repository = repository ?? DictionaryRepository();

  final DictionaryRepository _repository;
  List<VocabWord> _words = const [];
  final Map<String, WordProgress> _progressById = {};
  final Map<String, DailyStudyStats> _statsByDay = {};
  final Set<String> _bookmarks = {};
  final Set<String> _studyWordIds = {};

  SharedPreferences? _preferences;
  bool _isReady = false;
  int _dailyNewLimit = 12;
  bool _autoPronounce = true;

  bool get isReady => _isReady;

  int get dailyNewLimit => _dailyNewLimit;

  bool get autoPronounce => _autoPronounce;

  List<VocabWord> get words => List.unmodifiable(_words);

  int get totalWordsInBooks => _words.length;

  Set<String> get bookmarks => Set.unmodifiable(_bookmarks);

  bool isBookmarked(String wordId) => _bookmarks.contains(wordId);

  Set<String> get studyWordIds => Set.unmodifiable(_studyWordIds);

  List<VocabWord> get studyWords {
    if (_studyWordIds.isEmpty) {
      return List.unmodifiable(_words);
    }
    return List.unmodifiable(
      _words.where((w) => _studyWordIds.contains(w.id)).toList(),
    );
  }

  /// All words from all books (for dictionary/search)
  List<VocabWord>? _allWords;
  
  List<VocabWord> get allWords {
    if (_allWords != null && _allWords!.isNotEmpty) {
      return List.unmodifiable(_allWords!);
    }
    return words;
  }

  Future<void> loadAllWords() async {
    if (_allWords != null && _allWords!.isNotEmpty) {
      return;
    }
    // Load in a microtask to not block UI
    await Future.microtask(() async {
      _allWords = await _repository.loadAllWords();
    });
    notifyListeners();
  }

  DailyStudyStats get todayStats {
    final key = studyDayKey(DateTime.now());
    return _statsByDay[key] ?? DailyStudyStats.empty(key);
  }

  int get reviewedToday => todayStats.reviewed;

  int get dueCount => currentQueue.where((item) => !item.isNew).length;

  int get newTodayCount => todayStats.newWords;

  int get remainingNewToday =>
      math.max(0, _dailyNewLimit - todayStats.newWords);

  int get masteredCount =>
      _progressById.values.where((value) => value.isMastered).length;

  int get learningCount =>
      _progressById.values.where((value) => value.isLearning).length;

  int get seenWordsCount => _progressById.length;

  int get backlogCount => math.max(0, _words.length - _progressById.length);

  int get tomorrowCount {
    final now = DateTime.now();
    final tomorrow = startOfDay(now).add(const Duration(days: 1));
    final afterTomorrow = tomorrow.add(const Duration(days: 1));
    return _progressById.values
        .where(
          (value) =>
              value.nextReviewAt.isAfter(tomorrow) &&
              value.nextReviewAt.isBefore(afterTomorrow),
        )
        .length;
  }

  int get futureReviewCount {
    final threshold = startOfDay(DateTime.now()).add(const Duration(days: 2));
    return _progressById.values
        .where((value) => value.nextReviewAt.isAfter(threshold))
        .length;
  }

  double get retentionRateToday => todayStats.retentionRate;

  int get studyStreak {
    var streak = 0;
    var cursor = startOfDay(DateTime.now());
    for (var i = 0; i < 365; i++) {
      final key = studyDayKey(cursor);
      final stats = _statsByDay[key];
      if (stats == null || stats.reviewed == 0) break;
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  List<DailyStudyStats> get recentStats {
    final today = startOfDay(DateTime.now());
    final result = <DailyStudyStats>[];
    for (var offset = 6; offset >= 0; offset--) {
      final day = today.subtract(Duration(days: offset));
      final key = studyDayKey(day);
      result.add(_statsByDay[key] ?? DailyStudyStats.empty(key));
    }
    return result;
  }

  StudyQueueItem? get currentItem {
    final queue = currentQueue;
    if (queue.isEmpty) {
      return null;
    }
    return queue.first;
  }

  List<StudyQueueItem> get currentQueue {
    final now = DateTime.now();
    final wordsToStudy = studyWords;

    final dueItems =
        wordsToStudy
            .where((word) {
              final progress = _progressById[word.id];
              return progress != null && !progress.nextReviewAt.isAfter(now);
            })
            .map(
              (word) =>
                  StudyQueueItem(word: word, progress: _progressById[word.id]),
            )
            .toList()
          ..sort(
            (left, right) => left.progress!.nextReviewAt.compareTo(
              right.progress!.nextReviewAt,
            ),
          );

    final freshItems = wordsToStudy
        .where((word) => !_progressById.containsKey(word.id))
        .take(remainingNewToday)
        .map((word) => StudyQueueItem(word: word, progress: null))
        .toList();

    return [...dueItems, ...freshItems];
  }

  WordProgress? progressFor(String wordId) => _progressById[wordId];

  Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();
    _dailyNewLimit = _preferences?.getInt(_dailyLimitStorageKey) ?? 12;
    _autoPronounce = _preferences?.getBool(_autoPronounceStorageKey) ?? true;
    _words = await _repository.loadWords();
    _loadCustomWords();
    _loadStudyWords();
    _loadProgress();
    _loadStats();
    _loadBookmarks();
    _pruneOldStats();
    _isReady = true;
    notifyListeners();
  }

  Future<void> setDailyNewLimit(int value) async {
    _dailyNewLimit = value.clamp(1, 999);
    await _preferences?.setInt(_dailyLimitStorageKey, _dailyNewLimit);
    notifyListeners();
  }

  Future<void> setAutoPronounce(bool value) async {
    _autoPronounce = value;
    await _preferences?.setBool(_autoPronounceStorageKey, value);
    notifyListeners();
  }

  Future<void> answer(StudyQueueItem item, RecallRating rating) async {
    final now = DateTime.now();
    final wasNewWord = item.isNew;
    final scheduled = _schedule(item.progress, rating, now, item.word.id);
    _progressById[item.word.id] = scheduled;

    final dayKey = studyDayKey(now);
    final currentStats = _statsByDay[dayKey] ?? DailyStudyStats.empty(dayKey);
    _statsByDay[dayKey] = currentStats.copyWith(
      reviewed: currentStats.reviewed + 1,
      newWords: currentStats.newWords + (wasNewWord ? 1 : 0),
      forgotten:
          currentStats.forgotten + (rating == RecallRating.forgot ? 1 : 0),
      confident: currentStats.confident + (rating == RecallRating.know ? 1 : 0),
    );

    await _persistAll();
    notifyListeners();
  }

  Future<void> toggleBookmark(String wordId) async {
    if (_bookmarks.contains(wordId)) {
      _bookmarks.remove(wordId);
    } else {
      _bookmarks.add(wordId);
    }
    await _preferences?.setStringList(_bookmarksStorageKey, _bookmarks.toList());
    notifyListeners();
  }

  Future<void> addWordToStudy(String wordId) async {
    _studyWordIds.add(wordId);
    await _preferences?.setStringList(_studyWordsStorageKey, _studyWordIds.toList());
    notifyListeners();
  }

  Future<void> addWordsToStudy(List<String> wordIds) async {
    _studyWordIds.addAll(wordIds);
    await _preferences?.setStringList(_studyWordsStorageKey, _studyWordIds.toList());
    notifyListeners();
  }

  Future<void> removeWordFromStudy(String wordId) async {
    _studyWordIds.remove(wordId);
    await _preferences?.setStringList(_studyWordsStorageKey, _studyWordIds.toList());
    notifyListeners();
  }

  Future<String?> pickAndImportDictionary() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final path = result.files.first.path;
    if (path == null) {
      return null;
    }

    await _repository.importCustomDictionary(path);
    return path;
  }

  Future<void> resetToDefaultDictionary() async {
    await _repository.resetToDefault();
  }

  Future<String?> getCustomDictPath() async {
    return await _repository.getCustomDictPath();
  }

  Future<void> addWord({
    required String word,
    required String meaning,
    String phonetic = '',
    String definition = '',
  }) async {
    final id = word.toLowerCase().trim();
    if (id.isEmpty) return;

    final existing = _words.where((w) => w.id == id).isNotEmpty;
    if (existing) return;

    final newWord = VocabWord(
      id: id,
      word: word.trim(),
      phonetic: phonetic,
      meaning: meaning,
      definition: definition,
      note: definition,
      level: '手动添加',
      tags: ['手动添加'],
      examples: [],
    );

    _words = [..._words, newWord];
    await _saveCustomWords();
    notifyListeners();
  }

  Future<void> _saveCustomWords() async {
    final customWords = _words
        .where((w) => w.level == '手动添加')
        .map((w) => w.toJson())
        .toList();
    await _preferences?.setString('word_journey.custom_words', jsonEncode(customWords));
  }

  Future<String> exportData() async {
    final data = {
      'progress': _progressById.values.map((v) => v.toJson()).toList(),
      'stats': _statsByDay.values.map((v) => v.toJson()).toList(),
      'bookmarks': _bookmarks.toList(),
      'studyWords': _studyWordIds.toList(),
      'dailyLimit': _dailyNewLimit,
    };
    return jsonEncode(data);
  }

  Future<void> importData(String json) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    _progressById.clear();
    for (final item in (data['progress'] as List<dynamic>?) ?? []) {
      final progress = WordProgress.fromJson(Map<String, dynamic>.from(item as Map));
      _progressById[progress.wordId] = progress;
    }
    _statsByDay.clear();
    for (final item in (data['stats'] as List<dynamic>?) ?? []) {
      final stats = DailyStudyStats.fromJson(Map<String, dynamic>.from(item as Map));
      _statsByDay[stats.dayKey] = stats;
    }
    _bookmarks.clear();
    _bookmarks.addAll(List<String>.from((data['bookmarks'] as List<dynamic>?) ?? []));
    _studyWordIds.clear();
    _studyWordIds.addAll(List<String>.from((data['studyWords'] as List<dynamic>?) ?? []));
    if (data['dailyLimit'] != null) {
      _dailyNewLimit = data['dailyLimit'] as int;
    }
    await _persistAll();
    await _preferences?.setStringList(_bookmarksStorageKey, _bookmarks.toList());
    await _preferences?.setStringList(_studyWordsStorageKey, _studyWordIds.toList());
    await _preferences?.setInt(_dailyLimitStorageKey, _dailyNewLimit);
    notifyListeners();
  }

  Future<void> resetAllProgress() async {
    _progressById.clear();
    _statsByDay.clear();
    _bookmarks.clear();
    _studyWordIds.clear();
    await _preferences?.remove(_progressStorageKey);
    await _preferences?.remove(_statsStorageKey);
    await _preferences?.remove(_bookmarksStorageKey);
    await _preferences?.remove(_studyWordsStorageKey);
    notifyListeners();
  }

  void _loadProgress() {
    try {
      final raw = _preferences?.getString(_progressStorageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      for (final item in decoded) {
        final progress = WordProgress.fromJson(Map<String, dynamic>.from(item as Map));
        _progressById[progress.wordId] = progress;
      }
    } catch (_) {
      _preferences?.remove(_progressStorageKey);
    }
  }

  void _loadStats() {
    try {
      final raw = _preferences?.getString(_statsStorageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      for (final item in decoded) {
        final stats = DailyStudyStats.fromJson(Map<String, dynamic>.from(item as Map));
        _statsByDay[stats.dayKey] = stats;
      }
    } catch (_) {
      _preferences?.remove(_statsStorageKey);
    }
  }

  void _loadCustomWords() {
    try {
      final raw = _preferences?.getString('word_journey.custom_words');
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      final customWords = decoded.map((item) => VocabWord.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      final existingIds = _words.map((w) => w.id).toSet();
      final newWords = customWords.where((w) => !existingIds.contains(w.id)).toList();
      _words = [..._words, ...newWords];
    } catch (_) {
      _preferences?.remove('word_journey.custom_words');
    }
  }

  void _loadBookmarks() {
    final bookmarks = _preferences?.getStringList(_bookmarksStorageKey);
    if (bookmarks != null) {
      _bookmarks.addAll(bookmarks);
    }
  }

  void _loadStudyWords() {
    final studyWords = _preferences?.getStringList(_studyWordsStorageKey);
    if (studyWords != null) {
      _studyWordIds.addAll(studyWords);
    }
  }

  void _pruneOldStats() {
    final cutoff = startOfDay(
      DateTime.now(),
    ).subtract(const Duration(days: 45));
    final expiredKeys = _statsByDay.entries
        .where((entry) => DateTime.parse(entry.key).isBefore(cutoff))
        .map((entry) => entry.key)
        .toList();
    for (final key in expiredKeys) {
      _statsByDay.remove(key);
    }
  }

  Future<void> _persistAll() async {
    await _preferences?.setString(
      _progressStorageKey,
      jsonEncode(_progressById.values.map((value) => value.toJson()).toList()),
    );
    await _preferences?.setString(
      _statsStorageKey,
      jsonEncode(_statsByDay.values.map((value) => value.toJson()).toList()),
    );
  }

  WordProgress _schedule(
    WordProgress? existing,
    RecallRating rating,
    DateTime now,
    String wordId,
  ) {
    final current = existing ?? WordProgress.initial(wordId: wordId, now: now);
    final newTotalReviews = current.totalReviews + 1;

    switch (rating) {
      case RecallRating.forgot:
        // Ebbinghaus: forgotten → short intervals, frequent review
        final newLapses = current.lapses + 1;
        final newEase = math.max(1.3, current.easeFactor - 0.2);
        // Re-review in 5 min, then 30 min, then 1 day, 2 days...
        final reviewMinutes = current.lapses == 0 ? 5 : 30;
        return current.copyWith(
          nextReviewAt: now.add(Duration(minutes: reviewMinutes)),
          lastReviewedAt: now,
          intervalDays: 0,
          totalReviews: newTotalReviews,
          familiarity: math.max(0, current.familiarity - 1),
          easyStreak: 0,
          lastRating: rating,
          easeFactor: newEase,
          lapses: newLapses,
        );
      case RecallRating.hesitant:
        // Ebbinghaus: medium difficulty → standard intervals
        // 1d → 2d → 4d → 7d → 15d
        final newEase = math.max(1.3, current.easeFactor - 0.1);
        int nextDays;
        if (current.intervalDays == 0) {
          nextDays = 1;
        } else if (current.intervalDays == 1) {
          nextDays = 2;
        } else if (current.intervalDays <= 3) {
          nextDays = 4;
        } else if (current.intervalDays <= 6) {
          nextDays = 7;
        } else if (current.intervalDays <= 10) {
          nextDays = 15;
        } else {
          nextDays = math.max(current.intervalDays, (current.intervalDays * 1.5).round());
        }
        return current.copyWith(
          nextReviewAt: _nextStudyMoment(now.add(Duration(days: nextDays))),
          lastReviewedAt: now,
          intervalDays: nextDays,
          totalReviews: newTotalReviews,
          familiarity: math.min(6, current.familiarity + 1),
          easyStreak: 0,
          lastRating: rating,
          easeFactor: newEase,
        );
      case RecallRating.know:
        // Ebbinghaus: easy → longer intervals
        // 1d → 3d → 7d → 15d → 30d → 60d
        final bonus = current.easyStreak >= 2 ? 1.5 : 1.0;
         final newEase = math.min(3.0, current.easeFactor + 0.15);
        int nextDays;
        if (current.intervalDays == 0) {
          nextDays = 1;
        } else if (current.intervalDays == 1) {
          nextDays = 3;
        } else if (current.intervalDays <= 3) {
          nextDays = 7;
        } else if (current.intervalDays <= 10) {
          nextDays = 15;
        } else if (current.intervalDays <= 20) {
          nextDays = 30;
        } else {
          nextDays = (current.intervalDays * bonus * 2.0).round();
          nextDays = math.max(current.intervalDays + 1, nextDays);
        }
        return current.copyWith(
          nextReviewAt: _nextStudyMoment(now.add(Duration(days: nextDays))),
          lastReviewedAt: now,
          intervalDays: nextDays,
          totalReviews: newTotalReviews,
          familiarity: math.min(8, current.familiarity + 2),
          easyStreak: current.easyStreak + 1,
          lastRating: rating,
          easeFactor: newEase,
        );
    }
  }

  DateTime _nextStudyMoment(DateTime value) {
    final base = DateTime(value.year, value.month, value.day, 9);
    final jitter = math.Random().nextInt(60);
    return base.add(Duration(minutes: jitter));
  }
}
