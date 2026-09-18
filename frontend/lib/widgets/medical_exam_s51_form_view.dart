import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// वैद्यकीय तपासणी (भारतीय नागरीक सुरक्षा संहिता २०२३ कलम ५१)
/// Medical Examination Request under Section 51 BNSS
class MedicalExamS51FormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const MedicalExamS51FormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<MedicalExamS51FormView> createState() => MedicalExamS51FormViewState();
}

class MedicalExamS51FormViewState extends State<MedicalExamS51FormView> {
  final _outpostCtrl = TextEditingController();
  final _psCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _dateDayCtrl = TextEditingController();
  final _dateMonthCtrl = TextEditingController();
  final _dateYearCtrl = TextEditingController();

  String get _dateCombined {
    if (_dateCtrl.text.trim().isNotEmpty) {
      return _dateCtrl.text.trim();
    }
    final d = _dateDayCtrl.text.trim();
    final m = _dateMonthCtrl.text.trim();
    final y = _dateYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) {
      return '';
    }
    final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
    return '$d/$m/$yFull'.replaceAll(RegExp(r'/+$'), '');
  }

  Future<void> _pickDateForController({
    required TextEditingController controller,
    TextEditingController? dayCtrl,
    TextEditingController? monthCtrl,
    TextEditingController? yearCtrl,
  }) async {
    final now = DateTime.now();
    DateTime initial = now;
    final currentText = controller.text.trim();
    if (currentText.isNotEmpty) {
      final parts = currentText.split(RegExp(r'[/.-]'));
      if (parts.length >= 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        int? y = int.tryParse(parts[2]);
        if (y != null && y < 100) y += 2000;
        if (d != null && m != null && y != null) {
          try {
            initial = DateTime(y, m, d);
          } catch (_) {}
        }
      }
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      final dStr = picked.day.toString().padLeft(2, '0');
      final mStr = picked.month.toString().padLeft(2, '0');
      final yFullStr = picked.year.toString();
      final yShortStr = (picked.year % 100).toString().padLeft(2, '0');
      controller.text = '$dStr/$mStr/$yFullStr';
      if (dayCtrl != null) dayCtrl.text = dStr;
      if (monthCtrl != null) monthCtrl.text = mStr;
      if (yearCtrl != null) yearCtrl.text = yShortStr;
      if (mounted) setState(() {});
    }
  }

  Widget _datePickerField({
    required TextEditingController controller,
    TextEditingController? dayCtrl,
    TextEditingController? monthCtrl,
    TextEditingController? yearCtrl,
    double width = 140,
    String hint = 'DD/MM/YYYY',
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: widget.readOnly
            ? null
            : () => _pickDateForController(
                  controller: controller,
                  dayCtrl: dayCtrl,
                  monthCtrl: monthCtrl,
                  yearCtrl: yearCtrl,
                ),
        style: FormTypography.serifStyle().copyWith(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          hintText: hint,
          hintStyle: FormTypography.serifStyle().copyWith(
            fontSize: 12,
            color: Colors.black38,
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black87, width: 1.0),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 1.5),
          ),
          suffixIcon: widget.readOnly
              ? null
              : InkWell(
                  onTap: () => _pickDateForController(
                    controller: controller,
                    dayCtrl: dayCtrl,
                    monthCtrl: monthCtrl,
                    yearCtrl: yearCtrl,
                  ),
                  child: const Icon(Icons.calendar_today, size: 16),
                ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 24,
            minHeight: 24,
          ),
        ),
      ),
    );
  }

  Widget _wrappingUnderlineInput({
    required TextEditingController controller,
    double minWidth = 100,
    double maxWidth = 350,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final text =
            controller.text.isEmpty ? (hintText ?? '') : controller.text;
        final style = FormTypography.serifStyle().copyWith(fontSize: 13);
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: style,
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();

        final measured = tp.width + 20.0;
        final calcWidth = measured < minWidth
            ? minWidth
            : (measured > 800.0 ? 800.0 : measured);

        return SizedBox(
          width: calcWidth,
          child: TextFormField(
            controller: controller,
            readOnly: widget.readOnly,
            maxLines: 1,
            keyboardType: keyboardType ?? TextInputType.text,
            style: style,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              hintText: hintText,
              hintStyle: style.copyWith(
                fontSize: 12,
                color: Colors.black38,
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black87, width: 1.0),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue, width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _policeStationField({
    required TextEditingController controller,
    double minWidth = 100,
    double? maxWidth,
    String? hintText,
  }) {
    final baseMin = minWidth;
    final baseMax = maxWidth ?? 600.0;
    const double baseFontSize = 13.0;
    final style = FormTypography.serifStyle().copyWith(fontSize: baseFontSize);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasFiniteWidth = constraints.maxWidth.isFinite;
        final availableWidth = hasFiniteWidth ? constraints.maxWidth : baseMax;

        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final text =
                controller.text.isEmpty ? (hintText ?? '') : controller.text;

            final tp = TextPainter(
              text: TextSpan(
                text: text,
                style: style.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: baseFontSize,
                ),
              ),
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout();

            double effectiveFontSize = baseFontSize;
            final double textW = tp.width + 12.0;

            if (hasFiniteWidth &&
                textW > availableWidth &&
                availableWidth > 30) {
              final scale =
                  ((availableWidth - 8.0) / tp.width).clamp(0.60, 1.0);
              effectiveFontSize =
                  (baseFontSize * scale).clamp(8.5, baseFontSize);
            }

            final double computedWidth = hasFiniteWidth
                ? availableWidth
                : (textW < baseMin
                    ? baseMin
                    : (textW > baseMax ? baseMax : textW));

            return SizedBox(
              width: computedWidth,
              child: TextFormField(
                controller: controller,
                readOnly: widget.readOnly,
                maxLines: 1,
                scrollPhysics: const ClampingScrollPhysics(),
                style: style.copyWith(
                  fontSize: effectiveFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  hintText: hintText,
                  hintStyle: style.copyWith(
                    color: Colors.grey.shade400,
                    fontSize: effectiveFontSize,
                  ),
                  border: const UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFF333333), width: 1.0),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFF555555), width: 1.0),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFF1976D2), width: 2.0),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  final _toOfficerCtrl = TextEditingController();
  final _toHospitalCtrl = TextEditingController();
  final _toTahDistCtrl = TextEditingController();

  final _fromLocationCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();

  final _victimNameCtrl = TextEditingController();
  final _victimAgeCtrl = TextEditingController();
  final _victimResidenceCtrl = TextEditingController();
  final _victimTahCtrl = TextEditingController();
  final _victimDistCtrl = TextEditingController();
  final _assaultDetailsCtrl = TextEditingController();
  final _officerSignatureCtrl = TextEditingController();

  @override
  void dispose() {
    _outpostCtrl.dispose();
    _psCtrl.dispose();
    _dateCtrl.dispose();
    _dateDayCtrl.dispose();
    _dateMonthCtrl.dispose();
    _dateYearCtrl.dispose();
    _toOfficerCtrl.dispose();
    _toHospitalCtrl.dispose();
    _toTahDistCtrl.dispose();
    _fromLocationCtrl.dispose();
    _subjectCtrl.dispose();
    _victimNameCtrl.dispose();
    _victimAgeCtrl.dispose();
    _victimResidenceCtrl.dispose();
    _victimTahCtrl.dispose();
    _victimDistCtrl.dispose();
    _assaultDetailsCtrl.dispose();
    _officerSignatureCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'outpost': _outpostCtrl.text.trim(),
      'policeStation': _psCtrl.text.trim(),
      'date': _dateCombined,
      'dateDay': _dateDayCtrl.text.trim(),
      'dateMonth': _dateMonthCtrl.text.trim(),
      'dateYear': _dateYearCtrl.text.trim(),
      'toOfficer': _toOfficerCtrl.text.trim(),
      'toHospital': _toHospitalCtrl.text.trim(),
      'toTahDist': _toTahDistCtrl.text.trim(),
      'fromLocation': _fromLocationCtrl.text.trim(),
      'subject': _subjectCtrl.text.trim(),
      'victimName': _victimNameCtrl.text.trim(),
      'victimAge': _victimAgeCtrl.text.trim(),
      'victimResidence': _victimResidenceCtrl.text.trim(),
      'victimTah': _victimTahCtrl.text.trim(),
      'victimDist': _victimDistCtrl.text.trim(),
      'assaultDetails': _assaultDetailsCtrl.text.trim(),
      'officerSignature': _officerSignatureCtrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    if (data.containsKey('outpost')) {
      _outpostCtrl.text = data['outpost']?.toString() ?? '';
    }
    if (data.containsKey('policeStation')) {
      _psCtrl.text = data['policeStation']?.toString() ?? '';
    }
    _dateCtrl.text = data['date']?.toString() ?? '';
    _dateDayCtrl.text = data['dateDay']?.toString() ?? '';
    _dateMonthCtrl.text = data['dateMonth']?.toString() ?? '';
    _dateYearCtrl.text = data['dateYear']?.toString() ?? '';
    if (_dateDayCtrl.text.isEmpty && _dateCtrl.text.isNotEmpty) {
      final parts = _dateCtrl.text.split(RegExp(r'[/.-]'));
      if (parts.length >= 3) {
        _dateDayCtrl.text = parts[0].trim();
        _dateMonthCtrl.text = parts[1].trim();
        var yr = parts[2].trim();
        if (yr.startsWith('20') && yr.length == 4) yr = yr.substring(2);
        _dateYearCtrl.text = yr;
      }
    } else if (_dateCtrl.text.isEmpty && _dateDayCtrl.text.isNotEmpty) {
      final d = _dateDayCtrl.text.trim();
      final m = _dateMonthCtrl.text.trim();
      final y = _dateYearCtrl.text.trim();
      final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
      _dateCtrl.text = '$d/$m/$yFull';
    }
    if (data.containsKey('toOfficer')) {
      _toOfficerCtrl.text = data['toOfficer']?.toString() ?? '';
    }
    if (data.containsKey('toHospital')) {
      _toHospitalCtrl.text = data['toHospital']?.toString() ?? '';
    }
    if (data.containsKey('toTahDist')) {
      _toTahDistCtrl.text = data['toTahDist']?.toString() ?? '';
    }
    if (data.containsKey('fromLocation')) {
      _fromLocationCtrl.text = data['fromLocation']?.toString() ?? '';
    }
    if (data.containsKey('subject')) {
      _subjectCtrl.text = data['subject']?.toString() ?? '';
    }
    if (data.containsKey('victimName')) {
      _victimNameCtrl.text = data['victimName']?.toString() ?? '';
    }
    if (data.containsKey('victimAge')) {
      _victimAgeCtrl.text = data['victimAge']?.toString() ?? '';
    }
    if (data.containsKey('victimResidence')) {
      _victimResidenceCtrl.text = data['victimResidence']?.toString() ?? '';
    }
    if (data.containsKey('victimTah')) {
      _victimTahCtrl.text = data['victimTah']?.toString() ?? '';
    }
    if (data.containsKey('victimDist')) {
      _victimDistCtrl.text = data['victimDist']?.toString() ?? '';
    }
    if (data.containsKey('assaultDetails')) {
      _assaultDetailsCtrl.text = data['assaultDetails']?.toString() ?? '';
    }
    if (data.containsKey('officerSignature')) {
      _officerSignatureCtrl.text = data['officerSignature']?.toString() ?? '';
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final marathi = FormTypography.marathiLabelStyle();

    final bodyTextStyle = marathi.copyWith(
      fontSize: 13,
      height: 2.0,
      color: Colors.black87,
    );
    final headerLabelStyle = marathi.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        FormPaperPage(
          formLabel: widget.pageRange,
          children: [
            const SizedBox(height: 8),

            // ── HEADER ──
            Center(
              child: Column(
                children: [
                  Text(
                    'वैद्यकीय तपासणी',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '(भारतीय नागरीक सुरक्षा संहिता २०२३ कलम ५१)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── TOP RIGHT POLICE STATION / OUTPOST / DATE ──
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 380,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('पोलीस दुरक्षेत्र ', style: headerLabelStyle),
                        Expanded(
                          child: _policeStationField(
                            controller: _outpostCtrl,
                            minWidth: 100,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('पोलीस स्टेशन ', style: headerLabelStyle),
                        Expanded(
                          child: _policeStationField(
                            controller: _psCtrl,
                            minWidth: 100,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('दिनांक : ', style: headerLabelStyle),
                        _datePickerField(
                          controller: _dateCtrl,
                          dayCtrl: _dateDayCtrl,
                          monthCtrl: _dateMonthCtrl,
                          yearCtrl: _dateYearCtrl,
                          width: 140,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── RECIPIENT (प्रति,) ──
            Text(
              'प्रति,',
              style: headerLabelStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _wrappingUnderlineInput(
                    controller: _toOfficerCtrl,
                    minWidth: 260,
                    maxWidth: 500,
                  ),
                  const SizedBox(height: 6),
                  _wrappingUnderlineInput(
                    controller: _toHospitalCtrl,
                    minWidth: 260,
                    maxWidth: 500,
                  ),
                  const SizedBox(height: 6),
                  _wrappingUnderlineInput(
                    controller: _toTahDistCtrl,
                    minWidth: 260,
                    maxWidth: 500,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── SENDER (पासुन :-) ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('पासुन  :-    ', style: headerLabelStyle),
                Expanded(
                  child: _policeStationField(
                    controller: _fromLocationCtrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── SUBJECT (विषय :-) ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('विषय   :-    ', style: headerLabelStyle),
                Expanded(
                  child: _wrappingUnderlineInput(
                    controller: _subjectCtrl,
                    minWidth: 280,
                    maxWidth: 600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── DECORATIVE OOOO ──
            Center(
              child: Text(
                '००००',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── MAIN BODY PARAGRAPH ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 10,
              children: [
                Text(
                  '        उपरोक्त विषयान्वये सादर आहे की, जखमी नामे ',
                  style: bodyTextStyle,
                ),
                _wrappingUnderlineInput(
                  controller: _victimNameCtrl,
                  minWidth: 200,
                  maxWidth: 400,
                ),
                Text(', वय ', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _victimAgeCtrl,
                  minWidth: 44,
                  maxWidth: 80,
                  keyboardType: TextInputType.number,
                ),
                Text(' वर्ष रा ', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _victimResidenceCtrl,
                  minWidth: 160,
                  maxWidth: 400,
                ),
                Text(' ता ', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _victimTahCtrl,
                  minWidth: 110,
                  maxWidth: 250,
                ),
                Text(' जिल्हा ', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _victimDistCtrl,
                  minWidth: 100,
                  maxWidth: 250,
                ),
                Text(
                  ' यांना गैरअर्जदार/ आरोपी यांनी भांडणात मारहाण केल्याचे ',
                  style: bodyTextStyle,
                ),
                _wrappingUnderlineInput(
                  controller: _assaultDetailsCtrl,
                  minWidth: 240,
                  maxWidth: 550,
                ),
                Text(
                  ' मारलागल्याचे सांगत आहे. तरी मार कशाचा व किती वेळ पुर्विचा आहे, सदर माराची तपासणी होउन आपला अभिप्राय मिळणेस विनंती आहे.',
                  style: bodyTextStyle,
                ),
              ],
            ),
            const SizedBox(height: 48),

            // ── BOTTOM RIGHT M.R.W ──
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'M.R.W',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
