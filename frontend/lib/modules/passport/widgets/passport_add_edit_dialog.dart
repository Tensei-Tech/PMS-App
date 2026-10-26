// lib/modules/passport/widgets/passport_add_edit_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/base_record.dart';
import '../providers/passport_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';

class PassportAddEditDialog extends StatefulWidget {
  final ModuleRecord? existingRecord;
  final List<ModuleRecord>? groupedRecords;
  final int? initialVerified;
  final int? initialPending;

  const PassportAddEditDialog({
    super.key,
    this.existingRecord,
    this.groupedRecords,
    this.initialVerified,
    this.initialPending,
  });

  static Future<void> show(
    BuildContext context, {
    ModuleRecord? existingRecord,
    List<ModuleRecord>? groupedRecords,
    int? initialVerified,
    int? initialPending,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PassportAddEditDialog(
        existingRecord: existingRecord,
        groupedRecords: groupedRecords,
        initialVerified: initialVerified,
        initialPending: initialPending,
      ),
    );
  }

  @override
  State<PassportAddEditDialog> createState() => _PassportAddEditDialogState();
}

class _PassportAddEditDialogState extends State<PassportAddEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  final _verifiedCtrl = TextEditingController();
  final _pendingCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.existingRecord;
    _selectedDate = r?.incidentDate ?? DateTime.now();

    if (widget.initialVerified != null || widget.initialPending != null) {
      final v = widget.initialVerified ?? 0;
      final p = widget.initialPending ?? 0;
      _verifiedCtrl.text = v > 0 ? v.toString() : '';
      _pendingCtrl.text = p > 0 ? p.toString() : '';
    } else if (r != null) {
      final v = PassportProvider.getRecordVerifiedCount(r);
      final p = PassportProvider.getRecordPendingCount(r);
      _verifiedCtrl.text = v > 0 ? v.toString() : '';
      _pendingCtrl.text = p > 0 ? p.toString() : '';
    } else {
      _verifiedCtrl.text = '';
      _pendingCtrl.text = '';
    }
  }

  @override
  void dispose() {
    _verifiedCtrl.dispose();
    _pendingCtrl.dispose();
    super.dispose();
  }

  int get _verifiedCount => int.tryParse(_verifiedCtrl.text.trim()) ?? 0;
  int get _pendingCount => int.tryParse(_pendingCtrl.text.trim()) ?? 0;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final provider = context.read<PassportProvider>();

      final verified = _verifiedCount;
      final pending = _pendingCount;
      final total = verified + pending;

      // Handle full, partial (mixed), and pending states accurately
      final String status;
      if (pending == 0 && verified > 0) {
        status = PassportProvider.statusVerified;
      } else if (verified > 0 && pending > 0) {
        status = PassportProvider.statusPartial;
      } else {
        status = PassportProvider.statusPending;
      }

      final dateCode = DateFormat('yyMMdd').format(_selectedDate);
      final randSuffix = (DateTime.now().millisecondsSinceEpoch % 1000)
          .toString()
          .padLeft(3, '0');

      if (widget.existingRecord != null) {
        // Edit existing record only - never delete other same-day entries
        final existing = widget.existingRecord!;
        final fileNo = existing.caseNumber.isNotEmpty
            ? existing.caseNumber
            : 'PV-$dateCode-$randSuffix';

        final extraFields = <String, dynamic>{
          ...existing.extraFields,
          'file_number': fileNo,
          'applicant_name': 'Passport Verification ($total)',
          'verified_count': verified,
          'pending_count': pending,
          'total_count': total,
          'verification_status': status,
          'verification_date': _selectedDate.toIso8601String(),
        };

        final updatedRecord = existing.copyWith(
          incidentDate: _selectedDate,
          description: '$verified Verified, $pending Pending',
          accused: '',
          status: status,
          extraFields: extraFields,
        );
        await provider.updateRecord(updatedRecord);
      } else {
        // Add new record independently - never overwrite or delete same-day records
        final fileNo = 'PV-$dateCode-$randSuffix';
        final extraFields = <String, dynamic>{
          'file_number': fileNo,
          'applicant_name': 'Passport Verification ($total)',
          'verified_count': verified,
          'pending_count': pending,
          'total_count': total,
          'verification_status': status,
          'verification_date': _selectedDate.toIso8601String(),
        };

        final record = ModuleRecord(
          id: const Uuid().v4(),
          moduleKey: 'passport',
          title: 'Passport Verification',
          caseNumber: fileNo,
          description: '$verified Verified, $pending Pending',
          complainant: 'Passport Office',
          accused: '',
          location: '',
          incidentDate: _selectedDate,
          priority: 'Normal',
          status: status,
          assignedOfficer: '',
          subCategory: 'Passport Verification',
          extraFields: extraFields,
          createdAt: DateTime.now(),
        );
        await provider.addRecord(record);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.navyDark,
            content: Text(
              widget.existingRecord != null
                  ? TranslationHelper.translate(
                      context, 'Passport record updated successfully')
                  : TranslationHelper.translate(
                      context, 'Passport record saved successfully'),
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingRecord != null ||
        (widget.groupedRecords != null && widget.groupedRecords!.isNotEmpty);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.badge_rounded,
                        color: Color(0xFF1E40AF),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit
                                ? TranslationHelper.translate(
                                    context, 'Edit Passport Verification')
                                : TranslationHelper.translate(
                                    context, 'Passport Verification'),
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyDark,
                            ),
                          ),
                          Text(
                            TranslationHelper.translate(
                              context,
                              'Enter verified and pending counts',
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.lightSubText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.lightSubText),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 18),

                // 1. Date Field
                _buildDatePickerField(
                  label: TranslationHelper.translate(context, 'Date'),
                  date: _selectedDate,
                  onTap: _pickDate,
                  icon: Icons.calendar_today_rounded,
                ),
                const SizedBox(height: 16),

                // 2. Verified / Report Submitted
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationHelper.translate(
                          context, 'Verified / Report Submitted'),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _verifiedCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF047857),
                      ),
                      decoration: _inputDecoration(
                        hintText: TranslationHelper.translate(
                            context, 'Enter count (e.g. 5)'),
                        prefixIcon: Icons.verified_user_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. Pending
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationHelper.translate(context, 'Pending'),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _pendingCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD97706),
                      ),
                      decoration: _inputDecoration(
                        hintText: TranslationHelper.translate(
                            context, 'Enter count (e.g. 3)'),
                        prefixIcon: Icons.hourglass_top_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    if (isEdit)
                      IconButton(
                        tooltip: TranslationHelper.translate(context, 'Delete'),
                        onPressed: _isSaving
                            ? null
                            : () async {
                                final provider =
                                    context.read<PassportProvider>();
                                final nav = Navigator.of(context);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(TranslationHelper.translate(
                                        context, 'Delete Record?')),
                                    content: Text(TranslationHelper.translate(
                                        context,
                                        'Are you sure you want to delete this record?')),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text(TranslationHelper.translate(
                                            context, 'Cancel')),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.red.shade700,
                                            foregroundColor: Colors.white),
                                        child: Text(TranslationHelper.translate(
                                            context, 'Delete')),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && mounted) {
                                  if (widget.existingRecord != null) {
                                    try {
                                      await provider.deleteRecord(
                                          widget.existingRecord!.id);
                                    } catch (_) {}
                                  }
                                  nav.pop();
                                }
                              },
                        icon: Icon(Icons.delete_outline_rounded,
                            color: Colors.red.shade700),
                      ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        TranslationHelper.translate(context, 'Cancel'),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightSubText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyMid,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        isEdit
                            ? TranslationHelper.translate(context, 'Update')
                            : TranslationHelper.translate(context, 'Save'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? date,
    required VoidCallback? onTap,
    IconData? icon,
  }) {
    final enabled = onTap != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: enabled ? AppColors.navyDark : AppColors.lightSubText,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: enabled ? AppColors.navyMid : AppColors.lightSubText,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('dd MMM yyyy').format(date)
                        : 'Select date',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: date != null
                          ? AppColors.navyDark
                          : AppColors.lightSubText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        fontSize: 13,
        color: AppColors.lightSubText.withValues(alpha: 0.6),
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: AppColors.navyMid)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.navyMid, width: 1.8),
      ),
    );
  }
}
