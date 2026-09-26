import 'package:flutter/material.dart';

import '../modules/core/models/base_record.dart';
import '../modules/accidental_death/providers/accidental_death_provider.dart';
import '../providers/auth_provider.dart';
import '../services/case_service.dart';
import '../services/firestore_service.dart';
import '../utils/ad_disposal_helper.dart';
import '../utils/app_constants.dart';
import '../widgets/base_form/base_form.dart';
import '../widgets/common_form/government_vehicle_usage_widget.dart';
import '../widgets/common_form/section_82_83_action_widget.dart';
import '../theme/app_theme.dart';
import '../widgets/dynamic_form/dynamic_form_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Theme colors
// ─────────────────────────────────────────────────────────────────────────────
const Color primaryDark = AppColors.navyDark;
const Color primaryMid = AppColors.navyMid;
const Color accentTeal = AppColors.cyanPrimary;
const Color accentBlue = AppColors.infoBlue;
const Color accentGreen = AppColors.successGreen;
const Color accentRed = AppColors.dangerRed;
const Color textPrimary = AppColors.lightText;
const Color textSecondary = AppColors.lightSubText;
const Color textMuted = AppColors.lightSubText;
const Color inputBg = AppColors.lightSurface;
const Color inputBorder = AppColors.lightBorder;
const Color cardBg = AppColors.lightCard;
const Color pageBg = AppColors.lightBg;

// ─────────────────────────────────────────────────────────────────────────────
// ACT data
// ─────────────────────────────────────────────────────────────────────────────
// ignore: constant_identifier_names — public map symbol shared with downstream / Firestore payloads
const Map<String, Map<String, dynamic>> ACT_DATA = {
  'BNS': {
    'label': 'BNS, 2023',
    'hint': 'Applies to offences on or after 1 July 2024.',
    'sections': [
      {'val': '100', 'label': '100 - Culpable homicide', 'cat': 'BNS_C6'},
      {'val': '101', 'label': '101 - Murder', 'cat': 'BNS_C6'},
      {'val': '103', 'label': '103 - Punishment for murder', 'cat': 'BNS_C6'},
      {'val': '104', 'label': '104 - Murder by life convict', 'cat': 'BNS_C6'},
      {
        'val': '105',
        'label': '105 - Culpable homicide not amounting to murder',
        'cat': 'BNS_C6'
      },
      {
        'val': '106',
        'label': '106 - Causing death by negligence',
        'cat': 'BNS_C6'
      },
      {
        'val': '107',
        'label': '107 - Abetment of suicide of child',
        'cat': 'BNS_C6'
      },
      {'val': '108', 'label': '108 - Abetment of suicide', 'cat': 'BNS_C6'},
      {'val': '109', 'label': '109 - Attempt to murder', 'cat': 'BNS_C6'},
      {
        'val': '110',
        'label': '110 - Attempt to commit culpable homicide',
        'cat': 'BNS_C6'
      },
      {'val': '111', 'label': '111 - Organised crime', 'cat': 'BNS_C6'},
      {'val': '113', 'label': '113 - Terrorist act', 'cat': 'BNS_C6'},
      {'val': '114', 'label': '114 - Hurt', 'cat': 'BNS_C6'},
      {
        'val': '115',
        'label': '115 - Voluntarily causing hurt',
        'cat': 'BNS_C6'
      },
      {'val': '116', 'label': '116 - Grievous hurt', 'cat': 'BNS_C6'},
      {
        'val': '117',
        'label': '117 - Voluntarily causing grievous hurt',
        'cat': 'BNS_C6'
      },
      {
        'val': '118',
        'label': '118 - Hurt by dangerous weapons',
        'cat': 'BNS_C6'
      },
      {'val': '124', 'label': '124 - Grievous hurt by acid', 'cat': 'BNS_C6'},
      {'val': '125', 'label': '125 - Act endangering life', 'cat': 'BNS_C6'},
      {'val': '140', 'label': '140 - Kidnapping to murder', 'cat': 'BNS_C6'},
      {'val': '143', 'label': '143 - Trafficking of person', 'cat': 'BNS_C6'},
      {'val': '63', 'label': '63 - Rape', 'cat': 'BNS_C5'},
      {'val': '70', 'label': '70 - Gang rape', 'cat': 'BNS_C5'},
      {'val': '80', 'label': '80 - Dowry death', 'cat': 'BNS_C5'},
      {
        'val': '85',
        'label': '85 - Cruelty by husband or relatives',
        'cat': 'BNS_C5'
      },
      {'val': '303', 'label': '303 - Theft', 'cat': 'BNS_C17'},
      {'val': '309', 'label': '309 - Robbery', 'cat': 'BNS_C17'},
      {'val': '310', 'label': '310 - Dacoity', 'cat': 'BNS_C17'},
      {
        'val': '316',
        'label': '316 - Criminal breach of trust',
        'cat': 'BNS_C17'
      },
      {'val': '318', 'label': '318 - Cheating', 'cat': 'BNS_C17'},
      {'val': '336', 'label': '336 - Forgery', 'cat': 'BNS_C18'},
      {'val': '351', 'label': '351 - Criminal intimidation', 'cat': 'BNS_C19'},
    ],
  },
  'IPC': {
    'label': 'IPC, 1860',
    'hint': 'Applies to offences BEFORE 1 July 2024.',
    'sections': [
      {'val': '302', 'label': '302 - Murder', 'cat': '1'},
      {
        'val': '304',
        'label': '304 - Culpable homicide not amounting to murder',
        'cat': '1'
      },
      {
        'val': '304A',
        'label': '304A - Causing death by negligence',
        'cat': '1'
      },
      {'val': '307', 'label': '307 - Attempt to murder', 'cat': '1'},
      {'val': '376', 'label': '376 - Rape', 'cat': '3'},
      {'val': '379', 'label': '379 - Theft', 'cat': '2'},
      {'val': '392', 'label': '392 - Robbery', 'cat': '2'},
      {'val': '395', 'label': '395 - Dacoity', 'cat': '2'},
      {'val': '406', 'label': '406 - Criminal breach of trust', 'cat': '2'},
      {'val': '420', 'label': '420 - Cheating', 'cat': '2'},
    ],
  },
  'ARMS': {
    'label': 'Arms Act, 1959',
    'hint': 'Apply when illegal weapons or ammunition are seized.',
    'sections': [
      {
        'val': '3',
        'label': '3 - Licence required for Arms/Ammunition',
        'cat': '5'
      },
      {'val': '25', 'label': '25 - Unlawful Possession of Arms', 'cat': '5'},
      {'val': '27', 'label': '27 - Punishment for using arms', 'cat': '5'},
    ],
  },
  'NDPS': {
    'label': 'NDPS Act, 1985',
    'hint': 'Narcotics/drugs/psychotropic substances.',
    'sections': [
      {
        'val': '8',
        'label': '8 - Prohibition on production/sale/possession',
        'cat': '5'
      },
      {'val': '20', 'label': '20 - Offences relating to Cannabis', 'cat': '5'},
      {
        'val': '21',
        'label': '21 - Offences relating to manufactured drugs',
        'cat': '5'
      },
      {
        'val': '22',
        'label': '22 - Offences relating to psychotropic substances',
        'cat': '5'
      },
    ],
  },
  'POCSO': {
    'label': 'POCSO Act, 2012',
    'hint': 'Victim must be under 18 years.',
    'sections': [
      {'val': '3', 'label': '3 - Penetrative Sexual Assault', 'cat': '3'},
      {
        'val': '4',
        'label': '4 - Punishment for Penetrative Sexual Assault',
        'cat': '3'
      },
      {'val': '7', 'label': '7 - Sexual Assault', 'cat': '3'},
      {'val': '8', 'label': '8 - Punishment for Sexual Assault', 'cat': '3'},
    ],
  },
  'MCOCA': {
    'label': 'MCOCA, 1999',
    'hint': 'Requires SP-level sanction to invoke.',
    'sections': [
      {
        'val': '3(1)(i)',
        'label': '3(1)(i) - Organised Crime causing death',
        'cat': '5'
      },
      {'val': '3(2)', 'label': '3(2) - Abetment/Conspiracy', 'cat': '5'},
    ],
  },
  'MPDA': {
    'label': 'MPDA, 1981',
    'hint': 'Preventive Detention order.',
    'sections': [
      {
        'val': '3(1)',
        'label': '3(1) - Detention of dangerous person',
        'cat': '5'
      },
    ],
  },
  'IT': {
    'label': 'IT Act, 2000',
    'hint': 'Apply for cyber crimes and electronic fraud.',
    'sections': [
      {'val': '66', 'label': '66 - Computer Related Offences', 'cat': '5'},
      {'val': '66C', 'label': '66C - Identity Theft', 'cat': '5'},
      {
        'val': '66D',
        'label': '66D - Cheating by personation using computer',
        'cat': '5'
      },
      {
        'val': '67',
        'label': '67 - Publishing obscene material electronically',
        'cat': '5'
      },
    ],
  },
  'SC_ST': {
    'label': 'SC/ST (PoA) Act, 1989',
    'hint': 'Atrocity cases involving SC/ST victims.',
    'sections': [
      {
        'val': '3(1)(r)',
        'label': '3(1)(r) - Intentional insult/intimidation',
        'cat': '5'
      },
      {
        'val': '3(2)(v)',
        'label': '3(2)(v) - Murder/attempt on SC/ST member',
        'cat': '5'
      },
    ],
  },
};

class ADFormScreen extends StatefulWidget {
  /// When set (e.g. user tapped Edit on the A.D hub), form loads `ad_forms` / draft by AD No.
  final ModuleRecord? existingRecord;

  /// Routes to pop after successful submit (hub→form = 1; hub→detail→form = 2).
  final int popCountAfterSubmit;

  const ADFormScreen({
    super.key,
    this.existingRecord,
    this.popCountAfterSubmit = 1,
  });

  @override
  State<ADFormScreen> createState() => _ADFormScreenState();
}

class _ADFormScreenState extends State<ADFormScreen> {
  @override
  Widget build(BuildContext context) {
    return DynamicFormScreen(
      categoryId: 40,
      moduleLabel: 'A.D.',
      moduleKey: 'ad',
      subCategory: 'A.D.',
      existingRecord: widget.existingRecord,
    );
  }
}
