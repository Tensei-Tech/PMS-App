import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_table_helpers.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// -:: पंच सुचनापत्र ::- (कलम १७९ भारतीय नागरीक सुरक्षा संहिता २०२३ अन्वये)
/// पान १: घटनास्थळ / जप्ती पंचनामा सुचनापत्र
/// पान २: दारू प्रोहिबीशन रेड पंच सुचनापत्र
class BnssPanchNoticeFormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;
  final String? initialNoticeType;

  const BnssPanchNoticeFormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
    this.initialNoticeType,
  });

  @override
  State<BnssPanchNoticeFormView> createState() =>
      BnssPanchNoticeFormViewState();
}

class BnssPanchNoticeFormViewState extends State<BnssPanchNoticeFormView> {
  // ── PAGE 1 CONTROLLERS (घटनास्थळ / जप्ती पंचनामा) ──
  final _p1PsCtrl = TextEditingController();
  final _p1DateCtrl = TextEditingController();
  final _p1Panch1Ctrl = TextEditingController();
  final _p1Panch2Ctrl = TextEditingController();
  final _p1FirPsCtrl = TextEditingController();
  final _p1CrimeNoCtrl = TextEditingController();
  final _p1ActSecCtrl = TextEditingController();
  final _p1ComplainantNameCtrl = TextEditingController();
  final _p1ComplainantResidenceCtrl = TextEditingController();
  final _p1ComplainantTahCtrl = TextEditingController();
  final _p1ComplainantDistCtrl = TextEditingController(text: 'यवतमाळ');
  final _p1IoNameSigCtrl = TextEditingController();
  final _p1Panch1ReceiptCtrl = TextEditingController();
  final _p1Panch2ReceiptCtrl = TextEditingController();

  // ── PAGE 2 CONTROLLERS (दारू प्रोहिबीशन रेड) ──
  final _p2PsCtrl = TextEditingController();
  final _p2DateCtrl = TextEditingController();
  final _p2Panch1Ctrl = TextEditingController();
  final _p2Panch2Ctrl = TextEditingController();
  final _p2RaidDateCtrl = TextEditingController();
  final _p2VillageCtrl = TextEditingController();
  final _p2SuspectNameCtrl = TextEditingController();
  final _p2SuspectAgeCtrl = TextEditingController();
  final _p2SuspectResidenceCtrl = TextEditingController();
  final _p2SuspectTahCtrl = TextEditingController();
  final _p2SuspectDistCtrl = TextEditingController(text: 'यवतमाळ');
  final _p2IoNameSigCtrl = TextEditingController();
  final _p2Panch1ReceiptCtrl = TextEditingController();
  final _p2Panch2ReceiptCtrl = TextEditingController();

  @override
  void dispose() {
    _p1PsCtrl.dispose();
    _p1DateCtrl.dispose();
    _p1Panch1Ctrl.dispose();
    _p1Panch2Ctrl.dispose();
    _p1FirPsCtrl.dispose();
    _p1CrimeNoCtrl.dispose();
    _p1ActSecCtrl.dispose();
    _p1ComplainantNameCtrl.dispose();
    _p1ComplainantResidenceCtrl.dispose();
    _p1ComplainantTahCtrl.dispose();
    _p1ComplainantDistCtrl.dispose();
    _p1IoNameSigCtrl.dispose();
    _p1Panch1ReceiptCtrl.dispose();
    _p1Panch2ReceiptCtrl.dispose();

    _p2PsCtrl.dispose();
    _p2DateCtrl.dispose();
    _p2Panch1Ctrl.dispose();
    _p2Panch2Ctrl.dispose();
    _p2RaidDateCtrl.dispose();
    _p2VillageCtrl.dispose();
    _p2SuspectNameCtrl.dispose();
    _p2SuspectAgeCtrl.dispose();
    _p2SuspectResidenceCtrl.dispose();
    _p2SuspectTahCtrl.dispose();
    _p2SuspectDistCtrl.dispose();
    _p2IoNameSigCtrl.dispose();
    _p2Panch1ReceiptCtrl.dispose();
    _p2Panch2ReceiptCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      // Page 1
      'p1_policeStation': _p1PsCtrl.text,
      'p1_date': _p1DateCtrl.text,
      'p1_panch1': _p1Panch1Ctrl.text,
      'p1_panch2': _p1Panch2Ctrl.text,
      'p1_firPs': _p1FirPsCtrl.text,
      'p1_crimeNo': _p1CrimeNoCtrl.text,
      'p1_actSec': _p1ActSecCtrl.text,
      'p1_complainantName': _p1ComplainantNameCtrl.text,
      'p1_complainantResidence': _p1ComplainantResidenceCtrl.text,
      'p1_complainantTah': _p1ComplainantTahCtrl.text,
      'p1_complainantDist': _p1ComplainantDistCtrl.text,
      'p1_ioNameSig': _p1IoNameSigCtrl.text,
      'p1_panch1Receipt': _p1Panch1ReceiptCtrl.text,
      'p1_panch2Receipt': _p1Panch2ReceiptCtrl.text,
      // Page 2
      'p2_policeStation': _p2PsCtrl.text,
      'p2_date': _p2DateCtrl.text,
      'p2_panch1': _p2Panch1Ctrl.text,
      'p2_panch2': _p2Panch2Ctrl.text,
      'p2_raidDate': _p2RaidDateCtrl.text,
      'p2_village': _p2VillageCtrl.text,
      'p2_suspectName': _p2SuspectNameCtrl.text,
      'p2_suspectAge': _p2SuspectAgeCtrl.text,
      'p2_suspectResidence': _p2SuspectResidenceCtrl.text,
      'p2_suspectTah': _p2SuspectTahCtrl.text,
      'p2_suspectDist': _p2SuspectDistCtrl.text,
      'p2_ioNameSig': _p2IoNameSigCtrl.text,
      'p2_panch1Receipt': _p2Panch1ReceiptCtrl.text,
      'p2_panch2Receipt': _p2Panch2ReceiptCtrl.text,
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    // Page 1
    _p1PsCtrl.text = data['p1_policeStation']?.toString() ??
        data['policeStation']?.toString() ??
        '';
    _p1DateCtrl.text =
        data['p1_date']?.toString() ?? data['date']?.toString() ?? '';
    _p1Panch1Ctrl.text =
        data['p1_panch1']?.toString() ?? data['panch1']?.toString() ?? '';
    _p1Panch2Ctrl.text =
        data['p1_panch2']?.toString() ?? data['panch2']?.toString() ?? '';
    _p1FirPsCtrl.text =
        data['p1_firPs']?.toString() ?? data['firPs']?.toString() ?? '';
    _p1CrimeNoCtrl.text =
        data['p1_crimeNo']?.toString() ?? data['crimeNo']?.toString() ?? '';
    _p1ActSecCtrl.text =
        data['p1_actSec']?.toString() ?? data['actSec']?.toString() ?? '';
    _p1ComplainantNameCtrl.text = data['p1_complainantName']?.toString() ??
        data['complainantName']?.toString() ??
        '';
    _p1ComplainantResidenceCtrl.text =
        data['p1_complainantResidence']?.toString() ??
            data['complainantResidence']?.toString() ??
            '';
    _p1ComplainantTahCtrl.text = data['p1_complainantTah']?.toString() ??
        data['complainantTah']?.toString() ??
        '';
    _p1ComplainantDistCtrl.text = data['p1_complainantDist']?.toString() ??
        data['complainantDist']?.toString() ??
        'यवतमाळ';
    _p1IoNameSigCtrl.text =
        data['p1_ioNameSig']?.toString() ?? data['ioNameSig']?.toString() ?? '';
    _p1Panch1ReceiptCtrl.text = data['p1_panch1Receipt']?.toString() ??
        data['panch1Receipt']?.toString() ??
        '';
    _p1Panch2ReceiptCtrl.text = data['p1_panch2Receipt']?.toString() ??
        data['panch2Receipt']?.toString() ??
        '';

    // Page 2
    _p2PsCtrl.text = data['p2_policeStation']?.toString() ??
        data['policeStation']?.toString() ??
        '';
    _p2DateCtrl.text =
        data['p2_date']?.toString() ?? data['date']?.toString() ?? '';
    _p2Panch1Ctrl.text =
        data['p2_panch1']?.toString() ?? data['panch1']?.toString() ?? '';
    _p2Panch2Ctrl.text =
        data['p2_panch2']?.toString() ?? data['panch2']?.toString() ?? '';
    _p2RaidDateCtrl.text =
        data['p2_raidDate']?.toString() ?? data['raidDate']?.toString() ?? '';
    _p2VillageCtrl.text =
        data['p2_village']?.toString() ?? data['village']?.toString() ?? '';
    _p2SuspectNameCtrl.text = data['p2_suspectName']?.toString() ??
        data['suspectName']?.toString() ??
        '';
    _p2SuspectAgeCtrl.text = data['p2_suspectAge']?.toString() ??
        data['suspectAge']?.toString() ??
        '';
    _p2SuspectResidenceCtrl.text = data['p2_suspectResidence']?.toString() ??
        data['suspectResidence']?.toString() ??
        '';
    _p2SuspectTahCtrl.text = data['p2_suspectTah']?.toString() ??
        data['suspectTah']?.toString() ??
        '';
    _p2SuspectDistCtrl.text = data['p2_suspectDist']?.toString() ??
        data['suspectDist']?.toString() ??
        'यवतमाळ';
    _p2IoNameSigCtrl.text =
        data['p2_ioNameSig']?.toString() ?? data['ioNameSig']?.toString() ?? '';
    _p2Panch1ReceiptCtrl.text = data['p2_panch1Receipt']?.toString() ??
        data['panch1Receipt']?.toString() ??
        '';
    _p2Panch2ReceiptCtrl.text = data['p2_panch2Receipt']?.toString() ??
        data['panch2Receipt']?.toString() ??
        '';

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final serif = FormTypography.serifStyle();
    final marathi = FormTypography.marathiLabelStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        // ══════════════════════════════════════════════════════════
        // ── PAGE 1: घटनास्थळ / जप्ती पंचनामा सुचनापत्र ──
        // ══════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'पान १: घटनास्थळ / जप्ती पंचनामा सुचनापत्र',
          children: [
            // Top Right
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BilingualField(
                      label: '',
                      marathiLabel: 'पोलीस स्टेशन',
                      controller: _p1PsCtrl,
                      serifStyle: serif,
                      marathiLabelStyle: marathi,
                    ),
                    BilingualField(
                      label: '',
                      marathiLabel: 'दिनांक :-',
                      hintText: '......./ ......../२०...',
                      controller: _p1DateCtrl,
                      serifStyle: serif,
                      marathiLabelStyle: marathi,
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
                    '-:: पंच सुचनापत्र ::-',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '(कलम १७९ भारतीय नागरीक सुरक्षा संहिता २०२३ अन्वये)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Panch names
            Text(
              'पंच नांव  :-',
              style:
                  marathi.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            BilingualMultilineField(
              label: '',
              marathiLabel: '१)',
              controller: _p1Panch1Ctrl,
              minLines: 2,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 6),
            BilingualMultilineField(
              label: '',
              marathiLabel: '२)',
              controller: _p1Panch2Ctrl,
              minLines: 2,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 14),

            // Center oooo
            Center(
              child: Text(
                '००००',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Paragraph
            Text(
              'आपणास या सुचनापत्र देण्यात येते की, पोलीस स्टेशन',
              style: marathi.copyWith(fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 4),
            BilingualFieldRow(
              fields: [
                BilingualField(
                  label: '',
                  marathiLabel: 'पोलीस स्टेशन :',
                  controller: _p1FirPsCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'येथील अप / मर्ग / स्टे.डा क्रमांक :',
                  hintText: '......../२०.....',
                  controller: _p1CrimeNoCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
              ],
            ),
            const SizedBox(height: 4),
            BilingualField(
              label: '',
              marathiLabel: 'कलम :',
              controller: _p1ActSecCtrl,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 4),
            BilingualField(
              label: '',
              marathiLabel: 'मधील फिर्यादी नामे :',
              controller: _p1ComplainantNameCtrl,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 4),
            BilingualFieldRow(
              fields: [
                BilingualField(
                  label: '',
                  marathiLabel: 'रा. (राहणार) :',
                  controller: _p1ComplainantResidenceCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'ता. :-',
                  controller: _p1ComplainantTahCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'जिल्हा :-',
                  controller: _p1ComplainantDistCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'यांनी तक्रार दिली वरून सदरचा गुन्हा नोंद होउन तपासात आहे. तरी सदर गुन्ह्यामधील घटनास्थळचा/ जप्ती पंचनामा करावयाचा असल्याने आपण पंच म्हणुन हजर राहा असे सांगीतल्या वरून पंच हजर आले आहे.',
              style: marathi.copyWith(fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'करीता सुचनापत्र देण्यात येत आहे.',
                style: marathi.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Signature
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 250,
                child: Column(
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
                      controller: _p1IoNameSigCtrl,
                      serifStyle: serif,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Receipt Acknowledgement
            Text(
              'सुचनापत्र मिळाले आहे.',
              style: marathi.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 320,
              child: Column(
                children: [
                  BilingualField(
                    label: '',
                    marathiLabel: '१)',
                    controller: _p1Panch1ReceiptCtrl,
                    serifStyle: serif,
                    marathiLabelStyle: marathi,
                  ),
                  const SizedBox(height: 6),
                  BilingualField(
                    label: '',
                    marathiLabel: '२)',
                    controller: _p1Panch2ReceiptCtrl,
                    serifStyle: serif,
                    marathiLabelStyle: marathi,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FormMrwFooter(serifStyle: serif),
          ],
        ),

        // ══════════════════════════════════════════════════════════
        // ── PAGE 2: दारूबाबत प्रोहिबीशन रेड पंच सुचनापत्र ──
        // ══════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'पान २: दारूबाबत प्रोहिबीशन रेड पंच सुचनापत्र',
          children: [
            // Top Right
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BilingualField(
                      label: '',
                      marathiLabel: 'पोलीस स्टेशन',
                      controller: _p2PsCtrl,
                      serifStyle: serif,
                      marathiLabelStyle: marathi,
                    ),
                    BilingualField(
                      label: '',
                      marathiLabel: 'दिनांक :-',
                      hintText: '......./ ......../२०...',
                      controller: _p2DateCtrl,
                      serifStyle: serif,
                      marathiLabelStyle: marathi,
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
                    '-:: पंच सुचनापत्र ::-',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '(कलम १७९ भारतीय नागरीक सुरक्षा संहिता २०२३ अन्वये)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Panch names
            Text(
              'पंच नांव  :-',
              style:
                  marathi.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            BilingualMultilineField(
              label: '',
              marathiLabel: '१)',
              controller: _p2Panch1Ctrl,
              minLines: 2,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 6),
            BilingualMultilineField(
              label: '',
              marathiLabel: '२)',
              controller: _p2Panch2Ctrl,
              minLines: 2,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 14),

            // Center oooo
            Center(
              child: Text(
                '००००',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Paragraph
            Text(
              'आपणास या सुचनापत्र देण्यात येते की, आज दिनांक:',
              style: marathi.copyWith(fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 4),
            BilingualField(
              label: '',
              marathiLabel: 'आज दिनांक :-',
              hintText: '......./ ......./२०..... रोजी',
              controller: _p2RaidDateCtrl,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 4),
            BilingualFieldRow(
              fields: [
                BilingualField(
                  label: '',
                  marathiLabel: 'ग्राम :',
                  controller: _p2VillageCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'येथीलनामे :',
                  controller: _p2SuspectNameCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'वय :',
                  hintText: '........ वर्ष',
                  controller: _p2SuspectAgeCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
              ],
            ),
            const SizedBox(height: 4),
            BilingualFieldRow(
              fields: [
                BilingualField(
                  label: '',
                  marathiLabel: 'रा. (राहणार) :',
                  controller: _p2SuspectResidenceCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'ता. :-',
                  controller: _p2SuspectTahCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'जिल्हा :-',
                  controller: _p2SuspectDistCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'हा त्याचे घरी दारू विक्री करतो अशा माहिती वरून त्याचे घरी दारूबाबत प्रोहिबीशन रेड करावयाचा असल्याने आपण जप्त पंच म्हणुन सोबत चला व हजर राहावे.',
              style: marathi.copyWith(fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'करीता सुचनापत्र देण्यात येत आहे.',
                style: marathi.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Signature
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 250,
                child: Column(
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
                      controller: _p2IoNameSigCtrl,
                      serifStyle: serif,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Receipt Acknowledgement
            Text(
              'सुचनापत्र मिळाले आहे.',
              style: marathi.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 320,
              child: Column(
                children: [
                  BilingualField(
                    label: '',
                    marathiLabel: '१)',
                    controller: _p2Panch1ReceiptCtrl,
                    serifStyle: serif,
                    marathiLabelStyle: marathi,
                  ),
                  const SizedBox(height: 6),
                  BilingualField(
                    label: '',
                    marathiLabel: '२)',
                    controller: _p2Panch2ReceiptCtrl,
                    serifStyle: serif,
                    marathiLabelStyle: marathi,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FormMrwFooter(serifStyle: serif),
          ],
        ),
      ],
    );
  }
}
