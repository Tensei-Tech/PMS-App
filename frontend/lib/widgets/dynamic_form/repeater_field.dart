import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'dynamic_control_factory.dart';
import 'dynamic_field_model.dart';

class RepeaterField extends StatefulWidget {
  final Map<String, dynamic> config;
  final String label;
  final String fieldKey;
  final dynamic value; // This should be a List<Map<String, dynamic>>
  final ValueChanged<dynamic>? onChanged;
  final bool readOnly;

  const RepeaterField({
    super.key,
    required this.config,
    required this.label,
    required this.fieldKey,
    this.value,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  State<RepeaterField> createState() => _RepeaterFieldState();
}

class _RepeaterFieldState extends State<RepeaterField> {
  List<Map<String, dynamic>> _items = [];
  late List<DynamicFieldDef> _subFields;

  @override
  void initState() {
    super.initState();
    _initSubFields();
    _initItems();
  }

  void _initSubFields() {
    final rawFields = widget.config['fields'] as List? ?? [];
    _subFields = rawFields.map((f) {
      return DynamicFieldDef(
        fieldDefId: 0,
        fieldLabel: f['label'] ?? '',
        fieldKey: f['key'] ?? '',
        fieldSource: 'custom',
        fieldType: f['type'] ?? 'text',
        isRequired: false,
        displayOrder: 0,
        fieldConfig: f['config'],
      );
    }).toList();
  }

  void _initItems() {
    if (widget.value != null && widget.value is List) {
      _items = List<Map<String, dynamic>>.from(
          (widget.value as List).map((e) => Map<String, dynamic>.from(e)));
    } else {
      _items = [];
    }
  }

  void _notifyChanged() {
    widget.onChanged?.call(_items);
  }

  void _addItem() {
    setState(() {
      _items.add({});
      _notifyChanged();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _notifyChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            if (!widget.readOnly)
              ElevatedButton.icon(
                onPressed: _addItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyMid,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: Text(
                  'Add Item',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Center(
              child: Text(
                'No items added yet.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.lightSubText,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 16),
            itemBuilder: (ctx, index) {
              final itemValues = _items[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.lightBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Item #${index + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navyMid,
                          ),
                        ),
                        if (!widget.readOnly)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.dangerRed, size: 20),
                            onPressed: () => _removeItem(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Render sub-fields using DynamicControlFactory
                    ..._subFields.map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DynamicControlFactory(
                          fieldDef: f,
                          value: itemValues[f.fieldKey],
                          allValues: itemValues, // Pass local item values for dependencies
                          onChanged: (val) {
                            setState(() {
                              itemValues[f.fieldKey] = val;
                              _notifyChanged();
                            });
                          },
                          readOnly: widget.readOnly,
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
