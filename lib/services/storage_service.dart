import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:pocket_prof/core/constants/app_constants.dart';

/// Local storage service using Hive (IndexedDB on Web)
class StorageService {
  static StorageService? _instance;
  late Box _settingsBox;
  late Box _chatsBox;
  late Box _messagesBox;
  bool _isInitialized = false;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  /// Initialize Hive storage
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
    _chatsBox = await Hive.openBox(AppConstants.chatsBox);
    _messagesBox = await Hive.openBox(AppConstants.messagesBox);

    _isInitialized = true;
  }

  // ===== API Keys =====

  String? get openRouterApiKey =>
      _settingsBox.get(AppConstants.openRouterApiKey);

  Future<void> setOpenRouterApiKey(String? key) async {
    if (key == null || key.isEmpty) {
      await _settingsBox.delete(AppConstants.openRouterApiKey);
    } else {
      await _settingsBox.put(AppConstants.openRouterApiKey, key);
    }
  }

  String? get elevenLabsApiKey =>
      _settingsBox.get(AppConstants.elevenLabsApiKey);

  Future<void> setElevenLabsApiKey(String? key) async {
    if (key == null || key.isEmpty) {
      await _settingsBox.delete(AppConstants.elevenLabsApiKey);
    } else {
      await _settingsBox.put(AppConstants.elevenLabsApiKey, key);
    }
  }

  // ===== Model Settings =====

  String get selectedModel => _settingsBox.get(
    AppConstants.selectedModel,
    defaultValue: AppConstants.defaultModel,
  );

  Future<void> setSelectedModel(String model) async {
    await _settingsBox.put(AppConstants.selectedModel, model);
  }

  // ===== Voice Settings =====

  String get selectedVoice => _settingsBox.get(
    AppConstants.selectedVoice,
    defaultValue: AppConstants.defaultVoiceId,
  );

  Future<void> setSelectedVoice(String voiceId) async {
    await _settingsBox.put(AppConstants.selectedVoice, voiceId);
  }

  bool get ttsEnabled =>
      _settingsBox.get(AppConstants.ttsEnabled, defaultValue: true);

  Future<void> setTtsEnabled(bool enabled) async {
    await _settingsBox.put(AppConstants.ttsEnabled, enabled);
  }

  // ===== Theme Settings =====

  ThemeMode get themeMode {
    final value = _settingsBox.get('theme_mode', defaultValue: 'system');
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _settingsBox.put('theme_mode', value);
  }

  // ===== Chat History =====

  /// Save a chat session
  Future<void> saveChat(String chatId, Map<String, dynamic> chatData) async {
    await _chatsBox.put(chatId, chatData);
  }

  /// Get a chat session
  Map<String, dynamic>? getChat(String chatId) {
    final data = _chatsBox.get(chatId);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  /// Get all chat sessions
  List<Map<String, dynamic>> getAllChats() {
    return _chatsBox.values.map((e) => Map<String, dynamic>.from(e)).toList()
      ..sort(
        (a, b) => (b['updatedAt'] as int? ?? 0).compareTo(
          a['updatedAt'] as int? ?? 0,
        ),
      );
  }

  /// Delete a chat session
  Future<void> deleteChat(String chatId) async {
    await _chatsBox.delete(chatId);
    // Also delete associated messages
    final keysToDelete = _messagesBox.keys
        .where((key) => key.toString().startsWith('$chatId:'))
        .toList();
    for (final key in keysToDelete) {
      await _messagesBox.delete(key);
    }
  }

  // ===== Messages =====

  /// Save a message
  Future<void> saveMessage(
    String chatId,
    String messageId,
    Map<String, dynamic> messageData,
  ) async {
    await _messagesBox.put('$chatId:$messageId', messageData);
  }

  /// Get messages for a chat
  List<Map<String, dynamic>> getMessages(String chatId) {
    return _messagesBox.keys
        .where((key) => key.toString().startsWith('$chatId:'))
        .map((key) => Map<String, dynamic>.from(_messagesBox.get(key)))
        .toList()
      ..sort(
        (a, b) => (a['timestamp'] as int? ?? 0).compareTo(
          b['timestamp'] as int? ?? 0,
        ),
      );
  }

  // ===== General =====

  /// Clear all data
  Future<void> clearAll() async {
    await _settingsBox.clear();
    await _chatsBox.clear();
    await _messagesBox.clear();
  }

  /// Check if API keys are configured
  bool get hasApiKeys =>
      openRouterApiKey != null && openRouterApiKey!.isNotEmpty;

  // ===== Export / Import =====

  /// Export all chat data as a Map (for JSON serialization)
  Map<String, dynamic> exportAllData() {
    final chats = getAllChats();
    final Map<String, List<Map<String, dynamic>>> messagesMap = {};

    for (final chat in chats) {
      final chatId = chat['id'] as String;
      messagesMap[chatId] = getMessages(chatId);
    }

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'chats': chats,
      'messages': messagesMap,
    };
  }

  /// Import chat data from a Map (from JSON). Returns count of imported chats.
  /// Always creates new IDs to avoid conflicts.
  Future<int> importData(Map<String, dynamic> data) async {
    final chats = (data['chats'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final messagesMap = data['messages'] as Map<String, dynamic>? ?? {};

    int importedCount = 0;

    for (final chat in chats) {
      final oldId = chat['id'] as String;
      final newId = const Uuid().v4(); // Use unique UUID for each chat

      // Create new chat with new ID
      final newChat = Map<String, dynamic>.from(chat);
      newChat['id'] = newId;
      await saveChat(newId, newChat);

      // Import messages for this chat with new IDs
      final messages =
          (messagesMap[oldId] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (int i = 0; i < messages.length; i++) {
        final msg = Map<String, dynamic>.from(messages[i]);
        // Use UUID for message ID to ensure uniqueness
        final newMsgId = const Uuid().v4();
        msg['id'] = newMsgId;
        await saveMessage(newId, newMsgId, msg);
      }

      importedCount++;
    }

    return importedCount;
  }
}
