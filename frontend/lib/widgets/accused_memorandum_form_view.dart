import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// Helper class to hold all 12 controllers for a relative entry (Items 9 to 43).
class RelativeEntryControllers {
  final int itemNumber;
  final String title;
  final TextEditingController name = TextEditingController();
  final TextEditingController occ = TextEditingController();
  final TextEditingController currAddr = TextEditingController();
  final TextEditingController currTal = TextEditingController();
  final TextEditingController currDist = TextEditingController();
  final TextEditingController currState = TextEditingController();
  final TextEditingController permAddr = TextEditingController();
  final TextEditingController permTal = TextEditingController();
  final TextEditingController permDist = TextEditingController();
  final TextEditingController permState = TextEditingController();
  final TextEditingController prop = TextEditingController();
  final TextEditingController phone = TextEditingController();

  RelativeEntryControllers({
    required this.itemNumber,
    required this.title,
  });

  void dispose() {
    name.dispose();
    occ.dispose();
    currAddr.dispose();
    currTal.dispose();
    currDist.dispose();
    currState.dispose();
    permAddr.dispose();
    permTal.dispose();
    permDist.dispose();
    permState.dispose();
    prop.dispose();
    phone.dispose();
  }

  void hydrate(Map<String, dynamic> data) {
    name.text = data['rel${itemNumber}Name']?.toString() ?? '';
    occ.text = data['rel${itemNumber}Occ']?.toString() ?? '';
    currAddr.text = data['rel${itemNumber}CurrAddr']?.toString() ?? '';
    currTal.text = data['rel${itemNumber}CurrTal']?.toString() ?? '';
    currDist.text = data['rel${itemNumber}CurrDist']?.toString() ?? '';
    currState.text = data['rel${itemNumber}CurrState']?.toString() ?? '';
    permAddr.text = data['rel${itemNumber}PermAddr']?.toString() ?? '';
    permTal.text = data['rel${itemNumber}PermTal']?.toString() ?? '';
    permDist.text = data['rel${itemNumber}PermDist']?.toString() ?? '';
    permState.text = data['rel${itemNumber}PermState']?.toString() ?? '';
    prop.text = data['rel${itemNumber}Prop']?.toString() ?? '';
    phone.text = data['rel${itemNumber}Phone']?.toString() ?? '';
  }

  void collect(Map<String, dynamic> map) {
    map['rel${itemNumber}Name'] = name.text.trim();
    map['rel${itemNumber}Occ'] = occ.text.trim();
    map['rel${itemNumber}CurrAddr'] = currAddr.text.trim();
    map['rel${itemNumber}CurrTal'] = currTal.text.trim();
    map['rel${itemNumber}CurrDist'] = currDist.text.trim();
    map['rel${itemNumber}CurrState'] = currState.text.trim();
    map['rel${itemNumber}PermAddr'] = permAddr.text.trim();
    map['rel${itemNumber}PermTal'] = permTal.text.trim();
    map['rel${itemNumber}PermDist'] = permDist.text.trim();
    map['rel${itemNumber}PermState'] = permState.text.trim();
    map['rel${itemNumber}Prop'] = prop.text.trim();
    map['rel${itemNumber}Phone'] = phone.text.trim();
  }
}

/// Accused Interrogation Form (अटक आरोपीचा इंट्रोगेशन फॉर्म — संपुर्ण वैयक्तीक माहिती).
class AccusedMemorandumFormView extends StatefulWidget {
  final bool readOnly;
  final Map<String, dynamic>? existingRecord;
  final String? formSection;
  final String? pageRange;

  const AccusedMemorandumFormView({
    super.key,
    this.readOnly = false,
    this.existingRecord,
    this.formSection,
    this.pageRange,
  });

  @override
  State<AccusedMemorandumFormView> createState() =>
      AccusedMemorandumFormViewState();
}

class AccusedMemorandumFormViewState extends State<AccusedMemorandumFormView> {
  // ─── PAGE 1 CONTROLLERS (Items 1–8) ───────────────────────────────────────
  final _psCtrl = TextEditingController();
  final _crimeNoSectionCtrl = TextEditingController();
  final _accusedFullNameCtrl = TextEditingController();

  final _accusedAliasCtrl = TextEditingController();
  final _accusedOccupationCtrl = TextEditingController();
  final _accusedPropertyCtrl = TextEditingController();
  final _accusedFarmHouseVehicleCtrl = TextEditingController();
  final _accusedPhoneOtherCtrl = TextEditingController();

  // Item 5: Current Address
  final _currResAddrCtrl = TextEditingController();
  final _currTalukaCtrl = TextEditingController();
  final _currDistrictCtrl = TextEditingController();
  final _currStateCtrl = TextEditingController();

  // Item 6: Native Address
  final _permResAddrCtrl = TextEditingController();
  final _permTalukaCtrl = TextEditingController();
  final _permDistrictCtrl = TextEditingController();
  final _permStateCtrl = TextEditingController();

  // Item 7: Physical Description
  final _descColorCtrl = TextEditingController();
  final _descHeightCtrl = TextEditingController();
  final _descCasteCtrl = TextEditingController();
  final _descDeformityCtrl = TextEditingController();
  final _descTeethCtrl = TextEditingController();
  final _descHairCtrl = TextEditingController();
  final _descEyesCtrl = TextEditingController();
  final _descDressCtrl = TextEditingController();
  final _descVoterNameCtrl = TextEditingController();
  final _descBoilCtrl = TextEditingController();
  final _descMoleCtrl = TextEditingController();
  final _descTattooCtrl = TextEditingController();
  final _descEarsCtrl = TextEditingController();
  final _descNoseCtrl = TextEditingController();
  final _descMustacheCtrl = TextEditingController();
  final _descFaceCtrl = TextEditingController();
  final _descLanguageCtrl = TextEditingController();
  final _descDobCtrl = TextEditingController();
  final _descComplexionCtrl = TextEditingController();
  final _descBurnMarksCtrl = TextEditingController();
  final _descMainIdMarkCtrl = TextEditingController();

  // Item 8: Birth place
  final _accusedBirthPlaceCtrl = TextEditingController();

  // ─── RELATIVE CONTROLLERS (Items 9–43) ───────────────────────────────────
  late final Map<int, RelativeEntryControllers> _relatives;

  @override
  void initState() {
    super.initState();
    _relatives = {
      9: RelativeEntryControllers(itemNumber: 9, title: 'आरोपीच्या आईचे संपुर्ण नांव'),
      10: RelativeEntryControllers(itemNumber: 10, title: 'आईचे वडीलांचे संपुर्ण नांव'),
      11: RelativeEntryControllers(itemNumber: 11, title: 'आरोपीच्या वडीलांचे संपुर्ण नांव'),
      12: RelativeEntryControllers(itemNumber: 12, title: 'आरोपीच्या वडीलांचे वडील यांचे संपुर्ण नांव (आजा)'),
      13: RelativeEntryControllers(itemNumber: 13, title: 'आरोपीच्या भावाचे संपुर्ण नांव'),
      14: RelativeEntryControllers(itemNumber: 14, title: 'आरोपीच्या भावाचे संपुर्ण नांव'),
      15: RelativeEntryControllers(itemNumber: 15, title: 'आरोपीच्या बहिणीचे संपुर्ण नांव'),
      16: RelativeEntryControllers(itemNumber: 16, title: 'आरोपीच्या बहिणीचे संपुर्ण नांव'),
      17: RelativeEntryControllers(itemNumber: 17, title: 'आरोपीच्या पत्नीचे संपुर्ण नांव'),
      18: RelativeEntryControllers(itemNumber: 18, title: 'आरोपीच्या दुसऱ्या पत्नीचे संपुर्ण नांव'),
      19: RelativeEntryControllers(itemNumber: 19, title: 'आरोपीच्या सासऱ्याचे संपुर्ण नांव'),
      20: RelativeEntryControllers(itemNumber: 20, title: 'आरोपीच्या मुलाचे संपुर्ण नांव'),
      21: RelativeEntryControllers(itemNumber: 21, title: 'आरोपीच्या मुलाचे संपुर्ण नांव'),
      22: RelativeEntryControllers(itemNumber: 22, title: 'आरोपीच्या मुलाचे संपुर्ण नांव'),
      23: RelativeEntryControllers(itemNumber: 23, title: 'आरोपीच्या मुलीचे संपुर्ण नांव'),
      24: RelativeEntryControllers(itemNumber: 24, title: 'आरोपीच्या मुलीचे संपुर्ण नांव'),
      25: RelativeEntryControllers(itemNumber: 25, title: 'आरोपीच्या मुलीचे संपुर्ण नांव'),
      26: RelativeEntryControllers(itemNumber: 26, title: 'आरोपीच्या सालीचे संपुर्ण नांव (बायकोच्या बहिणीचे)'),
      27: RelativeEntryControllers(itemNumber: 27, title: 'आरोपीच्या सालीचे संपुर्ण नांव (बायकोच्या बहिणीचे)'),
      28: RelativeEntryControllers(itemNumber: 28, title: 'आरोपीच्या सालीचे संपुर्ण नांव (बायकोच्या बहिणीचे)'),
      29: RelativeEntryControllers(itemNumber: 29, title: 'आरोपीच्या साळयाचे संपुर्ण नांव (बायकोच्या भावाचे)'),
      30: RelativeEntryControllers(itemNumber: 30, title: 'आरोपीच्या साळयाचे संपुर्ण नांव (बायकोच्या भावाचे)'),
      31: RelativeEntryControllers(itemNumber: 31, title: 'आरोपीच्या साळयाचे संपुर्ण नांव (बायकोच्या भावाचे)'),
      32: RelativeEntryControllers(itemNumber: 32, title: 'आरोपीच्या मामाचे संपुर्ण नांव'),
      33: RelativeEntryControllers(itemNumber: 33, title: 'आरोपीच्या मामाचे संपुर्ण नांव'),
      34: RelativeEntryControllers(itemNumber: 34, title: 'आरोपीच्या मामाचे संपुर्ण नांव'),
      35: RelativeEntryControllers(itemNumber: 35, title: 'आरोपीच्या मामाचे संपुर्ण नांव'),
      36: RelativeEntryControllers(itemNumber: 36, title: 'आरोपीच्या मावशीचे संपुर्ण नांव'),
      37: RelativeEntryControllers(itemNumber: 37, title: 'आरोपीच्या मावशीचे संपुर्ण नांव'),
      38: RelativeEntryControllers(itemNumber: 38, title: 'आरोपीच्या मावशीचे संपुर्ण नांव'),
      39: RelativeEntryControllers(itemNumber: 39, title: 'आरोपीच्या काकाचे संपुर्ण नांव'),
      40: RelativeEntryControllers(itemNumber: 40, title: 'आरोपीच्या काकाचे संपुर्ण नांव'),
      41: RelativeEntryControllers(itemNumber: 41, title: 'आरोपीच्या काकाचे संपुर्ण नांव'),
      42: RelativeEntryControllers(itemNumber: 42, title: 'आरोपीच्या आत्याचे संपुर्ण नांव'),
      43: RelativeEntryControllers(itemNumber: 43, title: 'आरोपीच्या आत्याचे संपुर्ण नांव'),
    };

    if (widget.existingRecord != null) {
      hydrateFrom(widget.existingRecord!);
    }
  }

  @override
  void dispose() {
    _psCtrl.dispose();
    _crimeNoSectionCtrl.dispose();
    _accusedFullNameCtrl.dispose();
    _accusedAliasCtrl.dispose();
    _accusedOccupationCtrl.dispose();
    _accusedPropertyCtrl.dispose();
    _accusedFarmHouseVehicleCtrl.dispose();
    _accusedPhoneOtherCtrl.dispose();
    _currResAddrCtrl.dispose();
    _currTalukaCtrl.dispose();
    _currDistrictCtrl.dispose();
    _currStateCtrl.dispose();
    _permResAddrCtrl.dispose();
    _permTalukaCtrl.dispose();
    _permDistrictCtrl.dispose();
    _permStateCtrl.dispose();
    _descColorCtrl.dispose();
    _descHeightCtrl.dispose();
    _descCasteCtrl.dispose();
    _descDeformityCtrl.dispose();
    _descTeethCtrl.dispose();
    _descHairCtrl.dispose();
    _descEyesCtrl.dispose();
    _descDressCtrl.dispose();
    _descVoterNameCtrl.dispose();
    _descBoilCtrl.dispose();
    _descMoleCtrl.dispose();
    _descTattooCtrl.dispose();
    _descEarsCtrl.dispose();
    _descNoseCtrl.dispose();
    _descMustacheCtrl.dispose();
    _descFaceCtrl.dispose();
    _descLanguageCtrl.dispose();
    _descDobCtrl.dispose();
    _descComplexionCtrl.dispose();
    _descBurnMarksCtrl.dispose();
    _descMainIdMarkCtrl.dispose();
    _accusedBirthPlaceCtrl.dispose();

    for (final rel in _relatives.values) {
      rel.dispose();
    }
    super.dispose();
  }

  void hydrateFrom(Map<String, dynamic> data) {
    setState(() {
      _psCtrl.text = data['ps']?.toString() ?? data['policeStation']?.toString() ?? '';
      _crimeNoSectionCtrl.text = data['crimeNoSection']?.toString() ?? data['crimeNo']?.toString() ?? '';
      _accusedFullNameCtrl.text = data['accusedFullName']?.toString() ?? data['accusedName']?.toString() ?? '';
      _accusedAliasCtrl.text = data['accusedAlias']?.toString() ?? '';
      _accusedOccupationCtrl.text = data['accusedOccupation']?.toString() ?? '';
      _accusedPropertyCtrl.text = data['accusedProperty']?.toString() ?? '';
      _accusedFarmHouseVehicleCtrl.text = data['accusedFarmHouseVehicle']?.toString() ?? '';
      _accusedPhoneOtherCtrl.text = data['accusedPhoneOther']?.toString() ?? '';

      _currResAddrCtrl.text = data['currResAddr']?.toString() ?? '';
      _currTalukaCtrl.text = data['currTaluka']?.toString() ?? '';
      _currDistrictCtrl.text = data['currDistrict']?.toString() ?? '';
      _currStateCtrl.text = data['currState']?.toString() ?? '';

      _permResAddrCtrl.text = data['permResAddr']?.toString() ?? '';
      _permTalukaCtrl.text = data['permTaluka']?.toString() ?? '';
      _permDistrictCtrl.text = data['permDistrict']?.toString() ?? '';
      _permStateCtrl.text = data['permState']?.toString() ?? '';

      _descColorCtrl.text = data['descColor']?.toString() ?? '';
      _descHeightCtrl.text = data['descHeight']?.toString() ?? '';
      _descCasteCtrl.text = data['descCaste']?.toString() ?? '';
      _descDeformityCtrl.text = data['descDeformity']?.toString() ?? '';
      _descTeethCtrl.text = data['descTeeth']?.toString() ?? '';
      _descHairCtrl.text = data['descHair']?.toString() ?? '';
      _descEyesCtrl.text = data['descEyes']?.toString() ?? '';
      _descDressCtrl.text = data['descDress']?.toString() ?? '';
      _descVoterNameCtrl.text = data['descVoterName']?.toString() ?? '';
      _descBoilCtrl.text = data['descBoil']?.toString() ?? '';
      _descMoleCtrl.text = data['descMole']?.toString() ?? '';
      _descTattooCtrl.text = data['descTattoo']?.toString() ?? '';
      _descEarsCtrl.text = data['descEars']?.toString() ?? '';
      _descNoseCtrl.text = data['descNose']?.toString() ?? '';
      _descMustacheCtrl.text = data['descMustache']?.toString() ?? '';
      _descFaceCtrl.text = data['descFace']?.toString() ?? '';
      _descLanguageCtrl.text = data['descLanguage']?.toString() ?? '';
      _descDobCtrl.text = data['descDob']?.toString() ?? '';
      _descComplexionCtrl.text = data['descComplexion']?.toString() ?? '';
      _descBurnMarksCtrl.text = data['descBurnMarks']?.toString() ?? '';
      _descMainIdMarkCtrl.text = data['descMainIdMark']?.toString() ?? '';
      _accusedBirthPlaceCtrl.text = data['accusedBirthPlace']?.toString() ?? '';

      for (final rel in _relatives.values) {
        rel.hydrate(data);
      }
    });
  }

  Map<String, dynamic> collectData() {
    final map = <String, dynamic>{
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'ps': _psCtrl.text.trim(),
      'crimeNoSection': _crimeNoSectionCtrl.text.trim(),
      'accusedFullName': _accusedFullNameCtrl.text.trim(),
      'accusedAlias': _accusedAliasCtrl.text.trim(),
      'accusedOccupation': _accusedOccupationCtrl.text.trim(),
      'accusedProperty': _accusedPropertyCtrl.text.trim(),
      'accusedFarmHouseVehicle': _accusedFarmHouseVehicleCtrl.text.trim(),
      'accusedPhoneOther': _accusedPhoneOtherCtrl.text.trim(),
      'currResAddr': _currResAddrCtrl.text.trim(),
      'currTaluka': _currTalukaCtrl.text.trim(),
      'currDistrict': _currDistrictCtrl.text.trim(),
      'currState': _currStateCtrl.text.trim(),
      'permResAddr': _permResAddrCtrl.text.trim(),
      'permTaluka': _permTalukaCtrl.text.trim(),
      'permDistrict': _permDistrictCtrl.text.trim(),
      'permState': _permStateCtrl.text.trim(),
      'descColor': _descColorCtrl.text.trim(),
      'descHeight': _descHeightCtrl.text.trim(),
      'descCaste': _descCasteCtrl.text.trim(),
      'descDeformity': _descDeformityCtrl.text.trim(),
      'descTeeth': _descTeethCtrl.text.trim(),
      'descHair': _descHairCtrl.text.trim(),
      'descEyes': _descEyesCtrl.text.trim(),
      'descDress': _descDressCtrl.text.trim(),
      'descVoterName': _descVoterNameCtrl.text.trim(),
      'descBoil': _descBoilCtrl.text.trim(),
      'descMole': _descMoleCtrl.text.trim(),
      'descTattoo': _descTattooCtrl.text.trim(),
      'descEars': _descEarsCtrl.text.trim(),
      'descNose': _descNoseCtrl.text.trim(),
      'descMustache': _descMustacheCtrl.text.trim(),
      'descFace': _descFaceCtrl.text.trim(),
      'descLanguage': _descLanguageCtrl.text.trim(),
      'descDob': _descDobCtrl.text.trim(),
      'descComplexion': _descComplexionCtrl.text.trim(),
      'descBurnMarks': _descBurnMarksCtrl.text.trim(),
      'descMainIdMark': _descMainIdMarkCtrl.text.trim(),
      'accusedBirthPlace': _accusedBirthPlaceCtrl.text.trim(),
    };

    for (final rel in _relatives.values) {
      rel.collect(map);
    }

    return map;
  }

  Widget _tableCellInput(
    TextEditingController ctrl,
    TextStyle serifStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: BilingualSimpleUnderlineInput(
        controller: ctrl,
        serifStyle: serifStyle.copyWith(fontSize: 11),
      ),
    );
  }

  Widget _tableHeader(String text, TextStyle serifStyle) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Text(
        text,
        style: serifStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAddressSubGrid({
    required TextEditingController resAddr,
    required TextEditingController taluka,
    required TextEditingController dist,
    required TextEditingController state,
    required TextStyle marathiLabelStyle,
    required TextStyle serifStyle,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text('रा. ', style: marathiLabelStyle),
            Expanded(
              flex: 3,
              child: _tableCellInput(resAddr, serifStyle),
            ),
            const SizedBox(width: 8),
            Text('ता ', style: marathiLabelStyle),
            Expanded(
              flex: 2,
              child: _tableCellInput(taluka, serifStyle),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text('जिल्हा ', style: marathiLabelStyle),
            Expanded(
              child: _tableCellInput(dist, serifStyle),
            ),
            const SizedBox(width: 8),
            Text('राज्य ', style: marathiLabelStyle),
            Expanded(
              child: _tableCellInput(state, serifStyle),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRelativeBlock(
    RelativeEntryControllers rel, {
    required TextStyle marathiLabelStyle,
    required TextStyle serifStyle,
  }) {
    return Table(
      border: TableBorder.all(color: Colors.black87),
      columnWidths: const {
        0: FixedColumnWidth(44),
        1: FlexColumnWidth(1.8),
        2: FlexColumnWidth(4.2),
      },
      children: [
        TableRow(
          children: [
            _tableHeader('${rel.itemNumber}.', serifStyle),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(rel.title, style: marathiLabelStyle),
            ),
            _tableCellInput(rel.name, serifStyle),
          ],
        ),
        TableRow(
          children: [
            const SizedBox(),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text('धंदा', style: marathiLabelStyle),
            ),
            _tableCellInput(rel.occ, serifStyle),
          ],
        ),
        TableRow(
          children: [
            const SizedBox(),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text('ह.मुक्काम संपुर्ण पत्ता', style: marathiLabelStyle),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: _buildAddressSubGrid(
                resAddr: rel.currAddr,
                taluka: rel.currTal,
                dist: rel.currDist,
                state: rel.currState,
                marathiLabelStyle: marathiLabelStyle,
                serifStyle: serifStyle,
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            const SizedBox(),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text('मुळ गावचा संपुर्ण पत्ता', style: marathiLabelStyle),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: _buildAddressSubGrid(
                resAddr: rel.permAddr,
                taluka: rel.permTal,
                dist: rel.permDist,
                state: rel.permState,
                marathiLabelStyle: marathiLabelStyle,
                serifStyle: serifStyle,
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            const SizedBox(),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text('स्थावर जंगम मालमत्ता', style: marathiLabelStyle),
            ),
            _tableCellInput(rel.prop, serifStyle),
          ],
        ),
        TableRow(
          children: [
            const SizedBox(),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text('फोन नंबर व इतर माहिती', style: marathiLabelStyle),
            ),
            _tableCellInput(rel.phone, serifStyle),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle serifStyle = FormTypography.serifStyle();
    final TextStyle marathiLabelStyle = FormTypography.marathiLabelStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        // ══════════════════════════════════════════════════════════════════
        // PAGE 1 — ITEMS 1 TO 9 (Basic particulars, Description, Mother)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 1 (Personal Particulars)',
          children: [
            Center(
              child: Text(
                '-:: अटक आरोपीचा इंट्रोगेशन फॉर्म ::-',
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                '(संपुर्ण वैयक्तीक माहिती)',
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),

            Table(
              border: TableBorder.all(color: Colors.black87),
              columnWidths: const {
                0: FixedColumnWidth(44),
                1: FlexColumnWidth(1.8),
                2: FlexColumnWidth(4.2),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                  children: [
                    _tableHeader('अ.क्र', serifStyle),
                    _tableHeader('विवरण', serifStyle),
                    _tableHeader('माहिती', serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    _tableHeader('1.', serifStyle),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('पोलीस स्टेशन', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_psCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    _tableHeader('2.', serifStyle),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('अप.क्रमांक व कलम', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_crimeNoSectionCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    _tableHeader('3.', serifStyle),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('आरोपीचे संपुर्ण नांव', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_accusedFullNameCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    _tableHeader('4.', serifStyle),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('आरोपीचे टोपण नांव', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_accusedAliasCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('धंदा', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_accusedOccupationCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('स्थावर/ जंगम मालमत्ता', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_accusedPropertyCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('शेती, घर व वाहन', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_accusedFarmHouseVehicleCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('फोन नंबर व इतर माहिती', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_accusedPhoneOtherCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    _tableHeader('5.', serifStyle),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('आरोपीचा संपूर्ण पत्ता व राज्य', style: marathiLabelStyle),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: _buildAddressSubGrid(
                        resAddr: _currResAddrCtrl,
                        taluka: _currTalukaCtrl,
                        dist: _currDistrictCtrl,
                        state: _currStateCtrl,
                        marathiLabelStyle: marathiLabelStyle,
                        serifStyle: serifStyle,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    _tableHeader('6.', serifStyle),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('आरोपीचा मुळ गांवचा संपूर्ण पत्ता व राज्य', style: marathiLabelStyle),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: _buildAddressSubGrid(
                        resAddr: _permResAddrCtrl,
                        taluka: _permTalukaCtrl,
                        dist: _permDistrictCtrl,
                        state: _permStateCtrl,
                        marathiLabelStyle: marathiLabelStyle,
                        serifStyle: serifStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Item 7: Physical Description Sub-table
            Table(
              border: TableBorder.all(color: Colors.black87),
              columnWidths: const {
                0: FixedColumnWidth(44),
                1: FlexColumnWidth(1.8),
                2: FlexColumnWidth(4.2),
              },
              children: [
                TableRow(
                  children: [
                    _tableHeader('7.', serifStyle),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('आरोपीचे वर्णन', style: marathiLabelStyle),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text('रंग— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descColorCtrl, serifStyle)),
                              const SizedBox(width: 4),
                              Text('उंच— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descHeightCtrl, serifStyle)),
                              const SizedBox(width: 4),
                              Text('जात— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descCasteCtrl, serifStyle)),
                            ],
                          ),
                          Row(
                            children: [
                              Text('व्यंग— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descDeformityCtrl, serifStyle)),
                              const SizedBox(width: 4),
                              Text('दात— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descTeethCtrl, serifStyle)),
                              const SizedBox(width: 4),
                              Text('केस— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descHairCtrl, serifStyle)),
                            ],
                          ),
                          Row(
                            children: [
                              Text('डोळे— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descEyesCtrl, serifStyle)),
                              const SizedBox(width: 8),
                              Text('पोषख— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descDressCtrl, serifStyle)),
                            ],
                          ),
                          Row(
                            children: [
                              Text('मतदार यादिलीत नांव— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descVoterNameCtrl, serifStyle)),
                            ],
                          ),
                          Row(
                            children: [
                              Text('फोड— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descBoilCtrl, serifStyle)),
                              const SizedBox(width: 4),
                              Text('तिळ— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descMoleCtrl, serifStyle)),
                              const SizedBox(width: 4),
                              Text('गोदने— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descTattooCtrl, serifStyle)),
                            ],
                          ),
                          Row(
                            children: [
                              Text('कान— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descEarsCtrl, serifStyle)),
                              const SizedBox(width: 4),
                              Text('नाक— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descNoseCtrl, serifStyle)),
                              const SizedBox(width: 4),
                              Text('मिशी— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descMustacheCtrl, serifStyle)),
                            ],
                          ),
                          Row(
                            children: [
                              Text('चेहरा— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descFaceCtrl, serifStyle)),
                              const SizedBox(width: 4),
                              Text('भाषा— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descLanguageCtrl, serifStyle)),
                              const SizedBox(width: 4),
                              Text('जन्म तारीख— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descDobCtrl, serifStyle)),
                            ],
                          ),
                          Row(
                            children: [
                              Text('वर्ण— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descComplexionCtrl, serifStyle)),
                              const SizedBox(width: 8),
                              Text('भाजल्याच्या खुणा— ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descBurnMarksCtrl, serifStyle)),
                            ],
                          ),
                          Row(
                            children: [
                              Text('मुख्य ओळख चिन्ह: ', style: marathiLabelStyle),
                              Expanded(child: _tableCellInput(_descMainIdMarkCtrl, serifStyle)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    _tableHeader('8.', serifStyle),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('आरोपीचे जन्म ठिकाण', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_accusedBirthPlaceCtrl, serifStyle),
                  ],
                ),
              ],
            ),

            // Item 9: Mother
            _buildRelativeBlock(
              _relatives[9]!,
              marathiLabelStyle: marathiLabelStyle,
              serifStyle: serifStyle,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 2 — ITEMS 10 TO 12 (Grandparents & Father)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 2 (Parents & Grandparents)',
          children: [
            _buildRelativeBlock(_relatives[10]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[11]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[12]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
          ],
        ),

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 3 — ITEMS 13 TO 16 (Siblings)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 3 (Siblings Particulars)',
          children: [
            _buildRelativeBlock(_relatives[13]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[14]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[15]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[16]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
          ],
        ),

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 4 — ITEMS 17 TO 19 (Spouse & In-Laws)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 4 (Spouse & In-Laws)',
          children: [
            _buildRelativeBlock(_relatives[17]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[18]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[19]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
          ],
        ),

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 5 — ITEMS 20 TO 23 (Children Part 1)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 5 (Children Particulars)',
          children: [
            _buildRelativeBlock(_relatives[20]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[21]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[22]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[23]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
          ],
        ),

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 6 — ITEMS 24 TO 27 (Daughters & Sisters-in-law)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 6 (Daughters & Sisters-in-law)',
          children: [
            _buildRelativeBlock(_relatives[24]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[25]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[26]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[27]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
          ],
        ),

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 7 — ITEMS 28 TO 31 (Sali & Brothers-in-law / Sala)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 7 (In-laws — Sali & Sala)',
          children: [
            _buildRelativeBlock(_relatives[28]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[29]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[30]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[31]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
          ],
        ),

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 8 — ITEMS 32 TO 35 (Maternal Uncles / Mama)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 8 (Maternal Uncles — Mama)',
          children: [
            _buildRelativeBlock(_relatives[32]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[33]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[34]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[35]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
          ],
        ),

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 9 — ITEMS 36 TO 39 (Maternal Aunts & Paternal Uncle / Kaka)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 9 (Aunts — Mavashi & Uncle — Kaka)',
          children: [
            _buildRelativeBlock(_relatives[36]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[37]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[38]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[39]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
          ],
        ),

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 10 — ITEMS 40 TO 43 (Uncles — Kaka & Paternal Aunts — Aatya)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 10 (Kaka & Aatya)',
          children: [
            _buildRelativeBlock(_relatives[40]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[41]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[42]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 12),
            _buildRelativeBlock(_relatives[43]!, marathiLabelStyle: marathiLabelStyle, serifStyle: serifStyle),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'M.R.W',
                style: serifStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
