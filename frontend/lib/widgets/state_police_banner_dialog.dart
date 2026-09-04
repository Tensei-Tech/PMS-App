// lib/widgets/state_police_banner_dialog.dart
// Interactive State Police Collaboration & Jurisdiction Banner Modal.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/state_branding_helper.dart';
import '../utils/translation_helper.dart';
import 'app_logo.dart';

class StatePoliceBannerDialog extends StatelessWidget {
  final AuthProvider auth;

  const StatePoliceBannerDialog({super.key, required this.auth});

  static void show(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatePoliceBannerDialog(auth: auth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateCode = auth.currentUser?.stateCode ?? auth.stateCode;
    final branding = StateBrandingHelper.getBranding(stateCode);
    final user = auth.currentUser;
    final officerName =
        auth.fullName.isNotEmpty ? auth.fullName : (user?.name ?? 'Officer');
    final rawDesig = auth.designation.isNotEmpty
        ? auth.designation
        : (user?.designation ?? '');
    final transDesig = rawDesig.isNotEmpty
        ? TranslationHelper.translate(context, rawDesig)
        : '';
    final officerValue =
        transDesig.isNotEmpty ? '$officerName ($transDesig)' : officerName;

    final rawDistrict = auth.district.isNotEmpty
        ? auth.district
        : (user?.district ?? 'Headquarters');
    final districtValue = TranslationHelper.translate(context, rawDistrict);

    final rawStation = auth.homeStationName.isNotEmpty
        ? auth.homeStationName
        : (user?.stationName ?? 'State HQ');
    final stationValue = TranslationHelper.translate(context, rawStation);

    final mottoEnglishTrans = TranslationHelper.translate(
      context,
      branding.mottoEnglish,
    );

    final servingMsg =
        '${TranslationHelper.translate(context, 'Serving')} ${branding.stateName} ${TranslationHelper.translate(context, 'State with Honor, Integrity, and Excellence. Integrated via Khakhi Diary Enterprise Portal.')}';

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle indicator
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // Header Banner Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [branding.primaryColor, AppColors.navyDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: branding.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ── LINE 1: Small Text "KHAKHI DIARY" ──
                    Text(
                      'KHAKHI DIARY',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── LINE 2: Khakhi Diary Logo + State Name (Medium Text) + State Police Logo ──
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width > 500
                            ? 460
                            : MediaQuery.of(context).size.width - 40,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Khakhi Diary Logo (Bigger)
                            AppLogo(size: 50, logoUrl: user?.departmentLogoUrl),
                            const SizedBox(width: 12),
                            // State Name (Medium Text)
                            Text(
                              branding.policeForceTitle.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // State Police Emblem Logo Badge (Bigger)
                            if (branding.logoAssetPath != null)
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: branding.accentColor,
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: branding.accentColor.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    branding.logoAssetPath!,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      branding.emblemIcon,
                                      color: branding.accentColor,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: branding.accentColor.withValues(
                                    alpha: 0.25,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: branding.accentColor,
                                    width: 2.0,
                                  ),
                                ),
                                child: Icon(
                                  branding.emblemIcon,
                                  color: branding.accentColor,
                                  size: 28,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade400.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.amber.shade300.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        '"${branding.motto}"',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber.shade200,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mottoEnglishTrans,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Jurisdiction Information Grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _infoRow(
                      context: context,
                      icon: Icons.person_rounded,
                      label: 'Logged-in Officer',
                      value: officerValue,
                      valueColor: AppColors.navyDark,
                    ),
                    const Divider(height: 20),
                    _infoRow(
                      context: context,
                      icon: Icons.location_on_rounded,
                      label: 'State Jurisdiction',
                      value: '${branding.stateName} (${branding.stateCode})',
                      valueColor: AppColors.infoBlue,
                    ),
                    const Divider(height: 20),
                    _infoRow(
                      context: context,
                      icon: Icons.business_rounded,
                      label: 'District / Unit',
                      value: districtValue,
                    ),
                    const Divider(height: 20),
                    _infoRow(
                      context: context,
                      icon: Icons.local_police_rounded,
                      label: 'Home Police Station',
                      value: stationValue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Inspirational State Banner Message
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: branding.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: branding.primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: branding.primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        servingMsg,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.navyMid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    TranslationHelper.translate(context, 'Dismiss'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.navyMid),
        const SizedBox(width: 10),
        Text(
          TranslationHelper.translate(context, label),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.lightSubText,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.navyDark,
            ),
          ),
        ),
      ],
    );
  }
}
