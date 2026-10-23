// test/nc_hub_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:khakhi_diary/modules/form_iv/providers/form_iv_provider.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/screens/nc/nc_hub_screen.dart';
import 'package:khakhi_diary/services/api_service.dart';
import 'package:khakhi_diary/services/case_service.dart';
import 'package:khakhi_diary/services/history_sheeter_service.dart';
import 'package:khakhi_diary/services/mpda_service.dart';
import 'package:khakhi_diary/services/nc_service.dart';
import 'package:khakhi_diary/services/rti_service.dart';
import 'package:khakhi_diary/utils/category_navigation_helper.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_control_factory.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_field_model.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_section_builder.dart';
import 'package:khakhi_diary/widgets/repeating_cascading_charges_selector.dart';

http.Response _json(Object body) => http.Response(jsonEncode(body), 200,
    headers: {'content-type': 'application/json'});

Map<String, dynamic> _config({String pending = 'TEST Pending'}) => {
      'target_category_code': 'STAND_NC',
      'sub_tab_labels': {
        'total': 'TEST Total',
        'pending': pending,
        'disposal': 'TEST Disposal',
      },
      'action_labels': {
        'add': 'TEST Add NC',
        'edit': 'TEST Edit',
        'view': 'TEST View',
        'pdf': 'TEST PDF',
      },
      'search_placeholder': 'TEST search',
      'empty_list_message': 'TEST nothing here',
      'messages': {'pdf_failed_message': 'TEST pdf failed'},
      'page_size': 2,
      'field_max_lengths': {'nc_first_information': 50},
      'serial_label': 'TEST Sr',
      'pending_definition': 'TEST pending means incomplete preventive',
    };

Widget _app(Widget home) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FormIVProvider()),
      ],
      child: MaterialApp(home: home),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService().setAuthToken('test-token');
    NcService().clearConfigCache();
    HistorySheeterService().clearCache();
    MpdaService().clearCache();
    RtiService().clearCache();
    CaseService().clearCache();
  });

  tearDown(() => ApiService.clientForTesting = null);

  _liveNamesTest();
  chargesInRowTest();

  testWidgets(
      'NC hub draws tabs, counts, list and actions from the backend only',
      (tester) async {
    final requests = <Uri>[];
    ApiService.clientForTesting = MockClient((req) async {
      requests.add(req.url);
      final p = req.url.path;
      if (p.endsWith('/api/nc/config/')) return _json(_config());
      if (p.endsWith('/api/nc/counts/')) {
        return _json({'total': 3, 'pending': 2, 'disposal': 1});
      }
      if (p.endsWith('/api/nc/')) {
        return _json({
          'results': [
            {
              'id': 1,
              'nc_no': 'TEST-NC-1',
              'registered_date': '01/10/2026',
              'complainants': ['TEST Complainant'],
              'non_applicants': ['TEST Non Applicant'],
              'crime_spot': 'TEST Village',
              'is_disposal': true,
              'status_label': 'TEST Disposal',
              // Card lines come from the backend with their labels
              'card_rows': [
                ['TEST NC No.', 'TEST-NC-1'],
                ['TEST Act', 'TEST Act Name'],
                ['TEST Complainant Label', 'TEST Complainant'],
              ],
              'preventive_label': 'TEST Preventive',
              'preventive_rows': [
                [
                  ['TEST Outward Number', 'TEST-OUT-1'],
                  ['TEST Bond Date', ''],
                ]
              ],
            }
          ],
          'next_cursor': null,
        });
      }
      return _json({});
    });

    await tester.pumpWidget(_app(const NcHubScreen(
        categoryName: 'N.C.', categoryCode: 'STAND_NC', moduleKey: 'nc')));
    await tester.pumpAndSettle();

    // New card: every requested line with its label; empty value shows '-'
    expect(find.text('TEST NC No.'), findsOneWidget);
    expect(find.text('TEST Act Name'), findsOneWidget);
    expect(find.text('TEST Complainant'), findsOneWidget);
    // Preventive fields sit in the same line as the main fields, no heading
    expect(find.text('TEST Preventive'), findsNothing);
    expect(find.text('TEST Outward Number'), findsOneWidget);
    // All boxes on ONE line: every label starts at the same height
    final labelTops = [
      'TEST NC No.',
      'TEST Act',
      'TEST Complainant Label',
      'TEST Outward Number',
      'TEST Bond Date',
    ].map((t) => tester.getTopLeft(find.text(t)).dy).toSet();
    expect(labelTops.length, 1);
    expect(find.text('TEST-OUT-1'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);

    expect(find.text('TEST Total'), findsOneWidget);
    expect(find.text('TEST Pending'), findsOneWidget);
    expect(find.text('TEST Disposal'), findsWidgets); // tab + status chip
    expect(find.text('2'), findsOneWidget);
    expect(find.text('TEST Add NC'), findsOneWidget);
    expect(find.text('TEST search'), findsOneWidget);
    expect(find.text('TEST-NC-1'), findsOneWidget);
    expect(find.text('TEST View'), findsOneWidget);
    expect(find.text('TEST Edit'), findsOneWidget);
    expect(find.text('TEST PDF'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
    expect(requests.any((u) => u.queryParameters['tab'] == 'total'), isTrue);
    expect(find.text('TEST Sr 1'), findsOneWidget);

    // Pending definition shows only on the Pending tab
    expect(find.text('TEST pending means incomplete preventive'), findsNothing);
    await tester.tap(find.text('TEST Pending'));
    await tester.pumpAndSettle();
    expect(
        find.text('TEST pending means incomplete preventive'), findsOneWidget);
  });

  testWidgets('a changed tab label in config is shown with no code change',
      (tester) async {
    ApiService.clientForTesting = MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/api/nc/config/')) {
        return _json(_config(pending: 'TEST Renamed Pending'));
      }
      if (p.endsWith('/api/nc/counts/')) return _json({});
      return _json({'results': [], 'next_cursor': null});
    });

    await tester.pumpWidget(_app(const NcHubScreen(
        categoryName: 'N.C.', categoryCode: 'STAND_NC', moduleKey: 'nc')));
    await tester.pumpAndSettle();

    expect(find.text('TEST Renamed Pending'), findsOneWidget);
    expect(find.text('TEST nothing here'), findsOneWidget);
  });

  testWidgets('switching tab requests that tab from the backend',
      (tester) async {
    final tabs = <String?>[];
    ApiService.clientForTesting = MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/api/nc/config/')) return _json(_config());
      if (p.endsWith('/api/nc/counts/')) return _json({});
      tabs.add(req.url.queryParameters['tab']);
      return _json({'results': [], 'next_cursor': null});
    });

    await tester.pumpWidget(_app(const NcHubScreen(
        categoryName: 'N.C.', categoryCode: 'STAND_NC', moduleKey: 'nc')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TEST Disposal'));
    await tester.pumpAndSettle();
    expect(tabs, containsAllInOrder(['total', 'disposal']));
  });

  group('form engine additions', () {
    testWidgets('rows: options list the names of another repeating group',
        (tester) async {
      final values = <String, dynamic>{
        'nc_non_applicants': [
          {'nc_na_name': 'TEST Alpha'},
          {'nc_na_name': 'TEST Beta'},
          {'nc_na_name': ''},
        ],
      };
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DynamicControlFactory(
            fieldDef: const DynamicFieldDef(
              fieldDefId: 1,
              fieldKey: 'nc_prev_person',
              fieldLabel: 'TEST Non Applicant',
              fieldSource: 'custom',
              fieldType: 'dropdown',
              isRequired: false,
              displayOrder: 1,
              optionsSource: 'rows:nc_non_applicants.nc_na_name',
            ),
            formValues: values,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('TEST Alpha'), findsWidgets);
      expect(find.text('TEST Beta'), findsWidgets);
    });

    testWidgets('charges field type draws the Act and Section picker',
        (tester) async {
      ApiService.clientForTesting =
          MockClient((req) async => _json(<dynamic>[]));
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DynamicControlFactory(
              fieldDef: DynamicFieldDef(
                fieldDefId: 2,
                fieldKey: 'nc_charges',
                fieldLabel: 'TEST Act and Section',
                fieldSource: 'custom',
                fieldType: 'charges',
                isRequired: false,
                displayOrder: 2,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('TEST Act and Section'), findsOneWidget);
      expect(find.byType(RepeatingCascadingChargesSelector), findsOneWidget);
    });

    testWidgets('maxLength from config limits a text area', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DynamicControlFactory(
            fieldDef: const DynamicFieldDef(
              fieldDefId: 3,
              fieldKey: 'nc_first_information',
              fieldLabel: 'TEST First information',
              fieldSource: 'custom',
              fieldType: 'textarea',
              isRequired: false,
              displayOrder: 3,
            ),
            controller: ctrl,
            maxLength: 5,
          ),
        ),
      ));
      await tester.enterText(find.byType(TextFormField), 'TEST_too_long');
      expect(ctrl.text.length, 5);
    });
  });

  testWidgets(
      'the N.C tile routes to the N.C. hub through target_category_code',
      (tester) async {
    ApiService.clientForTesting = MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/api/nc/config/')) return _json(_config());
      if (p.contains('/config/')) {
        return _json({'target_category_code': 'TEST_OTHER'});
      }
      if (p.endsWith('/api/nc/counts/')) return _json({});
      if (p.endsWith('/api/nc/')) {
        return _json({'results': [], 'next_cursor': null});
      }
      return _json(<dynamic>[]);
    });
    CaseService().setCategoriesCache([
      {
        'category_id': 245,
        'category_code': 'STAND_NC',
        'category_name': 'N.C.',
        'group': null,
        'parent_category': null,
        'is_active': true,
      }
    ]);

    late BuildContext ctx;
    await tester.pumpWidget(_app(Builder(builder: (c) {
      ctx = c;
      return const Scaffold();
    })));
    await CategoryNavigationHelper.handleDashboardCategoryTap(
      context: ctx,
      categoryName: 'N.C',
      moduleKey: 'nc',
    );
    await tester.pumpAndSettle();
    expect(find.byType(NcHubScreen), findsOneWidget);
  });
}

// Live update: names typed in the Non Applicant group appear in the
// Preventive person dropdown (two section cards sharing one values map).
void _liveNamesTest() {
  testWidgets('Preventive person dropdown lists Non Applicant names as typed',
      (tester) async {
    const naGroup = DynamicFieldDef(
        fieldDefId: 60,
        fieldKey: 'nc_non_applicants',
        fieldLabel: 'TEST Non Applicant',
        fieldSource: 'custom',
        fieldType: 'repeating_group',
        isRequired: false,
        displayOrder: 60,
        section: 'TEST Non Applicant');
    const naName = DynamicFieldDef(
        fieldDefId: 61,
        fieldKey: 'nc_na_name',
        fieldLabel: 'TEST Name',
        fieldSource: 'custom',
        fieldType: 'text',
        isRequired: false,
        displayOrder: 61,
        parentFieldKey: 'nc_non_applicants');
    const prevGroup = DynamicFieldDef(
        fieldDefId: 100,
        fieldKey: 'nc_preventive_actions',
        fieldLabel: 'TEST Preventive',
        fieldSource: 'custom',
        fieldType: 'repeating_group',
        isRequired: false,
        displayOrder: 100,
        section: 'TEST Preventive');
    const prevPerson = DynamicFieldDef(
        fieldDefId: 101,
        fieldKey: 'nc_prev_person',
        fieldLabel: 'TEST Person',
        fieldSource: 'custom',
        fieldType: 'dropdown',
        isRequired: false,
        displayOrder: 101,
        parentFieldKey: 'nc_preventive_actions',
        optionsSource: 'rows:nc_non_applicants.nc_na_name');
    const all = [naGroup, naName, prevGroup, prevPerson];

    final values = <String, dynamic>{
      'nc_non_applicants': [<String, dynamic>{}],
      'nc_preventive_actions': [<String, dynamic>{}],
    };
    final controllers = <String, TextEditingController>{};
    var requestedRows = false;
    ApiService.clientForTesting = MockClient((req) async {
      if (req.url.path.contains('rows:')) requestedRows = true;
      return _json(<dynamic>[]);
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(builder: (context, setState) {
          void changed(String k, dynamic v) => setState(() => values[k] = v);
          return ListView(children: [
            DynamicSectionCard(
                title: 'TEST Non Applicant',
                icon: Icons.person,
                fields: const [naGroup],
                controllers: controllers,
                values: values,
                onValueChanged: changed,
                allFormFields: all),
            DynamicSectionCard(
                title: 'TEST Preventive',
                icon: Icons.shield,
                fields: const [prevGroup],
                controllers: controllers,
                values: values,
                onValueChanged: changed,
                allFormFields: all),
          ]);
        }),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, '').first, 'TEST Ramesh');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    expect(find.text('TEST Ramesh'), findsWidgets);
    expect(requestedRows, isFalse);
  });
}

// History Sheeter Crime Chart: the Act / Section / Subsection picker inside a
// repeating row allows exactly one charge (no "Add Another Charge").
void chargesInRowTest() {
  testWidgets('charges field inside a repeating row is limited to one charge',
      (tester) async {
    ApiService.clientForTesting = MockClient((req) async => _json(<dynamic>[]));
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DynamicControlFactory(
            fieldDef: DynamicFieldDef(
              fieldDefId: 323,
              fieldKey: 'hs_crime_act_section',
              fieldLabel: 'TEST Act / Section / Subsection',
              fieldSource: 'custom',
              fieldType: 'charges',
              isRequired: false,
              displayOrder: 323,
              parentFieldKey: 'hs_crime_chart',
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(RepeatingCascadingChargesSelector), findsOneWidget);
    expect(find.text('Add Another Charge'), findsNothing);
  });
}
