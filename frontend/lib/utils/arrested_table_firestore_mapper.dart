// Converts [ModuleRecord] from `arrested_cases` into table rows for
// [ArrestedCasesDemoDataTable] / Arrested Summary / Arrested demo table screens.

import '../modules/core/models/base_record.dart';
import 'common_form_module.dart';
import 'arrested_io_wise_logic.dart';

/// UI time-period labels aligned with Arrested Cases time-range filters.
/// Uses [anchor] vs [reference] (usually `DateTime.now()`).
String arrestedTablePeriodLabel(DateTime anchor, DateTime reference) {
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
  final raw = r.extraFields[kCommonFormExtraFieldsKey];
  if (raw is Map<String, dynamic>) {
    final ch = raw['charges'];
    if (ch is Map) {
      final parts = <String>[];
      for (final entry in ch.entries) {
        final v = entry.value;
        if (v is Map) {
          final act = v['act']?.toString().trim();
          final secs = v['sections'];
          if (secs is List && secs.isNotEmpty) {
            parts.add('$act ${secs.join(', ')}'.trim());
          } else if (act != null && act.isNotEmpty) {
            parts.add(act);
          }
        }
      }
      if (parts.isNotEmpty) return parts.join('; ');
    }
  }
  return r.firestoreCategoryDisplayName.trim();
}

String _headLine(ModuleRecord r) {
  final sub = r.subCategory?.trim();
  if (sub != null && sub.isNotEmpty) return sub;
  return r.firestoreCategoryDisplayName.trim();
}

/// One row map: keys `sr`, `cr`, `sections`, `date`, `io`, `reason`, `period`, `head`
/// plus optional `spot` for AD column.
Map<String, String> arrestedModuleRecordToTableRow(
  ModuleRecord r,
  DateTime reference, {
  required int sr,
}) {
  final io = arrestedIoWiseIoDisplayName(r) ?? r.assignedOfficer.trim();
  
  String arrDate = '—';
  dynamic rawArr = r.extraFields['arrest_date'] ?? r.extraFields['arrest_datetime'];
  
  if (rawArr == null) {
    // Try to find it inside arrest_records or arrests array
    final list = r.extraFields['arrest_records'] ?? r.extraFields['arrests'];
    if (list is List && list.isNotEmpty) {
      final first = list.first;
      if (first is Map) {
        rawArr = first['arrest_date'] ?? first['arrest_datetime'] ?? first['date'];
      }
    }
  }

  if (rawArr != null) {
    try {
      final dt = DateTime.parse(rawArr.toString());
      arrDate = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {}
  }

  return {
    'sr': '$sr',
    'cr': r.caseNumber.trim(),
    'sections': _sectionsLine(r),
    'arrest_date': arrDate,
    'io': io.isEmpty ? '—' : io,
    'station': r.stationName.trim().isEmpty ? '—' : r.stationName.trim(),
    'head': _headLine(r),
    'period': arrestedTablePeriodLabel(r.incidentDate, reference),
  };
}

List<Map<String, String>> arrestedModuleRecordsToTableRows(
  List<ModuleRecord> records,
  DateTime reference,
) {
  final sorted = List<ModuleRecord>.from(
    records,
  ).where((r) => r.moduleKey != 'nc').toList()
    ..sort((a, b) => b.incidentDate.compareTo(a.incidentDate));
  return List<Map<String, String>>.generate(
    sorted.length,
    (i) => arrestedModuleRecordToTableRow(sorted[i], reference, sr: i + 1),
  );
}

/// Arrested collection cases for station [stationId], limited to dashboard category chip.
List<Map<String, String>> arrestedTableRowsForCategory(
  List<ModuleRecord> arrestedRecords,
  String dashboardCategory,
  DateTime reference,
) {
  final filtered = arrestedRecords.where(
    (r) => arrestedRecordMatchesDashboardCategory(
      r: r,
      dashboardCategory: dashboardCategory,
    ),
  );
  return arrestedModuleRecordsToTableRows(filtered.toList(), reference);
}

/// All arrested rows mapped (no category filter — summary).
List<Map<String, String>> arrestedTableRowsAll(
  List<ModuleRecord> arrestedRecords,
  DateTime reference,
) {
  return arrestedModuleRecordsToTableRows(arrestedRecords, reference);
}
