import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/utils/crime_detail_pdf.dart';

void main() {
  group('mapToCrimeDetailDoc Tests', () {
    test('correctly maps standard crime detail document structure', () {
      final source = {
        'crNo': 'CR/123/2026',
        'regDate': '2026-09-01',
        'complainant': {
          'name': 'Ramesh Patil',
          'age': '42',
          'gender': 'Male',
          'occ': 'Farmer',
          'mobile': '9876543210',
          'aadhaar': '1234-5678-9012',
          'address': 'Pune, Maharashtra',
          'religion': 'Hindu',
          'caste': 'Maratha',
        },
        'victim': {
          'name': 'Suresh Patil',
          'age': '38',
          'gender': 'Male',
          'occ': 'Shopkeeper',
          'mobile': '9123456780',
          'aadhaar': '9876-5432-1098',
          'address': 'Pune, Maharashtra',
          'religion': 'Hindu',
          'caste': 'Maratha',
        },
        'spotVillage': 'Shivajinagar',
        'spotArea': 'FC Road',
        'spotAddress': 'Near Deccan Gymkhana',
        'caseResponsibility': {
          'ioName': 'Inspector K. Shinde',
          'ioDesig': 'Police Inspector (PI)',
        },
      };

      final mapped = mapToCrimeDetailDoc(source);

      expect(mapped['firNo'], equals('CR/123/2026'));
      expect(mapped['date'], equals('2026-09-01'));
      expect(mapped['complainantName'], equals('Ramesh Patil'));
      expect(mapped['complainantAge'], equals('42'));
      expect(mapped['complainantGender'], equals('Male'));
      expect(mapped['victimName'], equals('Suresh Patil'));
      expect(mapped['victimMobile'], equals('9123456780'));
      expect(
        mapped['spotAddress'],
        equals('Near Deccan Gymkhana, FC Road, Shivajinagar'),
      );
      expect(
        mapped['placeAddress'],
        equals('Near Deccan Gymkhana, FC Road, Shivajinagar'),
      );
      expect(mapped['ioName'], equals('Inspector K. Shinde'));
      expect(mapped['ioDesig'], equals('Police Inspector (PI)'));
      expect(mapped['ioRank'], equals('Police Inspector (PI)'));
    });

    test('verifies FIR number fallback priority chain', () {
      // 1. crNo priority
      expect(
        mapToCrimeDetailDoc({'crNo': 'CR-1', 'firNo': 'FIR-2'})['firNo'],
        equals('CR-1'),
      );

      // 2. firNo fallback
      expect(
        mapToCrimeDetailDoc({'firNo': 'FIR-2', 'caseNumber': 'CN-3'})['firNo'],
        equals('FIR-2'),
      );

      // 3. caseNumber fallback
      expect(
        mapToCrimeDetailDoc({'caseNumber': 'CN-3', 'adNo': 'AD-4'})['firNo'],
        equals('CN-3'),
      );

      // 4. adNo fallback
      expect(
        mapToCrimeDetailDoc({'adNo': 'AD-4', 'ncNo': 'NC-5'})['firNo'],
        equals('AD-4'),
      );

      // 5. ncNo fallback
      expect(mapToCrimeDetailDoc({'ncNo': 'NC-5'})['firNo'], equals('NC-5'));

      // 6. empty fallback
      expect(mapToCrimeDetailDoc({})['firNo'], equals(''));
    });

    test('verifies date fallback priority chain', () {
      expect(
        mapToCrimeDetailDoc({
          'regDate': '2026-01-01',
          'date': '2026-02-02',
        })['date'],
        equals('2026-01-01'),
      );
      expect(
        mapToCrimeDetailDoc({
          'date': '2026-02-02',
          'incidentDate': '2026-03-03',
        })['date'],
        equals('2026-02-02'),
      );
      expect(
        mapToCrimeDetailDoc({'incidentDate': '2026-03-03'})['date'],
        equals('2026-03-03'),
      );
      expect(mapToCrimeDetailDoc({})['date'], equals(''));
    });

    test('handles empty and partial spot details cleanly', () {
      final onlyVillage = mapToCrimeDetailDoc({'spotVillage': 'Kothrud'});
      expect(onlyVillage['spotAddress'], equals('Kothrud'));

      final noSpot = mapToCrimeDetailDoc({});
      expect(noSpot.containsKey('spotAddress'), isFalse);
    });

    test(
      'handles non-map or missing nested objects gracefully without crashing',
      () {
        final docWithInvalidTypes = {
          'complainant': 'not-a-map',
          'victim': null,
          'caseResponsibility': 12345,
        };

        final mapped = mapToCrimeDetailDoc(docWithInvalidTypes);
        expect(mapped, isNotNull);
        expect(mapped['complainant'], equals('not-a-map'));
        expect(mapped['victim'], isNull);
      },
    );

    test(
      'handles exceptionally long inputs without truncation errors or crashes',
      () {
        final longString = 'A' * 10000;
        final marathiLongString = 'पोलीस तपास अहवाल ' * 500;

        final mapped = mapToCrimeDetailDoc({
          'crNo': longString,
          'spotAddress': marathiLongString,
          'complainant': {'name': longString, 'address': marathiLongString},
        });

        expect(mapped['firNo'], equals(longString));
        expect(mapped['complainantName'], equals(longString));
        expect(mapped['complainantAddress'], equals(marathiLongString));
      },
    );
  });
}
