// lib/modules/licence/widgets/licence_add_edit_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/base_record.dart';
import '../constants/licence_noc_types.dart';
import '../providers/licence_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';

class LicenceAddEditDialog extends StatefulWidget {
  final ModuleRecord? existingRecord;

  const LicenceAddEditDialog({super.key, this.existingRecord});

  static Future<void> show(
    BuildContext context, {
    ModuleRecord? existingRecord,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LicenceAddEditDialog(existingRecord: existingRecord),
    );
  }

  @override
  State<LicenceAddEditDialog> createState() => _LicenceAddEditDialogState();
}

class _LicenceAddEditDialogState extends State<LicenceAddEditDialog> {
  final _formKey = GlobalKey<FormState>();

  final _applicantNameCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _licenceTypeCtrl = TextEditingController();
  final _otherDetailsCtrl = TextEditingController();

  String? _selectedLicenceType;
  late DateTime _receivedDate;
  String? _status;
  bool _isSaving = false;

  LicenceNocOption? get _selectedLicenceOption =>
      findLicenceNocOption(_selectedLicenceType);

  @override
  void initState() {
    super.initState();
    final r = widget.existingRecord;
    _receivedDate = r?.incidentDate ?? DateTime.now();

    if (r != null) {
      _applicantNameCtrl.text = (r.extraFields['applicant_name'] ??
              (r.complainant != 'Licence Authority' ? r.complainant : ''))
          .toString();
      _businessNameCtrl.text = (r.extraFields['business_name'] ??
              (r.accused != 'Licence Applicant' ? r.accused : ''))
          .toString();

      final rawType = (r.extraFields['licence_type'] ??
              (r.title != 'Licence Verification' ? r.title : ''))
          .toString()
          .trim();

      final matched = findLicenceNocOption(rawType);
      if (matched != null) {
        _selectedLicenceType = matched.displayName;
        _licenceTypeCtrl.text = matched.displayName;
        if ((matched.number == 25 || matched.number == 38) &&
            rawType.contains(' - ')) {
          _otherDetailsCtrl.text =
              rawType.split(' - ').skip(1).join(' - ').trim();
        }
      } else if (rawType.isNotEmpty) {
        _selectedLicenceType = rawType;
        _licenceTypeCtrl.text = rawType;
      }

      if (LicenceProvider.isApprovedRecord(r)) {
        _status = LicenceProvider.statusApproved;
      } else if (LicenceProvider.isRejectedRecord(r)) {
        _status = LicenceProvider.statusRejected;
      } else if (LicenceProvider.isReturnedRecord(r)) {
        _status = LicenceProvider.statusReturned;
      } else {
        _status = null; // Not approved, rejected, returned -> Pending
      }
    } else {
      _status = null; // New case -> Pending
    }
  }

  @override
  void dispose() {
    _applicantNameCtrl.dispose();
    _businessNameCtrl.dispose();
    _licenceTypeCtrl.dispose();
    _otherDetailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _receivedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final isEdit = widget.existingRecord != null;
      final provider = context.read<LicenceProvider>();

      final dateCode = DateFormat('yyMMdd').format(_receivedDate);
      final randSuffix = (DateTime.now().millisecondsSinceEpoch % 1000)
          .toString()
          .padLeft(3, '0');
      final fileNo = isEdit && widget.existingRecord!.caseNumber.isNotEmpty
          ? widget.existingRecord!.caseNumber
          : 'LIC-$dateCode-$randSuffix';

      final applicantName = _applicantNameCtrl.text.trim();
      final businessName = _businessNameCtrl.text.trim();

      String licenceType =
          (_selectedLicenceType ?? _licenceTypeCtrl.text).trim();
      final matchedOpt = findLicenceNocOption(licenceType);
      if ((matchedOpt?.number == 25 || matchedOpt?.number == 38) &&
          _otherDetailsCtrl.text.trim().isNotEmpty) {
        licenceType = '$licenceType - ${_otherDetailsCtrl.text.trim()}';
      }

      final statusToSave = (_status == LicenceProvider.statusApproved ||
              _status == LicenceProvider.statusRejected ||
              _status == LicenceProvider.statusReturned)
          ? _status!
          : LicenceProvider.statusPending;

      final extraFields = <String, dynamic>{
        if (isEdit) ...widget.existingRecord!.extraFields,
        'applicant_name': applicantName,
        'business_name': businessName,
        'licence_type': licenceType,
        'received_date': _receivedDate.toIso8601String(),
        'licence_number': fileNo,
        'licence_status': statusToSave,
        'status_updated_at': DateTime.now().toIso8601String(),
      };

      final record = ModuleRecord(
        id: isEdit ? widget.existingRecord!.id : const Uuid().v4(),
        moduleKey: 'licence',
        title: licenceType.isNotEmpty ? licenceType : 'Licence Verification',
        caseNumber: fileNo,
        description: statusToSave,
        complainant:
            applicantName.isNotEmpty ? applicantName : 'Licence Applicant',
        accused: businessName.isNotEmpty ? businessName : 'Business / Entity',
        location: '',
        incidentDate: _receivedDate,
        priority: 'Normal',
        status: statusToSave,
        assignedOfficer: '',
        subCategory:
            licenceType.isNotEmpty ? licenceType : 'Licence Verification',
        extraFields: extraFields,
        createdAt: isEdit ? widget.existingRecord!.createdAt : DateTime.now(),
      );

      if (isEdit) {
        await provider.updateRecord(record);
      } else {
        await provider.addRecord(record);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.navyDark,
            content: Text(
              isEdit
                  ? TranslationHelper.translate(
                      context, 'Licence record updated successfully')
                  : TranslationHelper.translate(
                      context, 'Licence record saved successfully'),
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
    final isEdit = widget.existingRecord != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_ind_rounded,
                        color: Color(0xFF7C3AED),
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
                                    context, 'Edit Licence / NOC Record')
                                : TranslationHelper.translate(
                                    context, 'Add Licence / NOC Record'),
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyDark,
                            ),
                          ),
                          Text(
                            TranslationHelper.translate(
                              context,
                              'Fill applicant and licence verification details',
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

                // 1. Applicant Name
                _buildFieldLabel(context, 'Applicant Name'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _applicantNameCtrl,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: _inputDecoration(
                    hint: TranslationHelper.translate(
                        context, 'Enter full name of applicant'),
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Business Name
                _buildFieldLabel(context, 'Business Name'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _businessNameCtrl,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: _inputDecoration(
                    hint: TranslationHelper.translate(
                        context, 'Enter business / shop / firm name'),
                    prefixIcon: Icons.storefront_outlined,
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Licence / NOC Type
                _buildFieldLabel(context, 'Licence / NOC Type'),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Autocomplete<LicenceNocOption>(
                      initialValue: TextEditingValue(
                        text: _selectedLicenceType ?? _licenceTypeCtrl.text,
                      ),
                      displayStringForOption: (opt) => opt.displayName,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final query =
                            textEditingValue.text.trim().toLowerCase();
                        if (query.isEmpty) {
                          return kLicenceNocOptions;
                        }
                        return kLicenceNocOptions.where((opt) {
                          return opt.name.toLowerCase().contains(query);
                        });
                      },
                      onSelected: (LicenceNocOption selection) {
                        setState(() {
                          _selectedLicenceType = selection.displayName;
                          _licenceTypeCtrl.text = selection.displayName;
                        });
                      },
                      fieldViewBuilder: (
                        context,
                        fieldTextController,
                        focusNode,
                        onFieldSubmitted,
                      ) {
                        return TextFormField(
                          controller: fieldTextController,
                          focusNode: focusNode,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.navyDark),
                          decoration: _inputDecoration(
                            hint: TranslationHelper.translate(
                              context,
                              'Type directly or select Licence / NOC type',
                            ),
                            prefixIcon: Icons.category_outlined,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (fieldTextController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear_rounded,
                                        size: 16),
                                    tooltip: TranslationHelper.translate(
                                        context, 'Clear'),
                                    onPressed: () {
                                      fieldTextController.clear();
                                      setState(() {
                                        _selectedLicenceType = null;
                                        _licenceTypeCtrl.clear();
                                        _otherDetailsCtrl.clear();
                                      });
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_drop_down,
                                      color: AppColors.lightSubText),
                                  onPressed: () {
                                    if (!focusNode.hasFocus) {
                                      focusNode.requestFocus();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          onChanged: (text) {
                            setState(() {
                              _selectedLicenceType = text.trim();
                              _licenceTypeCtrl.text = text.trim();
                            });
                          },
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                            clipBehavior: Clip.antiAlias,
                            child: Container(
                              width: constraints.maxWidth,
                              constraints: const BoxConstraints(maxHeight: 280),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                shrinkWrap: true,
                                itemCount: options.length,
                                separatorBuilder: (_, __) => const Divider(
                                    height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (ctx, index) {
                                  final opt = options.elementAt(index);
                                  final isSelected =
                                      _selectedLicenceType == opt.displayName;

                                  return InkWell(
                                    onTap: () => onSelected(opt),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      color: isSelected
                                          ? const Color(0xFFEFF6FF)
                                          : Colors.transparent,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              opt.name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                                color: isSelected
                                                    ? const Color(0xFF1E40AF)
                                                    : AppColors.navyDark,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_rounded,
                                              size: 16,
                                              color: Color(0xFF3B82F6),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                if (_selectedLicenceOption?.number == 25 ||
                    _selectedLicenceOption?.number == 38) ...[
                  const SizedBox(height: 10),
                  _buildFieldLabel(
                      context, 'Specify Other Licence / NOC Details'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _otherDetailsCtrl,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: _inputDecoration(
                      hint: TranslationHelper.translate(
                          context, 'Enter specific details of Licence / NOC'),
                      prefixIcon: Icons.edit_note_rounded,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // 4. Received Date
                _buildFieldLabel(context, 'Received Date'),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 16, color: AppColors.navyMid),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_receivedDate),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.navyDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down,
                            color: AppColors.lightSubText),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 5. Verification completed
                _buildFieldLabel(context, 'Verification completed'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: (_status == LicenceProvider.statusApproved ||
                          _status == LicenceProvider.statusRejected ||
                          _status == LicenceProvider.statusReturned)
                      ? _status
                      : null,
                  isExpanded: true,
                  hint: Text(
                    TranslationHelper.translate(
                        context, 'Select (Leave empty for Pending)'),
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: AppColors.lightSubText.withValues(alpha: 0.7),
                    ),
                  ),
                  decoration: _inputDecoration(
                    prefixIcon: Icons.verified_user_outlined,
                    suffixIcon: _status != null
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            tooltip: TranslationHelper.translate(
                                context, 'Reset to Pending'),
                            onPressed: () => setState(() => _status = null),
                          )
                        : null,
                  ),
                  items: [
                    _buildStatusMenuItem(
                      value: LicenceProvider.statusApproved,
                      label: 'Approved',
                      color: const Color(0xFF047857),
                      icon: Icons.verified_rounded,
                    ),
                    _buildStatusMenuItem(
                      value: LicenceProvider.statusRejected,
                      label: 'Rejected',
                      color: const Color(0xFFDC2626),
                      icon: Icons.cancel_rounded,
                    ),
                    _buildStatusMenuItem(
                      value: LicenceProvider.statusReturned,
                      label: 'Returned',
                      color: const Color(0xFF7C3AED),
                      icon: Icons.assignment_return_rounded,
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _status = val);
                  },
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
                                    context.read<LicenceProvider>();
                                final nav = Navigator.of(context);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(TranslationHelper.translate(
                                        context, 'Delete Record?')),
                                    content: Text(TranslationHelper.translate(
                                        context,
                                        'Are you sure you want to delete this licence record?')),
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
                                  await provider
                                      .deleteRecord(widget.existingRecord!.id);
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
                          color: AppColors.lightSubText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              TranslationHelper.translate(
                                  context, 'Save Record'),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
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

  Widget _buildFieldLabel(BuildContext context, String label) {
    return Text(
      TranslationHelper.translate(context, label),
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.navyDark,
      ),
    );
  }

  DropdownMenuItem<String> _buildStatusMenuItem({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            TranslationHelper.translate(context, label),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 12.5,
        color: AppColors.lightSubText.withValues(alpha: 0.7),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 16, color: AppColors.navyMid)
          : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
      ),
    );
  }
}
