import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_field_model.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_section_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Same As Above - Dynamic Generic Copy-on-Tick Tests', () {
    testWidgets('1. Ticking copies the value and target field stays editable',
        (tester) async {
      final controllers = <String, TextEditingController>{};
      final values = <String, dynamic>{};

      const tickKey = 'dyn_copy_trigger';
      const srcKey = 'dyn_source_field';
      const tgtKey = 'dyn_target_field';

      final rules = [
        {
          'trigger_field': tickKey,
          'source_field': srcKey,
          'target_field': tgtKey,
        }
      ];

      final fields = <DynamicFieldDef>[
        const DynamicFieldDef(
          fieldDefId: 1,
          fieldLabel: 'Source Address',
          fieldKey: srcKey,
          fieldSource: 'custom',
          fieldType: 'textarea',
          isRequired: false,
          section: 'Addresses',
          displayOrder: 1,
        ),
        const DynamicFieldDef(
          fieldDefId: 2,
          fieldLabel: 'Target Address',
          fieldKey: tgtKey,
          fieldSource: 'custom',
          fieldType: 'textarea',
          isRequired: false,
          section: 'Addresses',
          displayOrder: 2,
        ),
        const DynamicFieldDef(
          fieldDefId: 3,
          fieldLabel: 'Same as Above Choice',
          fieldKey: tickKey,
          fieldSource: 'custom',
          fieldType: 'checkbox',
          isRequired: false,
          section: 'Addresses',
          displayOrder: 3,
        ),
      ];

      controllers[srcKey] = TextEditingController(text: '123 MG Road, Pune');
      values[srcKey] = '123 MG Road, Pune';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicSectionCard(
              title: 'Addresses',
              icon: Icons.location_on,
              fields: fields,
              controllers: controllers,
              values: values,
              copyOnTickRules: rules,
              onValueChanged: (k, v) {
                values[k] = v;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially target is empty
      expect(controllers[tgtKey]?.text ?? '', isEmpty);

      // Tap the checkbox to tick it
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Target field must now have copied the source value
      expect(values[tgtKey], equals('123 MG Road, Pune'));
      expect(controllers[tgtKey]?.text, equals('123 MG Road, Pune'));

      // Target field stays editable afterwards: user types additional details
      controllers[tgtKey]?.text = '123 MG Road, Pune - Near Station';
      values[tgtKey] = '123 MG Road, Pune - Near Station';
      await tester.pumpAndSettle();

      expect(controllers[tgtKey]?.text,
          equals('123 MG Road, Pune - Near Station'));
    });

    testWidgets('2. Ticking when source is empty copies an empty value',
        (tester) async {
      final controllers = <String, TextEditingController>{};
      final values = <String, dynamic>{};

      const tickKey = 'dyn_copy_trigger';
      const srcKey = 'dyn_source_field';
      const tgtKey = 'dyn_target_field';

      final rules = [
        {
          'trigger_field': tickKey,
          'source_field': srcKey,
          'target_field': tgtKey,
        }
      ];

      final fields = <DynamicFieldDef>[
        const DynamicFieldDef(
          fieldDefId: 1,
          fieldLabel: 'Source Field',
          fieldKey: srcKey,
          fieldSource: 'custom',
          fieldType: 'textarea',
          isRequired: false,
          section: 'Addresses',
          displayOrder: 1,
        ),
        const DynamicFieldDef(
          fieldDefId: 2,
          fieldLabel: 'Target Field',
          fieldKey: tgtKey,
          fieldSource: 'custom',
          fieldType: 'textarea',
          isRequired: false,
          section: 'Addresses',
          displayOrder: 2,
        ),
        const DynamicFieldDef(
          fieldDefId: 3,
          fieldLabel: 'Same as Above Choice',
          fieldKey: tickKey,
          fieldSource: 'custom',
          fieldType: 'checkbox',
          isRequired: false,
          section: 'Addresses',
          displayOrder: 3,
        ),
      ];

      // Source is empty
      controllers[srcKey] = TextEditingController(text: '');
      values[srcKey] = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicSectionCard(
              title: 'Addresses',
              icon: Icons.location_on,
              fields: fields,
              controllers: controllers,
              values: values,
              copyOnTickRules: rules,
              onValueChanged: (k, v) {
                values[k] = v;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final checkboxFinder = find.byType(Checkbox);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      expect(values[tgtKey], equals(''));
      expect(controllers[tgtKey]?.text, equals(''));
    });

    testWidgets('3. Unticking changes nothing (target keeps current value)',
        (tester) async {
      final controllers = <String, TextEditingController>{};
      final values = <String, dynamic>{};

      const tickKey = 'dyn_copy_trigger';
      const srcKey = 'dyn_source_field';
      const tgtKey = 'dyn_target_field';

      final rules = [
        {
          'trigger_field': tickKey,
          'source_field': srcKey,
          'target_field': tgtKey,
        }
      ];

      final fields = <DynamicFieldDef>[
        const DynamicFieldDef(
          fieldDefId: 1,
          fieldLabel: 'Source Address',
          fieldKey: srcKey,
          fieldSource: 'custom',
          fieldType: 'textarea',
          isRequired: false,
          section: 'Addresses',
          displayOrder: 1,
        ),
        const DynamicFieldDef(
          fieldDefId: 2,
          fieldLabel: 'Target Address',
          fieldKey: tgtKey,
          fieldSource: 'custom',
          fieldType: 'textarea',
          isRequired: false,
          section: 'Addresses',
          displayOrder: 2,
        ),
        const DynamicFieldDef(
          fieldDefId: 3,
          fieldLabel: 'Same as Above Choice',
          fieldKey: tickKey,
          fieldSource: 'custom',
          fieldType: 'checkbox',
          isRequired: false,
          section: 'Addresses',
          displayOrder: 3,
        ),
      ];

      controllers[srcKey] = TextEditingController(text: 'Initial Source Text');
      values[srcKey] = 'Initial Source Text';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicSectionCard(
              title: 'Addresses',
              icon: Icons.location_on,
              fields: fields,
              controllers: controllers,
              values: values,
              copyOnTickRules: rules,
              onValueChanged: (k, v) {
                values[k] = v;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tick
      final checkboxFinder = find.byType(Checkbox);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();
      expect(controllers[tgtKey]?.text, equals('Initial Source Text'));

      // Modify target text manually
      controllers[tgtKey]?.text = 'Modified Target Text';
      values[tgtKey] = 'Modified Target Text';
      await tester.pumpAndSettle();

      // Untick
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Target text MUST NOT be cleared or changed on untick
      expect(controllers[tgtKey]?.text, equals('Modified Target Text'));
      expect(values[tgtKey], equals('Modified Target Text'));
    });

    testWidgets('4. Editing source address after the tick changes nothing',
        (tester) async {
      final controllers = <String, TextEditingController>{};
      final values = <String, dynamic>{};

      const tickKey = 'dyn_copy_trigger';
      const srcKey = 'dyn_source_field';
      const tgtKey = 'dyn_target_field';

      final rules = [
        {
          'trigger_field': tickKey,
          'source_field': srcKey,
          'target_field': tgtKey,
        }
      ];

      final fields = <DynamicFieldDef>[
        const DynamicFieldDef(
          fieldDefId: 1,
          fieldLabel: 'Source Address',
          fieldKey: srcKey,
          fieldSource: 'custom',
          fieldType: 'textarea',
          isRequired: false,
          section: 'Addresses',
          displayOrder: 1,
        ),
        const DynamicFieldDef(
          fieldDefId: 2,
          fieldLabel: 'Target Address',
          fieldKey: tgtKey,
          fieldSource: 'custom',
          fieldType: 'textarea',
          isRequired: false,
          section: 'Addresses',
          displayOrder: 2,
        ),
        const DynamicFieldDef(
          fieldDefId: 3,
          fieldLabel: 'Same as Above Choice',
          fieldKey: tickKey,
          fieldSource: 'custom',
          fieldType: 'checkbox',
          isRequired: false,
          section: 'Addresses',
          displayOrder: 3,
        ),
      ];

      controllers[srcKey] = TextEditingController(text: 'Original Address');
      values[srcKey] = 'Original Address';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicSectionCard(
              title: 'Addresses',
              icon: Icons.location_on,
              fields: fields,
              controllers: controllers,
              values: values,
              copyOnTickRules: rules,
              onValueChanged: (k, v) {
                values[k] = v;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tick
      final checkboxFinder = find.byType(Checkbox);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();
      expect(controllers[tgtKey]?.text, equals('Original Address'));

      // Edit the source address afterwards
      controllers[srcKey]?.text = 'Updated New Source Address';
      values[srcKey] = 'Updated New Source Address';
      await tester.pumpAndSettle();

      // Target field MUST NOT follow later edits to source address
      expect(controllers[tgtKey]?.text, equals('Original Address'));
      expect(values[tgtKey], equals('Original Address'));
    });

    testWidgets(
        '5. Changing the setting to other field keys changes which fields copy, with no code change',
        (tester) async {
      final controllers = <String, TextEditingController>{};
      final values = <String, dynamic>{};

      // Completely different arbitrary field keys
      const tickKey = 'custom_check_alpha';
      const srcKey = 'custom_input_source';
      const tgtKey = 'custom_input_dest';

      final customRules = [
        {
          'trigger_field': tickKey,
          'source_field': srcKey,
          'target_field': tgtKey,
        }
      ];

      final fields = <DynamicFieldDef>[
        const DynamicFieldDef(
          fieldDefId: 10,
          fieldLabel: 'Custom Source',
          fieldKey: srcKey,
          fieldSource: 'custom',
          fieldType: 'text',
          isRequired: false,
          section: 'Custom Section',
          displayOrder: 1,
        ),
        const DynamicFieldDef(
          fieldDefId: 11,
          fieldLabel: 'Custom Target',
          fieldKey: tgtKey,
          fieldSource: 'custom',
          fieldType: 'text',
          isRequired: false,
          section: 'Custom Section',
          displayOrder: 2,
        ),
        const DynamicFieldDef(
          fieldDefId: 12,
          fieldLabel: 'Custom Tick',
          fieldKey: tickKey,
          fieldSource: 'custom',
          fieldType: 'checkbox',
          isRequired: false,
          section: 'Custom Section',
          displayOrder: 3,
        ),
      ];

      controllers[srcKey] = TextEditingController(text: 'Alpha Data Value');
      values[srcKey] = 'Alpha Data Value';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicSectionCard(
              title: 'Custom Section',
              icon: Icons.tune,
              fields: fields,
              controllers: controllers,
              values: values,
              copyOnTickRules: customRules,
              onValueChanged: (k, v) {
                values[k] = v;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controllers[tgtKey]?.text ?? '', isEmpty);

      final checkboxFinder = find.byType(Checkbox);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Custom target receives custom source value purely driven by the setting
      expect(controllers[tgtKey]?.text, equals('Alpha Data Value'));
      expect(values[tgtKey], equals('Alpha Data Value'));
    });

    test(
        '6. Verify Flutter codebase contains NO hardcoded hs_same_as_above, hs_permanent_address, or hs_present_address',
        () {
      final libDir = Directory('lib');
      final forbiddenKeys = [
        'hs_same_as_above',
        'hs_permanent_address',
        'hs_present_address',
      ];

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          // Exclude legacy dead files in modules/mpda as per instructions
          .where(
              (f) => !f.path.replaceAll(r'\', '/').contains('/modules/mpda/'))
          .toList();

      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final key in forbiddenKeys) {
          if (content.contains(key)) {
            violations.add(
                '${file.path} contains forbidden field key literal "$key"');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Flutter must NOT contain hardcoded History Sheeter address field keys:\n${violations.join('\n')}',
      );
    });
  });
}
