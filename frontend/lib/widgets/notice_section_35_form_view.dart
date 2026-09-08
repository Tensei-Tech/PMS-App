import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_section_utils.dart';
import 'form_table_helpers.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// Notice u/s 35(3) BNSS — 2 distinct forms:
/// 1) Main: तपास व उपस्थिती नोटीस (९ अटी व वैधानिक चेतावणी)
/// 2) Rights & Signatures: दोषारोपपत्र न्यायप्रविष्ठ / ७ वर्षांपेक्षा कमी शिक्षा नोटीस
class NoticeSection35FormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const NoticeSection35FormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<NoticeSection35FormView> createState() =>
      NoticeSection35FormViewState();
}

class NoticeSection35FormViewState extends State<NoticeSection35FormView> {
  static const kMain = 'Notice Section 35 Main';
  static const kContinuation = 'Notice Section 35 Continuation';
  static const _knownSectionIds = {kMain, kContinuation};

  bool _shows(String id) => showsFormSection(
        activeSection: widget.formSection,
        sectionId: id,
        knownSectionIds: _knownSectionIds,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 1 (Main: तपास व ९ अटी सूचनापत्र)
  // ═══════════════════════════════════════════════════════════════════════════
  final _p1PsCtrl = TextEditingController();
  final _p1DateCtrl = TextEditingController();
  final _p1RecipientLine1Ctrl = TextEditingController();
  final _p1RecipientLine2Ctrl = TextEditingController();
  final _p1RecipientLine3Ctrl = TextEditingController();
  final _p1AadhaarCtrl = TextEditingController();
  final _p1EmailCtrl = TextEditingController();

  final _p1IncidentDateCtrl = TextEditingController();
  final _p1IncidentPsCtrl = TextEditingController();
  final _p1CrimeNoCtrl = TextEditingController();
  final _p1ActSecCtrl = TextEditingController();
  final _p1AppearanceDateCtrl = TextEditingController();
  final _p1AppearanceTimeCtrl = TextEditingController();

  final _p1AccusedSigCtrl = TextEditingController();
  final _p1IoSigCtrl = TextEditingController();

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 2 (Rights & Signatures: दोषारोपपत्र न्यायप्रविष्ठ नोटीस)
  // ═══════════════════════════════════════════════════════════════════════════
  final _p2PsCtrl = TextEditingController();
  final _p2DateCtrl = TextEditingController();
  final _p2RecipientLine1Ctrl = TextEditingController();
  final _p2RecipientLine2Ctrl = TextEditingController();
  final _p2RecipientLine3Ctrl = TextEditingController();

  final _p2IncidentPsCtrl = TextEditingController();
  final _p2DistCtrl = TextEditingController(text: 'यवतमाळ');
  final _p2CrimeNoCtrl = TextEditingController();
  final _p2ActSecCtrl = TextEditingController();

  final _p2CourtDateCtrl = TextEditingController();
  final _p2CourtTimeCtrl = TextEditingController(text: '१०:३०');
  final _p2CourtPsCtrl = TextEditingController();
  final _p2CourtNameCtrl = TextEditingController();

  final _p2IoSigCtrl = TextEditingController();
  final _p2AccusedAckSigCtrl = TextEditingController();

  @override
  void dispose() {
    _p1PsCtrl.dispose();
    _p1DateCtrl.dispose();
    _p1RecipientLine1Ctrl.dispose();
    _p1RecipientLine2Ctrl.dispose();
    _p1RecipientLine3Ctrl.dispose();
    _p1AadhaarCtrl.dispose();
    _p1EmailCtrl.dispose();
    _p1IncidentDateCtrl.dispose();
    _p1IncidentPsCtrl.dispose();
    _p1CrimeNoCtrl.dispose();
    _p1ActSecCtrl.dispose();
    _p1AppearanceDateCtrl.dispose();
    _p1AppearanceTimeCtrl.dispose();
    _p1AccusedSigCtrl.dispose();
    _p1IoSigCtrl.dispose();

    _p2PsCtrl.dispose();
    _p2DateCtrl.dispose();
    _p2RecipientLine1Ctrl.dispose();
    _p2RecipientLine2Ctrl.dispose();
    _p2RecipientLine3Ctrl.dispose();
    _p2IncidentPsCtrl.dispose();
    _p2DistCtrl.dispose();
    _p2CrimeNoCtrl.dispose();
    _p2ActSecCtrl.dispose();
    _p2CourtDateCtrl.dispose();
    _p2CourtTimeCtrl.dispose();
    _p2CourtPsCtrl.dispose();
    _p2CourtNameCtrl.dispose();
    _p2IoSigCtrl.dispose();
    _p2AccusedAckSigCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      // Page 1
      'p1PoliceStation': _p1PsCtrl.text,
      'p1NoticeDate': _p1DateCtrl.text,
      'p1RecipientLine1': _p1RecipientLine1Ctrl.text,
      'p1RecipientLine2': _p1RecipientLine2Ctrl.text,
      'p1RecipientLine3': _p1RecipientLine3Ctrl.text,
      'p1AadhaarNo': _p1AadhaarCtrl.text,
      'p1Email': _p1EmailCtrl.text,
      'p1IncidentDate': _p1IncidentDateCtrl.text,
      'p1IncidentPs': _p1IncidentPsCtrl.text,
      'p1CrimeNo': _p1CrimeNoCtrl.text,
      'p1ActSec': _p1ActSecCtrl.text,
      'p1AppearanceDate': _p1AppearanceDateCtrl.text,
      'p1AppearanceTime': _p1AppearanceTimeCtrl.text,
      'p1AccusedSig': _p1AccusedSigCtrl.text,
      'p1IoSig': _p1IoSigCtrl.text,
      // Page 2
      'p2PoliceStation': _p2PsCtrl.text,
      'p2NoticeDate': _p2DateCtrl.text,
      'p2RecipientLine1': _p2RecipientLine1Ctrl.text,
      'p2RecipientLine2': _p2RecipientLine2Ctrl.text,
      'p2RecipientLine3': _p2RecipientLine3Ctrl.text,
      'p2IncidentPs': _p2IncidentPsCtrl.text,
      'p2District': _p2DistCtrl.text,
      'p2CrimeNo': _p2CrimeNoCtrl.text,
      'p2ActSec': _p2ActSecCtrl.text,
      'p2CourtDate': _p2CourtDateCtrl.text,
      'p2CourtTime': _p2CourtTimeCtrl.text,
      'p2CourtPs': _p2CourtPsCtrl.text,
      'p2CourtName': _p2CourtNameCtrl.text,
      'p2IoSig': _p2IoSigCtrl.text,
      'p2AccusedAckSig': _p2AccusedAckSigCtrl.text,
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    // Page 1
    _p1PsCtrl.text = data['p1PoliceStation']?.toString() ??
        data['policeStation']?.toString() ??
        '';
    _p1DateCtrl.text = data['p1NoticeDate']?.toString() ??
        data['noticeDate']?.toString() ??
        '';
    _p1RecipientLine1Ctrl.text = data['p1RecipientLine1']?.toString() ??
        data['recipientLine1']?.toString() ??
        '';
    _p1RecipientLine2Ctrl.text = data['p1RecipientLine2']?.toString() ??
        data['recipientLine2']?.toString() ??
        '';
    _p1RecipientLine3Ctrl.text = data['p1RecipientLine3']?.toString() ??
        data['recipientLine3']?.toString() ??
        '';
    _p1AadhaarCtrl.text =
        data['p1AadhaarNo']?.toString() ?? data['aadhaarNo']?.toString() ?? '';
    _p1EmailCtrl.text =
        data['p1Email']?.toString() ?? data['email']?.toString() ?? '';
    _p1IncidentDateCtrl.text = data['p1IncidentDate']?.toString() ??
        data['incidentDate']?.toString() ??
        '';
    _p1IncidentPsCtrl.text = data['p1IncidentPs']?.toString() ??
        data['incidentPs']?.toString() ??
        '';
    _p1CrimeNoCtrl.text =
        data['p1CrimeNo']?.toString() ?? data['crimeNo']?.toString() ?? '';
    _p1ActSecCtrl.text =
        data['p1ActSec']?.toString() ?? data['actSec']?.toString() ?? '';
    _p1AppearanceDateCtrl.text = data['p1AppearanceDate']?.toString() ??
        data['appearanceDate']?.toString() ??
        '';
    _p1AppearanceTimeCtrl.text = data['p1AppearanceTime']?.toString() ??
        data['appearanceTime']?.toString() ??
        '';
    _p1AccusedSigCtrl.text = data['p1AccusedSig']?.toString() ??
        data['accusedSig']?.toString() ??
        '';
    _p1IoSigCtrl.text = data['p1IoSig']?.toString() ??
        data['investigatingOfficerSig']?.toString() ??
        '';

    // Page 2
    _p2PsCtrl.text = data['p2PoliceStation']?.toString() ??
        data['policeStation']?.toString() ??
        '';
    _p2DateCtrl.text = data['p2NoticeDate']?.toString() ??
        data['noticeDate']?.toString() ??
        '';
    _p2RecipientLine1Ctrl.text = data['p2RecipientLine1']?.toString() ??
        data['recipientLine1']?.toString() ??
        '';
    _p2RecipientLine2Ctrl.text = data['p2RecipientLine2']?.toString() ??
        data['recipientLine2']?.toString() ??
        '';
    _p2RecipientLine3Ctrl.text = data['p2RecipientLine3']?.toString() ??
        data['recipientLine3']?.toString() ??
        '';
    _p2IncidentPsCtrl.text = data['p2IncidentPs']?.toString() ??
        data['incidentPs']?.toString() ??
        '';
    _p2DistCtrl.text = data['p2District']?.toString() ?? 'यवतमाळ';
    _p2CrimeNoCtrl.text =
        data['p2CrimeNo']?.toString() ?? data['crimeNo']?.toString() ?? '';
    _p2ActSecCtrl.text =
        data['p2ActSec']?.toString() ?? data['actSec']?.toString() ?? '';
    _p2CourtDateCtrl.text = data['p2CourtDate']?.toString() ?? '';
    _p2CourtTimeCtrl.text = data['p2CourtTime']?.toString() ?? '१०:३०';
    _p2CourtPsCtrl.text = data['p2CourtPs']?.toString() ?? '';
    _p2CourtNameCtrl.text = data['p2CourtName']?.toString() ?? '';
    _p2IoSigCtrl.text = data['p2IoSig']?.toString() ??
        data['investigatingOfficerSig']?.toString() ??
        '';
    _p2AccusedAckSigCtrl.text = data['p2AccusedAckSig']?.toString() ?? '';

    if (mounted) setState(() {});
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 1 BUILDER (तपास व ९ अटी सूचनापत्र)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPage1(TextStyle serif, TextStyle marathi) {
    return FormPaperPage(
      formLabel: widget.pageRange,
      children: [
        // Top Right
        Align(
          alignment: Alignment.topRight,
          child: SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'पोलीस स्टेशन ',
                      style: marathi.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: BilingualSimpleUnderlineInput(
                        controller: _p1PsCtrl,
                        serifStyle: serif,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'दिनांक : ',
                      style: marathi.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: BilingualSimpleUnderlineInput(
                        controller: _p1DateCtrl,
                        serifStyle: serif,
                        hintText: '......./ ......./२०...',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Center(
          child: Column(
            children: [
              Text(
                '-:: नोटीस ::-',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '( कलम ३५ (३) भारतीय नागरी संरक्षण संहिता सन २०२३ अन्वये)',
                style: marathi.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Recipient
        Text(
          'प्रति,',
          style: marathi.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        BilingualSimpleUnderlineInput(
          controller: _p1RecipientLine1Ctrl,
          serifStyle: serif,
          hintText: 'नाव / पत्ता...',
        ),
        const SizedBox(height: 6),
        BilingualSimpleUnderlineInput(
          controller: _p1RecipientLine2Ctrl,
          serifStyle: serif,
        ),
        const SizedBox(height: 6),
        BilingualSimpleUnderlineInput(
          controller: _p1RecipientLine3Ctrl,
          serifStyle: serif,
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Text(
              'आधार क :- ',
              style: marathi.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Expanded(
              child: BilingualSimpleUnderlineInput(
                controller: _p1AadhaarCtrl,
                serifStyle: serif,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Text(
              'ईमेल:- ',
              style: marathi.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Expanded(
              child: BilingualSimpleUnderlineInput(
                controller: _p1EmailCtrl,
                serifStyle: serif,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Paragraph 1
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '        भारतीय नागरी संरक्षण संहिता सन २०२३ मधील कलम ३५ (३) अन्वये प्रदान केलेल्या अधिकाराचा वापर करून मी खाली स्वाक्षरी करणार निर्देशित करतो की, दिनांक',
              style: marathi.copyWith(fontSize: 13, height: 1.8),
            ),
            SizedBox(
              width: 140,
              child: BilingualSimpleUnderlineInput(
                controller: _p1IncidentDateCtrl,
                serifStyle: serif,
                hintText: '....../ ....../२०.....',
              ),
            ),
            Text(
              ' रोजी पोलीस स्टेशन ',
              style: marathi.copyWith(fontSize: 13, height: 1.8),
            ),
            SizedBox(
              width: 140,
              child: BilingualSimpleUnderlineInput(
                controller: _p1IncidentPsCtrl,
                serifStyle: serif,
              ),
            ),
            Text(
              ' येथे दाखल असलेला अपराध क्रमांक ',
              style: marathi.copyWith(fontSize: 13, height: 1.8),
            ),
            SizedBox(
              width: 130,
              child: BilingualSimpleUnderlineInput(
                controller: _p1CrimeNoCtrl,
                serifStyle: serif,
                hintText: '........./२०....',
              ),
            ),
            Text(
              ' कलम ',
              style: marathi.copyWith(fontSize: 13, height: 1.8),
            ),
            SizedBox(
              width: 180,
              child: BilingualSimpleUnderlineInput(
                controller: _p1ActSecCtrl,
                serifStyle: serif,
              ),
            ),
            Text(
              ' तपासा दरम्यान हे निष्पन्न झाले की, या गुन्हयाच्या तपासाच्या अनुषंगाने तथ्य आणि वस्तुस्थिती जाणून घेण्यासाठी तुमच्याकडे विचारपुस करण्यासाठी सबळ व वाजवी कारणे आहेत. त्यामुळे तुम्हास दिनांक ',
              style: marathi.copyWith(fontSize: 13, height: 1.8),
            ),
            SizedBox(
              width: 140,
              child: BilingualSimpleUnderlineInput(
                controller: _p1AppearanceDateCtrl,
                serifStyle: serif,
                hintText: '....../ ....../२०.....',
              ),
            ),
            Text(
              ' रोजी ',
              style: marathi.copyWith(fontSize: 13, height: 1.8),
            ),
            SizedBox(
              width: 110,
              child: BilingualSimpleUnderlineInput(
                controller: _p1AppearanceTimeCtrl,
                serifStyle: serif,
                hintText: '......../ .......',
              ),
            ),
            Text(
              ' वाजता ठाण्यात माझे समक्ष न चुकता उपस्थित राहण्याचे निर्देश देण्यात येत आहे.',
              style: marathi.copyWith(fontSize: 13, height: 1.8),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Text(
          '        त्याच प्रमाणे तुम्हास खालील निर्देश काटेकोर पालन करण्याच्या सुचना देण्यात येत आहेत.',
          style: marathi.copyWith(fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 10),

        _buildClause(
          '१) भवीष्यात तुम्ही कोणताही गुन्हा करणार नाही.',
          marathi,
        ),
        _buildClause(
          '२) तुम्ही या गुन्हया संदर्भातील कोणत्याही पुराव्या मध्ये बदल/ छेड-छाड करणार नाहीत.',
          marathi,
        ),
        _buildClause(
          '३) या गुन्हयाच्या तथ्यांशी परिचित असलेल्या कोणत्याही व्यक्तीला तो अशी तथ्ये पोलीस अथवा न्यायालया समोर उघड करण्यापासुन परावृत्त होण्याची शक्यता आहे. अशा प्रकारे तुम्ही कोणतीही धमकी, प्रलोभन, किंवा आश्वासन देणार नाहीत.',
          marathi,
        ),
        _buildClause(
          '४) जेव्हा आवश्यक असेल/ आदेशीत करण्यात येईल तेव्हा तुम्ही न चुकता न्यायालया समोर हजर व्हाल.',
          marathi,
        ),
        _buildClause(
          '५) सदर गुन्हयाच्या तपासा दरम्यान आपण निर्देशित केल्यानंतर न चुकता दिलेल्या ठिकाणी वेळेत हजर राहाल व तपासा दरम्यान पूर्ण सहकार्य कराल.',
          marathi,
        ),
        _buildClause(
          '६) गुन्हयाच्या तपासा दरम्यान योग्य निष्कर्शा पर्यंत पोहोचण्यासाठी आपण कोणतेही बाब न लपविता सर्व तथ्ये सत्यतेने उघड कराल.',
          marathi,
        ),
        _buildClause(
          '७) तुम्ही तपासासाठी आवश्यक सर्व दस्तऐवज/ इतर साहित्य तपासी अधिकारी यांना उपलब्ध करून द्याल.',
          marathi,
        ),
        _buildClause(
          '८) गुन्हयातील सहभागी इतर कोणत्याही आरोपींना अटक करणे आवश्यक असल्यास आपण सर्वतोपरी सहकार्य कराल.',
          marathi,
        ),
        _buildClause(
          '९) याव्यतिरीक्त तपासी अधिकाऱ्यांनी दिलेल्या सर्व कायदेशीर निर्देश आपण काटेकोरपणे पाल कराल.',
          marathi,
        ),
        const SizedBox(height: 12),

        // Warning Paragraph
        Text(
          '        इतर कोणत्याही अटी, ज्या तपास अधिकाऱ्याने लादल्या जाउ शकतात/ प्रकरणातील वस्तुस्थितीनुसार भा.ना.सु.सं.कलम ३५ (४) च्या सुचनेच्या अटींचे पालन करण्यात/ हजर राहण्यात अयशस्वी झाल्यास भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ३५ (६) अंतर्गत अटक करण्यासाठी तुम्हाला जबाबदार धरले जाउ शकते.',
          style: marathi.copyWith(fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 28),

        // Signatures
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'आरोपीची स्वाक्षरी',
                    style: marathi.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BilingualSimpleUnderlineInput(
                    controller: _p1AccusedSigCtrl,
                    serifStyle: serif,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'तपासी अधिकारी नांव स्वाक्षरी',
                    style: marathi.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BilingualSimpleUnderlineInput(
                    controller: _p1IoSigCtrl,
                    serifStyle: serif,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        FormMrwFooter(serifStyle: serif),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 2 BUILDER (दोषारोपपत्र न्यायप्रविष्ठ नोटीस / Rights & Signatures)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPage2(TextStyle serif, TextStyle marathi) {
    return FormPaperPage(
      formLabel: widget.pageRange,
      children: [
        // Top Right
        Align(
          alignment: Alignment.topRight,
          child: SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'पोलीस स्टेशन ',
                      style: marathi.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: BilingualSimpleUnderlineInput(
                        controller: _p2PsCtrl,
                        serifStyle: serif,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'दिनांक : ',
                      style: marathi.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: BilingualSimpleUnderlineInput(
                        controller: _p2DateCtrl,
                        serifStyle: serif,
                        hintText: '......./ ......./२०...',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Title
        Center(
          child: Column(
            children: [
              Text(
                '-:: नोटीस ::-',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '( कलम ३५ (३) भारतीय नागरी संरक्षण संहिता सन २०२३ अन्वये)',
                style: marathi.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Recipient
        Text(
          'प्रति,',
          style: marathi.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        BilingualSimpleUnderlineInput(
          controller: _p2RecipientLine1Ctrl,
          serifStyle: serif,
          hintText: 'नाव / पत्ता...',
        ),
        const SizedBox(height: 8),
        BilingualSimpleUnderlineInput(
          controller: _p2RecipientLine2Ctrl,
          serifStyle: serif,
        ),
        const SizedBox(height: 8),
        BilingualSimpleUnderlineInput(
          controller: _p2RecipientLine3Ctrl,
          serifStyle: serif,
        ),
        const SizedBox(height: 24),

        // Paragraph 1
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '        आपणास या नोटीस व्दारे कळविण्यात येते की, आपना विरूध्द पोलीस स्टेशन ',
              style: marathi.copyWith(fontSize: 13.5, height: 1.9),
            ),
            SizedBox(
              width: 140,
              child: BilingualSimpleUnderlineInput(
                controller: _p2IncidentPsCtrl,
                serifStyle: serif,
              ),
            ),
            Text(
              ' जिल्हा ',
              style: marathi.copyWith(fontSize: 13.5, height: 1.9),
            ),
            SizedBox(
              width: 100,
              child: BilingualSimpleUnderlineInput(
                controller: _p2DistCtrl,
                serifStyle: serif,
              ),
            ),
            Text(
              ' येथे अपराध क्रमांक ',
              style: marathi.copyWith(fontSize: 13.5, height: 1.9),
            ),
            SizedBox(
              width: 130,
              child: BilingualSimpleUnderlineInput(
                controller: _p2CrimeNoCtrl,
                serifStyle: serif,
                hintText: '........./२०........',
              ),
            ),
            Text(
              ' कलम ',
              style: marathi.copyWith(fontSize: 13.5, height: 1.9),
            ),
            SizedBox(
              width: 220,
              child: BilingualSimpleUnderlineInput(
                controller: _p2ActSecCtrl,
                serifStyle: serif,
              ),
            ),
            Text(
              ' अन्वये गुन्हा नोंद करण्यात आलेला आहे. सदर अपराधा मध्ये शिक्षा ७ वर्षा पेक्षा कमी आहे किंवा ७ वर्षा पर्यंत द्रव्यदंडा सह किंवा त्या व्यतिरीक्त होवू शकते त्यामुळे सध्या आपनास अटक करणे गरजेचे वाटत नाही.',
              style: marathi.copyWith(fontSize: 13.5, height: 1.9),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Paragraph 2
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '        तरी वरील अपराधा मध्ये दोषारोपपत्र न्यायप्रविष्ठ करावयाचा असल्याने आपण दिनांक :. ',
              style: marathi.copyWith(fontSize: 13.5, height: 1.9),
            ),
            SizedBox(
              width: 140,
              child: BilingualSimpleUnderlineInput(
                controller: _p2CourtDateCtrl,
                serifStyle: serif,
                hintText: '......./ ......./२०.....',
              ),
            ),
            Text(
              ' रोजी ',
              style: marathi.copyWith(fontSize: 13.5, height: 1.9),
            ),
            SizedBox(
              width: 80,
              child: BilingualSimpleUnderlineInput(
                controller: _p2CourtTimeCtrl,
                serifStyle: serif,
              ),
            ),
            Text(
              ' वाजता पोलीस स्टेशन ',
              style: marathi.copyWith(fontSize: 13.5, height: 1.9),
            ),
            SizedBox(
              width: 140,
              child: BilingualSimpleUnderlineInput(
                controller: _p2CourtPsCtrl,
                serifStyle: serif,
              ),
            ),
            Text(
              ' येथे हजर यावे त्यानंतर मा.वि.न्यायदंडाधिकारी साहेब प्रथम श्रेणी कोर्ट ',
              style: marathi.copyWith(fontSize: 13.5, height: 1.9),
            ),
            SizedBox(
              width: 140,
              child: BilingualSimpleUnderlineInput(
                controller: _p2CourtNameCtrl,
                serifStyle: serif,
              ),
            ),
            Text(
              ' येथील न्यायालयात जामीनदारासह न चुकता हजर राहावे.',
              style: marathi.copyWith(fontSize: 13.5, height: 1.9),
            ),
          ],
        ),
        const SizedBox(height: 36),

        // IO Signature (Right)
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'तपासी अधिकारी नांव व सही',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                BilingualSimpleUnderlineInput(
                  controller: _p2IoSigCtrl,
                  serifStyle: serif,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),

        // Accused Acknowledgment (Bottom Left)
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'सुचनापत्र मिळाले आहे.',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                BilingualSimpleUnderlineInput(
                  controller: _p2AccusedAckSigCtrl,
                  serifStyle: serif,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 36),

        FormMrwFooter(serifStyle: serif),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final serif = FormTypography.serifStyle();
    final marathi = FormTypography.marathiLabelStyle();
    final pages = <Widget>[];

    if (_shows(kMain)) pages.add(_buildPage1(serif, marathi));
    if (_shows(kMain) && _shows(kContinuation)) {
      pages.add(const SizedBox(height: 24));
    }
    if (_shows(kContinuation)) pages.add(_buildPage2(serif, marathi));

    return FormViewScaffold(readOnly: widget.readOnly, children: pages);
  }

  Widget _buildClause(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: style.copyWith(fontSize: 13, height: 1.5),
      ),
    );
  }
}
