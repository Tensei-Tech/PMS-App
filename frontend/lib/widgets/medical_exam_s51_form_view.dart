import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';
import 'form_date_pickers.dart';

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

  Widget _wrappingUnderlineInput({
    required TextEditingController controller,
    double minWidth = 100,
    double maxWidth = 350,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return _MedicalExamDynamicUnderlineField(
      controller: controller,
      style: FormTypography.serifStyle(),
      minWidth: minWidth,
      maxWidth: maxWidth,
      hintText: hintText,
      keyboardType: keyboardType,
      readOnly: widget.readOnly,
    );
  }

  Widget _policeStationField({
    required TextEditingController controller,
    double minWidth = 100,
    double? maxWidth,
    String? hintText,
  }) {
    return _MedicalExamDynamicUnderlineField(
      controller: controller,
      style: FormTypography.serifStyle(),
      minWidth: minWidth,
      maxWidth: maxWidth,
      hintText: hintText,
      readOnly: widget.readOnly,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text('पोलीस दुरक्षेत्र ',
                              style: headerLabelStyle),
                        ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text('पोलीस स्टेशन ', style: headerLabelStyle),
                        ),
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
                        formDatePickerField(
                          context,
                          controller: _dateCtrl,
                          dayCtrl: _dateDayCtrl,
                          monthCtrl: _dateMonthCtrl,
                          yearCtrl: _dateYearCtrl,
                          width: 140,
                          readOnly: widget.readOnly,
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
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text('पासुन  :-    ', style: headerLabelStyle),
                ),
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

class _MedicalExamDynamicUnderlinePainter extends CustomPainter {
  final int lines;
  final double lineHeight;
  final Color color;
  final double thickness;

  const _MedicalExamDynamicUnderlinePainter({
    required this.lines,
    required this.lineHeight,
    required this.color,
    this.thickness = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= lines; i++) {
      final y = ((i * lineHeight) - 1.0).clamp(1.0, size.height - 0.5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(
      covariant _MedicalExamDynamicUnderlinePainter oldDelegate) {
    return oldDelegate.lines != lines ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.color != color ||
        oldDelegate.thickness != thickness;
  }
}

class _MedicalExamDynamicUnderlineField extends StatefulWidget {
  final TextEditingController controller;
  final TextStyle style;
  final double minWidth;
  final double? maxWidth;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool readOnly;

  const _MedicalExamDynamicUnderlineField({
    required this.controller,
    required this.style,
    this.minWidth = 100,
    this.maxWidth,
    this.hintText,
    this.keyboardType,
    this.readOnly = false,
  });

  @override
  State<_MedicalExamDynamicUnderlineField> createState() =>
      _MedicalExamDynamicUnderlineFieldState();
}

class _MedicalExamDynamicUnderlineFieldState
    extends State<_MedicalExamDynamicUnderlineField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double lineHeight = 26.0;
    const double baseFontSize = 13.0;
    const double horizontalPadding = 3.0;

    final effectiveTextStyle = widget.style.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: baseFontSize,
      color: const Color(0xFF0D47A1),
      height: lineHeight / baseFontSize,
    );

    const effectiveStrutStyle = StrutStyle(
      fontSize: baseFontSize,
      height: lineHeight / baseFontSize,
      forceStrutHeight: true,
    );

    final bool isFocused = _focusNode.hasFocus;
    final Color lineColor =
        isFocused ? const Color(0xFF1976D2) : const Color(0xFF555555);
    final double lineThickness = isFocused ? 1.5 : 1.0;

    final effectiveMin = widget.minWidth;
    final effectiveMax = widget.maxWidth ?? 800.0;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final hasFiniteWidth =
                constraints.maxWidth.isFinite && constraints.maxWidth > 0;
            final double availableWidth =
                hasFiniteWidth ? constraints.maxWidth : effectiveMax;
            final text = widget.controller.text;

            final singleLinePainter = TextPainter(
              text: TextSpan(
                text: text.isEmpty ? (widget.hintText ?? '') : text,
                style: effectiveTextStyle,
              ),
              textDirection: TextDirection.ltr,
              strutStyle: effectiveStrutStyle,
              maxLines: 1,
            )..layout(maxWidth: double.infinity);

            final double measuredWidth = singleLinePainter.width + 16.0;

            double computedWidth;
            int lineCount = 1;

            if (measuredWidth <= availableWidth &&
                measuredWidth <= effectiveMax &&
                !text.contains('\n')) {
              computedWidth =
                  measuredWidth < effectiveMin ? effectiveMin : measuredWidth;
              lineCount = 1;
            } else {
              computedWidth =
                  availableWidth < effectiveMax ? availableWidth : effectiveMax;
              if (computedWidth < effectiveMin) computedWidth = effectiveMin;

              final double textMaxWidth =
                  (computedWidth - (horizontalPadding * 2) - 2.0)
                      .clamp(20.0, computedWidth);

              final multilinePainter = TextPainter(
                text: TextSpan(
                  text: text.isEmpty ? ' ' : text,
                  style: effectiveTextStyle,
                ),
                textDirection: TextDirection.ltr,
                strutStyle: effectiveStrutStyle,
              )..layout(maxWidth: textMaxWidth);

              final metrics = multilinePainter.computeLineMetrics();
              lineCount = metrics.length;
              if (lineCount < 1) lineCount = 1;

              final newlineCount = '\n'.allMatches(text).length + 1;
              if (newlineCount > lineCount) {
                lineCount = newlineCount;
              }
            }

            final double totalHeight = lineCount * lineHeight;

            return RepaintBoundary(
              child: SizedBox(
                width: computedWidth,
                height: totalHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: Size(computedWidth, totalHeight),
                          painter: _MedicalExamDynamicUnderlinePainter(
                            lines: lineCount,
                            lineHeight: lineHeight,
                            color: lineColor,
                            thickness: lineThickness,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: TextFormField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        readOnly: widget.readOnly,
                        minLines: lineCount,
                        maxLines: null,
                        keyboardType:
                            widget.keyboardType ?? TextInputType.multiline,
                        style: effectiveTextStyle,
                        strutStyle: effectiveStrutStyle,
                        decoration: InputDecoration(
                          isDense: true,
                          isCollapsed: true,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.only(
                            left: horizontalPadding,
                            right: horizontalPadding,
                            top: 0,
                            bottom: 2,
                          ),
                          fillColor: Colors.transparent,
                          filled: false,
                          hintText: widget.hintText,
                          hintStyle: widget.style.copyWith(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: lineHeight / 12.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
