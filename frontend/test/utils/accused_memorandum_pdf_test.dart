import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/utils/accused_memorandum_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Accused Memorandum PDF Tests', () {
    test('Empty fields test: generates PDF without crashing', () async {
      final doc = <String, dynamic>{};
      final pdfBytes = await generateAccusedMemorandumPdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('200+ char accused name & address with spaces test', () async {
      const longText =
          'रमेश चंद्रकांत पाटील, वय ३२ वर्षे, व्यवसाय शेती, रा. घर नं. १२३, मारुती मंदिराशेजारी, मुख्य रस्ता, ता. हवेली, जि. पुणे, महाराष्ट्र राज्य, भारत, पिन कोड ४११०३८, फोन ९८७६५४३२१०';
      expect(longText.length, greaterThan(100));

      final doc = <String, dynamic>{
        'dist': 'पुणे ग्रामीण',
        'ps': 'हवेली पोलीस ठाणे',
        'year': '२०२६',
        'firNo': '१२३/२६',
        'firDate': '०५/१०/२०२६',
        'accusedName': longText,
        'accusedAge': '३२',
        'accusedSex': 'पुरुष',
        'arrestDate': '०५/१०/२०२६',
        'arrestTime': '१०:३० AM',
        'accusedMemorandum':
            'मी माझ्या ताब्यातील गुन्ह्यात वापरलेली वस्तू काढून देण्यास तयार असून ती मी घटनास्थळाजवळ लपवून ठेवली आहे. सदर ठिकाणी मी पोलिसांना आणि पंचांना घेऊन जाण्यास तयार आहे.',
        'placeOfMemorandum': 'हवेली पोलीस ठाणे तपास कक्ष',
        'memDate': '०५/१०/२०२६',
        'memTime': '११:०० AM ते ११:४५ AM पर्यंत',
        'panch1NameAddr': 'सुरेश विष्णू शिंदे, वय ४५, रा. हवेली, पुणे',
        'panch1Sig': 'सुरेश शिंदे',
        'panch2NameAddr': 'गणेश मारुती पवार, वय ३८, रा. हवेली, पुणे',
        'panch2Sig': 'गणेश पवार',
        'part1AccusedSig': 'रमेश पाटील',
        'part1IoName': 'पो.उप.नि. संजय काळे',
        'part1IoRank': 'PSI',
        'part1IoNo': '१२३४',
        'part1IoPosting': 'हवेली पो.स्टे.',
      };

      final pdfBytes = await generateAccusedMemorandumPdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('150+ char unbroken run without spaces test', () async {
      const unbroken =
          'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz';
      expect(unbroken.length, greaterThan(150));

      final doc = <String, dynamic>{
        'dist': 'Pune',
        'accusedMemorandum': unbroken,
        'furtherPanchanama': unbroken,
      };

      final pdfBytes = await generateAccusedMemorandumPdf(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('Section filtering: Part I only, Part II only, and Complete form',
        () async {
      final docComplete = <String, dynamic>{'formSection': ''};
      final bytesComplete = await generateAccusedMemorandumPdf(docComplete);
      expect(bytesComplete.length, greaterThan(1000));

      final docPartI = <String, dynamic>{'formSection': 'Accused Part I'};
      final bytesPartI = await generateAccusedMemorandumPdf(docPartI);
      expect(bytesPartI.length, greaterThan(1000));

      final docPartII = <String, dynamic>{'formSection': 'Accused Part II'};
      final bytesPartII = await generateAccusedMemorandumPdf(docPartII);
      expect(bytesPartII.length, greaterThan(1000));
    });

    testWidgets('Widget build test for Page 1 and Page 2', (tester) async {
      final sampleDoc = <String, dynamic>{
        'dist': 'पुणे',
        'ps': 'शिवाजीनगर पोलीस ठाणे',
        'year': '२०२६',
        'firNo': '४५६/२६',
        'firDate': '०५/१०/२०२६',
        'accusedName': 'अजय विनायक जोशी, रा. सदाशिव पेठ, पुणे',
        'accusedAge': '२८',
        'accusedSex': 'पुरुष',
        'arrestDate': '०५/१०/२०२६',
        'arrestTime': '०९:१५ AM',
        'accusedMemorandum':
            'मी गुन्ह्यात वापरलेला मुद्देमाल दाखवून काढून देतो.',
        'placeOfMemorandum': 'शिवाजीनगर पोलीस स्टेशन',
        'memDate': '०५/१०/२०२६',
        'memTime': '१०:०० AM ते १०:३० AM',
        'panch1NameAddr': '१) विजय मोरे, रा. पुणे',
        'panch1Sig': 'विजय',
        'panch2NameAddr': '२) दीपक सावंत, रा. पुणे',
        'panch2Sig': 'दीपक',
        'part1AccusedSig': 'अजय जोशी',
        'part1IoName': 'सचिन कदम',
        'part1IoRank': 'PI',
        'part1IoNo': '५६७',
        'part1IoPosting': 'शिवाजीनगर',
      };

      final key1 = GlobalKey();
      final key2 = GlobalKey();
      final p1 = accusedMemorandumPg1Widget(sampleDoc, key1);
      final p2 = accusedMemorandumPg2Widget(sampleDoc, key2);

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

      expect(box1?.size.width, equals(794.0));
      expect(box1?.size.height, equals(1123.0));
      expect(box2?.size.width, equals(794.0));
      expect(box2?.size.height, equals(1123.0));
    });
  });
}
