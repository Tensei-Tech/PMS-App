// test/utils/mock_api_client.dart
// Provides a mock HTTP client implementing standard DRF endpoint responses
// for offline, deterministic Flutter unit and widget testing.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Creates a [MockClient] that intercepts API calls to Django backend endpoints
/// and returns the structured JSON responses matching the live backend.
http.Client createMockApiClient() {
  return MockClient((http.Request request) async {
    final uri = request.url;
    final path = uri.path;

    // 1. Administrative Divisions: GET /api/divisions/
    if (path.contains('/divisions')) {
      final divisions = [
        {'id': 1, 'name': 'Chhatrapati Sambhajinagar'},
        {'id': 2, 'name': 'Pune'},
        {'id': 3, 'name': 'Nashik'},
        {'id': 4, 'name': 'Konkan'},
        {'id': 5, 'name': 'Nagpur'},
        {'id': 6, 'name': 'Amravati'},
      ];
      return http.Response(jsonEncode(divisions), 200, headers: _headers);
    }

    // 2. Districts: GET /api/districts/?division_id=...
    if (path.contains('/districts')) {
      final divisionId = uri.queryParameters['division_id'];

      // Pune Division (id=2) -> 5 districts
      if (divisionId == '2') {
        final puneDistricts = [
          {'id': 201, 'name': 'Kolhapur', 'division_id': 2},
          {'id': 202, 'name': 'Pune', 'division_id': 2},
          {'id': 203, 'name': 'Sangli', 'division_id': 2},
          {'id': 204, 'name': 'Satara', 'division_id': 2},
          {'id': 205, 'name': 'Solapur', 'division_id': 2},
        ];
        return http.Response(jsonEncode(puneDistricts), 200, headers: _headers);
      }

      // Konkan Division -> 7 districts
      if (divisionId == 'Konkan' || divisionId == '4') {
        final konkanDistricts = [
          {'id': 401, 'name': 'Mumbai City', 'division_id': 4},
          {'id': 402, 'name': 'Mumbai Suburban', 'division_id': 4},
          {'id': 403, 'name': 'Palghar', 'division_id': 4},
          {'id': 404, 'name': 'Raigad', 'division_id': 4},
          {'id': 405, 'name': 'Ratnagiri', 'division_id': 4},
          {'id': 406, 'name': 'Sindhudurg', 'division_id': 4},
          {'id': 407, 'name': 'Thane', 'division_id': 4},
        ];
        return http.Response(jsonEncode(konkanDistricts), 200,
            headers: _headers);
      }

      // All 36 Maharashtra Districts
      final all36Districts = [
        {'id': 1, 'name': 'Pune'},
        {'id': 2, 'name': 'Mumbai City'},
        {'id': 3, 'name': 'Amravati'},
        {'id': 4, 'name': 'Nashik'},
        {'id': 5, 'name': 'Nagpur'},
        {'id': 6, 'name': 'Kolhapur'},
        {'id': 7, 'name': 'Sangli'},
        {'id': 8, 'name': 'Satara'},
        {'id': 9, 'name': 'Solapur'},
        {'id': 10, 'name': 'Mumbai Suburban'},
        {'id': 11, 'name': 'Palghar'},
        {'id': 12, 'name': 'Raigad'},
        {'id': 13, 'name': 'Ratnagiri'},
        {'id': 14, 'name': 'Sindhudurg'},
        {'id': 15, 'name': 'Thane'},
        {'id': 16, 'name': 'Ahmednagar'},
        {'id': 17, 'name': 'Dhule'},
        {'id': 18, 'name': 'Jalgaon'},
        {'id': 19, 'name': 'Nandurbar'},
        {'id': 20, 'name': 'Chhatrapati Sambhajinagar'},
        {'id': 21, 'name': 'Beed'},
        {'id': 22, 'name': 'Jalna'},
        {'id': 23, 'name': 'Dharashiv'},
        {'id': 24, 'name': 'Nanded'},
        {'id': 25, 'name': 'Latur'},
        {'id': 26, 'name': 'Parbhani'},
        {'id': 27, 'name': 'Hingoli'},
        {'id': 28, 'name': 'Akola'},
        {'id': 29, 'name': 'Buldhana'},
        {'id': 30, 'name': 'Yavatmal'},
        {'id': 31, 'name': 'Washim'},
        {'id': 32, 'name': 'Bhandara'},
        {'id': 33, 'name': 'Chandrapur'},
        {'id': 34, 'name': 'Gadchiroli'},
        {'id': 35, 'name': 'Gondia'},
        {'id': 36, 'name': 'Wardha'},
      ];
      return http.Response(jsonEncode(all36Districts), 200, headers: _headers);
    }

    // 3. Police Stations: GET /api/stations/?district_id=...
    if (path.contains('/stations')) {
      final districtId = uri.queryParameters['district_id'] ?? '';
      if (districtId.contains('PUNE') ||
          districtId == 'Pune' ||
          districtId == '1') {
        final puneStations = List.generate(
            57,
            (i) => {
                  'id': 'STN-PUNE-${i + 1}',
                  'name': 'Pune Station ${i + 1}',
                  'district_id': districtId,
                });
        return http.Response(jsonEncode(puneStations), 200, headers: _headers);
      }

      if (districtId.contains('Amravati') || districtId == '3') {
        final amrStations = List.generate(
            20,
            (i) => {
                  'id': 'STN-AMR-${i + 1}',
                  'name': 'Amravati Station ${i + 1}',
                  'district_id': districtId,
                });
        return http.Response(jsonEncode(amrStations), 200, headers: _headers);
      }

      final defaultStations = List.generate(
          10,
          (i) => {
                'id': 'STN-$districtId-${i + 1}',
                'name': 'Station ${i + 1}',
                'district_id': districtId,
              });
      return http.Response(jsonEncode(defaultStations), 200, headers: _headers);
    }

    // 4. Category Groups: GET /api/groups/
    if (path.endsWith('/groups/') || path.endsWith('/groups')) {
      final groups = [
        {
          'group_id': 1,
          'group_name': '1 to 5',
          'group_code': 'I TO V',
          'display_order': 1
        },
        {
          'group_id': 2,
          'group_name': 'Part 6',
          'group_code': 'VI',
          'display_order': 2
        },
      ];
      return http.Response(jsonEncode(groups), 200, headers: _headers);
    }

    // 5. Group 1 Categories: GET /api/groups/1/categories/ (28 categories)
    if (path.contains('/groups/1/categories')) {
      final group1Names = [
        'Murder',
        'Attempt to Murder',
        'Dacoity',
        'Robbery',
        'Theft',
        'Extortion',
        'Kidnapping',
        'Hurt',
        'Rape',
        'Rioting',
        'Burglary',
        'House Breaking by Day',
        'House Breaking by Night',
        'Cheating',
        'Criminal Breach of Trust',
        'Counterfeiting Currency',
        'Arson',
        'Mischief',
        'Culpable Homicide',
        'Dowry Death',
        'Assault on Public Servant',
        'Rash and Negligent Act',
        'Criminal Intimidation',
        'Forgery',
        'Cruelty by Husband or Relatives',
        'Unnatural Offences',
        'Human Trafficking',
        'Other IPC/BNS Crimes',
      ];
      final g1Cats = group1Names
          .asMap()
          .entries
          .map((e) => {
                'id': e.key + 1,
                'category_id': e.key + 1,
                'category_name': e.value,
                'category_code': e.value.replaceAll(' ', '_').toUpperCase(),
                'group_id': 1,
              })
          .toList();
      return http.Response(jsonEncode(g1Cats), 200, headers: _headers);
    }

    // 6. Group 2 Categories: GET /api/groups/2/categories/ (9 categories)
    if (path.contains('/groups/2/categories')) {
      final group2Names = [
        'ST Drugs',
        'Prohibition',
        'Gambling',
        'POCSO',
        'NDPS',
        'UAPA',
        'Arms Act',
        'Essential Commodities',
        'Copyright Act',
      ];
      final g2Cats = group2Names
          .asMap()
          .entries
          .map((e) => {
                'id': 100 + e.key + 1,
                'category_id': 100 + e.key + 1,
                'category_name': e.value,
                'category_code': e.value.replaceAll(' ', '_').toUpperCase(),
                'group_id': 2,
              })
          .toList();
      return http.Response(jsonEncode(g2Cats), 200, headers: _headers);
    }

    // 7. Standalone Categories: GET /api/categories/standalone/ (26 categories)
    if (path.contains('/categories/standalone')) {
      const standaloneNames = [
        'A.D.',
        'Accident',
        'Coin',
        'Crime Against Women',
        'Death Due to Rash Driving',
        'Gambling',
        'Gowans',
        'Hurt',
        'IT Act',
        'Kidnapping',
        'M.V Act',
        'Missing',
        'N.C.',
        'NDPS',
        'Normal Accident',
        'Other Road Accident',
        'POCSO',
        'Prohibition',
        'Road Accident',
        'Sand Theft',
        'Sec 156(3)/175(3)(BNSS)',
        'ST Drugs',
        'Suicide',
        'Theft',
        'Two/Four Wheeler Theft',
        'UAPA',
      ];
      final cats = standaloneNames
          .asMap()
          .entries
          .map((e) => {
                'id': 200 + e.key + 1,
                'category_id': 200 + e.key + 1,
                'category_name': e.value,
                'category_code': e.value.replaceAll(' ', '_').toUpperCase(),
                'group_id': null,
              })
          .toList();
      return http.Response(jsonEncode(cats), 200, headers: _headers);
    }

    // 8. Category Children Drilldown: GET /api/categories/{id}/children/
    final childrenMatch =
        RegExp(r'/categories/([^/]+)/children/?').firstMatch(path);
    if (childrenMatch != null) {
      final categoryRaw = Uri.decodeComponent(childrenMatch.group(1)!);
      if (categoryRaw.equalsIgnoreCase('Accident')) {
        final children = [
          {'id': 301, 'category_id': 301, 'category_name': 'Normal Accident'},
          {'id': 302, 'category_id': 302, 'category_name': 'Road Accident'},
        ];
        return http.Response(jsonEncode(children), 200, headers: _headers);
      }
      if (categoryRaw.equalsIgnoreCase('Road Accident')) {
        final children = [
          {
            'id': 303,
            'category_id': 303,
            'category_name': 'Death Due to Rash Driving'
          },
          {
            'id': 304,
            'category_id': 304,
            'category_name': 'Other Road Accident'
          },
        ];
        return http.Response(jsonEncode(children), 200, headers: _headers);
      }
      // Leaf categories have no children
      return http.Response(jsonEncode([]), 200, headers: _headers);
    }

    // 9. Dynamic Form Definition: GET /api/categories/{id}/form-definition/
    final formDefMatch =
        RegExp(r'/categories/([^/]+)/form-definition/?').firstMatch(path);
    if (formDefMatch != null) {
      final catParam = Uri.decodeComponent(formDefMatch.group(1)!);
      final sectionsParam = uri.queryParameters['sections'] ??
          uri.queryParameters['section_ids'] ??
          '';

      final formDef = _buildFormDefinition(catParam, sectionsParam);
      return http.Response(jsonEncode(formDef), 200, headers: _headers);
    }

    // Default 200 response for any other backend endpoint (e.g. health check or case list)
    return http.Response(jsonEncode({'status': 'ok'}), 200, headers: _headers);
  });
}

const _headers = {'content-type': 'application/json; charset=utf-8'};

extension _StringCaseInsensitive on String {
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();
}

/// Builds the dynamic form definition payload matching Django's get_form_definition
Map<String, dynamic> _buildFormDefinition(String category, String sections) {
  // 1. Exactly 105 baseline fields (all field_source == 'common')
  final baselineFields = <Map<String, dynamic>>[
    // Registration Info
    {
      'field_label': 'CR Number',
      'field_key': 'cr_number',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Registration Info',
      'display_order': 10
    },
    {
      'field_label': 'Registration Date & Time',
      'field_key': 'registered_datetime',
      'field_source': 'common',
      'field_type': 'datetime',
      'section': 'Registration Info',
      'display_order': 20
    },
    {
      'field_label': 'Unknown Accused Involved',
      'field_key': 'is_unknown_accused',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Registration Info',
      'display_order': 30
    },

    // Crime Spot
    {
      'field_label': 'Village / Town',
      'field_key': 'village_town',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Crime Spot',
      'display_order': 40
    },
    {
      'field_label': 'Area Name',
      'field_key': 'area_name',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Crime Spot',
      'display_order': 50
    },
    {
      'field_label': 'Crime Spot Full Address',
      'field_key': 'full_address',
      'field_source': 'common',
      'field_type': 'textarea',
      'section': 'Crime Spot',
      'display_order': 60
    },
    {
      'field_label': 'Occurrence Date & Time',
      'field_key': 'occurrence_datetime',
      'field_source': 'common',
      'field_type': 'datetime',
      'section': 'Crime Spot',
      'display_order': 70
    },

    // Acts & Sections (Charges)
    {
      'field_label': 'Acts & Sections Filed',
      'field_key': 'charges',
      'field_source': 'common',
      'field_type': 'chips',
      'section': 'Acts & Sections',
      'display_order': 80
    },

    // Complainant KYC
    {
      'field_label': 'Complainant Name',
      'field_key': 'complainant_name',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Complainant',
      'display_order': 90
    },
    {
      'field_label': 'Complainant Age',
      'field_key': 'complainant_age',
      'field_source': 'common',
      'field_type': 'number',
      'section': 'Complainant',
      'display_order': 100
    },
    {
      'field_label': 'Complainant Gender',
      'field_key': 'complainant_gender',
      'field_source': 'common',
      'field_type': 'dropdown',
      'section': 'Complainant',
      'display_order': 110
    },
    {
      'field_label': 'Complainant Occupation',
      'field_key': 'complainant_occupation',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Complainant',
      'display_order': 120
    },
    {
      'field_label': 'Complainant Mobile',
      'field_key': 'complainant_mobile',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Complainant',
      'display_order': 130
    },
    {
      'field_label': 'Complainant Aadhaar',
      'field_key': 'complainant_aadhaar',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Complainant',
      'display_order': 140
    },
    {
      'field_label': 'Complainant PAN',
      'field_key': 'complainant_pan',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Complainant',
      'display_order': 150
    },
    {
      'field_label': 'Complainant Religion',
      'field_key': 'complainant_religion',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Complainant',
      'display_order': 160
    },
    {
      'field_label': 'Complainant Caste',
      'field_key': 'complainant_caste',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Complainant',
      'display_order': 170
    },
    {
      'field_label': 'Complainant Address',
      'field_key': 'complainant_address',
      'field_source': 'common',
      'field_type': 'textarea',
      'section': 'Complainant',
      'display_order': 180
    },

    // Accused KYC
    {
      'field_label': 'Accused Name',
      'field_key': 'accused_name',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Accused',
      'display_order': 190
    },
    {
      'field_label': 'Accused Age',
      'field_key': 'accused_age',
      'field_source': 'common',
      'field_type': 'number',
      'section': 'Accused',
      'display_order': 200
    },
    {
      'field_label': 'Accused Gender',
      'field_key': 'accused_gender',
      'field_source': 'common',
      'field_type': 'dropdown',
      'section': 'Accused',
      'display_order': 210
    },
    {
      'field_label': 'Accused Occupation',
      'field_key': 'accused_occupation',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Accused',
      'display_order': 220
    },
    {
      'field_label': 'Accused Mobile',
      'field_key': 'accused_mobile',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Accused',
      'display_order': 230
    },
    {
      'field_label': 'Accused Aadhaar',
      'field_key': 'accused_aadhaar',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Accused',
      'display_order': 240
    },
    {
      'field_label': 'Accused PAN',
      'field_key': 'accused_pan',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Accused',
      'display_order': 250
    },
    {
      'field_label': 'Accused Religion',
      'field_key': 'accused_religion',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Accused',
      'display_order': 260
    },
    {
      'field_label': 'Accused Caste',
      'field_key': 'accused_caste',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Accused',
      'display_order': 270
    },
    {
      'field_label': 'Accused Address',
      'field_key': 'accused_address',
      'field_source': 'common',
      'field_type': 'textarea',
      'section': 'Accused',
      'display_order': 280
    },

    // Unidentified Accused (8 exact fields and order)
    {
      'field_label': 'Approximate Age',
      'field_key': 'approximate_age',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Unidentified Accused',
      'display_order': 290
    },
    {
      'field_label': 'Gender',
      'field_key': 'gender',
      'field_source': 'common',
      'field_type': 'dropdown',
      'section': 'Unidentified Accused',
      'display_order': 300
    },
    {
      'field_label': 'Skin Colour',
      'field_key': 'skin_colour',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Unidentified Accused',
      'display_order': 310
    },
    {
      'field_label': 'Possible Occupation',
      'field_key': 'possible_occupation',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Unidentified Accused',
      'display_order': 320
    },
    {
      'field_label': 'Identification Mark',
      'field_key': 'identification_mark',
      'field_source': 'common',
      'field_type': 'textarea',
      'section': 'Unidentified Accused',
      'display_order': 330
    },
    {
      'field_label': 'Height',
      'field_key': 'height',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Unidentified Accused',
      'display_order': 340
    },
    {
      'field_label': 'Address',
      'field_key': 'unid_address',
      'field_source': 'common',
      'field_type': 'textarea',
      'section': 'Unidentified Accused',
      'display_order': 345
    },
    {
      'field_label': 'Description',
      'field_key': 'description',
      'field_source': 'common',
      'field_type': 'textarea',
      'section': 'Unidentified Accused',
      'display_order': 350
    },

    // Responsibility
    {
      'field_label': 'IO Name',
      'field_key': 'io_name',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Responsibility',
      'display_order': 360
    },
    {
      'field_label': 'IO Designation',
      'field_key': 'io_designation',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Responsibility',
      'display_order': 370
    },
    {
      'field_label': 'Registered By Name',
      'field_key': 'registered_by_name',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Responsibility',
      'display_order': 380
    },
    {
      'field_label': 'Registered By Designation',
      'field_key': 'registered_by_designation',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Responsibility',
      'display_order': 390
    },

    // Arrest & Release Status (11 fields, first is 'Arrested Person Name' with key 'arrested_person_name')
    {
      'field_label': 'Arrested Person Name',
      'field_key': 'arrested_person_name',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Arrest',
      'display_order': 400
    },
    {
      'field_label': 'Arrest Date & Time',
      'field_key': 'arrest_datetime',
      'field_source': 'common',
      'field_type': 'datetime',
      'section': 'Arrest',
      'display_order': 410
    },
    {
      'field_label': 'Sec 47/48 BNSS Complied',
      'field_key': 'sec_47_48_bnss',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Arrest',
      'display_order': 420
    },
    {
      'field_label': 'Relative / Friend Informed',
      'field_key': 'relative_friend_name',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Arrest',
      'display_order': 430
    },
    {
      'field_label': 'Relative / Friend Relation',
      'field_key': 'relative_friend_relation',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Arrest',
      'display_order': 440
    },
    {
      'field_label': 'Release on Notice',
      'field_key': 'release_on_notice',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Arrest',
      'display_order': 450
    },
    {
      'field_label': 'Release on Notice Date & Time',
      'field_key': 'release_on_notice_datetime',
      'field_source': 'common',
      'field_type': 'datetime',
      'section': 'Arrest',
      'display_order': 460
    },
    {
      'field_label': 'Anticipatory Bail',
      'field_key': 'anticipatory_bail',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Arrest',
      'display_order': 470
    },
    {
      'field_label': 'Anticipatory Bail Date & Time',
      'field_key': 'anticipatory_bail_datetime',
      'field_source': 'common',
      'field_type': 'datetime',
      'section': 'Arrest',
      'display_order': 480
    },
    {
      'field_label': 'Death of Accused',
      'field_key': 'death_of_accused',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Arrest',
      'display_order': 490
    },
    {
      'field_label': 'Death of Accused Date & Time',
      'field_key': 'death_of_accused_datetime',
      'field_source': 'common',
      'field_type': 'datetime',
      'section': 'Arrest',
      'display_order': 500
    },

    // Remand & Custody
    {
      'field_label': 'PCR (Days)',
      'field_key': 'pcr_days',
      'field_source': 'common',
      'field_type': 'number',
      'section': 'Remand & Custody',
      'display_order': 510
    },
    {
      'field_label': 'MCR',
      'field_key': 'mcr',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Remand & Custody',
      'display_order': 520
    },
    {
      'field_label': 'PR Bond',
      'field_key': 'pr_bond',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Remand & Custody',
      'display_order': 530
    },
    {
      'field_label': 'Bail',
      'field_key': 'bail',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Remand & Custody',
      'display_order': 540
    },
    {
      'field_label': 'Surety Name',
      'field_key': 'surety_name',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Remand & Custody',
      'display_order': 550
    },
    {
      'field_label': 'Jail',
      'field_key': 'jail',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Remand & Custody',
      'display_order': 560
    },

    // CCTV & Technical
    {
      'field_label': 'CCTV Checked',
      'field_key': 'cctv_checked',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'CCTV & Technical',
      'display_order': 570
    },
    {
      'field_label': 'CDR Sent Date',
      'field_key': 'cdr_sent_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'CCTV & Technical',
      'display_order': 580
    },
    {
      'field_label': 'CDR Received Date',
      'field_key': 'cdr_received_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'CCTV & Technical',
      'display_order': 590
    },

    // Procedural Checklist
    {
      'field_label': 'Spot Panchanama',
      'field_key': 'spot_panchanama',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Procedural Checklist',
      'display_order': 600
    },
    {
      'field_label': 'Seizure Panchanama',
      'field_key': 'seizure_panchanama',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Procedural Checklist',
      'display_order': 610
    },
    {
      'field_label': 'Search Panchanama',
      'field_key': 'search_panchanama',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Procedural Checklist',
      'display_order': 620
    },
    {
      'field_label': 'Personal Search Panchanama',
      'field_key': 'personal_search_panchanama',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Procedural Checklist',
      'display_order': 630
    },
    {
      'field_label': 'Memorandum Panchanama',
      'field_key': 'memorandum_panchanama',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Procedural Checklist',
      'display_order': 640
    },
    {
      'field_label': 'Identification Panchanama',
      'field_key': 'identification_panchanama',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Procedural Checklist',
      'display_order': 650
    },
    {
      'field_label': 'Identification Parade Panchanama',
      'field_key': 'identification_parade_panchanama',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Procedural Checklist',
      'display_order': 660
    },

    // Forensics
    {
      'field_label': 'E-Shakshya',
      'field_key': 'e_shakshya',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Forensics',
      'display_order': 670
    },
    {
      'field_label': 'Fingerprint Taken',
      'field_key': 'fingerprint_taken',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Forensics',
      'display_order': 680
    },
    {
      'field_label': 'NAFIS Fingerprint',
      'field_key': 'nafis_fingerprint',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Forensics',
      'display_order': 690
    },

    // Seizures
    {
      'field_label': 'Object Name',
      'field_key': 'object_name',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Seizures',
      'display_order': 700
    },
    {
      'field_label': 'Seizure Description',
      'field_key': 'seizure_description',
      'field_source': 'common',
      'field_type': 'textarea',
      'section': 'Seizures',
      'display_order': 710
    },
    {
      'field_label': 'Seizure From Whom',
      'field_key': 'seizure_person_name',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Seizures',
      'display_order': 720
    },

    // Preventive Action Items
    {
      'field_label': 'Preventive Action Type',
      'field_key': 'preventive_action_type',
      'field_source': 'common',
      'field_type': 'dropdown',
      'section': 'Preventive Action Items',
      'display_order': 730
    },
    {
      'field_label': 'Preventive Action Date',
      'field_key': 'preventive_action_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'Preventive Action Items',
      'display_order': 740
    },
    {
      'field_label': 'Preventive Action Outward No',
      'field_key': 'preventive_outward_no',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Preventive Action Items',
      'display_order': 750
    },

    // Preventive Bond
    {
      'field_label': 'Bond Date',
      'field_key': 'bond_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'Preventive Bond',
      'display_order': 760
    },
    {
      'field_label': 'Bond Cancellation Date',
      'field_key': 'bond_cancellation_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'Preventive Bond',
      'display_order': 770
    },

    // Discharge Status
    {
      'field_label': 'Discharged Accused',
      'field_key': 'is_discharged',
      'field_source': 'common',
      'field_type': 'checkbox',
      'section': 'Discharge Status',
      'display_order': 780
    },

    // Scrutiny Pipeline
    {
      'field_label': 'SDPO/ACP Send Date',
      'field_key': 'sdpo_acp_send_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'Scrutiny Pipeline',
      'display_order': 790
    },
    {
      'field_label': 'SDPO/ACP Grant Date',
      'field_key': 'sdpo_acp_grant_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'Scrutiny Pipeline',
      'display_order': 800
    },
    {
      'field_label': 'Addl SP/DCP Send Date',
      'field_key': 'addl_sp_dcp_send_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'Scrutiny Pipeline',
      'display_order': 810
    },
    {
      'field_label': 'Addl SP/DCP Grant Date',
      'field_key': 'addl_sp_dcp_grant_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'Scrutiny Pipeline',
      'display_order': 820
    },
    {
      'field_label': 'Addl CP Send Date',
      'field_key': 'addl_cp_send_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'Scrutiny Pipeline',
      'display_order': 830
    },
    {
      'field_label': 'Addl CP Grant Date',
      'field_key': 'addl_cp_grant_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'Scrutiny Pipeline',
      'display_order': 840
    },
    {
      'field_label': 'APP Send Date',
      'field_key': 'app_send_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'Scrutiny Pipeline',
      'display_order': 850
    },
    {
      'field_label': 'APP Grant Date',
      'field_key': 'app_grant_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'Scrutiny Pipeline',
      'display_order': 860
    },

    // Final Verdict
    {
      'field_label': 'Charge Sheet No',
      'field_key': 'charge_sheet_no',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Final Verdict',
      'display_order': 870
    },
    {
      'field_label': 'A Final Number',
      'field_key': 'a_final_number',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Final Verdict',
      'display_order': 880
    },
    {
      'field_label': 'B Final Number',
      'field_key': 'b_final_number',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Final Verdict',
      'display_order': 890
    },
    {
      'field_label': 'C Final Number',
      'field_key': 'c_final_number',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Final Verdict',
      'display_order': 900
    },
    {
      'field_label': 'NC Final Number',
      'field_key': 'nc_final_number',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Final Verdict',
      'display_order': 910
    },
    {
      'field_label': 'Abeted Summary No',
      'field_key': 'abeted_summary_no',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Final Verdict',
      'display_order': 920
    },
    {
      'field_label': 'Stay by High Court Date',
      'field_key': 'stay_by_high_court_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'Final Verdict',
      'display_order': 930
    },
    {
      'field_label': 'Quashed by High Court Date',
      'field_key': 'quashed_by_high_court_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'Final Verdict',
      'display_order': 940
    },

    // Exactly 10 additional common baseline fields to reach exactly 105
    {
      'field_label': 'Case Remarks',
      'field_key': 'case_remarks',
      'field_source': 'common',
      'field_type': 'textarea',
      'section': 'Additional Info',
      'display_order': 950
    },
    {
      'field_label': 'Special Instructions',
      'field_key': 'special_instructions',
      'field_source': 'common',
      'field_type': 'textarea',
      'section': 'Additional Info',
      'display_order': 952
    },
    {
      'field_label': 'Witness Name',
      'field_key': 'witness_name',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Witness Info',
      'display_order': 954
    },
    {
      'field_label': 'Witness Mobile',
      'field_key': 'witness_mobile',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Witness Info',
      'display_order': 956
    },
    {
      'field_label': 'Witness Statement Summary',
      'field_key': 'witness_statement',
      'field_source': 'common',
      'field_type': 'textarea',
      'section': 'Witness Info',
      'display_order': 958
    },
    {
      'field_label': 'Medical Officer Name',
      'field_key': 'mo_name',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Medical Info',
      'display_order': 960
    },
    {
      'field_label': 'Medical Exam Date',
      'field_key': 'medical_exam_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'Medical Info',
      'display_order': 962
    },
    {
      'field_label': 'Forensic Lab Outward No',
      'field_key': 'fsl_outward_no',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Forensic Info',
      'display_order': 964
    },
    {
      'field_label': 'Forensic Lab Report Date',
      'field_key': 'fsl_report_date',
      'field_source': 'common',
      'field_type': 'date',
      'section': 'Forensic Info',
      'display_order': 966
    },
    {
      'field_label': 'Court Case Number',
      'field_key': 'court_case_no',
      'field_source': 'common',
      'field_type': 'text',
      'section': 'Court Info',
      'display_order': 968
    },
  ];

  assert(baselineFields.length == 105, 'Baseline fields must be exactly 105');
  final fields = List<Map<String, dynamic>>.from(baselineFields);

  // If Murder category: add 6 Murder extra fields (field_source: 'custom')
  if (category.equalsIgnoreCase('Murder') || category == '1') {
    final murderExtras = [
      {
        'field_label': 'Deceased Name',
        'field_key': 'deceased_name',
        'field_source': 'custom',
        'field_type': 'text',
        'section': 'Special Section / Template Details',
        'display_order': 1000
      },
      {
        'field_label': 'Deceased Age',
        'field_key': 'deceased_age',
        'field_source': 'custom',
        'field_type': 'number',
        'section': 'Special Section / Template Details',
        'display_order': 1010
      },
      {
        'field_label': 'Deceased Gender',
        'field_key': 'deceased_gender',
        'field_source': 'custom',
        'field_type': 'dropdown',
        'section': 'Special Section / Template Details',
        'display_order': 1020
      },
      {
        'field_label': 'Inquest Panchanama Details',
        'field_key': 'inquest_panchanama',
        'field_source': 'custom',
        'field_type': 'textarea',
        'section': 'Special Section / Template Details',
        'display_order': 1030
      },
      {
        'field_label': 'Post-Mortem Report Date',
        'field_key': 'pm_report_date',
        'field_source': 'custom',
        'field_type': 'date',
        'section': 'Special Section / Template Details',
        'display_order': 1040
      },
      {
        'field_label': 'Cause of Death',
        'field_key': 'cause_of_death',
        'field_source': 'custom',
        'field_type': 'textarea',
        'section': 'Special Section / Template Details',
        'display_order': 1050
      },
    ];
    fields.addAll(murderExtras);
  }

  // If Hurt charge included (BNS 115): add 4 Hurt extra fields (field_source: 'custom')
  if (sections.contains('115')) {
    final hurtExtras = [
      {
        'field_label': 'Injured Person Name',
        'field_key': 'injured_name',
        'field_source': 'custom',
        'field_type': 'text',
        'section': 'Special Section / Template Details',
        'display_order': 1100
      },
      {
        'field_label': 'Injury Type / Severity',
        'field_key': 'injury_type',
        'field_source': 'custom',
        'field_type': 'text',
        'section': 'Special Section / Template Details',
        'display_order': 1110
      },
      {
        'field_label': 'Medical Certificate Date',
        'field_key': 'medical_certificate_date',
        'field_source': 'custom',
        'field_type': 'date',
        'section': 'Special Section / Template Details',
        'display_order': 1120
      },
      {
        'field_label': 'Hospital Name',
        'field_key': 'hospital_name',
        'field_source': 'custom',
        'field_type': 'text',
        'section': 'Special Section / Template Details',
        'display_order': 1130
      },
    ];
    fields.addAll(hurtExtras);
  }

  return {
    'category_id': 1,
    'category_name': category,
    'fields': fields,
    'preventive_items': ['Preventive 1', 'Preventive 2'],
    'acts': {},
  };
}
