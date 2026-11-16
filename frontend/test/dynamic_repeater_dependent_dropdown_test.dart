// test/dynamic_repeater_dependent_dropdown_test.dart
// 'dependent_dropdown' and 'repeater' fields, with the Tadipar (category 264)
// field configs as the backend sends them.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:khakhi_diary/widgets/dynamic_form/dynamic_control_factory.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_dependent_dropdown.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_field_model.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_repeater_value.dart';

const _actConfig = {
  'api_url': 'acts/',
  'label_key': 'act_name',
  'value_key': 'id',
};
const _sectionConfig = {
  'api_url': 'act-sections/?act_id={parent_value}',
  'label_key': 'display_name',
  'value_key': 'id',
  'depends_on': 'act_id',
};

DynamicFieldDef _field(String key, String label, String type,
        Map<String, dynamic> config) =>
    DynamicFieldDef(
      fieldDefId: 1,
      fieldKey: key,
      fieldLabel: label,
      fieldSource: 'custom',
      fieldType: type,
      isRequired: false,
      displayOrder: 1,
      fieldConfig: config,
    );

final _act = _field('act_id', 'Act', 'dependent_dropdown', _actConfig);
final _section =
    _field('section_id', 'Section', 'dependent_dropdown', _sectionConfig);
final _crimeChart = _field('crime_chart_entries', 'Crime Chart', 'repeater', {
  'fields': [
    {'key': 'cr_number', 'type': 'text', 'label': 'CR No.'},
    {
      'key': 'act_id',
      'type': 'dependent_dropdown',
      'label': 'Act',
      'config': _actConfig,
    },
    {
      'key': 'section_id',
      'type': 'dependent_dropdown',
      'label': 'Section',
      'config': _sectionConfig,
    },
  ],
});

final _requested = <String>[];

Future<List<Map<String, dynamic>>> _fakeLoader(String route) async {
  _requested.add(route);
  if (route == 'acts/') {
    return [
      {'id': 1, 'act_name': 'Indian Penal Code'},
      {'id': 2, 'act_name': 'Maharashtra Police Act'},
    ];
  }
  if (route == 'act-sections/?act_id=1') {
    return [
      {'id': 11, 'display_name': 'Sec 302 - Murder'},
    ];
  }
  if (route == 'act-sections/?act_id=2') {
    return [
      {'id': 21, 'display_name': 'Sec 56 - Externment'},
    ];
  }
  return [];
}

/// A small form: the fields share [values], as the section builder does.
class _Host extends StatefulWidget {
  final List<DynamicFieldDef> fields;
  final Map<String, dynamic> values;
  const _Host(this.fields, this.values);

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final _controllers = <String, TextEditingController>{};

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Form(
            child: Column(
              children: [
                for (final f in widget.fields)
                  DynamicControlFactory(
                    fieldDef: f,
                    controller: _controllers.putIfAbsent(
                        f.fieldKey, () => TextEditingController()),
                    value: widget.values[f.fieldKey],
                    formValues: widget.values,
                    allFields: widget.fields,
                    onChanged: (v) => setState(() {
                      if (v == null) {
                        widget.values.remove(f.fieldKey);
                      } else {
                        widget.values[f.fieldKey] = v;
                      }
                    }),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _pick(WidgetTester tester, Finder field, String label) async {
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    _requested.clear();
    DynamicDependentDropdown.loaderForTesting = _fakeLoader;
  });
  tearDown(() => DynamicDependentDropdown.loaderForTesting = null);

  group('RepeaterValue.parse', () {
    test('a list is used as it is', () {
      final rows = [
        {'cr_number': '12'}
      ];
      expect(identical(RepeaterValue.parse(rows).rows, rows), isTrue);
    });

    test('JSON text is read as rows', () {
      final v = RepeaterValue.parse('[{"cr_number": "12", "act_id": 1}]');
      expect(v.rows, [
        {'cr_number': '12', 'act_id': 1}
      ]);
      expect(v.legacyText, isNull);
    });

    test('the text the server writes for rows is read as rows', () {
      final v = RepeaterValue.parse(
          "{'cr_number': '12/2024', 'act_id': 1, 'section_id': None, "
          "'crime_head': \"Theft, house\"}, {'cr_number': '7', 'act_id': 2}");
      expect(v.legacyText, isNull);
      expect(v.rows, [
        {
          'cr_number': '12/2024',
          'act_id': 1,
          'section_id': null,
          'crime_head': 'Theft, house'
        },
        {'cr_number': '7', 'act_id': 2},
      ]);
    });

    test('typed text from older records is kept as text', () {
      final v = RepeaterValue.parse('CR 12/2020 IPC 379, CR 4/2021 IPC 380');
      expect(v.rows, isEmpty);
      expect(v.legacyText, 'CR 12/2020 IPC 379, CR 4/2021 IPC 380');
    });

    test('empty answers give no rows and no text', () {
      for (final empty in [null, '', '[]', 'null']) {
        final v = RepeaterValue.parse(empty);
        expect(v.rows, isEmpty);
        expect(v.legacyText, isNull);
      }
    });
  });

  test('repeater columns come from field_config.fields', () {
    final cols = repeaterColumnFields(_crimeChart);
    expect(cols.map((c) => c.fieldKey), ['cr_number', 'act_id', 'section_id']);
    expect(cols.map((c) => c.fieldType),
        ['text', 'dependent_dropdown', 'dependent_dropdown']);
    expect(cols.every((c) => c.parentFieldKey == 'crime_chart_entries'),
        isTrue);
    expect(cols[2].fieldConfig?['depends_on_label'], 'Act');
  });

  testWidgets('Act / Section save ids; changing the Act clears the Section',
      (tester) async {
    final values = <String, dynamic>{};
    await tester.pumpWidget(_Host([_act, _section], values));
    await tester.pumpAndSettle();

    expect(find.text('Select Act first'), findsOneWidget);
    expect(_requested, ['acts/']);

    final dropdowns = find.byType(DropdownButtonFormField<String>);
    await _pick(tester, dropdowns.at(0), 'Indian Penal Code');
    expect(values['act_id'], 1);
    expect(_requested, contains('act-sections/?act_id=1'));

    await _pick(tester, dropdowns.at(1), 'Sec 302 - Murder');
    expect(values['section_id'], 11);

    await _pick(tester, dropdowns.at(0), 'Maharashtra Police Act');
    expect(values['act_id'], 2);
    expect(values.containsKey('section_id'), isFalse);
    expect(_requested, contains('act-sections/?act_id=2'));
  });

  testWidgets('a saved record opens with its Act and Section shown',
      (tester) async {
    // The server gives ids back as text
    final values = <String, dynamic>{'act_id': '1', 'section_id': '11'};
    await tester.pumpWidget(_Host([_act, _section], values));
    await tester.pumpAndSettle();

    expect(find.text('Indian Penal Code'), findsOneWidget);
    expect(find.text('Sec 302 - Murder'), findsOneWidget);
    expect(values, {'act_id': '1', 'section_id': '11'});
  });

  testWidgets('older typed Act / Section text is still shown, not lost',
      (tester) async {
    final values = <String, dynamic>{'act_id': 'IPC', 'section_id': '302'};
    await tester.pumpWidget(_Host([_act, _section], values));
    await tester.pumpAndSettle();

    expect(find.text('IPC (earlier entry)'), findsOneWidget);
    expect(find.text('302 (earlier entry)'), findsOneWidget);
    expect(_requested, contains('act-sections/?act_id=IPC'));
    expect(values, {'act_id': 'IPC', 'section_id': '302'});
  });

  testWidgets('Crime Chart rows: add, pick Act / Section per row, remove',
      (tester) async {
    final values = <String, dynamic>{};
    await tester.pumpWidget(_Host([_crimeChart], values));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Crime Chart 1'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '12/2024');
    final dropdowns = find.byType(DropdownButtonFormField<String>);
    await _pick(tester, dropdowns.at(0), 'Maharashtra Police Act');
    await _pick(tester, dropdowns.at(1), 'Sec 56 - Externment');

    expect(values['crime_chart_entries'], [
      {'cr_number': '12/2024', 'act_id': 2, 'section_id': 21}
    ]);

    // A second row; changing its Act clears only its own Section
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await _pick(tester, dropdowns.at(2), 'Indian Penal Code');
    await _pick(tester, dropdowns.at(3), 'Sec 302 - Murder');
    await _pick(tester, dropdowns.at(2), 'Maharashtra Police Act');
    expect(values['crime_chart_entries'], [
      {'cr_number': '12/2024', 'act_id': 2, 'section_id': 21},
      {'act_id': 2, 'section_id': null},
    ]);

    // Removing the first row leaves the second as it was
    await tester.tap(find.byTooltip('Remove').first);
    await tester.pumpAndSettle();
    expect(values['crime_chart_entries'], [
      {'act_id': 2, 'section_id': null},
    ]);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    expect(values['crime_chart_entries'], isEmpty);
  });

  testWidgets('an older typed Crime Chart is shown read-only above the rows',
      (tester) async {
    final values = <String, dynamic>{
      'crime_chart_entries': 'CR 12/2020 IPC 379',
    };
    await tester.pumpWidget(_Host([_crimeChart], values));
    await tester.pumpAndSettle();

    expect(find.text('CR 12/2020 IPC 379'), findsOneWidget);
    expect(find.textContaining('Saved earlier as text'), findsOneWidget);
    expect(values['crime_chart_entries'], 'CR 12/2020 IPC 379');
  });
}
