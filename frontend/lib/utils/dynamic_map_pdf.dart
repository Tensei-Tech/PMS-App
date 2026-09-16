// lib/utils/dynamic_map_pdf.dart
// Fully dynamic PDF bodies from arbitrary Maps / ModuleRecord — labels from hub + A.D maps
// + humanized keys. Nested maps/lists expand recursively. All content uses bordered tables
// with section bands (no hardcoded field lists).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../modules/core/models/base_record.dart';
import '../widgets/ad_form_dynamic_document_view.dart'
    show
        humanizeFieldKey,
        kAdFormFieldLabels,
        kAdProceduralSubLabels,
        kAdUnknownSubLabels;
import '../utils/ad_form_display_order.dart';
import '../widgets/module_record_dynamic_document_view.dart'
    show kModuleHubFieldLabels, orderedModuleHubScalarKeys;
import 'pdf_layout_constants.dart';

class DynamicMapPdf {
  DynamicMapPdf._();

  static const String emptyDisplay = '\u2014';

  static String pdfLabelForKey(String key) =>
      kModuleHubFieldLabels[key] ??
      kAdFormFieldLabels[key] ??
      kAdUnknownSubLabels[key] ??
      kAdProceduralSubLabels[key] ??
      humanizeFieldKey(key);

  static String disp(dynamic v) {
    if (v == null) return emptyDisplay;
    if (v is bool) return v ? 'Yes' : 'No';
    if (v is Timestamp) {
      final d = v.toDate().toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    if (v is DateTime) {
      return DateFormat('dd MMMM yyyy, hh:mm a').format(v.toLocal());
    }
    if (v is String) {
      final t = v.trim();
      if (t.isEmpty) return emptyDisplay;
      try {
        if (t.length >= 10 &&
            (t.contains('T') || RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(t))) {
          final d = DateTime.parse(t).toLocal();
          final datePart = DateFormat('dd MMMM yyyy').format(d);
          final hasTime = t.contains('T') &&
              (d.hour != 0 || d.minute != 0 || d.second != 0);
          if (hasTime) {
            return '$datePart, ${DateFormat('hh:mm a').format(d)}';
          }
          return datePart;
        }
      } catch (_) {}
      return t;
    }
    final s = v.toString().trim();
    return s.isEmpty ? emptyDisplay : s;
  }

  static pw.TableBorder get _tableBorder => pw.TableBorder.all(
        color: PdfLayoutConstants.colorBorder,
        width: PdfLayoutConstants.borderWidth,
      );

  /// Quick summary chips (case no., status, priority) — shared by module / dashboard PDFs.
  static pw.Widget summaryStatBox(String label, String value) {
    return pw.Container(
      padding: PdfLayoutConstants.cellPadding,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfLayoutConstants.colorBorder,
          width: PdfLayoutConstants.borderWidth,
        ),
        borderRadius: pw.BorderRadius.circular(PdfLayoutConstants.borderRadius),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: PdfLayoutConstants.labelFontSize,
              color: PdfLayoutConstants.colorSecondary,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: PdfLayoutConstants.valueBoldFontSize,
              fontWeight: pw.FontWeight.bold,
              color: PdfLayoutConstants.colorDark,
            ),
          ),
        ],
      ),
    );
  }

  /// Standard navy header strip on portrait case reports.
  static pw.Widget pmsNavyHeaderBand({
    required String amberSubtitle,
    String systemTitle = 'POLICE MANAGEMENT SYSTEM',
  }) {
    return pw.Container(
      width: double.infinity,
      padding: PdfLayoutConstants.bannerPadding,
      decoration: const pw.BoxDecoration(
        color: PdfLayoutConstants.colorDark,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            systemTitle,
            style: pw.TextStyle(
              color: PdfLayoutConstants.colorWhite,
              fontSize: PdfLayoutConstants.titleFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            amberSubtitle,
            style: const pw.TextStyle(
              color: PdfLayoutConstants.colorAmber,
              fontSize: PdfLayoutConstants.subtitleFontSize,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget confidentialFooterRow({
    required String generatedText,
    String confidentialText = 'CONFIDENTIAL - Police Use Only',
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfLayoutConstants.colorBorder,
            width: PdfLayoutConstants.borderWidth,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            generatedText,
            style: const pw.TextStyle(
              fontSize: PdfLayoutConstants.footerFontSize,
              color: PdfLayoutConstants.colorSecondary,
            ),
          ),
          pw.Text(
            confidentialText,
            style: pw.TextStyle(
              fontSize: PdfLayoutConstants.footerFontSize,
              color: PdfLayoutConstants.colorSecondary,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Major section title (full-width band) — use for top-level PDF sections.
  static pw.Widget mainSectionBanner(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
      child: pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
        decoration: pw.BoxDecoration(
          color: PdfLayoutConstants.colorDark,
          border: pw.Border.all(
            color: PdfLayoutConstants.colorBorder,
            width: PdfLayoutConstants.borderWidth,
          ),
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: PdfLayoutConstants.sectionTitleFontSize,
            fontWeight: pw.FontWeight.bold,
            color: PdfLayoutConstants.colorWhite,
          ),
        ),
      ),
    );
  }

  /// In-document subsection / nested group heading.
  static pw.Widget subSectionBanner(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6, bottom: 3),
      child: pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: pw.BoxDecoration(
          color: PdfLayoutConstants.colorHeaderBg,
          border: pw.Border.all(
            color: PdfLayoutConstants.colorBorder,
            width: PdfLayoutConstants.borderWidth,
          ),
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: PdfLayoutConstants.sectionTitleFontSize,
            fontWeight: pw.FontWeight.bold,
            color: PdfLayoutConstants.colorDark,
          ),
        ),
      ),
    );
  }

  /// Backwards-compatible name: subsection band under the main document header.
  static pw.Widget sectionHeader(String title) => subSectionBanner(title);

  static pw.Widget _labelCell(String text) {
    return pw.Container(
      color: PdfLayoutConstants.colorLabelBg,
      padding: PdfLayoutConstants.cellPadding,
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: PdfLayoutConstants.labelFontSize,
          fontWeight: pw.FontWeight.bold,
          color: PdfLayoutConstants.colorSecondary,
        ),
      ),
    );
  }

  static pw.Widget _valueCell(String text) {
    return pw.Container(
      padding: PdfLayoutConstants.cellPadding,
      alignment: pw.Alignment.topLeft,
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: PdfLayoutConstants.valueFontSize),
      ),
    );
  }

  static pw.TableRow _kvTableRow(String label, String value) {
    return pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.top,
      children: [_labelCell(label), _valueCell(value)],
    );
  }

  static pw.Widget _twoColumnTable(List<pw.TableRow> rows) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: PdfLayoutConstants.rowGap),
      child: pw.Table(
        border: _tableBorder,
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
        columnWidths: const {
          0: pw.FlexColumnWidth(0.38),
          1: pw.FlexColumnWidth(0.62),
        },
        children: rows,
      ),
    );
  }

  static pw.Widget _singleKv(String label, String value) {
    return _twoColumnTable([_kvTableRow(label, value)]);
  }

  static List<String> _sortedKeys(Map<String, dynamic> data) =>
      data.keys.map((k) => k.toString()).toList()..sort();

  static List<String> _insertionKeys(Map<String, dynamic> data) =>
      data.keys.map((k) => k.toString()).toList();

  static List<pw.Widget> _professionalListItems(
    List<dynamic> list, {
    required bool hubInsertionNestedMaps,
  }) {
    final out = <pw.Widget>[];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      final title = 'Item ${i + 1}';
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        out.add(subSectionBanner(title));
        if (m.isEmpty) {
          out.add(_singleKv('(empty)', emptyDisplay));
        } else {
          final childOrder =
              hubInsertionNestedMaps ? _insertionKeys(m) : _sortedKeys(m);
          out.addAll(_buildHubKeyedMap(m, childOrder));
        }
      } else if (item is List) {
        out.add(subSectionBanner(title));
        if (item.isEmpty) {
          out.add(_singleKv('(empty)', emptyDisplay));
        } else {
          out.addAll(
            _professionalListItems(
              item,
              hubInsertionNestedMaps: hubInsertionNestedMaps,
            ),
          );
        }
      } else {
        out.add(subSectionBanner(title));
        out.add(_singleKv('Value', disp(item)));
      }
    }
    return out;
  }

  /// Hub / generic maps: stable form order at root; nested maps/lists preserve insertion order.
  static List<pw.Widget> _buildHubKeyedMap(
    Map<String, dynamic> data,
    List<String> orderedKeys,
  ) {
    final out = <pw.Widget>[];

    for (final k in orderedKeys) {
      if (!data.containsKey(k)) continue;
      final v = data[k];
      final label = pdfLabelForKey(k);

      if (v is Map) {
        final m = Map<String, dynamic>.from(v);
        out.add(subSectionBanner(label));
        if (m.isEmpty) {
          out.add(_singleKv('(empty)', emptyDisplay));
        } else {
          out.addAll(_buildHubKeyedMap(m, _insertionKeys(m)));
        }
      } else if (v is List) {
        final list = v;
        out.add(subSectionBanner('$label (${list.length})'));
        if (list.isEmpty) {
          out.add(_singleKv('(empty)', emptyDisplay));
        } else {
          out.addAll(
            _professionalListItems(list, hubInsertionNestedMaps: true),
          );
        }
      } else {
        out.add(_singleKv(label, disp(v)));
      }
    }
    return out;
  }

  static List<pw.Widget> _professionalListItemsAd(
    List<dynamic> list, {
    required String listFieldKey,
  }) {
    final out = <pw.Widget>[];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      final title = 'Item ${i + 1}';
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        out.add(subSectionBanner(title));
        if (m.isEmpty) {
          out.add(_singleKv('(empty)', emptyDisplay));
        } else {
          final keys = orderedKeysForAdListItemMap(
            listFieldKey: listFieldKey,
            m: m,
          );
          out.addAll(
            _buildAdFormKeyedMap(m, keys, parentFieldKey: listFieldKey),
          );
        }
      } else if (item is List) {
        out.add(subSectionBanner(title));
        if (item.isEmpty) {
          out.add(_singleKv('(empty)', emptyDisplay));
        } else {
          out.addAll(
            _professionalListItemsAd(item, listFieldKey: listFieldKey),
          );
        }
      } else {
        out.add(subSectionBanner(title));
        out.add(_singleKv('Value', disp(item)));
      }
    }
    return out;
  }

  static List<pw.Widget> _buildAdFormKeyedMap(
    Map<String, dynamic> data,
    List<String> orderedKeys, {
    required String? parentFieldKey,
  }) {
    final out = <pw.Widget>[];
    final rowBuffer = <pw.TableRow>[];

    void flush() {
      if (rowBuffer.isEmpty) return;
      out.add(_twoColumnTable(rowBuffer));
      rowBuffer.clear();
    }

    for (final k in orderedKeys) {
      if (!data.containsKey(k)) continue;
      final v = data[k];
      final label = pdfLabelForKey(k);

      if (v is Map) {
        flush();
        final m = Map<String, dynamic>.from(v);
        out.add(subSectionBanner(label));
        if (m.isEmpty) {
          out.add(_singleKv('(empty)', emptyDisplay));
        } else {
          final kind = adNestedMapKindFor(parentFieldKey: parentFieldKey, m: m);
          final childKeys = orderedKeysForAdNestedMap(kind: kind, m: m);
          final parentForNestedValues = kind == AdNestedMapKind.chargeDataSlots
              ? 'chargeData'
              : parentFieldKey;
          out.addAll(
            _buildAdFormKeyedMap(
              m,
              childKeys,
              parentFieldKey: parentForNestedValues,
            ),
          );
        }
      } else if (v is List) {
        flush();
        final list = v;
        out.add(subSectionBanner('$label (${list.length})'));
        if (list.isEmpty) {
          out.add(_singleKv('(empty)', emptyDisplay));
        } else {
          out.addAll(_professionalListItemsAd(list, listFieldKey: k));
        }
      } else {
        rowBuffer.add(_kvTableRow(label, disp(v)));
      }
    }
    flush();
    return out;
  }

  /// Hub / dashboard case document (ModuleRecord + optional display name).
  static List<pw.Widget> buildModuleRecordPdfBody(
    ModuleRecord record,
    String moduleDisplayName,
  ) {
    final raw = Map<String, dynamic>.from(record.toMap());
    final extra = raw['extraFields'] != null
        ? Map<String, dynamic>.from(raw['extraFields'] as Map? ?? {})
        : <String, dynamic>{};
    raw.remove('extraFields');

    final children = <pw.Widget>[
      mainSectionBanner('Module'),
      _twoColumnTable([_kvTableRow('Dashboard module', moduleDisplayName)]),
      mainSectionBanner('All saved case fields'),
      ..._buildHubKeyedMap(raw, orderedModuleHubScalarKeys(raw)),
    ];

    if (extra.isNotEmpty) {
      children.add(mainSectionBanner('Extended & additional fields'));
      children.addAll(_buildHubKeyedMap(extra, _insertionKeys(extra)));
    }

    return children;
  }

  /// A.D complete form map — field order matches [AdFormScreen.buildAdDocumentMap].
  static List<pw.Widget> buildAdFormMapPdfBody(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return [_singleKv('(empty)', emptyDisplay)];
    }
    return _buildAdFormKeyedMap(
      data,
      orderedAdFormRootKeys(data),
      parentFieldKey: null,
    );
  }

  /// Non–A.D arbitrary nested map (sorted keys). Prefer [buildAdFormMapPdfBody] for A.D.
  static List<pw.Widget> buildArbitraryMapPdfBody(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return [_singleKv('(empty)', emptyDisplay)];
    }
    return _buildHubKeyedMap(data, _sortedKeys(data));
  }

  static pw.Widget _landscapeHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      color: const PdfColor.fromInt(0xFF0A0E21),
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _landscapeBodyCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  /// Landscape listing PDF: columns = union of all row keys (sorted). Labels via [pdfLabelForKey].
  /// Optional leading serial column replaces a stored `sr` key to avoid duplication.
  static pw.Document buildLandscapeDataTableDocument({
    required pw.ThemeData theme,
    required String title,
    required List<Map<String, dynamic>> rows,
    bool prependSerial = true,
  }) {
    final doc = pw.Document();
    final allKeys = <String>{};
    for (final r in rows) {
      for (final k in r.keys) {
        final ks = k.toString();
        if (prependSerial && (ks == 'sr' || ks == 'Sr' || ks == 'SR')) {
          continue;
        }
        allKeys.add(ks);
      }
    }
    final sortedKeys = allKeys.toList()..sort();

    doc.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4.landscape.copyWith(
          marginLeft: 18,
          marginRight: 18,
          marginTop: 18,
          marginBottom: 18,
        ),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              color: const PdfColor.fromInt(0xFF0A0E21),
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
              children: [
                pw.TableRow(
                  children: [
                    if (prependSerial) _landscapeHeaderCell('Sr. No.'),
                    ...sortedKeys.map(
                      (k) => _landscapeHeaderCell(pdfLabelForKey(k)),
                    ),
                  ],
                ),
                for (var i = 0; i < rows.length; i++)
                  pw.TableRow(
                    children: [
                      if (prependSerial) _landscapeBodyCell('${i + 1}'),
                      ...sortedKeys.map(
                        (k) => _landscapeBodyCell(disp(rows[i][k])),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    return doc;
  }
}
