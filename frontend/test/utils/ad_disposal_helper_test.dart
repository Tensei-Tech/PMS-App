import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/modules/core/models/base_record.dart';
import 'package:khakhi_diary/utils/ad_disposal_helper.dart';

ModuleRecord _record({
  required String moduleKey,
  required String status,
  Map<String, dynamic> extraFields = const {},
}) =>
    ModuleRecord(
      id: 'TEST-$moduleKey-$status',
      moduleKey: moduleKey,
      title: 'TEST Case',
      caseNumber: 'TEST/1/2026',
      description: 'TEST',
      complainant: 'TEST',
      accused: 'N/A',
      location: 'TEST',
      incidentDate: DateTime(2026, 1, 1),
      priority: 'Medium',
      status: status,
      assignedOfficer: 'TEST Officer',
      extraFields: extraFields,
    );

void main() {
  group('AD Disposal Helper Tests', () {
    test('AD case is recognised by module key or sub-category', () {
      expect(isAdCase(_record(moduleKey: 'ad', status: 'Pending')), isTrue);
      expect(
          isAdCase(
              {'module_key': 'missing', 'sub_category': 'Accidental Death'}),
          isTrue);
      expect(isAdCase(_record(moduleKey: 'theft', status: 'Pending')), isFalse);
    });

    test('AD case is Disposal when the backend saved status Disposal', () {
      final record = _record(moduleKey: 'ad', status: 'Disposal');
      expect(isRecordDisposal(record), isTrue);
      expect(isRecordPending(record), isFalse);
    });

    test('AD answers alone do not make Disposal: the backend status decides',
        () {
      // The rule (which answer, which value, which date) lives in the backend
      // module_settings; until the backend saves Disposal the case is Pending.
      final record = _record(
        moduleKey: 'ad',
        status: 'Pending',
        extraFields: {
          'ad_sdm_granted': 'Yes',
          'ad_sdm_granted_date': '15/01/2026',
        },
      );
      expect(isRecordDisposal(record), isFalse);
      expect(isRecordPending(record), isTrue);
    });

    test('Non-AD cases with status Closed/Disposal are recognized as Disposal',
        () {
      expect(isRecordDisposal(_record(moduleKey: 'theft', status: 'Closed')),
          isTrue);
      expect(isRecordPending(_record(moduleKey: 'theft', status: 'Pending')),
          isTrue);
    });

    test('Preventive Case with preventiveNo and date is classified as Disposal',
        () {
      final prevRecord = ModuleRecord(
        id: 'prev-1',
        moduleKey: 'preventive',
        title: 'Preventive Case 1',
        caseNumber: 'PREV/101/2026',
        description: 'Test preventive case',
        complainant: 'Officer P',
        accused: 'Accused 1',
        location: 'Pune',
        incidentDate: DateTime(2026, 1, 1),
        priority: 'Medium',
        status: 'Pending',
        assignedOfficer: 'PSI Deshmukh',
        extraFields: {
          'preventiveNo': '11',
          'preventiveDate': '26/10/2026',
          'outwardNo': '14',
        },
      );

      expect(isPreventiveCase(prevRecord), isTrue);
      expect(isPreventiveDisposalCase(prevRecord), isTrue);
      expect(isRecordDisposal(prevRecord), isTrue);
      expect(isRecordPending(prevRecord), isFalse);
    });

    test(
        'Preventive Case with Marathi keys (इस्तेगाशा नंबर + दिनांक) is classified as Disposal',
        () {
      final prevMarathi = ModuleRecord(
        id: 'prev-marathi',
        moduleKey: 'preventive',
        title: 'Preventive Marathi',
        caseNumber: 'PREV/102/2026',
        description: 'Test Marathi preventive',
        complainant: 'Officer M',
        accused: 'Accused 2',
        location: 'Nashik',
        incidentDate: DateTime(2026, 1, 1),
        priority: 'Medium',
        status: 'Under Investigation',
        assignedOfficer: 'PSI Shinde',
        extraFields: {
          'इस्तेगाशा नंबर': '45',
          'दिनांक': '20/10/2026',
        },
      );

      expect(isPreventiveCase(prevMarathi), isTrue);
      expect(isPreventiveDisposalCase(prevMarathi), isTrue);
      expect(isRecordDisposal(prevMarathi), isTrue);
    });

    test('Preventive Case missing date is NOT classified as Disposal', () {
      final prevNoDate = ModuleRecord(
        id: 'prev-no-date',
        moduleKey: 'preventive',
        title: 'Preventive No Date',
        caseNumber: 'PREV/103/2026',
        description: 'No date',
        complainant: 'Officer M',
        accused: 'Accused 3',
        location: 'Nashik',
        incidentDate: DateTime(2026, 1, 1),
        priority: 'Medium',
        status: 'Under Investigation',
        assignedOfficer: 'PSI Shinde',
        extraFields: {
          'preventiveNo': '45',
        },
      );

      expect(isPreventiveCase(prevNoDate), isTrue);
      expect(isPreventiveDisposalCase(prevNoDate), isFalse);
      expect(isRecordDisposal(prevNoDate), isFalse);
    });
  });
}
