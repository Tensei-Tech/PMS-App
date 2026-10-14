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
  final bool? isExpanded;
  final VoidCallback? onToggle;
  final List<String>? accusedOptions;
  final Widget? headerAction;
  final int? sectionIndex;
  final bool hideEmptyFields;
  final List<String>? designationOptions;
  final List<String>? preventiveOptions;

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
    this.isExpanded,
    this.onToggle,
    this.accusedOptions,
    this.headerAction,
    this.sectionIndex,
    this.hideEmptyFields = false,
    this.designationOptions,
    this.preventiveOptions,
  });

  @override
  State<DynamicSectionCard> createState() => _DynamicSectionCardState();
}

class _DynamicSectionCardState extends State<DynamicSectionCard> {
  bool _expanded = false;

  bool get _isExpanded => widget.isExpanded ?? _expanded;

  void _handleToggle() {
    if (widget.onToggle != null) {
      widget.onToggle!();
    } else {
      setState(() => _expanded = !_expanded);
    }
  }

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant DynamicSectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != null && widget.isExpanded != _expanded) {
      _expanded = widget.isExpanded!;
    }
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
    // Arrest & Release conditional reveals
    'release_on_notice_datetime': 'release_on_notice',
    'anticipatory_bail_datetime': 'anticipatory_bail',
    'death_of_accused_datetime': 'death_of_accused',
    // Preventive action conditional reveals
    'bond_cancellation_date': 'bond_date',
    // Discharge section conditional reveals
    'discharge_date': 'is_discharged',
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

  bool _isFieldEmpty(DynamicFieldDef f) {
    final ctrl = widget.controllers[f.fieldKey];
    if (ctrl != null && ctrl.text.trim().isNotEmpty) {
      if (ctrl.text.trim().toLowerCase() == 'false') return true;
      return false;
    }
    final val = widget.values[f.fieldKey];
    if (val != null) {
      if (val is bool) return !val;
      if (val.toString().trim().isNotEmpty &&
          val.toString().trim().toLowerCase() != 'false') {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final baseFields = widget.fields.where(_isFieldVisible).toList();
    if (baseFields.isEmpty) return const SizedBox.shrink();

    final visibleFields = (widget.readOnly && widget.hideEmptyFields)
        ? baseFields.where((f) => !_isFieldEmpty(f)).toList()
        : baseFields;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 600;

    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? 10.0 : 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? AppRadius.md : AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.04),
            blurRadius: isCompact ? 6 : 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          InkWell(
            onTap: _handleToggle,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isCompact ? AppRadius.md : AppRadius.lg),
              bottom: Radius.circular(_isExpanded ? 0 : (isCompact ? AppRadius.md : AppRadius.lg)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 16,
                vertical: isCompact ? 11 : 14,
              ),
              child: Row(
                children: [
                  Container(
                    width: isCompact ? 34 : 38,
                    height: isCompact ? 34 : 38,
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: widget.sectionIndex != null
                        ? Text(
                            '${widget.sectionIndex}',
                            style: GoogleFonts.poppins(
                              fontSize: isCompact ? 13.5 : 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyDark,
                            ),
                          )
                        : Icon(widget.icon, size: isCompact ? 18 : 20, color: AppColors.navyMid),
                  ),
                  SizedBox(width: isCompact ? 10 : 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: isCompact ? 13.5 : 14,
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
                      color: visibleFields.isEmpty
                          ? const Color(0xFFF1F5F9)
                          : AppColors.navyMid.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      visibleFields.isEmpty
                          ? 'Empty'
                          : '${visibleFields.length} field${visibleFields.length == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: visibleFields.isEmpty
                            ? AppColors.lightSubText
                            : AppColors.navyMid,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: _isExpanded ? 'Collapse' : 'Expand',
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.navyMid,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fields Grid / Column with smooth AnimatedCrossFade
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: AppColors.lightBorder),
                if (visibleFields.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: AppColors.navyMid),
                          const SizedBox(width: 10),
                          Text(
                            'No data recorded for this section',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: AppColors.lightSubText,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
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
                            designationOptions: widget.designationOptions,
                            preventiveOptions: widget.preventiveOptions,
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
                                padding: EdgeInsets.only(bottom: isCompact ? 10 : 12),
                                child: buildControl(f),
                              );
                            }).toList(),
                          );
                        }

                        // Special one-line layout for CCTV & CDR (3 compact fields)
                        if (widget.title.toLowerCase().contains('cctv') &&
                            visibleFields.length == 3) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: isCompact ? 10 : 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: buildControl(visibleFields[0]),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 4,
                                  child: buildControl(visibleFields[1]),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 4,
                                  child: buildControl(visibleFields[2]),
                                ),
                              ],
                            ),
                          );
                        }

                        // 2-Column Responsive Grid on wider screens:
                        // Group single-line fields in 2-column pairs, and give textareas full-width rows!
                        final items = <Widget>[];
                        final singleLineFields = <DynamicFieldDef>[];
                        final textareas = <DynamicFieldDef>[];

                        for (final f in visibleFields) {
                          if (f.fieldType == 'textarea') {
                            textareas.add(f);
                          } else {
                            singleLineFields.add(f);
                          }
                        }

                        for (var i = 0; i < singleLineFields.length; i += 2) {
                          final f1 = singleLineFields[i];
                          final f2 = (i + 1 < singleLineFields.length)
                              ? singleLineFields[i + 1]
                              : null;

                          items.add(
                            Padding(
                              padding: EdgeInsets.only(bottom: isCompact ? 10 : 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: buildControl(f1),
                                  ),
                                  const SizedBox(width: 18),
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

                        for (final ta in textareas) {
                          items.add(
                            Padding(
                              padding: EdgeInsets.only(bottom: isCompact ? 10 : 12),
                              child: buildControl(ta),
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
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }
}
