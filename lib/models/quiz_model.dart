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
    // More flexible pattern to find question starts
    final questionStartPattern = RegExp(
      r'(?:^|\n)(?:[\#\*\-\s\d\w\.]+)?(?:❓?\s*)?(?:Soru|Question)\s*(\d+)[:.)]?\s*',
      caseSensitive: false,
      multiLine: true,
    );

    var matches = questionStartPattern.allMatches(cleanContent).toList();

    // Fallback 1: Try just numbers at start of lines e.g. "1. ", "1) ", "1: ", "1- "
    if (matches.isEmpty) {
      final fallbackStart = RegExp(
        r'(?:^|\n)\s*(?:\*\*|[\#\-\s])*(\d+)[\.)\-:]\s+',
        multiLine: true,
      );
      matches = fallbackStart.allMatches(cleanContent).toList();
    }
    
    // Fallback 2: Try "### 1" or "## 1"
    if (matches.isEmpty) {
      final headerStart = RegExp(
        r'(?:^|\n)\s*#{1,6}\s*(\d+)\s*',
        multiLine: true,
      );
      matches = headerStart.allMatches(cleanContent).toList();
    }

    // Fallback 3: Just look for bolded numbers like **1.**
    if (matches.isEmpty) {
      final boldNumberStart = RegExp(
        r'(?:^|\n)\s*\*\*(\d+)[\.)]\*\*',
        multiLine: true,
      );
      matches = boldNumberStart.allMatches(cleanContent).toList();
    }

    matches.sort((a, b) => a.start.compareTo(b.start));

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

    // 2. Identify the boundary where options end (Answer or Explanation section)
    final answerSectionStart = block.indexOf(RegExp(
      r'✅|Doğru\s*Cevap|Correct\s*Answer|Cevap|Answer|Doğru|💡|Açıklama|Explain',
      caseSensitive: false,
    ));

    // 3. Options location - support A), A., A-, (A)
    final optionPattern = RegExp(
      r'(?:\n|\s)[\*\-\s]*\(?([A-D])[\.)\-\s]', 
      caseSensitive: false, 
    );
    
    // Only find options before the answer section starts
    final allMatches = optionPattern.allMatches(block);
    final allOptionMatches = allMatches.where((m) {
      return answerSectionStart == -1 || m.start < answerSectionStart;
    }).toList();

    if (allOptionMatches.isEmpty) return null;

    // Question text cleanup - remove common difficulty markers like [Zorluk: ...], (Kolay), **(Zor)** etc.
    String questionText = block
        .substring(0, allOptionMatches.first.start)
        .replaceAll(
          RegExp(r'\**\s*[\(\[]?\s*(?:Zorluk:?\s*)?(?:Kolay|Orta|Zor)\s*[\]\)]?\s*\**', caseSensitive: false),
          '',
        )
        .trim();
    
    // Final cleanup of any lingering labels (e.g., "Soru 1:")
    questionText = _cleanText(questionText);

    // 4. Extract options
    final options = <QuizOption>[];
    for (int j = 0; j < allOptionMatches.length; j++) {
      final m = allOptionMatches[j];
      final start = m.end;
      final end = j + 1 < allOptionMatches.length
          ? allOptionMatches[j + 1].start
          : (answerSectionStart != -1 ? answerSectionStart : block.length);

      String optContent = block.substring(start, end);
      // Strip any lingering markers just in case
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
      r'(?:✅|Doğru\s*Cevap|Correct\s*Answer|Cevap|Answer|Doğru)[:\s\*-]*\s*([A-D])(?!\w)',
      caseSensitive: false,
    ).firstMatch(block);

    if (explicitMatch != null) {
      correctAnswer = explicitMatch.group(1)!.toUpperCase();
    } else {
      // Priority 2: Look for bolded letter e.g. **A** or **A)**
      final boldMatch = RegExp(r'\*\*\(?([A-D])[\)\.]?\*\*').firstMatch(block);
      if (boldMatch != null) {
        correctAnswer = boldMatch.group(1)!.toUpperCase();
      } else {
        // Priority 3: Look for something like (B) or [B] in the text
        final parenMatch = RegExp(r'[\(\[]([A-D])[\]\)]').firstMatch(block);
        if (parenMatch != null) {
          correctAnswer = parenMatch.group(1)!.toUpperCase();
        }
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
    // Uses \b to avoid matching part of a word (e.g. "Sorunu" vs "Soru")
    final labelPattern = RegExp(
      r'^(?:[^\w\s]*(?:ÖN\s*YÜZ|ARKA\s*YÜZ|Soru\/Kavram|Soru|Kavram|Cevap|Açıklama|İpucu|Front|Back|Hint|Zorluk)\b(?:\s*\d+)?[:\s\)\*\_]+)+',
      caseSensitive: false,
    );

    result = result.replaceFirst(labelPattern, '').trim();

    final symbolsToRemove = [
      '**',
      '*',
      '_',
      ':',
      '💭',
      '❓',
      '✅',
      '💡',
      '🔗',
      '#',
      '-',
      '.',
      ' ',
      '🗓️',
      '🎴',
    ];

    bool changed = true;
    while (changed) {
      changed = false;
      for (final symbol in symbolsToRemove) {
        if (result.startsWith(symbol)) {
          result = result.substring(symbol.length).trim();
          changed = true;
        }
        if (result.endsWith(symbol)) {
          result = result.substring(0, result.length - symbol.length).trim();
          changed = true;
        }
      }
    }

    // Final cleanup of common leading punctuation
    while (result.isNotEmpty && r'*_:-. '.contains(result[0])) {
      result = result.substring(1).trim();
    }
    return result;
  }
}
