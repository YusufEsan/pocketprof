import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocket_prof/core/theme/app_theme.dart';
import 'package:pocket_prof/providers/chat_provider.dart';
import 'package:pocket_prof/models/quiz_model.dart';
import 'package:pocket_prof/models/flashcard_model.dart';
import 'package:pocket_prof/features/quiz/quiz_screen.dart';
import 'package:pocket_prof/features/flashcard/flashcard_screen.dart';

/// Chat message bubble widget with animations and markdown-like rendering
class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onSpeak;
  final int index;
  final bool shouldAnimate;
  final String? searchQuery;
  final bool isHighlighted;
  final int? activeOccurrenceIndex; // Which occurrence in this message is active

  final bool isStreaming;

  const MessageBubble({
    super.key,
    required this.message,
    this.onSpeak,
    this.index = 0,
    this.shouldAnimate = true,
    this.searchQuery,
    this.isHighlighted = false,
    this.activeOccurrenceIndex,
    this.isStreaming = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;
  bool _showAnswers = false; // For quiz answer visibility

  static final _quizAnswerRegex = RegExp(
    r'✅\s*\*?\*?Doğru Cevap:?\*?\*?\s*[A-D]',
    caseSensitive: false,
  );
  static final _explanationRegex = RegExp(
    r'💡\s*\*?\*?Açıklama:?\*?\*?\s*.+',
    caseSensitive: false,
  );
  static final _flashcardBackRegex = RegExp(
    r'\*\*ARKA\s*YÜZ.*?:\*\*\s*.+',
    caseSensitive: false,
  );
  static final _hintRegex = RegExp(
    r'🔗\s*\*?\*?İpucu:?\*?\*?\s*.+',
    caseSensitive: false,
  );
  static final _heading2Regex = RegExp(r'^##\s', multiLine: true);
  static final _heading3Regex = RegExp(r'^###\s', multiLine: true);
  static final _boldItalicRegex = RegExp(r'(\*\*|\*)(.+?)\1');
  static final _numberListRegex = RegExp(r'^(\d+)\. ');

  List<Widget>? _cachedWidgets;
  String? _lastContent;
  bool? _lastShowAnswers;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.shouldAnimate) {
      _controller.forward();
    } else {
      _controller.value = 1.0; // Skip animation
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isUser) {
      return _buildUserMessage(context);
    }
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideIn,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(false),
                const SizedBox(width: 10),
                Flexible(child: _buildMessageContent(context, false)),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserMessage(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 10),
              Flexible(child: _buildMessageContent(context, true)),
              const SizedBox(width: 10),
              _buildAvatar(true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isUser
            ? null
            : LinearGradient(
                colors: [
                  AppTheme.primary,
                  AppTheme.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isUser ? AppTheme.userBubble : null,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isUser ? AppTheme.userBubble : AppTheme.primary).withValues(
              alpha: 0.3,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person : Icons.school,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isUser) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUser ? AppTheme.userBubble : AppTheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 20),
        ),
        border: isUser ? null : Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode badge at top
          if (widget.message.mode != null) ...[
            _buildModeBadge(context, isUser),
            const SizedBox(height: 8),
          ],

          // Attachment card (for PDF)
          if (widget.message.hasAttachment) ...[
            _buildAttachmentCard(context, isUser),
            const SizedBox(height: 8),
          ],

          // Rendered content
          isUser
              ? (widget.searchQuery != null && widget.searchQuery!.isNotEmpty
                  ? _buildHighlightedText(context, widget.message.content, widget.searchQuery!)
                  : SelectableText(
                      widget.message.content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ))
              : _buildFormattedContent(context),

          // Action buttons for AI
          if (!isUser) ...[
            const SizedBox(height: 12),
            _buildActionBar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildModeBadge(BuildContext context, bool isUser) {
    final modeLabels = {
      'explain': 'Konu Anlatımı',
      'summary': 'Özet Çıkarma',
      'quiz': 'Sınav Sorusu',
      'flashcard': 'Hatırlatma Kartı',
    };

    final modeIcons = {
      'explain': Icons.school,
      'summary': Icons.summarize,
      'quiz': Icons.quiz,
      'flashcard': Icons.style,
    };

    final mode = widget.message.mode ?? 'explain';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withValues(alpha: 0.2)
            : AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            modeIcons[mode] ?? Icons.school,
            size: 12,
            color: isUser
                ? Colors.white.withValues(alpha: 0.9)
                : AppTheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            modeLabels[mode] ?? 'Konu Anlatımı',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isUser
                  ? Colors.white.withValues(alpha: 0.9)
                  : AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(BuildContext context, bool isUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withValues(alpha: 0.15)
            : AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUser
              ? Colors.white.withValues(alpha: 0.3)
              : AppTheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 16,
            color: isUser ? Colors.white : AppTheme.error,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.message.attachmentName!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isUser
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(BuildContext context) {
    final currentContent = widget.message.content;

    // Skip memoization when search is active (need to re-render highlights)
    final hasActiveSearch = widget.searchQuery != null && widget.searchQuery!.isNotEmpty;

    // Memoization check: Only re-parse if content or answer toggle changed
    if (!hasActiveSearch && 
        _cachedWidgets != null &&
        _lastContent == currentContent &&
        _lastShowAnswers == _showAnswers) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _cachedWidgets!,
      );
    }

    String content = currentContent;

    // If quiz/flashcard mode and answers should be hidden, mask the contents
    if ((widget.message.mode == 'quiz' || widget.message.mode == 'flashcard') && !_showAnswers) {
      if (widget.message.mode == 'quiz') {
        // Hide ✅ **Doğru Cevap:** X lines
        content = content.replaceAllMapped(
          _quizAnswerRegex,
          (match) => '✅ **Doğru Cevap:** •••',
        );
        // Hide 💡 **Açıklama:** lines
        content = content.replaceAllMapped(
          _explanationRegex,
          (match) => '💡 **Açıklama:** ••••••••••••••••',
        );
      } else {
        // Flashcard mode
        // Hide **ARKA YÜZ:** lines
        content = content.replaceAllMapped(
          _flashcardBackRegex,
          (match) => '**ARKA YÜZ:** ••••••••••••••••',
        );
        // Hint will remain visible as per user request
      }
    }

    final lines = content.split('\n');
    final widgets = lines.map((line) => _buildLine(context, line)).toList();

    _cachedWidgets = widgets;
    _lastContent = currentContent;
    _lastShowAnswers = _showAnswers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildLine(BuildContext context, String line) {
    final trimmedLine = line.trim();
    if (trimmedLine.isEmpty) return const SizedBox(height: 8);

    // Fast string checks instead of regex for headings
    if (trimmedLine.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(
          trimmedLine.substring(3),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      );
    }

    if (trimmedLine.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                trimmedLine.substring(4),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Important note: 💡 **Önemli:**
    if (line.contains('💡') ||
        line.contains('**Önemli:**') ||
        line.contains('**Dikkat:**')) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💡', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStyledText(
                context,
                line.replaceAll('💡', '').trim(),
              ),
            ),
          ],
        ),
      );
    }

    // Bullet points: - or *
    if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, right: 8),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: _buildStyledText(context, line.trim().substring(2)),
            ),
          ],
        ),
      );
    }

    // Numbered list
    final numberMatch = _numberListRegex.firstMatch(line.trim());
    if (numberMatch != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  numberMatch.group(1)!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _buildStyledText(
                context,
                line.trim().substring(numberMatch.end),
              ),
            ),
          ],
        ),
      );
    }

    // Regular text with bold/italic support
    if (line.trim().isEmpty) {
      return const SizedBox(height: 8);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: _buildStyledText(context, line),
    );
  }

  Widget _buildStyledText(BuildContext context, String text) {
    // If there's a search query, highlight it
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      return _buildHighlightedText(context, text, widget.searchQuery!);
    }

    // Parse **bold** and *italic* text
    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in _boldItalicRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      final marker = match.group(1);
      final content = match.group(2);

      spans.add(
        TextSpan(
          text: content,
          style: TextStyle(
            fontWeight: marker == '**' ? FontWeight.bold : null,
            fontStyle: marker == '*' ? FontStyle.italic : null,
          ),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          height: 1.6,
        ),
        children: spans.isEmpty ? [TextSpan(text: text)] : spans,
      ),
    );
  }

  Widget _buildHighlightedText(BuildContext context, String text, String query) {
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int lastEnd = 0;
    int currentOccurrence = 0;

    int start = lowerText.indexOf(lowerQuery);
    while (start != -1) {
      // Add text before match
      if (start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, start)));
      }

      // Determine if this is the active occurrence
      final isActiveOccurrence = widget.isHighlighted && 
          widget.activeOccurrenceIndex != null &&
          currentOccurrence == widget.activeOccurrenceIndex;

      // Add highlighted match
      spans.add(
        TextSpan(
          text: text.substring(start, start + query.length),
          style: TextStyle(
            backgroundColor: isActiveOccurrence
                ? Colors.orange.withValues(alpha: 0.6)  // Active occurrence
                : Colors.yellow.withValues(alpha: 0.4), // Other occurrences
            fontWeight: FontWeight.w600,
            color: widget.message.isUser ? Colors.white : null,
          ),
        ),
      );

      currentOccurrence++;
      lastEnd = start + query.length;
      start = lowerText.indexOf(lowerQuery, lastEnd);
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: widget.message.isUser 
              ? Colors.white 
              : Theme.of(context).textTheme.bodyLarge?.color,
          height: 1.6,
        ),
        children: spans.isEmpty ? [TextSpan(text: text)] : spans,
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    final isQuizMode = widget.message.mode == 'quiz';
    final isFlashcardMode = widget.message.mode == 'flashcard';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Listen button
            if (widget.onSpeak != null) ...[
              _buildActionButton(
                icon: Icons.volume_up,
                label: 'Dinle',
                onTap: widget.onSpeak!,
              ),
              const SizedBox(width: 8),
            ],
            // Copy button
            _buildActionButton(
              icon: Icons.copy_outlined,
              label: 'Kopyala',
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.message.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Metin kopyalandı'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            // Answer visibility toggle
            if (isQuizMode || isFlashcardMode) ...[
              const SizedBox(width: 8),
              _buildActionButton(
                icon: _showAnswers ? Icons.visibility : Icons.visibility_off,
                label: _showAnswers ? 'Cevapları Gizle' : 'Cevapları Göster',
                onTap: () => setState(() => _showAnswers = !_showAnswers),
              ),
            ],
          ],
        ),
        // Quiz start button
        if (isQuizMode) ...[
          const SizedBox(height: 12),
          AbsorbPointer(
            absorbing: widget.isStreaming,
            child: Opacity(
              opacity: widget.isStreaming ? 0.3 : 1.0,
              child: ColorFiltered(
                colorFilter: widget.isStreaming 
                    ? const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0,      0,      0,      1, 0,
                      ])
                    : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: InkWell(
                  onTap: widget.isStreaming ? null : () => _startQuiz(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary,
                          AppTheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: widget.isStreaming ? null : [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          widget.isStreaming ? 'Hazırlanıyor...' : 'Quiz\'i Başlat',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        // Flashcard start button
        if (isFlashcardMode) ...[
          const SizedBox(height: 12),
          AbsorbPointer(
            absorbing: widget.isStreaming,
            child: Opacity(
              opacity: widget.isStreaming ? 0.3 : 1.0,
              child: ColorFiltered(
                colorFilter: widget.isStreaming 
                    ? const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0,      0,      0,      1, 0,
                      ])
                    : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: InkWell(
                  onTap: widget.isStreaming ? null : () => _startFlashcards(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple, Colors.purple.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: widget.isStreaming ? null : [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.style, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          widget.isStreaming ? 'Hazırlanıyor...' : 'Kartları Başlat',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _startQuiz(BuildContext context) {
    try {
      var questions = QuizParser.parse(widget.message.content);

      // Strict enforcement of requested count
      if (widget.message.questionCount != null &&
          questions.length > widget.message.questionCount!) {
        questions = questions.take(widget.message.questionCount!).toList();
      }

      if (questions.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Quiz soruları bulunamadı')));
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => QuizScreen(questions: questions)),
      );
    } catch (e) {
      debugPrint('Quiz start error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quiz başlatılamadı: $e')),
        );
      }
    }
  }

  void _startFlashcards(BuildContext context) {
    try {
      var cards = FlashcardParser.parse(widget.message.content);

      // Strict enforcement of requested count
      if (widget.message.questionCount != null &&
          cards.length > widget.message.questionCount!) {
        cards = cards.take(widget.message.questionCount!).toList();
      }

      if (cards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hatırlatma kartları bulunamadı')),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => FlashcardScreen(cards: cards)),
      );
    } catch (e) {
      debugPrint('Flashcard start error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kartlar başlatılamadı: $e')),
        );
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
