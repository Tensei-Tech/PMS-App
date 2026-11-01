// lib/modules/pvr/widgets/pvr_add_edit_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/base_record.dart';
import '../providers/pvr_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';

class PvrAddEditDialog extends StatefulWidget {
  final ModuleRecord? existingRecord;
  final List<ModuleRecord>? groupedRecords;
  final int? initialVerified;
  final int? initialPending;
  final PvrProvider? provider;

  const PvrAddEditDialog({
    super.key,
    this.existingRecord,
    this.groupedRecords,
    this.initialVerified,
    this.initialPending,
    this.provider,
  });

  static Future<void> show(
    BuildContext context, {
    ModuleRecord? existingRecord,
    List<ModuleRecord>? groupedRecords,
    int? initialVerified,
    int? initialPending,
    PvrProvider? provider,
  }) {
    PvrProvider? prov = provider;
    if (prov == null) {
      try {
        prov = context.read<PvrProvider>();
      } catch (_) {}
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final content = PvrAddEditDialog(
          existingRecord: existingRecord,
          groupedRecords: groupedRecords,
          initialVerified: initialVerified,
          initialPending: initialPending,
          provider: prov,
        );
        if (prov != null) {
          return ChangeNotifierProvider<PvrProvider>.value(
            value: prov,
            child: content,
          );
        }
        return content;
      },
    );
  }

  @override
  State<PvrAddEditDialog> createState() => _PvrAddEditDialogState();
}

class _PvrAddEditDialogState extends State<PvrAddEditDialog> {
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
      final v = PvrProvider.getRecordVerifiedCount(r);
      final p = PvrProvider.getRecordPendingCount(r);
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
      PvrProvider? provider = widget.provider;
      if (provider == null) {
        try {
          provider = context.read<PvrProvider>();
        } catch (_) {}
      }
      provider ??= PvrProvider();

      final verified = _verifiedCount;
      final pending = _pendingCount;
      final total = verified + pending;

      final String status;
      if (pending == 0 && verified > 0) {
        status = PvrProvider.statusVerified;
      } else if (verified > 0 && pending > 0) {
        status = PvrProvider.statusPartial;
      } else {
        status = PvrProvider.statusPending;
      }

      final dateCode = DateFormat('yyMMdd').format(_selectedDate);
      final randSuffix = (DateTime.now().millisecondsSinceEpoch % 1000)
          .toString()
          .padLeft(3, '0');

      if (widget.existingRecord != null) {
        final existing = widget.existingRecord!;
        final fileNo = existing.caseNumber.isNotEmpty
            ? existing.caseNumber
            : 'PVR-$dateCode-$randSuffix';

        final extraFields = <String, dynamic>{
          ...existing.extraFields,
          'file_number': fileNo,
          'applicant_name': 'PVR Verification ($total)',
          'verified_count': verified,
          'pending_count': pending,
          'total_count': total,
          'verification_status': status,
        };

        final updated = existing.copyWith(
          caseNumber: fileNo,
          incidentDate: _selectedDate,
          status: status,
          extraFields: extraFields,
        );
        await provider.updateRecord(updated);
      } else {
        final newId = const Uuid().v4();
        final fileNo = 'PVR-$dateCode-$randSuffix';

        final extraFields = <String, dynamic>{
          'file_number': fileNo,
          'applicant_name': 'PVR Verification ($total)',
          'verified_count': verified,
          'pending_count': pending,
          'total_count': total,
          'verification_status': status,
        };

        final newRecord = ModuleRecord(
          id: newId,
          moduleKey: 'pvr',
          title: 'PVR Verification',
          caseNumber: fileNo,
          description: '$verified Verified, $pending Pending',
          complainant: 'Police Department',
          accused: '',
          location: '',
          incidentDate: _selectedDate,
          priority: 'Normal',
          status: status,
          assignedOfficer: '',
          subCategory: 'PVR',
          extraFields: extraFields,
        );
        await provider.addRecord(newRecord);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingRecord != null
                  ? 'PVR counts updated successfully'
                  : 'PVR verification entry added successfully',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: AppColors.dangerRed,
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
    final isEditing = widget.existingRecord != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.navyMid.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fact_check_rounded,
                        color: AppColors.navyMid,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing
                                ? TranslationHelper.translate(
                                    context, 'Edit PVR Counts')
                                : TranslationHelper.translate(
                                    context, 'Add PVR Entry'),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyDark,
                            ),
                          ),
                          Text(
                            TranslationHelper.translate(
                              context,
                              'Record Total, Verified, and Pending counts',
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
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.lightSubText),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Date Picker field
                Text(
                  TranslationHelper.translate(context, 'Date'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.lightBorder),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: AppColors.navyMid,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('dd MMMM yyyy').format(_selectedDate),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.navyDark,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppColors.lightSubText,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Verified Count
                Text(
                  TranslationHelper.translate(context, 'Verified Count'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF047857),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _verifiedCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Enter verified count (e.g. 5)',
                    prefixIcon: const Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFF047857),
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.lightBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pending Count
                Text(
                  TranslationHelper.translate(context, 'Pending Count'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _pendingCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Enter pending count (e.g. 3)',
                    prefixIcon: const Icon(
                      Icons.pending_actions_rounded,
                      color: Color(0xFFB45309),
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.lightBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: Text(
                        TranslationHelper.translate(context, 'Cancel'),
                        style: GoogleFonts.poppins(
                          color: AppColors.lightSubText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyMid,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              TranslationHelper.translate(
                                  context, isEditing ? 'Update' : 'Save'),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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
}
