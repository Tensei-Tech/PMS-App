import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/utils/ground_of_arrest_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ground of Arrest PDF Tests', () {
    test('Empty fields test: generates exactly 2 pages with no errors',
        () async {
      final doc = <String, dynamic>{};
      final pdfBytes = await generateGroundOfArrestPdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('200+ char address with spaces test', () async {
      const longAddress =
          'घर क्रमांक १२३, साई श्रद्धा निवास, विठ्ठल रुक्मिणी मंदिर जवळ, मुख्य चौक, शिवाजी नगर, ता. हवेली, जि. पुणे, महाराष्ट्र राज्य, भारत पिन कोड ४११०१६ फोन नंबर ९८७६५४३२१० आणि अतिरिक्त पत्ता तपशील येथे नमूद करण्यात येत आहे, फ्लॅट क्रमांक ४०२';
      expect(longAddress.length, greaterThan(200));

      final doc = <String, dynamic>{
        'outwardNo': '1234/2026',
        'outwardYear': '२६',
        'policeStation': 'शिवाजीनगर पोलीस स्टेशन पुणे शहर',
        'accusedNameAddress': longAddress,
        'accusedNameAddressLine2': 'पर्यायी पत्ता: कोथरूड, पुणे ४११०३८',
        'subjectPs': 'शिवाजीनगर',
        'subjectCrNo': '४५६/२६',
        'subjectSection': '१०३(१)',
        'firPs': 'शिवाजीनगर',
        'firCrNo': '४५६',
        'firCrYear': '२०२६',
        'firActSec': '१०३(१)',
        'ioName': 'पो.नि. सचिन कदम',
        'briefDescription':
            'आरोपीने फिर्यादी यांचेवर प्राणघातक हल्ला करून गंभीर जखमी केल्याचे निष्पन्न झाले आहे.',
      };

      final pdfBytes = await generateGroundOfArrestPdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('150+ char address without spaces (unbroken run) test', () async {
      const unbrokenAddress =
          'hhhhhhhhkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk';
      expect(unbrokenAddress.length, greaterThan(150));

      final doc = <String, dynamic>{
        'accusedNameAddress': unbrokenAddress,
      };

      final pdfBytes = await generateGroundOfArrestPdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('Long police station name & long text in all 5 grounds test',
        () async {
      final doc = <String, dynamic>{
        'policeStation':
            'मध्यवर्ती विशेष गुन्हे अन्वेषण विभाग पोलीस स्टेशन, परिमंडळ ४, बृहन्मुंबई महानगर',
        'ground1':
            'आरोपी हा गुन्ह्याच्या घटनास्थळी प्रत्यक्ष उपस्थित असल्याबाबत प्रत्यक्षदर्शी साक्षीदारांचे जबाब नोंदविण्यात आलेले आहेत.',
        'ground1Line2':
            'तसेच आरोपीच्या ताब्यातून गुन्ह्यात वापरलेले हत्यार व इतर पुरावे जप्त करावयाचे आहेत.',
        'ground2':
            'सदर गुन्ह्यातील सहआरोपी अद्याप फरार असून त्यांच्या ठावठिकाण्याबाबत आरोपीकडे सखोल तपास करणे अत्यंत गरजेचे आहे.',
        'ground2Line2':
            'आरोपी तपासकामी सहकार्य करत नसून वस्तुस्थिती लपविण्याचा प्रयत्न करीत आहे.',
        'ground3':
            'आरोपीने गुन्ह्यातील महत्त्वाचा पुरावा नष्ट करण्याचा व साक्षीदारांवर दबाव आणण्याचा प्रयत्न केल्याचे तपासात निष्पन्न झाले आहे.',
        'ground3Line2':
            'न्यायालयातील उपस्थिती निश्चित करण्यासाठी आरोपीस अटक करणे आवश्यक आहे.',
        'ground4':
            'घटनास्थळावरील सीसीटीव्ही फुटेजची तपासणी केली असता आरोपीचा गुन्ह्यातील प्रत्यक्ष सहभाग स्पष्टपणे दिसून येत आहे.',
        'ground4Line2':
            'याबाबत आरोपीची ओळख पटवून सविस्तर पंचनामा करणे गरजेचे आहे.',
        'ground5':
            'नमुद गुन्हा हा दखलपात्र व अजामीनपात्र स्वरूपाचा असून आरोपी मोकाट राहिल्यास पुन्हा अशाच प्रकारचा गंभीर गुन्हा करण्याची शक्यता आहे.',
        'ground5Line2':
            'त्यामुळे नागरिकांच्या सुरक्षेच्या दृष्टीने आरोपीस अटक करणे अपरिहार्य आहे.',
        'relativeName': 'श्री. विनायक गोपाळ जोशी (भाऊ)',
        'relativeAddress': 'रा. सदाशिव पेठ, पुणे',
        'relativePhone': '९८२२१२३४५६',
        'accusedName': 'अजय विनायक जोशी',
        'accusedDateTime': '०२/१०/२०२६ १०:३० AM',
        'ioNameRank': 'पोलीस निरीक्षक संजय काळे',
        'ioPs': 'शिवाजीनगर',
        'ioTah': 'हवेली',
        'ioDist': 'पुणे',
      };

      final pdfBytes = await generateGroundOfArrestPdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    testWidgets('Measure unscaled content height of Page 1 and Page 2',
        (tester) async {
      final sampleDoc = <String, dynamic>{
        'outwardNo': '1234/2026',
        'outwardYear': '२६',
        'policeStation': 'शिवाजीनगर पोलीस स्टेशन',
        'outwardDate': '02/10/2026',
        'accusedNameAddress': 'अजय विनायक जोशी, रा. शिवाजीनगर, पुणे',
        'subjectPs': 'शिवाजीनगर',
        'subjectCrNo': '४५६/२६',
        'subjectSection': '१०३(१)',
        'firPs': 'शिवाजीनगर',
        'firCrNo': '४५६',
        'firCrYear': '२०२६',
        'firActSec': '१०३(१)',
        'ioName': 'पो.नि. सचिन कदम',
        'briefDescription':
            'आरोपीने फिर्यादी यांचेवर प्राणघातक हल्ला करून गंभीर जखमी केल्याचे निष्पन्न झाले आहे.',
        'ground1': 'आरोपी हा गुन्ह्याच्या घटनास्थळी प्रत्यक्ष उपस्थित होता.',
        'ground2': 'सदर गुन्ह्यातील सहआरोपी अद्याप फरार असून तपास करणे आहे.',
        'ground3':
            'आरोपीने गुन्ह्यातील महत्त्वाचा पुरावा नष्ट करण्याचा प्रयत्न केला.',
        'ground4':
            'सीसीटीव्ही फुटेजची तपासणी केली असता सहभाग स्पष्ट दिसून येतो.',
        'ground5': 'नमुद गुन्हा दखलपात्र व अजामीनपात्र स्वरूपाचा आहे.',
        'relativeName': 'श्री. विनायक गोपाळ जोशी (भाऊ)',
        'relativeAddress': 'रा. सदाशिव पेठ, पुणे',
        'relativePhone': '९८२२१२३४५६',
        'accusedName': 'अजय विनायक जोशी',
        'accusedDateTime': '०२/१०/२०२६ १०:३० AM',
        'ioNameRank': 'पोलीस निरीक्षक संजय काळे',
        'ioPs': 'शिवाजीनगर',
        'ioTah': 'हवेली',
        'ioDist': 'पुणे',
      };

      final key1 = GlobalKey();
      final key2 = GlobalKey();
      final p1 = groundOfArrestPg1Widget(sampleDoc, key1);
      final p2 = groundOfArrestPg2Widget(sampleDoc, key2);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [p1, p2],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final box1 = key1.currentContext?.findRenderObject() as RenderBox?;
      final box2 = key2.currentContext?.findRenderObject() as RenderBox?;

      debugPrint('TEST_PAGE_1_UNSCALED_HEIGHT: ${box1?.size.height} px');
      debugPrint('TEST_PAGE_2_UNSCALED_HEIGHT: ${box2?.size.height} px');

      expect(box1?.size.height, isNotNull);
      expect(box2?.size.height, isNotNull);

      // Also measure with all empty fields
      final emptyDoc = <String, dynamic>{};
      final emptyKey1 = GlobalKey();
      final emptyKey2 = GlobalKey();
      final ep1 = groundOfArrestPg1Widget(emptyDoc, emptyKey1);
      final ep2 = groundOfArrestPg2Widget(emptyDoc, emptyKey2);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [ep1, ep2],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final emptyBox1 =
          emptyKey1.currentContext?.findRenderObject() as RenderBox?;
      final emptyBox2 =
          emptyKey2.currentContext?.findRenderObject() as RenderBox?;
      debugPrint('EMPTY_PAGE_1_UNSCALED_HEIGHT: ${emptyBox1?.size.height} px');
      debugPrint('EMPTY_PAGE_2_UNSCALED_HEIGHT: ${emptyBox2?.size.height} px');
    });
  });
}
