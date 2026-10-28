import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/utils/common_form_module.dart';

void main() {
  group('Forms tab & dedicated forms baseline linking', () {
    test('dedicated forms resolve to CommonForm baseline and not dynamic form',
        () {
      expect(
        isTabLinkedToCommonFormBaseline(
          moduleKey: 'form_1_5',
          categoryName: 'Property & Seizure Form',
        ),
        isTrue,
      );
      expect(
        isTabLinkedToCommonFormBaseline(
          moduleKey: 'form_1_5',
          categoryName: 'Crime Detail Form',
        ),
        isTrue,
      );
      expect(
        isTabLinkedToCommonFormBaseline(
          moduleKey: 'form_1_5',
          categoryName: '376 Medical Form',
        ),
        isTrue,
      );
      expect(
        isTabLinkedToCommonFormBaseline(
          moduleKey: 'form_1_5',
          categoryName: 'Interrogation Form',
        ),
        isTrue,
      );
      expect(
        isTabLinkedToCommonFormBaseline(
          moduleKey: 'form_1_5',
          categoryName: 'Inquest Panchanama',
        ),
        isTrue,
      );
      expect(
        isTabLinkedToCommonFormBaseline(
          moduleKey: 'form_1_5',
          categoryName: 'Order Section 47 & 48',
        ),
        isTrue,
      );
      expect(
        isTabLinkedToCommonFormBaseline(
          moduleKey: 'form_1_5',
          categoryName: 'Nil House Search Panchanama',
        ),
        isTrue,
      );
    });

    test('unlinked categories remain unlinked', () {
      expect(
        isTabLinkedToCommonFormBaseline(
          moduleKey: 'form_1_5',
          categoryName: 'RTI',
        ),
        isFalse,
      );
      expect(
        isTabLinkedToCommonFormBaseline(
          moduleKey: 'application',
          categoryName: 'RTI',
        ),
        isFalse,
      );
    });
  });
}
