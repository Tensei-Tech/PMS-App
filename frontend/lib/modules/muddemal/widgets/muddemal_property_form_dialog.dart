// lib/modules/muddemal/widgets/muddemal_property_form_dialog.dart
// Schema-driven dynamic property addition/editing dialog.
// Categories, dropdown options, and custom fields are 100% backend-driven.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/dynamic_form/dynamic_field_model.dart';
import '../models/muddemal_models.dart';
import '../providers/muddemal_provider.dart';

class MuddemalPropertyFormDialog extends StatefulWidget {
  final MuddemalPropertyItem? existingProperty;

  const MuddemalPropertyFormDialog({super.key, this.existingProperty});

  @override
  State<MuddemalPropertyFormDialog> createState() =>
      _MuddemalPropertyFormDialogState();
}

class _MuddemalPropertyFormDialogState
    extends State<MuddemalPropertyFormDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedRegisterId;
  String? _selectedCategoryCode;
  final _descriptionCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  String _selectedUnit = 'Numbers';
  final _unitValueCtrl = TextEditingController(text: '0');
  final _totalItemValueCtrl = TextEditingController(text: '0');
  final _ownerNameCtrl = TextEditingController();
  final _seizedFromCtrl = TextEditingController();
  final _seizureDateCtrl = TextEditingController();
  String _selectedStatus = 'Seized';
  bool _fslRequired = false;
  final _remarksCtrl = TextEditingController();

  // Dynamic category-specific field values and controllers
  final Map<String, TextEditingController> _dynamicControllers = {};
  final Map<String, dynamic> _dynamicValues = {};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _seizureDateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (widget.existingProperty != null) {
      final p = widget.existingProperty!;
      _selectedRegisterId = p.muddemalRecordId;
      _selectedCategoryCode = p.categoryCode;
      _descriptionCtrl.text = p.description;
      _quantityCtrl.text = p.quantity.toString();
      _selectedUnit = p.unit;
      _unitValueCtrl.text = p.unitValue.toString();
      _totalItemValueCtrl.text = p.totalItemValue.toString();
      _ownerNameCtrl.text = p.ownerName;
      _seizedFromCtrl.text = p.seizedFrom;
      _seizureDateCtrl.text = p.seizureDate ?? '';
      _selectedStatus = p.propertyStatus;
      _fslRequired = p.fslRequired;
      _remarksCtrl.text = p.remarks;

      if (p.categoryAttributes.isNotEmpty) {
        _dynamicValues.addAll(p.categoryAttributes);
        p.categoryAttributes.forEach((key, val) {
          _dynamicControllers[key] =
              TextEditingController(text: val?.toString() ?? '');
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MuddemalProvider>();
      if (_selectedRegisterId == null && provider.registers.isNotEmpty) {
        setState(() {
          _selectedRegisterId = provider.activeRegister?.id ?? provider.registers.first.id;
        });
      }
      if (_selectedCategoryCode == null && provider.categories.isNotEmpty) {
        setState(() {
          _selectedCategoryCode = provider.categories.first.categoryCode;
        });
      }
      if (_selectedCategoryCode != null) {
        _onCategoryChanged(_selectedCategoryCode!);
      }
    });

    _quantityCtrl.addListener(_recalculateTotal);
    _unitValueCtrl.addListener(_recalculateTotal);
  }

  void _recalculateTotal() {
    final qty = double.tryParse(_quantityCtrl.text.trim()) ?? 1.0;
    final unitVal = double.tryParse(_unitValueCtrl.text.trim()) ?? 0.0;
    final total = qty * unitVal;
    if (total > 0) {
      _totalItemValueCtrl.text = total.toStringAsFixed(2);
    }
  }

  void _onCategoryChanged(String categoryCode) {
    setState(() {
      _selectedCategoryCode = categoryCode;
    });

    final provider = context.read<MuddemalProvider>();
    provider.loadCategoryFields(categoryCode).then((fields) {
      if (mounted) {
        setState(() {
          for (final f in fields) {
            if (!_dynamicControllers.containsKey(f.fieldKey)) {
              _dynamicControllers[f.fieldKey] = TextEditingController(
                text: _dynamicValues[f.fieldKey]?.toString() ??
                    f.fieldConfig?['default_value']?.toString() ??
                    '',
              );
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _quantityCtrl.dispose();
    _unitValueCtrl.dispose();
    _totalItemValueCtrl.dispose();
    _ownerNameCtrl.dispose();
    _seizedFromCtrl.dispose();
    _seizureDateCtrl.dispose();
    _remarksCtrl.dispose();
    for (final c in _dynamicControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Collect category-specific dynamic extra fields
    final extraFields = <String, dynamic>{};
    _dynamicControllers.forEach((key, ctrl) {
      if (ctrl.text.trim().isNotEmpty) {
        extraFields[key] = ctrl.text.trim();
      }
    });
    // Add dropdown/boolean values
    _dynamicValues.forEach((key, val) {
      if (!extraFields.containsKey(key) && val != null) {
        extraFields[key] = val;
      }
    });

    final provider = context.read<MuddemalProvider>();
    final matchedCategory = provider.categories.where(
      (c) => c.categoryCode == _selectedCategoryCode,
    ).firstOrNull;

    final seizureDateVal = _seizureDateCtrl.text.trim();

    final payload = <String, dynamic>{
      'category_code': _selectedCategoryCode,
      if (matchedCategory != null) 'property_category': matchedCategory.id,
      'description': _descriptionCtrl.text.trim(),
      'quantity': double.tryParse(_quantityCtrl.text.trim()) ?? 1.0,
      'unit': _selectedUnit,
      'unit_value': double.tryParse(_unitValueCtrl.text.trim()) ?? 0.0,
      'total_item_value':
          double.tryParse(_totalItemValueCtrl.text.trim()) ?? 0.0,
      'owner_name': _ownerNameCtrl.text.trim(),
      'seized_from': _seizedFromCtrl.text.trim(),
      'seizure_date': seizureDateVal.isEmpty ? null : seizureDateVal,
      'property_status': _selectedStatus,
      'fsl_required': _fslRequired,
      'remarks': _remarksCtrl.text.trim(),
      'extra_fields': extraFields,
    };

    if (widget.existingProperty != null) {
      if (widget.existingProperty!.muddemalRecordId > 0) {
        payload['muddemal_record'] = widget.existingProperty!.muddemalRecordId;
      }
    } else if (_selectedRegisterId != null) {
      payload['muddemal_record'] = _selectedRegisterId;
    }

    bool ok = false;
    if (widget.existingProperty != null) {
      ok = await provider.updateProperty(widget.existingProperty!.id, payload);
      if (ok) {
        provider.loadProperties();
      }
    } else {
      final res = await provider.addProperty(payload);
      ok = (res != null);
      if (ok) {
        provider.loadProperties();
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (ok) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingProperty != null
                  ? 'Property updated successfully.'
                  : 'Property registered in Muddemal with verified UID.',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Submission failed.'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MuddemalProvider>();
    final categories = provider.categories;
    final units = provider.measurementUnits;
    final statuses = provider.propertyStatuses;
    final currentFields = provider.currentCategoryFields;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.lightSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850, maxHeight: 900),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.navyMid.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.inventory_2_rounded,
                              color: AppColors.navyMid, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.existingProperty != null
                                  ? 'Edit Muddemal Property (${() {
                                      try {
                                        final d = widget.existingProperty!.displayCrNumber;
                                        if (d.isNotEmpty) return d;
                                      } catch (_) {}
                                      final u = widget.existingProperty!.propertyUid;
                                      final match = RegExp(r'(CR-[0-9A-Za-z]+/\d{4})').firstMatch(u);
                                      return match != null ? match.group(1)! : u;
                                    }()})'
                                  : 'Add Property to Muddemal Register',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyDark,
                              ),
                            ),
                            Builder(
                              builder: (_) {
                                final selectedReg = provider.registers
                                        .where((r) => r.id == _selectedRegisterId)
                                        .firstOrNull ??
                                    provider.activeRegister;
                                  return Text(
                                    selectedReg != null
                                        ? 'CR: ${selectedReg.crNumberSnapshot} | ${selectedReg.stationName}'
                                        : provider.fillDynamicInfoLabel,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.lightSubText,
                                    ),
                                  );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 28),

                // Scrollable Form Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECTION 0: Linked Case / Register (Backend Database)
                        if (widget.existingProperty == null && provider.registers.isNotEmpty) ...[
                          _buildSectionHeader('0. Linked Case / CR Register (Backend Database)'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: provider.registers.any((r) => r.id == _selectedRegisterId)
                                ? _selectedRegisterId
                                : provider.registers.first.id,
                            decoration: _inputDecoration(
                              label: 'Select Case / CR Register *',
                              icon: Icons.folder_shared_rounded,
                            ),
                            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
                            items: provider.registers.map((r) {
                              return DropdownMenuItem<int>(
                                value: r.id,
                                child: Text(
                                  '${r.crNumberSnapshot} (${r.registerNo}) - ${r.stationName}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedRegisterId = val);
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // SECTION 1: Category Selection
                        _buildSectionHeader('1. ${provider.propertyCategoryLabel} (Backend-Driven)'),
                        const SizedBox(height: 8),
                        if (categories.isEmpty)
                          const Center(child: CircularProgressIndicator())
                        else
                          DropdownButtonFormField<String>(
                            value: _selectedCategoryCode ??
                                (categories.isNotEmpty
                                    ? categories.first.categoryCode
                                    : null),
                            decoration: _inputDecoration(
                              label: provider.selectPropertyCategoryLabel,
                              icon: Icons.category_rounded,
                            ),
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: AppColors.lightText),
                            items: categories.map((c) {
                              return DropdownMenuItem<String>(
                                value: c.categoryCode,
                                child: Text(c.categoryName),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) _onCategoryChanged(val);
                            },
                          ),
                        const SizedBox(height: 20),

                        // SECTION 2: General & Valuation Info
                        _buildSectionHeader('2. General & Automatic Valuation Details'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _descriptionCtrl,
                          decoration: _inputDecoration(
                            label: 'Description / Item Title *',
                            icon: Icons.description_rounded,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Description is required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _quantityCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(
                                  label: 'Quantity *',
                                  icon: Icons.format_list_numbered_rounded,
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Enter quantity'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: units.contains(_selectedUnit)
                                    ? _selectedUnit
                                    : (units.isNotEmpty ? units.first : 'Numbers'),
                                decoration: _inputDecoration(
                                  label: 'Unit *',
                                  icon: Icons.straighten_rounded,
                                ),
                                items: units
                                    .map((u) => DropdownMenuItem(
                                        value: u, child: Text(u)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _selectedUnit = v);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _unitValueCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(
                                  label: 'Unit Value (₹)',
                                  icon: Icons.currency_rupee_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 4,
                              child: TextFormField(
                                controller: _totalItemValueCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(
                                  label: 'Total Value (₹) *',
                                  icon: Icons.account_balance_wallet_rounded,
                                  hint: 'Quantity x Unit Value or Valuation',
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Valuation is required'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _ownerNameCtrl,
                                decoration: _inputDecoration(
                                  label: 'Owner Name',
                                  icon: Icons.person_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _seizedFromCtrl,
                                decoration: _inputDecoration(
                                  label: 'Seized / Recovered From',
                                  icon: Icons.location_on_rounded,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _seizureDateCtrl,
                                decoration: _inputDecoration(
                                  label: 'Seizure Date (YYYY-MM-DD)',
                                  icon: Icons.calendar_today_rounded,
                                ),
                                onTap: () async {
                                  final dt = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (dt != null) {
                                    _seizureDateCtrl.text =
                                        DateFormat('yyyy-MM-dd').format(dt);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: statuses.contains(_selectedStatus)
                                    ? _selectedStatus
                                    : (statuses.isNotEmpty
                                        ? statuses.first
                                        : 'Seized'),
                                decoration: _inputDecoration(
                                  label: 'Property Status *',
                                  icon: Icons.shield_rounded,
                                ),
                                items: statuses
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedStatus = v);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.navyMid.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.navyMid.withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _fslRequired,
                                activeColor: AppColors.navyMid,
                                onChanged: (v) =>
                                    setState(() => _fslRequired = v ?? false),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Forensic Science Laboratory (FSL) examination required for this property',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.navyDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // SECTION 3: Dynamic Category-Specific Fields
                        _buildSectionHeader(
                          '3. ${provider.categorySpecificInfoLabel} ($_selectedCategoryCode)',
                        ),
                        const SizedBox(height: 10),
                        if (provider.isFieldsLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (currentFields.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Standard fields apply for this category. Additional fields are loaded dynamically.',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: AppColors.lightSubText),
                            ),
                          )
                        else
                          ...currentFields.map((f) => _buildDynamicField(f)),

                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _remarksCtrl,
                          maxLines: 2,
                          decoration: _inputDecoration(
                            label: 'Remarks / Custody Notes',
                            icon: Icons.notes_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 24),
                // Footer Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: AppColors.lightSubText),
                      ),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyMid,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(
                        widget.existingProperty != null
                            ? 'Save Changes'
                            : 'Register Property',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.navyMid.withOpacity(0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: AppColors.navyMid, width: 4)),
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.navyMid,
        ),
      ),
    );
  }

  Widget _buildDynamicField(DynamicFieldDef fieldDef) {
    final ctrl = _dynamicControllers[fieldDef.fieldKey] ??
        TextEditingController(
            text: _dynamicValues[fieldDef.fieldKey]?.toString() ?? '');
    _dynamicControllers[fieldDef.fieldKey] = ctrl;

    if (fieldDef.fieldType == 'dropdown' && fieldDef.options.isNotEmpty) {
      String? currentVal = _dynamicValues[fieldDef.fieldKey]?.toString();
      if (currentVal == null || !fieldDef.options.contains(currentVal)) {
        currentVal = fieldDef.options.first;
        _dynamicValues[fieldDef.fieldKey] = currentVal;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 14.0),
        child: DropdownButtonFormField<String>(
          value: currentVal,
          decoration: _inputDecoration(
            label: '${fieldDef.fieldLabel}${fieldDef.isRequired ? ' *' : ''}',
            icon: Icons.list_alt_rounded,
          ),
          items: fieldDef.options
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _dynamicValues[fieldDef.fieldKey] = val;
              ctrl.text = val ?? '';
            });
          },
          validator: fieldDef.isRequired
              ? (v) => (v == null || v.isEmpty) ? '${fieldDef.fieldLabel} required' : null
              : null,
        ),
      );
    } else if (fieldDef.fieldType == 'checkbox') {
      bool isChecked = _dynamicValues[fieldDef.fieldKey] == true ||
          ctrl.text.toLowerCase() == 'true';
      return Padding(
        padding: const EdgeInsets.only(bottom: 14.0),
        child: Row(
          children: [
            Checkbox(
              value: isChecked,
              activeColor: AppColors.navyMid,
              onChanged: (val) {
                setState(() {
                  _dynamicValues[fieldDef.fieldKey] = val;
                  ctrl.text = val.toString();
                });
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fieldDef.fieldLabel,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.lightText),
              ),
            ),
          ],
        ),
      );
    } else if (fieldDef.fieldType == 'date') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14.0),
        child: TextFormField(
          controller: ctrl,
          decoration: _inputDecoration(
            label: '${fieldDef.fieldLabel}${fieldDef.isRequired ? ' *' : ''}',
            icon: Icons.calendar_month_rounded,
          ),
          onTap: () async {
            final dt = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (dt != null) {
              ctrl.text = DateFormat('yyyy-MM-dd').format(dt);
              _dynamicValues[fieldDef.fieldKey] = ctrl.text;
            }
          },
          validator: fieldDef.isRequired
              ? (v) => (v == null || v.trim().isEmpty) ? '${fieldDef.fieldLabel} required' : null
              : null,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: TextFormField(
        controller: ctrl,
        maxLines: fieldDef.fieldType == 'textarea' ? 3 : 1,
        keyboardType: (fieldDef.fieldType == 'number' || fieldDef.fieldType == 'decimal')
            ? TextInputType.number
            : TextInputType.text,
        decoration: _inputDecoration(
          label: '${fieldDef.fieldLabel}${fieldDef.isRequired ? ' *' : ''}',
          icon: (fieldDef.fieldType == 'number' || fieldDef.fieldType == 'decimal')
              ? Icons.numbers_rounded
              : Icons.edit_note_rounded,
        ),
        onChanged: (val) => _dynamicValues[fieldDef.fieldKey] = val,
        validator: fieldDef.isRequired
            ? (v) => (v == null || v.trim().isEmpty) ? '${fieldDef.fieldLabel} required' : null
            : null,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppColors.navyMid),
      labelStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightSubText),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.lightBorder.withOpacity(0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.navyMid, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.03),
    );
  }
}
