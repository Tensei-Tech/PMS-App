// lib/utils/pdf_layout_constants.dart
// Centralized compact layout tokens, typography, and styling standards for official PDF generators.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfLayoutConstants {
  PdfLayoutConstants._();

  // ── Page Margins ───────────────────────────────────────────────────────────
  static const pw.EdgeInsets pageMargin =
      pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20);
  static const pw.EdgeInsets pageMarginCompact =
      pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16);

  // ── Spacing & Gaps ─────────────────────────────────────────────────────────
  static const double sectionGap = 8.0;
  static const double sectionGapCompact = 6.0;
  static const double rowGap = 4.0;
  static const double fieldGap = 8.0;
  static const double labelValueGap = 1.5;
  static const double signatureMarginTop = 14.0;

  // ── Padding Tokens ─────────────────────────────────────────────────────────
  static const pw.EdgeInsets cellPadding =
      pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5);
  static const pw.EdgeInsets headerPadding =
      pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4);
  static const pw.EdgeInsets cardPadding =
      pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5);
  static const pw.EdgeInsets bannerPadding =
      pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6);

  // ── Typography ─────────────────────────────────────────────────────────────
  static const double titleFontSize = 12.0;
  static const double subtitleFontSize = 8.0;
  static const double sectionTitleFontSize = 8.0;
  static const double marathiTitleFontSize = 6.5;
  static const double labelFontSize = 7.0;
  static const double valueFontSize = 7.5;
  static const double valueBoldFontSize = 8.0;
  static const double tableHeaderFontSize = 7.0;
  static const double footerFontSize = 6.5;
  static const double badgeFontSize = 7.0;

  // ── Color Palette ──────────────────────────────────────────────────────────
  static const PdfColor colorDark = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor colorHeaderBg = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor colorLabelBg = PdfColor.fromInt(0xFFF1F5F9);
  static const PdfColor colorRowAltBg = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor colorBorder = PdfColor.fromInt(0xFFCBD5E1);
  static const PdfColor colorSecondary = PdfColor.fromInt(0xFF475569);
  static const PdfColor colorMuted = PdfColor.fromInt(0xFF94A3B8);
  static const PdfColor colorTeal = PdfColor.fromInt(0xFF0EA5E9);
  static const PdfColor colorGreen = PdfColor.fromInt(0xFF059669);
  static const PdfColor colorRed = PdfColor.fromInt(0xFFDC2626);
  static const PdfColor colorAmber = PdfColor.fromInt(0xFFD97706);
  static const PdfColor colorWhite = PdfColors.white;

  // ── Border Widths ──────────────────────────────────────────────────────────
  static const double borderWidth = 0.5;
  static const double borderWidthBold = 0.8;
  static const double borderRadius = 3.5;
}
