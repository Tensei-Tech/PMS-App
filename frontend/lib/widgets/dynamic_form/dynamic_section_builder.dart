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
  final String? stationId;

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
    this.stationId,
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

  bool _isFieldVisible(DynamicFieldDef f, [Set<String>? visiting]) {
    // If no dependency is declared, field is visible
    if (f.dependsOnFieldKey == null || f.dependsOnFieldKey!.trim().isEmpty) {
      return true;
    }

    final parentKey = f.dependsOnFieldKey!.trim();
    final visitSet = visiting ?? <String>{};
    if (visitSet.contains(f.fieldKey)) {
      return false; // Break cyclic dependencies safely
    }
    visitSet.add(f.fieldKey);

    // If parent field exists in this field list, evaluate parent's visibility first (cascading)
    final parentField =
        widget.fields.where((item) => item.fieldKey == parentKey).firstOrNull;
    if (parentField != null) {
      final isParentVis = _isFieldVisible(parentField, visitSet);
      if (!isParentVis) return false;
    }

    final rawVal =
        widget.values[parentKey] ?? widget.controllers[parentKey]?.text;
    if (rawVal == null) return false;

    final targetVal = f.dependsOnValue?.trim() ?? '';
    final currentStr = rawVal.toString().trim();

    if (targetVal.isEmpty) {
      return currentStr.isNotEmpty &&
          currentStr.toLowerCase() != 'false' &&
          currentStr != '0';
    }

    if (currentStr.toLowerCase() == targetVal.toLowerCase()) {
      return true;
    }

    // Match boolean representations
    if ((currentStr.toLowerCase() == 'true' ||
            currentStr == '1' ||
            currentStr.toLowerCase() == 'yes') &&
        (targetVal.toLowerCase() == 'true' ||
            targetVal == '1' ||
            targetVal.toLowerCase() == 'yes')) {
      return true;
    }

    return false;
  }

  void _pruneHiddenFields() {
    bool changed = true;
    int maxPasses = 10;
    while (changed && maxPasses > 0) {
      changed = false;
      maxPasses--;
      for (final f in widget.fields) {
        if (!_isFieldVisible(f)) {
          if (widget.values.containsKey(f.fieldKey)) {
            widget.values.remove(f.fieldKey);
            widget.onValueChanged(f.fieldKey, null);
            changed = true;
          }
          if (widget.controllers.containsKey(f.fieldKey)) {
            if (widget.controllers[f.fieldKey]!.text.isNotEmpty) {
              widget.controllers[f.fieldKey]!.clear();
              changed = true;
            }
          }
          final dateKey = '${f.fieldKey}_date';
          if (widget.values.containsKey(dateKey)) {
            widget.values.remove(dateKey);
            widget.onValueChanged(dateKey, null);
            changed = true;
          }
          if (widget.controllers.containsKey(dateKey)) {
            if (widget.controllers[dateKey]!.text.isNotEmpty) {
              widget.controllers[dateKey]!.clear();
              changed = true;
            }
          }
        }
      }
    }
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
                        widget.values[f.fieldKey] = val;
                        widget.onValueChanged(f.fieldKey, val);
                        _pruneHiddenFields();
                        if (mounted) setState(() {});
                      },
                      readOnly: widget.readOnly,
                      accusedOptions: widget.accusedOptions,
                      dateController: dateCtrl,
                      stationId: widget.stationId,
                      onDateChanged: (val) {
                        widget.values[dateKey] = val;
                        widget.onValueChanged(dateKey, val);
                        _pruneHiddenFields();
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
