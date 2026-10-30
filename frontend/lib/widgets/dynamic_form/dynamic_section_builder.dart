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
  final String? stationId;
  final List<dynamic>? copyOnTickRules;
  final List<DynamicFieldDef>? allFormFields;

  /// Optional per-field character limits (field_key -> max length).
  final Map<String, int>? fieldMaxLengths;

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
    this.isExpanded,
    this.onToggle,
    this.accusedOptions,
    this.headerAction,
    this.sectionIndex,
    this.hideEmptyFields = false,
    this.designationOptions,
    this.preventiveOptions,
    this.stationId,
    this.copyOnTickRules,
    this.allFormFields,
    this.fieldMaxLengths,
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

  /// Shown only when both rules allow it: the field's own dependency from the
  /// database (depends_on_field_key / depends_on_value, cascading) and the
  /// parent-field graph above.
  bool _isFieldVisible(DynamicFieldDef f, [Set<String>? visiting]) {
    return _isDependencyMet(f, visiting) && _isGraphVisible(f);
  }

  bool _isDependencyMet(DynamicFieldDef f, [Set<String>? visiting]) {
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

    return dependsOnValueMatches(rawVal, f.dependsOnValue,
        parentIsMultiSelect: parentField?.fieldType == 'multi_select');
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

  bool _isCopyTrigger(String fieldKey) {
    return (widget.copyOnTickRules ?? const []).any((rule) =>
        rule is Map &&
        (rule['trigger_field'] ?? rule['tick_field'])?.toString() == fieldKey);
  }

  void _handleCopyOnTick(String triggerKey) {
    if (widget.copyOnTickRules == null || widget.copyOnTickRules!.isEmpty) {
      return;
    }

    for (final rule in widget.copyOnTickRules!) {
      if (rule is! Map) continue;
      final tKey = (rule['trigger_field'] ?? rule['tick_field'])?.toString();
      if (tKey == triggerKey) {
        final sKey = (rule['source_field'] ?? rule['from_field'])?.toString();
        final tgtKey = (rule['target_field'] ?? rule['to_field'])?.toString();
        if (sKey != null &&
            tgtKey != null &&
            sKey.isNotEmpty &&
            tgtKey.isNotEmpty) {
          final sVal = widget.controllers[sKey]?.text ??
              widget.values[sKey]?.toString() ??
              '';
          widget.values[tgtKey] = sVal;
          if (widget.controllers.containsKey(tgtKey)) {
            widget.controllers[tgtKey]?.text = sVal;
          } else {
            try {
              widget.controllers
                  .putIfAbsent(tgtKey, () => TextEditingController(text: sVal));
            } catch (_) {}
          }
          widget.onValueChanged(tgtKey, sVal);
        }
      }
    }
  }

  bool _isGraphVisible(DynamicFieldDef f) {
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
    final baseFields = widget.fields
        .where((f) => f.parentFieldKey == null || f.parentFieldKey!.isEmpty)
        .where(_isFieldVisible)
        .toList();
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
        borderRadius:
            BorderRadius.circular(isCompact ? AppRadius.md : AppRadius.lg),
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
              bottom: Radius.circular(
                  _isExpanded ? 0 : (isCompact ? AppRadius.md : AppRadius.lg)),
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
                        : Icon(widget.icon,
                            size: isCompact ? 18 : 20,
                            color: AppColors.navyMid),
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
                          TextEditingController? dateCtrl =
                              widget.controllers[dateKey];
                          if (dateCtrl == null) {
                            try {
                              dateCtrl = widget.controllers.putIfAbsent(
                                dateKey,
                                () => TextEditingController(
                                  text:
                                      widget.values[dateKey]?.toString() ?? '',
                                ),
                              );
                            } catch (_) {
                              dateCtrl = TextEditingController(
                                text: widget.values[dateKey]?.toString() ?? '',
                              );
                            }
                          }
                          if (widget.values[dateKey] != null &&
                              dateCtrl.text.isEmpty) {
                            dateCtrl.text = widget.values[dateKey].toString();
                          }

                          TextEditingController? fieldCtrl =
                              widget.controllers[f.fieldKey];
                          if (fieldCtrl == null) {
                            try {
                              fieldCtrl = widget.controllers.putIfAbsent(
                                f.fieldKey,
                                () => TextEditingController(
                                  text: widget.values[f.fieldKey]?.toString() ??
                                      '',
                                ),
                              );
                            } catch (_) {
                              fieldCtrl = TextEditingController(
                                text:
                                    widget.values[f.fieldKey]?.toString() ?? '',
                              );
                            }
                          }
                          if (widget.values[f.fieldKey] != null &&
                              fieldCtrl.text.isEmpty) {
                            fieldCtrl.text =
                                widget.values[f.fieldKey].toString();
                          }
                          if ((widget.values[f.fieldKey] == null ||
                                  widget.values[f.fieldKey].toString().isEmpty) &&
                              f.defaultValue != null &&
                              f.defaultValue!.isNotEmpty) {
                            widget.values[f.fieldKey] = f.defaultValue;
                            fieldCtrl.text = f.defaultValue!;
                          }

                          return DynamicControlFactory(
                            fieldDef: f,
                            controller: fieldCtrl,
                            value: widget.values[f.fieldKey],
                            onChanged: (val) {
                              final oldVal = widget.values[f.fieldKey];
                              widget.values[f.fieldKey] = val;
                              widget.onValueChanged(f.fieldKey, val);

                              final wasTicked = (oldVal == true ||
                                  oldVal == 'true' ||
                                  oldVal == 1 ||
                                  oldVal == '1' ||
                                  oldVal == 'Yes');
                              final isTicked = (val == true ||
                                  val == 'true' ||
                                  val == 1 ||
                                  val == '1' ||
                                  val == 'Yes');
                              if (!wasTicked && isTicked) {
                                _handleCopyOnTick(f.fieldKey);
                              }

                              _pruneHiddenFields();
                              if (mounted) setState(() {});
                            },
                            readOnly: widget.readOnly || f.isReadOnly || f.isAutoGenerated,
                            accusedOptions: widget.accusedOptions,
                            designationOptions: widget.designationOptions,
                            preventiveOptions: widget.preventiveOptions,
                            dateController: dateCtrl,
                            stationId: widget.stationId,
                            allFields: widget.allFormFields ?? widget.fields,
                            formValues: widget.values,
                            maxLength: widget.fieldMaxLengths?[f.fieldKey],
                            compact: f.fieldType == 'checkbox' &&
                                _isCopyTrigger(f.fieldKey),
                            onMultiFieldChanged: (extraVals) {
                              for (final e in extraVals.entries) {
                                widget.values[e.key] = e.value;
                                widget.controllers[e.key]?.text =
                                    e.value?.toString() ?? '';
                                widget.onValueChanged(e.key, e.value);
                              }
                              _pruneHiddenFields();
                              if (mounted) setState(() {});
                            },
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
                                padding: EdgeInsets.only(
                                    bottom: isCompact ? 10 : 12),
                                child: buildControl(f),
                              );
                            }).toList(),
                          );
                        }

                        // Special one-line layout for CCTV & CDR (3 compact fields)
                        if (widget.title.toLowerCase().contains('cctv') &&
                            visibleFields.length == 3) {
                          return Padding(
                            padding:
                                EdgeInsets.only(bottom: isCompact ? 10 : 12),
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

                        // 2-Column Responsive Grid on wider screens: single-line
                        // fields in pairs, in display order; textareas, repeating
                        // groups and Act / Section pickers take a full row
                        bool isFullWidth(DynamicFieldDef f) =>
                            f.fieldType == 'textarea' ||
                            f.fieldType == 'repeating_group' ||
                            f.fieldType == 'charges';
                        final items = <Widget>[];
                        final pending = <DynamicFieldDef>[];

                        void flushPair() {
                          if (pending.isEmpty) return;
                          final f1 = pending[0];
                          final f2 = pending.length > 1 ? pending[1] : null;
                          pending.clear();
                          items.add(
                            Padding(
                              padding:
                                  EdgeInsets.only(bottom: isCompact ? 10 : 12),
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

                        for (final f in visibleFields) {
                          if (isFullWidth(f)) {
                            flushPair();
                            items.add(
                              Padding(
                                padding: EdgeInsets.only(
                                    bottom: isCompact ? 10 : 12),
                                child: buildControl(f),
                              ),
                            );
                          } else {
                            pending.add(f);
                            if (pending.length == 2) flushPair();
                          }
                        }
                        flushPair();

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
