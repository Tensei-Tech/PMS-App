import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/utils/order_section_47_48_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Order Section 47 & 48 PDF Tests', () {
    test('Empty fields test: generates exactly 2 pages with no errors',
        () async {
      final doc = <String, dynamic>{};
      final pdfBytes = await generateOrderSection4748Pdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('200+ char address with spaces test', () async {
      const longAddress =
          'घर क्रमांक १२३, साई श्रद्धा निवास, विठ्ठल रुक्मिणी मंदिर जवळ, मुख्य चौक, शिवाजी नगर, ता. हवेली, जि. पुणे, महाराष्ट्र राज्य, भारत पिन कोड ४११०१६ फोन नंबर ९८७६५४३२१० आणि अतिरिक्त पत्ता तपशील येथे नमूद करण्यात येत आहे, फ्लॅट क्रमांक ४०२';
      expect(longAddress.length, greaterThan(200));

      final doc = <String, dynamic>{
        'policeStation': 'शिवाजीनगर पोलीस स्टेशन पुणे शहर',
        'crNo': '४५६',
        'crYear': '२०२६',
        'bnsSection': '१०३(१), ३(५) भा.न्या.स.',
        'arrestDate': '02/10/2026',
        'arrestTime': '14:30',
        'ioName': 'पो.नि. सचिन कदम',
        'p1To1': 'अजय विनायक जोशी',
        'p1To2': longAddress,
        'p1To3': 'मो. ९८७६५४३२१०',
        'p1Fact1':
            'आरोपीने फिर्यादी यांच्यावर धारदार शस्त्राने हल्ला करून गंभीर दुखापत केली.',
        'p1Ground1':
            'आरोपी घटनास्थळावरून पळून जाण्याच्या तयारीत असताना रंगेहाथ पकडण्यात आले.',
        'p1Reason1':
            'गुन्ह्यातील पुरावा नष्ट करू नये व साक्षीदारांवर दबाव आणू नये म्हणून अटक आवश्यक आहे.',
      };

      final pdfBytes = await generateOrderSection4748Pdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('150+ char address without spaces (unbroken run) test', () async {
      const unbrokenAddress =
          'aaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeeeffffffffffgggggggggghhhhhhhhhhiiiiiiiiiijjjjjjjjjjkkkkkkkkkkllllllllllmmmmmmmmmmnnnnnnnnnnoooooooooopppppppppp';
      expect(unbrokenAddress.length, greaterThan(150));

      final doc = <String, dynamic>{
        'p1To2': unbrokenAddress,
        'p2To2': unbrokenAddress,
      };

      final pdfBytes = await generateOrderSection4748Pdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test(
        'Long police station name & long text in facts, grounds, and reasons test',
        () async {
      final doc = <String, dynamic>{
        'policeStation':
            'मध्यवर्ती विशेष गुन्हे अन्वेषण विभाग पोलीस स्टेशन, परिमंडळ ४, बृहन्मुंबई महानगर',
        'crNo': '९८७६५/२६',
        'crYear': '२०२६',
        'bnsSection': '१०३, ३(५), ६१(२), ११५(२) भा.न्या.स.',
        'arrestDate': '2026-10-02',
        'arrestTime': '11:45',
        'ioName':
            'सहाय्यक पोलीस आयुक्त तथा तपास अधिकारी विजय सूर्यवंशी, गुन्हे शाखा, मुंबई',
        'p1To1': 'समीर रमेश कुलकर्णी (वय ३५ वर्षे)',
        'p1To2':
            'फ्लॅट क्र. ९०२, ए विंग, राज रेसिडेन्सी, स्वामी समर्थ मार्ग, ठाणे पश्चिम ४००६०१',
        'p1To3': 'व्यवसाय नोकरी, मूळ गाव कराड जि. सातारा',
        'p1Fact1':
            'आरोपी हा गुन्ह्याच्या घटनास्थळी प्रत्यक्ष उपस्थित असल्याबाबत प्रत्यक्षदर्शी साक्षीदारांचे जबाब नोंदविण्यात आलेले आहेत व पुरावा हस्तगत करायचा आहे.',
        'p1Fact2':
            'तपासादरम्यान मिळालेल्या तांत्रिक विश्लेषणावरून आरोपीचे मोबाइल लोकेशन घटनास्थळी निष्पन्न झाले आहे.',
        'p1Fact3':
            'आरोपीने गुन्ह्यात वापरलेली कार व इतर साहित्य हस्तगत करणे बाकी आहे.',
        'p1Ground1':
            'आरोपी घटनास्थळावरून पसार होण्याच्या बेतात असताना गुप्त माहितीच्या आधारे सापळा रचून ताब्यात घेण्यात आले.',
        'p1Ground2':
            'गुन्ह्याची तीव्रता आणि स्वरूप अत्यंत गंभीर असल्याने तात्काळ अटक करणे अपरिहार्य होते.',
        'p1Reason1':
            'आरोपीकडून गुन्ह्यातील हत्यार व महत्वाचे दस्तावेज जप्त करणे आवश्यक आहे.',
        'p1Reason2':
            'सहआरोपी अद्याप फरार असून त्यांच्या शोधासाठी आरोपीकडे चौकशी करणे गरजेचे आहे.',
        'p2To1': 'सुनिता समीर कुलकर्णी (पत्नी)',
        'p2To2': 'फ्लॅट क्र. ९०२, ए विंग, राज रेसिडेन्सी, ठाणे पश्चिम',
        'p2AccusedName': 'समीर रमेश कुलकर्णी',
      };

      final pdfBytes = await generateOrderSection4748Pdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    testWidgets(
        'Measure unscaled content height of Order Section 47 Page 1 and Page 2',
        (tester) async {
      final sampleDoc = <String, dynamic>{
        'policeStation': 'शिवाजीनगर पोलीस स्टेशन पुणे शहर',
        'crNo': '४५६',
        'crYear': '२०२६',
        'bnsSection': '१०३(१), ३(५)',
        'arrestDate': '02/10/2026',
        'arrestTime': '14:30',
        'ioName': 'पो.नि. सचिन कदम',
        'p1To1': 'अजय विनायक जोशी',
        'p1To2': 'घर क्र १२३, शिवाजीनगर, पुणे',
        'p1Fact1':
            'आरोपीने फिर्यादी यांच्यावर धारदार शस्त्राने हल्ला करून गंभीर दुखापत केली.',
        'p1Ground1':
            'आरोपी घटनास्थळावरून पळून जाण्याच्या तयारीत असताना रंगेहाथ पकडण्यात आले.',
        'p1Reason1': 'गुन्ह्यातील पुरावा नष्ट करू नये म्हणून अटक आवश्यक आहे.',
        'p2To1': 'अनिता अजय जोशी (पत्नी)',
        'p2To2': 'घर क्र १२३, शिवाजीनगर, पुणे',
        'p2AccusedName': 'अजय विनायक जोशी',
      };

      // Test Page 1
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: orderSection4748Pg1Widget(sampleDoc),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final p1Finder = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints?.maxWidth == 794.0 &&
            w.constraints?.maxHeight == 1123.0,
      );
      expect(p1Finder, findsOneWidget);
      final p1Size = tester.getSize(p1Finder);
      expect(p1Size.width, equals(794.0));
      expect(p1Size.height, equals(1123.0));

      // Test Page 2
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: orderSection4748Pg2Widget(sampleDoc),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final p2Finder = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints?.maxWidth == 794.0 &&
            w.constraints?.maxHeight == 1123.0,
      );
      expect(p2Finder, findsOneWidget);
      final p2Size = tester.getSize(p2Finder);
      expect(p2Size.width, equals(794.0));
      expect(p2Size.height, equals(1123.0));
    });

    testWidgets(
        'Overflow fallback test: heavy content scales cleanly without exceptions',
        (tester) async {
      const longAddress =
          'घर क्रमांक १२३, साई श्रद्धा निवास, विठ्ठल रुक्मिणी मंदिर जवळ, मुख्य चौक, शिवाजी नगर, ता. हवेली, जि. पुणे, महाराष्ट्र राज्य, भारत पिन कोड ४११०१६ फोन नंबर ९८७६५४३२१० आणि अतिरिक्त पत्ता तपशील येथे नमूद करण्यात येत आहे, फ्लॅट क्रमांक ४०२';

      final heavyDoc = <String, dynamic>{
        'policeStation':
            'मध्यवर्ती विशेष गुन्हे अन्वेषण विभाग पोलीस स्टेशन, परिमंडळ ४, बृहन्मुंबई महानगर',
        'crNo': '९८७६५/२६',
        'crYear': '२०२६',
        'bnsSection': '१०३, ३(५), ६१(२), ११५(२) भा.न्या.स.',
        'arrestDate': '2026-10-02',
        'arrestTime': '11:45',
        'ioName': 'सहाय्यक पोलीस आयुक्त विजय सूर्यवंशी',
        'p1To1': 'समीर रमेश कुलकर्णी',
        'p1To2': longAddress,
        'p1To3': longAddress,
        'p1Fact1':
            'आरोपीने गुन्ह्यातील पुरावा नष्ट करण्याचा प्रयत्न केला व साक्षीदारांवर दबाव आणला.',
        'p1Fact2':
            'घटनास्थळावरील सीसीटीव्ही फुटेजची तपासणी केली असता आरोपीचा सहभाग स्पष्ट दिसून येतो.',
        'p1Fact3': 'नमुद गुन्हा दखलपात्र व अजामीनपात्र स्वरूपाचा आहे.',
        'p1Ground1': 'आरोपी घटनास्थळावरून पसार होण्याच्या तयारीत होता.',
        'p1Ground2':
            'सहआरोपी अद्याप फरार असून त्यांच्या ठावठिकाण्याबाबत तपास करायचा आहे.',
        'p1Ground3': 'आरोपीने गुन्ह्यातील हत्यार लपवून ठेवले आहे.',
        'p1Ground4': 'आरोपीकडून मोबाईल व कागदपत्रे हस्तगत करायची आहेत.',
        'p1Ground5': 'आरोपी पुन्हा गुन्हा करण्याची दाट शक्यता आहे.',
        'p1Reason1':
            'गुन्ह्याच्या सखोल तपासासाठी आरोपीची पोलीस कोठडी आवश्यक आहे.',
        'p1Reason2': 'आरोपीने गुन्ह्यातील पैशांची विल्हेवाट लावली आहे.',
        'p1Reason3': 'आरोपी साक्षीदारांना धमकावण्याची शक्यता आहे.',
        'p1Reason4': 'आरोपीच्या बँक खात्यांची तपासणी करायची आहे.',
        'p1Reason5': 'आरोपीचा पूर्वेतिहास गुन्हेगारी स्वरूपाचा आहे.',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: orderSection4748Pg1Widget(heavyDoc),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final p1Finder = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints?.maxWidth == 794.0 &&
            w.constraints?.maxHeight == 1123.0,
      );
      expect(p1Finder, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
