import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/modules/core/models/base_record.dart';
import 'package:khakhi_diary/modules/core/providers/base_module_provider.dart';
import 'package:khakhi_diary/utils/case_visibility.dart';

/// In-memory stand-in for the backend; set [online] to false to make every
/// save fail, like saving with no connection.
class _FakeBackend {
  final Map<String, ModuleRecord> stored = {};
  bool online = true;

  void attach(BaseModuleProvider p) {
    p.saveCaseForTest = (record, isCreate) async {
      if (!online) return false;
      stored[record.id] = record;
      return true;
    };
    p.fetchCasesForTest = () async => stored.values.toList();
    p.deleteCaseForTest = (id) async {
      if (!online) return false;
      stored.remove(id);
      return true;
    };
  }
}

void main() {
  late BaseModuleProvider p;
  late _FakeBackend backend;

  void enterStation(String station) => p.setStationContext(
        stationId: station,
        uid: 'officer-1',
        visibilityMode: CaseVisibilityMode.stationWide,
      );

  setUp(() {
    p = BaseModuleProvider('licence');
    backend = _FakeBackend()..attach(p);
    enterStation('Kotwali');
  });

  ModuleRecord newRecord(String title) => p.createRecord(
        title: title,
        caseNumber: '1/2026',
        description: '',
        complainant: '',
        accused: '',
        location: '',
        incidentDate: DateTime(2026, 11, 28),
        priority: 'Normal',
        assignedOfficer: 'Officer',
      );

  test('a record whose save fails stays in the list after refetching',
      () async {
    backend.online = false;
    final r = newRecord('Arms licence');

    await p.addRecord(r);
    expect(p.getById(r.id), isNotNull);
    expect(p.isUnsynced(r.id), isTrue);

    await p.refresh();
    expect(p.getById(r.id), isNotNull);
  });

  test('a successful save is no longer marked unsynced', () async {
    final r = newRecord('Arms licence');

    await p.addRecord(r);

    expect(p.getById(r.id), isNotNull);
    expect(p.isUnsynced(r.id), isFalse);
  });

  test('a failed update keeps the edited version over the server copy',
      () async {
    final r = newRecord('Arms licence');
    await p.addRecord(r);

    backend.online = false;
    await p.updateRecord(r.copyWith(title: 'Arms licence (renewal)'));
    await p.refresh();

    expect(p.getById(r.id)?.title, 'Arms licence (renewal)');
  });

  test('retrying after a failed save clears the unsynced mark', () async {
    backend.online = false;
    final r = newRecord('Arms licence');
    await p.addRecord(r);

    backend.online = true;
    await p.updateRecord(r);

    expect(p.isUnsynced(r.id), isFalse);
    expect(backend.stored.containsKey(r.id), isTrue);
  });

  test('deleting an unsynced record removes it for good', () async {
    backend.online = false;
    final r = newRecord('Arms licence');
    await p.addRecord(r);

    await p.deleteRecord(r.id);
    await p.refresh();

    expect(p.getById(r.id), isNull);
    expect(p.isUnsynced(r.id), isFalse);
  });

  test('changing station drops unsynced records of the old station', () async {
    backend.online = false;
    final r = newRecord('Arms licence');
    await p.addRecord(r);

    enterStation('Sitabuldi');
    await p.refresh();

    expect(p.getById(r.id), isNull);
    expect(p.isUnsynced(r.id), isFalse);
  });
}
