import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_table_helpers.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// INJURY CERTIFICATE
class InjuryCertificateFormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const InjuryCertificateFormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<InjuryCertificateFormView> createState() =>
      InjuryCertificateFormViewState();
}

class InjuryRowControllers {
  final TextEditingController typeOfInjury;
  final TextEditingController siteOnBody;
  final TextEditingController ageOfInjury;
  final TextEditingController size;
  final TextEditingController color;
  final TextEditingController probableWeapon;
  final TextEditingController simpleGrievous;
  final TextEditingController remark;

  InjuryRowControllers({
    String typeOfInjury = '',
    String siteOnBody = '',
    String ageOfInjury = '',
    String size = '',
    String color = '',
    String probableWeapon = '',
    String simpleGrievous = '',
    String remark = '',
  })  : typeOfInjury = TextEditingController(text: typeOfInjury),
        siteOnBody = TextEditingController(text: siteOnBody),
        ageOfInjury = TextEditingController(text: ageOfInjury),
        size = TextEditingController(text: size),
        color = TextEditingController(text: color),
        probableWeapon = TextEditingController(text: probableWeapon),
        simpleGrievous = TextEditingController(text: simpleGrievous),
        remark = TextEditingController(text: remark);

  void dispose() {
    typeOfInjury.dispose();
    siteOnBody.dispose();
    ageOfInjury.dispose();
    size.dispose();
    color.dispose();
    probableWeapon.dispose();
    simpleGrievous.dispose();
    remark.dispose();
  }

  Map<String, String> toMap() {
    return {
      'typeOfInjury': typeOfInjury.text,
      'siteOnBody': siteOnBody.text,
      'ageOfInjury': ageOfInjury.text,
      'size': size.text,
      'color': color.text,
      'probableWeapon': probableWeapon.text,
      'simpleGrievous': simpleGrievous.text,
      'remark': remark.text,
    };
  }
}

class InjuryCertificateFormViewState extends State<InjuryCertificateFormView> {
  final _mlcNoCtrl = TextEditingController();
  final _mlcDateCtrl = TextEditingController();
  final _patientNameCtrl = TextEditingController();
  final _patientAgeCtrl = TextEditingController();
  final _idMarkAndAddressCtrl = TextEditingController();
  final _tahCtrl = TextEditingController();
  final _distCtrl = TextEditingController();
  final _broughtByCtrl = TextEditingController();
  final _buckleNoCtrl = TextEditingController();
  final _policeStationCtrl = TextEditingController();
  final _broughtTimeCtrl = TextEditingController();
  final _broughtDateCtrl = TextEditingController();
  final _examDateCtrl = TextEditingController();
  final _examTimeCtrl = TextEditingController();
  final _footerDateCtrl = TextEditingController();
  final _footerPlaceCtrl = TextEditingController();
  final _moNameCtrl = TextEditingController();

  final List<InjuryRowControllers> _injuryRows = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      _injuryRows.add(InjuryRowControllers());
    }
  }

  @override
  void dispose() {
    _mlcNoCtrl.dispose();
    _mlcDateCtrl.dispose();
    _patientNameCtrl.dispose();
    _patientAgeCtrl.dispose();
    _idMarkAndAddressCtrl.dispose();
    _tahCtrl.dispose();
    _distCtrl.dispose();
    _broughtByCtrl.dispose();
    _buckleNoCtrl.dispose();
    _policeStationCtrl.dispose();
    _broughtTimeCtrl.dispose();
    _broughtDateCtrl.dispose();
    _examDateCtrl.dispose();
    _examTimeCtrl.dispose();
    _footerDateCtrl.dispose();
    _footerPlaceCtrl.dispose();
    _moNameCtrl.dispose();
    for (final r in _injuryRows) {
      r.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'mlcNo': _mlcNoCtrl.text,
      'mlcDate': _mlcDateCtrl.text,
      'patientName': _patientNameCtrl.text,
      'patientAge': _patientAgeCtrl.text,
      'idMarkAndAddress': _idMarkAndAddressCtrl.text,
      'tah': _tahCtrl.text,
      'dist': _distCtrl.text,
      'broughtBy': _broughtByCtrl.text,
      'buckleNo': _buckleNoCtrl.text,
      'policeStation': _policeStationCtrl.text,
      'broughtTime': _broughtTimeCtrl.text,
      'broughtDate': _broughtDateCtrl.text,
      'examDate': _examDateCtrl.text,
      'examTime': _examTimeCtrl.text,
      'injuries': _injuryRows.map((r) => r.toMap()).toList(),
      'footerDate': _footerDateCtrl.text,
      'footerPlace': _footerPlaceCtrl.text,
      'moName': _moNameCtrl.text,
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    _mlcNoCtrl.text = data['mlcNo']?.toString() ?? '';
    _mlcDateCtrl.text = data['mlcDate']?.toString() ?? '';
    _patientNameCtrl.text = data['patientName']?.toString() ?? '';
    _patientAgeCtrl.text = data['patientAge']?.toString() ?? '';
    _idMarkAndAddressCtrl.text = data['idMarkAndAddress']?.toString() ?? '';
    _tahCtrl.text = data['tah']?.toString() ?? '';
    _distCtrl.text = data['dist']?.toString() ?? '';
    _broughtByCtrl.text = data['broughtBy']?.toString() ?? '';
    _buckleNoCtrl.text = data['buckleNo']?.toString() ?? '';
    _policeStationCtrl.text = data['policeStation']?.toString() ?? '';
    _broughtTimeCtrl.text = data['broughtTime']?.toString() ?? '';
    _broughtDateCtrl.text = data['broughtDate']?.toString() ?? '';
    _examDateCtrl.text = data['examDate']?.toString() ?? '';
    _examTimeCtrl.text = data['examTime']?.toString() ?? '';
    _footerDateCtrl.text = data['footerDate']?.toString() ?? '';
    _footerPlaceCtrl.text = data['footerPlace']?.toString() ?? '';
    _moNameCtrl.text = data['moName']?.toString() ?? '';

    final rawInjuries = data['injuries'];
    if (rawInjuries is List && rawInjuries.isNotEmpty) {
      for (final r in _injuryRows) {
        r.dispose();
      }
      _injuryRows.clear();
      for (final item in rawInjuries) {
        if (item is Map) {
          _injuryRows.add(
            InjuryRowControllers(
              typeOfInjury: item['typeOfInjury']?.toString() ?? '',
              siteOnBody: item['siteOnBody']?.toString() ?? '',
              ageOfInjury: item['ageOfInjury']?.toString() ?? '',
              size: item['size']?.toString() ?? '',
              color: item['color']?.toString() ?? '',
              probableWeapon: item['probableWeapon']?.toString() ?? '',
              simpleGrievous: item['simpleGrievous']?.toString() ?? '',
              remark: item['remark']?.toString() ?? '',
            ),
          );
        }
      }
    }
    if (mounted) setState(() {});
  }

  void _addRow() {
    setState(() {
      _injuryRows.add(InjuryRowControllers());
    });
  }

  void _removeRow() {
    if (_injuryRows.length > 1) {
      setState(() {
        final last = _injuryRows.removeLast();
        last.dispose();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final serif = FormTypography.serifStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        FormPaperPage(
          formLabel: widget.pageRange,
          children: [
            Center(
              child: Text(
                'INJURY CERTIFICATE',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BilingualField(
                      label: 'MLC No.:-',
                      marathiLabel: '',
                      hintText: '................................',
                      controller: _mlcNoCtrl,
                      serifStyle: serif,
                      marathiLabelStyle: serif,
                    ),
                    BilingualField(
                      label: 'Date.',
                      marathiLabel: '',
                      hintText: '....../........ /20.....',
                      controller: _mlcDateCtrl,
                      serifStyle: serif,
                      marathiLabelStyle: serif,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── PARAGRAPH SECTION ──
            BilingualFieldRow(
              fields: [
                BilingualField(
                  label: 'Certified that shri/smt',
                  marathiLabel: '',
                  hintText: '................................................................',
                  controller: _patientNameCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: serif,
                ),
                BilingualField(
                  label: 'age',
                  marathiLabel: '',
                  hintText: '..........',
                  controller: _patientAgeCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: serif,
                ),
              ],
            ),
            const Text(
              'about years',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),

            BilingualField(
              label: 'bearing following identification mark R/O.',
              marathiLabel: '',
              hintText: '................................................................................',
              controller: _idMarkAndAddressCtrl,
              serifStyle: serif,
              marathiLabelStyle: serif,
            ),
            BilingualFieldRow(
              fields: [
                BilingualField(
                  label: 'tah',
                  marathiLabel: '',
                  hintText: '...................',
                  controller: _tahCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: serif,
                ),
                BilingualField(
                  label: 'dist.',
                  marathiLabel: '',
                  hintText: '...........................',
                  controller: _distCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: serif,
                ),
              ],
            ),
            const SizedBox(height: 8),

            BilingualFieldRow(
              fields: [
                BilingualField(
                  label: 'brought to this hospital by PC/HC.',
                  marathiLabel: '',
                  hintText: '..........................',
                  controller: _broughtByCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: serif,
                ),
                BilingualField(
                  label: 'B.No.',
                  marathiLabel: '',
                  hintText: '.......',
                  controller: _buckleNoCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: serif,
                ),
                BilingualField(
                  label: 'Police station.',
                  marathiLabel: '',
                  hintText: '.......................',
                  controller: _policeStationCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: serif,
                ),
              ],
            ),
            const SizedBox(height: 8),

            BilingualFieldRow(
              fields: [
                BilingualField(
                  label: 'at',
                  marathiLabel: '',
                  hintText: '.......',
                  controller: _broughtTimeCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: serif,
                ),
                BilingualField(
                  label: 'AM/PM on',
                  marathiLabel: '',
                  hintText: '....../....../20......',
                  controller: _broughtDateCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: serif,
                ),
                BilingualField(
                  label: '& examination by me on',
                  marathiLabel: '',
                  hintText: '....../....... /20.....',
                  controller: _examDateCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: serif,
                ),
                BilingualField(
                  label: 'at',
                  marathiLabel: '',
                  hintText: '....../.......',
                  controller: _examTimeCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: serif,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 9-COLUMN TABLE ──
            Table(
              border: TableBorder.all(color: Colors.black, width: 1.0),
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(1.2),
                5: FlexColumnWidth(1.2),
                6: FlexColumnWidth(2),
                7: FlexColumnWidth(1.5),
                8: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    _buildHeaderCell('Sr\nno'),
                    _buildHeaderCell('Type of\ninjury'),
                    _buildHeaderCell('Site on the part of\nbody'),
                    _buildHeaderCell('Age of\ninjury'),
                    _buildHeaderCell('Size'),
                    _buildHeaderCell('Color'),
                    _buildHeaderCell('Probable\nweapon used'),
                    _buildHeaderCell('Simpler\nGrievous'),
                    _buildHeaderCell('Remark'),
                  ],
                ),
                for (int i = 0; i < _injuryRows.length; i++)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      _buildTableCell(_injuryRows[i].typeOfInjury),
                      _buildTableCell(_injuryRows[i].siteOnBody),
                      _buildTableCell(_injuryRows[i].ageOfInjury),
                      _buildTableCell(_injuryRows[i].size),
                      _buildTableCell(_injuryRows[i].color),
                      _buildTableCell(_injuryRows[i].probableWeapon),
                      _buildTableCell(_injuryRows[i].simpleGrievous),
                      _buildTableCell(_injuryRows[i].remark),
                    ],
                  ),
              ],
            ),
            if (!widget.readOnly) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Row'),
                  ),
                  const SizedBox(width: 8),
                  if (_injuryRows.length > 1)
                    OutlinedButton.icon(
                      onPressed: _removeRow,
                      icon: const Icon(Icons.remove, size: 16),
                      label: const Text('Remove Row'),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 36),

            // ── FOOTER SECTION ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: BilingualField(
                    label: 'Date:-',
                    marathiLabel: '',
                    hintText: '......./..../20.....',
                    controller: _footerDateCtrl,
                    serifStyle: serif,
                    marathiLabelStyle: serif,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: BilingualField(
                    label: 'Place:-',
                    marathiLabel: '',
                    hintText: '..........................',
                    controller: _footerPlaceCtrl,
                    serifStyle: serif,
                    marathiLabelStyle: serif,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medical officer',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Name and Sing',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      BilingualField(
                        label: '',
                        marathiLabel: '',
                        controller: _moNameCtrl,
                        serifStyle: serif,
                        marathiLabelStyle: serif,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FormMrwFooter(serifStyle: serif),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TextField(
        controller: ctrl,
        readOnly: widget.readOnly,
        maxLines: 2,
        minLines: 1,
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }
}
