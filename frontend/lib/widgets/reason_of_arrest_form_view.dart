import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// Reason of Arrest notice u/s 35(1)(b)(ii) BNSS — 2 pages.
class ReasonOfArrestFormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const ReasonOfArrestFormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<ReasonOfArrestFormView> createState() => ReasonOfArrestFormViewState();
}

class ReasonOfArrestFormViewState extends State<ReasonOfArrestFormView> {
  bool get _showMain {
    final s = widget.formSection?.toLowerCase() ?? '';
    if (s.isEmpty) return true;
    return s.contains('main') && !s.contains('continuation');
  }

  bool get _showContinuation {
    final s = widget.formSection?.toLowerCase() ?? '';
    if (s.isEmpty) return true;
    return s.contains('continuation');
  }

  final _outwardNoCtrl = TextEditingController();
  final _outwardYearCtrl = TextEditingController(text: '2025');
  final _policeStationCtrl = TextEditingController();
  final _talukaCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _noticeDateCtrl = TextEditingController();
  final _accusedNameAddressCtrl = TextEditingController();
  final _subjectPsCtrl = TextEditingController();
  final _subjectCrNoCtrl = TextEditingController();
  final _subjectSectionCtrl = TextEditingController();
  final _subjectBnsCtrl = TextEditingController();
  final _ioNameCtrl = TextEditingController();
  final _briefDescriptionCtrl = TextEditingController();
  final _reason1Ctrl = TextEditingController();
  final _reason2Ctrl = TextEditingController();
  final _reason3Ctrl = TextEditingController();
  final _reason4Ctrl = TextEditingController();
  final _reason5Ctrl = TextEditingController();
  final _relativeNameCtrl = TextEditingController();
  final _relativeAddressCtrl = TextEditingController();
  final _relativePhoneCtrl = TextEditingController();
  final _accusedSigCtrl = TextEditingController();
  final _accusedNameSigCtrl = TextEditingController();
  final _accusedDateTimeCtrl = TextEditingController();
  final _ioSigCtrl = TextEditingController();
  final _ioNameRankCtrl = TextEditingController();
  final _ioPsCtrl = TextEditingController();
  final _ioTalukaCtrl = TextEditingController();
  final _ioDistrictCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _outwardNoCtrl,
      _outwardYearCtrl,
      _policeStationCtrl,
      _talukaCtrl,
      _districtCtrl,
      _noticeDateCtrl,
      _accusedNameAddressCtrl,
      _subjectPsCtrl,
      _subjectCrNoCtrl,
      _subjectSectionCtrl,
      _subjectBnsCtrl,
      _ioNameCtrl,
      _briefDescriptionCtrl,
      _reason1Ctrl,
      _reason2Ctrl,
      _reason3Ctrl,
      _reason4Ctrl,
      _reason5Ctrl,
      _relativeNameCtrl,
      _relativeAddressCtrl,
      _relativePhoneCtrl,
      _accusedSigCtrl,
      _accusedNameSigCtrl,
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
      'outwardNo': _outwardNoCtrl.text.trim(),
      'outwardYear': _outwardYearCtrl.text.trim(),
      'policeStation': _policeStationCtrl.text.trim(),
      'taluka': _talukaCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      'noticeDate': _noticeDateCtrl.text.trim(),
      'accusedNameAddress': _accusedNameAddressCtrl.text.trim(),
      'subjectPs': _subjectPsCtrl.text.trim(),
      'subjectCrNo': _subjectCrNoCtrl.text.trim(),
      'subjectSection': _subjectSectionCtrl.text.trim(),
      'subjectBns': _subjectBnsCtrl.text.trim(),
      'ioName': _ioNameCtrl.text.trim(),
      'briefDescription': _briefDescriptionCtrl.text.trim(),
      'reason1': _reason1Ctrl.text.trim(),
      'reason2': _reason2Ctrl.text.trim(),
      'reason3': _reason3Ctrl.text.trim(),
      'reason4': _reason4Ctrl.text.trim(),
      'reason5': _reason5Ctrl.text.trim(),
      'relativeName': _relativeNameCtrl.text.trim(),
      'relativeAddress': _relativeAddressCtrl.text.trim(),
      'relativePhone': _relativePhoneCtrl.text.trim(),
      'accusedSig': _accusedSigCtrl.text.trim(),
      'accusedNameSig': _accusedNameSigCtrl.text.trim(),
      'accusedDateTime': _accusedDateTimeCtrl.text.trim(),
      'ioSig': _ioSigCtrl.text.trim(),
      'ioNameRank': _ioNameRankCtrl.text.trim(),
      'ioPs': _ioPsCtrl.text.trim(),
      'ioTaluka': _ioTalukaCtrl.text.trim(),
      'ioDistrict': _ioDistrictCtrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    for (final e in {
      'outwardNo': _outwardNoCtrl,
      'outwardYear': _outwardYearCtrl,
      'policeStation': _policeStationCtrl,
      'taluka': _talukaCtrl,
      'district': _districtCtrl,
      'noticeDate': _noticeDateCtrl,
      'accusedNameAddress': _accusedNameAddressCtrl,
      'subjectPs': _subjectPsCtrl,
      'subjectCrNo': _subjectCrNoCtrl,
      'subjectSection': _subjectSectionCtrl,
      'subjectBns': _subjectBnsCtrl,
      'ioName': _ioNameCtrl,
      'briefDescription': _briefDescriptionCtrl,
      'reason1': _reason1Ctrl,
      'reason2': _reason2Ctrl,
      'reason3': _reason3Ctrl,
      'reason4': _reason4Ctrl,
      'reason5': _reason5Ctrl,
      'relativeName': _relativeNameCtrl,
      'relativeAddress': _relativeAddressCtrl,
      'relativePhone': _relativePhoneCtrl,
      'accusedSig': _accusedSigCtrl,
      'accusedNameSig': _accusedNameSigCtrl,
      'accusedDateTime': _accusedDateTimeCtrl,
      'ioSig': _ioSigCtrl,
      'ioNameRank': _ioNameRankCtrl,
      'ioPs': _ioPsCtrl,
      'ioTaluka': _ioTalukaCtrl,
      'ioDistrict': _ioDistrictCtrl,
    }.entries) {
      e.value.text = data[e.key]?.toString() ?? '';
    }
    if (mounted) setState(() {});
  }

  Widget _buildPage1(
    TextStyle serif,
    TextStyle marathiBody,
    TextStyle marathiBold,
  ) {
    return FormPaperPage(
      formLabel: widget.pageRange ?? 'Page 1 — सुचनापत्र',
      children: [
        // Top Header
        Center(
          child: Text(
            'भारतीय नागरीक सुरक्षा संहिता,२०२३ चे कलम ३५ (१)(ब)(ii) नुसार अन्वये',
            style: marathiBold.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),

        // Title
        Center(
          child: Text(
            'सुचनापत्र',
            style: marathiBold.copyWith(fontSize: 17),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),

        // Right-aligned dispatch details
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('जावक.क्रमांक- ', style: marathiBold),
                  _UnderlineInput(
                    controller: _outwardNoCtrl,
                    width: 90,
                    readOnly: widget.readOnly,
                  ),
                  Text(' /', style: marathiBold),
                  _UnderlineInput(
                    controller: _outwardYearCtrl,
                    width: 55,
                    readOnly: widget.readOnly,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('पोलीस स्टेशन ', style: marathiBold),
                  _UnderlineInput(
                    controller: _policeStationCtrl,
                    width: 150,
                    readOnly: widget.readOnly,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('ता.', style: marathiBold),
                  _UnderlineInput(
                    controller: _talukaCtrl,
                    width: 85,
                    readOnly: widget.readOnly,
                  ),
                  Text(' -जिल्हा', style: marathiBold),
                  _UnderlineInput(
                    controller: _districtCtrl,
                    width: 85,
                    readOnly: widget.readOnly,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('दिनांक:- ', style: marathiBold),
                  _UnderlineInput(
                    controller: _noticeDateCtrl,
                    width: 120,
                    readOnly: widget.readOnly,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Recipient (प्रति)
        Text('प्रति,', style: marathiBold),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('नाव व पत्ता: ', style: marathiBold),
            ),
            Expanded(
              child: _UnderlineInput(
                controller: _accusedNameAddressCtrl,
                readOnly: widget.readOnly,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Subject (विषय)
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 8,
          children: [
            Text('विषय:- पोलीस स्टेशन', style: marathiBold),
            _UnderlineInput(
              controller: _subjectPsCtrl,
              width: 140,
              hintText: '[पोलीस स्टेशन]',
              readOnly: widget.readOnly,
            ),
            Text('गुन्हा रजि.क्र.', style: marathiBold),
            _UnderlineInput(
              controller: _subjectCrNoCtrl,
              width: 100,
              readOnly: widget.readOnly,
            ),
            Text('कलम', style: marathiBold),
            _UnderlineInput(
              controller: _subjectSectionCtrl,
              width: 90,
              readOnly: widget.readOnly,
            ),
            Text(
              '--- भा.न्या.स. नुसार दाखल असलेल्या गुन्ह्यांचे अनुषंगाने आरोपीस अटक करतांना अटक करण्यासाठी आधारभूत मुद्दे आणि अटकेची कारणे कळविणे बाबत.',
              style: marathiBody,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Main Notice Paragraph (Flowing paragraph with inline blanks)
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 10,
          children: [
            const SizedBox(width: 24), // Indent
            Text(
              'आपणास या सुचनापत्राद्वारे कळविण्यात येते की,आपल्या विरुद्ध पोलीस ठाणे',
              style: marathiBody,
            ),
            _UnderlineInput(
              controller: _policeStationCtrl,
              width: 140,
              hintText: '[पोलीस ठाणे]',
              readOnly: widget.readOnly,
            ),
            Text('येथे गुन्हा रजि.क्र.', style: marathiBody),
            _UnderlineInput(
              controller: _subjectCrNoCtrl,
              width: 100,
              readOnly: widget.readOnly,
            ),
            Text('/-- कलम', style: marathiBody),
            _UnderlineInput(
              controller: _subjectSectionCtrl,
              width: 100,
              readOnly: widget.readOnly,
            ),
            Text(
              'भारतीय न्याय संहिता २०२३ अन्वये गुन्हा नोंद करण्यात आला असुन,आम्ही',
              style: marathiBody,
            ),
            _UnderlineInput(
              controller: _ioNameCtrl,
              width: 150,
              hintText: '[तपासी अधिकारी]',
              readOnly: widget.readOnly,
            ),
            Text(
              'तपासी अधिकारी म्हणून सदर गुन्ह्यांचा तपास करीत आहोत.सदर गुन्ह्यांचे तपासकामी आपणास अटक करणे गरजेचे असून भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ३५ (१)(ब)(ii) नुसार ) अटकेची कारणे खालील प्रमाणे आहेत.',
              style: marathiBody,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Reasons Heading
        Center(
          child: Text(
            'अटकेची कारणे (REASONS FOR ARREST)',
            style: marathiBold.copyWith(fontSize: 14.5),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),

        // Reasons 1 to 5
        for (final item in [
          ('१.', _reason1Ctrl),
          ('२.', _reason2Ctrl),
          ('३.', _reason3Ctrl),
          ('४.', _reason4Ctrl),
          ('५.', _reason5Ctrl),
        ]) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('${item.$1} ', style: marathiBold),
                ),
                Expanded(
                  child: _UnderlineInput(
                    controller: item.$2,
                    readOnly: widget.readOnly,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Bottom right continuation marker
        Align(
          alignment: Alignment.centerRight,
          child: Text('२..', style: marathiBold),
        ),
      ],
    );
  }

  Widget _buildPage2(
    TextStyle serif,
    TextStyle marathiBody,
    TextStyle marathiBold,
  ) {
    return FormPaperPage(
      formLabel: widget.pageRange ?? 'Page 2 — सुचनापत्र (पृष्ठ २)',
      children: [
        Center(
          child: Text(
            '..२..',
            style: marathiBold.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),

        // Paragraph 1
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 32),
            Expanded(
              child: Text(
                'आपणास असेही कळविण्यांत येते की, नमुद गुन्हा हा दखलपात्र असुन अजामीनपात्र आहे आणि त्यामुळे आपण त्या गुन्ह्यात न्यायालयात जामिनाचा अर्ज सादर करुन न्यायालयाचे आदेशाने जामिनावर मुक्त होवु शकता.',
                style: marathiBody,
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Paragraph 2 (with inline relative/friend name, address, phone number blanks)
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 10,
          children: [
            const SizedBox(width: 32), // Indent
            Text(
              'आपल्या अटकेची माहीती आपले नातेवाईक/ मित्र',
              style: marathiBody,
            ),
            _UnderlineInput(
              controller: _relativeNameCtrl,
              width: 170,
              hintText: '[नातेवाईक/मित्र नाव]',
              readOnly: widget.readOnly,
            ),
            Text('रा.', style: marathiBody),
            _UnderlineInput(
              controller: _relativeAddressCtrl,
              width: 180,
              hintText: '[पत्ता]',
              readOnly: widget.readOnly,
            ),
            Text('यांना लेखी सुचनेव्दारे/फोन क्रमांक', style: marathiBody),
            _UnderlineInput(
              controller: _relativePhoneCtrl,
              width: 130,
              hintText: '[फोन क्रमांक]',
              readOnly: widget.readOnly,
            ),
            Text('यावर संपर्क करुन देण्यांत आली आहे.', style: marathiBody),
          ],
        ),
        const SizedBox(height: 18),

        // Paragraph 3
        Row(
          children: [
            const SizedBox(width: 32),
            Text(
              'याकरीता आपणास सुचनापत्र देण्यांत येत आहे.',
              style: marathiBody,
            ),
          ],
        ),
        const SizedBox(height: 36),

        // Signatures (Two Columns)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column (Accused)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('मला सुचनापत्र प्राप्त झाले', style: marathiBold),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('(आरोपीची सही', style: marathiBold),
                    ),
                    _UnderlineInput(
                      controller: _accusedSigCtrl,
                      width: 130,
                      readOnly: widget.readOnly,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(')', style: marathiBold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('आरोपीचे नांव ', style: marathiBold),
                    ),
                    _UnderlineInput(
                      controller: _accusedNameSigCtrl,
                      width: 150,
                      readOnly: widget.readOnly,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('दिनांक:व वेळ ', style: marathiBold),
                    ),
                    _UnderlineInput(
                      controller: _accusedDateTimeCtrl,
                      width: 160,
                      readOnly: widget.readOnly,
                    ),
                  ],
                ),
              ],
            ),

            // Right Column (IO)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('तपास अधि सही/-', style: marathiBold),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('नाव/हुद्दा', style: marathiBold),
                    ),
                    _UnderlineInput(
                      controller: _ioNameRankCtrl,
                      width: 140,
                      readOnly: widget.readOnly,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('पोलीस स्टेशन', style: marathiBold),
                    ),
                    _UnderlineInput(
                      controller: _ioPsCtrl,
                      width: 140,
                      readOnly: widget.readOnly,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('ता.', style: marathiBold),
                    ),
                    _UnderlineInput(
                      controller: _ioTalukaCtrl,
                      width: 75,
                      readOnly: widget.readOnly,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(' जिल्हा', style: marathiBold),
                    ),
                    _UnderlineInput(
                      controller: _ioDistrictCtrl,
                      width: 75,
                      readOnly: widget.readOnly,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final serif = FormTypography.serifStyle();
    final marathiBold = GoogleFonts.notoSansDevanagari(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
    final marathiBody = GoogleFonts.notoSansDevanagari(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Colors.black87,
      height: 1.7,
    );

    final pages = <Widget>[];
    if (_showMain) {
      pages.add(_buildPage1(serif, marathiBody, marathiBold));
      if (_showContinuation) pages.add(const SizedBox(height: 24));
    }
    if (_showContinuation) {
      pages.add(_buildPage2(serif, marathiBody, marathiBold));
    }

    return FormViewScaffold(readOnly: widget.readOnly, children: pages);
  }
}

class _UnderlineInput extends StatelessWidget {
  final TextEditingController controller;
  final double? width;
  final String? hintText;
  final bool readOnly;

  const _UnderlineInput({
    required this.controller,
    this.width,
    this.hintText,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: 1,
      textAlign: TextAlign.start,
      scrollPhysics: const NeverScrollableScrollPhysics(),
      scrollPadding: EdgeInsets.zero,
      style: GoogleFonts.notoSansDevanagari(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.blue.shade900,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.only(bottom: 0, top: 2),
        hintText: hintText,
        hintStyle: GoogleFonts.notoSansDevanagari(
          fontSize: 13,
          color: Colors.black38,
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black54, width: 1),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black54, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 1.5),
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
  }
}
