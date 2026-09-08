import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_table_helpers.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// -:: आरोपीस सुचनापत्र ::- (भारतीय नागरी सुरक्षा संहिता २०२३ कलम ४७ (१)(२))
class NoticeToAccusedFormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const NoticeToAccusedFormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<NoticeToAccusedFormView> createState() =>
      NoticeToAccusedFormViewState();
}

class NoticeToAccusedFormViewState extends State<NoticeToAccusedFormView> {
  final _psCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  final _accusedNameAddressCtrl = TextEditingController();
  final _mobileNoCtrl = TextEditingController();
  final _aadhaarNoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final _firPsCtrl = TextEditingController();
  final _crimeNoCtrl = TextEditingController();
  final _actSecCtrl = TextEditingController();
  final _coActSecCtrl = TextEditingController();
  final _firDateCtrl = TextEditingController();

  final _bailTypeCtrl = TextEditingController(text: 'अजमीनपात्र/ जामीनपात्र');
  final _relativeDetailsCtrl = TextEditingController();

  final _accusedSigCtrl = TextEditingController();
  final _ioNameSigCtrl = TextEditingController();

  @override
  void dispose() {
    _psCtrl.dispose();
    _dateCtrl.dispose();
    _accusedNameAddressCtrl.dispose();
    _mobileNoCtrl.dispose();
    _aadhaarNoCtrl.dispose();
    _emailCtrl.dispose();
    _firPsCtrl.dispose();
    _crimeNoCtrl.dispose();
    _actSecCtrl.dispose();
    _coActSecCtrl.dispose();
    _firDateCtrl.dispose();
    _bailTypeCtrl.dispose();
    _relativeDetailsCtrl.dispose();
    _accusedSigCtrl.dispose();
    _ioNameSigCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'policeStation': _psCtrl.text,
      'date': _dateCtrl.text,
      'accusedNameAddress': _accusedNameAddressCtrl.text,
      'mobileNo': _mobileNoCtrl.text,
      'aadhaarNo': _aadhaarNoCtrl.text,
      'email': _emailCtrl.text,
      'firPs': _firPsCtrl.text,
      'crimeNo': _crimeNoCtrl.text,
      'actSec': _actSecCtrl.text,
      'coActSec': _coActSecCtrl.text,
      'firDate': _firDateCtrl.text,
      'bailType': _bailTypeCtrl.text,
      'relativeDetails': _relativeDetailsCtrl.text,
      'accusedSig': _accusedSigCtrl.text,
      'ioNameSig': _ioNameSigCtrl.text,
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    _psCtrl.text = data['policeStation']?.toString() ?? '';
    _dateCtrl.text = data['date']?.toString() ?? '';
    _accusedNameAddressCtrl.text = data['accusedNameAddress']?.toString() ?? '';
    _mobileNoCtrl.text = data['mobileNo']?.toString() ?? '';
    _aadhaarNoCtrl.text = data['aadhaarNo']?.toString() ?? '';
    _emailCtrl.text = data['email']?.toString() ?? '';
    _firPsCtrl.text = data['firPs']?.toString() ?? '';
    _crimeNoCtrl.text = data['crimeNo']?.toString() ?? '';
    _actSecCtrl.text = data['actSec']?.toString() ?? '';
    _coActSecCtrl.text = data['coActSec']?.toString() ?? '';
    _firDateCtrl.text = data['firDate']?.toString() ?? '';
    _bailTypeCtrl.text =
        data['bailType']?.toString() ?? 'अजमीनपात्र/ जामीनपात्र';
    _relativeDetailsCtrl.text = data['relativeDetails']?.toString() ?? '';
    _accusedSigCtrl.text = data['accusedSig']?.toString() ?? '';
    _ioNameSigCtrl.text = data['ioNameSig']?.toString() ?? '';
    if (mounted) setState(() {});
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
            // ── TOP RIGHT POLICE STATION & DATE ──
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BilingualField(
                      label: '',
                      marathiLabel: 'पोलीस स्टेशन',
                      controller: _psCtrl,
                      serifStyle: serif,
                      marathiLabelStyle: marathi,
                    ),
                    BilingualField(
                      label: '',
                      marathiLabel: 'दिनांक :-',
                      hintText: '......./ ......../२०...',
                      controller: _dateCtrl,
                      serifStyle: serif,
                      marathiLabelStyle: marathi,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── TITLE ──
            Center(
              child: Column(
                children: [
                  Text(
                    '-:: आरोपीस सुचनापत्र ::-',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '(भारतीय नागरी सुरक्षा संहिता २०२३ कलम ४७ (१)(२))',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── ACCUSED DETAILS ──
            BilingualMultilineField(
              label: '',
              marathiLabel: 'नांव :-',
              controller: _accusedNameAddressCtrl,
              minLines: 2,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 8),

            BilingualFieldRow(
              fields: [
                BilingualField(
                  label: '',
                  marathiLabel: 'मो.नं.:-',
                  controller: _mobileNoCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'आधार क्र :-',
                  controller: _aadhaarNoCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
              ],
            ),
            const SizedBox(height: 6),

            BilingualField(
              label: '',
              marathiLabel: 'ईमेल :-',
              controller: _emailCtrl,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 20),

            // ── PARAGRAPH 1 ──
            Text(
              'आपणास याद्वारे सुचीत करण्यात येते की, आपणा विरुध्द पोलीस स्टेशन',
              style: marathi.copyWith(fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 4),
            BilingualFieldRow(
              fields: [
                BilingualField(
                  label: '',
                  marathiLabel: 'पोलीस स्टेशन :',
                  controller: _firPsCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'अपराध क्रमांक :',
                  hintText: '............/२०......',
                  controller: _crimeNoCtrl,
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
                  marathiLabel: 'कलम भा.न्या.संहिता २०२३ :',
                  controller: _actSecCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'व सह कलम :',
                  controller: _coActSecCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
              ],
            ),
            const SizedBox(height: 4),
            BilingualField(
              label: '',
              marathiLabel: 'प्रमाणे दिनांक :',
              hintText: '...../...../२०.....',
              controller: _firDateCtrl,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 4),
            Text(
              'गुन्हा दाखल असुन सदर गुन्ह्याचा तपास आम्ही स्वतः करत आहोत. सदर गुन्ह्याच्या तपासकामी आपणास अटक करण्यात येत आहे.',
              style: marathi.copyWith(fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 16),

            // ── PARAGRAPH 2 ──
            BilingualField(
              label: '',
              marathiLabel: 'गुन्ह्याचे स्वरूप (अजमीनपात्र/ जामीनपात्र) :',
              controller: _bailTypeCtrl,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 4),
            Text(
              'सदर गुन्हा दखलपात्र असुन अजमीनपात्र/ जामीनपात्र आहे. आपल्या अटकेबाबतची माहित भारतीय नागरीक सुरक्षा संहिता २०२३ कलम (४८) प्रमाणे आपले नातेवाईक/ मित्र',
              style: marathi.copyWith(fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 4),
            BilingualMultilineField(
              label: '',
              marathiLabel: 'नातेवाईक/ मित्र नांव, पत्ता व संपर्क :',
              controller: _relativeDetailsCtrl,
              minLines: 2,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 4),
            Text(
              'यांना समक्ष/फोनद्वारे देण्यात आली असुन अटक पंचनाम्यावर त्यांची स्वाक्षरी घेण्यात आली आहे.',
              style: marathi.copyWith(fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'करीता आपणास सुचनापत्र देण्यात येत आहे.',
                style: marathi.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 36),

            // ── SIGNATURES ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 200,
                  child: Column(
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
                        controller: _accusedSigCtrl,
                        serifStyle: serif,
                      ),
                    ],
                  ),
                ),
                SizedBox(
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
                        controller: _ioNameSigCtrl,
                        serifStyle: serif,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FormMrwFooter(serifStyle: serif),
          ],
        ),
      ],
    );
  }
}
