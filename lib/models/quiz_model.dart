/// Quiz question model
class QuizQuestion {
  final int number;
  final String difficulty;
  final String question;
  final List<QuizOption> options;
  final String correctAnswer;
  final String explanation;

  QuizQuestion({
    required this.number,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  String get correctOptionLetter {
    for (var opt in options) {
      if (opt.letter == correctAnswer) return opt.letter;
    }
    return correctAnswer;
  }
}

/// Quiz option model
class QuizOption {
  final String letter;
  final String text;

  QuizOption({required this.letter, required this.text});
}

/// Quiz result model
class QuizResult {
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final List<QuizAnswer> answers;

  QuizResult({
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.answers,
  });

  double get percentage =>
      totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0;
}

class QuizAnswer {
  final int questionNumber;
  final String selectedAnswer;
  final String correctAnswer;
  final bool isCorrect;

  QuizAnswer({
    required this.questionNumber,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });
}

/// Quiz parser - parses AI response into quiz questions
class QuizParser {
  /// Parse AI quiz response into list of questions
  static List<QuizQuestion> parse(String content) {
    final questions = <QuizQuestion>[];

    // 1. Clean content from code blocks
    String cleanContent = content.replaceAll(
      RegExp(r'```.*?(\n|$)', dotAll: false),
      '',
    );
    cleanContent = cleanContent.replaceAll('```', '');

    // 2. Identify question blocks
    // Pattern to find the start of a question
    final questionStartPattern = RegExp(
      r'(?:^|\n)(?:[\#\*\-\s]*)(?:❓?\s*)?(?:Soru\s*)?(\d+)[:.)]?\s*',
      caseSensitive: false,
      multiLine: true,
    );

    final matches = questionStartPattern.allMatches(cleanContent).toList();

    // Fallback: if no "Soru" markers, try just numbers at start of lines
    if (matches.isEmpty) {
      final fallbackStart = RegExp(
        r'(?:^|\n)(?:\*\*|\s)*(\d+)[\.)]\s+',
        multiLine: true,
      );
      matches.addAll(fallbackStart.allMatches(cleanContent));
      matches.sort((a, b) => a.start.compareTo(b.start));
    }

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final startIndex = match.end;
      final endIndex = i + 1 < matches.length
          ? matches[i + 1].start
          : cleanContent.length;

      final block = cleanContent.substring(startIndex, endIndex).trim();
      if (block.length < 10) continue;

      final question = _parseQuestionBlock(
        int.tryParse(match.group(1) ?? '') ?? (i + 1),
        block,
      );

      if (question != null) {
        questions.add(question);
      }
    }

    return questions;
  }

  static QuizQuestion? _parseQuestionBlock(int number, String block) {
    // 1. Difficulty
    final difficultyMatch = RegExp(
      r'\[?Zorluk:?\s*(Kolay|Orta|Zor)\]?',
      caseSensitive: false,
    ).firstMatch(block);
    final difficulty = difficultyMatch?.group(1) ?? 'Orta';

    // 2. Options location
    final optionPattern = RegExp(r'(?:^|\n)\s*([A-D])[\.)\)]', multiLine: true);
    final allOptionMatches = optionPattern.allMatches(block).toList();

    if (allOptionMatches.isEmpty) return null;

    // Question text cleanup
    String questionText = block
        .substring(0, allOptionMatches.first.start)
        .replaceAll(
          RegExp(r'\[?Zorluk:?\s*(Kolay|Orta|Zor)\]?', caseSensitive: false),
          '',
        )
        .trim();
    questionText = _cleanText(questionText);

    // 3. Extract options
    final options = <QuizOption>[];
    for (int j = 0; j < allOptionMatches.length; j++) {
      final m = allOptionMatches[j];
      final start = m.end;
      final end = j + 1 < allOptionMatches.length
          ? allOptionMatches[j + 1].start
          : block.length;

      String optContent = block.substring(start, end);
      // Added 'Cevap' and 'Answer' to marker list to better strip them from options
      final markerIndex = optContent.indexOf(
        RegExp(
          r'✅|Correct|Doğru|💡|Açıklama|Explain|Cevap|Answer',
          caseSensitive: false,
        ),
      );
      if (markerIndex != -1) {
        optContent = optContent.substring(0, markerIndex);
      }

      options.add(
        QuizOption(
          letter: m.group(1)!.toUpperCase(),
          text: _cleanText(optContent),
        ),
      );
    }

    // 4. Correct Answer
    String correctAnswer = '';
    // Priority 1: Explicit markers (Doğru Cevap, etc)
    final explicitMatch = RegExp(
      r'(?:✅|Doğru Cevap|Correct Answer)[:\s\*-]*([A-D])(?!\w)',
      caseSensitive: false,
    ).firstMatch(block);

    if (explicitMatch != null) {
      // Prioritize explicit "Doğru Cevap: X"
      correctAnswer = explicitMatch.group(1)!.toUpperCase();
    } else {
      // Priority 2: Generic "Cevap: X" - be careful not to match random text
      final genericMatch = RegExp(
        r'(?:Cevap|Answer)[:\s\*-]*([A-D])(?!\w)',
        caseSensitive: false,
      ).firstMatch(block);
      if (genericMatch != null) {
        correctAnswer = genericMatch.group(1)!.toUpperCase();
      } else if (block.contains(RegExp(r'\*\*([A-D])\)\*\*'))) {
        // Priority 3: Bolded option e.g. **A)**
        correctAnswer = RegExp(
          r'\*\*([A-D])\)\*\*',
        ).firstMatch(block)!.group(1)!;
      }
    }

    // 5. Explanation cleanup
    String explanation = '';
    final explainMatch = RegExp(
      r'(?:💡|Açıklama|Neden)[:\s*]*(.+?)(?=\n\s*(?:###|Soru|\d+[\.)]|$))',
      dotAll: true,
      caseSensitive: false,
    ).firstMatch(block);
    if (explainMatch != null) {
      explanation = _cleanText(explainMatch.group(1)!);
    }

    if (questionText.isEmpty || options.isEmpty || correctAnswer.isEmpty)
      return null;

    return QuizQuestion(
      number: number,
      difficulty: difficulty,
      question: questionText,
      options: options,
      correctAnswer: correctAnswer,
      explanation: explanation,
    );
  }

  static String _cleanText(String text) {
    String result = text.trim();

    // Comprehensive label removal regex
    final labelPattern = RegExp(
      r'^(?:(?:\*\*|[\(\)\s\_])*(?:ÖN\s*YÜZ|ARKA\s*YÜZ|Soru\/Kavram|Soru|Kavram|Cevap|Açıklama|İpucu|Front|Back|Hint|Zorluk)[^:]*?[:\s\)\*\_]+)+',
      caseSensitive: false,
    );

    result = result.replaceFirst(labelPattern, '').trim();

    final prefixesToRemove = [
      '**',
      '*',
      '_',
      ':',
      '💭',
      '❓',
      '✅',
      '💡',
      '🔗',
      '(',
      ')',
      '.',
      ' ',
      '🗓️',
    ];

    bool changed = true;
    while (changed) {
      changed = false;
      for (final prefix in prefixesToRemove) {
        if (result.startsWith(prefix)) {
          result = result.substring(prefix.length).trim();
          changed = true;
        }
        if (result.endsWith(prefix)) {
          result = result.substring(0, result.length - prefix.length).trim();
          changed = true;
        }
      }
    }

    result = result
        .replaceFirst(
          RegExp(r'^[^\w\p{L}\d\s\u{1F300}-\u{1F9FF}]+', unicode: true),
          '',
        )
        .trim();
    return result;
  }
}
