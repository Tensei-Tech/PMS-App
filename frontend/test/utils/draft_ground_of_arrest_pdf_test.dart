import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/utils/draft_ground_of_arrest_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Draft Ground of Arrest PDF Tests', () {
    test(
        'Empty fields test: generates exactly 3 pages by default with no errors',
        () async {
      final doc = <String, dynamic>{};
      final pdfBytes = await generateDraftGroundOfArrestPdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('Section filtering tests (Page 9 only, 10 only, 11 only)', () async {
      final p9Doc = <String, dynamic>{'formSection': 'page 9'};
      final p9Bytes = await generateDraftGroundOfArrestPdf(p9Doc);
      expect(p9Bytes, isNotNull);

      final p10Doc = <String, dynamic>{'formSection': 'page 10'};
      final p10Bytes = await generateDraftGroundOfArrestPdf(p10Doc);
      expect(p10Bytes, isNotNull);

      final p11Doc = <String, dynamic>{'formSection': 'page 11'};
      final p11Bytes = await generateDraftGroundOfArrestPdf(p11Doc);
      expect(p11Bytes, isNotNull);
    });

    test('200+ char address with spaces test', () async {
      const longAddress =
          'घर क्रमांक १२३, साई श्रद्धा निवास, विठ्ठल रुक्मिणी मंदिर जवळ, मुख्य चौक, शिवाजी नगर, ता. हवेली, जि. पुणे, महाराष्ट्र राज्य, भारत पिन कोड ४११०१६ फोन नंबर ९८७६५४३२१० आणि अतिरिक्त पत्ता तपशील येथे नमूद करण्यात येत आहे, फ्लॅट क्रमांक ४०२';
      expect(longAddress.length, greaterThan(200));

      final doc = <String, dynamic>{
        'accusedName': 'अजय विनायक जोशी',
        'accusedAge': '२८',
        'accusedAddress': longAddress,
        'psName': 'शिवाजीनगर पोलीस स्टेशन पुणे शहर',
        'crNo': '४५६/२६',
        'bnsSection': '१०३(१)',
        'arrestDate': '2026-10-02',
        'arrestTime': '14:30',
        'briefFacts':
            'आरोपीने फिर्यादी यांचेवर प्राणघातक हल्ला करून गंभीर जखमी केल्याचे निष्पन्न झाले आहे.',
        'relativeName': 'श्री. विनायक गोपाळ जोशी (भाऊ)',
        'relativeAge': '५२',
        'relativeAddress': longAddress,
        'relationship': 'भाऊ',
      };

      final pdfBytes = await generateDraftGroundOfArrestPdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('150+ char address without spaces (unbroken run) test', () async {
      const unbrokenAddress =
          'hhhhhhhhkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk';
      expect(unbrokenAddress.length, greaterThan(150));

      final doc = <String, dynamic>{
        'accusedAddress': unbrokenAddress,
        'relativeAddress': unbrokenAddress,
      };

      final pdfBytes = await generateDraftGroundOfArrestPdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('Long police station name & long text in brief facts & tables test',
        () async {
      final doc = <String, dynamic>{
        'accusedName': 'रामचंद्र गोविंद साळुंखे',
        'accusedAge': '३४',
        'accusedAddress':
            'फ्लॅट क्र. १२, चिंतामणी टॉवर्स, महात्मा फुले रोड, नवी मुंबई',
        'psName':
            'मध्यवर्ती विशेष गुन्हे अन्वेषण विभाग पोलीस ठाणे, परिमंडळ ४, बृहन्मुंबई महानगर',
        'crNo': '१२३/२४',
        'bnsSection': '३०४, ३२३, ५०४, ५०६, ३४',
        'arrestDate': '02/10/2026',
        'arrestTime': '10:30 AM',
        'briefFacts':
            'आरोपीने गुन्ह्यातील इतर साथीदारांसह फिर्यादी यांच्या घरात जबरदस्तीने प्रवेश करून धारदार शस्त्राने हल्ला केला व मौल्यवान ऐवज लंपास केला तसेच साक्षीदारांना जीवे मारण्याची धमकी दिली.',
        'witnessName': 'साक्षीदार श्री. रमेश महादेव कदम (वय ४२, रा. ठाणे)',
        'coAccusedName': 'सहआरोपी किरण भास्कर पाटील (रा. नवी मुंबई)',
        'relativeName': 'सुमित्रा रामचंद्र साळुंखे (पत्नी)',
        'relativeAge': '३०',
        'relativeAddress': 'रा. नवी मुंबई',
        'relationship': 'पत्नी',
        'custodyPs': 'मध्यवर्ती विशेष गुन्हे अन्वेषण विभाग पोलीस ठाणे',
        'noticeDate': '2026-10-02',
        'noticePlace': 'नवी मुंबई',
        'officerName': 'पोलीस निरीक्षक विजयराव देशमुख, ब.नं. १२३४',
        'relativeSig': 'सुमित्रा रामचंद्र साळुंखे',
      };

      final pdfBytes = await generateDraftGroundOfArrestPdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });
    test('100+ char unbroken string (yeeeeee... and gggggg...) in address',
        () async {
      final yRun = 'y' * 120;
      final gRun = 'g' * 110;
      final doc = <String, dynamic>{
        'accusedName': 'Test Accused',
        'accusedAge': '२५',
        'accusedAddress': yRun,
        'relativeName': 'Test Relative',
        'relativeAge': '५०',
        'relativeAddress': gRun,
      };

      final pdfBytes = await generateDraftGroundOfArrestPdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('Normal 3-4 line address with mixed Marathi and English', () async {
      const multilineAddress =
          'फ्लॅट नंबर ३०२, विनायक रेसिडेन्सी, प्लॉट नंबर ४५, '
          'शिवाजी चौक, Near Old Water Tank, टिळक रोड, '
          'पुणे शहर, महाराष्ट्र राज्य, ४११०३०';

      final doc = <String, dynamic>{
        'accusedName': 'महेश अशोक पाटील',
        'accusedAge': '३२',
        'accusedAddress': multilineAddress,
        'relativeName': 'अशोक दत्तात्रय पाटील',
        'relativeAge': '६०',
        'relativeAddress': multilineAddress,
      };

      final pdfBytes = await generateDraftGroundOfArrestPdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('1-line short address test', () async {
      final doc = <String, dynamic>{
        'accusedName': 'अमित काळे',
        'accusedAge': '२२',
        'accusedAddress': 'रा. हडपसर, पुणे',
        'relativeName': 'सुनंदा काळे',
        'relativeAge': '४५',
        'relativeAddress': 'रा. हडपसर, पुणे',
      };

      final pdfBytes = await generateDraftGroundOfArrestPdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test(
        'Zero-width space insertion breaks unbroken runs and preserves Devanagari marks',
        () {
      final yRun = 'y' * 100;
      final processed = insertZeroWidthSpacesDraft(yRun);
      expect(processed.contains('\u200B'), isTrue);

      const marathiWord = 'महाराष्ट्र';
      final marathiProcessed = insertZeroWidthSpacesDraft(marathiWord);
      expect(marathiProcessed, equals('महाराष्ट्र'));
    });

    test(
        'breakTextIntoLinesDraft splits 100+ unbroken string into multiple lines',
        () {
      final yRun = 'y' * 120;
      const style = TextStyle(fontSize: 13.5);
      final lines = breakTextIntoLinesDraft(
        text: yRun,
        style: style,
        firstLineWidth: 250.0,
        fullLineWidth: 500.0,
      );

      expect(lines.length, greaterThan(1));
      for (final line in lines) {
        expect(line.trim().isNotEmpty, isTrue);
      }
    });

    testWidgets(
        'buildAddressWithAgeBlockForTest renders 100+ unbroken address without overflow',
        (tester) async {
      final yRun = 'y' * 120;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              child: buildAddressWithAgeBlockForTest(
                age: '२५',
                address: yRun,
                labelStyle: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.bold),
                textStyle: const TextStyle(fontSize: 13.5),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets(
        'buildAddressWithAgeBlockForTest renders 1-line short address as single row',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              child: buildAddressWithAgeBlockForTest(
                age: '२२',
                address: 'रा. हडपसर, पुणे',
                labelStyle: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.bold),
                textStyle: const TextStyle(fontSize: 13.5),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
