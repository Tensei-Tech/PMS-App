import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'form_paper_page.dart';
import 'form_view_scaffold.dart';

/// Ground of Arrest Notice u/s 47(1)(2) BNSS — Standard A4 Full-Size Paper View
class GroundOfArrestFormView extends StatefulWidget {
  final dynamic existingRecord;
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const GroundOfArrestFormView({
    super.key,
    this.existingRecord,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<GroundOfArrestFormView> createState() => GroundOfArrestFormViewState();
}

class GroundOfArrestFormViewState extends State<GroundOfArrestFormView> {
  // ── Page 1 Controllers ──
  final _outwardNoCtrl = TextEditingController();
  final _policeStationCtrl = TextEditingController();
  final _talukaCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _noticeDateDayCtrl = TextEditingController();
  final _noticeDateMonthCtrl = TextEditingController();
  final _accusedNameAddressCtrl = TextEditingController();
  final _subjectPsCtrl = TextEditingController();
  final _subjectCrNoCtrl = TextEditingController();
  final _subjectSectionCtrl = TextEditingController();
  final _noticePsCtrl = TextEditingController();
  final _noticeCrNoCtrl = TextEditingController();
  final _noticeCrYearCtrl = TextEditingController();
  final _noticeSectionCtrl = TextEditingController();
  final _ioNameCtrl = TextEditingController();
  final _offenceSummaryCtrl = TextEditingController();

  // ── Page 2 Controllers ──
  final _ground1Ctrl = TextEditingController();
  final _ground2Ctrl = TextEditingController();
  final _ground3Ctrl = TextEditingController();
  final _ground4Ctrl = TextEditingController();
  final _ground5Ctrl = TextEditingController();
  final _relativeNameCtrl = TextEditingController();
  final _relativeResidingCtrl = TextEditingController();
  final _relativePhoneCtrl = TextEditingController();
  final _accusedSigCtrl = TextEditingController();
  final _accusedNameCtrl = TextEditingController();
  final _accusedDateTimeCtrl = TextEditingController();
  final _ioSigCtrl = TextEditingController();
  final _ioNameRankCtrl = TextEditingController();
  final _ioPsCtrl = TextEditingController();
  final _ioTalukaCtrl = TextEditingController();
  final _ioDistrictCtrl = TextEditingController();

  bool get _showPage1 {
    final s = widget.formSection?.toLowerCase() ?? '';
    if (s.isEmpty) return true;
    return s.contains('main') || s.contains('page 1') || s.contains('1');
  }

  bool get _showPage2 {
    final s = widget.formSection?.toLowerCase() ?? '';
    if (s.isEmpty) return true;
    return s.contains('continuation') || s.contains('page 2') || s.contains('2');
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null && widget.existingRecord is Map) {
      hydrateFrom(Map<String, dynamic>.from(widget.existingRecord as Map));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _outwardNoCtrl,
      _policeStationCtrl,
      _talukaCtrl,
      _districtCtrl,
      _noticeDateDayCtrl,
      _noticeDateMonthCtrl,
      _accusedNameAddressCtrl,
      _subjectPsCtrl,
      _subjectCrNoCtrl,
      _subjectSectionCtrl,
      _noticePsCtrl,
      _noticeCrNoCtrl,
      _noticeCrYearCtrl,
      _noticeSectionCtrl,
      _ioNameCtrl,
      _offenceSummaryCtrl,
      _ground1Ctrl,
      _ground2Ctrl,
      _ground3Ctrl,
      _ground4Ctrl,
      _ground5Ctrl,
      _relativeNameCtrl,
      _relativeResidingCtrl,
      _relativePhoneCtrl,
      _accusedSigCtrl,
      _accusedNameCtrl,
      _accusedDateTimeCtrl,
      _ioSigCtrl,
      _ioNameRankCtrl,
      _ioPsCtrl,
      _ioTalukaCtrl,
      _ioDistrictCtrl,
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
      'policeStation': _policeStationCtrl.text.trim(),
      'taluka': _talukaCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      'noticeDateDay': _noticeDateDayCtrl.text.trim(),
      'noticeDateMonth': _noticeDateMonthCtrl.text.trim(),
      'accusedNameAddress': _accusedNameAddressCtrl.text.trim(),
      'subjectPs': _subjectPsCtrl.text.trim(),
      'subjectCrNo': _subjectCrNoCtrl.text.trim(),
      'subjectSection': _subjectSectionCtrl.text.trim(),
      'noticePs': _noticePsCtrl.text.trim(),
      'noticeCrNo': _noticeCrNoCtrl.text.trim(),
      'noticeCrYear': _noticeCrYearCtrl.text.trim(),
      'noticeSection': _noticeSectionCtrl.text.trim(),
      'ioName': _ioNameCtrl.text.trim(),
      'offenceSummary': _offenceSummaryCtrl.text.trim(),
      'briefDescription': _offenceSummaryCtrl.text.trim(),
      // Page 2
      'ground1': _ground1Ctrl.text.trim(),
      'ground2': _ground2Ctrl.text.trim(),
      'ground3': _ground3Ctrl.text.trim(),
      'ground4': _ground4Ctrl.text.trim(),
      'ground5': _ground5Ctrl.text.trim(),
      'relativeName': _relativeNameCtrl.text.trim(),
      'relativeResiding': _relativeResidingCtrl.text.trim(),
      'relativePhone': _relativePhoneCtrl.text.trim(),
      'accusedSig': _accusedSigCtrl.text.trim(),
      'accusedName': _accusedNameCtrl.text.trim(),
      'accusedDateTime': _accusedDateTimeCtrl.text.trim(),
      'ioSig': _ioSigCtrl.text.trim(),
      'ioNameRank': _ioNameRankCtrl.text.trim(),
      'ioPs': _ioPsCtrl.text.trim(),
      'ioTaluka': _ioTalukaCtrl.text.trim(),
      'ioDistrict': _ioDistrictCtrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    setState(() {
      _outwardNoCtrl.text = data['outwardNo']?.toString() ?? '';
      _policeStationCtrl.text = data['policeStation']?.toString() ?? '';
      _talukaCtrl.text = data['taluka']?.toString() ?? '';
      _districtCtrl.text = data['district']?.toString() ?? '';
      _noticeDateDayCtrl.text = data['noticeDateDay']?.toString() ?? '';
      _noticeDateMonthCtrl.text = data['noticeDateMonth']?.toString() ?? '';
      _accusedNameAddressCtrl.text = data['accusedNameAddress']?.toString() ?? '';
      _subjectPsCtrl.text = data['subjectPs']?.toString() ?? '';
      _subjectCrNoCtrl.text = data['subjectCrNo']?.toString() ?? '';
      _subjectSectionCtrl.text = data['subjectSection']?.toString() ?? '';
      _noticePsCtrl.text = data['noticePs']?.toString() ?? data['policeStation']?.toString() ?? '';
      _noticeCrNoCtrl.text = data['noticeCrNo']?.toString() ?? data['subjectCrNo']?.toString() ?? '';
      _noticeCrYearCtrl.text = data['noticeCrYear']?.toString() ?? '';
      _noticeSectionCtrl.text = data['noticeSection']?.toString() ?? data['subjectSection']?.toString() ?? '';
      _ioNameCtrl.text = data['ioName']?.toString() ?? '';
      _offenceSummaryCtrl.text = data['offenceSummary']?.toString() ?? data['briefDescription']?.toString() ?? '';

      _ground1Ctrl.text = data['ground1']?.toString() ?? '';
      _ground2Ctrl.text = data['ground2']?.toString() ?? '';
      _ground3Ctrl.text = data['ground3']?.toString() ?? '';
      _ground4Ctrl.text = data['ground4']?.toString() ?? '';
      _ground5Ctrl.text = data['ground5']?.toString() ?? '';
      _relativeNameCtrl.text = data['relativeName']?.toString() ?? '';
      _relativeResidingCtrl.text = data['relativeResiding']?.toString() ?? data['relativeAddress']?.toString() ?? '';
      _relativePhoneCtrl.text = data['relativePhone']?.toString() ?? '';
      _accusedSigCtrl.text = data['accusedSig']?.toString() ?? '';
      _accusedNameCtrl.text = data['accusedName']?.toString() ?? data['accusedNameSig']?.toString() ?? '';
      _accusedDateTimeCtrl.text = data['accusedDateTime']?.toString() ?? '';
      _ioSigCtrl.text = data['ioSig']?.toString() ?? '';
      _ioNameRankCtrl.text = data['ioNameRank']?.toString() ?? '';
      _ioPsCtrl.text = data['ioPs']?.toString() ?? data['policeStation']?.toString() ?? '';
      _ioTalukaCtrl.text = data['ioTaluka']?.toString() ?? data['taluka']?.toString() ?? '';
      _ioDistrictCtrl.text = data['ioDistrict']?.toString() ?? data['district']?.toString() ?? '';
    });
  }

  // ── Helper Widgets for Clean Paper Input ──

  Widget _inlineBlank({
    required TextEditingController controller,
    required TextStyle style,
    double? width,
    bool readOnly = false,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        readOnly: widget.readOnly || readOnly,
        style: style.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: const Color(0xFF0D47A1),
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF333333), width: 1.2),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF1976D2), width: 2.0),
          ),
        ),
      ),
    );
  }

  Widget _multilineBlankBox({
    required TextEditingController controller,
    required TextStyle style,
    int minLines = 3,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: widget.readOnly,
      minLines: minLines,
      maxLines: null,
      style: style.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 15,
        height: 1.5,
        color: const Color(0xFF0D47A1),
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1976D2), width: 2.0),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1 — Exactly matching Image 1
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPage1(TextStyle mrStyle) {
    return FormPaperPage(
      formLabel: widget.pageRange ?? 'Page 1',
      children: [
        // ── Main Centered Header ──
        Center(
          child: Column(
            children: [
              Text(
                'भारतीय नागरीक सुरक्षा संहिता, २०२३ चे कलम ४७ (१)(२) अन्वये',
                textAlign: TextAlign.center,
                style: mrStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'सुचनापत्र',
                textAlign: TextAlign.center,
                style: mrStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Top Right Reference Details ──
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('जावक.क्रमांक- ', style: mrStyle.copyWith(fontSize: 15)),
                    Expanded(
                      child: _inlineBlank(
                        controller: _outwardNoCtrl,
                        style: mrStyle,
                      ),
                    ),
                    Text(' / २०२५', style: mrStyle.copyWith(fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('पोलीस स्टेशन - ', style: mrStyle.copyWith(fontSize: 15)),
                    Expanded(
                      child: _inlineBlank(
                        controller: _policeStationCtrl,
                        style: mrStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('ता.- ', style: mrStyle.copyWith(fontSize: 15)),
                    _inlineBlank(
                      controller: _talukaCtrl,
                      style: mrStyle,
                      width: 100,
                    ),
                    Text(' -जिल्हा- ', style: mrStyle.copyWith(fontSize: 15)),
                    Expanded(
                      child: _inlineBlank(
                        controller: _districtCtrl,
                        style: mrStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('दिनांक:- ', style: mrStyle.copyWith(fontSize: 15)),
                    _inlineBlank(
                      controller: _noticeDateDayCtrl,
                      style: mrStyle,
                      width: 45,
                    ),
                    Text(' / ', style: mrStyle.copyWith(fontSize: 15)),
                    _inlineBlank(
                      controller: _noticeDateMonthCtrl,
                      style: mrStyle,
                      width: 45,
                    ),
                    Text(' / २०२५', style: mrStyle.copyWith(fontSize: 15)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── To / Name & Address Block (प्रति, नाव व पत्ता) ──
        Text('प्रति,', style: mrStyle.copyWith(fontSize: 15.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('नाव व पत्ता ', style: mrStyle.copyWith(fontSize: 15)),
            Expanded(
              child: _inlineBlank(
                controller: _accusedNameAddressCtrl,
                style: mrStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // ── Subject Paragraph (विषय) ──
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 10,
          children: [
            Text(
              'विषय:- पोलीस स्टेशन',
              style: mrStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            _inlineBlank(
              controller: _subjectPsCtrl,
              style: mrStyle,
              width: 150,
            ),
            Text(
              'गुन्हा रजि.क्र.-',
              style: mrStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            _inlineBlank(
              controller: _subjectCrNoCtrl,
              style: mrStyle,
              width: 90,
            ),
            Text(
              '-कलम',
              style: mrStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            _inlineBlank(
              controller: _subjectSectionCtrl,
              style: mrStyle,
              width: 130,
            ),
            Text(
              'भा.न्या.स.',
              style: mrStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              'नुसार दाखल असलेल्या गुन्ह्यांचे अनुषंगाने आरोपीस अटक करतांना अटक',
              style: mrStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              'करण्यासाठी आधारभूत मुद्दे आणि अटकेची कारणे कळविणे बाबत.',
              style: mrStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // ── Main Body Paragraph with Inlines ──
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 10,
          children: [
            Text(
              'आपणास या सुचनापत्राद्वारे कळविण्यात येते की,आपल्या विरुध्द पोलीस ठाणे',
              style: mrStyle.copyWith(fontSize: 15, height: 1.6),
            ),
            _inlineBlank(
              controller: _noticePsCtrl,
              style: mrStyle,
              width: 200,
            ),
            Text(
              'येथे गुन्हा रजि.क्र.-',
              style: mrStyle.copyWith(fontSize: 15),
            ),
            _inlineBlank(
              controller: _noticeCrNoCtrl,
              style: mrStyle,
              width: 80,
            ),
            Text(
              '/',
              style: mrStyle.copyWith(fontSize: 15),
            ),
            _inlineBlank(
              controller: _noticeCrYearCtrl,
              style: mrStyle,
              width: 55,
            ),
            Text(
              'कलम',
              style: mrStyle.copyWith(fontSize: 15),
            ),
            _inlineBlank(
              controller: _noticeSectionCtrl,
              style: mrStyle,
              width: 150,
            ),
            Text(
              'भारतीय न्याय संहीता २०२३ अन्वये गुन्हा नोंद करण्यात आला असुन,आम्ही-',
              style: mrStyle.copyWith(fontSize: 15),
            ),
            _inlineBlank(
              controller: _ioNameCtrl,
              style: mrStyle,
              width: 220,
            ),
            Text(
              'तपासी अधिकारी म्हणून सदर गुन्हयांचा तपास करीत आहोत.सदर गुन्हयांचे तपासकामी आपणास अटक करणे गरजेचे असून भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ४७ (१)(२) नुसार आपणास अटक करण्यासाठी आधारभूत मुद्दे (भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ४७ (१)(२) नुसार ) खालील प्रमाणे आहेत.',
              style: mrStyle.copyWith(fontSize: 15, height: 1.6),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Brief Description of Offence (गुन्हयांचे संक्षीप्त विवरण) ──
        Text(
          'गुन्हयांचे संक्षीप्त विवरण :-',
          style: mrStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 15.5,
          ),
        ),
        const SizedBox(height: 8),
        _multilineBlankBox(
          controller: _offenceSummaryCtrl,
          style: mrStyle,
          minLines: 5,
        ),
        const SizedBox(height: 24),

        // ── Page 1 Bottom Notes ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '(अधिक माहितीसाठी फिर्यादीची प्रत सोबत जोडली आहे)',
              style: mrStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '२..',
              style: mrStyle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 2 — Exactly matching Image 2
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPage2(TextStyle mrStyle) {
    return FormPaperPage(
      formLabel: widget.pageRange ?? 'Page 2',
      children: [
        // ── Top Center Page Indicator & Header ──
        Center(
          child: Column(
            children: [
              Text(
                '..२..',
                style: mrStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'अटक करण्यासाठी आधारभूत मुद्दे (GROUNDS OF ARREST)',
                textAlign: TextAlign.center,
                style: mrStyle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Grounds 1 to 5 with Numbered Multi-line Inputs ──
        for (final item in [
          ('१.', _ground1Ctrl),
          ('२.', _ground2Ctrl),
          ('३.', _ground3Ctrl),
          ('४.', _ground4Ctrl),
          ('५.', _ground5Ctrl),
        ]) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: Text(
                    item.$1,
                    style: mrStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                    ),
                  ),
                ),
                Expanded(
                  child: _multilineBlankBox(
                    controller: item.$2,
                    style: mrStyle,
                    minLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // ── Bail Rights Notice Paragraph ──
        Text(
          'आपणास असेही कळविण्यांत येते की, नमुद गुन्हा हा दखलपात्र असुन अजामीनपात्र आहे आणि त्यामुळे आपण त्या गुन्हयात न्यायालयात जामिनाचा अर्ज सादर करुन न्यायालयाचे आदेशाने जामिनावर मुक्त होवु शकता.',
          style: mrStyle.copyWith(
            fontSize: 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 18),

        // ── Relative / Friend Intimation Paragraph ──
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 10,
          children: [
            Text(
              'आपल्या अटकेची माहीती आपले नातेवाईक/ मित्र',
              style: mrStyle.copyWith(fontSize: 15),
            ),
            _inlineBlank(
              controller: _relativeNameCtrl,
              style: mrStyle,
              width: 180,
            ),
            Text(
              'रा.',
              style: mrStyle.copyWith(fontSize: 15),
            ),
            _inlineBlank(
              controller: _relativeResidingCtrl,
              style: mrStyle,
              width: 120,
            ),
            Text(
              'यांना लेखी सुचनेव्दारे/फोन क्रमांक',
              style: mrStyle.copyWith(fontSize: 15),
            ),
            _inlineBlank(
              controller: _relativePhoneCtrl,
              style: mrStyle,
              width: 150,
            ),
            Text(
              'यावर संपर्क करुन देण्यांत आली आहे.',
              style: mrStyle.copyWith(fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Closing line ──
        Text(
          'याकरीता आपणास सुचनापत्र देण्यांत येत आहे.',
          style: mrStyle.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 32),

        // ── Signatures 2-Column Block ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Accused Sign / Receipt
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'मला सुचनापत्र प्राप्त झाले',
                    style: mrStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('(आरोपीची सही ', style: mrStyle.copyWith(fontSize: 14.5)),
                      Expanded(
                        child: _inlineBlank(
                          controller: _accusedSigCtrl,
                          style: mrStyle,
                        ),
                      ),
                      Text(')', style: mrStyle.copyWith(fontSize: 14.5)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('आरोपीचे नांव ', style: mrStyle.copyWith(fontSize: 14.5)),
                      Expanded(
                        child: _inlineBlank(
                          controller: _accusedNameCtrl,
                          style: mrStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('दिनांक:व वेळ ', style: mrStyle.copyWith(fontSize: 14.5)),
                      Expanded(
                        child: _inlineBlank(
                          controller: _accusedDateTimeCtrl,
                          style: mrStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),

            // Right Column: Investigating Officer Sign & Station
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'तपास अधि सही/-',
                    style: mrStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('नाव/हुद्दा ', style: mrStyle.copyWith(fontSize: 14.5)),
                      Expanded(
                        child: _inlineBlank(
                          controller: _ioNameRankCtrl,
                          style: mrStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('पोलीस स्टेशन ', style: mrStyle.copyWith(fontSize: 14.5)),
                      Expanded(
                        child: _inlineBlank(
                          controller: _ioPsCtrl,
                          style: mrStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('ता.- ', style: mrStyle.copyWith(fontSize: 14.5)),
                      _inlineBlank(
                        controller: _ioTalukaCtrl,
                        style: mrStyle,
                        width: 85,
                      ),
                      Text(' -जिल्हा- ', style: mrStyle.copyWith(fontSize: 14.5)),
                      Expanded(
                        child: _inlineBlank(
                          controller: _ioDistrictCtrl,
                          style: mrStyle,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final mrStyle = GoogleFonts.notoSansDevanagari(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
    );

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        if (_showPage1) _buildPage1(mrStyle),
        if (_showPage1 && _showPage2) const SizedBox(height: 24),
        if (_showPage2) _buildPage2(mrStyle),
      ],
    );
  }
}
