// lib/widgets/dynamic_form/dynamic_repeater_value.dart
// Reading a saved 'repeater' answer (a list of rows) and its column fields.

import 'dart:convert';

import 'dynamic_field_model.dart';

/// A saved repeater answer: the rows, or the free text an older record holds.
class RepeaterValue {
  final List<dynamic> rows;

  /// Text saved before the field had rows (e.g. a typed Crime Chart); shown
  /// read-only above the rows. Null when the answer is rows (or empty).
  final String? legacyText;

  const RepeaterValue(this.rows, [this.legacyText]);

  /// Rows from a list, a JSON text, or the Python-style text the server
  /// writes for a list of rows (`{'cr_number': '12', ...}, {...}`).
  /// Anything else that is not empty is kept as [legacyText].
  static RepeaterValue parse(dynamic value) {
    if (value is List) return RepeaterValue(value);
    if (value is Map) return RepeaterValue([value]);
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null' || text == '[]') {
      return const RepeaterValue([]);
    }
    final rows = _rowsFromText(text);
    if (rows != null) return RepeaterValue(rows);
    return RepeaterValue(const [], text);
  }

  static List<dynamic>? _rowsFromText(String text) {
    if (!text.startsWith('[') && !text.startsWith('{')) return null;
    for (final candidate in [text, '[$text]']) {
      final parsed = _tryJson(candidate) ?? _PyLiteral.tryParse(candidate);
      if (parsed is List && parsed.every((r) => r is Map)) {
        return parsed
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
      }
    }
    return null;
  }

  static dynamic _tryJson(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }
}

/// The columns of a repeater, from `field_config.fields`
/// (`{key, type, label, config?}`), as child fields of [parent].
List<DynamicFieldDef> repeaterColumnFields(DynamicFieldDef parent) {
  final raw = parent.fieldConfig?['fields'];
  if (raw is! List) return const [];
  final columns = raw.whereType<Map>().toList();
  String labelOf(String key) {
    for (final c in columns) {
      if (c['key']?.toString() == key) return c['label']?.toString() ?? key;
    }
    return key;
  }

  final fields = <DynamicFieldDef>[];
  for (var i = 0; i < columns.length; i++) {
    final c = columns[i];
    final key = c['key']?.toString().trim() ?? '';
    if (key.isEmpty) continue;
    final config = c['config'] is Map
        ? Map<String, dynamic>.from(c['config'] as Map)
        : <String, dynamic>{};
    final dependsOn = config['depends_on']?.toString();
    if (dependsOn != null && dependsOn.isNotEmpty) {
      config.putIfAbsent('depends_on_label', () => labelOf(dependsOn));
    }
    final options = c['options'] ?? config['options'];
    fields.add(DynamicFieldDef(
      fieldDefId: 0,
      fieldLabel: c['label']?.toString() ?? key,
      fieldKey: key,
      fieldSource: 'custom',
      fieldType: (c['type']?.toString() ?? 'text').toLowerCase(),
      isRequired: c['required'] == true || config['required'] == true,
      displayOrder: i,
      options: options is List
          ? options.map((e) => e.toString()).toList()
          : const [],
      parentFieldKey: parent.fieldKey,
      fieldConfig: config,
    ));
  }
  return fields;
}

/// Reads Python literals (dicts, lists, tuples, quoted text, numbers,
/// None / True / False), as written by Python's str() of a list of rows.
class _PyLiteral {
  final String s;
  int i = 0;
  _PyLiteral(this.s);

  static dynamic tryParse(String text) {
    try {
      final p = _PyLiteral(text);
      final v = p._value();
      p._ws();
      return p.i == text.length ? v : null;
    } catch (_) {
      return null;
    }
  }

  void _ws() {
    while (i < s.length && ' \t\r\n'.contains(s[i])) {
      i++;
    }
  }

  dynamic _value() {
    _ws();
    if (i >= s.length) throw const FormatException('end');
    final c = s[i];
    if (c == '{') return _dict();
    if (c == '[') return _seq(']');
    if (c == '(') return _seq(')');
    if (c == "'" || c == '"') return _str();
    for (final word in const {'None': null, 'True': true, 'False': false}
        .entries) {
      if (s.startsWith(word.key, i)) {
        i += word.key.length;
        return word.value;
      }
    }
    final m = RegExp(r'-?\d+(\.\d+)?').matchAsPrefix(s, i);
    if (m == null) throw const FormatException('value');
    i = m.end;
    return m.group(1) == null ? int.parse(m.group(0)!) : double.parse(m[0]!);
  }

  Map<String, dynamic> _dict() {
    i++; // {
    final out = <String, dynamic>{};
    _ws();
    if (s[i] == '}') {
      i++;
      return out;
    }
    while (true) {
      final key = _value();
      _ws();
      if (s[i] != ':') throw const FormatException(':');
      i++;
      out[key.toString()] = _value();
      _ws();
      if (s[i] == ',') {
        i++;
        _ws();
        if (s[i] == '}') {
          i++;
          return out;
        }
        continue;
      }
      if (s[i] == '}') {
        i++;
        return out;
      }
      throw const FormatException('dict');
    }
  }

  List<dynamic> _seq(String close) {
    i++; // [ or (
    final out = <dynamic>[];
    _ws();
    if (s[i] == close) {
      i++;
      return out;
    }
    while (true) {
      out.add(_value());
      _ws();
      if (s[i] == ',') {
        i++;
        _ws();
        if (s[i] == close) {
          i++;
          return out;
        }
        continue;
      }
      if (s[i] == close) {
        i++;
        return out;
      }
      throw const FormatException('list');
    }
  }

  String _str() {
    final quote = s[i++];
    final b = StringBuffer();
    while (i < s.length && s[i] != quote) {
      if (s[i] == '\\' && i + 1 < s.length) {
        final n = s[i + 1];
        b.write(const {'n': '\n', 't': '\t', 'r': '\r'}[n] ?? n);
        i += 2;
      } else {
        b.write(s[i++]);
      }
    }
    if (i >= s.length) throw const FormatException('string');
    i++; // closing quote
    return b.toString();
  }
}
