import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_table_helpers.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// वैद्यकीय तपासणी (भारतीय नागरीक सुरक्षा संहिता २०२३ कलम ५१)
/// Medical Examination Request under Section 51 BNSS
class MedicalExamS51FormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const MedicalExamS51FormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<MedicalExamS51FormView> createState() => MedicalExamS51FormViewState();
}

class MedicalExamS51FormViewState extends State<MedicalExamS51FormView> {
  final _outpostCtrl = TextEditingController(text: 'सावळी');
  final _psCtrl = TextEditingController(text: 'पारवा');
  final _dateCtrl = TextEditingController();

  final _toOfficerCtrl = TextEditingController(text: 'मा. वैद्यकीय अधिकारी');
  final _toHospitalCtrl =
      TextEditingController(text: 'प्राथमिक आरोग्य केंद्र सावळी सदोबा');
  final _toTahDistCtrl = TextEditingController(text: 'ता आर्णी जिल्हा यवतमाळ.');

  final _fromLocationCtrl = TextEditingController(
    text: 'पोलीस दुरक्षेत्र सावळी सदोबा पोलीस स्टेशन पारवा जिल्हा यवतमाळ',
  );

  final _subjectCtrl = TextEditingController(
    text: 'जखमी यांचे माराची वैद्यकीय तपासणी करून अहवाल मिळणेबाबत.',
  );

  final _victimNameCtrl = TextEditingController();
  final _victimAgeCtrl = TextEditingController();
  final _victimResidenceCtrl = TextEditingController();
  final _victimTahCtrl = TextEditingController();
  final _victimDistCtrl = TextEditingController();
  final _assaultDetailsCtrl = TextEditingController();

  final _officerSignatureCtrl = TextEditingController();

  @override
  void dispose() {
    _outpostCtrl.dispose();
    _psCtrl.dispose();
    _dateCtrl.dispose();
    _toOfficerCtrl.dispose();
    _toHospitalCtrl.dispose();
    _toTahDistCtrl.dispose();
    _fromLocationCtrl.dispose();
    _subjectCtrl.dispose();
    _victimNameCtrl.dispose();
    _victimAgeCtrl.dispose();
    _victimResidenceCtrl.dispose();
    _victimTahCtrl.dispose();
    _victimDistCtrl.dispose();
    _assaultDetailsCtrl.dispose();
    _officerSignatureCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'outpost': _outpostCtrl.text,
      'policeStation': _psCtrl.text,
      'date': _dateCtrl.text,
      'toOfficer': _toOfficerCtrl.text,
      'toHospital': _toHospitalCtrl.text,
      'toTahDist': _toTahDistCtrl.text,
      'fromLocation': _fromLocationCtrl.text,
      'subject': _subjectCtrl.text,
      'victimName': _victimNameCtrl.text,
      'victimAge': _victimAgeCtrl.text,
      'victimResidence': _victimResidenceCtrl.text,
      'victimTah': _victimTahCtrl.text,
      'victimDist': _victimDistCtrl.text,
      'assaultDetails': _assaultDetailsCtrl.text,
      'officerSignature': _officerSignatureCtrl.text,
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    if (data.containsKey('outpost')) {
      _outpostCtrl.text = data['outpost']?.toString() ?? '';
    }
    if (data.containsKey('policeStation')) {
      _psCtrl.text = data['policeStation']?.toString() ?? '';
    }
    if (data.containsKey('date')) {
      _dateCtrl.text = data['date']?.toString() ?? '';
    }
    if (data.containsKey('toOfficer')) {
      _toOfficerCtrl.text = data['toOfficer']?.toString() ?? '';
    }
    if (data.containsKey('toHospital')) {
      _toHospitalCtrl.text = data['toHospital']?.toString() ?? '';
    }
    if (data.containsKey('toTahDist')) {
      _toTahDistCtrl.text = data['toTahDist']?.toString() ?? '';
    }
    if (data.containsKey('fromLocation')) {
      _fromLocationCtrl.text = data['fromLocation']?.toString() ?? '';
    }
    if (data.containsKey('subject')) {
      _subjectCtrl.text = data['subject']?.toString() ?? '';
    }
    if (data.containsKey('victimName')) {
      _victimNameCtrl.text = data['victimName']?.toString() ?? '';
    }
    if (data.containsKey('victimAge')) {
      _victimAgeCtrl.text = data['victimAge']?.toString() ?? '';
    }
    if (data.containsKey('victimResidence')) {
      _victimResidenceCtrl.text = data['victimResidence']?.toString() ?? '';
    }
    if (data.containsKey('victimTah')) {
      _victimTahCtrl.text = data['victimTah']?.toString() ?? '';
    }
    if (data.containsKey('victimDist')) {
      _victimDistCtrl.text = data['victimDist']?.toString() ?? '';
    }
    if (data.containsKey('assaultDetails')) {
      _assaultDetailsCtrl.text = data['assaultDetails']?.toString() ?? '';
    }
    if (data.containsKey('officerSignature')) {
      _officerSignatureCtrl.text = data['officerSignature']?.toString() ?? '';
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final serif = FormTypography.serifStyle();
    final marathi = FormTypography.marathiLabelStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        FormPaperPage(
          formLabel: widget.pageRange,
          children: [
            // ── HEADER ──
            Center(
              child: Column(
                children: [
                  Text(
                    'वैद्यकीय तपासणी',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '(भारतीय नागरीक सुरक्षा संहिता २०२३ कलम ५१)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── TOP RIGHT POLICE STATION / OUTPOST / DATE ──
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BilingualField(
                      label: '',
                      marathiLabel: 'पोलीस दुरक्षेत्र :',
                      controller: _outpostCtrl,
                      serifStyle: serif,
                      marathiLabelStyle: marathi,
                    ),
                    BilingualField(
                      label: '',
                      marathiLabel: 'पोलीस स्टेशन :',
                      controller: _psCtrl,
                      serifStyle: serif,
                      marathiLabelStyle: marathi,
                    ),
                    BilingualField(
                      label: '',
                      marathiLabel: 'दिनांक :-',
                      hintText: '......./ ......../ २०....',
                      controller: _dateCtrl,
                      serifStyle: serif,
                      marathiLabelStyle: marathi,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── RECIPIENT (प्रति,) ──
            Text(
              'प्रति,',
              style: marathi.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BilingualField(
                    label: '',
                    marathiLabel: 'पदनाम :',
                    controller: _toOfficerCtrl,
                    serifStyle: serif,
                    marathiLabelStyle: marathi,
                  ),
                  BilingualField(
                    label: '',
                    marathiLabel: 'रुग्णालय / आरोग्य केंद्र :',
                    controller: _toHospitalCtrl,
                    serifStyle: serif,
                    marathiLabelStyle: marathi,
                  ),
                  BilingualField(
                    label: '',
                    marathiLabel: 'ता. / जिल्हा :',
                    controller: _toTahDistCtrl,
                    serifStyle: serif,
                    marathiLabelStyle: marathi,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── SENDER (पासुन :-) ──
            BilingualField(
              label: '',
              marathiLabel: 'पासुन :-',
              controller: _fromLocationCtrl,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 12),

            // ── SUBJECT (विषय :-) ──
            BilingualField(
              label: '',
              marathiLabel: 'विषय :-',
              controller: _subjectCtrl,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 14),

            // ── DECORATIVE OOOO ──
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

            // ── PARAGRAPH INTRO ──
            Text(
              'उपरोक्त विषयान्वये सादर आहे की,',
              style: marathi.copyWith(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 8),

            // ── VICTIM DETAILS ──
            BilingualField(
              label: '',
              marathiLabel: 'जखमी नामे :',
              controller: _victimNameCtrl,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 6),
            BilingualFieldRow(
              fields: [
                BilingualField(
                  label: '',
                  marathiLabel: 'वय :',
                  hintText: '...... वर्ष',
                  controller: _victimAgeCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'रा. (राहणार) :',
                  controller: _victimResidenceCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'ता. :-',
                  controller: _victimTahCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'जिल्हा :-',
                  controller: _victimDistCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'यांना गैरअर्जदार / आरोपी यांनी भांडणात मारहाण केल्याचे व मार लागल्याचे वर्णन :',
              style: marathi.copyWith(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 6),
            BilingualMultilineField(
              label: '',
              marathiLabel: 'मारहाण व जखमांचे वर्णन :',
              controller: _assaultDetailsCtrl,
              minLines: 3,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 12),

            // ── CLOSING TEXT ──
            Text(
              'मार लागल्याचे सांगत आहे. तरी मार कशाचा व किती वेळ पुर्विचा आहे, सदर माराची तपासणी होउन आपला अभिप्राय मिळणेस विनंती आहे.',
              style: marathi.copyWith(fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 36),

            // ── SIGNATURE / SENDER ──
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 250,
                child: Column(
                  children: [
                    BilingualField(
                      label: '',
                      marathiLabel: 'सही व पदनाम',
                      controller: _officerSignatureCtrl,
                      serifStyle: serif,
                      marathiLabelStyle: marathi,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FormMrwFooter(serifStyle: serif),
          ],
        ),
      ],
    );
  }
}
