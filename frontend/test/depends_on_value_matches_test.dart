import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_field_model.dart';

void main() {
  group('dependsOnValueMatches (field_template_fields.depends_on_value)', () {
    test('any of "A|B" against a multi-select list', () {
      const target = 'Cash|ATM and Banking Related';
      expect(dependsOnValueMatches(['Vehicle Theft', 'Cash'], target), isTrue);
      expect(
          dependsOnValueMatches(['ATM and Banking Related'], target), isTrue);
      expect(dependsOnValueMatches(['Vehicle Theft'], target), isFalse);
      expect(dependsOnValueMatches(<String>[], target), isFalse);
    });

    test('single value, comma text and yes/true', () {
      expect(dependsOnValueMatches('Other', 'Other'), isTrue);
      expect(
          dependsOnValueMatches('Copper, Other Metal', 'Other Metal',
              parentIsMultiSelect: true),
          isTrue);
      expect(dependsOnValueMatches('true', 'Yes'), isTrue);
      expect(dependsOnValueMatches('No', 'Yes'), isFalse);
    });

    test('empty target means any filled value', () {
      expect(dependsOnValueMatches('x', null), isTrue);
      expect(dependsOnValueMatches('', null), isFalse);
      expect(dependsOnValueMatches('false', ''), isFalse);
    });
  });
}
