import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// भारतीय नागरीक सुरक्षा संहिता, २०२३ चे कलम ४७ (१)(२) अन्वये सुचनापत्र (GROUNDS OF ARREST) — 2 A4 Pages
class GroundOfArrestFormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const GroundOfArrestFormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<GroundOfArrestFormView> createState() => GroundOfArrestFormViewState();
}

class GroundOfArrestFormViewState extends State<GroundOfArrestFormView> {
  // ══════════════════════════════════════════════════════════
  // ── PAGE 1 CONTROLLERS ──
  // ══════════════════════════════════════════════════════════
  final _outwardNoCtrl = TextEditingController();
  final _outwardYearCtrl = TextEditingController(text: '२५');
  final _policeStationCtrl = TextEditingController();
  final _talukaCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();

  final _dateDayCtrl = TextEditingController();
  final _dateMonthCtrl = TextEditingController();
  final _dateYearCtrl = TextEditingController(text: '२५');
  final _noticeDateCtrl = TextEditingController();

  String get _noticeDateCombined {
    final d = _dateDayCtrl.text.trim();
    final m = _dateMonthCtrl.text.trim();
    final y = _dateYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) {
      return _noticeDateCtrl.text.trim();
    }
    final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
    return '$d/$m/$yFull'.replaceAll(RegExp(r'/+$'), '');
  }

  // To (प्रति)
  final _accusedNameAddressCtrl = TextEditingController();
  final _accusedNameAddressLine2Ctrl = TextEditingController();

  // Subject (विषय)
  final _subjectPsCtrl = TextEditingController();
  final _subjectCrNoCtrl = TextEditingController();
  final _subjectSectionCtrl = TextEditingController();
  final _subjectBnsCtrl = TextEditingController();

  // Paragraph 1
  final _firPsCtrl = TextEditingController();
  final _firCrNoCtrl = TextEditingController();
  final _firCrYearCtrl = TextEditingController();
  final _firActSecCtrl = TextEditingController();
  final _ioNameCtrl = TextEditingController();

  // गुन्ह्यांचे संक्षिप्त विवरण
  final _briefDescriptionCtrl = TextEditingController();
  final _briefDescLine2Ctrl = TextEditingController();
  final _briefDescLine3Ctrl = TextEditingController();
  final _briefDescLine4Ctrl = TextEditingController();
  final _briefDescLine5Ctrl = TextEditingController();

  // ══════════════════════════════════════════════════════════
  // ── PAGE 2 CONTROLLERS ──
  // ══════════════════════════════════════════════════════════
  final _ground1Ctrl = TextEditingController();
  final _ground1Line2Ctrl = TextEditingController();
  final _ground2Ctrl = TextEditingController();
  final _ground2Line2Ctrl = TextEditingController();
  final _ground3Ctrl = TextEditingController();
  final _ground3Line2Ctrl = TextEditingController();
  final _ground4Ctrl = TextEditingController();
  final _ground4Line2Ctrl = TextEditingController();
  final _ground5Ctrl = TextEditingController();
  final _ground5Line2Ctrl = TextEditingController();

  // Relative info
  final _relativeNameCtrl = TextEditingController();
  final _relativeAddressCtrl = TextEditingController();
  final _relativePhoneCtrl = TextEditingController();

  // Signatures Left
  final _accusedSigCtrl = TextEditingController();
  final _accusedNameCtrl = TextEditingController();
  final _accusedDateTimeCtrl = TextEditingController();

  // Signatures Right
  final _ioSigCtrl = TextEditingController();
  final _ioNameRankCtrl = TextEditingController();
  final _ioPsCtrl = TextEditingController();
  final _ioTahCtrl = TextEditingController();
  final _ioDistCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _outwardNoCtrl,
      _outwardYearCtrl,
      _policeStationCtrl,
      _talukaCtrl,
      _districtCtrl,
      _dateDayCtrl,
      _dateMonthCtrl,
      _dateYearCtrl,
      _noticeDateCtrl,
      _accusedNameAddressCtrl,
      _accusedNameAddressLine2Ctrl,
      _subjectPsCtrl,
      _subjectCrNoCtrl,
      _subjectSectionCtrl,
      _subjectBnsCtrl,
      _firPsCtrl,
      _firCrNoCtrl,
      _firCrYearCtrl,
      _firActSecCtrl,
      _ioNameCtrl,
      _briefDescriptionCtrl,
      _briefDescLine2Ctrl,
      _briefDescLine3Ctrl,
      _briefDescLine4Ctrl,
      _briefDescLine5Ctrl,
      _ground1Ctrl,
      _ground1Line2Ctrl,
      _ground2Ctrl,
      _ground2Line2Ctrl,
      _ground3Ctrl,
      _ground3Line2Ctrl,
      _ground4Ctrl,
      _ground4Line2Ctrl,
      _ground5Ctrl,
      _ground5Line2Ctrl,
      _relativeNameCtrl,
      _relativeAddressCtrl,
      _relativePhoneCtrl,
      _accusedSigCtrl,
      _accusedNameCtrl,
      _accusedDateTimeCtrl,
      _ioSigCtrl,
      _ioNameRankCtrl,
      _ioPsCtrl,
      _ioTahCtrl,
      _ioDistCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      // Page 1
      'outwardNo': _outwardNoCtrl.text.trim(),
      'outwardYear': _outwardYearCtrl.text.trim(),
      'policeStation': _policeStationCtrl.text.trim(),
      'taluka': _talukaCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      'noticeDate': _noticeDateCombined,
      'dateDay': _dateDayCtrl.text.trim(),
      'dateMonth': _dateMonthCtrl.text.trim(),
      'dateYear': _dateYearCtrl.text.trim(),
      'accusedNameAddress': _accusedNameAddressCtrl.text.trim(),
      'accusedNameAddressLine2': _accusedNameAddressLine2Ctrl.text.trim(),
      'subjectPs': _subjectPsCtrl.text.trim(),
      'subjectCrNo': _subjectCrNoCtrl.text.trim(),
      'subjectSection': _subjectSectionCtrl.text.trim(),
      'subjectBns': _subjectBnsCtrl.text.trim(),
      'firPs': _firPsCtrl.text.trim(),
      'firCrNo': _firCrNoCtrl.text.trim(),
      'firCrYear': _firCrYearCtrl.text.trim(),
      'firActSec': _firActSecCtrl.text.trim(),
      'ioName': _ioNameCtrl.text.trim(),
      'briefDescription': _briefDescriptionCtrl.text.trim(),
      'briefDescLine2': _briefDescLine2Ctrl.text.trim(),
      'briefDescLine3': _briefDescLine3Ctrl.text.trim(),
      'briefDescLine4': _briefDescLine4Ctrl.text.trim(),
      'briefDescLine5': _briefDescLine5Ctrl.text.trim(),

      // Page 2
      'ground1': _ground1Ctrl.text.trim(),
      'ground1Line2': _ground1Line2Ctrl.text.trim(),
      'ground2': _ground2Ctrl.text.trim(),
      'ground2Line2': _ground2Line2Ctrl.text.trim(),
      'ground3': _ground3Ctrl.text.trim(),
      'ground3Line2': _ground3Line2Ctrl.text.trim(),
      'ground4': _ground4Ctrl.text.trim(),
      'ground4Line2': _ground4Line2Ctrl.text.trim(),
      'ground5': _ground5Ctrl.text.trim(),
      'ground5Line2': _ground5Line2Ctrl.text.trim(),
      'relativeName': _relativeNameCtrl.text.trim(),
      'relativeAddress': _relativeAddressCtrl.text.trim(),
      'relativePhone': _relativePhoneCtrl.text.trim(),
      'accusedSig': _accusedSigCtrl.text.trim(),
      'accusedName': _accusedNameCtrl.text.trim(),
      'accusedDateTime': _accusedDateTimeCtrl.text.trim(),
      'ioSig': _ioSigCtrl.text.trim(),
      'ioNameRank': _ioNameRankCtrl.text.trim(),
      'ioPs': _ioPsCtrl.text.trim(),
      'ioTah': _ioTahCtrl.text.trim(),
      'ioDist': _ioDistCtrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    void setCtrl(TextEditingController c, String key) {
      c.text = data[key]?.toString() ?? '';
    }

    for (final e in {
      'outwardNo': _outwardNoCtrl,
      'outwardYear': _outwardYearCtrl,
      'policeStation': _policeStationCtrl,
      'taluka': _talukaCtrl,
      'district': _districtCtrl,
      'noticeDate': _noticeDateCtrl,
      'dateDay': _dateDayCtrl,
      'dateMonth': _dateMonthCtrl,
      'dateYear': _dateYearCtrl,
      'accusedNameAddress': _accusedNameAddressCtrl,
      'accusedNameAddressLine2': _accusedNameAddressLine2Ctrl,
      'subjectPs': _subjectPsCtrl,
      'subjectCrNo': _subjectCrNoCtrl,
      'subjectSection': _subjectSectionCtrl,
      'subjectBns': _subjectBnsCtrl,
      'firPs': _firPsCtrl,
      'firCrNo': _firCrNoCtrl,
      'firCrYear': _firCrYearCtrl,
      'firActSec': _firActSecCtrl,
      'ioName': _ioNameCtrl,
      'briefDescription': _briefDescriptionCtrl,
      'briefDescLine2': _briefDescLine2Ctrl,
      'briefDescLine3': _briefDescLine3Ctrl,
      'briefDescLine4': _briefDescLine4Ctrl,
      'briefDescLine5': _briefDescLine5Ctrl,
      'ground1': _ground1Ctrl,
      'ground1Line2': _ground1Line2Ctrl,
      'ground2': _ground2Ctrl,
      'ground2Line2': _ground2Line2Ctrl,
      'ground3': _ground3Ctrl,
      'ground3Line2': _ground3Line2Ctrl,
      'ground4': _ground4Ctrl,
      'ground4Line2': _ground4Line2Ctrl,
      'ground5': _ground5Ctrl,
      'ground5Line2': _ground5Line2Ctrl,
      'relativeName': _relativeNameCtrl,
      'relativeAddress': _relativeAddressCtrl,
      'relativePhone': _relativePhoneCtrl,
      'accusedSig': _accusedSigCtrl,
      'accusedName': _accusedNameCtrl,
      'accusedDateTime': _accusedDateTimeCtrl,
      'ioSig': _ioSigCtrl,
      'ioNameRank': _ioNameRankCtrl,
      'ioPs': _ioPsCtrl,
      'ioTah': _ioTahCtrl,
      'ioDist': _ioDistCtrl,
    }.entries) {
      setCtrl(e.value, e.key);
    }

    if (_dateDayCtrl.text.isEmpty && _noticeDateCtrl.text.isNotEmpty) {
      final parts = _noticeDateCtrl.text.split(RegExp(r'[/.-]'));
      if (parts.length >= 3) {
        _dateDayCtrl.text = parts[0].trim();
        _dateMonthCtrl.text = parts[1].trim();
        var yr = parts[2].trim();
        if (yr.startsWith('20') && yr.length == 4) yr = yr.substring(2);
        _dateYearCtrl.text = yr;
      }
    }

    if (_outwardYearCtrl.text.isEmpty) _outwardYearCtrl.text = '२५';
    if (_dateYearCtrl.text.isEmpty) _dateYearCtrl.text = '२५';

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final serif = FormTypography.serifStyle();
    final marathi = FormTypography.marathiLabelStyle();

    final bodyTextStyle = marathi.copyWith(
      fontSize: 14,
      height: 2.3,
      color: Colors.black87,
    );
    final headerLabelStyle = marathi.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );
    final boldLabelStyle = marathi.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
    final serifBold = serif.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: Colors.black87,
    );

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        // ══════════════════════════════════════════════════════════
        // ── PAGE 1 (Image 1) ──
        // ══════════════════════════════════════════════════════════
        FormPaperPage(
          minHeight: 1180,
          children: [
            const SizedBox(height: 12),

            // ── TOP HEADER ──
            Center(
              child: Column(
                children: [
                  Text(
                    'भारतीय नागरीक सुरक्षा संहिता, २०२३ चे कलम ४७ (१)(२) अन्वये',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'सुचनापत्र',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── TOP RIGHT METADATA BOX ──
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('जावक.क्रमांक- ', style: headerLabelStyle),
                        Expanded(
                          child: BilingualSimpleUnderlineInput(
                            controller: _outwardNoCtrl,
                            serifStyle: serif,
                          ),
                        ),
                        Text(' /२०', style: headerLabelStyle),
                        SizedBox(
                          width: 36,
                          child: BilingualSimpleUnderlineInput(
                            controller: _outwardYearCtrl,
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
                            controller: _policeStationCtrl,
                            serifStyle: serif,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('ता.-', style: headerLabelStyle),
                        Expanded(
                          child: BilingualSimpleUnderlineInput(
                            controller: _talukaCtrl,
                            serifStyle: serif,
                          ),
                        ),
                        Text(' -जिल्हा-', style: headerLabelStyle),
                        Expanded(
                          child: BilingualSimpleUnderlineInput(
                            controller: _districtCtrl,
                            serifStyle: serif,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('दिनांक:- ', style: headerLabelStyle),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 34,
                          child: BilingualSimpleUnderlineInput(
                            controller: _dateDayCtrl,
                            serifStyle: serif,
                          ),
                        ),
                        Text('/', style: serifBold),
                        SizedBox(
                          width: 34,
                          child: BilingualSimpleUnderlineInput(
                            controller: _dateMonthCtrl,
                            serifStyle: serif,
                          ),
                        ),
                        Text('/२०', style: headerLabelStyle),
                        SizedBox(
                          width: 36,
                          child: BilingualSimpleUnderlineInput(
                            controller: _dateYearCtrl,
                            serifStyle: serif,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── RECIPIENT SECTION ──
            Text('प्रति,', style: boldLabelStyle),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('नाव व पत्ता ', style: headerLabelStyle),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _accusedNameAddressCtrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            BilingualSimpleUnderlineInput(
              controller: _accusedNameAddressLine2Ctrl,
              serifStyle: serif,
            ),
            const SizedBox(height: 24),

            // ── SUBJECT (विषय) ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 10,
              children: [
                Text('विषय:- पोलीस स्टेशन', style: boldLabelStyle),
                SizedBox(
                  width: 140,
                  child: BilingualSimpleUnderlineInput(
                    controller: _subjectPsCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('गुन्हा रजि.क्र.', style: boldLabelStyle),
                SizedBox(
                  width: 90,
                  child: BilingualSimpleUnderlineInput(
                    controller: _subjectCrNoCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('कलम', style: boldLabelStyle),
                SizedBox(
                  width: 110,
                  child: BilingualSimpleUnderlineInput(
                    controller: _subjectSectionCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('भा.न्या.स.', style: boldLabelStyle),
                Text(
                  'नुसार दाखल असलेल्या गुन्ह्यांचे अनुषंगाने आरोपीस अटक करतांना अटक करण्यासाठी आधारभूत मुद्दे आणि अटकेची कारणे कळविणे बाबत.',
                  style: bodyTextStyle,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── MAIN PARAGRAPH ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 12,
              children: [
                Text(
                  '        आपणास या सुचनापत्राद्वारे कळविण्यात येते की,आपल्या विरुद्ध पोलीस ठाणे',
                  style: bodyTextStyle,
                ),
                SizedBox(
                  width: 150,
                  child: BilingualSimpleUnderlineInput(
                    controller: _firPsCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('येथे गुन्हा रजि.क्र.', style: bodyTextStyle),
                SizedBox(
                  width: 80,
                  child: BilingualSimpleUnderlineInput(
                    controller: _firCrNoCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('/', style: serifBold),
                SizedBox(
                  width: 36,
                  child: BilingualSimpleUnderlineInput(
                    controller: _firCrYearCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('कलम', style: bodyTextStyle),
                SizedBox(
                  width: 130,
                  child: BilingualSimpleUnderlineInput(
                    controller: _firActSecCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(
                  'भारतीय न्याय संहिता २०२३ अन्वये गुन्हा नोंद करण्यात आला असुन, आम्ही',
                  style: bodyTextStyle,
                ),
                SizedBox(
                  width: 200,
                  child: BilingualSimpleUnderlineInput(
                    controller: _ioNameCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(
                  'तपासी अधिकारी म्हणून सदर गुन्ह्यांचा तपास करीत आहोत.सदर गुन्ह्यांचे तपासकामी आपणास अटक करणे गरजेचे असून भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ४७ (१)(२) नुसार आपणास अटक करण्यासाठी आधारभूत मुद्दे (भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ४७ (१)(२) नुसार ) खालील प्रमाणे आहेत.',
                  style: bodyTextStyle,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── गुन्ह्यांचे संक्षीप्त विवरण ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('गुन्ह्यांचे संक्षीप्त विवरण :-', style: boldLabelStyle),
                const SizedBox(width: 8),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _briefDescriptionCtrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            BilingualSimpleUnderlineInput(
              controller: _briefDescLine2Ctrl,
              serifStyle: serif,
            ),
            const SizedBox(height: 8),
            BilingualSimpleUnderlineInput(
              controller: _briefDescLine3Ctrl,
              serifStyle: serif,
            ),
            const SizedBox(height: 8),
            BilingualSimpleUnderlineInput(
              controller: _briefDescLine4Ctrl,
              serifStyle: serif,
            ),
            const SizedBox(height: 8),
            BilingualSimpleUnderlineInput(
              controller: _briefDescLine5Ctrl,
              serifStyle: serif,
            ),
            const SizedBox(height: 24),

            // ── NOTE & PAGE 2 INDICATOR ──
            Text(
              '(अधिक माहितीसाठी फिर्यादीची प्रत सोबत जोडली आहे)',
              style: bodyTextStyle.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '२..',
                style: boldLabelStyle.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),

        // ══════════════════════════════════════════════════════════
        // ── SPACING BETWEEN PAGES ──
        // ══════════════════════════════════════════════════════════
        const SizedBox(height: 56),

        // ══════════════════════════════════════════════════════════
        // ── PAGE 2 (Image 2) ──
        // ══════════════════════════════════════════════════════════
        FormPaperPage(
          minHeight: 1180,
          children: [
            const SizedBox(height: 12),

            // ── TOP CONTINUATION INDICATOR ──
            Center(
              child: Text(
                '..२..',
                style: boldLabelStyle.copyWith(fontSize: 15),
              ),
            ),
            const SizedBox(height: 18),

            // ── GROUNDS OF ARREST HEADER ──
            Center(
              child: Text(
                'अटक करण्यासाठी आधारभूत मुद्दे (GROUNDS OF ARREST)',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),

            // ── GROUNDS 1 TO 5 ──
            // Ground 1
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('१. ', style: boldLabelStyle),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _ground1Ctrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: BilingualSimpleUnderlineInput(
                controller: _ground1Line2Ctrl,
                serifStyle: serif,
              ),
            ),
            const SizedBox(height: 14),

            // Ground 2
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('२. ', style: boldLabelStyle),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _ground2Ctrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: BilingualSimpleUnderlineInput(
                controller: _ground2Line2Ctrl,
                serifStyle: serif,
              ),
            ),
            const SizedBox(height: 14),

            // Ground 3
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('३. ', style: boldLabelStyle),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _ground3Ctrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: BilingualSimpleUnderlineInput(
                controller: _ground3Line2Ctrl,
                serifStyle: serif,
              ),
            ),
            const SizedBox(height: 14),

            // Ground 4
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('४. ', style: boldLabelStyle),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _ground4Ctrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: BilingualSimpleUnderlineInput(
                controller: _ground4Line2Ctrl,
                serifStyle: serif,
              ),
            ),
            const SizedBox(height: 14),

            // Ground 5
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('५. ', style: boldLabelStyle),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _ground5Ctrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: BilingualSimpleUnderlineInput(
                controller: _ground5Line2Ctrl,
                serifStyle: serif,
              ),
            ),
            const SizedBox(height: 28),

            // ── PARAGRAPH 1 (Bail inform) ──
            Text(
              '        आपणास असेही कळविण्यात येते की, नमुद गुन्हा हा दखलपात्र असुन अजामीनपात्र आहे आणि त्यामुळे आपण त्या गुन्ह्यात न्यायालयात जामिनाचा अर्ज सादर करुन न्यायालयाचे आदेशाने जामिनावर मुक्त होवु शकता.',
              style: bodyTextStyle,
            ),
            const SizedBox(height: 20),

            // ── PARAGRAPH 2 (Relative inform) ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 10,
              children: [
                Text(
                  '        आपल्या अटकेची माहीती आपले नातेवाईक/ मित्र',
                  style: bodyTextStyle,
                ),
                SizedBox(
                  width: 180,
                  child: BilingualSimpleUnderlineInput(
                    controller: _relativeNameCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('रा.', style: bodyTextStyle),
                SizedBox(
                  width: 150,
                  child: BilingualSimpleUnderlineInput(
                    controller: _relativeAddressCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('यांना लेखी सुचनेद्वारे/फोन क्रमांक', style: bodyTextStyle),
                SizedBox(
                  width: 140,
                  child: BilingualSimpleUnderlineInput(
                    controller: _relativePhoneCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(
                  'यावर संपर्क करुन देण्यांत आली आहे.',
                  style: bodyTextStyle,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── PARAGRAPH 3 (Closing) ──
            Text(
              '        याकरीता आपणास सुचनापत्र देण्यांत येत आहे.',
              style: bodyTextStyle,
            ),
            const SizedBox(height: 48),

            // ── SIGNATURES (2 COLUMNS) ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column (Accused Receipt)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('मला सुचनापत्र प्राप्त झाले', style: boldLabelStyle),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('(आरोपीची सही', style: headerLabelStyle),
                          const SizedBox(width: 4),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _accusedSigCtrl,
                              serifStyle: serif,
                            ),
                          ),
                          Text(')', style: headerLabelStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text('आरोपीचे नांव ', style: headerLabelStyle),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _accusedNameCtrl,
                              serifStyle: serif,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text('दिनांक:व वेळ ', style: headerLabelStyle),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _accusedDateTimeCtrl,
                              serifStyle: serif,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),

                // Right Column (IO Signature)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('तपास अधि सही/-', style: boldLabelStyle),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('नाव/हुद्दा ', style: headerLabelStyle),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _ioNameRankCtrl,
                              serifStyle: serif,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text('पोलीस स्टेशन ', style: headerLabelStyle),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _ioPsCtrl,
                              serifStyle: serif,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text('ता.-', style: headerLabelStyle),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _ioTahCtrl,
                              serifStyle: serif,
                            ),
                          ),
                          Text(' जिल्हा-', style: headerLabelStyle),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _ioDistCtrl,
                              serifStyle: serif,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
