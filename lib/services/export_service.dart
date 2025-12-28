import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:pocket_prof/providers/chat_provider.dart';

/// Export service for chat conversations - Only Markdown
class ExportService {
  /// Export chat to Markdown and download
  void exportToMarkdown({
    required List<ChatMessage> messages,
    required String title,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('# $title');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    for (final msg in messages) {
      if (msg.isUser) {
        buffer.writeln('## 👤 Kullanıcı');
      } else {
        buffer.writeln('## 🎓 PocketProf');
      }
      buffer.writeln();
      buffer.writeln(msg.content);
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    final bytes = utf8.encode(buffer.toString());
    final blob = web.Blob([bytes.toJS].toJS);
    final url = web.URL.createObjectURL(blob);
    (web.document.createElement('a') as web.HTMLAnchorElement)
      ..href = url
      ..download = '${_sanitizeFileName(title)}.md'
      ..click();
    web.URL.revokeObjectURL(url);
  }

  String _sanitizeFileName(String name) {
    final sanitized = name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();

    if (sanitized.isEmpty) return 'pocketprof_chat';
    return sanitized.length > 50 ? sanitized.substring(0, 50) : sanitized;
  }
}
