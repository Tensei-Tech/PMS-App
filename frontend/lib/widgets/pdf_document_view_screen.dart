// lib/widgets/pdf_document_view_screen.dart
// Read-only "View" page that shows a record exactly as its PDF looks
// (no print or download; the module's PDF button still offers those).

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../theme/app_theme.dart';
import '../utils/translation_helper.dart';
import 'module_hub_screen_app_bar.dart';

class PdfDocumentViewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String moduleName;

  const PdfDocumentViewScreen({
    super.key,
    required this.pdfBytes,
    required this.moduleName,
  });

  /// Opens the view page for [pdfBytes] under the module's name.
  static Future<void> open(
    BuildContext context, {
    required Uint8List pdfBytes,
    required String moduleName,
  }) {
    return Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: PdfDocumentViewScreen(pdfBytes: pdfBytes, moduleName: moduleName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = TranslationHelper.translate(context, moduleName);
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: '${TranslationHelper.translate(context, 'View')} $name',
        subtitle: name,
      ),
      body: PdfPreview(
        build: (_) async => pdfBytes,
        useActions: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        initialPageFormat: PdfPageFormat.a4,
        maxPageWidth: 850,
        scrollViewDecoration: const BoxDecoration(color: AppColors.lightBg),
        previewPageMargin:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
