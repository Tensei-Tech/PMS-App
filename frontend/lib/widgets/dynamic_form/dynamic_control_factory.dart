// lib/widgets/dynamic_form/dynamic_control_factory.dart
// Factory widget producing standard, pixel-perfect police inputs based on DynamicFieldDef.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../person_select_or_custom_field.dart';
import 'dynamic_field_model.dart';

class DynamicControlFactory extends StatelessWidget {
  final DynamicFieldDef fieldDef;
  final TextEditingController? controller;
  final dynamic value;
  final ValueChanged<dynamic>? onChanged;
  final bool readOnly;
  final List<String>? accusedOptions;
  final TextEditingController? dateController;
  final ValueChanged<String>? onDateChanged;
  final List<String>? designationOptions;
  final List<String>? preventiveOptions;

  const DynamicControlFactory({
    super.key,
    required this.fieldDef,
    this.controller,
    this.value,
    this.onChanged,
    this.readOnly = false,
    this.accusedOptions,
    this.dateController,
    this.onDateChanged,
    this.designationOptions,
    this.preventiveOptions,
  });

  String get _displayLabel {
    final lower = fieldDef.fieldLabel.toLowerCase().trim();
    if (lower == 'crime spot full address' ||
        lower == 'spot full address' ||
        lower == 'crime spot address') {
      return 'Address';
    }
    return fieldDef.fieldLabel;
  }

  @override
  Widget build(BuildContext context) {
    if (fieldDef.fieldKey == 'arrested_person_name' ||
        fieldDef.fieldKey == 'seizure_person_name' ||
        fieldDef.fieldKey == 'relative_friend_name' ||
        fieldDef.fieldKey == 'discharged_accused_name' ||
        fieldDef.fieldKey == 'chargesheeted_accused_name') {
      return _buildPersonSelectField(context);
    }

    if (fieldDef.fieldKey == 'io_designation' ||
        fieldDef.fieldKey == 'registered_by_designation' ||
        (fieldDef.fieldLabel.toLowerCase().contains('designation') &&
            fieldDef.section?.toLowerCase().contains('officer') == true)) {
      return _buildDesignationDropdownField(context);
    }

    switch (fieldDef.fieldType) {
      case 'textarea':
        return _buildTextArea(context);
      case 'number':
        return _buildNumberField(context);
      case 'date':
        return _buildDateField(context);
      case 'datetime':
        return _buildDateTimeField(context);
      case 'dropdown':
        return _buildDropdownField(context);
      case 'checkbox':
        return _buildCheckbox(context);
      case 'chips':
        return _buildChipsSelector(context);
      case 'file':
        return _buildFileField(context);
      case 'text':
      default:
        return _buildTextField(context);
    }
  }

  Widget _buildFieldLayout(BuildContext context, Widget control,
      {bool forceStacked = false, bool isMultiline = false}) {
    if (forceStacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(context),
          control,
        ],
      );
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 340;
        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(context),
              control,
            ],
          );
        }
        return Row(
          crossAxisAlignment: isMultiline
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 130,
              child: Padding(
                padding: EdgeInsets.only(top: isMultiline ? 12 : 0),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        _displayLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (fieldDef.isRequired)
                      const Text(
                        ' *',
                        style: TextStyle(
                          color: AppColors.dangerRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (fieldDef.fieldSource == 'custom')
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.goldPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'SP',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyMid,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: control),
          ],
        );
      },
    );
  }

  Widget _buildPersonSelectField(BuildContext context) {
    return _buildFieldLayout(
      context,
      PersonSelectOrCustomField(
        label: fieldDef.fieldLabel,
        options: accusedOptions ?? const [],
        ctrl:
            controller ?? TextEditingController(text: value?.toString() ?? ''),
        isRequired: fieldDef.isRequired,
        decoration: _inputDecoration(hint: 'Select or Type New Name'),
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
        onChanged: (val) {
          if (controller != null) {
            controller!.text = val;
          }
          onChanged?.call(val);
        },
      ),
    );
  }

  Widget _buildLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _displayLabel,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark,
              ),
            ),
          ),
          if (fieldDef.isRequired)
            const Text(
              ' *',
              style: TextStyle(
                color: AppColors.dangerRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (fieldDef.fieldSource == 'custom')
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.goldPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'SPECIFIC',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyMid,
                ),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
      {String? hint, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint ?? 'Enter $_displayLabel',
      hintStyle:
          GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.navyMid, width: 1.5),
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    return _buildFieldLayout(
      context,
      TextFormField(
        controller: controller,
        readOnly: readOnly,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
        decoration: _inputDecoration(),
        validator: (v) {
          if (fieldDef.isRequired && (v == null || v.trim().isEmpty)) {
            return '${fieldDef.fieldLabel} is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTextArea(BuildContext context) {
    final hint = fieldDef.fieldLabel.toLowerCase().contains('address')
        ? 'Enter Address'
        : (fieldDef.fieldLabel.toLowerCase().contains('description')
            ? 'Enter Description'
            : 'Enter ${fieldDef.fieldLabel}');
    return _buildFieldLayout(
      context,
      TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: 3,
        minLines: 2,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
        decoration: _inputDecoration(hint: hint),
        validator: (v) {
          if (fieldDef.isRequired && (v == null || v.trim().isEmpty)) {
            return '${fieldDef.fieldLabel} is required';
          }
          return null;
        },
      ),
      forceStacked: false,
      isMultiline: true,
    );
  }

  Widget _buildNumberField(BuildContext context) {
    return _buildFieldLayout(
      context,
      TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
        decoration: _inputDecoration(),
        validator: (v) {
          if (fieldDef.isRequired && (v == null || v.trim().isEmpty)) {
            return '${fieldDef.fieldLabel} is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return _buildFieldLayout(
      context,
      TextFormField(
        controller: controller,
        readOnly: true,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
        decoration: _inputDecoration(
          hint: 'DD/MM/YYYY',
          suffixIcon: const Icon(Icons.calendar_today_rounded,
              size: 18, color: AppColors.navyMid),
        ),
        onTap: readOnly
            ? null
            : () async {
                final now = DateTime.now();
                DateTime initial = now;
                if (controller != null && controller!.text.trim().isNotEmpty) {
                  final parts = controller!.text.trim().split(RegExp(r'[-/]'));
                  if (parts.length >= 3) {
                    final d = int.tryParse(parts[0]) ?? now.day;
                    final m = int.tryParse(parts[1]) ?? now.month;
                    final y = int.tryParse(parts[2]) ?? now.year;
                    initial = DateTime(y, m, d);
                  }
                }
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  final formatted = DateFormat('dd/MM/yyyy').format(picked);
                  controller?.text = formatted;
                  onChanged?.call(formatted);
                }
              },
        validator: (v) {
          if (fieldDef.isRequired && (v == null || v.trim().isEmpty)) {
            return '${fieldDef.fieldLabel} is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateTimeField(BuildContext context) {
    return _buildFieldLayout(
      context,
      TextFormField(
        controller: controller,
        readOnly: true,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
        decoration: _inputDecoration(
          hint: 'DD/MM/YYYY HH:mm',
          suffixIcon: const Icon(Icons.access_time_rounded,
              size: 18, color: AppColors.navyMid),
        ),
        onTap: readOnly
            ? null
            : () async {
                final now = DateTime.now();
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: DateTime(1970),
                  lastDate: DateTime(2050),
                );
                if (pickedDate == null || !context.mounted) return;
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  final dt = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                  controller?.text = DateFormat('dd/MM/yyyy HH:mm').format(dt);
                  onChanged?.call(controller?.text);
                }
              },
        validator: (v) {
          if (fieldDef.isRequired && (v == null || v.trim().isEmpty)) {
            return '${fieldDef.fieldLabel} is required';
          }
          return null;
        },
      ),
    );
  }

  static const List<String> preventiveActionChoices = [
    '107 CrPC/126 BNSS',
    '109 CrPC/128 BNSS',
    '110 CrPC/129 BNSS',
    '151(3) CrPC/170 BNSS',
    '144 CrPC/163 BNSS',
    '149 CrPC/168 BNSS',
    '55 MPA',
    '56 MPA',
    '57 MPA',
    '122 MPA',
    '93 Prohibition Act',
  ];

  Widget _buildDesignationDropdownField(BuildContext context) {
    final rawOpts =
        (designationOptions != null && designationOptions!.isNotEmpty)
            ? designationOptions!
            : const [
                'Police Constable (PC)',
                'Naik Police Constable (NPC)',
                'Head Constable (HC)',
                'Assistant Sub Inspector (ASI)',
                'Police Sub Inspector (PSI)',
                'Assistant Police Inspector (API)',
                'Police Inspector (PI)',
                'Deputy Superintendent of Police (Dy. SP)',
                'Assistant Commissioner of Police (ACP)',
                'Superintendent of Police (SP)',
                'Deputy Commissioner of Police (DCP)',
                'Deputy Inspector General (DIG)',
                'Commissioner of Police (CP)',
                'Director General of Police (DGP)',
              ];

    final uniqueOpts = <String>[];
    final seen = <String>{};
    for (final opt in rawOpts) {
      final trimmed = opt.trim();
      if (trimmed.isNotEmpty && seen.add(trimmed.toLowerCase())) {
        uniqueOpts.add(trimmed);
      }
    }

    final currentVal =
        value?.toString().trim() ?? controller?.text.trim() ?? '';
    String? matchedVal;
    if (currentVal.isNotEmpty) {
      for (final opt in uniqueOpts) {
        if (opt.toLowerCase() == currentVal.toLowerCase()) {
          matchedVal = opt;
          break;
        }
      }
      if (matchedVal == null) {
        for (final opt in uniqueOpts) {
          if (opt.toLowerCase().contains(currentVal.toLowerCase()) ||
              currentVal.toLowerCase().contains(opt.toLowerCase())) {
            matchedVal = opt;
            break;
          }
        }
      }
      if (matchedVal == null) {
        matchedVal = currentVal;
        uniqueOpts.insert(0, currentVal);
      }
    }

    final items = <DropdownMenuItem<String>>[];
    final itemValuesSeen = <String>{};
    for (final opt in uniqueOpts) {
      if (itemValuesSeen.add(opt)) {
        items.add(
          DropdownMenuItem<String>(
            value: opt,
            child: Text(
              opt,
              overflow: TextOverflow.ellipsis,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: AppColors.navyDark),
            ),
          ),
        );
      }
    }

    final safeValue =
        (matchedVal != null && itemValuesSeen.contains(matchedVal))
            ? matchedVal
            : null;

    return _buildFieldLayout(
      context,
      DropdownButtonFormField<String>(
        key: ValueKey('desig_${fieldDef.fieldKey}_${safeValue ?? 'none'}'),
        initialValue: safeValue,
        isExpanded: true,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.navyDark),
        decoration: InputDecoration(
          hintText: 'Select Designation...',
          hintStyle: GoogleFonts.poppins(
              fontSize: 12.5, color: AppColors.lightSubText),
          filled: true,
          fillColor: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.navyMid, width: 1.5),
          ),
        ),
        items: items,
        onChanged: readOnly
            ? null
            : (newVal) {
                if (newVal != null) {
                  controller?.text = newVal;
                  onChanged?.call(newVal);
                }
              },
      ),
    );
  }

  Widget _buildDropdownField(BuildContext context) {
    final isPreventive =
        fieldDef.fieldKey.toLowerCase().contains('preventive') ||
            fieldDef.fieldLabel.toLowerCase().contains('preventive');
    final rawOpts = fieldDef.options.isNotEmpty
        ? fieldDef.options
        : (isPreventive
            ? (preventiveOptions != null && preventiveOptions!.isNotEmpty
                ? preventiveOptions!
                : preventiveActionChoices)
            : (fieldDef.fieldKey.toLowerCase().contains('gender')
                ? const ['Male', 'Female', 'Other']
                : const ['Yes', 'No', 'N/A']));

    final uniqueOpts = <String>[];
    final seen = <String>{};
    for (final opt in rawOpts) {
      final trimmed = opt.trim();
      if (trimmed.isNotEmpty && seen.add(trimmed.toLowerCase())) {
        uniqueOpts.add(trimmed);
      }
    }

    final currentVal = value?.toString().trim() ?? controller?.text.trim();
    String? validVal;
    if (currentVal != null && currentVal.isNotEmpty) {
      for (final opt in uniqueOpts) {
        if (opt.toLowerCase() == currentVal.toLowerCase()) {
          validVal = opt;
          break;
        }
      }
      if (validVal == null) {
        validVal = currentVal;
        uniqueOpts.insert(0, currentVal);
      }
    }

    final items = <DropdownMenuItem<String>>[];
    final itemValuesSeen = <String>{};
    for (final opt in uniqueOpts) {
      if (itemValuesSeen.add(opt)) {
        items.add(
          DropdownMenuItem<String>(
            value: opt,
            child: Text(
              opt,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
            ),
          ),
        );
      }
    }

    final safeValue = (validVal != null && itemValuesSeen.contains(validVal))
        ? validVal
        : null;

    return _buildFieldLayout(
      context,
      DropdownButtonFormField<String>(
        key: ValueKey('drop_${fieldDef.fieldKey}_${safeValue ?? 'none'}'),
        initialValue: safeValue,
        items: items,
        onChanged: readOnly
            ? null
            : (newVal) {
                if (controller != null && newVal != null) {
                  controller!.text = newVal;
                }
                onChanged?.call(newVal);
              },
        decoration: _inputDecoration(hint: 'Select ${fieldDef.fieldLabel}'),
        validator: (v) {
          if (fieldDef.isRequired && (v == null || v.isEmpty)) {
            return '${fieldDef.fieldLabel} is required';
          }
          return null;
        },
      ),
    );
  }

  bool get _isPanchanamaField {
    final k = fieldDef.fieldKey.toLowerCase();
    final l = fieldDef.fieldLabel.toLowerCase();
    final s = fieldDef.section?.toLowerCase() ?? '';
    return s.contains('panchnama') ||
        s.contains('panchanama') ||
        k.contains('panchanama') ||
        k.contains('panch') ||
        l.contains('panchanama');
  }

  Widget _buildCheckbox(BuildContext context) {
    final isChecked = (value is bool)
        ? value as bool
        : (controller?.text.toLowerCase() == 'true' ||
            controller?.text.toLowerCase() == 'yes');
    final isPanch = _isPanchanamaField;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isChecked
            ? AppColors.navyMid.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isChecked ? AppColors.navyMid : AppColors.lightBorder,
          width: isChecked ? 1.5 : 1.0,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;
          final checkboxRow = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: isChecked,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: AppColors.navyMid,
                onChanged: readOnly
                    ? null
                    : (newVal) {
                        final b = newVal ?? false;
                        controller?.text = b.toString();
                        if (b && isPanch) {
                          if (dateController != null &&
                              dateController!.text.trim().isEmpty) {
                            final nowStr = DateFormat('dd/MM/yyyy HH:mm')
                                .format(DateTime.now());
                            dateController!.text = nowStr;
                            onDateChanged?.call(nowStr);
                          }
                        }
                        onChanged?.call(b);
                      },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fieldDef.fieldLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isChecked ? AppColors.navyDark : AppColors.lightText,
                  ),
                ),
              ),
            ],
          );

          if (!isPanch || !isChecked) {
            return InkWell(
              onTap: readOnly
                  ? null
                  : () {
                      final b = !isChecked;
                      controller?.text = b.toString();
                      if (b && isPanch) {
                        if (dateController != null &&
                            dateController!.text.trim().isEmpty) {
                          final nowStr = DateFormat('dd/MM/yyyy HH:mm')
                              .format(DateTime.now());
                          dateController!.text = nowStr;
                          onDateChanged?.call(nowStr);
                        }
                      }
                      onChanged?.call(b);
                    },
              child: checkboxRow,
            );
          }

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                checkboxRow,
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: _buildPanchanamaDateTimeButton(context),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: readOnly
                      ? null
                      : () {
                          final b = !isChecked;
                          controller?.text = b.toString();
                          onChanged?.call(b);
                        },
                  child: checkboxRow,
                ),
              ),
              const SizedBox(width: 8),
              _buildPanchanamaDateTimeButton(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPanchanamaDateTimeButton(BuildContext context) {
    String dtText = dateController?.text.trim() ?? '';
    if (dtText.isEmpty) {
      dtText = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      if (dateController != null) {
        dateController!.text = dtText;
      }
      onDateChanged?.call(dtText);
    }

    return InkWell(
      onTap: readOnly
          ? null
          : () async {
              final now = DateTime.now();
              DateTime initial = now;
              if (dtText.isNotEmpty) {
                final match = RegExp(
                  r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})(?:\s+(\d{1,2}):(\d{2}))?',
                ).firstMatch(dtText);
                if (match != null) {
                  final d = int.tryParse(match.group(1)!) ?? now.day;
                  final m = int.tryParse(match.group(2)!) ?? now.month;
                  final y = int.tryParse(match.group(3)!) ?? now.year;
                  final hr = match.group(4) != null
                      ? int.tryParse(match.group(4)!) ?? 0
                      : 0;
                  final min = match.group(5) != null
                      ? int.tryParse(match.group(5)!) ?? 0
                      : 0;
                  initial = DateTime(y, m, d, hr, min);
                }
              }

              final pickedDate = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (pickedDate == null || !context.mounted) return;

              final pickedTime = await showTimePicker(
                context: context,
                initialTime:
                    TimeOfDay(hour: initial.hour, minute: initial.minute),
              );

              final finalDt = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime?.hour ?? initial.hour,
                pickedTime?.minute ?? initial.minute,
              );
              final formatted = DateFormat('dd/MM/yyyy HH:mm').format(finalDt);
              if (dateController != null) {
                dateController!.text = formatted;
              }
              onDateChanged?.call(formatted);
            },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.navyMid.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time_filled_rounded,
              size: 14,
              color: AppColors.navyMid,
            ),
            const SizedBox(width: 5),
            Text(
              'Date & Time: ',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.lightSubText,
              ),
            ),
            Text(
              dtText,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark,
              ),
            ),
            if (!readOnly) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.edit_calendar_rounded,
                size: 13,
                color: AppColors.navyMid,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChipsSelector(BuildContext context) {
    final opts = fieldDef.options.isNotEmpty
        ? fieldDef.options
        : ['Option 1', 'Option 2', 'Option 3'];
    final currentVal = value?.toString() ?? controller?.text ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: opts.map((opt) {
            final isSelected = opt == currentVal;
            return ChoiceChip(
              label: Text(
                opt,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.lightText,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.navyMid,
              backgroundColor: Colors.white,
              onSelected: readOnly
                  ? null
                  : (selected) {
                      final chosen = selected ? opt : '';
                      controller?.text = chosen;
                      onChanged?.call(chosen);
                    },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFileField(BuildContext context) {
    final filePath = controller?.text ?? value?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.navyMid.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.upload_file_rounded,
                    color: AppColors.navyMid, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  filePath.isNotEmpty ? filePath : 'No file attached',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: filePath.isNotEmpty
                        ? AppColors.lightText
                        : AppColors.lightSubText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!readOnly)
                TextButton.icon(
                  onPressed: () {
                    // For web/mobile demo file reference
                    controller?.text =
                        'attached_doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
                    onChanged?.call(controller?.text);
                  },
                  icon: const Icon(Icons.attach_file, size: 16),
                  label:
                      Text('Attach', style: GoogleFonts.poppins(fontSize: 12)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
