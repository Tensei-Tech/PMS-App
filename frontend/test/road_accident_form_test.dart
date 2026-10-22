// test/road_accident_form_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:khakhi_diary/services/api_service.dart';
import 'package:khakhi_diary/services/case_service.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/modules/form_iv/providers/form_iv_provider.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_form_screen.dart';
import 'package:khakhi_diary/modules/core/models/base_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService().setAuthToken('test-token');
    CaseService().clearCache();
  });

  const formDefinitionMock = '''{
    "category_id": 268,
    "category_code": "ACC_RASH",
    "category_name": "Death Due to Rash Driving",
    "has_linked_bundle": true,
    "sections": [
      {
        "section_key": "accident_details",
        "section_title": "Accident Details",
        "display_order": 1
      },
      {
        "section_key": "vehicles_involved",
        "section_title": "Vehicles Involved",
        "display_order": 2
      },
      {
        "section_key": "injured_details",
        "section_title": "Injured Details",
        "display_order": 3
      },
      {
        "section_key": "deceased_details",
        "section_title": "Deceased Details",
        "display_order": 4
      },
      {
        "section_key": "investigation_compliance",
        "section_title": "Investigation & Compliance",
        "display_order": 5
      }
    ],
    "fields": [
      {
        "field_key": "acc_vehicle_abandoned",
        "field_label": "Vehicle abandoned Y/N",
        "field_type": "dropdown",
        "section_key": "accident_details",
        "options": ["Yes", "No"]
      },
      {
        "field_key": "acc_driver_subsequently_traced",
        "field_label": "Driver subsequently traced Y/N",
        "field_type": "dropdown",
        "section_key": "accident_details",
        "options": ["Yes", "No"]
      },
      {
        "field_key": "acc_nature_of_accident",
        "field_label": "Nature of Accident",
        "field_type": "dropdown",
        "section_key": "accident_details",
        "options": ["Collision", "Pedestrian hit", "Overturning", "Over speed", "Dangerous overtaking", "Wrong side driving", "Fall", "Stationary vehicle", "Other"]
      },
      {
        "field_key": "acc_vehicles",
        "field_label": "Vehicles Involved",
        "field_type": "repeating_group",
        "section_key": "vehicles_involved"
      },
      {
        "field_key": "acc_veh_number",
        "field_label": "Vehicle number",
        "field_type": "text",
        "parent_field_key": "acc_vehicles"
      },
      {
        "field_key": "acc_veh_name",
        "field_label": "Vehicle Name",
        "field_type": "text",
        "parent_field_key": "acc_vehicles"
      },
      {
        "field_key": "acc_injured",
        "field_label": "Injured Details",
        "field_type": "repeating_group",
        "section_key": "injured_details"
      },
      {
        "field_key": "acc_inj_name",
        "field_label": "Name of injured",
        "field_type": "text",
        "parent_field_key": "acc_injured"
      },
      {
        "field_key": "acc_deceased",
        "field_label": "Deceased Details",
        "field_type": "repeating_group",
        "section_key": "deceased_details"
      },
      {
        "field_key": "acc_dec_name",
        "field_label": "Name of deceased",
        "field_type": "text",
        "parent_field_key": "acc_deceased"
      },
      {
        "field_key": "acc_victim_identity_established",
        "field_label": "Identity of victim(s) established - Y/N",
        "field_type": "dropdown",
        "section_key": "investigation_compliance",
        "options": ["Yes", "No"]
      },
      {
        "field_key": "acc_irad",
        "field_label": "IRAD Y/N",
        "field_type": "dropdown",
        "section_key": "investigation_compliance",
        "options": ["Yes", "No"]
      },
      {
        "field_key": "acc_irad_date",
        "field_label": "IRAD Date",
        "field_type": "date",
        "section_key": "investigation_compliance",
        "depends_on_field_key": "acc_irad",
        "depends_on_value": "Yes"
      }
    ]
  }''';

  Widget buildTestWidget(
      {ModuleRecord? record, Map<String, dynamic>? initialData}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FormIVProvider()),
      ],
      child: MaterialApp(
        home: DynamicFormScreen(
          moduleLabel: 'Death Due to Rash Driving',
          moduleKey: 'form_1_5',
          subCategory: 'Death Due to Rash Driving',
          existingRecord: record,
          initialData: initialData,
        ),
      ),
    );
  }

  testWidgets(
      'DynamicFormScreen populates Road Accident fields and repeating groups on View/Edit',
      (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('/form-definition/')) {
        return http.Response(formDefinitionMock, 200,
            headers: {'content-type': 'application/json'});
      }
      return http.Response('{}', 200,
          headers: {'content-type': 'application/json'});
    });
    ApiService.clientForTesting = mockClient;
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final testRecord = ModuleRecord(
      id: 'ACC_123',
      moduleKey: 'form_1_5',
      title: 'Road Accident Case',
      caseNumber: 'CR/2026/999',
      description: 'Accident report',
      complainant: 'Officer Patil',
      accused: 'Ramesh Driver',
      location: 'Pune Bypass',
      incidentDate: DateTime.now(),
      priority: 'High',
      status: 'Open',
      assignedOfficer: 'PI Kulkarni',
      subCategory: 'Death Due to Rash Driving',
      extraFields: {
        'acc_nature_of_accident': 'Collision',
        'acc_vehicle_abandoned': 'Yes',
        'acc_driver_subsequently_traced': 'No',
        'acc_victim_identity_established': 'Yes',
        'acc_irad': 'Yes',
        'acc_irad_date': '14/10/2026',
        'acc_vehicles': [
          {
            'acc_veh_number': 'MH-12-XY-9999',
            'acc_veh_name': 'Scorpio',
          }
        ],
        'acc_injured': [
          {
            'acc_inj_name': 'Ganesh Gaikwad',
          }
        ],
        'acc_deceased': [
          {
            'acc_dec_name': 'Sunil Kamble',
          }
        ]
      },
    );

    await tester.pumpWidget(buildTestWidget(record: testRecord));
    await tester.pumpAndSettle();

    // Verify form rendered the accident fields
    expect(find.text('Vehicle abandoned Y/N'), findsOneWidget);
    expect(find.text('Vehicles Involved'), findsWidgets);
    expect(find.text('Injured Details'), findsWidgets);
    expect(find.text('Deceased Details'), findsWidgets);

    // Verify repeating group cards hydrated
    expect(find.text('MH-12-XY-9999'), findsOneWidget);
    expect(find.text('Scorpio'), findsOneWidget);
    expect(find.text('Ganesh Gaikwad'), findsOneWidget);
    expect(find.text('Sunil Kamble'), findsOneWidget);
  });
}
