// lib/screens/module_form_screen.dart
// Unified shim forwarding ModuleFormScreen callers to the single-source-of-truth DynamicFormScreen.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../modules/absconded/providers/absconded_provider.dart';
import '../modules/accident/providers/accident_provider.dart';
import '../modules/accidental_death/providers/accidental_death_provider.dart';
import '../modules/application/providers/application_provider.dart';
import '../modules/arrested/providers/arrested_provider.dart';
import '../modules/bnss/providers/bnss_provider.dart';
import '../modules/coin/providers/coin_provider.dart';
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
