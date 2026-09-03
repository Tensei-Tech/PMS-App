import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> previewMedical376FormPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateMedical376FormPdf(doc);
  if (!context.mounted) return;
  final fileName =
      '376_Medical_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
  try {
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
    }
  } catch (_) {
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}

Future<Uint8List> generateMedical376FormPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final loraRegular = await PdfGoogleFonts.loraRegular();
  final loraBold = await PdfGoogleFonts.loraBold();
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final body = pw.TextStyle(font: loraRegular, fontSize: 10);
  final bold = pw.TextStyle(
      font: loraBold, fontSize: 11, fontWeight: pw.FontWeight.bold);
  final title = pw.TextStyle(
      font: loraBold, fontSize: 14, fontWeight: pw.FontWeight.bold);
  final marathi = pw.TextStyle(font: devanagari, fontSize: 8.5);
  final marathiBold = pw.TextStyle(
      font: devanagariBold, fontSize: 9, fontWeight: pw.FontWeight.bold);
  final value =
      pw.TextStyle(font: devanagari, fontSize: 10, color: PdfColors.blue900);

  String v(String key) => doc[key]?.toString().trim() ?? '';

  pw.Widget row(String labelEn, String labelMr, String val) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 180,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(labelEn, style: bold),
                pw.Text(labelMr, style: marathi),
              ],
            ),
          ),
          pw.Expanded(child: pw.Text(val.isEmpty ? '—' : val, style: value)),
        ],
      ),
    );
  }

  pw.Widget section(String en, String mr) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(en, style: bold),
          pw.Text(mr, style: marathiBold),
        ],
      ),
    );
  }

  pw.Widget textBlock(String en, String mr) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(en.isEmpty ? '—' : en, style: body),
          if (mr.isNotEmpty) pw.Text(mr, style: marathi),
        ],
      ),
    );
  }

  final sectionKey = v('formSection').toLowerCase();
  final isFemaleSection = sectionKey.contains('female');
  final isMaleSection = sectionKey.contains('male') && !isFemaleSection;
  final showFemale = sectionKey.isEmpty || isFemaleSection;
  final showMale = isMaleSection;

  if (showFemale) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Text(
            'महाराष्ट्र शासन — सार्वजनिक आरोग्य विभाग. परिपत्रक क्र.: संकीर्ण-२०१४/प्र.क्र.२७०/आरोग्य-३. दिनांक: ०७ ऑगस्ट, २०१५.',
            style: marathiBold,
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('CONFIDENTIAL', style: bold),
                pw.Text('गोपनीय', style: marathiBold),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'Medico-legal Examination Report of Sexual Violence (Female)',
                  style: title,
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  'लैंगिक हिंसाचाराचा वैद्यकीय-कायदेशीर तपासणी अहवाल (स्त्री)',
                  style: marathiBold,
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          row('Hospital', 'रुग्णालय', v('f_hospital')),
          row('Name', 'नाव', v('f_name')),
          row('Age / DOB', 'वय / जन्मतारीख', '${v('f_age')} / ${v('f_dob')}'),
          row('MLC / P.S.', 'एम.एल.सी. / पो.ठ.',
              '${v('f_mlc')} / ${v('f_ps')}'),
          row('Arrival', 'आगमन', v('f_arrival')),
          section(
              '12. Informed Consent/refusal', '१२. माहितीपूर्ण संमती / नकार'),
          pw.Text(
            'I ${v('f_consentName').isEmpty ? v('f_name') : v('f_consentName')} D/o or S/o ${v('f_consentParent').isEmpty ? v('f_parent') : v('f_consentParent')} hereby give my consent for:',
            style: body,
          ),
          row('a) medical examination for treatment',
              'अ) उपचारासाठी वैद्यकीय तपासणी', v('f_consentTreatment')),
          row('b) this medico legal examination',
              'ब) ही वैद्यकीय-कायदेशीर तपासणी', v('f_consentMedicoLegal')),
          row('c) sample collection for clinical & forensic examination',
              'क) नैदानिक व फॉरेन्सिक नमुने गोळा करणे', v('f_consentSample')),
          pw.SizedBox(height: 4),
          pw.Text(
            'I also understand that as per law the hospital is required to inform police and this has been explained to me.',
            style: body.copyWith(fontSize: 8.5),
          ),
          row('Information revealed to police', 'माहिती पोलिसांना दिली जावी',
              v('f_consentPoliceInfo')),
          pw.SizedBox(height: 4),
          pw.Text(
            'I have understood the purpose and procedure of the examination including risk and benefit. Explained in: ${v('f_consentLanguage')} language. Support person: ${v('f_consentSupportRole')}',
            style: body.copyWith(fontSize: 8.5),
          ),
          if (v('f_consentHelperSig').isNotEmpty)
            row('Special educator/interpreter signature',
                'विशेष शिक्षक/दुभाषी सही', v('f_consentHelperSig')),
          section('Signatures', 'सह्या'),
          row('Survivor / Guardian signature', 'पीडित / पालक सही',
              v('f_survivorSig')),
          row('Witness signature / thumb', 'साक्षीदार सही / अंगठा',
              v('f_witnessSig')),
          section('13. Marks of identification', '१३. ओळखीच्या खुणा'),
          row('(1)', '(१)', v('f_idMark1')),
          row('(2)', '(२)', v('f_idMark2')),
          section('14. Relevant Medical/Surgical history',
              '१४. संबंधित वैद्यकीय / शस्त्रक्रिया इतिहास'),
          row('Onset of menarche', 'मासिक पाळी सुरू झाल्याचे',
              '${v('f_menarcheYesNo')} (Age: ${v('f_menarcheAge')})'),
          row('Menstrual history', 'मासिक पाळी चक्र व LMP',
              'Cycle: ${v('f_menstrualCycle')}, LMP: ${v('f_lastMenstrualPeriod')}'),
          row(
              'Menstruation at incident / exam',
              'घटनेच्या वेळी / तपासणीच्या वेळी',
              'Incident: ${v('f_menstruationAtIncident')}, Exam: ${v('f_menstruationAtExam')}'),
          row('Pregnant at incident', 'गर्भधारणा',
              '${v('f_pregnantAtIncident')} (${v('f_pregnancyDuration')} weeks)'),
          row('Contraception use', 'गर्भनिरोधक',
              '${v('f_contraceptionUse')} (${v('f_contraceptionMethod')})'),
          row('Vaccination status', 'लसीकरण स्थिती',
              'Tetanus: ${v('f_vaccinationTetanus')}, Hep B: ${v('f_vaccinationHepB')}'),
          section('15 A. History of Sexual Violence',
              '१५ अ. लैंगिक हिंसाचाराचा इतिहास'),
          row('(i) Date / (ii) Time / (iii) Location', 'तारीख / वेळ / ठिकाण',
              '${v('f_incidentDate')} / ${v('f_incidentTime')} / ${v('f_incidentLocation')}'),
          row('(iv) Duration / Episode', 'कालावधी / प्रसंग',
              '${v('f_estimatedDuration')} / ${v('f_episode')}'),
          row('(v) Assailants', 'आरोपींची संख्या व नावे',
              v('f_assailantCountAndNames')),
          row(
              '(vi) Assailant Sex / Age / Relationship',
              'लिंग / वय / नातेसंबंध',
              '${v('f_assailantSex')} / ${v('f_assailantAge')} / ${v('f_assailantRelationship')}'),
          row('(vii) Narrator', 'निवेदक', v('f_narratorDetails')),
          textBlock(v('f_violenceHistory'), 'घटनेचे वर्णन'),
          section('15 B. Type of physical violence used',
              '१५ ब. शारीरिक हिंसाचाराचा प्रकार'),
          ...() {
            final List<String> types = [];
            if (v('f_hitWith').isNotEmpty) {
              types.add('Hit with (Hand, fist, blunt, sharp)');
            }
            if (v('f_burnedWith').isNotEmpty) types.add('Burned with');
            if (v('f_biting').isNotEmpty) types.add('Biting');
            if (v('f_kicking').isNotEmpty) types.add('Kicking');
            if (v('f_pinching').isNotEmpty) types.add('Pinching');
            if (v('f_pullingHair').isNotEmpty) types.add('Pulling Hair');
            if (v('f_violentShaking').isNotEmpty) types.add('Violent shaking');
            if (v('f_bangingHead').isNotEmpty) types.add('Banging head');
            if (types.isEmpty) {
              return [
                pw.Text(
                    v('f_physicalViolence').isEmpty
                        ? '—'
                        : v('f_physicalViolence'),
                    style: value)
              ];
            }
            return types.map((t) => pw.Text('• $t', style: value)).toList();
          }(),
          section('15 C. Other violence details', '१५ क. इतर हिंसा तपशील'),
          if (v('f_15cEmotionalAbuse').isNotEmpty)
            row('Emotional abuse', 'भावनिक छळ', v('f_15cEmotionalAbuse')),
          if (v('f_15cRestraints').isNotEmpty)
            row('Use of restraints', 'बंधने वापरली', v('f_15cRestraints')),
          if (v('f_15cWeapons').isNotEmpty)
            row('Weapons/objects', 'शस्त्रे/वस्तू', v('f_15cWeapons')),
          if (v('f_15cVerbalThreats').isNotEmpty)
            row('Verbal threats', 'धमक्या', v('f_15cVerbalThreats')),
          if (v('f_15cLuring').isNotEmpty)
            row('Luring', 'आमिष', v('f_15cLuring')),
          if (v('f_15cAnyOther').isNotEmpty)
            row('Any other', 'इतर', v('f_15cAnyOther')),
          section('15 D. Intoxication & Consciousness', '१५ ड. नशा व शुद्धी'),
          row('Drug/alcohol intoxication', 'औषध/दारू नशा',
              v('f_15dIntoxication')),
          row('Sleeping/unconscious at incident', 'झोपलेले/बेशुद्ध',
              v('f_15dUnconscious')),
          section('15 E. Injury on assailant', '१५ इ. आरोपीवर जखमा'),
          row('Marks on assailant', 'आरोपीवरील खुणा',
              v('f_15eAssailantInjury')),
          section('15 F. Sexual violence details', '१५ फ. लैंगिक हिंसा तपशील'),
          row(
              'Penetration Genitalia (Penis/Body/Obj)',
              'योनी प्रवेश (लिंग/अवयव/वस्तू)',
              '${v('f_penGenitaliaPenis')} / ${v('f_penGenitaliaBodyPart')} / ${v('f_penGenitaliaObject')} (Emission: ${v('f_emissionGenitalia')})'),
          row(
              'Penetration Anus (Penis/Body/Obj)',
              'गुद प्रवेश (लिंग/अवयव/वस्तू)',
              '${v('f_penAnusPenis')} / ${v('f_penAnusBodyPart')} / ${v('f_penAnusObject')} (Emission: ${v('f_emissionAnus')})'),
          row(
              'Penetration Mouth (Penis/Body/Obj)',
              'मुख प्रवेश (लिंग/अवयव/वस्तू)',
              '${v('f_penMouthPenis')} / ${v('f_penMouthBodyPart')} / ${v('f_penMouthObject')} (Emission: ${v('f_emissionMouth')})'),
          row('Oral sex by assailant', 'आरोपीने केलेले ओरल सेक्स',
              v('f_oralSexPerformed')),
          row(
              'Forced masturbation of self',
              'स्वतःचे हस्तमैथुन करण्यास भाग पाडले',
              v('f_forcedMasturbationSelf')),
          row('Masturbation of assailant', 'आरोपीचे हस्तमैथुन',
              v('f_masturbationAssailant')),
          row('Exhibitionism', 'प्रदर्शित करणे', v('f_exhibitionism')),
          row('Ejaculation outside body orifice', 'बाहेर वीर्यस्खलन',
              v('f_ejaculationOutside')),
          if (v('f_ejaculationWhereBody').isNotEmpty)
            row('Ejaculation location on body', 'शरीरावर ठिकाण',
                v('f_ejaculationWhereBody')),
          row('Kissing, licking or sucking', 'चुंबन / चाटणे',
              '${v('f_kissingLickingSucking')} ${v('f_kissingLickingDesc').isNotEmpty ? "(${v('f_kissingLickingDesc')})" : ""}'),
          row('Touching / Fondling', 'स्पर्श करणे',
              '${v('f_touchingFondling')} ${v('f_touchingFondlingDesc').isNotEmpty ? "(${v('f_touchingFondlingDesc')})" : ""}'),
          row('Condom used', 'निरोध वापरला', v('f_condomUsed')),
          if (v('f_condomStatus').isNotEmpty)
            row('Status of condom', 'निरोध स्थिती', v('f_condomStatus')),
          row('Lubricant used', 'स्नेहक वापरले', v('f_lubricantUsed')),
          if (v('f_lubricantKindDesc').isNotEmpty)
            row('Kind of lubricant', 'स्नेहक प्रकार', v('f_lubricantKindDesc')),
          if (v('f_objectUsedDesc').isNotEmpty)
            row('Object description', 'वस्तूचे वर्णन', v('f_objectUsedDesc')),
          if (v('f_otherSexualViolenceForms').isNotEmpty)
            row('Other forms of sexual violence', 'इतर लैंगिक हिंसा प्रकार',
                v('f_otherSexualViolenceForms')),
          section('Post-incident actions (Page 5)', 'घटनोत्तर कृती (पृ. ५)'),
          ...[
            (
              'Changed clothes',
              'f_postChangedClothes',
              'f_postChangedClothesRem'
            ),
            (
              'Changed undergarments',
              'f_postChangedUndergarments',
              'f_postChangedUndergarmentsRem'
            ),
            (
              'Cleaned/washed clothes',
              'f_postCleanedClothes',
              'f_postCleanedClothesRem'
            ),
            (
              'Cleaned/washed undergarments',
              'f_postCleanedUndergarments',
              'f_postCleanedUndergarmentsRem'
            ),
            ('Bathed', 'f_postBathed', 'f_postBathedRem'),
            ('Douched', 'f_postDouched', 'f_postDouchedRem'),
            ('Passed urine', 'f_postPassedUrine', 'f_postPassedUrineRem'),
            ('Passed stools', 'f_postPassedStools', 'f_postPassedStoolsRem'),
            (
              'Rinsing mouth/brushing/vomiting',
              'f_postRinsingMouth',
              'f_postRinsingMouthRem'
            ),
          ].map((item) {
            final choice = v(item.$2);
            final rem = v(item.$3);
            if (choice.isEmpty && rem.isEmpty) return pw.SizedBox();
            return row(
                item.$1, '', '$choice ${rem.isNotEmpty ? "— $rem" : ""}');
          }),
          if (v('f_timeSinceIncident').isNotEmpty)
            row('Time since incident', 'घटनेपासून वेळ',
                v('f_timeSinceIncident')),
          if (v('f_bleedingPriorIncident').isNotEmpty)
            row('Bleeding/discharge prior to incident', 'घटनेपूर्वी रक्तस्राव',
                v('f_bleedingPriorIncident')),
          if (v('f_bleedingSinceIncident').isNotEmpty)
            row('Bleeding/discharge since incident', 'घटनेनंतर रक्तस्राव',
                v('f_bleedingSinceIncident')),
          if (v('f_painSinceIncident').isNotEmpty)
            row('Pain/urination/fissures since incident', 'वेदना/लघवी त्रास',
                v('f_painSinceIncident')),
          section(
              '16. General Physical Examination', '१६. सामान्य शारीरिक तपासणी'),
          if (v('f_examIsFirst').isNotEmpty)
            row('Is this the first examination', 'पहिली तपासणी आहे का',
                v('f_examIsFirst')),
          if (v('f_examPulse').isNotEmpty || v('f_examBp').isNotEmpty)
            row('Pulse / BP', 'नाडी / रक्तदाब',
                'Pulse: ${v('f_examPulse')} | BP: ${v('f_examBp')}'),
          if (v('f_examTemp').isNotEmpty || v('f_examRespRate').isNotEmpty)
            row('Temp / Resp. Rate', 'तापमान / श्वसन दर',
                'Temp: ${v('f_examTemp')} | Resp: ${v('f_examRespRate')}'),
          if (v('f_examPupils').isNotEmpty)
            row('Pupils', 'डोळ्यांच्या बाहुल्या', v('f_examPupils')),
          if (v('f_examGeneralWellbeing').isNotEmpty)
            row('General wellbeing observation', 'सामान्य आरोग्य निरीक्षण',
                v('f_examGeneralWellbeing')),
          if (v('f_generalExam').isNotEmpty) textBlock(v('f_generalExam'), ''),
          section('17. Examination for injuries on the body if any',
              '१७. शरीरावरील जखमा तपासणी'),
          ...() {
            final rows = doc['f_injuryRows'];
            if (rows is! List || rows.isEmpty) {
              return [pw.Text('—', style: body)];
            }
            const labels = [
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
              'Other, please specify',
            ];
            final filled = <pw.Widget>[];
            for (var i = 0; i < rows.length; i++) {
              final val = rows[i]?.toString().trim() ?? '';
              if (val.isNotEmpty) {
                final lbl = i < labels.length ? labels[i] : 'Site ${i + 1}';
                filled.add(row(lbl, '', val));
              }
            }
            return filled.isEmpty
                ? [pw.Text('No injuries noted', style: body)]
                : filled;
          }(),
          section('18. Local examination of genital parts/other orifices',
              '१८. गुप्तांग / इतर छिद्रांची स्थानिक तपासणी'),
          ...() {
            final findings = doc['f_genitalPartFindings'];
            final notes = doc['f_genitalPartNotes'];
            const labels = [
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
              'Any Other',
            ];
            final out = <pw.Widget>[];
            if (findings is List) {
              for (var i = 0; i < findings.length && i < labels.length; i++) {
                final fVal = findings[i]?.toString().trim() ?? '';
                final nVal = notes is List && i < notes.length
                    ? notes[i]?.toString().trim() ?? ''
                    : '';
                if (fVal.isNotEmpty || nVal.isNotEmpty) {
                  out.add(row(labels[i], '',
                      '$fVal ${nVal.isNotEmpty ? "($nVal)" : ""}'));
                }
              }
            }
            return out;
          }(),
          if (v('f_psFindings').isNotEmpty)
            row('P/S findings', 'P/S तपासणी', v('f_psFindings')),
          if (v('f_pvFindings').isNotEmpty)
            row('P/V findings', 'P/V तपासणी', v('f_pvFindings')),
          if (v('f_pvPsReasons').isNotEmpty)
            row('Reasons for P/V or P/S', 'P/V किंवा P/S कारणे',
                v('f_pvPsReasons')),
          if (v('f_anusRectumEncircled').isNotEmpty ||
              v('f_anusRectumNotes').isNotEmpty)
            row('Anus & Rectum', 'गुद व गुदाशय',
                '${v('f_anusRectumEncircled')} ${v('f_anusRectumNotes').isNotEmpty ? "— ${v('f_anusRectumNotes')}" : ""}'),
          if (v('f_oralCavityEncircled').isNotEmpty ||
              v('f_oralCavityNotes').isNotEmpty)
            row('Oral Cavity', 'तोंड / मुखगुहा',
                '${v('f_oralCavityEncircled')} ${v('f_oralCavityNotes').isNotEmpty ? "— ${v('f_oralCavityNotes')}" : ""}'),
          if (v('f_genitalExam').isNotEmpty) textBlock(v('f_genitalExam'), ''),
          section('19. Systemic Examination', '१९. प्रणालीगत तपासणी'),
          if (v('f_sysCns').isNotEmpty)
            row('Central Nervous System', 'मध्यवर्ती मज्जासंस्था',
                v('f_sysCns')),
          if (v('f_sysCvs').isNotEmpty)
            row('Cardio Vascular System', 'हृदय व रक्तवाहिन्या', v('f_sysCvs')),
          if (v('f_sysResp').isNotEmpty)
            row('Respiratory System', 'श्वसन संस्था', v('f_sysResp')),
          if (v('f_sysChest').isNotEmpty) row('Chest', 'छाती', v('f_sysChest')),
          if (v('f_sysAbdomen').isNotEmpty)
            row('Abdomen', 'पोट', v('f_sysAbdomen')),
          if (v('f_systemicExam').isNotEmpty)
            textBlock(v('f_systemicExam'), ''),
          section('20. Sample Collection — Hospital Lab',
              '२०. नमुने — रुग्णालय प्रयोगशाळा'),
          if (v('f_sampleBloodHiv').isNotEmpty)
            row('Blood for HIV, VDRL, HbsAg', 'रक्त तपासणी',
                v('f_sampleBloodHiv')),
          if (v('f_sampleUrinePreg').isNotEmpty)
            row('Urine test for Pregnancy', 'गर्भधारणा तपासणी',
                v('f_sampleUrinePreg')),
          if (v('f_sampleUsg').isNotEmpty)
            row('Ultrasound pregnancy/injury', 'सोनोग्राफी', v('f_sampleUsg')),
          if (v('f_sampleXray').isNotEmpty)
            row('X-ray for Injury', 'क्ष-किरण तपासणी', v('f_sampleXray')),
          section('21. Samples for Forensic Science Laboratory',
              '२१. न्यायवैद्यक विज्ञान प्रयोगशाळेसाठी नमुने'),
          if (v('f_fslDebris').isNotEmpty)
            row('Debris collection paper', 'डेब्रिस कागद', v('f_fslDebris')),
          if (v('f_clothingDetails').isNotEmpty)
            row('Clothing worn by survivor', 'पीडितेचे कपडे तपशील',
                v('f_clothingDetails')),
          ...() {
            final col = doc['f_fslSampleCollected'];
            final rsn = doc['f_fslSampleReasons'];
            const labels = [
              'Swabs from Stains on body',
              'Scalp hair (10-15 strands)',
              'Head hair combing',
              'Nail scrapings',
              'Nail clippings',
              'Oral swab',
              'Blood for grouping/alcohol (plain vial)',
              'Blood for alcohol (Sodium fluoride vial)',
              'Blood for DNA analysis (EDTA vial)',
              'Urine (drug testing)',
              'Any other (tampon/napkin/condom/object)',
            ];
            final out = <pw.Widget>[];
            if (col is List) {
              for (var i = 0; i < col.length && i < labels.length; i++) {
                final cVal = col[i]?.toString().trim() ?? '';
                final rVal = rsn is List && i < rsn.length
                    ? rsn[i]?.toString().trim() ?? ''
                    : '';
                if (cVal.isNotEmpty || rVal.isNotEmpty) {
                  out.add(row(labels[i], '',
                      '$cVal ${rVal.isNotEmpty ? "(Reason: $rVal)" : ""}'));
                }
              }
            }
            return out;
          }(),
          section('4) Genital and Anal Evidence', '४) गुप्तांग व गुद पुरावा'),
          ...() {
            final col = doc['f_genitalEvidenceCollected'];
            final rsn = doc['f_genitalEvidenceReasons'];
            const labels = [
              'Matted pubic hair',
              'Pubic hair combing',
              'Cutting of pubic hair',
              'Two Vulval swabs',
              'Two Vaginal swabs',
              'Two Anal swabs',
              'Vaginal smear (air-dried)',
              'Vaginal washing',
              'Urethral swab',
              'Swab from glans/clitoropenis',
            ];
            final out = <pw.Widget>[];
            if (col is List) {
              for (var i = 0; i < col.length && i < labels.length; i++) {
                final cVal = col[i]?.toString().trim() ?? '';
                final rVal = rsn is List && i < rsn.length
                    ? rsn[i]?.toString().trim() ?? ''
                    : '';
                if (cVal.isNotEmpty || rVal.isNotEmpty) {
                  out.add(row(labels[i], '',
                      '$cVal ${rVal.isNotEmpty ? "(Reason: $rVal)" : ""}'));
                }
              }
            }
            return out;
          }(),
          section(
              '22. Provisional Medical Opinion', '२२. तात्पुरती वैद्यकीय मते'),
          if (v('f_provSurvivorName').isNotEmpty ||
              v('f_provCircumstances').isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                'Examined ${v('f_provSurvivorName')} (${v('f_provGender')}, Age: ${v('f_provAge')}) reporting ${v('f_provCircumstances')}, ${v('f_provTimeAfterIncident')} after incident (bathed/douched: ${v('f_provBathedDouched')}).',
                style: body,
              ),
            ),
          if (v('f_provFslSamples').isNotEmpty)
            row('FSL Samples awaiting reports', 'एफएसएल नमुने',
                v('f_provFslSamples')),
          if (v('f_provHospSamples').isNotEmpty)
            row('Hospital Lab Samples', 'रुग्णालय नमुने',
                v('f_provHospSamples')),
          if (v('f_provClinicalFindings').isNotEmpty)
            row('Clinical Findings', 'वैद्यकीय निष्कर्ष',
                v('f_provClinicalFindings')),
          if (v('f_provAdditionalObs').isNotEmpty)
            row('Additional Observations', 'अतिरिक्त निरीक्षणे',
                v('f_provAdditionalObs')),
          if (v('f_provisionalOpinion').isNotEmpty)
            textBlock(v('f_provisionalOpinion'), ''),
          section('23. Treatment Prescribed', '२३. दिलेला उपचार'),
          ...() {
            final choices = doc['f_treatmentChoice'];
            final comments = doc['f_treatmentComments'];
            const labels = [
              'STI prevention treatment',
              'Emergency contraception',
              'Wound treatment',
              'Tetanus prophylaxis',
              'Hepatitis B vaccination',
              'Post exposure prophylaxis for HIV',
              'Counselling',
              'Other',
            ];
            final out = <pw.Widget>[];
            if (choices is List) {
              for (var i = 0; i < choices.length && i < labels.length; i++) {
                final cVal = choices[i]?.toString().trim() ?? '';
                final comVal = comments is List && i < comments.length
                    ? comments[i]?.toString().trim() ?? ''
                    : '';
                if (cVal.isNotEmpty || comVal.isNotEmpty) {
                  out.add(row(labels[i], '',
                      '$cVal ${comVal.isNotEmpty ? "($comVal)" : ""}'));
                }
              }
            }
            return out;
          }(),
          if (v('f_treatment').isNotEmpty) textBlock(v('f_treatment'), ''),
          section('24. Completion of Examination', '२४. तपासणी पूर्णता'),
          if (v('f_completionDateTime').isNotEmpty)
            row('Date and time of completion', 'पूर्णता दिनांक व वेळ',
                v('f_completionDateTime')),
          if (v('f_reportSheetsCount').isNotEmpty ||
              v('f_reportEnvelopesCount').isNotEmpty)
            row('Sheets / Envelopes', 'पृष्ठे / पाकिटे',
                'Sheets: ${v('f_reportSheetsCount')}, Envelopes: ${v('f_reportEnvelopesCount')}'),
          if (v('f_completionPlace').isNotEmpty)
            row('Place', 'ठिकाण', v('f_completionPlace')),
          if (v('f_doctorName').isNotEmpty)
            row('Examining Doctor', 'तपासणी करणारे डॉक्टर',
                '${v('f_doctorName')} ${v('f_doctorSeal').isNotEmpty ? "(Seal: ${v('f_doctorSeal')})" : ""}'),
          if (v('f_completion').isNotEmpty) textBlock(v('f_completion'), ''),
          section('25. Final Opinion', '२५. अंतिम मत'),
          if (v('f_finalOpinionPerson').isNotEmpty ||
              v('f_finalOpinionTime').isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                'Taking into account history, examination and lab reports of ${v('f_finalOpinionPerson')}, ${v('f_finalOpinionTime')} after incident:',
                style: body,
              ),
            ),
          if (v('f_finalOpinionText').isNotEmpty)
            textBlock(v('f_finalOpinionText'), ''),
          if (v('f_finalOpinionPlace').isNotEmpty)
            row('Place', 'ठिकाण', v('f_finalOpinionPlace')),
          if (v('f_finalDoctorName').isNotEmpty)
            row('Examining Doctor', 'डॉक्टर',
                '${v('f_finalDoctorName')} ${v('f_finalDoctorSeal').isNotEmpty ? "(Seal: ${v('f_finalDoctorSeal')})" : ""}'),
          if (v('f_finalOpinion').isNotEmpty)
            textBlock(v('f_finalOpinion'), ''),
          pw.SizedBox(height: 8),
          pw.Text(
            'COPY OF THE ENTIRE MEDICAL REPORT MUST BE GIVEN TO THE SURVIVOR/VICTIM FREE OF COST IMMEDIATELY',
            style: bold.copyWith(fontSize: 9),
          ),
          pw.Text(
            'संपूर्ण वैद्यकीय अहवालाची प्रत पीडित/पीडितेला त्वरित विनामूल्य द्यावी',
            style: marathiBold,
          ),
        ],
      ),
    );
  }

  if (showMale) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'Forensic Medical Examination of Alleged Accused (Male)',
                  style: title,
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  'आरोपीची फॉरेन्सिक वैद्यकीय तपासणी (पुरुष)',
                  style: marathiBold,
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          row('Hospital', 'रुग्णालय', v('m_hospital')),
          row('Accused Name', 'आरोपीचे नाव', v('m_accusedName')),
          row('Age / DOB', 'वय / जन्मतारीख', '${v('m_age')} / ${v('m_dob')}'),
          row('MLC / C.R.No', 'एम.एल.सी. / गु.नो.',
              '${v('m_mlc')} / ${v('m_crNo')}'),
          row('Police / P.S.', 'पोलीस / ठाणे',
              '${v('m_policeName')} / ${v('m_ps')}'),
          section('8. CONSENT', '८. संमती'),
          textBlock(v('m_consent'), 'संमती तपशील'),
          section(
              'History (as stated by Accused)', 'आरोपीने सांगितलेला इतिहास'),
          textBlock(v('m_assaultHistory'), ''),
          section('General Physical Examination', 'सामान्य शारीरिक तपासणी'),
          textBlock(v('m_generalPhysical'), ''),
          section('Local Examination', 'स्थानिक तपासणी'),
          textBlock(v('m_localExam'), ''),
          section(
            'VIII) Sample collection for Hospital/ Clinical Laboratory',
            '८) रुग्णालय / क्लिनिकल प्रयोगशाळेसाठी नमुने गोळा करणे',
          ),
          pw.Table(
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
            columnWidths: const {
              0: pw.FixedColumnWidth(30),
              1: pw.FlexColumnWidth(2.6),
              2: pw.FlexColumnWidth(2.8),
              3: pw.FlexColumnWidth(2.2),
              4: pw.FixedColumnWidth(60),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(3),
                    child: pw.Text('Sr No',
                        style: bold, textAlign: pw.TextAlign.center),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(3),
                    child: pw.Text('Sample name', style: bold),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(3),
                    child: pw.Text('Test for', style: bold),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(3),
                    child: pw.Text('Preservative / Packing', style: bold),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(3),
                    child: pw.Text('Collected?\nYes/No',
                        style: bold, textAlign: pw.TextAlign.center),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('7',
                          style: body, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('Urethral Swab', style: body)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('Microscopy & Culture', style: body)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('Plain Sterile Bulb', style: body)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(v('m_lab7Collected'),
                          style: body, textAlign: pw.TextAlign.center)),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('8',
                          style: body, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('Swab (Sterile Cotton) from discharge',
                          style: body)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('Microscopy & Culture', style: body)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('Plain Sterile Bulb', style: body)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(v('m_lab8Collected'),
                          style: body, textAlign: pw.TextAlign.center)),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('9',
                          style: body, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('Blood', style: body)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(
                          'Serology (for syphilis, HIV & Hepatitis B)',
                          style: body)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('Plain Sterile Bulb', style: body)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(v('m_lab9Collected'),
                          style: body, textAlign: pw.TextAlign.center)),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('10',
                          style: body, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('Urine (midstream)', style: body)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('Microscopy & Culture', style: body)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('Plain Sterile Bulb', style: body)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(v('m_lab10Collected'),
                          style: body, textAlign: pw.TextAlign.center)),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('11',
                          style: body, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(v('m_lab11Sample'), style: body)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(v('m_lab11Test'), style: body)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(v('m_lab11Packing'), style: body)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(v('m_lab11Collected'),
                          style: body, textAlign: pw.TextAlign.center)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          section(
            '(IX) Samples/ Forensic Evidence preserved for FSL',
            '(९) एफ.एस.एल.साठी जतन केलेला फॉरेन्सिक पुरावा / नमुने',
          ),
          pw.Text(
            'The samples must be collected as per time elapsed between assault and examination, history and physical findings. This will avoid unnecessary sample collection. The list of samples to be preserved is annexed herewith in triplicate, which is the part of requisition to FSL for relevant examination. Here it must be remembered that specific mention in words as to which samples are collected & which are not collected is very necessary.',
            style: body.copyWith(fontSize: 8.5),
          ),
          pw.SizedBox(height: 4),
          row('Note (If any)', 'टिपणी (असल्यास)', v('m_fslNote')),
          section('PROVISIONAL OPINION: **', 'तात्पुरते वैद्यकीय मत: **'),
          pw.Text(
            'After examining the person bearing above mentioned identification marks, ${v('m_opinionTimeElapsed')} days/hours after the incident, I/We is/are of the opinion that:',
            style: body,
          ),
          textBlock(v('m_provisionalOpinion'), ''),
          pw.Row(
            children: [
              pw.Text('Date: ${v('m_opinionDate')}', style: bold),
              pw.Spacer(),
              pw.Text(
                '(Report contains ${v('m_reportPagesCount')} pages each signed by doctor)',
                style: body,
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Container(
                width: 90,
                height: 45,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.8),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(20)),
                ),
                child: pw.Center(child: pw.Text('Stamp', style: body)),
              ),
              pw.Spacer(),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Signature: ${v('m_doctorSig')}', style: body),
                  pw.Text('Name of Dr.: ${v('m_doctorName')}', style: body),
                  pw.Text('Dept/ Designation: ${v('m_doctorDeptDesig')}',
                      style: body),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(5),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('IMPORTANT NOTE**:', style: bold),
                pw.Text(
                  '• The provisional opinion must be in the form of general opinion / impression about possibility of sexual intercourse, after taking into account positive findings in relation to genitals and the body in general. As mentioned above the provisional opinion must include the fact of capacity of the accused to perform sexual act. In absence of these findings, opinion must be reserved till receipt of results of accessory examination.',
                  style: body.copyWith(fontSize: 7.5),
                ),
                pw.Text(
                  '• Precisely brief justification (reasons) in support of your opinion must be given.',
                  style: body.copyWith(fontSize: 7.5),
                ),
                pw.Text(
                  '• * The accused can be examined physically without consent as per Cr.P.C 53 & 53 a, if he denies consent.',
                  style: body.copyWith(fontSize: 7.5),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          section('RECEIPT (by police official):', 'पोलीस अधिकाऱ्याची पावती :'),
          pw.Text('Received forensic medical examination report:', style: body),
          pw.Row(
            children: [
              pw.Expanded(
                  child: pw.Text('Signature: ${v('m_receiptPolice')}',
                      style: body)),
              pw.Expanded(
                  child: pw.Text('Name of police: ${v('m_receiptPoliceName')}',
                      style: body)),
              pw.Expanded(
                  child: pw.Text('Buckle No.: ${v('m_receiptBuckleNo')}',
                      style: body)),
            ],
          ),
          pw.Text('Police station: ${v('m_receiptPs')}', style: body),
        ],
      ),
    );
  }

  return pdf.save();
}
