import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'form_paper_page.dart';
import 'form_view_scaffold.dart';

/// Draft Ground of Arrest — Exact Marathi BNSS Notice Templates (Pages 9, 10, 11 of 13).
class DraftGroundOfArrestFormView extends StatefulWidget {
  final dynamic existingRecord;
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const DraftGroundOfArrestFormView({
    super.key,
    this.existingRecord,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<DraftGroundOfArrestFormView> createState() =>
      DraftGroundOfArrestFormViewState();
}

class DraftGroundOfArrestFormViewState
    extends State<DraftGroundOfArrestFormView> {
  int? get _activeSection {
    final s = widget.formSection?.toLowerCase().trim() ?? '';
    if (s.isEmpty) return null;
    if (s.contains('pcr') || s.contains('police custody')) return 4;
    if (s.contains('reason of arrest') || s.contains('reason for arrest') || s.contains('page 11')) {
      return 3;
    }
    if (s.contains('relative notice') || s.contains('नातेवाईक') || s.contains('page 10')) {
      return 2;
    }
    if (s.contains('ground of arrest') || s.contains('अटकेचा आधार') || s.contains('page 9')) {
      return 1;
    }
    if (s.contains('ref') || s.contains('guide')) {
      return 0;
    }
    return null;
  }

  bool get _showPage9 => _activeSection == null || _activeSection == 1;
  bool get _showPage10 => _activeSection == null || _activeSection == 2;
  bool get _showPage11 => _activeSection == null || _activeSection == 3;
  bool get _showPage12 => _activeSection == 4;
  bool get _showRefPages => _activeSection == 0;

  // ── Shared / Accused Controllers ──
  final _accusedNameCtrl = TextEditingController();
  final _accusedAgeCtrl = TextEditingController();
  final _accusedAddressCtrl = TextEditingController();
  final _psNameCtrl = TextEditingController();
  final _crNoCtrl = TextEditingController();
  final _bnsSectionCtrl = TextEditingController();
  final _arrestDateCtrl = TextEditingController();
  final _arrestTimeCtrl = TextEditingController();
  final _briefFactsCtrl = TextEditingController();

  // ── Page 9 (Ground of Arrest u/s 47 BNSS) ──
  bool _goaG1 = false;
  bool _goaG2 = false;
  bool _goaG3 = false;
  bool _goaG4 = false;
  bool _goaG5 = false;
  bool _goaG6 = false;
  bool _goaG7 = false;
  final _goaWitnessNameCtrl = TextEditingController();
  final _goaCoAccusedCtrl = TextEditingController();
  final _goaKinNameCtrl = TextEditingController();
  final _goaFooterDateCtrl = TextEditingController();
  final _goaOfficerNameRankCtrl = TextEditingController();
  final _goaAccusedSigCtrl = TextEditingController();

  // ── Page 10 (Relative Notice u/s 48 BNSS) ──
  final _s48RelativeNameCtrl = TextEditingController();
  final _s48RelativeAgeCtrl = TextEditingController();
  final _s48RelativeAddressCtrl = TextEditingController();
  final _s48RelationshipCtrl = TextEditingController();
  final _s48CustodyPsCtrl = TextEditingController();
  bool _s48G1 = false;
  bool _s48G2 = false;
  bool _s48G3 = false;
  bool _s48G5 = false;
  bool _s48G6 = false;
  final _s48WitnessNameCtrl = TextEditingController();
  final _s48CoAccusedCtrl = TextEditingController();
  final _s48DateCtrl = TextEditingController();
  final _s48PlaceCtrl = TextEditingController();
  final _s48OfficerSigCtrl = TextEditingController();
  final _s48RelativeSigCtrl = TextEditingController();

  // ── Page 11 (Reason of Arrest u/s 35(1)(b) BNSS) ──
  bool _roaR1 = false;
  bool _roaR2 = false;
  bool _roaR3 = false;
  bool _roaR4 = false;
  bool _roaR5 = false;
  final _roaDateCtrl = TextEditingController();
  final _roaPlaceCtrl = TextEditingController();
  final _roaOfficerSigCtrl = TextEditingController();
  final _roaAccusedSigCtrl = TextEditingController();

  // ── Page 12 (PCR Reasons optional) ──
  bool _pcr1 = false;
  bool _pcr2 = false;
  bool _pcr3 = false;
  bool _pcr4 = false;
  bool _pcr5 = false;
  bool _pcr6 = false;
  bool _pcr7 = false;
  final _pcrOtherCtrl = TextEditingController();

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
      _accusedNameCtrl,
      _accusedAgeCtrl,
      _accusedAddressCtrl,
      _psNameCtrl,
      _crNoCtrl,
      _bnsSectionCtrl,
      _arrestDateCtrl,
      _arrestTimeCtrl,
      _briefFactsCtrl,
      _goaWitnessNameCtrl,
      _goaCoAccusedCtrl,
      _goaKinNameCtrl,
      _goaFooterDateCtrl,
      _goaOfficerNameRankCtrl,
      _goaAccusedSigCtrl,
      _s48RelativeNameCtrl,
      _s48RelativeAgeCtrl,
      _s48RelativeAddressCtrl,
      _s48RelationshipCtrl,
      _s48CustodyPsCtrl,
      _s48WitnessNameCtrl,
      _s48CoAccusedCtrl,
      _s48DateCtrl,
      _s48PlaceCtrl,
      _s48OfficerSigCtrl,
      _s48RelativeSigCtrl,
      _roaDateCtrl,
      _roaPlaceCtrl,
      _roaOfficerSigCtrl,
      _roaAccusedSigCtrl,
      _pcrOtherCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'accusedName': _accusedNameCtrl.text.trim(),
      'accusedAge': _accusedAgeCtrl.text.trim(),
      'accusedAddress': _accusedAddressCtrl.text.trim(),
      'psName': _psNameCtrl.text.trim(),
      'crNo': _crNoCtrl.text.trim(),
      'bnsSection': _bnsSectionCtrl.text.trim(),
      'arrestDate': _arrestDateCtrl.text.trim(),
      'arrestTime': _arrestTimeCtrl.text.trim(),
      'briefFacts': _briefFactsCtrl.text.trim(),
      // Page 9
      'goaG1': _goaG1,
      'goaG2': _goaG2,
      'goaG3': _goaG3,
      'goaG4': _goaG4,
      'goaG5': _goaG5,
      'goaG6': _goaG6,
      'goaG7': _goaG7,
      'goaWitnessName': _goaWitnessNameCtrl.text.trim(),
      'goaCoAccused': _goaCoAccusedCtrl.text.trim(),
      'goaKinName': _goaKinNameCtrl.text.trim(),
      'goaFooterDate': _goaFooterDateCtrl.text.trim(),
      'goaOfficerNameRank': _goaOfficerNameRankCtrl.text.trim(),
      'goaAccusedSig': _goaAccusedSigCtrl.text.trim(),
      // Page 10
      's48RelativeName': _s48RelativeNameCtrl.text.trim(),
      's48RelativeAge': _s48RelativeAgeCtrl.text.trim(),
      's48RelativeAddress': _s48RelativeAddressCtrl.text.trim(),
      's48Relationship': _s48RelationshipCtrl.text.trim(),
      's48CustodyPs': _s48CustodyPsCtrl.text.trim(),
      's48G1': _s48G1,
      's48G2': _s48G2,
      's48G3': _s48G3,
      's48G5': _s48G5,
      's48G6': _s48G6,
      's48WitnessName': _s48WitnessNameCtrl.text.trim(),
      's48CoAccused': _s48CoAccusedCtrl.text.trim(),
      's48Date': _s48DateCtrl.text.trim(),
      's48Place': _s48PlaceCtrl.text.trim(),
      's48OfficerSig': _s48OfficerSigCtrl.text.trim(),
      's48RelativeSig': _s48RelativeSigCtrl.text.trim(),
      // Page 11
      'roaR1': _roaR1,
      'roaR2': _roaR2,
      'roaR3': _roaR3,
      'roaR4': _roaR4,
      'roaR5': _roaR5,
      'roaDate': _roaDateCtrl.text.trim(),
      'roaPlace': _roaPlaceCtrl.text.trim(),
      'roaOfficerSig': _roaOfficerSigCtrl.text.trim(),
      'roaAccusedSig': _roaAccusedSigCtrl.text.trim(),
      // Page 12
      'pcr1': _pcr1,
      'pcr2': _pcr2,
      'pcr3': _pcr3,
      'pcr4': _pcr4,
      'pcr5': _pcr5,
      'pcr6': _pcr6,
      'pcr7': _pcr7,
      'pcrOther': _pcrOtherCtrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    void setCtrl(TextEditingController c, String key, [String? fallbackKey]) {
      final v = data[key]?.toString() ?? (fallbackKey != null ? data[fallbackKey]?.toString() : null) ?? '';
      c.text = v;
    }

    void setBool(void Function(bool) setter, String key) {
      final v = data[key];
      if (v is bool) {
        setter(v);
      } else if (v is String) {
        setter(v == 'true' || v == '1');
      }
    }

    setCtrl(_accusedNameCtrl, 'accusedName', 'accused_name');
    setCtrl(_accusedAgeCtrl, 'accusedAge', 'accused_age');
    setCtrl(_accusedAddressCtrl, 'accusedAddress', 'accused_address');
    setCtrl(_psNameCtrl, 'psName', 'police_station');
    setCtrl(_crNoCtrl, 'crNo', 'crime_number');
    setCtrl(_bnsSectionCtrl, 'bnsSection', 'bns_section');
    setCtrl(_arrestDateCtrl, 'arrestDate', 'arrest_date');
    setCtrl(_arrestTimeCtrl, 'arrestTime', 'arrest_time');
    setCtrl(_briefFactsCtrl, 'briefFacts', 'brief_facts');

    setBool((v) => _goaG1 = v, 'goaG1');
    setBool((v) => _goaG2 = v, 'goaG2');
    setBool((v) => _goaG3 = v, 'goaG3');
    setBool((v) => _goaG4 = v, 'goaG4');
    setBool((v) => _goaG5 = v, 'goaG5');
    setBool((v) => _goaG6 = v, 'goaG6');
    setBool((v) => _goaG7 = v, 'goaG7');
    setCtrl(_goaWitnessNameCtrl, 'goaWitnessName');
    setCtrl(_goaCoAccusedCtrl, 'goaCoAccused');
    setCtrl(_goaKinNameCtrl, 'goaKinName');
    setCtrl(_goaFooterDateCtrl, 'goaFooterDate');
    setCtrl(_goaOfficerNameRankCtrl, 'goaOfficerNameRank', 'goaOfficerName');
    setCtrl(_goaAccusedSigCtrl, 'goaAccusedSig');

    setCtrl(_s48RelativeNameCtrl, 's48RelativeName');
    setCtrl(_s48RelativeAgeCtrl, 's48RelativeAge');
    setCtrl(_s48RelativeAddressCtrl, 's48RelativeAddress');
    setCtrl(_s48RelationshipCtrl, 's48Relationship');
    setCtrl(_s48CustodyPsCtrl, 's48CustodyPs', 'psName');
    setBool((v) => _s48G1 = v, 's48G1');
    setBool((v) => _s48G2 = v, 's48G2');
    setBool((v) => _s48G3 = v, 's48G3');
    setBool((v) => _s48G5 = v, 's48G5');
    setBool((v) => _s48G6 = v, 's48G6');
    setCtrl(_s48WitnessNameCtrl, 's48WitnessName');
    setCtrl(_s48CoAccusedCtrl, 's48CoAccused');
    setCtrl(_s48DateCtrl, 's48Date');
    setCtrl(_s48PlaceCtrl, 's48Place');
    setCtrl(_s48OfficerSigCtrl, 's48OfficerSig');
    setCtrl(_s48RelativeSigCtrl, 's48RelativeSig');

    setBool((v) => _roaR1 = v, 'roaR1');
    setBool((v) => _roaR2 = v, 'roaR2');
    setBool((v) => _roaR3 = v, 'roaR3');
    setBool((v) => _roaR4 = v, 'roaR4');
    setBool((v) => _roaR5 = v, 'roaR5');
    setCtrl(_roaDateCtrl, 'roaDate');
    setCtrl(_roaPlaceCtrl, 'roaPlace');
    setCtrl(_roaOfficerSigCtrl, 'roaOfficerSig');
    setCtrl(_roaAccusedSigCtrl, 'roaAccusedSig');

    setBool((v) => _pcr1 = v, 'pcr1');
    setBool((v) => _pcr2 = v, 'pcr2');
    setBool((v) => _pcr3 = v, 'pcr3');
    setBool((v) => _pcr4 = v, 'pcr4');
    setBool((v) => _pcr5 = v, 'pcr5');
    setBool((v) => _pcr6 = v, 'pcr6');
    setBool((v) => _pcr7 = v, 'pcr7');
    setCtrl(_pcrOtherCtrl, 'pcrOther');

    if (mounted) setState(() {});
  }

  // ── Input Helper Widgets ──

  Widget _inlineBlank({
    required TextEditingController controller,
    required TextStyle style,
    double? width,
    String? hintText,
    bool readOnly = false,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        readOnly: widget.readOnly || readOnly,
        style: style.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
          color: const Color(0xFF0D47A1),
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: style.copyWith(
            fontSize: 12,
            color: Colors.grey.shade400,
            fontStyle: FontStyle.italic,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF333333), width: 1.0),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF1976D2), width: 2.0),
          ),
        ),
      ),
    );
  }

  Widget _multilineBlankBox({
    required TextEditingController controller,
    required TextStyle style,
    int minLines = 2,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: widget.readOnly,
      minLines: minLines,
      maxLines: null,
      style: style.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14.5,
        height: 1.5,
        color: const Color(0xFF0D47A1),
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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

  // Top Right Prosecutor Box
  Widget _buildTopProsecutorBox(TextStyle mrStyle) {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black87, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gaware Ashok',
              style: mrStyle.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Public Prosecutor A.Nagar',
              style: mrStyle.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '9823911047',
              style: mrStyle.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 9 OF 13 — EXACTLY MATCHING IMAGE 1
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPage9(TextStyle mrStyle) {
    return FormPaperPage(
      formLabel: widget.pageRange ?? 'Page 9 of 13',
      children: [
        _buildTopProsecutorBox(mrStyle),
        const SizedBox(height: 8),

        // Page Number
        Center(
          child: Text(
            'Page 9 of 13',
            style: mrStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Underlined Title
        Center(
          child: Text(
            'अटकेचा आधार (कलम ४७ BNSS)',
            textAlign: TextAlign.center,
            style: mrStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Legal Citation Subtitle
        Text(
          '(भारतीय नागरिक सुरक्षा संहिता, २०२३ च्या कलम ४७ आणि भारतीय संविधान कलम २२(१) अन्वये तसेच माननीय सर्वोच्च न्यायालयाच्या \'पंकज बन्सल\', \'प्रबीर पुरकायस्थ\', \'विहान कुमार\' आणि \'मिहीर शाह\' निवाड्यांमधील मार्गदर्शक तत्त्वांच्या अधीन)',
          textAlign: TextAlign.center,
          style: mrStyle.copyWith(
            fontSize: 12,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // प्रति,
        Text(
          'प्रति,',
          style: mrStyle.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Name of accused
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('अटक केलेल्या आरोपीचे नाव: ', style: mrStyle.copyWith(fontSize: 14.5)),
            Expanded(
              child: _inlineBlank(
                controller: _accusedNameCtrl,
                style: mrStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Age, Address
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('वय: ', style: mrStyle.copyWith(fontSize: 14.5)),
            _inlineBlank(
              controller: _accusedAgeCtrl,
              style: mrStyle,
              width: 70,
            ),
            Text(' वर्ष, पत्ता: ', style: mrStyle.copyWith(fontSize: 14.5)),
            Expanded(
              child: _inlineBlank(
                controller: _accusedAddressCtrl,
                style: mrStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Notice Intimation Paragraph
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 8,
          children: [
            Text(
              'या नोटीसीद्वारे तुम्हाला माहिती करण्यात येते की, तुम्हाला पोलीस ठाणे',
              style: mrStyle.copyWith(fontSize: 14.5, height: 1.6),
            ),
            _inlineBlank(
              controller: _psNameCtrl,
              style: mrStyle,
              width: 170,
            ),
            Text(
              'येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक',
              style: mrStyle.copyWith(fontSize: 14.5),
            ),
            _inlineBlank(
              controller: _crNoCtrl,
              style: mrStyle,
              width: 110,
            ),
            Text(
              ', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम',
              style: mrStyle.copyWith(fontSize: 14.5),
            ),
            _inlineBlank(
              controller: _bnsSectionCtrl,
              style: mrStyle,
              width: 130,
            ),
            Text(
              'अन्वये नोंदवलेल्या गुन्ह्यात आज दिनांक',
              style: mrStyle.copyWith(fontSize: 14.5),
            ),
            _inlineBlank(
              controller: _arrestDateCtrl,
              style: mrStyle,
              width: 110,
            ),
            Text(
              'रोजी वेळ',
              style: mrStyle.copyWith(fontSize: 14.5),
            ),
            _inlineBlank(
              controller: _arrestTimeCtrl,
              style: mrStyle,
              width: 80,
            ),
            Text(
              'वाजता अटक करण्यात आली आहे.',
              style: mrStyle.copyWith(fontSize: 14.5),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Brief facts
        Text(
          'गुन्ह्याची थोडक्यात हकीकत :-',
          style: mrStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
          ),
        ),
        const SizedBox(height: 6),
        _multilineBlankBox(
          controller: _briefFactsCtrl,
          style: mrStyle,
          minLines: 2,
        ),
        const SizedBox(height: 16),

        // Heading: अटकेचा आधार :-
        Text(
          'अटकेचा आधार :-',
          style: mrStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            decoration: TextDecoration.underline,
          ),
        ),
        const SizedBox(height: 8),

        // Table 1: Ground of Arrest
        Table(
          border: TableBorder.all(color: Colors.black87, width: 1.0),
          columnWidths: const {
            0: FixedColumnWidth(60),
            1: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Text(
                    'अ.क्र.',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: Text(
                    'अटकेचे आधार ( Ground of Arrest )',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            _buildCheckTableRow(
              srNo: '१',
              checked: _goaG1,
              onChanged: (v) => setState(() => _goaG1 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'फिर्यादीने दाखल केलेल्या FIR मध्ये तुमचे विरुद्ध आरोप केलेले आहेत.',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
            _buildCheckTableRow(
              srNo: '२',
              checked: _goaG2,
              onChanged: (v) => setState(() => _goaG2 = v ?? false),
              mrStyle: mrStyle,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('प्रत्यक्षदर्शी साक्षीदार [नाव] ', style: mrStyle.copyWith(fontSize: 13.5)),
                  _inlineBlank(
                    controller: _goaWitnessNameCtrl,
                    style: mrStyle,
                    width: 140,
                    hintText: 'साक्षीदाराचे नाव',
                  ),
                  Text(
                    ' यांनी दिलेल्या जबाबानुसार गुन्ह्यामध्ये तुमचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
                    style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
                  ),
                ],
              ),
            ),
            _buildCheckTableRow(
              srNo: '३',
              checked: _goaG3,
              onChanged: (v) => setState(() => _goaG3 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'घटनास्थळावरील पुराव्यांच्या (CCTV / डिजिटल रेकॉर्ड / मोबाईल व्हिडिओ ) आधारे गुन्ह्यामध्ये तुमचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
            _buildCheckTableRow(
              srNo: '४',
              checked: _goaG4,
              onChanged: (v) => setState(() => _goaG4 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'गुन्ह्यात वापरलेले हत्यार / चोरीची मालमत्ता / गुन्ह्याशी संबंधित महत्त्वाचे दस्तऐवज हे केवळ तुमच्याकडे असलेल्या माहितीच्या आधारे आणि तुमच्या ताब्यातून हस्तगत करण्यात आले आहेत.',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
            _buildCheckTableRow(
              srNo: '५',
              checked: _goaG5,
              onChanged: (v) => setState(() => _goaG5 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'तुम्ही गुन्हा केल्याची कबुली दिली आहे.',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
            _buildCheckTableRow(
              srNo: '६',
              checked: _goaG6,
              onChanged: (v) => setState(() => _goaG6 = v ?? false),
              mrStyle: mrStyle,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('गुन्ह्यातील सहआरोपी ', style: mrStyle.copyWith(fontSize: 13.5)),
                  _inlineBlank(
                    controller: _goaCoAccusedCtrl,
                    style: mrStyle,
                    width: 140,
                    hintText: 'सहआरोपीचे नाव',
                  ),
                  Text(
                    ' यांनी तुम्ही गुन्ह्यामध्ये सहभागी असल्याचे कबुल केले आहे.',
                    style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
                  ),
                ],
              ),
            ),
            _buildCheckTableRow(
              srNo: '७',
              checked: _goaG7,
              onChanged: (v) => setState(() => _goaG7 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'मोबाईल CDR वरून घटनेच्या दिवशी तुमचे tower location घटनास्थळाजवळ असल्याचे दिसून आले आहे.',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Heading: आरोपींचे हक्क /अधिकार :-
        Text(
          'आरोपींचे हक्क /अधिकार :-',
          style: mrStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            decoration: TextDecoration.underline,
          ),
        ),
        const SizedBox(height: 8),

        // Table 2: Rights of Accused
        Table(
          border: TableBorder.all(color: Colors.black87, width: 1.0),
          columnWidths: const {
            0: FixedColumnWidth(60),
            1: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Text(
                    'अ.क्र.',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: Text(
                    'आरोपींचे हक्क',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            _buildSimpleTableRow(
              srNo: '१',
              mrStyle: mrStyle,
              child: Text(
                'तुम्हाला माननीय न्यायालयासमोर हजर केल्यावर जामीन अर्ज सादर करण्याचा पूर्ण कायदेशीर अधिकार आहे.',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
            _buildSimpleTableRow(
              srNo: '२',
              mrStyle: mrStyle,
              child: Text(
                'तुमच्या पसंतीच्या कायदेशीर सल्लागाराचा (वकिलाचा) सल्ला घेण्याचा, त्यांना पोलीस कोठडीत भेटण्याचा आणि माननीय न्यायालयासमोर रिमांडला कायदेशीर विरोध करण्याचा पूर्ण अधिकार आहे.',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
            _buildSimpleTableRow(
              srNo: '३',
              mrStyle: mrStyle,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'तुमच्या अटकेची आणि तुम्हाला ज्या ठिकाणी कोठडीत ठेवण्यात आले आहे त्या ठिकाणाची माहिती तुमच्याद्वारे नामांकित केलेले नातेवाईक/मित्र ',
                    style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
                  ),
                  _inlineBlank(
                    controller: _goaKinNameCtrl,
                    style: mrStyle,
                    width: 170,
                    hintText: 'नातेवाईक/मित्र नाव',
                  ),
                  Text(
                    ' यांना देण्यात आली आहे.',
                    style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Footer: दिनांक / पोलीस अधिकारी / आरोपीचे नाव, सही
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('दिनांक :- ', style: mrStyle.copyWith(fontSize: 13.5)),
                      Expanded(
                        child: _inlineBlank(
                          controller: _goaFooterDateCtrl,
                          style: mrStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'पोलीस अधिकारी नाव, हुद्दा सही शिक्का',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  _inlineBlank(
                    controller: _goaOfficerNameRankCtrl,
                    style: mrStyle,
                    hintText: 'नाव व हुद्दा',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'आरोपीचे नाव , सही, अंगठा',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  _inlineBlank(
                    controller: _goaAccusedSigCtrl,
                    style: mrStyle,
                    hintText: 'नाव / सही / अंगठा',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 10 OF 13 — EXACTLY MATCHING IMAGE 2
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPage10(TextStyle mrStyle) {
    return FormPaperPage(
      formLabel: widget.pageRange ?? 'Page 10 of 13',
      children: [
        _buildTopProsecutorBox(mrStyle),
        const SizedBox(height: 8),

        // Page Number
        Center(
          child: Text(
            'Page 10 of 13',
            style: mrStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Underlined Title
        Center(
          child: Text(
            'नातेवाईक/ मित्रांसाठी अटकेच्या माहितीची नोटीस ( कलम ४८ BNSS)',
            textAlign: TextAlign.center,
            style: mrStyle.copyWith(
              fontSize: 17.5,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Subtitle Legal Citation
        Text(
          '(भारतीय नागरिक सुरक्षा संहिता, २०२३ च्या कलम ४८(१) अन्वये माननीय सर्वोच्च न्यायालयाच्या \'पंकज बन्सल\', \'प्रबीर पुरकायस्थ\', \'विहान कुमार\' आणि \'मिहीर शाह\' निवाड्यांमधील मार्गदर्शक तत्त्वांच्या अधीन)',
          textAlign: TextAlign.center,
          style: mrStyle.copyWith(
            fontSize: 12,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // प्रति,
        Text(
          'प्रति,',
          style: mrStyle.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Relative Name, Age, Address
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('नातेवाईक/मित्राचे नाव:- ', style: mrStyle.copyWith(fontSize: 14.5)),
            Expanded(
              flex: 3,
              child: _inlineBlank(
                controller: _s48RelativeNameCtrl,
                style: mrStyle,
              ),
            ),
            Text(' वय :- ', style: mrStyle.copyWith(fontSize: 14.5)),
            _inlineBlank(
              controller: _s48RelativeAgeCtrl,
              style: mrStyle,
              width: 50,
            ),
            Text(' पत्ता:- ', style: mrStyle.copyWith(fontSize: 14.5)),
            Expanded(
              flex: 3,
              child: _inlineBlank(
                controller: _s48RelativeAddressCtrl,
                style: mrStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Relationship
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('आरोपीशी असलेले नाते: ', style: mrStyle.copyWith(fontSize: 14.5)),
            Expanded(
              child: _inlineBlank(
                controller: _s48RelationshipCtrl,
                style: mrStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Notice Intimation Paragraph
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 8,
          children: [
            Text(
              'या नोटीसीद्वारे तुम्हाला, भारतीय नागरिक सुरक्षा संहिता, २०२३ (BNSS) च्या कलम ४८(१) मधील कायदेशीर तरतुदींनुसार अधिकृतपणे सूचित करण्यात येते की, तुमचे/तुमच्या आरोपीचे नाव:',
              style: mrStyle.copyWith(fontSize: 14.5, height: 1.6),
            ),
            _inlineBlank(
              controller: _accusedNameCtrl,
              style: mrStyle,
              width: 180,
            ),
            Text('वय:', style: mrStyle.copyWith(fontSize: 14.5)),
            _inlineBlank(
              controller: _accusedAgeCtrl,
              style: mrStyle,
              width: 50,
            ),
            Text('वर्ष, पत्ता:-', style: mrStyle.copyWith(fontSize: 14.5)),
            _inlineBlank(
              controller: _accusedAddressCtrl,
              style: mrStyle,
              width: 170,
            ),
            Text('यांना पोलीस ठाणे', style: mrStyle.copyWith(fontSize: 14.5)),
            _inlineBlank(
              controller: _psNameCtrl,
              style: mrStyle,
              width: 160,
            ),
            Text('येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक (Cr.No.)', style: mrStyle.copyWith(fontSize: 14.5)),
            _inlineBlank(
              controller: _crNoCtrl,
              style: mrStyle,
              width: 100,
            ),
            Text(', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम', style: mrStyle.copyWith(fontSize: 14.5)),
            _inlineBlank(
              controller: _bnsSectionCtrl,
              style: mrStyle,
              width: 120,
            ),
            Text('अन्वये नोंदवलेल्या गुन्ह्याच्या तपासाच्या अनुषंगाने आज दिनांक', style: mrStyle.copyWith(fontSize: 14.5)),
            _inlineBlank(
              controller: _arrestDateCtrl,
              style: mrStyle,
              width: 100,
            ),
            Text('रोजी वेळ', style: mrStyle.copyWith(fontSize: 14.5)),
            _inlineBlank(
              controller: _arrestTimeCtrl,
              style: mrStyle,
              width: 70,
            ),
            Text('वाजता कायदेशीररीत्या अटक करण्यात आली आहे.', style: mrStyle.copyWith(fontSize: 14.5)),
          ],
        ),
        const SizedBox(height: 14),

        // Brief facts
        Text(
          'गुन्ह्याची थोडक्यात हकीकत :-',
          style: mrStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
          ),
        ),
        const SizedBox(height: 6),
        _multilineBlankBox(
          controller: _briefFactsCtrl,
          style: mrStyle,
          minLines: 2,
        ),
        const SizedBox(height: 16),

        // Heading: आरोपींच्या अटकेबाबत तुम्हाला खालील बाबींची लेखी माहिती देण्यात येत आहे:-
        Text(
          'आरोपींच्या अटकेबाबत तुम्हाला खालील बाबींची लेखी माहिती देण्यात येत आहे:-',
          style: mrStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
          ),
        ),
        const SizedBox(height: 8),

        // Table 1: Information
        Table(
          border: TableBorder.all(color: Colors.black87, width: 1.0),
          columnWidths: const {
            0: FixedColumnWidth(60),
            1: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Text(
                    'अ.क्र.',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: Text(
                    'अटकेबाबत माहिती',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            _buildSimpleTableRow(
              srNo: '१.',
              mrStyle: mrStyle,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('आरोपी नाव ', style: mrStyle.copyWith(fontSize: 13.5)),
                  _inlineBlank(
                    controller: _accusedNameCtrl,
                    style: mrStyle,
                    width: 150,
                  ),
                  Text(' यांना गुन्हा रजिस्टर क्रमांक ', style: mrStyle.copyWith(fontSize: 13.5)),
                  _inlineBlank(
                    controller: _crNoCtrl,
                    style: mrStyle,
                    width: 80,
                  ),
                  Text(', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम ', style: mrStyle.copyWith(fontSize: 13.5)),
                  _inlineBlank(
                    controller: _bnsSectionCtrl,
                    style: mrStyle,
                    width: 100,
                  ),
                  Text(
                    ' अन्वये नोंदवलेल्या गुन्ह्याच्या तपासाच्या अनुषंगाने कायदेशीररीत्या अटक करण्यात आली असून सदर आरोपीला सध्या [पोलीस ठाण्याचे नाव ',
                    style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
                  ),
                  _inlineBlank(
                    controller: _s48CustodyPsCtrl,
                    style: mrStyle,
                    width: 150,
                    hintText: 'पोलीस ठाण्याचे नाव',
                  ),
                  Text(
                    '] येथे ठेवण्यात आले आहे.',
                    style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
                  ),
                ],
              ),
            ),
            _buildSimpleTableRow(
              srNo: '२.',
              mrStyle: mrStyle,
              child: Text(
                'आरोपीला माननीय न्यायालयासमोर हजर केल्यावर जामीन अर्ज सादर करण्याचा पूर्ण कायदेशीर अधिकार आहे.',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
            _buildSimpleTableRow(
              srNo: '३.',
              mrStyle: mrStyle,
              child: Text(
                'तुमच्या पसंतीच्या कायदेशीर सल्लागाराचा (वकिलाचा) सल्ला घेण्याचा, त्यांना पोलीस कोठडीत भेटण्याचा आणि माननीय न्यायालयासमोर रिमांडला कायदेशीर विरोध करण्याचा पूर्ण अधिकार आहे.',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Table 2: Grounds Table (Ground of Arrest)
        Table(
          border: TableBorder.all(color: Colors.black87, width: 1.0),
          columnWidths: const {
            0: FixedColumnWidth(60),
            1: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Text(
                    'अ.क्र.',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: Text(
                    'अटकेचे आधार ( Ground of Arrest )',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            _buildCheckTableRow(
              srNo: '१',
              checked: _s48G1,
              onChanged: (v) => setState(() => _s48G1 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'FIR मध्ये आरोपीने सदर गुन्हा केल्याचा उल्लेख आहे.',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
            _buildCheckTableRow(
              srNo: '२',
              checked: _s48G2,
              onChanged: (v) => setState(() => _s48G2 = v ?? false),
              mrStyle: mrStyle,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('प्रत्यक्षदर्शी साक्षीदार [नाव] ', style: mrStyle.copyWith(fontSize: 13.5)),
                  _inlineBlank(
                    controller: _s48WitnessNameCtrl,
                    style: mrStyle,
                    width: 140,
                    hintText: 'साक्षीदाराचे नाव',
                  ),
                  Text(
                    ' यांनी दिलेल्या जबाबानुसार गुन्ह्यामध्ये आरोपीचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
                    style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
                  ),
                ],
              ),
            ),
            _buildCheckTableRow(
              srNo: '३',
              checked: _s48G3,
              onChanged: (v) => setState(() => _s48G3 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'घटनास्थळावरील पुराव्यांच्या CCTV / डिजिटल रेकॉर्ड आधारे गुन्ह्यामध्ये थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
            _buildCheckTableRow(
              srNo: '५',
              checked: _s48G5,
              onChanged: (v) => setState(() => _s48G5 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'आरोपीने गुन्हा केल्याची कबुली दिली आहे.',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
            _buildCheckTableRow(
              srNo: '६',
              checked: _s48G6,
              onChanged: (v) => setState(() => _s48G6 = v ?? false),
              mrStyle: mrStyle,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('गुन्ह्यातील सहआरोपी ', style: mrStyle.copyWith(fontSize: 13.5)),
                  _inlineBlank(
                    controller: _s48CoAccusedCtrl,
                    style: mrStyle,
                    width: 140,
                    hintText: 'सहआरोपीचे नाव',
                  ),
                  Text(
                    ' यांनी गुन्ह्यामध्ये आरोपी सहभागी असल्याचे कबुल केले आहे.',
                    style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Footer Signatures
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('दिनांक :- ', style: mrStyle.copyWith(fontSize: 13.5)),
                      Expanded(
                        child: _inlineBlank(
                          controller: _s48DateCtrl,
                          style: mrStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('ठिकाण :- ', style: mrStyle.copyWith(fontSize: 13.5)),
                      Expanded(
                        child: _inlineBlank(
                          controller: _s48PlaceCtrl,
                          style: mrStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'पोलीस अधिकारी नाव सही शिक्का',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  _inlineBlank(
                    controller: _s48OfficerSigCtrl,
                    style: mrStyle,
                    hintText: 'नाव, सही, शिक्का',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'नातेवाईक/ मित्र यांचे नाव , सही, अंगठा',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  _inlineBlank(
                    controller: _s48RelativeSigCtrl,
                    style: mrStyle,
                    hintText: 'नाव / सही / अंगठा',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 11 OF 13 — EXACTLY MATCHING IMAGE 3
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPage11(TextStyle mrStyle) {
    return FormPaperPage(
      formLabel: widget.pageRange ?? 'Page 11 of 13',
      children: [
        _buildTopProsecutorBox(mrStyle),
        const SizedBox(height: 8),

        // Page Number
        Center(
          child: Text(
            'Page 11 of 13',
            style: mrStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Underlined Title
        Center(
          child: Text(
            'अटकेचे कारणे [कलम ३५(१)(ब) BNSS ]',
            textAlign: TextAlign.center,
            style: mrStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Subtitle Legal Citation
        Text(
          '(भारतीय नागरिक सुरक्षा संहिता, २०२३ कलम ३५(१)(ब) अन्वये मा. सर्वोच्च न्यायालयाच्या मार्गदर्शक तत्त्वांच्या निकषांच्या अधीन)',
          textAlign: TextAlign.center,
          style: mrStyle.copyWith(
            fontSize: 12,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // प्रति,
        Text(
          'प्रति,',
          style: mrStyle.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Accused Name
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('अटक केलेल्या आरोपीचे नाव:- ', style: mrStyle.copyWith(fontSize: 14.5)),
            Expanded(
              child: _inlineBlank(
                controller: _accusedNameCtrl,
                style: mrStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Age, Address
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('वय:- ', style: mrStyle.copyWith(fontSize: 14.5)),
            _inlineBlank(
              controller: _accusedAgeCtrl,
              style: mrStyle,
              width: 70,
            ),
            Text(' वर्ष, पत्ता:- ', style: mrStyle.copyWith(fontSize: 14.5)),
            Expanded(
              child: _inlineBlank(
                controller: _accusedAddressCtrl,
                style: mrStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Notice Intimation Paragraph
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 8,
          children: [
            Text(
              'या नोटीसीद्वारे तुम्हाला सूचित करण्यात येते की, पोलीस ठाणे [पोलीस ठाण्याचे नाव]',
              style: mrStyle.copyWith(fontSize: 14.5, height: 1.6),
            ),
            _inlineBlank(
              controller: _psNameCtrl,
              style: mrStyle,
              width: 170,
            ),
            Text('येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक', style: mrStyle.copyWith(fontSize: 14.5)),
            _inlineBlank(
              controller: _crNoCtrl,
              style: mrStyle,
              width: 110,
            ),
            Text(', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम', style: mrStyle.copyWith(fontSize: 14.5)),
            _inlineBlank(
              controller: _bnsSectionCtrl,
              style: mrStyle,
              width: 130,
            ),
            Text('अन्वये नोंदवलेल्या गुन्ह्यात तपासाच्या अनुषंगाने आज दिनांक', style: mrStyle.copyWith(fontSize: 14.5)),
            _inlineBlank(
              controller: _arrestDateCtrl,
              style: mrStyle,
              width: 110,
            ),
            Text('रोजी वेळ', style: mrStyle.copyWith(fontSize: 14.5)),
            _inlineBlank(
              controller: _arrestTimeCtrl,
              style: mrStyle,
              width: 80,
            ),
            Text('वाजता अटक करण्यात आली आहे.', style: mrStyle.copyWith(fontSize: 14.5)),
          ],
        ),
        const SizedBox(height: 14),

        // Brief facts
        Text(
          'गुन्ह्याची थोडक्यात हकीकत :-',
          style: mrStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
          ),
        ),
        const SizedBox(height: 6),
        _multilineBlankBox(
          controller: _briefFactsCtrl,
          style: mrStyle,
          minLines: 2,
        ),
        const SizedBox(height: 16),

        // Heading: अटकेची कारणे (Reasons for Arrest) खालीलप्रमाणे लिखित स्वरूपात पुरवण्यात येत आहेत:-
        Text(
          'अटकेची कारणे (Reasons for Arrest) खालीलप्रमाणे लिखित स्वरूपात पुरवण्यात येत आहेत:-',
          style: mrStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
          ),
        ),
        const SizedBox(height: 8),

        // Reasons Table
        Table(
          border: TableBorder.all(color: Colors.black87, width: 1.0),
          columnWidths: const {
            0: FixedColumnWidth(60),
            1: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Text(
                    'अ.क्र.',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: Text(
                    'अटकेचे कारणे ( Reason of Arrest )',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            _buildCheckTableRow(
              srNo: '१',
              checked: _roaR1,
              onChanged: (v) => setState(() => _roaR1 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'या पुढे कोणताही गुन्हा करण्यास प्रतिबंध करण्यासाठी अटक करण्यात आली आहे.',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
            _buildCheckTableRow(
              srNo: '२',
              checked: _roaR2,
              onChanged: (v) => setState(() => _roaR2 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'गुन्ह्याचा योग्य तपास / अन्वेषण करण्यासाठी .',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
            _buildCheckTableRow(
              srNo: '३',
              checked: _roaR3,
              onChanged: (v) => setState(() => _roaR3 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'गुन्ह्यातील पुरावा नष्ट किंवा पुराव्यांशी छेडछाड / फेरफार करण्यापासून रोखण्यासाठी',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
            _buildCheckTableRow(
              srNo: '४',
              checked: _roaR4,
              onChanged: (v) => setState(() => _roaR4 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'गुन्ह्यातील साक्षीदारांना धाक, धाकडपटशा, वचन किंवा प्रलोभन देण्यापासून रोखणे, धमकावण्यापासून रोखण्यासाठी',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
            _buildCheckTableRow(
              srNo: '५',
              checked: _roaR5,
              onChanged: (v) => setState(() => _roaR5 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'न्यायालयातील उपस्थिती निश्चित करण्यासाठी अटक न केल्यास तुम्ही तपासातून आणि न्यायालयाच्या प्रक्रियेतून फरार होण्याची शक्यता आहे',
                style: mrStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Footer Signatures
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('दिनांक :- ', style: mrStyle.copyWith(fontSize: 13.5)),
                      Expanded(
                        child: _inlineBlank(
                          controller: _roaDateCtrl,
                          style: mrStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('ठिकाण :- ', style: mrStyle.copyWith(fontSize: 13.5)),
                      Expanded(
                        child: _inlineBlank(
                          controller: _roaPlaceCtrl,
                          style: mrStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'पोलीस अधिकारी नाव सही शिक्का',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  _inlineBlank(
                    controller: _roaOfficerSigCtrl,
                    style: mrStyle,
                    hintText: 'नाव, सही, शिक्का',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'आरोपीचे नाव , सही, अंगठा',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  _inlineBlank(
                    controller: _roaAccusedSigCtrl,
                    style: mrStyle,
                    hintText: 'नाव / सही / अंगठा',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 12 (PCR REASONS — Optional Section)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPage12(TextStyle mrStyle) {
    return FormPaperPage(
      formLabel: 'Page 12 of 13',
      children: [
        _buildTopProsecutorBox(mrStyle),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Page 12 of 13',
            style: mrStyle.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'पोलिस कोठडीची कारणे (Reason for PCR)',
            textAlign: TextAlign.center,
            style: mrStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 1.0),
          columnWidths: const {
            0: FixedColumnWidth(60),
            1: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Text(
                    'अ.क्र.',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: Text(
                    'कोठडीची कारणे',
                    textAlign: TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            _buildCheckTableRow(
              srNo: '१',
              checked: _pcr1,
              onChanged: (v) => setState(() => _pcr1 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'गुन्ह्यात वापरलेले हत्यार जप्त करणे बाकी आहे.',
                style: mrStyle.copyWith(fontSize: 13.5),
              ),
            ),
            _buildCheckTableRow(
              srNo: '२',
              checked: _pcr2,
              onChanged: (v) => setState(() => _pcr2 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'गुन्हा करण्यामागील हेतू माहित करावयाचा आहे.',
                style: mrStyle.copyWith(fontSize: 13.5),
              ),
            ),
            _buildCheckTableRow(
              srNo: '३',
              checked: _pcr3,
              onChanged: (v) => setState(() => _pcr3 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'अजून कोणी आरोपी आहेत का याची माहिती घ्यावयाची आहे.',
                style: mrStyle.copyWith(fontSize: 13.5),
              ),
            ),
            _buildCheckTableRow(
              srNo: '४',
              checked: _pcr4,
              onChanged: (v) => setState(() => _pcr4 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'चोरी गेलेली रक्कम, सोन्याचे अलंकार जप्त करावयाचे आहेत.',
                style: mrStyle.copyWith(fontSize: 13.5),
              ),
            ),
            _buildCheckTableRow(
              srNo: '५',
              checked: _pcr5,
              onChanged: (v) => setState(() => _pcr5 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'गुन्ह्यात वापरलेले वाहन जप्त करावयाचे आहे.',
                style: mrStyle.copyWith(fontSize: 13.5),
              ),
            ),
            _buildCheckTableRow(
              srNo: '६',
              checked: _pcr6,
              onChanged: (v) => setState(() => _pcr6 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'आरोपीचे कपडे जप्त करावयाचे आहेत.',
                style: mrStyle.copyWith(fontSize: 13.5),
              ),
            ),
            _buildCheckTableRow(
              srNo: '७',
              checked: _pcr7,
              onChanged: (v) => setState(() => _pcr7 = v ?? false),
              mrStyle: mrStyle,
              child: Text(
                'आरोपीचे ब्लड सॅम्पल घेणे बाकी आहे.',
                style: mrStyle.copyWith(fontSize: 13.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '८) इतर कारणे (इत्यादी) :-',
          style: mrStyle.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        _multilineBlankBox(
          controller: _pcrOtherCtrl,
          style: mrStyle,
          minLines: 2,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REFERENCE PAGES (Pages 1-8 — Reference Only)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRefPages(TextStyle mrStyle) {
    return FormPaperPage(
      formLabel: 'Reference Pages 1–8',
      children: [
        _buildTopProsecutorBox(mrStyle),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'अटकेचा आधार व कारणे — कायदेशीर संदर्भ व मार्गदर्शक तत्त्वे',
            textAlign: TextAlign.center,
            style: mrStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'भारतीय नागरिक सुरक्षा संहिता (BNSS), २०२३ आणि सर्वोच्च न्यायालयाच्या मार्गदर्शक सूचनांनुसार अटकेचा आधार व कारणे लेखी देणे बंधनकारक आहे.',
          style: mrStyle.copyWith(fontSize: 13.5, height: 1.5),
        ),
        const SizedBox(height: 10),
        Text(
          '१. कलम ४७ BNSS: अटकेचा आधार (Ground of Arrest) — सर्व गुन्ह्यांसाठी आवश्यक पुरावे.\n'
          '२. कलम ४८ BNSS: नातेवाईक/मित्रांना अटकेची लेखी माहिती देणे.\n'
          '३. कलम ३५(१)(ब) BNSS: अटकेची कारणे (Reason of Arrest) — ७ वर्षांपेक्षा कमी शिक्षा असलेल्या गुन्ह्यांसाठी ५ विशिष्ट कारणे.',
          style: mrStyle.copyWith(fontSize: 13.5, height: 1.5),
        ),
      ],
    );
  }

  // ── Table Row Builders ──

  TableRow _buildCheckTableRow({
    required String srNo,
    required bool checked,
    required ValueChanged<bool?> onChanged,
    required TextStyle mrStyle,
    required Widget child,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Checkbox(
                value: checked,
                onChanged: widget.readOnly ? null : onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                srNo,
                style: mrStyle.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: child,
        ),
      ],
    );
  }

  TableRow _buildSimpleTableRow({
    required String srNo,
    required TextStyle mrStyle,
    required Widget child,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            srNo,
            textAlign: TextAlign.center,
            style: mrStyle.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: child,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mrStyle = GoogleFonts.notoSansDevanagari(
      fontSize: 14.5,
      fontWeight: FontWeight.normal,
      color: Colors.black87,
    );

    final pages = <Widget>[];

    if (_showRefPages) {
      pages.add(_buildRefPages(mrStyle));
      pages.add(const SizedBox(height: 24));
    }

    if (_showPage9) {
      pages.add(_buildPage9(mrStyle));
      pages.add(const SizedBox(height: 24));
    }
    if (_showPage10) {
      pages.add(_buildPage10(mrStyle));
      pages.add(const SizedBox(height: 24));
    }
    if (_showPage11) {
      pages.add(_buildPage11(mrStyle));
      pages.add(const SizedBox(height: 24));
    }
    if (_showPage12) {
      pages.add(_buildPage12(mrStyle));
    }

    if (pages.isNotEmpty && pages.last is SizedBox) {
      pages.removeLast();
    }

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: pages,
    );
  }
}
