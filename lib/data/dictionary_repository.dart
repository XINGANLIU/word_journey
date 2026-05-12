import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_models.dart';

const _customDictPathKey = 'word_journey.custom_dict_path';
const _selectedBooksKey = 'word_journey.selected_books';

class DictionaryRepository {
  const DictionaryRepository();

  static const _defaultAssetPath = 'assets/data/starter_dictionary.json';

  static const _bookAssetPaths = {
    'cet4': 'assets/data/word_books/cet4.json',
    'cet6': 'assets/data/word_books/cet6.json',
    'kaoyan': 'assets/data/word_books/kaoyan.json',
    'gaokao': 'assets/data/word_books/gaokao.json',
    'ielts': 'assets/data/word_books/ielts.json',
    'toefl': 'assets/data/word_books/toefl.json',
    'common_10000': 'assets/data/word_books/common_10000.json',
  };

  Future<List<VocabWord>> loadWords() async {
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString(_customDictPathKey);

    if (customPath != null && customPath.isNotEmpty) {
      try {
        return await _loadFromPath(customPath);
      } catch (_) {
        // Fall back to default if custom dict fails
      }
    }

    // Load from selected books
    final selectedBooks = prefs.getStringList(_selectedBooksKey) ?? [];
    if (selectedBooks.isNotEmpty) {
      return await _loadFromBooks(selectedBooks);
    }

    // Default: load starter dictionary
    return await _loadFromAsset(_defaultAssetPath);
  }

  Future<List<VocabWord>> _loadFromBooks(List<String> bookIds) async {
    final allWords = <String, VocabWord>{};

    for (final bookId in bookIds) {
      final assetPath = _bookAssetPaths[bookId];
      if (assetPath == null) continue;

      try {
        final words = await _loadFromAsset(assetPath);
        for (final word in words) {
          allWords[word.id] = word;
        }
      } catch (_) {
        // Skip failed books
      }
    }

    return allWords.values.toList();
  }

  Future<List<VocabWord>> _loadFromAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return _parseWords(raw);
  }

  Future<List<VocabWord>> _loadFromPath(String path) async {
    final file = File(path);
    final raw = await file.readAsString();
    return _parseWords(raw);
  }

  List<VocabWord> _parseWords(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final words = decoded['words'] as List<dynamic>? ?? const [];
    return words
        .map(
          (item) => VocabWord.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<Map<String, int>> getBookWordCounts() async {
    final counts = <String, int>{};
    for (final entry in _bookAssetPaths.entries) {
      try {
        final raw = await rootBundle.loadString(entry.value);
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        counts[entry.key] = decoded['wordCount'] as int? ?? 0;
      } catch (_) {
        counts[entry.key] = 0;
      }
    }
    return counts;
  }

  /// Load ALL words from all books for dictionary search
  Future<List<VocabWord>> loadAllWords() async {
    final allWords = <String, VocabWord>{};
    for (final assetPath in _bookAssetPaths.values) {
      try {
        final words = await _loadFromAsset(assetPath);
        for (final word in words) {
          if (!allWords.containsKey(word.id)) {
            allWords[word.id] = word;
          }
        }
      } catch (_) {}
    }
    return allWords.values.toList();
  }

  Future<void> importCustomDictionary(String path) async {
    final file = File(path);
    final exists = await file.exists();
    if (!exists) {
      throw Exception('文件不存在');
    }

    final raw = await file.readAsString();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final words = decoded['words'] as List<dynamic>?;
    if (words == null) {
      throw Exception('无效的词库格式，需要包含 "words" 字段');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customDictPathKey, path);
  }

  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customDictPathKey);
  }

  Future<String?> getCustomDictPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customDictPathKey);
  }
}
