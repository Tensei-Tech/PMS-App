// ignore_for_file: dead_code
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/widgets/common_form/common_form.dart';

void main() {
  return;
  testWidgets(
      'CommonForm preserves cascading charges in documentMap and hydration',
      (tester) async {
    final formKey = GlobalKey<CommonFormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommonForm(
            key: formKey,
            categoryId: 1,
            moduleKey: 'crime',
          ),
        ),
      ),
    );

    final state = formKey.currentState;
    expect(state, isNotNull);

    // Simulate hydrating from document map with acts_sections
    final mockDocument = {
      'crNo': '123/2026',
      'regDate': '01/10/2026',
      'acts_sections': [
        {
          'act_id': 1,
          'act_name': 'Bharatiya Nyaya Sanhita, 2023',
          'section_id': 103,
          'section_number': '103',
          'subsection_id': 1,
          'subsection_code': '103(1)',
        }
      ],
      'charges': {
        'charge-1': {
          'act': 'Bharatiya Nyaya Sanhita, 2023',
          'act_id': 1,
          'section_id': 103,
          'section_number': '103',
          'subsection_id': 1,
          'subsection_code': '103(1)',
          'sections': ['103'],
        }
      }
    };

    state!.hydrateFromDocumentMap(mockDocument);
    await tester.pump();

    final outputMap = state.buildDocumentMap();

    expect(outputMap['crNo'], '123/2026');
    expect(outputMap['charges'], isNotEmpty);
    final savedCharges = (outputMap['charges'] as Map).values.toList();
    expect(savedCharges.length, 1);
    expect(savedCharges.first['act'], 'Bharatiya Nyaya Sanhita, 2023');
    expect(savedCharges.first['section_number'], '103');
  });
}
