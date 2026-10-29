// lib/widgets/add_warrant_case_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../modules/core/models/base_record.dart';
import '../modules/sam_warrant/providers/sam_warrant_provider.dart';
import '../providers/auth_provider.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';

/// Modal dialog allowing police officers to register a new Summons or Warrant case.
/// Automatically calculates into the Summons & Warrant monthly report.
class AddWarrantCaseDialog extends StatefulWidget {
  final int? initialYear;
  final int? initialMonth;

  const AddWarrantCaseDialog({
    super.key,
    this.initialYear,
    this.initialMonth,
  });

  static Future<bool?> show(
    BuildContext context, {
    int? initialYear,
    int? initialMonth,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddWarrantCaseDialog(
        initialYear: initialYear,
        initialMonth: initialMonth,
      ),
    );
  }

  @override
  State<AddWarrantCaseDialog> createState() => _AddWarrantCaseDialogState();
}

class _AddWarrantCaseDialogState extends State<AddWarrantCaseDialog> {
  final _formKey = GlobalKey<FormState>();

  String _processType = 'summons'; // 'summons', 'nbw', 'bw'
  final TextEditingController _caseNumberCtrl = TextEditingController();
  final TextEditingController _accusedNameCtrl = TextEditingController();
  final TextEditingController _courtNameCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _executionStatus = 'pending'; // 'pending', 'executed', 'unserved'
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final y = widget.initialYear ?? now.year;
    final m = widget.initialMonth ?? now.month;
    // Set initial date to match selected month/year if within valid bounds
    if (y == now.year && m == now.month) {
      _selectedDate = now;
    } else {
      _selectedDate = DateTime(y, m, 15);
    }
  }

  @override
  void dispose() {
    _caseNumberCtrl.dispose();
    _accusedNameCtrl.dispose();
    _courtNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navyMid,
              onPrimary: Colors.white,
              onSurface: AppColors.navyDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthProvider>();
      final stationName = auth.stationName.isNotEmpty ? auth.stationName : 'ALL';
      final officerName = auth.displayName.isNotEmpty ? auth.displayName : 'Officer';
      final officerUid = auth.uid;

      String subCatLabel;
      String titlePrefix;
      if (_processType == 'nbw') {
        subCatLabel = 'Non-Bailable Warrant (पकड वारंट)';
        titlePrefix = 'NBW (पकड वारंट)';
      } else if (_processType == 'bw') {
        subCatLabel = 'Bailable Warrant (जमानती वारंट)';
        titlePrefix = 'BW (जमानती वारंट)';
      } else {
        subCatLabel = 'Summons (समंस)';
        titlePrefix = 'Summons (समंस)';
      }

      final caseNum = _caseNumberCtrl.text.trim();
      final accused = _accusedNameCtrl.text.trim();
      final court = _courtNameCtrl.text.trim();
      final notes = _notesCtrl.text.trim();

      String caseStatus;
      if (_executionStatus == 'executed') {
        caseStatus = 'Disposal';
      } else if (_executionStatus == 'unserved') {
        caseStatus = 'Closed';
      } else {
        caseStatus = 'Pending';
      }

      final recordId = 'sam_${DateTime.now().millisecondsSinceEpoch}';

      final Map<String, dynamic> caseData = {
        'id': recordId,
        'case_number': caseNum,
        'module_key': 'sam_warrant',
        'title': '$titlePrefix - $caseNum ($accused)',
        'sub_category': subCatLabel,
        'accused': accused,
        'complainant': court.isNotEmpty ? court : 'Court',
        'incident_date': _selectedDate.toIso8601String(),
        'status': caseStatus,
        'station_name': stationName,
        'assigned_officer': officerName,
        'assigned_officer_uid': officerUid,
        'created_by': officerUid,
        'description': notes,
        'extra_fields': {
          'warrant_type': _processType,
          'execution_status': _executionStatus,
          'warrant_number': caseNum,
          'accused_name': accused,
          'court_name': court,
          'issue_date': _selectedDate.toIso8601String(),
          'notes': notes,
        },
      };

      // 1. Save to Backend Database API
      final res = await BackendCaseService().createCase(caseData);

      // 2. Add to Local Provider Cache
      if (mounted) {
        try {
          final localRec = ModuleRecord.fromMap(res ?? caseData, recordId);
          context.read<SamWarrantProvider>().addRecord(localRec);
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Warrant case "$caseNum" registered successfully!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save warrant: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentStation = auth.stationName.isNotEmpty ? auth.stationName : 'ALL';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.navyDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Register Summons / Warrant (समंस वारंट नोंदणी)',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Station: $currentStation • Data links automatically to monthly report',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Process Type Selector
                      _buildSectionLabel('1. Process Type (प्रकार) *'),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildChoiceChip(
                            label: 'Summons (समंस)',
                            value: 'summons',
                            current: _processType,
                            onSelected: (val) => setState(() => _processType = val),
                          ),
                          _buildChoiceChip(
                            label: 'NBW (पकड वारंट)',
                            value: 'nbw',
                            current: _processType,
                            onSelected: (val) => setState(() => _processType = val),
                          ),
                          _buildChoiceChip(
                            label: 'BW (जमानती वारंट)',
                            value: 'bw',
                            current: _processType,
                            onSelected: (val) => setState(() => _processType = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Case / Warrant Number
                      _buildSectionLabel('2. Warrant / Case Number (वारंट / समंस क्र.) *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _caseNumberCtrl,
                        decoration: _inputDecoration(
                          hint: 'e.g. SAM/2026/01 or WAR/89/2026',
                          icon: Icons.tag_rounded,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Case Number is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Accused / Subject Name
                      _buildSectionLabel('3. Accused / Subject Name (व्यक्ती / आरोपीचे नाव) *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _accusedNameCtrl,
                        decoration: _inputDecoration(
                          hint: 'Enter full name of subject',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Court / Issuing Authority & Date Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel('4. Court / Authority (न्यायालय)'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _courtNameCtrl,
                                  decoration: _inputDecoration(
                                    hint: 'e.g. JMFC Court',
                                    icon: Icons.account_balance_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel('5. Issue Date (जारी दिनांक) *'),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 13),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.lightBorder),
                                      borderRadius: BorderRadius.circular(8),
                                      color: const Color(0xFFF8FAFC),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded,
                                            size: 16, color: AppColors.navyMid),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            DateFormat('dd MMM yyyy').format(_selectedDate),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.navyDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Execution Status
                      _buildSectionLabel('6. Execution Status (तामील स्थिती) *'),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildChoiceChip(
                            label: 'Pending (अखेर / प्रलंबित)',
                            value: 'pending',
                            current: _executionStatus,
                            color: Colors.amber.shade800,
                            onSelected: (val) =>
                                setState(() => _executionStatus = val),
                          ),
                          _buildChoiceChip(
                            label: 'Executed (तामील)',
                            value: 'executed',
                            current: _executionStatus,
                            color: AppColors.successGreen,
                            onSelected: (val) =>
                                setState(() => _executionStatus = val),
                          ),
                          _buildChoiceChip(
                            label: 'Unserved (अदम)',
                            value: 'unserved',
                            current: _executionStatus,
                            color: AppColors.dangerRed,
                            onSelected: (val) =>
                                setState(() => _executionStatus = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notes / Description
                      _buildSectionLabel('7. Description / Remarks (टिप्पणी)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: _inputDecoration(
                          hint: 'Additional notes or address...',
                          icon: Icons.notes_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightSubText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyMid,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _isSubmitting ? 'Saving...' : 'Register Warrant',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.navyDark,
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required String value,
    required String current,
    required ValueChanged<String> onSelected,
    Color? color,
  }) {
    final isSelected = value == current;
    final activeColor = color ?? AppColors.navyMid;

    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.navyDark,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: activeColor,
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? activeColor : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
      prefixIcon: Icon(icon, size: 18, color: AppColors.navyMid),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.navyMid, width: 1.5),
      ),
    );
  }
}
