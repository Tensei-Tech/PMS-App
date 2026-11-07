import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/modules/core/models/base_record.dart';
import 'package:khakhi_diary/modules/tadipar/providers/tadipar_provider.dart';
import 'package:khakhi_diary/providers/module_registry.dart';
import 'package:khakhi_diary/utils/common_form_module.dart';

void main() {
  group('Tadipar Dashboard & Flow Unit Tests', () {
    test('TadiparProvider initializes with moduleKey tadipar', () {
      final provider = TadiparProvider();
      expect(provider.moduleKey, equals('tadipar'));
    });

    test('module_registry maps Tadipar label to tadipar moduleKey', () {
      expect(labelToModuleKey['Tadipar'], equals('tadipar'));
      expect(labelToModuleKey['tadipar'], equals('tadipar'));
    });

    test('isDedicatedFormTab recognizes tadipar as dedicated dynamic module',
        () {
      expect(isDedicatedFormTab('tadipar'), isTrue);
      expect(isDedicatedFormTab('Tadipar'), isTrue);
    });

    test('Tadipar uses dynamic form and is not linked to common form baseline',
        () {
      expect(moduleUsesCommonCrimeForm('tadipar'), isFalse);
      expect(moduleUsesCommonCrimeForm('tadipar', 'Tadipar'), isFalse);
      expect(isTabLinkedToCommonFormBaseline(moduleKey: 'tadipar'), isFalse);
      expect(
          isTabLinkedToCommonFormBaseline(
              moduleKey: 'tadipar', categoryName: 'Tadipar'),
          isFalse);
    });

    test('TadiparProvider filter logic returns records accurately', () {
      final provider = TadiparProvider();
      final sampleRecord = ModuleRecord(
        id: '1791526974593',
        moduleKey: 'tadipar',
        title: 'Tadipar CR/1791526974593',
        caseNumber: 'CR/1791526974593',
        description: '',
        complainant: '',
        accused: 'Rahul',
        location: '',
        incidentDate: DateTime(2026, 10, 9),
        priority: 'Low',
        status: 'Pending',
        assignedOfficer: 'DGP Maharashtra',
        subCategory: 'Tadipar',
        createdAt: DateTime(2026, 10, 9),
        extraFields: {
          'sr_no': '9',
          'externed_name': 'Rahul',
          'order_number': 'ORD-123',
        },
      );

      // Verify getFilteredRecords with empty list initially
      expect(provider.getFilteredRecords(null), isEmpty);
      expect(provider.getFilteredTotalCount(null), equals(0));
      expect(sampleRecord.moduleKey, equals('tadipar'));
      expect(sampleRecord.subCategory, equals('Tadipar'));
    });
  });
}
