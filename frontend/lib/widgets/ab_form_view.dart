import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'form_paper_page.dart';
import 'form_view_scaffold.dart';

/// AB Form for Medical Examination:
/// Page 1: Form A (Certificate by registered medical practitioner)
/// Page 2: FORM "B" (Requisition for testing of blood sample)
class AbFormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const AbFormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<AbFormView> createState() => AbFormViewState();
}

class AbFormViewState extends State<AbFormView> {
  // ── Form A Fields ──
  final _serialNoCtrl = TextEditingController();
  final _dispensaryCtrl = TextEditingController();
  final _personNameCtrl = TextEditingController();
  final _personNameContCtrl = TextEditingController();
  final _broughtByOfficerCtrl = TextEditingController();
  final _broughtOfficerTitleCtrl = TextEditingController();
  final _broughtDateCtrl = TextEditingController();
  final _broughtTimeCtrl = TextEditingController();
  final _examinedDateCtrl = TextEditingController();
  final _examinedTimeCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _breathCtrl = TextEditingController();
  final _speechCtrl = TextEditingController();
  final _gaitCtrl = TextEditingController();
  final _pupilsCtrl = TextEditingController();
  final _additionalRemarksCtrl = TextEditingController();
  final _consumedOpinionCtrl = TextEditingController();
  final _influenceOpinionCtrl = TextEditingController();
  final _bloodNbCtrl = TextEditingController();
  final _formADatedCtrl = TextEditingController();
  final _formATimeCtrl = TextEditingController();
  final _moSignatureCtrl = TextEditingController();
  final _moDesignationCtrl = TextEditingController();
  final _examinedSigCtrl = TextEditingController();
  final _idMarksCtrl = TextEditingController();

  // ── Form B Fields ──
  final _formBNoCtrl = TextEditingController();
  final _fromPractitionerLine1Ctrl = TextEditingController();
  final _fromPractitionerLine2Ctrl = TextEditingController();
  final _toTestingOfficerLine1Ctrl = TextEditingController();
  final _toTestingOfficerLine2Ctrl = TextEditingController();
  final _formBDateCtrl = TextEditingController();
  final _messengerNameCtrl = TextEditingController();
  final _policeStationCtrl = TextEditingController();
  final _phialSerialCtrl = TextEditingController();
  final _bloodAmountCcCtrl = TextEditingController();
  final _collectionDateCtrl = TextEditingController();
  final _collectionTimeCtrl = TextEditingController();
  final _subjectNameCtrl = TextEditingController();
  final _subjectNameContCtrl = TextEditingController();
  final _subjectAddressCtrl = TextEditingController();
  final _producedByCtrl = TextEditingController();
  final _producedByContCtrl = TextEditingController();
  final _formBSignatureCtrl = TextEditingController();

  bool get _showFormA {
    final s = (widget.formSection ?? '').toLowerCase();
    if (s.isEmpty || s.contains('complete')) return true;
    return s.contains('main') || s.contains('form a') || s.contains('1');
  }

  bool get _showFormB {
    final s = (widget.formSection ?? '').toLowerCase();
    if (s.isEmpty || s.contains('complete')) return true;
    return s.contains('continuation') || s.contains('form b') || s.contains('2');
  }

  bool get _showAll => !_showFormA && !_showFormB;

  @override
  void dispose() {
    for (final c in [
      _serialNoCtrl,
      _dispensaryCtrl,
      _personNameCtrl,
      _personNameContCtrl,
      _broughtByOfficerCtrl,
      _broughtOfficerTitleCtrl,
      _broughtDateCtrl,
      _broughtTimeCtrl,
      _examinedDateCtrl,
      _examinedTimeCtrl,
      _ageCtrl,
      _weightCtrl,
      _breathCtrl,
      _speechCtrl,
      _gaitCtrl,
      _pupilsCtrl,
      _additionalRemarksCtrl,
      _consumedOpinionCtrl,
      _influenceOpinionCtrl,
      _bloodNbCtrl,
      _formADatedCtrl,
      _formATimeCtrl,
      _moSignatureCtrl,
      _moDesignationCtrl,
      _examinedSigCtrl,
      _idMarksCtrl,
      _formBNoCtrl,
      _fromPractitionerLine1Ctrl,
      _fromPractitionerLine2Ctrl,
      _toTestingOfficerLine1Ctrl,
      _toTestingOfficerLine2Ctrl,
      _formBDateCtrl,
      _messengerNameCtrl,
      _policeStationCtrl,
      _phialSerialCtrl,
      _bloodAmountCcCtrl,
      _collectionDateCtrl,
      _collectionTimeCtrl,
      _subjectNameCtrl,
      _subjectNameContCtrl,
      _subjectAddressCtrl,
      _producedByCtrl,
      _producedByContCtrl,
      _formBSignatureCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',

      // Form A
      'serialNo': _serialNoCtrl.text.trim(),
      'dispensary': _dispensaryCtrl.text.trim(),
      'personName': _personNameCtrl.text.trim(),
      'personNameCont': _personNameContCtrl.text.trim(),
      'broughtBy': _broughtByOfficerCtrl.text.trim(),
      'broughtOfficerTitle': _broughtOfficerTitleCtrl.text.trim(),
      'broughtDate': _broughtDateCtrl.text.trim(),
      'broughtTime': _broughtTimeCtrl.text.trim(),
      'examinedDate': _examinedDateCtrl.text.trim(),
      'examinedTime': _examinedTimeCtrl.text.trim(),
      'age': _ageCtrl.text.trim(),
      'weight': _weightCtrl.text.trim(),
      'breath': _breathCtrl.text.trim(),
      'speech': _speechCtrl.text.trim(),
      'gait': _gaitCtrl.text.trim(),
      'pupils': _pupilsCtrl.text.trim(),
      'additionalRemarks': _additionalRemarksCtrl.text.trim(),
      'consumed': _consumedOpinionCtrl.text.trim(),
      'underInfluence': _influenceOpinionCtrl.text.trim(),
      'bloodCollected': _bloodNbCtrl.text.trim(),
      'formADated': _formADatedCtrl.text.trim(),
      'formATime': _formATimeCtrl.text.trim(),
      'moSignature': _moSignatureCtrl.text.trim(),
      'moDesignation': _moDesignationCtrl.text.trim(),
      'examinedSignature': _examinedSigCtrl.text.trim(),
      'identificationMarks': _idMarksCtrl.text.trim(),

      // Form B
      'formBNo': _formBNoCtrl.text.trim(),
      'fromPractitionerLine1': _fromPractitionerLine1Ctrl.text.trim(),
      'fromPractitionerLine2': _fromPractitionerLine2Ctrl.text.trim(),
      'toTestingOfficerLine1': _toTestingOfficerLine1Ctrl.text.trim(),
      'toTestingOfficerLine2': _toTestingOfficerLine2Ctrl.text.trim(),
      'formBDate': _formBDateCtrl.text.trim(),
      'messengerName': _messengerNameCtrl.text.trim(),
      'policeStation': _policeStationCtrl.text.trim(),
      'phialSerial': _phialSerialCtrl.text.trim(),
      'bloodAmountCc': _bloodAmountCcCtrl.text.trim(),
      'collectionDate': _collectionDateCtrl.text.trim(),
      'collectionTime': _collectionTimeCtrl.text.trim(),
      'subjectName': _subjectNameCtrl.text.trim(),
      'subjectNameCont': _subjectNameContCtrl.text.trim(),
      'subjectAddress': _subjectAddressCtrl.text.trim(),
      'producedBy': _producedByCtrl.text.trim(),
      'producedByCont': _producedByContCtrl.text.trim(),
      'formBSignature': _formBSignatureCtrl.text.trim(),

      // Compatibility aliases
      'fromPractitioner': _fromPractitionerLine1Ctrl.text.trim(),
      'toTestingOfficer': _toTestingOfficerLine1Ctrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    void set(TextEditingController c, List<String> keys, [String fallback = '']) {
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

    // Form A
    set(_serialNoCtrl, ['serialNo']);
    set(_dispensaryCtrl, ['dispensary']);
    set(_personNameCtrl, ['personName']);
    set(_personNameContCtrl, ['personNameCont']);
    set(_broughtByOfficerCtrl, ['broughtBy']);
    set(_broughtOfficerTitleCtrl, ['broughtOfficerTitle']);
    set(_broughtDateCtrl, ['broughtDate']);
    set(_broughtTimeCtrl, ['broughtTime']);
    set(_examinedDateCtrl, ['examinedDate']);
    set(_examinedTimeCtrl, ['examinedTime']);
    set(_ageCtrl, ['age']);
    set(_weightCtrl, ['weight']);
    set(_breathCtrl, ['breath']);
    set(_speechCtrl, ['speech']);
    set(_gaitCtrl, ['gait']);
    set(_pupilsCtrl, ['pupils']);
    set(_additionalRemarksCtrl, ['additionalRemarks']);
    set(_consumedOpinionCtrl, ['consumed']);
    set(_influenceOpinionCtrl, ['underInfluence']);
    set(_bloodNbCtrl, ['bloodCollected']);
    set(_formADatedCtrl, ['formADated']);
    set(_formATimeCtrl, ['formATime']);
    set(_moSignatureCtrl, ['moSignature']);
    set(_moDesignationCtrl, ['moDesignation']);
    set(_examinedSigCtrl, ['examinedSignature']);
    set(_idMarksCtrl, ['identificationMarks']);

    // Form B
    set(_formBNoCtrl, ['formBNo']);
    set(_fromPractitionerLine1Ctrl, ['fromPractitionerLine1', 'fromPractitioner', 'moSignature']);
    set(_fromPractitionerLine2Ctrl, ['fromPractitionerLine2', 'dispensary']);
    set(_toTestingOfficerLine1Ctrl, ['toTestingOfficerLine1', 'toTestingOfficer']);
    set(_toTestingOfficerLine2Ctrl, ['toTestingOfficerLine2']);
    set(_formBDateCtrl, ['formBDate', 'formADated']);
    set(_messengerNameCtrl, ['messengerName']);
    set(_policeStationCtrl, ['policeStation', 'police_station', 'policeStationName']);
    set(_phialSerialCtrl, ['phialSerial', 'serialNo']);
    set(_bloodAmountCcCtrl, ['bloodAmountCc'], '5');
    set(_collectionDateCtrl, ['collectionDate', 'examinedDate']);
    set(_collectionTimeCtrl, ['collectionTime', 'examinedTime']);
    set(_subjectNameCtrl, ['subjectName', 'personName']);
    set(_subjectNameContCtrl, ['subjectNameCont', 'personNameCont']);
    set(_subjectAddressCtrl, ['subjectAddress']);
    set(_producedByCtrl, ['producedBy', 'broughtBy']);
    set(_producedByContCtrl, ['producedByCont']);
    set(_formBSignatureCtrl, ['formBSignature', 'moSignature']);

    if (mounted) setState(() {});
  }

  Widget _buildFormA(TextStyle bodyStyle, TextStyle boldStyle) {
    return FormPaperPage(
      formLabel: widget.pageRange ?? 'Page 1 — Form A (See Rule No 3)',
      children: [
        // Top Center Title
        Center(
          child: Column(
            children: [
              Text(
                'Form A',
                style: boldStyle.copyWith(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                '(See Rule No 3)',
                style: boldStyle.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Certificate by registered medical practioner aboving where person examined by him has or has not consumed an intoxicant.',
          style: boldStyle.copyWith(fontSize: 12.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),

        // Serial No (Right Aligned)
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Serial No : ', style: boldStyle),
              _UnderlineInput(
                controller: _serialNoCtrl,
                width: 140,
                readOnly: widget.readOnly,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Hospital / Dispensary
        Text('(Name and location of the Dispensary of Hospital)', style: boldStyle),
        const SizedBox(height: 2),
        _UnderlineInput(
          controller: _dispensaryCtrl,
          readOnly: widget.readOnly,
        ),
        const SizedBox(height: 12),

        // Certified that Shri/Smt/Kumari Paragraph
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text('•   Certified that Shri/Smt/Kumari', style: boldStyle),
            _UnderlineInput(
              controller: _personNameCtrl,
              width: 320,
              readOnly: widget.readOnly,
            ),
          ],
        ),
        const SizedBox(height: 4),
        _UnderlineInput(
          controller: _personNameContCtrl,
          readOnly: widget.readOnly,
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text('was brought to this hospital /dispensary by', style: bodyStyle),
            _UnderlineInput(
              controller: _broughtByOfficerCtrl,
              width: 250,
              readOnly: widget.readOnly,
            ),
          ],
        ),
        const SizedBox(height: 4),
        _UnderlineInput(
          controller: _broughtOfficerTitleCtrl,
          hintText: '(here state name and designation of the officer)',
          readOnly: widget.readOnly,
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text('on', style: bodyStyle),
            _UnderlineInput(
              controller: _broughtDateCtrl,
              width: 150,
              readOnly: widget.readOnly,
            ),
            Text('at', style: bodyStyle),
            _UnderlineInput(
              controller: _broughtTimeCtrl,
              width: 90,
              readOnly: widget.readOnly,
            ),
            Text('(a.m./p.m. and was examined by MO )', style: bodyStyle),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text('on', style: bodyStyle),
            _UnderlineInput(
              controller: _examinedDateCtrl,
              width: 120,
              readOnly: widget.readOnly,
            ),
            Text('at', style: bodyStyle),
            _UnderlineInput(
              controller: _examinedTimeCtrl,
              width: 90,
              readOnly: widget.readOnly,
            ),
            Text('a.m./p.m.', style: bodyStyle),
          ],
        ),
        const SizedBox(height: 14),

        // Clinical Examination Heading
        Text(
          'A clinical examination of the above named person disclosed the following :-',
          style: boldStyle,
        ),
        const SizedBox(height: 8),

        // Examination Items
        _buildExamRow('Age :', _ageCtrl, width: 140, boldStyle: boldStyle),
        const SizedBox(height: 6),
        _buildExamRow('Weight:', _weightCtrl, width: 140, boldStyle: boldStyle),
        const SizedBox(height: 6),
        _buildExamRow(
          'Breath :',
          _breathCtrl,
          suffix: 'smelling/Not smelling of Alcohol/Opium/Charas/Ganja/Bhang',
          width: 140,
          boldStyle: boldStyle,
          bodyStyle: bodyStyle,
        ),
        const SizedBox(height: 6),
        _buildExamRow(
          'Speech :',
          _speechCtrl,
          suffix: 'Incoherent/Normal',
          width: 140,
          boldStyle: boldStyle,
          bodyStyle: bodyStyle,
        ),
        const SizedBox(height: 6),
        _buildExamRow(
          'Gait  :',
          _gaitCtrl,
          suffix: 'unstead/Steady.',
          width: 140,
          boldStyle: boldStyle,
          bodyStyle: bodyStyle,
        ),
        const SizedBox(height: 6),
        _buildExamRow(
          'Pupiles.',
          _pupilsCtrl,
          suffix: 'Dilated/Normal',
          width: 140,
          boldStyle: boldStyle,
          bodyStyle: bodyStyle,
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Additional remarks any ', style: boldStyle),
            Expanded(
              child: _UnderlineInput(
                controller: _additionalRemarksCtrl,
                readOnly: widget.readOnly,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Finding Paragraph
        Text(
          '        I find that the above named person has consumed/has not consumed Alcohol/Opium/\nCharas/Ganja/Bhang/any toxicant I also find that he is/is not under the influence of alcohol',
          style: boldStyle.copyWith(height: 1.4),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Finding / Remarks: ', style: boldStyle),
            Expanded(
              child: _UnderlineInput(
                controller: _consumedOpinionCtrl,
                hintText: '[consumed / has not consumed / under influence]',
                readOnly: widget.readOnly,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // N.B. Blood collection
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            Text('(N.B.', style: boldStyle),
            _UnderlineInput(
              controller: _bloodNbCtrl,
              width: 100,
              hintText: 'was / was not',
              readOnly: widget.readOnly,
            ),
            Text(
              'Blood from the body of the above named was/was not collected by MO for Chemical examination )',
              style: boldStyle,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Dated / Time & Signature / Designation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Dated & Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Dated  ', style: boldStyle),
                    _UnderlineInput(
                      controller: _formADatedCtrl,
                      width: 160,
                      readOnly: widget.readOnly,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Time   ', style: boldStyle),
                    _UnderlineInput(
                      controller: _formATimeCtrl,
                      width: 160,
                      readOnly: widget.readOnly,
                    ),
                  ],
                ),
              ],
            ),

            // Right: Signature & Designation
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Signature ', style: boldStyle),
                    _UnderlineInput(
                      controller: _moSignatureCtrl,
                      width: 160,
                      readOnly: widget.readOnly,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Designation ', style: boldStyle),
                    _UnderlineInput(
                      controller: _moDesignationCtrl,
                      width: 160,
                      readOnly: widget.readOnly,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Signature/Thumb impression of person examined
        Text('Signature/Thumb impression of the person examined', style: boldStyle),
        const SizedBox(height: 2),
        _UnderlineInput(
          controller: _examinedSigCtrl,
          readOnly: widget.readOnly,
        ),
        const SizedBox(height: 10),

        // Marks of identification
        Text(
          'Marks of Identification of the person examined in case he refuses to given his signature /Thumb impression',
          style: boldStyle.copyWith(height: 1.3),
        ),
        const SizedBox(height: 2),
        _UnderlineInput(
          controller: _idMarksCtrl,
          readOnly: widget.readOnly,
        ),
      ],
    );
  }

  Widget _buildExamRow(
    String label,
    TextEditingController controller, {
    double width = 140,
    String? suffix,
    required TextStyle boldStyle,
    TextStyle? bodyStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 75,
          child: Text(label, style: boldStyle),
        ),
        _UnderlineInput(
          controller: controller,
          width: width,
          readOnly: widget.readOnly,
        ),
        if (suffix != null) ...[
          const SizedBox(width: 6),
          Expanded(child: Text(suffix, style: bodyStyle ?? boldStyle)),
        ],
      ],
    );
  }

  Widget _buildFormB(TextStyle bodyStyle, TextStyle boldStyle) {
    return FormPaperPage(
      formLabel: widget.pageRange ?? 'Page 2 — FORM "B" (See rule 4 (2))',
      children: [
        // Top Center Title
        Center(
          child: Column(
            children: [
              Text(
                'FORM "B"',
                style: boldStyle.copyWith(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                '(See rule 4 (2))',
                style: boldStyle.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // No. (Top Right)
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No. ', style: boldStyle),
              _UnderlineInput(
                controller: _formBNoCtrl,
                width: 180,
                readOnly: widget.readOnly,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // From
        Text('From,', style: boldStyle),
        const SizedBox(height: 2),
        Text(
          '(Name, Designation and address of the registred medical practioner)',
          style: boldStyle,
        ),
        const SizedBox(height: 2),
        _UnderlineInput(
          controller: _fromPractitionerLine1Ctrl,
          readOnly: widget.readOnly,
        ),
        const SizedBox(height: 4),
        _UnderlineInput(
          controller: _fromPractitionerLine2Ctrl,
          readOnly: widget.readOnly,
        ),
        const SizedBox(height: 10),

        // To
        Text('To,', style: boldStyle),
        const SizedBox(height: 2),
        Text(
          '(Name and address of the Testing Officer)',
          style: boldStyle,
        ),
        const SizedBox(height: 2),
        _UnderlineInput(
          controller: _toTestingOfficerLine1Ctrl,
          readOnly: widget.readOnly,
        ),
        const SizedBox(height: 4),
        _UnderlineInput(
          controller: _toTestingOfficerLine2Ctrl,
          readOnly: widget.readOnly,
        ),
        const SizedBox(height: 10),

        // Date (Right Aligned)
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Date :- ', style: boldStyle),
              _UnderlineInput(
                controller: _formBDateCtrl,
                width: 130,
                readOnly: widget.readOnly,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Salutation
        Text('Sir,', style: boldStyle),
        const SizedBox(height: 8),

        // Flowing Main Body Paragraph
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            const SizedBox(width: 32), // Indent
            Text('I forward here with by post / with Shri.', style: bodyStyle),
            _UnderlineInput(
              controller: _messengerNameCtrl,
              width: 180,
              readOnly: widget.readOnly,
            ),
            Text('of', style: bodyStyle),
            _UnderlineInput(
              controller: _policeStationCtrl,
              width: 130,
              readOnly: widget.readOnly,
            ),
            Text('Police station a phial bearing serial No.', style: bodyStyle),
            _UnderlineInput(
              controller: _phialSerialCtrl,
              width: 130,
              readOnly: widget.readOnly,
            ),
            Text('containing', style: bodyStyle),
            _UnderlineInput(
              controller: _bloodAmountCcCtrl,
              width: 60,
              readOnly: widget.readOnly,
            ),
            Text('c.c. of venues blood collected by me on', style: bodyStyle),
            _UnderlineInput(
              controller: _collectionDateCtrl,
              width: 110,
              readOnly: widget.readOnly,
            ),
            Text('at', style: bodyStyle),
            _UnderlineInput(
              controller: _collectionTimeCtrl,
              width: 90,
              hintText: 'a.m./p.m.',
              readOnly: widget.readOnly,
            ),
            Text('from the body of Shri/smt/Kumari', style: bodyStyle),
            _UnderlineInput(
              controller: _subjectNameCtrl,
              width: 200,
              readOnly: widget.readOnly,
            ),
          ],
        ),
        const SizedBox(height: 4),
        _UnderlineInput(
          controller: _subjectNameContCtrl,
          readOnly: widget.readOnly,
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text('of', style: bodyStyle),
            _UnderlineInput(
              controller: _subjectAddressCtrl,
              width: 260,
              readOnly: widget.readOnly,
            ),
            Text('who was produced before me for medical examination and / or collection of blood from his / her body by', style: bodyStyle),
            _UnderlineInput(
              controller: _producedByCtrl,
              width: 180,
              readOnly: widget.readOnly,
            ),
          ],
        ),
        const SizedBox(height: 4),
        _UnderlineInput(
          controller: _producedByContCtrl,
          readOnly: widget.readOnly,
        ),
        const SizedBox(height: 6),
        Text(
          'and request you to test the blood and issue a certificate ( in duplicates ) regarding the result of the test.',
          style: bodyStyle,
        ),
        const SizedBox(height: 18),

        // Yours Faithfully & Signature
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 32),
            child: Text('Yours Faithfully,', style: boldStyle),
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _UnderlineInput(
                controller: _formBSignatureCtrl,
                width: 250,
                hintText: '[Signature & Designation]',
                readOnly: widget.readOnly,
              ),
              const SizedBox(height: 4),
              Text(
                'Signature and designation of the registered medical\npractioner.',
                style: boldStyle,
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Facsimile Seal Box
        Text(
          'Fascimile of the seal or Monogram\nused for sealing the phial containing the blood.',
          style: boldStyle,
        ),
        const SizedBox(height: 6),
        Container(
          width: 140,
          height: 65,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54, width: 1),
          ),
          child: const Center(
            child: Text('[ SEAL / STAMP ]', style: TextStyle(color: Colors.black38, fontSize: 11)),
          ),
        ),
        const SizedBox(height: 18),

        // Horizontal Divider Line
        const Divider(color: Colors.black87, thickness: 1),
        const SizedBox(height: 6),

        // Footnotes
        Text(
          'Here specify the name, designation and address of the messenger with whom the phial containing the blood is forwarded for delivery to the Testing.',
          style: bodyStyle.copyWith(fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          'Strike off, if these words are not required.',
          style: bodyStyle.copyWith(fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          'Here state the name and designation of the officer by whom the said person was produced for collection of blood.',
          style: bodyStyle.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = GoogleFonts.lora(
      fontSize: 13,
      fontWeight: FontWeight.normal,
      color: Colors.black87,
      height: 1.5,
    );
    final boldStyle = GoogleFonts.lora(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
      height: 1.4,
    );

    final showA = _showFormA || _showAll;
    final showB = _showFormB || _showAll;

    final pages = <Widget>[];
    if (showA) {
      pages.add(_buildFormA(bodyStyle, boldStyle));
    }
    if (showB) {
      if (pages.isNotEmpty) pages.add(const SizedBox(height: 28));
      pages.add(_buildFormB(bodyStyle, boldStyle));
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
      scrollPhysics: const NeverScrollableScrollPhysics(),
      scrollPadding: EdgeInsets.zero,
      style: GoogleFonts.lora(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.blue.shade900,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.only(bottom: 0, top: 1),
        hintText: hintText,
        hintStyle: GoogleFonts.lora(
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
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
  }
}
