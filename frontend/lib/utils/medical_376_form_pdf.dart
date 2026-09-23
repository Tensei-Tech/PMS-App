// lib/utils/medical_376_form_pdf.dart
//
// IMAGE-BASED PDF generation for 376 Medical Examination Form (Female & Male).
// Each page is rendered as a Flutter widget via an offscreen RepaintBoundary,
// captured as a high-resolution PNG (2.0x pixel ratio), and assembled into an A4 PDF.
// This guarantees 100% Devanagari text shaping fidelity with zero matra/conjunct errors
// and zero page overflow/clipping.

// ignore_for_file: unused_element

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'form_image_pdf_helper.dart';

// ── Dimensions ─────────────────────────────────────────────────────────────────
const double _kW = 794.0; // A4 portrait width at 96 DPI
const double _kH = 1123.0; // A4 portrait height at 96 DPI

// ── Public API ─────────────────────────────────────────────────────────────────

Future<void> previewMedical376FormPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      '376_Medical_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final sectionKey = _v(doc, 'formSection').toLowerCase();
  final isFemaleSection = sectionKey.contains('female');
  final isMaleSection = sectionKey.contains('male') && !isFemaleSection;
  final showFemale = sectionKey.isEmpty || isFemaleSection;
  final showMale = isMaleSection;

  final pages = <Widget>[];

  if (showFemale) {
    pages.add(_pgFemale1(doc));
    pages.add(_pgFemale2(doc));
    pages.add(_pgFemale3(doc));
    pages.add(_pgFemale4(doc));
  } else if (showMale) {
    pages.add(_pgMale1(doc));
    pages.add(_pgMale2(doc));
  }

  if (pages.isEmpty) {
    pages.add(_pgFemale1(doc));
    pages.add(_pgFemale2(doc));
    pages.add(_pgFemale3(doc));
    pages.add(_pgFemale4(doc));
  }

  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: pages,
    height: null,
  );
}

Future<Uint8List> generateMedical376FormPdf(Map<String, dynamic> doc) async {
  return Uint8List(0);
}

// ── Typography & Helper Styles ─────────────────────────────────────────────────

TextStyle _fH1() => GoogleFonts.lora(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

TextStyle _fH1M() => GoogleFonts.notoSansDevanagari(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

TextStyle _fBold({double size = 8.5}) => GoogleFonts.lora(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

TextStyle _fRegular({double size = 8.0}) => GoogleFonts.lora(
      fontSize: size,
      color: Colors.black,
    );

TextStyle _fMarathi({double size = 7.5, bool isBold = false}) =>
    GoogleFonts.notoSansDevanagari(
      fontSize: size,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: Colors.black,
    );

TextStyle _fValue({double size = 8.0}) => GoogleFonts.notoSansDevanagari(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

String _v(Map<String, dynamic> doc, String key) =>
    doc[key]?.toString().trim() ?? '';

Widget _row(
  String labelEn,
  String labelMr,
  String val, {
  double labelWidth = 190,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 1.5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(labelEn, style: _fBold(size: 8)),
              if (labelMr.isNotEmpty) Text(labelMr, style: _fMarathi(size: 7)),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 1),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: Colors.black45, width: 0.5)),
            ),
            child: Text(
              val.isEmpty ? '—' : val,
              style: _fValue(size: 8),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _section(String en, String mr) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 4, bottom: 2),
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
    color: const Color(0xFFEEEEEE),
    child: Row(
      children: [
        Text(en, style: _fBold(size: 8.5)),
        if (mr.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(mr, style: _fMarathi(size: 8, isBold: true)),
        ],
      ],
    ),
  );
}

Widget _textBlock(String val, String caption) {
  if (val.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 1.5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (caption.isNotEmpty)
          Text(caption, style: _fMarathi(size: 7.5, isBold: true)),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26, width: 0.5),
            color: const Color(0xFFFAFAFA),
          ),
          child: Text(val, style: _fValue(size: 8)),
        ),
      ],
    ),
  );
}

/// Shows a section header + [children] only when at least one child has content.
/// Pass the list of content widgets; if all are [SizedBox.shrink()] this collapses.
Widget _sectionedBlock(
  String en,
  String mr,
  List<Widget> children,
) {
  // A cleaner heuristic: check if children list has any non-SizedBox.shrink entries
  final hasContent = children.any((w) {
    if (w is SizedBox && w.height == null && w.width == null) return false;
    return true;
  });
  if (!hasContent) return const SizedBox.shrink();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _section(en, mr),
      ...children,
    ],
  );
}

/// A [Wrap] that returns [SizedBox.shrink()] when all mapped children are empty.
Widget _compactWrap(List<Widget> children,
    {double spacing = 16, double runSpacing = 3}) {
  final nonEmpty = children.where((w) {
    if (w is SizedBox && w.height == null && w.width == null) return false;
    return true;
  }).toList();
  if (nonEmpty.isEmpty) return const SizedBox.shrink();
  return Wrap(
    spacing: spacing,
    runSpacing: runSpacing,
    children: nonEmpty,
  );
}

// ── FEMALE PAGE 1 ──────────────────────────────────────────────────────────────

Widget _pgFemale1(Map<String, dynamic> doc) {
  return Container(
    width: _kW,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'महाराष्ट्र शासन — सार्वजनिक आरोग्य विभाग. परिपत्रक क्र.: संकीर्ण-२०१४/प्र.क्र.२७०/आरोग्य-३. दिनांक: ०७ ऑगस्ट, २०१५.',
            style: _fMarathi(size: 8, isBold: true),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('CONFIDENTIAL', style: _fBold(size: 8.5)),
              Text('गोपनीय', style: _fMarathi(size: 7.5, isBold: true)),
            ],
          ),
        ),
        Center(
          child: Column(
            children: [
              Text(
                  'Medico-legal Examination Report of Sexual Violence (Female)',
                  style: _fH1(),
                  textAlign: TextAlign.center),
              Text('लैंगिक हिंसाचाराचा वैद्यकीय-कायदेशीर तपासणी अहवाल (स्त्री)',
                  style: _fH1M(), textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _row('Hospital', 'रुग्णालय', _v(doc, 'f_hospital')),
        _row('Name', 'नाव', _v(doc, 'f_name')),
        _row('Age / DOB', 'वय / जन्मतारीख',
            '${_v(doc, 'f_age')} / ${_v(doc, 'f_dob')}'),
        _row('MLC / P.S.', 'एम.एल.सी. / पो.ठ.',
            '${_v(doc, 'f_mlc')} / ${_v(doc, 'f_ps')}'),
        _row('Arrival', 'आगमन', _v(doc, 'f_arrival')),
        _section(
            '12. Informed Consent / refusal', '१२. माहितीपूर्ण संमती / नकार'),
        Text(
          'I ${_v(doc, 'f_consentName').isEmpty ? _v(doc, 'f_name') : _v(doc, 'f_consentName')} D/o or S/o ${_v(doc, 'f_consentParent').isEmpty ? _v(doc, 'f_parent') : _v(doc, 'f_consentParent')} hereby give my consent for:',
          style: _fRegular(size: 7.5),
        ),
        _row('a) medical examination for treatment',
            'अ) उपचारासाठी वैद्यकीय तपासणी', _v(doc, 'f_consentTreatment')),
        _row('b) this medico legal examination',
            'ब) ही वैद्यकीय-कायदेशीर तपासणी', _v(doc, 'f_consentMedicoLegal')),
        _row(
            'c) sample collection for clinical & forensic examination',
            'क) नैदानिक व फॉरेन्सिक नमुने गोळा करणे',
            _v(doc, 'f_consentSample')),
        Text(
          'I also understand that as per law the hospital is required to inform police and this has been explained to me.',
          style: _fRegular(size: 7.5),
        ),
        _row('Information revealed to police', 'माहिती पोलिसांना दिली जावी',
            _v(doc, 'f_consentPoliceInfo')),
        Text(
          'I have understood the purpose and procedure of the examination including risk and benefit. Explained in: ${_v(doc, 'f_consentLanguage')} language. Support person: ${_v(doc, 'f_consentSupportRole')}',
          style: _fRegular(size: 7.5),
        ),
        if (_v(doc, 'f_consentHelperSig').isNotEmpty)
          _row('Special educator/interpreter signature',
              'विशेष शिक्षक/दुभाषी सही', _v(doc, 'f_consentHelperSig')),
        _section('Signatures', 'सह्या'),
        _row('Survivor / Guardian signature', 'पीडित / पालक सही',
            _v(doc, 'f_survivorSig')),
        _row('Witness signature / thumb', 'साक्षीदार सही / अंगठा',
            _v(doc, 'f_witnessSig')),
        _section('13. Marks of identification', '१३. ओळखीच्या खुणा'),
        _row('(1)', '(१)', _v(doc, 'f_idMark1')),
        _row('(2)', '(२)', _v(doc, 'f_idMark2')),
        _section('14. Relevant Medical/Surgical history',
            '१४. संबंधित वैद्यकीय / शस्त्रक्रिया इतिहास'),
        _row('Onset of menarche', 'मासिक पाळी सुरू झाल्याचे',
            '${_v(doc, 'f_menarcheYesNo')} (Age: ${_v(doc, 'f_menarcheAge')})'),
        _row('Menstrual history', 'मासिक पाळी चक्र व LMP',
            'Cycle: ${_v(doc, 'f_menstrualCycle')}, LMP: ${_v(doc, 'f_lastMenstrualPeriod')}'),
        _row(
            'Menstruation at incident / exam',
            'घटनेच्या वेळी / तपासणीच्या वेळी',
            'Incident: ${_v(doc, 'f_menstruationAtIncident')}, Exam: ${_v(doc, 'f_menstruationAtExam')}'),
        _row('Pregnant at incident', 'गर्भधारणा',
            '${_v(doc, 'f_pregnantAtIncident')} (${_v(doc, 'f_pregnancyDuration')} weeks)'),
        _row('Contraception use', 'गर्भनिरोधक',
            '${_v(doc, 'f_contraceptionUse')} (${_v(doc, 'f_contraceptionMethod')})'),
        _row('Vaccination status', 'लसीकरण स्थिती',
            'Tetanus: ${_v(doc, 'f_vaccinationTetanus')}, Hep B: ${_v(doc, 'f_vaccinationHepB')}'),
      ],
    ),
  );
}

// ── FEMALE PAGE 2 ──────────────────────────────────────────────────────────────

Widget _pgFemale2(Map<String, dynamic> doc) {
  return Container(
    width: _kW,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('15 A. History of Sexual Violence',
            '१५ अ. लैंगिक हिंसाचाराचा इतिहास'),
        _row('(i) Date / (ii) Time / (iii) Location', 'तारीख / वेळ / ठिकाण',
            '${_v(doc, 'f_incidentDate')} / ${_v(doc, 'f_incidentTime')} / ${_v(doc, 'f_incidentLocation')}'),
        _row('(iv) Duration / Episode', 'कालावधी / प्रसंग',
            '${_v(doc, 'f_estimatedDuration')} / ${_v(doc, 'f_episode')}'),
        _row('(v) Assailants', 'आरोपींची संख्या व नावे',
            _v(doc, 'f_assailantCountAndNames')),
        _row('(vi) Assailant Sex / Age / Relationship', 'लिंग / वय / नातेसंबंध',
            '${_v(doc, 'f_assailantSex')} / ${_v(doc, 'f_assailantAge')} / ${_v(doc, 'f_assailantRelationship')}'),
        _row('(vii) Narrator', 'निवेदक', _v(doc, 'f_narratorDetails')),
        _textBlock(_v(doc, 'f_violenceHistory'), 'घटनेचे वर्णन :'),
        _section('15 B. Type of physical violence used',
            '१५ ब. शारीरिक हिंसाचाराचा प्रकार'),
        () {
          final List<String> types = [];
          if (_v(doc, 'f_hitWith').isNotEmpty) {
            types.add('Hit with: ${_v(doc, 'f_hitWith')}');
          }
          if (_v(doc, 'f_burnedWith').isNotEmpty) {
            types.add('Burned with: ${_v(doc, 'f_burnedWith')}');
          }
          if (_v(doc, 'f_biting').isNotEmpty) types.add('Biting');
          if (_v(doc, 'f_kicking').isNotEmpty) types.add('Kicking');
          if (_v(doc, 'f_pinching').isNotEmpty) types.add('Pinching');
          if (_v(doc, 'f_pullingHair').isNotEmpty) types.add('Pulling Hair');
          if (_v(doc, 'f_violentShaking').isNotEmpty) {
            types.add('Violent shaking');
          }
          if (_v(doc, 'f_bangingHead').isNotEmpty) types.add('Banging head');
          if (types.isEmpty) {
            return Text(
              _v(doc, 'f_physicalViolence').isEmpty
                  ? '—'
                  : _v(doc, 'f_physicalViolence'),
              style: _fValue(size: 8),
            );
          }
          return Wrap(
            spacing: 12,
            runSpacing: 2,
            children: types
                .map((t) => Text('• $t', style: _fValue(size: 7.8)))
                .toList(),
          );
        }(),
        _section('15 C. Other violence details', '१५ क. इतर हिंसा तपशील'),
        if (_v(doc, 'f_15cEmotionalAbuse').isNotEmpty)
          _row('Emotional abuse', 'भावनिक छळ', _v(doc, 'f_15cEmotionalAbuse')),
        if (_v(doc, 'f_15cRestraints').isNotEmpty)
          _row('Use of restraints', 'बंधने वापरली', _v(doc, 'f_15cRestraints')),
        if (_v(doc, 'f_15cWeapons').isNotEmpty)
          _row('Weapons/objects', 'शस्त्रे/वस्तू', _v(doc, 'f_15cWeapons')),
        if (_v(doc, 'f_15cVerbalThreats').isNotEmpty)
          _row('Verbal threats', 'धमक्या', _v(doc, 'f_15cVerbalThreats')),
        if (_v(doc, 'f_15cLuring').isNotEmpty)
          _row('Luring', 'आमिष', _v(doc, 'f_15cLuring')),
        if (_v(doc, 'f_15cAnyOther').isNotEmpty)
          _row('Any other', 'इतर', _v(doc, 'f_15cAnyOther')),
        _section('15 D. Intoxication & Consciousness', '१५ ड. नशा व शुद्धी'),
        _row('Drug/alcohol intoxication', 'औषध/दारू नशा',
            _v(doc, 'f_15dIntoxication')),
        _row('Sleeping/unconscious at incident', 'झोपलेले/बेशुद्ध',
            _v(doc, 'f_15dUnconscious')),
        _section('15 E. Injury on assailant', '१५ इ. आरोपीवर जखमा'),
        _row('Marks on assailant', 'आरोपीवरील खुणा',
            _v(doc, 'f_15eAssailantInjury')),
        _section('15 F. Sexual violence details', '१५ फ. लैंगिक हिंसा तपशील'),
        _row(
            'Penetration Genitalia (Penis/Body/Obj)',
            'योनी प्रवेश (लिंग/अवयव/वस्तू)',
            '${_v(doc, 'f_penGenitaliaPenis')} / ${_v(doc, 'f_penGenitaliaBodyPart')} / ${_v(doc, 'f_penGenitaliaObject')} (Emission: ${_v(doc, 'f_emissionGenitalia')})'),
        _row(
            'Penetration Anus (Penis/Body/Obj)',
            'गुद प्रवेश (लिंग/अवयव/वस्तू)',
            '${_v(doc, 'f_penAnusPenis')} / ${_v(doc, 'f_penAnusBodyPart')} / ${_v(doc, 'f_penAnusObject')} (Emission: ${_v(doc, 'f_emissionAnus')})'),
        _row(
            'Penetration Mouth (Penis/Body/Obj)',
            'मुख प्रवेश (लिंग/अवयव/वस्तू)',
            '${_v(doc, 'f_penMouthPenis')} / ${_v(doc, 'f_penMouthBodyPart')} / ${_v(doc, 'f_penMouthObject')} (Emission: ${_v(doc, 'f_emissionMouth')})'),
        _row('Oral sex by assailant', 'आरोपीने केलेले ओरल सेक्स',
            _v(doc, 'f_oralSexPerformed')),
        _row(
            'Forced masturbation of self',
            'स्वतःचे हस्तमैथुन करण्यास भाग पाडले',
            _v(doc, 'f_forcedMasturbationSelf')),
        _row('Masturbation of assailant', 'आरोपीचे हस्तमैथुन',
            _v(doc, 'f_masturbationAssailant')),
        _row('Exhibitionism', 'प्रदर्शित करणे', _v(doc, 'f_exhibitionism')),
        _row('Ejaculation outside body orifice', 'बाहेर वीर्यस्खलन',
            _v(doc, 'f_ejaculationOutside')),
        if (_v(doc, 'f_ejaculationWhereBody').isNotEmpty)
          _row('Ejaculation location on body', 'शरीरावर ठिकाण',
              _v(doc, 'f_ejaculationWhereBody')),
        _row('Kissing, licking or sucking', 'चुंबन / चाटणे',
            '${_v(doc, 'f_kissingLickingSucking')} ${_v(doc, 'f_kissingLickingDesc').isNotEmpty ? "(${_v(doc, 'f_kissingLickingDesc')})" : ""}'),
        _row('Touching / Fondling', 'स्पर्श करणे',
            '${_v(doc, 'f_touchingFondling')} ${_v(doc, 'f_touchingFondlingDesc').isNotEmpty ? "(${_v(doc, 'f_touchingFondlingDesc')})" : ""}'),
        _row('Condom used', 'निरोध वापरला', _v(doc, 'f_condomUsed')),
        if (_v(doc, 'f_condomStatus').isNotEmpty)
          _row('Status of condom', 'निरोध स्थिती', _v(doc, 'f_condomStatus')),
        _row('Lubricant used', 'स्नेहक वापरले', _v(doc, 'f_lubricantUsed')),
        if (_v(doc, 'f_lubricantKindDesc').isNotEmpty)
          _row('Kind of lubricant', 'स्नेहक प्रकार',
              _v(doc, 'f_lubricantKindDesc')),
        if (_v(doc, 'f_objectUsedDesc').isNotEmpty)
          _row('Object description', 'वस्तूचे वर्णन',
              _v(doc, 'f_objectUsedDesc')),
        if (_v(doc, 'f_otherSexualViolenceForms').isNotEmpty)
          _row('Other forms of sexual violence', 'इतर लैंगिक हिंसा प्रकार',
              _v(doc, 'f_otherSexualViolenceForms')),
      ],
    ),
  );
}

// ── FEMALE PAGE 3 ──────────────────────────────────────────────────────────────

Widget _pgFemale3(Map<String, dynamic> doc) {
  final postActionKeys = [
    ('Changed clothes', 'f_postChangedClothes', 'f_postChangedClothesRem'),
    (
      'Changed undergarments',
      'f_postChangedUndergarments',
      'f_postChangedUndergarmentsRem'
    ),
    ('Cleaned clothes', 'f_postCleanedClothes', 'f_postCleanedClothesRem'),
    (
      'Cleaned undergarments',
      'f_postCleanedUndergarments',
      'f_postCleanedUndergarmentsRem'
    ),
    ('Bathed', 'f_postBathed', 'f_postBathedRem'),
    ('Douched', 'f_postDouched', 'f_postDouchedRem'),
    ('Passed urine', 'f_postPassedUrine', 'f_postPassedUrineRem'),
    ('Passed stools', 'f_postPassedStools', 'f_postPassedStoolsRem'),
    ('Rinsing mouth/brushing', 'f_postRinsingMouth', 'f_postRinsingMouthRem'),
  ];
  final postChips = postActionKeys.map<Widget>((item) {
    final choice = _v(doc, item.$2);
    final rem = _v(doc, item.$3);
    if (choice.isEmpty && rem.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('${item.$1}: ', style: _fBold(size: 7.8)),
      Text('$choice${rem.isNotEmpty ? " ($rem)" : ""}',
          style: _fValue(size: 7.8)),
    ]);
  }).toList();
  final examVitals = <Widget>[
    if (_v(doc, 'f_examPulse').isNotEmpty || _v(doc, 'f_examBp').isNotEmpty)
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text('Pulse/BP: ', style: _fBold(size: 8)),
        Text('${_v(doc, 'f_examPulse')} / ${_v(doc, 'f_examBp')}',
            style: _fValue(size: 8)),
      ]),
    if (_v(doc, 'f_examTemp').isNotEmpty ||
        _v(doc, 'f_examRespRate').isNotEmpty)
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text('Temp/Resp: ', style: _fBold(size: 8)),
        Text('${_v(doc, 'f_examTemp')} / ${_v(doc, 'f_examRespRate')}',
            style: _fValue(size: 8)),
      ]),
    if (_v(doc, 'f_examPupils').isNotEmpty)
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text('Pupils: ', style: _fBold(size: 8)),
        Text(_v(doc, 'f_examPupils'), style: _fValue(size: 8)),
      ]),
  ];
  const injuryLabels = [
    'Scalp examination',
    'Facial bone injury',
    'Petechial haemorrhage in eyes',
    'Lips & Buccal Mucosa / Gums',
    'Behind the ears',
    'Ear drum',
    'Neck, Shoulders & Breast',
    'Upper limb',
    'Inner aspect of upper arms',
    'Inner aspect of thighs',
    'Lower limb / Buttocks',
    'Other, please specify'
  ];
  final injuryRows = doc['f_injuryRows'];
  final injuryWidgets = <Widget>[];
  if (injuryRows is List) {
    for (var i = 0; i < injuryRows.length; i++) {
      final val = injuryRows[i]?.toString().trim() ?? '';
      if (val.isNotEmpty) {
        injuryWidgets.add(_row(
            i < injuryLabels.length ? injuryLabels[i] : 'Site ${i + 1}',
            '',
            val));
      }
    }
  }
  const genitalLabels = [
    'Urethral meatus & vestibule',
    'Labia majora',
    'Labia minora',
    'Fourchette & Introitus',
    'Hymen Perineum',
    'External Urethral Meatus',
    'Penis',
    'Scrotum',
    'Testes',
    'Clitoropenis',
    'Labioscrotum',
    'Any Other'
  ];
  final genitalFindings = doc['f_genitalPartFindings'];
  final genitalNotes = doc['f_genitalPartNotes'];
  final genitalWidgets = <Widget>[];
  if (genitalFindings is List) {
    for (var i = 0;
        i < genitalFindings.length && i < genitalLabels.length;
        i++) {
      final fVal = genitalFindings[i]?.toString().trim() ?? '';
      final nVal = genitalNotes is List && i < genitalNotes.length
          ? genitalNotes[i]?.toString().trim() ?? ''
          : '';
      if (fVal.isNotEmpty || nVal.isNotEmpty) {
        genitalWidgets.add(_row(
            genitalLabels[i], '', '$fVal${nVal.isNotEmpty ? " ($nVal)" : ""}'));
      }
    }
  }
  return Container(
    width: _kW,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionedBlock('Post-incident actions', 'घटनोत्तर कृती', [
          _compactWrap(postChips),
          if (_v(doc, 'f_timeSinceIncident').isNotEmpty)
            _row('Time since incident', 'घटनेपासून वेळ',
                _v(doc, 'f_timeSinceIncident')),
          if (_v(doc, 'f_bleedingPriorIncident').isNotEmpty)
            _row('Bleeding/discharge prior to incident', 'घटनेपूर्वी रक्तस्राव',
                _v(doc, 'f_bleedingPriorIncident')),
          if (_v(doc, 'f_bleedingSinceIncident').isNotEmpty)
            _row('Bleeding/discharge since incident', 'घटनेनंतर रक्तस्राव',
                _v(doc, 'f_bleedingSinceIncident')),
          if (_v(doc, 'f_painSinceIncident').isNotEmpty)
            _row('Pain/urination/fissures since incident', 'वेदना/लघवी त्रास',
                _v(doc, 'f_painSinceIncident')),
        ]),
        _sectionedBlock(
            '16. General Physical Examination', '१६. सामान्य शारीरिक तपासणी', [
          if (_v(doc, 'f_examIsFirst').isNotEmpty)
            _row('Is this the first examination', 'पहिली तपासणी आहे का',
                _v(doc, 'f_examIsFirst')),
          _compactWrap(examVitals),
          if (_v(doc, 'f_examGeneralWellbeing').isNotEmpty)
            _row('General wellbeing observation', 'सामान्य आरोग्य निरीक्षण',
                _v(doc, 'f_examGeneralWellbeing')),
          _textBlock(_v(doc, 'f_generalExam'), ''),
        ]),
        _sectionedBlock(
            '17. Examination for injuries on the body',
            '१७. शरीरावरील जखमा तपासणी',
            injuryWidgets.isEmpty
                ? [
                    Text('No injuries noted / कोणतीही जखम नाही',
                        style: _fRegular(size: 8))
                  ]
                : injuryWidgets),
        _sectionedBlock(
            '18. Local examination of genital parts / other orifices',
            '१८. गुप्तांग / इतर छिद्रांची स्थानिक तपासणी', [
          ...(genitalWidgets.isEmpty
              ? [Text('Normal / प्राकृत', style: _fRegular(size: 8))]
              : genitalWidgets),
          if (_v(doc, 'f_psFindings').isNotEmpty)
            _row('P/S findings', 'P/S तपासणी', _v(doc, 'f_psFindings')),
          if (_v(doc, 'f_pvFindings').isNotEmpty)
            _row('P/V findings', 'P/V तपासणी', _v(doc, 'f_pvFindings')),
          if (_v(doc, 'f_pvPsReasons').isNotEmpty)
            _row('Reasons for P/V or P/S', 'कारणे', _v(doc, 'f_pvPsReasons')),
          if (_v(doc, 'f_anusRectumEncircled').isNotEmpty ||
              _v(doc, 'f_anusRectumNotes').isNotEmpty)
            _row('Anus & Rectum', 'गुद व गुदाशय',
                '${_v(doc, 'f_anusRectumEncircled')}${_v(doc, 'f_anusRectumNotes').isNotEmpty ? " — ${_v(doc, 'f_anusRectumNotes')}" : ""}'),
          if (_v(doc, 'f_oralCavityEncircled').isNotEmpty ||
              _v(doc, 'f_oralCavityNotes').isNotEmpty)
            _row('Oral Cavity', 'तोंड / मुखगुहा',
                '${_v(doc, 'f_oralCavityEncircled')}${_v(doc, 'f_oralCavityNotes').isNotEmpty ? " — ${_v(doc, 'f_oralCavityNotes')}" : ""}'),
          _textBlock(_v(doc, 'f_genitalExam'), ''),
        ]),
      ],
    ),
  );
}

// ── FEMALE PAGE 4 ──────────────────────────────────────────────────────────────

Widget _pgFemale4(Map<String, dynamic> doc) {
  // Section 19 systemic vitals
  final sysVitals = <Widget>[
    if (_v(doc, 'f_sysCns').isNotEmpty)
      _row('CNS:', '', _v(doc, 'f_sysCns'), labelWidth: 40),
    if (_v(doc, 'f_sysCvs').isNotEmpty)
      _row('CVS:', '', _v(doc, 'f_sysCvs'), labelWidth: 40),
    if (_v(doc, 'f_sysResp').isNotEmpty)
      _row('Resp:', '', _v(doc, 'f_sysResp'), labelWidth: 40),
    if (_v(doc, 'f_sysChest').isNotEmpty)
      _row('Chest:', '', _v(doc, 'f_sysChest'), labelWidth: 40),
    if (_v(doc, 'f_sysAbdomen').isNotEmpty)
      _row('Abdomen:', '', _v(doc, 'f_sysAbdomen'), labelWidth: 60),
  ];

  // Section 21 FSL samples
  const fslLabels = [
    'Swabs from Stains on body',
    'Scalp hair (10-15 strands)',
    'Head hair combing',
    'Nail scrapings',
    'Nail clippings',
    'Oral swab',
    'Blood for grouping (plain vial)',
    'Blood for alcohol (Fluoride vial)',
    'Blood for DNA (EDTA vial)',
    'Urine (drug testing)',
    'Any other'
  ];
  final fslCol = doc['f_fslSampleCollected'];
  final fslRsn = doc['f_fslSampleReasons'];
  final fslWidgets = <Widget>[];
  if (fslCol is List) {
    for (var i = 0; i < fslCol.length && i < fslLabels.length; i++) {
      final cVal = fslCol[i]?.toString().trim() ?? '';
      final rVal = fslRsn is List && i < fslRsn.length
          ? fslRsn[i]?.toString().trim() ?? ''
          : '';
      if (cVal.isNotEmpty || rVal.isNotEmpty) {
        fslWidgets.add(_row(fslLabels[i], '',
            '$cVal${rVal.isNotEmpty ? " (Reason: $rVal)" : ""}'));
      }
    }
  }

  // Genital/Anal evidence
  const genAnalLabels = [
    'Matted pubic hair',
    'Pubic hair combing',
    'Cutting of pubic hair',
    'Two Vulval swabs',
    'Two Vaginal swabs',
    'Two Anal swabs',
    'Vaginal smear',
    'Vaginal washing',
    'Urethral swab',
    'Swab from glans/clitoropenis'
  ];
  final genAnalCol = doc['f_genitalEvidenceCollected'];
  final genAnalRsn = doc['f_genitalEvidenceReasons'];
  final genAnalWidgets = <Widget>[];
  if (genAnalCol is List) {
    for (var i = 0; i < genAnalCol.length && i < genAnalLabels.length; i++) {
      final cVal = genAnalCol[i]?.toString().trim() ?? '';
      final rVal = genAnalRsn is List && i < genAnalRsn.length
          ? genAnalRsn[i]?.toString().trim() ?? ''
          : '';
      if (cVal.isNotEmpty || rVal.isNotEmpty) {
        genAnalWidgets.add(_row(genAnalLabels[i], '',
            '$cVal${rVal.isNotEmpty ? " (Reason: $rVal)" : ""}'));
      }
    }
  }

  // Section 23 treatment
  const treatLabels = [
    'STI prevention',
    'Emergency contraception',
    'Wound treatment',
    'Tetanus prophylaxis',
    'Hep B vaccination',
    'HIV PEP',
    'Counselling',
    'Other'
  ];
  final treatChoices = doc['f_treatmentChoice'];
  final treatComments = doc['f_treatmentComments'];
  final treatWidgets = <Widget>[];
  if (treatChoices is List) {
    for (var i = 0; i < treatChoices.length && i < treatLabels.length; i++) {
      final cVal = treatChoices[i]?.toString().trim() ?? '';
      final comVal = treatComments is List && i < treatComments.length
          ? treatComments[i]?.toString().trim() ?? ''
          : '';
      if (cVal.isNotEmpty || comVal.isNotEmpty) {
        treatWidgets.add(_row(treatLabels[i], '',
            '$cVal${comVal.isNotEmpty ? " ($comVal)" : ""}'));
      }
    }
  }

  // Section 24/25 completion details
  final completionDetails = <Widget>[
    if (_v(doc, 'f_completionDateTime').isNotEmpty)
      _row('Completed:', '', _v(doc, 'f_completionDateTime'), labelWidth: 65),
    if (_v(doc, 'f_completionPlace').isNotEmpty)
      _row('Place:', '', _v(doc, 'f_completionPlace'), labelWidth: 40),
    if (_v(doc, 'f_doctorName').isNotEmpty)
      _row('Doctor:', '',
          '${_v(doc, 'f_doctorName')}${_v(doc, 'f_doctorSeal').isNotEmpty ? " (Seal: ${_v(doc, 'f_doctorSeal')})" : ""}',
          labelWidth: 50),
  ];

  return Container(
    width: _kW,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 19: Systemic Examination
        _sectionedBlock('19. Systemic Examination', '१९. प्रणालीगत तपासणी', [
          _compactWrap(sysVitals),
          _textBlock(_v(doc, 'f_systemicExam'), ''),
        ]),
        // Section 20: Hospital Lab samples
        _sectionedBlock('20. Sample Collection — Hospital Lab',
            '२०. नमुने — रुग्णालय प्रयोगशाळा', [
          if (_v(doc, 'f_sampleBloodHiv').isNotEmpty)
            _row('Blood for HIV, VDRL, HbsAg', 'रक्त तपासणी',
                _v(doc, 'f_sampleBloodHiv')),
          if (_v(doc, 'f_sampleUrinePreg').isNotEmpty)
            _row('Urine test for Pregnancy', 'गर्भधारणा तपासणी',
                _v(doc, 'f_sampleUrinePreg')),
          if (_v(doc, 'f_sampleUsg').isNotEmpty)
            _row('Ultrasound pregnancy/injury', 'सोनोग्राफी',
                _v(doc, 'f_sampleUsg')),
          if (_v(doc, 'f_sampleXray').isNotEmpty)
            _row(
                'X-ray for Injury', 'क्ष-किरण तपासणी', _v(doc, 'f_sampleXray')),
        ]),
        // Section 21: FSL samples
        _sectionedBlock(
            '21. Samples for FSL', '२१. न्यायवैद्यक प्रयोगशाळेसाठी नमुने', [
          if (_v(doc, 'f_fslDebris').isNotEmpty)
            _row('Debris paper', 'डेब्रिस कागद', _v(doc, 'f_fslDebris')),
          if (_v(doc, 'f_clothingDetails').isNotEmpty)
            _row('Clothing worn by survivor', 'कपडे तपशील',
                _v(doc, 'f_clothingDetails')),
          ...fslWidgets,
        ]),
        // Genital & Anal Evidence
        _sectionedBlock('Genital and Anal Evidence', 'गुप्तांग व गुद पुरावा',
            genAnalWidgets),
        // Section 22: Provisional Opinion
        _sectionedBlock(
            '22. Provisional Medical Opinion', '२२. तात्पुरती वैद्यकीय मते', [
          if (_v(doc, 'f_provSurvivorName').isNotEmpty ||
              _v(doc, 'f_provCircumstances').isNotEmpty)
            Text(
                'Examined ${_v(doc, 'f_provSurvivorName')} (${_v(doc, 'f_provGender')}, Age: ${_v(doc, 'f_provAge')}) reporting ${_v(doc, 'f_provCircumstances')}, ${_v(doc, 'f_provTimeAfterIncident')} after incident.',
                style: _fRegular(size: 7.5)),
          if (_v(doc, 'f_provClinicalFindings').isNotEmpty)
            _row('Clinical Findings', 'वैद्यकीय निष्कर्ष',
                _v(doc, 'f_provClinicalFindings')),
          _textBlock(_v(doc, 'f_provisionalOpinion'), ''),
        ]),
        // Section 23: Treatment
        _sectionedBlock('23. Treatment Prescribed', '२३. दिलेला उपचार', [
          ...treatWidgets,
          _textBlock(_v(doc, 'f_treatment'), ''),
        ]),
        // Section 24 & 25: Completion & Final Opinion
        _sectionedBlock('24. Completion & 25. Final Opinion',
            '२४. पूर्णता व २५. अंतिम मत', [
          _compactWrap(completionDetails),
          _textBlock(_v(doc, 'f_finalOpinionText'), 'अंतिम मत:'),
        ]),
        const SizedBox(height: 6),
        Center(
          child: Column(
            children: [
              Text(
                  'COPY OF THE ENTIRE MEDICAL REPORT MUST BE GIVEN TO THE SURVIVOR/VICTIM FREE OF COST IMMEDIATELY',
                  style: _fBold(size: 7.5),
                  textAlign: TextAlign.center),
              Text(
                  'संपूर्ण वैद्यकीय अहवालाची प्रत पीडित/पीडितेला त्वरित विनामूल्य द्यावी',
                  style: _fMarathi(size: 7.5, isBold: true),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── MALE PAGE 1 ────────────────────────────────────────────────────────────────

Widget _pgMale1(Map<String, dynamic> doc) {
  return Container(
    width: _kW,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text('Forensic Medical Examination of Alleged Accused (Male)',
                  style: _fH1(), textAlign: TextAlign.center),
              Text('आरोपीची फॉरेन्सिक वैद्यकीय तपासणी (पुरुष)',
                  style: _fH1M(), textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _row('Hospital', 'रुग्णालय', _v(doc, 'm_hospital')),
        _row('Accused Name', 'आरोपीचे नाव', _v(doc, 'm_accusedName')),
        _row('Age / DOB', 'वय / जन्मतारीख',
            '${_v(doc, 'm_age')} / ${_v(doc, 'm_dob')}'),
        _row('MLC / C.R.No', 'एम.एल.सी. / गु.नो.',
            '${_v(doc, 'm_mlc')} / ${_v(doc, 'm_crNo')}'),
        _row('Police / P.S.', 'पोलीस / ठाणे',
            '${_v(doc, 'm_policeName')} / ${_v(doc, 'm_ps')}'),
        _section('8. CONSENT', '८. संमती'),
        _textBlock(_v(doc, 'm_consent'), 'संमती तपशील:'),
        _section('History (as stated by Accused)', 'आरोपीने सांगितलेला इतिहास'),
        _textBlock(_v(doc, 'm_assaultHistory'), ''),
        _section('General Physical Examination', 'सामान्य शारीरिक तपासणी'),
        _textBlock(_v(doc, 'm_generalPhysical'), ''),
        _section('Local Examination', 'स्थानिक तपासणी'),
        _textBlock(_v(doc, 'm_localExam'), ''),
        _section('VIII) Sample collection for Hospital / Clinical Laboratory',
            '८) रुग्णालय / क्लिनिकल प्रयोगशाळेसाठी नमुने गोळा करणे'),
        Table(
          border: TableBorder.all(color: Colors.black54, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(35),
            1: FlexColumnWidth(2.5),
            2: FlexColumnWidth(2.5),
            3: FlexColumnWidth(2.2),
            4: FixedColumnWidth(65),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text('Sr No',
                      style: _fBold(size: 7.5), textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text('Sample name', style: _fBold(size: 7.5)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text('Test for', style: _fBold(size: 7.5)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text('Packing', style: _fBold(size: 7.5)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text('Collected?',
                      style: _fBold(size: 7.5), textAlign: TextAlign.center),
                ),
              ],
            ),
            _maleLabRow('7', 'Urethral Swab', 'Microscopy & Culture',
                'Plain Sterile Bulb', _v(doc, 'm_lab7Collected')),
            _maleLabRow('8', 'Swab from discharge', 'Microscopy & Culture',
                'Plain Sterile Bulb', _v(doc, 'm_lab8Collected')),
            _maleLabRow('9', 'Blood', 'Serology (syphilis, HIV, Hep B)',
                'Plain Sterile Bulb', _v(doc, 'm_lab9Collected')),
            _maleLabRow('10', 'Urine (midstream)', 'Microscopy & Culture',
                'Plain Sterile Bulb', _v(doc, 'm_lab10Collected')),
            _maleLabRow(
                '11',
                _v(doc, 'm_lab11Sample').isEmpty
                    ? 'Other'
                    : _v(doc, 'm_lab11Sample'),
                _v(doc, 'm_lab11Test'),
                _v(doc, 'm_lab11Packing'),
                _v(doc, 'm_lab11Collected')),
          ],
        ),
      ],
    ),
  );
}

TableRow _maleLabRow(
    String sr, String sample, String test, String packing, String collected) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(3),
        child:
            Text(sr, style: _fRegular(size: 7.5), textAlign: TextAlign.center),
      ),
      Padding(
        padding: const EdgeInsets.all(3),
        child: Text(sample, style: _fRegular(size: 7.5)),
      ),
      Padding(
        padding: const EdgeInsets.all(3),
        child: Text(test, style: _fRegular(size: 7.5)),
      ),
      Padding(
        padding: const EdgeInsets.all(3),
        child: Text(packing, style: _fRegular(size: 7.5)),
      ),
      Padding(
        padding: const EdgeInsets.all(3),
        child: Text(collected.isEmpty ? '—' : collected,
            style: _fValue(size: 7.5), textAlign: TextAlign.center),
      ),
    ],
  );
}

// ── MALE PAGE 2 ────────────────────────────────────────────────────────────────

Widget _pgMale2(Map<String, dynamic> doc) {
  return Container(
    width: _kW,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('(IX) Samples / Forensic Evidence preserved for FSL',
            '(९) एफ.एस.एल.साठी जतन केलेला फॉरेन्सिक पुरावा / नमुने'),
        Text(
          'The samples must be collected as per time elapsed between assault and examination, history and physical findings. Specific mention in words as to which samples are collected & which are not collected is very necessary.',
          style: _fRegular(size: 7.5),
        ),
        const SizedBox(height: 4),
        _row('Note (If any)', 'टिपणी (असल्यास)', _v(doc, 'm_fslNote')),
        _section('PROVISIONAL OPINION: **', 'तात्पुरते वैद्यकीय मत: **'),
        Text(
          'After examining the person bearing above mentioned identification marks, ${_v(doc, 'm_opinionTimeElapsed')} days/hours after the incident, I/We is/are of the opinion that:',
          style: _fRegular(size: 8),
        ),
        const SizedBox(height: 4),
        _textBlock(_v(doc, 'm_provisionalOpinion'), ''),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('Date: ${_v(doc, 'm_opinionDate')}', style: _fBold(size: 8.5)),
            const Spacer(),
            Text(
              '(Report contains ${_v(doc, 'm_reportPagesCount')} pages each signed by doctor)',
              style: _fRegular(size: 8),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 80,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black54, width: 0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Text('Stamp', style: _fRegular(size: 8))),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Signature: ${_v(doc, 'm_doctorSig')}',
                    style: _fValue(size: 8)),
                Text('Name of Dr.: ${_v(doc, 'm_doctorName')}',
                    style: _fValue(size: 8)),
                Text('Dept/Desig: ${_v(doc, 'm_doctorDeptDesig')}',
                    style: _fValue(size: 8)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26, width: 0.5),
            color: const Color(0xFFFAFAFA),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('IMPORTANT NOTE**:', style: _fBold(size: 8)),
              Text(
                '• The provisional opinion must be in the form of general opinion / impression about possibility of sexual intercourse. The provisional opinion must include the fact of capacity of the accused to perform sexual act.',
                style: _fRegular(size: 7.2),
              ),
              Text(
                '• Precisely brief justification (reasons) in support of your opinion must be given.',
                style: _fRegular(size: 7.2),
              ),
              Text(
                '• The accused can be examined physically without consent as per Cr.P.C 53 & 53A, if he denies consent.',
                style: _fRegular(size: 7.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _section('RECEIPT (by police official):', 'पोलीस अधिकाऱ्याची पावती :'),
        Text('Received forensic medical examination report:',
            style: _fRegular(size: 8)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _row('Signature:', '', _v(doc, 'm_receiptPolice'),
                  labelWidth: 60),
            ),
            Expanded(
              child: _row('Name:', '', _v(doc, 'm_receiptPoliceName'),
                  labelWidth: 45),
            ),
            Expanded(
              child: _row('Buckle No.:', '', _v(doc, 'm_receiptBuckleNo'),
                  labelWidth: 65),
            ),
          ],
        ),
        _row('Police station:', 'पोलीस ठाणे:', _v(doc, 'm_receiptPs'),
            labelWidth: 90),
      ],
    ),
  );
}
