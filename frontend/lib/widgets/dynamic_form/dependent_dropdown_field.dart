import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/api_config.dart';

class DependentDropdownField extends StatefulWidget {
  final Map<String, dynamic> config;
  final String label;
  final String fieldKey;
  final dynamic value;
  final Map<String, dynamic>? allValues;
  final ValueChanged<dynamic>? onChanged;
  final bool readOnly;

  const DependentDropdownField({
    super.key,
    required this.config,
    required this.label,
    required this.fieldKey,
    this.value,
    this.allValues,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  State<DependentDropdownField> createState() => _DependentDropdownFieldState();
}

class _DependentDropdownFieldState extends State<DependentDropdownField> {
  List<Map<String, dynamic>> _options = [];
  bool _isLoading = false;
  dynamic _parentValue;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkDependencyAndFetch();
  }

  @override
  void didUpdateWidget(DependentDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasDependencyChanged(oldWidget)) {
      if (widget.value != null) {
        // Clear the current value if the parent changed
        widget.onChanged?.call(null);
      }
      _checkDependencyAndFetch();
    }
  }

  bool _hasDependencyChanged(DependentDropdownField oldWidget) {
    final dependsOn = widget.config['depends_on'];
    if (dependsOn == null) return false;
    
    final oldParentVal = oldWidget.allValues?[dependsOn];
    final newParentVal = widget.allValues?[dependsOn];
    return oldParentVal != newParentVal;
  }

  Future<void> _checkDependencyAndFetch() async {
    final dependsOn = widget.config['depends_on'];
    if (dependsOn != null) {
      final currentParentVal = widget.allValues?[dependsOn];
      if (currentParentVal == null || currentParentVal.toString().isEmpty) {
        setState(() {
          _options = [];
          _parentValue = null;
        });
        return;
      }
      if (_parentValue == currentParentVal) return;
      _parentValue = currentParentVal;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String apiUrl = widget.config['api_url'] ?? '';
      if (dependsOn != null && _parentValue != null) {
        apiUrl = apiUrl.replaceAll('{parent_value}', _parentValue.toString());
      }
      
      if (!apiUrl.startsWith('http')) {
        apiUrl = '${ApiConfig.baseUrl}/$apiUrl';
      }
      
      final response = await _apiService.get(apiUrl);
      if (response.isSuccess && response.data is List) {
        setState(() {
          _options = (response.data as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error fetching dropdown data: $e');
      setState(() {
        _options = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelKey = widget.config['label_key'] ?? 'name';
    final valueKey = widget.config['value_key'] ?? 'id';

    final dependsOn = widget.config['depends_on'];
    final isDependencyMissing = dependsOn != null && widget.allValues?[dependsOn] == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Text(
                widget.label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DYNAMIC',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: widget.readOnly || isDependencyMissing ? AppColors.lightBg : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.lightBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _isLoading
              ? const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyMid),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<dynamic>(
                    isExpanded: true,
                    value: _options.any((o) => o[valueKey].toString() == widget.value?.toString())
                        ? widget.value?.toString()
                        : null,
                    hint: Text(
                      isDependencyMissing 
                          ? 'Select parent first...' 
                          : 'Select ${widget.label}...',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.lightSubText,
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.lightText),
                    items: _options.map((opt) {
                      return DropdownMenuItem<dynamic>(
                        value: opt[valueKey].toString(),
                        child: Text(
                          opt[labelKey]?.toString() ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.navyDark,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (widget.readOnly || isDependencyMissing)
                        ? null
                        : (val) {
                            if (widget.onChanged != null) {
                              widget.onChanged!(val);
                            }
                          },
                  ),
                ),
        ),
      ],
    );
  }
}
