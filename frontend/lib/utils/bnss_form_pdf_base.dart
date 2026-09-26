import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'form_image_pdf_helper.dart';
import 'pdf_font_cache.dart';

Future<void> previewBnssFormPdf(
  BuildContext context,
  Map<String, dynamic> doc, {
  required String filePrefix,
  required String titleEn,
  required String titleMr,
  required List<BnssPdfSection> sections,
}) async {
  final fileName = '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  try {
    final pages = _buildBnssWidgetPages(doc,
        titleEn: titleEn, titleMr: titleMr, sections: sections);
    if (pages.isNotEmpty) {
      await FormImagePdfHelper.previewImageBasedPdf(
        context,
        fileName: fileName,
        pages: pages,
        fallbackPdfGenerator: () => generateBnssFormPdf(
          doc,
          titleEn: titleEn,
          titleMr: titleMr,
          sections: sections,
        ),
      );
      return;
    }
  } catch (e) {
    debugPrint('Error generating image-based BNSS PDF: $e');
  }

  if (!context.mounted) return;
  try {
    final bytes = await generateBnssFormPdf(
      doc,
      titleEn: titleEn,
      titleMr: titleMr,
      sections: sections,
    );
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  } catch (_) {}
}

class BnssPdfSection {
  final String id;
  final String headingEn;
  final String headingMr;
  final List<String> fieldKeys;
  final Map<String, String> labels;

  const BnssPdfSection({
    required this.id,
    required this.headingEn,
    required this.headingMr,
    this.fieldKeys = const [],
    this.labels = const {},
  });
}

List<Widget> _buildBnssWidgetPages(
  Map<String, dynamic> doc, {
  required String titleEn,
  required String titleMr,
  required List<BnssPdfSection> sections,
}) {
  String v(String key) => doc[key]?.toString().trim() ?? '';
  final active = v('formSection');

  bool showSection(String id) {
    if (active.isEmpty) return true;
    if (sections.every((s) => s.id != active)) return true;
    return active == id;
  }

  final pageWidgets = <Widget>[];

  for (final section in sections) {
    if (!showSection(section.id)) continue;
    final keys = section.fieldKeys.isNotEmpty
        ? section.fieldKeys
        : doc.keys
            .where((k) =>
                k != 'formSection' && k != 'pageRange' && k != 'noticeType')
            .cast<String>()
            .toList();

    pageWidgets.add(
      FormImagePdfHelper.buildA4Page(
        children: [
          Center(
            child: Text(
              titleEn,
              style: GoogleFonts.lora(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ),
          Center(
            child: Text(
              titleMr,
              style: FormImagePdfHelper.mBld(13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          if (section.headingEn.isNotEmpty)
            Text(
              section.headingEn,
              style: GoogleFonts.lora(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          if (section.headingMr.isNotEmpty)
            Text(
              section.headingMr,
              style: FormImagePdfHelper.mReg(10.5),
            ),
          const SizedBox(height: 12),
          for (final key in keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.labels[key] ?? key,
                    style: GoogleFonts.lora(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  if ((section.labels['${key}_mr'] ?? '').isNotEmpty)
                    Text(
                      section.labels['${key}_mr']!,
                      style: FormImagePdfHelper.mReg(9.5),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    v(key).isEmpty ? '—' : v(key),
                    style: FormImagePdfHelper.valStyle(10),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  return pageWidgets;
}

Future<Uint8List> generateBnssFormPdf(
  Map<String, dynamic> doc, {
  required String titleEn,
  required String titleMr,
  required List<BnssPdfSection> sections,
}) async {
  final pdf = pw.Document();
  final loraRegular = await PdfFontCache.loraRegular();
  final loraBold = await PdfFontCache.loraBold();
  final devanagari = await PdfFontCache.devanagariRegular();
  final devanagariBold = await PdfFontCache.devanagariBold();

  final body = pw.TextStyle(font: loraRegular, fontSize: 10);
  final bold = pw.TextStyle(
    font: loraBold,
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
  );
  final title = pw.TextStyle(
    font: loraBold,
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
  );
  final mr = pw.TextStyle(font: devanagari, fontSize: 9);
  final mrBold = pw.TextStyle(font: devanagariBold, fontSize: 10);

  String v(String key) => doc[key]?.toString().trim() ?? '';
  final active = v('formSection');

  bool showSection(String id) {
    if (active.isEmpty) return true;
    if (sections.every((s) => s.id != active)) return true;
    return active == id;
  }

  pw.Widget row(String en, String mrLabel, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(en, style: bold),
          if (mrLabel.isNotEmpty) pw.Text(mrLabel, style: mr),
          pw.Text(value.isEmpty ? '—' : value, style: body),
        ],
      ),
    );
  }

  for (final section in sections) {
    if (!showSection(section.id)) continue;
    final keys = section.fieldKeys.isNotEmpty
        ? section.fieldKeys
        : doc.keys
            .where(
              (k) =>
                  k != 'formSection' && k != 'pageRange' && k != 'noticeType',
            )
            .cast<String>()
            .toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: pw.Text(titleEn, style: title)),
            pw.Center(child: pw.Text(titleMr, style: mrBold)),
            pw.SizedBox(height: 8),
            pw.Text(section.headingEn, style: bold),
            pw.Text(section.headingMr, style: mr),
            pw.SizedBox(height: 10),
            for (final key in keys)
              row(
                section.labels[key] ?? key,
                section.labels['${key}_mr'] ?? '',
                v(key),
              ),
          ],
        ),
      ),
    );
  }

  return pdf.save();
}

Future<void> previewMinimalMarathiFormPdf(
  BuildContext context,
  Map<String, dynamic> doc, {
  required String filePrefix,
  required String titleMr,
  required String titleEn,
  required List<String> fieldKeys,
  Map<String, String> labels = const {},
}) async {
  final fileName = '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  try {
    String v(String key) => doc[key]?.toString().trim() ?? '';
    final pageWidget = FormImagePdfHelper.buildA4Page(
      children: [
        Center(
          child: Text(
            titleMr,
            style: FormImagePdfHelper.mBld(14)
                .copyWith(decoration: TextDecoration.underline),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            titleEn,
            style: GoogleFonts.lora(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ),
        const SizedBox(height: 16),
        for (final key in fieldKeys) ...[
          Text(
            labels[key] ?? key,
            style: FormImagePdfHelper.mBld(10.5),
          ),
          const SizedBox(height: 2),
          Text(
            v(key).isEmpty ? '—' : v(key),
            style: FormImagePdfHelper.valStyle(10),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );

    final bytes =
        await FormImagePdfHelper.buildPdfFromWidgets(context, [pageWidget]);
    if (!context.mounted) return;
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
    }
    return;
  } catch (e) {
    debugPrint('Error generating image-based minimal Marathi PDF: $e');
  }

  if (!context.mounted) return;
  try {
    final bytes = await generateMinimalMarathiFormPdf(
      doc,
      titleMr: titleMr,
      titleEn: titleEn,
      fieldKeys: fieldKeys,
      labels: labels,
    );
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  } catch (_) {}
}

Future<Uint8List> generateMinimalMarathiFormPdf(
  Map<String, dynamic> doc, {
  required String titleMr,
  required String titleEn,
  required List<String> fieldKeys,
  Map<String, String> labels = const {},
}) async {
  final pdf = pw.Document();
  final loraBold = await PdfFontCache.loraBold();
  final devanagari = await PdfFontCache.devanagariRegular();

  final bold = pw.TextStyle(
    font: loraBold,
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
  );
  final value = pw.TextStyle(
    font: devanagari,
    fontSize: 10,
    color: PdfColors.black,
  );

  String v(String key) => doc[key]?.toString().trim() ?? '';

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(titleMr, style: bold),
          pw.Text(titleEn, style: bold),
          pw.SizedBox(height: 12),
          for (final key in fieldKeys) ...[
            pw.Text(labels[key] ?? key, style: bold),
            pw.Text(v(key).isEmpty ? '—' : v(key), style: value),
            pw.SizedBox(height: 6),
          ],
        ],
      ),
    ),
  );

  return pdf.save();
}
