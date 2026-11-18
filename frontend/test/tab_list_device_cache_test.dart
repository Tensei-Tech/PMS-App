import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khakhi_diary/services/api_service.dart';
import 'package:khakhi_diary/services/case_service.dart';
import 'package:khakhi_diary/utils/translation_helper.dart';

/// Tab lists from the database are kept on the device and used when the
/// backend cannot be reached; rows can carry their own Marathi / Hindi labels.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tiles = [
    {'label': 'Monthly', 'module_key': 'monthly', 'display_order': 10},
    {'label': 'Pending', 'module_key': 'pending', 'display_order': 20},
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiService().setAuthToken('test-token');
    CaseService().clearCategoryCache();
  });
  tearDown(() {
    ApiService.clientForTesting = null;
    CaseService().clearCategoryCache();
    TranslationHelper.activeLanguageCode = 'en';
  });

  test('The last list the backend sent is used when it cannot be reached',
      () async {
    ApiService.clientForTesting =
        MockClient((_) async => http.Response(jsonEncode(tiles), 200));
    expect((await CaseService().fetchDashboardTiles()).length, 2);

    // Next session, no network
    CaseService().clearCategoryCache();
    ApiService.clientForTesting =
        MockClient((_) async => throw Exception('no network'));
    final offline = await CaseService().fetchDashboardTiles();
    expect(offline.map((t) => t['label']), ['Monthly', 'Pending']);
  });

  test('An empty answer (table not there yet) keeps the saved list', () async {
    SharedPreferences.setMockInitialValues({
      'tab_list_cache:categories/dashboard-tiles/': jsonEncode(tiles),
    });
    ApiService.clientForTesting =
        MockClient((_) async => http.Response('[]', 200));
    expect((await CaseService().fetchDashboardTiles()).length, 2);
  });

  test('Nothing saved and no network gives an empty list (built-in grid)',
      () async {
    ApiService.clientForTesting =
        MockClient((_) async => http.Response('error', 500));
    expect(await CaseService().fetchDashboardTiles(), isEmpty);
  });

  testWidgets('A row\'s label_mr / label_hi win over the dictionary',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    }));
    TranslationHelper.registerRowLabels([
      {'label': 'Killings', 'label_mr': 'खून', 'label_hi': ''},
    ], 'label');

    TranslationHelper.activeLanguageCode = 'mr';
    expect(TranslationHelper.translate(ctx, 'Killings'), 'खून');
    // No Hindi label: the text is left as the dictionary has it
    TranslationHelper.activeLanguageCode = 'hi';
    expect(TranslationHelper.translate(ctx, 'Killings'), 'Killings');
    TranslationHelper.activeLanguageCode = 'en';
    expect(TranslationHelper.translate(ctx, 'Killings'), 'Killings');
  });
}
