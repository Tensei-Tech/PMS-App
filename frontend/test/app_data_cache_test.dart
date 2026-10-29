import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/services/case_service.dart';
import 'package:khakhi_diary/utils/app_data_cache.dart';

void main() {
  late int clears;
  late DateTime clock;

  setUp(() {
    AppDataCache.resetForTest();
    clears = 0;
    clock = DateTime(2026, 10, 25, 10);
    AppDataCache.now = () => clock;
    AppDataCache.clearCaches = () => clears++;
  });

  tearDown(AppDataCache.resetForTest);

  final scopeA = AppDataCache.scopeFor(
      uid: 'u1', stateCode: 'MH', station: 'Shivajinagar');

  test('first dashboard open clears once', () {
    expect(AppDataCache.ensureFresh(scopeA), isTrue);
    expect(clears, 1);
  });

  test('reopening the dashboard soon keeps the caches', () {
    AppDataCache.ensureFresh(scopeA);
    clock = clock.add(const Duration(minutes: 5));
    expect(AppDataCache.ensureFresh(scopeA), isFalse);
    expect(AppDataCache.ensureFresh(scopeA), isFalse);
    expect(clears, 1);
  });

  test('caches older than maxAge are cleared', () {
    AppDataCache.ensureFresh(scopeA);
    clock = clock.add(AppDataCache.maxAge + const Duration(seconds: 1));
    expect(AppDataCache.ensureFresh(scopeA), isTrue);
    expect(clears, 2);
  });

  test('another user, state or station clears the caches', () {
    AppDataCache.ensureFresh(scopeA);
    final others = [
      AppDataCache.scopeFor(
          uid: 'u2', stateCode: 'MH', station: 'Shivajinagar'),
      AppDataCache.scopeFor(
          uid: 'u2', stateCode: 'GJ', station: 'Shivajinagar'),
      AppDataCache.scopeFor(uid: 'u2', stateCode: 'GJ', station: 'Navrangpura'),
    ];
    for (final scope in others) {
      expect(AppDataCache.ensureFresh(scope), isTrue, reason: scope);
    }
    expect(clears, 4);
  });

  test('clearAll (login/logout) forces the next open to clear', () {
    AppDataCache.ensureFresh(scopeA);
    AppDataCache.clearAll();
    expect(clears, 2);
    expect(AppDataCache.ensureFresh(scopeA), isTrue);
    expect(clears, 3);
  });

  test('clearCategoryCache also drops cached category children', () {
    final service = CaseService();
    service.primeChildrenCacheForTest('1:', [
      {'id': 2, 'name': 'child'},
    ]);
    expect(service.hasChildrenCacheForTest('1:'), isTrue);
    service.clearCategoryCache();
    expect(service.hasChildrenCacheForTest('1:'), isFalse);
  });
}
