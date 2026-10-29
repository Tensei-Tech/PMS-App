import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_control_factory.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_field_model.dart';

DynamicFieldDef _field(String type, String? source) => DynamicFieldDef(
      fieldDefId: 1,
      fieldLabel: 'Property Description',
      fieldKey: 'cbt_property_description',
      fieldSource: 'custom',
      fieldType: type,
      isRequired: false,
      displayOrder: 1,
      optionsSource: source,
    );

TextEditingValue _v(String text) => TextEditingValue(text: text);

void main() {
  test('words:<n> on a text or text area field is its word limit', () {
    expect(_field('text', 'words:20').maxWords, 20);
    expect(_field('textarea', 'words:5').maxWords, 5);
    expect(_field('number', 'words:20').maxWords, isNull);
    expect(_field('text', null).maxWords, isNull);
    expect(_field('text', 'words:0').maxWords, isNull);
  });

  test('a word past the limit is not typed', () {
    final f = maxWordsFormatter(3);
    expect(f.formatEditUpdate(_v('one two'), _v('one two three')).text,
        'one two three');
    // Space after the last word is fine; a fourth word is refused.
    expect(f.formatEditUpdate(_v('one two three'), _v('one two three ')).text,
        'one two three ');
    expect(f.formatEditUpdate(_v('one two three '), _v('one two three f')).text,
        'one two three ');
    // Pasting too many words keeps the old text.
    expect(f.formatEditUpdate(_v(''), _v('a b c d e')).text, '');
  });
}
