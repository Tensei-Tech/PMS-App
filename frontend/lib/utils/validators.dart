// lib/utils/validators.dart
// Centralized form validators with user-friendly error messages.

import 'package:flutter/services.dart';

/// Auto-uppercases input as the user types (e.g. for PAN cards)
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class AppValidators {
  /// Full name: required, at least 2 words
  static String? fullName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Full name is required';
    if (v.trim().split(' ').length < 2) return 'Please enter your full name';
    return null;
  }

  /// Required field validator — general purpose
  static String? required(String? v, [String fieldName = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  /// Email validator — standard public or government domains.
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email address is required';
    final value = v.trim();
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!regex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  /// Registration / login email — allows Gmail, Yahoo, gov.in, etc.
  static String? govtEmail(String? v) => email(v);

  /// 10-digit mobile number
  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Mobile number is required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Enter a valid 10-digit mobile number';
    return null;
  }

  /// Indian Mobile Number: exactly 10 digits starting with 6, 7, 8, 9
  static String? indianMobile(String? v, {bool required = true}) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) {
      return required ? 'Mobile number is required (10 digits)' : null;
    }
    final digits = s.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return 'Mobile number must be exactly 10 digits';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return 'Enter a valid Indian mobile number (starts with 6-9)';
    }
    return null;
  }

  // ── Verhoeff Algorithm Tables for Aadhaar Checksum ──────────────────────────
  static const List<List<int>> _verhoeffD = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
    [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
    [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
    [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
    [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
    [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
    [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
    [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
    [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
  ];

  static const List<List<int>> _verhoeffP = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    [7, 0, 4, 6, 9, 1, 3, 2, 5, 8]
  ];

  /// Validates a number string using the Verhoeff checksum algorithm
  static bool validateVerhoeff(String num) {
    int c = 0;
    final reversed = num.split('').reversed.toList();
    for (int i = 0; i < reversed.length; i++) {
      final digit = int.tryParse(reversed[i]);
      if (digit == null) return false;
      c = _verhoeffD[c][_verhoeffP[i % 8][digit]];
    }
    return c == 0;
  }

  /// Aadhaar Number Validator:
  /// - Optional (returns null when empty)
  /// - Exactly 12 digits, numeric only (Regex: ^\d{12}$)
  /// - Cannot start with 0 or 1 (Regex: ^[2-9]\d{11}$)
  /// - Validated using the Verhoeff checksum algorithm
  static String? aadhaar(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null; // Optional
    final digits = s.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 12) {
      return 'Aadhaar must be exactly 12 digits';
    }
    if (!RegExp(r'^[2-9]\d{11}$').hasMatch(digits)) {
      return 'Aadhaar cannot start with 0 or 1';
    }
    if (!validateVerhoeff(digits)) {
      return 'Invalid Aadhaar number (checksum failed)';
    }
    return null;
  }

  /// PAN Number Validator:
  /// - Optional (returns null when empty)
  /// - Exactly 10 characters
  /// - Format: 5 letters + 4 digits + 1 letter (Regex: ^[A-Z]{5}[0-9]{4}[A-Z]{1}$)
  static String? pan(String? v) {
    final s = v?.trim().toUpperCase() ?? '';
    if (s.isEmpty) return null; // Optional
    if (s.length != 10) {
      return 'PAN must be exactly 10 characters';
    }
    final regex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    if (!regex.hasMatch(s)) {
      return 'Invalid PAN format (e.g. ABCDE1234F)';
    }
    return null;
  }

  /// Username: alphanumeric, 4-20 chars
  static String? username(String? v) {
    if (v == null || v.trim().isEmpty) return 'Username is required';
    if (v.trim().length < 4) return 'Username must be at least 4 characters';
    if (v.trim().length > 20) return 'Username must be at most 20 characters';
    if (!RegExp(r'^[a-zA-Z0-9_\.]+$').hasMatch(v.trim())) {
      return 'Username can only contain letters, numbers, _ and .';
    }
    return null;
  }

  /// Password: min 8 chars
  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  /// Confirm password
  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  /// 6-digit PIN
  static String? pin(String? v) {
    if (v == null || v.isEmpty) return 'PIN is required';
    if (v.length != 6) return 'PIN must be exactly 6 digits';
    if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'PIN must contain only digits';
    return null;
  }

  /// Landline number: at least 8 digits
  static String? landline(String? v) {
    if (v == null || v.trim().isEmpty) return 'Landline number is required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return 'Enter a valid landline number';
    return null;
  }

  /// Login identifier: email or username
  static String? loginId(String? v) {
    if (v == null || v.trim().isEmpty) return 'Username or email is required';
    return null;
  }
}

