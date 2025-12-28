import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pocket_prof/core/constants/app_constants.dart';

/// Service for interacting with OpenRouter API (LLM)
class LLMService {
  final String apiKey;
  final String model;

  LLMService({required this.apiKey, this.model = AppConstants.defaultModel});

  /// Available teaching modes
  static const Map<String, String> modes = {
    'explain': 'Konu Anlatımı',
    'summary': 'Özet Çıkarma',
    'quiz': 'Sınav Sorusu',
    'flashcard': 'Flashcard',
  };

  /// Get system prompt based on mode
  String _getSystemPrompt(String mode, {int? questionCount}) {
    String prompt;
    switch (mode) {
      case 'summary':
        prompt = AppConstants.summaryPrompt;
        break;
      case 'quiz':
        prompt = AppConstants.quizPrompt;
        break;
      case 'flashcard':
        prompt = AppConstants.flashcardPrompt;
        break;
      case 'explain':
      default:
        prompt = AppConstants.teacherSystemPrompt;
        break;
    }

    if (questionCount != null && (mode == 'quiz' || mode == 'flashcard')) {
      prompt +=
          "\n\nKRİTİK TALİMAT: Tam olarak $questionCount adet ${mode == 'quiz' ? 'soru' : 'flashcard'} oluşturmalısın. Ne eksik ne fazla.";
    }

    prompt +=
        "\n\nÖNEMLİ: Sana birden fazla kaynak/dosya içeriği verilmişse, lütfen TÜM kaynakları dikkatle incele ve yanıtını tüm bu bilgileri harmanlayarak oluştur. Sadece bir kaynağa odaklanma.";

    return prompt;
  }

  Future<String> sendMessage({
    required String userMessage,
    String mode = 'explain',
    List<Map<String, String>>? conversationHistory,
    int? questionCount,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception(
        'API key is required. Please set your OpenRouter API key in settings.',
      );
    }

    final systemPrompt = _getSystemPrompt(mode, questionCount: questionCount);

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    // Add conversation history if provided
    if (conversationHistory != null) {
      messages.addAll(conversationHistory);
    }

    // Add current user message
    messages.add({'role': 'user', 'content': userMessage});

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.openRouterBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://pocketprof.app',
          'X-Title': 'PocketProf AI Tutor',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 8000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null) {
          return content as String;
        }
        throw Exception('Invalid response format from OpenRouter');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['error']?['message'] ??
              'API request failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  Stream<String> streamMessage({
    required String userMessage,
    String mode = 'explain',
    List<Map<String, String>>? conversationHistory,
    int? questionCount,
  }) async* {
    if (apiKey.isEmpty) {
      throw Exception(
        'API key is required. Please set your OpenRouter API key in settings.',
      );
    }

    final systemPrompt = _getSystemPrompt(mode, questionCount: questionCount);
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    if (conversationHistory != null) {
      messages.addAll(conversationHistory);
    }
    messages.add({'role': 'user', 'content': userMessage});

    final request = http.Request(
      'POST',
      Uri.parse('${AppConstants.openRouterBaseUrl}/chat/completions'),
    );
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'HTTP-Referer': 'https://pocketprof.app',
      'X-Title': 'PocketProf AI Tutor',
    });

    // Enable streaming
    request.body = jsonEncode({
      'model': model,
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 8000,
      'stream': true,
    });

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        try {
          final error = jsonDecode(body);
          throw Exception(
            error['error']?['message'] ??
                'API request failed: ${response.statusCode}',
          );
        } catch (_) {
          throw Exception('API request failed: ${response.statusCode}');
        }
      }

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data);
            final content = json['choices']?[0]?['delta']?['content'];
            if (content != null) {
              yield content;
            }
          } catch (e) {
            // Ignore parse errors for incomplete chunks
          }
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error during streaming: $e');
    } finally {
      client.close();
    }
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      final response = await sendMessage(
        userMessage: 'Merhaba, kısa bir test mesajı.',
        mode: 'explain',
      );
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
