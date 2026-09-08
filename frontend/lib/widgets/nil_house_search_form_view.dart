import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_table_helpers.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// निल घरझडती पंचनामा (Nil House Search Panchanama)
class NilHouseSearchFormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const NilHouseSearchFormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<NilHouseSearchFormView> createState() => NilHouseSearchFormViewState();
}

class NilHouseSearchFormViewState extends State<NilHouseSearchFormView> {
  final _psCtrl = TextEditingController();
  final _campCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  final _panch1Ctrl = TextEditingController();
  final _panch2Ctrl = TextEditingController();

  final _officerNameCtrl = TextEditingController();
  final _officerPsCtrl = TextEditingController();
  final _summonDateCtrl = TextEditingController();
  final _mauzaCtrl = TextEditingController();
  final _firPsCtrl = TextEditingController();
  final _crimeNoCtrl = TextEditingController();
  final _actSecCtrl = TextEditingController();
  final _accusedNameCtrl = TextEditingController();
  final _accusedTahCtrl = TextEditingController();

  final _searchPlaceCtrl = TextEditingController();
  final _personFoundCtrl = TextEditingController();
  final _searchPremisesCtrl = TextEditingController();
  final _seizurePropertyCtrl = TextEditingController();

  final _panchDateCtrl = TextEditingController();
  final _startTimeCtrl = TextEditingController();
  final _endTimeCtrl = TextEditingController();

  final _ownerSigCtrl = TextEditingController();
  final _panch1SigCtrl = TextEditingController();
  final _panch2SigCtrl = TextEditingController();

  @override
  void dispose() {
    _psCtrl.dispose();
    _campCtrl.dispose();
    _dateCtrl.dispose();
    _panch1Ctrl.dispose();
    _panch2Ctrl.dispose();
    _officerNameCtrl.dispose();
    _officerPsCtrl.dispose();
    _summonDateCtrl.dispose();
    _mauzaCtrl.dispose();
    _firPsCtrl.dispose();
    _crimeNoCtrl.dispose();
    _actSecCtrl.dispose();
    _accusedNameCtrl.dispose();
    _accusedTahCtrl.dispose();
    _searchPlaceCtrl.dispose();
    _personFoundCtrl.dispose();
    _searchPremisesCtrl.dispose();
    _seizurePropertyCtrl.dispose();
    _panchDateCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    _ownerSigCtrl.dispose();
    _panch1SigCtrl.dispose();
    _panch2SigCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'ps': _psCtrl.text,
      'camp': _campCtrl.text,
      'date': _dateCtrl.text,
      'panch1': _panch1Ctrl.text,
      'panch2': _panch2Ctrl.text,
      'officerName': _officerNameCtrl.text,
      'officerPs': _officerPsCtrl.text,
      'summonDate': _summonDateCtrl.text,
      'mauza': _mauzaCtrl.text,
      'firPs': _firPsCtrl.text,
      'crimeNo': _crimeNoCtrl.text,
      'actSec': _actSecCtrl.text,
      'accusedName': _accusedNameCtrl.text,
      'accusedTah': _accusedTahCtrl.text,
      'searchPlace': _searchPlaceCtrl.text,
      'personFound': _personFoundCtrl.text,
      'searchPremises': _searchPremisesCtrl.text,
      'seizureProperty': _seizurePropertyCtrl.text,
      'panchDate': _panchDateCtrl.text,
      'startTime': _startTimeCtrl.text,
      'endTime': _endTimeCtrl.text,
      'ownerSig': _ownerSigCtrl.text,
      'panch1Sig': _panch1SigCtrl.text,
      'panch2Sig': _panch2SigCtrl.text,
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    _psCtrl.text = data['ps']?.toString() ?? '';
    _campCtrl.text = data['camp']?.toString() ?? '';
    _dateCtrl.text = data['date']?.toString() ?? '';
    _panch1Ctrl.text = data['panch1']?.toString() ?? '';
    _panch2Ctrl.text = data['panch2']?.toString() ?? '';
    _officerNameCtrl.text = data['officerName']?.toString() ?? '';
    _officerPsCtrl.text = data['officerPs']?.toString() ?? '';
    _summonDateCtrl.text = data['summonDate']?.toString() ?? '';
    _mauzaCtrl.text = data['mauza']?.toString() ?? '';
    _firPsCtrl.text = data['firPs']?.toString() ?? '';
    _crimeNoCtrl.text = data['crimeNo']?.toString() ?? '';
    _actSecCtrl.text = data['actSec']?.toString() ?? '';
    _accusedNameCtrl.text = data['accusedName']?.toString() ?? '';
    _accusedTahCtrl.text = data['accusedTah']?.toString() ?? '';
    _searchPlaceCtrl.text = data['searchPlace']?.toString() ?? '';
    _personFoundCtrl.text = data['personFound']?.toString() ?? '';
    _searchPremisesCtrl.text = data['searchPremises']?.toString() ?? '';
    _seizurePropertyCtrl.text = data['seizureProperty']?.toString() ?? '';
    _panchDateCtrl.text = data['panchDate']?.toString() ?? '';
    _startTimeCtrl.text = data['startTime']?.toString() ?? '';
    _endTimeCtrl.text = data['endTime']?.toString() ?? '';
    _ownerSigCtrl.text = data['ownerSig']?.toString() ?? '';
    _panch1SigCtrl.text = data['panch1Sig']?.toString() ?? '';
    _panch2SigCtrl.text = data['panch2Sig']?.toString() ?? '';
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final serif = FormTypography.serifStyle();
    final marathi = FormTypography.marathiLabelStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        FormPaperPage(
          formLabel: widget.pageRange,
          children: [
            // ── TOP RIGHT POLICE STATION / CAMP / DATE ──
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 340,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BilingualField(
                      label: '',
                      marathiLabel: 'पोलीस स्टेशन :',
                      controller: _psCtrl,
                      serifStyle: serif,
                      marathiLabelStyle: marathi,
                    ),
                    BilingualField(
                      label: '',
                      marathiLabel: 'कॅम्प :',
                      controller: _campCtrl,
                      serifStyle: serif,
                      marathiLabelStyle: marathi,
                    ),
                    BilingualField(
                      label: '',
                      marathiLabel: 'दिनांक :-',
                      hintText: '......./ ....../ २०....',
                      controller: _dateCtrl,
                      serifStyle: serif,
                      marathiLabelStyle: marathi,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── TITLE ──
            Center(
              child: Text(
                'निल घरझडती पंचनामा',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── PANCH NAMES ──
            Text(
              'पंच नांव :-',
              style:
                  marathi.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            BilingualMultilineField(
              label: '',
              marathiLabel: '१)',
              controller: _panch1Ctrl,
              minLines: 2,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 6),
            BilingualMultilineField(
              label: '',
              marathiLabel: '२)',
              controller: _panch2Ctrl,
              minLines: 2,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 16),

            // ── PARAGRAPH 1 ──
            BilingualFieldRow(
              fields: [
                BilingualField(
                  label: '',
                  marathiLabel: 'आम्ही',
                  controller: _officerNameCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'पोलीस स्टेशन',
                  controller: _officerPsCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
              ],
            ),
            BilingualFieldRow(
              fields: [
                BilingualField(
                  label: '',
                  marathiLabel: 'यांनी दिनांक',
                  hintText: '...../ ....../ २०....',
                  controller: _summonDateCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'रोजी वरील नमुद पंचांना मौजा',
                  controller: _mauzaCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'येथे बोलवून कळविले की,',
              style: marathi.copyWith(fontSize: 12),
            ),
            BilingualFieldRow(
              fields: [
                BilingualField(
                  label: '',
                  marathiLabel: 'पो.स्टे.',
                  controller: _firPsCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'येथे अप.क्र.',
                  hintText: '........./ २०....',
                  controller: _crimeNoCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
              ],
            ),
            BilingualField(
              label: '',
              marathiLabel: 'कलम',
              hintText: 'भा.न्या.सं २०२३ अन्वये',
              controller: _actSecCtrl,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 4),
            Text(
              'दाखल असुन चोरीच्या मालाबाबत/ अवैध प्रोहिबीशन बाबत सदर गुन्ह्यामध्ये आरोपी नामे',
              style: marathi.copyWith(fontSize: 12),
            ),
            BilingualFieldRow(
              fields: [
                BilingualField(
                  label: '',
                  marathiLabel: 'आरोपी नामे :',
                  controller: _accusedNameCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'ता.-',
                  controller: _accusedTahCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'जि यवतमाळ याचे घराचे झडती घेणे असल्याने आपण पंच म्हणुन हजर राहावे. असे पंचाना कळवुन नमुद पंच सहमत होवून हजर आले.',
              style: marathi.copyWith(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 16),

            // ── PARAGRAPH 2 ──
            BilingualMultilineField(
              label: '',
              marathiLabel: 'आम्ही स्वतः सोबत पंच व स्टाफसह',
              controller: _searchPlaceCtrl,
              minLines: 2,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 4),
            Text(
              'त्याचे घरी जावुन आवाज दिला असता त्याचे घरी',
              style: marathi.copyWith(fontSize: 12),
            ),
            BilingualField(
              label: '',
              marathiLabel: 'व्यक्तीचे नाव :',
              hintText: 'हा हजर मिळाला...',
              controller: _personFoundCtrl,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 4),
            Text(
              'हा हजर मिळाला त्याचे घरी येण्याचा उद्देश समजवून सांगुन व त्याचा नाव, गावाची खात्री करून त्याचे',
              style: marathi.copyWith(fontSize: 12),
            ),
            BilingualField(
              label: '',
              marathiLabel: 'घराचे / जागेचे वर्णन :',
              controller: _searchPremisesCtrl,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 4),
            Text(
              'कायदेशीररित्या झडती घेतली असता त्याचे येथे सदर गुन्ह्यातील चोरी गेलेला माल/ मादक द्रव्य/ इतर संशयीत माल',
              style: marathi.copyWith(fontSize: 12),
            ),
            BilingualMultilineField(
              label: '',
              marathiLabel: 'माल तपशील / काही नाही :',
              controller: _seizurePropertyCtrl,
              minLines: 2,
              serifStyle: serif,
              marathiLabelStyle: marathi,
            ),
            const SizedBox(height: 4),
            Text(
              'मिळुन आला आहे/ नाही. घर झडती दरम्यान घरामधील सामानाचे नुकसान किंवा घरातील लोकांच्या धार्मीक भावना दुखाविण्या सारखे/ धर्मा विरूध्द कोणतेही कृत्य करण्यात आले नाही.',
              style: marathi.copyWith(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 16),

            // ── CLOSING PARAGRAPH ──
            BilingualFieldRow(
              fields: [
                BilingualField(
                  label: '',
                  marathiLabel: 'निल घरझडती पंचनामा आज दिनांक',
                  hintText: '......./ ...../ २०....',
                  controller: _panchDateCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'सुरू वेळ',
                  hintText: '....../ ........ वा',
                  controller: _startTimeCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
                BilingualField(
                  label: '',
                  marathiLabel: 'संपविला वेळ',
                  hintText: '...../ ..... वा',
                  controller: _endTimeCtrl,
                  serifStyle: serif,
                  marathiLabelStyle: marathi,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'मोक्यावर संपविला. पंचनामा पंचाना वाचुन दाखविला/ वाचुन पाहिला, बरोबर असल्याचे खात्री करून त्यावर त्यांनी सह्या केल्या.',
              style: marathi.copyWith(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 32),

            // ── SIGNATURES ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ज्याचे घराचे झडती घेतली त्याची सही/अंगठा',
                        style: marathi.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      BilingualField(
                        label: '',
                        marathiLabel: '',
                        controller: _ownerSigCtrl,
                        serifStyle: serif,
                        marathiLabelStyle: marathi,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'समक्ष',
                        style: marathi.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'पंच सही',
                        style: marathi.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      BilingualField(
                        label: '',
                        marathiLabel: '१)',
                        controller: _panch1SigCtrl,
                        serifStyle: serif,
                        marathiLabelStyle: marathi,
                      ),
                      const SizedBox(height: 6),
                      BilingualField(
                        label: '',
                        marathiLabel: '२)',
                        controller: _panch2SigCtrl,
                        serifStyle: serif,
                        marathiLabelStyle: marathi,
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
}
