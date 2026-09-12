import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/modules/core/models/base_record.dart';
import 'package:khakhi_diary/utils/ad_disposal_helper.dart';

void main() {
  group('AD Disposal Helper Tests', () {
    test(
        'AD Case with both summaryNo and summaryDate is classified as Disposal',
        () {
      final record = ModuleRecord(
        id: 'ad-1',
        moduleKey: 'ad',
        title: 'AD Case 1',
        caseNumber: 'AD/101/2026',
        description: 'Test AD case',
        complainant: 'Officer A',
        accused: 'N/A',
        location: 'Pune',
        incidentDate: DateTime(2026, 1, 1),
        priority: 'Medium',
        status: 'Open',
        assignedOfficer: 'PSI Sharma',
        extraFields: {
          'adSummaryNo': '12/2026',
          'adSummaryDate': '15/01/2026',
        },
      );

      expect(isAdCase(record), isTrue);
      expect(isAdDisposalCase(record), isTrue);
      expect(isRecordDisposal(record), isTrue);
      expect(isRecordPending(record), isFalse);
    });

    test(
        'AD Case with Marathi keys (मर्ग समरी No. + मर्ग समरी दिनांक) is classified as Disposal',
        () {
      final record = ModuleRecord(
        id: 'ad-marathi',
        moduleKey: 'ad',
        title: 'AD Case Marathi',
        caseNumber: 'AD/102/2026',
        description: 'Test Marathi keys',
        complainant: 'Officer B',
        accused: 'N/A',
        location: 'Mumbai',
        incidentDate: DateTime(2026, 1, 1),
        priority: 'Medium',
        status: 'Open',
        assignedOfficer: 'PSI Patil',
        extraFields: {
          'मर्ग समरी No.': '45/2026',
          'मर्ग समरी दिनांक': '20/01/2026',
        },
      );

      expect(isAdDisposalCase(record), isTrue);
      expect(isRecordDisposal(record), isTrue);
      expect(isRecordPending(record), isFalse);
    });

    test(
        'AD Case with nested summary fields in extraFields is classified as Disposal',
        () {
      final record = ModuleRecord(
        id: 'ad-nested',
        moduleKey: 'ad',
        title: 'AD Nested',
        caseNumber: 'AD/103/2026',
        description: 'Test nested keys',
        complainant: 'Officer C',
        accused: 'N/A',
        location: 'Nagpur',
        incidentDate: DateTime(2026, 1, 1),
        priority: 'Medium',
        status: 'Pending',
        assignedOfficer: 'PSI Kadam',
        extraFields: {
          'finalReport': {
            'summaryNumber': '88/2026',
            'summaryDate': '25/02/2026',
          },
        },
      );

      expect(isAdDisposalCase(record), isTrue);
      expect(isRecordDisposal(record), isTrue);
    });

    test(
        'AD Case with only summaryNo missing summaryDate is NOT classified as Disposal',
        () {
      final record = ModuleRecord(
        id: 'ad-missing-date',
        moduleKey: 'ad',
        title: 'AD Missing Date',
        caseNumber: 'AD/104/2026',
        description: 'Missing Date',
        complainant: 'Officer D',
        accused: 'N/A',
        location: 'Nashik',
        incidentDate: DateTime(2026, 1, 1),
        priority: 'Medium',
        status: 'Open',
        assignedOfficer: 'PSI Shinde',
        extraFields: {
          'adSummaryNo': '99/2026',
          'adSummaryDate': '',
        },
      );

      expect(isAdDisposalCase(record), isFalse);
      expect(isRecordDisposal(record), isFalse);
      expect(isRecordPending(record), isTrue);
    });

    test(
        'AD Case with only summaryDate missing summaryNo is NOT classified as Disposal',
        () {
      final record = ModuleRecord(
        id: 'ad-missing-no',
        moduleKey: 'ad',
        title: 'AD Missing No',
        caseNumber: 'AD/105/2026',
        description: 'Missing No',
        complainant: 'Officer E',
        accused: 'N/A',
        location: 'Thane',
        incidentDate: DateTime(2026, 1, 1),
        priority: 'Medium',
        status: 'Pending',
        assignedOfficer: 'PSI Joshi',
        extraFields: {
          'adSummaryNo': '',
          'adSummaryDate': '12/03/2026',
        },
      );

      expect(isAdDisposalCase(record), isFalse);
      expect(isRecordDisposal(record), isFalse);
      expect(isRecordPending(record), isTrue);
    });

    test('Non-AD cases are NOT affected by AD summary fields check', () {
      final theftRecord = ModuleRecord(
        id: 'theft-1',
        moduleKey: 'theft',
        title: 'Theft Case 1',
        caseNumber: 'TH/01/2026',
        description: 'Theft Case',
        complainant: 'Citizen A',
        accused: 'Unknown',
        location: 'Kolhapur',
        incidentDate: DateTime(2026, 1, 1),
        priority: 'Low',
        status: 'Pending',
        assignedOfficer: 'PSI Raut',
        extraFields: {
          'adSummaryNo': '123',
          'adSummaryDate': '12/03/2026',
        },
      );

      expect(isAdCase(theftRecord), isFalse);
      expect(isAdDisposalCase(theftRecord), isFalse);
      // Because theft status is 'Pending', it should remain pending
      expect(isRecordDisposal(theftRecord), isFalse);
      expect(isRecordPending(theftRecord), isTrue);
    });

    test('Non-AD cases with status Closed/Disposal are recognized as Disposal',
        () {
      final theftClosed = ModuleRecord(
        id: 'theft-2',
        moduleKey: 'theft',
        title: 'Theft Closed',
        caseNumber: 'TH/02/2026',
        description: 'Theft Closed',
        complainant: 'Citizen B',
        accused: 'Known',
        location: 'Satara',
        incidentDate: DateTime(2026, 1, 1),
        priority: 'Low',
        status: 'Closed',
        assignedOfficer: 'PSI Raut',
      );

      expect(isRecordDisposal(theftClosed), isTrue);
      expect(isRecordPending(theftClosed), isFalse);
    });
  });
}
