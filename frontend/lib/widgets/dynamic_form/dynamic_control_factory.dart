// ignore_for_file: deprecated_member_use
// lib/widgets/dynamic_form/dynamic_control_factory.dart
// Factory widget producing standard, pixel-perfect police inputs based on DynamicFieldDef.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/dynamic_options_service.dart';
import '../../theme/app_theme.dart';
import '../person_select_or_custom_field.dart';
import 'dynamic_field_model.dart';
import 'dynamic_repeating_group_widget.dart';
import '../repeating_cascading_charges_selector.dart';

class DynamicControlFactory extends StatelessWidget {
  final DynamicFieldDef fieldDef;
  final TextEditingController? controller;
  final dynamic value;
  final ValueChanged<dynamic>? onChanged;
  final bool readOnly;
  final List<String>? accusedOptions;
  final TextEditingController? dateController;
  final ValueChanged<String>? onDateChanged;
  final String? stationId;
  final List<DynamicFieldDef>? allFields;
  final ValueChanged<Map<String, dynamic>>? onMultiFieldChanged;

  /// Render a checkbox as a small inline tick + label (e.g. "Same as above")
  final bool compact;

  /// Live form values, used by options sources of the form
  /// `rows:<repeating_group_key>.<child_field_key>` (options built from the
  /// current rows of another repeating group, e.g. the Non applicant names).
  final Map<String, dynamic>? formValues;

  /// Maximum characters for text / textarea fields (null = no limit).
  final int? maxLength;
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
    this.stationId,
    this.allFields,
    this.onMultiFieldChanged,
    this.compact = false,
    this.formValues,
    this.maxLength,
    this.designationOptions,
    this.preventiveOptions,
  });

  static const String _rowsOptionsPrefix = 'rows:';

  /// Options for a `rows:<group>.<child>` source from the current form values.
  List<String> _rowsOptions(String source) {
    final spec = source.substring(_rowsOptionsPrefix.length);
    final dot = spec.indexOf('.');
    if (dot <= 0) return const [];
    final rows = formValues?[spec.substring(0, dot)];
    if (rows is! List) return const [];
    final child = spec.substring(dot + 1);
    final seen = <String>{};
    for (final r in rows) {
      if (r is Map) {
        final v = r[child]?.toString().trim() ?? '';
        if (v.isNotEmpty) seen.add(v);
      }
    }
    return seen.toList();
  }

  List<TextInputFormatter>? get _lengthFormatters =>
      maxLength != null && maxLength! > 0
          ? [LengthLimitingTextInputFormatter(maxLength)]
          : null;

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

    // Designation picker for officer designation fields that have no options
    // source of their own (those load their list from the database)
    if ((fieldDef.optionsSource ?? '').isEmpty &&
        (fieldDef.fieldKey == 'io_designation' ||
            fieldDef.fieldKey == 'registered_by_designation' ||
            (fieldDef.fieldLabel.toLowerCase().contains('designation') &&
                fieldDef.section?.toLowerCase().contains('officer') == true))) {
      return _buildDesignationDropdownField(context);
    }

    switch (fieldDef.fieldType) {
      case 'textarea':
        return _buildTextArea(context);
      case 'number':
        return _buildNumberField(context);
      case 'mobile':
        return _buildMobileField(context);
      case 'email':
        return _buildEmailField(context);
      case 'aadhaar':
        return _buildAadhaarField(context);
      case 'year':
        return _buildFieldLayout(
          context,
          YearPickerField(
            controller: controller,
            readOnly: readOnly,
            isRequired: fieldDef.isRequired,
            label: fieldDef.fieldLabel,
            onChanged: onChanged,
            decoration: _inputDecoration(hint: 'Select or type year (e.g. 03)')
                .copyWith(
                    suffixIcon: const Icon(Icons.arrow_drop_down_rounded)),
          ),
        );
      case 'date':
        return _buildDateField(context);
      case 'datetime':
        return _buildDateTimeField(context);
      case 'dropdown':
        return _buildDropdownField(context);
      case 'radio':
        return _buildRadioGroup(context);
      case 'checkbox':
        return _buildCheckbox(context);
      case 'chips':
        return _buildChipsSelector(context);
      case 'file':
        return _buildFileField(context);
      case 'multi_select':
        return _buildMultiSelectField(context);
      case 'repeating_group':
        return _buildRepeatingGroup(context);
      case 'charges':
        return _buildChargesField(context);
      case 'text':
      default:
        if (fieldDef.optionsSource != null &&
            (fieldDef.optionsSource!.contains('officer') ||
                fieldDef.fieldKey.contains('io_name'))) {
          return _buildOfficerPicker(context);
        }
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
          const SizedBox(height: 6),
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
              const SizedBox(height: 6),
              control,
            ],
          );
        }
        final labelWidth = constraints.maxWidth >= 400 ? 165.0 : 145.0;
        return Row(
          crossAxisAlignment: isMultiline
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding: EdgeInsets.only(top: isMultiline ? 10 : 0),
                child: Text.rich(
                  TextSpan(
                    text: _displayLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyDark,
                      height: 1.25,
                    ),
                    children: [
                      if (fieldDef.isRequired)
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(
                            color: AppColors.dangerRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
      child: Text.rich(
        TextSpan(
          text: _displayLabel,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.navyDark,
          ),
          children: [
            if (fieldDef.isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: AppColors.dangerRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
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
        onChanged: onChanged,
        inputFormatters: _lengthFormatters,
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

  /// Optional 10-digit mobile number; the error shows under the field while typing.
  Widget _buildMobileField(BuildContext context) {
    return _buildFieldLayout(
      context,
      TextFormField(
        controller: controller,
        readOnly: readOnly,
        onChanged: onChanged,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
        decoration: _inputDecoration(),
        validator: (v) {
          final value = v?.trim() ?? '';
          if (value.isEmpty) {
            return fieldDef.isRequired
                ? '${fieldDef.fieldLabel} is required'
                : null;
          }
          if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
            return '${fieldDef.fieldLabel} must be exactly 10 digits';
          }
          return null;
        },
      ),
    );
  }

  /// Optional e-mail address; checked only when something is typed.
  Widget _buildEmailField(BuildContext context) {
    return _buildFieldLayout(
      context,
      TextFormField(
        controller: controller,
        readOnly: readOnly,
        onChanged: onChanged,
        keyboardType: TextInputType.emailAddress,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
        decoration: _inputDecoration(),
        validator: (v) {
          final value = v?.trim() ?? '';
          if (value.isEmpty) {
            return fieldDef.isRequired
                ? '${fieldDef.fieldLabel} is required'
                : null;
          }
          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
            return 'Enter a valid ${fieldDef.fieldLabel}';
          }
          return null;
        },
      ),
    );
  }

  /// Optional 12-digit Aadhaar number, typed in groups of four
  /// (1234 5678 9012); the error shows under the field while typing.
  Widget _buildAadhaarField(BuildContext context) {
    return _buildFieldLayout(
      context,
      TextFormField(
        controller: controller,
        readOnly: readOnly,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(12),
          AadhaarGroupFormatter(),
        ],
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
        decoration: _inputDecoration(hint: 'XXXX XXXX XXXX'),
        validator: (v) {
          final digits = (v ?? '').replaceAll(' ', '');
          if (digits.isEmpty) {
            return fieldDef.isRequired
                ? '${fieldDef.fieldLabel} is required'
                : null;
          }
          if (digits.length != 12) {
            return '${fieldDef.fieldLabel} must be exactly 12 digits';
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
        onChanged: onChanged,
        inputFormatters: _lengthFormatters,
        maxLength: maxLength,
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
    // A `sum:` total is calculated from other fields, never typed in
    final isTotal = fieldDef.sumOf.isNotEmpty;
    // A digit limit from the field definition (options source `digits:<n>`,
    // e.g. ages): extra digits are refused with a message under the field
    final maxDigits = fieldDef.maxDigits;
    if (maxDigits != null && !isTotal) {
      final maxField = _MaxDigitsField(
        controller: controller,
        readOnly: readOnly,
        maxDigits: maxDigits,
        label: fieldDef.fieldLabel,
        isRequired: fieldDef.isRequired,
        onChanged: onChanged,
        decoration: _inputDecoration(),
      );
      return _buildFieldLayout(
        context,
        maxField,
      );
    }
    final numField = TextFormField(
      controller: controller,
      readOnly: readOnly || isTotal,
      canRequestFocus: !isTotal,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      style: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.lightText,
          fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal),
      decoration: isTotal
          ? _inputDecoration().copyWith(fillColor: const Color(0xFFF8FAFC))
          : _inputDecoration(),
      validator: (v) {
        final value = v?.trim() ?? '';
        if (value.isEmpty) {
          return fieldDef.isRequired
              ? '${fieldDef.fieldLabel} is required'
              : null;
        }
        return null;
      },
    );
    return _buildFieldLayout(
      context,
      numField,
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

  Widget _buildDesignationDropdownField(BuildContext context) {
    // Designations from the designations master (/api/master/designations/)
    final rawOpts = designationOptions ?? const <String>[];

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
    final source = fieldDef.optionsSource ?? '';
    final isPreventive =
        fieldDef.fieldKey.toLowerCase().contains('preventive') ||
            fieldDef.fieldLabel.toLowerCase().contains('preventive');
    if (source.isEmpty &&
        fieldDef.options.isEmpty &&
        isPreventive &&
        (preventiveOptions?.isNotEmpty ?? false)) {
      return _buildFieldLayout(
        context,
        _DynamicDropdownWidget(
          fieldDef: fieldDef.copyWith(options: preventiveOptions),
          controller: controller,
          value: value,
          onChanged: onChanged,
          readOnly: readOnly,
          stationId: stationId,
          decoration: _inputDecoration(hint: 'Select ${fieldDef.fieldLabel}'),
          labelWidget: const SizedBox.shrink(),
        ),
      );
    }
    if (source.startsWith(_rowsOptionsPrefix)) {
      final opts = _rowsOptions(source);
      // Options follow the other group's rows: rebuild when they change
      return _buildFieldLayout(
        context,
        _DynamicDropdownWidget(
          key: ValueKey('${fieldDef.fieldKey}|${opts.join('|')}'),
          fieldDef: fieldDef.copyWith(options: opts),
          controller: controller,
          value: value,
          onChanged: onChanged,
          readOnly: readOnly,
          stationId: stationId,
          decoration: _inputDecoration(hint: 'Select ${fieldDef.fieldLabel}'),
          labelWidget: const SizedBox.shrink(),
        ),
      );
    }
    return _buildFieldLayout(
      context,
      _DynamicDropdownWidget(
        fieldDef: fieldDef,
        controller: controller,
        value: value,
        onChanged: onChanged,
        readOnly: readOnly,
        stationId: stationId,
        decoration: _inputDecoration(hint: 'Select ${fieldDef.fieldLabel}'),
        labelWidget: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildRadioGroup(BuildContext context) {
    return _buildFieldLayout(
      context,
      _DynamicRadioWidget(
        fieldDef: fieldDef,
        controller: controller,
        value: value,
        onChanged: onChanged,
        readOnly: readOnly,
        stationId: stationId,
        labelWidget: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildMultiSelectField(BuildContext context) {
    return _DynamicMultiSelectWidget(
      fieldDef: fieldDef,
      controller: controller,
      value: value,
      onChanged: onChanged,
      readOnly: readOnly,
      labelWidget: _buildLabel(context),
      decoration: _inputDecoration(hint: 'Select ${fieldDef.fieldLabel}'),
    );
  }

  Widget _buildOfficerPicker(BuildContext context) {
    return _DynamicOfficerPickerWidget(
      fieldDef: fieldDef,
      controller: controller,
      value: value,
      onChanged: onChanged,
      readOnly: readOnly,
      stationId: stationId,
      labelWidget: _buildLabel(context),
      onMultiFieldChanged: onMultiFieldChanged,
    );
  }

  Widget _buildChargesField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
        RepeatingCascadingChargesSelector(
          initialCharges: value is List ? value as List : null,
          readOnly: readOnly,
          // Inside a repeating group row: exactly one Act / Section / Subsection
          maxCharges: fieldDef.parentFieldKey != null ? 1 : null,
          onChargesChanged: (charges) => onChanged?.call(charges),
        ),
      ],
    );
  }

  Widget _buildRepeatingGroup(BuildContext context) {
    var children = (allFields ?? [])
        .where((f) => f.parentFieldKey == fieldDef.fieldKey)
        .toList();
    final isMpdaCrime = fieldDef.fieldKey == 'mpda_crime_chart';
    final isMpdaGang = fieldDef.fieldKey == 'mpda_gang_members';
    final isMpdaAccused = fieldDef.fieldKey == 'mpda_accused';

    if (children.isEmpty && isMpdaAccused) {
      children = const [
        DynamicFieldDef(
          fieldDefId: 1601,
          fieldKey: 'mpda_accused_name',
          fieldLabel: 'Name',
          fieldSource: 'custom',
          fieldType: 'text',
          isRequired: true,
          displayOrder: 31,
          parentFieldKey: 'mpda_accused',
        ),
        DynamicFieldDef(
          fieldDefId: 1602,
          fieldKey: 'mpda_accused_age',
          fieldLabel: 'Age',
          fieldSource: 'custom',
          fieldType: 'number',
          isRequired: false,
          displayOrder: 32,
          parentFieldKey: 'mpda_accused',
          optionsSource: 'digits:3',
        ),
        DynamicFieldDef(
          fieldDefId: 1603,
          fieldKey: 'mpda_accused_gender',
          fieldLabel: 'Gender',
          fieldSource: 'custom',
          fieldType: 'dropdown',
          isRequired: false,
          displayOrder: 33,
          parentFieldKey: 'mpda_accused',
          optionsSource: '/api/options/gender/',
        ),
        DynamicFieldDef(
          fieldDefId: 1604,
          fieldKey: 'mpda_accused_mobile',
          fieldLabel: 'Mobile',
          fieldSource: 'custom',
          fieldType: 'mobile',
          isRequired: false,
          displayOrder: 34,
          parentFieldKey: 'mpda_accused',
        ),
        DynamicFieldDef(
          fieldDefId: 1605,
          fieldKey: 'mpda_accused_aadhaar',
          fieldLabel: 'Aadhaar',
          fieldSource: 'custom',
          fieldType: 'aadhaar',
          isRequired: false,
          displayOrder: 35,
          parentFieldKey: 'mpda_accused',
        ),
        DynamicFieldDef(
          fieldDefId: 1606,
          fieldKey: 'mpda_accused_address',
          fieldLabel: 'Address',
          fieldSource: 'custom',
          fieldType: 'textarea',
          isRequired: false,
          displayOrder: 36,
          parentFieldKey: 'mpda_accused',
        ),
        DynamicFieldDef(
          fieldDefId: 1607,
          fieldKey: 'mpda_accused_occupation',
          fieldLabel: 'Occupation',
          fieldSource: 'custom',
          fieldType: 'text',
          isRequired: false,
          displayOrder: 37,
          parentFieldKey: 'mpda_accused',
        ),
        DynamicFieldDef(
          fieldDefId: 1608,
          fieldKey: 'mpda_accused_pan',
          fieldLabel: 'PAN card',
          fieldSource: 'custom',
          fieldType: 'text',
          isRequired: false,
          displayOrder: 38,
          parentFieldKey: 'mpda_accused',
        ),
        DynamicFieldDef(
          fieldDefId: 1609,
          fieldKey: 'mpda_accused_cast',
          fieldLabel: 'Caste',
          fieldSource: 'custom',
          fieldType: 'text',
          isRequired: false,
          displayOrder: 39,
          parentFieldKey: 'mpda_accused',
        ),
        DynamicFieldDef(
          fieldDefId: 1610,
          fieldKey: 'mpda_accused_religion',
          fieldLabel: 'Religion',
          fieldSource: 'custom',
          fieldType: 'text',
          isRequired: false,
          displayOrder: 40,
          parentFieldKey: 'mpda_accused',
        ),
      ];
    } else if (children.isEmpty && isMpdaCrime) {
      children = const [
        DynamicFieldDef(
          fieldDefId: 1624,
          fieldKey: 'mpda_crime_type',
          fieldLabel: 'Crime Type',
          fieldSource: 'custom',
          fieldType: 'dropdown',
          isRequired: false,
          displayOrder: 291,
          parentFieldKey: 'mpda_crime_chart',
          optionsSource: '/api/options/mpda_crime_types/',
        ),
        DynamicFieldDef(
          fieldDefId: 1625,
          fieldKey: 'mpda_crime_cr_no',
          fieldLabel: 'CR No.',
          fieldSource: 'custom',
          fieldType: 'text',
          isRequired: false,
          displayOrder: 292,
          parentFieldKey: 'mpda_crime_chart',
        ),
        DynamicFieldDef(
          fieldDefId: 1626,
          fieldKey: 'mpda_crime_date',
          fieldLabel: 'Date',
          fieldSource: 'custom',
          fieldType: 'date',
          isRequired: false,
          displayOrder: 293,
          parentFieldKey: 'mpda_crime_chart',
        ),
        DynamicFieldDef(
          fieldDefId: 1627,
          fieldKey: 'mpda_crime_police_station',
          fieldLabel: 'Police Station',
          fieldSource: 'custom',
          fieldType: 'text',
          isRequired: false,
          displayOrder: 294,
          parentFieldKey: 'mpda_crime_chart',
        ),
        DynamicFieldDef(
          fieldDefId: 1628,
          fieldKey: 'mpda_crime_act_section',
          fieldLabel: 'Act / Section / Subsection',
          fieldSource: 'custom',
          fieldType: 'charges',
          isRequired: false,
          displayOrder: 295,
          parentFieldKey: 'mpda_crime_chart',
        ),
      ];
    } else if (children.isEmpty && isMpdaGang) {
      children = const [
        DynamicFieldDef(
          fieldDefId: 1616,
          fieldKey: 'mpda_gang_member_name',
          fieldLabel: 'Member Name',
          fieldSource: 'custom',
          fieldType: 'text',
          isRequired: false,
          displayOrder: 151,
          parentFieldKey: 'mpda_gang_members',
        ),
      ];
    }

    final optSource =
        fieldDef.optionsSource?.isNotEmpty == true && fieldDef.maxItems == null
            ? fieldDef.optionsSource
            : (isMpdaCrime ? '/api/options/mpda_crime_types/' : null);

    return DynamicRepeatingGroupWidget(
      fieldDef: fieldDef,
      childFields: children,
      value: value,
      onChanged: (rows) => onChanged?.call(rows),
      readOnly: readOnly,
      formValues: formValues,
      groupByFieldKey: isMpdaCrime ? 'mpda_crime_type' : null,
      groupOptionsSource: optSource,
      maxItems: fieldDef.maxItems,
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

    if (compact) {
      return InkWell(
        onTap: readOnly
            ? null
            : () {
                final b = !isChecked;
                controller?.text = b.toString();
                onChanged?.call(b);
              },
        borderRadius: BorderRadius.circular(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Checkbox(
                value: isChecked,
                activeColor: AppColors.navyMid,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: readOnly
                    ? null
                    : (newVal) {
                        final b = newVal ?? false;
                        controller?.text = b.toString();
                        onChanged?.call(b);
                      },
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                fieldDef.fieldLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navyDark,
                ),
              ),
            ),
          ],
        ),
      );
    }

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

class _DynamicDropdownWidget extends StatefulWidget {
  final DynamicFieldDef fieldDef;
  final TextEditingController? controller;
  final dynamic value;
  final ValueChanged<dynamic>? onChanged;
  final bool readOnly;
  final String? stationId;
  final InputDecoration decoration;
  final Widget labelWidget;

  const _DynamicDropdownWidget({
    super.key,
    required this.fieldDef,
    this.controller,
    this.value,
    this.onChanged,
    this.readOnly = false,
    this.stationId,
    required this.decoration,
    required this.labelWidget,
  });

  @override
  State<_DynamicDropdownWidget> createState() => _DynamicDropdownWidgetState();
}

class _DynamicDropdownWidgetState extends State<_DynamicDropdownWidget> {
  List<String> _options = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initOptions();
  }

  @override
  void didUpdateWidget(covariant _DynamicDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fieldDef.optionsSource != widget.fieldDef.optionsSource ||
        oldWidget.fieldDef.options != widget.fieldDef.options ||
        oldWidget.stationId != widget.stationId) {
      _initOptions();
    }
  }

  void _initOptions() {
    if (widget.fieldDef.options.isNotEmpty ||
        (widget.fieldDef.optionsSource ?? '')
            .startsWith(DynamicControlFactory._rowsOptionsPrefix)) {
      // `rows:` sources are built from the form itself; never fetched
      _options = widget.fieldDef.options;
      _isLoading = false;
      _error = null;
      return;
    }

    final src = widget.fieldDef.optionsSource;
    if (src != null && src.trim().isNotEmpty) {
      final cached = DynamicOptionsService()
          .getCachedOptions(src, stationId: widget.stationId);
      if (cached != null) {
        _options = cached;
        _isLoading = false;
        _error = null;
      } else {
        _isLoading = true;
        _error = null;
        DynamicOptionsService()
            .fetchOptions(src, stationId: widget.stationId)
            .then((opts) {
          if (mounted) {
            setState(() {
              _options = opts;
              _isLoading = false;
            });
          }
        }).catchError((err) {
          if (mounted) {
            setState(() {
              _error = 'Failed to load options';
              _isLoading = false;
            });
          }
        });
      }
    } else {
      _options = const [];
      _isLoading = false;
      _error = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentVal = widget.value?.toString() ?? widget.controller?.text;
    final validVal = _options.contains(currentVal) ? currentVal : null;

    if (_isLoading) {
      if (widget.labelWidget is SizedBox) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.navyMid),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.labelWidget,
          InputDecorator(
            decoration: widget.decoration.copyWith(
              suffixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.navyMid),
                ),
              ),
            ),
            child: Text(
              'Loading options...',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.lightSubText),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.labelWidget,
          InputDecorator(
            decoration: widget.decoration.copyWith(
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh,
                    size: 18, color: AppColors.dangerRed),
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  final src = widget.fieldDef.optionsSource;
                  if (src != null) {
                    DynamicOptionsService()
                        .fetchOptions(src,
                            stationId: widget.stationId, forceRefresh: true)
                        .then((opts) {
                      if (mounted) {
                        setState(() {
                          _options = opts;
                          _isLoading = false;
                        });
                      }
                    }).catchError((e) {
                      if (mounted) {
                        setState(() {
                          _error = 'Failed to load options';
                          _isLoading = false;
                        });
                      }
                    });
                  }
                },
              ),
            ),
            child: Text(
              _error!,
              style:
                  GoogleFonts.poppins(fontSize: 12, color: AppColors.dangerRed),
            ),
          ),
        ],
      );
    }

    final dropdownControl = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: validVal,
      items: _options.map((opt) {
        return DropdownMenuItem<String>(
          value: opt,
          child: Text(
            opt,
            overflow: TextOverflow.ellipsis,
            style:
                GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
          ),
        );
      }).toList(),
      onChanged: widget.readOnly
          ? null
          : (newVal) {
              if (widget.controller != null && newVal != null) {
                widget.controller!.text = newVal;
              }
              widget.onChanged?.call(newVal);
            },
      decoration: widget.decoration,
      validator: (v) {
        if (widget.fieldDef.isRequired && (v == null || v.isEmpty)) {
          return '${widget.fieldDef.fieldLabel} is required';
        }
        return null;
      },
    );

    if (widget.labelWidget is SizedBox) {
      return dropdownControl;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.labelWidget,
        dropdownControl,
      ],
    );
  }
}

class _DynamicRadioWidget extends StatefulWidget {
  final DynamicFieldDef fieldDef;
  final TextEditingController? controller;
  final dynamic value;
  final ValueChanged<dynamic>? onChanged;
  final bool readOnly;
  final String? stationId;
  final Widget labelWidget;

  const _DynamicRadioWidget({
    required this.fieldDef,
    this.controller,
    this.value,
    this.onChanged,
    this.readOnly = false,
    this.stationId,
    required this.labelWidget,
  });

  @override
  State<_DynamicRadioWidget> createState() => _DynamicRadioWidgetState();
}

class _DynamicRadioWidgetState extends State<_DynamicRadioWidget> {
  List<String> _options = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initOptions();
  }

  @override
  void didUpdateWidget(covariant _DynamicRadioWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fieldDef.optionsSource != widget.fieldDef.optionsSource ||
        oldWidget.fieldDef.options != widget.fieldDef.options ||
        oldWidget.stationId != widget.stationId) {
      _initOptions();
    }
  }

  void _initOptions() {
    if (widget.fieldDef.options.isNotEmpty) {
      _options = widget.fieldDef.options;
      _isLoading = false;
      _error = null;
      return;
    }

    final src = widget.fieldDef.optionsSource;
    if (src != null && src.trim().isNotEmpty) {
      final cached = DynamicOptionsService()
          .getCachedOptions(src, stationId: widget.stationId);
      if (cached != null) {
        _options = cached;
        _isLoading = false;
        _error = null;
      } else {
        _isLoading = true;
        _error = null;
        DynamicOptionsService()
            .fetchOptions(src, stationId: widget.stationId)
            .then((opts) {
          if (mounted) {
            setState(() {
              _options = opts;
              _isLoading = false;
            });
          }
        }).catchError((err) {
          if (mounted) {
            setState(() {
              _error = 'Failed to load options';
              _isLoading = false;
            });
          }
        });
      }
    } else {
      _options = const [];
      _isLoading = false;
      _error = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentVal =
        widget.value?.toString() ?? widget.controller?.text ?? '';

    if (_isLoading) {
      if (widget.labelWidget is SizedBox) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.navyMid),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.labelWidget,
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.navyMid),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      if (widget.labelWidget is SizedBox) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            _error!,
            style:
                GoogleFonts.poppins(fontSize: 12, color: AppColors.dangerRed),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.labelWidget,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              _error!,
              style:
                  GoogleFonts.poppins(fontSize: 12, color: AppColors.dangerRed),
            ),
          ),
        ],
      );
    }

    final radioWrap = Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: _options.map((opt) {
          final isSelected = opt.toLowerCase() == currentVal.toLowerCase();
          return InkWell(
            onTap: widget.readOnly
                ? null
                : () {
                    if (widget.controller != null) {
                      widget.controller!.text = opt;
                    }
                    widget.onChanged?.call(opt);
                  },
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.navyMid.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected ? AppColors.navyMid : AppColors.lightBorder,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<String>(
                    value: opt,
                    groupValue: currentVal,
                    activeColor: AppColors.navyMid,
                    onChanged: widget.readOnly
                        ? null
                        : (val) {
                            if (val != null) {
                              if (widget.controller != null) {
                                widget.controller!.text = val;
                              }
                              widget.onChanged?.call(val);
                            }
                          },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    opt,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color:
                          isSelected ? AppColors.navyDark : AppColors.lightText,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (widget.labelWidget is SizedBox) {
      return radioWrap;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.labelWidget,
        radioWrap,
      ],
    );
  }
}

class _DynamicMultiSelectWidget extends StatefulWidget {
  final DynamicFieldDef fieldDef;
  final TextEditingController? controller;
  final dynamic value;
  final ValueChanged<dynamic>? onChanged;
  final bool readOnly;
  final Widget labelWidget;
  final InputDecoration decoration;

  const _DynamicMultiSelectWidget({
    required this.fieldDef,
    this.controller,
    this.value,
    this.onChanged,
    this.readOnly = false,
    required this.labelWidget,
    required this.decoration,
  });

  @override
  State<_DynamicMultiSelectWidget> createState() =>
      _DynamicMultiSelectWidgetState();
}

class _DynamicMultiSelectWidgetState extends State<_DynamicMultiSelectWidget> {
  List<String> _options = [];
  List<String> _selected = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initSelected();
    _initOptions();
  }

  @override
  void didUpdateWidget(covariant _DynamicMultiSelectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _initSelected();
    }
  }

  void _initSelected() {
    if (widget.value is List) {
      _selected =
          (widget.value as List).map((e) => e.toString().trim()).toList();
    } else if (widget.controller?.text.isNotEmpty == true) {
      final text = widget.controller!.text.trim();
      final cleaned = text.replaceAll(RegExp(r'^\[|\]$'), '');
      _selected = cleaned
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      _selected = [];
    }
  }

  void _initOptions() {
    if (widget.fieldDef.options.isNotEmpty) {
      _options = widget.fieldDef.options;
      return;
    }
    final src = widget.fieldDef.optionsSource;
    if (src != null && src.isNotEmpty) {
      final cached = DynamicOptionsService().getCachedOptions(src);
      if (cached != null) {
        _options = cached;
      } else {
        _isLoading = true;
        DynamicOptionsService().fetchOptions(src).then((opts) {
          if (mounted) {
            setState(() {
              _options = opts;
              _isLoading = false;
            });
          }
        }).catchError((_) {
          if (mounted) setState(() => _isLoading = false);
        });
      }
    }
  }

  void _setSelected(List<String> selected) {
    if (widget.readOnly) return;
    // Keep the options' display order regardless of tap order
    final ordered = [
      ..._options.where(selected.contains),
      ...selected.where((s) => !_options.contains(s)),
    ];
    setState(() => _selected = ordered);
    if (widget.controller != null) {
      widget.controller!.text = _selected.join(', ');
    }
    widget.onChanged?.call(List<String>.from(_selected));
  }

  Future<void> _openPicker() async {
    final temp = List<String>.from(_selected);
    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            widget.fieldDef.fieldLabel,
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              children: _options.map((opt) {
                return CheckboxListTile(
                  value: temp.contains(opt),
                  dense: true,
                  activeColor: AppColors.navyMid,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(opt,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.lightText)),
                  onChanged: (checked) => setDialogState(() {
                    if (checked == true) {
                      temp.add(opt);
                    } else {
                      temp.remove(opt);
                    }
                  }),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.navyMid),
              onPressed: () => Navigator.pop(ctx, temp),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
    if (result != null) _setSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = _selected.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.labelWidget,
        InkWell(
          onTap: widget.readOnly || _isLoading ? null : _openPicker,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            isEmpty: !hasValue,
            decoration: widget.decoration.copyWith(
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : const Icon(Icons.arrow_drop_down_rounded,
                      color: AppColors.navyMid),
            ),
            child: hasValue
                ? Text(
                    _selected.join(', '),
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.lightText),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _DynamicOfficerPickerWidget extends StatefulWidget {
  final DynamicFieldDef fieldDef;
  final TextEditingController? controller;
  final dynamic value;
  final ValueChanged<dynamic>? onChanged;
  final bool readOnly;
  final String? stationId;
  final Widget labelWidget;
  final ValueChanged<Map<String, dynamic>>? onMultiFieldChanged;

  const _DynamicOfficerPickerWidget({
    required this.fieldDef,
    this.controller,
    this.value,
    this.onChanged,
    this.readOnly = false,
    this.stationId,
    required this.labelWidget,
    this.onMultiFieldChanged,
  });

  @override
  State<_DynamicOfficerPickerWidget> createState() =>
      _DynamicOfficerPickerWidgetState();
}

class _DynamicOfficerPickerWidgetState
    extends State<_DynamicOfficerPickerWidget> {
  List<Map<String, dynamic>> _officers = [];
  bool _isLoading = false;
  late TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = widget.controller ??
        TextEditingController(text: widget.value?.toString() ?? '');
    _loadOfficers();
  }

  Future<void> _loadOfficers() async {
    final src = widget.fieldDef.optionsSource;
    if (src == null || src.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final opts = await DynamicOptionsService()
          .fetchOptions(src, stationId: widget.stationId);
      if (mounted) {
        setState(() {
          _officers = opts
              .map((name) => {
                    'name': name,
                    'label': name,
                    'designation': '',
                    'uid': '',
                  })
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onOfficerPicked(String officerName) {
    _textCtrl.text = officerName;
    widget.onChanged?.call(officerName);
    final match = _officers.where((o) => o['name'] == officerName).firstOrNull;
    final desig = match?['designation']?.toString().trim();
    String? postToFill;
    if (desig != null && desig.isNotEmpty) {
      final postOptions = DynamicOptionsService()
              .getCachedOptions('/api/options/designations/') ??
          DynamicOptionsService()
              .getCachedOptions('/api/master/designations/') ??
          [];
      if (postOptions.isEmpty ||
          postOptions
              .any((opt) => opt.trim().toLowerCase() == desig.toLowerCase())) {
        postToFill = desig;
      }
    }

    widget.onMultiFieldChanged?.call({
      widget.fieldDef.fieldKey: officerName,
      'mpda_io_name': officerName,
      if (postToFill != null) 'mpda_io_post': postToFill,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.labelWidget,
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _textCtrl.text),
          optionsBuilder: (TextEditingValue val) {
            if (val.text.isEmpty) {
              return _officers.map((o) => o['name'].toString());
            }
            return _officers.map((o) => o['name'].toString()).where(
                (name) => name.toLowerCase().contains(val.text.toLowerCase()));
          },
          onSelected: (selection) => _onOfficerPicked(selection),
          fieldViewBuilder: (context, fieldTextEditingController, focusNode,
              onFieldSubmitted) {
            return TextFormField(
              controller: fieldTextEditingController,
              focusNode: focusNode,
              readOnly: widget.readOnly,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
              decoration: InputDecoration(
                filled: true,
                fillColor:
                    widget.readOnly ? const Color(0xFFF8FAFC) : Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  borderSide:
                      const BorderSide(color: AppColors.navyMid, width: 1.5),
                ),
                hintText: null,
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.lightSubText),
                suffixIcon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : const Icon(Icons.person_search_rounded,
                        size: 20, color: AppColors.navyMid),
              ),
              onChanged: (text) {
                _textCtrl.text = text;
                widget.onChanged?.call(text);
                widget.onMultiFieldChanged?.call({
                  widget.fieldDef.fieldKey: text,
                  'mpda_io_name': text,
                });
              },
            );
          },
        ),
      ],
    );
  }
}

/// Shows digits in groups of four: 123456789012 -> 1234 5678 9012.
class AadhaarGroupFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Digits-only field that stops at [maxDigits]; trying to type more shows
/// "<label> can be at most N digits" under the field until the next edit.
class _MaxDigitsField extends StatefulWidget {
  final TextEditingController? controller;
  final bool readOnly;
  final int maxDigits;
  final String label;
  final bool isRequired;
  final ValueChanged<String>? onChanged;
  final InputDecoration decoration;

  const _MaxDigitsField({
    required this.controller,
    required this.readOnly,
    required this.maxDigits,
    required this.label,
    required this.isRequired,
    required this.onChanged,
    required this.decoration,
  });

  @override
  State<_MaxDigitsField> createState() => _MaxDigitsFieldState();
}

class _MaxDigitsFieldState extends State<_MaxDigitsField> {
  bool _tooLong = false;

  void _setTooLong(bool value) {
    if (_tooLong != value) setState(() => _tooLong = value);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      readOnly: widget.readOnly,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        TextInputFormatter.withFunction((oldValue, newValue) {
          final tooLong = newValue.text.length > widget.maxDigits;
          _setTooLong(tooLong);
          return tooLong ? oldValue : newValue;
        }),
      ],
      onChanged: widget.onChanged,
      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
      decoration: widget.decoration.copyWith(
        errorText: _tooLong
            ? '${widget.label} can be at most ${widget.maxDigits} digits'
            : null,
      ),
      validator: (v) {
        if ((v?.trim() ?? '').isEmpty && widget.isRequired) {
          return '${widget.label} is required';
        }
        return null;
      },
    );
  }
}

/// Year from a dropdown of 2001-2100 that can also be typed into. A short
/// year means 20xx: typing "03" lists 2003 first and becomes 2003 when the
/// field is left ("00" means 2100).
class YearPickerField extends StatefulWidget {
  static const int firstYear = 2001;
  static const int lastYear = 2100;

  final TextEditingController? controller;
  final bool readOnly;
  final bool isRequired;
  final String label;
  final Function(dynamic)? onChanged;
  final InputDecoration decoration;

  const YearPickerField({
    super.key,
    this.controller,
    this.readOnly = false,
    this.isRequired = false,
    required this.label,
    this.onChanged,
    required this.decoration,
  });

  /// '3' / '03' -> '2003', '00' -> '2100'; anything else is returned as is.
  static String expand(String text) {
    final t = text.trim();
    if (!RegExp(r'^[0-9]{1,2}$').hasMatch(t)) return t;
    final n = int.parse(t);
    return '${n == 0 ? lastYear : 2000 + n}';
  }

  /// Years matching what is typed: a short entry matches the last two digits
  /// ("0" -> 2001-2009, 2100; "03" -> 2003), a longer one the start.
  static List<String> matches(String text) {
    final q = text.trim();
    final years = [for (var y = firstYear; y <= lastYear; y++) '$y'];
    if (q.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(q)) return years;
    if (q.length <= 2) {
      return years.where((y) => y.substring(2).startsWith(q)).toList();
    }
    return years.where((y) => y.startsWith(q)).toList();
  }

  @override
  State<YearPickerField> createState() => _YearPickerFieldState();
}

class _YearPickerFieldState extends State<YearPickerField> {
  late final TextEditingController _ctrl =
      widget.controller ?? TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  // Leaving the field turns a short year into the full one
  void _onFocusChange() {
    if (!_focus.hasFocus) _expand();
  }

  void _expand() {
    final full = YearPickerField.expand(_ctrl.text);
    if (full != _ctrl.text) {
      _ctrl.text = full;
      widget.onChanged?.call(full);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: _ctrl,
      focusNode: _focus,
      optionsBuilder: (value) =>
          widget.readOnly ? const [] : YearPickerField.matches(value.text),
      onSelected: (year) => widget.onChanged?.call(year),
      fieldViewBuilder: (context, ctrl, focus, onSubmitted) => TextFormField(
        controller: ctrl,
        focusNode: focus,
        readOnly: widget.readOnly,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
        decoration: widget.decoration,
        onChanged: widget.onChanged,
        onFieldSubmitted: (_) {
          _expand();
          onSubmitted();
        },
        validator: (v) {
          final year = YearPickerField.expand(v ?? '');
          if (year.isEmpty) {
            return widget.isRequired ? '${widget.label} is required' : null;
          }
          final n = int.tryParse(year);
          if (n == null ||
              n < YearPickerField.firstYear ||
              n > YearPickerField.lastYear) {
            return 'Select a year from ${YearPickerField.firstYear} to ${YearPickerField.lastYear}';
          }
          return null;
        },
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 220),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, i) {
                final year = options.elementAt(i);
                return InkWell(
                  onTap: () => onSelected(year),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Text(year,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.navyDark)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
