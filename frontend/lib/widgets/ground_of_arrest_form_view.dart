import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';
import 'form_date_pickers.dart';

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
  final _dateYearCtrl = TextEditingController();
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
  final _accusedDateTimeCtrl = TextEditingController(); // acts as Date
  final _accusedTimeCtrl = TextEditingController();

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
      'accusedDateTime':
          '${_accusedDateTimeCtrl.text.trim()} ${_accusedTimeCtrl.text.trim()}'
              .trim(),
      'accusedDateOnly': _accusedDateTimeCtrl.text.trim(),
      'accusedTimeOnly': _accusedTimeCtrl.text.trim(),
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
      'accusedDateOnly': _accusedDateTimeCtrl,
      'accusedTimeOnly': _accusedTimeCtrl,
      'ioSig': _ioSigCtrl,
      'ioNameRank': _ioNameRankCtrl,
      'ioPs': _ioPsCtrl,
      'ioTah': _ioTahCtrl,
      'ioDist': _ioDistCtrl,
    }.entries) {
      setCtrl(e.value, e.key);
    }

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
                        BilingualSimpleUnderlineInput(
                          minWidth: 36,
                          controller: _outwardYearCtrl,
                          serifStyle: serif,
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('दिनांक:- ', style: headerLabelStyle),
                        const SizedBox(width: 4),
                        formDatePickerField(
                          context,
                          controller: _noticeDateCtrl,
                          width: 140,
                          readOnly: widget.readOnly,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text('नाव व पत्ता ', style: headerLabelStyle),
                ),
                Expanded(
                  child: GroundLinedMultilineInput(
                    controller: _accusedNameAddressCtrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            AnimatedBuilder(
              animation: _accusedNameAddressLine2Ctrl,
              builder: (context, _) {
                if (_accusedNameAddressLine2Ctrl.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: GroundLinedMultilineInput(
                    controller: _accusedNameAddressLine2Ctrl,
                    serifStyle: serif,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── SUBJECT (विषय) ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 10,
              children: [
                Text('विषय:- पोलीस स्टेशन', style: boldLabelStyle),
                GroundLinedMultilineInput(
                  minWidth: 140,
                  controller: _subjectPsCtrl,
                  serifStyle: serif,
                ),
                Text('गुन्हा रजि.क्र.', style: boldLabelStyle),
                BilingualSimpleUnderlineInput(
                  minWidth: 90,
                  controller: _subjectCrNoCtrl,
                  serifStyle: serif,
                ),
                Text('कलम', style: boldLabelStyle),
                BilingualSimpleUnderlineInput(
                  minWidth: 110,
                  controller: _subjectSectionCtrl,
                  serifStyle: serif,
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
                GroundLinedMultilineInput(
                  minWidth: 150,
                  controller: _firPsCtrl,
                  serifStyle: serif,
                ),
                Text('येथे गुन्हा रजि.क्र.', style: bodyTextStyle),
                BilingualSimpleUnderlineInput(
                  minWidth: 80,
                  controller: _firCrNoCtrl,
                  serifStyle: serif,
                ),
                Text('/', style: serifBold),
                BilingualSimpleUnderlineInput(
                  minWidth: 36,
                  controller: _firCrYearCtrl,
                  serifStyle: serif,
                ),
                Text('कलम', style: bodyTextStyle),
                BilingualSimpleUnderlineInput(
                  minWidth: 130,
                  controller: _firActSecCtrl,
                  serifStyle: serif,
                ),
                Text(
                  'भारतीय न्याय संहिता २०२३ अन्वये गुन्हा नोंद करण्यात आला असुन, आम्ही',
                  style: bodyTextStyle,
                ),
                GroundLinedMultilineInput(
                  minWidth: 200,
                  controller: _ioNameCtrl,
                  serifStyle: serif,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text('गुन्ह्यांचे संक्षीप्त विवरण :-',
                      style: boldLabelStyle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GroundLinedMultilineInput(
                    controller: _briefDescriptionCtrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            AnimatedBuilder(
              animation: Listenable.merge([
                _briefDescLine2Ctrl,
                _briefDescLine3Ctrl,
                _briefDescLine4Ctrl,
                _briefDescLine5Ctrl,
              ]),
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_briefDescLine2Ctrl.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      GroundLinedMultilineInput(
                        controller: _briefDescLine2Ctrl,
                        serifStyle: serif,
                      ),
                    ],
                    if (_briefDescLine3Ctrl.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      GroundLinedMultilineInput(
                        controller: _briefDescLine3Ctrl,
                        serifStyle: serif,
                      ),
                    ],
                    if (_briefDescLine4Ctrl.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      GroundLinedMultilineInput(
                        controller: _briefDescLine4Ctrl,
                        serifStyle: serif,
                      ),
                    ],
                    if (_briefDescLine5Ctrl.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      GroundLinedMultilineInput(
                        controller: _briefDescLine5Ctrl,
                        serifStyle: serif,
                      ),
                    ],
                  ],
                );
              },
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text('१. ', style: boldLabelStyle),
                ),
                Expanded(
                  child: GroundLinedMultilineInput(
                    controller: _ground1Ctrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            AnimatedBuilder(
              animation: _ground1Line2Ctrl,
              builder: (context, _) {
                if (_ground1Line2Ctrl.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 20, top: 6),
                  child: GroundLinedMultilineInput(
                    controller: _ground1Line2Ctrl,
                    serifStyle: serif,
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Ground 2
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text('२. ', style: boldLabelStyle),
                ),
                Expanded(
                  child: GroundLinedMultilineInput(
                    controller: _ground2Ctrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            AnimatedBuilder(
              animation: _ground2Line2Ctrl,
              builder: (context, _) {
                if (_ground2Line2Ctrl.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 20, top: 6),
                  child: GroundLinedMultilineInput(
                    controller: _ground2Line2Ctrl,
                    serifStyle: serif,
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Ground 3
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text('३. ', style: boldLabelStyle),
                ),
                Expanded(
                  child: GroundLinedMultilineInput(
                    controller: _ground3Ctrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            AnimatedBuilder(
              animation: _ground3Line2Ctrl,
              builder: (context, _) {
                if (_ground3Line2Ctrl.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 20, top: 6),
                  child: GroundLinedMultilineInput(
                    controller: _ground3Line2Ctrl,
                    serifStyle: serif,
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Ground 4
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text('४. ', style: boldLabelStyle),
                ),
                Expanded(
                  child: GroundLinedMultilineInput(
                    controller: _ground4Ctrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            AnimatedBuilder(
              animation: _ground4Line2Ctrl,
              builder: (context, _) {
                if (_ground4Line2Ctrl.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 20, top: 6),
                  child: GroundLinedMultilineInput(
                    controller: _ground4Line2Ctrl,
                    serifStyle: serif,
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Ground 5
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text('५. ', style: boldLabelStyle),
                ),
                Expanded(
                  child: GroundLinedMultilineInput(
                    controller: _ground5Ctrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            AnimatedBuilder(
              animation: _ground5Line2Ctrl,
              builder: (context, _) {
                if (_ground5Line2Ctrl.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 20, top: 6),
                  child: GroundLinedMultilineInput(
                    controller: _ground5Line2Ctrl,
                    serifStyle: serif,
                  ),
                );
              },
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
                BilingualSimpleUnderlineInput(
                  minWidth: 180,
                  controller: _relativeNameCtrl,
                  serifStyle: serif,
                ),
                Text('रा.', style: bodyTextStyle),
                BilingualSimpleUnderlineInput(
                  minWidth: 150,
                  controller: _relativeAddressCtrl,
                  serifStyle: serif,
                ),
                Text('यांना लेखी सुचनेद्वारे/फोन क्रमांक',
                    style: bodyTextStyle),
                BilingualSimpleUnderlineInput(
                  minWidth: 140,
                  controller: _relativePhoneCtrl,
                  serifStyle: serif,
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
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          Text('दिनांक:व वेळ ', style: headerLabelStyle),
                          formDatePickerField(
                            context,
                            controller: _accusedDateTimeCtrl,
                            width: 120,
                            readOnly: widget.readOnly,
                          ),
                          formTimePickerField(
                            context,
                            controller: _accusedTimeCtrl,
                            width: 95,
                            readOnly: widget.readOnly,
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

class GroundLinedMultilineInput extends StatefulWidget {
  final TextEditingController? controller;
  final TextStyle serifStyle;
  final String? hintText;
  final double minWidth;
  final int minLines;
  final double lineHeight;

  const GroundLinedMultilineInput({
    super.key,
    this.controller,
    required this.serifStyle,
    this.hintText,
    this.minWidth = 50,
    this.minLines = 1,
    this.lineHeight = 26.0,
  });

  @override
  State<GroundLinedMultilineInput> createState() =>
      _GroundLinedMultilineInputState();
}

class _GroundLinedMultilineInputState extends State<GroundLinedMultilineInput> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListenableBuilder(
          listenable: widget.controller ?? ValueNotifier(''),
          builder: (context, _) {
            final text = widget.controller?.text ?? '';

            // Calculate width:
            // When constraints.maxWidth is finite (e.g. inside Expanded), take full available width.
            // When unbounded (e.g. inside Wrap), measure single-line text and clamp between minWidth and 650.
            double effectiveWidth = widget.minWidth;
            if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
              effectiveWidth = constraints.maxWidth;
            } else {
              if (text.isNotEmpty) {
                final tp = TextPainter(
                  text: TextSpan(
                    text: text,
                    style: widget.serifStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                )..layout(minWidth: 0, maxWidth: double.infinity);
                final calculatedWidth = tp.size.width + 16.0;
                effectiveWidth = calculatedWidth > widget.minWidth
                    ? calculatedWidth.clamp(widget.minWidth, 650.0)
                    : widget.minWidth;
              }
            }

            int lineCount = widget.minLines;
            if (text.isNotEmpty && effectiveWidth > 0) {
              final tp = TextPainter(
                text: TextSpan(
                  text: text,
                  style: widget.serifStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                textDirection: TextDirection.ltr,
                maxLines: null,
              )..layout(maxWidth: effectiveWidth);
              final metrics = tp.computeLineMetrics();
              if (metrics.length > lineCount) {
                lineCount = metrics.length;
              }
            }

            final totalHeight = lineCount * widget.lineHeight;

            final lineColor =
                _isFocused ? Colors.black87 : const Color(0x8A000000);
            final strokeWidth = _isFocused ? 1.2 : 0.8;

            return CustomPaint(
              painter: _GroundFormLinedPainter(
                lineCount: lineCount,
                lineHeight: widget.lineHeight,
                lineColor: lineColor,
                strokeWidth: strokeWidth,
              ),
              child: SizedBox(
                width: constraints.maxWidth.isFinite
                    ? double.infinity
                    : effectiveWidth,
                height: totalHeight,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: false,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  child: TextField(
                    focusNode: _focusNode,
                    controller: widget.controller,
                    minLines: 1,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    cursorColor: Colors.black87,
                    strutStyle: StrutStyle(
                      fontSize: 14.0,
                      height: widget.lineHeight / 14.0,
                      forceStrutHeight: true,
                    ),
                    style: widget.serifStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: widget.lineHeight / 14.0,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.only(bottom: 3, top: 0),
                      hintText: widget.hintText,
                      hintStyle: widget.serifStyle.copyWith(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GroundFormLinedPainter extends CustomPainter {
  final int lineCount;
  final double lineHeight;
  final Color lineColor;
  final double strokeWidth;

  _GroundFormLinedPainter({
    required this.lineCount,
    required this.lineHeight,
    required this.lineColor,
    this.strokeWidth = 0.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= lineCount; i++) {
      final y = i * lineHeight - 1.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GroundFormLinedPainter oldDelegate) {
    return oldDelegate.lineCount != lineCount ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
