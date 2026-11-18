import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/screens/rti/rti_hub_screen.dart';

/// Each RTI outcome badge has its own colour; Rejected is no longer the same
/// red as Pending.
void main() {
  test('Rejected has its own colour, not Pending red', () {
    final rejected = rtiOutcomeColors('Rejected');
    final pending = rtiOutcomeColors('Pending');
    expect(rejected.$1, isNot(pending.$1));
    expect(rtiOutcomeColors('Replied').$1, const Color(0xFF2E7D32));
    expect(rtiOutcomeColors('Transferred').$1, const Color(0xFF0284C7));
  });
}
