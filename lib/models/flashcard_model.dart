/// Flashcard model
class Flashcard {
  final int number;
  final String front;
  final String back;
  final String? hint;
  
  Flashcard({
    required this.number,
    required this.front,
    required this.back,
    this.hint,
  });
}

/// Flashcard parser - parses AI response into flashcards
class FlashcardParser {
  /// Parse AI flashcard response into list of cards
  static List<Flashcard> parse(String content) {
    final cards = <Flashcard>[];
    
    // 1. Clean content from code blocks
    String cleanContent = content.replaceAll(RegExp(r'```.*?(\n|$)', dotAll: false), '');
    
    // 2. Identify card blocks
    final cardStartPattern = RegExp(
      r'(?:^|\n)(?:[\#\*\-\s\d\w\.]+)?(?:🎴?\s*)?(?:Kart|Card)\s*(\d+)[:.)]?\s*',
      caseSensitive: false,
      multiLine: true,
    );
    
    var matches = cardStartPattern.allMatches(cleanContent).toList();
    
    // Fallback: If no "Kart" markers, try just numbers at start of lines
    if (matches.isEmpty) {
      final fallbackStart = RegExp(
        r'(?:^|\n)\s*(?:\*\*|[\#\-\s])*(\d+)[\.)\-:]\s+',
        multiLine: true,
      );
      matches = fallbackStart.allMatches(cleanContent).toList();
    }
    
    // Fallback 2: Just look for bolded numbers like **1.**
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
      if (block.length < 5) continue;

      final card = _parseCardBlock(
        int.tryParse(match.group(1) ?? '') ?? (i + 1),
        block,
      );
      
      if (card != null) {
        cards.add(card);
      }
    }
    
    return cards;
  }
  
  static Flashcard? _parseCardBlock(int number, String block) {
    // Labels to look for
    final frontMarkers = ['ÖN YÜZ', 'Soru/Kavram', 'Soru', 'Kavram', 'Front'];
    final backMarkers = ['ARKA YÜZ', 'Cevap', 'Açıklama', 'Back'];
    final hintMarkers = ['🔗', 'İpucu', 'Hint'];

    String front = '';
    String back = '';
    String? hint;

    // Find indices of markers
    int findMarkerIndex(List<String> markers, String text) {
      int earliest = -1;
      for (final m in markers) {
        final pos = text.toLowerCase().indexOf(m.toLowerCase());
        if (pos != -1 && (earliest == -1 || pos < earliest)) {
          earliest = pos;
        }
      }
      return earliest;
    }

    final frontIndex = findMarkerIndex(frontMarkers, block);
    final backIndex = findMarkerIndex(backMarkers, block);
    final hintIndex = findMarkerIndex(hintMarkers, block);

    // If we have backIndex, the text before it is potentially front
    if (backIndex != -1) {
      front = block.substring(0, backIndex);
      final rest = block.substring(backIndex);
      
      if (hintIndex != -1 && hintIndex > backIndex) {
        back = block.substring(backIndex, hintIndex);
        hint = block.substring(hintIndex);
      } else {
        back = rest;
      }
    } else {
      // Fallback: split by line
      final lines = block.split('\n');
      if (lines.length >= 2) {
        front = lines[0];
        back = lines.sublist(1).join('\n');
      } else if (lines.length == 1 && lines[0].isNotEmpty) {
        front = lines[0];
        back = "..."; // Placeholder if back is missing
      } else {
        return null; // Can't parse
      }
    }

    front = _cleanText(front);
    back = _cleanText(back);
    if (hint != null) hint = _cleanText(hint);

    if (front.isEmpty || back.isEmpty) return null;
    
    return Flashcard(
      number: number,
      front: front,
      back: back,
      hint: hint,
    );
  }

  static String _cleanText(String text) {
    String result = text.trim();
    
    // Comprehensive label removal regex
    // This wipes out: "Kavram:", "Soru 1:", "ÖN YÜZ:", "**Cevap:**", etc.
    // Uses \b to avoid matching part of a word (e.g. "Sorunu" vs "Soru")
    final labelPattern = RegExp(
      r'^(?:[^\w\s]*(?:ÖN\s*YÜZ|ARKA\s*YÜZ|Soru\/Kavram|Soru|Kavram|Cevap|Açıklama|İpucu|Front|Back|Hint|Zorluk)\b(?:\s*\d+)?[:\s\)\*\_]+)+',
      caseSensitive: false,
    );
    
    result = result.replaceFirst(labelPattern, '').trim();

    // Now clean up any leftover symbols at start/end
    bool changed = true;
    while (changed) {
      changed = false;
      final symbols = ['**', '*', '_', ':', '💭', '❓', '✅', '💡', '🔗', '#', '-', '(', ')', '.', ' ', '🗓️', '🎴'];
      for (final s in symbols) {
        if (result.startsWith(s)) {
          result = result.substring(s.length).trim();
          changed = true;
        }
        if (result.endsWith(s)) {
          result = result.substring(0, result.length - s.length).trim();
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
