import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/modules/muddemal/models/muddemal_models.dart';
import 'package:khakhi_diary/modules/muddemal/providers/muddemal_provider.dart';

void main() {
  group('Muddemal 100% Dynamic Backend-Driven Architecture Tests', () {
    test('MuddemalDashboardTab deserializes backend schema correctly', () {
      final json = {
        'key': 'Disposal',
        'label': 'Disposal Cases',
        'badge_color': '#059669',
        'display_order': 3,
        'applicable_statuses': [
          'Disposed',
          'Returned to Owner',
          'Released on Supurdnama'
        ],
      };

      final tab = MuddemalDashboardTab.fromJson(json);
      expect(tab.key, 'Disposal');
      expect(tab.label, 'Disposal Cases');
      expect(tab.badgeColor, '#059669');
      expect(tab.displayOrder, 3);
      expect(tab.applicableStatuses.length, 3);
      expect(tab.applicableStatuses, contains('Disposed'));
    });

    test('MuddemalDisposalAuthority deserializes backend authority catalog',
        () {
      final json = {
        'code': 'JMFC',
        'label': 'Judicial Magistrate First Class (JMFC)',
        'display_order': 1,
      };

      final auth = MuddemalDisposalAuthority.fromJson(json);
      expect(auth.code, 'JMFC');
      expect(auth.label, 'Judicial Magistrate First Class (JMFC)');
      expect(auth.displayOrder, 1);
    });

    test('MuddemalFslReportStatus deserializes backend statuses', () {
      final json = {
        'code': 'Inconclusive',
        'label': 'Report Inconclusive',
        'color': '#F59E0B',
      };

      final status = MuddemalFslReportStatus.fromJson(json);
      expect(status.code, 'Inconclusive');
      expect(status.label, 'Report Inconclusive');
      expect(status.color, '#F59E0B');
    });

    test('MuddemalProvider handles dynamic status categories and tab matching',
        () {
      final provider = MuddemalProvider();

      // Verify empty fallbacks
      expect(provider.measurementUnits, isEmpty);
      expect(provider.propertyStatuses, isEmpty);
      expect(provider.movementLocations, isEmpty);
      expect(provider.movementTypes, isEmpty);
      expect(provider.disposalTypes, isEmpty);
      expect(provider.disposalAuthorities, isEmpty);

      // Verify fallback helpers
      expect(provider.isDisposalStatus('Disposed'), isTrue);
      expect(provider.isDisposalStatus('Returned to Owner'), isTrue);
      expect(provider.isDisposalStatus('Released on Supurdnama'), isTrue);
      expect(provider.isDisposalStatus('Seized'), isFalse);
      expect(provider.isPendingStatus('Seized'), isTrue);
      expect(provider.isPendingStatus('Sent to FSL'), isTrue);
    });
  });
}
