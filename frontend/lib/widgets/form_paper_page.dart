import 'package:flutter/material.dart';

import 'form_layout.dart';
import 'form_typography.dart';

/// A4 paper-styled page container shared across bilingual form views.
class FormPaperPage extends StatelessWidget {
  final List<Widget> children;
  final String? formLabel;
  final CrossAxisAlignment crossAxisAlignment;
  final double? minHeight;

  const FormPaperPage({
    super.key,
    required this.children,
    this.formLabel,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: FormLayout.maxPaperWidth,
        constraints: BoxConstraints(
          minHeight: minHeight ?? 1100,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFCFA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        padding: const EdgeInsets.all(FormLayout.paperPadding),
        child: Column(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            if (formLabel != null)
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  formLabel!,
                  style: FormTypography.serifStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ).copyWith(decoration: TextDecoration.underline),
                ),
              ),
            if (formLabel != null) const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
