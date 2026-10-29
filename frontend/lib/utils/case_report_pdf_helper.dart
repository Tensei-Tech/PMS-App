import 'package:flutter/material.dart';

import '../modules/core/models/base_record.dart';
import '../services/case_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_pdf_preview_dialog.dart';
import '../widgets/pdf_document_view_screen.dart';

/// View and PDF of a "1 to 5" / Part 6 case, the same way the RTI tab does
/// it: the server builds one report PDF; View shows it read-only (no action
/// buttons) and PDF opens it in the preview dialog to save or share.
class CaseReportPdfHelper {
  CaseReportPdfHelper._();

  static String _tabName(ModuleRecord record) =>
      record.subCategory?.isNotEmpty == true ? record.subCategory! : record.title;

  static String _docTitle(ModuleRecord record) {
    final cr = record.caseNumber.trim();
    return [_tabName(record), cr].where((x) => x.isNotEmpty && x != '-').join(' - ');
  }

  static void _fail(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.dangerRed),
    );
  }

  static Future<void> view(BuildContext context, ModuleRecord record) async {
    final bytes = await CaseService().fetchCaseReportPdfBytes(record.id);
    if (!context.mounted) return;
    if (bytes == null || bytes.isEmpty) {
      _fail(context, 'Failed to load case details.');
      return;
    }
    await PdfDocumentViewScreen.open(context,
        pdfBytes: bytes, moduleName: _tabName(record));
  }

  static Future<void> download(BuildContext context, ModuleRecord record) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Generating case PDF report...'),
          duration: Duration(seconds: 2)),
    );
    final bytes = await CaseService().fetchCaseReportPdfBytes(record.id);
    if (!context.mounted) return;
    if (bytes == null || bytes.isEmpty) {
      _fail(context, 'Failed to generate PDF report.');
      return;
    }
    final title = _docTitle(record);
    await CustomPdfPreviewDialog.show(
      context: context,
      title: title,
      fileName: '${title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}.pdf',
      buildPdf: (_) async => bytes,
    );
  }
}
