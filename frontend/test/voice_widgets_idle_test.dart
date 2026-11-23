// The voice widgets must not animate while the mic is off. A pulse that runs
// all the time makes the web app redraw the whole page every frame, which
// can make Chrome drop the page's graphics (the screen blinks).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/widgets/common_form/pocso_voice_banner.dart';
import 'package:khakhi_diary/widgets/voice_dictation_button.dart';

Future<void> _expectIdle(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  // Times out if an animation keeps running
  await tester.pumpAndSettle(const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
  expect(tester.binding.hasScheduledFrame, isFalse,
      reason: 'nothing should redraw while the mic is off');
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('mic button does not animate while not listening',
      (tester) async {
    final ctrl = TextEditingController();
    addTearDown(ctrl.dispose);
    await _expectIdle(tester, VoiceDictationButton(controller: ctrl));
  });

  testWidgets('voice banner does not animate while not listening',
      (tester) async {
    final ctrl = TextEditingController();
    addTearDown(ctrl.dispose);
    await _expectIdle(
      tester,
      PocsoVoiceBanner(activeController: ctrl, activeFieldLabel: 'Name'),
    );
  });
}
