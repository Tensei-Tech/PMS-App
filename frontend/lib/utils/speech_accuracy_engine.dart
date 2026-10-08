// lib/utils/speech_accuracy_engine.dart
// High-accuracy speech normalizer for English police forms, numeric fields, case numbers, and legal acronyms.

class SpeechAccuracyEngine {
  static final Map<String, String> _numberWords = {
    'zero': '0',
    'oh': '0',
    'one': '1',
    'won': '1',
    'two': '2',
    'to': '2',
    'too': '2',
    'three': '3',
    'four': '4',
    'for': '4',
    'fore': '4',
    'five': '5',
    'six': '6',
    'seven': '7',
    'eight': '8',
    'ate': '8',
    'nine': '9',
  };

  static final Map<String, int> _wordsToNum = {
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
  };

  static final Map<String, String> _policeAcronyms = {
    r'\b(p\.s\.i\.|p\s+s\s+i|piece\s+eye|psi|sub\s+inspector)\b': 'PSI',
    r'\b(p\.i\.|p\s+i|police\s+inspector|pi)\b': 'PI',
    r'\b(a\.p\.i\.|a\s+p\s+i|assistant\s+police\s+inspector|api)\b': 'API',
    r'\b(h\.c\.|h\s+c|head\s+constable|hc)\b': 'HC',
    r'\b(p\.c\.|p\s+c|police\s+constable|pc)\b': 'PC',
    r'\b(a\.s\.i\.|a\s+s\s+i|asi)\b': 'ASI',
    r'\b(d\.s\.p\.|d\s+s\s+p|dsp)\b': 'DSP',
    r'\b(a\.c\.p\.|a\s+c\s+p|acp)\b': 'ACP',
    r'\b(d\.c\.p\.|d\s+c\s+p|dcp)\b': 'DCP',
    r'\b(s\.p\.|s\s+p|sp)\b': 'SP',
    r'\b(i\.o\.|i\s+o|io|investigation\s+officer)\b': 'IO',
    r'\b(f\.i\.r\.|f\s+i\s+r|fire|fir)\b': 'FIR',
    r'\b(c\.r\.\s*no|c\s+r\s+no|see\s+are\s+no|cr\s+number|cr\s+no)\b':
        'CR No.',
    r'\b(n\.c\.\s*no|n\s+c\s+no|nc\s+number|nc\s+no)\b': 'NC No.',
    r'\b(b\.n\.s\.|b\s+n\s+s|bns)\b': 'BNS',
    r'\b(i\.p\.c\.|i\s+p\s+c|ipc)\b': 'IPC',
    r'\b(c\.r\.p\.c\.|c\s+r\s+p\s+c|crpc)\b': 'CrPC',
    r'\b(b\.n\.s\.s\.|b\s+n\s+s\s+s|bnss)\b': 'BNSS',
    r'\b(p\.o\.c\.s\.o\.|p\s+o\s+c\s+s\s+o|pocso)\b': 'POCSO',
    r'\b(m\.p\.d\.a\.|m\s+p\s+d\s+a|mpda)\b': 'MPDA',
    r'\b(n\.d\.p\.s\.|n\s+d\s+p\s+s|ndps)\b': 'NDPS',
    r'\b(m\.c\.o\.c\.a\.|m\s+c\s+o\s+c\s+a|mcoca)\b': 'MCOCA',
    r'\b(u\.a\.p\.a\.|u\s+a\s+p\s+a|uapa)\b': 'UAPA',
    r'\b(c\.c\.t\.v\.|c\s+c\s+t\s+v|cctv)\b': 'CCTV',
    r'\b(c\.d\.r\.|c\s+d\s+r|cdr)\b': 'CDR',
    r'\b(c\.w\.c\.|c\s+w\s+c|cwc)\b': 'CWC',
    r'\b(s\.d\.\s*no|s\s+d\s+no|station\s+diary)\b': 'SD No.',
  };

  static final List<String> _maharashtraPlaces = [
    'Nagpur',
    'Mumbai',
    'Pune',
    'Thane',
    'Nashik',
    'Aurangabad',
    'Chhatrapati Sambhajinagar',
    'Solapur',
    'Amravati',
    'Nanded',
    'Kolhapur',
    'Akola',
    'Jalgaon',
    'Latur',
    'Dhule',
    'Ahmednagar',
    'Chandrapur',
    'Parbhani',
    'Jalna',
    'Bhiwandi',
    'Gondia',
    'Wardha',
    'Yavatmal',
    'Bhandara',
    'Buldhana',
    'Gadchiroli',
    'Hingoli',
    'Nandurbar',
    'Dharashiv',
    'Osmanabad',
    'Palghar',
    'Raigad',
    'Ratnagiri',
    'Sangli',
    'Satara',
    'Sindhudurg',
    'Washim',
    'Ram Nagar',
    'Sitabuldi',
    'Dharampeth',
    'Sadar',
    'Kotwali',
    'Pardi',
    'Ganeshpeth',
    'Ambazari',
    'Dhantoli',
    'Sakkardara',
    'Nandanvan',
    'Hudkeshwar',
    'Wathoda',
    'Ajni',
    'Bajaj Nagar',
    'Pratap Nagar',
    'Rana Pratap Nagar',
    'MIDC',
    'Hingna',
    'Wadi',
    'Kalamna',
    'Yashodhara Nagar',
    'Jaripatka',
    'Koradi',
    'Mankapur',
    'Gittikhadan',
  ];

  /// Master normalization method based on active field context
  static String normalize(
    String rawText, {
    String? fieldLabel,
    String? sectionName,
  }) {
    if (rawText.trim().isEmpty) return '';

    String text = rawText.trim();
    final labelLower = (fieldLabel ?? '').toLowerCase();
    final sectionLower = (sectionName ?? '').toLowerCase();

    // 1. Check if field is strictly Numeric (Age, Pin code, Quantity, Amount, Count)
    if (_isAgeField(labelLower)) {
      return _normalizeAge(text);
    }

    if (_isStrictNumericField(labelLower)) {
      return _normalizeStrictNumbers(text);
    }

    // 2. Check if field is Phone / Mobile / Aadhaar / WhatsApp / PAN
    if (_isPhoneOrAadhaarField(labelLower)) {
      return _normalizePhoneOrAadhaar(text);
    }

    // 3. Check if field is Case / Crime / FIR / NC / SD / Outward Number
    if (_isCaseOrReferenceNumber(labelLower, sectionLower)) {
      return _normalizeCaseNumber(text);
    }

    // 4. Check if field is Date
    if (_isDateField(labelLower)) {
      return _normalizeDate(text);
    }

    // 5. Check if field is Designation / Officer
    if (_isDesignationField(labelLower)) {
      return _normalizeDesignation(text);
    }

    // 6. General Text Fields (Name, Address, Description, Remarks, Reason, Spot, etc.)
    return _normalizeGeneralText(text, labelLower);
  }

  // ── Helper Checkers ────────────────────────────────────────────────────────
  static bool _isAgeField(String label) {
    return label == 'age' ||
        label.contains('age (') ||
        label.contains('age (years)') ||
        label.endsWith(' age') ||
        label == 'accused age' ||
        label == 'victim age' ||
        label == 'complainant age';
  }

  static bool _isStrictNumericField(String label) {
    return label.contains('pin code') ||
        label.contains('pincode') ||
        label.contains('quantity') ||
        label.contains('amount') ||
        label.contains('count') ||
        label.contains('value (rs') ||
        label.contains('worth (rs');
  }

  static bool _isPhoneOrAadhaarField(String label) {
    return label.contains('mobile') ||
        label.contains('phone') ||
        label.contains('whatsapp') ||
        label.contains('aadhaar') ||
        label.contains('aadhar') ||
        label.contains('pan card') ||
        label.contains('pan number') ||
        label == 'pan';
  }

  static bool _isCaseOrReferenceNumber(String label, String section) {
    return label.contains('crime no') ||
        label.contains('cr no') ||
        label.contains('cr. no') ||
        label.contains('fir no') ||
        label.contains('nc no') ||
        label.contains('nc. no') ||
        label.contains('case number') ||
        label.contains('case no') ||
        label.contains('missing number') ||
        label.contains('outward number') ||
        label.contains('outward no') ||
        label.contains('sd number') ||
        label.contains('proposal no') ||
        label.contains('preventive number') ||
        label.contains('preventive no') ||
        section.contains('crime registration');
  }

  static bool _isDateField(String label) {
    return label.contains('date') ||
        label.contains('dob') ||
        label.contains('dd/mm/yyyy');
  }

  static bool _isDesignationField(String label) {
    return label.contains('designation') || label.contains('rank');
  }

  // ── Normalization Handlers ─────────────────────────────────────────────────

  /// Normalizes Age fields into pure integer numbers e.g. "twenty five" -> "25", "32 years" -> "32"
  static String _normalizeAge(String text) {
    String clean = text.toLowerCase();
    clean = clean.replaceAll(RegExp(r'\b(years|year|old|yrs|yr)\b'), '').trim();

    // Check direct word number
    final wordNum = _parseSpokenNumber(clean);
    if (wordNum != null) {
      return wordNum.toString();
    }

    // Extract first digit sequence
    final match = RegExp(r'\d+').firstMatch(clean);
    if (match != null) {
      return match.group(0)!;
    }

    return text.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Normalizes strict numeric fields into pure digits
  static String _normalizeStrictNumbers(String text) {
    String converted = _convertWordsToDigitsSequence(text);
    return converted.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Normalizes Phone numbers and Aadhaar (handling "double 9", "triple 5", etc.)
  static String _normalizePhoneOrAadhaar(String text) {
    String t = text.toLowerCase();

    // Multipliers: "double nine" -> "99", "triple five" -> "555"
    t = _expandMultipliers(t);

    // Convert word digits
    t = _convertWordsToDigitsSequence(t);

    // If Aadhaar or phone, keep only numbers (or letters if PAN)
    return t.replaceAll(RegExp(r'[\s\-]'), '');
  }

  /// Normalizes Case / Crime / FIR / NC Numbers e.g. "123 slash 2024" -> "123/2024"
  static String _normalizeCaseNumber(String text) {
    String t = text.toLowerCase();

    t = _expandMultipliers(t);

    // Replace slash words
    t = t.replaceAll(RegExp(r'\b(slash|by|divided by|oblique)\b'), '/');
    t = t.replaceAll(RegExp(r'\b(dash|hyphen|minus)\b'), '-');
    t = t.replaceAll(RegExp(r'\b(of)\b'), '/');

    // Convert words to digits
    t = _convertSpokenWordsInPhrase(t);

    // Apply police acronyms
    for (final entry in _policeAcronyms.entries) {
      t = t.replaceAll(RegExp(entry.key, caseSensitive: false), entry.value);
    }

    // Clean up spaces around slashes: "123 / 2024" -> "123/2024"
    t = t.replaceAll(RegExp(r'\s*/\s*'), '/');
    t = t.replaceAll(RegExp(r'\s*-\s*'), '-');

    return t.trim();
  }

  /// Normalizes spoken dates e.g. "15 September 2026" or "15 9 2026"
  static String _normalizeDate(String text) {
    String t = text.toLowerCase().trim();
    t = t.replaceAll(RegExp(r'\b(slash|by|dot|point)\b'), '/');
    t = t.replaceAll(RegExp(r'\b(dash|hyphen)\b'), '/');
    t = _convertSpokenWordsInPhrase(t);
    t = t.replaceAll(RegExp(r'\s*/\s*'), '/');
    return t.trim();
  }

  /// Normalizes designation / rank fields e.g. "psi" -> "PSI", "hc" -> "HC"
  static String _normalizeDesignation(String text) {
    String t = text.trim();
    for (final entry in _policeAcronyms.entries) {
      t = t.replaceAll(RegExp(entry.key, caseSensitive: false), entry.value);
    }
    return t;
  }

  /// Normalizes general text fields (Name, Address, Description, Spot, Remarks)
  static String _normalizeGeneralText(String text, String labelLower) {
    String t = text.trim();

    // 1. Spoken Punctuation
    t = t.replaceAll(RegExp(r'\b(comma)\b', caseSensitive: false), ',');
    t = t.replaceAll(
        RegExp(r'\b(full stop|period)\b', caseSensitive: false), '.');
    t = t.replaceAll(RegExp(r'\b(question mark)\b', caseSensitive: false), '?');
    t = t.replaceAll(RegExp(r'\b(colon)\b', caseSensitive: false), ':');
    t = t.replaceAll(RegExp(r'\b(hyphen|dash)\b', caseSensitive: false), '-');
    t = t.replaceAll(
        RegExp(r'\b(at the rate|at sign)\b', caseSensitive: false), '@');

    // 2. Expand multipliers in numbers
    t = _expandMultipliers(t);

    // 3. Convert isolated digit words
    t = _convertSpokenWordsInPhrase(t);

    // 4. Police acronyms & Legal terms
    for (final entry in _policeAcronyms.entries) {
      t = t.replaceAll(RegExp(entry.key, caseSensitive: false), entry.value);
    }

    // 5. Maharashtra Place Names & Proper Nouns Capitalization
    for (final place in _maharashtraPlaces) {
      t = t.replaceAll(
        RegExp(r'\b' + RegExp.escape(place) + r'\b', caseSensitive: false),
        place,
      );
    }

    // 6. Auto Capitalize First Letter & names if it's a name field
    if (labelLower.contains('name') || labelLower.contains('spot')) {
      t = _capitalizeWords(t);
    } else {
      t = _capitalizeSentences(t);
    }

    return t;
  }

  // ── Word to Digits Helpers ─────────────────────────────────────────────────

  static String _expandMultipliers(String input) {
    String t = input;
    // "double 9" -> "99", "double nine" -> "nine nine"
    final doubleRegex =
        RegExp(r'\bdouble\s+([a-z0-9]+)\b', caseSensitive: false);
    t = t.replaceAllMapped(doubleRegex, (m) => '${m.group(1)} ${m.group(1)}');

    // "triple 5" -> "555"
    final tripleRegex =
        RegExp(r'\btriple\s+([a-z0-9]+)\b', caseSensitive: false);
    t = t.replaceAllMapped(
        tripleRegex, (m) => '${m.group(1)} ${m.group(1)} ${m.group(1)}');

    return t;
  }

  static String _convertWordsToDigitsSequence(String input) {
    final tokens = input.toLowerCase().split(RegExp(r'\s+'));
    final result = <String>[];

    for (final token in tokens) {
      if (_numberWords.containsKey(token)) {
        result.add(_numberWords[token]!);
      } else if (int.tryParse(token) != null) {
        result.add(token);
      } else if (_wordsToNum.containsKey(token)) {
        result.add(_wordsToNum[token]!.toString());
      } else {
        result.add(token);
      }
    }

    return result.join(' ');
  }

  static String _convertSpokenWordsInPhrase(String input) {
    final words = input.split(' ');
    final out = <String>[];

    for (int i = 0; i < words.length; i++) {
      final w = words[i].toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      if (_numberWords.containsKey(w)) {
        out.add(_numberWords[w]!);
      } else if (_wordsToNum.containsKey(w) && _wordsToNum[w]! < 100) {
        out.add(_wordsToNum[w]!.toString());
      } else {
        out.add(words[i]);
      }
    }

    return out.join(' ');
  }

  static int? _parseSpokenNumber(String text) {
    final clean = text.toLowerCase().trim();
    if (int.tryParse(clean) != null) return int.parse(clean);

    final tokens = clean.split(RegExp(r'[\s\-]+'));
    int total = 0;
    int current = 0;

    for (final token in tokens) {
      if (_wordsToNum.containsKey(token)) {
        current += _wordsToNum[token]!;
      } else if (token == 'hundred') {
        current = (current == 0 ? 1 : current) * 100;
      } else if (token == 'thousand') {
        total += (current == 0 ? 1 : current) * 1000;
        current = 0;
      } else if (int.tryParse(token) != null) {
        current += int.parse(token);
      }
    }

    total += current;
    return total > 0 ? total : null;
  }

  static String _capitalizeWords(String input) {
    return input.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  static String _capitalizeSentences(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (capitalizeNext && RegExp(r'[a-zA-Z]').hasMatch(char)) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
      }
      if (char == '.' || char == '!' || char == '?') {
        capitalizeNext = true;
      }
    }

    return buffer.toString();
  }
}
