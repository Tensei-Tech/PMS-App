import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class SearchableMultiSelect extends StatefulWidget {
  final String label;
  final List<String> options;
  final List<String> initialValues;
  final ValueChanged<List<String>> onChanged;
  final bool readOnly;

  const SearchableMultiSelect({
    super.key,
    required this.label,
    required this.options,
    required this.initialValues,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  State<SearchableMultiSelect> createState() => _SearchableMultiSelectState();
}

class _SearchableMultiSelectState extends State<SearchableMultiSelect> {
  late List<String> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = List.from(widget.initialValues);
  }

  void _showSelectionDialog() {
    if (widget.readOnly) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return _MultiSelectDialog(
          label: widget.label,
          options: widget.options,
          initialSelected: _selectedValues,
          onApply: (newValues) {
            setState(() {
              _selectedValues = newValues;
            });
            widget.onChanged(_selectedValues);
          },
        );
      },
    );
  }

  void _removeValue(String val) {
    if (widget.readOnly) return;
    setState(() {
      _selectedValues.remove(val);
    });
    widget.onChanged(_selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The Dropdown-like Button
        InkWell(
          onTap: _showSelectionDialog,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.readOnly ? const Color(0xFFF8FAFC) : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _selectedValues.isEmpty
                      ? Text(
                          'Select ${widget.label}...',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.lightSubText,
                          ),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _selectedValues.map((val) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.navyMid.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    val,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                  if (!widget.readOnly) ...[
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => _removeValue(val),
                                      child: const Icon(Icons.close,
                                          size: 14, color: AppColors.dangerRed),
                                    ),
                                  ]
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down, color: AppColors.lightSubText),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MultiSelectDialog extends StatefulWidget {
  final String label;
  final List<String> options;
  final List<String> initialSelected;
  final ValueChanged<List<String>> onApply;

  const _MultiSelectDialog({
    required this.label,
    required this.options,
    required this.initialSelected,
    required this.onApply,
  });

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late List<String> _tempSelected;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.initialSelected);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredOptions = widget.options
        .where((opt) => opt.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select ${widget.label}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.lightBorder),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredOptions.isEmpty
                  ? Center(
                      child: Text(
                        'No options found',
                        style: GoogleFonts.poppins(color: AppColors.lightSubText),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredOptions.length,
                      itemBuilder: (ctx, i) {
                        final opt = filteredOptions[i];
                        final isSelected = _tempSelected.contains(opt);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.navyMid,
                          title: Text(
                            opt,
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _tempSelected.add(opt);
                              } else {
                                _tempSelected.remove(opt);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.lightSubText)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onApply(_tempSelected);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyMid,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: Text('Apply', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
