import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Verify Flutter codebase contains no hardcoded RTI labels or option lists', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist');

    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    final forbiddenPatterns = [
      RegExp(r"['\x22]rti_mode_of_receipt['\x22]\s*:\s*\["), // Hardcoded option arrays
      RegExp(r"['\x22]rti_info_type['\x22]\s*:\s*\["),
      RegExp(r"['\x22]rti_outcome['\x22]\s*:\s*\["),
      RegExp(r"const\s+List<String>\s+rtiModeOptions\s*="),
      RegExp(r"const\s+List<String>\s+rtiInfoTypeOptions\s*="),
    ];

    final violations = <String>[];

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      for (final pattern in forbiddenPatterns) {
        if (pattern.hasMatch(content)) {
          violations.add('${file.path}: Matches forbidden pattern ${pattern.pattern}');
        }
      }
    }

    expect(violations, isEmpty, reason: 'Found hardcoded RTI options or static definitions in Flutter codebase: $violations');
  });
}
