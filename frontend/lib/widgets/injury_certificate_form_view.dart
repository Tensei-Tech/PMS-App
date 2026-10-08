import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_date_pickers.dart';
import 'form_paper_page.dart';
import 'form_table_helpers.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// INJURY CERTIFICATE
class InjuryCertificateFormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const InjuryCertificateFormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<InjuryCertificateFormView> createState() =>
      InjuryCertificateFormViewState();
}

class InjuryRowControllers {
  final TextEditingController typeOfInjury;
  final TextEditingController siteOnBody;
  final TextEditingController ageOfInjury;
  final TextEditingController size;
  final TextEditingController color;
  final TextEditingController probableWeapon;
  final TextEditingController simpleGrievous;
  final TextEditingController remark;

  InjuryRowControllers({
    String typeOfInjury = '',
    String siteOnBody = '',
    String ageOfInjury = '',
    String size = '',
    String color = '',
    String probableWeapon = '',
    String simpleGrievous = '',
    String remark = '',
  })  : typeOfInjury = TextEditingController(text: typeOfInjury),
        siteOnBody = TextEditingController(text: siteOnBody),
        ageOfInjury = TextEditingController(text: ageOfInjury),
        size = TextEditingController(text: size),
        color = TextEditingController(text: color),
        probableWeapon = TextEditingController(text: probableWeapon),
        simpleGrievous = TextEditingController(text: simpleGrievous),
        remark = TextEditingController(text: remark);

  void dispose() {
    typeOfInjury.dispose();
    siteOnBody.dispose();
    ageOfInjury.dispose();
    size.dispose();
    color.dispose();
    probableWeapon.dispose();
    simpleGrievous.dispose();
    remark.dispose();
  }

  Map<String, String> toMap() {
    return {
      'typeOfInjury': typeOfInjury.text,
      'siteOnBody': siteOnBody.text,
      'ageOfInjury': ageOfInjury.text,
      'size': size.text,
      'color': color.text,
      'probableWeapon': probableWeapon.text,
      'simpleGrievous': simpleGrievous.text,
      'remark': remark.text,
    };
  }
}

class InjuryCertificateFormViewState extends State<InjuryCertificateFormView> {
  final _mlcNoCtrl = TextEditingController();
  final _mlcDateCtrl = TextEditingController();
  final _patientNameCtrl = TextEditingController();
  final _patientAgeCtrl = TextEditingController();
  final _idMarkAndAddressCtrl = TextEditingController();
  final _tahCtrl = TextEditingController();
  final _distCtrl = TextEditingController();
  final _broughtByCtrl = TextEditingController();
  final _buckleNoCtrl = TextEditingController();
  final _policeStationCtrl = TextEditingController();
  final _broughtTimeCtrl = TextEditingController();
  final _broughtDateCtrl = TextEditingController();
  final _examDateCtrl = TextEditingController();
  final _examTimeCtrl = TextEditingController();
  final _footerDateCtrl = TextEditingController();
  final _footerPlaceCtrl = TextEditingController();
  final _moNameCtrl = TextEditingController();

  final List<InjuryRowControllers> _injuryRows = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      _injuryRows.add(InjuryRowControllers());
    }
  }

  @override
  void dispose() {
    _mlcNoCtrl.dispose();
    _mlcDateCtrl.dispose();
    _patientNameCtrl.dispose();
    _patientAgeCtrl.dispose();
    _idMarkAndAddressCtrl.dispose();
    _tahCtrl.dispose();
    _distCtrl.dispose();
    _broughtByCtrl.dispose();
    _buckleNoCtrl.dispose();
    _policeStationCtrl.dispose();
    _broughtTimeCtrl.dispose();
    _broughtDateCtrl.dispose();
    _examDateCtrl.dispose();
    _examTimeCtrl.dispose();
    _footerDateCtrl.dispose();
    _footerPlaceCtrl.dispose();
    _moNameCtrl.dispose();
    for (final r in _injuryRows) {
      r.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'mlcNo': _mlcNoCtrl.text,
      'mlcDate': _mlcDateCtrl.text,
      'patientName': _patientNameCtrl.text,
      'patientAge': _patientAgeCtrl.text,
      'idMarkAndAddress': _idMarkAndAddressCtrl.text,
      'tah': _tahCtrl.text,
      'dist': _distCtrl.text,
      'broughtBy': _broughtByCtrl.text,
      'buckleNo': _buckleNoCtrl.text,
      'policeStation': _policeStationCtrl.text,
      'broughtTime': _broughtTimeCtrl.text,
      'broughtDate': _broughtDateCtrl.text,
      'examDate': _examDateCtrl.text,
      'examTime': _examTimeCtrl.text,
      'injuries': _injuryRows.map((r) => r.toMap()).toList(),
      'footerDate': _footerDateCtrl.text,
      'footerPlace': _footerPlaceCtrl.text,
      'moName': _moNameCtrl.text,
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    _mlcNoCtrl.text = data['mlcNo']?.toString() ?? '';
    _mlcDateCtrl.text = data['mlcDate']?.toString() ?? '';
    _patientNameCtrl.text = data['patientName']?.toString() ?? '';
    _patientAgeCtrl.text = data['patientAge']?.toString() ?? '';
    _idMarkAndAddressCtrl.text = data['idMarkAndAddress']?.toString() ?? '';
    _tahCtrl.text = data['tah']?.toString() ?? '';
    _distCtrl.text = data['dist']?.toString() ?? '';
    _broughtByCtrl.text = data['broughtBy']?.toString() ?? '';
    _buckleNoCtrl.text = data['buckleNo']?.toString() ?? '';
    _policeStationCtrl.text = data['policeStation']?.toString() ?? '';
    _broughtTimeCtrl.text = data['broughtTime']?.toString() ?? '';
    _broughtDateCtrl.text = data['broughtDate']?.toString() ?? '';
    _examDateCtrl.text = data['examDate']?.toString() ?? '';
    _examTimeCtrl.text = data['examTime']?.toString() ?? '';
    _footerDateCtrl.text = data['footerDate']?.toString() ?? '';
    _footerPlaceCtrl.text = data['footerPlace']?.toString() ?? '';
    _moNameCtrl.text = data['moName']?.toString() ?? '';

    final rawInjuries = data['injuries'];
    if (rawInjuries is List && rawInjuries.isNotEmpty) {
      for (final r in _injuryRows) {
        r.dispose();
      }
      _injuryRows.clear();
      for (final item in rawInjuries) {
        if (item is Map) {
          _injuryRows.add(
            InjuryRowControllers(
              typeOfInjury: item['typeOfInjury']?.toString() ?? '',
              siteOnBody: item['siteOnBody']?.toString() ?? '',
              ageOfInjury: item['ageOfInjury']?.toString() ?? '',
              size: item['size']?.toString() ?? '',
              color: item['color']?.toString() ?? '',
              probableWeapon: item['probableWeapon']?.toString() ?? '',
              simpleGrievous: item['simpleGrievous']?.toString() ?? '',
              remark: item['remark']?.toString() ?? '',
            ),
          );
        }
      }
    }
    if (mounted) setState(() {});
  }

  void _addRow() {
    setState(() {
      _injuryRows.add(InjuryRowControllers());
    });
  }

  void _removeRow() {
    if (_injuryRows.length > 1) {
      setState(() {
        final last = _injuryRows.removeLast();
        last.dispose();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final serif = FormTypography.serifStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        FormPaperPage(
          formLabel: widget.pageRange,
          children: [
            Center(
              child: Text(
                'INJURY CERTIFICATE',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDynamicField(
                      label: 'MLC No.:-',
                      hintText: '................................',
                      controller: _mlcNoCtrl,
                      serifStyle: serif,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Date.', style: serif),
                        const SizedBox(height: 4),
                        formDatePickerField(
                          context,
                          controller: _mlcDateCtrl,
                          width: double.infinity,
                          readOnly: widget.readOnly,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── PARAGRAPH SECTION ──
            BilingualFieldRow(
              fields: [
                _buildDynamicField(
                  label: 'Certified that shri/smt',
                  hintText:
                      '................................................................',
                  controller: _patientNameCtrl,
                  serifStyle: serif,
                ),
                _buildDynamicField(
                  label: 'age',
                  hintText: '..........',
                  controller: _patientAgeCtrl,
                  serifStyle: serif,
                ),
              ],
            ),
            const Text(
              'about years',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),

            _buildDynamicField(
              label: 'bearing following identification mark R/O.',
              hintText:
                  '................................................................................',
              controller: _idMarkAndAddressCtrl,
              serifStyle: serif,
            ),
            BilingualFieldRow(
              fields: [
                _buildDynamicField(
                  label: 'tah',
                  hintText: '...................',
                  controller: _tahCtrl,
                  serifStyle: serif,
                ),
                _buildDynamicField(
                  label: 'dist.',
                  hintText: '...........................',
                  controller: _distCtrl,
                  serifStyle: serif,
                ),
              ],
            ),
            const SizedBox(height: 8),

            BilingualFieldRow(
              fields: [
                _buildDynamicField(
                  label: 'brought to this hospital by PC/HC.',
                  hintText: '..........................',
                  controller: _broughtByCtrl,
                  serifStyle: serif,
                ),
                _buildDynamicField(
                  label: 'B.No.',
                  hintText: '.......',
                  controller: _buckleNoCtrl,
                  serifStyle: serif,
                ),
                _buildDynamicField(
                  label: 'Police station.',
                  hintText: '.......................',
                  controller: _policeStationCtrl,
                  serifStyle: serif,
                ),
              ],
            ),
            const SizedBox(height: 8),

            BilingualFieldRow(
              fields: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('at', style: serif),
                    const SizedBox(height: 4),
                    formTimePickerField(
                      context,
                      controller: _broughtTimeCtrl,
                      width: double.infinity,
                      readOnly: widget.readOnly,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('AM/PM on', style: serif),
                    const SizedBox(height: 4),
                    formDatePickerField(
                      context,
                      controller: _broughtDateCtrl,
                      width: double.infinity,
                      readOnly: widget.readOnly,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('& examination by me on', style: serif),
                    const SizedBox(height: 4),
                    formDatePickerField(
                      context,
                      controller: _examDateCtrl,
                      width: double.infinity,
                      readOnly: widget.readOnly,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('at', style: serif),
                    const SizedBox(height: 4),
                    formTimePickerField(
                      context,
                      controller: _examTimeCtrl,
                      width: double.infinity,
                      readOnly: widget.readOnly,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 9-COLUMN TABLE ──
            Table(
              border: TableBorder.all(color: Colors.black, width: 1.0),
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(1.2),
                5: FlexColumnWidth(1.2),
                6: FlexColumnWidth(2),
                7: FlexColumnWidth(1.5),
                8: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    _buildHeaderCell('Sr\nno'),
                    _buildHeaderCell('Type of\ninjury'),
                    _buildHeaderCell('Site on the part of\nbody'),
                    _buildHeaderCell('Age of\ninjury'),
                    _buildHeaderCell('Size'),
                    _buildHeaderCell('Color'),
                    _buildHeaderCell('Probable\nweapon used'),
                    _buildHeaderCell('Simpler\nGrievous'),
                    _buildHeaderCell('Remark'),
                  ],
                ),
                for (int i = 0; i < _injuryRows.length; i++)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      _buildTableCell(_injuryRows[i].typeOfInjury),
                      _buildTableCell(_injuryRows[i].siteOnBody),
                      _buildTableCell(_injuryRows[i].ageOfInjury),
                      _buildTableCell(_injuryRows[i].size),
                      _buildTableCell(_injuryRows[i].color),
                      _buildTableCell(_injuryRows[i].probableWeapon),
                      _buildTableCell(_injuryRows[i].simpleGrievous),
                      _buildTableCell(_injuryRows[i].remark),
                    ],
                  ),
              ],
            ),
            if (!widget.readOnly) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Row'),
                  ),
                  const SizedBox(width: 8),
                  if (_injuryRows.length > 1)
                    OutlinedButton.icon(
                      onPressed: _removeRow,
                      icon: const Icon(Icons.remove, size: 16),
                      label: const Text('Remove Row'),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 36),

            // ── FOOTER SECTION ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Date:-', style: serif),
                      const SizedBox(height: 4),
                      formDatePickerField(
                        context,
                        controller: _footerDateCtrl,
                        width: double.infinity,
                        readOnly: widget.readOnly,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildDynamicField(
                    label: 'Place:-',
                    hintText: '..........................',
                    controller: _footerPlaceCtrl,
                    serifStyle: serif,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medical officer',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Name and Sing',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildDynamicField(
                        label: '',
                        controller: _moNameCtrl,
                        serifStyle: serif,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FormMrwFooter(serifStyle: serif),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TextField(
        controller: ctrl,
        readOnly: widget.readOnly,
        maxLines: 2,
        minLines: 1,
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }

  Widget _buildDynamicField({
    required String label,
    required TextEditingController controller,
    required TextStyle serifStyle,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty) Text(label, style: serifStyle),
        const SizedBox(height: 4),
        _InjuryDynamicUnderlineField(
          controller: controller,
          style: serifStyle,
          hintText: hintText,
          readOnly: widget.readOnly,
        ),
      ],
    );
  }
}

class _InjuryDynamicUnderlinePainter extends CustomPainter {
  final int lines;
  final double lineHeight;
  final Color color;
  final double thickness;

  const _InjuryDynamicUnderlinePainter({
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
  bool shouldRepaint(covariant _InjuryDynamicUnderlinePainter oldDelegate) {
    return oldDelegate.lines != lines ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.color != color ||
        oldDelegate.thickness != thickness;
  }
}

class _InjuryDynamicUnderlineField extends StatefulWidget {
  final TextEditingController controller;
  final TextStyle style;
  final String? hintText;
  final bool readOnly;

  const _InjuryDynamicUnderlineField({
    required this.controller,
    required this.style,
    this.hintText,
    this.readOnly = false,
  });

  @override
  State<_InjuryDynamicUnderlineField> createState() =>
      _InjuryDynamicUnderlineFieldState();
}

class _InjuryDynamicUnderlineFieldState
    extends State<_InjuryDynamicUnderlineField> {
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
    const double horizontalPadding = 2.0;
    const double minWidth = 40.0;

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

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final hasFiniteWidth =
                constraints.maxWidth.isFinite && constraints.maxWidth > 0;
            final double availableWidth =
                hasFiniteWidth ? constraints.maxWidth : 500.0;
            final double computedWidth =
                availableWidth < minWidth ? minWidth : availableWidth;
            final text = widget.controller.text;

            int lineCount = 1;
            if (text.isNotEmpty) {
              final double textMaxWidth =
                  (computedWidth - (horizontalPadding * 2) - 2.0)
                      .clamp(20.0, computedWidth);

              final multilinePainter = TextPainter(
                text: TextSpan(
                  text: text,
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
                          painter: _InjuryDynamicUnderlinePainter(
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
                        keyboardType: TextInputType.multiline,
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
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            height: lineHeight / 11.0,
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
