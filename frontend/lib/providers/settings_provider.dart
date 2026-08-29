// lib/providers/settings_provider.dart
// Manages app-wide settings: font size, language, notifications, cache.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_constants.dart';

enum FontSize { small, medium, large }

class SettingsProvider extends ChangeNotifier {
  FontSize _fontSize = FontSize.medium;
  Locale _locale = const Locale('en');
  bool _isBiometricEnabled = false;
  bool _isBiometricSkipped = false;
  bool _shouldSkipNextBiometricAutoTrigger = false;

  FontSize get fontSize => _fontSize;
  Locale get locale => _locale;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isBiometricSkipped => _isBiometricSkipped;
  bool get shouldSkipNextBiometricAutoTrigger => _shouldSkipNextBiometricAutoTrigger;

  String get language {
    switch (_locale.languageCode) {
      case 'mr':
        return 'Marathi';
      case 'hi':
        return 'Hindi';
      default:
        return 'English';
    }
  }

  double get fontScale {
    switch (_fontSize) {
      case FontSize.small:
        return 0.85;
      case FontSize.large:
        return 1.15;
      default:
        return 1.0;
    }
  }

  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'mr': 'Marathi',
    'hi': 'Hindi',
    'gu': 'Gujarati',
    'ta': 'Tamil',
    'te': 'Telugu',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'pa': 'Punjabi',
    'bn': 'Bengali',
  };

  SettingsProvider() {
    Future.microtask(() {
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fs = prefs.getString(StorageKeys.fontSize) ?? 'medium';
      _fontSize = fs == 'small'
          ? FontSize.small
          : fs == 'large'
              ? FontSize.large
              : FontSize.medium;

      final langCode = prefs.getString(StorageKeys.language) ?? 'en';
      _locale = Locale(langCode);
      _isBiometricEnabled = prefs.getBool('isBiometricEnabled') ?? false;
      _isBiometricSkipped = prefs.getBool('isBiometricSkipped') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> setFontSize(FontSize size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        StorageKeys.fontSize,
        size == FontSize.small
            ? 'small'
            : size == FontSize.large
                ? 'large'
                : 'medium');
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    _locale = Locale(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.language, langCode);
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _isBiometricEnabled = enabled;
    if (enabled) {
      _isBiometricSkipped = false;
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isBiometricEnabled', enabled);
      if (enabled) {
        await prefs.setBool('isBiometricSkipped', false);
      }
    } catch (e) {
      debugPrint('setBiometricEnabled non-blocking error: $e');
    }
  }

  Future<void> setBiometricSkipped(bool skipped) async {
    _isBiometricSkipped = skipped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBiometricSkipped', skipped);
    notifyListeners();
  }

  void setSkipBiometricAutoTrigger(bool skip) {
    _shouldSkipNextBiometricAutoTrigger = skip;
    notifyListeners();
  }

  Future<String> getCacheSize() async {
    // Approximation — in production this would scan the cache dir
    return '4.2 MB';
  }

  Future<void> clearCache() async {
    // In production: delete app cache directory
    notifyListeners();
  }
}
