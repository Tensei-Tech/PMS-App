// Converts [ModuleRecord] from `arrested_cases` into table rows for
// [ArrestedCasesDemoDataTable] / Arrested Summary / Arrested demo table screens.

import '../modules/core/models/base_record.dart';
import 'common_form_module.dart';
import 'arrested_io_wise_logic.dart';
import 'excel_export_helper.dart';

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

bool _isActOrSection(String s) {
  final lower = s.toLowerCase().trim();
  if (lower.isEmpty) return false;
  return lower.contains('act') ||
      lower.contains('ipc') ||
      lower.contains('bns') ||
      lower.contains('bnss') ||
      lower.contains('bsa') ||
      lower.contains('pocso') ||
      lower.contains('ndps') ||
      lower.contains('uapa') ||
      lower.contains('mcr') ||
      lower.contains('section') ||
      lower.contains('sec.') ||
      lower.contains('sec ') ||
      RegExp(r'\d').hasMatch(s);
}

String _sectionsLine(ModuleRecord r) {
  // 1. Check charges under commonForm
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
            final secsStr = secs.join(', ').trim();
            parts.add(act != null && act.isNotEmpty ? '$act $secsStr' : secsStr);
          } else if (act != null && act.isNotEmpty) {
            parts.add(act);
          }
        }
      }
      if (parts.isNotEmpty) return parts.join('; ');
    } else if (ch is List && ch.isNotEmpty) {
      final f = ExcelExportHelper.formatSectionAct(ch);
      if (f.isNotEmpty) return f;
    }

    for (final key in [
      'acts_sections',
      'sections',
      'section_act',
      'act_section',
      'otherSections'
    ]) {
      final val = raw[key];
      if (val != null) {
        final formatted = ExcelExportHelper.formatSectionAct(val);
        if (formatted.isNotEmpty) return formatted;
      }
    }
  }

  // 2. Check top-level extraFields keys
  final topCharges = r.extraFields['charges'];
  if (topCharges is Map && topCharges.isNotEmpty) {
    final parts = <String>[];
    for (final entry in topCharges.entries) {
      final v = entry.value;
      if (v is Map) {
        final act = v['act']?.toString().trim();
        final secs = v['sections'];
        if (secs is List && secs.isNotEmpty) {
          final secsStr = secs.join(', ').trim();
          parts.add(act != null && act.isNotEmpty ? '$act $secsStr' : secsStr);
        } else if (act != null && act.isNotEmpty) {
          parts.add(act);
        }
      }
    }
    if (parts.isNotEmpty) return parts.join('; ');
  }

  for (final key in [
    'acts_sections',
    'sections',
    'section_act',
    'charges',
    'act_section',
    'preventiveSectionAct',
    'preventiveSecAct',
    'otherSections',
  ]) {
    final val = r.extraFields[key];
    if (val != null) {
      final formatted = ExcelExportHelper.formatSectionAct(val);
      if (formatted.isNotEmpty) return formatted;
    }
  }

  // 3. Fallback: only use firestoreCategoryDisplayName or subCategory if it is an actual Act or Section
  final cat = r.firestoreCategoryDisplayName.trim();
  if (cat.isNotEmpty && _isActOrSection(cat)) return cat;
  final sub = r.subCategory?.trim();
  if (sub != null && sub.isNotEmpty && _isActOrSection(sub)) return sub;

  return '—';
}

String _headLine(ModuleRecord r) {
  final sub = r.subCategory?.trim();
  if (sub != null && sub.isNotEmpty) return sub;
  final cat = r.firestoreCategoryDisplayName.trim();
  if (cat.isNotEmpty) return cat;
  return '—';
}

String _accusedNameLine(ModuleRecord r) {
  // 1. Direct accused field on ModuleRecord
  if (r.accused.trim().isNotEmpty &&
      r.accused.trim().toLowerCase() != 'default accused') {
    return r.accused.trim();
  }

  // 2. Check arrest_records / arrests array for arrested person name
  final arrList = r.extraFields['arrest_records'] ?? r.extraFields['arrests'];
  if (arrList is List && arrList.isNotEmpty) {
    for (final item in arrList) {
      if (item is Map) {
        final n = item['arrested_person_name'] ??
            item['person_name'] ??
            item['name'];
        if (n != null &&
            n.toString().trim().isNotEmpty &&
            n.toString().toLowerCase() != 'default accused') {
          return n.toString().trim();
        }
      }
    }
  }

  // 3. Check direct arrested_person_name
  final rawArrPerson = r.extraFields['arrested_person_name'];
  if (rawArrPerson != null &&
      rawArrPerson.toString().trim().isNotEmpty &&
      rawArrPerson.toString().toLowerCase() != 'default accused') {
    return rawArrPerson.toString().trim();
  }

  // 4. Check extraFields keys
  for (final key in ['accused_name', 'AccusedName', 'accusedName']) {
    final val = r.extraFields[key];
    if (val != null &&
        val.toString().trim().isNotEmpty &&
        val.toString().toLowerCase() != 'default accused') {
      return val.toString().trim();
    }
  }

  // 5. Check extraFields['accused']
  if (r.extraFields['accused'] != null) {
    final f = ExcelExportHelper.formatAccused(r.extraFields['accused']);
    if (f.isNotEmpty && f.toLowerCase() != 'default accused') return f;
  }

  // 6. Check commonForm map
  final cf = r.extraFields[kCommonFormExtraFieldsKey];
  if (cf is Map) {
    if (cf['accused'] != null) {
      final f = ExcelExportHelper.formatAccused(cf['accused']);
      if (f.isNotEmpty && f.toLowerCase() != 'default accused') return f;
    }
    if (cf['accused_list'] != null) {
      final f = ExcelExportHelper.formatAccused(cf['accused_list']);
      if (f.isNotEmpty && f.toLowerCase() != 'default accused') return f;
    }
    for (final key in ['accused_name', 'AccusedName', 'accusedName']) {
      final val = cf[key];
      if (val != null &&
          val.toString().trim().isNotEmpty &&
          val.toString().toLowerCase() != 'default accused') {
        return val.toString().trim();
      }
    }
  }

  // 7. Check accused_list / persons
  final list = r.extraFields['accused_list'] ?? r.extraFields['persons'];
  if (list is List && list.isNotEmpty) {
    final f = ExcelExportHelper.formatAccused(list);
    if (f.isNotEmpty && f.toLowerCase() != 'default accused') return f;
  }

  return '—';
}

String _accusedAgeLine(ModuleRecord r) {
  for (final key in [
    'accused_age',
    'accusedAge',
    'age',
    'juvenile_age',
    'juvenileAge',
    'suspected_accused_age',
  ]) {
    final val = r.extraFields[key];
    if (val != null && val.toString().trim().isNotEmpty) {
      return val.toString().trim();
    }
  }

  for (final listKey in [
    'accused_list',
    'accusedDetails',
    'suspected_accused_list',
    'persons',
    'unidentified_accused_list',
  ]) {
    final list = r.extraFields[listKey];
    if (list is List && list.isNotEmpty) {
      for (final item in list) {
        if (item is Map) {
          for (final key in ['age', 'accused_age', 'ua_age']) {
            final val = item[key];
            if (val != null && val.toString().trim().isNotEmpty) {
              return val.toString().trim();
            }
          }
        }
      }
    }
  }

  final cf = r.extraFields['commonForm'];
  if (cf is Map) {
    for (final key in ['accused_age', 'accusedAge', 'age', 'juvenileAge']) {
      final val = cf[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    final list = cf['accused_list'] ?? cf['accusedDetails'];
    if (list is List && list.isNotEmpty) {
      for (final item in list) {
        if (item is Map) {
          final val = item['age'];
          if (val != null && val.toString().trim().isNotEmpty) {
            return val.toString().trim();
          }
        }
      }
    }
  }

  return '—';
}

/// One row map: keys `sr`, `cr`, `sections`, `head`, `accused_name`, `age`, `arrest_date`, `io`
Map<String, String> arrestedModuleRecordToTableRow(
  ModuleRecord r,
  DateTime reference, {
  required int sr,
}) {
  final io = arrestedIoWiseIoDisplayName(r) ?? r.assignedOfficer.trim();
  const placeholder = '—';

  String arrDate = placeholder;
  dynamic rawArr =
      r.extraFields['arrest_date'] ?? r.extraFields['arrest_datetime'];

  if (rawArr == null || rawArr.toString().trim().isEmpty) {
    final list = r.extraFields['arrest_records'] ?? r.extraFields['arrests'];
    if (list is List && list.isNotEmpty) {
      for (final item in list) {
        if (item is Map) {
          final candidate = item['arrest_date'] ??
              item['arrest_datetime'] ??
              item['date'];
          if (candidate != null && candidate.toString().trim().isNotEmpty) {
            rawArr = candidate;
            break;
          }
        }
      }
    }
  }

  if (rawArr != null && rawArr.toString().trim().isNotEmpty) {
    final s = rawArr.toString().trim();
    final match = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})').firstMatch(s);
    if (match != null) {
      final d = match.group(1)!.padLeft(2, '0');
      final m = match.group(2)!.padLeft(2, '0');
      final y = match.group(3)!;
      arrDate = '$d/$m/$y';
    } else {
      try {
        final dt = DateTime.parse(s);
        arrDate =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        arrDate = s.split(' ').first;
      }
    }
  }

  return {
    'sr': '$sr',
    'cr': r.caseNumber.trim().isEmpty ? placeholder : r.caseNumber.trim(),
    'sections': _sectionsLine(r),
    'head': _headLine(r),
    'accused_name': _accusedNameLine(r),
    'age': _accusedAgeLine(r),
    'arrest_date': arrDate,
    'io': io.isEmpty ? placeholder : io,
    'station':
        r.stationName.trim().isEmpty ? placeholder : r.stationName.trim(),
    'period': arrestedTablePeriodLabel(r.incidentDate, reference),
    'multiple_cr': r.extraFields['multiple_cr']?.toString() ?? placeholder,
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
