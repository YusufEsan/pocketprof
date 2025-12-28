import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_prof/services/audio_teacher_service.dart';
import 'package:pocket_prof/providers/settings_provider.dart';

/// Audio player state
class AudioPlayerState {
  final AudioState status;
  final double position;
  final double duration;
  final double rate;
  final String? currentText;
  final String? error;
  
  const AudioPlayerState({
    this.status = AudioState.stopped,
    this.position = 0,
    this.duration = 0,
    this.rate = 1.0,
    this.currentText,
    this.error,
  });
  
  AudioPlayerState copyWith({
    AudioState? status,
    double? position,
    double? duration,
    double? rate,
    String? currentText,
    String? error,
    bool clearText = false,
  }) {
    return AudioPlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      rate: rate ?? this.rate,
      currentText: clearText ? null : (currentText ?? this.currentText),
      error: error,
    );
  }
  
  bool get isPlaying => status == AudioState.playing;
  bool get isPaused => status == AudioState.paused;
  bool get isLoading => status == AudioState.loading;
  bool get isStopped => status == AudioState.stopped;
  bool get hasText => currentText != null && currentText!.isNotEmpty;
}

/// Audio player notifier
class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final AudioTeacherService _audioService;
  StreamSubscription? _stateSubscription;
  
  AudioPlayerNotifier(this._audioService) : super(const AudioPlayerState()) {
    _listenToAudioState();
  }
  
  void _listenToAudioState() {
    _stateSubscription = _audioService.stateStream.listen((audioState) {
      if (!mounted) return;
      state = state.copyWith(
        status: audioState,
        position: _audioService.currentPosition,
        duration: _audioService.duration,
      );
    });
  }
  
  /// Speak text
  Future<void> speak(String text) async {
    state = state.copyWith(currentText: text, error: null);
    try {
      await _audioService.speak(text);
    } catch (e) {
      state = state.copyWith(
        status: AudioState.error,
        error: e.toString(),
      );
    }
  }
  
  /// Pause playback
  Future<void> pause() async {
    await _audioService.pause();
  }
  
  /// Resume playback
  Future<void> resume() async {
    await _audioService.resume();
  }
  
  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else if (state.isPaused) {
      await resume();
    } else if (state.currentText != null) {
      await speak(state.currentText!);
    }
  }
  
  /// Stop playback
  Future<void> stop() async {
    await _audioService.stop();
    state = state.copyWith(status: AudioState.stopped, clearText: true);
  }
  
  /// Skip forward
  Future<void> skipForward(int seconds) async {
    await _audioService.skipForward(seconds);
  }
  
  /// Skip backward
  Future<void> skipBackward(int seconds) async {
    await _audioService.skipBackward(seconds);
  }
  
  /// Set playback rate
  void setRate(double rate) {
    _audioService.setRate(rate);
    state = state.copyWith(rate: rate);
  }
  
  @override
  void dispose() {
    _stateSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}

/// Audio player provider
final audioPlayerProvider = StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  final audioService = ref.watch(audioTeacherServiceProvider);
  return AudioPlayerNotifier(audioService);
});
