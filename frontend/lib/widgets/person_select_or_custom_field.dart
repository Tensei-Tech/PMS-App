// lib/widgets/person_select_or_custom_field.dart
// Dropdown of persons (accused) with type new name custom option.

import 'package:flutter/material.dart';
import '../utils/translation_helper.dart';

class PersonSelectOrCustomField extends StatefulWidget {
  const PersonSelectOrCustomField({
    super.key,
    required this.label,
    required this.options,
    required this.ctrl,
    required this.decoration,
    required this.style,
    this.otherLabel = 'Type New Name',
    this.onChanged,
    this.isRequired = false,
  });

  final String label;
  final List<String> options;
  final TextEditingController ctrl;
  final InputDecoration decoration;
  final TextStyle style;
  final String otherLabel;
  final void Function(String)? onChanged;
  final bool isRequired;

  @override
  State<PersonSelectOrCustomField> createState() =>
      _PersonSelectOrCustomFieldState();
}

class _PersonSelectOrCustomFieldState
    extends State<PersonSelectOrCustomField> {
  String? _selected;
  final _customCtrl = TextEditingController();

  List<String> get _cleanOptions => widget.options
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty && e != 'Other (Type New Name)')
      .toSet()
      .toList();

  @override
  void initState() {
    super.initState();
    _initSelected();
  }

  @override
  void didUpdateWidget(covariant PersonSelectOrCustomField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options ||
        oldWidget.ctrl.text != widget.ctrl.text) {
      _initSelected();
    }
  }

  void _initSelected() {
    final t = widget.ctrl.text.trim();
    final clean = _cleanOptions;
    if (t.isEmpty) {
      _selected = null;
      _customCtrl.clear();
    } else if (clean.contains(t)) {
      _selected = t;
    } else {
      _selected = 'Other (Type New Name)';
      _customCtrl.text = t;
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOther = _selected == 'Other (Type New Name)';
    final dropdownItems = [
      ..._cleanOptions,
      'Other (Type New Name)',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: dropdownItems.contains(_selected) ? _selected : null,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
          menuMaxHeight: 300,
          isExpanded: true,
          decoration: widget.decoration.copyWith(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          style: widget.style,
          icon: const Icon(Icons.arrow_drop_down,
              size: 20, color: Color(0xFF64748B)),
          hint: Text(
            TranslationHelper.translate(context, widget.label),
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          items: dropdownItems
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    TranslationHelper.translate(context, e),
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                  )))
              .toList(),
          validator: (v) {
            if (widget.isRequired && widget.ctrl.text.trim().isEmpty) {
              return '${widget.label} is required';
            }
            return null;
          },
          onChanged: (v) {
            setState(() {
              _selected = v;
              if (v != null && v != 'Other (Type New Name)') {
                widget.ctrl.text = v;
                widget.onChanged?.call(v);
              } else if (v == 'Other (Type New Name)') {
                widget.ctrl.text = _customCtrl.text;
                widget.onChanged?.call(_customCtrl.text);
              }
            });
          },
        ),
        if (isOther) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _customCtrl,
            style: widget.style,
            decoration: widget.decoration.copyWith(
              hintText: TranslationHelper.translate(context, widget.otherLabel),
              labelText:
                  TranslationHelper.translate(context, widget.otherLabel),
            ),
            onChanged: (v) {
              widget.ctrl.text = v;
              widget.onChanged?.call(v);
            },
          ),
        ],
      ],
    );
  }
}
