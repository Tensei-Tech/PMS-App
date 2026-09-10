// lib/widgets/custom_pdf_preview_dialog.dart
// Interactive, smooth in-app PDF preview dialog with zoom, print, download, and page navigation.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class CustomPdfPreviewDialog extends StatelessWidget {
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;
  final String title;
  final String fileName;

  const CustomPdfPreviewDialog({
    super.key,
    required this.buildPdf,
    this.title = 'Document Preview',
    this.fileName = 'Document.pdf',
  });

  /// Shows a modal full-screen PDF preview dialog
  static Future<void> show({
    required BuildContext context,
    required Future<Uint8List> Function(PdfPageFormat format) buildPdf,
    String title = 'Document Preview',
    String fileName = 'Document.pdf',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1050,
            maxHeight: 900,
          ),
          child: CustomPdfPreviewDialog(
            buildPdf: buildPdf,
            title: title,
            fileName: fileName,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Close Preview',
        ),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded,
                color: Color(0xFF0EA5E9), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Download PDF',
            onPressed: () async {
              try {
                final bytes = await buildPdf(PdfPageFormat.a4);
                await Printing.sharePdf(bytes: bytes, filename: fileName);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Download failed: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PdfPreview(
        build: buildPdf,
        pdfFileName: fileName,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        initialPageFormat: PdfPageFormat.a4,
        allowPrinting: true,
        allowSharing: true,
        maxPageWidth: 750,
        loadingWidget: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
              ),
              const SizedBox(height: 16),
              Text(
                'Rendering Document Preview...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFEF4444), size: 48),
                const SizedBox(height: 12),
                Text(
                  'Failed to render PDF preview',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  '$error',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        previewPageMargin:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actionBarTheme: const PdfActionBarTheme(
          backgroundColor: Color(0xFF0F172A),
          iconColor: Colors.white,
          textStyle: TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}
