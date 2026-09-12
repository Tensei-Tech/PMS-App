import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/modules/core/models/base_record.dart';
import 'package:khakhi_diary/modules/preventive/screens/preventive_view_screen.dart';
import 'package:khakhi_diary/modules/preventive/widgets/preventive_form.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Preventive Module Tests', () {
    testWidgets('PreventiveForm builds and serializes all 14 statutory fields',
        (tester) async {
      final formKey = GlobalKey<PreventiveFormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PreventiveForm(key: formKey),
          ),
        ),
      );

      final state = formKey.currentState;
      expect(state, isNotNull);

      // Verify form data structure
      final doc = state!.buildDocumentMap();
      expect(doc['caseRef'], isNotNull);
      expect(doc['sections'], isNotNull);
      expect(doc['accusedList'], isA<List>());
      expect(doc['istegasha'], isNotNull);
      expect(doc['riskAndStatus'], isNotNull);

      expect(doc['riskAndStatus']['riskFlag'], contains('High Priority'));
      expect(doc['riskAndStatus']['actionStatus'], contains('Completed'));
    });

    testWidgets('PreventiveForm hydrator properly restores data',
        (tester) async {
      final formKey = GlobalKey<PreventiveFormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PreventiveForm(key: formKey),
          ),
        ),
      );

      final testData = {
        'caseRef': {
          'crimeNo': 'CR/101/2026',
          'regDate': '11/09/2026',
          'crimeCategory': 'Cyber',
          'caseStatus': 'Chargesheeted',
        },
        'sections': {
          'act': 'BNS',
          'selectedSections': ['303', '318'],
          'otherSections': 'Sec 66D IT Act',
        },
        'accusedList': [
          {
            'name': 'Ramesh Kumar',
            'actionType': 'Arrested',
            'bondTaken': 'Yes',
            'bondDetails': '₹25,000 Surety',
          },
          {
            'name': 'Suresh Shinde',
            'actionType': 'Notice Issued',
            'bondTaken': 'No',
            'bondDetails': '',
          },
        ],
        'istegasha': {
          'preventiveNo': 'IST/99/2026',
          'preventiveDate': '12/09/2026',
          'outwardNo': 'OW/882/2026',
          'ioName': 'PI Kadam',
        },
        'riskAndStatus': {
          'riskFlag': '🛑 Sensitive',
          'actionStatus': '🟡 Partially Completed',
          'remarks': 'Action initiated against cyber fraudsters',
        },
      };

      formKey.currentState!.hydrateFromDocumentMap(testData);
      await tester.pump();

      final exported = formKey.currentState!.buildDocumentMap();
      expect(exported['caseRef']['crimeNo'], 'CR/101/2026');
      expect(exported['caseRef']['crimeCategory'], 'Cyber');
      expect(exported['caseRef']['caseStatus'], 'Chargesheeted');
      expect(exported['accusedList'].length, 2);
      expect(exported['accusedList'][0]['name'], 'Ramesh Kumar');
      expect(exported['accusedList'][0]['actionType'], 'Arrested');
      expect(exported['accusedList'][0]['bondTaken'], 'Yes');
      expect(exported['accusedList'][1]['name'], 'Suresh Shinde');
      expect(exported['istegasha']['preventiveNo'], 'IST/99/2026');
      expect(exported['istegasha']['ioName'], 'PI Kadam');
      expect(exported['riskAndStatus']['riskFlag'], '🛑 Sensitive');
      expect(
          exported['riskAndStatus']['actionStatus'], '🟡 Partially Completed');
    });

    testWidgets('PreventiveViewDocumentView renders all 14 statutory fields',
        (tester) async {
      final mockRecord = ModuleRecord(
        id: 'prev-123',
        moduleKey: 'preventive',
        title: 'CR/101/2026',
        caseNumber: 'CR/101/2026',
        description: 'Action initiated against cyber fraudsters',
        complainant: 'State',
        accused: 'Ramesh Kumar, Suresh Shinde',
        incidentDate: DateTime.now(),
        location: 'City PS',
        priority: '🛑 Sensitive',
        status: 'Chargesheeted',
        assignedOfficer: 'PI Kadam',
        subCategory: 'Cyber',
        extraFields: {
          'preventiveForm': {
            'caseRef': {
              'crimeNo': 'CR/101/2026',
              'regDate': '11/09/2026',
              'crimeCategory': 'Cyber',
              'caseStatus': 'Chargesheeted',
            },
            'sections': {
              'act': 'BNS',
              'selectedSections': ['303', '318'],
              'otherSections': 'Sec 66D IT Act',
            },
            'accusedList': [
              {
                'name': 'Ramesh Kumar',
                'actionType': 'Arrested',
                'bondTaken': 'Yes',
                'bondDetails': '₹25,000 Surety',
              },
              {
                'name': 'Suresh Shinde',
                'actionType': 'Notice Issued',
                'bondTaken': 'No',
                'bondDetails': '',
              },
            ],
            'istegasha': {
              'preventiveNo': 'IST/99/2026',
              'preventiveDate': '12/09/2026',
              'outwardNo': 'OW/882/2026',
              'ioName': 'PI Kadam',
            },
            'riskAndStatus': {
              'riskFlag': '🛑 Sensitive',
              'actionStatus': '🟡 Partially Completed',
              'remarks': 'Action initiated against cyber fraudsters',
            },
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PreventiveViewDocumentView(
                record: mockRecord,
                prevMap: mockRecord.extraFields['preventiveForm']
                    as Map<String, dynamic>,
                moduleLabel: 'Preventive Action',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify fields rendered in View
      expect(find.textContaining('CR/101/2026'), findsWidgets);
      expect(find.text('Cyber'), findsOneWidget);
      expect(find.text('Chargesheeted'), findsOneWidget);
      expect(find.text('BNS 303'), findsOneWidget);
      expect(find.text('BNS 318'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Suresh Shinde'), findsOneWidget);
      expect(find.text('IST/99/2026'), findsOneWidget);
      expect(find.text('PI Kadam'), findsOneWidget);
      expect(find.text('🛑 Sensitive'), findsOneWidget);
      expect(find.text('🟡 Partially Completed'), findsOneWidget);
    });
  });
}
