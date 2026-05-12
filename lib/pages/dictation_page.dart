import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/study_controller.dart';
import '../models/study_models.dart';
import '../services/pronunciation_service.dart';

class DictationPage extends StatefulWidget {
  const DictationPage({
    super.key,
    required this.controller,
    required this.pronunciation,
  });

  final StudyController controller;
  final PronunciationService pronunciation;

  @override
  State<DictationPage> createState() => _DictationPageState();
}

class _DictationPageState extends State<DictationPage> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  
  VocabWord? _currentWord;
  bool _showResult = false;
  bool _isCorrect = false;
  int _correctCount = 0;
  int _totalCount = 0;
  bool _autoPlay = true;
  List<VocabWord> _wordPool = [];

  @override
  void initState() {
    super.initState();
    _loadWordPool();
    _nextWord();
  }

  void _loadWordPool() {
    _wordPool = List.from(widget.controller.studyWords);
    if (_wordPool.isEmpty) {
      _wordPool = List.from(widget.controller.words);
    }
    _wordPool.shuffle();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _nextWord() {
    if (_wordPool.isEmpty) {
      _loadWordPool();
    }
    if (_wordPool.isEmpty) return;
    setState(() {
      _currentWord = _wordPool.removeLast();
      _showResult = false;
      _isCorrect = false;
      _inputController.clear();
    });

    _inputFocus.requestFocus();

    if (_autoPlay && _currentWord != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.pronunciation.speak(_currentWord!.word);
      });
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
      if (_isCorrect) {
        _correctCount++;
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _playAudio() {
    if (_currentWord != null) {
      widget.pronunciation.speak(_currentWord!.word);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_currentWord == null) {
      return const Scaffold(
        body: Center(child: Text('没有可听写的单词')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('听写模式'),
        actions: [
          Row(
            children: [
              const Text('自动播放'),
              Switch(
                value: _autoPlay,
                onChanged: (value) {
                  setState(() {
                    _autoPlay = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Stats bar
          _SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _StatChip(
                    icon: Icons.check_circle_outline,
                    label: '正确',
                    value: '$_correctCount',
                    color: Colors.green,
                  ),
                  _StatChip(
                    icon: Icons.format_list_numbered,
                    label: '总数',
                    value: '$_totalCount',
                    color: theme.colorScheme.primary,
                  ),
                  if (_totalCount > 0)
                    _StatChip(
                      icon: Icons.percent,
                      label: '正确率',
                      value: '${(_correctCount / _totalCount * 100).round()}%',
                      color: theme.colorScheme.tertiary,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Audio player section
          _SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '听发音，拼写单词',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentWord!.meaning,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Big play button
                  GestureDetector(
                    onTap: _playAudio,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primaryContainer,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.volume_up,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _playAudio,
                    icon: const Icon(Icons.replay),
                    label: const Text('再听一次'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Input section
          _SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '输入单词',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _inputController,
                    focusNode: _inputFocus,
                    decoration: InputDecoration(
                      hintText: '请输入英文单词...',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _inputController.clear(),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _showResult ? _nextWord() : _checkSpelling(),
                    enabled: !_showResult,
                  ),
                  const SizedBox(height: 16),

                  // Result feedback
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
                          Row(
                            children: [
                              Icon(
                                _isCorrect ? Icons.check_circle : Icons.cancel,
                                color: _isCorrect ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isCorrect ? '正确!' : '错误',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _isCorrect ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          if (!_isCorrect) ...[
                            const SizedBox(height: 12),
                            Text(
                              '正确答案: ${_currentWord!.word}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentWord!.phonetic,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            _currentWord!.meaning,
                            style: theme.textTheme.bodyLarge,
                          ),
                          if (_currentWord!.examples.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...(_currentWord!.examples.take(1).map(
                              (ex) => Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  ex.en,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _showResult ? _nextWord : _checkSpelling,
                      icon: Icon(_showResult ? Icons.arrow_forward : Icons.check),
                      label: Text(_showResult ? '下一个' : '检查'),
                    ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: child,
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            '$label $value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
