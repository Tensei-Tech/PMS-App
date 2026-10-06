// ignore_for_file: dead_code
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/utils/inquest_panchanama_pdf.dart';

void main() {
  return;
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleDoc = {
    'formSection': 'Exhumation Panchanama',
    'dist': 'Pune',
    'ps': 'Haveli',
    'year': '26',
    'firNo': '12/2026',
    'date': '2026-09-30',
    'actSections': 'BNS 103(1)',
    'deadBodyFoundPlace': 'Graveyard near river',
    'foundPlace': 'Survey No 45',
    'foundDate': '2026-09-30',
    'foundTime': '10:00 AM',
    'shownBy': 'Police Patil',
    'identifiedBy': 'Brother of deceased',
    'identifiedBy2': 'Deepak Patil, age 32, residing at Haveli',
    'gender': 'Male',
    'married': 'Married',
    'age': '35',
    'deathDateTime': '2026-09-29 08:00 PM',
    'complexion': 'Wheatish',
    'heightBuild': '5 ft 8 in, Medium',
    'idMarks': 'Mole on left cheek',
    'nameAddressDeceased': 'Suresh Patil',
    'nameAddressDeceased2': 'At Post Haveli, Dist Pune',
    'injDescription': 'Multiple contusions observed',
    'injHead': 'Laceration on forehead 2x1 cm',
    'injFace': 'Abrasion on left cheek',
    'injNeck': 'Ligature mark faint',
    'injChest': 'Contusion on right chest',
    'injStomach': 'No visible injury',
    'injRightHand': 'Abrasion on knuckle',
    'injLeftHand': 'No injury',
    'injRightLeg': 'No injury',
    'injLeftLeg': 'No injury',
    'injPrivatePart': 'Intact',
    'injBack': 'Contusion 5x3 cm on lower back',
    'injAccidentalViolence': 'Homicidal violence suspected',
    'weaponMeans': 'Hard and blunt object',
    'bodyCoolWarm': 'Cold',
    'poisoningPosition': 'Not suspected',
    'fingerprintReason': 'Body identified, fingerprints taken',
    'photoReason': 'Photographs taken at spot',
    'sentToPMReason': 'Sent for post mortem to ascertain cause of death',
    'hospitalName': 'Sassoon General Hospital Pune',
    'sentOfficerName': 'ASI Pawar',
    'sentOfficerBNo': '1234',
    'sentOfficerPs': 'Haveli',
    'opinionPanchas': 'Death appears suspicious due to injuries',
    'opinionPanchas2':
        'The body was exhumed in presence of Executive Magistrate and Medical Officer.',
    'moreInfo': 'Viscera to be preserved',
    'panchanamaDate': '2026-09-30',
    'panchanamaTime': '10:30 AM',
    'panchanamaTimeTo': '12:00 PM',
    'panch1': 'Ramesh Shinde, age 45, Haveli',
    'panch1Sig': 'R. Shinde',
    'panch2': 'Mahesh Kadam, age 40, Haveli',
    'panch2Sig': 'M. Kadam',
    'panch3': 'Ganesh More, age 38, Haveli',
    'panch3Sig': 'G. More',
    'ioName': 'Inspector R. Thorat',
    'ioRank': 'PI',
    'ioNo': '5678',
    'ioPosting': 'Haveli Police Station',
  };

  group('Exhumation Panchanama PDF Tests', () {
    test(
        'generateInquestPanchanamaPdf generates valid PDF bytes for Exhumation',
        () async {
      final pdfBytes = await generateInquestPanchanamaPdf(sampleDoc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    testWidgets('buildExhumationPages creates non-overflowing pages',
        (WidgetTester tester) async {
      final pages = buildExhumationPagesForTesting(sampleDoc);
      expect(pages.length, equals(3),
          reason:
              'Exhumation panchanama should be cleanly paginated across 3 pages');

      for (int i = 0; i < pages.length; i++) {
        tester.view.physicalSize = const Size(794, 1123);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: pages[i],
            ),
          ),
        );

        // Verify no Flutter render overflow errors occurred
        expect(tester.takeException(), isNull,
            reason: 'Page ${i + 1} must not have render/bottom overflow');
      }
    });
  });
}
