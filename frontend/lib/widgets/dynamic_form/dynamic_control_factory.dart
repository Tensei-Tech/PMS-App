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
      case 'radio':
        return _buildRadioGroup(context);
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
          ctrl: controller ??
              TextEditingController(text: value?.toString() ?? ''),
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
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
      {String? hint, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint ?? 'Enter ${fieldDef.fieldLabel}',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onChanged: onChanged,
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
          onChanged: onChanged,
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
          onChanged: onChanged,
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
            suffixIcon: const Icon(Icons.calendar_today_rounded,
                size: 18, color: AppColors.navyMid),
          ),
          onTap: readOnly
              ? null
              : () async {
                  final now = DateTime.now();
                  DateTime initial = now;
                  if (controller != null &&
                      controller!.text.trim().isNotEmpty) {
                    final parts =
                        controller!.text.trim().split(RegExp(r'[-/]'));
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
                    controller?.text =
                        DateFormat('dd/MM/yyyy HH:mm').format(dt);
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
    return _DynamicDropdownWidget(
      fieldDef: fieldDef,
      controller: controller,
      value: value,
      onChanged: onChanged,
      readOnly: readOnly,
      stationId: stationId,
      decoration: _inputDecoration(hint: 'Select ${fieldDef.fieldLabel}'),
      labelWidget: _buildLabel(context),
    );
  }

  Widget _buildRadioGroup(BuildContext context) {
    return _DynamicRadioWidget(
      fieldDef: fieldDef,
      controller: controller,
      value: value,
      onChanged: onChanged,
      readOnly: readOnly,
      stationId: stationId,
      labelWidget: _buildLabel(context),
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
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
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
                      color:
                          isChecked ? AppColors.navyDark : AppColors.lightText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isPanch && isChecked) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: _buildPanchanamaDateTimeButton(context),
            ),
          ],
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              size: 15,
              color: AppColors.navyMid,
            ),
            const SizedBox(width: 6),
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark,
              ),
            ),
            if (!readOnly) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.edit_calendar_rounded,
                size: 14,
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
    if (widget.fieldDef.options.isNotEmpty) {
      _options = widget.fieldDef.options;
      _isLoading = false;
      _error = null;
      return;
    }

    final src = widget.fieldDef.optionsSource;
    if (src != null && src.trim().isNotEmpty) {
      final cached = DynamicOptionsService().getCachedOptions(src, stationId: widget.stationId);
      if (cached != null) {
        _options = cached;
        _isLoading = false;
        _error = null;
      } else {
        _isLoading = true;
        _error = null;
        DynamicOptionsService().fetchOptions(src, stationId: widget.stationId).then((opts) {
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyMid),
                ),
              ),
            ),
            child: Text(
              'Loading options...',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
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
                icon: const Icon(Icons.refresh, size: 18, color: AppColors.dangerRed),
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  final src = widget.fieldDef.optionsSource;
                  if (src != null) {
                    DynamicOptionsService()
                        .fetchOptions(src, stationId: widget.stationId, forceRefresh: true)
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
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.dangerRed),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.labelWidget,
        DropdownButtonFormField<String>(
          initialValue: validVal,
          items: _options.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(
                opt,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
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
        ),
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
      final cached = DynamicOptionsService().getCachedOptions(src, stationId: widget.stationId);
      if (cached != null) {
        _options = cached;
        _isLoading = false;
        _error = null;
      } else {
        _isLoading = true;
        _error = null;
        DynamicOptionsService().fetchOptions(src, stationId: widget.stationId).then((opts) {
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
    final currentVal = widget.value?.toString() ?? widget.controller?.text ?? '';

    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.labelWidget,
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyMid),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              _error!,
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.dangerRed),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.labelWidget,
        Wrap(
          spacing: 16,
          runSpacing: 8,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navyMid.withValues(alpha: 0.08) : Colors.white,
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
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.navyDark : AppColors.lightText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

