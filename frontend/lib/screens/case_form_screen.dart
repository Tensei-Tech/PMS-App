// lib/screens/case_form_screen.dart
// Unified shim routing CaseFormScreen callers to the database-driven DynamicFormScreen.

import 'package:flutter/material.dart';
import '../modules/core/models/base_record.dart';
import '../widgets/dynamic_form/dynamic_form_screen.dart';

class CaseFormScreen extends StatelessWidget {
  final String categoryName;
  final ModuleRecord? existingCase;

  const CaseFormScreen({
    super.key,
    required this.categoryName,
    this.existingCase,
  });

  @override
  Widget build(BuildContext context) {
    return DynamicFormScreen(
      moduleLabel: categoryName,
      moduleKey: existingCase?.moduleKey ?? 'crime',
      subCategory: categoryName,
      existingRecord: existingCase,
    );
  }
}
