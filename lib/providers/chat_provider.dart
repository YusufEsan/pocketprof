import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:pocket_prof/services/llm_service.dart';
import 'package:pocket_prof/services/storage_service.dart';
import 'package:pocket_prof/providers/settings_provider.dart';

/// Chat session model
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String mode;

  ChatSession({
    String? id,
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.mode = 'explain',
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'mode': mode,
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'],
    title: json['title'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
    mode: json['mode'] ?? 'explain',
  );
}

/// Chat message model
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? mode;
  final String? attachmentName; // PDF file name
  final String? attachmentContent; // Hidden content from PDF
  final int? questionCount; // Requested count for quiz/flashcards

  ChatMessage({
    String? id,
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.mode,
    this.attachmentName,
    this.attachmentContent,
    this.questionCount,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  bool get hasAttachment =>
      attachmentName != null && attachmentName!.isNotEmpty;

  /// Get the full content including attachment for AI processing
  String get fullContent {
    if (hasAttachment && attachmentContent != null) {
      return '$attachmentContent\n\nKullanıcı mesajı: $content';
    }
    return content;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'isUser': isUser,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'mode': mode,
    'attachmentName': attachmentName,
    'attachmentContent': attachmentContent,
    'questionCount': questionCount,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    content: json['content'],
    isUser: json['isUser'],
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    mode: json['mode'],
    attachmentName: json['attachmentName'],
    attachmentContent: json['attachmentContent'],
    questionCount: json['questionCount'],
  );
}

/// Chat state
class ChatState {
  final String? currentSessionId;
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String currentMode;
  final List<ChatSession> recentSessions;

  const ChatState({
    this.currentSessionId,
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.currentMode = 'explain',
    this.recentSessions = const [],
  });

  ChatState copyWith({
    Object? currentSessionId = _sentinel,
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? currentMode,
    List<ChatSession>? recentSessions,
  }) {
    return ChatState(
      currentSessionId: currentSessionId == _sentinel
          ? this.currentSessionId
          : currentSessionId as String?,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentMode: currentMode ?? this.currentMode,
      recentSessions: recentSessions ?? this.recentSessions,
    );
  }

  static const _sentinel = Object();

  List<Map<String, String>> get conversationHistory {
    return messages
        .map(
          (m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.content,
          },
        )
        .toList();
  }
}

/// Chat notifier
class ChatNotifier extends StateNotifier<ChatState> {
  final LLMService? _llmService;
  final StorageService _storage;

  ChatNotifier(this._llmService, this._storage) : super(const ChatState()) {
    _loadRecentSessions();
  }

  void _loadRecentSessions() {
    final sessions = _storage
        .getAllChats()
        .map((json) => ChatSession.fromJson(json))
        .toList();
    state = state.copyWith(recentSessions: sessions);
  }

  Future<void> _saveCurrentSession() async {
    if (state.messages.isEmpty) return;

    final sessionId = state.currentSessionId ?? const Uuid().v4();

    // Find first user message for title
    final firstUserMsg = state.messages.firstWhere(
      (m) => m.isUser,
      orElse: () => state.messages.first,
    );

    final title = firstUserMsg.content.split('\n').first;
    final displayTitle = title.length > 50
        ? '${title.substring(0, 50)}...'
        : title;

    // Get existing session data to preserve createdAt
    final existingData = _storage.getChat(sessionId);
    final createdAt = existingData != null
        ? DateTime.fromMillisecondsSinceEpoch(
            existingData['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
          )
        : DateTime.now();

    final session = ChatSession(
      id: sessionId,
      title: displayTitle,
      createdAt: createdAt,
      mode: state.currentMode,
      updatedAt: DateTime.now(),
    );

    await _storage.saveChat(sessionId, session.toJson());

    // Save all messages
    for (final msg in state.messages) {
      await _storage.saveMessage(sessionId, msg.id, msg.toJson());
    }

    if (state.currentSessionId == null) {
      state = state.copyWith(currentSessionId: sessionId);
    }

    _loadRecentSessions();
  }

  /// Load a previous session
  void loadSession(String sessionId) {
    final messages = _storage
        .getMessages(sessionId)
        .map((json) => ChatMessage.fromJson(json))
        .toList();

    final sessionData = _storage.getChat(sessionId);
    final mode = sessionData?['mode'] ?? 'explain';

    state = state.copyWith(
      currentSessionId: sessionId,
      messages: messages,
      currentMode: mode,
      error: null,
    );
  }

  void setMode(String mode) {
    state = state.copyWith(currentMode: mode);
  }

  void clearMessages() {
    state = state.copyWith(currentSessionId: null, messages: [], error: null);
  }

  Future<void> sendMessage(
    String content, {
    String? attachmentName,
    String? attachmentContent,
    int? questionCount,
  }) async {
    if (content.isEmpty && attachmentContent == null) return;

    // Capture the starting session ID
    var effectiveSessionId = state.currentSessionId;

    if (_llmService == null) {
      state = state.copyWith(
        error: 'Lütfen önce Ayarlar\'dan OpenRouter API anahtarınızı girin.',
      );
      return;
    }

    final userMessage = ChatMessage(
      content: content,
      isUser: true,
      mode: state.currentMode,
      attachmentName: attachmentName,
      attachmentContent: attachmentContent,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    // Save immediately so it appears in the sidebar title list
    if (effectiveSessionId == null) {
      await _saveCurrentSession();
      // Update our track ID because _saveCurrentSession sets a new one
      effectiveSessionId = state.currentSessionId;
    }

    try {
      final aiMessageId = const Uuid().v4();
      var currentContent = '';

      final placeholderMessage = ChatMessage(
        id: aiMessageId,
        content: '',
        isUser: false,
        mode: state.currentMode,
        questionCount: questionCount,
        // Ensure assistant message is always "after" user message in sorting
        timestamp: DateTime.now().add(const Duration(milliseconds: 10)),
      );

      state = state.copyWith(
        messages: [...state.messages, placeholderMessage],
        isLoading: true,
      );

      final stopwatch = Stopwatch()..start();
      var lastUpdate = Duration.zero;
      var pendingContent = '';

      // Check if we need to filter conversation history due to mode change
      // Only include messages that match the current mode to prevent format confusion
      List<Map<String, String>> filteredHistory = [];
      final currentMode = state.currentMode;
      
      // If quiz or flashcard mode, don't include previous AI responses from different modes
      if (currentMode == 'quiz' || currentMode == 'flashcard') {
        for (final msg in state.messages.take(10)) {
          if (msg.isUser) {
            filteredHistory.add({'role': 'user', 'content': msg.content});
          } else if (msg.mode == currentMode) {
            // Only include AI responses from the same mode
            filteredHistory.add({'role': 'assistant', 'content': msg.content});
          }
        }
      } else {
        filteredHistory = state.conversationHistory.take(10).toList();
      }

      await for (final chunk in _llmService.streamMessage(
        userMessage: userMessage.fullContent,
        mode: state.currentMode,
        conversationHistory: filteredHistory,
        questionCount: questionCount,
      )) {
        // Safety check: if user switched sessions or cleared, STOP streaming/updating
        if (state.currentSessionId != effectiveSessionId) return;

        pendingContent += chunk;

        if (stopwatch.elapsed - lastUpdate > const Duration(milliseconds: 50)) {
          currentContent += pendingContent;
          pendingContent = '';
          lastUpdate = stopwatch.elapsed;

          final updatedMessages = List<ChatMessage>.from(state.messages);
          if (updatedMessages.isNotEmpty) updatedMessages.removeLast();
          updatedMessages.add(
            ChatMessage(
              id: aiMessageId,
              content: currentContent,
              isUser: false,
              mode: state.currentMode,
              questionCount: questionCount,
              timestamp: placeholderMessage.timestamp,
            ),
          );

          state = state.copyWith(messages: updatedMessages);
        }
      }

      if (pendingContent.isNotEmpty &&
          state.currentSessionId == effectiveSessionId) {
        currentContent += pendingContent;
        final updatedMessages = List<ChatMessage>.from(state.messages);
        if (updatedMessages.isNotEmpty) updatedMessages.removeLast();
        updatedMessages.add(
          ChatMessage(
            id: aiMessageId,
            content: currentContent,
            isUser: false,
            mode: state.currentMode,
            questionCount: questionCount,
            timestamp: placeholderMessage.timestamp,
          ),
        );
        state = state.copyWith(messages: updatedMessages);
      }

      state = state.copyWith(isLoading: false);

      if (state.currentSessionId == effectiveSessionId) {
        await _saveCurrentSession();
      }
    } catch (e) {
      if (state.currentSessionId == effectiveSessionId) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> sendInitialContent(String content, String mode) async {
    state = state.copyWith(currentSessionId: null, messages: []);
    setMode(mode);
    await sendMessage(content);
  }

  Future<void> deleteSession(String sessionId) async {
    await _storage.deleteChat(sessionId);
    if (state.currentSessionId == sessionId) {
      state = state.copyWith(currentSessionId: null, messages: []);
    }
    _loadRecentSessions();
  }

  Map<String, dynamic> exportAllSessions() {
    return _storage.exportAllData();
  }

  Future<int> importSessions(Map<String, dynamic> data) async {
    final count = await _storage.importData(data);
    _loadRecentSessions();
    return count;
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return ChatNotifier(llmService, storage);
});
