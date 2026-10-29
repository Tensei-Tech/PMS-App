// lib/widgets/dynamic_form/dynamic_repeating_group_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/dynamic_options_service.dart';
import '../../theme/app_theme.dart';
import 'dynamic_control_factory.dart';
import 'dynamic_field_model.dart';

/// Renders repeating group rows dynamically driven by child fields where
/// [DynamicFieldDef.parentFieldKey] == [fieldDef.fieldKey].
/// Evaluates child field conditions strictly within the row's own context.
class DynamicRepeatingGroupWidget extends StatefulWidget {
  final DynamicFieldDef fieldDef;
  final List<DynamicFieldDef> childFields;
  final dynamic value;
  final ValueChanged<List<Map<String, dynamic>>>? onChanged;
  final bool readOnly;
  final int? maxItems;
  final String? groupByFieldKey;
  final String? groupOptionsSource;

  /// Live form values, passed to child controls (for `rows:` option sources).
  final Map<String, dynamic>? formValues;

  const DynamicRepeatingGroupWidget({
    super.key,
    required this.fieldDef,
    required this.childFields,
    this.value,
    this.onChanged,
    this.readOnly = false,
    this.maxItems,
    this.groupByFieldKey,
    this.groupOptionsSource,
    this.formValues,
  });

  @override
  State<DynamicRepeatingGroupWidget> createState() =>
      _DynamicRepeatingGroupWidgetState();
}

class _DynamicRepeatingGroupWidgetState
    extends State<DynamicRepeatingGroupWidget> {
  List<Map<String, dynamic>> _rows = [];
  List<String> _groupOptions = [];
  bool _isLoadingGroups = false;
  final Map<String, bool> _expandedGroups = {};
  final Map<String, TextEditingController> _rowControllers = {};

  @override
  void initState() {
    super.initState();
    _initRows();
    _initGroupOptions();
  }

  @override
  void didUpdateWidget(covariant DynamicRepeatingGroupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _initRows();
    }
  }

  @override
  void dispose() {
    for (final c in _rowControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initRows() {
    if (widget.value is List) {
      _rows = (widget.value as List)
          .map((item) => item is Map
              ? Map<String, dynamic>.from(item)
              : <String, dynamic>{})
          .toList();
    } else {
      _rows = [];
    }
    if (_rows.isEmpty &&
        (widget.fieldDef.fieldKey.contains('accused') ||
            widget.fieldDef.fieldKey.contains('injured') ||
            widget.fieldDef.fieldKey.contains('damage') ||
            _isSingleRow)) {
      _rows.add({});
    }
    if (widget.groupByFieldKey != null) {
      for (final r in _rows) {
        final g = r[widget.groupByFieldKey]?.toString();
        if (g != null && g.trim().isNotEmpty) {
          _expandedGroups[g.trim().toLowerCase()] = true;
        }
      }
    }
  }

  Future<void> _initGroupOptions() async {
    final optSrc = widget.groupOptionsSource;
    if (optSrc != null && optSrc.isNotEmpty) {
      setState(() => _isLoadingGroups = true);
      try {
        final opts = await DynamicOptionsService().fetchOptions(optSrc);
        if (mounted) {
          setState(() {
            _groupOptions = opts;
            _isLoadingGroups = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoadingGroups = false);
      }
    }
  }

  /// A group limited to one row always shows that row, with no Add / Remove
  bool get _isSingleRow => widget.maxItems == 1;

  void _addRow([Map<String, dynamic>? initialValues]) {
    if (widget.maxItems != null && _rows.length >= widget.maxItems!) {
      return;
    }
    final newRow = <String, dynamic>{};
    if (initialValues != null) {
      newRow.addAll(initialValues);
    }
    setState(() {
      _rows.add(newRow);
    });
    widget.onChanged?.call(List.from(_rows));
  }

  void _removeRow(int index) {
    if (index >= 0 && index < _rows.length) {
      setState(() {
        _rows.removeAt(index);
        for (final c in _rowControllers.values) {
          c.dispose();
        }
        _rowControllers.clear();
      });
      widget.onChanged?.call(List.from(_rows));
    }
  }

  void _updateRowField(int index, String fieldKey, dynamic val) {
    if (index >= 0 && index < _rows.length) {
      _rows[index][fieldKey] = val;
      widget.onChanged?.call(List.from(_rows));
    }
  }

  TextEditingController _getController(
      int index, String fieldKey, dynamic val) {
    final k = '${index}_$fieldKey';
    final strVal = val?.toString() ?? '';
    final ctrl = _rowControllers.putIfAbsent(
      k,
      () => TextEditingController(text: strVal),
    );
    if (ctrl.text != strVal &&
        val != null &&
        !(FocusManager.instance.primaryFocus?.hasFocus ?? false)) {
      ctrl.value = ctrl.value.copyWith(
        text: strVal,
        selection: TextSelection.collapsed(offset: strVal.length),
      );
    }
    return ctrl;
  }

  bool _isChildVisibleInRow(DynamicFieldDef child, Map<String, dynamic> row) {
    if (child.dependsOnFieldKey == null ||
        child.dependsOnFieldKey!.trim().isEmpty) {
      return true;
    }

    final parentKey = child.dependsOnFieldKey!.trim();
    final rawVal = row[parentKey];
    if (rawVal == null) return false;

    return dependsOnValueMatches(rawVal, child.dependsOnValue);
  }

  @override
  Widget build(BuildContext context) {
    // If grouped by a category/type (e.g. MPDA Crime Chart in 12 sections)
    if (widget.groupByFieldKey != null &&
        widget.groupByFieldKey!.isNotEmpty &&
        _groupOptions.isNotEmpty) {
      return _buildGroupedSections();
    }

    return _buildStandardRepeatingGroup();
  }

  Widget _buildStandardRepeatingGroup() {
    final canAdd = !widget.readOnly &&
        (widget.maxItems == null || _rows.length < widget.maxItems!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The Add button sits right next to the group's name
        Row(
          children: [
            Flexible(
              child: Text(
                widget.fieldDef.fieldLabel,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyDark,
                ),
              ),
            ),
            if (canAdd) const SizedBox(width: 12),
            if (canAdd)
              TextButton.icon(
                onPressed: () => _addRow(),
                icon: const Icon(Icons.add_circle_outline,
                    size: 16, color: AppColors.navyMid),
                label: Text(
                  widget.fieldDef.fieldKey.contains('accused')
                      ? 'Add Accused'
                      : widget.fieldDef.fieldKey.contains('victim')
                          ? 'Add Victim'
                          : widget.fieldDef.fieldKey.contains('injured')
                              ? 'Add Injured Person'
                              : widget.fieldDef.fieldKey.contains('damage')
                                  ? 'Add Damaged Property'
                                  : 'Add',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyMid),
                ),
              ),
          ],
        ),
        if (_rows.isEmpty)
          const SizedBox.shrink()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildRowCard(index, _rows[index]);
            },
          ),
      ],
    );
  }

  Widget _buildRowCard(
    int index,
    Map<String, dynamic> row, {
    String? groupLabel,
    int? itemNumber,
  }) {
    final isAccused = widget.fieldDef.fieldKey.contains('accused');
    final isGang = widget.fieldDef.fieldKey.contains('gang');
    final isVictim = widget.fieldDef.fieldKey.contains('victim');
    final isInjured = widget.fieldDef.fieldKey.contains('injured');
    final isDamage = widget.fieldDef.fieldKey.contains('damage');
    // Other groups are numbered by their own name: "Complainant 1", "Complainant 2"
    final titleText = groupLabel != null
        ? '$groupLabel Crime #${itemNumber ?? (index + 1)}'
        : isAccused
            ? 'Accused Person #${index + 1}'
            : isGang
                ? 'Member #${index + 1}'
                : isVictim
                    ? 'Victim #${index + 1}'
                    : isInjured
                        ? 'Injured Person #${index + 1}'
                        : isDamage
                            ? 'Damaged Property #${index + 1}'
                            : '${widget.fieldDef.fieldLabel} ${index + 1}';

    final visibleChildren = widget.childFields
        .where((child) => _isChildVisibleInRow(child, row))
        .where((child) =>
            widget.groupByFieldKey == null ||
            child.fieldKey != widget.groupByFieldKey)
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titleText,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyMid,
                ),
              ),
              if (!widget.readOnly && !_isSingleRow)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.dangerRed),
                  tooltip: 'Remove',
                  onPressed: () => _removeRow(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 550;
              if (isWide && visibleChildren.length >= 2) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: visibleChildren.map((child) {
                    final val = row[child.fieldKey];
                    final ctrl = _getController(index, child.fieldKey, val);
                    final colWidth =
                        (constraints.maxWidth - 24) / visibleChildren.length;
                    final isFullWidth = child.fieldType == 'textarea' ||
                        child.fieldType == 'repeating_group' ||
                        child.fieldType == 'charges';
                    final itemWidth = isFullWidth
                        ? constraints.maxWidth
                        : (colWidth > 150
                            ? colWidth
                            : (constraints.maxWidth - 12) / 2);
                    return SizedBox(
                      width: itemWidth,
                      child: DynamicControlFactory(
                        fieldDef: child,
                        controller: ctrl,
                        value: val,
                        readOnly: widget.readOnly,
                        formValues: widget.formValues,
                        onChanged: (newVal) {
                          _updateRowField(index, child.fieldKey, newVal);
                        },
                      ),
                    );
                  }).toList(),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: visibleChildren.map((child) {
                  final val = row[child.fieldKey];
                  final ctrl = _getController(index, child.fieldKey, val);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DynamicControlFactory(
                      fieldDef: child,
                      controller: ctrl,
                      value: val,
                      readOnly: widget.readOnly,
                      formValues: widget.formValues,
                      onChanged: (newVal) {
                        _updateRowField(index, child.fieldKey, newVal);
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _toggleCategory(String opt, String groupKey, bool checked) {
    final isOther = opt.trim().toLowerCase().contains('other');
    final knownKeys = _groupOptions
        .where((g) => !g.trim().toLowerCase().contains('other'))
        .map((g) => g.trim().toLowerCase())
        .toSet();

    setState(() {
      if (checked) {
        // Multiple categories can be selected simultaneously
        _expandedGroups[groupKey] = true;

        final hasRow = _rows.any((r) {
          final rowVal =
              (r[widget.groupByFieldKey]?.toString().trim().toLowerCase() ??
                  '');
          if (isOther) {
            return rowVal == groupKey ||
                (rowVal.isNotEmpty && !knownKeys.contains(rowVal));
          }
          return rowVal == groupKey;
        });

        if (!hasRow) {
          _rows.add({
            widget.groupByFieldKey!: opt,
          });
        }
      } else {
        _expandedGroups[groupKey] = false;

        _rows.removeWhere((r) {
          final rowVal =
              (r[widget.groupByFieldKey]?.toString().trim().toLowerCase() ??
                  '');
          if (isOther) {
            return rowVal == groupKey ||
                (rowVal.isNotEmpty && !knownKeys.contains(rowVal));
          }
          return rowVal == groupKey;
        });

        // Clean up text controllers
        for (final c in _rowControllers.values) {
          c.dispose();
        }
        _rowControllers.clear();
      }
    });
    widget.onChanged?.call(List<Map<String, dynamic>>.from(_rows));
  }

  Widget _buildGroupRowForm(
    String opt,
    String groupKey,
    List<MapEntry<int, Map<String, dynamic>>> groupRows,
  ) {
    final isOther = opt.trim().toLowerCase().contains('other');

    if (groupRows.isEmpty) {
      final newRow = <String, dynamic>{widget.groupByFieldKey!: opt};
      _rows.add(newRow);
      groupRows = [MapEntry(_rows.length - 1, newRow)];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < groupRows.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: AppColors.lightBorder),
            ),
          _buildSingleCrimeRow(
            opt: opt,
            groupKey: groupKey,
            index: groupRows[i].key,
            row: groupRows[i].value,
            itemNumber: groupRows.length > 1 ? i + 1 : null,
            canDelete: groupRows.length > 1 && !widget.readOnly,
            isOther: isOther,
          ),
        ],
        if (!widget.readOnly) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _rows.add({widget.groupByFieldKey!: opt});
                });
                widget.onChanged?.call(List<Map<String, dynamic>>.from(_rows));
              },
              icon: const Icon(Icons.add_circle_outline,
                  size: 16, color: AppColors.navyMid),
              label: Text(
                'Add Another CR',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyMid,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSingleCrimeRow({
    required String opt,
    required String groupKey,
    required int index,
    required Map<String, dynamic> row,
    required int? itemNumber,
    required bool canDelete,
    required bool isOther,
  }) {
    final visibleChildren = widget.childFields
        .where((child) => _isChildVisibleInRow(child, row))
        .where((child) =>
            widget.groupByFieldKey == null ||
            child.fieldKey != widget.groupByFieldKey)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (itemNumber != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Crime #$itemNumber',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyMid,
                ),
              ),
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.dangerRed),
                  tooltip: 'Remove',
                  onPressed: () => _removeRow(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        if (isOther) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Specify Crime Type / Name',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
                      ),
                    ),
                    const Text(
                      ' *',
                      style: TextStyle(
                        color: AppColors.dangerRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _getController(
                    index,
                    'mpda_crime_other_type',
                    row['mpda_crime_other_type'] ??
                        row['other_crime_type'] ??
                        (row['mpda_crime_type'] != opt
                            ? row['mpda_crime_type']
                            : ''),
                  ),
                  readOnly: widget.readOnly,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.lightText),
                  decoration: InputDecoration(
                    hintText:
                        'Type other crime name (e.g. Cyber Crime, Financial Fraud...)',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.lightSubText),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: widget.readOnly
                        ? const Color(0xFFF8FAFC)
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide:
                          const BorderSide(color: AppColors.lightBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide:
                          const BorderSide(color: AppColors.lightBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(
                          color: AppColors.navyMid, width: 1.5),
                    ),
                  ),
                  onChanged: (text) {
                    _updateRowField(index, 'mpda_crime_other_type', text);
                    _updateRowField(index, 'other_crime_type', text);
                    _updateRowField(index, 'mpda_crime_type',
                        text.trim().isNotEmpty ? text.trim() : opt);
                  },
                ),
              ],
            ),
          ),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 550;
            if (isWide && visibleChildren.length >= 2) {
              return Wrap(
                spacing: 12,
                runSpacing: 10,
                children: visibleChildren.map((child) {
                  final val = row[child.fieldKey];
                  final ctrl = _getController(index, child.fieldKey, val);
                  final colWidth =
                      (constraints.maxWidth - 24) / visibleChildren.length;
                  final isFullWidth = child.fieldType == 'textarea' ||
                      child.fieldType == 'repeating_group' ||
                      child.fieldType == 'charges';
                  final itemWidth = isFullWidth
                      ? constraints.maxWidth
                      : (colWidth > 150
                          ? colWidth
                          : (constraints.maxWidth - 12) / 2);
                  return SizedBox(
                    width: itemWidth,
                    child: DynamicControlFactory(
                      fieldDef: child,
                      controller: ctrl,
                      value: val,
                      readOnly: widget.readOnly,
                      formValues: widget.formValues,
                      onChanged: (newVal) {
                        _updateRowField(index, child.fieldKey, newVal);
                      },
                    ),
                  );
                }).toList(),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: visibleChildren.map((child) {
                final val = row[child.fieldKey];
                final ctrl = _getController(index, child.fieldKey, val);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DynamicControlFactory(
                    fieldDef: child,
                    controller: ctrl,
                    value: val,
                    readOnly: widget.readOnly,
                    formValues: widget.formValues,
                    onChanged: (newVal) {
                      _updateRowField(index, child.fieldKey, newVal);
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGroupedSections() {
    if (_isLoadingGroups) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.fieldDef.fieldLabel,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
          ),
        ),
        const SizedBox(height: 8),
        ..._groupOptions.map((opt) {
          final groupKey = opt.trim().toLowerCase();
          final isOther = groupKey.contains('other');

          final knownKeys = _groupOptions
              .where((g) => !g.trim().toLowerCase().contains('other'))
              .map((g) => g.trim().toLowerCase())
              .toSet();

          final groupRows = _rows.asMap().entries.where((e) {
            final rowVal = (e.value[widget.groupByFieldKey]
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '');
            if (isOther) {
              return rowVal == groupKey ||
                  (rowVal.isNotEmpty && !knownKeys.contains(rowVal));
            }
            return rowVal == groupKey;
          }).toList();

          final isChecked =
              groupRows.isNotEmpty || (_expandedGroups[groupKey] == true);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isChecked ? AppColors.navyMid : AppColors.lightBorder,
                width: isChecked ? 1.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: isChecked
                      ? AppColors.navyMid.withValues(alpha: 0.04)
                      : Colors.white,
                  child: InkWell(
                    onTap: widget.readOnly
                        ? null
                        : () => _toggleCategory(opt, groupKey, !isChecked),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isChecked,
                            activeColor: AppColors.navyMid,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: widget.readOnly
                                ? null
                                : (bool? val) => _toggleCategory(
                                    opt, groupKey, val ?? false),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              opt,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: isChecked
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isChecked
                                    ? AppColors.navyDark
                                    : AppColors.lightText,
                              ),
                            ),
                          ),
                          Icon(
                            isChecked
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: isChecked
                                ? AppColors.navyMid
                                : AppColors.lightSubText,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isChecked) ...[
                  const Divider(height: 1, color: AppColors.lightBorder),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildGroupRowForm(opt, groupKey, groupRows),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
