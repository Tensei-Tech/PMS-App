import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

class AbFormView extends StatefulWidget {
  final dynamic existingRecord;
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const AbFormView({
    super.key,
    this.existingRecord,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<AbFormView> createState() => AbFormViewState();
}

class AbFormViewState extends State<AbFormView> {
  // ── Form A Controllers ──
  final _serialNoCtrl = TextEditingController();
  final _dispensaryCtrl = TextEditingController();
  final _personNameCtrl = TextEditingController();
  final _broughtByCtrl = TextEditingController();
  final _officerNameDesigCtrl = TextEditingController();
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
  final _consumedCtrl = TextEditingController();
  final _intoxicantTypeCtrl = TextEditingController();
  final _underInfluenceCtrl = TextEditingController();
  final _bloodCollectedCtrl = TextEditingController();
  final _formADatedCtrl = TextEditingController();
  final _formATimeCtrl = TextEditingController();
  final _moSignatureCtrl = TextEditingController();
  final _moDesignationCtrl = TextEditingController();
  final _examinedSigCtrl = TextEditingController();
  final _idMarksCtrl = TextEditingController();

  // ── Form B Controllers ──
  final _formBNoCtrl = TextEditingController();
  final _fromPractitionerCtrl = TextEditingController();
  final _toTestingOfficerCtrl = TextEditingController();
  final _formBDateCtrl = TextEditingController();
  final _messengerNameCtrl = TextEditingController();
  final _policeStationNameCtrl = TextEditingController();
  final _phialSerialCtrl = TextEditingController();
  final _bloodAmountCtrl = TextEditingController();
  final _collectionDateCtrl = TextEditingController();
  final _collectionTimeCtrl = TextEditingController();
  final _subjectNameCtrl = TextEditingController();
  final _subjectAddressCtrl = TextEditingController();
  final _producedByCtrl = TextEditingController();
  final _formBSignatureCtrl = TextEditingController();
  final _sealFacsimileCtrl = TextEditingController();

  bool get _showFormA {
    final s = widget.formSection?.toLowerCase() ?? '';
    if (s.isEmpty) return true;
    return s.contains('main') ||
        s.contains('form a') ||
        s.contains('page 1') ||
        s.contains('certificate');
  }

  bool get _showFormB {
    final s = widget.formSection?.toLowerCase() ?? '';
    if (s.isEmpty) return true;
    return s.contains('continuation') ||
        s.contains('form b') ||
        s.contains('page 2') ||
        s.contains('testing') ||
        s.contains('requisition');
  }

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
      _serialNoCtrl,
      _dispensaryCtrl,
      _personNameCtrl,
      _broughtByCtrl,
      _officerNameDesigCtrl,
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
      _consumedCtrl,
      _intoxicantTypeCtrl,
      _underInfluenceCtrl,
      _bloodCollectedCtrl,
      _formADatedCtrl,
      _formATimeCtrl,
      _moSignatureCtrl,
      _moDesignationCtrl,
      _examinedSigCtrl,
      _idMarksCtrl,
      _formBNoCtrl,
      _fromPractitionerCtrl,
      _toTestingOfficerCtrl,
      _formBDateCtrl,
      _messengerNameCtrl,
      _policeStationNameCtrl,
      _phialSerialCtrl,
      _bloodAmountCtrl,
      _collectionDateCtrl,
      _collectionTimeCtrl,
      _subjectNameCtrl,
      _subjectAddressCtrl,
      _producedByCtrl,
      _formBSignatureCtrl,
      _sealFacsimileCtrl,
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
      'broughtBy': _broughtByCtrl.text.trim(),
      'officerNameDesig': _officerNameDesigCtrl.text.trim(),
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
      'consumed': _consumedCtrl.text.trim(),
      'intoxicantType': _intoxicantTypeCtrl.text.trim(),
      'underInfluence': _underInfluenceCtrl.text.trim(),
      'bloodCollected': _bloodCollectedCtrl.text.trim(),
      'formADated': _formADatedCtrl.text.trim(),
      'formATime': _formATimeCtrl.text.trim(),
      'moSignature': _moSignatureCtrl.text.trim(),
      'moDesignation': _moDesignationCtrl.text.trim(),
      'examinedSignature': _examinedSigCtrl.text.trim(),
      'identificationMarks': _idMarksCtrl.text.trim(),
      // Form B
      'formBNo': _formBNoCtrl.text.trim(),
      'fromPractitioner': _fromPractitionerCtrl.text.trim(),
      'toTestingOfficer': _toTestingOfficerCtrl.text.trim(),
      'formBDate': _formBDateCtrl.text.trim(),
      'messengerName': _messengerNameCtrl.text.trim(),
      'policeStationName': _policeStationNameCtrl.text.trim(),
      'phialSerial': _phialSerialCtrl.text.trim(),
      'bloodAmountCc': _bloodAmountCtrl.text.trim(),
      'collectionDate': _collectionDateCtrl.text.trim(),
      'collectionTime': _collectionTimeCtrl.text.trim(),
      'subjectName': _subjectNameCtrl.text.trim(),
      'subjectAddress': _subjectAddressCtrl.text.trim(),
      'producedBy': _producedByCtrl.text.trim(),
      'formBSignature': _formBSignatureCtrl.text.trim(),
      'sealFacsimile': _sealFacsimileCtrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    setState(() {
      // Form A
      _serialNoCtrl.text = data['serialNo']?.toString() ?? '';
      _dispensaryCtrl.text = data['dispensary']?.toString() ?? '';
      _personNameCtrl.text = data['personName']?.toString() ?? '';
      _broughtByCtrl.text = data['broughtBy']?.toString() ?? '';
      _officerNameDesigCtrl.text = data['officerNameDesig']?.toString() ?? '';
      _broughtDateCtrl.text = data['broughtDate']?.toString() ?? '';
      _broughtTimeCtrl.text = data['broughtTime']?.toString() ?? '';
      _examinedDateCtrl.text = data['examinedDate']?.toString() ?? '';
      _examinedTimeCtrl.text = data['examinedTime']?.toString() ?? '';
      _ageCtrl.text = data['age']?.toString() ?? '';
      _weightCtrl.text = data['weight']?.toString() ?? '';
      _breathCtrl.text = data['breath']?.toString() ?? '';
      _speechCtrl.text = data['speech']?.toString() ?? '';
      _gaitCtrl.text = data['gait']?.toString() ?? '';
      _pupilsCtrl.text = data['pupils']?.toString() ?? '';
      _additionalRemarksCtrl.text = data['additionalRemarks']?.toString() ?? '';
      _consumedCtrl.text = data['consumed']?.toString() ?? '';
      _intoxicantTypeCtrl.text = data['intoxicantType']?.toString() ?? '';
      _underInfluenceCtrl.text = data['underInfluence']?.toString() ?? '';
      _bloodCollectedCtrl.text = data['bloodCollected']?.toString() ?? '';
      _formADatedCtrl.text = data['formADated']?.toString() ?? '';
      _formATimeCtrl.text = data['formATime']?.toString() ?? '';
      _moSignatureCtrl.text = data['moSignature']?.toString() ?? '';
      _moDesignationCtrl.text = data['moDesignation']?.toString() ?? '';
      _examinedSigCtrl.text = data['examinedSignature']?.toString() ?? '';
      _idMarksCtrl.text = data['identificationMarks']?.toString() ?? '';
      // Form B
      _formBNoCtrl.text = data['formBNo']?.toString() ?? '';
      _fromPractitionerCtrl.text = data['fromPractitioner']?.toString() ?? '';
      _toTestingOfficerCtrl.text = data['toTestingOfficer']?.toString() ?? '';
      _formBDateCtrl.text = data['formBDate']?.toString() ?? '';
      _messengerNameCtrl.text = data['messengerName']?.toString() ?? '';
      _policeStationNameCtrl.text = data['policeStationName']?.toString() ?? '';
      _phialSerialCtrl.text = data['phialSerial']?.toString() ?? '';
      _bloodAmountCtrl.text = data['bloodAmountCc']?.toString() ?? '';
      _collectionDateCtrl.text = data['collectionDate']?.toString() ?? '';
      _collectionTimeCtrl.text = data['collectionTime']?.toString() ?? '';
      _subjectNameCtrl.text = data['subjectName']?.toString() ?? '';
      _subjectAddressCtrl.text = data['subjectAddress']?.toString() ?? '';
      _producedByCtrl.text = data['producedBy']?.toString() ?? '';
      _formBSignatureCtrl.text = data['formBSignature']?.toString() ?? '';
      _sealFacsimileCtrl.text = data['sealFacsimile']?.toString() ?? '';
    });
  }

  // ── Helper Widgets for Clean Paper Form (No Placeholders) ──

  Widget _inlineBlank({
    required TextEditingController controller,
    required TextStyle style,
    double? width,
    bool readOnly = false,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        readOnly: widget.readOnly || readOnly,
        style: style.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0D47A1),
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF333333), width: 1.2),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF1976D2), width: 1.8),
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
        color: const Color(0xFF0D47A1),
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1976D2), width: 1.8),
        ),
      ),
    );
  }

  Widget _quickOptionChip(
    String text,
    TextEditingController controller, {
    String? valueToSet,
  }) {
    if (widget.readOnly) return const SizedBox.shrink();
    final isSelected = controller.text.trim() == (valueToSet ?? text);
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            controller.text = valueToSet ?? text;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE3F2FD) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade300,
              width: 0.8,
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.lora(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FORM A PAGE (Rule 3) — Exactly matching Image 1
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFormAPage(TextStyle serifStyle) {
    return FormPaperPage(
      formLabel: 'Form A (Rule 3)',
      children: [
        // ── Form A Centered Header ──
        Center(
          child: Column(
            children: [
              Text(
                'Form A',
                style: serifStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '(See Rule No 3)',
                style: serifStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Certificate by registered medical practioner aboving where person examined by him has  or\nhas not consumed an intoxicant.',
                textAlign: TextAlign.center,
                style: serifStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Serial No (Right/Center-Right) ──
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Serial No : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            _inlineBlank(
              controller: _serialNoCtrl,
              style: serifStyle,
              width: 140,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Hospital / Dispensary Block ──
        Text(
          '(Name and location of the Dispensary of Hospital)',
          style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        _inlineBlank(
          controller: _dispensaryCtrl,
          style: serifStyle,
          width: double.infinity,
        ),
        const SizedBox(height: 16),

        // ── Certified that Shri/Smt/Kumari Body Paragraph ──
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 8,
          children: [
            Text('•', style: serifStyle.copyWith(fontSize: 16)),
            Text('Certified that Shri/Smt/Kumari', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _personNameCtrl,
              style: serifStyle,
              width: 320,
            ),
            Text('was brought to this hospital /dispensary by', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _broughtByCtrl,
              style: serifStyle,
              width: 260,
            ),
            Text('(here state name and designation of the officer)', style: serifStyle.copyWith(fontSize: 11, fontStyle: FontStyle.italic)),
            Text('on', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _broughtDateCtrl,
              style: serifStyle,
              width: 110,
            ),
            Text('at', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _broughtTimeCtrl,
              style: serifStyle,
              width: 100,
            ),
            Text('(a.m./p.m. and was examined by MO )', style: serifStyle.copyWith(fontSize: 12)),
            Text('on', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _examinedDateCtrl,
              style: serifStyle,
              width: 110,
            ),
            Text('at', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _examinedTimeCtrl,
              style: serifStyle,
              width: 100,
            ),
            Text('a.m./p.m.', style: serifStyle.copyWith(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 20),

        // ── A clinical examination section ──
        Text(
          'A clinical examination of the above named person disclosed the following :-',
          style: serifStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),

        // Age
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 90,
                child: Text('Age :', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              Expanded(
                child: _inlineBlank(
                  controller: _ageCtrl,
                  style: serifStyle,
                ),
              ),
            ],
          ),
        ),

        // Weight
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 90,
                child: Text('Weight:', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              Expanded(
                child: _inlineBlank(
                  controller: _weightCtrl,
                  style: serifStyle,
                ),
              ),
            ],
          ),
        ),

        // Breath
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 90,
                    child: Text('Breath :', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  Expanded(
                    child: _inlineBlank(
                      controller: _breathCtrl,
                      style: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                children: [
                  _quickOptionChip('Smelling of Alcohol', _breathCtrl),
                  _quickOptionChip('Not smelling of Alcohol', _breathCtrl),
                  _quickOptionChip('Smelling of Ganja', _breathCtrl),
                  _quickOptionChip('Not smelling of any intoxicant', _breathCtrl),
                ],
              ),
            ],
          ),
        ),

        // Speech
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 90,
                    child: Text('Speech :', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  Expanded(
                    child: _inlineBlank(
                      controller: _speechCtrl,
                      style: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                children: [
                  _quickOptionChip('Normal', _speechCtrl),
                  _quickOptionChip('Incoherent', _speechCtrl),
                  _quickOptionChip('Slurred', _speechCtrl),
                ],
              ),
            ],
          ),
        ),

        // Gait
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 90,
                    child: Text('Gait :', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  Expanded(
                    child: _inlineBlank(
                      controller: _gaitCtrl,
                      style: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                children: [
                  _quickOptionChip('Steady', _gaitCtrl),
                  _quickOptionChip('Unsteady', _gaitCtrl),
                  _quickOptionChip('Staggering', _gaitCtrl),
                ],
              ),
            ],
          ),
        ),

        // Pupils
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 90,
                    child: Text('Pupiles. :', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  Expanded(
                    child: _inlineBlank(
                      controller: _pupilsCtrl,
                      style: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                children: [
                  _quickOptionChip('Normal', _pupilsCtrl),
                  _quickOptionChip('Dilated', _pupilsCtrl),
                  _quickOptionChip('Constricted', _pupilsCtrl),
                  _quickOptionChip('Reacting to light', _pupilsCtrl),
                ],
              ),
            ],
          ),
        ),

        // Additional remarks any
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Additional remarks any : ',
                style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Expanded(
                child: _inlineBlank(
                  controller: _additionalRemarksCtrl,
                  style: serifStyle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Finding Paragraph ──
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 8,
          children: [
            Text('I find that the above named person', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _consumedCtrl,
              style: serifStyle,
              width: 170,
            ),
            _inlineBlank(
              controller: _intoxicantTypeCtrl,
              style: serifStyle,
              width: 190,
            ),
            Text('I also find that he', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _underInfluenceCtrl,
              style: serifStyle,
              width: 90,
            ),
            Text('under the Influence of alcohol', style: serifStyle.copyWith(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          children: [
            _quickOptionChip('has consumed', _consumedCtrl),
            _quickOptionChip('has not consumed', _consumedCtrl),
            _quickOptionChip('Alcohol', _intoxicantTypeCtrl),
            _quickOptionChip('Opium', _intoxicantTypeCtrl),
            _quickOptionChip('Charas', _intoxicantTypeCtrl),
            _quickOptionChip('Ganja', _intoxicantTypeCtrl),
            _quickOptionChip('Bhang', _intoxicantTypeCtrl),
            _quickOptionChip('is', _underInfluenceCtrl),
            _quickOptionChip('is not', _underInfluenceCtrl),
          ],
        ),
        const SizedBox(height: 14),

        // ── (N.B. ... Blood note) ──
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            Text('(N.B.', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
            _inlineBlank(
              controller: _bloodCollectedCtrl,
              style: serifStyle,
              width: 90,
            ),
            Text(
              'Blood from the body of the above named was/was not collected by MO for',
              style: serifStyle.copyWith(fontSize: 12.5),
            ),
            Text('Chemical examination )', style: serifStyle.copyWith(fontSize: 12.5)),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          children: [
            _quickOptionChip('was', _bloodCollectedCtrl),
            _quickOptionChip('was not', _bloodCollectedCtrl),
          ],
        ),
        const SizedBox(height: 24),

        // ── Dated / Time / Signature / Designation Row (2 columns) ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Dated : ', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                      Expanded(
                        child: _inlineBlank(
                          controller: _formADatedCtrl,
                          style: serifStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Time : ', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                      Expanded(
                        child: _inlineBlank(
                          controller: _formATimeCtrl,
                          style: serifStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Signature : ', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                      Expanded(
                        child: _inlineBlank(
                          controller: _moSignatureCtrl,
                          style: serifStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Designation : ', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                      Expanded(
                        child: _inlineBlank(
                          controller: _moDesignationCtrl,
                          style: serifStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Person Examined Signature / Thumb Impression ──
        Text(
          'Signature/Thumb impression of the person examined',
          style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 12.5),
        ),
        _inlineBlank(
          controller: _examinedSigCtrl,
          style: serifStyle,
          width: double.infinity,
        ),
        const SizedBox(height: 16),

        // ── Marks of Identification in case refuses ──
        Text(
          'Marks of Identification of the person examined in case he refuses to given his signature /Thumb impression',
          style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        _multilineBlankBox(
          controller: _idMarksCtrl,
          style: serifStyle,
          minLines: 2,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FORM B PAGE (Rule 4(2)) — Exactly matching Image 2
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFormBPage(TextStyle serifStyle) {
    return FormPaperPage(
      formLabel: 'FORM "B" (Rule 4(2))',
      children: [
        // ── Form B Header ──
        Center(
          child: Column(
            children: [
              Text(
                'FORM "B"',
                style: serifStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '(See rule 4 (2))',
                style: serifStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── No. ......................... (Right aligned) ──
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('No. ', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
            _inlineBlank(
              controller: _formBNoCtrl,
              style: serifStyle,
              width: 180,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── From, Address Block ──
        Text('From,', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(
          '(Name, Designation and address of the registred medical practioner)',
          style: serifStyle.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
        ),
        _multilineBlankBox(
          controller: _fromPractitionerCtrl,
          style: serifStyle,
          minLines: 2,
        ),
        const SizedBox(height: 14),

        // ── To, Address Block ──
        Text('To,', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(
          '(Name and address of the Testing Officer)',
          style: serifStyle.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
        ),
        _multilineBlankBox(
          controller: _toTestingOfficerCtrl,
          style: serifStyle,
          minLines: 2,
        ),
        const SizedBox(height: 10),

        // ── Date :- (Right aligned) ──
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Date :- ', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
            _inlineBlank(
              controller: _formBDateCtrl,
              style: serifStyle,
              width: 160,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Sir, ──
        Text('Sir,', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),

        // ── Body Paragraph with Inlines matching Image 2 ──
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 10,
          children: [
            Text('I forward here with by post / with Shri.', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _messengerNameCtrl,
              style: serifStyle,
              width: 180,
            ),
            Text('of', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _policeStationNameCtrl,
              style: serifStyle,
              width: 160,
            ),
            Text('Police station a phial bearing serial No.', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _phialSerialCtrl,
              style: serifStyle,
              width: 140,
            ),
            Text('containing', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _bloodAmountCtrl,
              style: serifStyle,
              width: 60,
            ),
            Text('c.c. of venues blood collected by me on', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _collectionDateCtrl,
              style: serifStyle,
              width: 110,
            ),
            Text('at', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _collectionTimeCtrl,
              style: serifStyle,
              width: 100,
            ),
            Text('a.m./p.m. from the body of Shri/Smt/Kumari', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _subjectNameCtrl,
              style: serifStyle,
              width: 260,
            ),
            Text('of', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _subjectAddressCtrl,
              style: serifStyle,
              width: 320,
            ),
            Text('who was produced before me for medical examination and / or collection of blood from his / her body by', style: serifStyle.copyWith(fontSize: 13)),
            _inlineBlank(
              controller: _producedByCtrl,
              style: serifStyle,
              width: 260,
            ),
            Text('and request you to test the blood and issue a certificate ( in duplicates ) regarding the result of the test.', style: serifStyle.copyWith(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 28),

        // ── Yours Faithfully Signoff ──
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Yours Faithfully,', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 20),
              _inlineBlank(
                controller: _formBSignatureCtrl,
                style: serifStyle,
                width: 260,
              ),
              const SizedBox(height: 4),
              Text(
                'Signature and designation of the registered medical\npractioner.',
                textAlign: TextAlign.right,
                style: serifStyle.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Facsimile of the seal or Monogram Box ──
        Text(
          'Fascimile of the seal or Monogram',
          style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 12.5),
        ),
        Text(
          'used for sealing the phial containing the blood.',
          style: serifStyle.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 6),
        Container(
          height: 90,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1.0),
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey.shade50,
          ),
          padding: const EdgeInsets.all(8),
          child: TextFormField(
            controller: _sealFacsimileCtrl,
            readOnly: widget.readOnly,
            maxLines: 3,
            style: serifStyle.copyWith(
              fontSize: 12,
              color: const Color(0xFF0D47A1),
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Footnotes Separator & 3 Statutory Rules ──
        const Divider(color: Color(0xFF333333), thickness: 1.2),
        const SizedBox(height: 6),
        Text(
          'Here specify the name, designation and address of the messenger with whom the phial containing the blood is forwarded for delivery to the Testing.',
          style: serifStyle.copyWith(fontSize: 11, height: 1.3),
        ),
        const SizedBox(height: 4),
        Text(
          'Strike off, if these words are not required.',
          style: serifStyle.copyWith(fontSize: 11, height: 1.3),
        ),
        const SizedBox(height: 4),
        Text(
          'Here state the name and designation of the officer by whom the said person was produced for collection of blood.',
          style: serifStyle.copyWith(fontSize: 11, height: 1.3),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final serifStyle = FormTypography.serifStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        if (_showFormA) _buildFormAPage(serifStyle),
        if (_showFormA && _showFormB) const SizedBox(height: 24),
        if (_showFormB) _buildFormBPage(serifStyle),
      ],
    );
  }
}
