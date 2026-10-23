// test/dynamic_engine_hs_mpda_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:khakhi_diary/services/api_service.dart';
import 'package:khakhi_diary/services/dynamic_options_service.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_control_factory.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_field_model.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_repeating_group_widget.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_section_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService().setAuthToken('test-token');
    DynamicOptionsService().clearCache();
  });

  group('Dynamic Form Engine - Multi Select & Repeating Group Conditions', () {
    testWidgets(
        'Condition on multi_select: child field is visible when parent multi_select list contains target value',
        (tester) async {
      const parentField = DynamicFieldDef(
        fieldDefId: 1,
        fieldKey: 'hs_category_type',
        fieldLabel: 'Category / Type',
        fieldSource: 'custom',
        fieldType: 'multi_select',
        isRequired: false,
        section: 'General',
        displayOrder: 10,
        options: ['Body Offender', 'Property Offender', 'Other'],
      );

      const dependentChildField = DynamicFieldDef(
        fieldDefId: 2,
        fieldKey: 'hs_category_other',
        fieldLabel: 'Other Category Details',
        fieldSource: 'custom',
        fieldType: 'text',
        isRequired: false,
        section: 'General',
        displayOrder: 20,
        dependsOnFieldKey: 'hs_category_type',
        dependsOnValue: 'Other',
      );

      final formValues = <String, dynamic>{
        'hs_category_type': ['Body Offender'], // Does not contain 'Other'
      };
      final testControllers = <String, TextEditingController>{};

      late void Function(void Function()) setCardState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (ctx, setState) {
                setCardState = setState;
                return DynamicSectionCard(
                  key: ValueKey(formValues['hs_category_type'].toString()),
                  title: 'General',
                  icon: Icons.folder_outlined,
                  fields: const [parentField, dependentChildField],
                  controllers: testControllers,
                  values: formValues,
                  onValueChanged: (key, val) {
                    formValues[key] = val;
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Child field should NOT be visible when 'Other' is not in the list
      expect(find.text('Other Category Details'), findsNothing);

      // Now add 'Other' to the multi_select value
      setCardState(() {
        formValues['hs_category_type'] = ['Body Offender', 'Other'];
      });

      await tester.pumpAndSettle();

      // Child field should now BE visible because the list contains 'Other'
      expect(find.text('Other Category Details'), findsOneWidget);
    });

    testWidgets(
        'In-row condition in repeating group: child field evaluates condition strictly against its own row data',
        (tester) async {
      const repeatingGroupField = DynamicFieldDef(
        fieldDefId: 10,
        fieldKey: 'hs_preventive_actions',
        fieldLabel: 'Preventive Action Taken',
        fieldSource: 'custom',
        fieldType: 'repeating_group',
        isRequired: false,
        section: 'Preventive Actions',
        displayOrder: 100,
      );

      const actionTypeChild = DynamicFieldDef(
        fieldDefId: 11,
        fieldKey: 'hs_preventive_action_type',
        fieldLabel: 'Action Taken',
        fieldSource: 'custom',
        fieldType: 'text',
        isRequired: false,
        section: 'Preventive Actions',
        displayOrder: 101,
        parentFieldKey: 'hs_preventive_actions',
      );

      const actionOtherChild = DynamicFieldDef(
        fieldDefId: 12,
        fieldKey: 'hs_preventive_action_other',
        fieldLabel: 'Other Preventive Action Details',
        fieldSource: 'custom',
        fieldType: 'text',
        isRequired: false,
        section: 'Preventive Actions',
        displayOrder: 102,
        parentFieldKey: 'hs_preventive_actions',
        dependsOnFieldKey: 'hs_preventive_action_type',
        dependsOnValue: 'Other',
      );

      // Row 1: Externment (Other field hidden)
      // Row 2: Other (Other field visible)
      final rowsData = [
        {'hs_preventive_action_type': 'Externment'},
        {'hs_preventive_action_type': 'Other'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicRepeatingGroupWidget(
              fieldDef: repeatingGroupField,
              childFields: const [actionTypeChild, actionOtherChild],
              value: rowsData,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Only Row 2 should show 'Other Preventive Action Details' (findsOneWidget)
      expect(find.text('Other Preventive Action Details'), findsOneWidget);
    });

    testWidgets('IO Picker supports picking officer or typing text',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/mpda/officers/')) {
          return http.Response(
              '''[
            {"name": "PI Ramesh Patil", "designation": "Police Inspector", "uid": "USR-101"},
            {"name": "PSI Suresh Kadam", "designation": "Sub-Inspector", "uid": "USR-102"}
          ]''',
              200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('[]', 200,
            headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      const ioField = DynamicFieldDef(
        fieldDefId: 50,
        fieldKey: 'mpda_io_name',
        fieldLabel: 'IO Name & Post',
        fieldSource: 'custom',
        fieldType: 'text',
        isRequired: false,
        section: 'Officer',
        displayOrder: 1,
        optionsSource: '/api/mpda/officers/',
      );

      Map<String, dynamic> multiFieldOutput = {};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicControlFactory(
              fieldDef: ioField,
              onMultiFieldChanged: (data) {
                multiFieldOutput = data;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter custom officer text
      await tester.enterText(find.byType(TextFormField), 'Custom Typed IO');
      await tester.pumpAndSettle();

      // Verify custom typed text sets name and does not emit or write uid
      expect(multiFieldOutput['mpda_io_name'], 'Custom Typed IO');
      expect(multiFieldOutput.containsKey('mpda_io_uid'), isFalse);

      ApiService.clientForTesting = null;
    });

    testWidgets(
        'MPDA Crime Chart grouped repeating group expands and reveals CR No. and Date fields on tap',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/options/mpda_crime_types/')) {
          return http.Response(
            '["Crimes against the body", "Crimes against property", "Murder", "Other special"]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('[]', 200,
            headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      const chartField = DynamicFieldDef(
        fieldDefId: 290,
        fieldKey: 'mpda_crime_chart',
        fieldLabel: 'Crime Chart',
        fieldSource: 'custom',
        fieldType: 'repeating_group',
        isRequired: false,
        displayOrder: 290,
        optionsSource: '/api/options/mpda_crime_types/',
      );

      const typeChild = DynamicFieldDef(
        fieldDefId: 291,
        fieldKey: 'mpda_crime_type',
        fieldLabel: 'Crime Type',
        fieldSource: 'custom',
        fieldType: 'dropdown',
        isRequired: false,
        displayOrder: 291,
        parentFieldKey: 'mpda_crime_chart',
      );

      const crNoChild = DynamicFieldDef(
        fieldDefId: 292,
        fieldKey: 'mpda_crime_cr_no',
        fieldLabel: 'CR No.',
        fieldSource: 'custom',
        fieldType: 'text',
        isRequired: false,
        displayOrder: 292,
        parentFieldKey: 'mpda_crime_chart',
      );

      const dateChild = DynamicFieldDef(
        fieldDefId: 293,
        fieldKey: 'mpda_crime_date',
        fieldLabel: 'Date',
        fieldSource: 'custom',
        fieldType: 'date',
        isRequired: false,
        displayOrder: 293,
        parentFieldKey: 'mpda_crime_chart',
      );

      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      List<Map<String, dynamic>> updatedRows = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DynamicControlFactory(
                fieldDef: chartField,
                allFields: const [chartField, typeChild, crNoChild, dateChild],
                onChanged: (val) {
                  if (val is List) {
                    updatedRows = List<Map<String, dynamic>>.from(val);
                  }
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify category headers are present
      expect(find.text('Crimes against the body'), findsOneWidget);
      expect(find.text('Crimes against property'), findsOneWidget);
      expect(find.text('Murder'), findsOneWidget);

      // Initially CR No. and Date fields are not visible because groups are closed
      expect(find.text('CR No.'), findsNothing);
      expect(find.text('Date'), findsNothing);

      // Tap on "Crimes against the body" header
      await tester.tap(find.text('Crimes against the body'));
      await tester.pumpAndSettle();

      // Verify it immediately expanded AND auto-created row 1, showing CR No. and Date!
      expect(find.text('CR No.'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(updatedRows.isNotEmpty, isTrue);
      expect(updatedRows.first['mpda_crime_type'], 'Crimes against the body');

      // Tap on "Murder" -> Multiple selection: both "Crimes against the body" AND "Murder" are selected simultaneously!
      await tester.tap(find.text('Murder'));
      await tester.pumpAndSettle();
      expect(updatedRows.length, 2);
      expect(
          updatedRows
              .any((r) => r['mpda_crime_type'] == 'Crimes against the body'),
          isTrue);
      expect(updatedRows.any((r) => r['mpda_crime_type'] == 'Murder'), isTrue);

      // Tap on "Other special" -> All 3 are selected simultaneously and "Specify Crime Type" appears
      await tester.tap(find.text('Other special'));
      await tester.pumpAndSettle();
      expect(find.text('Specify Crime Type / Name'), findsOneWidget);
      expect(updatedRows.length, 3);
      expect(updatedRows.any((r) => r['mpda_crime_type'] == 'Other special'),
          isTrue);

      // Type in the custom crime field
      final customCrimeFinder = find.byWidgetPredicate((w) =>
          w is TextField &&
          w.decoration?.hintText?.contains('other crime') == true);
      await tester.enterText(customCrimeFinder, 'Cyber Crime');
      await tester.pumpAndSettle();
      expect(updatedRows.any((r) => r['mpda_crime_type'] == 'Cyber Crime'),
          isTrue);
      expect(
          updatedRows.any((r) => r['mpda_crime_other_type'] == 'Cyber Crime'),
          isTrue);

      // Tap on "Murder" again -> unselects only "Murder", leaving 2 selected
      await tester.tap(find.text('Murder'));
      await tester.pumpAndSettle();
      expect(updatedRows.length, 2);
      expect(updatedRows.any((r) => r['mpda_crime_type'] == 'Murder'), isFalse);
      expect(
          updatedRows
              .any((r) => r['mpda_crime_type'] == 'Crimes against the body'),
          isTrue);

      ApiService.clientForTesting = null;
    });
  });
}
