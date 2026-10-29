import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/services/api_config.dart';

void main() {
  test('uiConfig points at /master/ui-config/ without a double slash', () {
    expect(ApiConfig.uiConfig, endsWith('/master/ui-config/'));
    expect(ApiConfig.uiConfig, isNot(contains('//ui-config')));
  });

  test('endpoint URLs have no double slash after the scheme', () {
    final urls = <String>[
      ApiConfig.authLogin,
      ApiConfig.authCheckExists,
      ApiConfig.authPermissions,
      ApiConfig.appVersion,
      ApiConfig.users,
      ApiConfig.stations,
      ApiConfig.cases,
      ApiConfig.master,
      ApiConfig.uiConfig,
      ApiConfig.masterStates,
      ApiConfig.announcements,
      ApiConfig.rtiConfig,
      ApiConfig.rtiReminders,
      ApiConfig.mpdaConfig,
      ApiConfig.mpdaReminders,
      ApiConfig.historySheeterConfig,
    ];
    for (final url in urls) {
      final path = url.substring(url.indexOf('://') + 3);
      expect(path, isNot(contains('//')), reason: url);
    }
  });
}
