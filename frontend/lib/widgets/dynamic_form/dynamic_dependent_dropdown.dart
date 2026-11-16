// lib/widgets/dynamic_form/dynamic_dependent_dropdown.dart
// 'dependent_dropdown' field: options from field_config.api_url, keeping the
// chosen row's id (value_key) and showing its label (label_key). With
// field_config.depends_on it follows another field (e.g. Section after Act).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/dynamic_options_service.dart';
import '../../theme/app_theme.dart';
import 'dynamic_field_model.dart';

typedef DependentOptionsLoader = Future<List<Map<String, dynamic>>> Function(
    String route);

class DynamicDependentDropdown extends StatefulWidget {
  final DynamicFieldDef fieldDef;
  final dynamic value;

  /// Values the parent field is read from (the form, or a repeater row).
  final Map<String, dynamic>? formValues;
  final TextEditingController? controller;
  final ValueChanged<dynamic>? onChanged;
  final bool readOnly;
  final InputDecoration decoration;

  /// Replaces the network loader in tests.
  @visibleForTesting
  static DependentOptionsLoader? loaderForTesting;

  const DynamicDependentDropdown({
    super.key,
    required this.fieldDef,
    required this.decoration,
    this.value,
    this.formValues,
    this.controller,
    this.onChanged,
    this.readOnly = false,
  });

  static const String parentPlaceholder = '{parent_value}';

  Map<String, dynamic> get _config => fieldDef.fieldConfig ?? const {};
  String get apiUrl => _config['api_url']?.toString().trim() ?? '';
  String get labelKey => _config['label_key']?.toString() ?? '';
  String get valueKey => _config['value_key']?.toString() ?? 'id';
  String? get dependsOn {
    final d = _config['depends_on']?.toString().trim();
    return (d == null || d.isEmpty) ? null : d;
  }

  String get parentValue =>
      dependsOn == null ? '' : _text(formValues?[dependsOn!]);

  /// The route to load now, or null while the parent has no value.
  String? get route {
    if (apiUrl.isEmpty) return null;
    if (dependsOn != null && parentValue.isEmpty) return null;
    return apiUrl.replaceAll(
        parentPlaceholder, Uri.encodeQueryComponent(parentValue));
  }

  static String _text(dynamic v) {
    if (v == null) return '';
    final s = v.toString().trim();
    return s == 'null' ? '' : s;
  }

  @override
  State<DynamicDependentDropdown> createState() =>
      _DynamicDependentDropdownState();
}

class _DynamicDependentDropdownState extends State<DynamicDependentDropdown> {
  List<Map<String, dynamic>> _rows = const [];
  String? _loadedRoute;
  bool _loading = false;
  String? _error;
  int _request = 0;

  /// The parent answer last seen (the form's values map is changed in place,
  /// so the old widget cannot tell what it was).
  String _parentSeen = '';

  @override
  void initState() {
    super.initState();
    _parentSeen = widget.parentValue;
    _loadFor(widget.route);
  }

  @override
  void didUpdateWidget(covariant DynamicDependentDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent moved from one answer to another (not filled in for the
    // first time while a record opens): this answer no longer fits, clear it.
    final oldParent = _parentSeen;
    _parentSeen = widget.parentValue;
    // Inside a repeater row the row group clears it (row widgets are not
    // keyed, so after a row is removed they would see another row's parent)
    if (widget.fieldDef.parentFieldKey == null &&
        widget.dependsOn != null &&
        oldParent.isNotEmpty &&
        oldParent != widget.parentValue &&
        DynamicDependentDropdown._text(widget.value).isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.controller?.clear();
        widget.onChanged?.call(null);
      });
    }
    if (widget.route != _loadedRoute) _loadFor(widget.route);
  }

  Future<void> _loadFor(String? route) async {
    final request = ++_request;
    _loadedRoute = route;
    // Called from initState / didUpdateWidget / a tap, all followed by a
    // build, so the fields are set directly here
    _error = null;
    if (route == null) {
      _rows = const [];
      _loading = false;
      return;
    }
    _loading = true;
    try {
      final loader = DynamicDependentDropdown.loaderForTesting ??
          DynamicOptionsService().fetchRecords;
      final rows = await loader(route);
      if (!mounted || request != _request) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _rows = const [];
        _loading = false;
        _error = 'Could not load ${widget.fieldDef.fieldLabel}';
      });
    }
  }

  String _labelOf(Map<String, dynamic> row) {
    final key = widget.labelKey;
    final v = (key.isNotEmpty ? row[key] : null) ??
        row['display_name'] ??
        row['name'] ??
        row['label'] ??
        row[widget.valueKey];
    return v?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final current = DynamicDependentDropdown._text(widget.value) != ''
        ? DynamicDependentDropdown._text(widget.value)
        : (widget.controller?.text.trim() ?? '');

    final items = <DropdownMenuItem<String>>[];
    final rawById = <String, dynamic>{};
    for (final row in _rows) {
      final raw = row[widget.valueKey];
      final id = DynamicDependentDropdown._text(raw);
      if (id.isEmpty || rawById.containsKey(id)) continue;
      rawById[id] = raw;
      items.add(_item(id, _labelOf(row)));
    }
    // An answer the list does not hold (older records typed the Act or
    // Section as text): kept and shown as it was saved.
    final isOldText = current.isNotEmpty && !rawById.containsKey(current);
    if (isOldText) {
      items.insert(
          0,
          _item(current, _loading ? current : '$current (earlier entry)',
              italic: !_loading));
    }

    final waitingForParent =
        widget.dependsOn != null && widget.parentValue.isEmpty;
    final parentLabel =
        widget.fieldDef.fieldConfig?['depends_on_label']?.toString() ??
            'the field above';
    var decoration = widget.decoration;
    if (waitingForParent && current.isEmpty) {
      decoration = decoration.copyWith(hintText: 'Select $parentLabel first');
    }
    if (_loading) {
      decoration = decoration.copyWith(
        suffixIcon: const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.navyMid),
          ),
        ),
      );
    } else if (_error != null) {
      decoration = decoration.copyWith(
        errorText: _error,
        suffixIcon: IconButton(
          tooltip: 'Retry',
          icon: const Icon(Icons.refresh, size: 18, color: AppColors.dangerRed),
          onPressed: () => setState(() {
            _loadFor(widget.route);
          }),
        ),
      );
    }

    final canPick = !widget.readOnly && !_loading && items.isNotEmpty;
    return DropdownButtonFormField<String>(
      // Rebuilt when the list or the answer changes (cleared, re-opened)
      key: ValueKey('${widget.fieldDef.fieldKey}|$_loadedRoute|'
          '${items.length}|$current'),
      isExpanded: true,
      menuMaxHeight: 360,
      initialValue: current.isEmpty ? null : current,
      items: items,
      onChanged: canPick
          ? (id) {
              if (id == null || id == current) return;
              final raw = rawById.containsKey(id) ? rawById[id] : id;
              widget.controller?.text = id;
              widget.onChanged?.call(raw);
            }
          : null,
      decoration: decoration,
      validator: (v) {
        if (widget.fieldDef.isRequired && (v == null || v.isEmpty)) {
          return '${widget.fieldDef.fieldLabel} is required';
        }
        return null;
      },
    );
  }

  DropdownMenuItem<String> _item(String id, String label,
          {bool italic = false}) =>
      DropdownMenuItem<String>(
        value: id,
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.lightText,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      );
}
