import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class UiConfigService {
  static const String _cacheKey = 'dynamic_ui_config_cache';
  static Map<String, dynamic> _config = {};

  static Map<String, dynamic> get repeatOffenderSummary {
    return _config['repeat_offender_summary'] ??
        {
          "unknown_offender_label": "Unknown Offender",
          "other_bucket_label": "Other",
          "empty_placeholder": "—",
          "error_message": "Could not load repeat offender cases",
          "add_button_label": "Add Repeat Offender",
          "form_module_key": "form_1_5",
          "form_sub_category": "Repeat Offender",
          "form_module_label": "Repeat Offender",
          "no_cases_label": "No cases",
          "title": "Repeat Offender — Summary"
        };
  }

  static Map<String, dynamic> get juvenileSummary {
    return _config['juvenile_summary'] ??
        {
          "unknown_offender_label": "Unknown Offender",
          "other_bucket_label": "Other",
          "empty_placeholder": "—",
          "error_message": "Could not load CiCL cases",
          "add_button_label": "Add CiCL",
          "form_module_key": "pocso",
          "form_sub_category": "Juvenile",
          "form_module_label": "Juvenile",
          "no_cases_label": "No cases",
          "title": "CiCL — Summary"
        };
  }

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        _config = jsonDecode(cached);
      } catch (_) {}
    }

    // Fetch latest from API asynchronously
    _fetchLatest();
  }

  static Future<void> _fetchLatest() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.uiConfig));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _config = data;
        final prefs = await SharedPreferences.getInstance();
        prefs.setString(_cacheKey, jsonEncode(data));
      }
    } catch (e) {
      // Use cache or defaults
    }
  }
}
