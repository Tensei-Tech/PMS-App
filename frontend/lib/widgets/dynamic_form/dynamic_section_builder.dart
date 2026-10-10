// lib/widgets/dynamic_form/dynamic_section_builder.dart
// Groups database-driven fields into collapsible, highly legible police case sections.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import 'dynamic_control_factory.dart';
import 'dynamic_field_model.dart';

class DynamicSectionCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<DynamicFieldDef> fields;
  final Map<String, TextEditingController> controllers;
  final Map<String, dynamic> values;
  final Function(String key, dynamic value) onValueChanged;
  final bool readOnly;
  final bool initiallyExpanded;
  final List<String>? accusedOptions;
  final Widget? headerAction;

  const DynamicSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.fields,
    required this.controllers,
    required this.values,
    required this.onValueChanged,
    this.readOnly = false,
    this.initiallyExpanded = true,
    this.accusedOptions,
    this.headerAction,
  });

  @override
  State<DynamicSectionCard> createState() => _DynamicSectionCardState();
}

class _DynamicSectionCardState extends State<DynamicSectionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  // Data-driven field dependency graph: child_field_key -> parent_field_key
  static const Map<String, String> _fieldParentDependency = {
    // Remand & Custody section dependencies
    'pr_bond': 'mcr',
    'bail': 'mcr',
    'jail': 'mcr',
    'pr_bond_date': 'pr_bond',
    'surety_name': 'bail',
    'surety_age': 'bail',
    'surety_gender': 'bail',
    'surety_occupation': 'bail',
    'surety_mobile': 'bail',
    'surety_aadhaar': 'bail',
    'surety_pan': 'bail',
    'surety_address': 'bail',
    'surety_relation': 'bail',
    'jail_date': 'jail',
  };

  bool _isFieldVisible(DynamicFieldDef f) {
    var currentKey = f.fieldKey;
    while (_fieldParentDependency.containsKey(currentKey)) {
      final parentKey = _fieldParentDependency[currentKey]!;
      final parentVal =
          widget.values[parentKey] ?? widget.controllers[parentKey]?.text;
      final isParentTrue = parentVal == true ||
          parentVal == 'true' ||
          parentVal == '1' ||
          (parentVal is String &&
              parentVal.trim().isNotEmpty &&
              parentVal.toLowerCase() != 'false');
      if (!isParentTrue) return false;
      currentKey = parentKey;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final visibleFields = widget.fields.where(_isFieldVisible).toList();
    if (visibleFields.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppRadius.lg),
              bottom: Radius.circular(_expanded ? 0 : AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(widget.icon, size: 20, color: AppColors.navyMid),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                  if (widget.headerAction != null) ...[
                    widget.headerAction!,
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${visibleFields.length} fields',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyMid,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.navyMid,
                  ),
                ],
              ),
            ),
          ),

          // Fields Grid / Column
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.lightBorder),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  Widget buildControl(DynamicFieldDef f) {
                    final dateKey = '${f.fieldKey}_date';
                    final dateCtrl = widget.controllers.putIfAbsent(
                      dateKey,
                      () => TextEditingController(
                        text: widget.values[dateKey]?.toString() ?? '',
                      ),
                    );
                    if (widget.values[dateKey] != null &&
                        dateCtrl.text.isEmpty) {
                      dateCtrl.text = widget.values[dateKey].toString();
                    }

                    final fieldCtrl = widget.controllers.putIfAbsent(
                      f.fieldKey,
                      () => TextEditingController(
                        text: widget.values[f.fieldKey]?.toString() ?? '',
                      ),
                    );
                    if (widget.values[f.fieldKey] != null &&
                        fieldCtrl.text.isEmpty) {
                      fieldCtrl.text = widget.values[f.fieldKey].toString();
                    }

                    return DynamicControlFactory(
                      fieldDef: f,
                      controller: fieldCtrl,
                      value: widget.values[f.fieldKey],
                      onChanged: (val) {
                        widget.onValueChanged(f.fieldKey, val);
                        if (mounted) setState(() {});
                      },
                      readOnly: widget.readOnly,
                      accusedOptions: widget.accusedOptions,
                      dateController: dateCtrl,
                      onDateChanged: (val) {
                        widget.onValueChanged(dateKey, val);
                        if (mounted) setState(() {});
                      },
                    );
                  }

                  if (!isWide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: visibleFields.map((f) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: buildControl(f),
                        );
                      }).toList(),
                    );
                  }

                  // 2-Column Responsive Grid on wider screens
                  final items = <Widget>[];
                  for (var i = 0; i < visibleFields.length; i += 2) {
                    final f1 = visibleFields[i];
                    final f2 = (i + 1 < visibleFields.length)
                        ? visibleFields[i + 1]
                        : null;

                    // If f1 is textarea, give it full row width
                    if (f1.fieldType == 'textarea') {
                      items.add(
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: buildControl(f1),
                        ),
                      );
                      i -= 1; // Realign single step
                      continue;
                    }

                    items.add(
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: buildControl(f1),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: f2 != null
                                  ? buildControl(f2)
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
