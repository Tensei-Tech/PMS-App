import 'package:flutter/material.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// Draft Ground of Arrest:
/// Page 9: अटकेचा आधार (कलम ४७ BNSS) — Notice to Accused
/// Page 10: नातेवाईक/ मित्रांसाठी अटकेच्या माहितीची नोटीस (कलम ४८ BNSS) — Notice to Relative
/// Page 11: अटकेचे कारणे [कलम ३५(१)(ब) BNSS ] — Reasons of Arrest to Accused
class DraftGroundOfArrestFormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const DraftGroundOfArrestFormView({
    super.key,
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
  // Shared Accused & Arrest fields
  final _accusedNameCtrl = TextEditingController();
  final _accusedAgeCtrl = TextEditingController();
  final _accusedAddressCtrl = TextEditingController();
  final _psNameCtrl = TextEditingController();
  final _crNoCtrl = TextEditingController();
  final _bnsSectionCtrl = TextEditingController();
  final _arrestDateCtrl = TextEditingController();
  final _arrestTimeCtrl = TextEditingController();
  final _custodyPsCtrl = TextEditingController();

  // Brief facts (shared)
  final _briefFactsCtrl = TextEditingController();

  // Page 10: Relative / Friend fields
  final _relativeNameCtrl = TextEditingController();
  final _relativeAgeCtrl = TextEditingController();
  final _relativeAddressCtrl = TextEditingController();
  final _relationshipCtrl = TextEditingController();

  // Grounds of arrest (Page 9 & 10)
  bool _g1Fir = true;
  bool _g2Witness = true;
  final _witnessNameCtrl = TextEditingController();
  bool _g3Cctv = true;
  bool _g4Recovery = true;
  bool _g5Confession = true;
  bool _g6CoAccused = true;
  final _coAccusedNameCtrl = TextEditingController();
  bool _g7Cdr = true;

  // Reasons of arrest (Page 11)
  bool _roaR1 = true;
  bool _roaR2 = true;
  bool _roaR3 = true;
  bool _roaR4 = true;
  bool _roaR5 = true;

  // Footer / Signatures
  final _noticeDateCtrl = TextEditingController();
  final _noticePlaceCtrl = TextEditingController();
  final _officerNameCtrl = TextEditingController();
  final _relativeSigCtrl = TextEditingController();

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
      _custodyPsCtrl,
      _briefFactsCtrl,
      _relativeNameCtrl,
      _relativeAgeCtrl,
      _relativeAddressCtrl,
      _relationshipCtrl,
      _witnessNameCtrl,
      _coAccusedNameCtrl,
      _noticeDateCtrl,
      _noticePlaceCtrl,
      _officerNameCtrl,
      _relativeSigCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      // Accused details
      'accusedName': _accusedNameCtrl.text.trim(),
      'accusedAge': _accusedAgeCtrl.text.trim(),
      'accusedAddress': _accusedAddressCtrl.text.trim(),
      'psName': _psNameCtrl.text.trim(),
      'crNo': _crNoCtrl.text.trim(),
      'bnsSection': _bnsSectionCtrl.text.trim(),
      'arrestDate': _arrestDateCtrl.text.trim(),
      'arrestTime': _arrestTimeCtrl.text.trim(),
      'custodyPs': _custodyPsCtrl.text.trim(),
      // Facts
      'briefFacts': _briefFactsCtrl.text.trim(),
      // Relative details
      'relativeName': _relativeNameCtrl.text.trim(),
      'relativeAge': _relativeAgeCtrl.text.trim(),
      'relativeAddress': _relativeAddressCtrl.text.trim(),
      'relationship': _relationshipCtrl.text.trim(),
      // Grounds
      'g1Fir': _g1Fir,
      'g2Witness': _g2Witness,
      'witnessName': _witnessNameCtrl.text.trim(),
      'g3Cctv': _g3Cctv,
      'g4Recovery': _g4Recovery,
      'g5Confession': _g5Confession,
      'g6CoAccused': _g6CoAccused,
      'coAccusedName': _coAccusedNameCtrl.text.trim(),
      'g7Cdr': _g7Cdr,
      // Reasons (Section 35(1)(b))
      'roaR1': _roaR1,
      'roaR2': _roaR2,
      'roaR3': _roaR3,
      'roaR4': _roaR4,
      'roaR5': _roaR5,
      // Footer
      'noticeDate': _noticeDateCtrl.text.trim(),
      'noticePlace': _noticePlaceCtrl.text.trim(),
      'officerName': _officerNameCtrl.text.trim(),
      'relativeSig': _relativeSigCtrl.text.trim(),
      // Backward compatibility aliases
      's48RelativeName': _relativeNameCtrl.text.trim(),
      's48RelativeAge': _relativeAgeCtrl.text.trim(),
      's48RelativeAddress': _relativeAddressCtrl.text.trim(),
      's48Relationship': _relationshipCtrl.text.trim(),
      's48CustodyPs': _custodyPsCtrl.text.trim(),
      's48G1': _g1Fir,
      's48G2': _g2Witness,
      's48G3': _g3Cctv,
      's48G5': _g5Confession,
      's48G6': _g6CoAccused,
      's48WitnessName': _witnessNameCtrl.text.trim(),
      's48CoAccused': _coAccusedNameCtrl.text.trim(),
      's48Date': _noticeDateCtrl.text.trim(),
      's48Place': _noticePlaceCtrl.text.trim(),
      's48OfficerSig': _officerNameCtrl.text.trim(),
      's48RelativeSig': _relativeSigCtrl.text.trim(),
      'roaDate': _noticeDateCtrl.text.trim(),
      'roaPlace': _noticePlaceCtrl.text.trim(),
      'roaOfficerSig': _officerNameCtrl.text.trim(),
      'roaAccusedSig': _accusedNameCtrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    void setCtrl(TextEditingController c, List<String> keys) {
      for (final k in keys) {
        final v = data[k];
        if (v != null && v.toString().trim().isNotEmpty) {
          c.text = v.toString().trim();
          return;
        }
      }
    }

    void setBool(
      void Function(bool) setter,
      List<String> keys,
      bool defaultVal,
    ) {
      for (final k in keys) {
        final v = data[k];
        if (v is bool) {
          setter(v);
          return;
        }
      }
      setter(defaultVal);
    }

    setCtrl(_accusedNameCtrl, ['accusedName']);
    setCtrl(_accusedAgeCtrl, ['accusedAge']);
    setCtrl(_accusedAddressCtrl, ['accusedAddress']);
    setCtrl(_psNameCtrl, ['psName']);
    setCtrl(_crNoCtrl, ['crNo']);
    setCtrl(_bnsSectionCtrl, ['bnsSection']);
    setCtrl(_arrestDateCtrl, ['arrestDate']);
    setCtrl(_arrestTimeCtrl, ['arrestTime']);
    setCtrl(_custodyPsCtrl, ['custodyPs', 's48CustodyPs']);

    setCtrl(_briefFactsCtrl, ['briefFacts']);

    setCtrl(_relativeNameCtrl, ['relativeName', 's48RelativeName']);
    setCtrl(_relativeAgeCtrl, ['relativeAge', 's48RelativeAge']);
    setCtrl(_relativeAddressCtrl, ['relativeAddress', 's48RelativeAddress']);
    setCtrl(_relationshipCtrl, ['relationship', 's48Relationship']);

    setBool((v) => _g1Fir = v, ['g1Fir', 's48G1'], true);
    setBool((v) => _g2Witness = v, ['g2Witness', 's48G2'], true);
    setCtrl(_witnessNameCtrl, ['witnessName', 's48WitnessName']);
    setBool((v) => _g3Cctv = v, ['g3Cctv', 's48G3'], true);
    setBool((v) => _g4Recovery = v, ['g4Recovery'], true);
    setBool((v) => _g5Confession = v, ['g5Confession', 's48G5'], true);
    setBool((v) => _g6CoAccused = v, ['g6CoAccused', 's48G6'], true);
    setCtrl(_coAccusedNameCtrl, ['coAccusedName', 's48CoAccused']);
    setBool((v) => _g7Cdr = v, ['g7Cdr'], true);

    setBool((v) => _roaR1 = v, ['roaR1'], true);
    setBool((v) => _roaR2 = v, ['roaR2'], true);
    setBool((v) => _roaR3 = v, ['roaR3'], true);
    setBool((v) => _roaR4 = v, ['roaR4'], true);
    setBool((v) => _roaR5 = v, ['roaR5'], true);

    setCtrl(_noticeDateCtrl, ['noticeDate', 's48Date', 'roaDate']);
    setCtrl(_noticePlaceCtrl, ['noticePlace', 's48Place', 'roaPlace']);
    setCtrl(_officerNameCtrl, ['officerName', 's48OfficerSig', 'roaOfficerSig']);
    setCtrl(_relativeSigCtrl, ['relativeSig', 's48RelativeSig']);

    if (mounted) setState(() {});
  }

  Widget _buildProsecutorBox(String pageLabel, TextStyle serif, TextStyle marathi) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 80),
        Text(
          pageLabel,
          style: marathi.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Text(
                'Gaware Ashok',
                style: serif.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Public Prosecutor A.Nagar',
                style: serif.copyWith(fontSize: 9.5),
              ),
              Text('9823911047', style: serif.copyWith(fontSize: 9.5)),
            ],
          ),
        ),
      ],
    );
  }

  bool get _showPage9 {
    final s = (widget.formSection ?? '').toLowerCase();
    if (s.isEmpty || s.contains('complete')) return true;
    return s.contains('9') || s.contains('47') || s.contains('आधार');
  }

  bool get _showPage10 {
    final s = (widget.formSection ?? '').toLowerCase();
    if (s.isEmpty || s.contains('complete')) return true;
    return s.contains('10') || s.contains('48') || s.contains('नातेवाईक');
  }

  bool get _showPage11 {
    final s = (widget.formSection ?? '').toLowerCase();
    if (s.isEmpty || s.contains('complete')) return true;
    return s.contains('11') || s.contains('35') || s.contains('कारणे');
  }

  bool get _showAll => !_showPage9 && !_showPage10 && !_showPage11;

  @override
  Widget build(BuildContext context) {
    final serif = FormTypography.serifStyle();
    final marathiBody = FormTypography.marathiLabelStyle(
      fontWeight: FontWeight.normal,
    ).copyWith(fontSize: 13, height: 1.6, color: Colors.black87);
    final marathiBold = FormTypography.marathiLabelStyle(
      fontWeight: FontWeight.bold,
    ).copyWith(fontSize: 13, color: Colors.black87);

    final show9 = _showPage9 || _showAll;
    final show10 = _showPage10 || _showAll;
    final show11 = _showPage11 || _showAll;

    final pages = <Widget>[];
    if (show9) {
      pages.add(_buildPage9(serif, marathiBody, marathiBold));
    }
    if (show10) {
      if (pages.isNotEmpty) pages.add(const SizedBox(height: 32));
      pages.add(_buildPage10(serif, marathiBody, marathiBold));
    }
    if (show11) {
      if (pages.isNotEmpty) pages.add(const SizedBox(height: 32));
      pages.add(_buildPage11(serif, marathiBody, marathiBold));
    }

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: pages,
    );
  }

  Widget _buildPage9(
    TextStyle serif,
    TextStyle marathiBody,
    TextStyle marathiBold,
  ) {
    return FormPaperPage(
          formLabel: 'Page 9 of 13 — अटकेचा आधार (कलम ४७ BNSS)',
          children: [
            _buildProsecutorBox('Page 9 of 13', serif, marathiBody),
            const SizedBox(height: 12),

            // Form Title
            Center(
              child: Text(
                'अटकेचा आधार (कलम ४७ BNSS)',
                style: marathiBold.copyWith(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 5),

            // Subtitle
            Center(
              child: Text(
                '(भारतीय नागरिक सुरक्षा संहिता, २०२३ च्या कलम ४७ आणि भारतीय संविधान कलम २२(१) अन्वये तसेच माननीय सर्वोच्च न्यायालयाच्या \'पंकज बन्सल\', \'प्रबीर पुरकायस्थ\', \'विद्वान कुमार\' आणि \'मिहीर शाह\' निवाड्यांमधील मार्गदर्शक तत्त्वांच्या अधीन)',
                style: marathiBody.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // Paragraph: प्रति & आरोपी नाव
            Text('प्रति,', style: marathiBold),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('अटक केलेल्या आरोपीचे नाव: ', style: marathiBold),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _accusedNameCtrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('वय: ', style: marathiBold),
                SizedBox(
                  width: 60,
                  child: BilingualSimpleUnderlineInput(
                    controller: _accusedAgeCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(' वर्ष, पत्ता: ', style: marathiBold),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _accusedAddressCtrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Notice Paragraph (Flowing text with inline blanks)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 8,
              children: [
                Text(
                  'या नोटीसद्वारे तुम्हाला माहिती करण्यात येते की, तुम्हाला पोलीस ठाणे',
                  style: marathiBody,
                ),
                SizedBox(
                  width: 140,
                  child: BilingualSimpleUnderlineInput(
                    controller: _psNameCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक', style: marathiBody),
                SizedBox(
                  width: 130,
                  child: BilingualSimpleUnderlineInput(
                    controller: _crNoCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(
                  ', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम',
                  style: marathiBody,
                ),
                SizedBox(
                  width: 120,
                  child: BilingualSimpleUnderlineInput(
                    controller: _bnsSectionCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(
                  'अन्वये नोंदवलेल्या गुन्ह्यात आज दिनांक',
                  style: marathiBody,
                ),
                SizedBox(
                  width: 110,
                  child: BilingualSimpleUnderlineInput(
                    controller: _arrestDateCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('रोजी वेळ', style: marathiBody),
                SizedBox(
                  width: 90,
                  child: BilingualSimpleUnderlineInput(
                    controller: _arrestTimeCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('वाजता अटक करण्यात आली आहे.', style: marathiBody),
              ],
            ),
            const SizedBox(height: 14),

            // Brief facts
            Text('गुन्ह्याची थोडक्यात हकीकत :-', style: marathiBold),
            const SizedBox(height: 4),
            TextField(
              controller: _briefFactsCtrl,
              maxLines: 2,
              style: marathiBody.copyWith(
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                border: UnderlineInputBorder(),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Table 1: Grounds
            Text('अटकेचा आधार :-', style: marathiBold),
            const SizedBox(height: 6),
            Table(
              border: TableBorder.all(color: Colors.black87, width: 0.8),
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Center(child: Text('अ.क्र.', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Center(
                        child: Text(
                          'अटकेचे आधार ( Ground of Arrest )',
                          style: marathiBold,
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('१', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'फिर्यादीने दाखल केलेल्या FIR मध्ये तुमचे विरुद्ध आरोप केलेले आहेत.',
                        style: marathiBody,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('२', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('प्रत्यक्षदर्शी साक्षीदार ', style: marathiBody),
                          SizedBox(
                            width: 140,
                            child: BilingualSimpleUnderlineInput(
                              controller: _witnessNameCtrl,
                              serifStyle: serif,
                              hintText: '[नाव]',
                            ),
                          ),
                          Text(
                            ' यांनी दिलेल्या जबाबानुसार गुन्ह्यामध्ये तुमचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
                            style: marathiBody,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('३', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'घटनास्थळावरील पुराव्यांच्या (CCTV / डिजिटल रेकॉर्ड / मोबाईल व्हिडिओ ) आधारे गुन्ह्यामध्ये तुमचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
                        style: marathiBody,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('4', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'गुन्ह्यात वापरलेले हत्यार / चोरीची मालमत्ता / गुन्ह्याशी संबंधित महत्त्वाचे दस्तऐवज हे केवळ तुमच्याकडे असलेल्या माहितीच्या आधारे आणि तुमच्या ताब्यातून हस्तगत करण्यात आले आहेत.',
                        style: marathiBody,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('५', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('तुम्ही गुन्हा केल्याची कबुली दिली आहे.', style: marathiBody),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('६', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('गुन्ह्यातील सहआरोपी ', style: marathiBody),
                          SizedBox(
                            width: 140,
                            child: BilingualSimpleUnderlineInput(
                              controller: _coAccusedNameCtrl,
                              serifStyle: serif,
                              hintText: '___________',
                            ),
                          ),
                          Text(
                            ' यांनी तुम्ही गुन्ह्यामध्ये सहभागी असल्याचे कबुल केले आहे.',
                            style: marathiBody,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('७', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'मोबाईल CDR वरून घटनेच्या दिवशी तुमचे tower location घटनास्थळाजवळ असल्याचे दिसून आले आहे.',
                        style: marathiBody,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table 2: Rights of Accused
            Text('आरोपीचे हक्क /अधिकार :-', style: marathiBold),
            const SizedBox(height: 6),
            Table(
              border: TableBorder.all(color: Colors.black87, width: 0.8),
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Center(child: Text('अ.क्र.', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Center(child: Text('आरोपींचे हक्क', style: marathiBold)),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('१', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'तुम्हाला माननीय न्यायालयासमोर हजर केल्यावर जामीन अर्ज सादर करण्याचा पूर्ण कायदेशीर अधिकार आहे.',
                        style: marathiBody,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('२', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'तुमच्या पसंतीच्या कायदेशीर सल्लागाराचा (वकिलाचा) सल्ला घेण्याचा, त्यांना पोलीस कोठडीत भेटण्याचा आणि माननीय न्यायालयासमोर रिमांडला कायदेशीर विरोध करण्याचा पूर्ण अधिकार आहे.',
                        style: marathiBody,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('३', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'तुमच्या अटकेची आणि तुम्हाला ज्या ठिकाणी कोठडीत ठेवण्यात आले आहे त्या ठिकाणाची माहिती तुमच्याद्वारे नामांकित केलेले नातेवाईक/मित्र ',
                            style: marathiBody,
                          ),
                          SizedBox(
                            width: 170,
                            child: BilingualSimpleUnderlineInput(
                              controller: _relativeNameCtrl,
                              serifStyle: serif,
                              hintText: '____________________________',
                            ),
                          ),
                          Text(' यांना देण्यात आली आहे.', style: marathiBody),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Page 9 Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('दिनांक :- ', style: marathiBold),
                    SizedBox(
                      width: 100,
                      child: BilingualSimpleUnderlineInput(
                        controller: _noticeDateCtrl,
                        serifStyle: serif,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    SizedBox(
                      width: 180,
                      child: BilingualSimpleUnderlineInput(
                        controller: _officerNameCtrl,
                        serifStyle: serif,
                        hintText: 'अधिकारी नाव, हुद्दा',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('पोलीस अधिकारी नाव, हुद्दा सही शिक्का', style: marathiBody),
                  ],
                ),
                Column(
                  children: [
                    SizedBox(
                      width: 160,
                      child: Text(
                        _accusedNameCtrl.text.isNotEmpty ? _accusedNameCtrl.text : '',
                        style: marathiBold.copyWith(color: Colors.blue.shade900),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('आरोपीचे नाव , सही, अंगठा', style: marathiBody),
                  ],
                ),
              ],
            ),
          ],
        );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ── PAGE 2: नातेवाईक/ मित्रांसाठी अटकेची नोटीस (कलम ४८ BNSS) ──
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildPage10(
    TextStyle serif,
    TextStyle marathiBody,
    TextStyle marathiBold,
  ) {
    return FormPaperPage(
          formLabel: 'Page 10 of 13 — नातेवाईक/ मित्रांसाठी अटकेची नोटीस (कलम ४८ BNSS)',
          children: [
            _buildProsecutorBox('Page 10 of 13', serif, marathiBody),
            const SizedBox(height: 12),

            // Form Title
            Center(
              child: Text(
                'नातेवाईक/ मित्रांसाठी अटकेच्या माहितीची नोटीस ( कलम ४८ BNSS)',
                style: marathiBold.copyWith(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 5),

            // Subtitle
            Center(
              child: Text(
                '(भारतीय नागरिक सुरक्षा संहिता, २०२३ च्या कलम ४८(१) अन्वये माननीय सर्वोच्च न्यायालयाच्या \'पंकज बन्सल\', \'प्रबीर पुरकायस्थ\', \'विद्वान कुमार\' आणि \'मिहीर शाह\' निवाड्यांमधील मार्गदर्शक तत्त्वांच्या अधीन)',
                style: marathiBody.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // Section: प्रति (नातेवाईक / मित्र)
            Text('प्रति,', style: marathiBold),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('नातेवाईक/मित्राचे नाव:- ', style: marathiBold),
                Expanded(
                  flex: 3,
                  child: BilingualSimpleUnderlineInput(
                    controller: _relativeNameCtrl,
                    serifStyle: serif,
                  ),
                ),
                const SizedBox(width: 8),
                Text('वय :- ', style: marathiBold),
                SizedBox(
                  width: 50,
                  child: BilingualSimpleUnderlineInput(
                    controller: _relativeAgeCtrl,
                    serifStyle: serif,
                  ),
                ),
                const SizedBox(width: 8),
                Text('पत्ता:- ', style: marathiBold),
                Expanded(
                  flex: 4,
                  child: BilingualSimpleUnderlineInput(
                    controller: _relativeAddressCtrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('आरोपीशी असलेले नाते: ', style: marathiBold),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _relationshipCtrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Flowing Paragraph for Page 10
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 8,
              children: [
                Text(
                  'या नोटीसद्वारे तुम्हाला, भारतीय नागरिक सुरक्षा संहिता, २०२३ (BNSS) च्या कलम ४८(१) मधील कायदेशीर तरतुदींनुसार अधिकृतपणे सूचित करण्यात येते की, तुमचे/तुमच्या आरोपीचे नाव: ',
                  style: marathiBody,
                ),
                SizedBox(
                  width: 170,
                  child: BilingualSimpleUnderlineInput(
                    controller: _accusedNameCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('वय: ', style: marathiBody),
                SizedBox(
                  width: 50,
                  child: BilingualSimpleUnderlineInput(
                    controller: _accusedAgeCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('वर्ष, पत्ता:- ', style: marathiBody),
                SizedBox(
                  width: 160,
                  child: BilingualSimpleUnderlineInput(
                    controller: _accusedAddressCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('यांना पोलीस ठाणे ', style: marathiBody),
                SizedBox(
                  width: 140,
                  child: BilingualSimpleUnderlineInput(
                    controller: _psNameCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(
                  'येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक (Cr.No.) ',
                  style: marathiBody,
                ),
                SizedBox(
                  width: 120,
                  child: BilingualSimpleUnderlineInput(
                    controller: _crNoCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(
                  ', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम ',
                  style: marathiBody,
                ),
                SizedBox(
                  width: 120,
                  child: BilingualSimpleUnderlineInput(
                    controller: _bnsSectionCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(
                  'अन्वये नोंदवलेल्या गुन्ह्याच्या तपासाच्या अनुषंगाने आज दिनांक ',
                  style: marathiBody,
                ),
                SizedBox(
                  width: 110,
                  child: BilingualSimpleUnderlineInput(
                    controller: _arrestDateCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('रोजी वेळ ', style: marathiBody),
                SizedBox(
                  width: 90,
                  child: BilingualSimpleUnderlineInput(
                    controller: _arrestTimeCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('वाजता कायदेशीररीत्या अटक करण्यात आली आहे.', style: marathiBody),
              ],
            ),
            const SizedBox(height: 14),

            // Brief facts
            Text('गुन्ह्याची थोडक्यात हकीकत :-', style: marathiBold),
            const SizedBox(height: 4),
            TextField(
              controller: _briefFactsCtrl,
              maxLines: 2,
              style: marathiBody.copyWith(
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                border: UnderlineInputBorder(),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Table Header Intro
            Text(
              'आरोपीच्या अटकेबाबत तुम्हाला खालील बाबींची लेखी माहिती देण्यात येत आहे:-',
              style: marathiBold,
            ),
            const SizedBox(height: 6),

            // Table 1: Information regarding arrest
            Table(
              border: TableBorder.all(color: Colors.black87, width: 0.8),
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Center(child: Text('अ.क्र.', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Center(child: Text('अटकेबाबत माहिती', style: marathiBold)),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('१.', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('आरोपी नाव ', style: marathiBody),
                          Text(
                            _accusedNameCtrl.text.isNotEmpty
                                ? _accusedNameCtrl.text
                                : '___________________',
                            style: marathiBold.copyWith(color: Colors.blue.shade900),
                          ),
                          Text(' यांना गुन्हा रजिस्टर क्रमांक ', style: marathiBody),
                          Text(
                            _crNoCtrl.text.isNotEmpty ? _crNoCtrl.text : '_______________',
                            style: marathiBold.copyWith(color: Colors.blue.shade900),
                          ),
                          Text(', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम ', style: marathiBody),
                          Text(
                            _bnsSectionCtrl.text.isNotEmpty
                                ? _bnsSectionCtrl.text
                                : '__________________',
                            style: marathiBold.copyWith(color: Colors.blue.shade900),
                          ),
                          Text(
                            ' अन्वये नोंदवलेल्या गुन्ह्याच्या तपासाच्या अनुषंगाने कायदेशीररीत्या अटक करण्यात आली असून सदर आरोपीला सध्या [पोलीस ठाण्याचे नाव ',
                            style: marathiBody,
                          ),
                          SizedBox(
                            width: 140,
                            child: BilingualSimpleUnderlineInput(
                              controller: _custodyPsCtrl,
                              serifStyle: serif,
                              hintText: _psNameCtrl.text.isNotEmpty
                                  ? _psNameCtrl.text
                                  : 'पोलीस ठाणे',
                            ),
                          ),
                          Text('] येथे ठेवण्यात आले आहे.', style: marathiBody),
                        ],
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('२.', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'आरोपीला माननीय न्यायालयासमोर हजर केल्यावर जामीन अर्ज सादर करण्याचा पूर्ण कायदेशीर अधिकार आहे.',
                        style: marathiBody,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('३.', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'तुमच्या पसंतीच्या कायदेशीर सल्लागाराचा (वकिलाचा) सल्ला घेण्याचा, त्यांना पोलीस कोठडीत भेटण्याचा आणि माननीय न्यायालयासमोर रिमांडला कायदेशीर विरोध करण्याचा पूर्ण अधिकार आहे.',
                        style: marathiBody,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Table 2: Grounds of Arrest
            Table(
              border: TableBorder.all(color: Colors.black87, width: 0.8),
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Center(child: Text('अ.क्र.', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Center(
                        child: Text(
                          'अटकेचे आधार (Ground of Arrest )',
                          style: marathiBold,
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('१', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'FIR मध्ये आरोपीने सदर गुन्हा केल्याचा उल्लेख आहे.',
                        style: marathiBody,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('२', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('प्रत्यक्षदर्शी साक्षीदार ', style: marathiBody),
                          SizedBox(
                            width: 140,
                            child: BilingualSimpleUnderlineInput(
                              controller: _witnessNameCtrl,
                              serifStyle: serif,
                              hintText: '[नाव]',
                            ),
                          ),
                          Text(
                            ' यांनी दिलेल्या जबाबानुसार गुन्ह्यामध्ये आरोपीचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
                            style: marathiBody,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('३', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'घटनास्थळावरील पुराव्यांच्या CCTV/डिजिटल रेकॉर्ड आधारे गुन्ह्यामध्ये थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
                        style: marathiBody,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('५', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('आरोपीने गुन्हा केल्याची कबुली दिली आहे.', style: marathiBody),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('६', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('गुन्ह्यातील सहआरोपी ', style: marathiBody),
                          SizedBox(
                            width: 140,
                            child: BilingualSimpleUnderlineInput(
                              controller: _coAccusedNameCtrl,
                              serifStyle: serif,
                              hintText: '___________',
                            ),
                          ),
                          Text(
                            ' यांनी गुन्ह्यामध्ये आरोपी सहभागी असल्याचे कबुल केले आहे.',
                            style: marathiBody,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Page 10 Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('दिनांक :- ', style: marathiBold),
                        SizedBox(
                          width: 90,
                          child: BilingualSimpleUnderlineInput(
                            controller: _noticeDateCtrl,
                            serifStyle: serif,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('ठिकाण :- ', style: marathiBold),
                        SizedBox(
                          width: 90,
                          child: BilingualSimpleUnderlineInput(
                            controller: _noticePlaceCtrl,
                            serifStyle: serif,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  children: [
                    SizedBox(
                      width: 180,
                      child: BilingualSimpleUnderlineInput(
                        controller: _officerNameCtrl,
                        serifStyle: serif,
                        hintText: 'अधिकारी नाव, हुद्दा',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('पोलीस अधिकारी नाव सही शिक्का', style: marathiBody),
                  ],
                ),
                Column(
                  children: [
                    SizedBox(
                      width: 180,
                      child: BilingualSimpleUnderlineInput(
                        controller: _relativeSigCtrl,
                        serifStyle: serif,
                        hintText: 'नातेवाईक/मित्र नाव',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('नातेवाईक/ मित्र यांचे नाव , सही, अंगठा', style: marathiBody),
                  ],
                ),
              ],
            ),
          ],
        );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ── PAGE 3: अटकेचे कारणे [कलम ३५(१)(ब) BNSS ] — Page 11 of 13 ──
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildPage11(
    TextStyle serif,
    TextStyle marathiBody,
    TextStyle marathiBold,
  ) {
    return FormPaperPage(
          formLabel: 'Page 11 of 13 — अटकेचे कारणे [कलम ३५(१)(ब) BNSS ]',
          children: [
            _buildProsecutorBox('Page 11 of 13', serif, marathiBody),
            const SizedBox(height: 12),

            // Form Title
            Center(
              child: Text(
                'अटकेचे कारणे [कलम ३५(१)(ब) BNSS ]',
                style: marathiBold.copyWith(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 5),

            // Subtitle
            Center(
              child: Text(
                '(भारतीय नागरिक सुरक्षा संहिता,२०२३ कलम ३५(१)(ब) अन्वये मा.सर्वोच्च न्यायालयाच्या मार्गदर्शक तत्त्वांच्या निकषांच्या अधीन)',
                style: marathiBody.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // Recipient block
            Text('प्रति,', style: marathiBold),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('अटक केलेल्या आरोपीचे नाव:- ', style: marathiBold),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _accusedNameCtrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('वय:- ', style: marathiBold),
                SizedBox(
                  width: 60,
                  child: BilingualSimpleUnderlineInput(
                    controller: _accusedAgeCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(' वर्ष, पत्ता:- ', style: marathiBold),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _accusedAddressCtrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Flowing Paragraph for Page 11
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 8,
              children: [
                Text(
                  'या नोटीसद्वारे तुम्हाला सूचित करण्यात येते की, पोलीस ठाणे',
                  style: marathiBody,
                ),
                SizedBox(
                  width: 140,
                  child: BilingualSimpleUnderlineInput(
                    controller: _psNameCtrl,
                    serifStyle: serif,
                    hintText: '[पोलीस ठाण्याचे नाव]',
                  ),
                ),
                Text('येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक', style: marathiBody),
                SizedBox(
                  width: 130,
                  child: BilingualSimpleUnderlineInput(
                    controller: _crNoCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(
                  ', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम',
                  style: marathiBody,
                ),
                SizedBox(
                  width: 120,
                  child: BilingualSimpleUnderlineInput(
                    controller: _bnsSectionCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text(
                  'अन्वये नोंदवलेल्या गुन्ह्यात तपासाच्या अनुषंगाने आज दिनांक',
                  style: marathiBody,
                ),
                SizedBox(
                  width: 110,
                  child: BilingualSimpleUnderlineInput(
                    controller: _arrestDateCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('रोजी वेळ', style: marathiBody),
                SizedBox(
                  width: 90,
                  child: BilingualSimpleUnderlineInput(
                    controller: _arrestTimeCtrl,
                    serifStyle: serif,
                  ),
                ),
                Text('वाजता अटक करण्यात आली आहे.', style: marathiBody),
              ],
            ),
            const SizedBox(height: 14),

            // Brief facts
            Text(
              'गुन्ह्याची थोडक्यात हकीकत :-',
              style: marathiBold.copyWith(decoration: TextDecoration.underline),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _briefFactsCtrl,
              maxLines: 3,
              style: marathiBody.copyWith(
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                border: UnderlineInputBorder(),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Table Header Intro
            Text(
              'अटकेची कारणे (Reasons for Arrest) खालीलप्रमाणे लिखित स्वरूपात पुरवण्यात येत आहेत:-',
              style: marathiBold.copyWith(decoration: TextDecoration.underline),
            ),
            const SizedBox(height: 6),

            // Table: Reasons of Arrest (Section 35(1)(b))
            Table(
              border: TableBorder.all(color: Colors.black87, width: 0.8),
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Center(child: Text('अ.क्र.', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Center(
                        child: Text(
                          'अटकेचे कारणे ( Reason of Arrest )',
                          style: marathiBold,
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('१', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'या पुढे कोणताही गुन्हा करण्यास प्रतिबंध करण्यासाठी अटक करण्यात आली आहे.',
                        style: marathiBody,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('२', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'गुन्ह्याचा योग्य तपास / अन्वेषण करण्यासाठी .',
                        style: marathiBody,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('३', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'गुन्ह्यातील पुरावा नष्ट किंवा पुराव्यांशी छेडछाड / फेरफार करण्यापासून रोखण्यासाठी',
                        style: marathiBody,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('४', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'गुन्ह्यातील साक्षीदारांना धाक, धाकदपटशा, वचन किंवा प्रलोभन देण्यापासून रोखणे, धमकावण्यापासून रोखण्यासाठी',
                        style: marathiBody,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Center(child: Text('५', style: marathiBold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'न्यायालयातील उपस्थिती निश्चित करण्यासाठी अटक न केल्यास तुम्ही तपासातून आणि न्यायालयाच्या प्रक्रियेतून फरार होण्याची शक्यता आहे',
                        style: marathiBody,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Page 11 Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('दिनांक :- ', style: marathiBold),
                        SizedBox(
                          width: 90,
                          child: BilingualSimpleUnderlineInput(
                            controller: _noticeDateCtrl,
                            serifStyle: serif,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('ठिकाण :- ', style: marathiBold),
                        SizedBox(
                          width: 90,
                          child: BilingualSimpleUnderlineInput(
                            controller: _noticePlaceCtrl,
                            serifStyle: serif,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  children: [
                    SizedBox(
                      width: 180,
                      child: BilingualSimpleUnderlineInput(
                        controller: _officerNameCtrl,
                        serifStyle: serif,
                        hintText: 'अधिकारी नाव, हुद्दा',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('पोलीस अधिकारी नाव सही शिक्का', style: marathiBody),
                  ],
                ),
                Column(
                  children: [
                    SizedBox(
                      width: 160,
                      child: AnimatedBuilder(
                        animation: _accusedNameCtrl,
                        builder: (context, _) => Text(
                          _accusedNameCtrl.text.isNotEmpty
                              ? _accusedNameCtrl.text
                              : '',
                          style: marathiBold.copyWith(
                            color: Colors.blue.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('आरोपीचे नाव , सही, अंगठा', style: marathiBody),
                  ],
                ),
              ],
            ),
          ],
        );
  }
}
