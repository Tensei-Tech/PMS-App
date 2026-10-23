// test/dynamic_engine_prerequisites_test.dart
// Tests for dynamic engine prerequisites:
// - DynamicFieldDef with depends_on_field_key, depends_on_value, options_source
// - Conditional field visibility & value/controller clearing on hide
// - Cascading parent-child hiding in the same pass
// - Radio button control & value saving
// - Dynamic options loading with session caching & station-keyed cache
// - Cache clearing on logout

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/services/api_service.dart';
import 'package:khakhi_diary/services/dynamic_options_service.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_field_model.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_control_factory.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_section_builder.dart';
import 'utils/mock_api_client.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    ApiService.clientForTesting = createMockApiClient();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  tearDownAll(() {
    ApiService.clientForTesting = null;
  });

  setUp(() {
    DynamicOptionsService().clearCache();
  });

  group('Dynamic Options Service & Session Caching', () {
    test('loads options from route and caches in memory for session', () async {
      final service = DynamicOptionsService();

      // First call loads from mock API
      final opts1 = await service.fetchOptions('/options/marital_status/');
      expect(opts1.length, equals(3));
      expect(opts1, equals(['Single', 'Married', 'Divorced']));

      // Second call uses cached result
      expect(service.hasCached('/options/marital_status/'), isTrue);
      final opts2 = await service.fetchOptions('/options/marital_status/');
      expect(opts2, equals(opts1));
    });

    test('officer route cache is partitioned by stationId', () async {
      final service = DynamicOptionsService();

      final optsStation1 =
          await service.fetchOptions('/options/officers/', stationId: '1');
      final optsStation2 =
          await service.fetchOptions('/options/officers/', stationId: '2');

      expect(optsStation1.first, contains('Station 1'));
      expect(optsStation2.first, contains('Station 2'));
    });

    test('unknown option group returns empty list without error', () async {
      final service = DynamicOptionsService();
      final opts = await service.fetchOptions('/options/unknown_group/');
      expect(opts, isEmpty);
    });

    test('clearCache resets in-memory cache on logout', () async {
      final service = DynamicOptionsService();

      await service.fetchOptions('/options/marital_status/');
      expect(service.hasCached('/options/marital_status/'), isTrue);

      service.clearCache();
      expect(service.hasCached('/options/marital_status/'), isFalse);
    });
  });

  group('DynamicFieldDef Model Serialization', () {
    test('parses and serializes conditional visibility & optionsSource fields',
        () {
      final json = {
        'id': 101,
        'field_key': 'vehicle_registration',
        'field_label': 'Vehicle Registration Number',
        'field_type': 'text',
        'field_source': 'custom',
        'is_required': false,
        'section': 'Vehicle Details',
        'display_order': 10,
        'depends_on_field_key': 'has_vehicle',
        'depends_on_value': 'Yes',
        'options_source': '/options/vehicles/',
      };

      final field = DynamicFieldDef.fromJson(json);
      expect(field.fieldDefId, equals(101));
      expect(field.fieldKey, equals('vehicle_registration'));
      expect(field.dependsOnFieldKey, equals('has_vehicle'));
      expect(field.dependsOnValue, equals('Yes'));
      expect(field.optionsSource, equals('/options/vehicles/'));

      final serialized = field.toJson();
      expect(serialized['depends_on_field_key'], equals('has_vehicle'));
      expect(serialized['depends_on_value'], equals('Yes'));
      expect(serialized['options_source'], equals('/options/vehicles/'));
    });
  });

  group('Dynamic Section Card & Control Factory', () {
    testWidgets(
        'conditional field appears when parent matches and disappears + clears when parent changes',
        (tester) async {
      const parentField = DynamicFieldDef(
        fieldDefId: 1,
        fieldKey: 'has_vehicle',
        fieldLabel: 'Has Vehicle',
        fieldSource: 'custom',
        fieldType: 'radio',
        isRequired: false,
        section: 'General',
        displayOrder: 1,
        options: ['Yes', 'No'],
      );

      const childField = DynamicFieldDef(
        fieldDefId: 2,
        fieldKey: 'vehicle_no',
        fieldLabel: 'Vehicle Number',
        fieldSource: 'custom',
        fieldType: 'text',
        isRequired: false,
        section: 'General',
        displayOrder: 2,
        dependsOnFieldKey: 'has_vehicle',
        dependsOnValue: 'Yes',
      );

      final fields = [parentField, childField];
      final formValues = <String, dynamic>{'has_vehicle': 'No'};
      final controllers = <String, TextEditingController>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DynamicSectionCard(
                  title: 'General',
                  icon: Icons.folder,
                  fields: fields,
                  values: formValues,
                  controllers: controllers,
                  onValueChanged: (key, val) {
                    setState(() {
                      if (val == null) {
                        formValues.remove(key);
                      } else {
                        formValues[key] = val;
                      }
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially 'No' -> childField should NOT be visible
      expect(find.text('Vehicle Number'), findsNothing);

      // Select 'Yes' on Radio
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      // Now childField should be visible
      expect(find.text('Vehicle Number'), findsOneWidget);

      // Enter text into child field
      await tester.enterText(find.byType(TextField), 'MH-12-AB-1234');
      await tester.pumpAndSettle();
      expect(formValues['vehicle_no'], equals('MH-12-AB-1234'));

      // Switch Radio to 'No' -> child field must disappear and value must be cleared
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      expect(find.text('Vehicle Number'), findsNothing);
      expect(formValues.containsKey('vehicle_no'), isFalse);
    });

    testWidgets('cascading hide: hiding parent hides child in same pass',
        (tester) async {
      const rootField = DynamicFieldDef(
        fieldDefId: 10,
        fieldKey: 'has_weapon',
        fieldLabel: 'Has Weapon',
        fieldSource: 'custom',
        fieldType: 'radio',
        isRequired: false,
        section: 'Crime Details',
        displayOrder: 1,
        options: ['Yes', 'No'],
      );

      const childField = DynamicFieldDef(
        fieldDefId: 11,
        fieldKey: 'weapon_type',
        fieldLabel: 'Weapon Type',
        fieldSource: 'custom',
        fieldType: 'radio',
        isRequired: false,
        section: 'Crime Details',
        displayOrder: 2,
        options: ['Firearm', 'Blade'],
        dependsOnFieldKey: 'has_weapon',
        dependsOnValue: 'Yes',
      );

      const grandChildField = DynamicFieldDef(
        fieldDefId: 12,
        fieldKey: 'firearm_caliber',
        fieldLabel: 'Firearm Caliber',
        fieldSource: 'custom',
        fieldType: 'text',
        isRequired: false,
        section: 'Crime Details',
        displayOrder: 3,
        dependsOnFieldKey: 'weapon_type',
        dependsOnValue: 'Firearm',
      );

      final fields = [rootField, childField, grandChildField];
      final formValues = <String, dynamic>{
        'has_weapon': 'Yes',
        'weapon_type': 'Firearm',
        'firearm_caliber': '.32'
      };
      final controllers = <String, TextEditingController>{
        'firearm_caliber': TextEditingController(text: '.32')
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DynamicSectionCard(
                  title: 'Crime Details',
                  icon: Icons.shield,
                  fields: fields,
                  values: formValues,
                  controllers: controllers,
                  onValueChanged: (key, val) {
                    setState(() {
                      if (val == null) {
                        formValues.remove(key);
                      } else {
                        formValues[key] = val;
                      }
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // All 3 fields visible
      expect(find.text('Has Weapon'), findsOneWidget);
      expect(find.text('Weapon Type'), findsOneWidget);
      expect(find.text('Firearm Caliber'), findsOneWidget);

      // Tap 'No' on root 'Has Weapon'
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      // Both child and grandchild must be hidden and their values pruned
      expect(find.text('Weapon Type'), findsNothing);
      expect(find.text('Firearm Caliber'), findsNothing);
      expect(formValues.containsKey('weapon_type'), isFalse);
      expect(formValues.containsKey('firearm_caliber'), isFalse);
    });

    testWidgets('radio button group updates values and triggers callback',
        (tester) async {
      String? selectedVal;
      const radioField = DynamicFieldDef(
        fieldDefId: 20,
        fieldKey: 'gender',
        fieldLabel: 'Gender',
        fieldSource: 'custom',
        fieldType: 'radio',
        isRequired: false,
        section: 'Basic',
        displayOrder: 1,
        options: ['Male', 'Female', 'Other'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DynamicControlFactory(
                  fieldDef: radioField,
                  value: selectedVal,
                  onChanged: (val) {
                    setState(() {
                      selectedVal = val as String?;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);

      await tester.tap(find.text('Female'));
      await tester.pumpAndSettle();

      expect(selectedVal, equals('Female'));
    });
  });
}
