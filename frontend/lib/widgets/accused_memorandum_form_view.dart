import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

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
  // ─── PAGE 1 CONTROLLERS (Items 1–9 Part 1) ────────────────────────────────
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

  // Item 9: Mother
  final _rel9NameCtrl = TextEditingController();
  final _rel9OccCtrl = TextEditingController();
  final _rel9CurrAddrCtrl = TextEditingController();
  final _rel9CurrTalCtrl = TextEditingController();
  final _rel9CurrDistCtrl = TextEditingController();
  final _rel9CurrStateCtrl = TextEditingController();
  final _rel9PermAddrCtrl = TextEditingController();
  final _rel9PermTalCtrl = TextEditingController();
  final _rel9PermDistCtrl = TextEditingController();
  final _rel9PermStateCtrl = TextEditingController();
  final _rel9PropCtrl = TextEditingController();
  final _rel9PhoneCtrl = TextEditingController();

  // ─── PAGE 2 CONTROLLERS (Items 10–12) ────────────────────────────────────
  // Item 10: Maternal Grandfather (आईचे वडील)
  final _rel10NameCtrl = TextEditingController();
  final _rel10OccCtrl = TextEditingController();
  final _rel10CurrAddrCtrl = TextEditingController();
  final _rel10CurrTalCtrl = TextEditingController();
  final _rel10CurrDistCtrl = TextEditingController();
  final _rel10CurrStateCtrl = TextEditingController();
  final _rel10PermAddrCtrl = TextEditingController();
  final _rel10PermTalCtrl = TextEditingController();
  final _rel10PermDistCtrl = TextEditingController();
  final _rel10PermStateCtrl = TextEditingController();
  final _rel10PropCtrl = TextEditingController();
  final _rel10PhoneCtrl = TextEditingController();

  // Item 11: Father (आरोपीच्या वडीलांचे संपुर्ण नांव)
  final _rel11NameCtrl = TextEditingController();
  final _rel11OccCtrl = TextEditingController();
  final _rel11CurrAddrCtrl = TextEditingController();
  final _rel11CurrTalCtrl = TextEditingController();
  final _rel11CurrDistCtrl = TextEditingController();
  final _rel11CurrStateCtrl = TextEditingController();
  final _rel11PermAddrCtrl = TextEditingController();
  final _rel11PermTalCtrl = TextEditingController();
  final _rel11PermDistCtrl = TextEditingController();
  final _rel11PermStateCtrl = TextEditingController();
  final _rel11PropCtrl = TextEditingController();
  final _rel11PhoneCtrl = TextEditingController();

  // Item 12: Paternal Grandfather (आरोपीच्या वडीलांचे वडील — आजा)
  final _rel12NameCtrl = TextEditingController();
  final _rel12OccCtrl = TextEditingController();
  final _rel12CurrAddrCtrl = TextEditingController();
  final _rel12CurrTalCtrl = TextEditingController();
  final _rel12CurrDistCtrl = TextEditingController();
  final _rel12CurrStateCtrl = TextEditingController();
  final _rel12PermAddrCtrl = TextEditingController();
  final _rel12PermTalCtrl = TextEditingController();
  final _rel12PermDistCtrl = TextEditingController();
  final _rel12PermStateCtrl = TextEditingController();
  final _rel12PropCtrl = TextEditingController();
  final _rel12PhoneCtrl = TextEditingController();

  // ─── PAGE 3 CONTROLLERS (Items 13–16 Part 1) ─────────────────────────────
  // Item 13: Brother 1 (आरोपीच्या भावाचे संपुर्ण नांव)
  final _rel13NameCtrl = TextEditingController();
  final _rel13OccCtrl = TextEditingController();
  final _rel13CurrAddrCtrl = TextEditingController();
  final _rel13CurrTalCtrl = TextEditingController();
  final _rel13CurrDistCtrl = TextEditingController();
  final _rel13CurrStateCtrl = TextEditingController();
  final _rel13PermAddrCtrl = TextEditingController();
  final _rel13PermTalCtrl = TextEditingController();
  final _rel13PermDistCtrl = TextEditingController();
  final _rel13PermStateCtrl = TextEditingController();
  final _rel13PropCtrl = TextEditingController();
  final _rel13PhoneCtrl = TextEditingController();

  // Item 14: Brother 2 (आरोपीच्या भावाचे संपुर्ण नांव)
  final _rel14NameCtrl = TextEditingController();
  final _rel14OccCtrl = TextEditingController();
  final _rel14CurrAddrCtrl = TextEditingController();
  final _rel14CurrTalCtrl = TextEditingController();
  final _rel14CurrDistCtrl = TextEditingController();
  final _rel14CurrStateCtrl = TextEditingController();
  final _rel14PermAddrCtrl = TextEditingController();
  final _rel14PermTalCtrl = TextEditingController();
  final _rel14PermDistCtrl = TextEditingController();
  final _rel14PermStateCtrl = TextEditingController();
  final _rel14PropCtrl = TextEditingController();
  final _rel14PhoneCtrl = TextEditingController();

  // Item 15: Sister 1 (आरोपीच्या बहिणीचे संपुर्ण नांव)
  final _rel15NameCtrl = TextEditingController();
  final _rel15OccCtrl = TextEditingController();
  final _rel15CurrAddrCtrl = TextEditingController();
  final _rel15CurrTalCtrl = TextEditingController();
  final _rel15CurrDistCtrl = TextEditingController();
  final _rel15CurrStateCtrl = TextEditingController();
  final _rel15PermAddrCtrl = TextEditingController();
  final _rel15PermTalCtrl = TextEditingController();
  final _rel15PermDistCtrl = TextEditingController();
  final _rel15PermStateCtrl = TextEditingController();
  final _rel15PropCtrl = TextEditingController();
  final _rel15PhoneCtrl = TextEditingController();

  // Item 16: Sister 2 (आरोपीच्या बहिणीचे संपुर्ण नांव)
  final _rel16NameCtrl = TextEditingController();
  final _rel16OccCtrl = TextEditingController();
  final _rel16CurrAddrCtrl = TextEditingController();
  final _rel16CurrTalCtrl = TextEditingController();
  final _rel16CurrDistCtrl = TextEditingController();
  final _rel16CurrStateCtrl = TextEditingController();
  final _rel16PermAddrCtrl = TextEditingController();
  final _rel16PermTalCtrl = TextEditingController();
  final _rel16PermDistCtrl = TextEditingController();
  final _rel16PermStateCtrl = TextEditingController();
  final _rel16PropCtrl = TextEditingController();
  final _rel16PhoneCtrl = TextEditingController();

  // ─── PAGE 4 CONTROLLERS (Items 17–19) ────────────────────────────────────
  // Item 17: Wife 1 (आरोपीच्या पत्नीचे संपुर्ण नांव)
  final _rel17NameCtrl = TextEditingController();
  final _rel17OccCtrl = TextEditingController();
  final _rel17CurrAddrCtrl = TextEditingController();
  final _rel17CurrTalCtrl = TextEditingController();
  final _rel17CurrDistCtrl = TextEditingController();
  final _rel17CurrStateCtrl = TextEditingController();
  final _rel17PermAddrCtrl = TextEditingController();
  final _rel17PermTalCtrl = TextEditingController();
  final _rel17PermDistCtrl = TextEditingController();
  final _rel17PermStateCtrl = TextEditingController();
  final _rel17PropCtrl = TextEditingController();
  final _rel17PhoneCtrl = TextEditingController();

  // Item 18: Wife 2 (आरोपीच्या दुसऱ्या पत्नीचे संपुर्ण नांव)
  final _rel18NameCtrl = TextEditingController();
  final _rel18OccCtrl = TextEditingController();
  final _rel18CurrAddrCtrl = TextEditingController();
  final _rel18CurrTalCtrl = TextEditingController();
  final _rel18CurrDistCtrl = TextEditingController();
  final _rel18CurrStateCtrl = TextEditingController();
  final _rel18PermAddrCtrl = TextEditingController();
  final _rel18PermTalCtrl = TextEditingController();
  final _rel18PermDistCtrl = TextEditingController();
  final _rel18PermStateCtrl = TextEditingController();
  final _rel18PropCtrl = TextEditingController();
  final _rel18PhoneCtrl = TextEditingController();

  // Item 19: Father-in-law (आरोपीच्या सासऱ्याचे संपुर्ण नांव)
  final _rel19NameCtrl = TextEditingController();
  final _rel19OccCtrl = TextEditingController();
  final _rel19CurrAddrCtrl = TextEditingController();
  final _rel19CurrTalCtrl = TextEditingController();
  final _rel19CurrDistCtrl = TextEditingController();
  final _rel19CurrStateCtrl = TextEditingController();
  final _rel19PermAddrCtrl = TextEditingController();
  final _rel19PermTalCtrl = TextEditingController();
  final _rel19PermDistCtrl = TextEditingController();
  final _rel19PermStateCtrl = TextEditingController();
  final _rel19PropCtrl = TextEditingController();
  final _rel19PhoneCtrl = TextEditingController();

  // ─── PAGE 5 CONTROLLERS (Items 20–23) ────────────────────────────────────
  // Item 20: Son 1 (आरोपीच्या मुलाचे संपुर्ण नांव)
  final _rel20NameCtrl = TextEditingController();
  final _rel20OccCtrl = TextEditingController();
  final _rel20CurrAddrCtrl = TextEditingController();
  final _rel20CurrTalCtrl = TextEditingController();
  final _rel20CurrDistCtrl = TextEditingController();
  final _rel20CurrStateCtrl = TextEditingController();
  final _rel20PermAddrCtrl = TextEditingController();
  final _rel20PermTalCtrl = TextEditingController();
  final _rel20PermDistCtrl = TextEditingController();
  final _rel20PermStateCtrl = TextEditingController();
  final _rel20PropCtrl = TextEditingController();
  final _rel20PhoneCtrl = TextEditingController();

  // Item 21: Son 2 (आरोपीच्या मुलाचे संपुर्ण नांव)
  final _rel21NameCtrl = TextEditingController();
  final _rel21OccCtrl = TextEditingController();
  final _rel21CurrAddrCtrl = TextEditingController();
  final _rel21CurrTalCtrl = TextEditingController();
  final _rel21CurrDistCtrl = TextEditingController();
  final _rel21CurrStateCtrl = TextEditingController();
  final _rel21PermAddrCtrl = TextEditingController();
  final _rel21PermTalCtrl = TextEditingController();
  final _rel21PermDistCtrl = TextEditingController();
  final _rel21PermStateCtrl = TextEditingController();
  final _rel21PropCtrl = TextEditingController();
  final _rel21PhoneCtrl = TextEditingController();

  // Item 22: Son 3 (आरोपीच्या मुलाचे संपुर्ण नांव)
  final _rel22NameCtrl = TextEditingController();
  final _rel22OccCtrl = TextEditingController();
  final _rel22CurrAddrCtrl = TextEditingController();
  final _rel22CurrTalCtrl = TextEditingController();
  final _rel22CurrDistCtrl = TextEditingController();
  final _rel22CurrStateCtrl = TextEditingController();
  final _rel22PermAddrCtrl = TextEditingController();
  final _rel22PermTalCtrl = TextEditingController();
  final _rel22PermDistCtrl = TextEditingController();
  final _rel22PermStateCtrl = TextEditingController();
  final _rel22PropCtrl = TextEditingController();
  final _rel22PhoneCtrl = TextEditingController();

  // Item 23: Daughter (आरोपीच्या मुलीचे संपुर्ण नांव)
  final _rel23NameCtrl = TextEditingController();
  final _rel23OccCtrl = TextEditingController();
  final _rel23CurrAddrCtrl = TextEditingController();
  final _rel23CurrTalCtrl = TextEditingController();
  final _rel23CurrDistCtrl = TextEditingController();
  final _rel23CurrStateCtrl = TextEditingController();
  final _rel23PermAddrCtrl = TextEditingController();
  final _rel23PermTalCtrl = TextEditingController();
  final _rel23PermDistCtrl = TextEditingController();
  final _rel23PermStateCtrl = TextEditingController();
  final _rel23PropCtrl = TextEditingController();
  final _rel23PhoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
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

    _rel9NameCtrl.dispose();
    _rel9OccCtrl.dispose();
    _rel9CurrAddrCtrl.dispose();
    _rel9CurrTalCtrl.dispose();
    _rel9CurrDistCtrl.dispose();
    _rel9CurrStateCtrl.dispose();
    _rel9PermAddrCtrl.dispose();
    _rel9PermTalCtrl.dispose();
    _rel9PermDistCtrl.dispose();
    _rel9PermStateCtrl.dispose();
    _rel9PropCtrl.dispose();
    _rel9PhoneCtrl.dispose();

    _rel10NameCtrl.dispose();
    _rel10OccCtrl.dispose();
    _rel10CurrAddrCtrl.dispose();
    _rel10CurrTalCtrl.dispose();
    _rel10CurrDistCtrl.dispose();
    _rel10CurrStateCtrl.dispose();
    _rel10PermAddrCtrl.dispose();
    _rel10PermTalCtrl.dispose();
    _rel10PermDistCtrl.dispose();
    _rel10PermStateCtrl.dispose();
    _rel10PropCtrl.dispose();
    _rel10PhoneCtrl.dispose();

    _rel11NameCtrl.dispose();
    _rel11OccCtrl.dispose();
    _rel11CurrAddrCtrl.dispose();
    _rel11CurrTalCtrl.dispose();
    _rel11CurrDistCtrl.dispose();
    _rel11CurrStateCtrl.dispose();
    _rel11PermAddrCtrl.dispose();
    _rel11PermTalCtrl.dispose();
    _rel11PermDistCtrl.dispose();
    _rel11PermStateCtrl.dispose();
    _rel11PropCtrl.dispose();
    _rel11PhoneCtrl.dispose();

    _rel12NameCtrl.dispose();
    _rel12OccCtrl.dispose();
    _rel12CurrAddrCtrl.dispose();
    _rel12CurrTalCtrl.dispose();
    _rel12CurrDistCtrl.dispose();
    _rel12CurrStateCtrl.dispose();
    _rel12PermAddrCtrl.dispose();
    _rel12PermTalCtrl.dispose();
    _rel12PermDistCtrl.dispose();
    _rel12PermStateCtrl.dispose();
    _rel12PropCtrl.dispose();
    _rel12PhoneCtrl.dispose();

    _rel13NameCtrl.dispose();
    _rel13OccCtrl.dispose();
    _rel13CurrAddrCtrl.dispose();
    _rel13CurrTalCtrl.dispose();
    _rel13CurrDistCtrl.dispose();
    _rel13CurrStateCtrl.dispose();
    _rel13PermAddrCtrl.dispose();
    _rel13PermTalCtrl.dispose();
    _rel13PermDistCtrl.dispose();
    _rel13PermStateCtrl.dispose();
    _rel13PropCtrl.dispose();
    _rel13PhoneCtrl.dispose();

    _rel14NameCtrl.dispose();
    _rel14OccCtrl.dispose();
    _rel14CurrAddrCtrl.dispose();
    _rel14CurrTalCtrl.dispose();
    _rel14CurrDistCtrl.dispose();
    _rel14CurrStateCtrl.dispose();
    _rel14PermAddrCtrl.dispose();
    _rel14PermTalCtrl.dispose();
    _rel14PermDistCtrl.dispose();
    _rel14PermStateCtrl.dispose();
    _rel14PropCtrl.dispose();
    _rel14PhoneCtrl.dispose();

    _rel15NameCtrl.dispose();
    _rel15OccCtrl.dispose();
    _rel15CurrAddrCtrl.dispose();
    _rel15CurrTalCtrl.dispose();
    _rel15CurrDistCtrl.dispose();
    _rel15CurrStateCtrl.dispose();
    _rel15PermAddrCtrl.dispose();
    _rel15PermTalCtrl.dispose();
    _rel15PermDistCtrl.dispose();
    _rel15PermStateCtrl.dispose();
    _rel15PropCtrl.dispose();
    _rel15PhoneCtrl.dispose();

    _rel16NameCtrl.dispose();
    _rel16OccCtrl.dispose();
    _rel16CurrAddrCtrl.dispose();
    _rel16CurrTalCtrl.dispose();
    _rel16CurrDistCtrl.dispose();
    _rel16CurrStateCtrl.dispose();
    _rel16PermAddrCtrl.dispose();
    _rel16PermTalCtrl.dispose();
    _rel16PermDistCtrl.dispose();
    _rel16PermStateCtrl.dispose();
    _rel16PropCtrl.dispose();
    _rel16PhoneCtrl.dispose();

    _rel17NameCtrl.dispose();
    _rel17OccCtrl.dispose();
    _rel17CurrAddrCtrl.dispose();
    _rel17CurrTalCtrl.dispose();
    _rel17CurrDistCtrl.dispose();
    _rel17CurrStateCtrl.dispose();
    _rel17PermAddrCtrl.dispose();
    _rel17PermTalCtrl.dispose();
    _rel17PermDistCtrl.dispose();
    _rel17PermStateCtrl.dispose();
    _rel17PropCtrl.dispose();
    _rel17PhoneCtrl.dispose();

    _rel18NameCtrl.dispose();
    _rel18OccCtrl.dispose();
    _rel18CurrAddrCtrl.dispose();
    _rel18CurrTalCtrl.dispose();
    _rel18CurrDistCtrl.dispose();
    _rel18CurrStateCtrl.dispose();
    _rel18PermAddrCtrl.dispose();
    _rel18PermTalCtrl.dispose();
    _rel18PermDistCtrl.dispose();
    _rel18PermStateCtrl.dispose();
    _rel18PropCtrl.dispose();
    _rel18PhoneCtrl.dispose();

    _rel19NameCtrl.dispose();
    _rel19OccCtrl.dispose();
    _rel19CurrAddrCtrl.dispose();
    _rel19CurrTalCtrl.dispose();
    _rel19CurrDistCtrl.dispose();
    _rel19CurrStateCtrl.dispose();
    _rel19PermAddrCtrl.dispose();
    _rel19PermTalCtrl.dispose();
    _rel19PermDistCtrl.dispose();
    _rel19PermStateCtrl.dispose();
    _rel19PropCtrl.dispose();
    _rel19PhoneCtrl.dispose();

    _rel20NameCtrl.dispose();
    _rel20OccCtrl.dispose();
    _rel20CurrAddrCtrl.dispose();
    _rel20CurrTalCtrl.dispose();
    _rel20CurrDistCtrl.dispose();
    _rel20CurrStateCtrl.dispose();
    _rel20PermAddrCtrl.dispose();
    _rel20PermTalCtrl.dispose();
    _rel20PermDistCtrl.dispose();
    _rel20PermStateCtrl.dispose();
    _rel20PropCtrl.dispose();
    _rel20PhoneCtrl.dispose();

    _rel21NameCtrl.dispose();
    _rel21OccCtrl.dispose();
    _rel21CurrAddrCtrl.dispose();
    _rel21CurrTalCtrl.dispose();
    _rel21CurrDistCtrl.dispose();
    _rel21CurrStateCtrl.dispose();
    _rel21PermAddrCtrl.dispose();
    _rel21PermTalCtrl.dispose();
    _rel21PermDistCtrl.dispose();
    _rel21PermStateCtrl.dispose();
    _rel21PropCtrl.dispose();
    _rel21PhoneCtrl.dispose();

    _rel22NameCtrl.dispose();
    _rel22OccCtrl.dispose();
    _rel22CurrAddrCtrl.dispose();
    _rel22CurrTalCtrl.dispose();
    _rel22CurrDistCtrl.dispose();
    _rel22CurrStateCtrl.dispose();
    _rel22PermAddrCtrl.dispose();
    _rel22PermTalCtrl.dispose();
    _rel22PermDistCtrl.dispose();
    _rel22PermStateCtrl.dispose();
    _rel22PropCtrl.dispose();
    _rel22PhoneCtrl.dispose();

    _rel23NameCtrl.dispose();
    _rel23OccCtrl.dispose();
    _rel23CurrAddrCtrl.dispose();
    _rel23CurrTalCtrl.dispose();
    _rel23CurrDistCtrl.dispose();
    _rel23CurrStateCtrl.dispose();
    _rel23PermAddrCtrl.dispose();
    _rel23PermTalCtrl.dispose();
    _rel23PermDistCtrl.dispose();
    _rel23PermStateCtrl.dispose();
    _rel23PropCtrl.dispose();
    _rel23PhoneCtrl.dispose();

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

      _rel9NameCtrl.text = data['rel9Name']?.toString() ?? '';
      _rel9OccCtrl.text = data['rel9Occ']?.toString() ?? '';
      _rel9CurrAddrCtrl.text = data['rel9CurrAddr']?.toString() ?? '';
      _rel9CurrTalCtrl.text = data['rel9CurrTal']?.toString() ?? '';
      _rel9CurrDistCtrl.text = data['rel9CurrDist']?.toString() ?? '';
      _rel9CurrStateCtrl.text = data['rel9CurrState']?.toString() ?? '';
      _rel9PermAddrCtrl.text = data['rel9PermAddr']?.toString() ?? '';
      _rel9PermTalCtrl.text = data['rel9PermTal']?.toString() ?? '';
      _rel9PermDistCtrl.text = data['rel9PermDist']?.toString() ?? '';
      _rel9PermStateCtrl.text = data['rel9PermState']?.toString() ?? '';
      _rel9PropCtrl.text = data['rel9Prop']?.toString() ?? '';
      _rel9PhoneCtrl.text = data['rel9Phone']?.toString() ?? '';

      _rel10NameCtrl.text = data['rel10Name']?.toString() ?? '';
      _rel10OccCtrl.text = data['rel10Occ']?.toString() ?? '';
      _rel10CurrAddrCtrl.text = data['rel10CurrAddr']?.toString() ?? '';
      _rel10CurrTalCtrl.text = data['rel10CurrTal']?.toString() ?? '';
      _rel10CurrDistCtrl.text = data['rel10CurrDist']?.toString() ?? '';
      _rel10CurrStateCtrl.text = data['rel10CurrState']?.toString() ?? '';
      _rel10PermAddrCtrl.text = data['rel10PermAddr']?.toString() ?? '';
      _rel10PermTalCtrl.text = data['rel10PermTal']?.toString() ?? '';
      _rel10PermDistCtrl.text = data['rel10PermDist']?.toString() ?? '';
      _rel10PermStateCtrl.text = data['rel10PermState']?.toString() ?? '';
      _rel10PropCtrl.text = data['rel10Prop']?.toString() ?? '';
      _rel10PhoneCtrl.text = data['rel10Phone']?.toString() ?? '';

      _rel11NameCtrl.text = data['rel11Name']?.toString() ?? '';
      _rel11OccCtrl.text = data['rel11Occ']?.toString() ?? '';
      _rel11CurrAddrCtrl.text = data['rel11CurrAddr']?.toString() ?? '';
      _rel11CurrTalCtrl.text = data['rel11CurrTal']?.toString() ?? '';
      _rel11CurrDistCtrl.text = data['rel11CurrDist']?.toString() ?? '';
      _rel11CurrStateCtrl.text = data['rel11CurrState']?.toString() ?? '';
      _rel11PermAddrCtrl.text = data['rel11PermAddr']?.toString() ?? '';
      _rel11PermTalCtrl.text = data['rel11PermTal']?.toString() ?? '';
      _rel11PermDistCtrl.text = data['rel11PermDist']?.toString() ?? '';
      _rel11PermStateCtrl.text = data['rel11PermState']?.toString() ?? '';
      _rel11PropCtrl.text = data['rel11Prop']?.toString() ?? '';
      _rel11PhoneCtrl.text = data['rel11Phone']?.toString() ?? '';

      _rel12NameCtrl.text = data['rel12Name']?.toString() ?? '';
      _rel12OccCtrl.text = data['rel12Occ']?.toString() ?? '';
      _rel12CurrAddrCtrl.text = data['rel12CurrAddr']?.toString() ?? '';
      _rel12CurrTalCtrl.text = data['rel12CurrTal']?.toString() ?? '';
      _rel12CurrDistCtrl.text = data['rel12CurrDist']?.toString() ?? '';
      _rel12CurrStateCtrl.text = data['rel12CurrState']?.toString() ?? '';
      _rel12PermAddrCtrl.text = data['rel12PermAddr']?.toString() ?? '';
      _rel12PermTalCtrl.text = data['rel12PermTal']?.toString() ?? '';
      _rel12PermDistCtrl.text = data['rel12PermDist']?.toString() ?? '';
      _rel12PermStateCtrl.text = data['rel12PermState']?.toString() ?? '';
      _rel12PropCtrl.text = data['rel12Prop']?.toString() ?? '';
      _rel12PhoneCtrl.text = data['rel12Phone']?.toString() ?? '';

      _rel13NameCtrl.text = data['rel13Name']?.toString() ?? '';
      _rel13OccCtrl.text = data['rel13Occ']?.toString() ?? '';
      _rel13CurrAddrCtrl.text = data['rel13CurrAddr']?.toString() ?? '';
      _rel13CurrTalCtrl.text = data['rel13CurrTal']?.toString() ?? '';
      _rel13CurrDistCtrl.text = data['rel13CurrDist']?.toString() ?? '';
      _rel13CurrStateCtrl.text = data['rel13CurrState']?.toString() ?? '';
      _rel13PermAddrCtrl.text = data['rel13PermAddr']?.toString() ?? '';
      _rel13PermTalCtrl.text = data['rel13PermTal']?.toString() ?? '';
      _rel13PermDistCtrl.text = data['rel13PermDist']?.toString() ?? '';
      _rel13PermStateCtrl.text = data['rel13PermState']?.toString() ?? '';
      _rel13PropCtrl.text = data['rel13Prop']?.toString() ?? '';
      _rel13PhoneCtrl.text = data['rel13Phone']?.toString() ?? '';

      _rel14NameCtrl.text = data['rel14Name']?.toString() ?? '';
      _rel14OccCtrl.text = data['rel14Occ']?.toString() ?? '';
      _rel14CurrAddrCtrl.text = data['rel14CurrAddr']?.toString() ?? '';
      _rel14CurrTalCtrl.text = data['rel14CurrTal']?.toString() ?? '';
      _rel14CurrDistCtrl.text = data['rel14CurrDist']?.toString() ?? '';
      _rel14CurrStateCtrl.text = data['rel14CurrState']?.toString() ?? '';
      _rel14PermAddrCtrl.text = data['rel14PermAddr']?.toString() ?? '';
      _rel14PermTalCtrl.text = data['rel14PermTal']?.toString() ?? '';
      _rel14PermDistCtrl.text = data['rel14PermDist']?.toString() ?? '';
      _rel14PermStateCtrl.text = data['rel14PermState']?.toString() ?? '';
      _rel14PropCtrl.text = data['rel14Prop']?.toString() ?? '';
      _rel14PhoneCtrl.text = data['rel14Phone']?.toString() ?? '';

      _rel15NameCtrl.text = data['rel15Name']?.toString() ?? '';
      _rel15OccCtrl.text = data['rel15Occ']?.toString() ?? '';
      _rel15CurrAddrCtrl.text = data['rel15CurrAddr']?.toString() ?? '';
      _rel15CurrTalCtrl.text = data['rel15CurrTal']?.toString() ?? '';
      _rel15CurrDistCtrl.text = data['rel15CurrDist']?.toString() ?? '';
      _rel15CurrStateCtrl.text = data['rel15CurrState']?.toString() ?? '';
      _rel15PermAddrCtrl.text = data['rel15PermAddr']?.toString() ?? '';
      _rel15PermTalCtrl.text = data['rel15PermTal']?.toString() ?? '';
      _rel15PermDistCtrl.text = data['rel15PermDist']?.toString() ?? '';
      _rel15PermStateCtrl.text = data['rel15PermState']?.toString() ?? '';
      _rel15PropCtrl.text = data['rel15Prop']?.toString() ?? '';
      _rel15PhoneCtrl.text = data['rel15Phone']?.toString() ?? '';

      _rel16NameCtrl.text = data['rel16Name']?.toString() ?? '';
      _rel16OccCtrl.text = data['rel16Occ']?.toString() ?? '';
      _rel16CurrAddrCtrl.text = data['rel16CurrAddr']?.toString() ?? '';
      _rel16CurrTalCtrl.text = data['rel16CurrTal']?.toString() ?? '';
      _rel16CurrDistCtrl.text = data['rel16CurrDist']?.toString() ?? '';
      _rel16CurrStateCtrl.text = data['rel16CurrState']?.toString() ?? '';
      _rel16PermAddrCtrl.text = data['rel16PermAddr']?.toString() ?? '';
      _rel16PermTalCtrl.text = data['rel16PermTal']?.toString() ?? '';
      _rel16PermDistCtrl.text = data['rel16PermDist']?.toString() ?? '';
      _rel16PermStateCtrl.text = data['rel16PermState']?.toString() ?? '';
      _rel16PropCtrl.text = data['rel16Prop']?.toString() ?? '';
      _rel16PhoneCtrl.text = data['rel16Phone']?.toString() ?? '';

      _rel17NameCtrl.text = data['rel17Name']?.toString() ?? '';
      _rel17OccCtrl.text = data['rel17Occ']?.toString() ?? '';
      _rel17CurrAddrCtrl.text = data['rel17CurrAddr']?.toString() ?? '';
      _rel17CurrTalCtrl.text = data['rel17CurrTal']?.toString() ?? '';
      _rel17CurrDistCtrl.text = data['rel17CurrDist']?.toString() ?? '';
      _rel17CurrStateCtrl.text = data['rel17CurrState']?.toString() ?? '';
      _rel17PermAddrCtrl.text = data['rel17PermAddr']?.toString() ?? '';
      _rel17PermTalCtrl.text = data['rel17PermTal']?.toString() ?? '';
      _rel17PermDistCtrl.text = data['rel17PermDist']?.toString() ?? '';
      _rel17PermStateCtrl.text = data['rel17PermState']?.toString() ?? '';
      _rel17PropCtrl.text = data['rel17Prop']?.toString() ?? '';
      _rel17PhoneCtrl.text = data['rel17Phone']?.toString() ?? '';

      _rel18NameCtrl.text = data['rel18Name']?.toString() ?? '';
      _rel18OccCtrl.text = data['rel18Occ']?.toString() ?? '';
      _rel18CurrAddrCtrl.text = data['rel18CurrAddr']?.toString() ?? '';
      _rel18CurrTalCtrl.text = data['rel18CurrTal']?.toString() ?? '';
      _rel18CurrDistCtrl.text = data['rel18CurrDist']?.toString() ?? '';
      _rel18CurrStateCtrl.text = data['rel18CurrState']?.toString() ?? '';
      _rel18PermAddrCtrl.text = data['rel18PermAddr']?.toString() ?? '';
      _rel18PermTalCtrl.text = data['rel18PermTal']?.toString() ?? '';
      _rel18PermDistCtrl.text = data['rel18PermDist']?.toString() ?? '';
      _rel18PermStateCtrl.text = data['rel18PermState']?.toString() ?? '';
      _rel18PropCtrl.text = data['rel18Prop']?.toString() ?? '';
      _rel18PhoneCtrl.text = data['rel18Phone']?.toString() ?? '';

      _rel19NameCtrl.text = data['rel19Name']?.toString() ?? '';
      _rel19OccCtrl.text = data['rel19Occ']?.toString() ?? '';
      _rel19CurrAddrCtrl.text = data['rel19CurrAddr']?.toString() ?? '';
      _rel19CurrTalCtrl.text = data['rel19CurrTal']?.toString() ?? '';
      _rel19CurrDistCtrl.text = data['rel19CurrDist']?.toString() ?? '';
      _rel19CurrStateCtrl.text = data['rel19CurrState']?.toString() ?? '';
      _rel19PermAddrCtrl.text = data['rel19PermAddr']?.toString() ?? '';
      _rel19PermTalCtrl.text = data['rel19PermTal']?.toString() ?? '';
      _rel19PermDistCtrl.text = data['rel19PermDist']?.toString() ?? '';
      _rel19PermStateCtrl.text = data['rel19PermState']?.toString() ?? '';
      _rel19PropCtrl.text = data['rel19Prop']?.toString() ?? '';
      _rel19PhoneCtrl.text = data['rel19Phone']?.toString() ?? '';

      _rel20NameCtrl.text = data['rel20Name']?.toString() ?? '';
      _rel20OccCtrl.text = data['rel20Occ']?.toString() ?? '';
      _rel20CurrAddrCtrl.text = data['rel20CurrAddr']?.toString() ?? '';
      _rel20CurrTalCtrl.text = data['rel20CurrTal']?.toString() ?? '';
      _rel20CurrDistCtrl.text = data['rel20CurrDist']?.toString() ?? '';
      _rel20CurrStateCtrl.text = data['rel20CurrState']?.toString() ?? '';
      _rel20PermAddrCtrl.text = data['rel20PermAddr']?.toString() ?? '';
      _rel20PermTalCtrl.text = data['rel20PermTal']?.toString() ?? '';
      _rel20PermDistCtrl.text = data['rel20PermDist']?.toString() ?? '';
      _rel20PermStateCtrl.text = data['rel20PermState']?.toString() ?? '';
      _rel20PropCtrl.text = data['rel20Prop']?.toString() ?? '';
      _rel20PhoneCtrl.text = data['rel20Phone']?.toString() ?? '';

      _rel21NameCtrl.text = data['rel21Name']?.toString() ?? '';
      _rel21OccCtrl.text = data['rel21Occ']?.toString() ?? '';
      _rel21CurrAddrCtrl.text = data['rel21CurrAddr']?.toString() ?? '';
      _rel21CurrTalCtrl.text = data['rel21CurrTal']?.toString() ?? '';
      _rel21CurrDistCtrl.text = data['rel21CurrDist']?.toString() ?? '';
      _rel21CurrStateCtrl.text = data['rel21CurrState']?.toString() ?? '';
      _rel21PermAddrCtrl.text = data['rel21PermAddr']?.toString() ?? '';
      _rel21PermTalCtrl.text = data['rel21PermTal']?.toString() ?? '';
      _rel21PermDistCtrl.text = data['rel21PermDist']?.toString() ?? '';
      _rel21PermStateCtrl.text = data['rel21PermState']?.toString() ?? '';
      _rel21PropCtrl.text = data['rel21Prop']?.toString() ?? '';
      _rel21PhoneCtrl.text = data['rel21Phone']?.toString() ?? '';

      _rel22NameCtrl.text = data['rel22Name']?.toString() ?? '';
      _rel22OccCtrl.text = data['rel22Occ']?.toString() ?? '';
      _rel22CurrAddrCtrl.text = data['rel22CurrAddr']?.toString() ?? '';
      _rel22CurrTalCtrl.text = data['rel22CurrTal']?.toString() ?? '';
      _rel22CurrDistCtrl.text = data['rel22CurrDist']?.toString() ?? '';
      _rel22CurrStateCtrl.text = data['rel22CurrState']?.toString() ?? '';
      _rel22PermAddrCtrl.text = data['rel22PermAddr']?.toString() ?? '';
      _rel22PermTalCtrl.text = data['rel22PermTal']?.toString() ?? '';
      _rel22PermDistCtrl.text = data['rel22PermDist']?.toString() ?? '';
      _rel22PermStateCtrl.text = data['rel22PermState']?.toString() ?? '';
      _rel22PropCtrl.text = data['rel22Prop']?.toString() ?? '';
      _rel22PhoneCtrl.text = data['rel22Phone']?.toString() ?? '';

      _rel23NameCtrl.text = data['rel23Name']?.toString() ?? '';
      _rel23OccCtrl.text = data['rel23Occ']?.toString() ?? '';
      _rel23CurrAddrCtrl.text = data['rel23CurrAddr']?.toString() ?? '';
      _rel23CurrTalCtrl.text = data['rel23CurrTal']?.toString() ?? '';
      _rel23CurrDistCtrl.text = data['rel23CurrDist']?.toString() ?? '';
      _rel23CurrStateCtrl.text = data['rel23CurrState']?.toString() ?? '';
      _rel23PermAddrCtrl.text = data['rel23PermAddr']?.toString() ?? '';
      _rel23PermTalCtrl.text = data['rel23PermTal']?.toString() ?? '';
      _rel23PermDistCtrl.text = data['rel23PermDist']?.toString() ?? '';
      _rel23PermStateCtrl.text = data['rel23PermState']?.toString() ?? '';
      _rel23PropCtrl.text = data['rel23Prop']?.toString() ?? '';
      _rel23PhoneCtrl.text = data['rel23Phone']?.toString() ?? '';
    });
  }

  Map<String, dynamic> collectData() {
    return {
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

      'rel9Name': _rel9NameCtrl.text.trim(),
      'rel9Occ': _rel9OccCtrl.text.trim(),
      'rel9CurrAddr': _rel9CurrAddrCtrl.text.trim(),
      'rel9CurrTal': _rel9CurrTalCtrl.text.trim(),
      'rel9CurrDist': _rel9CurrDistCtrl.text.trim(),
      'rel9CurrState': _rel9CurrStateCtrl.text.trim(),
      'rel9PermAddr': _rel9PermAddrCtrl.text.trim(),
      'rel9PermTal': _rel9PermTalCtrl.text.trim(),
      'rel9PermDist': _rel9PermDistCtrl.text.trim(),
      'rel9PermState': _rel9PermStateCtrl.text.trim(),
      'rel9Prop': _rel9PropCtrl.text.trim(),
      'rel9Phone': _rel9PhoneCtrl.text.trim(),

      'rel10Name': _rel10NameCtrl.text.trim(),
      'rel10Occ': _rel10OccCtrl.text.trim(),
      'rel10CurrAddr': _rel10CurrAddrCtrl.text.trim(),
      'rel10CurrTal': _rel10CurrTalCtrl.text.trim(),
      'rel10CurrDist': _rel10CurrDistCtrl.text.trim(),
      'rel10CurrState': _rel10CurrStateCtrl.text.trim(),
      'rel10PermAddr': _rel10PermAddrCtrl.text.trim(),
      'rel10PermTal': _rel10PermTalCtrl.text.trim(),
      'rel10PermDist': _rel10PermDistCtrl.text.trim(),
      'rel10PermState': _rel10PermStateCtrl.text.trim(),
      'rel10Prop': _rel10PropCtrl.text.trim(),
      'rel10Phone': _rel10PhoneCtrl.text.trim(),

      'rel11Name': _rel11NameCtrl.text.trim(),
      'rel11Occ': _rel11OccCtrl.text.trim(),
      'rel11CurrAddr': _rel11CurrAddrCtrl.text.trim(),
      'rel11CurrTal': _rel11CurrTalCtrl.text.trim(),
      'rel11CurrDist': _rel11CurrDistCtrl.text.trim(),
      'rel11CurrState': _rel11CurrStateCtrl.text.trim(),
      'rel11PermAddr': _rel11PermAddrCtrl.text.trim(),
      'rel11PermTal': _rel11PermTalCtrl.text.trim(),
      'rel11PermDist': _rel11PermDistCtrl.text.trim(),
      'rel11PermState': _rel11PermStateCtrl.text.trim(),
      'rel11Prop': _rel11PropCtrl.text.trim(),
      'rel11Phone': _rel11PhoneCtrl.text.trim(),

      'rel12Name': _rel12NameCtrl.text.trim(),
      'rel12Occ': _rel12OccCtrl.text.trim(),
      'rel12CurrAddr': _rel12CurrAddrCtrl.text.trim(),
      'rel12CurrTal': _rel12CurrTalCtrl.text.trim(),
      'rel12CurrDist': _rel12CurrDistCtrl.text.trim(),
      'rel12CurrState': _rel12CurrStateCtrl.text.trim(),
      'rel12PermAddr': _rel12PermAddrCtrl.text.trim(),
      'rel12PermTal': _rel12PermTalCtrl.text.trim(),
      'rel12PermDist': _rel12PermDistCtrl.text.trim(),
      'rel12PermState': _rel12PermStateCtrl.text.trim(),
      'rel12Prop': _rel12PropCtrl.text.trim(),
      'rel12Phone': _rel12PhoneCtrl.text.trim(),

      'rel13Name': _rel13NameCtrl.text.trim(),
      'rel13Occ': _rel13OccCtrl.text.trim(),
      'rel13CurrAddr': _rel13CurrAddrCtrl.text.trim(),
      'rel13CurrTal': _rel13CurrTalCtrl.text.trim(),
      'rel13CurrDist': _rel13CurrDistCtrl.text.trim(),
      'rel13CurrState': _rel13CurrStateCtrl.text.trim(),
      'rel13PermAddr': _rel13PermAddrCtrl.text.trim(),
      'rel13PermTal': _rel13PermTalCtrl.text.trim(),
      'rel13PermDist': _rel13PermDistCtrl.text.trim(),
      'rel13PermState': _rel13PermStateCtrl.text.trim(),
      'rel13Prop': _rel13PropCtrl.text.trim(),
      'rel13Phone': _rel13PhoneCtrl.text.trim(),

      'rel14Name': _rel14NameCtrl.text.trim(),
      'rel14Occ': _rel14OccCtrl.text.trim(),
      'rel14CurrAddr': _rel14CurrAddrCtrl.text.trim(),
      'rel14CurrTal': _rel14CurrTalCtrl.text.trim(),
      'rel14CurrDist': _rel14CurrDistCtrl.text.trim(),
      'rel14CurrState': _rel14CurrStateCtrl.text.trim(),
      'rel14PermAddr': _rel14PermAddrCtrl.text.trim(),
      'rel14PermTal': _rel14PermTalCtrl.text.trim(),
      'rel14PermDist': _rel14PermDistCtrl.text.trim(),
      'rel14PermState': _rel14PermStateCtrl.text.trim(),
      'rel14Prop': _rel14PropCtrl.text.trim(),
      'rel14Phone': _rel14PhoneCtrl.text.trim(),

      'rel15Name': _rel15NameCtrl.text.trim(),
      'rel15Occ': _rel15OccCtrl.text.trim(),
      'rel15CurrAddr': _rel15CurrAddrCtrl.text.trim(),
      'rel15CurrTal': _rel15CurrTalCtrl.text.trim(),
      'rel15CurrDist': _rel15CurrDistCtrl.text.trim(),
      'rel15CurrState': _rel15CurrStateCtrl.text.trim(),
      'rel15PermAddr': _rel15PermAddrCtrl.text.trim(),
      'rel15PermTal': _rel15PermTalCtrl.text.trim(),
      'rel15PermDist': _rel15PermDistCtrl.text.trim(),
      'rel15PermState': _rel15PermStateCtrl.text.trim(),
      'rel15Prop': _rel15PropCtrl.text.trim(),
      'rel15Phone': _rel15PhoneCtrl.text.trim(),

      'rel16Name': _rel16NameCtrl.text.trim(),
      'rel16Occ': _rel16OccCtrl.text.trim(),
      'rel16CurrAddr': _rel16CurrAddrCtrl.text.trim(),
      'rel16CurrTal': _rel16CurrTalCtrl.text.trim(),
      'rel16CurrDist': _rel16CurrDistCtrl.text.trim(),
      'rel16CurrState': _rel16CurrStateCtrl.text.trim(),
      'rel16PermAddr': _rel16PermAddrCtrl.text.trim(),
      'rel16PermTal': _rel16PermTalCtrl.text.trim(),
      'rel16PermDist': _rel16PermDistCtrl.text.trim(),
      'rel16PermState': _rel16PermStateCtrl.text.trim(),
      'rel16Prop': _rel16PropCtrl.text.trim(),
      'rel16Phone': _rel16PhoneCtrl.text.trim(),

      'rel17Name': _rel17NameCtrl.text.trim(),
      'rel17Occ': _rel17OccCtrl.text.trim(),
      'rel17CurrAddr': _rel17CurrAddrCtrl.text.trim(),
      'rel17CurrTal': _rel17CurrTalCtrl.text.trim(),
      'rel17CurrDist': _rel17CurrDistCtrl.text.trim(),
      'rel17CurrState': _rel17CurrStateCtrl.text.trim(),
      'rel17PermAddr': _rel17PermAddrCtrl.text.trim(),
      'rel17PermTal': _rel17PermTalCtrl.text.trim(),
      'rel17PermDist': _rel17PermDistCtrl.text.trim(),
      'rel17PermState': _rel17PermStateCtrl.text.trim(),
      'rel17Prop': _rel17PropCtrl.text.trim(),
      'rel17Phone': _rel17PhoneCtrl.text.trim(),

      'rel18Name': _rel18NameCtrl.text.trim(),
      'rel18Occ': _rel18OccCtrl.text.trim(),
      'rel18CurrAddr': _rel18CurrAddrCtrl.text.trim(),
      'rel18CurrTal': _rel18CurrTalCtrl.text.trim(),
      'rel18CurrDist': _rel18CurrDistCtrl.text.trim(),
      'rel18CurrState': _rel18CurrStateCtrl.text.trim(),
      'rel18PermAddr': _rel18PermAddrCtrl.text.trim(),
      'rel18PermTal': _rel18PermTalCtrl.text.trim(),
      'rel18PermDist': _rel18PermDistCtrl.text.trim(),
      'rel18PermState': _rel18PermStateCtrl.text.trim(),
      'rel18Prop': _rel18PropCtrl.text.trim(),
      'rel18Phone': _rel18PhoneCtrl.text.trim(),

      'rel19Name': _rel19NameCtrl.text.trim(),
      'rel19Occ': _rel19OccCtrl.text.trim(),
      'rel19CurrAddr': _rel19CurrAddrCtrl.text.trim(),
      'rel19CurrTal': _rel19CurrTalCtrl.text.trim(),
      'rel19CurrDist': _rel19CurrDistCtrl.text.trim(),
      'rel19CurrState': _rel19CurrStateCtrl.text.trim(),
      'rel19PermAddr': _rel19PermAddrCtrl.text.trim(),
      'rel19PermTal': _rel19PermTalCtrl.text.trim(),
      'rel19PermDist': _rel19PermDistCtrl.text.trim(),
      'rel19PermState': _rel19PermStateCtrl.text.trim(),
      'rel19Prop': _rel19PropCtrl.text.trim(),
      'rel19Phone': _rel19PhoneCtrl.text.trim(),

      'rel20Name': _rel20NameCtrl.text.trim(),
      'rel20Occ': _rel20OccCtrl.text.trim(),
      'rel20CurrAddr': _rel20CurrAddrCtrl.text.trim(),
      'rel20CurrTal': _rel20CurrTalCtrl.text.trim(),
      'rel20CurrDist': _rel20CurrDistCtrl.text.trim(),
      'rel20CurrState': _rel20CurrStateCtrl.text.trim(),
      'rel20PermAddr': _rel20PermAddrCtrl.text.trim(),
      'rel20PermTal': _rel20PermTalCtrl.text.trim(),
      'rel20PermDist': _rel20PermDistCtrl.text.trim(),
      'rel20PermState': _rel20PermStateCtrl.text.trim(),
      'rel20Prop': _rel20PropCtrl.text.trim(),
      'rel20Phone': _rel20PhoneCtrl.text.trim(),

      'rel21Name': _rel21NameCtrl.text.trim(),
      'rel21Occ': _rel21OccCtrl.text.trim(),
      'rel21CurrAddr': _rel21CurrAddrCtrl.text.trim(),
      'rel21CurrTal': _rel21CurrTalCtrl.text.trim(),
      'rel21CurrDist': _rel21CurrDistCtrl.text.trim(),
      'rel21CurrState': _rel21CurrStateCtrl.text.trim(),
      'rel21PermAddr': _rel21PermAddrCtrl.text.trim(),
      'rel21PermTal': _rel21PermTalCtrl.text.trim(),
      'rel21PermDist': _rel21PermDistCtrl.text.trim(),
      'rel21PermState': _rel21PermStateCtrl.text.trim(),
      'rel21Prop': _rel21PropCtrl.text.trim(),
      'rel21Phone': _rel21PhoneCtrl.text.trim(),

      'rel22Name': _rel22NameCtrl.text.trim(),
      'rel22Occ': _rel22OccCtrl.text.trim(),
      'rel22CurrAddr': _rel22CurrAddrCtrl.text.trim(),
      'rel22CurrTal': _rel22CurrTalCtrl.text.trim(),
      'rel22CurrDist': _rel22CurrDistCtrl.text.trim(),
      'rel22CurrState': _rel22CurrStateCtrl.text.trim(),
      'rel22PermAddr': _rel22PermAddrCtrl.text.trim(),
      'rel22PermTal': _rel22PermTalCtrl.text.trim(),
      'rel22PermDist': _rel22PermDistCtrl.text.trim(),
      'rel22PermState': _rel22PermStateCtrl.text.trim(),
      'rel22Prop': _rel22PropCtrl.text.trim(),
      'rel22Phone': _rel22PhoneCtrl.text.trim(),

      'rel23Name': _rel23NameCtrl.text.trim(),
      'rel23Occ': _rel23OccCtrl.text.trim(),
      'rel23CurrAddr': _rel23CurrAddrCtrl.text.trim(),
      'rel23CurrTal': _rel23CurrTalCtrl.text.trim(),
      'rel23CurrDist': _rel23CurrDistCtrl.text.trim(),
      'rel23CurrState': _rel23CurrStateCtrl.text.trim(),
      'rel23PermAddr': _rel23PermAddrCtrl.text.trim(),
      'rel23PermTal': _rel23PermTalCtrl.text.trim(),
      'rel23PermDist': _rel23PermDistCtrl.text.trim(),
      'rel23PermState': _rel23PermStateCtrl.text.trim(),
      'rel23Prop': _rel23PropCtrl.text.trim(),
      'rel23Phone': _rel23PhoneCtrl.text.trim(),
    };
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

  Widget _buildRelativeBlock({
    required String number,
    required String title,
    required TextEditingController nameCtrl,
    required TextEditingController occCtrl,
    required TextEditingController currAddrCtrl,
    required TextEditingController currTalCtrl,
    required TextEditingController currDistCtrl,
    required TextEditingController currStateCtrl,
    required TextEditingController permAddrCtrl,
    required TextEditingController permTalCtrl,
    required TextEditingController permDistCtrl,
    required TextEditingController permStateCtrl,
    required TextEditingController propCtrl,
    required TextEditingController phoneCtrl,
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
            _tableHeader(number, serifStyle),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(title, style: marathiLabelStyle),
            ),
            _tableCellInput(nameCtrl, serifStyle),
          ],
        ),
        TableRow(
          children: [
            const SizedBox(),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text('धंदा', style: marathiLabelStyle),
            ),
            _tableCellInput(occCtrl, serifStyle),
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
                resAddr: currAddrCtrl,
                taluka: currTalCtrl,
                dist: currDistCtrl,
                state: currStateCtrl,
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
                resAddr: permAddrCtrl,
                taluka: permTalCtrl,
                dist: permDistCtrl,
                state: permStateCtrl,
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
            _tableCellInput(propCtrl, serifStyle),
          ],
        ),
        TableRow(
          children: [
            const SizedBox(),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text('फोन नंबर व इतर माहिती', style: marathiLabelStyle),
            ),
            _tableCellInput(phoneCtrl, serifStyle),
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
              number: '9.',
              title: 'आरोपीच्या आईचे संपुर्ण नांव',
              nameCtrl: _rel9NameCtrl,
              occCtrl: _rel9OccCtrl,
              currAddrCtrl: _rel9CurrAddrCtrl,
              currTalCtrl: _rel9CurrTalCtrl,
              currDistCtrl: _rel9CurrDistCtrl,
              currStateCtrl: _rel9CurrStateCtrl,
              permAddrCtrl: _rel9PermAddrCtrl,
              permTalCtrl: _rel9PermTalCtrl,
              permDistCtrl: _rel9PermDistCtrl,
              permStateCtrl: _rel9PermStateCtrl,
              propCtrl: _rel9PropCtrl,
              phoneCtrl: _rel9PhoneCtrl,
              marathiLabelStyle: marathiLabelStyle,
              serifStyle: serifStyle,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 2 — ITEMS 10 TO 12 (Grandfather, Father, Paternal Grandfather)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 2 (Parents & Grandparents)',
          children: [
            _buildRelativeBlock(
              number: '10.',
              title: 'आईचे वडीलांचे संपुर्ण नांव',
              nameCtrl: _rel10NameCtrl,
              occCtrl: _rel10OccCtrl,
              currAddrCtrl: _rel10CurrAddrCtrl,
              currTalCtrl: _rel10CurrTalCtrl,
              currDistCtrl: _rel10CurrDistCtrl,
              currStateCtrl: _rel10CurrStateCtrl,
              permAddrCtrl: _rel10PermAddrCtrl,
              permTalCtrl: _rel10PermTalCtrl,
              permDistCtrl: _rel10PermDistCtrl,
              permStateCtrl: _rel10PermStateCtrl,
              propCtrl: _rel10PropCtrl,
              phoneCtrl: _rel10PhoneCtrl,
              marathiLabelStyle: marathiLabelStyle,
              serifStyle: serifStyle,
            ),
            const SizedBox(height: 12),

            _buildRelativeBlock(
              number: '11.',
              title: 'आरोपीच्या वडीलांचे संपुर्ण नांव',
              nameCtrl: _rel11NameCtrl,
              occCtrl: _rel11OccCtrl,
              currAddrCtrl: _rel11CurrAddrCtrl,
              currTalCtrl: _rel11CurrTalCtrl,
              currDistCtrl: _rel11CurrDistCtrl,
              currStateCtrl: _rel11CurrStateCtrl,
              permAddrCtrl: _rel11PermAddrCtrl,
              permTalCtrl: _rel11PermTalCtrl,
              permDistCtrl: _rel11PermDistCtrl,
              permStateCtrl: _rel11PermStateCtrl,
              propCtrl: _rel11PropCtrl,
              phoneCtrl: _rel11PhoneCtrl,
              marathiLabelStyle: marathiLabelStyle,
              serifStyle: serifStyle,
            ),
            const SizedBox(height: 12),

            _buildRelativeBlock(
              number: '12.',
              title: 'आरोपीच्या वडीलांचे वडील यांचे संपुर्ण नांव (आजा)',
              nameCtrl: _rel12NameCtrl,
              occCtrl: _rel12OccCtrl,
              currAddrCtrl: _rel12CurrAddrCtrl,
              currTalCtrl: _rel12CurrTalCtrl,
              currDistCtrl: _rel12CurrDistCtrl,
              currStateCtrl: _rel12CurrStateCtrl,
              permAddrCtrl: _rel12PermAddrCtrl,
              permTalCtrl: _rel12PermTalCtrl,
              permDistCtrl: _rel12PermDistCtrl,
              permStateCtrl: _rel12PermStateCtrl,
              propCtrl: _rel12PropCtrl,
              phoneCtrl: _rel12PhoneCtrl,
              marathiLabelStyle: marathiLabelStyle,
              serifStyle: serifStyle,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 3 — ITEMS 13 TO 16 (Brothers & Sisters)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 3 (Siblings Particulars)',
          children: [
            _buildRelativeBlock(
              number: '13.',
              title: 'आरोपीच्या भावाचे संपुर्ण नांव',
              nameCtrl: _rel13NameCtrl,
              occCtrl: _rel13OccCtrl,
              currAddrCtrl: _rel13CurrAddrCtrl,
              currTalCtrl: _rel13CurrTalCtrl,
              currDistCtrl: _rel13CurrDistCtrl,
              currStateCtrl: _rel13CurrStateCtrl,
              permAddrCtrl: _rel13PermAddrCtrl,
              permTalCtrl: _rel13PermTalCtrl,
              permDistCtrl: _rel13PermDistCtrl,
              permStateCtrl: _rel13PermStateCtrl,
              propCtrl: _rel13PropCtrl,
              phoneCtrl: _rel13PhoneCtrl,
              marathiLabelStyle: marathiLabelStyle,
              serifStyle: serifStyle,
            ),
            const SizedBox(height: 12),

            _buildRelativeBlock(
              number: '14.',
              title: 'आरोपीच्या भावाचे संपुर्ण नांव',
              nameCtrl: _rel14NameCtrl,
              occCtrl: _rel14OccCtrl,
              currAddrCtrl: _rel14CurrAddrCtrl,
              currTalCtrl: _rel14CurrTalCtrl,
              currDistCtrl: _rel14CurrDistCtrl,
              currStateCtrl: _rel14CurrStateCtrl,
              permAddrCtrl: _rel14PermAddrCtrl,
              permTalCtrl: _rel14PermTalCtrl,
              permDistCtrl: _rel14PermDistCtrl,
              permStateCtrl: _rel14PermStateCtrl,
              propCtrl: _rel14PropCtrl,
              phoneCtrl: _rel14PhoneCtrl,
              marathiLabelStyle: marathiLabelStyle,
              serifStyle: serifStyle,
            ),
            const SizedBox(height: 12),

            _buildRelativeBlock(
              number: '15.',
              title: 'आरोपीच्या बहिणीचे संपुर्ण नांव',
              nameCtrl: _rel15NameCtrl,
              occCtrl: _rel15OccCtrl,
              currAddrCtrl: _rel15CurrAddrCtrl,
              currTalCtrl: _rel15CurrTalCtrl,
              currDistCtrl: _rel15CurrDistCtrl,
              currStateCtrl: _rel15CurrStateCtrl,
              permAddrCtrl: _rel15PermAddrCtrl,
              permTalCtrl: _rel15PermTalCtrl,
              permDistCtrl: _rel15PermDistCtrl,
              permStateCtrl: _rel15PermStateCtrl,
              propCtrl: _rel15PropCtrl,
              phoneCtrl: _rel15PhoneCtrl,
              marathiLabelStyle: marathiLabelStyle,
              serifStyle: serifStyle,
            ),
            const SizedBox(height: 12),

            _buildRelativeBlock(
              number: '16.',
              title: 'आरोपीच्या बहिणीचे संपुर्ण नांव',
              nameCtrl: _rel16NameCtrl,
              occCtrl: _rel16OccCtrl,
              currAddrCtrl: _rel16CurrAddrCtrl,
              currTalCtrl: _rel16CurrTalCtrl,
              currDistCtrl: _rel16CurrDistCtrl,
              currStateCtrl: _rel16CurrStateCtrl,
              permAddrCtrl: _rel16PermAddrCtrl,
              permTalCtrl: _rel16PermTalCtrl,
              permDistCtrl: _rel16PermDistCtrl,
              permStateCtrl: _rel16PermStateCtrl,
              propCtrl: _rel16PropCtrl,
              phoneCtrl: _rel16PhoneCtrl,
              marathiLabelStyle: marathiLabelStyle,
              serifStyle: serifStyle,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 4 — ITEMS 17 TO 19 (Wives & In-Laws)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 4 (Spouse & In-Laws)',
          children: [
            _buildRelativeBlock(
              number: '17.',
              title: 'आरोपीच्या पत्नीचे संपुर्ण नांव',
              nameCtrl: _rel17NameCtrl,
              occCtrl: _rel17OccCtrl,
              currAddrCtrl: _rel17CurrAddrCtrl,
              currTalCtrl: _rel17CurrTalCtrl,
              currDistCtrl: _rel17CurrDistCtrl,
              currStateCtrl: _rel17CurrStateCtrl,
              permAddrCtrl: _rel17PermAddrCtrl,
              permTalCtrl: _rel17PermTalCtrl,
              permDistCtrl: _rel17PermDistCtrl,
              permStateCtrl: _rel17PermStateCtrl,
              propCtrl: _rel17PropCtrl,
              phoneCtrl: _rel17PhoneCtrl,
              marathiLabelStyle: marathiLabelStyle,
              serifStyle: serifStyle,
            ),
            const SizedBox(height: 12),

            _buildRelativeBlock(
              number: '18.',
              title: 'आरोपीच्या दुसऱ्या पत्नीचे संपुर्ण नांव',
              nameCtrl: _rel18NameCtrl,
              occCtrl: _rel18OccCtrl,
              currAddrCtrl: _rel18CurrAddrCtrl,
              currTalCtrl: _rel18CurrTalCtrl,
              currDistCtrl: _rel18CurrDistCtrl,
              currStateCtrl: _rel18CurrStateCtrl,
              permAddrCtrl: _rel18PermAddrCtrl,
              permTalCtrl: _rel18PermTalCtrl,
              permDistCtrl: _rel18PermDistCtrl,
              permStateCtrl: _rel18PermStateCtrl,
              propCtrl: _rel18PropCtrl,
              phoneCtrl: _rel18PhoneCtrl,
              marathiLabelStyle: marathiLabelStyle,
              serifStyle: serifStyle,
            ),
            const SizedBox(height: 12),

            _buildRelativeBlock(
              number: '19.',
              title: 'आरोपीच्या सासऱ्याचे संपुर्ण नांव',
              nameCtrl: _rel19NameCtrl,
              occCtrl: _rel19OccCtrl,
              currAddrCtrl: _rel19CurrAddrCtrl,
              currTalCtrl: _rel19CurrTalCtrl,
              currDistCtrl: _rel19CurrDistCtrl,
              currStateCtrl: _rel19CurrStateCtrl,
              permAddrCtrl: _rel19PermAddrCtrl,
              permTalCtrl: _rel19PermTalCtrl,
              permDistCtrl: _rel19PermDistCtrl,
              permStateCtrl: _rel19PermStateCtrl,
              propCtrl: _rel19PropCtrl,
              phoneCtrl: _rel19PhoneCtrl,
              marathiLabelStyle: marathiLabelStyle,
              serifStyle: serifStyle,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 5 — ITEMS 20 TO 23 (Children)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 5 (Children Particulars)',
          children: [
            _buildRelativeBlock(
              number: '20.',
              title: 'आरोपीच्या मुलाचे संपुर्ण नांव',
              nameCtrl: _rel20NameCtrl,
              occCtrl: _rel20OccCtrl,
              currAddrCtrl: _rel20CurrAddrCtrl,
              currTalCtrl: _rel20CurrTalCtrl,
              currDistCtrl: _rel20CurrDistCtrl,
              currStateCtrl: _rel20CurrStateCtrl,
              permAddrCtrl: _rel20PermAddrCtrl,
              permTalCtrl: _rel20PermTalCtrl,
              permDistCtrl: _rel20PermDistCtrl,
              permStateCtrl: _rel20PermStateCtrl,
              propCtrl: _rel20PropCtrl,
              phoneCtrl: _rel20PhoneCtrl,
              marathiLabelStyle: marathiLabelStyle,
              serifStyle: serifStyle,
            ),
            const SizedBox(height: 12),

            _buildRelativeBlock(
              number: '21.',
              title: 'आरोपीच्या मुलाचे संपुर्ण नांव',
              nameCtrl: _rel21NameCtrl,
              occCtrl: _rel21OccCtrl,
              currAddrCtrl: _rel21CurrAddrCtrl,
              currTalCtrl: _rel21CurrTalCtrl,
              currDistCtrl: _rel21CurrDistCtrl,
              currStateCtrl: _rel21CurrStateCtrl,
              permAddrCtrl: _rel21PermAddrCtrl,
              permTalCtrl: _rel21PermTalCtrl,
              permDistCtrl: _rel21PermDistCtrl,
              permStateCtrl: _rel21PermStateCtrl,
              propCtrl: _rel21PropCtrl,
              phoneCtrl: _rel21PhoneCtrl,
              marathiLabelStyle: marathiLabelStyle,
              serifStyle: serifStyle,
            ),
            const SizedBox(height: 12),

            _buildRelativeBlock(
              number: '22.',
              title: 'आरोपीच्या मुलाचे संपुर्ण नांव',
              nameCtrl: _rel22NameCtrl,
              occCtrl: _rel22OccCtrl,
              currAddrCtrl: _rel22CurrAddrCtrl,
              currTalCtrl: _rel22CurrTalCtrl,
              currDistCtrl: _rel22CurrDistCtrl,
              currStateCtrl: _rel22CurrStateCtrl,
              permAddrCtrl: _rel22PermAddrCtrl,
              permTalCtrl: _rel22PermTalCtrl,
              permDistCtrl: _rel22PermDistCtrl,
              permStateCtrl: _rel22PermStateCtrl,
              propCtrl: _rel22PropCtrl,
              phoneCtrl: _rel22PhoneCtrl,
              marathiLabelStyle: marathiLabelStyle,
              serifStyle: serifStyle,
            ),
            const SizedBox(height: 12),

            _buildRelativeBlock(
              number: '23.',
              title: 'आरोपीच्या मुलीचे संपुर्ण नांव',
              nameCtrl: _rel23NameCtrl,
              occCtrl: _rel23OccCtrl,
              currAddrCtrl: _rel23CurrAddrCtrl,
              currTalCtrl: _rel23CurrTalCtrl,
              currDistCtrl: _rel23CurrDistCtrl,
              currStateCtrl: _rel23CurrStateCtrl,
              permAddrCtrl: _rel23PermAddrCtrl,
              permTalCtrl: _rel23PermTalCtrl,
              permDistCtrl: _rel23PermDistCtrl,
              permStateCtrl: _rel23PermStateCtrl,
              propCtrl: _rel23PropCtrl,
              phoneCtrl: _rel23PhoneCtrl,
              marathiLabelStyle: marathiLabelStyle,
              serifStyle: serifStyle,
            ),
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
