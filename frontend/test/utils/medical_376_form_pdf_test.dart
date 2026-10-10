import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/utils/medical_376_form_pdf_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const artifactDir =
      r'C:\Users\TANISHK.GUPTA\.gemini\antigravity-ide\brain\551ca1b5-9c81-40bd-b64f-a20a0ed11036';

  Future<({Uint8List pdfBytes, int pageCount, List<Uint8List> pageImages})>
      runPdfBuild(
    WidgetTester tester,
    Map<String, dynamic> doc,
  ) async {
    ({Uint8List pdfBytes, int pageCount, List<Uint8List> pageImages})? result;
    Completer<void> done = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  try {
                    result =
                        await buildMedical376FormPdfDocumentV2(context, doc);
                  } catch (e, st) {
                    // ignore: avoid_print
                    print('ERROR in test: $e\n$st');
                  } finally {
                    done.complete();
                  }
                },
                child: const Text('Generate'),
              );
            },
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      await tester.tap(find.text('Generate'));
      await tester.pump();
      int waited = 0;
      while (!done.isCompleted && waited < 120) {
        waited++;
        await Future.delayed(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 50));
      }
    });

    expect(result, isNotNull, reason: 'PDF build should complete successfully');
    return result!;
  }

  void saveArtifactFile(String filename, List<int> bytes) {
    try {
      if (Directory(artifactDir).existsSync()) {
        File('$artifactDir/$filename').writeAsBytesSync(bytes);
      }
    } catch (_) {}
  }

  group('376 Medical Form PDF Tests (Phase C Complete)', () {
    testWidgets('Empty female form test (Sections 1-25): generates valid PDF',
        (WidgetTester tester) async {
      final doc = <String, dynamic>{
        'formSection': 'female',
      };

      final res = await runPdfBuild(tester, doc);
      saveArtifactFile(
          'medical_376_female_empty.pdf', res.pdfBytes as List<int>);

      final pageImages = res.pageImages as List<Uint8List>? ?? [];
      for (int i = 0; i < pageImages.length; i++) {
        saveArtifactFile(
            'medical_376_female_empty_page_${i + 1}.png', pageImages[i]);
      }

      // ignore: avoid_print
      print('PHASE C EMPTY FEMALE PAGE COUNT: ${res.pageCount}');
      expect(res.pageCount, greaterThanOrEqualTo(5));
      expect(res.pdfBytes.length, greaterThan(1000));
    });

    testWidgets(
        'Fully filled female form test (Sections 1-25 + Free Copy Notice): generates multi-page PDF',
        (WidgetTester tester) async {
      final doc = <String, dynamic>{
        'formSection': 'female',
        // Phase A fields:
        'f_hospital': 'District Civil Hospital, Pune',
        'f_opd': 'OPD-12345/2026',
        'f_inpatient': 'IP-6789/2026',
        'f_name': 'Savita Suresh Patil',
        'f_parent': 'Suresh Shankar Patil',
        'f_address':
            'Flat 102, Shanti Niwas, MG Road, Shivaji Nagar, Pune - 411005',
        'f_age': '24',
        'f_dob': '2002-05-15',
        'f_sex': 'Female',
        'f_arrival': '2026-10-02T14:30:00',
        'f_examStart': '2026-10-02T15:00:00',
        'f_broughtBy': 'WPC Sunita Deshmukh, B.No. 4521, Shivaji Nagar PS',
        'f_mlc': 'MLC-987/26',
        'f_ps': 'Shivaji Nagar Police Station',
        'f_conscious':
            'Yes, fully conscious, oriented in time, place and person',
        'f_disability': 'None reported or observed during clinical evaluation',
        'f_consentName': 'Savita Suresh Patil',
        'f_consentParent': 'Suresh Shankar Patil',
        'f_consentTreatment': 'Yes',
        'f_consentMedicoLegal': 'Yes',
        'f_consentSample': 'Yes',
        'f_consentPoliceInfo': 'Yes',
        'f_consentLanguage': 'Marathi',
        'f_consentSupportRole': 'Social Worker / Counselor Sneha Joshi',
        'f_consentHelperSig': 'Sneha Joshi, Signed on 02/10/2026 3:15 PM',
        'f_survivorSig':
            'Savita Patil\nDate: 02/10/2026, Time: 3:20 PM, Place: Civil Hospital Pune',
        'f_witnessSig':
            'WPC Sunita Deshmukh, B.No. 4521\nDate: 02/10/2026, Time: 3:20 PM, Place: Pune',
        'f_idMark1': 'A black mole measuring 3mm on left collar bone',
        'f_idMark2':
            'A linear scar 2cm long over the right forearm ventral aspect',
        'f_menarcheYesNo': 'Yes',
        'f_menarcheAge': '13 years',
        'f_menstrualCycle': '28 days / regular / 4-5 days flow',
        'f_lastMenstrualPeriod': '2026-09-18',
        'f_menstruationAtIncident': 'No',
        'f_menstruationAtExam': 'No',
        'f_pregnantAtIncident': 'No',
        'f_pregnancyDuration': '',
        'f_contraceptionUse': 'No',
        'f_contraceptionMethod': '',
        'f_vaccinationTetanus': 'Vaccinated (Given within last 6 months)',
        'f_vaccinationHepB': 'Vaccinated (Completed 3 doses in 2024)',

        // Phase B fields (Sections 15A–15F & Post-Incident Table):
        'f_incidentDate': '2026-10-01',
        'f_incidentTime': '22:30',
        'f_incidentLocation':
            'Isolated area near Mutha riverbank, Deccan, Pune',
        'f_estimatedDuration': '1-7 days',
        'f_episode': 'One',
        'f_assailantCountAndNames': 'One assailant, known as Ramesh Shinde',
        'f_assailantSex': 'Male',
        'f_assailantAge': 'Approx. 28 years',
        'f_assailantRelationship':
            'Acquaintance / neighbour from same locality',
        'f_narratorDetails':
            'Savita Patil (Survivor herself narrated in Marathi)',
        'f_violenceHistory':
            'On 01/10/2026 around 10:30 PM, while returning from coaching class, the assailant approached on motorcycle, threatened with knife, pulled hair, dragged towards bushes, subjected to forceful non-consensual sexual intercourse despite resistance, and fled after threat of death if informed to police.',
        'f_hitWith': 'Fist and blunt hand strikes on face',
        'f_burnedWith': '',
        'f_biting': 'Bite mark on right shoulder',
        'f_kicking': 'Kicked on abdomen and lower limbs',
        'f_pinching': 'Pinching on upper arms',
        'f_pullingHair': 'Hair forcefully pulled and dragged',
        'f_violentShaking': 'Violently shaken while pinned down',
        'f_bangingHead': '',
        'f_15cEmotionalAbuse':
            'Abused with filthy words, cursed, insulted and humiliated continuously',
        'f_15cRestraints': 'Hands pinned behind back and held down by force',
        'f_15cWeapons':
            'Sharp knife shown to intimidate and threatened to stab',
        'f_15cVerbalThreats':
            'Threatened to kill family members and circulate defamatory allegations',
        'f_15cLuring': '',
        'f_15cAnyOther': 'Deprived of mobile phone during the assault',
        'f_15dIntoxication':
            'Strong smell of alcohol from assailant; survivor was not intoxicated',
        'f_15dUnconscious':
            'Survivor felt dizzy and briefly stunned after blow to head, but remained conscious',
        'f_15eAssailantInjury':
            'Survivor scratched assailant on his left cheek and neck in self-defence',
        'f_penGenitaliaPenis': 'Y',
        'f_penGenitaliaBodyPart': 'Y',
        'f_penGenitaliaObject': 'N',
        'f_emissionGenitalia': 'Yes',
        'f_penAnusPenis': 'N',
        'f_penAnusBodyPart': 'N',
        'f_penAnusObject': 'N',
        'f_emissionAnus': 'No',
        'f_penMouthPenis': 'N',
        'f_penMouthBodyPart': 'N',
        'f_penMouthObject': 'N',
        'f_emissionMouth': 'No',
        'f_oralSexPerformed': 'N',
        'f_forcedMasturbationSelf': 'N',
        'f_masturbationAssailant': 'N',
        'f_exhibitionism': 'Y',
        'f_ejaculationOutside': 'Y',
        'f_ejaculationWhereBody': 'Over lower abdomen and thighs',
        'f_kissingLickingSucking': 'Y',
        'f_kissingLickingDesc': 'Forced kissing on lips and neck',
        'f_touchingFondling': 'Y',
        'f_touchingFondlingDesc':
            'Aggressive fondling over breasts and genitals over clothing and undergarments',
        'f_condomUsed': 'N',
        'f_condomStatus': '',
        'f_lubricantUsed': 'N',
        'f_lubricantKindDesc': '',
        'f_objectUsedDesc': '',
        'f_otherSexualViolenceForms': 'Clothes torn by force during assault',
        'f_postChangedClothes': 'N',
        'f_postChangedClothesRem':
            'Wearing same salwar kameez worn during incident',
        'f_postChangedUndergarments': 'N',
        'f_postChangedUndergarmentsRem':
            'Same undergarments preserved for forensic collection',
        'f_postCleanedClothes': 'N',
        'f_postCleanedClothesRem': 'Not washed or cleaned',
        'f_postCleanedUndergarments': 'N',
        'f_postCleanedUndergarmentsRem': 'Not washed',
        'f_postBathed': 'N',
        'f_postBathedRem': 'No bath taken after incident',
        'f_postDouched': 'N',
        'f_postDouchedRem': 'No douching done',
        'f_postPassedUrine': 'Y',
        'f_postPassedUrineRem':
            'Passed urine once around 2 hours after incident',
        'f_postPassedStools': 'N',
        'f_postPassedStoolsRem': 'Did not pass stools',
        'f_postRinsingMouth': 'Y',
        'f_postRinsingMouthRem': 'Rinsed mouth with water once due to dryness',
        'f_timeSinceIncident':
            'Approx. 16 hours elapsed between incident and examination',
        'f_bleedingPriorIncident': 'No prior bleeding or discharge reported',
        'f_bleedingSinceIncident':
            'Mild per-vaginal bleeding and spotting noticed following the incident',
        'f_painSinceIncident':
            'Severe pain in genital region, tenderness over lower abdomen, painful urination',

        // Phase C fields (Sections 16–25):
        // Section 16:
        'f_examIsFirst': 'Yes',
        'f_examPulse': '88/min',
        'f_examBp': '124/82 mmHg',
        'f_examTemp': '98.4 °F',
        'f_examRespRate': '18/min',
        'f_examPupils': 'Normal size, equal, reacting to light',
        'f_examGeneralWellbeing':
            'Anxious, distressed, tearful but well-oriented in time, place and person',

        // Section 17 (12 rows):
        'f_injuryRows': [
          'Tenderness present over vertex, no haematoma',
          'Mild swelling over left cheek bone',
          'Absent',
          'Contusion 1x0.5 cm inside lower lip mucosa',
          'NIL',
          'Intact, no perforation or bleeding',
          'Multiple reddish contusions over right breast and left clavicular region',
          'Linear abrasions over bilateral dorsal forearms',
          'Multiple pinch mark bruises over medial left arm',
          'Contusion 4x3 cm over inner right thigh with tenderness',
          'Abrasions over buttocks consistent with friction on rough ground',
          'NIL',
        ],

        // Section 18:
        'f_genitalPartFindings': [
          'Redness and mild congestion around urethral meatus',
          'Oedematous, tender to touch',
          'Erythema present bilateral minora',
          'Fresh mucosal tear at fourchette measuring 0.5 cm, oozing blood',
          'Hymen shows fresh tear at 6 oclock position with swollen edges',
          'Normal, no discharge',
          'NA',
          'NA',
          'NA',
          'NA',
          'NA',
          'NA',
        ],
        'f_genitalPartNotes': [
          'Swab collected',
          'Oedema noted',
          'Tender',
          'Recent injury',
          'Fresh tear',
          'Clear',
          'NA',
          'NA',
          'NA',
          'NA',
          'NA',
          'NA',
        ],
        'f_psFindings':
            'Not indicated; deferred as external injuries were clearly documented',
        'f_pvFindings':
            'Not indicated, avoided as per national protocol guidelines',
        'f_pvPsReasons': 'NA',
        'f_anusRectumEncircled': 'Bleeding, Tenderness',
        'f_anusRectumNotes':
            'No gross tear visible, sphincter tone normal, mild perianal redness and tenderness',
        'f_oralCavityEncircled': 'Bleeding',
        'f_oralCavityNotes':
            'Contusion inside lower lip, no teeth loosened, swab taken for FSL',

        // Section 19:
        'f_sysCns': 'Conscious, alert, oriented, GCS 15/15',
        'f_sysCvs': 'S1 S2 heard, regular rhythm, no murmurs',
        'f_sysResp': 'Bilateral air entry equal, clear, no added sounds',
        'f_sysChest': 'Tenderness over sternum, no rib fractures detected',
        'f_sysAbdomen':
            'Soft, mild diffuse lower abdominal tenderness, bowel sounds present',

        // Section 20:
        'f_sampleBloodHiv':
            'Collected in plain bulb & EDTA, sent to pathology lab for HIV/VDRL/HBsAg',
        'f_sampleUrinePreg': 'Negative (Card test done in OPD)',
        'f_sampleUsg': 'Pelvic USG advised, scheduled in radiology dept',
        'f_sampleXray': 'X-ray chest and skull - No bony fracture seen',

        // Section 21:
        'f_fslDebris':
            'Debris and hair from body collected over filter paper, sealed in envelope',
        'f_clothingDetails':
            '1. Blue printed cotton Kurti (torn near right shoulder, mud stains on back)\n2. White Salwar (stained)\n3. Cotton innerwear (duly air-dried and sealed in separate brown paper bag)',
        'f_fslSampleCollected': [
          'Collected',
          'Collected',
          'Collected',
          'Collected',
          'Collected',
          'Collected',
          'Collected',
          'Collected',
          'Collected',
          'Not Collected',
        ],
        'f_fslSampleReasons': [
          'Stains from inner thigh swabbed',
          '15 strands collected with roots',
          'Hair combing preserved',
          'Scrapings taken bilateral hands',
          'Nails clipped and packed',
          'Oral swab taken',
          'Plain vial collected',
          'Sodium fluoride vial collected',
          'EDTA vial collected',
          'Tampon/object not present',
        ],
        'f_genitalEvidenceCollected': [
          'Collected',
          'Collected',
          'Collected',
          'Collected',
          'Collected',
          'Collected',
          'Collected',
          'Not Collected',
          'Not Collected',
          'Not Collected',
        ],
        'f_genitalEvidenceReasons': [
          'Matted pubic hair clipped and sealed',
          'Combing preserved in envelope',
          'Hair clippings collected',
          '2 Vulval swabs taken',
          '2 Vaginal swabs taken',
          '2 Anal swabs taken',
          'Air-dried smear prepared',
          'Not indicated',
          'Not indicated',
          'NA (Female survivor)',
        ],

        // Section 22:
        'f_provSurvivorName': 'Savita Suresh Patil',
        'f_provGender': 'Female',
        'f_provAge': '24 years',
        'f_provCircumstances':
            'Forcible sexual assault by known assailant with physical violence',
        'f_provTimeAfterIncident': '16 hours',
        'f_provBathedDouched': 'Not bathed, not douched',
        'f_provFslSamples':
            'Sealed parcel containing clothing, vaginal/vulval swabs, blood & nail clippings forwarded to FSL Pune',
        'f_provHospSamples':
            'Blood sent for HIV, VDRL, HBsAg; urine pregnancy test negative',
        'f_provClinicalFindings':
            'Fresh genital injuries (fourchette & hymen tear) along with multiple bodily contusions and abrasions consistent with history of sexual violence and physical struggle.',
        'f_provAdditionalObs':
            'Psychological trauma counseling initiated immediately.',

        // Section 23:
        'f_treatmentChoice': [
          'Yes',
          'Yes',
          'Yes',
          'Yes',
          'Yes',
          'Yes',
          'Yes',
          'No',
        ],
        'f_treatmentComments': [
          'Tab Azithromycin 1g stat + Cefixime 400mg stat given',
          'Tab Levonorgestrel 1.5mg stat given in OPD',
          'Local antiseptic dressing on abrasions and lip contusion',
          'Inj TT 0.5ml IM given stat',
          'Hepatitis B vaccine first dose administered stat',
          'PEP starter pack prescribed (Tenofovir + Lamivudine + Dolutegravir)',
          'Crisis counseling and follow-up support arranged with MSW Sneha',
          'NIL',
        ],

        // Section 24:
        'f_completionDateTime': '2026-10-02 17:30',
        'f_reportSheetsCount': '8',
        'f_reportEnvelopesCount': '3',
        'f_completionPlace': 'District Civil Hospital, Pune',
        'f_doctorName': 'Dr. Anjali Deshpande, MD (OBGY)',
        'f_doctorSeal': 'Reg. No. MMC-2012/04/1234, Senior Medical Officer',

        // Section 25:
        'f_finalOpinionPerson': 'Savita Suresh Patil',
        'f_finalOpinionTime': '16 hours',
        'f_finalOpinionText':
            'Based on the clinical examination, pattern of fresh external bodily injuries and genital mucosal tears (fourchette and hymenal tear at 6 oclock), together with the FSL chemical analysis confirming presence of human semen and matching DNA profile of the alleged assailant, it is concluded that there is conclusive medical and forensic evidence of recent sexual intercourse and physical assault.',
        'f_finalOpinionPlace': 'District Civil Hospital, Pune',
        'f_finalDoctorName': 'Dr. Anjali Deshpande, MD (OBGY)',
        'f_finalDoctorSeal':
            'Reg. No. MMC-2012/04/1234, CMO / Forensic Medical Examiner',
      };

      final res = await runPdfBuild(tester, doc);
      saveArtifactFile(
          'medical_376_female_filled.pdf', res.pdfBytes as List<int>);

      final pageImages = res.pageImages as List<Uint8List>? ?? [];
      for (int i = 0; i < pageImages.length; i++) {
        saveArtifactFile(
            'medical_376_female_filled_page_${i + 1}.png', pageImages[i]);
      }

      // ignore: avoid_print
      print('PHASE C FILLED FEMALE PAGE COUNT: ${res.pageCount}');
      expect(res.pageCount, greaterThanOrEqualTo(6));
      expect(res.pdfBytes.length, greaterThan(1000));
    });

    testWidgets('Empty male form test (Sections 1-24): generates valid PDF',
        (WidgetTester tester) async {
      final doc = <String, dynamic>{
        'formSection': 'male',
      };

      final res = await runPdfBuild(tester, doc);
      saveArtifactFile('medical_376_male_empty.pdf', res.pdfBytes as List<int>);

      final pageImages = res.pageImages as List<Uint8List>? ?? [];
      for (int i = 0; i < pageImages.length; i++) {
        saveArtifactFile(
            'medical_376_male_empty_page_${i + 1}.png', pageImages[i]);
      }

      // ignore: avoid_print
      print('FULL EMPTY MALE PAGE COUNT: ${res.pageCount}');
      expect(res.pageCount, greaterThan(0));
      expect(res.pdfBytes.length, greaterThan(1000));
    });

    testWidgets(
        'Fully filled male form test (Sections 1-24): generates valid PDF',
        (WidgetTester tester) async {
      final doc = <String, dynamic>{
        'formSection': 'male',
        'm_hospital': 'Sassoon General Hospital, Pune',
        'm_opd': 'OPD-9988/2026',
        'm_date': '2026-10-02',
        'm_mlc': 'MLC-M-445/26',
        'm_mlcDate': '2026-10-02',
        'm_accusedName': 'Ramesh Vitthal Shinde',
        'm_age': '28',
        'm_dob': '1998-03-21',
        'm_religion': 'Hindu',
        'm_marital': 'Unmarried',
        'm_address': 'Room 12, Ganpati Chawl, Hadapsar, Pune - 411028',
        'm_policeName': 'API R. K. Jadhav, Deccan PS',
        'm_buckle': '8872',
        'm_ps': 'Deccan Gymkhana PS',
        'm_crNo': '112/2026',
        'm_section': 'BNS 64, 351(2)',
        'm_consent':
            'I voluntarily give consent for medical and forensic examination.\nSigned: Ramesh Shinde\nDate: 02/10/2026 4:30 PM',
        'm_idMark1': 'Scar on forehead above right eyebrow 1.5 cm',
        'm_idMark2': 'Left thumb impression taken on record',
        'm_examDateTime': '2026-10-02T16:45:00',
        'm_doctor': 'Dr. Pravin Sawant, MD (Forensic Medicine)',
        'm_assaultHistory':
            'Accused stated that he was present at Deccan riverbank area and had an argument with the complainant; denied committing non-consensual sexual act; states scratch marks on his cheek occurred during altercation.',
        'm_witnessSig': 'PC K. B. More, B.No. 3312, Deccan PS',
        'm_accusedSig': 'Ramesh Vitthal Shinde, Dated: 02/10/2026',
        'm_medSurgicalHistory':
            'No major past illness, no history of epilepsy or bleeding disorders; fit for examination',
        'm_generalPhysical':
            'Well-built adult male, pulse 80/min, BP 120/80 mmHg, afebrile, oriented, multiple scratch abrasions on left cheek and anterior neck',
        'm_localExam':
            'Penis circumcised, no smegma, coronal sulcus clear, no active ulcer or discharge, testicular sensation normal bilateral, scrotal rugosity present',
        'm_systemicExam':
            'CNS: Conscious and oriented, CVS: S1 S2 normal, RS: Clear, Abdomen: Soft, no organomegaly',
        'm_additionalFindings':
            'Referred to Psychiatry OPD for standard baseline assessment',
        'm_lab7Collected': 'Yes',
        'm_lab8Collected': 'Yes',
        'm_lab9Collected': 'Yes',
        'm_lab10Collected': 'Yes',
        'm_lab11Sample': 'Nail clippings & Penile swab',
        'm_lab11Test': 'DNA & Forensics',
        'm_lab11Packing': 'Sterile paper envelope',
        'm_lab11Collected': 'Yes',
        'm_fslNote':
            'Penile swab, urethral swab, scalp hair, pubic hair combings and blood in EDTA preserved and sealed for FSL Pune.',
        'm_opinionTimeElapsed': '18 hours',
        'm_provisionalOpinion':
            'After thorough physical, genital and forensic examination, there are positive physical findings (scratch abrasions on face and neck consistent with struggle) and there is nothing to suggest that the accused is incapable of performing sexual intercourse.',
        'm_opinionDate': '2026-10-02',
        'm_reportPagesCount': '4',
        'm_doctorSig': 'Dr. Pravin Sawant',
        'm_doctorName': 'Dr. Pravin Sawant, MD (Forensic Medicine)',
        'm_doctorDeptDesig':
            'Associate Professor & Medical Examiner, Sassoon Hospital',
        'm_receiptPolice': 'API R. K. Jadhav',
        'm_receiptPoliceName': 'API Ramesh K. Jadhav',
        'm_receiptBuckleNo': '8872',
        'm_receiptPs': 'Deccan Gymkhana Police Station',
      };

      final res = await runPdfBuild(tester, doc);
      saveArtifactFile(
          'medical_376_male_filled.pdf', res.pdfBytes as List<int>);

      final pageImages = res.pageImages as List<Uint8List>? ?? [];
      for (int i = 0; i < pageImages.length; i++) {
        saveArtifactFile(
            'medical_376_male_filled_page_${i + 1}.png', pageImages[i]);
      }

      // ignore: avoid_print
      print('FULL FILLED MALE PAGE COUNT: ${res.pageCount}');
      expect(res.pageCount, greaterThan(0));
      expect(res.pdfBytes.length, greaterThan(1000));
    });
  });
}
