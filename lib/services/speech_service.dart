import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    if (kIsWeb) return false;
    if (_initialized) return _isAvailable;
    try {
      _isAvailable = await _speech.initialize(
        onError: (val) => debugPrint('[SpeechService] onError: ${val.errorMsg}'),
        onStatus: (val) => debugPrint('[SpeechService] onStatus: $val'),
      );
      _initialized = true;
      return _isAvailable;
    } catch (e) {
      debugPrint('[SpeechService] initialize error: $e');
      _initialized = true;
      _isAvailable = false;
      return false;
    }
  }

  Future<void> listen({
    required void Function(String recognizedWords, bool isFinal) onResult,
    String? localeId,
  }) async {
    final available = await initialize();
    if (!available) return;
    try {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: localeId,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
        ),
      );
    } catch (e) {
      debugPrint('[SpeechService] listen error: $e');
    }
  }

  Future<void> stop() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('[SpeechService] stop error: $e');
    }
  }

  Future<void> cancel() async {
    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (e) {
      debugPrint('[SpeechService] cancel error: $e');
    }
  }
}
