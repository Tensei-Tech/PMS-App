// test/hs_mpda_no_hardcoding_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'Verify Flutter codebase contains NO hardcoded History Sheeter or MPDA labels, options, tabs, cards, or limits',
      () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist');

    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        // Exclude legacy mpda module files which are retained unused per instructions ('keep MpdaFormScreen and its files, unused, and delete nothing')
        .where((file) => !file.path.contains('modules${Platform.pathSeparator}mpda') && !file.path.contains('modules/mpda'));

    final forbiddenPatterns = [
      // Hardcoded option lists for History Sheeter or MPDA
      RegExp(r"['\x22]Body Offender['\x22]"),
      RegExp(r"['\x22]Property Offender['\x22]"),
      RegExp(r"['\x22]Bootlegger['\x22]"),
      RegExp(r"['\x22]Dangerous Person['\x22]"),
      RegExp(r"['\x22]Video Pirate['\x22]"),
      RegExp(r"['\x22]Sand Smuggler['\x22]"),
      RegExp(r"['\x22]Crimes against the body['\x22]"),
      RegExp(r"['\x22]Crimes against property['\x22]"),
      RegExp(r"['\x22]Crimes against women['\x22]"),

      // Forbidden status words or phantom cards
      RegExp(r"Persons currently detained", caseSensitive: false),

      // Hardcoded tab or card labels for History Sheeter or MPDA in hub screens or services
      RegExp(r"['\x22]Active History Sheeter['\x22]"),
      RegExp(r"['\x22]History Sheet Open['\x22]"),
      RegExp(r"['\x22]History Sheet Closed['\x22]"),
      RegExp(r"['\x22]Total MPDA proposal['\x22]"),
      RegExp(r"['\x22]Approved MPDA['\x22]"),
      RegExp(r"['\x22]Rejected MPDA['\x22]"),
      RegExp(r"['\x22]Total person in jail under MPDA['\x22]"),
      RegExp(r"['\x22]Total MPDA revoked['\x22]"),
      RegExp(r"['\x22]Released in next month['\x22]"),
    ];

    final violations = <String>[];

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      for (final pattern in forbiddenPatterns) {
        if (pattern.hasMatch(content)) {
          violations.add(
              '${file.path}: Matches forbidden pattern ${pattern.pattern}');
        }
      }
    }

    expect(violations, isEmpty,
        reason:
            'Found hardcoded History Sheeter or MPDA options/labels/tabs/cards in Flutter codebase: $violations');
  });
}
