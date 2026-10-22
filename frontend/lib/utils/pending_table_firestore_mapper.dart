// Converts [ModuleRecord] from `pending_cases` into table rows for
// [PendingCasesDemoDataTable] / Pending Summary / Pending demo table screens.

import '../modules/core/models/base_record.dart';
import 'common_form_module.dart';
import 'pending_io_wise_logic.dart';

/// UI time-period labels aligned with Pending Cases time-range filters.
/// Uses [anchor] vs [reference] (usually `DateTime.now()`).
String pendingTablePeriodLabel(DateTime anchor, DateTime reference) {
  if (anchor.isAfter(reference)) return 'Within 3 months';
  final days = reference.difference(anchor).inDays;
  if (days >= 366) return 'More than 1 year';
  if (days >= 184) return '6 to 12 months';
  if (days >= 92) return '3 to 6 months';
  if (days >= 32) return 'More than 3 months';
  if (days <= 30) return '1 month';
  return 'Within 3 months';
}

String _sectionsLine(ModuleRecord r) {
  final sectionsList = <String>[];

  void extractFromMap(Map chMap) {
    for (final entry in chMap.entries) {
      final v = entry.value;
      if (v is Map) {
        final secs = v['sections'];
        if (secs is List) {
          for (final s in secs) {
            final st = s?.toString().trim();
            if (st != null && st.isNotEmpty && st != 'null' && st != 'None' && st != '—' && st != '-') {
              sectionsList.add(st);
            }
          }
        }
        final secNum = (v['section_number'] ?? v['section'])?.toString().trim();
        final sub = (v['subsection_code'] ?? v['subsection'])?.toString().trim();
        if (secNum != null && secNum.isNotEmpty && secNum != 'null' && secNum != 'None' && secNum != '—' && secNum != '-') {
          if (sub != null && sub.isNotEmpty && sub != 'null' && sub != 'None' && sub != '—' && sub != '-') {
            sectionsList.add('$secNum($sub)');
          } else {
            sectionsList.add(secNum);
          }
        }
      }
    }
  }

  void extractFromList(List chList) {
    for (final item in chList) {
      if (item is Map) {
        final secs = item['sections'];
        if (secs is List) {
          for (final s in secs) {
            final st = s?.toString().trim();
            if (st != null && st.isNotEmpty && st != 'null' && st != 'None' && st != '—' && st != '-') {
              sectionsList.add(st);
            }
          }
        }
        final secNum = (item['section_number'] ?? item['section'])?.toString().trim();
        final sub = (item['subsection_code'] ?? item['subsection'])?.toString().trim();
        if (secNum != null && secNum.isNotEmpty && secNum != 'null' && secNum != 'None' && secNum != '—' && secNum != '-') {
          if (sub != null && sub.isNotEmpty && sub != 'null' && sub != 'None' && sub != '—' && sub != '-') {
            sectionsList.add('$secNum($sub)');
          } else {
            sectionsList.add(secNum);
          }
        }
      }
    }
  }

  final raw = r.extraFields[kCommonFormExtraFieldsKey] ?? r.extraFields['common_form'];
  if (raw is Map) {
    final ch = raw['charges'] ?? raw['acts_sections'];
    if (ch is Map) extractFromMap(ch);
    if (ch is List) extractFromList(ch);
  }

  final topCh = r.extraFields['charges'] ?? r.extraFields['acts_sections'];
  if (topCh is Map) extractFromMap(topCh);
  if (topCh is List) extractFromList(topCh);

  final direct = r.extraFields['sections'] ?? r.extraFields['section_number'] ?? r.extraFields['section_id'];
  if (direct is List) {
    for (final s in direct) {
      final st = s?.toString().trim();
      if (st != null && st.isNotEmpty && st != 'null' && st != 'None' && st != '—' && st != '-') {
        sectionsList.add(st);
      }
    }
  } else if (direct != null) {
    final st = direct.toString().trim();
    if (st.isNotEmpty && st != 'null' && st != 'None' && st != '—' && st != '-') {
      sectionsList.add(st);
    }
  }

  final seen = <String>{};
  final unique = sectionsList.where((x) => seen.add(x)).toList();
  if (unique.isNotEmpty) {
    return unique.join(', ');
  }

  return '—';
}

String _headLine(ModuleRecord r) {
  final sub = r.subCategory?.trim();
  if (sub != null && sub.isNotEmpty) return sub;
  return r.firestoreCategoryDisplayName.trim();
}

String _victimNamesLine(ModuleRecord r) {
  final raw = r.extraFields[kCommonFormExtraFieldsKey];
  if (raw is Map<String, dynamic>) {
    final v = raw['victims'];
    if (v is List) {
      final names = v
          .map((e) => e is Map
              ? (e['name']?.toString() ?? e['victim_name']?.toString() ?? '')
              : '')
          .where((s) => s.isNotEmpty)
          .toList();
      if (names.isNotEmpty) return names.join(', ');
    }
  }
  return '';
}

String _victimConditionLine(ModuleRecord r) {
  final raw = r.extraFields[kCommonFormExtraFieldsKey];
  if (raw is Map<String, dynamic>) {
    final v = raw['victims'];
    if (v is List) {
      final conditions = v
          .map((e) => e is Map
              ? (e['status']?.toString() ??
                  e['condition']?.toString() ??
                  e['injured_deceased']?.toString() ??
                  e['health_status']?.toString() ??
                  '')
              : '')
          .where((s) => s.isNotEmpty)
          .toList();
      if (conditions.isNotEmpty) return conditions.join(', ');
    }
  }
  return '';
}

final Map<String, ModuleRecord> _pendingRecordCache = {};

void cachePendingModuleRecord(ModuleRecord r) {
  if (r.id.isNotEmpty) _pendingRecordCache[r.id] = r;
  if (r.caseNumber.trim().isNotEmpty) {
    _pendingRecordCache[r.caseNumber.trim()] = r;
  }
}

ModuleRecord? getPendingModuleRecord(String key) {
  return _pendingRecordCache[key];
}

/// One row map: keys `sr`, `cr`, `sections`, `date`, `io`, `reason`, `period`, `head`
/// plus optional `spot` for AD column and victim fields.
Map<String, String> pendingModuleRecordToTableRow(
  ModuleRecord r,
  DateTime reference, {
  required int sr,
}) {
  final io = pendingIoWiseIoDisplayName(r) ?? r.assignedOfficer.trim();

  // Dynamically fetch the head directly from the database record instead of hardcoding
  final dynamicHead = _headLine(r);

  // Cache record in memory for instant retrieval
  cachePendingModuleRecord(r);

  return {
    'id': r.id,
    'module_key': r.moduleKey,
    'sub_category': r.subCategory ?? '',
    'title': r.title,
    'cr': r.caseNumber.trim(),
    'sections': _sectionsLine(r),
    'accused': r.accused.trim().isEmpty ? '—' : r.accused.trim(),
    'io': io.isEmpty ? '—' : io,
    'station': r.stationName.trim().isEmpty ? '—' : r.stationName.trim(),
    'head': dynamicHead,
    'victim_head': dynamicHead,
    'victim_name': _victimNamesLine(r),
    'injured_deceased': _victimConditionLine(r),
    'period': pendingTablePeriodLabel(r.incidentDate, reference),
    'incident_date': r.incidentDate.toIso8601String(),
    'complainant': r.complainant.trim().isEmpty ? '—' : r.complainant.trim(),
    'priority': r.priority,
    'status': r.status,
    'description': r.description,
  };
}

List<Map<String, String>> pendingModuleRecordsToTableRows(
  List<ModuleRecord> records,
  DateTime reference,
) {
  final sorted = List<ModuleRecord>.from(
    records,
  ).where((r) => r.moduleKey != 'nc').toList()
    ..sort((a, b) => b.incidentDate.compareTo(a.incidentDate));
  return List<Map<String, String>>.generate(
    sorted.length,
    (i) => pendingModuleRecordToTableRow(sorted[i], reference, sr: i + 1),
  );
}

/// Pending collection cases for station [stationId], limited to dashboard category chip.
List<Map<String, String>> pendingTableRowsForCategory(
  List<ModuleRecord> pendingRecords,
  String dashboardCategory,
  DateTime reference,
) {
  final filtered = pendingRecords.where(
    (r) => pendingRecordMatchesDashboardCategory(
      r: r,
      dashboardCategory: dashboardCategory,
    ),
  );
  return pendingModuleRecordsToTableRows(filtered.toList(), reference);
}

/// All pending rows mapped (no category filter — summary).
List<Map<String, String>> pendingTableRowsAll(
  List<ModuleRecord> pendingRecords,
  DateTime reference,
) {
  return pendingModuleRecordsToTableRows(pendingRecords, reference);
}
