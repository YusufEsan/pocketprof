import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as markdown;
import 'package:pocket_prof/core/theme/app_theme.dart';
import 'package:pocket_prof/models/quiz_model.dart';

/// Interactive Quiz Screen with Modern Animations
class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;

  const QuizScreen({super.key, required this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _answered = false;
  final List<QuizAnswer> _answers = [];

  late AnimationController _cardAnimController;
  late AnimationController _optionAnimController;
  late Animation<double> _cardScaleAnim;
  late Animation<double> _cardFadeAnim;
  late Animation<Offset> _cardSlideAnim;

  @override
  void initState() {
    super.initState();
    _cardAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _optionAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardScaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimController, curve: Curves.elasticOut),
    );
    _cardFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimController, curve: Curves.easeOut),
    );
    _cardSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _cardAnimController,
            curve: Curves.easeOutCubic,
          ),
        );

    _cardAnimController.forward();
    _optionAnimController.forward();
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    _optionAnimController.dispose();
    super.dispose();
  }

  QuizQuestion get currentQuestion => widget.questions[_currentIndex];
  bool get isLastQuestion => _currentIndex == widget.questions.length - 1;

  void _selectAnswer(String letter) {
    if (_answered) return;

    setState(() {
      _selectedAnswer = letter;
      _answered = true;
      _answers.add(
        QuizAnswer(
          questionNumber: currentQuestion.number,
          selectedAnswer: letter,
          correctAnswer: currentQuestion.correctAnswer,
          isCorrect: letter == currentQuestion.correctAnswer,
        ),
      );
    });
  }

  void _nextQuestion() {
    if (isLastQuestion) {
      _showResults();
    } else {
      _cardAnimController.reset();
      _optionAnimController.reset();
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
      _cardAnimController.forward();
      _optionAnimController.forward();
    }
  }

  void _showResults() {
    final result = QuizResult(
      totalQuestions: widget.questions.length,
      correctCount: _answers.where((a) => a.isCorrect).length,
      wrongCount: _answers.where((a) => !a.isCorrect).length,
      answers: _answers,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Quiz Result',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: FadeTransition(
            opacity: anim1,
            child: _QuizResultDialog(
              result: result,
              onClose: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  Color _getOptionColor(String letter) {
    if (!_answered) {
      return _selectedAnswer == letter
          ? AppTheme.primary.withValues(alpha: 0.15)
          : Theme.of(context).colorScheme.surface;
    }

    if (letter == currentQuestion.correctAnswer) {
      return Colors.green.withValues(alpha: 0.15);
    }

    if (letter == _selectedAnswer && letter != currentQuestion.correctAnswer) {
      return Colors.red.withValues(alpha: 0.15);
    }

    return Theme.of(context).colorScheme.surface;
  }

  Color _getOptionBorderColor(String letter) {
    if (!_answered) {
      return _selectedAnswer == letter
          ? AppTheme.primary
          : Theme.of(context).dividerColor;
    }

    if (letter == currentQuestion.correctAnswer) {
      return Colors.green;
    }

    if (letter == _selectedAnswer && letter != currentQuestion.correctAnswer) {
      return Colors.red;
    }

    return Theme.of(context).dividerColor;
  }

  IconData? _getOptionIcon(String letter) {
    if (!_answered) return null;

    if (letter == currentQuestion.correctAnswer) {
      return Icons.check_circle;
    }

    if (letter == _selectedAnswer && letter != currentQuestion.correctAnswer) {
      return Icons.cancel;
    }

    return null;
  }

  /// Parse markdown bold (**text**) and italic (*text*) and return RichText widget
  Widget _buildQuestionText(BuildContext context, String text) {
    final spans = <TextSpan>[];
    // Pattern to match **bold** OR *italic*
    // Group 1: marker (** or *)
    // Group 2: content
    final regex = RegExp(r'(\*\*|\*)(.+?)\1');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add normal text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      final marker = match.group(1);
      final content = match.group(2);

      // Add styled text
      spans.add(
        TextSpan(
          text: content,
          style: TextStyle(
            fontWeight: marker == '**' ? FontWeight.w800 : null,
            fontStyle: marker == '*' ? FontStyle.italic : null,
          ),
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    // If no matches, just return plain text
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              Icons.close,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Quiz',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.2),
                  AppTheme.primary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentIndex + 1}/${widget.questions.length}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Animated progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0,
                  end: (_currentIndex + 1) / widget.questions.length,
                ),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: Theme.of(context).dividerColor,
                    valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                    minHeight: 8,
                  );
                },
              ),
            ),
          ),

          // Question card with animation
          Expanded(
            child: SlideTransition(
              position: _cardSlideAnim,
              child: FadeTransition(
                opacity: _cardFadeAnim,
                child: ScaleTransition(
                  scale: _cardScaleAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.surface,
                                Theme.of(
                                  context,
                                ).colorScheme.surface.withValues(alpha: 0.95),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Difficulty badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getDifficultyColor(
                                        currentQuestion.difficulty,
                                      ),
                                      _getDifficultyColor(
                                        currentQuestion.difficulty,
                                      ).withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getDifficultyColor(
                                        currentQuestion.difficulty,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  currentQuestion.difficulty,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Question number
                              Text(
                                'Soru ${_currentIndex + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Question text with markdown support
                              _buildQuestionText(
                                context,
                                currentQuestion.question,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Options with staggered animation
                        ...currentQuestion.options.asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                milliseconds: 300 + (index * 100),
                              ),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(50 * (1 - value), 0),
                                  child: Opacity(
                                    opacity: value,
                                    child: _buildOptionCard(option),
                                  ),
                                );
                              },
                            ),
                          );
                        }),

                        // Explanation with animation
                        if (_answered && currentQuestion.explanation.isNotEmpty)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 0.9 + (0.1 * value),
                                child: Opacity(
                                  opacity: value,
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.blue.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.lightbulb,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Açıklama',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              markdown.MarkdownBody(
                                                data:
                                                    currentQuestion.explanation,
                                                styleSheet:
                                                    markdown.MarkdownStyleSheet(
                                                      p: Theme.of(
                                                        context,
                                                      ).textTheme.bodyMedium,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                        // Next button
                        if (_answered)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: ElevatedButton(
                                      onPressed: _nextQuestion,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 8,
                                        shadowColor: AppTheme.primary
                                            .withValues(alpha: 0.4),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            isLastQuestion
                                                ? 'Sonuçları Gör'
                                                : 'Sonraki Soru',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            isLastQuestion
                                                ? Icons.emoji_events
                                                : Icons.arrow_forward,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(QuizOption option) {
    final icon = _getOptionIcon(option.letter);
    final isCorrect =
        _answered && option.letter == currentQuestion.correctAnswer;
    final isWrong = _answered && option.letter == _selectedAnswer && !isCorrect;

    return InkWell(
      onTap: () => _selectAnswer(option.letter),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _getOptionColor(option.letter),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getOptionBorderColor(option.letter),
            width: 2,
          ),
          boxShadow: [
            if (isCorrect || isWrong)
              BoxShadow(
                color: (isCorrect ? Colors.green : Colors.red).withValues(
                  alpha: 0.2,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isCorrect || isWrong
                    ? LinearGradient(
                        colors: isCorrect
                            ? [Colors.green, Colors.green.shade400]
                            : [Colors.red, Colors.red.shade400],
                      )
                    : null,
                color: isCorrect || isWrong
                    ? null
                    : _getOptionBorderColor(
                        option.letter,
                      ).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: icon != null
                    ? Icon(icon, color: Colors.white, size: 20)
                    : Text(
                        option.letter,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isCorrect || isWrong
                              ? Colors.white
                              : _getOptionBorderColor(option.letter),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                option.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isCorrect || isWrong ? FontWeight.w600 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'kolay':
        return Colors.green;
      case 'orta':
        return Colors.orange;
      case 'zor':
        return Colors.red;
      default:
        return AppTheme.primary;
    }
  }
}

/// Modern Quiz result dialog - wider and horizontal
class _QuizResultDialog extends StatelessWidget {
  final QuizResult result;
  final VoidCallback onClose;

  const _QuizResultDialog({required this.result, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isSuccess = result.percentage >= 60;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          constraints: const BoxConstraints(maxWidth: 650),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Side: Percentage
                      Expanded(
                        flex: 1,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: result.percentage),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 180,
                                  height: 180,
                                  child: CircularProgressIndicator(
                                    value: value / 100,
                                    strokeWidth: 16,
                                    backgroundColor: Colors.grey.shade100,
                                    valueColor: AlwaysStoppedAnimation(
                                      isSuccess ? Colors.green : Colors.orange,
                                    ),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Text(
                                  '%${value.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                    color: isSuccess
                                        ? Colors.green
                                        : Colors.orange,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 40),
                      // Right Side: Title and Stats
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSuccess ? 'Harika İş! 🎉' : 'İyi Deneme! 💪',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${result.correctCount}/${result.totalQuestions} Soru doğru cevaplandı.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildStatCard(
                              context,
                              icon: Icons.check_circle,
                              value: '${result.correctCount}',
                              label: 'Doğru Cevap',
                              color: Colors.green,
                            ),
                            const SizedBox(height: 12),
                            _buildStatCard(
                              context,
                              icon: Icons.cancel,
                              value: '${result.wrongCount}',
                              label: 'Yanlış Cevap',
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Close button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onClose,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                        ),
                        child: const Text(
                          'Sohbete Dön',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
