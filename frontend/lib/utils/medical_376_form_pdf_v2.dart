// lib/utils/medical_376_form_pdf_v2.dart
//
// 376 Medical Examination Form PDF Generator (Phase A: Sections 1–14).
// High-fidelity A4 (794x1123 px) layout matching the editable form widgets.
// No shared file modifications, strict pixelRatio 3.0, null-safe captures,
// clean progress indicator, automatic block-packing without orphan headers.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'form_image_pdf_helper.dart';

// ── Constants ──────────────────────────────────────────────────────────────────
const double _kPageW = 794.0;
const double _kPageH = 1123.0;
const double _kPadH = 36.0;
const double _kPadV = 32.0;
const double _kContentW = _kPageW - (2 * _kPadH); // 722.0 px
const double _kMaxPageContentH = _kPageH - (2 * _kPadV) - 30.0; // ~1029 px
const double _kLineH = 22.0;

// ── Public Entry Point ─────────────────────────────────────────────────────────

Future<void> previewMedical376FormPdfV2(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      '376_Medical_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';

  final statusNotifier = ValueNotifier<String>('Preparing form data...');
  BuildContext? dialogContext;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      dialogContext = ctx;
      return PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.white,
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ValueListenableBuilder<String>(
              valueListenable: statusNotifier,
              builder: (_, status, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 18),
                  Flexible(
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  try {
    // 60-second safety timeout to ensure spinner is never stuck indefinitely
    final result = await buildMedical376FormPdfDocumentV2(
      context,
      doc,
      onStatus: (msg) => statusNotifier.value = msg,
      onProgress: (cur, tot) =>
          statusNotifier.value = 'Generating page $cur of $tot...',
    ).timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw TimeoutException(
        'PDF generation timed out after 60 seconds. Please check device memory and try again.',
      ),
    );

    // Close progress modal before presenting PDF
    if (dialogContext != null && dialogContext!.mounted) {
      final nav = Navigator.of(dialogContext!, rootNavigator: true);
      if (nav.canPop()) nav.pop();
      dialogContext = null;
    }

    statusNotifier.value = 'Opening PDF preview / download...';

    // Present PDF with web fallback
    if (kIsWeb) {
      try {
        await Printing.sharePdf(bytes: result.pdfBytes, filename: fileName);
      } catch (shareErr) {
        debugPrint(
            'Printing.sharePdf failed on Web, falling back to layoutPdf: $shareErr');
        await Printing.layoutPdf(
          onLayout: (_) async => result.pdfBytes,
          name: fileName,
        );
      }
    } else {
      await Printing.layoutPdf(
        onLayout: (_) async => result.pdfBytes,
        name: fileName,
      );
    }
  } catch (e, st) {
    debugPrint('Error generating 376 Medical PDF: $e\n$st');
    // Ensure progress modal is closed
    if (dialogContext != null && dialogContext!.mounted) {
      final nav = Navigator.of(dialogContext!, rootNavigator: true);
      if (nav.canPop()) nav.pop();
      dialogContext = null;
    }
    if (context.mounted) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('PDF Generation Error'),
          content: Text(
            e is TimeoutException
                ? e.message ?? 'PDF generation timed out.'
                : 'Failed to generate PDF: $e',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  } finally {
    if (dialogContext != null && dialogContext!.mounted) {
      final nav = Navigator.of(dialogContext!, rootNavigator: true);
      if (nav.canPop()) nav.pop();
      dialogContext = null;
    }
  }
}

bool _medical376FontsPreloaded = false;

Future<({Uint8List pdfBytes, int pageCount, List<Uint8List> pageImages})>
    buildMedical376FormPdfDocumentV2(
  BuildContext context,
  Map<String, dynamic> doc, {
  void Function(String message)? onStatus,
  void Function(int current, int total)? onProgress,
}) async {
  final swTotal = Stopwatch()..start();
  final swFont = Stopwatch()..start();

  // 1. Ensure Devanagari and serif fonts are loaded (cached after first run)
  if (!_medical376FontsPreloaded) {
    try {
      await GoogleFonts.pendingFonts()
          .timeout(const Duration(milliseconds: 300));
      _medical376FontsPreloaded = true;
    } catch (_) {}
  }
  swFont.stop();

  final sectionKey = (doc['formSection'] ?? '').toString().toLowerCase();
  final isFemaleSection = sectionKey.contains('female');
  final isMaleSection = sectionKey.contains('male') && !isFemaleSection;
  final isMale = isMaleSection;

  // 2. Build discrete content blocks
  final blocks = isMale
      ? _buildMaleBlocks(doc)
      : [
          ..._buildFemalePhaseABlocks(doc),
          ..._buildFemalePhaseBBlocks(doc),
          ..._buildFemalePhaseCBlocks(doc),
        ];

  onStatus?.call('Calculating page layout...');
  final swMeasure = Stopwatch()..start();

  // 3. Measure every block's real RenderBox height offscreen at content width 722px
  if (!context.mounted) {
    return (pdfBytes: Uint8List(0), pageCount: 0, pageImages: <Uint8List>[]);
  }
  final measured = await _measureBlocks(context, blocks);
  debugPrint('=== 376 Medical Form Measured Block Heights ===');
  for (int i = 0; i < blocks.length; i++) {
    debugPrint(
        '  [${blocks[i].id.padRight(28)}] -> ${measured.heights[i].toStringAsFixed(1)} px');
  }

  final pagesBlocks = _packBlocksIntoPages(
    blocks,
    measured.heights,
    measured.headerHeights,
  );
  swMeasure.stop();
  final totalPages = pagesBlocks.length;

  // 4. Build page widgets
  final pageWidgets = <Widget>[];
  for (int i = 0; i < totalPages; i++) {
    pageWidgets.add(_buildA4Page(
      content: pagesBlocks[i],
      pageNumber: i + 1,
      totalPages: totalPages,
    ));
  }

  if (!context.mounted) {
    return (pdfBytes: Uint8List(0), pageCount: 0, pageImages: <Uint8List>[]);
  }

  final pdfDoc = pw.Document();

  // 5. Sequential single-page capture directly into pw.Document with immediate disposal
  final captureResult = await _captureOffscreenPagesSequential(
    context,
    pageWidgets,
    pdfDoc: pdfDoc,
    onStatus: onStatus,
    onProgress: onProgress,
  );

  final capturedBytes = captureResult.images;
  if (capturedBytes.isEmpty) {
    throw StateError('Failed to capture any pages for 376 Medical Form');
  }

  // 6. Save PDF document
  onStatus?.call('Finalizing PDF document...');
  final swSave = Stopwatch()..start();
  final pdfBytes = await pdfDoc.save();
  swSave.stop();
  swTotal.stop();

  // Print comprehensive timing and size report
  debugPrint('=== 376 Medical PDF Timing & Size Report ===');
  debugPrint('1. Font Load: ${swFont.elapsedMilliseconds} ms');
  debugPrint(
      '2. Block Measure & Pack: ${swMeasure.elapsedMilliseconds} ms ($totalPages pages total)');
  debugPrint('3. Sequential Render & Encode:');
  double totalImageKb = 0.0;
  for (int i = 0; i < captureResult.images.length; i++) {
    final kb = captureResult.images[i].lengthInBytes / 1024.0;
    totalImageKb += kb;
    final toImg = i < captureResult.toImageTimes.length
        ? captureResult.toImageTimes[i]
        : 0;
    final enc =
        i < captureResult.encodeTimes.length ? captureResult.encodeTimes[i] : 0;
    debugPrint(
        '   Page ${i + 1} of $totalPages: toImage: ${toImg}ms, encode: ${enc}ms | Size: ${kb.toStringAsFixed(1)} KB');
  }
  debugPrint(
      '   Total Captured Images Size: ${totalImageKb.toStringAsFixed(1)} KB');
  debugPrint(
      '4. PDF Doc Save: ${swSave.elapsedMilliseconds} ms | Total PDF Size: ${(pdfBytes.lengthInBytes / 1024.0).toStringAsFixed(1)} KB (${(pdfBytes.lengthInBytes / (1024.0 * 1024.0)).toStringAsFixed(2)} MB)');
  debugPrint(
      '>>> TOTAL TIME (Start -> Ready): ${swTotal.elapsedMilliseconds} ms ($totalPages pages) <<<');

  return (
    pdfBytes: pdfBytes,
    pageCount: capturedBytes.length,
    pageImages: capturedBytes,
  );
}

// ── Block Structure ────────────────────────────────────────────────────────────

class Medical376Block {
  final String id;
  final Widget widget;
  final bool keepWithNext;
  final Widget? tableHeaderToRepeat;
  final double estimatedHeight;

  const Medical376Block({
    this.id = '',
    required this.widget,
    this.keepWithNext = false,
    this.tableHeaderToRepeat,
    this.estimatedHeight = 40.0,
  });
}

typedef _ContentBlock = Medical376Block;

// ── Typography ─────────────────────────────────────────────────────────────────

TextStyle _fSerif({
  double size = 11.0,
  FontWeight weight = FontWeight.normal,
  FontStyle style = FontStyle.normal,
  FontStyle? fontStyle,
  Color? color,
  double? height,
}) =>
    GoogleFonts.lora(
      fontSize: size,
      fontWeight: weight,
      fontStyle: fontStyle ?? style,
      height: height,
      color: color ?? Colors.black87,
    );

TextStyle _fMarathi({
  double size = 10.0,
  FontWeight weight = FontWeight.normal,
  FontStyle style = FontStyle.normal,
  FontStyle? fontStyle,
  Color? color,
  double? height,
}) =>
    GoogleFonts.notoSansDevanagari(
      fontSize: size,
      fontWeight: weight,
      fontStyle: fontStyle ?? style,
      height: height,
      color: color ?? Colors.black87,
    );

// ── Text Sanitization & Formatting Helpers ─────────────────────────────────────

String _wrapLongWords(String text) {
  if (text.isEmpty) return text;
  final buffer = StringBuffer();
  int currentRun = 0;
  for (int i = 0; i < text.length; i++) {
    final char = text[i];
    if (char == ' ' || char == '\n' || char == '\t') {
      currentRun = 0;
      buffer.write(char);
    } else {
      currentRun++;
      if (currentRun >= 20) {
        buffer.write('\u200B');
        currentRun = 0;
      }
      buffer.write(char);
    }
  }
  return buffer.toString();
}

String _formatDate(String raw) {
  if (raw.trim().isEmpty) return '';
  final s = raw.trim();
  try {
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
      final dt = DateTime.tryParse(s);
      if (dt != null) {
        final day = dt.day.toString().padLeft(2, '0');
        final month = dt.month.toString().padLeft(2, '0');
        final year = dt.year.toString();
        return '$day/$month/$year';
      }
    }
  } catch (_) {}
  return s;
}

String _formatDateTime(String raw) {
  if (raw.trim().isEmpty) return '';
  final s = raw.trim();
  try {
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
      final dt = DateTime.tryParse(s);
      if (dt != null) {
        final day = dt.day.toString().padLeft(2, '0');
        final month = dt.month.toString().padLeft(2, '0');
        final year = dt.year.toString();
        if (s.contains('T') || s.contains(' ')) {
          int hour = dt.hour;
          final minute = dt.minute.toString().padLeft(2, '0');
          final ampm = hour >= 12 ? 'PM' : 'AM';
          hour = hour % 12;
          if (hour == 0) hour = 12;
          final hourStr = hour.toString().padLeft(2, '0');
          return '$day/$month/$year $hourStr:$minute $ampm';
        }
        return '$day/$month/$year';
      }
    }
    final timeMatch = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s);
    if (timeMatch != null && !s.contains('/')) {
      int hour = int.parse(timeMatch.group(1)!);
      final min = timeMatch.group(2)!;
      final ampm = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '${hour.toString().padLeft(2, '0')}:$min $ampm';
    }
  } catch (_) {}
  return s;
}

// ── ReadOnly Section Widgets (Exact Form Visuals) ──────────────────────────────

Widget _buildSectionHeader(String en, String mr) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 8, bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      border: Border.all(color: Colors.black26, width: 0.8),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            en,
            style: _fSerif(size: 11, weight: FontWeight.bold),
          ),
        ),
        if (mr.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            mr,
            style: _fMarathi(size: 10, weight: FontWeight.bold),
          ),
        ],
      ],
    ),
  );
}

Widget _buildUnderlineValue(String val, {int minLines = 1}) {
  final clean = _wrapLongWords(val.trim());
  if (minLines <= 1) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 2),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black87, width: 0.8)),
      ),
      child: Text(
        clean.isEmpty ? ' ' : clean,
        style: _fMarathi(size: 11, weight: FontWeight.w600),
      ),
    );
  }

  // Multi-line ruled box
  final lines = clean.isEmpty ? [''] : clean.split('\n');
  final count = lines.length > minLines ? lines.length : minLines;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: List.generate(count, (idx) {
      final lineText = idx < lines.length ? lines[idx] : '';
      return Container(
        height: _kLineH,
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.only(bottom: 2),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black54, width: 0.8)),
        ),
        child: Text(
          lineText.isEmpty ? ' ' : lineText,
          style: _fMarathi(size: 10.5, weight: FontWeight.w600),
        ),
      );
    }),
  );
}

Widget _buildBilingualField({
  required String labelEn,
  required String labelMr,
  required String value,
  int minLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          labelEn,
          style: _fSerif(size: 10.5, weight: FontWeight.w600),
        ),
        if (labelMr.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(
            labelMr,
            style: _fMarathi(size: 9.5),
          ),
        ],
        const SizedBox(height: 2),
        _buildUnderlineValue(value, minLines: minLines),
      ],
    ),
  );
}

Widget _buildFieldRow(List<Widget> fields) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 2.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: fields[i]),
        ],
      ],
    ),
  );
}

Widget _buildConsentRadioDot(String label, bool isSelected) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: _fSerif(
          size: 10.5,
          weight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      const SizedBox(width: 4),
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black87, width: 1.2),
        ),
        padding: const EdgeInsets.all(2.5),
        child: isSelected
            ? Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black87,
                ),
              )
            : null,
      ),
    ],
  );
}

Widget _buildConsentYesNoRow({
  required String labelEn,
  required String labelMr,
  required String value,
}) {
  final lower = value.trim().toLowerCase();
  final isYes = lower == 'yes' || lower == 'होय' || lower == 'y';
  final isNo = lower == 'no' || lower == 'नाही' || lower == 'n';

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3.5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(labelEn,
                  style: _fSerif(size: 10.5, weight: FontWeight.w500)),
              if (labelMr.isNotEmpty)
                Text(labelMr, style: _fMarathi(size: 9.5)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildConsentRadioDot('Yes', isYes),
            const SizedBox(width: 14),
            _buildConsentRadioDot('No', isNo),
          ],
        ),
      ],
    ),
  );
}

Widget _buildInlineYesNo(String label, String value) {
  final lower = value.trim().toLowerCase();
  final isYes = lower == 'yes' || lower == 'होय' || lower == 'y';
  final isNo = lower == 'no' || lower == 'नाही' || lower == 'n';

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: _fSerif(size: 10.5)),
      const SizedBox(width: 6),
      _buildConsentRadioDot('Yes', isYes),
      const SizedBox(width: 10),
      _buildConsentRadioDot('No', isNo),
    ],
  );
}

Widget _buildLinedSignatureBox({
  required String titleEn,
  required String titleMr,
  required String text,
  int minLines = 3,
  String? caption,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(titleEn, style: _fSerif(size: 10.5, weight: FontWeight.bold)),
        if (titleMr.isNotEmpty)
          Text(titleMr, style: _fMarathi(size: 9.5, weight: FontWeight.bold)),
        const SizedBox(height: 4),
        _buildUnderlineValue(text, minLines: minLines),
        if (caption != null && caption.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            caption,
            style: _fSerif(size: 9.5, style: FontStyle.italic),
          ),
        ],
      ],
    ),
  );
}

Widget _buildYNDNKSelector(String value) {
  final val = value.trim().toUpperCase();

  Widget opt(String code) {
    final isSelected = val == code;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            code,
            style: _fSerif(
              size: 8.5,
              weight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 1.5),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black87,
                width: 1.0,
              ),
              color: Colors.transparent,
            ),
            padding: const EdgeInsets.all(1.5),
            child: isSelected
                ? Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black87,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 1.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        opt('Y'),
        const SizedBox(width: 2),
        opt('N'),
        const SizedBox(width: 2),
        opt('DNK'),
      ],
    ),
  );
}

Widget _buildYNCell(String code, String value) {
  final isSel = value.trim().toUpperCase() == code.toUpperCase();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 1.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          code,
          style: _fSerif(
            size: 9.0,
            weight: isSel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 2),
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black87,
              width: 1.0,
            ),
            color: Colors.transparent,
          ),
          padding: const EdgeInsets.all(1.8),
          child: isSel
              ? Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black87,
                  ),
                )
              : null,
        ),
      ],
    ),
  );
}

Widget _buildCheckOption(String label, String value) {
  final isSel = value.trim().toLowerCase() == label.trim().toLowerCase();
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
    child: _buildConsentRadioDot(label, isSel),
  );
}

Widget _buildPhysicalViolenceItem(String labelEn, String value) {
  final isChecked =
      value.trim().isNotEmpty && value.trim().toLowerCase() != 'no';
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 1.2),
            borderRadius: BorderRadius.circular(2),
            color: isChecked ? Colors.black87 : Colors.transparent,
          ),
          child: isChecked
              ? const Center(
                  child: Icon(Icons.check, size: 11, color: Colors.white),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            labelEn,
            style: _fSerif(
              size: 9.5,
              weight: isChecked ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTable2Header() {
  return Table(
    border: TableBorder.all(color: Colors.black87, width: 0.8),
    columnWidths: const {
      0: FlexColumnWidth(5.5),
      1: FlexColumnWidth(1.2),
      2: FlexColumnWidth(1.2),
      3: FlexColumnWidth(1.4),
    },
    children: [
      TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text('Activity / Question',
                style: _fSerif(size: 9.5, weight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text('Y',
                textAlign: TextAlign.center,
                style: _fSerif(size: 10, weight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text('N',
                textAlign: TextAlign.center,
                style: _fSerif(size: 10, weight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text('DNK',
                textAlign: TextAlign.center,
                style: _fSerif(size: 10, weight: FontWeight.bold)),
          ),
        ],
      ),
    ],
  );
}

Widget _buildPostIncidentHeader() {
  return Table(
    border: TableBorder.all(color: Colors.black87, width: 0.8),
    columnWidths: const {
      0: FlexColumnWidth(4.0),
      1: FlexColumnWidth(2.5),
      2: FlexColumnWidth(3.5),
    },
    children: [
      TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(
              'Post incident has the survivor',
              style: _fSerif(size: 9.5, weight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(
              'Yes/No/Do Not know',
              textAlign: TextAlign.center,
              style: _fSerif(size: 9.5, weight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(
              'Remarks',
              textAlign: TextAlign.center,
              style: _fSerif(size: 9.5, weight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ],
  );
}

// ── FEMALE PHASE A BLOCKS (Sections 1–14) ──────────────────────────────────────

List<_ContentBlock> _buildFemalePhaseABlocks(Map<String, dynamic> doc) {
  final blocks = <_ContentBlock>[];

  // Block 1: Header / Confidential / Title (NO "(Female)" in header)
  blocks.add(_ContentBlock(
    id: 'f_header_title',
    estimatedHeight: 88.0,
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 0.8),
          ),
          child: Text(
            'महाराष्ट्र शासन — सार्वजनिक आरोग्य विभाग. परिपत्रक क्रमांक: संकीर्ण-२०१४/प्र.क्र.२७०/आरोग्य-३. दिनांक: ०७ ऑगस्ट, २०१५.',
            style: _fMarathi(size: 9.5, weight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('CONFIDENTIAL',
                  style: _fSerif(size: 10, weight: FontWeight.bold)),
              Text('गोपनीय',
                  style: _fMarathi(size: 9, weight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Column(
            children: [
              Text(
                'Medico-legal Examination Report of Sexual Violence',
                textAlign: TextAlign.center,
                style: _fSerif(size: 13.5, weight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'लैंगिक हिंसाचाराचा वैद्यकीय-कायदेशीर तपासणी अहवाल',
                textAlign: TextAlign.center,
                style: _fMarathi(size: 11.5, weight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  ));

  // Section 1–11 Header (keepWithNext)
  blocks.add(_ContentBlock(
    id: 'f_sec_1_11_header',
    estimatedHeight: 36.0,
    widget:
        _buildSectionHeader('1–11. Basic Information', '१–११. मूलभूत माहिती'),
    keepWithNext: true,
  ));

  // 1. Hospital & OPD
  blocks.add(_ContentBlock(
    id: 'f_hospital_opd',
    estimatedHeight: 48.0,
    widget: _buildFieldRow([
      _buildBilingualField(
        labelEn: '1. Hospital',
        labelMr: '१. रुग्णालयाचे नाव',
        value: doc['f_hospital']?.toString() ?? '',
      ),
      _buildBilingualField(
        labelEn: 'OPD No.',
        labelMr: 'बाह्य रुग्ण क्र.',
        value: doc['f_opd']?.toString() ?? '',
      ),
    ]),
  ));

  // Inpatient No.
  blocks.add(_ContentBlock(
    id: 'f_inpatient',
    estimatedHeight: 48.0,
    widget: _buildBilingualField(
      labelEn: 'Inpatient No.',
      labelMr: 'अंतर्गत रुग्ण क्र.',
      value: doc['f_inpatient']?.toString() ?? '',
    ),
  ));

  // 2. Name & Parent
  blocks.add(_ContentBlock(
    id: 'f_name_parent',
    estimatedHeight: 48.0,
    widget: _buildFieldRow([
      _buildBilingualField(
        labelEn: '2. Name',
        labelMr: '२. नाव',
        value: doc['f_name']?.toString() ?? '',
      ),
      _buildBilingualField(
        labelEn: 'D/o or S/o (where known)',
        labelMr: 'मुलगी / मुलगा (माहित असल्यास)',
        value: doc['f_parent']?.toString() ?? '',
      ),
    ]),
  ));

  // 3. Address
  blocks.add(_ContentBlock(
    id: 'f_address',
    estimatedHeight: 72.0,
    widget: _buildBilingualField(
      labelEn: '3. Address',
      labelMr: '३. पत्ता',
      value: doc['f_address']?.toString() ?? '',
      minLines: 2,
    ),
  ));

  // 4. Age & DOB & 5. Sex
  blocks.add(_ContentBlock(
    id: 'f_age_dob_sex',
    estimatedHeight: 48.0,
    widget: _buildFieldRow([
      _buildBilingualField(
        labelEn: '4. Age (as reported)',
        labelMr: '४. वय (सांगितले)',
        value: doc['f_age']?.toString() ?? '',
      ),
      _buildBilingualField(
        labelEn: 'Date of Birth',
        labelMr: 'जन्मतारीख',
        value: _formatDate(doc['f_dob']?.toString() ?? ''),
      ),
      _buildBilingualField(
        labelEn: '5. Sex (M/F/Others)',
        labelMr: '५. लिंग (पु/स्त्री/इ.)',
        value: doc['f_sex']?.toString() ?? '',
      ),
    ]),
  ));

  // 6. Arrival & 7. Exam Start
  blocks.add(_ContentBlock(
    id: 'f_arrival_exam',
    estimatedHeight: 48.0,
    widget: _buildFieldRow([
      _buildBilingualField(
        labelEn: '6. Date and Time of arrival',
        labelMr: '६. रुग्णालयात आगमन दिनांक व वेळ',
        value: _formatDateTime(doc['f_arrival']?.toString() ?? ''),
      ),
      _buildBilingualField(
        labelEn: '7. Date and Time of commencement of examination',
        labelMr: '७. तपासणी सुरू दिनांक व वेळ',
        value: _formatDateTime(doc['f_examStart']?.toString() ?? ''),
      ),
    ]),
  ));

  // 8. Brought by
  blocks.add(_ContentBlock(
    id: 'f_brought_by',
    estimatedHeight: 48.0,
    widget: _buildBilingualField(
      labelEn: '8. Brought by (Name & signatures)',
      labelMr: '८. कोणी आणले (नाव व सही)',
      value: doc['f_broughtBy']?.toString() ?? '',
    ),
  ));

  // 9. MLC No. & Police Station
  blocks.add(_ContentBlock(
    id: 'f_mlc_ps',
    estimatedHeight: 48.0,
    widget: _buildFieldRow([
      _buildBilingualField(
        labelEn: '9. MLC No.',
        labelMr: '९. एम.एल.सी. क्र.',
        value: doc['f_mlc']?.toString() ?? '',
      ),
      _buildBilingualField(
        labelEn: 'Police Station',
        labelMr: 'पोलीस ठाणे',
        value: doc['f_ps']?.toString() ?? '',
      ),
    ]),
  ));

  // 10. Conscious & 11. Disability
  blocks.add(_ContentBlock(
    id: 'f_conscious_disability',
    estimatedHeight: 152.0,
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBilingualField(
          labelEn:
              '10. Whether conscious, oriented in time and place and person',
          labelMr: '१०. जागरूक, वेळ/ठिकाण/व्यक्ती ओळखणारी आहे का',
          value: doc['f_conscious']?.toString() ?? '',
        ),
        _buildBilingualField(
          labelEn: '11. Any physical/intellectual/psychosocial disability',
          labelMr: '११. शारीरिक / बौद्धिक / मानसिक अपंगत्व',
          value: doc['f_disability']?.toString() ?? '',
          minLines: 2,
        ),
        Text(
          '(Interpreters or special educators will be needed where the survivor has special needs such as hearing/speech disability, language barriers, intellectual or psychosocial disability.)',
          style: _fSerif(size: 8.5, style: FontStyle.italic),
        ),
        Text(
          '(श्रवण/वाक् अपंगत्व, भाषा अडथळा, बौद्धिक/मानसिक अपंगत्व असल्यास दुभाषी / विशेष शिक्षक आवश्यक.)',
          style: _fMarathi(size: 8),
        ),
      ],
    ),
  ));

  // Section 12: Informed Consent / refusal (keepWithNext)
  blocks.add(_ContentBlock(
    id: 'f_sec_12_header',
    estimatedHeight: 36.0,
    widget: _buildSectionHeader(
        '12. Informed Consent/refusal', '१२. माहितीपूर्ण संमती / नकार'),
    keepWithNext: true,
  ));

  // Consent Preamble & Radios
  final consentName = (doc['f_consentName'] ?? '').toString().trim();
  final consentParent = (doc['f_consentParent'] ?? '').toString().trim();

  blocks.add(_ContentBlock(
    id: 'f_consent_preamble',
    estimatedHeight: 65.0,
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('I ', style: _fSerif(size: 11, weight: FontWeight.w600)),
            Expanded(
              flex: 5,
              child: _buildUnderlineValue(consentName),
            ),
            const SizedBox(width: 8),
            Text(' D/o or S/o ',
                style: _fSerif(size: 11, weight: FontWeight.w600)),
            Expanded(
              flex: 5,
              child: _buildUnderlineValue(consentParent),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('मी ... मुलगी किंवा मुलगा ... यांची', style: _fMarathi(size: 9.5)),
        const SizedBox(height: 6),
        Text(
          'hereby give my consent for / येथे खालील बाबींसाठी संमती देतो/देते:',
          style: _fSerif(size: 11, weight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        _buildConsentYesNoRow(
          labelEn: 'a)  medical examination for treatment',
          labelMr: 'अ)  उपचारासाठी वैद्यकीय तपासणी',
          value: doc['f_consentTreatment']?.toString() ?? '',
        ),
        _buildConsentYesNoRow(
          labelEn: 'b)  this medico legal examination',
          labelMr: 'ब)  ही वैद्यकीय-कायदेशीर तपासणी',
          value: doc['f_consentMedicoLegal']?.toString() ?? '',
        ),
        _buildConsentYesNoRow(
          labelEn: 'c)  sample collection for clinical & forensic examination',
          labelMr: 'क)  नैदानिक व फॉरेन्सिक नमुने गोळा करणे',
          value: doc['f_consentSample']?.toString() ?? '',
        ),
      ],
    ),
  ));

  // Consent Police revelation & procedures
  final consentLang = (doc['f_consentLanguage'] ?? '').toString().trim();
  final consentRole = (doc['f_consentSupportRole'] ?? '').toString().trim();
  final consentHelperSig = (doc['f_consentHelperSig'] ?? '').toString().trim();

  blocks.add(_ContentBlock(
    id: 'f_consent_police',
    estimatedHeight: 230.0,
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        Text(
          'I also understand that as per law the hospital is required to inform police and this has been explained to me.',
          style: _fSerif(size: 10, height: 1.3),
        ),
        Text(
          'कायद्यानुसार रुग्णालयाने पोलिसांना कळवणे आवश्यक आहे आणि हे मला समजावून सांगितले आहे हे मला समजते.',
          style: _fMarathi(size: 9, height: 1.3),
        ),
        const SizedBox(height: 4),
        _buildConsentYesNoRow(
          labelEn: 'I want the information to be revealed to the police',
          labelMr: 'माहिती पोलिसांना दिली जावी अशी माझी इच्छा आहे',
          value: doc['f_consentPoliceInfo']?.toString() ?? '',
        ),
        const SizedBox(height: 6),
        Text(
          'I have understood the purpose and the procedure of the examination including the risk and benefit, explained to me by the examining doctor. My right to refuse the examination at any stage and the consequence of such refusal, including that my medical treatment will not be affected by my refusal, has also been explained and may be recorded.',
          style: _fSerif(size: 9.5, height: 1.3),
        ),
        Text(
          'तपासणीचा उद्देश, कार्यपद्धती, धोके आणि फायदे तपासणी करणाऱ्या डॉक्टरांनी मला समजावून सांगितले असून ते मला समजले आहेत. कोणत्याही टप्प्यावर तपासणी नाकारण्याचा माझा अधिकार आणि अशा नकाराचा परिणाम, ज्यामध्ये माझ्या वैद्यकीय उपचारांवर परिणाम होणार नाही, हे देखील मला समजावून सांगितले आहे.',
          style: _fMarathi(size: 8.5, height: 1.3),
        ),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Contents explained to me in ', style: _fSerif(size: 10.5)),
            SizedBox(
              width: 110,
              child: _buildUnderlineValue(consentLang),
            ),
            Text(
                ' language with the help of educator/interpreter/support person: ',
                style: _fSerif(size: 10.5)),
            SizedBox(
              width: 140,
              child: _buildUnderlineValue(consentRole),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 5,
              child: Text(
                'If special educator/interpreter/support person has helped, name & signature:\nविशेष शिक्षक/दुभाषी/मदतनीस नाव व सही:',
                style: _fSerif(size: 9.5, style: FontStyle.italic),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: _buildUnderlineValue(consentHelperSig),
            ),
          ],
        ),
      ],
    ),
  ));

  // Survivor & Witness Signature Blocks
  blocks.add(_ContentBlock(
    id: 'f_survivor_sig',
    estimatedHeight: 115.0,
    widget: _buildLinedSignatureBox(
      titleEn:
          'Name & signature of survivor or parent/Guardian/person in whom child reposes trust (<12 yrs)',
      titleMr:
          'पीडित किंवा पालक/पाल्य (<१२ वर्षे असल्यास ज्या व्यक्तीवर विश्वास आहे) यांचे नाव व सही',
      text: doc['f_survivorSig']?.toString() ?? '',
      minLines: 3,
      caption: 'With date, time & place / दिनांक, वेळ आणि ठिकाणासह',
    ),
  ));

  blocks.add(_ContentBlock(
    id: 'f_witness_sig',
    estimatedHeight: 115.0,
    widget: _buildLinedSignatureBox(
      titleEn: 'Name & signature/thumb impression of Witness',
      titleMr: 'साक्षीदाराचे नाव आणि सही / अंगठ्याचा ठसा',
      text: doc['f_witnessSig']?.toString() ?? '',
      minLines: 3,
      caption: 'With Date, time and place / दिनांक, वेळ आणि ठिकाणासह',
    ),
  ));

  // Section 13: Marks of identification (keepWithNext)
  blocks.add(_ContentBlock(
    id: 'f_sec_13_header',
    estimatedHeight: 36.0,
    widget: _buildSectionHeader(
      '13. Marks of identification (Any scar/mole)',
      '१३. ओळखीच्या खुणा (कोणताही व्रण/तीळ)',
    ),
    keepWithNext: true,
  ));

  // Marks Row with Left Thumb Box
  blocks.add(_ContentBlock(
    id: 'f_id_marks_thumb',
    estimatedHeight: 105.0,
    widget: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('(1) ',
                      style: _fSerif(size: 11, weight: FontWeight.bold)),
                  Expanded(
                      child: _buildUnderlineValue(
                          doc['f_idMark1']?.toString() ?? '')),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('(2) ',
                      style: _fSerif(size: 11, weight: FontWeight.bold)),
                  Expanded(
                      child: _buildUnderlineValue(
                          doc['f_idMark2']?.toString() ?? '')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Column(
          children: [
            Container(
              width: 140,
              height: 70,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87, width: 1.0),
              ),
            ),
            const SizedBox(height: 4),
            Text('Left Thumb impression',
                style: _fSerif(size: 10, weight: FontWeight.bold)),
            Text('डाव्या हाताचा अंगठ्याचा ठसा', style: _fMarathi(size: 9)),
          ],
        ),
      ],
    ),
  ));

  // Section 14: Medical/Surgical history (keepWithNext)
  blocks.add(_ContentBlock(
    id: 'f_sec_14_header',
    estimatedHeight: 36.0,
    widget: _buildSectionHeader(
      '14. Relevant Medical/Surgical history',
      '१४. संबंधित वैद्यकीय / शस्त्रक्रिया इतिहास',
    ),
    keepWithNext: true,
  ));

  // Section 14 Boxed Content
  blocks.add(_ContentBlock(
    id: 'f_med_history_box',
    estimatedHeight: 220.0,
    widget: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildInlineYesNo(
                'Onset of menarche (in case of girls): ',
                doc['f_menarcheYesNo']?.toString() ?? '',
              ),
              const SizedBox(width: 20),
              Text('Age of onset: ', style: _fSerif(size: 10.5)),
              SizedBox(
                width: 100,
                child: _buildUnderlineValue(
                    doc['f_menarcheAge']?.toString() ?? ''),
              ),
            ],
          ),
          const Divider(color: Colors.black26, height: 14),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Menstrual history – Cycle length and duration: ',
                  style: _fSerif(size: 10.5)),
              SizedBox(
                width: 120,
                child: _buildUnderlineValue(
                    doc['f_menstrualCycle']?.toString() ?? ''),
              ),
              const SizedBox(width: 16),
              Text('Last menstrual period (LMP): ', style: _fSerif(size: 10.5)),
              SizedBox(
                width: 100,
                child: _buildUnderlineValue(_formatDate(
                    doc['f_lastMenstrualPeriod']?.toString() ?? '')),
              ),
            ],
          ),
          const Divider(color: Colors.black26, height: 14),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildInlineYesNo(
                'Menstruation at incident: ',
                doc['f_menstruationAtIncident']?.toString() ?? '',
              ),
              const SizedBox(width: 20),
              _buildInlineYesNo(
                'Menstruation at examination: ',
                doc['f_menstruationAtExam']?.toString() ?? '',
              ),
            ],
          ),
          const Divider(color: Colors.black26, height: 14),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildInlineYesNo(
                'Was survivor pregnant at incident: ',
                doc['f_pregnantAtIncident']?.toString() ?? '',
              ),
              const SizedBox(width: 16),
              Text('If yes, duration: ', style: _fSerif(size: 10.5)),
              SizedBox(
                width: 90,
                child: _buildUnderlineValue(
                    doc['f_pregnancyDuration']?.toString() ?? ''),
              ),
            ],
          ),
          const Divider(color: Colors.black26, height: 14),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildInlineYesNo(
                'Contraception use: ',
                doc['f_contraceptionUse']?.toString() ?? '',
              ),
              const SizedBox(width: 16),
              Text('If yes – method used: ', style: _fSerif(size: 10.5)),
              SizedBox(
                width: 160,
                child: _buildUnderlineValue(
                    doc['f_contraceptionMethod']?.toString() ?? ''),
              ),
            ],
          ),
          const Divider(color: Colors.black26, height: 14),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Vaccination status – Tetanus: ',
                  style: _fSerif(size: 10.5)),
              SizedBox(
                width: 140,
                child: _buildUnderlineValue(
                    doc['f_vaccinationTetanus']?.toString() ?? ''),
              ),
              const SizedBox(width: 16),
              Text('Hepatitis B: ', style: _fSerif(size: 10.5)),
              SizedBox(
                width: 140,
                child: _buildUnderlineValue(
                    doc['f_vaccinationHepB']?.toString() ?? ''),
              ),
            ],
          ),
        ],
      ),
    ),
  ));

  return blocks;
}

// ── FEMALE PHASE B BLOCKS (Sections 15A–15F & Post-Incident Table) ─────────────

Widget _buildTable2StandardRow(String question, String value,
    {bool isFirst = false}) {
  return Table(
    border: TableBorder(
      left: const BorderSide(color: Colors.black87, width: 0.8),
      right: const BorderSide(color: Colors.black87, width: 0.8),
      bottom: const BorderSide(color: Colors.black87, width: 0.8),
      top: isFirst
          ? const BorderSide(color: Colors.black87, width: 0.8)
          : BorderSide.none,
      verticalInside: const BorderSide(color: Colors.black87, width: 0.8),
    ),
    columnWidths: const {
      0: FlexColumnWidth(5.5),
      1: FlexColumnWidth(1.2),
      2: FlexColumnWidth(1.2),
      3: FlexColumnWidth(1.4),
    },
    children: [
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(question, style: _fSerif(size: 9.5)),
          ),
          _buildYNCell('Y', value),
          _buildYNCell('N', value),
          _buildYNCell('DNK', value),
        ],
      ),
    ],
  );
}

Widget _buildTable2RowWithDesc({
  required String question,
  required String ynValue,
  required String descValue,
  bool isFirst = false,
}) {
  return Table(
    border: TableBorder(
      left: const BorderSide(color: Colors.black87, width: 0.8),
      right: const BorderSide(color: Colors.black87, width: 0.8),
      bottom: const BorderSide(color: Colors.black87, width: 0.8),
      top: isFirst
          ? const BorderSide(color: Colors.black87, width: 0.8)
          : BorderSide.none,
      verticalInside: const BorderSide(color: Colors.black87, width: 0.8),
    ),
    columnWidths: const {
      0: FlexColumnWidth(5.5),
      1: FlexColumnWidth(1.2),
      2: FlexColumnWidth(1.2),
      3: FlexColumnWidth(1.4),
    },
    children: [
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(question, style: _fSerif(size: 9.5)),
          ),
          _buildYNCell('Y', ynValue),
          _buildYNCell('N', ynValue),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
            child: _buildUnderlineValue(descValue),
          ),
        ],
      ),
    ],
  );
}

Widget _buildTable2DescRow(String label, String value, {bool isFirst = false}) {
  return Table(
    border: TableBorder(
      left: const BorderSide(color: Colors.black87, width: 0.8),
      right: const BorderSide(color: Colors.black87, width: 0.8),
      bottom: const BorderSide(color: Colors.black87, width: 0.8),
      top: isFirst
          ? const BorderSide(color: Colors.black87, width: 0.8)
          : BorderSide.none,
      verticalInside: const BorderSide(color: Colors.black87, width: 0.8),
    ),
    columnWidths: const {
      0: FlexColumnWidth(5.5),
      1: FlexColumnWidth(3.8),
    },
    children: [
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(label, style: _fSerif(size: 9.5)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
            child: _buildUnderlineValue(value),
          ),
        ],
      ),
    ],
  );
}

Widget _buildPostIncidentRowWidget({
  required String label,
  required String choice,
  required String remarks,
  bool isFirst = false,
}) {
  return Table(
    border: TableBorder(
      left: const BorderSide(color: Colors.black87, width: 0.8),
      right: const BorderSide(color: Colors.black87, width: 0.8),
      bottom: const BorderSide(color: Colors.black87, width: 0.8),
      top: isFirst
          ? const BorderSide(color: Colors.black87, width: 0.8)
          : BorderSide.none,
      verticalInside: const BorderSide(color: Colors.black87, width: 0.8),
    ),
    columnWidths: const {
      0: FlexColumnWidth(4.0),
      1: FlexColumnWidth(2.5),
      2: FlexColumnWidth(3.5),
    },
    children: [
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(label, style: _fSerif(size: 9.5)),
          ),
          _buildYNDNKSelector(choice),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
            child: _buildUnderlineValue(remarks),
          ),
        ],
      ),
    ],
  );
}

List<_ContentBlock> _buildFemalePhaseBBlocks(Map<String, dynamic> doc) {
  final blocks = <_ContentBlock>[];

  // ── 15 A. History of Sexual Violence ─────────────────────────────────────────
  blocks.add(_ContentBlock(
    id: 'f_sec_15a_header',
    widget: _buildSectionHeader(
      '15 A. History of Sexual Violence',
      '१५ अ. लैंगिक हिंसाचाराचा इतिहास',
    ),
    keepWithNext: true,
  ));

  // Sub-block 1: Date / Time / Location Table
  blocks.add(_ContentBlock(
    id: 'f_15a_datetime_location',
    keepWithNext: true,
    widget: Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87, width: 0.8),
      ),
      child: Table(
        border: const TableBorder(
          verticalInside: BorderSide(color: Colors.black87, width: 0.8),
        ),
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade100),
            children: [
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text('(i) Date of incident/s being reported',
                    style: _fSerif(size: 9.5, weight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text('(ii) Time of incident/s',
                    style: _fSerif(size: 9.5, weight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text('(iii) Location/s',
                    style: _fSerif(size: 9.5, weight: FontWeight.bold)),
              ),
            ],
          ),
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: _buildUnderlineValue(
                    _formatDate(doc['f_incidentDate']?.toString() ?? '')),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: _buildUnderlineValue(
                    _formatDateTime(doc['f_incidentTime']?.toString() ?? '')),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: _buildUnderlineValue(
                    doc['f_incidentLocation']?.toString() ?? ''),
              ),
            ],
          ),
        ],
      ),
    ),
  ));

  // Sub-block 2: Duration & Episode
  blocks.add(_ContentBlock(
    id: 'f_15a_duration_episode',
    keepWithNext: true,
    widget: Container(
      padding: const EdgeInsets.all(6.0),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.black87, width: 0.8),
          right: BorderSide(color: Colors.black87, width: 0.8),
          bottom: BorderSide(color: Colors.black87, width: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('(iv) Estimated duration : ',
                  style: _fSerif(size: 10, weight: FontWeight.bold)),
              _buildCheckOption(
                  '1-7 days', doc['f_estimatedDuration']?.toString() ?? ''),
              _buildCheckOption('1 week to 2 months',
                  doc['f_estimatedDuration']?.toString() ?? ''),
              _buildCheckOption(
                  '2-6 months', doc['f_estimatedDuration']?.toString() ?? ''),
              _buildCheckOption(
                  '>6 months', doc['f_estimatedDuration']?.toString() ?? ''),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Episode: ',
                  style: _fSerif(size: 10, weight: FontWeight.bold)),
              _buildCheckOption('One', doc['f_episode']?.toString() ?? ''),
              _buildCheckOption('Multiple', doc['f_episode']?.toString() ?? ''),
              _buildCheckOption(
                  'Chronic (>6 months)', doc['f_episode']?.toString() ?? ''),
              _buildCheckOption('Unknown', doc['f_episode']?.toString() ?? ''),
            ],
          ),
        ],
      ),
    ),
  ));

  // Sub-block 3: Assailant details
  blocks.add(_ContentBlock(
    id: 'f_15a_assailants',
    widget: Container(
      padding: const EdgeInsets.all(8.0),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.black87, width: 0.8),
          right: BorderSide(color: Colors.black87, width: 0.8),
          bottom: BorderSide(color: Colors.black87, width: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('(v) Number of Assailant(s) and name/s: ',
                  style: _fSerif(size: 10)),
              Expanded(
                  child: _buildUnderlineValue(
                      doc['f_assailantCountAndNames']?.toString() ?? '')),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('(vi) Sex of assailant(s): ', style: _fSerif(size: 10)),
              SizedBox(
                  width: 90,
                  child: _buildUnderlineValue(
                      doc['f_assailantSex']?.toString() ?? '')),
              const SizedBox(width: 14),
              Text('Approx. Age of assailant(s): ', style: _fSerif(size: 10)),
              SizedBox(
                  width: 90,
                  child: _buildUnderlineValue(
                      doc['f_assailantAge']?.toString() ?? '')),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('If known to the survivor – relationship with survivor: ',
                  style: _fSerif(size: 10)),
              Expanded(
                  child: _buildUnderlineValue(
                      doc['f_assailantRelationship']?.toString() ?? '')),
            ],
          ),
        ],
      ),
    ),
  ));

  // Sub-block 4: Narrator Header & First 4 Ruled lines (Seamless connection to p2)
  blocks.add(_ContentBlock(
    id: 'f_15a_narrator_p1',
    widget: Container(
      padding: const EdgeInsets.all(8.0),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.black87, width: 0.8),
          right: BorderSide(color: Colors.black87, width: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('(vii) Description of incident in the words of the narrator:',
              style: _fSerif(size: 10, weight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  'Narrator of the incident: survivor/informant (name & relation): ',
                  style: _fSerif(size: 10)),
              Expanded(
                  child: _buildUnderlineValue(
                      doc['f_narratorDetails']?.toString() ?? '')),
            ],
          ),
          const SizedBox(height: 6),
          _buildUnderlineValue(
            (doc['f_violenceHistory']?.toString() ?? '')
                .split('\n')
                .take(4)
                .join('\n'),
            minLines: 4,
          ),
        ],
      ),
    ),
  ));

  // Sub-block 5: Narrator Remaining Ruled lines & Extra page footnote
  blocks.add(_ContentBlock(
    id: 'f_15a_narrator_p2',
    widget: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.black87, width: 0.8),
          right: BorderSide(color: Colors.black87, width: 0.8),
          bottom: BorderSide(color: Colors.black87, width: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUnderlineValue(
            (doc['f_violenceHistory']?.toString() ?? '')
                .split('\n')
                .skip(4)
                .join('\n'),
            minLines: 4,
          ),
          const SizedBox(height: 4),
          Text(
            'If this space is insufficient use extra page / ही जागा अपुरी असल्यास अतिरिक्त पान वापरा',
            style: _fSerif(size: 9, style: FontStyle.italic),
          ),
        ],
      ),
    ),
  ));

  // ── 15 B. Type of physical violence used ─────────────────────────────────────
  blocks.add(_ContentBlock(
    id: 'f_sec_15b_header',
    widget: _buildSectionHeader(
      '15 B. Type of physical violence used if any (Describe):',
      '१५ ब. शारीरिक हिंसाचाराचा प्रकार (वर्णन करा):',
    ),
    keepWithNext: true,
  ));

  // 15B Table (8 checkboxes in 4 rows, 2 columns)
  blocks.add(_ContentBlock(
    id: 'f_15b_table',
    widget: Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87, width: 0.8),
      ),
      child: Table(
        border: const TableBorder(
          verticalInside: BorderSide(color: Colors.black54, width: 0.8),
          horizontalInside: BorderSide(color: Colors.black26, width: 0.5),
        ),
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            children: [
              _buildPhysicalViolenceItem(
                  'Hit with (Hand, fist, blunt object, sharp object)',
                  doc['f_hitWith']?.toString() ?? ''),
              _buildPhysicalViolenceItem(
                  'Burned with', doc['f_burnedWith']?.toString() ?? ''),
            ],
          ),
          TableRow(
            children: [
              _buildPhysicalViolenceItem(
                  'Biting', doc['f_biting']?.toString() ?? ''),
              _buildPhysicalViolenceItem(
                  'Kicking', doc['f_kicking']?.toString() ?? ''),
            ],
          ),
          TableRow(
            children: [
              _buildPhysicalViolenceItem(
                  'Pinching', doc['f_pinching']?.toString() ?? ''),
              _buildPhysicalViolenceItem(
                  'Pulling Hair', doc['f_pullingHair']?.toString() ?? ''),
            ],
          ),
          TableRow(
            children: [
              _buildPhysicalViolenceItem(
                  'Violent shaking', doc['f_violentShaking']?.toString() ?? ''),
              _buildPhysicalViolenceItem(
                  'Banging head', doc['f_bangingHead']?.toString() ?? ''),
            ],
          ),
        ],
      ),
    ),
  ));

  // ── 15 C. Emotional abuse / Restraints / Weapons / Threats / Luring ──────────
  blocks.add(_ContentBlock(
    id: 'f_sec_15c_header',
    widget: _buildSectionHeader('15 C.', '१५ क.'),
    keepWithNext: true,
  ));

  blocks.add(_ContentBlock(
    id: 'f_15c_box',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBilingualField(
          labelEn:
              'i. Emotional abuse or violence if any (insulting, cursing, belittling, terrorizing):',
          labelMr: '',
          value: doc['f_15cEmotionalAbuse']?.toString() ?? '',
        ),
        _buildBilingualField(
          labelEn:
              'ii. Use of restraints if any (e.g. rope, cloth, handcuffs):',
          labelMr: '',
          value: doc['f_15cRestraints']?.toString() ?? '',
        ),
        _buildBilingualField(
          labelEn:
              'iii. Used or threatened the use of weapon(s) or objects if any:',
          labelMr: '',
          value: doc['f_15cWeapons']?.toString() ?? '',
        ),
        _buildBilingualField(
          labelEn:
              'iv. Verbal threats (e.g. killing/hurting survivor or loved ones, blackmailing) if any:',
          labelMr: '',
          value: doc['f_15cVerbalThreats']?.toString() ?? '',
        ),
        _buildBilingualField(
          labelEn: 'v. Luring (sweets, chocolates, money, job) if any:',
          labelMr: '',
          value: doc['f_15cLuring']?.toString() ?? '',
        ),
        _buildBilingualField(
          labelEn: 'vi. Any other:',
          labelMr: '',
          value: doc['f_15cAnyOther']?.toString() ?? '',
        ),
      ],
    ),
  ));

  // ── 15 D. Intoxication / Unconscious ─────────────────────────────────────────
  blocks.add(_ContentBlock(
    id: 'f_sec_15d_header',
    widget: _buildSectionHeader('15 D.', '१५ ड.'),
    keepWithNext: true,
  ));

  blocks.add(_ContentBlock(
    id: 'f_15d_box',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBilingualField(
          labelEn: 'i. Any H/O drug/alcohol intoxication:',
          labelMr: '',
          value: doc['f_15dIntoxication']?.toString() ?? '',
        ),
        _buildBilingualField(
          labelEn:
              'ii. Whether sleeping or unconscious at the time of the incident:',
          labelMr: '',
          value: doc['f_15dUnconscious']?.toString() ?? '',
        ),
      ],
    ),
  ));

  // ── 15 E. Marks of Injury on Assailant ───────────────────────────────────────
  blocks.add(_ContentBlock(
    id: 'f_sec_15e_header',
    widget: _buildSectionHeader('15 E.', '१५ इ.'),
    keepWithNext: true,
  ));

  blocks.add(_ContentBlock(
    id: 'f_15e_box',
    widget: _buildBilingualField(
      labelEn:
          'If survivor has left any marks of injury on assailant/s, enter details:',
      labelMr: '',
      value: doc['f_15eAssailantInjury']?.toString() ?? '',
    ),
  ));

  // ── 15 F. Details regarding sexual violence (Table 1: Orifice Penetration) ───
  blocks.add(_ContentBlock(
    id: 'f_sec_15f_header',
    widget: _buildSectionHeader(
      '15 F. Details regarding sexual violence:',
      '१५ फ. लैंगिक हिंसाचाराबाबत तपशील:',
    ),
    keepWithNext: true,
  ));

  blocks.add(_ContentBlock(
    id: 'f_15f_table1_orifice',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Was penetration by penis, fingers or object or other body parts (Write Y=Yes, N=No, DNK=Don’t know). Mention and describe body part/s and/or object/s used for penetration.',
          style: _fSerif(size: 9.5, weight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FlexColumnWidth(1.5),
            1: FlexColumnWidth(1.2),
            2: FlexColumnWidth(1.9),
            3: FlexColumnWidth(1.2),
            4: FlexColumnWidth(0.8),
            5: FlexColumnWidth(0.8),
            6: FlexColumnWidth(1.1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: [
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text('Orifice of Victim',
                      style: _fSerif(size: 9.5, weight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Text('Penetration\nBy Penis',
                      textAlign: TextAlign.center,
                      style: _fSerif(size: 8.5, weight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Text('By body part of self / assailant / 3rd party',
                      textAlign: TextAlign.center,
                      style: _fSerif(size: 8.5, weight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Text('Penetration\nBy Object',
                      textAlign: TextAlign.center,
                      style: _fSerif(size: 8.5, weight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Text('Emission\nYes',
                      textAlign: TextAlign.center,
                      style: _fSerif(size: 8.5, weight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Text('Emission\nNO',
                      textAlign: TextAlign.center,
                      style: _fSerif(size: 8.5, weight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Text('Emission\nDon’t know',
                      textAlign: TextAlign.center,
                      style: _fSerif(size: 8.5, weight: FontWeight.bold)),
                ),
              ],
            ),
            // Genitalia
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text('Genitalia\n(Vagina/urethra)',
                      style: _fSerif(size: 9, weight: FontWeight.w600)),
                ),
                _buildYNDNKSelector(
                    doc['f_penGenitaliaPenis']?.toString() ?? ''),
                _buildYNDNKSelector(
                    doc['f_penGenitaliaBodyPart']?.toString() ?? ''),
                _buildYNDNKSelector(
                    doc['f_penGenitaliaObject']?.toString() ?? ''),
                _buildYNCell(
                    'Yes', doc['f_emissionGenitalia']?.toString() ?? ''),
                _buildYNCell(
                    'No', doc['f_emissionGenitalia']?.toString() ?? ''),
                _buildYNCell(
                    'DNK', doc['f_emissionGenitalia']?.toString() ?? ''),
              ],
            ),
            // Anus
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text('Anus',
                      style: _fSerif(size: 9, weight: FontWeight.w600)),
                ),
                _buildYNDNKSelector(doc['f_penAnusPenis']?.toString() ?? ''),
                _buildYNDNKSelector(doc['f_penAnusBodyPart']?.toString() ?? ''),
                _buildYNDNKSelector(doc['f_penAnusObject']?.toString() ?? ''),
                _buildYNCell('Yes', doc['f_emissionAnus']?.toString() ?? ''),
                _buildYNCell('No', doc['f_emissionAnus']?.toString() ?? ''),
                _buildYNCell('DNK', doc['f_emissionAnus']?.toString() ?? ''),
              ],
            ),
            // Mouth
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text('Mouth',
                      style: _fSerif(size: 9, weight: FontWeight.w600)),
                ),
                _buildYNDNKSelector(doc['f_penMouthPenis']?.toString() ?? ''),
                _buildYNDNKSelector(
                    doc['f_penMouthBodyPart']?.toString() ?? ''),
                _buildYNDNKSelector(doc['f_penMouthObject']?.toString() ?? ''),
                _buildYNCell('Yes', doc['f_emissionMouth']?.toString() ?? ''),
                _buildYNCell('No', doc['f_emissionMouth']?.toString() ?? ''),
                _buildYNCell('DNK', doc['f_emissionMouth']?.toString() ?? ''),
              ],
            ),
          ],
        ),
      ],
    ),
  ));

  // ── 15 F. Table 2: Activity / Question Table (Splittable across pages) ─────────
  final t2Header = _buildTable2Header();

  // Row 1 + Header as the initial block
  blocks.add(_ContentBlock(
    id: 'f_15f_t2_row1',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        t2Header,
        _buildTable2StandardRow(
          'Oral sex performed by assailant on survivor',
          doc['f_oralSexPerformed']?.toString() ?? '',
          isFirst: false,
        ),
      ],
    ),
  ));

  // Row 2: Forced Masturbation of self
  blocks.add(_ContentBlock(
    id: 'f_15f_t2_row2',
    widget: _buildTable2StandardRow(
      'Forced Masturbation of self by survivor',
      doc['f_forcedMasturbationSelf']?.toString() ?? '',
    ),
    tableHeaderToRepeat: t2Header,
  ));

  // Row 3: Masturbation of Assailant
  blocks.add(_ContentBlock(
    id: 'f_15f_t2_row3',
    widget: _buildTable2StandardRow(
      'Masturbation of Assailant by Survivor,\nForced Manipulation of genitals of assailant by survivor',
      doc['f_masturbationAssailant']?.toString() ?? '',
    ),
    tableHeaderToRepeat: t2Header,
  ));

  // Row 4: Exhibitionism
  blocks.add(_ContentBlock(
    id: 'f_15f_t2_row4',
    widget: _buildTable2StandardRow(
      'Exhibitionism (perpetrator displaying genitals)',
      doc['f_exhibitionism']?.toString() ?? '',
    ),
    tableHeaderToRepeat: t2Header,
  ));

  // Row 5: Ejaculation outside
  blocks.add(_ContentBlock(
    id: 'f_15f_t2_row5',
    widget: _buildTable2StandardRow(
      'Did ejaculation occur outside body orifice (vagina/anus/mouth/urethra)?',
      doc['f_ejaculationOutside']?.toString() ?? '',
    ),
    tableHeaderToRepeat: t2Header,
  ));

  // Row 6: Where on body
  blocks.add(_ContentBlock(
    id: 'f_15f_t2_row6',
    widget: _buildTable2DescRow(
      'If yes, describe where on the body',
      doc['f_ejaculationWhereBody']?.toString() ?? '',
    ),
    tableHeaderToRepeat: t2Header,
  ));

  // Row 7: Kissing, licking, sucking
  blocks.add(_ContentBlock(
    id: 'f_15f_t2_row7',
    widget: _buildTable2RowWithDesc(
      question: 'Kissing, licking or sucking any part of survivor’s body',
      ynValue: doc['f_kissingLickingSucking']?.toString() ?? '',
      descValue: doc['f_kissingLickingDesc']?.toString() ?? '',
    ),
    tableHeaderToRepeat: t2Header,
  ));

  // Row 8: Touching/Fondling
  blocks.add(_ContentBlock(
    id: 'f_15f_t2_row8',
    widget: _buildTable2RowWithDesc(
      question: 'Touching/Fondling',
      ynValue: doc['f_touchingFondling']?.toString() ?? '',
      descValue: doc['f_touchingFondlingDesc']?.toString() ?? '',
    ),
    tableHeaderToRepeat: t2Header,
  ));

  // Row 9: Condom used
  blocks.add(_ContentBlock(
    id: 'f_15f_t2_row9',
    widget: _buildTable2StandardRow(
      'Condom used*',
      doc['f_condomUsed']?.toString() ?? '',
    ),
    tableHeaderToRepeat: t2Header,
  ));

  // Row 10: Status of condom
  blocks.add(_ContentBlock(
    id: 'f_15f_t2_row10',
    widget: _buildTable2StandardRow(
      'If yes status of condom',
      doc['f_condomStatus']?.toString() ?? '',
    ),
    tableHeaderToRepeat: t2Header,
  ));

  // Row 11: Lubricant used
  blocks.add(_ContentBlock(
    id: 'f_15f_t2_row11',
    widget: _buildTable2StandardRow(
      'Lubricant used*',
      doc['f_lubricantUsed']?.toString() ?? '',
    ),
    tableHeaderToRepeat: t2Header,
  ));

  // Row 12: Kind of lubricant
  blocks.add(_ContentBlock(
    id: 'f_15f_t2_row12',
    widget: _buildTable2DescRow(
      'If yes, describe kind of lubricant used',
      doc['f_lubricantKindDesc']?.toString() ?? '',
    ),
    tableHeaderToRepeat: t2Header,
  ));

  // Row 13: Describe object
  blocks.add(_ContentBlock(
    id: 'f_15f_t2_row13',
    widget: _buildTable2DescRow(
      'If object used, describe object:',
      doc['f_objectUsedDesc']?.toString() ?? '',
    ),
    tableHeaderToRepeat: t2Header,
  ));

  // Row 14: Other forms of sexual violence
  blocks.add(_ContentBlock(
    id: 'f_15f_t2_row14',
    widget: _buildTable2DescRow(
      'Any other forms of sexual violence',
      doc['f_otherSexualViolenceForms']?.toString() ?? '',
    ),
    tableHeaderToRepeat: t2Header,
  ));

  // Footnote on condom / lubricant
  blocks.add(_ContentBlock(
    id: 'f_15f_footnote',
    widget: Padding(
      padding: const EdgeInsets.only(top: 3.0, bottom: 6.0),
      child: Text(
        '* Explain what condom and lubricant is to the survivor',
        style:
            _fSerif(size: 9, weight: FontWeight.bold, style: FontStyle.italic),
      ),
    ),
  ));

  // ── Post-Incident Table (Splittable across pages) ─────────────────────────────
  final postHeader = _buildPostIncidentHeader();

  // Row 1 + Header as initial block
  blocks.add(_ContentBlock(
    id: 'f_post_row1',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        postHeader,
        _buildPostIncidentRowWidget(
          label: 'Changed clothes',
          choice: doc['f_postChangedClothes']?.toString() ?? '',
          remarks: doc['f_postChangedClothesRem']?.toString() ?? '',
          isFirst: false,
        ),
      ],
    ),
  ));

  // Row 2: Changed undergarments
  blocks.add(_ContentBlock(
    id: 'f_post_row2',
    widget: _buildPostIncidentRowWidget(
      label: 'Changed undergarments',
      choice: doc['f_postChangedUndergarments']?.toString() ?? '',
      remarks: doc['f_postChangedUndergarmentsRem']?.toString() ?? '',
    ),
    tableHeaderToRepeat: postHeader,
  ));

  // Row 3: Cleaned/washed clothes
  blocks.add(_ContentBlock(
    id: 'f_post_row3',
    widget: _buildPostIncidentRowWidget(
      label: 'Cleaned/washed clothes',
      choice: doc['f_postCleanedClothes']?.toString() ?? '',
      remarks: doc['f_postCleanedClothesRem']?.toString() ?? '',
    ),
    tableHeaderToRepeat: postHeader,
  ));

  // Row 4: Cleaned/washed undergarments
  blocks.add(_ContentBlock(
    id: 'f_post_row4',
    widget: _buildPostIncidentRowWidget(
      label: 'Cleaned/washed undergarments',
      choice: doc['f_postCleanedUndergarments']?.toString() ?? '',
      remarks: doc['f_postCleanedUndergarmentsRem']?.toString() ?? '',
    ),
    tableHeaderToRepeat: postHeader,
  ));

  // Row 5: Bathed
  blocks.add(_ContentBlock(
    id: 'f_post_row5',
    widget: _buildPostIncidentRowWidget(
      label: 'Bathed',
      choice: doc['f_postBathed']?.toString() ?? '',
      remarks: doc['f_postBathedRem']?.toString() ?? '',
    ),
    tableHeaderToRepeat: postHeader,
  ));

  // Row 6: Douched
  blocks.add(_ContentBlock(
    id: 'f_post_row6',
    widget: _buildPostIncidentRowWidget(
      label: 'Douched',
      choice: doc['f_postDouched']?.toString() ?? '',
      remarks: doc['f_postDouchedRem']?.toString() ?? '',
    ),
    tableHeaderToRepeat: postHeader,
  ));

  // Row 7: Passed urine
  blocks.add(_ContentBlock(
    id: 'f_post_row7',
    widget: _buildPostIncidentRowWidget(
      label: 'Passed urine',
      choice: doc['f_postPassedUrine']?.toString() ?? '',
      remarks: doc['f_postPassedUrineRem']?.toString() ?? '',
    ),
    tableHeaderToRepeat: postHeader,
  ));

  // Row 8: Passed stools
  blocks.add(_ContentBlock(
    id: 'f_post_row8',
    widget: _buildPostIncidentRowWidget(
      label: 'Passed stools',
      choice: doc['f_postPassedStools']?.toString() ?? '',
      remarks: doc['f_postPassedStoolsRem']?.toString() ?? '',
    ),
    tableHeaderToRepeat: postHeader,
  ));

  // Row 9: Rinsing of mouth/Brushing/Vomiting
  blocks.add(_ContentBlock(
    id: 'f_post_row9',
    widget: _buildPostIncidentRowWidget(
      label:
          'Rinsing of mouth/Brushing/ Vomiting\n(Circle any or all as appropriate)',
      choice: doc['f_postRinsingMouth']?.toString() ?? '',
      remarks: doc['f_postRinsingMouthRem']?.toString() ?? '',
    ),
    tableHeaderToRepeat: postHeader,
  ));

  // Post-Incident Follow-up Fields
  blocks.add(_ContentBlock(
    id: 'f_post_time_bleeding_prior',
    widget: Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Time since incident: ',
                    style: _fSerif(size: 10, weight: FontWeight.bold)),
                const SizedBox(height: 2),
                _buildUnderlineValue(
                    doc['f_timeSinceIncident']?.toString() ?? ''),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'H/o bleeding/discharge prior to incident:',
                  style: _fSerif(size: 9.5, weight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                _buildUnderlineValue(
                    doc['f_bleedingPriorIncident']?.toString() ?? ''),
              ],
            ),
          ),
        ],
      ),
    ),
  ));

  blocks.add(_ContentBlock(
    id: 'f_post_bleeding_since',
    widget: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'H/o vaginal/anal/oral bleeding/discharge since the incident of sexual violence:',
            style: _fSerif(size: 9.5, weight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          _buildUnderlineValue(
              doc['f_bleedingSinceIncident']?.toString() ?? ''),
        ],
      ),
    ),
  ));

  blocks.add(_ContentBlock(
    id: 'f_post_pain_since',
    widget: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'H/o painful urination/ painful defecation/ fissures/ abdominal pain/pain in genitals or any other part since incident:',
            style: _fSerif(size: 9.5, weight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          _buildUnderlineValue(doc['f_painSinceIncident']?.toString() ?? ''),
        ],
      ),
    ),
  ));

  return blocks;
}

// ── FEMALE PHASE C CONSTANTS & HELPER WIDGETS ──────────────────────────────────

const _kFemaleInjuryLabels = [
  (
    'Scalp examination for areas of tenderness\n(if hair pulled out/ dragged by hair)',
    'टाळू — संवेदनशीलता तपासणी (केस उपटले/ओढले असल्यास)'
  ),
  (
    'Facial bone injury: orbital blackening, tenderness',
    'चेहऱ्याच्या हाडांवर जखम: डोळ्याभोवती काळे पडणे, संवेदनशीलता'
  ),
  (
    'Petechial haemorrhage in eyes and other places',
    'डोळ्यांमध्ये व इतर ठिकाणी पेटेकियल रक्तस्त्राव'
  ),
  ('Lips and Buccal Mucosa / Gums', 'ओठ व गालाची आतली बाजू / दात-हिरड्या'),
  ('Behind the ears', 'कानामागे'),
  ('Ear drum', 'कानाचे पडदे'),
  ('Neck, Shoulders and Breast', 'मान, खांदे व स्तन'),
  ('Upper limb', 'वरचे अवयव / हात'),
  ('Inner aspect of upper arms', 'वरच्या हाताच्या आतील बाजू'),
  ('Inner aspect of thighs', 'मांड्यांच्या आतील बाजू'),
  ('Lower limb / Buttocks', 'खालचे अवयव / पाय / नितंब'),
  ('Other, please specify', 'इतर (कृपया नमूद करा)'),
];

const _kFemaleGenitalPartLabels = [
  'Urethral meatus & vestibule',
  'Labia majora',
  'Labia minora',
  'Fourchette & Introitus',
  'Hymen Perineum',
  'External Urethral Meatus',
  'Penis',
  'Scrotum',
  'Testes',
  'Clitoropenis',
  'Labioscrotum',
  'Any Other',
];

const _kFemaleFslSampleLabels = [
  'Swabs from Stains on the body (blood, semen, foreign material, others)',
  'Scalp hair (10-15 strands)',
  'Head hair combing',
  'Nail scrapings (both hands separately)',
  'Nail clippings (both hands separately)',
  'Oral swab',
  'Blood for grouping, testing drug/alcohol intoxication (plain vial)',
  'Blood for alcohol levels (Sodium fluoride vial)',
  'Blood for DNA analysis (EDTA vial)',
  'Any other (tampon/sanitary napkin/condom/object)',
];

const _kFemaleGenitalEvidenceLabels = [
  'Matted pubic hair',
  'Pubic hair combing (mention if shaved)',
  'Cutting of pubic hair (mention if shaved)',
  'Two Vulval swabs (for semen examination and DNA testing)',
  'Two Vaginal swabs (for semen examination and DNA testing)',
  'Two Anal swabs (for semen examination and DNA testing)',
  'Vaginal smear (air-dried) for semen examination',
  'Vaginal washing',
  'Urethral swab',
  'Swab from glans of penis/clitoropenis',
];

const _kFemaleTreatmentLabels = [
  'STI prevention treatment',
  'Emergency contraception',
  'Wound treatment',
  'Tetanus prophylaxis',
  'Hepatitis B vaccination',
  'Post exposure prophylaxis for HIV',
  'Counselling',
  'Other',
];

Widget _buildEncircleOptionsWidget(List<String> options, String selectedCsv) {
  final currentTokens = selectedCsv
      .split(',')
      .map((s) => s.trim().toLowerCase())
      .where((s) => s.isNotEmpty)
      .toSet();

  return Wrap(
    spacing: 8,
    runSpacing: 4,
    children: options.map((opt) {
      final isSelected = currentTokens.contains(opt.toLowerCase());
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.grey.shade400,
            width: isSelected ? 1.4 : 0.8,
          ),
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        ),
        child: Text(
          opt,
          style: _fSerif(
            size: 9.5,
            weight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }).toList(),
  );
}

Widget _buildCollectedRadioRow(String value) {
  final val = value.trim().toLowerCase();
  final isCollected = val == 'collected' || val == 'yes' || val == 'होय';
  final isNotCollected = val == 'not collected' || val == 'no' || val == 'नाही';

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Collected',
                style: _fSerif(
                    size: 8.5,
                    weight: isCollected ? FontWeight.bold : FontWeight.normal)),
            const SizedBox(width: 3),
            _buildConsentRadioDot('', isCollected),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Not Collected',
                style: _fSerif(
                    size: 8.5,
                    weight:
                        isNotCollected ? FontWeight.bold : FontWeight.normal)),
            const SizedBox(width: 3),
            _buildConsentRadioDot('', isNotCollected),
          ],
        ),
      ],
    ),
  );
}

Widget _buildInjuryTableHeader() {
  return Table(
    border: TableBorder.all(color: Colors.black87, width: 0.8),
    columnWidths: const {
      0: FlexColumnWidth(1.2),
      1: FlexColumnWidth(1.1),
    },
    children: [
      TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text('Body part / region',
                style: _fSerif(size: 9.5, weight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text('Details of injury / findings',
                style: _fSerif(size: 9.5, weight: FontWeight.bold)),
          ),
        ],
      ),
    ],
  );
}

Widget _buildInjuryRowWidget((String, String) labelPair, String value,
    {bool isFirst = false}) {
  return Table(
    border: TableBorder(
      left: const BorderSide(color: Colors.black87, width: 0.8),
      right: const BorderSide(color: Colors.black87, width: 0.8),
      bottom: const BorderSide(color: Colors.black87, width: 0.8),
      top: isFirst
          ? const BorderSide(color: Colors.black87, width: 0.8)
          : BorderSide.none,
      verticalInside: const BorderSide(color: Colors.black87, width: 0.8),
    ),
    columnWidths: const {
      0: FlexColumnWidth(1.2),
      1: FlexColumnWidth(1.1),
    },
    children: [
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(labelPair.$1, style: _fSerif(size: 9.5, height: 1.25)),
                if (labelPair.$2.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(labelPair.$2,
                      style: _fMarathi(
                          size: 8.5, color: Colors.black54, height: 1.25)),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
            child: _buildUnderlineValue(value),
          ),
        ],
      ),
    ],
  );
}

Widget _buildGenitalTableHeader() {
  return Table(
    border: TableBorder.all(color: Colors.black87, width: 0.8),
    columnWidths: const {
      0: FlexColumnWidth(2.8),
      1: FlexColumnWidth(2.6),
      2: FlexColumnWidth(2.6),
    },
    children: [
      TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text('Body parts to be examined',
                style: _fSerif(size: 9.5, weight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text('Findings',
                textAlign: TextAlign.center,
                style: _fSerif(size: 9.5, weight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text('Remarks / Notes',
                textAlign: TextAlign.center,
                style: _fSerif(size: 9.5, weight: FontWeight.bold)),
          ),
        ],
      ),
    ],
  );
}

Widget _buildGenitalRowWidget(String label, String finding, String note,
    {bool isFirst = false}) {
  return Table(
    border: TableBorder(
      left: const BorderSide(color: Colors.black87, width: 0.8),
      right: const BorderSide(color: Colors.black87, width: 0.8),
      bottom: const BorderSide(color: Colors.black87, width: 0.8),
      top: isFirst
          ? const BorderSide(color: Colors.black87, width: 0.8)
          : BorderSide.none,
      verticalInside: const BorderSide(color: Colors.black87, width: 0.8),
    ),
    columnWidths: const {
      0: FlexColumnWidth(2.8),
      1: FlexColumnWidth(2.6),
      2: FlexColumnWidth(2.6),
    },
    children: [
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            child: Text(label, style: _fSerif(size: 9.5)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: _buildUnderlineValue(finding),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: _buildUnderlineValue(note),
          ),
        ],
      ),
    ],
  );
}

Widget _buildFslTableHeader() {
  return Table(
    border: TableBorder.all(color: Colors.black87, width: 0.8),
    columnWidths: const {
      0: FlexColumnWidth(3.4),
      1: FlexColumnWidth(2.0),
      2: FlexColumnWidth(3.0),
    },
    children: [
      TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text('Sample',
                style: _fSerif(size: 9.5, weight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text('Collected/Not Collected',
                textAlign: TextAlign.center,
                style: _fSerif(size: 9.0, weight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text('Reason for not collecting',
                textAlign: TextAlign.center,
                style: _fSerif(size: 9.0, weight: FontWeight.bold)),
          ),
        ],
      ),
    ],
  );
}

Widget _buildFslRowWidget(String label, String collected, String reason,
    {bool isFirst = false}) {
  return Table(
    border: TableBorder(
      left: const BorderSide(color: Colors.black87, width: 0.8),
      right: const BorderSide(color: Colors.black87, width: 0.8),
      bottom: const BorderSide(color: Colors.black87, width: 0.8),
      top: isFirst
          ? const BorderSide(color: Colors.black87, width: 0.8)
          : BorderSide.none,
      verticalInside: const BorderSide(color: Colors.black87, width: 0.8),
    ),
    columnWidths: const {
      0: FlexColumnWidth(3.4),
      1: FlexColumnWidth(2.0),
      2: FlexColumnWidth(3.0),
    },
    children: [
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            child: Text(label, style: _fSerif(size: 9.5)),
          ),
          _buildCollectedRadioRow(collected),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: _buildUnderlineValue(reason),
          ),
        ],
      ),
    ],
  );
}

Widget _buildTreatmentTableHeader() {
  return Table(
    border: TableBorder.all(color: Colors.black87, width: 0.8),
    columnWidths: const {
      0: FlexColumnWidth(3.8),
      1: FlexColumnWidth(1.1),
      2: FlexColumnWidth(1.1),
      3: FlexColumnWidth(4.0),
    },
    children: [
      TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text('Treatment',
                style: _fSerif(size: 9.5, weight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text('Yes',
                textAlign: TextAlign.center,
                style: _fSerif(size: 9.5, weight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text('No',
                textAlign: TextAlign.center,
                style: _fSerif(size: 9.5, weight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text('Type and comments',
                textAlign: TextAlign.center,
                style: _fSerif(size: 9.5, weight: FontWeight.bold)),
          ),
        ],
      ),
    ],
  );
}

Widget _buildTreatmentRowWidget(String label, String choice, String comments,
    {bool isFirst = false}) {
  final lower = choice.trim().toLowerCase();
  final isYes = lower == 'yes' || lower == 'होय' || lower == 'y';
  final isNo = lower == 'no' || lower == 'नाही' || lower == 'n';

  return Table(
    border: TableBorder(
      left: const BorderSide(color: Colors.black87, width: 0.8),
      right: const BorderSide(color: Colors.black87, width: 0.8),
      bottom: const BorderSide(color: Colors.black87, width: 0.8),
      top: isFirst
          ? const BorderSide(color: Colors.black87, width: 0.8)
          : BorderSide.none,
      verticalInside: const BorderSide(color: Colors.black87, width: 0.8),
    ),
    columnWidths: const {
      0: FlexColumnWidth(3.8),
      1: FlexColumnWidth(1.1),
      2: FlexColumnWidth(1.1),
      3: FlexColumnWidth(4.0),
    },
    children: [
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            child: Text(label, style: _fSerif(size: 9.5)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: _buildConsentRadioDot('', isYes),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: _buildConsentRadioDot('', isNo),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: _buildUnderlineValue(comments),
          ),
        ],
      ),
    ],
  );
}

// ── FEMALE PHASE C BLOCKS (Sections 16–25) ─────────────────────────────────────

List<_ContentBlock> _buildFemalePhaseCBlocks(Map<String, dynamic> doc) {
  final blocks = <_ContentBlock>[];

  // ── 16. General Physical Examination ─────────────────────────────────────────
  blocks.add(_ContentBlock(
    id: 'f_sec_16_header',
    widget: _buildSectionHeader(
      '16. General Physical Examination-',
      '१६. सामान्य शारीरिक तपासणी-',
    ),
    keepWithNext: true,
  ));

  blocks.add(_ContentBlock(
    id: 'f_16_general_physical',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('i. Is this the first examination: ',
                style: _fSerif(size: 10)),
            Expanded(
                child: _buildUnderlineValue(
                    doc['f_examIsFirst']?.toString() ?? '')),
          ],
        ),
        const SizedBox(height: 6),
        _buildFieldRow([
          _buildBilingualField(
            labelEn: 'ii. Pulse',
            labelMr: 'नाडीचे ठोके',
            value: doc['f_examPulse']?.toString() ?? '',
          ),
          _buildBilingualField(
            labelEn: 'BP',
            labelMr: 'रक्तदाब',
            value: doc['f_examBp']?.toString() ?? '',
          ),
          _buildBilingualField(
            labelEn: 'iii. Temp',
            labelMr: 'तापमान',
            value: doc['f_examTemp']?.toString() ?? '',
          ),
          _buildBilingualField(
            labelEn: 'Resp. Rate',
            labelMr: 'श्वसन दर',
            value: doc['f_examRespRate']?.toString() ?? '',
          ),
        ]),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('iv. Pupils: ', style: _fSerif(size: 10)),
            Expanded(
                child: _buildUnderlineValue(
                    doc['f_examPupils']?.toString() ?? '')),
          ],
        ),
        const SizedBox(height: 6),
        _buildBilingualField(
          labelEn:
              'v. Any observation in terms of general physical wellbeing of the survivor:',
          labelMr: '५. पीडितेच्या सामान्य शारीरिक आरोग्याविषयीचे निरीक्षण:',
          value: doc['f_examGeneralWellbeing']?.toString() ?? '',
        ),
      ],
    ),
  ));

  // ── 17. Examination for injuries on the body ─────────────────────────────────
  blocks.add(_ContentBlock(
    id: 'f_sec_17_header_preamble',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(
          '17. Examination for injuries on the body if any',
          '१७. शरीरावरील जखमांची तपासणी (असल्यास)',
        ),
        const SizedBox(height: 3),
        Text(
          'The pattern of injuries sustained during an incident of sexual violence may show considerable variation. This may range from complete absence of injuries (more frequently) to grievous injuries (very rare).',
          style: _fSerif(size: 9.5, weight: FontWeight.bold, height: 1.3),
        ),
        const SizedBox(height: 3),
        Text(
          '(Look for bruises, physical torture injuries, nail abrasions, teeth bite marks, cuts, lacerations, fracture, tenderness, any other injury, boils, lesions, discharge specially on the scalp, face, neck, shoulders, breast, wrists, forearms, medial aspect of upper arms, thighs and buttocks) Note the Injury type, site, size, shape, colour, swelling signs of healing simple/grievous, dimensions.)',
          style: _fSerif(size: 9.0, color: Colors.black87, height: 1.3),
        ),
        const SizedBox(height: 6),
      ],
    ),
    keepWithNext: true,
  ));

  final injuryHeader = _buildInjuryTableHeader();
  final injuryList = doc['f_injuryRows'] as List<dynamic>? ?? [];

  for (int i = 0; i < _kFemaleInjuryLabels.length; i++) {
    final val = i < injuryList.length ? (injuryList[i]?.toString() ?? '') : '';
    if (i == 0) {
      blocks.add(_ContentBlock(
        id: 'f_17_injury_row_0',
        widget: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            injuryHeader,
            _buildInjuryRowWidget(_kFemaleInjuryLabels[0], val, isFirst: false),
          ],
        ),
      ));
    } else {
      blocks.add(_ContentBlock(
        id: 'f_17_injury_row_$i',
        widget: _buildInjuryRowWidget(_kFemaleInjuryLabels[i], val),
        tableHeaderToRepeat: injuryHeader,
      ));
    }
  }

  // ── 18. Local examination of genital parts/other orifices* ───────────────────
  blocks.add(_ContentBlock(
    id: 'f_sec_18_header',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(
          '18. Local examination of genital parts/other orifices*:',
          '१८. गुप्तांग व इतर अवयवांची स्थानिक तपासणी*:',
        ),
        const SizedBox(height: 3),
        Text(
          'A. External Genitalia: Record findings and state NA where not applicable.',
          style: _fSerif(size: 10, weight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
      ],
    ),
    keepWithNext: true,
  ));

  final genitalHeader = _buildGenitalTableHeader();
  final genitalFindings = doc['f_genitalPartFindings'] as List<dynamic>? ?? [];
  final genitalNotes = doc['f_genitalPartNotes'] as List<dynamic>? ?? [];

  for (int i = 0; i < _kFemaleGenitalPartLabels.length; i++) {
    final f = i < genitalFindings.length
        ? (genitalFindings[i]?.toString() ?? '')
        : '';
    final n =
        i < genitalNotes.length ? (genitalNotes[i]?.toString() ?? '') : '';
    if (i == 0) {
      blocks.add(_ContentBlock(
        id: 'f_18_genital_row_0',
        widget: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            genitalHeader,
            _buildGenitalRowWidget(_kFemaleGenitalPartLabels[0], f, n,
                isFirst: false),
          ],
        ),
      ));
    } else {
      blocks.add(_ContentBlock(
        id: 'f_18_genital_row_$i',
        widget: _buildGenitalRowWidget(_kFemaleGenitalPartLabels[i], f, n),
        tableHeaderToRepeat: genitalHeader,
      ));
    }
  }

  // 18. Footnote & P/S P/V findings
  blocks.add(_ContentBlock(
    id: 'f_18_pv_ps_findings',
    widget: Padding(
      padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '* Per/Vaginum /Per Speculum examination should not be done unless required for detection of injuries or for medical treatment.',
            style: _fSerif(size: 9.0, weight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('P/S findings if performed: ', style: _fSerif(size: 10)),
              Expanded(
                  child: _buildUnderlineValue(
                      doc['f_psFindings']?.toString() ?? '')),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('P/V findings if performed: ', style: _fSerif(size: 10)),
              Expanded(
                  child: _buildUnderlineValue(
                      doc['f_pvFindings']?.toString() ?? '')),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Record reasons if P/V of P/S examination performed: ',
                  style: _fSerif(size: 10)),
              Expanded(
                  child: _buildUnderlineValue(
                      doc['f_pvPsReasons']?.toString() ?? '')),
            ],
          ),
        ],
      ),
    ),
  ));

  // 18. C. Anus and Rectum
  blocks.add(_ContentBlock(
    id: 'f_18_anus_rectum',
    widget: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('C. Anus and Rectum (encircle the relevant):',
              style: _fSerif(size: 10, weight: FontWeight.bold)),
          const SizedBox(height: 4),
          _buildEncircleOptionsWidget(
            ['Bleeding', 'Tear', 'Discharge', 'Oedema', 'Tenderness'],
            doc['f_anusRectumEncircled']?.toString() ?? '',
          ),
          const SizedBox(height: 4),
          _buildUnderlineValue(doc['f_anusRectumNotes']?.toString() ?? ''),
        ],
      ),
    ),
  ));

  // 18. D. Oral Cavity
  blocks.add(_ContentBlock(
    id: 'f_18_oral_cavity',
    widget: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('D. Oral Cavity - (encircle the relevant):',
              style: _fSerif(size: 10, weight: FontWeight.bold)),
          const SizedBox(height: 4),
          _buildEncircleOptionsWidget(
            ['Bleeding', 'Discharge', 'Tear', 'Oedema', 'Tenderness'],
            doc['f_oralCavityEncircled']?.toString() ?? '',
          ),
          const SizedBox(height: 4),
          _buildUnderlineValue(doc['f_oralCavityNotes']?.toString() ?? ''),
        ],
      ),
    ),
  ));

  // ── 19. Systemic Examination ─────────────────────────────────────────────────
  blocks.add(_ContentBlock(
    id: 'f_sec_19_header',
    widget: _buildSectionHeader(
      '19. Systemic examination:',
      '१९. प्रणालीगत तपासणी:',
    ),
    keepWithNext: true,
  ));

  blocks.add(_ContentBlock(
    id: 'f_19_systemic_exam',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Central Nervous System: ', style: _fSerif(size: 10)),
            Expanded(
                child: _buildUnderlineValue(doc['f_sysCns']?.toString() ?? '')),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Cardio Vascular System: ', style: _fSerif(size: 10)),
            Expanded(
                child: _buildUnderlineValue(doc['f_sysCvs']?.toString() ?? '')),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Respiratory System: ', style: _fSerif(size: 10)),
            Expanded(
                child:
                    _buildUnderlineValue(doc['f_sysResp']?.toString() ?? '')),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Chest: ', style: _fSerif(size: 10)),
            Expanded(
                child:
                    _buildUnderlineValue(doc['f_sysChest']?.toString() ?? '')),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Abdomen: ', style: _fSerif(size: 10)),
            Expanded(
                child: _buildUnderlineValue(
                    doc['f_sysAbdomen']?.toString() ?? '')),
          ],
        ),
      ],
    ),
  ));

  // ── 20. Sample Collection / Investigations for Hospital Laboratory ───────────
  blocks.add(_ContentBlock(
    id: 'f_sec_20_header',
    widget: _buildSectionHeader(
      '20. Sample collection/investigations for hospital laboratory/ Clinical laboratory',
      '२०. रुग्णालय / क्लिनिकल प्रयोगशाळेसाठी नमुने गोळा करणे / तपासण्या',
    ),
    keepWithNext: true,
  ));

  blocks.add(_ContentBlock(
    id: 'f_20_hospital_samples',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('1) Blood for HIV, VDRL, HbsAg: ', style: _fSerif(size: 10)),
            Expanded(
                child: _buildUnderlineValue(
                    doc['f_sampleBloodHiv']?.toString() ?? '')),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('2) Urine test for Pregnancy/: ', style: _fSerif(size: 10)),
            Expanded(
                child: _buildUnderlineValue(
                    doc['f_sampleUrinePreg']?.toString() ?? '')),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('3) Ultrasound for pregnancy/internal injury: ',
                style: _fSerif(size: 10)),
            Expanded(
                child:
                    _buildUnderlineValue(doc['f_sampleUsg']?.toString() ?? '')),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('4) X-ray for Injury: ', style: _fSerif(size: 10)),
            Expanded(
                child: _buildUnderlineValue(
                    doc['f_sampleXray']?.toString() ?? '')),
          ],
        ),
      ],
    ),
  ));

  // ── 21. Samples Collection for FSL ───────────────────────────────────────────
  blocks.add(_ContentBlock(
    id: 'f_sec_21_header',
    widget: _buildSectionHeader(
      '21. Samples Collection for Central/ State Forensic Science Laboratory',
      '२१. फॉरेन्सिक सायन्स लॅबोरेटरीसाठी (FSL) नमुने गोळा करणे',
    ),
    keepWithNext: true,
  ));

  // 21. 1) Debris & 2) Clothing
  blocks.add(_ContentBlock(
    id: 'f_21_debris_clothing',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('1) Debris collectionpaper: ', style: _fSerif(size: 10)),
            Expanded(
                child:
                    _buildUnderlineValue(doc['f_fslDebris']?.toString() ?? '')),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '2) Clothing evidence where available – (to be packed in separate paper bags after air drying)',
          style: _fSerif(size: 9.5, weight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'List and Details of clothing worn by the survivor at time of incident of sexual violence',
                style: _fSerif(size: 9.5, weight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              _buildUnderlineValue(doc['f_clothingDetails']?.toString() ?? '',
                  minLines: 3),
            ],
          ),
        ),
      ],
    ),
  ));

  // 21. 3) Body Evidence Table
  blocks.add(_ContentBlock(
    id: 'f_21_body_evidence_header',
    widget: Padding(
      padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
      child: Text(
        '3) Body evidence samples as appropriate (duly labeled and packed separately)',
        style: _fSerif(size: 10, weight: FontWeight.bold),
      ),
    ),
    keepWithNext: true,
  ));

  final fslHeader = _buildFslTableHeader();
  final fslCollected = doc['f_fslSampleCollected'] as List<dynamic>? ?? [];
  final fslReasons = doc['f_fslSampleReasons'] as List<dynamic>? ?? [];

  for (int i = 0; i < _kFemaleFslSampleLabels.length; i++) {
    final c =
        i < fslCollected.length ? (fslCollected[i]?.toString() ?? '') : '';
    final r = i < fslReasons.length ? (fslReasons[i]?.toString() ?? '') : '';
    if (i == 0) {
      blocks.add(_ContentBlock(
        id: 'f_21_fsl_row_0',
        widget: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            fslHeader,
            _buildFslRowWidget(_kFemaleFslSampleLabels[0], c, r,
                isFirst: false),
          ],
        ),
      ));
    } else {
      blocks.add(_ContentBlock(
        id: 'f_21_fsl_row_$i',
        widget: _buildFslRowWidget(_kFemaleFslSampleLabels[i], c, r),
        tableHeaderToRepeat: fslHeader,
      ));
    }
  }

  // 21. 4) Genital and Anal Evidence Table
  blocks.add(_ContentBlock(
    id: 'f_21_genital_evidence_header',
    widget: Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '4) Genital and Anal evidence (Each sample to be packed, sealed, and labeled separately-to be placed in a bag)',
            style: _fSerif(size: 10, weight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '* Swab sticks for collecting samples should be moistened with distilled water provided.',
            style: _fSerif(size: 8.5, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    ),
    keepWithNext: true,
  ));

  final genevCollected =
      doc['f_genitalEvidenceCollected'] as List<dynamic>? ?? [];
  final genevReasons = doc['f_genitalEvidenceReasons'] as List<dynamic>? ?? [];

  for (int i = 0; i < _kFemaleGenitalEvidenceLabels.length; i++) {
    final c =
        i < genevCollected.length ? (genevCollected[i]?.toString() ?? '') : '';
    final r =
        i < genevReasons.length ? (genevReasons[i]?.toString() ?? '') : '';
    if (i == 0) {
      blocks.add(_ContentBlock(
        id: 'f_21_genev_row_0',
        widget: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            fslHeader,
            _buildFslRowWidget(_kFemaleGenitalEvidenceLabels[0], c, r,
                isFirst: false),
          ],
        ),
      ));
    } else {
      blocks.add(_ContentBlock(
        id: 'f_21_genev_row_$i',
        widget: _buildFslRowWidget(_kFemaleGenitalEvidenceLabels[i], c, r),
        tableHeaderToRepeat: fslHeader,
      ));
    }
  }

  // 21 Footnote
  blocks.add(_ContentBlock(
    id: 'f_21_footnote',
    widget: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        '*Samples to be preserved as directed till handed over to police along with duly attested sample seal.',
        style: _fSerif(size: 8.5, weight: FontWeight.bold),
      ),
    ),
  ));

  // ── 22. Provisional Medical Opinion ──────────────────────────────────────────
  blocks.add(_ContentBlock(
    id: 'f_sec_22_header',
    widget: _buildSectionHeader(
      '22. Provisional medical opinion',
      '२२. तात्पुरते वैद्यकीय मत',
    ),
    keepWithNext: true,
  ));

  blocks.add(_ContentBlock(
    id: 'f_22_provisional_opinion',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('I have examined (name of survivor) ',
                style: _fSerif(size: 10)),
            SizedBox(
                width: 130,
                child: _buildUnderlineValue(
                    doc['f_provSurvivorName']?.toString() ?? '')),
            Text(' M/F/Other ', style: _fSerif(size: 10)),
            SizedBox(
                width: 40,
                child: _buildUnderlineValue(
                    doc['f_provGender']?.toString() ?? '')),
            Text(' aged ', style: _fSerif(size: 10)),
            SizedBox(
                width: 40,
                child:
                    _buildUnderlineValue(doc['f_provAge']?.toString() ?? '')),
            Text(' reporting_ (type of sexual violence and circumstances) ',
                style: _fSerif(size: 10)),
            SizedBox(
                width: 140,
                child: _buildUnderlineValue(
                    doc['f_provCircumstances']?.toString() ?? '')),
            Text(', ', style: _fSerif(size: 10)),
            SizedBox(
                width: 70,
                child: _buildUnderlineValue(
                    doc['f_provTimeAfterIncident']?.toString() ?? '')),
            Text(' after the incident, after having (bathed/douched etc) ',
                style: _fSerif(size: 10)),
            SizedBox(
                width: 100,
                child: _buildUnderlineValue(
                    doc['f_provBathedDouched']?.toString() ?? '')),
            Text('. My findings are as follows:', style: _fSerif(size: 10)),
          ],
        ),
        const SizedBox(height: 8),
        _buildBilingualField(
          labelEn: '• Samples collected (for FSL), awaiting reports:',
          labelMr: '• फॉरेन्सिक सायन्स लॅबसाठी गोळा केलेले नमुने:',
          value: doc['f_provFslSamples']?.toString() ?? '',
        ),
        _buildBilingualField(
          labelEn: '• Samples collected (for hospital laboratory):',
          labelMr: '• रुग्णालय प्रयोगशाळेसाठी गोळा केलेले नमुने:',
          value: doc['f_provHospSamples']?.toString() ?? '',
        ),
        _buildBilingualField(
          labelEn: '• Clinical findings:',
          labelMr: '• नैदानिक निष्कर्ष:',
          value: doc['f_provClinicalFindings']?.toString() ?? '',
        ),
        _buildBilingualField(
          labelEn: '• Additional observations (if any):',
          labelMr: '• अतिरिक्त निरीक्षणे (असल्यास):',
          value: doc['f_provAdditionalObs']?.toString() ?? '',
        ),
      ],
    ),
  ));

  // ── 23. Treatment Prescribed ─────────────────────────────────────────────────
  blocks.add(_ContentBlock(
    id: 'f_sec_23_header',
    widget: _buildSectionHeader(
      '23. Treatment prescribed:',
      '२३. दिलेले / सुचवलेले उपचार:',
    ),
    keepWithNext: true,
  ));

  final trHeader = _buildTreatmentTableHeader();
  final trChoice = doc['f_treatmentChoice'] as List<dynamic>? ?? [];
  final trComm = doc['f_treatmentComments'] as List<dynamic>? ?? [];

  for (int i = 0; i < _kFemaleTreatmentLabels.length; i++) {
    final c = i < trChoice.length ? (trChoice[i]?.toString() ?? '') : '';
    final m = i < trComm.length ? (trComm[i]?.toString() ?? '') : '';
    if (i == 0) {
      blocks.add(_ContentBlock(
        id: 'f_23_treatment_row_0',
        widget: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            trHeader,
            _buildTreatmentRowWidget(_kFemaleTreatmentLabels[0], c, m,
                isFirst: false),
          ],
        ),
      ));
    } else {
      blocks.add(_ContentBlock(
        id: 'f_23_treatment_row_$i',
        widget: _buildTreatmentRowWidget(_kFemaleTreatmentLabels[i], c, m),
        tableHeaderToRepeat: trHeader,
      ));
    }
  }

  // ── 24. Completion & Doctor Signature ────────────────────────────────────────
  blocks.add(_ContentBlock(
    id: 'f_24_completion_doctor',
    widget: Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('24. Date and time of completion of examination: ',
                  style: _fSerif(size: 10, weight: FontWeight.bold)),
              Expanded(
                  child: _buildUnderlineValue(_formatDateTime(
                      doc['f_completionDateTime']?.toString() ?? ''))),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('This report contains ', style: _fSerif(size: 10)),
              SizedBox(
                  width: 60,
                  child: _buildUnderlineValue(
                      doc['f_reportSheetsCount']?.toString() ?? '')),
              Text(' number of sheets and ', style: _fSerif(size: 10)),
              SizedBox(
                  width: 60,
                  child: _buildUnderlineValue(
                      doc['f_reportEnvelopesCount']?.toString() ?? '')),
              Text(' number of envelopes.', style: _fSerif(size: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: _buildBilingualField(
                  labelEn: 'Place',
                  labelMr: 'ठिकाण',
                  value: doc['f_completionPlace']?.toString() ?? '',
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Signature of Examining Doctor',
                        style: _fSerif(size: 10, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Name: ', style: _fSerif(size: 9.5)),
                        Expanded(
                            child: _buildUnderlineValue(
                                doc['f_doctorName']?.toString() ?? '')),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Seal: ', style: _fSerif(size: 9.5)),
                        Expanded(
                            child: _buildUnderlineValue(
                                doc['f_doctorSeal']?.toString() ?? '')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    keepWithNext: true,
  ));

  // ── 25. Final Opinion & Statutory Free Copy Notice ───────────────────────────
  blocks.add(_ContentBlock(
    id: 'f_sec_25_header',
    widget: _buildSectionHeader(
      '25. Final Opinion (After receiving Lab reports)',
      '२५. अंतिम मत (प्रयोगशाळा अहवाल प्राप्त झाल्यानंतर)',
    ),
    keepWithNext: true,
  ));

  blocks.add(_ContentBlock(
    id: 'f_25_final_opinion',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
                'Findings in support of the above opinion, taking into account the history, clinical examination findings and Laboratory reports of ',
                style: _fSerif(size: 9.5)),
            SizedBox(
                width: 140,
                child: _buildUnderlineValue(
                    doc['f_finalOpinionPerson']?.toString() ?? '')),
            Text(' bearing identification marks described above, ',
                style: _fSerif(size: 9.5)),
            SizedBox(
                width: 70,
                child: _buildUnderlineValue(
                    doc['f_finalOpinionTime']?.toString() ?? '')),
            Text(
                ' after the incident of sexual violence, I am of the opinion that:',
                style: _fSerif(size: 9.5)),
          ],
        ),
        const SizedBox(height: 6),
        _buildUnderlineValue(doc['f_finalOpinionText']?.toString() ?? '',
            minLines: 4),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: _buildBilingualField(
                labelEn: 'Place',
                labelMr: 'ठिकाण',
                value: doc['f_finalOpinionPlace']?.toString() ?? '',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Signature of Examining Doctor',
                      style: _fSerif(size: 10, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Name: ', style: _fSerif(size: 9.5)),
                      Expanded(
                          child: _buildUnderlineValue(
                              doc['f_finalDoctorName']?.toString() ?? '')),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Seal: ', style: _fSerif(size: 9.5)),
                      Expanded(
                          child: _buildUnderlineValue(
                              doc['f_finalDoctorSeal']?.toString() ?? '')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
    keepWithNext: true,
  ));

  // Statutory Free Copy Footer Notice
  blocks.add(_ContentBlock(
    id: 'f_statutory_free_copy_notice',
    widget: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.black87, width: 0.8),
      ),
      child: Column(
        children: [
          Text(
            'COPY OF THE ENTIRE MEDICAL REPORT MUST BE GIVEN TO THE SURVIVOR/VICTIM FREE OF COST IMMEDIATELY',
            textAlign: TextAlign.center,
            style: _fSerif(size: 9.5, weight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'संपूर्ण वैद्यकीय अहवालाची प्रत पीडित/पीडितेला त्वरित विनामूल्य द्यावी',
            textAlign: TextAlign.center,
            style: _fMarathi(size: 9.0, weight: FontWeight.bold),
          ),
        ],
      ),
    ),
  ));

  return blocks;
}

// ── FULL MALE BLOCKS (Sections 1–24) ───────────────────────────────────────────

List<_ContentBlock> _buildMaleBlocks(Map<String, dynamic> doc) {
  final blocks = <_ContentBlock>[];

  // Block 1: Header / Title
  blocks.add(_ContentBlock(
    id: 'm_header_title',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                'FORENSIC MEDICAL EXAMINATION OF ALLEGED ACCUSED\nFOR EVIDENCE OF SEXUAL ASSAULT',
                textAlign: TextAlign.center,
                style: _fSerif(size: 12.5, weight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'लैंगिक अत्याचाराच्या पुराव्यासाठी\nआरोपीची फॉरेन्सिक वैद्यकीय तपासणी',
                textAlign: TextAlign.center,
                style: _fMarathi(size: 11, weight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  ));

  // Section 1 Header
  blocks.add(_ContentBlock(
    id: 'm_sec_1_header',
    widget: _buildSectionHeader(
      '(I) Preliminary information and consent',
      '(१) प्राथमिक माहिती व संमती',
    ),
    keepWithNext: true,
  ));

  // 1. Hospital
  blocks.add(_ContentBlock(
    id: 'm_hospital',
    widget: _buildBilingualField(
      labelEn: '1. Name of the hospital',
      labelMr: '१. रुग्णालयाचे नाव',
      value: doc['m_hospital']?.toString() ?? '',
    ),
  ));

  // 2. OPD/IPD No., Date, MLC No., MLC Date
  blocks.add(_ContentBlock(
    id: 'm_opd_mlc_row',
    widget: _buildFieldRow([
      _buildBilingualField(
        labelEn: '2. OPD/IPD No.',
        labelMr: '२. बाह्य/अंतर्गत क्र.',
        value: doc['m_opd']?.toString() ?? '',
      ),
      _buildBilingualField(
        labelEn: 'Date',
        labelMr: 'दिनांक',
        value: _formatDate(doc['m_date']?.toString() ?? ''),
      ),
      _buildBilingualField(
        labelEn: 'MLC No.',
        labelMr: 'एम.एल.सी. क्र.',
        value: doc['m_mlc']?.toString() ?? '',
      ),
      _buildBilingualField(
        labelEn: 'MLC Date',
        labelMr: 'एम.एल.सी. दिनांक',
        value: _formatDate(doc['m_mlcDate']?.toString() ?? ''),
      ),
    ]),
  ));

  // 3. Accused Name
  blocks.add(_ContentBlock(
    id: 'm_accused_name',
    widget: _buildBilingualField(
      labelEn: '3. Name of the alleged Accused',
      labelMr: '३. आरोपीचे नाव',
      value: doc['m_accusedName']?.toString() ?? '',
    ),
  ));

  // 4. Age, DOB, Religion, Marital
  blocks.add(_ContentBlock(
    id: 'm_age_dob_religion_marital',
    widget: _buildFieldRow([
      _buildBilingualField(
        labelEn: '4. Age',
        labelMr: '४. वय',
        value: doc['m_age']?.toString() ?? '',
      ),
      _buildBilingualField(
        labelEn: 'Date of Birth',
        labelMr: 'जन्मतारीख',
        value: _formatDate(doc['m_dob']?.toString() ?? ''),
      ),
      _buildBilingualField(
        labelEn: 'Religion',
        labelMr: 'धर्म',
        value: doc['m_religion']?.toString() ?? '',
      ),
      _buildBilingualField(
        labelEn: '5. Marital status',
        labelMr: '५. वैवाहिक स्थिती',
        value: doc['m_marital']?.toString() ?? '',
      ),
    ]),
  ));

  // 6. Address
  blocks.add(_ContentBlock(
    id: 'm_address',
    widget: _buildBilingualField(
      labelEn: '6. Address',
      labelMr: '६. पत्ता',
      value: doc['m_address']?.toString() ?? '',
      minLines: 2,
    ),
  ));

  // 7. Brought by & Police details
  blocks.add(_ContentBlock(
    id: 'm_brought_by_police',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBilingualField(
          labelEn:
              '7. Brought by — Name of police / B No. / Police Station / C.R.No / U/s',
          labelMr: '७. कोणी आणले — पोलीस नाव / बक्कल / ठाणे / गु.नो. / कलम',
          value: doc['m_policeName']?.toString() ?? '',
        ),
        _buildFieldRow([
          _buildBilingualField(
            labelEn: 'Buckle No.',
            labelMr: 'बक्कल क्र.',
            value: doc['m_buckle']?.toString() ?? '',
          ),
          _buildBilingualField(
            labelEn: 'P.S.',
            labelMr: 'पो.ठ.',
            value: doc['m_ps']?.toString() ?? '',
          ),
          _buildBilingualField(
            labelEn: 'C.R.No',
            labelMr: 'गु.नो.',
            value: doc['m_crNo']?.toString() ?? '',
          ),
          _buildBilingualField(
            labelEn: 'U/s',
            labelMr: 'कलम',
            value: doc['m_section']?.toString() ?? '',
          ),
        ]),
      ],
    ),
  ));

  // 8. Consent Header & Body
  blocks.add(_ContentBlock(
    id: 'm_sec_8_header',
    widget: _buildSectionHeader('8. CONSENT', '८. संमती'),
    keepWithNext: true,
  ));

  blocks.add(_ContentBlock(
    id: 'm_consent_body',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'I … hereby voluntarily consent to: (a) medical examination and examination of genitals and other body parts (b) collection of samples for medical and forensic examination and treatment. All this has been explained to me in the manner and language which I can understand.',
          style: _fSerif(size: 9.5, height: 1.3),
        ),
        Text(
          'मी … येथे स्वेच्छेने संमती देतो: (अ) वैद्यकीय व गुप्तांग/शरीर तपासणी (ब) वैद्यकीय व फॉरेन्सिक नमुने व उपचार. हे मला समजेल अशा भाषेत समजावले.',
          style: _fMarathi(size: 8.5, height: 1.3),
        ),
        const SizedBox(height: 6),
        _buildLinedSignatureBox(
          titleEn: 'Consent details / signature block',
          titleMr: 'संमती तपशील / सही',
          text: doc['m_consent']?.toString() ?? '',
          minLines: 3,
        ),
      ],
    ),
  ));

  // 9. Identification Marks
  blocks.add(_ContentBlock(
    id: 'm_sec_9_header',
    widget: _buildSectionHeader('9. Identification Marks', '९. ओळखीच्या खुणा'),
    keepWithNext: true,
  ));

  blocks.add(_ContentBlock(
    id: 'm_id_marks_body',
    widget: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: _buildBilingualField(
            labelEn: '(1) Identification Mark',
            labelMr: '(१) ओळखीची खूण',
            value: doc['m_idMark1']?.toString() ?? '',
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Container(
                width: 140,
                height: 65,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black87, width: 1.0),
                ),
              ),
              const SizedBox(height: 3),
              Text('(2) Left thumb impression',
                  style: _fSerif(size: 9.5, weight: FontWeight.bold)),
              Text('(२) डाव्या हाताचा अंगठा', style: _fMarathi(size: 8.5)),
            ],
          ),
        ),
      ],
    ),
  ));

  // 10. Date & time of examination
  blocks.add(_ContentBlock(
    id: 'm_sec_10_exam_date_time',
    widget: _buildBilingualField(
      labelEn: '10. Date & time of examination',
      labelMr: '१०. तपासणी दिनांक व वेळ',
      value: _formatDateTime(doc['m_examDateTime']?.toString() ?? ''),
    ),
  ));

  // 11. Name of doctor
  blocks.add(_ContentBlock(
    id: 'm_sec_11_doctor',
    widget: _buildBilingualField(
      labelEn: '11. Name/s of doctor who conducted examination',
      labelMr: '११. तपासणी केलेल्या डॉक्टराचे नाव',
      value: doc['m_doctor']?.toString() ?? '',
    ),
  ));

  // (II) History of alleged sexual assault as stated by Accused
  blocks.add(_ContentBlock(
    id: 'm_sec_ii_assault_history_header',
    widget: _buildSectionHeader(
      '(II) History of alleged sexual assault as stated by Accused',
      '(२) आरोपीने सांगितलेला अत्याचाराचा इतिहास',
    ),
    keepWithNext: true,
  ));

  blocks.add(_ContentBlock(
    id: 'm_sec_ii_assault_history_body',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildUnderlineValue(doc['m_assaultHistory']?.toString() ?? '',
            minLines: 4),
        const SizedBox(height: 8),
        _buildFieldRow([
          _buildBilingualField(
            labelEn: 'Signature & name of witness',
            labelMr: 'साक्षीदार सही व नाव',
            value: doc['m_witnessSig']?.toString() ?? '',
          ),
          _buildBilingualField(
            labelEn: 'Signature & name of accused/guardian',
            labelMr: 'आरोपी/पालक सही व नाव',
            value: doc['m_accusedSig']?.toString() ?? '',
          ),
        ]),
      ],
    ),
  ));

  // (III) Medical and Surgical History
  blocks.add(_ContentBlock(
    id: 'm_sec_iii_med_surgical_history',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(
          '(III) Medical and Surgical History',
          '(३) वैद्यकीय व शस्त्रक्रिया इतिहास',
        ),
        _buildUnderlineValue(doc['m_medSurgicalHistory']?.toString() ?? '',
            minLines: 4),
      ],
    ),
  ));

  // (IV) General physical examination
  blocks.add(_ContentBlock(
    id: 'm_sec_iv_general_physical',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(
          '(IV) General physical examination',
          '(४) सामान्य शारीरिक तपासणी',
        ),
        _buildUnderlineValue(doc['m_generalPhysical']?.toString() ?? '',
            minLines: 4),
      ],
    ),
  ));

  // (V) Local Examination: Perineum and Genitals
  blocks.add(_ContentBlock(
    id: 'm_sec_v_local_exam',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(
          '(V) Local Examination: Perineum and Genitals',
          '(५) स्थानिक तपासणी: गुदद्वार व गुप्तांग',
        ),
        _buildUnderlineValue(doc['m_localExam']?.toString() ?? '', minLines: 4),
      ],
    ),
  ));

  // (VI) Systemic Examination
  blocks.add(_ContentBlock(
    id: 'm_sec_vi_systemic_exam',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(
          '(VI) Systemic Examination',
          '(६) प्रणालीगत तपासणी',
        ),
        _buildUnderlineValue(doc['m_systemicExam']?.toString() ?? '',
            minLines: 3),
      ],
    ),
  ));

  // (VII) Additional findings / referral
  blocks.add(_ContentBlock(
    id: 'm_sec_vii_additional_findings',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(
          '(VII) Additional findings / referral',
          '(७) अतिरिक्त निष्कर्ष / संदर्भ',
        ),
        _buildUnderlineValue(doc['m_additionalFindings']?.toString() ?? '',
            minLines: 3),
      ],
    ),
  ));

  // (VIII) Sample collection for Hospital/ Clinical Laboratory
  blocks.add(_ContentBlock(
    id: 'm_sec_viii_hospital_samples',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(
          'VIII) Sample collection for Hospital/ Clinical Laboratory',
          '८) रुग्णालय / क्लिनिकल प्रयोगशाळेसाठी नमुने गोळा करणे',
        ),
        Text(
          'Samples can be taken according to requirement of a case advice investigations/ test according to case presentations & signs:',
          style: _fSerif(size: 9.0, height: 1.25),
        ),
        const SizedBox(height: 4),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(40),
            1: FlexColumnWidth(2.6),
            2: FlexColumnWidth(2.6),
            3: FlexColumnWidth(2.2),
            4: FixedColumnWidth(80),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: [
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text('Sr No',
                      textAlign: TextAlign.center,
                      style: _fSerif(size: 9, weight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text('Sample name',
                      style: _fSerif(size: 9, weight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text('Test for',
                      style: _fSerif(size: 9, weight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text('Preservative/Packing',
                      style: _fSerif(size: 9, weight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text('Collected?\nYes/No',
                      textAlign: TextAlign.center,
                      style: _fSerif(size: 9, weight: FontWeight.bold)),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text('7',
                        textAlign: TextAlign.center, style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text('Urethral Swab', style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child:
                        Text('Microscopy & Culture', style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text('Plain Sterile Bulb', style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _buildUnderlineValue(
                        doc['m_lab7Collected']?.toString() ?? '')),
              ],
            ),
            TableRow(
              children: [
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text('8',
                        textAlign: TextAlign.center, style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child:
                        Text('Swab from discharge', style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child:
                        Text('Microscopy & Culture', style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text('Plain Sterile Bulb', style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _buildUnderlineValue(
                        doc['m_lab8Collected']?.toString() ?? '')),
              ],
            ),
            TableRow(
              children: [
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text('9',
                        textAlign: TextAlign.center, style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text('Blood', style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text('Serology (syphilis, HIV, Hep B)',
                        style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text('Plain Sterile Bulb', style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _buildUnderlineValue(
                        doc['m_lab9Collected']?.toString() ?? '')),
              ],
            ),
            TableRow(
              children: [
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text('10',
                        textAlign: TextAlign.center, style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text('Urine (midstream)', style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child:
                        Text('Microscopy & Culture', style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text('Plain Sterile Bulb', style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _buildUnderlineValue(
                        doc['m_lab10Collected']?.toString() ?? '')),
              ],
            ),
            TableRow(
              children: [
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text('11',
                        textAlign: TextAlign.center, style: _fSerif(size: 9))),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _buildUnderlineValue(
                        doc['m_lab11Sample']?.toString() ?? '')),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _buildUnderlineValue(
                        doc['m_lab11Test']?.toString() ?? '')),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _buildUnderlineValue(
                        doc['m_lab11Packing']?.toString() ?? '')),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _buildUnderlineValue(
                        doc['m_lab11Collected']?.toString() ?? '')),
              ],
            ),
          ],
        ),
      ],
    ),
  ));

  // (IX) Samples/ Forensic Evidence preserved for FSL
  blocks.add(_ContentBlock(
    id: 'm_sec_ix_fsl_samples',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(
          '(IX) Samples/ Forensic Evidence preserved for FSL:',
          '(९) एफ.एस.एल.साठी जतन केलेला फॉरेन्सिक पुरावा / नमुने :',
        ),
        Text(
          'The samples must be collected as per time elapsed between assault and examination, history and physical findings. This will avoid unnecessary sample collection. The list of samples to be preserved is annexed herewith in triplicate, which is the part of requisition to FSL for relevant examination.',
          style: _fSerif(size: 9.0, height: 1.3),
        ),
        const SizedBox(height: 4),
        _buildBilingualField(
          labelEn: 'Note (If any)',
          labelMr: 'टिपणी (असल्यास)',
          value: doc['m_fslNote']?.toString() ?? '',
          minLines: 3,
        ),
      ],
    ),
  ));

  // PROVISIONAL OPINION: **
  blocks.add(_ContentBlock(
    id: 'm_provisional_opinion_header',
    widget: _buildSectionHeader(
      'PROVISIONAL OPINION: **',
      'तात्पुरते वैद्यकीय मत: **',
    ),
    keepWithNext: true,
  ));

  blocks.add(_ContentBlock(
    id: 'm_provisional_opinion_body',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
                'After examining the person bearing above mentioned identification marks, ',
                style: _fSerif(size: 9.5)),
            SizedBox(
                width: 100,
                child: _buildUnderlineValue(
                    doc['m_opinionTimeElapsed']?.toString() ?? '')),
            Text(
                ' days/hours after the incident, I/We is/are of the opinion that:',
                style: _fSerif(size: 9.5)),
          ],
        ),
        const SizedBox(height: 6),
        _buildUnderlineValue(doc['m_provisionalOpinion']?.toString() ?? '',
            minLines: 4),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Date: ', style: _fSerif(size: 10, weight: FontWeight.bold)),
            SizedBox(
                width: 90,
                child: _buildUnderlineValue(
                    _formatDate(doc['m_opinionDate']?.toString() ?? ''))),
            const Spacer(),
            Text('(Report contains ', style: _fSerif(size: 9.5)),
            SizedBox(
                width: 35,
                child: _buildUnderlineValue(
                    doc['m_reportPagesCount']?.toString() ?? '')),
            Text(' pages each signed by doctor)', style: _fSerif(size: 9.5)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black54, width: 1.0),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: Text('Stamp / शिक्का',
                    style: _fSerif(
                        size: 9.5,
                        color: Colors.black45,
                        weight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                          width: 100,
                          child: Text('Signature:', style: _fSerif(size: 9.5))),
                      Expanded(
                          child: _buildUnderlineValue(
                              doc['m_doctorSig']?.toString() ?? '')),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                          width: 100,
                          child:
                              Text('Name of Dr.:', style: _fSerif(size: 9.5))),
                      Expanded(
                          child: _buildUnderlineValue(
                              doc['m_doctorName']?.toString() ?? '')),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                          width: 100,
                          child: Text('Dept/ Designation:',
                              style: _fSerif(size: 9.5))),
                      Expanded(
                          child: _buildUnderlineValue(
                              doc['m_doctorDeptDesig']?.toString() ?? '')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
    keepWithNext: true,
  ));

  // IMPORTANT NOTE BOX
  blocks.add(_ContentBlock(
    id: 'm_important_note_box',
    widget: Container(
      margin: const EdgeInsets.only(top: 6, bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50.withValues(alpha: 0.4),
        border: Border.all(color: Colors.amber.shade300, width: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('IMPORTANT NOTE** / महत्त्वाची टिपणी** :',
              style: _fSerif(size: 9.5, weight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(
            '• The provisional opinion must be in the form of general opinion / impression about possibility of sexual intercourse, after taking into account positive findings in relation to genitals and the body in general. Must include capacity of the accused to perform sexual act.',
            style: _fSerif(size: 8.5, height: 1.25),
          ),
          const SizedBox(height: 2),
          Text(
            '• Precisely brief justification (reasons) in support of your opinion must be given.',
            style: _fSerif(size: 8.5, height: 1.25),
          ),
          const SizedBox(height: 2),
          Text(
            '• * The accused can be examined physically without consent as per Cr.P.C 53 & 53 a, if he denies consent.',
            style: _fSerif(size: 8.5, height: 1.25),
          ),
        ],
      ),
    ),
    keepWithNext: true,
  ));

  // RECEIPT (by police official)
  blocks.add(_ContentBlock(
    id: 'm_police_receipt',
    widget: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(
          'RECEIPT (by police official):',
          'पोलीस अधिकाऱ्याची पावती :',
        ),
        Text(
            'Received forensic medical examination report: / फॉरेन्सिक वैद्यकीय तपासणी अहवाल मिळाला:',
            style: _fSerif(size: 9.5, fontStyle: FontStyle.italic)),
        const SizedBox(height: 4),
        _buildFieldRow([
          _buildBilingualField(
              labelEn: 'Signature',
              labelMr: 'सही',
              value: doc['m_receiptPolice']?.toString() ?? ''),
          _buildBilingualField(
              labelEn: 'Name of police',
              labelMr: 'पोलीस नाव',
              value: doc['m_receiptPoliceName']?.toString() ?? ''),
          _buildBilingualField(
              labelEn: 'Buckle No.',
              labelMr: 'बक्कल क्र.',
              value: doc['m_receiptBuckleNo']?.toString() ?? ''),
          _buildBilingualField(
              labelEn: 'Police station',
              labelMr: 'पोलीस ठाणे',
              value: doc['m_receiptPs']?.toString() ?? ''),
        ]),
      ],
    ),
  ));

  return blocks;
}

// ── Measurement & Block Packing ────────────────────────────────────────────────

Future<({List<double> heights, Map<int, double> headerHeights})> _measureBlocks(
  BuildContext context,
  List<_ContentBlock> blocks,
) async {
  final keys = List.generate(blocks.length, (_) => GlobalKey());
  final headerKeys = <int, GlobalKey>{};
  for (int i = 0; i < blocks.length; i++) {
    if (blocks[i].tableHeaderToRepeat != null) {
      headerKeys[i] = GlobalKey();
    }
  }

  final completer =
      Completer<({List<double> heights, Map<int, double> headerHeights})>();
  OverlayEntry? entry;

  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -(_kPageW + 300),
      top: 0,
      width: _kContentW,
      child: Material(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < blocks.length; i++) ...[
              SizedBox(
                key: keys[i],
                width: _kContentW,
                child: blocks[i].widget,
              ),
              if (headerKeys.containsKey(i))
                SizedBox(
                  key: headerKeys[i],
                  width: _kContentW,
                  child: blocks[i].tableHeaderToRepeat!,
                ),
            ],
          ],
        ),
      ),
    ),
  );

  Overlay.of(context).insert(entry);

  try {
    WidgetsBinding.instance.scheduleFrame();
    await Future.any([
      WidgetsBinding.instance.endOfFrame,
      Future.delayed(const Duration(milliseconds: 150)),
    ]);
    await Future.delayed(const Duration(milliseconds: 60));

    final heights = <double>[];
    for (int i = 0; i < blocks.length; i++) {
      final rb = keys[i].currentContext?.findRenderObject() as RenderBox?;
      final h = rb?.size.height ?? 35.0;
      heights.add(h > 0 ? h : 35.0);
    }

    final headerHeights = <int, double>{};
    for (final entry in headerKeys.entries) {
      final rb = entry.value.currentContext?.findRenderObject() as RenderBox?;
      final h = rb?.size.height ?? 30.0;
      headerHeights[entry.key] = h > 0 ? h : 30.0;
    }

    completer.complete((heights: heights, headerHeights: headerHeights));
  } catch (e) {
    completer.complete((
      heights: List.filled(blocks.length, 50.0),
      headerHeights: <int, double>{},
    ));
  } finally {
    entry.remove();
  }

  return completer.future;
}

List<List<Medical376Block>> packMedical376Blocks({
  required List<Medical376Block> blocks,
  required dynamic heights,
  dynamic headerHeights,
  double maxContentHeight = _kMaxPageContentH,
}) {
  final pages = <List<Medical376Block>>[];
  var currentPage = <Medical376Block>[];
  double currentHeight = 0.0;

  for (int i = 0; i < blocks.length; i++) {
    final block = blocks[i];
    final double blockH;
    if (heights is Map<String, double>) {
      blockH = heights[block.id] ?? block.estimatedHeight;
    } else if (heights is List<double> && i < heights.length) {
      blockH = heights[i];
    } else {
      blockH = block.estimatedHeight;
    }

    // Check if keepWithNext requires keeping current block with next block
    double neededH = blockH;
    if (block.keepWithNext && i + 1 < blocks.length) {
      final nextBlock = blocks[i + 1];
      if (heights is Map<String, double>) {
        neededH += (heights[nextBlock.id] ?? nextBlock.estimatedHeight);
      } else if (heights is List<double> && (i + 1) < heights.length) {
        neededH += heights[i + 1];
      } else {
        neededH += nextBlock.estimatedHeight;
      }
    }

    if (currentHeight + neededH > maxContentHeight && currentPage.isNotEmpty) {
      pages.add(currentPage);
      currentPage = <Medical376Block>[];
      currentHeight = 0.0;

      // If moving to a new page and this block has a repeated table header, insert it first
      if (block.tableHeaderToRepeat != null) {
        final double hH;
        if (headerHeights is Map<String, double>) {
          hH = headerHeights[block.id] ?? 30.0;
        } else if (headerHeights is Map<int, double>) {
          hH = headerHeights[i] ?? 30.0;
        } else {
          hH = 30.0;
        }
        currentPage.add(Medical376Block(
          id: '${block.id}_rpt_hdr',
          widget: block.tableHeaderToRepeat!,
          estimatedHeight: hH,
        ));
        currentHeight += hH;
      }
    }

    currentPage.add(block);
    currentHeight += blockH;
  }

  if (currentPage.isNotEmpty) {
    pages.add(currentPage);
  }

  // Debug assert and detailed log for each packed page
  debugPrint('=== 376 Medical Form Paginator Real Page Breakdown ===');
  for (int p = 0; p < pages.length; p++) {
    final page = pages[p];
    double pageSum = 0.0;
    debugPrint('--- PAGE ${p + 1} of ${pages.length} ---');
    for (final b in page) {
      final double bH;
      if (b.id.endsWith('_rpt_hdr')) {
        bH = b.estimatedHeight;
      } else if (heights is Map<String, double>) {
        bH = heights[b.id] ?? b.estimatedHeight;
      } else {
        final idx = blocks.indexWhere((orig) => orig.id == b.id);
        bH = (idx >= 0 && heights is List<double> && idx < heights.length)
            ? heights[idx]
            : b.estimatedHeight;
      }
      pageSum += bH;
      debugPrint('   ${b.id.padRight(28)} : ${bH.toStringAsFixed(1)} px');
    }
    debugPrint(
        '   TOTAL PAGE ${p + 1} SUM : ${pageSum.toStringAsFixed(1)} px / MAX ${maxContentHeight.toStringAsFixed(1)} px (Remaining: ${(maxContentHeight - pageSum).toStringAsFixed(1)} px)');
    assert(
      pageSum <= maxContentHeight + 0.1,
      'Page ${p + 1} overflowed! Sum: $pageSum px > Max: $maxContentHeight px',
    );
    if (pageSum > maxContentHeight + 0.1) {
      throw StateError(
        'Page ${p + 1} height ($pageSum px) exceeded maximum allowed ($maxContentHeight px)!',
      );
    }
  }

  return pages;
}

List<List<Widget>> _packBlocksIntoPages(
  List<_ContentBlock> blocks,
  List<double> heights,
  Map<int, double> headerHeights,
) {
  final packed = packMedical376Blocks(
    blocks: blocks,
    heights: heights,
    headerHeights: headerHeights,
  );
  return packed.map((page) => page.map((b) => b.widget).toList()).toList();
}

// ── High-Resolution Single Page Offscreen Capture ──────────────────────────────

Widget _buildA4Page({
  required List<Widget> content,
  required int pageNumber,
  required int totalPages,
}) {
  return SizedBox(
    width: _kPageW,
    height: _kPageH,
    child: ClipRect(
      child: Container(
        color: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: _kPadH, vertical: _kPadV),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: content,
              ),
            ),
            // Clean Footer with reserved height and build marker
            Container(
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: Colors.black26, width: 0.5)),
              ),
              child: Text(
                'Page $pageNumber of $totalPages / पृष्ठ $pageNumber पैकी $totalPages  •  Build 2026-10-03-v2.2',
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<
    ({
      List<Uint8List> images,
      int layoutWaitMs,
      List<int> toImageTimes,
      List<int> encodeTimes,
    })> _captureOffscreenPagesSequential(
  BuildContext context,
  List<Widget> pageWidgets, {
  pw.Document? pdfDoc,
  void Function(String status)? onStatus,
  void Function(int current, int total)? onProgress,
}) async {
  final images = <Uint8List>[];
  final toImageTimes = <int>[];
  final encodeTimes = <int>[];
  int totalLayoutWaitMs = 0;

  for (int i = 0; i < pageWidgets.length; i++) {
    onProgress?.call(i + 1, pageWidgets.length);
    onStatus?.call('Rendering page ${i + 1} of ${pageWidgets.length}...');

    final boundaryKey = GlobalKey();
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -(_kPageW + 500),
        top: 0,
        width: _kPageW,
        height: _kPageH,
        child: Material(
          color: Colors.white,
          child: RepaintBoundary(
            key: boundaryKey,
            child: pageWidgets[i],
          ),
        ),
      ),
    );

    if (!context.mounted) break;
    final overlayState = Overlay.of(context);
    overlayState.insert(entry);

    try {
      final swWait = Stopwatch()..start();
      WidgetsBinding.instance.scheduleFrame();
      await Future.any([
        WidgetsBinding.instance.endOfFrame,
        Future.delayed(const Duration(milliseconds: 70)),
      ]);
      await Future.delayed(const Duration(milliseconds: 20));
      swWait.stop();
      totalLayoutWaitMs += swWait.elapsedMilliseconds;

      final rb = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (rb != null) {
        final swImg = Stopwatch()..start();
        // pixelRatio 1.5 provides crystal clear text for medical records with 45% smaller memory footprint
        final img = await rb.toImage(pixelRatio: 1.5);
        swImg.stop();
        toImageTimes.add(swImg.elapsedMilliseconds);

        onStatus?.call('Encoding page ${i + 1} of ${pageWidgets.length}...');
        final swEnc = Stopwatch()..start();
        final bytes =
            await FormImagePdfHelper.encodeImageFast(img, quality: 0.83);
        img.dispose();
        swEnc.stop();
        encodeTimes.add(swEnc.elapsedMilliseconds);

        images.add(bytes);

        // Add directly to pw.Document (avoids re-encoding/decompression)
        if (pdfDoc != null) {
          pdfDoc.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.zero,
              build: (_) => pw.Image(
                pw.MemoryImage(bytes),
                fit: pw.BoxFit.fill,
                width: PdfPageFormat.a4.width,
                height: PdfPageFormat.a4.height,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error capturing page ${i + 1}: $e');
    } finally {
      entry.remove();
    }

    // Fast yield to browser event loop
    await Future.delayed(Duration.zero);
  }

  return (
    images: images,
    layoutWaitMs: totalLayoutWaitMs,
    toImageTimes: toImageTimes,
    encodeTimes: encodeTimes,
  );
}
