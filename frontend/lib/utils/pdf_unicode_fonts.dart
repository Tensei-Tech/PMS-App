// lib/utils/pdf_unicode_fonts.dart
// Embeds Open Sans in PDFs so em dash, Devanagari, and other Unicode text render (not Helvetica).

import 'package:pdf/widgets.dart' as pw;
import 'pdf_font_cache.dart';

class PdfUnicodeFonts {
  PdfUnicodeFonts._();

  static Future<pw.ThemeData> openSansTheme() => PdfFontCache.openSansTheme();
}
