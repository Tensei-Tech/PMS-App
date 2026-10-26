import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/utils/category_icon_helper.dart';

void main() {
  group('CategoryIconHelper crime icon mappings', () {
    test('murder category variants resolve to assets/icons/murder.svg', () {
      const variants = [
        'murder',
        'attempt to murder',
        'att to murder',
        'murder/attempt to murder',
        'Murder',
        'Attempt to Murder',
      ];
      for (final v in variants) {
        expect(CategoryIconHelper.getSvgPath(v), 'assets/icons/murder.svg',
            reason: 'Failed for variant: $v');
      }
    });

    test('dacoity category variants resolve to assets/icons/dacoity.svg', () {
      const variants = [
        'dacoity',
        'decoity',
        'pro of dacoity',
        'pro of decoity',
        'dacoity/robbery',
        'Dacoity',
      ];
      for (final v in variants) {
        expect(CategoryIconHelper.getSvgPath(v), 'assets/icons/dacoity.svg',
            reason: 'Failed for variant: $v');
      }
    });

    test(
        'chain snatching and chain robbery variants resolve to assets/icons/chain_snatching.svg',
        () {
      const variants = [
        'chain snatching',
        'chainsnatching',
        'chain snatch',
        'chain robbery',
        'chain robery',
        'Chain Snatching',
        'Chain Robbery',
      ];
      for (final v in variants) {
        expect(CategoryIconHelper.getSvgPath(v),
            'assets/icons/chain_snatching.svg',
            reason: 'Failed for variant: $v');
      }
    });

    test('all resolved SVG asset files physically exist on disk', () {
      const categories = [
        'murder',
        'dacoity',
        'chain snatching',
        'theft',
        'hurt',
        'missing',
      ];
      for (final cat in categories) {
        final path = CategoryIconHelper.getSvgPath(cat);
        expect(path, isNotNull);
        final file = File(path!);
        expect(file.existsSync(), isTrue,
            reason: 'Expected $path to exist on disk');
      }
    });
  });
}
