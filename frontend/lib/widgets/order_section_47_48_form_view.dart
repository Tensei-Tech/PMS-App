import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/order_section_47_48_pdf.dart';
import 'form_date_pickers.dart';
import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// Order / Notice u/s 47 & 48 BNSS
/// Page 1: नोटीस बी.एन.एस.एस.कलम ४७(१) (Notice to Accused)
/// Page 2: नोटीस बी.एन.एस.एस.कलम ४८ (Notice to Relative / Friend)
class OrderSection4748FormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const OrderSection4748FormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<OrderSection4748FormView> createState() =>
      OrderSection4748FormViewState();
}

class OrderSection4748FormViewState extends State<OrderSection4748FormView> {
  @override
  void initState() {
    super.initState();
    preloadOrderSection4748PdfFonts();
  }

  bool get _showPage1 {
    final s = (widget.formSection ?? '').toLowerCase();
    if (s.isEmpty || s.contains('complete')) return true;
    return s.contains('47') || s.contains('main') || s.contains('1');
  }

  bool get _showPage2 {
    final s = (widget.formSection ?? '').toLowerCase();
    if (s.isEmpty || s.contains('complete')) return true;
    return s.contains('48') || s.contains('2');
  }

  bool get _showAll => !_showPage1 && !_showPage2;

  // Shared / Case fields
  final _policeStationCtrl = TextEditingController();
  final _crNoCtrl = TextEditingController();
  final _crYearCtrl = TextEditingController();
  final _bnsSectionCtrl = TextEditingController();
  final _arrestDateCtrl = TextEditingController();
  final _arrestTimeCtrl = TextEditingController();
  final _ioNameCtrl = TextEditingController();

  // Page 1 (Section 47(1)) specific
  final _p1ToLine1Ctrl = TextEditingController();
  final _p1ToLine2Ctrl = TextEditingController();
  final _p1ToLine3Ctrl = TextEditingController();
  final _p1Fact1Ctrl = TextEditingController();
  final _p1Fact2Ctrl = TextEditingController();
  final _p1Fact3Ctrl = TextEditingController();
  final _p1Ground1Ctrl = TextEditingController();
  final _p1Ground2Ctrl = TextEditingController();
  final _p1Ground3Ctrl = TextEditingController();
  final _p1Ground4Ctrl = TextEditingController();
  final _p1Ground5Ctrl = TextEditingController();
  final _p1Reason1Ctrl = TextEditingController();
  final _p1Reason2Ctrl = TextEditingController();
  final _p1Reason3Ctrl = TextEditingController();
  final _p1Reason4Ctrl = TextEditingController();
  final _p1Reason5Ctrl = TextEditingController();
  final _p1RemandDateCtrl = TextEditingController();
  final _p1AccusedSigCtrl = TextEditingController();
  final _p1IoSigCtrl = TextEditingController();

  // Page 2 (Section 48) specific
  final _p2ToLine1Ctrl = TextEditingController();
  final _p2ToLine2Ctrl = TextEditingController();
  final _p2ToLine3Ctrl = TextEditingController();
  final _p2AccusedNameCtrl = TextEditingController();
  final _p2Fact1Ctrl = TextEditingController();
  final _p2Fact2Ctrl = TextEditingController();
  final _p2Fact3Ctrl = TextEditingController();
  final _p2Ground1Ctrl = TextEditingController();
  final _p2Ground2Ctrl = TextEditingController();
  final _p2Ground3Ctrl = TextEditingController();
  final _p2Ground4Ctrl = TextEditingController();
  final _p2Ground5Ctrl = TextEditingController();
  final _p2Reason1Ctrl = TextEditingController();
  final _p2Reason2Ctrl = TextEditingController();
  final _p2Reason3Ctrl = TextEditingController();
  final _p2Reason4Ctrl = TextEditingController();
  final _p2Reason5Ctrl = TextEditingController();
  final _p2RemandDateCtrl = TextEditingController();
  final _p2RelativeSigCtrl = TextEditingController();
  final _p2IoSigCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _policeStationCtrl,
      _crNoCtrl,
      _crYearCtrl,
      _bnsSectionCtrl,
      _arrestDateCtrl,
      _arrestTimeCtrl,
      _ioNameCtrl,
      _p1ToLine1Ctrl,
      _p1ToLine2Ctrl,
      _p1ToLine3Ctrl,
      _p1Fact1Ctrl,
      _p1Fact2Ctrl,
      _p1Fact3Ctrl,
      _p1Ground1Ctrl,
      _p1Ground2Ctrl,
      _p1Ground3Ctrl,
      _p1Ground4Ctrl,
      _p1Ground5Ctrl,
      _p1Reason1Ctrl,
      _p1Reason2Ctrl,
      _p1Reason3Ctrl,
      _p1Reason4Ctrl,
      _p1Reason5Ctrl,
      _p1RemandDateCtrl,
      _p1AccusedSigCtrl,
      _p1IoSigCtrl,
      _p2ToLine1Ctrl,
      _p2ToLine2Ctrl,
      _p2ToLine3Ctrl,
      _p2AccusedNameCtrl,
      _p2Fact1Ctrl,
      _p2Fact2Ctrl,
      _p2Fact3Ctrl,
      _p2Ground1Ctrl,
      _p2Ground2Ctrl,
      _p2Ground3Ctrl,
      _p2Ground4Ctrl,
      _p2Ground5Ctrl,
      _p2Reason1Ctrl,
      _p2Reason2Ctrl,
      _p2Reason3Ctrl,
      _p2Reason4Ctrl,
      _p2Reason5Ctrl,
      _p2RemandDateCtrl,
      _p2RelativeSigCtrl,
      _p2IoSigCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'policeStation': _policeStationCtrl.text.trim(),
      'crNo': _crNoCtrl.text.trim(),
      'crYear': _crYearCtrl.text.trim(),
      'bnsSection': _bnsSectionCtrl.text.trim(),
      'arrestDate': _arrestDateCtrl.text.trim(),
      'arrestTime': _arrestTimeCtrl.text.trim(),
      'ioName': _ioNameCtrl.text.trim(),

      // Page 1
      'p1To1': _p1ToLine1Ctrl.text.trim(),
      'p1To2': _p1ToLine2Ctrl.text.trim(),
      'p1To3': _p1ToLine3Ctrl.text.trim(),
      'p1Fact1': _p1Fact1Ctrl.text.trim(),
      'p1Fact2': _p1Fact2Ctrl.text.trim(),
      'p1Fact3': _p1Fact3Ctrl.text.trim(),
      'p1Ground1': _p1Ground1Ctrl.text.trim(),
      'p1Ground2': _p1Ground2Ctrl.text.trim(),
      'p1Ground3': _p1Ground3Ctrl.text.trim(),
      'p1Ground4': _p1Ground4Ctrl.text.trim(),
      'p1Ground5': _p1Ground5Ctrl.text.trim(),
      'p1Reason1': _p1Reason1Ctrl.text.trim(),
      'p1Reason2': _p1Reason2Ctrl.text.trim(),
      'p1Reason3': _p1Reason3Ctrl.text.trim(),
      'p1Reason4': _p1Reason4Ctrl.text.trim(),
      'p1Reason5': _p1Reason5Ctrl.text.trim(),
      'p1RemandDate': _p1RemandDateCtrl.text.trim(),
      'p1AccusedSig': _p1AccusedSigCtrl.text.trim(),
      'p1IoSig': _p1IoSigCtrl.text.trim(),

      // Page 2
      'p2To1': _p2ToLine1Ctrl.text.trim(),
      'p2To2': _p2ToLine2Ctrl.text.trim(),
      'p2To3': _p2ToLine3Ctrl.text.trim(),
      'p2AccusedName': _p2AccusedNameCtrl.text.trim(),
      'p2Fact1': _p2Fact1Ctrl.text.trim(),
      'p2Fact2': _p2Fact2Ctrl.text.trim(),
      'p2Fact3': _p2Fact3Ctrl.text.trim(),
      'p2Ground1': _p2Ground1Ctrl.text.trim(),
      'p2Ground2': _p2Ground2Ctrl.text.trim(),
      'p2Ground3': _p2Ground3Ctrl.text.trim(),
      'p2Ground4': _p2Ground4Ctrl.text.trim(),
      'p2Ground5': _p2Ground5Ctrl.text.trim(),
      'p2Reason1': _p2Reason1Ctrl.text.trim(),
      'p2Reason2': _p2Reason2Ctrl.text.trim(),
      'p2Reason3': _p2Reason3Ctrl.text.trim(),
      'p2Reason4': _p2Reason4Ctrl.text.trim(),
      'p2Reason5': _p2Reason5Ctrl.text.trim(),
      'p2RemandDate': _p2RemandDateCtrl.text.trim(),
      'p2RelativeSig': _p2RelativeSigCtrl.text.trim(),
      'p2IoSig': _p2IoSigCtrl.text.trim(),

      // Backward compatibility aliases
      'accusedName': _p1ToLine1Ctrl.text.trim(),
      'section': _bnsSectionCtrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    void set(TextEditingController c, List<String> keys,
        [String fallback = '']) {
      for (final k in keys) {
        final val = data[k]?.toString();
        if (val != null && val.trim().isNotEmpty) {
          c.text = val.trim();
          return;
        }
      }
      if (fallback.isNotEmpty && c.text.isEmpty) {
        c.text = fallback;
      }
    }

    set(_policeStationCtrl, ['policeStation']);
    set(_crNoCtrl, ['crNo']);
    set(_crYearCtrl, ['crYear', 'outwardYear'], '२५');
    set(_bnsSectionCtrl, ['bnsSection', 'section']);
    set(_arrestDateCtrl, ['arrestDate', 'orderDate', 'n47Date']);
    set(_arrestTimeCtrl, ['arrestTime']);
    set(_ioNameCtrl, ['ioName', 'shoName', 'n47IoName']);

    // Page 1
    set(_p1ToLine1Ctrl, ['p1To1', 'accusedName', 'n47To']);
    set(_p1ToLine2Ctrl, ['p1To2']);
    set(_p1ToLine3Ctrl, ['p1To3']);
    set(_p1Fact1Ctrl, ['p1Fact1', 'orderBody', 'n47Body']);
    set(_p1Fact2Ctrl, ['p1Fact2']);
    set(_p1Fact3Ctrl, ['p1Fact3']);
    set(_p1Ground1Ctrl, ['p1Ground1']);
    set(_p1Ground2Ctrl, ['p1Ground2']);
    set(_p1Ground3Ctrl, ['p1Ground3']);
    set(_p1Ground4Ctrl, ['p1Ground4']);
    set(_p1Ground5Ctrl, ['p1Ground5']);
    set(_p1Reason1Ctrl, ['p1Reason1']);
    set(_p1Reason2Ctrl, ['p1Reason2']);
    set(_p1Reason3Ctrl, ['p1Reason3']);
    set(_p1Reason4Ctrl, ['p1Reason4']);
    set(_p1Reason5Ctrl, ['p1Reason5']);
    set(_p1RemandDateCtrl, ['p1RemandDate', 'arrestDate']);
    set(_p1AccusedSigCtrl, ['p1AccusedSig', 'n47AccusedSig', 'n47AccusedName']);
    set(_p1IoSigCtrl, ['p1IoSig', 'n47IoName', 'ioName']);

    // Page 2
    set(_p2ToLine1Ctrl, ['p2To1', 'n48To']);
    set(_p2ToLine2Ctrl, ['p2To2']);
    set(_p2ToLine3Ctrl, ['p2To3']);
    set(_p2AccusedNameCtrl, ['p2AccusedName', 'accusedName', 'p1To1']);
    set(_p2Fact1Ctrl, ['p2Fact1', 'p1Fact1']);
    set(_p2Fact2Ctrl, ['p2Fact2', 'p1Fact2']);
    set(_p2Fact3Ctrl, ['p2Fact3', 'p1Fact3']);
    set(_p2Ground1Ctrl, ['p2Ground1', 'p1Ground1']);
    set(_p2Ground2Ctrl, ['p2Ground2', 'p1Ground2']);
    set(_p2Ground3Ctrl, ['p2Ground3', 'p1Ground3']);
    set(_p2Ground4Ctrl, ['p2Ground4', 'p1Ground4']);
    set(_p2Ground5Ctrl, ['p2Ground5', 'p1Ground5']);
    set(_p2Reason1Ctrl, ['p2Reason1', 'p1Reason1']);
    set(_p2Reason2Ctrl, ['p2Reason2', 'p1Reason2']);
    set(_p2Reason3Ctrl, ['p2Reason3', 'p1Reason3']);
    set(_p2Reason4Ctrl, ['p2Reason4', 'p1Reason4']);
    set(_p2Reason5Ctrl, ['p2Reason5', 'p1Reason5']);
    set(_p2RemandDateCtrl, ['p2RemandDate', 'p1RemandDate', 'arrestDate']);
    set(_p2RelativeSigCtrl, ['p2RelativeSig', 'n48RelativeSig']);
    set(_p2IoSigCtrl, ['p2IoSig', 'n48IoName', 'ioName']);

    if (mounted) setState(() {});
  }

  Widget _buildRuledLine({
    String? prefix,
    required TextEditingController controller,
    String? hintText,
    bool readOnly = false,
    double bottomPadding = 8,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (prefix != null && prefix.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2, right: 6),
              child: Text(
                prefix,
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          Expanded(
            child: _UnderlineInput(
              controller: controller,
              hintText: hintText,
              readOnly: readOnly,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1(
      TextStyle serif, TextStyle marathiBody, TextStyle marathiBold) {
    return FormPaperPage(
      minHeight: 0,
      formLabel: widget.pageRange ?? 'Page 1 — नोटीस बी.एन.एस.एस.कलम ४७(१)',
      children: [
        // Top Center Headers
        Center(
          child: Column(
            children: [
              Text(
                'नोटीस',
                style: marathiBold.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                'बी.एन.एस.एस.कलम ४७(१)',
                style: marathiBold.copyWith(fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Recipient (प्रति,)
        Text('प्रति,', style: marathiBold.copyWith(fontSize: 14)),
        const SizedBox(height: 6),
        _buildRuledLine(
          controller: _p1ToLine1Ctrl,
          hintText: '[आरोपीचे पूर्ण नाव / पत्ता - ओळ १]',
          readOnly: widget.readOnly,
          bottomPadding: 8,
        ),
        _buildRuledLine(
          controller: _p1ToLine2Ctrl,
          hintText: '[पत्ता - ओळ २]',
          readOnly: widget.readOnly,
          bottomPadding: 8,
        ),
        _buildRuledLine(
          controller: _p1ToLine3Ctrl,
          hintText: '[पत्ता - ओळ ३]',
          readOnly: widget.readOnly,
          bottomPadding: 0,
        ),
        const SizedBox(height: 16),

        // Subject
        Text(
          'विषय :- गुन्ह्याचे तपास कामी अटक करण्याचा आधार व कारणांबाबत...',
          style: marathiBold.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 16),

        // Flowing Notice Paragraph
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 10,
          children: [
            const SizedBox(width: 28), // Indent
            Text('आपणास याद्वारे कळविण्यात येते की,', style: marathiBody),
            _policeStationField(
              controller: _policeStationCtrl,
              style: marathiBody,
              minWidth: 150,
              maxWidth: 450,
              hintText: 'पोलीस स्टेशन नाव',
            ),
            Text('पोलीस स्टेशन, गुन्हा रजि.नंबर', style: marathiBody),
            _UnderlineInput(
              controller: _crNoCtrl,
              width: 85,
              hintText: 'गु.र.नं.',
              readOnly: widget.readOnly,
            ),
            Text('/', style: marathiBody),
            _UnderlineInput(
              controller: _crYearCtrl,
              width: 50,
              hintText: 'वर्ष',
              textAlign: TextAlign.center,
              readOnly: widget.readOnly,
            ),
            Text('भा.न्या.सं.कलम', style: marathiBody),
            _UnderlineInput(
              controller: _bnsSectionCtrl,
              width: 210,
              hintText: 'कलम उदा. १०३, ३(५)',
              readOnly: widget.readOnly,
            ),
            Text(
              'या गुन्ह्याचे तपासात निष्पन्न झालेल्या पुराव्यावरून आपणास दिनांक',
              style: marathiBody,
            ),
            formDatePickerField(
              context,
              controller: _arrestDateCtrl,
              width: 140,
              readOnly: widget.readOnly,
            ),
            Text('रोजी', style: marathiBody),
            formTimePickerField(
              context,
              controller: _arrestTimeCtrl,
              width: 110,
              readOnly: widget.readOnly,
            ),
            Text(
              'वा. खालील आधारावर व कारणांसाठी अटक करण्यात येत आहे :-',
              style: marathiBody,
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Section अ: गुन्ह्याची थोडक्यात हकीगत :-
        Text('अ) गुन्ह्याची थोडक्यात हकीगत :-',
            style: marathiBold.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        _buildRuledLine(
          controller: _p1Fact1Ctrl,
          hintText: '[हकीगत ओळ १]',
          readOnly: widget.readOnly,
          bottomPadding: 8,
        ),
        _buildRuledLine(
          controller: _p1Fact2Ctrl,
          hintText: '[हकीगत ओळ २]',
          readOnly: widget.readOnly,
          bottomPadding: 8,
        ),
        _buildRuledLine(
          controller: _p1Fact3Ctrl,
          hintText: '[हकीगत ओळ ३]',
          readOnly: widget.readOnly,
          bottomPadding: 0,
        ),
        const SizedBox(height: 18),

        // Section ब: अटक करण्यासंबंधाने आधार :-
        Text('ब) अटक करण्यासंबंधाने आधार :-',
            style: marathiBold.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        for (final item in [
          ('१)', _p1Ground1Ctrl),
          ('२)', _p1Ground2Ctrl),
          ('३)', _p1Ground3Ctrl),
          ('४)', _p1Ground4Ctrl),
          ('५)', _p1Ground5Ctrl),
        ])
          _buildRuledLine(
            prefix: item.$1,
            controller: item.$2,
            hintText: '[आधार ${item.$1}]',
            readOnly: widget.readOnly,
            bottomPadding: item.$1 == '५)' ? 0 : 8,
          ),
        const SizedBox(height: 18),

        // Section क: अटकेची कारणे :-
        Text('क) अटकेची कारणे :-', style: marathiBold.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        for (final item in [
          ('१)', _p1Reason1Ctrl),
          ('२)', _p1Reason2Ctrl),
          ('३)', _p1Reason3Ctrl),
          ('४)', _p1Reason4Ctrl),
          ('५)', _p1Reason5Ctrl),
        ])
          _buildRuledLine(
            prefix: item.$1,
            controller: item.$2,
            hintText: '[कारण ${item.$1}]',
            readOnly: widget.readOnly,
            bottomPadding: item.$1 == '५)' ? 0 : 8,
          ),
        const SizedBox(height: 18),

        // Section ड
        Text(
          'ड) सदर गुन्हा हा जामीनपात्र/अजामीनपात्र आहे. गुन्हा जामीनपात्र असल्याने आपण योग्य तो जामीन दिल्यास आपणास जामीनावर मुक्त करण्यात येईल.',
          style: marathiBody,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 14),

        // Section इ
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 8,
          children: [
            Text('इ) आपणास दिनांक', style: marathiBody),
            formDatePickerField(
              context,
              controller: _p1RemandDateCtrl,
              width: 140,
              readOnly: widget.readOnly,
            ),
            Text(
              'रोजी मा.प्रथम वर्ग न्यायदंडाधिकारी यांचे समक्ष रिमांडसाठी हजर करण्यात येणार आहे.',
              style: marathiBody,
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Footer Signatures
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 36),
            child: Text('कळावे,', style: marathiBold.copyWith(fontSize: 14)),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Left: Accused signature
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 62,
                  width: 225,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black45, width: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '(सही / डाव्या हाताच्या अंगठ्याचा ठसा)',
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 10.5,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _UnderlineInput(
                  controller: _p1AccusedSigCtrl,
                  width: 220,
                  hintText: '[आरोपीचे नाव/स्वाक्षरी]',
                  textAlign: TextAlign.center,
                  readOnly: widget.readOnly,
                ),
                const SizedBox(height: 4),
                Text('आरोपीची स्वाक्षरी / अंगठा', style: marathiBold),
              ],
            ),

            // Right: IO signature
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 62,
                  width: 225,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black45, width: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '(स्वाक्षरी व पोलीस स्टेशन शिक्का)',
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 10.5,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _UnderlineInput(
                  controller: _p1IoSigCtrl,
                  width: 220,
                  hintText: '[अधिकारी नाव/हुद्दा]',
                  textAlign: TextAlign.center,
                  readOnly: widget.readOnly,
                ),
                const SizedBox(height: 4),
                Text('तपासणी अधिकारी / अंमलदार', style: marathiBold),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPage2(
      TextStyle serif, TextStyle marathiBody, TextStyle marathiBold) {
    return FormPaperPage(
      minHeight: 0,
      formLabel: widget.pageRange ?? 'Page 2 — नोटीस बी.एन.एस.एस.कलम ४८',
      children: [
        // Top Center Headers
        Center(
          child: Column(
            children: [
              Text(
                'नोटीस',
                style: marathiBold.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                'बी.एन.एस.एस.कलम ४८',
                style: marathiBold.copyWith(fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Recipient (प्रति,)
        Text('प्रति,', style: marathiBold.copyWith(fontSize: 14)),
        const SizedBox(height: 6),
        _buildRuledLine(
          controller: _p2ToLine1Ctrl,
          hintText: '[नातेवाईक/मित्राचे पूर्ण नाव / पत्ता - ओळ १]',
          readOnly: widget.readOnly,
          bottomPadding: 8,
        ),
        _buildRuledLine(
          controller: _p2ToLine2Ctrl,
          hintText: '[पत्ता - ओळ २]',
          readOnly: widget.readOnly,
          bottomPadding: 8,
        ),
        _buildRuledLine(
          controller: _p2ToLine3Ctrl,
          hintText: '[पत्ता - ओळ ३]',
          readOnly: widget.readOnly,
          bottomPadding: 0,
        ),
        const SizedBox(height: 16),

        // Subject
        Text(
          'विषय :- गुन्ह्याचे तपास कामी अटक केले संबंधी अवगत केले बाबत...',
          style: marathiBold.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 16),

        // Flowing Notice Paragraph
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 10,
          children: [
            const SizedBox(width: 28), // Indent
            Text('आपणास याद्वारे कळविण्यात येते की,', style: marathiBody),
            _policeStationField(
              controller: _policeStationCtrl,
              style: marathiBody,
              minWidth: 150,
              maxWidth: 450,
              hintText: 'पोलीस स्टेशन नाव',
            ),
            Text('पोलीस स्टेशन, गुन्हा रजि.नंबर', style: marathiBody),
            _UnderlineInput(
              controller: _crNoCtrl,
              width: 85,
              hintText: 'गु.र.नं.',
              readOnly: widget.readOnly,
            ),
            Text('/', style: marathiBody),
            _UnderlineInput(
              controller: _crYearCtrl,
              width: 50,
              hintText: 'वर्ष',
              textAlign: TextAlign.center,
              readOnly: widget.readOnly,
            ),
            Text('भा.न्या.सं.कलम', style: marathiBody),
            _UnderlineInput(
              controller: _bnsSectionCtrl,
              width: 210,
              hintText: 'कलम उदा. १०३, ३(५)',
              readOnly: widget.readOnly,
            ),
            Text(
              'या गुन्ह्यात आपले नातेवाईक / मित्र / आप्तेष्ठ नामे',
              style: marathiBody,
            ),
            _UnderlineInput(
              controller: _p2AccusedNameCtrl,
              width: 260,
              hintText: '[अटक व्यक्तीचे नाव]',
              readOnly: widget.readOnly,
            ),
            Text('यांना दिनांक', style: marathiBody),
            formDatePickerField(
              context,
              controller: _arrestDateCtrl,
              width: 140,
              readOnly: widget.readOnly,
            ),
            Text('रोजी', style: marathiBody),
            formTimePickerField(
              context,
              controller: _arrestTimeCtrl,
              width: 110,
              readOnly: widget.readOnly,
            ),
            Text('वा. अटक करण्यात आली आहे.', style: marathiBody),
          ],
        ),
        const SizedBox(height: 18),

        // Section अ: गुन्ह्याची थोडक्यात हकीगत :-
        Text('अ) गुन्ह्याची थोडक्यात हकीगत :-',
            style: marathiBold.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        _buildRuledLine(
          controller: _p2Fact1Ctrl,
          hintText: '[हकीगत ओळ १]',
          readOnly: widget.readOnly,
          bottomPadding: 8,
        ),
        _buildRuledLine(
          controller: _p2Fact2Ctrl,
          hintText: '[हकीगत ओळ २]',
          readOnly: widget.readOnly,
          bottomPadding: 8,
        ),
        _buildRuledLine(
          controller: _p2Fact3Ctrl,
          hintText: '[हकीगत ओळ ३]',
          readOnly: widget.readOnly,
          bottomPadding: 0,
        ),
        const SizedBox(height: 18),

        // Section ब: अटक करण्यासंबंधाने आधार :-
        Text('ब) अटक करण्यासंबंधाने आधार :-',
            style: marathiBold.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        for (final item in [
          ('१)', _p2Ground1Ctrl),
          ('२)', _p2Ground2Ctrl),
          ('३)', _p2Ground3Ctrl),
          ('४)', _p2Ground4Ctrl),
          ('५)', _p2Ground5Ctrl),
        ])
          _buildRuledLine(
            prefix: item.$1,
            controller: item.$2,
            hintText: '[आधार ${item.$1}]',
            readOnly: widget.readOnly,
            bottomPadding: item.$1 == '५)' ? 0 : 8,
          ),
        const SizedBox(height: 18),

        // Section क: अटकेची कारणे :-
        Text('क) अटकेची कारणे :-', style: marathiBold.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        for (final item in [
          ('१)', _p2Reason1Ctrl),
          ('२)', _p2Reason2Ctrl),
          ('३)', _p2Reason3Ctrl),
          ('४)', _p2Reason4Ctrl),
          ('५)', _p2Reason5Ctrl),
        ])
          _buildRuledLine(
            prefix: item.$1,
            controller: item.$2,
            hintText: '[कारण ${item.$1}]',
            readOnly: widget.readOnly,
            bottomPadding: item.$1 == '५)' ? 0 : 8,
          ),
        const SizedBox(height: 18),

        // Section ड
        Text(
          'ड) सदर गुन्हा हा जामीनपात्र/अजामीनपात्र आहे. गुन्हा जामीनपात्र असल्याने योग्य तो जामीन दिल्यास अटक व्यक्तीस जामीनावर मुक्त करण्यात येईल.',
          style: marathiBody,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 14),

        // Section इ
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 8,
          children: [
            Text('इ) अटक व्यक्तीला दिनांक', style: marathiBody),
            formDatePickerField(
              context,
              controller: _p2RemandDateCtrl,
              width: 140,
              readOnly: widget.readOnly,
            ),
            Text(
              'रोजी मा.प्रथम वर्ग न्यायदंडाधिकारी यांचे समक्ष रिमांडसाठी हजर करण्यात येणार आहे.',
              style: marathiBody,
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Footer Signatures
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 36),
            child: Text('कळावे,', style: marathiBold.copyWith(fontSize: 14)),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Left: Relative signature
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 62,
                  width: 225,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black45, width: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '(सही / डाव्या हाताच्या अंगठ्याचा ठसा)',
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 10.5,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _UnderlineInput(
                  controller: _p2RelativeSigCtrl,
                  width: 220,
                  hintText: '[नातेवाईकाचे नाव/स्वाक्षरी]',
                  textAlign: TextAlign.center,
                  readOnly: widget.readOnly,
                ),
                const SizedBox(height: 4),
                Text('नातेवाईकाची स्वाक्षरी / अंगठा', style: marathiBold),
              ],
            ),

            // Right: IO signature
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 62,
                  width: 225,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black45, width: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '(स्वाक्षरी व पोलीस स्टेशन शिक्का)',
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 10.5,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _UnderlineInput(
                  controller: _p2IoSigCtrl,
                  width: 220,
                  hintText: '[अधिकारी नाव/हुद्दा]',
                  textAlign: TextAlign.center,
                  readOnly: widget.readOnly,
                ),
                const SizedBox(height: 4),
                Text('तपासणी अधिकारी / अंमलदार', style: marathiBold),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final serif = FormTypography.serifStyle();
    final marathiBold = GoogleFonts.notoSansDevanagari(
      fontSize: 13.5,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
    final marathiBody = GoogleFonts.notoSansDevanagari(
      fontSize: 13.5,
      fontWeight: FontWeight.normal,
      color: Colors.black87,
      height: 1.65,
    );

    final show1 = _showPage1 || _showAll;
    final show2 = _showPage2 || _showAll;

    final pages = <Widget>[];
    if (show1) {
      pages.add(_buildPage1(serif, marathiBody, marathiBold));
    }
    if (show2) {
      if (pages.isNotEmpty) pages.add(const SizedBox(height: 32));
      pages.add(_buildPage2(serif, marathiBody, marathiBold));
    }

    return FormViewScaffold(readOnly: widget.readOnly, children: pages);
  }

  Widget _policeStationField({
    required TextEditingController controller,
    required TextStyle style,
    double minWidth = 150,
    double? maxWidth,
    String? hintText,
  }) {
    final baseMin = minWidth;
    final baseMax = maxWidth ?? 500.0;
    const double baseFontSize = 13.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasFiniteWidth = constraints.maxWidth.isFinite;
        final availableWidth = hasFiniteWidth ? constraints.maxWidth : baseMax;

        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final text =
                controller.text.isEmpty ? (hintText ?? '') : controller.text;
            final tp = TextPainter(
              text: TextSpan(
                text: text,
                style: GoogleFonts.notoSansDevanagari(
                  fontWeight: FontWeight.w600,
                  fontSize: baseFontSize,
                ),
              ),
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout();

            final double textW = tp.width + 12.0;
            final widthToUse =
                hasFiniteWidth ? availableWidth : textW.clamp(baseMin, baseMax);

            return SizedBox(
              width: widthToUse,
              child: TextFormField(
                controller: controller,
                readOnly: widget.readOnly,
                minLines: 1,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: baseFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                  height: 1.35,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.only(bottom: 2, top: 2),
                  hintText: hintText,
                  hintStyle: GoogleFonts.notoSansDevanagari(
                    fontSize: 12,
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
              ),
            );
          },
        );
      },
    );
  }
}

class _UnderlineInput extends StatelessWidget {
  final TextEditingController controller;
  final double? width;
  final String? hintText;
  final bool readOnly;
  final TextAlign textAlign;

  const _UnderlineInput({
    required this.controller,
    this.width,
    this.hintText,
    this.readOnly = false,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      readOnly: readOnly,
      textAlign: textAlign,
      maxLines: null,
      scrollPhysics: const NeverScrollableScrollPhysics(),
      scrollPadding: EdgeInsets.zero,
      style: GoogleFonts.notoSansDevanagari(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0D47A1),
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.only(bottom: 2, top: 2),
        hintText: hintText,
        hintStyle: GoogleFonts.notoSansDevanagari(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.black38,
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black54, width: 0.8),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black45, width: 0.8),
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
