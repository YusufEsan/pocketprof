import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_prof/services/storage_service.dart';
import 'package:pocket_prof/services/llm_service.dart';
import 'package:pocket_prof/services/audio_teacher_service.dart';

/// Settings state
class SettingsState {
  final String? openRouterApiKey;
  final String? elevenLabsApiKey;
  final String selectedModel;
  final String selectedVoice;
  final bool ttsEnabled;
  final ThemeMode themeMode;

  const SettingsState({
    this.openRouterApiKey,
    this.elevenLabsApiKey,
    this.selectedModel = 'google/gemini-flash-1.5',
    this.selectedVoice = '21m00Tcm4TlvDq8ikWAM',
    this.ttsEnabled = true,
    this.themeMode = ThemeMode.system,
  });

  SettingsState copyWith({
    String? openRouterApiKey,
    String? elevenLabsApiKey,
    String? selectedModel,
    String? selectedVoice,
    bool? ttsEnabled,
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      openRouterApiKey: openRouterApiKey ?? this.openRouterApiKey,
      elevenLabsApiKey: elevenLabsApiKey ?? this.elevenLabsApiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      selectedVoice: selectedVoice ?? this.selectedVoice,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  bool get hasOpenRouterKey =>
      openRouterApiKey != null && openRouterApiKey!.isNotEmpty;
  bool get hasElevenLabsKey =>
      elevenLabsApiKey != null && elevenLabsApiKey!.isNotEmpty;
}

/// Settings notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final StorageService _storage;

  SettingsNotifier(this._storage) : super(const SettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    state = SettingsState(
      openRouterApiKey: _storage.openRouterApiKey,
      elevenLabsApiKey: _storage.elevenLabsApiKey,
      selectedModel: _storage.selectedModel,
      selectedVoice: _storage.selectedVoice,
      ttsEnabled: _storage.ttsEnabled,
      themeMode: _storage.themeMode,
    );
  }

  Future<void> setOpenRouterApiKey(String? key) async {
    await _storage.setOpenRouterApiKey(key);
    state = state.copyWith(openRouterApiKey: key);
  }

  Future<void> setElevenLabsApiKey(String? key) async {
    await _storage.setElevenLabsApiKey(key);
    state = state.copyWith(elevenLabsApiKey: key);
  }

  Future<void> setSelectedModel(String model) async {
    await _storage.setSelectedModel(model);
    state = state.copyWith(selectedModel: model);
  }

  Future<void> setSelectedVoice(String voiceId) async {
    await _storage.setSelectedVoice(voiceId);
    state = state.copyWith(selectedVoice: voiceId);
  }

  Future<void> setTtsEnabled(bool enabled) async {
    await _storage.setTtsEnabled(enabled);
    state = state.copyWith(ttsEnabled: enabled);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _storage.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }
}

/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final storage = ref.watch(storageServiceProvider);
    return SettingsNotifier(storage);
  },
);

/// LLM service provider
final llmServiceProvider = Provider<LLMService?>((ref) {
  final settings = ref.watch(settingsProvider);
  if (!settings.hasOpenRouterKey) return null;
  return LLMService(
    apiKey: settings.openRouterApiKey!,
    model: settings.selectedModel,
  );
});

/// Audio teacher service provider
final audioTeacherServiceProvider = Provider<AudioTeacherService>((ref) {
  final settings = ref.watch(settingsProvider);
  return AudioTeacherService(
    elevenLabsApiKey: settings.elevenLabsApiKey,
    voiceId: settings.selectedVoice,
  );
});
