import '../modules/core/models/base_record.dart';
import 'common_form_module.dart';

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
            parts.add(' '.trim());
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

String _accusedLine(ModuleRecord r) {
  // Check standard accused field (if mapped to extraFields['accused'])
  if (r.extraFields.containsKey('accused') && r.extraFields['accused'] != null) {
      var acc = r.extraFields['accused'];
      if (acc is List && acc.isNotEmpty && acc[0] is Map) {
          return acc[0]['name']?.toString() ?? acc[0]['accused_name']?.toString() ?? acc.toString();
      }
      return r.extraFields['accused'].toString();
  }
  
  // Check other extra fields
  for (final key in ['AccusedName', 'accused_name', 'accusedName']) {
    final val = r.extraFields[key];
    if (val != null && val.toString().trim().isNotEmpty) {
      return val.toString().trim();
    }
  }
  return 'Unknown';
}

String _headLine(ModuleRecord r) {
  final sub = r.subCategory?.trim();
  if (sub != null && sub.isNotEmpty) return sub;
  return r.firestoreCategoryDisplayName.trim();
}

Map<String, String> detectedModuleRecordToTableRow(
  ModuleRecord r,
  DateTime reference, {
  required int sr,
}) {
  return {
    'sr': '',
    'cr': r.caseNumber.trim(),
    'sections': _sectionsLine(r),
    'accused': _accusedLine(r),
    'head': _headLine(r),
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
