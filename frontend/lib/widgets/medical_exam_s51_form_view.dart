import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
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
  final _outpostCtrl = TextEditingController();
  final _psCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _dateDayCtrl = TextEditingController();
  final _dateMonthCtrl = TextEditingController();
  final _dateYearCtrl = TextEditingController();

  String get _dateCombined {
    final d = _dateDayCtrl.text.trim();
    final m = _dateMonthCtrl.text.trim();
    final y = _dateYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) {
      return _dateCtrl.text.trim();
    }
    final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
    return '$d/$m/$yFull'.replaceAll(RegExp(r'/+$'), '');
  }

  final _toOfficerCtrl = TextEditingController();
  final _toHospitalCtrl = TextEditingController();
  final _toTahDistCtrl = TextEditingController();

  final _fromLocationCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();

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
    _dateDayCtrl.dispose();
    _dateMonthCtrl.dispose();
    _dateYearCtrl.dispose();
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
      'outpost': _outpostCtrl.text.trim(),
      'policeStation': _psCtrl.text.trim(),
      'date': _dateCombined,
      'dateDay': _dateDayCtrl.text.trim(),
      'dateMonth': _dateMonthCtrl.text.trim(),
      'dateYear': _dateYearCtrl.text.trim(),
      'toOfficer': _toOfficerCtrl.text.trim(),
      'toHospital': _toHospitalCtrl.text.trim(),
      'toTahDist': _toTahDistCtrl.text.trim(),
      'fromLocation': _fromLocationCtrl.text.trim(),
      'subject': _subjectCtrl.text.trim(),
      'victimName': _victimNameCtrl.text.trim(),
      'victimAge': _victimAgeCtrl.text.trim(),
      'victimResidence': _victimResidenceCtrl.text.trim(),
      'victimTah': _victimTahCtrl.text.trim(),
      'victimDist': _victimDistCtrl.text.trim(),
      'assaultDetails': _assaultDetailsCtrl.text.trim(),
      'officerSignature': _officerSignatureCtrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    if (data.containsKey('outpost')) {
      _outpostCtrl.text = data['outpost']?.toString() ?? '';
    }
    if (data.containsKey('policeStation')) {
      _psCtrl.text = data['policeStation']?.toString() ?? '';
    }
    _dateCtrl.text = data['date']?.toString() ?? '';
    _dateDayCtrl.text = data['dateDay']?.toString() ?? '';
    _dateMonthCtrl.text = data['dateMonth']?.toString() ?? '';
    _dateYearCtrl.text = data['dateYear']?.toString() ?? '';
    if (_dateDayCtrl.text.isEmpty && _dateCtrl.text.isNotEmpty) {
      final parts = _dateCtrl.text.split(RegExp(r'[/.-]'));
      if (parts.length >= 3) {
        _dateDayCtrl.text = parts[0].trim();
        _dateMonthCtrl.text = parts[1].trim();
        var yr = parts[2].trim();
        if (yr.startsWith('20') && yr.length == 4) yr = yr.substring(2);
        _dateYearCtrl.text = yr;
      }
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

    final bodyTextStyle = marathi.copyWith(
      fontSize: 13,
      height: 2.0,
      color: Colors.black87,
    );
    final headerLabelStyle = marathi.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );
    final serifBold = serif.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        FormPaperPage(
          formLabel: widget.pageRange,
          children: [
            const SizedBox(height: 8),

            // ── HEADER ──
            Center(
              child: Column(
                children: [
                  Text(
                    'वैद्यकीय तपासणी',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '(भारतीय नागरीक सुरक्षा संहिता २०२३ कलम ५१)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── TOP RIGHT POLICE STATION / OUTPOST / DATE ──
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('पोलीस दुरक्षेत्र ', style: headerLabelStyle),
                        Expanded(
                          child: BilingualSimpleUnderlineInput(
                            controller: _outpostCtrl,
                            serifStyle: serif,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('पोलीस स्टेशन ', style: headerLabelStyle),
                        Expanded(
                          child: BilingualSimpleUnderlineInput(
                            controller: _psCtrl,
                            serifStyle: serif,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('दिनांक : ', style: headerLabelStyle),
                        SizedBox(
                          width: 32,
                          child: BilingualSimpleUnderlineInput(
                            controller: _dateDayCtrl,
                            serifStyle: serif,
                            hintText: 'DD',
                          ),
                        ),
                        Text('/', style: serifBold),
                        SizedBox(
                          width: 32,
                          child: BilingualSimpleUnderlineInput(
                            controller: _dateMonthCtrl,
                            serifStyle: serif,
                            hintText: 'MM',
                          ),
                        ),
                        Text('/ २०', style: headerLabelStyle),
                        SizedBox(
                          width: 36,
                          child: BilingualSimpleUnderlineInput(
                            controller: _dateYearCtrl,
                            serifStyle: serif,
                            hintText: 'YY',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── RECIPIENT (प्रति,) ──
            Text(
              'प्रति,',
              style: headerLabelStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 340,
                    child: BilingualSimpleUnderlineInput(
                      controller: _toOfficerCtrl,
                      serifStyle: serif,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 340,
                    child: BilingualSimpleUnderlineInput(
                      controller: _toHospitalCtrl,
                      serifStyle: serif,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 340,
                    child: BilingualSimpleUnderlineInput(
                      controller: _toTahDistCtrl,
                      serifStyle: serif,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── SENDER (पासुन :-) ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('पासुन  :-    ', style: headerLabelStyle),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fromLocationCtrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── SUBJECT (विषय :-) ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('विषय   :-    ', style: headerLabelStyle),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _subjectCtrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── DECORATIVE OOOO ──
            Center(
              child: Text(
                '००००',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── MAIN BODY PARAGRAPH ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 10,
              children: [
                Text(
                  '        उपरोक्त विषयान्वये सादर आहे की, जखमी नामे ',
                  style: bodyTextStyle,
                ),
                SizedBox(
                  width: 280,
                  child: BilingualSimpleUnderlineInput(
                    controller: _victimNameCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(', वय ', style: bodyTextStyle),
                SizedBox(
                  width: 44,
                  child: BilingualSimpleUnderlineInput(
                    controller: _victimAgeCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(' वर्ष रा ', style: bodyTextStyle),
                SizedBox(
                  width: 180,
                  child: BilingualSimpleUnderlineInput(
                    controller: _victimResidenceCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(' ता ', style: bodyTextStyle),
                SizedBox(
                  width: 130,
                  child: BilingualSimpleUnderlineInput(
                    controller: _victimTahCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(' जिल्हा ', style: bodyTextStyle),
                SizedBox(
                  width: 100,
                  child: BilingualSimpleUnderlineInput(
                    controller: _victimDistCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(
                  ' यांना गैरअर्जदार/ आरोपी यांनी भांडणात मारहाण केल्याचे ',
                  style: bodyTextStyle,
                ),
                SizedBox(
                  width: 280,
                  child: BilingualSimpleUnderlineInput(
                    controller: _assaultDetailsCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(
                  ' मारलागल्याचे सांगत आहे. तरी मार कशाचा व किती वेळ पुर्विचा आहे, सदर माराची तपासणी होउन आपला अभिप्राय मिळणेस विनंती आहे.',
                  style: bodyTextStyle,
                ),
              ],
            ),
            const SizedBox(height: 48),

            // ── BOTTOM RIGHT M.R.W ──
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'M.R.W',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
