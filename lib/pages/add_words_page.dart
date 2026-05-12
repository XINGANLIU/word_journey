import 'package:flutter/material.dart';

import '../controllers/study_controller.dart';
import '../models/study_models.dart';
import '../services/pronunciation_service.dart';

class AddWordsPage extends StatefulWidget {
  const AddWordsPage({
    super.key,
    required this.controller,
    required this.pronunciation,
  });

  final StudyController controller;
  final PronunciationService pronunciation;

  @override
  State<AddWordsPage> createState() => _AddWordsPageState();
}

class _AddWordsPageState extends State<AddWordsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedTag = '全部';
  List<String> _tags = ['全部'];
  List<VocabWord> _allWords = [];
  bool _loadingAll = false;

  @override
  void initState() {
    super.initState();
    _loadAllWords();
  }

  Future<void> _loadAllWords() async {
    setState(() => _loadingAll = true);
    await widget.controller.loadAllWords();
    if (!mounted) return;
    _allWords = widget.controller.allWords;
    _loadTags();
    setState(() => _loadingAll = false);
  }

  void _loadTags() {
    final tags = <String>{};
    for (final word in _allWords) {
      tags.addAll(word.tags);
    }
    setState(() {
      _tags = ['全部', ...tags.toList()..sort()];
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VocabWord> _getFilteredWords() {
    var words = _allWords.where((w) {
      if (_query.isNotEmpty) {
        final haystack = '${w.word} ${w.meaning} ${w.phonetic}'.toLowerCase();
        if (!haystack.contains(_query)) return false;
      }
      if (_selectedTag != '全部' && !w.tags.contains(_selectedTag)) {
        return false;
      }
      return true;
    }).toList();

    words.sort((a, b) => a.word.compareTo(b.word));
    return words;
  }

  void _addWordToStudy(VocabWord word) {
    widget.controller.addWordToStudy(word.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加: ${word.word}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredWords = _getFilteredWords();
    final studyWordIds = widget.controller.studyWordIds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('词典搜索'),
        actions: [
          TextButton.icon(
            onPressed: _loadingAll ? null : () {
              final toAdd = filteredWords
                  .where((w) => !widget.controller.studyWordIds.contains(w.id))
                  .map((w) => w.id)
                  .toList();
              if (toAdd.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('所有单词已添加')),
                );
                return;
              }
              widget.controller.addWordsToStudy(toAdd);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已添加 ${toAdd.length} 个单词')),
              );
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('全部添加'),
          ),
        ],
      ),
      body: _loadingAll
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _query = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: '搜索单词或释义',
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
                            icon: const Icon(Icons.clear),
                          ),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tags.length,
                    itemBuilder: (context, index) {
                      final tag = _tags[index];
                      final selected = _selectedTag == tag;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(tag),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedTag = tag;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '词典 - 共 ${_allWords.length} 词',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '已学 ${widget.controller.studyWordIds.length} 词',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredWords.length,
              itemBuilder: (context, index) {
                final word = filteredWords[index];
                final isAdded = studyWordIds.contains(word.id);
                return _WordListTile(
                  word: word,
                  isAdded: isAdded,
                  pronunciation: widget.pronunciation,
                  onAdd: isAdded ? null : () => _addWordToStudy(word),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WordListTile extends StatelessWidget {
  const _WordListTile({
    required this.word,
    required this.isAdded,
    required this.pronunciation,
    required this.onAdd,
  });

  final VocabWord word;
  final bool isAdded;
  final PronunciationService pronunciation;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAdded
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Text(
            word.word.substring(0, 1).toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isAdded
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        title: Text(
          word.word,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${word.phonetic}\n${word.meaning}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.volume_up, size: 20),
              onPressed: () => pronunciation.speak(word.word),
            ),
            if (isAdded)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              )
            else
              FilledButton.tonal(
                onPressed: onAdd,
                child: const Text('添加'),
              ),
          ],
        ),
      ),
    );
  }
}
