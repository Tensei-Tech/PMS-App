// lib/utils/pdf_font_cache.dart
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Global in-memory cache for PDF Google fonts and themes across the application.
/// Avoids repeated network downloads and font parsing on every PDF generation.
class PdfFontCache {
  PdfFontCache._();

  static pw.Font? _loraRegular;
  static pw.Font? _loraBold;
  static pw.Font? _devanagariRegular;
  static pw.Font? _devanagariBold;
  static pw.Font? _openSansRegular;
  static pw.Font? _openSansBold;
  static pw.Font? _openSansItalic;
  static pw.ThemeData? _openSansTheme;

  static Future<pw.Font> loraRegular() async =>
      _loraRegular ??= await PdfGoogleFonts.loraRegular();

  static Future<pw.Font> loraBold() async =>
      _loraBold ??= await PdfGoogleFonts.loraBold();

  static Future<pw.Font> devanagariRegular() async =>
      _devanagariRegular ??= await PdfGoogleFonts.notoSansDevanagariRegular();

  static Future<pw.Font> devanagariBold() async =>
      _devanagariBold ??= await PdfGoogleFonts.notoSansDevanagariBold();

  static Future<pw.Font> openSansRegular() async =>
      _openSansRegular ??= await PdfGoogleFonts.openSansRegular();

  static Future<pw.Font> openSansBold() async =>
      _openSansBold ??= await PdfGoogleFonts.openSansBold();

  static Future<pw.Font> openSansItalic() async =>
      _openSansItalic ??= await PdfGoogleFonts.openSansItalic();

  static Future<pw.ThemeData> openSansTheme() async {
    if (_openSansTheme != null) return _openSansTheme!;
    final base = await openSansRegular();
    final bold = await openSansBold();
    final italic = await openSansItalic();
    return _openSansTheme =
        pw.ThemeData.withFont(base: base, bold: bold, italic: italic);
  }
}
