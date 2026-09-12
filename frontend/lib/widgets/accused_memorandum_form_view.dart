import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_io_signature_block.dart';
import 'form_paper_page.dart';
import 'form_table_helpers.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';
import 'responsive_field_row.dart';

/// Accused Memorandum Form (आरोपीचे निवेदन पंचनामा)
/// Under Section 23(2) Bhartiya Sakshya Adhiniyam, 2023 कलम २३ (२) भारतीय साक्ष अधिनियम २०२३
///
/// Styled strictly matching Crime Details Form (Form 2-A reference):
/// - Bilingual stacked labels (English bold top, Marathi bold bottom)
/// - Authentic underline and ruled line inputs
/// - Compound FIR No (/20 YY) & compound Date (DD/MM/20 YY)
/// - Dual mode support: Part I, Part II, or Complete form
class AccusedMemorandumFormView extends StatefulWidget {
  final bool readOnly;
  final Map<String, dynamic>? existingRecord;
  final String? formSection;
  final String? pageRange;

  const AccusedMemorandumFormView({
    super.key,
    this.readOnly = false,
    this.existingRecord,
    this.formSection,
    this.pageRange,
  });

  @override
  State<AccusedMemorandumFormView> createState() =>
      AccusedMemorandumFormViewState();
}

class AccusedMemorandumFormViewState extends State<AccusedMemorandumFormView> {
  // Mode detection:
  // Part I: 'Accused Part I' or 'Part I'
  // Part II: 'Accused Part II' or 'Part II'
  // Complete: null, empty or other
  bool get _isPartIOnly {
    final s = widget.formSection?.trim().toLowerCase() ?? '';
    return s == 'accused part i' ||
        (s.contains('part i') && !s.contains('part ii'));
  }

  bool get _isPartIIOnly {
    final s = widget.formSection?.trim().toLowerCase() ?? '';
    return s == 'accused part ii' || s.contains('part ii');
  }

  bool get _isCompleteForm => !_isPartIOnly && !_isPartIIOnly;

  // ─── PART I CONTROLLERS (Image 1: Items 1–7) ─────────────────────────────
  // Item 1: Case Details
  final _distCtrl = TextEditingController();
  final _psCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  // Compound FIR No
  final _firNoCtrl = TextEditingController();
  final _firYearSuffixCtrl = TextEditingController();

  // Compound FIR Date
  final _firDateCtrl = TextEditingController();
  final _firDateDayCtrl = TextEditingController();
  final _firDateMonthCtrl = TextEditingController();
  final _firDateYearCtrl = TextEditingController();

  // Item 2: Accused Particulars
  final _accusedNameCtrl = TextEditingController();
  final _accusedAgeCtrl = TextEditingController();
  final _accusedSexCtrl = TextEditingController();

  // Item 3: Arrest Particulars (Compound Date & Time)
  final _arrestDateCtrl = TextEditingController();
  final _arrestDateDayCtrl = TextEditingController();
  final _arrestDateMonthCtrl = TextEditingController();
  final _arrestDateYearCtrl = TextEditingController();

  final _arrestTimeCtrl = TextEditingController();
  final _arrestTimeHoursCtrl = TextEditingController();
  final _arrestTimeMinutesCtrl = TextEditingController();

  // Item 4: Memorandum Statement
  final _accusedMemorandumCtrl = TextEditingController();

  // Item 5: Place & Time of Memorandum
  final _placeOfMemorandumCtrl = TextEditingController();

  final _memDateCtrl = TextEditingController();
  final _memDateDayCtrl = TextEditingController();
  final _memDateMonthCtrl = TextEditingController();
  final _memDateYearCtrl = TextEditingController();

  final _memTimeFromCtrl = TextEditingController();
  final _memTimeFromHoursCtrl = TextEditingController();
  final _memTimeFromMinutesCtrl = TextEditingController();
  final _memTimeToCtrl = TextEditingController();
  final _memTimeToHoursCtrl = TextEditingController();
  final _memTimeToMinutesCtrl = TextEditingController();

  // Item 6: Panch Particulars & Signatures
  final _panch1NameAddrCtrl = TextEditingController();
  final _panch1SigCtrl = TextEditingController();
  final _panch2NameAddrCtrl = TextEditingController();
  final _panch2SigCtrl = TextEditingController();

  // Item 7: Signatures (Part I)
  final _part1AccusedSigCtrl = TextEditingController();
  final _part1IoNameCtrl = TextEditingController();
  final _part1IoRankCtrl = TextEditingController();
  final _part1IoNoCtrl = TextEditingController();
  final _part1IoPostingCtrl = TextEditingController();

  // ─── PART II CONTROLLERS (Image 3: Items 8–10) ────────────────────────────
  // Item 8: Details of Further Panchanama
  final _furtherPanchanamaCtrl = TextEditingController();

  final _furtherDateCtrl = TextEditingController();
  final _furtherDateDayCtrl = TextEditingController();
  final _furtherDateMonthCtrl = TextEditingController();
  final _furtherDateYearCtrl = TextEditingController();

  final _furtherTimeFromCtrl = TextEditingController();
  final _furtherTimeFromHoursCtrl = TextEditingController();
  final _furtherTimeFromMinutesCtrl = TextEditingController();
  final _furtherTimeToCtrl = TextEditingController();
  final _furtherTimeToHoursCtrl = TextEditingController();
  final _furtherTimeToMinutesCtrl = TextEditingController();

  // Item 9: Panch Particulars & Signatures (Part II)
  final _furtherPanch1NameAddrCtrl = TextEditingController();
  final _furtherPanch1SigCtrl = TextEditingController();
  final _furtherPanch2NameAddrCtrl = TextEditingController();
  final _furtherPanch2SigCtrl = TextEditingController();

  // Item 10: Signatures (Part II)
  final _accusedSigCtrl = TextEditingController();
  final _ioNameCtrl = TextEditingController();
  final _ioRankCtrl = TextEditingController();
  final _ioNoCtrl = TextEditingController();
  final _ioPostingCtrl = TextEditingController();

  // ─── COMBINED GETTERS ─────────────────────────────────────────────────────
  String get _firNoCombined {
    final no = _firNoCtrl.text.trim();
    final yy = _firYearSuffixCtrl.text.trim();
    if (no.isEmpty && yy.isEmpty) return '';
    if (yy.isNotEmpty) return '$no/20$yy';
    return no;
  }

  String get _firDateCombined => _combineDate(
        _firDateDayCtrl,
        _firDateMonthCtrl,
        _firDateYearCtrl,
        _firDateCtrl,
      );

  String get _arrestDateCombined => _combineDate(
        _arrestDateDayCtrl,
        _arrestDateMonthCtrl,
        _arrestDateYearCtrl,
        _arrestDateCtrl,
      );

  String get _arrestTimeCombined {
    final h = _arrestTimeHoursCtrl.text.trim();
    final m = _arrestTimeMinutesCtrl.text.trim();
    if (h.isEmpty && m.isEmpty) return _arrestTimeCtrl.text.trim();
    if (h.isNotEmpty && m.isNotEmpty) return '$h:$m';
    return h.isNotEmpty ? h : m;
  }

  String get _memDateCombined => _combineDate(
        _memDateDayCtrl,
        _memDateMonthCtrl,
        _memDateYearCtrl,
        _memDateCtrl,
      );

  String get _memTimeCombined => _combineTimeRange(
        _memTimeFromHoursCtrl,
        _memTimeFromMinutesCtrl,
        _memTimeToHoursCtrl,
        _memTimeToMinutesCtrl,
        _memTimeFromCtrl,
        _memTimeToCtrl,
      );

  String get _furtherDateCombined => _combineDate(
        _furtherDateDayCtrl,
        _furtherDateMonthCtrl,
        _furtherDateYearCtrl,
        _furtherDateCtrl,
      );

  String get _furtherTimeCombined => _combineTimeRange(
        _furtherTimeFromHoursCtrl,
        _furtherTimeFromMinutesCtrl,
        _furtherTimeToHoursCtrl,
        _furtherTimeToMinutesCtrl,
        _furtherTimeFromCtrl,
        _furtherTimeToCtrl,
      );

  static String _combineDate(
    TextEditingController dayCtrl,
    TextEditingController monthCtrl,
    TextEditingController yearCtrl,
    TextEditingController fallbackCtrl,
  ) {
    final d = dayCtrl.text.trim();
    final m = monthCtrl.text.trim();
    final y = yearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) {
      return fallbackCtrl.text.trim();
    }
    final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
    return '$d/$m/$yFull'.replaceAll(RegExp(r'/+$'), '');
  }

  static String _combineTimeRange(
    TextEditingController fromH,
    TextEditingController fromM,
    TextEditingController toH,
    TextEditingController toM,
    TextEditingController fallbackFrom,
    TextEditingController fallbackTo,
  ) {
    final fh = fromH.text.trim();
    final fm = fromM.text.trim();
    final th = toH.text.trim();
    final tm = toM.text.trim();
    if (fh.isEmpty && fm.isEmpty && th.isEmpty && tm.isEmpty) {
      final f = fallbackFrom.text.trim();
      final t = fallbackTo.text.trim();
      if (f.isNotEmpty && t.isNotEmpty) return '$f ते $t पर्यंत';
      return f.isNotEmpty ? f : t;
    }
    final from =
        fh.isNotEmpty && fm.isNotEmpty ? '$fh:$fm' : (fh.isNotEmpty ? fh : fm);
    final to =
        th.isNotEmpty && tm.isNotEmpty ? '$th:$tm' : (th.isNotEmpty ? th : tm);
    if (from.isNotEmpty && to.isNotEmpty) {
      return '$from ते $to पर्यंत';
    } else if (from.isNotEmpty) {
      return from;
    } else {
      return to;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      hydrateFrom(widget.existingRecord!);
    }
  }

  @override
  void dispose() {
    _distCtrl.dispose();
    _psCtrl.dispose();
    _yearCtrl.dispose();
    _firNoCtrl.dispose();
    _firYearSuffixCtrl.dispose();
    _firDateCtrl.dispose();
    _firDateDayCtrl.dispose();
    _firDateMonthCtrl.dispose();
    _firDateYearCtrl.dispose();

    _accusedNameCtrl.dispose();
    _accusedAgeCtrl.dispose();
    _accusedSexCtrl.dispose();

    _arrestDateCtrl.dispose();
    _arrestDateDayCtrl.dispose();
    _arrestDateMonthCtrl.dispose();
    _arrestDateYearCtrl.dispose();
    _arrestTimeCtrl.dispose();
    _arrestTimeHoursCtrl.dispose();
    _arrestTimeMinutesCtrl.dispose();

    _accusedMemorandumCtrl.dispose();

    _placeOfMemorandumCtrl.dispose();
    _memDateCtrl.dispose();
    _memDateDayCtrl.dispose();
    _memDateMonthCtrl.dispose();
    _memDateYearCtrl.dispose();
    _memTimeFromCtrl.dispose();
    _memTimeFromHoursCtrl.dispose();
    _memTimeFromMinutesCtrl.dispose();
    _memTimeToCtrl.dispose();
    _memTimeToHoursCtrl.dispose();
    _memTimeToMinutesCtrl.dispose();

    _panch1NameAddrCtrl.dispose();
    _panch1SigCtrl.dispose();
    _panch2NameAddrCtrl.dispose();
    _panch2SigCtrl.dispose();

    _part1AccusedSigCtrl.dispose();
    _part1IoNameCtrl.dispose();
    _part1IoRankCtrl.dispose();
    _part1IoNoCtrl.dispose();
    _part1IoPostingCtrl.dispose();

    _furtherPanchanamaCtrl.dispose();
    _furtherDateCtrl.dispose();
    _furtherDateDayCtrl.dispose();
    _furtherDateMonthCtrl.dispose();
    _furtherDateYearCtrl.dispose();
    _furtherTimeFromCtrl.dispose();
    _furtherTimeFromHoursCtrl.dispose();
    _furtherTimeFromMinutesCtrl.dispose();
    _furtherTimeToCtrl.dispose();
    _furtherTimeToHoursCtrl.dispose();
    _furtherTimeToMinutesCtrl.dispose();

    _furtherPanch1NameAddrCtrl.dispose();
    _furtherPanch1SigCtrl.dispose();
    _furtherPanch2NameAddrCtrl.dispose();
    _furtherPanch2SigCtrl.dispose();

    _accusedSigCtrl.dispose();
    _ioNameCtrl.dispose();
    _ioRankCtrl.dispose();
    _ioNoCtrl.dispose();
    _ioPostingCtrl.dispose();

    super.dispose();
  }

  void hydrateFrom(Map<String, dynamic> data) {
    void setField(TextEditingController ctrl, String key,
        [String fallback = '']) {
      if (data.containsKey(key) && data[key] != null) {
        ctrl.text = data[key].toString();
      } else if (fallback.isNotEmpty && ctrl.text.isEmpty) {
        ctrl.text = fallback;
      }
    }

    setField(_distCtrl, 'dist');
    setField(_psCtrl, 'ps');
    setField(_yearCtrl, 'year');

    // FIR No
    setField(_firNoCtrl, 'firNo');
    setField(_firYearSuffixCtrl, 'firYearSuffix');
    if (_firYearSuffixCtrl.text.isEmpty && _firNoCtrl.text.contains('/')) {
      final parts = _firNoCtrl.text.split('/');
      _firNoCtrl.text = parts[0].trim();
      var yr = parts[1].trim();
      if (yr.startsWith('20')) yr = yr.substring(2);
      _firYearSuffixCtrl.text = yr;
    }

    // FIR Date
    setField(_firDateCtrl, 'firDate');
    _populateDate(_firDateCtrl.text, _firDateDayCtrl, _firDateMonthCtrl,
        _firDateYearCtrl);

    // Accused
    setField(_accusedNameCtrl, 'accusedName');
    setField(_accusedAgeCtrl, 'accusedAge');
    setField(_accusedSexCtrl, 'accusedSex');

    // Arrest Date & Time
    setField(_arrestDateCtrl, 'arrestDate');
    _populateDate(_arrestDateCtrl.text, _arrestDateDayCtrl,
        _arrestDateMonthCtrl, _arrestDateYearCtrl);
    setField(_arrestTimeCtrl, 'arrestTime');
    _populateTime(
        _arrestTimeCtrl.text, _arrestTimeHoursCtrl, _arrestTimeMinutesCtrl);

    // Memorandum
    setField(_accusedMemorandumCtrl, 'accusedMemorandum');

    // Place & Time
    setField(_placeOfMemorandumCtrl, 'placeOfMemorandum');
    setField(_memDateCtrl, 'memDate');
    _populateDate(_memDateCtrl.text, _memDateDayCtrl, _memDateMonthCtrl,
        _memDateYearCtrl);
    setField(_memTimeFromCtrl, 'memTimeFrom');
    setField(_memTimeToCtrl, 'memTimeTo');
    _populateTimeRange(
      _memTimeFromCtrl.text.isNotEmpty
          ? '${_memTimeFromCtrl.text} ते ${_memTimeToCtrl.text}'
          : (data['memTime']?.toString() ?? ''),
      _memTimeFromHoursCtrl,
      _memTimeFromMinutesCtrl,
      _memTimeToHoursCtrl,
      _memTimeToMinutesCtrl,
    );

    // Panchas 1
    setField(_panch1NameAddrCtrl, 'panch1NameAddr');
    setField(_panch1SigCtrl, 'panch1Sig');
    setField(_panch2NameAddrCtrl, 'panch2NameAddr');
    setField(_panch2SigCtrl, 'panch2Sig');

    // Part I Signatures
    setField(_part1AccusedSigCtrl, 'part1AccusedSig');
    setField(_part1IoNameCtrl, 'part1IoName');
    setField(_part1IoRankCtrl, 'part1IoRank');
    setField(_part1IoNoCtrl, 'part1IoNo');
    setField(_part1IoPostingCtrl, 'part1IoPosting');

    // Part II
    setField(_furtherPanchanamaCtrl, 'furtherPanchanama');
    setField(_furtherDateCtrl, 'furtherDate');
    _populateDate(_furtherDateCtrl.text, _furtherDateDayCtrl,
        _furtherDateMonthCtrl, _furtherDateYearCtrl);
    setField(_furtherTimeFromCtrl, 'furtherTimeFrom');
    setField(_furtherTimeToCtrl, 'furtherTimeTo');
    _populateTimeRange(
      _furtherTimeFromCtrl.text.isNotEmpty
          ? '${_furtherTimeFromCtrl.text} ते ${_furtherTimeToCtrl.text}'
          : (data['furtherTime']?.toString() ?? ''),
      _furtherTimeFromHoursCtrl,
      _furtherTimeFromMinutesCtrl,
      _furtherTimeToHoursCtrl,
      _furtherTimeToMinutesCtrl,
    );

    setField(_furtherPanch1NameAddrCtrl, 'furtherPanch1NameAddr');
    setField(_furtherPanch1SigCtrl, 'furtherPanch1Sig');
    setField(_furtherPanch2NameAddrCtrl, 'furtherPanch2NameAddr');
    setField(_furtherPanch2SigCtrl, 'furtherPanch2Sig');

    setField(_accusedSigCtrl, 'accusedSig');
    setField(_ioNameCtrl, 'ioName');
    setField(_ioRankCtrl, 'ioRank');
    setField(_ioNoCtrl, 'ioNo');
    setField(_ioPostingCtrl, 'ioPosting');

    if (mounted) setState(() {});
  }

  static void _populateDate(
    String dateStr,
    TextEditingController dayCtrl,
    TextEditingController monthCtrl,
    TextEditingController yearCtrl,
  ) {
    if (dateStr.isEmpty) return;
    final parts = dateStr.split(RegExp(r'[-/.]'));
    if (parts.isNotEmpty && parts[0].isNotEmpty) dayCtrl.text = parts[0];
    if (parts.length > 1 && parts[1].isNotEmpty) monthCtrl.text = parts[1];
    if (parts.length > 2 && parts[2].isNotEmpty) {
      var y = parts[2];
      if (y.length == 4 && y.startsWith('20')) {
        y = y.substring(2);
      }
      yearCtrl.text = y;
    }
  }

  static void _populateTime(
    String timeStr,
    TextEditingController hoursCtrl,
    TextEditingController minutesCtrl,
  ) {
    if (timeStr.isEmpty) return;
    final parts = timeStr.split(RegExp(r'[:/.\s]'));
    if (parts.isNotEmpty && parts[0].isNotEmpty) hoursCtrl.text = parts[0];
    if (parts.length > 1 && parts[1].isNotEmpty) minutesCtrl.text = parts[1];
  }

  static void _populateTimeRange(
    String timeStr,
    TextEditingController fromH,
    TextEditingController fromM,
    TextEditingController toH,
    TextEditingController toM,
  ) {
    if (timeStr.isEmpty) return;
    if (timeStr.contains('ते')) {
      final parts = timeStr.split('ते');
      _populateTime(parts[0].trim(), fromH, fromM);
      if (parts.length > 1) {
        _populateTime(parts[1].replaceAll('पर्यंत', '').trim(), toH, toM);
      }
    } else if (timeStr.contains('-')) {
      final parts = timeStr.split('-');
      _populateTime(parts[0].trim(), fromH, fromM);
      if (parts.length > 1) {
        _populateTime(parts[1].trim(), toH, toM);
      }
    } else {
      _populateTime(timeStr, fromH, fromM);
    }
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'dist': _distCtrl.text.trim(),
      'ps': _psCtrl.text.trim(),
      'year': _yearCtrl.text.trim(),
      'firNo': _firNoCombined,
      'firNoRaw': _firNoCtrl.text.trim(),
      'firYearSuffix': _firYearSuffixCtrl.text.trim(),
      'firDate': _firDateCombined,
      'firDateDay': _firDateDayCtrl.text.trim(),
      'firDateMonth': _firDateMonthCtrl.text.trim(),
      'firDateYear': _firDateYearCtrl.text.trim(),
      'accusedName': _accusedNameCtrl.text.trim(),
      'accusedAge': _accusedAgeCtrl.text.trim(),
      'accusedSex': _accusedSexCtrl.text.trim(),
      'arrestDate': _arrestDateCombined,
      'arrestTime': _arrestTimeCombined,
      'accusedMemorandum': _accusedMemorandumCtrl.text.trim(),
      'placeOfMemorandum': _placeOfMemorandumCtrl.text.trim(),
      'memDate': _memDateCombined,
      'memTime': _memTimeCombined,
      'memTimeFrom': _memTimeFromCtrl.text.trim(),
      'memTimeTo': _memTimeToCtrl.text.trim(),
      'panch1NameAddr': _panch1NameAddrCtrl.text.trim(),
      'panch1Sig': _panch1SigCtrl.text.trim(),
      'panch2NameAddr': _panch2NameAddrCtrl.text.trim(),
      'panch2Sig': _panch2SigCtrl.text.trim(),
      'part1AccusedSig': _part1AccusedSigCtrl.text.trim(),
      'part1IoName': _part1IoNameCtrl.text.trim(),
      'part1IoRank': _part1IoRankCtrl.text.trim(),
      'part1IoNo': _part1IoNoCtrl.text.trim(),
      'part1IoPosting': _part1IoPostingCtrl.text.trim(),
      'furtherPanchanama': _furtherPanchanamaCtrl.text.trim(),
      'furtherDate': _furtherDateCombined,
      'furtherTime': _furtherTimeCombined,
      'furtherTimeFrom': _furtherTimeFromCtrl.text.trim(),
      'furtherTimeTo': _furtherTimeToCtrl.text.trim(),
      'furtherPanch1NameAddr': _furtherPanch1NameAddrCtrl.text.trim(),
      'furtherPanch1Sig': _furtherPanch1SigCtrl.text.trim(),
      'furtherPanch2NameAddr': _furtherPanch2NameAddrCtrl.text.trim(),
      'furtherPanch2Sig': _furtherPanch2SigCtrl.text.trim(),
      'accusedSig': _accusedSigCtrl.text.trim(),
      'ioName': _ioNameCtrl.text.trim(),
      'ioRank': _ioRankCtrl.text.trim(),
      'ioNo': _ioNoCtrl.text.trim(),
      'ioPosting': _ioPostingCtrl.text.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final serifStyle = FormTypography.serifStyle();
    final marathiLabelStyle = FormTypography.marathiLabelStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        if (!_isPartIIOnly) _buildPartIPage(serifStyle, marathiLabelStyle),
        if (_isCompleteForm) const SizedBox(height: 24),
        if (!_isPartIOnly) _buildPartIIPage(serifStyle, marathiLabelStyle),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PART I — Personal Info & Memorandum (Image 1: Items 1 to 7)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPartIPage(TextStyle serifStyle, TextStyle marathiLabelStyle) {
    return FormPaperPage(
      formLabel: _isPartIOnly
          ? 'Part I — Accused Memorandum (आरोपीचे निवेदन)'
          : (_isCompleteForm ? widget.pageRange ?? 'Page 1' : widget.pageRange),
      children: [
        // --- Top Right Form Header ---
        Align(
          alignment: Alignment.topRight,
          child: Text(
            'Form: 2-E',
            style: serifStyle.copyWith(
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // --- Center Title Header ---
        Center(
          child: Column(
            children: [
              Text(
                'ACCUSED MEMORANDUM FORM',
                style: serifStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'गुन्ह्यांच्या तपशीलाचा नमुना/ आरोपीचे निवेदन पंचनामा',
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '(Panchanama u/s 23(2) Bhartiya Saksh Adhiniyam, 2023 कलम २३ (२) भारतीय साक्ष अधिनियम २०२३)',
                style: serifStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // --- SECTION 1: District, P.S., Year, FIR No, Date ---
        _buildSection1(serifStyle, marathiLabelStyle),
        const SizedBox(height: 24),

        // --- SECTION 2: Name of Accused, Age, Sex ---
        _buildSection2(serifStyle, marathiLabelStyle),
        const SizedBox(height: 24),

        // --- SECTION 3: Date and Time of Arrest ---
        _buildSection3(serifStyle, marathiLabelStyle),
        const SizedBox(height: 24),

        // --- SECTION 4: Memorandum made by Accused (Lined text area) ---
        _buildSection4(serifStyle, marathiLabelStyle),
        const SizedBox(height: 24),

        // --- SECTION 5: Place of Memorandum, Date, Time ---
        _buildSection5(serifStyle, marathiLabelStyle),
        const SizedBox(height: 24),

        // --- SECTION 6: Name & Address of Panchas & Signatures ---
        _buildPanchasSection(
          itemNumber: 6,
          nameAddr1Ctrl: _panch1NameAddrCtrl,
          sig1Ctrl: _panch1SigCtrl,
          nameAddr2Ctrl: _panch2NameAddrCtrl,
          sig2Ctrl: _panch2SigCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        const SizedBox(height: 24),

        // --- SECTION 7: Signatures (Accused & I.O.) ---
        _buildSignaturesBlock(
          itemNumber: 7,
          accusedSigCtrl: _part1AccusedSigCtrl,
          ioNameCtrl: _part1IoNameCtrl,
          ioRankCtrl: _part1IoRankCtrl,
          ioNoCtrl: _part1IoNoCtrl,
          ioPostingCtrl: _part1IoPostingCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        const SizedBox(height: 16),
        FormMrwFooter(serifStyle: serifStyle, fontSize: 11),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PART II — Further Panchanama (Image 3: Items 8 to 10)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPartIIPage(TextStyle serifStyle, TextStyle marathiLabelStyle) {
    return FormPaperPage(
      formLabel: _isPartIIOnly
          ? 'Part II — Further Panchanama (अधिक पंचनामा)'
          : (_isCompleteForm ? 'Page 2 — Part II' : widget.pageRange),
      children: [
        // --- Top Right Form Header ---
        Align(
          alignment: Alignment.topRight,
          child: Text(
            'Form: 2-E (Part II)',
            style: serifStyle.copyWith(
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),

        const SizedBox(height: 12),

        // --- SECTION 8: Details of Further Panchanama (Lined text area & Date/Time) ---
        _buildSection8(serifStyle, marathiLabelStyle),
        const SizedBox(height: 24),

        // --- SECTION 9: Name & Address of Panchas & Signatures (Part II) ---
        _buildPanchasSection(
          itemNumber: 9,
          nameAddr1Ctrl: _furtherPanch1NameAddrCtrl,
          sig1Ctrl: _furtherPanch1SigCtrl,
          nameAddr2Ctrl: _furtherPanch2NameAddrCtrl,
          sig2Ctrl: _furtherPanch2SigCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        const SizedBox(height: 24),

        // --- SECTION 10: Signatures (Accused & I.O. - Part II) ---
        _buildSignaturesBlock(
          itemNumber: 10,
          accusedSigCtrl: _accusedSigCtrl,
          ioNameCtrl: _ioNameCtrl,
          ioRankCtrl: _ioRankCtrl,
          ioNoCtrl: _ioNoCtrl,
          ioPostingCtrl: _ioPostingCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        const SizedBox(height: 16),
        FormMrwFooter(serifStyle: serifStyle, fontSize: 11),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SUB-SECTION BUILDERS
  // ──────────────────────────────────────────────────────────────────────────

  /// 1) District / जिल्हा | P.S. / पोलीस स्टेशन | Year / वर्ष | FIR No / पहिली खबर क्र. /20 YY | Date / तारीख
  Widget _buildSection1(TextStyle serifStyle, TextStyle marathiLabelStyle) {
    return ResponsiveFieldRow(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 22,
          child: BilingualField(
            label: '1) District: ',
            marathiLabel: 'जिल्हा',
            controller: _distCtrl,
            serifStyle: serifStyle,
            marathiLabelStyle: marathiLabelStyle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 28,
          child: BilingualField(
            label: 'P.S.: ',
            marathiLabel: 'पोलीस स्टेशन',
            controller: _psCtrl,
            serifStyle: serifStyle,
            marathiLabelStyle: marathiLabelStyle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 15,
          child: BilingualField(
            label: 'Year: ',
            marathiLabel: 'वर्ष',
            controller: _yearCtrl,
            serifStyle: serifStyle,
            marathiLabelStyle: marathiLabelStyle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 22,
          child: ResponsiveFieldRow(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: BilingualField(
                  label: 'FIR No: ',
                  marathiLabel: 'पहिली खबर क्र.',
                  controller: _firNoCtrl,
                  serifStyle: serifStyle,
                  marathiLabelStyle: marathiLabelStyle,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2.0, left: 2, right: 2),
                child: Text('/20', style: serifStyle),
              ),
              SizedBox(
                width: 35,
                child: BilingualSimpleUnderlineInput(
                  controller: _firYearSuffixCtrl,
                  serifStyle: serifStyle,
                  hintText: 'YY',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date : ', style: serifStyle),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 35,
                        child: BilingualSimpleUnderlineInput(
                          controller: _firDateDayCtrl,
                          serifStyle: serifStyle,
                          hintText: 'DD',
                        ),
                      ),
                      Text('/', style: serifStyle),
                      SizedBox(
                        width: 35,
                        child: BilingualSimpleUnderlineInput(
                          controller: _firDateMonthCtrl,
                          serifStyle: serifStyle,
                          hintText: 'MM',
                        ),
                      ),
                      Text('/20', style: serifStyle),
                      SizedBox(
                        width: 35,
                        child: BilingualSimpleUnderlineInput(
                          controller: _firDateYearCtrl,
                          serifStyle: serifStyle,
                          hintText: 'YY',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('तारीख', style: marathiLabelStyle),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 2) Name of Accused / आरोपीचे नाव व पत्ता | Age / वय | Sex / लिंग
  Widget _buildSection2(TextStyle serifStyle, TextStyle marathiLabelStyle) {
    return ResponsiveFieldRow(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 55,
          child: BilingualField(
            label: '2) Name of Accused: ',
            marathiLabel: 'आरोपीचे नाव व पत्ता',
            controller: _accusedNameCtrl,
            serifStyle: serifStyle,
            marathiLabelStyle: marathiLabelStyle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 20,
          child: BilingualField(
            label: 'Age: ',
            marathiLabel: 'वय',
            controller: _accusedAgeCtrl,
            serifStyle: serifStyle,
            marathiLabelStyle: marathiLabelStyle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 25,
          child: BilingualField(
            label: 'Sex: ',
            marathiLabel: 'लिंग',
            controller: _accusedSexCtrl,
            serifStyle: serifStyle,
            marathiLabelStyle: marathiLabelStyle,
          ),
        ),
      ],
    );
  }

  /// 3) Date and Time of Arrest / अटकेची तारीख व वेळ
  Widget _buildSection3(TextStyle serifStyle, TextStyle marathiLabelStyle) {
    return ResponsiveFieldRow(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '3) Date and Time of Arrest :',
                style: serifStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'अटकेची तारीख व वेळ',
                style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date : ', style: serifStyle),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _arrestDateDayCtrl,
                              serifStyle: serifStyle,
                              hintText: 'DD',
                            ),
                          ),
                          Text('/', style: serifStyle),
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _arrestDateMonthCtrl,
                              serifStyle: serifStyle,
                              hintText: 'MM',
                            ),
                          ),
                          Text('/20', style: serifStyle),
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _arrestDateYearCtrl,
                              serifStyle: serifStyle,
                              hintText: 'YY',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('तारीख', style: marathiLabelStyle),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Time of Arrest :',
                style: serifStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'अटकेची वेळ',
                style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time : ', style: serifStyle),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _arrestTimeHoursCtrl,
                              serifStyle: serifStyle,
                              hintText: 'HH',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(':', style: serifStyle),
                          ),
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _arrestTimeMinutesCtrl,
                              serifStyle: serifStyle,
                              hintText: 'MM',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text('Hrs',
                                style: serifStyle.copyWith(fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('वेळ', style: marathiLabelStyle),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 4) Memorandum made by Accused / आरोपीने केलेले निवेदन (Lined paper text area)
  Widget _buildSection4(TextStyle serifStyle, TextStyle marathiLabelStyle) {
    return BilingualMultilineField(
      label: '4) Memorandum made by Accused: -',
      marathiLabel: '(आरोपीने केलेले निवेदन: -)',
      controller: _accusedMemorandumCtrl,
      minLines: 18,
      serifStyle: serifStyle,
      marathiLabelStyle: marathiLabelStyle,
    );
  }

  /// 5) Place of Memorandum / निवेदनाचे ठिकाण | Date / तारीख | Time / वेळ
  Widget _buildSection5(TextStyle serifStyle, TextStyle marathiLabelStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BilingualWideField(
          label: '5) Place of Memorandum :-',
          marathiLabel: 'पंचनाम्याचे / निवेदनाचे ठिकाण',
          controller: _placeOfMemorandumCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        const SizedBox(height: 12),
        ResponsiveFieldRow(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            Expanded(
              flex: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date : ', style: serifStyle),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _memDateDayCtrl,
                              serifStyle: serifStyle,
                              hintText: 'DD',
                            ),
                          ),
                          Text('/', style: serifStyle),
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _memDateMonthCtrl,
                              serifStyle: serifStyle,
                              hintText: 'MM',
                            ),
                          ),
                          Text('/20', style: serifStyle),
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _memDateYearCtrl,
                              serifStyle: serifStyle,
                              hintText: 'YY',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('तारीख', style: marathiLabelStyle),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Time (from ... to ...)
            Expanded(
              flex: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time : ', style: serifStyle),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _memTimeFromHoursCtrl,
                              serifStyle: serifStyle,
                              hintText: 'HH',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(':', style: serifStyle),
                          ),
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _memTimeFromMinutesCtrl,
                              serifStyle: serifStyle,
                              hintText: 'MM',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text('ते :', style: marathiLabelStyle),
                          ),
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _memTimeToHoursCtrl,
                              serifStyle: serifStyle,
                              hintText: 'HH',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(':', style: serifStyle),
                          ),
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _memTimeToMinutesCtrl,
                              serifStyle: serifStyle,
                              hintText: 'MM',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text('पर्यंत', style: marathiLabelStyle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('वेळ (पासून ... पर्यंत)', style: marathiLabelStyle),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 8) Details of Further Panchanama / अधिक पंचनामा तपशील
  Widget _buildSection8(TextStyle serifStyle, TextStyle marathiLabelStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BilingualMultilineField(
          label: '8) Details of Further Panchanama: ',
          marathiLabel: '(पंचनाम्याचा पुढील भाग / अधिक पंचनामा तपशील):-',
          controller: _furtherPanchanamaCtrl,
          minLines: 20,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        const SizedBox(height: 16),
        ResponsiveFieldRow(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            Expanded(
              flex: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date : ', style: serifStyle),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _furtherDateDayCtrl,
                              serifStyle: serifStyle,
                              hintText: 'DD',
                            ),
                          ),
                          Text('/', style: serifStyle),
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _furtherDateMonthCtrl,
                              serifStyle: serifStyle,
                              hintText: 'MM',
                            ),
                          ),
                          Text('/20', style: serifStyle),
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _furtherDateYearCtrl,
                              serifStyle: serifStyle,
                              hintText: 'YY',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('तारीख', style: marathiLabelStyle),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Time (from ... to ...)
            Expanded(
              flex: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time : ', style: serifStyle),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _furtherTimeFromHoursCtrl,
                              serifStyle: serifStyle,
                              hintText: 'HH',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(':', style: serifStyle),
                          ),
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _furtherTimeFromMinutesCtrl,
                              serifStyle: serifStyle,
                              hintText: 'MM',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text('ते :', style: marathiLabelStyle),
                          ),
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _furtherTimeToHoursCtrl,
                              serifStyle: serifStyle,
                              hintText: 'HH',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(':', style: serifStyle),
                          ),
                          SizedBox(
                            width: 35,
                            child: BilingualSimpleUnderlineInput(
                              controller: _furtherTimeToMinutesCtrl,
                              serifStyle: serifStyle,
                              hintText: 'MM',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text('पर्यंत', style: marathiLabelStyle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('वेळ (पासून ... पर्यंत)', style: marathiLabelStyle),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 6 or 9) Name & Address of Panchas & Signatures
  Widget _buildPanchasSection({
    required int itemNumber,
    required TextEditingController nameAddr1Ctrl,
    required TextEditingController sig1Ctrl,
    required TextEditingController nameAddr2Ctrl,
    required TextEditingController sig2Ctrl,
    required TextStyle serifStyle,
    required TextStyle marathiLabelStyle,
  }) {
    return ResponsiveFieldRow(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Panch Name & Address
        Expanded(
          flex: 55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$itemNumber) Name and Address of Panchas:-',
                style: serifStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'पंचांचे नाव व पत्ता',
                style: marathiLabelStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 12),
              Text('(1)',
                  style: serifStyle.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              BilingualDynamicLinedTextField(
                controller: nameAddr1Ctrl,
                minLines: 2,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),
              Text('(2)',
                  style: serifStyle.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              BilingualDynamicLinedTextField(
                controller: nameAddr2Ctrl,
                minLines: 2,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right: Panch Signatures
        Expanded(
          flex: 45,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Signature: -',
                style: serifStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'स्वाक्षरी / सही',
                style: marathiLabelStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 12),
              Text('(1)',
                  style: serifStyle.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              BilingualDynamicLinedTextField(
                controller: sig1Ctrl,
                minLines: 2,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),
              Text('(2)',
                  style: serifStyle.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              BilingualDynamicLinedTextField(
                controller: sig2Ctrl,
                minLines: 2,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 7 or 10) Signatures Block: Accused Signature & Thumb (Left) + I.O. Signature Block (Right)
  Widget _buildSignaturesBlock({
    required int itemNumber,
    required TextEditingController accusedSigCtrl,
    required TextEditingController ioNameCtrl,
    required TextEditingController ioRankCtrl,
    required TextEditingController ioNoCtrl,
    required TextEditingController ioPostingCtrl,
    required TextStyle serifStyle,
    required TextStyle marathiLabelStyle,
  }) {
    return ResponsiveFieldRow(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Accused Signature and Thumb Impression
        Expanded(
          flex: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$itemNumber) Signature and Thumb Impression of Accused: -',
                style: serifStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'आरोपीची स्वाक्षरी व डाव्या हाताच्या अंगठ्याचा ठसा',
                style: marathiLabelStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 125,
                decoration: BoxDecoration(
                  color:
                      widget.readOnly ? const Color(0xFFFAFAFA) : Colors.white,
                  border: Border.all(color: Colors.black45, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: TextField(
                    controller: accusedSigCtrl,
                    readOnly: widget.readOnly,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    style: serifStyle.copyWith(
                      fontSize: 12.5,
                      color: Colors.blue.shade900,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Accused Signature / Thumb Impression\n(आरोपीची स्वाक्षरी / डाव्या हाताच्या अंगठ्याचा ठसा)',
                      hintStyle: serifStyle.copyWith(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),

        // Right Column: Investigation Officer Signature Block
        Expanded(
          flex: 50,
          child: FormIoSignatureBlock(
            nameCtrl: ioNameCtrl,
            rankCtrl: ioRankCtrl,
            numberCtrl: ioNoCtrl,
            postingCtrl: ioPostingCtrl,
            serifStyle: serifStyle,
            marathiLabelStyle: marathiLabelStyle,
            englishLabel: 'Name and Signature of Investigation Officer: -',
            marathiLabel: 'तपासिक अंमलदाराचे नाव व सही',
          ),
        ),
      ],
    );
  }
}
