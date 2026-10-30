import 'package:flutter/material.dart';

import '../modules/core/models/base_record.dart';
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
