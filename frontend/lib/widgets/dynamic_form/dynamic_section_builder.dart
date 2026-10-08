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
  final int? index;
  final Widget? headerTrailing;
  final bool isCollapsible;
  final Widget? customBody; // Added back to prevent Hot Reload crash

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
    this.initiallyExpanded = false,
    this.accusedOptions,
    this.index,
    this.headerTrailing,
    this.isCollapsible = true,
    this.customBody, // Added back to prevent Hot Reload crash
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

  @override
  Widget build(BuildContext context) {
    if (widget.fields.isEmpty && widget.customBody == null) {
      return const SizedBox.shrink();
    }

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
            onTap: widget.isCollapsible
                ? () => setState(() => _expanded = !_expanded)
                : null,
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
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.index ?? ""}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyMid,
                      ),
                    ),
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
                  if (widget.headerTrailing != null) ...[
                    widget.headerTrailing!,
                    const SizedBox(width: 8),
                  ],
                  if (widget.isCollapsible) ...[
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.navyMid,
                    ),
                  ],
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
                  if (!isWide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.fields.map((f) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DynamicControlFactory(
                            fieldDef: f,
                            controller: widget.controllers[f.fieldKey],
                            value: widget.values[f.fieldKey],
                            onChanged: (val) =>
                                widget.onValueChanged(f.fieldKey, val),
                            readOnly: widget.readOnly,
                            accusedOptions: widget.accusedOptions,
                          ),
                        );
                      }).toList(),
                    );
                  }

                  // 2-Column Responsive Grid on wider screens
                  final items = <Widget>[];
                  for (var i = 0; i < widget.fields.length; i += 2) {
                    final f1 = widget.fields[i];
                    final f2 = (i + 1 < widget.fields.length)
                        ? widget.fields[i + 1]
                        : null;

                    // If f1 is textarea, header, or checkbox, give it full row width
                    if (f1.fieldType == 'textarea' ||
                        f1.fieldType == 'header' ||
                        f1.fieldType == 'checkbox' ||
                        f1.fieldType == 'full_text') {
                      items.add(
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DynamicControlFactory(
                            fieldDef: f1,
                            controller: widget.controllers[f1.fieldKey],
                            value: widget.values[f1.fieldKey],
                            onChanged: (val) =>
                                widget.onValueChanged(f1.fieldKey, val),
                            readOnly: widget.readOnly,
                            accusedOptions: widget.accusedOptions,
                          ),
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
                              child: DynamicControlFactory(
                                fieldDef: f1,
                                controller: widget.controllers[f1.fieldKey],
                                value: widget.values[f1.fieldKey],
                                onChanged: (val) =>
                                    widget.onValueChanged(f1.fieldKey, val),
                                readOnly: widget.readOnly,
                                accusedOptions: widget.accusedOptions,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: f2 != null
                                  ? DynamicControlFactory(
                                      fieldDef: f2,
                                      controller:
                                          widget.controllers[f2.fieldKey],
                                      value: widget.values[f2.fieldKey],
                                      onChanged: (val) => widget.onValueChanged(
                                          f2.fieldKey, val),
                                      readOnly: widget.readOnly,
                                      accusedOptions: widget.accusedOptions,
                                    )
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
          if (_expanded && widget.customBody != null) widget.customBody!,
        ],
      ),
    );
  }
}
