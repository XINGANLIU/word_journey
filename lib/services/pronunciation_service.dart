import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class PronunciationService extends ChangeNotifier {
  FlutterTts? _tts;
  bool _configured = false;
  String? _speakingWord;

  String? get speakingWord => _speakingWord;

  bool isSpeaking(String word) => _speakingWord == word;

  Future<void> speak(String word) async {
    final tts = await _ensureConfigured();
    await tts.stop();
    _speakingWord = word;
    notifyListeners();
    await tts.speak(word);
  }

  Future<void> speakOrStop(String word) async {
    if (_speakingWord == word) {
      await stop();
      return;
    }
    await speak(word);
  }

  Future<void> stop() async {
    final tts = _tts;
    if (tts != null) {
      await tts.stop();
    }
    _clearSpeakingState();
  }

  Future<FlutterTts> _ensureConfigured() async {
    _tts ??= FlutterTts();

    final tts = _tts!;
    if (_configured) {
      return tts;
    }

    tts.setStartHandler(() {
      notifyListeners();
    });
    tts.setCompletionHandler(_clearSpeakingState);
    tts.setCancelHandler(_clearSpeakingState);
    tts.setErrorHandler((_) {
      _clearSpeakingState();
    });

    await tts.awaitSpeakCompletion(false);
    await tts.setLanguage('en-US');
    await tts.setSpeechRate(0.42);
    await tts.setPitch(1.0);
    await tts.setVolume(1.0);

    _configured = true;
    return tts;
  }

  void _clearSpeakingState() {
    if (_speakingWord == null) {
      return;
    }
    _speakingWord = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
