import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final List<String> _queue = [];
  bool _isSpeaking = false;
  bool _isPaused = false;
  bool _isInitialized = false;
  Completer<void>? _speakCompleter;

  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Try to get available languages first
      final languages = await _flutterTts.getLanguages;
      String? language = "en-US";
      
      // Try to set language, fallback to default if en-US not available
      if (languages != null && languages.isNotEmpty) {
        if (languages.contains("en-US")) {
          language = "en-US";
        } else if (languages.contains("en")) {
          language = "en";
        } else {
          language = languages.first;
        }
      }
      
      await _flutterTts.setLanguage(language ?? "en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _speakCompleter?.complete();
        _speakCompleter = null;
        _processQueue();
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        _speakCompleter?.completeError(msg);
        _speakCompleter = null;
        _processQueue();
      });
      
      _isInitialized = true;
    } catch (e) {
      // If initialization fails, mark as initialized anyway to prevent retries
      _isInitialized = true;
      print('TTS initialization error: $e');
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    // Initialize if not already initialized
    if (!_isInitialized) {
      await initialize();
    }

    _queue.add(text);
    if (!_isSpeaking) {
      await _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_queue.isEmpty || _isSpeaking) return;

    _isSpeaking = true;
    _isPaused = false;
    final text = _queue.removeAt(0);
    _speakCompleter = Completer<void>();

    try {
      final result = await _flutterTts.speak(text);
      if (result == 1) {
        // Success, wait for completion
        await _speakCompleter!.future;
      } else {
        // Failed to speak
        _isSpeaking = false;
        _speakCompleter?.completeError('Failed to speak');
        _speakCompleter = null;
        _processQueue();
      }
    } catch (e) {
      print('TTS speak error: $e');
      _isSpeaking = false;
      _speakCompleter?.completeError(e);
      _speakCompleter = null;
      _processQueue();
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('TTS stop error: $e');
    }
    _queue.clear();
    _isSpeaking = false;
    _isPaused = false;
    _speakCompleter?.complete();
    _speakCompleter = null;
  }

  Future<void> pause() async {
    if (_isSpeaking && !_isPaused) {
      await _flutterTts.pause();
      _isPaused = true;
    }
  }

  Future<void> resume() async {
    if (_isPaused) {
      await _flutterTts.speak("");
      _isPaused = false;
    }
  }

  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
  }
}

