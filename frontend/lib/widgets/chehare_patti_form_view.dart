import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_table_helpers.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// चेहरे पट्टी (Chehare Patti - Descriptive Roll of Accused)
class CheharePattiFormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const CheharePattiFormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<CheharePattiFormView> createState() => CheharePattiFormViewState();
}

class CheharePattiFormViewState extends State<CheharePattiFormView> {
  final _dateCtrl = TextEditingController();
  final _psCtrl = TextEditingController();
  final _distCtrl = TextEditingController(text: 'यवतमाळ');

  final _crNoCtrl = TextEditingController();
  final _actSecCtrl = TextEditingController();
  final _accusedDetailsCtrl = TextEditingController();

  final _genderCtrl = TextEditingController();
  final _religionCtrl = TextEditingController();
  final _casteCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _physiqueCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _beardCtrl = TextEditingController();
  final _complexionCtrl = TextEditingController();
  final _disabilityCtrl = TextEditingController();
  final _eyesCtrl = TextEditingController();
  final _faceCtrl = TextEditingController();
  final _hairStyleCtrl = TextEditingController();
  final _mustacheCtrl = TextEditingController();
  final _noseCtrl = TextEditingController();
  final _earsCtrl = TextEditingController();
  final _teethCtrl = TextEditingController();
  final _burnMarksCtrl = TextEditingController();
  final _blackSpotsCtrl = TextEditingController();
  final _molesCtrl = TextEditingController();
  final _scarsCtrl = TextEditingController();
  final _tattooCtrl = TextEditingController();
  final _habitsCtrl = TextEditingController();
  final _speechCtrl = TextEditingController();
  final _clothingCtrl = TextEditingController();
  final _arrestDateTimeCtrl = TextEditingController();
  final _arrestingOfficerCtrl = TextEditingController();
  final _suretyCtrl = TextEditingController();
  final _pastConvictionCtrl = TextEditingController();
  final _caseResultCtrl = TextEditingController();

  final _accusedSigCtrl = TextEditingController();
  final _ioSigCtrl = TextEditingController();

  @override
  void dispose() {
    _dateCtrl.dispose();
    _psCtrl.dispose();
    _distCtrl.dispose();
    _crNoCtrl.dispose();
    _actSecCtrl.dispose();
    _accusedDetailsCtrl.dispose();
    _genderCtrl.dispose();
    _religionCtrl.dispose();
    _casteCtrl.dispose();
    _ageCtrl.dispose();
    _educationCtrl.dispose();
    _occupationCtrl.dispose();
    _physiqueCtrl.dispose();
    _heightCtrl.dispose();
    _beardCtrl.dispose();
    _complexionCtrl.dispose();
    _disabilityCtrl.dispose();
    _eyesCtrl.dispose();
    _faceCtrl.dispose();
    _hairStyleCtrl.dispose();
    _mustacheCtrl.dispose();
    _noseCtrl.dispose();
    _earsCtrl.dispose();
    _teethCtrl.dispose();
    _burnMarksCtrl.dispose();
    _blackSpotsCtrl.dispose();
    _molesCtrl.dispose();
    _scarsCtrl.dispose();
    _tattooCtrl.dispose();
    _habitsCtrl.dispose();
    _speechCtrl.dispose();
    _clothingCtrl.dispose();
    _arrestDateTimeCtrl.dispose();
    _arrestingOfficerCtrl.dispose();
    _suretyCtrl.dispose();
    _pastConvictionCtrl.dispose();
    _caseResultCtrl.dispose();
    _accusedSigCtrl.dispose();
    _ioSigCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'date': _dateCtrl.text,
      'policeStation': _psCtrl.text,
      'district': _distCtrl.text,
      'crNo': _crNoCtrl.text,
      'actSec': _actSecCtrl.text,
      'accusedDetails': _accusedDetailsCtrl.text,
      'gender': _genderCtrl.text,
      'religion': _religionCtrl.text,
      'caste': _casteCtrl.text,
      'age': _ageCtrl.text,
      'education': _educationCtrl.text,
      'occupation': _occupationCtrl.text,
      'physique': _physiqueCtrl.text,
      'height': _heightCtrl.text,
      'beard': _beardCtrl.text,
      'complexion': _complexionCtrl.text,
      'disability': _disabilityCtrl.text,
      'eyes': _eyesCtrl.text,
      'face': _faceCtrl.text,
      'hairStyle': _hairStyleCtrl.text,
      'mustache': _mustacheCtrl.text,
      'nose': _noseCtrl.text,
      'ears': _earsCtrl.text,
      'teeth': _teethCtrl.text,
      'burnMarks': _burnMarksCtrl.text,
      'blackSpots': _blackSpotsCtrl.text,
      'moles': _molesCtrl.text,
      'scars': _scarsCtrl.text,
      'tattoo': _tattooCtrl.text,
      'habits': _habitsCtrl.text,
      'speech': _speechCtrl.text,
      'clothing': _clothingCtrl.text,
      'arrestDateTime': _arrestDateTimeCtrl.text,
      'arrestingOfficer': _arrestingOfficerCtrl.text,
      'surety': _suretyCtrl.text,
      'pastConviction': _pastConvictionCtrl.text,
      'caseResult': _caseResultCtrl.text,
      'accusedSig': _accusedSigCtrl.text,
      'ioSig': _ioSigCtrl.text,
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    _dateCtrl.text = data['date']?.toString() ?? '';
    _psCtrl.text = data['policeStation']?.toString() ?? '';
    _distCtrl.text = data['district']?.toString() ?? 'यवतमाळ';
    _crNoCtrl.text = data['crNo']?.toString() ?? '';
    _actSecCtrl.text = data['actSec']?.toString() ?? '';
    _accusedDetailsCtrl.text = data['accusedDetails']?.toString() ?? '';
    _genderCtrl.text = data['gender']?.toString() ?? '';
    _religionCtrl.text = data['religion']?.toString() ?? '';
    _casteCtrl.text = data['caste']?.toString() ?? '';
    _ageCtrl.text = data['age']?.toString() ?? '';
    _educationCtrl.text = data['education']?.toString() ?? '';
    _occupationCtrl.text = data['occupation']?.toString() ?? '';
    _physiqueCtrl.text = data['physique']?.toString() ?? '';
    _heightCtrl.text = data['height']?.toString() ?? '';
    _beardCtrl.text = data['beard']?.toString() ?? '';
    _complexionCtrl.text = data['complexion']?.toString() ?? '';
    _disabilityCtrl.text = data['disability']?.toString() ?? '';
    _eyesCtrl.text = data['eyes']?.toString() ?? '';
    _faceCtrl.text = data['face']?.toString() ?? '';
    _hairStyleCtrl.text = data['hairStyle']?.toString() ?? '';
    _mustacheCtrl.text = data['mustache']?.toString() ?? '';
    _noseCtrl.text = data['nose']?.toString() ?? '';
    _earsCtrl.text = data['ears']?.toString() ?? '';
    _teethCtrl.text = data['teeth']?.toString() ?? '';
    _burnMarksCtrl.text = data['burnMarks']?.toString() ?? '';
    _blackSpotsCtrl.text = data['blackSpots']?.toString() ?? '';
    _molesCtrl.text = data['moles']?.toString() ?? '';
    _scarsCtrl.text = data['scars']?.toString() ?? '';
    _tattooCtrl.text = data['tattoo']?.toString() ?? '';
    _habitsCtrl.text = data['habits']?.toString() ?? '';
    _speechCtrl.text = data['speech']?.toString() ?? '';
    _clothingCtrl.text = data['clothing']?.toString() ?? '';
    _arrestDateTimeCtrl.text = data['arrestDateTime']?.toString() ?? '';
    _arrestingOfficerCtrl.text = data['arrestingOfficer']?.toString() ?? '';
    _suretyCtrl.text = data['surety']?.toString() ?? '';
    _pastConvictionCtrl.text = data['pastConviction']?.toString() ?? '';
    _caseResultCtrl.text = data['caseResult']?.toString() ?? '';
    _accusedSigCtrl.text = data['accusedSig']?.toString() ?? '';
    _ioSigCtrl.text = data['ioSig']?.toString() ?? '';
    if (mounted) setState(() {});
  }

  Widget _buildTableRow(String no, String title, Widget inputWidget,
      {bool isHeader = false}) {
    final marathi = FormTypography.marathiLabelStyle();
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 55,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            child: Text(
              no,
              style: isHeader
                  ? marathi.copyWith(fontWeight: FontWeight.bold, fontSize: 13)
                  : marathi.copyWith(fontSize: 12),
            ),
          ),
          Container(
            width: 220,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            child: Text(
              title,
              style: isHeader
                  ? marathi.copyWith(fontWeight: FontWeight.bold, fontSize: 13)
                  : marathi.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: inputWidget,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableInput(TextEditingController ctrl, {String? hint}) {
    final serif = FormTypography.serifStyle();
    return TextField(
      controller: ctrl,
      readOnly: widget.readOnly,
      style: serif.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade900,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        border: InputBorder.none,
        hintText: hint,
        hintStyle: serif.copyWith(color: Colors.grey.shade400, fontSize: 11),
      ),
    );
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
            // ── TOP BAR: TITLE & DATE ──
            Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    width: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('दिनांक : ', style: marathi),
                        Expanded(
                          child: BilingualSimpleUnderlineInput(
                            controller: _dateCtrl,
                            serifStyle: serif,
                            hintText: '......./ ...../ २०.......',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'चेहरे पट्टी',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── SUBHEADER: POLICE STATION & DISTRICT ──
            Center(
              child: SizedBox(
                width: 500,
                child: Row(
                  children: [
                    Text(
                      'पोलीस स्टेशन :- ',
                      style: marathi.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: BilingualSimpleUnderlineInput(
                        controller: _psCtrl,
                        serifStyle: serif,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'जिल्हा यवतमाळ',
                      style: marathi.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── MAIN TABLE ──
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.2),
              ),
              child: Column(
                children: [
                  // Table Header
                  _buildTableRow(
                    'अ.क्र.',
                    'विवरण',
                    Text(
                      '',
                      style: marathi.copyWith(fontWeight: FontWeight.bold),
                    ),
                    isHeader: true,
                  ),

                  // 1. CR NO & SECTION
                  _buildTableRow(
                    '१.',
                    'अप.क्र. व कलम',
                    Row(
                      children: [
                        SizedBox(
                          width: 140,
                          child: _tableInput(_crNoCtrl,
                              hint: '........../२०.....'),
                        ),
                        Text('कलम ',
                            style:
                                marathi.copyWith(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: _tableInput(_actSecCtrl,
                              hint: '....................................'),
                        ),
                      ],
                    ),
                  ),

                  // 2. ACCUSED NAME & ADDRESS & MOBILE
                  _buildTableRow(
                    '२.',
                    'आरोपीचे नांव व पत्ता मो नं',
                    TextField(
                      controller: _accusedDetailsCtrl,
                      readOnly: widget.readOnly,
                      minLines: 3,
                      maxLines: 4,
                      style: serif.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        border: InputBorder.none,
                        hintText: 'संपूर्ण नांव, पत्ता व मोबाईल नंबर...',
                        hintStyle: serif.copyWith(
                            color: Colors.grey.shade400, fontSize: 11),
                      ),
                    ),
                  ),

                  // 3. GENDER
                  _buildTableRow('३.', 'लिंग', _tableInput(_genderCtrl)),
                  // 4. RELIGION
                  _buildTableRow('४.', 'धर्म', _tableInput(_religionCtrl)),
                  // 5. CASTE
                  _buildTableRow('५.', 'जात', _tableInput(_casteCtrl)),
                  // 6. AGE
                  _buildTableRow('६.', 'वय', _tableInput(_ageCtrl)),
                  // 7. EDUCATION
                  _buildTableRow('७.', 'शिक्षण', _tableInput(_educationCtrl)),
                  // 8. OCCUPATION
                  _buildTableRow('८.', 'व्यवसाय', _tableInput(_occupationCtrl)),
                  // 9. PHYSIQUE
                  _buildTableRow(
                      '९.', 'शारिर बांधा', _tableInput(_physiqueCtrl)),
                  // 10. HEIGHT
                  _buildTableRow(
                      '१०.', 'उंची सें मी', _tableInput(_heightCtrl)),
                  // 11. BEARD
                  _buildTableRow('११.', 'दाढी', _tableInput(_beardCtrl)),
                  // 12. COLOR / COMPLEXION
                  _buildTableRow('१२.', 'रंग', _tableInput(_complexionCtrl)),
                  // 13. DISABILITY
                  _buildTableRow(
                      '१३.', 'व्यंग शरिरावर', _tableInput(_disabilityCtrl)),
                  // 14. EYES
                  _buildTableRow('१४.', 'डोळे', _tableInput(_eyesCtrl)),
                  // 15. FACE
                  _buildTableRow('१५.', 'चेहरा', _tableInput(_faceCtrl)),
                  // 16. HAIR STYLE
                  _buildTableRow(
                      '१६.', 'केसाची ठेवण', _tableInput(_hairStyleCtrl)),
                  // 17. MUSTACHE
                  _buildTableRow('१७.', 'मिशी', _tableInput(_mustacheCtrl)),
                  // 18. NOSE
                  _buildTableRow('१८.', 'नाक', _tableInput(_noseCtrl)),
                  // 19. EARS
                  _buildTableRow('१९.', 'कान', _tableInput(_earsCtrl)),
                  // 20. TEETH
                  _buildTableRow('२०.', 'दात', _tableInput(_teethCtrl)),
                  // 21. BURN MARKS
                  _buildTableRow(
                      '२१.', 'भाजल्याच्या खुना', _tableInput(_burnMarksCtrl)),
                  // 22. BLACK SPOTS
                  _buildTableRow(
                      '२२.', 'कोळ डाग', _tableInput(_blackSpotsCtrl)),
                  // 23. MOLE
                  _buildTableRow('२३.', 'तिळ', _tableInput(_molesCtrl)),
                  // 24. OLD SCARS
                  _buildTableRow('२४.', 'जुण्या जखमाचे व्रण व इतर खुणा',
                      _tableInput(_scarsCtrl)),
                  // 25. TATTOO
                  _buildTableRow('२५.', 'गोंदलेले', _tableInput(_tattooCtrl)),
                  // 26. HABITS
                  _buildTableRow('२६.', 'सवयी', _tableInput(_habitsCtrl)),
                  // 27. SPEECH
                  _buildTableRow(
                      '२७.', 'बोलण्याची पध्दत', _tableInput(_speechCtrl)),
                  // 28. DRESSING
                  _buildTableRow(
                      '२८.', 'कपडे कसे घालतो', _tableInput(_clothingCtrl)),
                  // 29. ARREST DATE TIME
                  _buildTableRow('२९.', 'अटकेचा दिनांक व वेळ',
                      _tableInput(_arrestDateTimeCtrl)),
                  // 30. ARRESTING OFFICER
                  _buildTableRow('३०.', 'अटक करणारे अंमलदार',
                      _tableInput(_arrestingOfficerCtrl)),
                  // 31. SURETY NAME
                  _buildTableRow(
                      '३१.',
                      'जमीनावर सोडला असल्यास जामीनदाराचे नांव',
                      _tableInput(_suretyCtrl)),
                  // 32. PAST CONVICTIONS
                  _buildTableRow(
                      '३२.',
                      'गुन्हेगारास अगोदर शिक्षा झाली काय व किती',
                      _tableInput(_pastConvictionCtrl)),
                  // 33. CASE OUTCOME
                  _buildTableRow(
                      '३३.', 'केंसचा निकाल', _tableInput(_caseResultCtrl)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── SIGNATURES ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      Text(
                        'आरोपीची स्वाक्षरी',
                        style: marathi.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BilingualSimpleUnderlineInput(
                        controller: _accusedSigCtrl,
                        serifStyle: serif,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      Text(
                        'तपासी अंमलदार सही',
                        style: marathi.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BilingualSimpleUnderlineInput(
                        controller: _ioSigCtrl,
                        serifStyle: serif,
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
