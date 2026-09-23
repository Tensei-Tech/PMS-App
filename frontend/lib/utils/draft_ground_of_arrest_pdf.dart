// lib/utils/draft_ground_of_arrest_pdf.dart
//
// IMAGE-BASED PDF generation for Draft Ground of Arrest forms:
//   Page 9:  अटकेचा आधार (कलम ४७ BNSS) — Notice to Accused
//   Page 10: नातेवाईक/ मित्रांसाठी अटकेची नोटीस (कलम ४८ BNSS) — Notice to Relative
//   Page 11: अटकेचे कारणे [कलम ३५(१)(ब) BNSS ] — Reasons of Arrest to Accused
//
// Each page is rendered as a native Flutter widget via an offscreen RepaintBoundary,
// captured at high DPI (2.0x = 1588x2246 px), and assembled into a clean A4 PDF.
// This guarantees 100% pixel-perfect Devanagari/Marathi font shaping (HarfBuzz).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'form_image_pdf_helper.dart';

// ── A4 layout constants at 96 DPI ──────────────────────────────────────────
const double _kW = 794.0;
const double _kH = 1123.0;

// ─────────────────────────────────────────────────────────────────────────────
// Public Entrypoints
//─────────────────────────────────────────────────────────────────────────────

Future<void> previewDraftGroundOfArrestPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Draft_Ground_of_Arrest_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final s = (doc['formSection'] ?? '').toString().toLowerCase();
  final p9Match = s.contains('9') || s.contains('47') || s.contains('आधार');
  final p10Match =
      s.contains('10') || s.contains('48') || s.contains('नातेवाईक');
  final p11Match = s.contains('11') || s.contains('35') || s.contains('कारणे');
  final showAll = s.isEmpty ||
      s.contains('complete') ||
      (!p9Match && !p10Match && !p11Match);

  final showP9 = showAll || p9Match;
  final showP10 = showAll || p10Match;
  final showP11 = showAll || p11Match;

  final pages = <Widget>[];
  if (showP9) pages.add(_pg9(doc));
  if (showP10) pages.add(_pg10(doc));
  if (showP11) pages.add(_pg11(doc));

  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: pages,
    fallbackPdfGenerator: () => generateDraftGroundOfArrestPdf(doc),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Helpers & Typography
// ─────────────────────────────────────────────────────────────────────────────

String _v(Map<String, dynamic> doc, String key, [String fallback = '']) {
  final val = doc[key]?.toString().trim() ?? '';
  return val.isEmpty ? fallback : val;
}

bool _b(Map<String, dynamic> doc, String key, [bool def = true]) {
  final val = doc[key];
  if (val is bool) return val;
  return def;
}

TextStyle _mReg([double sz = 10.5, double ht = 1.45]) =>
    GoogleFonts.notoSansDevanagari(
      fontSize: sz,
      height: ht,
      color: Colors.black87,
    );

TextStyle _mBld([double sz = 10.5, double ht = 1.45]) =>
    GoogleFonts.notoSansDevanagari(
      fontSize: sz,
      height: ht,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

TextStyle _valStyle([double sz = 10.5]) => GoogleFonts.notoSansDevanagari(
      fontSize: sz,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF0D47A1),
    );

Widget _prosecutorBox(String pageLabel) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(width: 100),
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          pageLabel,
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black87, width: 0.8),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Gaware Ashok',
              style: GoogleFonts.lora(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Public Prosecutor A.Nagar',
              style: GoogleFonts.lora(fontSize: 8, color: Colors.black87),
            ),
            Text(
              '9823911047',
              style: GoogleFonts.lora(fontSize: 8, color: Colors.black87),
            ),
          ],
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 9: अटकेचा आधार (कलम ४७ BNSS) — Notice to Accused
// ─────────────────────────────────────────────────────────────────────────────

Widget _pg9(Map<String, dynamic> doc) {
  final accusedName = _v(doc, 'accusedName');
  final accusedAge = _v(doc, 'accusedAge');
  final accusedAddress = _v(doc, 'accusedAddress');
  final psName = _v(doc, 'psName');
  final crNo = _v(doc, 'crNo');
  final bnsSection = _v(doc, 'bnsSection');
  final arrestDate = _v(doc, 'arrestDate');
  final arrestTime = _v(doc, 'arrestTime');
  final briefFacts = _v(doc, 'briefFacts');

  final g1Fir = _b(doc, 'g1Fir', _b(doc, 's48G1', true));
  final g2Witness = _b(doc, 'g2Witness', _b(doc, 's48G2', true));
  final witnessName = _v(doc, 'witnessName', _v(doc, 's48WitnessName'));
  final g3Cctv = _b(doc, 'g3Cctv', _b(doc, 's48G3', true));
  final g4Recovery = _b(doc, 'g4Recovery', true);
  final g5Confession = _b(doc, 'g5Confession', _b(doc, 's48G5', true));
  final g6CoAccused = _b(doc, 'g6CoAccused', _b(doc, 's48G6', true));
  final coAccusedName = _v(doc, 'coAccusedName', _v(doc, 's48CoAccused'));
  final g7Cdr = _b(doc, 'g7Cdr', true);

  final relativeName = _v(doc, 'relativeName', _v(doc, 's48RelativeName'));
  final noticeDate = _v(doc, 'noticeDate', _v(doc, 's48Date'));
  final officerName = _v(doc, 'officerName', _v(doc, 's48OfficerSig'));

  final groundRows = <TableRow>[
    TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Center(child: Text('अ.क्र.', style: _mBld(9.5))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
          child: Center(
            child: Text('अटकेचे आधार ( Ground of Arrest )', style: _mBld(9.5)),
          ),
        ),
      ],
    ),
  ];

  void addGround(String num, Widget textWidget) {
    groundRows.add(
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Center(child: Text(num, style: _mBld(9))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 6),
            child: textWidget,
          ),
        ],
      ),
    );
  }

  if (g1Fir) {
    addGround(
      '१',
      Text(
        'फिर्यादीने दाखल केलेल्या FIR मध्ये तुमचे विरुद्ध आरोप केलेले आहेत.',
        style: _mReg(9),
      ),
    );
  }
  if (g2Witness) {
    addGround(
      '२',
      RichText(
        text: TextSpan(
          style: _mReg(9),
          children: [
            const TextSpan(text: 'प्रत्यक्षदर्शी साक्षीदार '),
            TextSpan(
              text: witnessName.isNotEmpty ? witnessName : '[नाव]',
              style: witnessName.isNotEmpty ? _valStyle(9) : _mReg(9),
            ),
            const TextSpan(
              text:
                  ' यांनी दिलेल्या जबाबानुसार गुन्ह्यामध्ये तुमचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
            ),
          ],
        ),
      ),
    );
  }
  if (g3Cctv) {
    addGround(
      '३',
      Text(
        'घटनास्थळावरील पुराव्यांच्या (CCTV / डिजिटल रेकॉर्ड / मोबाईल व्हिडिओ ) आधारे गुन्ह्यामध्ये तुमचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
        style: _mReg(9),
      ),
    );
  }
  if (g4Recovery) {
    addGround(
      '४',
      Text(
        'गुन्ह्यात वापरलेले हत्यार / चोरीची मालमत्ता / गुन्ह्याशी संबंधित महत्त्वाचे दस्तऐवज हे केवळ तुमच्याकडे असलेल्या माहितीच्या आधारे आणि तुमच्या ताब्यातून हस्तगत करण्यात आले आहेत.',
        style: _mReg(9),
      ),
    );
  }
  if (g5Confession) {
    addGround(
      '५',
      Text('तुम्ही गुन्हा केल्याची कबुली दिली आहे.', style: _mReg(9)),
    );
  }
  if (g6CoAccused) {
    addGround(
      '६',
      RichText(
        text: TextSpan(
          style: _mReg(9),
          children: [
            const TextSpan(text: 'गुन्ह्यातील सहआरोपी '),
            TextSpan(
              text: coAccusedName.isNotEmpty ? coAccusedName : ' ',
              style: coAccusedName.isNotEmpty ? _valStyle(9) : _mReg(9),
            ),
            const TextSpan(
              text:
                  ' यांनी तुम्ही गुन्ह्यामध्ये सहभागी असल्याचे कबुल केले आहे.',
            ),
          ],
        ),
      ),
    );
  }
  if (g7Cdr) {
    addGround(
      '७',
      Text(
        'मोबाईल CDR वरून घटनेच्या दिवशी तुमचे tower location घटनास्थळाजवळ असल्याचे दिसून आले आहे.',
        style: _mReg(9),
      ),
    );
  }

  return Container(
    width: _kW,
    height: _kH,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _prosecutorBox('Page 9 of 13'),
        const SizedBox(height: 8),

        // Title
        Center(
          child: Text(
            'अटकेचा आधार (कलम ४७ BNSS)',
            style: _mBld(14).copyWith(decoration: TextDecoration.underline),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle
        Center(
          child: Text(
            '(भारतीय नागरिक सुरक्षा संहिता, २०२३ च्या कलम ४७ आणि भारतीय संविधान कलम २२(१) अन्वये तसेच माननीय सर्वोच्च न्यायालयाच्या \'पंकज बन्सल\', \'प्रबीर पुरकायस्थ\', \'विद्वान कुमार\' आणि \'मिहीर शाह\' निवाड्यांमधील मार्गदर्शक तत्त्वांच्या अधीन)',
            style: _mReg(8.8, 1.3),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),

        // Recipient block
        Text('प्रति,', style: _mBld(10)),
        const SizedBox(height: 3),
        RichText(
          text: TextSpan(
            style: _mBld(10),
            children: [
              const TextSpan(text: 'अटक केलेल्या आरोपीचे नाव: '),
              TextSpan(
                text: accusedName.isNotEmpty ? accusedName : ' ',
                style: accusedName.isNotEmpty ? _valStyle(10) : _mReg(10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        RichText(
          text: TextSpan(
            style: _mBld(10),
            children: [
              const TextSpan(text: 'वय: '),
              TextSpan(
                text: accusedAge.isNotEmpty ? accusedAge : ' ',
                style: accusedAge.isNotEmpty ? _valStyle(10) : _mReg(10),
              ),
              const TextSpan(text: ' वर्ष, पत्ता: '),
              TextSpan(
                text: accusedAddress.isNotEmpty ? accusedAddress : ' ',
                style: accusedAddress.isNotEmpty ? _valStyle(10) : _mReg(10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Notice text
        RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            style: _mReg(9.8, 1.5),
            children: [
              const TextSpan(
                text:
                    'या नोटीसद्वारे तुम्हाला माहिती करण्यात येते की, तुम्हाला पोलीस ठाणे ',
              ),
              TextSpan(
                text: psName.isNotEmpty ? psName : ' ',
                style: psName.isNotEmpty ? _valStyle(9.8) : _mBld(9.8),
              ),
              const TextSpan(
                text: ' येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक ',
              ),
              TextSpan(
                text: crNo.isNotEmpty ? crNo : ' ',
                style: crNo.isNotEmpty ? _valStyle(9.8) : _mBld(9.8),
              ),
              const TextSpan(
                text: ', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम ',
              ),
              TextSpan(
                text: bnsSection.isNotEmpty ? bnsSection : ' ',
                style: bnsSection.isNotEmpty ? _valStyle(9.8) : _mBld(9.8),
              ),
              const TextSpan(
                text: ' अन्वये नोंदवलेल्या गुन्ह्यात आज दिनांक ',
              ),
              TextSpan(
                text: arrestDate.isNotEmpty ? arrestDate : ' ',
                style: arrestDate.isNotEmpty ? _valStyle(9.8) : _mBld(9.8),
              ),
              const TextSpan(text: ' रोजी वेळ '),
              TextSpan(
                text: arrestTime.isNotEmpty ? arrestTime : ' ',
                style: arrestTime.isNotEmpty ? _valStyle(9.8) : _mBld(9.8),
              ),
              const TextSpan(text: ' वाजता अटक करण्यात आली आहे.'),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Brief facts
        Text('गुन्ह्याची थोडक्यात हकीकत :-', style: _mBld(10)),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
          ),
          child: Text(
            briefFacts.isNotEmpty ? briefFacts : ' ',
            style: briefFacts.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
          ),
        ),
        const SizedBox(height: 6),

        // Table 1: Grounds
        Text('अटकेचा आधार :-', style: _mBld(10)),
        const SizedBox(height: 3),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(34),
            1: FlexColumnWidth(1),
          },
          children: groundRows,
        ),
        const SizedBox(height: 6),

        // Table 2: Rights of Accused
        Text('आरोपीचे हक्क /अधिकार :-', style: _mBld(10)),
        const SizedBox(height: 3),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(34),
            1: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Center(child: Text('अ.क्र.', style: _mBld(9.5))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                  child: Center(
                    child: Text('आरोपींचे हक्क', style: _mBld(9.5)),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Center(child: Text('१', style: _mBld(9))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2.5, horizontal: 6),
                  child: Text(
                    'तुम्हाला माननीय न्यायालयासमोर हजर केल्यावर जामीन अर्ज सादर करण्याचा पूर्ण कायदेशीर अधिकार आहे.',
                    style: _mReg(9),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Center(child: Text('२', style: _mBld(9))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2.5, horizontal: 6),
                  child: Text(
                    'तुमच्या पसंतीच्या कायदेशीर सल्लागाराचा (वकिलाचा) सल्ला घेण्याचा, त्यांना पोलीस कोठडीत भेटण्याचा आणि माननीय न्यायालयासमोर रिमांडला कायदेशीर विरोध करण्याचा पूर्ण अधिकार आहे.',
                    style: _mReg(9),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Center(child: Text('३', style: _mBld(9))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2.5, horizontal: 6),
                  child: RichText(
                    text: TextSpan(
                      style: _mReg(9),
                      children: [
                        const TextSpan(
                          text:
                              'तुमच्या अटकेची आणि तुम्हाला ज्या ठिकाणी कोठडीत ठेवण्यात आले आहे त्या ठिकाणाची माहिती तुमच्याद्वारे नामांकित केलेले नातेवाईक/मित्र ',
                        ),
                        TextSpan(
                          text: relativeName.isNotEmpty ? relativeName : ' ',
                          style:
                              relativeName.isNotEmpty ? _valStyle(9) : _mReg(9),
                        ),
                        const TextSpan(text: ' यांना देण्यात आली आहे.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),

        // Page 9 Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('दिनांक :- ', style: _mBld(9.5)),
                Text(
                  noticeDate.isNotEmpty ? noticeDate : ' ',
                  style: noticeDate.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  officerName.isNotEmpty ? officerName : ' ',
                  style: officerName.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
                ),
                const SizedBox(height: 2),
                Text('पोलीस अधिकारी नाव, हुद्दा सही शिक्का', style: _mReg(9)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  accusedName.isNotEmpty ? accusedName : ' ',
                  style: accusedName.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
                ),
                const SizedBox(height: 2),
                Text('आरोपीचे नाव , सही, अंगठा', style: _mReg(9)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 10: नातेवाईक/ मित्रांसाठी अटकेची नोटीस (कलम ४८ BNSS)
// ─────────────────────────────────────────────────────────────────────────────

Widget _pg10(Map<String, dynamic> doc) {
  final accusedName = _v(doc, 'accusedName');
  final accusedAge = _v(doc, 'accusedAge');
  final accusedAddress = _v(doc, 'accusedAddress');
  final psName = _v(doc, 'psName');
  final crNo = _v(doc, 'crNo');
  final bnsSection = _v(doc, 'bnsSection');
  final arrestDate = _v(doc, 'arrestDate');
  final arrestTime = _v(doc, 'arrestTime');
  final briefFacts = _v(doc, 'briefFacts');

  final relativeName = _v(doc, 'relativeName', _v(doc, 's48RelativeName'));
  final relativeAge = _v(doc, 'relativeAge', _v(doc, 's48RelativeAge'));
  final relativeAddress =
      _v(doc, 'relativeAddress', _v(doc, 's48RelativeAddress'));
  final relationship = _v(doc, 'relationship', _v(doc, 's48Relationship'));
  final custodyPs = _v(doc, 'custodyPs', _v(doc, 's48CustodyPs', psName));

  final g1Fir = _b(doc, 'g1Fir', _b(doc, 's48G1', true));
  final g2Witness = _b(doc, 'g2Witness', _b(doc, 's48G2', true));
  final witnessName = _v(doc, 'witnessName', _v(doc, 's48WitnessName'));
  final g3Cctv = _b(doc, 'g3Cctv', _b(doc, 's48G3', true));
  final g5Confession = _b(doc, 'g5Confession', _b(doc, 's48G5', true));
  final g6CoAccused = _b(doc, 'g6CoAccused', _b(doc, 's48G6', true));
  final coAccusedName = _v(doc, 'coAccusedName', _v(doc, 's48CoAccused'));

  final noticeDate = _v(doc, 'noticeDate', _v(doc, 's48Date'));
  final noticePlace = _v(doc, 'noticePlace', _v(doc, 's48Place'));
  final officerName = _v(doc, 'officerName', _v(doc, 's48OfficerSig'));
  final relativeSig = _v(doc, 'relativeSig', _v(doc, 's48RelativeSig'));

  final groundRows = <TableRow>[
    TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Center(child: Text('अ.क्र.', style: _mBld(9.5))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
          child: Center(
            child: Text('अटकेचे आधार (Ground of Arrest )', style: _mBld(9.5)),
          ),
        ),
      ],
    ),
  ];

  void addGround(String num, Widget textWidget) {
    groundRows.add(
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Center(child: Text(num, style: _mBld(9))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 6),
            child: textWidget,
          ),
        ],
      ),
    );
  }

  if (g1Fir) {
    addGround(
      '१',
      Text(
        'FIR मध्ये आरोपीने सदर गुन्हा केल्याचा उल्लेख आहे.',
        style: _mReg(9),
      ),
    );
  }
  if (g2Witness) {
    addGround(
      '२',
      RichText(
        text: TextSpan(
          style: _mReg(9),
          children: [
            const TextSpan(text: 'प्रत्यक्षदर्शी साक्षीदार '),
            TextSpan(
              text: witnessName.isNotEmpty ? witnessName : '[नाव]',
              style: witnessName.isNotEmpty ? _valStyle(9) : _mReg(9),
            ),
            const TextSpan(
              text:
                  ' यांनी दिलेल्या जबाबानुसार गुन्ह्यामध्ये आरोपीचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
            ),
          ],
        ),
      ),
    );
  }
  if (g3Cctv) {
    addGround(
      '३',
      Text(
        'घटनास्थळावरील पुराव्यांच्या CCTV/डिजिटल रेकॉर्ड आधारे गुन्ह्यामध्ये थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
        style: _mReg(9),
      ),
    );
  }
  if (g5Confession) {
    addGround(
      '५',
      Text('आरोपीने गुन्हा केल्याची कबुली दिली आहे.', style: _mReg(9)),
    );
  }
  if (g6CoAccused) {
    addGround(
      '६',
      RichText(
        text: TextSpan(
          style: _mReg(9),
          children: [
            const TextSpan(text: 'गुन्ह्यातील सहआरोपी '),
            TextSpan(
              text: coAccusedName.isNotEmpty ? coAccusedName : ' ',
              style: coAccusedName.isNotEmpty ? _valStyle(9) : _mReg(9),
            ),
            const TextSpan(
              text: ' यांनी गुन्ह्यामध्ये आरोपी सहभागी असल्याचे कबुल केले आहे.',
            ),
          ],
        ),
      ),
    );
  }

  return Container(
    width: _kW,
    height: _kH,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _prosecutorBox('Page 10 of 13'),
        const SizedBox(height: 8),

        // Title
        Center(
          child: Text(
            'नातेवाईक/ मित्रांसाठी अटकेच्या माहितीची नोटीस ( कलम ४८ BNSS)',
            style: _mBld(13.5).copyWith(decoration: TextDecoration.underline),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle
        Center(
          child: Text(
            '(भारतीय नागरिक सुरक्षा संहिता, २०२३ च्या कलम ४८(१) अन्वये माननीय सर्वोच्च न्यायालयाच्या \'पंकज बन्सल\', \'प्रबीर पुरकायस्थ\', \'विद्वान कुमार\' आणि \'मिहीर शाह\' निवाड्यांमधील मार्गदर्शक तत्त्वांच्या अधीन)',
            style: _mReg(8.8, 1.3),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),

        // Recipient block
        Text('प्रति,', style: _mBld(10)),
        const SizedBox(height: 3),
        RichText(
          text: TextSpan(
            style: _mBld(9.8),
            children: [
              const TextSpan(text: 'नातेवाईक/मित्राचे नाव:- '),
              TextSpan(
                text: relativeName.isNotEmpty ? relativeName : ' ',
                style: relativeName.isNotEmpty ? _valStyle(9.8) : _mReg(9.8),
              ),
              const TextSpan(text: '   वय :- '),
              TextSpan(
                text: relativeAge.isNotEmpty ? relativeAge : ' ',
                style: relativeAge.isNotEmpty ? _valStyle(9.8) : _mReg(9.8),
              ),
              const TextSpan(text: '   पत्ता:- '),
              TextSpan(
                text: relativeAddress.isNotEmpty ? relativeAddress : ' ',
                style: relativeAddress.isNotEmpty ? _valStyle(9.8) : _mReg(9.8),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        RichText(
          text: TextSpan(
            style: _mBld(9.8),
            children: [
              const TextSpan(text: 'आरोपीशी असलेले नाते: '),
              TextSpan(
                text: relationship.isNotEmpty ? relationship : ' ',
                style: relationship.isNotEmpty ? _valStyle(9.8) : _mReg(9.8),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Notice text
        RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            style: _mReg(9.6, 1.45),
            children: [
              const TextSpan(
                text:
                    'या नोटीसद्वारे तुम्हाला, भारतीय नागरिक सुरक्षा संहिता, २०२३ (BNSS) च्या कलम ४८(१) मधील कायदेशीर तरतुदींनुसार अधिकृतपणे सूचित करण्यात येते की, तुमचे/तुमच्या आरोपीचे नाव: ',
              ),
              TextSpan(
                text: accusedName.isNotEmpty ? accusedName : ' ',
                style: accusedName.isNotEmpty ? _valStyle(9.6) : _mBld(9.6),
              ),
              const TextSpan(text: ' वय: '),
              TextSpan(
                text: accusedAge.isNotEmpty ? accusedAge : ' ',
                style: accusedAge.isNotEmpty ? _valStyle(9.6) : _mBld(9.6),
              ),
              const TextSpan(text: ' वर्ष, पत्ता:- '),
              TextSpan(
                text: accusedAddress.isNotEmpty ? accusedAddress : ' ',
                style: accusedAddress.isNotEmpty ? _valStyle(9.6) : _mBld(9.6),
              ),
              const TextSpan(text: ' यांना पोलीस ठाणे '),
              TextSpan(
                text: psName.isNotEmpty ? psName : ' ',
                style: psName.isNotEmpty ? _valStyle(9.6) : _mBld(9.6),
              ),
              const TextSpan(
                text: ' येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक (Cr.No.) ',
              ),
              TextSpan(
                text: crNo.isNotEmpty ? crNo : ' ',
                style: crNo.isNotEmpty ? _valStyle(9.6) : _mBld(9.6),
              ),
              const TextSpan(
                text: ', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम ',
              ),
              TextSpan(
                text: bnsSection.isNotEmpty ? bnsSection : ' ',
                style: bnsSection.isNotEmpty ? _valStyle(9.6) : _mBld(9.6),
              ),
              const TextSpan(
                text:
                    ' अन्वये नोंदवलेल्या गुन्ह्याच्या तपासाच्या अनुषंगाने आज दिनांक ',
              ),
              TextSpan(
                text: arrestDate.isNotEmpty ? arrestDate : ' ',
                style: arrestDate.isNotEmpty ? _valStyle(9.6) : _mBld(9.6),
              ),
              const TextSpan(text: ' रोजी वेळ '),
              TextSpan(
                text: arrestTime.isNotEmpty ? arrestTime : ' ',
                style: arrestTime.isNotEmpty ? _valStyle(9.6) : _mBld(9.6),
              ),
              const TextSpan(
                  text: ' वाजता कायदेशीररीत्या अटक करण्यात आली आहे.'),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Brief facts
        Text('गुन्ह्याची थोडक्यात हकीकत :-', style: _mBld(10)),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
          ),
          child: Text(
            briefFacts.isNotEmpty ? briefFacts : ' ',
            style: briefFacts.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
          ),
        ),
        const SizedBox(height: 6),

        // Table 1: Information
        Text(
          'आरोपीच्या अटकेबाबत तुम्हाला खालील बाबींची लेखी माहिती देण्यात येत आहे:-',
          style: _mBld(9.8),
        ),
        const SizedBox(height: 3),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(34),
            1: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Center(child: Text('अ.क्र.', style: _mBld(9.5))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                  child: Center(
                    child: Text('अटकेबाबत माहिती', style: _mBld(9.5)),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Center(child: Text('१.', style: _mBld(9))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2.5, horizontal: 6),
                  child: RichText(
                    text: TextSpan(
                      style: _mReg(9),
                      children: [
                        const TextSpan(text: 'आरोपी नाव '),
                        TextSpan(
                          text: accusedName.isNotEmpty ? accusedName : ' ',
                          style:
                              accusedName.isNotEmpty ? _valStyle(9) : _mBld(9),
                        ),
                        const TextSpan(text: ' यांना गुन्हा रजिस्टर क्रमांक '),
                        TextSpan(
                          text: crNo.isNotEmpty ? crNo : ' ',
                          style: crNo.isNotEmpty ? _valStyle(9) : _mBld(9),
                        ),
                        const TextSpan(
                          text:
                              ', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम ',
                        ),
                        TextSpan(
                          text: bnsSection.isNotEmpty ? bnsSection : ' ',
                          style:
                              bnsSection.isNotEmpty ? _valStyle(9) : _mBld(9),
                        ),
                        const TextSpan(
                          text:
                              ' अन्वये नोंदवलेल्या गुन्ह्याच्या तपासाच्या अनुषंगाने कायदेशीररीत्या अटक करण्यात आली असून सदर आरोपीला सध्या [पोलीस ठाण्याचे नाव: ',
                        ),
                        TextSpan(
                          text: custodyPs.isNotEmpty
                              ? custodyPs
                              : (psName.isNotEmpty ? psName : 'पोलीस ठाणे'),
                          style: _valStyle(9),
                        ),
                        const TextSpan(text: '] येथे ठेवण्यात आले आहे.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Center(child: Text('२.', style: _mBld(9))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2.5, horizontal: 6),
                  child: Text(
                    'आरोपीला माननीय न्यायालयासमोर हजर केल्यावर जामीन अर्ज सादर करण्याचा पूर्ण कायदेशीर अधिकार आहे.',
                    style: _mReg(9),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Center(child: Text('३.', style: _mBld(9))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2.5, horizontal: 6),
                  child: Text(
                    'तुमच्या पसंतीच्या कायदेशीर सल्लागाराचा (वकिलाचा) सल्ला घेण्याचा, त्यांना पोलीस कोठडीत भेटण्याचा आणि माननीय न्यायालयासमोर रिमांडला कायदेशीर विरोध करण्याचा पूर्ण अधिकार आहे.',
                    style: _mReg(9),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Table 2: Grounds
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(34),
            1: FlexColumnWidth(1),
          },
          children: groundRows,
        ),
        const Spacer(),

        // Page 10 Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('दिनांक :- ', style: _mBld(9.5)),
                    Text(
                      noticeDate.isNotEmpty ? noticeDate : ' ',
                      style:
                          noticeDate.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ठिकाण :- ', style: _mBld(9.5)),
                    Text(
                      noticePlace.isNotEmpty ? noticePlace : ' ',
                      style:
                          noticePlace.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  officerName.isNotEmpty ? officerName : ' ',
                  style: officerName.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
                ),
                const SizedBox(height: 2),
                Text('पोलीस अधिकारी नाव सही शिक्का', style: _mReg(9)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  relativeSig.isNotEmpty ? relativeSig : ' ',
                  style: relativeSig.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
                ),
                const SizedBox(height: 2),
                Text('नातेवाईक/ मित्र यांचे नाव , सही, अंगठा', style: _mReg(9)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 11: अटकेचे कारणे [कलम ३५(१)(ब) BNSS ] — Reasons of Arrest to Accused
// ─────────────────────────────────────────────────────────────────────────────

Widget _pg11(Map<String, dynamic> doc) {
  final accusedName = _v(doc, 'accusedName');
  final accusedAge = _v(doc, 'accusedAge');
  final accusedAddress = _v(doc, 'accusedAddress');
  final psName = _v(doc, 'psName');
  final crNo = _v(doc, 'crNo');
  final bnsSection = _v(doc, 'bnsSection');
  final arrestDate = _v(doc, 'arrestDate');
  final arrestTime = _v(doc, 'arrestTime');
  final briefFacts = _v(doc, 'briefFacts');

  final roaR1 = _b(doc, 'roaR1', true);
  final roaR2 = _b(doc, 'roaR2', true);
  final roaR3 = _b(doc, 'roaR3', true);
  final roaR4 = _b(doc, 'roaR4', true);
  final roaR5 = _b(doc, 'roaR5', true);

  final noticeDate = _v(doc, 'noticeDate', _v(doc, 'roaDate'));
  final noticePlace = _v(doc, 'noticePlace', _v(doc, 'roaPlace'));
  final officerName = _v(doc, 'officerName', _v(doc, 'roaOfficerSig'));

  final roaRows = <TableRow>[
    TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Center(child: Text('अ.क्र.', style: _mBld(9.5))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
          child: Center(
            child: Text('अटकेचे कारण (Reason for Arrest)', style: _mBld(9.5)),
          ),
        ),
      ],
    ),
  ];

  void addReason(String num, String text) {
    roaRows.add(
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Center(child: Text(num, style: _mBld(9))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
            child: Text(text, style: _mReg(9)),
          ),
        ],
      ),
    );
  }

  if (roaR1) {
    addReason(
      '१',
      'कलम ३५(१)(ब)(i) — आरोपीने आणखी कोणताही गुन्हा करू नये यासाठी त्याची अटक आवश्यक आहे.',
    );
  }
  if (roaR2) {
    addReason(
      '२',
      'कलम ३५(१)(ब)(ii) — गुन्ह्याच्या योग्य तपासासाठी आरोपीची अटक आवश्यक आहे.',
    );
  }
  if (roaR3) {
    addReason(
      '३',
      'कलम ३५(१)(ब)(iii) — आरोपीने गुन्ह्यातील पुरावे नष्ट करू नये किंवा अशा पुराव्यांमध्ये छेडछाड करू नये यासाठी अटक आवश्यक आहे.',
    );
  }
  if (roaR4) {
    addReason(
      '४',
      'कलम ३५(१)(ब)(iv) — गुन्ह्याशी संबंधित कोणत्याही साक्षीदाराला आरोपीने धमकी, प्रलोभन किंवा दबाव आणू नये यासाठी अटक आवश्यक आहे.',
    );
  }
  if (roaR5) {
    addReason(
      '५',
      'कलम ३५(१)(ब)(v) — आरोपीला न्यायालयात हजर करणे सुनिश्चित करण्यासाठी आणि तो फरारी होऊ नये यासाठी त्याची अटक आवश्यक आहे.',
    );
  }

  return Container(
    width: _kW,
    height: _kH,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _prosecutorBox('Page 11 of 13'),
        const SizedBox(height: 8),

        // Title
        Center(
          child: Text(
            'अटकेचे कारणे [कलम ३५(१)(ब) BNSS ]',
            style: _mBld(14).copyWith(decoration: TextDecoration.underline),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle
        Center(
          child: Text(
            '(भारतीय नागरिक सुरक्षा संहिता,२०२३ कलम ३५(१)(ब) अन्वये मा.सर्वोच्च न्यायालयाच्या मार्गदर्शक तत्त्वांच्या निकषांच्या अधीन)',
            style: _mReg(8.8, 1.3),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),

        // Recipient block
        Text('प्रति,', style: _mBld(10)),
        const SizedBox(height: 3),
        RichText(
          text: TextSpan(
            style: _mBld(10),
            children: [
              const TextSpan(text: 'अटक केलेल्या आरोपीचे नाव:- '),
              TextSpan(
                text: accusedName.isNotEmpty ? accusedName : ' ',
                style: accusedName.isNotEmpty ? _valStyle(10) : _mReg(10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        RichText(
          text: TextSpan(
            style: _mBld(10),
            children: [
              const TextSpan(text: 'वय:- '),
              TextSpan(
                text: accusedAge.isNotEmpty ? accusedAge : ' ',
                style: accusedAge.isNotEmpty ? _valStyle(10) : _mReg(10),
              ),
              const TextSpan(text: ' वर्ष, पत्ता:- '),
              TextSpan(
                text: accusedAddress.isNotEmpty ? accusedAddress : ' ',
                style: accusedAddress.isNotEmpty ? _valStyle(10) : _mReg(10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Notice text
        RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            style: _mReg(9.8, 1.5),
            children: [
              const TextSpan(
                text:
                    'या नोटीसद्वारे तुम्हाला सूचित करण्यात येते की, पोलीस ठाणे ',
              ),
              TextSpan(
                text: psName.isNotEmpty ? psName : ' ',
                style: psName.isNotEmpty ? _valStyle(9.8) : _mBld(9.8),
              ),
              const TextSpan(
                text: ' येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक ',
              ),
              TextSpan(
                text: crNo.isNotEmpty ? crNo : ' ',
                style: crNo.isNotEmpty ? _valStyle(9.8) : _mBld(9.8),
              ),
              const TextSpan(
                text: ', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम ',
              ),
              TextSpan(
                text: bnsSection.isNotEmpty ? bnsSection : ' ',
                style: bnsSection.isNotEmpty ? _valStyle(9.8) : _mBld(9.8),
              ),
              const TextSpan(
                text:
                    ' अन्वये नोंदवलेल्या गुन्ह्यात तपासाच्या अनुषंगाने आज दिनांक ',
              ),
              TextSpan(
                text: arrestDate.isNotEmpty ? arrestDate : ' ',
                style: arrestDate.isNotEmpty ? _valStyle(9.8) : _mBld(9.8),
              ),
              const TextSpan(text: ' रोजी वेळ '),
              TextSpan(
                text: arrestTime.isNotEmpty ? arrestTime : ' ',
                style: arrestTime.isNotEmpty ? _valStyle(9.8) : _mBld(9.8),
              ),
              const TextSpan(text: ' वाजता अटक करण्यात आली आहे.'),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Brief facts
        Text('गुन्ह्याची थोडक्यात हकीकत :-', style: _mBld(10)),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
          ),
          child: Text(
            briefFacts.isNotEmpty ? briefFacts : ' ',
            style: briefFacts.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
          ),
        ),
        const SizedBox(height: 8),

        // Table: Reasons
        Text('अटकेची कारणे [कलम ३५(१)(ब) BNSS]:-', style: _mBld(10)),
        const SizedBox(height: 3),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(34),
            1: FlexColumnWidth(1),
          },
          children: roaRows,
        ),
        const Spacer(),

        // Page 11 Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('दिनांक :- ', style: _mBld(9.5)),
                    Text(
                      noticeDate.isNotEmpty ? noticeDate : ' ',
                      style:
                          noticeDate.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ठिकाण :- ', style: _mBld(9.5)),
                    Text(
                      noticePlace.isNotEmpty ? noticePlace : ' ',
                      style:
                          noticePlace.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  officerName.isNotEmpty ? officerName : ' ',
                  style: officerName.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
                ),
                const SizedBox(height: 2),
                Text('पोलीस अधिकारी नाव सही शिक्का', style: _mReg(9)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  accusedName.isNotEmpty ? accusedName : ' ',
                  style: accusedName.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
                ),
                const SizedBox(height: 2),
                Text('आरोपीचे नाव , सही, अंगठा', style: _mReg(9)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Backward Compatibility Fallback
// ─────────────────────────────────────────────────────────────────────────────

Future<Uint8List> generateDraftGroundOfArrestPdf(
  Map<String, dynamic> doc,
) async {
  final pdf = pw.Document();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final bold = pw.TextStyle(
      font: devanagariBold, fontSize: 9, fontWeight: pw.FontWeight.bold);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Center(
        child: pw.Text('Draft Ground of Arrest', style: bold),
      ),
    ),
  );

  return pdf.save();
}
