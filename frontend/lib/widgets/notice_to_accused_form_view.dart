import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
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
  // ── TOP HEADER ──
  final _psCtrl = TextEditingController();
  final _dateDayCtrl = TextEditingController();
  final _dateMonthCtrl = TextEditingController();
  final _dateYearCtrl = TextEditingController(text: '२५');
  final _dateCtrl = TextEditingController();

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

  // ── ACCUSED DETAILS ──
  final _accusedNameLine1Ctrl = TextEditingController();
  final _accusedNameLine2Ctrl = TextEditingController();
  final _mobileNoCtrl = TextEditingController();
  final _aadhaarNoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // ── PARAGRAPH 1 ──
  final _firPsCtrl = TextEditingController();
  final _firDistCtrl = TextEditingController();
  final _crimeNoCtrl = TextEditingController();
  final _crimeYearCtrl = TextEditingController(text: '२५');
  final _actSecCtrl = TextEditingController();
  final _actSecLine2Ctrl = TextEditingController();
  final _coActSecCtrl = TextEditingController();
  final _coActSecLine2Ctrl = TextEditingController();

  final _firDayCtrl = TextEditingController();
  final _firMonthCtrl = TextEditingController();
  final _firYearCtrl = TextEditingController(text: '२५');
  final _firDateCtrl = TextEditingController();

  String get _firDateCombined {
    final d = _firDayCtrl.text.trim();
    final m = _firMonthCtrl.text.trim();
    final y = _firYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) {
      return _firDateCtrl.text.trim();
    }
    final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
    return '$d/$m/$yFull'.replaceAll(RegExp(r'/+$'), '');
  }

  // ── PARAGRAPH 2 ──
  final _bailTypeCtrl = TextEditingController(text: 'अजमीनपात्र/ जामीनपात्र');
  final _relativeDetailsLine1Ctrl = TextEditingController();
  final _relativeDetailsLine2Ctrl = TextEditingController();

  // ── SIGNATURES ──
  final _accusedSigCtrl = TextEditingController();
  final _ioNameSigCtrl = TextEditingController();

  @override
  void dispose() {
    _psCtrl.dispose();
    _dateDayCtrl.dispose();
    _dateMonthCtrl.dispose();
    _dateYearCtrl.dispose();
    _dateCtrl.dispose();

    _accusedNameLine1Ctrl.dispose();
    _accusedNameLine2Ctrl.dispose();
    _mobileNoCtrl.dispose();
    _aadhaarNoCtrl.dispose();
    _emailCtrl.dispose();

    _firPsCtrl.dispose();
    _firDistCtrl.dispose();
    _crimeNoCtrl.dispose();
    _crimeYearCtrl.dispose();
    _actSecCtrl.dispose();
    _actSecLine2Ctrl.dispose();
    _coActSecCtrl.dispose();
    _coActSecLine2Ctrl.dispose();

    _firDayCtrl.dispose();
    _firMonthCtrl.dispose();
    _firYearCtrl.dispose();
    _firDateCtrl.dispose();

    _bailTypeCtrl.dispose();
    _relativeDetailsLine1Ctrl.dispose();
    _relativeDetailsLine2Ctrl.dispose();

    _accusedSigCtrl.dispose();
    _ioNameSigCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    final accusedCombined = [
      _accusedNameLine1Ctrl.text.trim(),
      _accusedNameLine2Ctrl.text.trim(),
    ].where((e) => e.isNotEmpty).join('\n');

    final actSecCombined = [
      _actSecCtrl.text.trim(),
      _actSecLine2Ctrl.text.trim(),
    ].where((e) => e.isNotEmpty).join(' ');

    final coActSecCombined = [
      _coActSecCtrl.text.trim(),
      _coActSecLine2Ctrl.text.trim(),
    ].where((e) => e.isNotEmpty).join(' ');

    final relativeCombined = [
      _relativeDetailsLine1Ctrl.text.trim(),
      _relativeDetailsLine2Ctrl.text.trim(),
    ].where((e) => e.isNotEmpty).join('\n');

    final crCombined = _crimeYearCtrl.text.trim().isNotEmpty
        ? '${_crimeNoCtrl.text.trim()}/${_crimeYearCtrl.text.trim()}'
        : _crimeNoCtrl.text.trim();

    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'policeStation': _psCtrl.text.trim(),
      'date': _dateCombined,
      'dateDay': _dateDayCtrl.text.trim(),
      'dateMonth': _dateMonthCtrl.text.trim(),
      'dateYear': _dateYearCtrl.text.trim(),
      'accusedName': _accusedNameLine1Ctrl.text.trim(),
      'accusedNameLine2': _accusedNameLine2Ctrl.text.trim(),
      'accusedNameAddress': accusedCombined,
      'mobileNo': _mobileNoCtrl.text.trim(),
      'aadhaarNo': _aadhaarNoCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'firPs': _firPsCtrl.text.trim(),
      'firDist': _firDistCtrl.text.trim(),
      'crimeNo': crCombined,
      'crimeNumberOnly': _crimeNoCtrl.text.trim(),
      'crimeYear': _crimeYearCtrl.text.trim(),
      'actSec': actSecCombined,
      'actSecLine1': _actSecCtrl.text.trim(),
      'actSecLine2': _actSecLine2Ctrl.text.trim(),
      'coActSec': coActSecCombined,
      'coActSecLine1': _coActSecCtrl.text.trim(),
      'coActSecLine2': _coActSecLine2Ctrl.text.trim(),
      'firDate': _firDateCombined,
      'firDay': _firDayCtrl.text.trim(),
      'firMonth': _firMonthCtrl.text.trim(),
      'firYear': _firYearCtrl.text.trim(),
      'bailType': _bailTypeCtrl.text.trim(),
      'relativeDetails': relativeCombined,
      'relativeDetailsLine1': _relativeDetailsLine1Ctrl.text.trim(),
      'relativeDetailsLine2': _relativeDetailsLine2Ctrl.text.trim(),
      'accusedSig': _accusedSigCtrl.text.trim(),
      'ioNameSig': _ioNameSigCtrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    setState(() {
      _psCtrl.text =
          data['policeStation']?.toString() ?? data['ps']?.toString() ?? '';

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

      final rawAccused = data['accusedNameAddress']?.toString() ??
          data['accusedName']?.toString() ??
          '';
      if (rawAccused.contains('\n')) {
        final p = rawAccused.split('\n');
        _accusedNameLine1Ctrl.text = p[0].trim();
        _accusedNameLine2Ctrl.text = p.sublist(1).join(' ').trim();
      } else {
        _accusedNameLine1Ctrl.text =
            data['accusedName']?.toString() ?? rawAccused;
        _accusedNameLine2Ctrl.text = data['accusedNameLine2']?.toString() ?? '';
      }

      _mobileNoCtrl.text = data['mobileNo']?.toString() ?? '';
      _aadhaarNoCtrl.text = data['aadhaarNo']?.toString() ?? '';
      _emailCtrl.text = data['email']?.toString() ?? '';

      _firPsCtrl.text = data['firPs']?.toString() ?? '';
      _firDistCtrl.text = data['firDist']?.toString() ?? '';

      final rawCr = data['crimeNo']?.toString() ?? '';
      if (rawCr.contains('/')) {
        final p = rawCr.split('/');
        _crimeNoCtrl.text = p[0].trim();
        var y = p[1].trim();
        if (y.startsWith('20') && y.length == 4) y = y.substring(2);
        _crimeYearCtrl.text = y;
      } else {
        _crimeNoCtrl.text = data['crimeNumberOnly']?.toString() ?? rawCr;
        _crimeYearCtrl.text = data['crimeYear']?.toString() ?? '२५';
      }

      _actSecCtrl.text =
          data['actSecLine1']?.toString() ?? data['actSec']?.toString() ?? '';
      _actSecLine2Ctrl.text = data['actSecLine2']?.toString() ?? '';

      _coActSecCtrl.text = data['coActSecLine1']?.toString() ??
          data['coActSec']?.toString() ??
          '';
      _coActSecLine2Ctrl.text = data['coActSecLine2']?.toString() ?? '';

      _firDateCtrl.text = data['firDate']?.toString() ?? '';
      _firDayCtrl.text = data['firDay']?.toString() ?? '';
      _firMonthCtrl.text = data['firMonth']?.toString() ?? '';
      _firYearCtrl.text = data['firYear']?.toString() ?? '';
      if (_firDayCtrl.text.isEmpty && _firDateCtrl.text.isNotEmpty) {
        final parts = _firDateCtrl.text.split(RegExp(r'[/.-]'));
        if (parts.length >= 3) {
          _firDayCtrl.text = parts[0].trim();
          _firMonthCtrl.text = parts[1].trim();
          var yr = parts[2].trim();
          if (yr.startsWith('20') && yr.length == 4) yr = yr.substring(2);
          _firYearCtrl.text = yr;
        }
      }

      _bailTypeCtrl.text =
          data['bailType']?.toString() ?? 'अजमीनपात्र/ जामीनपात्र';

      final rawRel = data['relativeDetails']?.toString() ?? '';
      if (rawRel.contains('\n')) {
        final p = rawRel.split('\n');
        _relativeDetailsLine1Ctrl.text = p[0].trim();
        _relativeDetailsLine2Ctrl.text = p.sublist(1).join(' ').trim();
      } else {
        _relativeDetailsLine1Ctrl.text =
            data['relativeDetailsLine1']?.toString() ?? rawRel;
        _relativeDetailsLine2Ctrl.text =
            data['relativeDetailsLine2']?.toString() ?? '';
      }

      _accusedSigCtrl.text = data['accusedSig']?.toString() ?? '';
      _ioNameSigCtrl.text = data['ioNameSig']?.toString() ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final serif = FormTypography.serifStyle();
    final marathi = FormTypography.marathiLabelStyle();

    final bodyTextStyle = marathi.copyWith(
      fontSize: 14.5,
      height: 2.2,
      color: Colors.black87,
    );
    final headerLabelStyle = marathi.copyWith(
      fontSize: 14.5,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );
    final serifBold = serif.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 14.5,
      color: Colors.black87,
    );

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        FormPaperPage(
          minHeight: 1180,
          formLabel: widget.pageRange ?? 'आरोपीस सुचनापत्र',
          children: [
            const SizedBox(height: 12),

            // ── TOP RIGHT POLICE STATION & DATE ──
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('पोलीस स्टेशन', style: headerLabelStyle),
                        const SizedBox(width: 8),
                        Expanded(
                          child: BilingualSimpleUnderlineInput(
                            controller: _psCtrl,
                            serifStyle: serif,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('दिनांक :', style: headerLabelStyle),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 38,
                          child: BilingualSimpleUnderlineInput(
                            controller: _dateDayCtrl,
                            serifStyle: serif,
                            hintText: '.......',
                          ),
                        ),
                        Text('/', style: serifBold),
                        SizedBox(
                          width: 42,
                          child: BilingualSimpleUnderlineInput(
                            controller: _dateMonthCtrl,
                            serifStyle: serif,
                            hintText: '........',
                          ),
                        ),
                        Text('/ २०', style: headerLabelStyle),
                        SizedBox(
                          width: 44,
                          child: BilingualSimpleUnderlineInput(
                            controller: _dateYearCtrl,
                            serifStyle: serif,
                            hintText: '....',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── TITLE ──
            Center(
              child: Column(
                children: [
                  Text(
                    '-:: आरोपीस सुचनापत्र ::-',
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(भारतीय नागरी सुरक्षा संहिता २०२३ कलम ४७ (१)(२))',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // ── ACCUSED DETAILS ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 60,
                  child: Text('नांव :-', style: headerLabelStyle),
                ),
                Expanded(
                  child: Column(
                    children: [
                      BilingualSimpleUnderlineInput(
                        controller: _accusedNameLine1Ctrl,
                        serifStyle: serif,
                      ),
                      const SizedBox(height: 10),
                      BilingualSimpleUnderlineInput(
                        controller: _accusedNameLine2Ctrl,
                        serifStyle: serif,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Mobile & Aadhaar
            Row(
              children: [
                Text('मो.नं.:-', style: headerLabelStyle),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: BilingualSimpleUnderlineInput(
                    controller: _mobileNoCtrl,
                    serifStyle: serif,
                  ),
                ),
                const SizedBox(width: 24),
                Text('आधार क्र :-', style: headerLabelStyle),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: BilingualSimpleUnderlineInput(
                    controller: _aadhaarNoCtrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Email
            Row(
              children: [
                Text('ईमेल :-', style: headerLabelStyle),
                const SizedBox(width: 8),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _emailCtrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // ── PARAGRAPH 1 ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 12,
              children: [
                Text(
                  '        आपणास याद्वारे सुचीत करण्यात येते की,आपणा विरूध्द पोलीस स्टेशन',
                  style: bodyTextStyle,
                ),
                SizedBox(
                  width: 200,
                  child: BilingualSimpleUnderlineInput(
                    controller: _firPsCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('जिल्हा', style: bodyTextStyle),
                SizedBox(
                  width: 95,
                  child: BilingualSimpleUnderlineInput(
                    controller: _firDistCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('येथे अपराध क्रमांक', style: bodyTextStyle),
                SizedBox(
                  width: 100,
                  child: BilingualSimpleUnderlineInput(
                    controller: _crimeNoCtrl,
                    serifStyle: serif,
                    hintText: '............',
                  ),
                ),
                Text('/ २०', style: bodyTextStyle),
                SizedBox(
                  width: 44,
                  child: BilingualSimpleUnderlineInput(
                    controller: _crimeYearCtrl,
                    serifStyle: serif,
                    hintText: '.....',
                  ),
                ),
                Text('कलम', style: bodyTextStyle),
                SizedBox(
                  width: 260,
                  child: BilingualSimpleUnderlineInput(
                    controller: _actSecCtrl,
                    serifStyle: serif,
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: BilingualSimpleUnderlineInput(
                    controller: _actSecLine2Ctrl,
                    serifStyle: serif,
                  ),
                ),
                Text('भा.न्या.संहिता २०२३ व सह कलम', style: bodyTextStyle),
                SizedBox(
                  width: 240,
                  child: BilingualSimpleUnderlineInput(
                    controller: _coActSecCtrl,
                    serifStyle: serif,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: BilingualSimpleUnderlineInput(
                    controller: _coActSecLine2Ctrl,
                    serifStyle: serif,
                  ),
                ),
                Text('प्रमाणे दिनांक', style: bodyTextStyle),
                SizedBox(
                  width: 38,
                  child: BilingualSimpleUnderlineInput(
                    controller: _firDayCtrl,
                    serifStyle: serif,
                    hintText: '.....',
                  ),
                ),
                Text('/', style: serifBold),
                SizedBox(
                  width: 38,
                  child: BilingualSimpleUnderlineInput(
                    controller: _firMonthCtrl,
                    serifStyle: serif,
                    hintText: '.....',
                  ),
                ),
                Text('/ २०', style: bodyTextStyle),
                SizedBox(
                  width: 44,
                  child: BilingualSimpleUnderlineInput(
                    controller: _firYearCtrl,
                    serifStyle: serif,
                    hintText: '......',
                  ),
                ),
                Text(
                  'गुन्हा दाखल असुन सदर गुन्ह्याचा तपास आम्ही स्वतः करत आहोत. सदर गुन्ह्याच्या तपासकामी आपणास अटक करण्यात येत आहे.',
                  style: bodyTextStyle,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── PARAGRAPH 2 ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 12,
              children: [
                Text('        सदर गुन्हा दखलपात्र असुन', style: bodyTextStyle),
                SizedBox(
                  width: 170,
                  child: BilingualSimpleUnderlineInput(
                    controller: _bailTypeCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(
                  'आहे. आपल्या अटकेबाबतची माहित भारतीय नागरीक सुरक्षा संहिता २०२३ कलम (४८) प्रमाणे आपले नातेवाईक/ मित्र.....',
                  style: bodyTextStyle,
                ),
                SizedBox(
                  width: 320,
                  child: BilingualSimpleUnderlineInput(
                    controller: _relativeDetailsLine1Ctrl,
                    serifStyle: serif,
                  ),
                ),
                SizedBox(
                  width: 360,
                  child: BilingualSimpleUnderlineInput(
                    controller: _relativeDetailsLine2Ctrl,
                    serifStyle: serif,
                  ),
                ),
                Text(
                  'यांना समक्ष/फोनद्वारे देण्यात आली असुन अटक पंचनाम्यावर त्यांची स्वाक्षरी घेण्यात आली आहे.',
                  style: bodyTextStyle,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── PARAGRAPH 3 (Closing Line) ──
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                'करीता आपणास सुचनापत्र देण्यात येत आहे.',
                style: bodyTextStyle,
              ),
            ),
            const SizedBox(height: 64),

            // ── SIGNATURES ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 220,
                  child: Column(
                    children: [
                      Text('आरोपीची स्वाक्षरी', style: headerLabelStyle),
                      const SizedBox(height: 10),
                      BilingualSimpleUnderlineInput(
                        controller: _accusedSigCtrl,
                        serifStyle: serif,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 270,
                  child: Column(
                    children: [
                      Text('तपासी अधिकारी नांव व सही', style: headerLabelStyle),
                      const SizedBox(height: 10),
                      BilingualSimpleUnderlineInput(
                        controller: _ioNameSigCtrl,
                        serifStyle: serif,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // ── MRW FOOTER ──
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'M.R.W',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
