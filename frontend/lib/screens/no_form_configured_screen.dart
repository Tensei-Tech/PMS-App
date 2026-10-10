// lib/screens/no_form_configured_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../utils/translation_helper.dart';

/// Screen displayed for unlinked tabs or categories with no database category row or form bundle.
///
/// Rule: Must show ONLY the message "No form configured for this tab".
/// Must show NO "+ Add Case" button, NO list, NO counts, NO Delete button,
/// and must NEVER open [ModuleHubScreen] or save a case.
class NoFormConfiguredScreen extends StatelessWidget {
  final String moduleLabel;

  const NoFormConfiguredScreen({
    super.key,
    required this.moduleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final translatedTitle = TranslationHelper.translate(context, moduleLabel);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          translatedTitle,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_off_outlined,
                  size: 56,
                  color: AppColors.navyMid,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No form configured for this tab',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This category does not have a linked form bundle configured.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.lightSubText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
