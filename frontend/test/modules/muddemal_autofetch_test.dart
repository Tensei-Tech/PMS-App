import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/modules/muddemal/models/muddemal_models.dart';
import 'package:khakhi_diary/modules/muddemal/providers/muddemal_provider.dart';

void main() {
  group('Muddemal Auto-Fetch Architecture Tests', () {
    test(
        'MuddemalPropertyItem correctly parses auto-fetched properties from Crime module',
        () {
      final json = {
        'id': 101,
        'property_uid': 'MP-SHIVAJINAGAR-2026-CR-101-P01',
        'muddemal_record': 1,
        'register_no': 'MR-SHIVAJINAGAR-2026-0001',
        'cr_number': 'CR 101/2026',
        'station_name': 'Shivajinagar PS',
        'source_module': 'crime',
        'source_module_display_name': 'Crime Module',
        'source_case_id': 'uuid-case-101',
        'source_case_number': 'CR 101/2026',
        'source_record_id': 'seizure-memo-55',
        'property_category': 1,
        'category_code': 'CASH',
        'category_name': 'Cash / Currency',
        'property_serial_no': 1,
        'description':
            'Currency notes of Rs 500 denomination total Rs 50,000 seized',
        'quantity': 100.0,
        'unit': 'Numbers',
        'unit_value': 500.0,
        'total_item_value': 50000.0,
        'valuation_status': 'Valued',
        'owner_name': 'State',
        'seized_from': 'Ramesh Shinde',
        'seizure_date': '2026-03-10',
        'property_status': 'Seized',
        'fsl_required': false,
        'current_custody_location': 'Muddemal Room (मालखाना)',
        'fsl_status': 'Not Required',
        'disposal_status': 'In Custody',
        'remarks': 'Auto-synced from Crime module seizure memo',
      };

      final item = MuddemalPropertyItem.fromJson(json);

      expect(item.id, 101);
      expect(item.propertyUid, 'MP-SHIVAJINAGAR-2026-CR-101-P01');
      expect(item.sourceModule, 'crime');
      expect(item.sourceModuleDisplayName, 'Crime Module');
      expect(item.crNumber, 'CR 101/2026');
      expect(item.totalItemValue, 50000.0);
      expect(item.currentCustodyLocation, 'Muddemal Room (मालखाना)');
      expect(item.propertyStatus, 'Seized');
      expect(item.fslStatus, 'Not Required');
      expect(item.disposalStatus, 'In Custody');
    });

    test(
        'MuddemalPropertyItem correctly parses Prohibition & Gambling module seizures',
        () {
      final prohibitionJson = {
        'id': 102,
        'property_uid': 'MP-DECCAN-2026-CR-202-P01',
        'muddemal_record': 2,
        'register_no': 'MR-DECCAN-2026-0002',
        'cr_number': 'CR 202/2026',
        'station_name': 'Deccan PS',
        'source_module': 'prohibition',
        'source_record_id': 'prohibition_details',
        'property_category': 2,
        'category_code': 'ALCOHOL',
        'category_name': 'Alcohol / Liquor / Breweries',
        'description': 'Country liquor bottles (180ml each, total 45 bottles)',
        'quantity': 45.0,
        'unit': 'Bottles',
        'total_item_value': 11250.0,
        'property_status': 'Seized',
        'fsl_required': true,
        'current_custody_location': 'Muddemal Room (मालखाना)',
      };

      final gamblingJson = {
        'id': 103,
        'property_uid': 'MP-SWARGATE-2026-CR-303-P01',
        'muddemal_record': 3,
        'register_no': 'MR-SWARGATE-2026-0003',
        'cr_number': 'CR 303/2026',
        'station_name': 'Swargate PS',
        'source_module': 'gambling',
        'source_record_id': 'gambling_details',
        'property_category': 3,
        'category_code': 'GAMBLING',
        'category_name': 'Gambling Equipment & Stakes',
        'description':
            'Playing cards and gambling stake cash seized during raid',
        'quantity': 1.0,
        'unit': 'Numbers',
        'total_item_value': 28500.0,
        'property_status': 'Seized',
      };

      final pItem = MuddemalPropertyItem.fromJson(prohibitionJson);
      final gItem = MuddemalPropertyItem.fromJson(gamblingJson);

      expect(pItem.sourceModule, 'prohibition');
      expect(pItem.sourceModuleDisplayName, 'Prohibition Module');
      expect(pItem.categoryCode, 'ALCOHOL');
      expect(pItem.fslRequired, true);
      expect(pItem.fslStatus, 'Pending');

      expect(gItem.sourceModule, 'gambling');
      expect(gItem.sourceModuleDisplayName, 'Gambling Module');
      expect(gItem.categoryCode, 'GAMBLING');
      expect(gItem.totalItemValue, 28500.0);
    });

    test(
        'MuddemalProvider metadata getters are 100% dynamic without static fallbacks',
        () {
      final provider = MuddemalProvider();

      // Verify that uninitialized provider returns empty lists without hardcoded fallbacks
      expect(provider.sourceModules, isEmpty);
      expect(provider.categories, isEmpty);
      expect(provider.propertyStatuses, isEmpty);
      expect(provider.measurementUnits, isEmpty);
      expect(provider.movementLocations, isEmpty);
      expect(provider.movementTypes, isEmpty);
      expect(provider.disposalTypes, isEmpty);
      expect(provider.disposalAuthorities, isEmpty);
      expect(provider.fslDispatchReasons, isEmpty);
      expect(provider.fslReportStatuses, isEmpty);
      expect(provider.availableYears, isNotEmpty);
      expect(provider.dashboardTabs, isNotEmpty);
    });
  });
}
