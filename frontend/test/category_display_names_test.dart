import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/utils/translation_helper.dart';

void main() {
  testWidgets('Normal Accident is shown as Accident', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    }));
    final saved = TranslationHelper.activeLanguageCode;
    addTearDown(() => TranslationHelper.activeLanguageCode = saved);

    TranslationHelper.activeLanguageCode = 'en';
    expect(TranslationHelper.translate(ctx, 'Normal Accident'), 'Accident');
    expect(TranslationHelper.translate(ctx, 'Road Accident'), 'Road Accident');

    TranslationHelper.activeLanguageCode = 'mr';
    expect(TranslationHelper.translate(ctx, 'Normal Accident'),
        TranslationHelper.translate(ctx, 'Accident'));
  });

  testWidgets('Juvenile is shown as CiCL in English', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    }));
    final saved = TranslationHelper.activeLanguageCode;
    addTearDown(() => TranslationHelper.activeLanguageCode = saved);

    TranslationHelper.activeLanguageCode = 'en';
    expect(TranslationHelper.translate(ctx, 'Juvenile'), 'CiCL');
    expect(TranslationHelper.translate(ctx, 'Juvenile — Summary'),
        'Juvenile — Summary');
  });
}
