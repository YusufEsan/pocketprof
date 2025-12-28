import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pocket_prof/core/constants/app_constants.dart';

/// OCR Service - Web platform için Vision AI kullanarak metin çıkarma
class OCRService {
  final String apiKey;
  
  OCRService({required this.apiKey});
  
  /// Extract text from image using Vision AI
  Future<String> extractText(Uint8List imageBytes, {String language = 'tur+eng'}) async {
    if (apiKey.isEmpty) {
      throw Exception('API key gerekli. Lütfen ayarlardan OpenRouter API key girin.');
    }
    
    try {
      // Convert image to base64
      final base64Image = base64Encode(imageBytes);
      
      // Detect image type
      String mimeType = 'image/jpeg';
      if (imageBytes.length > 4) {
        if (imageBytes[0] == 0x89 && imageBytes[1] == 0x50) {
          mimeType = 'image/png';
        } else if (imageBytes[0] == 0x47 && imageBytes[1] == 0x49) {
          mimeType = 'image/gif';
        }
      }
      
      // Use vision-capable model through OpenRouter
      final response = await http.post(
        Uri.parse('${AppConstants.openRouterBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://pocketprof.app',
          'X-Title': 'PocketProf AI Tutor',
        },
        body: jsonEncode({
          'model': 'google/gemini-2.0-flash-001', // Vision capable model
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Bu görüntüdeki tüm metni aynen oku ve yaz. Sadece görüntüdeki metni ver, başka bir şey ekleme. Eğer metin yoksa veya okunamıyorsa "Metin bulunamadı" yaz.',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:$mimeType;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'temperature': 0.1,
          'max_tokens': 2000,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null && content.toString().isNotEmpty) {
          final text = content.toString().trim();
          if (text == 'Metin bulunamadı' || text.isEmpty) {
            throw Exception('Görüntüden metin çıkarılamadı. Lütfen daha net bir görsel deneyin.');
          }
          return text;
        }
        throw Exception('Görüntüden metin çıkarılamadı.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']?['message'] ?? 'OCR isteği başarısız: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('OCR işlemi sırasında hata: $e');
    }
  }
  
  /// Check if the image is suitable for OCR
  bool isValidImageSize(Uint8List bytes) {
    // Max 10MB for OCR processing
    return bytes.length <= 10 * 1024 * 1024;
  }
}
