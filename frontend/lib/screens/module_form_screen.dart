// lib/screens/module_form_screen.dart
// Unified shim forwarding ModuleFormScreen callers to the single-source-of-truth DynamicFormScreen.

import 'package:flutter/material.dart';
import '../modules/core/models/base_record.dart';
import '../widgets/dynamic_form/dynamic_form_screen.dart';

class ModuleFormScreen extends StatefulWidget {
  final String moduleLabel;
  final String moduleKey;
  final String? subCategory;
  final ModuleRecord? existingRecord;

  const ModuleFormScreen({
    super.key,
    required this.moduleLabel,
    required this.moduleKey,
    this.subCategory,
    this.existingRecord,
  });

  @override
  State<ModuleFormScreen> createState() => _ModuleFormScreenState();
}

class _ModuleFormScreenState extends State<ModuleFormScreen> {
  @override
  Widget build(BuildContext context) {
    return DynamicFormScreen(
      moduleLabel: widget.moduleLabel,
      moduleKey: widget.moduleKey,
      subCategory: widget.subCategory,
      existingRecord: widget.existingRecord,
    );
  }
}
