import '../modules/core/models/base_record.dart';
import 'common_form_module.dart';
import 'excel_export_helper.dart';

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
            parts
                .add(act != null && act.isNotEmpty ? '$act $secsStr' : secsStr);
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

  // If no section/act was recorded, return '-' instead of duplicating the crime head
  return '-';
}

String _accusedLine(ModuleRecord r) {
  // 1. Check the primary accused property on ModuleRecord
  if (r.accused.trim().isNotEmpty) {
    return r.accused.trim();
  }

  // 2. Check extraFields['accused']
  if (r.extraFields.containsKey('accused') &&
      r.extraFields['accused'] != null) {
    final formatted = ExcelExportHelper.formatAccused(r.extraFields['accused']);
    if (formatted.isNotEmpty) return formatted;
  }

  // 3. Check direct extra fields
  for (final key in ['AccusedName', 'accused_name', 'accusedName']) {
    final val = r.extraFields[key];
    if (val != null && val.toString().trim().isNotEmpty) {
      return val.toString().trim();
    }
  }

  // 4. Check commonForm map
  final common = r.extraFields[kCommonFormExtraFieldsKey];
  if (common is Map) {
    for (final key in ['accusedName', 'AccusedName', 'accused_name']) {
      final val = common[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    if (common['accused'] != null) {
      final formatted = ExcelExportHelper.formatAccused(common['accused']);
      if (formatted.isNotEmpty) return formatted;
    }
    if (common['accused_list'] is List) {
      final formatted = ExcelExportHelper.formatAccused(common['accused_list']);
      if (formatted.isNotEmpty) return formatted;
    }
  }

  return '-';
}

String _headLine(ModuleRecord r) {
  final sub = r.subCategory?.trim();
  if (sub != null && sub.isNotEmpty) return sub;
  final cat = r.firestoreCategoryDisplayName.trim();
  if (cat.isNotEmpty) return cat;
  return '-';
}

String _ioLine(ModuleRecord r) {
  if (r.assignedOfficer.trim().isNotEmpty) {
    return r.assignedOfficer.trim();
  }
  for (final key in [
    'assigned_officer',
    'assignedOfficer',
    'io_name',
    'ioName',
    'investigatingOfficer',
    '_ioName',
    'shoName',
  ]) {
    final val = r.extraFields[key];
    if (val != null && val.toString().trim().isNotEmpty) {
      return val.toString().trim();
    }
  }
  final common = r.extraFields[kCommonFormExtraFieldsKey];
  if (common is Map) {
    for (final key in [
      '_ioName',
      'ioName',
      'io_name',
      'investigatingOfficer',
      'assigned_officer',
      'assignedOfficer',
    ]) {
      final val = common[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
  }
  return '-';
}

Map<String, String> detectedModuleRecordToTableRow(
  ModuleRecord r,
  DateTime reference, {
  required int sr,
}) {
  return {
    'sr': '$sr',
    'cr': r.caseNumber.trim().isEmpty ? '-' : r.caseNumber.trim(),
    'sections': _sectionsLine(r),
    'head': _headLine(r),
    'accused': _accusedLine(r),
    'io': _ioLine(r),
  };
}

List<Map<String, String>> detectedModuleRecordsToTableRows(
  List<ModuleRecord> records,
  DateTime reference,
) {
  final sorted = List<ModuleRecord>.from(
    records,
  ).where((r) => r.moduleKey != 'nc').toList()
    ..sort((a, b) => b.incidentDate.compareTo(a.incidentDate));
  return List<Map<String, String>>.generate(
    sorted.length,
    (i) => detectedModuleRecordToTableRow(sorted[i], reference, sr: i + 1),
  );
}
