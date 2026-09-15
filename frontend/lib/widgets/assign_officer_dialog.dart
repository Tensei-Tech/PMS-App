import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../utils/translation_helper.dart';

class AssignOfficerDialog extends StatefulWidget {
  final String caseNumber;
  final String title;

  const AssignOfficerDialog(
      {super.key, required this.caseNumber, required this.title});

  static Future<bool?> show(BuildContext context,
      {required String caseNumber, required String title}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) =>
          AssignOfficerDialog(caseNumber: caseNumber, title: title),
    );
  }

  @override
  State<AssignOfficerDialog> createState() => _AssignOfficerDialogState();
}

class _AssignOfficerDialogState extends State<AssignOfficerDialog> {
  String? _selectedIO;

  final List<String> _mockIOs = [
    'Inspector Rajan (Self)',
    'Sub-Inspector Kadam',
    'Sub-Inspector Deshmukh',
    'Assistant Sub-Inspector Patil',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIO = _mockIOs.first;
  }

  void _assign() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TranslationHelper.translate(
            context, 'Case Assigned to $_selectedIO (Mock)')),
        backgroundColor: AppColors.successGreen,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TranslationHelper.translate(context, 'Assign Officer'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.caseNumber} - ${widget.title}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.navyMid,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              TranslationHelper.translate(
                  context, 'Select Investigating Officer (IO)'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedIO,
              items: _mockIOs
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedIO = val),
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    TranslationHelper.translate(context, 'Cancel'),
                    style: GoogleFonts.poppins(
                        color: AppColors.lightSubText,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _assign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    TranslationHelper.translate(context, 'Assign Case'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
