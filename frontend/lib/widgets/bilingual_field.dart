import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'responsive_field_row.dart';

/// Canonical bilingual form field styling (Crime Detail Form reference).
/// All forms must use these widgets — do not copy-paste field helpers locally.

class BilingualSimpleUnderlineInput extends StatefulWidget {
  final TextEditingController? controller;
  final TextStyle serifStyle;
  final String? hintText;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign? textAlign;
  final ValueChanged<String>? onChanged;
  final bool? isNumeric;

  const BilingualSimpleUnderlineInput({
    super.key,
    this.controller,
    required this.serifStyle,
    this.hintText,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.textAlign,
    this.onChanged,
    this.isNumeric,
  });

  @override
  State<BilingualSimpleUnderlineInput> createState() =>
      _BilingualSimpleUnderlineInputState();
}

class _BilingualSimpleUnderlineInputState
    extends State<BilingualSimpleUnderlineInput> {
  bool _isSanitizing = false;

  String get _normalizedHint => (widget.hintText ?? '').trim().toUpperCase();

  bool get _isTwoDigitHint {
    final h = _normalizedHint;
    return h == 'DD' ||
        h == 'MM' ||
        h == 'YY' ||
        h == 'HH' ||
        h == 'MIN' ||
        h == 'SS';
  }

  bool get _isFourDigitHint => _normalizedHint == 'YYYY';

  bool get _isYearHint => _normalizedHint == 'YY';

  int? get _effectiveMaxLength {
    if (widget.maxLength != null) return widget.maxLength;
    if (_isTwoDigitHint) return 2;
    if (_isFourDigitHint) return 4;
    return null;
  }

  bool get _effectiveDigitsOnly {
    if (widget.isNumeric == true) return true;
    if (_isTwoDigitHint || _isFourDigitHint) return true;
    return false;
  }

  TextAlign get _effectiveTextAlign {
    if (widget.textAlign != null) return widget.textAlign!;
    if (_isTwoDigitHint || _isFourDigitHint) return TextAlign.center;
    return TextAlign.start;
  }

  TextInputType? get _effectiveKeyboardType {
    if (widget.keyboardType != null) return widget.keyboardType;
    if (_effectiveDigitsOnly) return TextInputType.number;
    return null;
  }

  List<TextInputFormatter> get _effectiveInputFormatters {
    if (widget.inputFormatters != null) return widget.inputFormatters!;
    final formatters = <TextInputFormatter>[];
    if (_effectiveDigitsOnly) {
      // Allow ASCII digits (0-9) and Devanagari digits (०-९)
      formatters.add(
          FilteringTextInputFormatter.allow(RegExp(r'[0-9\u0966-\u096F]')));
    }
    final maxLen = _effectiveMaxLength;
    if (maxLen != null) {
      formatters.add(LengthLimitingTextInputFormatter(maxLen));
    }
    return formatters;
  }

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_handleTextChange);
    _sanitizeText();
  }

  @override
  void didUpdateWidget(BilingualSimpleUnderlineInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleTextChange);
      widget.controller?.addListener(_handleTextChange);
      _sanitizeText();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleTextChange() {
    _sanitizeText();
  }

  void _sanitizeText() {
    if (_isSanitizing) return;
    final ctrl = widget.controller;
    if (ctrl == null) return;

    final text = ctrl.text;
    if (text.isEmpty) return;

    final maxLen = _effectiveMaxLength;
    final digitsOnly = _effectiveDigitsOnly;
    final isYear = _isYearHint;

    var sanitized = text;
    if (digitsOnly) {
      // Keep only digits (ASCII and Devanagari)
      sanitized = sanitized.replaceAll(RegExp(r'[^\d\u0966-\u096F]'), '');
      if (isYear && sanitized.length == 4 && sanitized.startsWith('20')) {
        sanitized = sanitized.substring(2);
      }
    }
    if (maxLen != null && sanitized.length > maxLen) {
      sanitized = sanitized.substring(0, maxLen);
    }

    if (sanitized != text) {
      _isSanitizing = true;
      ctrl.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
      _isSanitizing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxLen = _effectiveMaxLength;

    return TextField(
      controller: widget.controller,
      textAlign: _effectiveTextAlign,
      scrollPhysics: const NeverScrollableScrollPhysics(),
      scrollPadding: EdgeInsets.zero,
      maxLines: 1,
      maxLength: maxLen,
      buildCounter: maxLen != null
          ? (context, {required currentLength, required isFocused, maxLength}) =>
              null
          : null,
      keyboardType: _effectiveKeyboardType,
      inputFormatters: _effectiveInputFormatters,
      onChanged: widget.onChanged,
      cursorColor: Colors.black87,
      style: widget.serifStyle.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: widget.serifStyle.color ?? Colors.black87,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.only(bottom: 4, top: 2),
        counterText: maxLen != null ? '' : null,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black54, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black87, width: 1.5),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black54, width: 0.8),
        ),
        hintText: widget.hintText,
        hintStyle: widget.serifStyle.copyWith(
          color: Colors.grey.shade400,
          fontSize: 11,
        ),
      ),
    );
  }
}

class BilingualField extends StatelessWidget {
  final String label;
  final String marathiLabel;
  final TextEditingController? controller;
  final TextStyle serifStyle;
  final TextStyle marathiLabelStyle;
  final bool showMarathiLabel;
  final String? hintText;
  final bool multiline;
  final int minLines;

  const BilingualField({
    super.key,
    required this.label,
    required this.marathiLabel,
    this.controller,
    required this.serifStyle,
    required this.marathiLabelStyle,
    this.showMarathiLabel = true,
    this.hintText,
    this.multiline = false,
    this.minLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty) Text(label, style: serifStyle),
        if (showMarathiLabel && marathiLabel.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(marathiLabel, style: marathiLabelStyle),
        ],
        const SizedBox(height: 4),
        if (multiline)
          BilingualDynamicLinedTextField(
            controller: controller,
            minLines: minLines,
            serifStyle: serifStyle,
            marathiLabelStyle: marathiLabelStyle,
          )
        else
          BilingualSimpleUnderlineInput(
            controller: controller,
            serifStyle: serifStyle,
            hintText: hintText,
          ),
      ],
    );
  }
}

class BilingualWideField extends StatelessWidget {
  final String label;
  final String marathiLabel;
  final TextEditingController? controller;
  final TextStyle serifStyle;
  final TextStyle marathiLabelStyle;
  final int minLines;

  const BilingualWideField({
    super.key,
    required this.label,
    required this.marathiLabel,
    this.controller,
    required this.serifStyle,
    required this.marathiLabelStyle,
    this.minLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty) Text('$label ', style: serifStyle),
        if (marathiLabel.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(marathiLabel, style: marathiLabelStyle),
        ],
        const SizedBox(height: 4),
        BilingualDynamicLinedTextField(
          controller: controller,
          minLines: minLines,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
      ],
    );
  }
}

class BilingualDynamicLinedTextField extends StatelessWidget {
  final TextEditingController? controller;
  final int minLines;
  final TextStyle serifStyle;
  final TextStyle? marathiLabelStyle;

  const BilingualDynamicLinedTextField({
    super.key,
    this.controller,
    required this.minLines,
    required this.serifStyle,
    this.marathiLabelStyle,
  });

  static const double _lineHeight = 24.0;

  @override
  Widget build(BuildContext context) {
    final effectiveController = controller ?? TextEditingController();
    final TextStyle textStyle = serifStyle.copyWith(
      fontSize: 13,
      height: _lineHeight / 13.0,
      color: serifStyle.color ?? Colors.black87,
      fontWeight: FontWeight.w600,
    );

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: effectiveController,
      builder: (context, value, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final textWidth = constraints.maxWidth - 8;

            int lines = minLines;
            if (value.text.isNotEmpty) {
              final textPainter = TextPainter(
                text: TextSpan(text: value.text, style: textStyle),
                textDirection: TextDirection.ltr,
                strutStyle: const StrutStyle(
                  fontSize: 13,
                  height: _lineHeight / 13.0,
                  forceStrutHeight: true,
                ),
              );
              textPainter.layout(maxWidth: textWidth > 0 ? textWidth : 100);
              final count = textPainter.computeLineMetrics().length;
              final newlineCount = '\n'.allMatches(value.text).length + 1;
              var detected = count > newlineCount ? count : newlineCount;

              // Fallback for long strings without spaces (e.g. repeated test characters)
              if (textWidth > 0) {
                final approxCharsPerLine = (textWidth / 8.0).floor().clamp(10, 150);
                int charWrapLines = 0;
                for (final line in value.text.split('\n')) {
                  final lineLines = (line.length / approxCharsPerLine).ceil();
                  charWrapLines += (lineLines < 1 ? 1 : lineLines);
                }
                if (charWrapLines > detected) {
                  detected = charWrapLines;
                }
              }

              if (detected > minLines) {
                lines = detected;
              }
            }

            final totalHeight = lines * _lineHeight;

            return SizedBox(
              height: totalHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    size: Size(constraints.maxWidth, totalHeight),
                    painter: _LinedBackgroundPainter(
                      lines: lines,
                      lineHeight: _lineHeight,
                    ),
                  ),
                  TextField(
                    controller: effectiveController,
                    textAlign: TextAlign.start,
                    textAlignVertical: TextAlignVertical.top,
                    minLines: lines,
                    maxLines: null,
                    scrollPhysics: const NeverScrollableScrollPhysics(),
                    keyboardType: TextInputType.multiline,
                    strutStyle: const StrutStyle(
                      fontSize: 13,
                      height: _lineHeight / 13.0,
                      forceStrutHeight: true,
                    ),
                    style: textStyle,
                    decoration: const InputDecoration(
                      isDense: true,
                      isCollapsed: true,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                      fillColor: Colors.transparent,
                      filled: true,
                      hoverColor: Colors.transparent,
                      focusColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _LinedBackgroundPainter extends CustomPainter {
  final int lines;
  final double lineHeight;

  const _LinedBackgroundPainter({
    required this.lines,
    required this.lineHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= lines; i++) {
      final y = (i * lineHeight) - 0.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinedBackgroundPainter oldDelegate) {
    return oldDelegate.lines != lines || oldDelegate.lineHeight != lineHeight;
  }
}

class BilingualMultilineField extends StatelessWidget {
  final String label;
  final String marathiLabel;
  final TextEditingController? controller;
  final int minLines;
  final TextStyle serifStyle;
  final TextStyle marathiLabelStyle;

  const BilingualMultilineField({
    super.key,
    required this.label,
    required this.marathiLabel,
    this.controller,
    required this.minLines,
    required this.serifStyle,
    required this.marathiLabelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style:
                serifStyle.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        if (marathiLabel.isNotEmpty)
          Text(
            marathiLabel,
            style: marathiLabelStyle.copyWith(
                fontSize: 12, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 8),
        BilingualDynamicLinedTextField(
          controller: controller,
          minLines: minLines,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
      ],
    );
  }
}

class BilingualSectionHeader extends StatelessWidget {
  final String label;
  final String marathiLabel;
  final TextStyle serifStyle;
  final TextStyle marathiLabelStyle;

  const BilingualSectionHeader({
    super.key,
    required this.label,
    required this.marathiLabel,
    required this.serifStyle,
    required this.marathiLabelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: serifStyle),
          Text(
            marathiLabel,
            style: marathiLabelStyle.copyWith(
                fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class BilingualFieldRow extends StatelessWidget {
  final List<Widget> fields;

  const BilingualFieldRow({
    super.key,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveFieldRow(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(width: 24),
          Expanded(child: fields[i]),
        ],
      ],
    );
  }
}

class BilingualNumberedMethodField extends StatelessWidget {
  final String number;
  final TextEditingController? controller;
  final TextStyle serifStyle;

  const BilingualNumberedMethodField({
    super.key,
    required this.number,
    this.controller,
    required this.serifStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$number : ',
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        BilingualDynamicLinedTextField(
          controller: controller,
          minLines: 1,
          serifStyle: serifStyle,
        ),
      ],
    );
  }
}
