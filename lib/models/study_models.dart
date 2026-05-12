String studyDayKey(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime startOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

enum RecallRating { forgot, hesitant, know }

class WordExample {
  const WordExample({
    required this.en,
    required this.zh,
    required this.source,
    this.sourceId,
  });

  factory WordExample.fromJson(Map<String, dynamic> json) {
    return WordExample(
      en: json['en'] as String? ?? '',
      zh: json['zh'] as String? ?? '',
      source: json['source'] as String? ?? '',
      sourceId: json['sourceId'] as String?,
    );
  }

  final String en;
  final String zh;
  final String source;
  final String? sourceId;

  Map<String, dynamic> toJson() {
    return {'en': en, 'zh': zh, 'source': source, 'sourceId': sourceId};
  }
}

class VocabWord {
  const VocabWord({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.meaning,
    required this.definition,
    required this.note,
    required this.level,
    required this.tags,
    required this.examples,
  });

  factory VocabWord.fromJson(Map<String, dynamic> json) {
    final examples = (json['examples'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              WordExample.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

    return VocabWord(
      id: json['id'] as String,
      word: json['word'] as String,
      phonetic: json['phonetic'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      note: json['note'] as String? ?? '',
      level: json['level'] as String? ?? '词库',
      tags: List<String>.from(json['tags'] as List<dynamic>? ?? const []),
      examples: examples,
    );
  }

  final String id;
  final String word;
  final String phonetic;
  final String meaning;
  final String definition;
  final String note;
  final String level;
  final List<String> tags;
  final List<WordExample> examples;

  WordExample? get primaryExample => examples.isEmpty ? null : examples.first;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'phonetic': phonetic,
      'meaning': meaning,
      'definition': definition,
      'note': note,
      'level': level,
      'tags': tags,
      'examples': examples.map((item) => item.toJson()).toList(),
    };
  }
}

class WordProgress {
  const WordProgress({
    required this.wordId,
    required this.nextReviewAt,
    required this.lastReviewedAt,
    required this.intervalDays,
    required this.totalReviews,
    required this.familiarity,
    required this.easyStreak,
    required this.lastRating,
    this.easeFactor = 2.5,
    this.lapses = 0,
  });

  factory WordProgress.initial({
    required String wordId,
    required DateTime now,
  }) {
    return WordProgress(
      wordId: wordId,
      nextReviewAt: now,
      lastReviewedAt: null,
      intervalDays: 0,
      totalReviews: 0,
      familiarity: 0,
      easyStreak: 0,
      lastRating: null,
      easeFactor: 2.5,
      lapses: 0,
    );
  }

  factory WordProgress.fromJson(Map<String, dynamic> json) {
    final ratingName = json['lastRating'] as String?;
    final rating = ratingName == null
        ? null
        : RecallRating.values.firstWhere(
            (value) => value.name == ratingName,
            orElse: () => RecallRating.hesitant,
          );

    return WordProgress(
      wordId: json['wordId'] as String,
      nextReviewAt: DateTime.parse(json['nextReviewAt'] as String),
      lastReviewedAt: json['lastReviewedAt'] == null
          ? null
          : DateTime.parse(json['lastReviewedAt'] as String),
      intervalDays: json['intervalDays'] as int? ?? 0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      familiarity: json['familiarity'] as int? ?? 0,
      easyStreak: json['easyStreak'] as int? ?? 0,
      lastRating: rating,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      lapses: json['lapses'] as int? ?? 0,
    );
  }

  final String wordId;
  final DateTime nextReviewAt;
  final DateTime? lastReviewedAt;
  final int intervalDays;
  final int totalReviews;
  final int familiarity;
  final int easyStreak;
  final RecallRating? lastRating;
  final double easeFactor;
  final int lapses;

  bool get isMastered =>
      intervalDays >= 21 || familiarity >= 6 || easyStreak >= 4;

  bool get isLearning => totalReviews > 0 && !isMastered;

  Map<String, dynamic> toJson() {
    return {
      'wordId': wordId,
      'nextReviewAt': nextReviewAt.toIso8601String(),
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'intervalDays': intervalDays,
      'totalReviews': totalReviews,
      'familiarity': familiarity,
      'easyStreak': easyStreak,
      'lastRating': lastRating?.name,
      'easeFactor': easeFactor,
      'lapses': lapses,
    };
  }

  WordProgress copyWith({
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    int? intervalDays,
    int? totalReviews,
    int? familiarity,
    int? easyStreak,
    RecallRating? lastRating,
    double? easeFactor,
    int? lapses,
  }) {
    return WordProgress(
      wordId: wordId,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      intervalDays: intervalDays ?? this.intervalDays,
      totalReviews: totalReviews ?? this.totalReviews,
      familiarity: familiarity ?? this.familiarity,
      easyStreak: easyStreak ?? this.easyStreak,
      lastRating: lastRating ?? this.lastRating,
      easeFactor: easeFactor ?? this.easeFactor,
      lapses: lapses ?? this.lapses,
    );
  }
}

class DailyStudyStats {
  const DailyStudyStats({
    required this.dayKey,
    required this.reviewed,
    required this.newWords,
    required this.forgotten,
    required this.confident,
  });

  factory DailyStudyStats.empty(String dayKey) {
    return DailyStudyStats(
      dayKey: dayKey,
      reviewed: 0,
      newWords: 0,
      forgotten: 0,
      confident: 0,
    );
  }

  factory DailyStudyStats.fromJson(Map<String, dynamic> json) {
    return DailyStudyStats(
      dayKey: json['dayKey'] as String,
      reviewed: json['reviewed'] as int? ?? 0,
      newWords: json['newWords'] as int? ?? 0,
      forgotten: json['forgotten'] as int? ?? 0,
      confident: json['confident'] as int? ?? 0,
    );
  }

  final String dayKey;
  final int reviewed;
  final int newWords;
  final int forgotten;
  final int confident;

  double get retentionRate {
    if (reviewed == 0) {
      return 0;
    }
    return ((reviewed - forgotten) / reviewed).clamp(0, 1).toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'dayKey': dayKey,
      'reviewed': reviewed,
      'newWords': newWords,
      'forgotten': forgotten,
      'confident': confident,
    };
  }

  DailyStudyStats copyWith({
    int? reviewed,
    int? newWords,
    int? forgotten,
    int? confident,
  }) {
    return DailyStudyStats(
      dayKey: dayKey,
      reviewed: reviewed ?? this.reviewed,
      newWords: newWords ?? this.newWords,
      forgotten: forgotten ?? this.forgotten,
      confident: confident ?? this.confident,
    );
  }
}

class StudyQueueItem {
  const StudyQueueItem({required this.word, required this.progress});

  final VocabWord word;
  final WordProgress? progress;

  bool get isNew => progress == null;
}
