import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';
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
  List<String> _officers = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initOfficers());
  }

  Future<void> _initOfficers() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final selfName = auth.displayName.isNotEmpty
        ? '${auth.displayName} (Self)'
        : 'Current Officer (Self)';

    final list = <String>[selfName];

    setState(() {
      _loading = true;
      _officers = list;
      _selectedIO = selfName;
    });

    try {
      final res = await ApiService().get(ApiConfig.users);
      if (res.isSuccess && res.data is List) {
        for (final item in res.data) {
          if (item is Map) {
            final name = (item['name'] ?? item['full_name'] ?? item['username'])
                ?.toString()
                .trim();
            final desig = item['designation']?.toString().trim();
            if (name != null && name.isNotEmpty) {
              final label = (desig != null && desig.isNotEmpty)
                  ? '$desig $name'
                  : name;
              if (!list.contains(label) && label != auth.displayName) {
                list.add(label);
              }
            }
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _loading = false;
        _officers = list;
        if (_selectedIO == null || !_officers.contains(_selectedIO)) {
          _selectedIO = _officers.first;
        }
      });
    }
  }

  void _assign() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TranslationHelper.translate(
            context, 'Case Assigned to $_selectedIO')),
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
              items: _officers
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedIO = val),
              decoration: InputDecoration(
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
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
