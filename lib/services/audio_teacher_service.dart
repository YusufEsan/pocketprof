import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pocket_prof/core/constants/app_constants.dart';
import 'package:web/web.dart' as web;

/// Hybrid TTS Service: ElevenLabs (Premium) + Web Speech API (Fallback)
class AudioTeacherService {
  String? _elevenLabsApiKey;
  String _voiceId = AppConstants.defaultVoiceId;
  bool _useElevenLabs = true;

  // Web Speech API state
  web.SpeechSynthesisUtterance? _currentUtterance;
  bool _isSpeaking = false;
  double _rate = 1.0;

  // Audio element for ElevenLabs
  web.HTMLAudioElement? _audioElement;

  // Stream controllers
  final _stateController = StreamController<AudioState>.broadcast();
  Stream<AudioState> get stateStream => _stateController.stream;

  AudioTeacherService({String? elevenLabsApiKey, String? voiceId}) {
    _elevenLabsApiKey = elevenLabsApiKey;
    _useElevenLabs = elevenLabsApiKey != null && elevenLabsApiKey.isNotEmpty;
    if (voiceId != null) _voiceId = voiceId;
  }

  /// Update ElevenLabs API key
  void setApiKey(String? apiKey) {
    _elevenLabsApiKey = apiKey;
    _useElevenLabs = apiKey != null && apiKey.isNotEmpty;
  }

  /// Set voice ID for ElevenLabs
  void setVoiceId(String voiceId) {
    _voiceId = voiceId;
  }

  /// Set speech rate (0.5 - 2.0)
  void setRate(double rate) {
    _rate = rate.clamp(0.5, 2.0);
  }

  /// Speak text using the best available TTS
  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    // Stop any current speech
    await stop();

    _stateController.add(AudioState.loading);

    if (_useElevenLabs && _elevenLabsApiKey != null) {
      try {
        await _speakWithElevenLabs(text);
        return;
      } catch (e) {
        debugPrint('ElevenLabs failed, falling back to Web Speech: $e');
        // Fallback to Web Speech API
      }
    }

    // Use Web Speech API as fallback
    await _speakWithWebSpeech(text);
  }

  /// Speak using ElevenLabs API
  Future<void> _speakWithElevenLabs(String text) async {
    final response = await http.post(
      Uri.parse('${AppConstants.elevenLabsBaseUrl}/text-to-speech/$_voiceId'),
      headers: {
        'Content-Type': 'application/json',
        'xi-api-key': _elevenLabsApiKey!,
      },
      body: jsonEncode({
        'text': text,
        'model_id': 'eleven_multilingual_v2',
        'voice_settings': {
          'stability': 0.45,
          'similarity_boost': 0.8,
          'style': 0.4,
          'use_speaker_boost': true,
        },
      }),
    );

    if (response.statusCode == 200) {
      final audioData = response.bodyBytes;
      await _playAudioBytes(audioData);
    } else {
      throw Exception('ElevenLabs API error: ${response.statusCode}');
    }
  }

  /// Play audio bytes using HTML audio element
  Future<void> _playAudioBytes(Uint8List audioData) async {
    // Create blob URL for audio data
    final blob = web.Blob(
      [audioData.toJS].toJS,
      web.BlobPropertyBag(type: 'audio/mpeg'),
    );
    final url = web.URL.createObjectURL(blob);

    // Create audio element
    _audioElement = web.HTMLAudioElement()
      ..src = url
      ..playbackRate = _rate;

    final completer = Completer<void>();

    _audioElement!.onplay = ((web.Event event) {
      _isSpeaking = true;
      _stateController.add(AudioState.playing);
    }).toJS;

    _audioElement!.onpause = ((web.Event event) {
      _isSpeaking = false;
      _stateController.add(AudioState.paused);
    }).toJS;

    _audioElement!.onended = ((web.Event event) {
      _isSpeaking = false;
      _stateController.add(AudioState.stopped);
      web.URL.revokeObjectURL(url);
      completer.complete();
    }).toJS;

    _audioElement!.onerror = ((web.Event event) {
      _isSpeaking = false;
      _stateController.add(AudioState.error);
      web.URL.revokeObjectURL(url);
      completer.completeError('Audio playback error');
    }).toJS;

    _audioElement!.play();

    return completer.future;
  }

  /// Speak using Web Speech API (Browser TTS)
  Future<void> _speakWithWebSpeech(String text) async {
    final synth = web.window.speechSynthesis;

    _currentUtterance = web.SpeechSynthesisUtterance(text)
      ..lang = 'tr-TR'
      ..rate =
          _rate *
          0.9 // Slightly slower for more natural pace
      ..pitch =
          0.95 // Slightly lower pitch for warmer voice
      ..volume = 1.0;

    final completer = Completer<void>();

    _currentUtterance!.onstart = ((web.Event event) {
      _isSpeaking = true;
      _stateController.add(AudioState.playing);
    }).toJS;

    _currentUtterance!.onpause = ((web.Event event) {
      _stateController.add(AudioState.paused);
    }).toJS;

    _currentUtterance!.onresume = ((web.Event event) {
      _stateController.add(AudioState.playing);
    }).toJS;

    _currentUtterance!.onend = ((web.Event event) {
      _isSpeaking = false;
      _stateController.add(AudioState.stopped);
      completer.complete();
    }).toJS;

    _currentUtterance!.onerror = ((web.Event event) {
      _isSpeaking = false;
      _stateController.add(AudioState.error);
      completer.completeError('Speech synthesis error');
    }).toJS;

    synth.speak(_currentUtterance!);

    return completer.future;
  }

  /// Pause current speech
  Future<void> pause() async {
    if (_audioElement != null) {
      _audioElement!.pause();
    } else {
      web.window.speechSynthesis.pause();
    }
    _stateController.add(AudioState.paused);
  }

  /// Resume paused speech
  Future<void> resume() async {
    if (_audioElement != null && _audioElement!.paused) {
      _audioElement!.play();
    } else {
      web.window.speechSynthesis.resume();
    }
    _stateController.add(AudioState.playing);
  }

  /// Stop current speech
  Future<void> stop() async {
    if (_audioElement != null) {
      _audioElement!.pause();
      _audioElement!.currentTime = 0;
      _audioElement = null;
    }

    web.window.speechSynthesis.cancel();
    _currentUtterance = null;
    _isSpeaking = false;
    _stateController.add(AudioState.stopped);
  }

  /// Skip forward by seconds
  Future<void> skipForward(int seconds) async {
    if (_audioElement != null) {
      _audioElement!.currentTime = _audioElement!.currentTime + seconds;
    }
  }

  /// Skip backward by seconds
  Future<void> skipBackward(int seconds) async {
    if (_audioElement != null) {
      final newTime = _audioElement!.currentTime - seconds;
      _audioElement!.currentTime = newTime < 0 ? 0 : newTime;
    }
  }

  /// Get current playback position
  double get currentPosition => _audioElement?.currentTime ?? 0;

  /// Get total duration
  double get duration => _audioElement?.duration ?? 0;

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Check if using ElevenLabs
  bool get isUsingElevenLabs => _useElevenLabs;

  /// Get available ElevenLabs voices
  Future<List<Map<String, dynamic>>> getElevenLabsVoices() async {
    if (_elevenLabsApiKey == null || _elevenLabsApiKey!.isEmpty) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.elevenLabsBaseUrl}/voices'),
        headers: {'xi-api-key': _elevenLabsApiKey!},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List voices = data['voices'] ?? [];
        return voices
            .map(
              (v) => {
                'id': v['voice_id'],
                'name': v['name'],
                'preview_url': v['preview_url'],
                'category': v['category'],
                'labels': v['labels'],
              },
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to fetch ElevenLabs voices: $e');
    }
    return [];
  }

  /// Preview a voice with specific text
  Future<void> previewVoice(String voiceId, String text) async {
    if (_elevenLabsApiKey == null || _elevenLabsApiKey!.isEmpty) return;

    // Temporarily change voiceId and speak
    final oldVoiceId = _voiceId;
    _voiceId = voiceId;
    try {
      await speak(text);
    } finally {
      _voiceId = oldVoiceId;
    }
  }

  /// Get available Web Speech voices
  List<web.SpeechSynthesisVoice> getAvailableVoices() {
    final voices = web.window.speechSynthesis.getVoices();
    final result = <web.SpeechSynthesisVoice>[];
    for (var i = 0; i < voices.length; i++) {
      final voice = voices[i];
      if (voice != null) result.add(voice);
    }
    return result;
  }

  /// Get Turkish voices
  List<web.SpeechSynthesisVoice> getTurkishVoices() {
    return getAvailableVoices().where((v) => v.lang.startsWith('tr')).toList();
  }

  /// Dispose resources
  void dispose() {
    stop();
    _stateController.close();
  }
}

/// Audio playback state
enum AudioState { stopped, loading, playing, paused, error }
