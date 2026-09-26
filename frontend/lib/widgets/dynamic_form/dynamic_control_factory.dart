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

  const DynamicControlFactory({
    super.key,
    required this.fieldDef,
    this.controller,
    this.value,
    this.onChanged,
    this.readOnly = false,
    this.accusedOptions,
  });

  @override
  Widget build(BuildContext context) {
    if (fieldDef.fieldKey == 'arrested_person_name') {
      return _buildArrestedPersonField(context);
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

  Widget _buildArrestedPersonField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
        PersonSelectOrCustomField(
          label: fieldDef.fieldLabel,
          options: accusedOptions ?? const [],
          ctrl: controller ?? TextEditingController(text: value?.toString() ?? ''),
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
      ],
    );
  }

  Widget _buildLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              fieldDef.fieldLabel,
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

  InputDecoration _inputDecoration({String? hint, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint ?? 'Enter ${fieldDef.fieldLabel}',
      hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
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
      ],
    );
  }

  Widget _buildTextArea(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: 3,
          minLines: 2,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
          decoration: _inputDecoration(hint: 'Enter detailed notes...'),
          validator: (v) {
            if (fieldDef.isRequired && (v == null || v.trim().isEmpty)) {
              return '${fieldDef.fieldLabel} is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNumberField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
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
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
        TextFormField(
          controller: controller,
          readOnly: true,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
          decoration: _inputDecoration(
            hint: 'DD/MM/YYYY',
            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.navyMid),
          ),
          onTap: readOnly
              ? null
              : () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: DateTime(1970),
                    lastDate: DateTime(2050),
                  );
                  if (picked != null) {
                    controller?.text = DateFormat('dd/MM/yyyy').format(picked);
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
      ],
    );
  }

  Widget _buildDateTimeField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
        TextFormField(
          controller: controller,
          readOnly: true,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
          decoration: _inputDecoration(
            hint: 'DD/MM/YYYY HH:mm',
            suffixIcon: const Icon(Icons.access_time_rounded, size: 18, color: AppColors.navyMid),
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
      ],
    );
  }

  Widget _buildDropdownField(BuildContext context) {
    final opts = fieldDef.options.isNotEmpty
        ? fieldDef.options
        : (fieldDef.fieldKey.toLowerCase().contains('gender')
            ? ['Male', 'Female', 'Other']
            : ['Yes', 'No', 'N/A']);
    final currentVal = value?.toString() ?? controller?.text;
    final validVal = opts.contains(currentVal) ? currentVal : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
        DropdownButtonFormField<String>(
          initialValue: validVal,
          items: opts.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(
                opt,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
              ),
            );
          }).toList(),
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
      ],
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    final isChecked = (value is bool)
        ? value as bool
        : (controller?.text.toLowerCase() == 'true' ||
            controller?.text.toLowerCase() == 'yes');

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isChecked ? AppColors.navyMid.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isChecked ? AppColors.navyMid : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isChecked,
            activeColor: AppColors.navyMid,
            onChanged: readOnly
                ? null
                : (newVal) {
                    final b = newVal ?? false;
                    controller?.text = b.toString();
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
                color: AppColors.navyDark,
              ),
            ),
          ),
        ],
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
                child: const Icon(Icons.upload_file_rounded, color: AppColors.navyMid, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  filePath.isNotEmpty ? filePath : 'No file attached',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: filePath.isNotEmpty ? AppColors.lightText : AppColors.lightSubText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!readOnly)
                TextButton.icon(
                  onPressed: () {
                    // For web/mobile demo file reference
                    controller?.text = 'attached_doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
                    onChanged?.call(controller?.text);
                  },
                  icon: const Icon(Icons.attach_file, size: 16),
                  label: Text('Attach', style: GoogleFonts.poppins(fontSize: 12)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
