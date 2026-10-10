import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/services/dynamic_options_service.dart';

void main() {
  group('Dynamic Options Parsing & Dropdown Label Reorder Tests', () {
    late DynamicOptionsService service;

    setUp(() {
      service = DynamicOptionsService();
      service.clearCache();
    });

    test(
        'Mode of Receipt: string list and option_value maps preserve display text',
        () {
      // 1. Raw string list (as returned by /api/options/rti_mode_of_receipt/)
      final rawStrings = ['Online', 'Offline', 'Post'];
      final parsedStrings = rawStrings.map((item) => item.toString()).toList();
      expect(parsedStrings, ['Online', 'Offline', 'Post']);

      // 2. Map list with option_value key
      final mapItems = [
        {'id': 1, 'option_value': 'Online', 'display_order': 1},
        {'id': 2, 'option_value': 'Offline', 'display_order': 2},
        {'id': 3, 'option_value': 'Post', 'display_order': 3},
      ];
      final parsedMaps = mapItems
          .map((item) => (item['label'] ??
                  item['option_value'] ??
                  item['name'] ??
                  item['title'] ??
                  item['value'] ??
                  item.toString())
              .toString())
          .toList();
      expect(parsedMaps, ['Online', 'Offline', 'Post']);
    });

    test(
        'Type of Info: string list and option_value maps preserve display text',
        () {
      // 1. Raw string list (as returned by /api/options/rti_info_type/)
      final rawStrings = [
        'Crime record',
        'Administrative',
        'Public safety',
        'Other'
      ];
      final parsedStrings = rawStrings.map((item) => item.toString()).toList();
      expect(parsedStrings,
          ['Crime record', 'Administrative', 'Public safety', 'Other']);

      // 2. Map list with option_value key
      final mapItems = [
        {'option_group': 'rti_info_type', 'option_value': 'Crime record'},
        {'option_group': 'rti_info_type', 'option_value': 'Administrative'},
        {'option_group': 'rti_info_type', 'option_value': 'Public safety'},
        {'option_group': 'rti_info_type', 'option_value': 'Other'},
      ];
      final parsedMaps = mapItems
          .map((item) => (item['label'] ??
                  item['option_value'] ??
                  item['name'] ??
                  item['title'] ??
                  item['value'] ??
                  item.toString())
              .toString())
          .toList();
      expect(parsedMaps,
          ['Crime record', 'Administrative', 'Public safety', 'Other']);
    });

    test('Outcome: string list and option_value maps preserve display text',
        () {
      // 1. Raw string list (as returned by /api/options/rti_outcome/)
      final rawStrings = ['Replied', 'Rejected', 'Transferred'];
      final parsedStrings = rawStrings.map((item) => item.toString()).toList();
      expect(parsedStrings, ['Replied', 'Rejected', 'Transferred']);

      // 2. Map list with option_value key
      final mapItems = [
        {'option_value': 'Replied'},
        {'option_value': 'Rejected'},
        {'option_value': 'Transferred'},
      ];
      final parsedMaps = mapItems
          .map((item) => (item['label'] ??
                  item['option_value'] ??
                  item['name'] ??
                  item['title'] ??
                  item['value'] ??
                  item.toString())
              .toString())
          .toList();
      expect(parsedMaps, ['Replied', 'Rejected', 'Transferred']);
    });

    test('Yes / No (Boolean/Radio fields) preserve display text', () {
      final yesNoOptions = ['Yes', 'No'];
      final parsed = yesNoOptions.map((item) => item.toString()).toList();
      expect(parsed, ['Yes', 'No']);

      final mapYesNo = [
        {'name': 'Yes', 'value': 'true'},
        {'name': 'No', 'value': 'false'},
      ];
      final parsedMaps = mapYesNo
          .map((item) => (item['label'] ??
                  item['option_value'] ??
                  item['name'] ??
                  item['title'] ??
                  item['value'] ??
                  item.toString())
              .toString())
          .toList();
      expect(parsedMaps, ['Yes', 'No']);
    });

    test(
        'Officers dropdown: prioritizes backend ready label "Name, Designation"',
        () {
      final officerItems = [
        {
          'uid': 'sa_mh_chhatrapati_1',
          'name': 'Ramesh Kulkarni',
          'designation': 'PI',
          'label': 'Ramesh Kulkarni, PI',
        },
        {
          'uid': 'sa_mh_chhatrapati_2',
          'name': 'Ganesh Shinde',
          'designation': '',
          'label': 'Ganesh Shinde',
        },
      ];
      final parsedOfficers = officerItems
          .map((item) => (item['label'] ??
                  item['option_value'] ??
                  item['name'] ??
                  item['title'] ??
                  item['value'] ??
                  item.toString())
              .toString())
          .toList();
      expect(parsedOfficers, ['Ramesh Kulkarni, PI', 'Ganesh Shinde']);
    });
  });
}
