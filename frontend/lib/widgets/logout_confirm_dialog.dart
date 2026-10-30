import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Asks "Are you sure you want to log out?"; true only when the user taps
/// the log-out button (Cancel, back or a tap outside give false).
Future<bool> confirmLogout(BuildContext context,
    {String label = 'Log out'}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.logout_rounded, color: AppColors.dangerRed),
          const SizedBox(width: 10),
          Text(
            '$label?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark,
            ),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to ${label.toLowerCase()}?',
        style: GoogleFonts.poppins(fontSize: 13.5, color: AppColors.lightText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.lightSubText,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.dangerRed,
            foregroundColor: Colors.white,
          ),
          child: Text(label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  return confirmed == true;
}
