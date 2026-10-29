// lib/widgets/common_form_document_view.dart
// Read-only UI: mirrors [CommonFormState.buildDocumentMap] §1–§17 + dynamic [extraMap]
// (same contract as common_form_pdf). Category-specific keys in [extraMap] render automatically.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../modules/core/models/base_record.dart';
import '../modules/form_iv/providers/form_iv_provider.dart';
import '../theme/app_theme.dart';
import '../utils/common_form_module.dart';
import '../utils/translation_helper.dart';

/// Matches PDF / form: plain string with fallback.
String _v(dynamic v, {String or = ''}) {
  if (v == null) return or;
  final s = v.toString().trim();
  return s.isEmpty ? or : s;
}

String _labelifyExtraKey(String key) {
  var result = key.replaceAll('_', ' ');
  result = result.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m.group(1)} ${m.group(2)}',
  );
  if (result.isEmpty) return key;
  return result[0].toUpperCase() + result.substring(1);
}

String _disp(dynamic v) {
  if (v == null) return '—';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is Timestamp) {
    final d = v.toDate().toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
  if (v is DateTime) {
    return DateFormat('dd MMMM yyyy, hh:mm a').format(v.toLocal());
  }
  if (v is String) {
    final t = v.trim();
    if (t.isEmpty) return '—';
    try {
      if (t.length >= 10 &&
          (t.contains('T') || RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(t))) {
        final d = DateTime.parse(t).toLocal();
        final datePart = DateFormat('dd MMMM yyyy').format(d);
        final hasTime =
            t.contains('T') && (d.hour != 0 || d.minute != 0 || d.second != 0);
        if (hasTime) {
          return '$datePart, ${DateFormat('hh:mm a').format(d)}';
        }
        return datePart;
      }
    } catch (_) {}
    return t;
  }
  if (v is List) {
    if (v.isEmpty) return '—';
    return v.map(_disp).join(', ');
  }
  if (v is Map) {
    if (v.isEmpty) return '—';
    return v.entries
        .map((e) => '${_labelifyExtraKey(e.key.toString())}: ${_disp(e.value)}')
        .join(' · ');
  }
  final s = v.toString().trim();
  return s.isEmpty ? '—' : s;
}

/// Matches [module_record_dynamic_document_view.dart] case-detail breakpoint.
const double _kCaseDetailDesktopBreakpoint = 800;

class _CaseDetailLayoutScope extends InheritedWidget {
  const _CaseDetailLayoutScope({required this.desktop, required super.child});

  final bool desktop;

  static bool isDesktop(BuildContext context) {
    final w =
        context.dependOnInheritedWidgetOfExactType<_CaseDetailLayoutScope>();
    return w?.desktop ?? false;
  }

  @override
  bool updateShouldNotify(_CaseDetailLayoutScope oldWidget) =>
      oldWidget.desktop != desktop;
}

const Map<String, String> _kProcLabels = {
  'chkMemo': 'Memorandum Panchanama',
  'chkPanchSpot': 'Panchanama Spot',
  'chkInquest': 'Inquest',
  'chkIdent': 'Identification',
  'chkSearch': 'Search',
  'chkPersSearch': 'Personal Search',
  'chkIdParade': 'Identification Parade',
  'chkExhumation': 'Exhumation',
};

class CommonFormDocumentView extends StatelessWidget {
  const CommonFormDocumentView({
    super.key,
    required this.commonMap,
    this.extraMap = const {},
    this.record,
    this.readOnly = false,
    this.onChargeSheetSubmitted,
    this.onEditChargeSheet,
  });

  final Map<String, dynamic> commonMap;
  final Map<String, dynamic> extraMap;
  final ModuleRecord? record;
  final bool readOnly;
  final VoidCallback? onChargeSheetSubmitted;
  final VoidCallback? onEditChargeSheet;

  Widget _sectionTitle(String title, IconData icon, Color accent) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _numSectionHeader(int num, String title, Color accent) {
    return Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: accent,
          child: Text(
            '$num',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() =>
      const Divider(height: 1, thickness: 0.5, color: AppColors.lightBorder);

  Widget _row(String label, String value, {bool fullWidth = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.lightSubText,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: value.isNotEmpty && value != '—'
                    ? AppColors.lightText
                    : AppColors.lightSubText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactLabelValue(String label, String value) {
    if (label.isEmpty) return const SizedBox();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.lightSubText,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: value.isNotEmpty && value != '—'
                  ? AppColors.lightText
                  : AppColors.lightSubText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _desktopTwoSimpleFieldsRow(
    String l1,
    String v1,
    String l2,
    String v2,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _compactLabelValue(l1, v1)),
          const SizedBox(width: 24),
          Expanded(
            child:
                l2.isNotEmpty ? _compactLabelValue(l2, v2) : const SizedBox(),
          ),
        ],
      ),
    );
  }

  /// Desktop: pairs consecutive non-[fullWidth] fields into two columns.
  List<Widget> _pairedSimpleFields(
    BuildContext context,
    List<({String label, String value, bool fullWidth})> fields,
  ) {
    final desktop = _CaseDetailLayoutScope.isDesktop(context);
    final out = <Widget>[];

    // Filter out empty, null, placeholder, and unselected values
    final validFields = fields.where((f) {
      final v = f.value.trim();
      if (v.isEmpty || v == '—' || v == '-' || v == 'null' || v == 'None') {
        return false;
      }
      final lower = v.toLowerCase();
      if (lower == 'not uploaded' ||
          lower == 'not set' ||
          lower == 'no charges added.' ||
          lower == 'none') {
        return false;
      }
      return true;
    }).toList();

    if (validFields.isEmpty) return const [];

    if (!desktop) {
      for (var i = 0; i < validFields.length; i++) {
        if (i > 0) out.add(_divider());
        final f = validFields[i];
        out.add(_row(f.label, f.value, fullWidth: f.fullWidth));
      }
      return out;
    }
    for (var i = 0; i < validFields.length; i++) {
      final f = validFields[i];
      if (f.fullWidth) {
        if (out.isNotEmpty) out.add(_divider());
        out.add(_row(f.label, f.value, fullWidth: true));
        continue;
      }
      if (i + 1 < validFields.length && !validFields[i + 1].fullWidth) {
        final g = validFields[i + 1];
        if (out.isNotEmpty) out.add(_divider());
        out.add(_desktopTwoSimpleFieldsRow(f.label, f.value, g.label, g.value));
        i++;
      } else {
        if (out.isNotEmpty) out.add(_divider());
        out.add(_desktopTwoSimpleFieldsRow(f.label, f.value, '', ''));
      }
    }
    return out;
  }

  Widget _surfaceCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _sectionShell(
    int idx,
    String title,
    Color accent,
    List<Widget> body, {
    IconData icon = Icons.article_outlined,
    Widget? headerAction,
  }) {
    final visibleBody = body.where((w) {
      if (w is SizedBox && (w.height == 0 || w.height == null || w.width == 0)) {
        return false;
      }
      return true;
    }).toList();
    if (visibleBody.isEmpty) {
      return const SizedBox.shrink();
    }

    return _surfaceCard([
      Row(
        children: [
          Expanded(
            child: idx > 0
                ? _numSectionHeader(idx, title, accent)
                : _sectionTitle(title, icon, accent),
          ),
          if (headerAction != null) headerAction,
        ],
      ),
      const SizedBox(height: 10),
      _divider(),
      const SizedBox(height: 10),
      ...visibleBody,
    ]);
  }

  Widget _personCard(
    BuildContext context,
    String heading,
    Map<String, dynamic> p,
  ) {
    final fields = _pairedSimpleFields(context, [
      (label: 'Name', value: _v(p['name'] ?? p['person_name'] ?? p['accused_name']), fullWidth: false),
      (label: 'Age', value: _v(p['age']), fullWidth: false),
      (label: 'Gender', value: _v(p['gender']), fullWidth: false),
      (label: 'Occupation', value: _v(p['occ']), fullWidth: false),
      (label: 'Mobile', value: _v(p['mobile']), fullWidth: false),
      (label: 'Aadhaar', value: _v(p['aadhaar']), fullWidth: false),
      (label: 'PAN Number', value: _v(p['pan']), fullWidth: false),
      (label: 'Religion', value: _v(p['religion']), fullWidth: false),
      (label: 'Caste', value: _v(p['caste']), fullWidth: false),
      (label: 'Address', value: _v(p['address']), fullWidth: true),
    ]);
    if (fields.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.lightBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: const Border(
          left: BorderSide(color: AppColors.infoBlue, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 8),
          _divider(),
          const SizedBox(height: 8),
          ...fields,
        ],
      ),
    );
  }

  List<Widget> _buildProceduralSection(
    BuildContext context,
    Map procChecks,
    Map procDates,
    Map m,
  ) {
    final desktop = _CaseDetailLayoutScope.isDesktop(context);
    final activeEntries = _kProcLabels.entries.where((e) {
      final on = procChecks[e.key] == true || m[e.key] == true;
      final d = (procDates[e.key] ?? m['${e.key}_date'])?.toString().trim() ?? '';
      return on || d.isNotEmpty;
    }).toList();

    final items = <Widget>[];

    for (var i = 0; i < activeEntries.length; i += 2) {
      final e1 = activeEntries[i];
      final on1 = procChecks[e1.key] == true || m[e1.key] == true;
      final d1 = (procDates[e1.key] ?? m['${e1.key}_date'])?.toString().trim() ?? '';

      final hasSecond = i + 1 < activeEntries.length;
      final e2 = hasSecond ? activeEntries[i + 1] : null;
      final on2 = hasSecond ? (procChecks[e2!.key] == true || m[e2.key] == true) : false;
      final d2 = hasSecond ? ((procDates[e2!.key] ?? m['${e2.key}_date'])?.toString().trim() ?? '') : '';

      if (items.isNotEmpty) {
        items.add(const SizedBox(height: 8));
      }

      if (desktop) {
        items.add(
          Row(
            children: [
              Expanded(child: _proceduralCheckItem(e1.value, on1, d1)),
              const SizedBox(width: 12),
              Expanded(
                child: hasSecond
                    ? _proceduralCheckItem(e2!.value, on2, d2)
                    : const SizedBox(),
              ),
            ],
          ),
        );
      } else {
        items.add(_proceduralCheckItem(e1.value, on1, d1));
        if (hasSecond) {
          items.add(const SizedBox(height: 8));
          items.add(_proceduralCheckItem(e2!.value, on2, d2));
        }
      }
    }

    final eshDt = _v(m['eshakshDt']);
    final eshReason = _v(m['eshakshReason']);
    final isEshYes = m['eshakshValue']?.toString().trim().toLowerCase() == 'yes' || m['e_shakshya'] == true;
    final isEshNo = m['eshakshValue']?.toString().trim().toLowerCase() == 'no';

    final eshakshFields = <({String label, String value, bool fullWidth})>[
      if (isEshYes)
        (
          label: 'E-Shakshya',
          value: 'Yes (Recorded)',
          fullWidth: false,
        ),
      if (isEshYes && eshDt.isNotEmpty && eshDt != '—')
        (
          label: 'E-Shakshya Date & Time',
          value: eshDt,
          fullWidth: false,
        )
      else if (isEshNo && eshReason.isNotEmpty && eshReason != '—')
        (
          label: 'Reason for No E-Shakshya',
          value: eshReason,
          fullWidth: false,
        ),
    ];

    final validEsh = _pairedSimpleFields(context, eshakshFields);

    if (items.isEmpty && validEsh.isEmpty) {
      return const [];
    }

    return [
      if (items.isNotEmpty) ...items,
      if (items.isNotEmpty && validEsh.isNotEmpty) const SizedBox(height: 14),
      if (validEsh.isNotEmpty) ...[
        Text(
          'E-SHAKSHYA COMPLIANCE',
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.navyMid,
          ),
        ),
        const SizedBox(height: 6),
        ...validEsh,
      ],
    ];
  }

  Widget _proceduralCheckItem(String title, bool isDone, String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.infoBlue.withValues(alpha: 0.04)
            : AppColors.lightBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isDone
              ? AppColors.infoBlue.withValues(alpha: 0.25)
              : AppColors.lightBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 18,
            color: isDone
                ? AppColors.infoBlue
                : AppColors.lightSubText.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: isDone ? FontWeight.w600 : FontWeight.w500,
                    color: isDone
                        ? AppColors.navyDark
                        : AppColors.navyDark.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDone
                      ? (date.isNotEmpty && date != '—'
                          ? 'Conducted on $date'
                          : 'Conducted (Date not set)')
                      : 'Not conducted',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: isDone ? FontWeight.w500 : FontWeight.w400,
                    color: isDone ? AppColors.infoBlue : AppColors.lightSubText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chargeCard(int n, Map<dynamic, dynamic> data) {
    final act = _v(data['act']);
    final rawSecs = data['sections'];
    final secs = (rawSecs is List)
        ? rawSecs
            .map((s) => s.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : (rawSecs is Map)
            ? rawSecs.values
                .map((s) => s.toString().trim())
                .where((s) => s.isNotEmpty)
                .toList()
            : (rawSecs != null && rawSecs.toString().trim().isNotEmpty)
                ? [rawSecs.toString().trim()]
                : <String>[];
    if (act.isEmpty && secs.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.lightBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: const Border(
          left: BorderSide(color: AppColors.infoBlue, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Charge #$n${act.isEmpty ? '' : ': $act'}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 8),
          if (secs.isEmpty)
            Text(
              'No sections selected',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.lightSubText,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: secs
                  .map(
                    (s) => Chip(
                      label: Text('§$s'),
                      visualDensity: VisualDensity.compact,
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color: AppColors.infoBlue.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _verdictColumn(String title, List<String> names, Color edge) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: edge.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: edge,
              ),
            ),
            _divider(),
            if (names.isEmpty)
              Text(
                'None',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.lightSubText,
                ),
              )
            else
              ...names.map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 6, color: edge),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          n,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.lightText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _scrutinyStepUi(
    BuildContext context,
    int step,
    String title,
    bool active, {
    required String send,
    required String grant,
    String? lockedMsg,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor:
                    active ? AppColors.infoBlue : AppColors.lightBorder,
                child: Text(
                  '$step',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  color: active ? AppColors.infoBlue : AppColors.lightBorder,
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.navyDark : AppColors.lightSubText,
                  ),
                ),
                const SizedBox(height: 6),
                if (!active && lockedMsg != null)
                  Text(
                    lockedMsg,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: AppColors.lightSubText,
                    ),
                  )
                else ...[
                  ..._pairedSimpleFields(context, [
                    (label: 'Send Date', value: send, fullWidth: false),
                    (label: 'Grant Date', value: grant, fullWidth: false),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExtraMapSection(
    BuildContext context, [
    int sectionNumber = 18,
  ]) {
    final mergedExtra = Map<String, dynamic>.from(extraMap);
    if (record != null && record!.extraFields.isNotEmpty) {
      for (final e in record!.extraFields.entries) {
        if (!mergedExtra.containsKey(e.key)) {
          mergedExtra[e.key] = e.value;
        }
      }
    }

    if (mergedExtra.isEmpty) return [];

    const ignoredKeys = {
      'commonForm', 'common_form', 'charges', 'acts_sections', 'seizures',
      'object_name', 'seizure_description', 'seizure_person_name',
      'proceduralChecks', 'proceduralDates', 'extra_field_values',
      'dynamic_extra_fields', 'unidentifiedList', 'custodyInfo',
      'custody_records', 'arrest_records', 'arrests', 'suspectedAccused',
      'unknownAccused', 'dischargeDetails', 'dischargeByAccused',
      'preventive_actions', 'discharges', 'custody', 'court', 'scrutiny',
      'unidentified', 'complainant', 'accused', 'remand_custody',
      'spotVillage', 'spotArea', 'spotAddress', 'crNo', 'regDate',
      'firCopyPath', 'isUnknownUntraced', 'isUnknownAccused', 'isSexualOffence',
      'village_town', 'area_name', 'full_address', 'cr_number',
      'registered_datetime', 'occurrence_datetime', 'io_name', 'io_designation',
      'registered_by_name', 'registered_by_designation', 'deceased_name',
      'deceased_age', 'deceased_gender', 'cause_of_death', 'pm_report_date',
      'witness_summons', 'witness_summons_date', 'charge_sheet_no',
      'cc_st_number', 'a_final_number', 'b_final_number', 'c_final_number',
      'nc_final_number', 'abeted_summary_no', 'stay_by_high_court_date',
      'quashed_by_high_court_date', 'cctv_checked', 'cdr_sent_date',
      'cdr_received_date', 'fingerprint_taken', 'nafis_fingerprint',
      'e_shakshya', 'e_shakshya_date', 'stay_by_high_court', 'quashed_by_high_court',
    };

    final flat = <({String label, String value, bool fullWidth})>[];
    for (final e in mergedExtra.entries) {
      if (ignoredKeys.contains(e.key) || e.key.endsWith('_date') || e.key.endsWith('_datetime')) continue;
      final val = e.value;
      if (val == null || val == false || val == '' || val == '—' || val == '-' || val == 'None') continue;
      if (val is Map || val is List) continue;
      flat.add((
        label: _labelifyExtraKey(e.key),
        value: _disp(val),
        fullWidth: false,
      ));
    }

    final validFlat = _pairedSimpleFields(context, flat);
    if (validFlat.isEmpty) return [];

    return [
      _sectionShell(
        sectionNumber,
        'AUDIT & ADDITIONAL DETAILS',
        AppColors.infoBlue,
        validFlat,
        icon: Icons.history_edu_outlined,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (layoutContext, constraints) {
        final wide = constraints.maxWidth > _kCaseDetailDesktopBreakpoint;
        return _CaseDetailLayoutScope(
          desktop: wide,
          child: Builder(builder: (context) => _buildDetailColumn(context)),
        );
      },
    );
  }

  Widget _buildDetailColumn(BuildContext context) {
    final m = commonMap;
    final r = record;
    final isUnknown = m['isUnknownUntraced'] == true || m['isUnknownAccused'] == true;
    final chargesRaw = m['charges'] ?? m['acts_sections'] ?? r?.extraFields['charges'] ?? r?.extraFields['acts_sections'];
    final chargesMap = (chargesRaw is Map) ? chargesRaw : {};
    final chargesList = (chargesRaw is List) ? chargesRaw : [];

    final comp = (m['complainant'] is Map) ? (m['complainant'] as Map) : {};
    final u = (m['unidentified'] is Map) ? (m['unidentified'] as Map) : {};
    final unidList = (m['unidentifiedList'] is List) ? (m['unidentifiedList'] as List) : [];
    final cr8 = (m['caseResponsibility'] is Map) ? (m['caseResponsibility'] as Map) : {};
    final procChecks = (m['proceduralChecks'] is Map) ? (m['proceduralChecks'] as Map) : {};
    final procDates = (m['proceduralDates'] is Map) ? (m['proceduralDates'] as Map) : {};
    final seizuresRaw = m['seizures'] ?? r?.extraFields['seizures'];
    final seizures = (seizuresRaw is List) ? seizuresRaw : [];
    final prev = (m['preventive'] is Map) ? (m['preventive'] as Map) : {};
    final discharge = (m['dischargeByAccused'] is Map) ? (m['dischargeByAccused'] as Map) : {};
    final disDetails = (m['dischargeDetails'] is Map) ? (m['dischargeDetails'] as Map) : {};
    final court = (m['court'] is Map)
        ? Map<String, dynamic>.from(m['court'] as Map)
        : <String, dynamic>{};
    final verdict = (m['verdict'] is Map) ? (m['verdict'] as Map) : {};
    final acquitted = (verdict['acquitted'] is List)
        ? (verdict['acquitted'] as List).map((x) => x.toString()).toList()
        : <String>[];
    final convicted = (verdict['convicted'] is List)
        ? (verdict['convicted'] as List).map((x) => x.toString()).toList()
        : <String>[];
    final sc = (m['scrutiny'] is Map) ? (m['scrutiny'] as Map) : {};
    final accusedList = (m['accused'] is List) ? (m['accused'] as List) : [];
    final suspectedList = (m['suspectedAccused'] is List) ? (m['suspectedAccused'] as List) : [];
    final arrests = (m['arrestRelease'] is List) ? (m['arrestRelease'] as List) : [];

    const accent = AppColors.infoBlue;
    int sIdx = 1;

    final children = <Widget>[
      _sectionTitle(
        'Case Details',
        Icons.folder_shared_outlined,
        AppColors.goldPrimary,
      ),
      const SizedBox(height: 10),
    ];

    // ── 1. Core Case Summary ───────────────────────────────────────────────
    final summaryFields = _pairedSimpleFields(context, [
      (
        label: 'Case No.',
        value: _v(r?.caseNumber.isNotEmpty == true ? r!.caseNumber : m['crNo']),
        fullWidth: false,
      ),
      (
        label: 'Crime Type',
        value: _v(r?.title.isNotEmpty == true ? r!.title : (r?.subCategory ?? m['crimeType'])),
        fullWidth: false,
      ),
      (
        label: 'Police Station',
        value: _v(r?.stationName.isNotEmpty == true ? r!.stationName : m['station_name']),
        fullWidth: false,
      ),
      (
        label: 'Status',
        value: _v(r?.status.isNotEmpty == true ? r!.status : m['status']),
        fullWidth: false,
      ),
      (
        label: 'Priority',
        value: _v(r?.priority.isNotEmpty == true ? r!.priority : m['priority']),
        fullWidth: false,
      ),
      (
        label: 'Incident Date',
        value: r != null && r.incidentDate.year > 1980
            ? DateFormat('dd/MM/yyyy').format(r.incidentDate)
            : _v(m['incidentDate'] ?? m['incident_date']),
        fullWidth: false,
      ),
      (
        label: 'Registered Date',
        value: _v(m['regDate'] ??
            (r != null && r.createdAt.year > 1980
                ? DateFormat('dd/MM/yyyy').format(r.createdAt)
                : null)),
        fullWidth: false,
      ),
      (
        label: 'Assigned Officer',
        value: _v(r?.assignedOfficer.isNotEmpty == true
            ? r!.assignedOfficer
            : (cr8['ioName'] ?? m['assigned_officer'])),
        fullWidth: false,
      ),
      (
        label: 'Location / Spot',
        value: _v(r?.location.isNotEmpty == true ? r!.location : (m['spotAddress'] ?? m['spotVillage'])),
        fullWidth: true,
      ),
      (
        label: 'Description',
        value: _v(r?.description.isNotEmpty == true ? r!.description : m['description']),
        fullWidth: true,
      ),
    ]);
    if (summaryFields.isNotEmpty) {
      children.add(
        _sectionShell(
          sIdx++,
          'CASE SUMMARY',
          accent,
          summaryFields,
          icon: Icons.badge_outlined,
        ),
      );
    }

    // ── 2. Crime Registration Info ─────────────────────────────────────────
    final regFields = _pairedSimpleFields(context, [
      (label: 'Cr. No.', value: _v(m['crNo']), fullWidth: false),
      (label: 'Registered Date', value: _v(m['regDate']), fullWidth: false),
      if (isUnknown)
        (
          label: 'Unknown / Untraced',
          value: 'Yes',
          fullWidth: false,
        ),
      (
        label: 'FIR Copy',
        value: _v(m['firCopyPath']),
        fullWidth: false,
      ),
    ]);
    if (regFields.isNotEmpty) {
      children.add(_sectionShell(sIdx++, 'CRIME REGISTRATION INFO', accent, regFields));
    }

    // ── 3. Acts & Sections Filed ───────────────────────────────────────────
    final chargeWidgets = <Widget>[];
    if (chargesMap.isNotEmpty) {
      chargesMap.entries.toList().asMap().entries.forEach((e) {
        final i = e.key + 1;
        final data = (e.value.value is Map) ? (e.value.value as Map) : <dynamic, dynamic>{};
        final card = _chargeCard(i, data);
        if (card is! SizedBox || (card.height != null && card.height! > 0)) {
          chargeWidgets.add(card);
        }
      });
    } else if (chargesList.isNotEmpty) {
      chargesList.asMap().entries.forEach((e) {
        final i = e.key + 1;
        final data = (e.value is Map) ? (e.value as Map) : <dynamic, dynamic>{};
        final card = _chargeCard(i, data);
        if (card is! SizedBox || (card.height != null && card.height! > 0)) {
          chargeWidgets.add(card);
        }
      });
    }
    if (chargeWidgets.isNotEmpty) {
      children.add(_sectionShell(sIdx++, 'ACTS & SECTIONS FILED', accent, chargeWidgets));
    }

    // ── 4. Crime Spot ──────────────────────────────────────────────────────
    final spotFields = _pairedSimpleFields(context, [
      (
        label: 'Village / Town',
        value: _v(m['spotVillage'] ?? m['village_town']),
        fullWidth: false,
      ),
      (label: 'Area Name', value: _v(m['spotArea'] ?? m['area_name']), fullWidth: false),
      (label: 'Full Address', value: _v(m['spotAddress'] ?? m['full_address']), fullWidth: true),
    ]);
    if (spotFields.isNotEmpty) {
      children.add(_sectionShell(sIdx++, 'CRIME SPOT', accent, spotFields));
    }

    // ── 5. Complainant ─────────────────────────────────────────────────────
    final compName = _v(comp['name'] ?? (r?.complainant.isNotEmpty == true ? r!.complainant : null));
    final compFields = _pairedSimpleFields(context, [
      (
        label: 'Name',
        value: (commonMap['isSexualOffence'] == true || compName.contains('Protected'))
            ? '⚠️ [Victim Identity Protected - Confidential]'
            : compName,
        fullWidth: false,
      ),
      (label: 'Age', value: _v(comp['age']), fullWidth: false),
      (label: 'Gender', value: _v(comp['gender']), fullWidth: false),
      (label: 'Occupation', value: _v(comp['occ']), fullWidth: false),
      (label: 'Mobile', value: _v(comp['mobile']), fullWidth: false),
      (label: 'Aadhaar', value: _v(comp['aadhaar']), fullWidth: false),
      (label: 'Religion', value: _v(comp['religion']), fullWidth: false),
      (label: 'Caste', value: _v(comp['caste']), fullWidth: false),
      (label: 'PAN Number', value: _v(comp['pan']), fullWidth: false),
    ]);
    if (compFields.isNotEmpty) {
      children.add(_sectionShell(sIdx++, 'COMPLAINANT', accent, compFields));
    }

    // ── 6. Accused ─────────────────────────────────────────────────────────
    final accusedWidgets = <Widget>[];
    if (accusedList.isNotEmpty) {
      for (var i = 0; i < accusedList.length; i++) {
        final item = accusedList[i];
        final pMap = (item is Map) ? Map<String, dynamic>.from(item) : <String, dynamic>{'name': item.toString()};
        final card = _personCard(context, 'Accused #${i + 1}', pMap);
        if (card is! SizedBox || (card.height != null && card.height! > 0)) {
          accusedWidgets.add(card);
        }
      }
    } else if (r != null && r.accused.isNotEmpty && r.accused != '—' && r.accused != 'None') {
      final card = _personCard(context, 'Accused #1', {'name': r.accused});
      if (card is! SizedBox || (card.height != null && card.height! > 0)) {
        accusedWidgets.add(card);
      }
    }
    if (accusedWidgets.isNotEmpty) {
      children.add(_sectionShell(sIdx++, 'ACCUSED', accent, accusedWidgets));
    }

    // ── 7. Suspected Accused ───────────────────────────────────────────────
    final suspectedWidgets = <Widget>[];
    if (suspectedList.isNotEmpty) {
      for (var i = 0; i < suspectedList.length; i++) {
        final item = suspectedList[i];
        final pMap = (item is Map) ? Map<String, dynamic>.from(item) : <String, dynamic>{'name': item.toString()};
        final card = _personCard(context, 'Suspected #${i + 1}', pMap);
        if (card is! SizedBox || (card.height != null && card.height! > 0)) {
          suspectedWidgets.add(card);
        }
      }
    }
    if (suspectedWidgets.isNotEmpty) {
      children.add(_sectionShell(sIdx++, 'SUSPECTED ACCUSED', accent, suspectedWidgets));
    }

    // ── 8. Unidentified Accused ────────────────────────────────────────────
    final unidWidgets = <Widget>[];
    if (unidList.isNotEmpty) {
      for (var i = 0; i < unidList.length; i++) {
        final row = (unidList[i] is Map) ? (unidList[i] as Map) : <dynamic, dynamic>{};
        final fields = _pairedSimpleFields(context, [
          (label: 'Approximate age', value: _v(row['approxAge']), fullWidth: false),
          (label: 'Gender', value: _v(row['gender']), fullWidth: false),
          (label: 'Skin colour', value: _v(row['skinColor']), fullWidth: false),
          (label: 'Possible occupation', value: _v(row['occupation']), fullWidth: false),
          (label: 'Identification mark', value: _v(row['otherPhysicalMarkers']), fullWidth: true),
          (label: 'Height', value: _v(row['approxHeight']), fullWidth: false),
          (label: 'Address', value: _v(row['lastKnownAddress']), fullWidth: true),
          (label: 'Description', value: _v(row['description']), fullWidth: true),
        ]);
        if (fields.isNotEmpty) {
          unidWidgets.add(
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.lightBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unidentified Accused #${i + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...fields,
                ],
              ),
            ),
          );
        }
      }
    } else if (u.isNotEmpty) {
      final fields = _pairedSimpleFields(context, [
        (label: 'Approximate age', value: _v(u['approxAge']), fullWidth: false),
        (label: 'Gender', value: _v(u['gender']), fullWidth: false),
        (label: 'Skin colour', value: _v(u['skinColor']), fullWidth: false),
        (label: 'Possible occupation', value: _v(u['occupation']), fullWidth: false),
        (label: 'Identification mark', value: _v(u['otherPhysicalMarkers']), fullWidth: true),
        (label: 'Height', value: _v(u['approxHeight']), fullWidth: false),
        (label: 'Address', value: _v(u['lastKnownAddress']), fullWidth: true),
        (label: 'Description', value: _v(u['description']), fullWidth: true),
      ]);
      if (fields.isNotEmpty) {
        unidWidgets.addAll(fields);
      }
    }
    if (unidWidgets.isNotEmpty) {
      children.add(_sectionShell(sIdx++, 'UNIDENTIFIED ACCUSED', accent, unidWidgets));
    }

    // ── 9. Unknown Accused ─────────────────────────────────────────────────
    if (isUnknown) {
      children.add(
        _sectionShell(sIdx++, 'UNKNOWN ACCUSED', accent, [
          ..._pairedSimpleFields(context, [
            (
              label: 'Unknown Accused / Untraced',
              value: 'Yes (✓ - अज्ञात आरोपी)',
              fullWidth: true,
            ),
          ]),
        ]),
      );
    }

    // ── 10. Case Responsibility ────────────────────────────────────────────
    final respFields = _pairedSimpleFields(context, [
      (
        label: 'IO Designation',
        value: _v(cr8['ioDesig'] ?? m['io_designation']),
        fullWidth: false,
      ),
      (label: 'IO Name', value: _v(cr8['ioName'] ?? m['io_name']), fullWidth: false),
      (
        label: 'Reg. By Desig.',
        value: _v(cr8['regDesig'] ?? m['registered_by_designation']),
        fullWidth: false,
      ),
      (
        label: 'Registrar Name',
        value: _v(cr8['regName'] ?? m['registered_by_name']),
        fullWidth: false,
      ),
    ]);
    if (respFields.isNotEmpty) {
      children.add(_sectionShell(sIdx++, 'CASE RESPONSIBILITY', accent, respFields));
    }

    // ── 11. Arrest ─────────────────────────────────────────────────────────
    final arrestWidgets = <Widget>[];
    for (final rRow in arrests) {
      final row = (rRow is Map) ? rRow : <dynamic, dynamic>{};
      final isDeceased = row['isDeceased'] == true;
      final sec47 = row['sec47_48'] == true;
      final relNotice = row['relOnNotice'] == true;
      final antBail = row['anticipatoryBail'] == true;
      final fields = _pairedSimpleFields(context, [
        (
          label: 'Accused Name',
          value: _v(row['accusedName'] ?? row['name']),
          fullWidth: false,
        ),
        (
          label: 'Arrest Date/Time',
          value: _v(row['arrestDt'] ?? row['arrest_date']),
          fullWidth: false,
        ),
        if (sec47)
          (
            label: 'sec. 47/48 BNSS',
            value: 'Yes',
            fullWidth: false,
          ),
        (
          label: 'Relative / Friend Name',
          value: _v(row['relName']),
          fullWidth: false,
        ),
        (
          label: 'Relation',
          value: _v(row['relationship']),
          fullWidth: false,
        ),
        if (relNotice)
          (
            label: 'Release on Notice',
            value: 'Yes (✓)',
            fullWidth: false,
          ),
        if (antBail)
          (
            label: 'Anticipatory Bail',
            value: 'Yes (✓)',
            fullWidth: false,
          ),
        if (isDeceased)
          (
            label: 'Death of Accused',
            value: 'Yes (✓)',
            fullWidth: false,
          ),
        if (isDeceased)
          (
            label: 'Date/Time of Death',
            value: _v(row['deathDt']),
            fullWidth: false,
          ),
      ]);
      if (fields.isNotEmpty) {
        arrestWidgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.lightBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Column(children: fields),
          ),
        );
      }
    }
    if (arrestWidgets.isNotEmpty) {
      children.add(_sectionShell(sIdx++, 'ARREST', accent, arrestWidgets));
    }

    // ── 12. Custody & Remand (PCR / MCR) ───────────────────────────────────
    final custody = (m['custody'] is Map) ? (m['custody'] as Map) : {};
    final surety = (m['surety'] is Map) ? (m['surety'] as Map) : {};
    final isMcr = custody['mcr'] == true || m['mcr'] == true;
    final isBail = custody['bail'] == true || custody['bailGranted'] == true;
    final isJail = custody['jail'] == true;
    final isPrBond = custody['prBond'] == true;
    final pcrDaysVal = _v(m['pcrDays'] ?? custody['pcrDays']);

    final custodyFields = _pairedSimpleFields(context, [
      (
        label: 'PCR (00 Day)',
        value: pcrDaysVal,
        fullWidth: false,
      ),
      if (isMcr)
        (
          label: 'MCR (Magisterial Custody)',
          value: 'Yes (✓)',
          fullWidth: false,
        ),
      if (isPrBond)
        (
          label: 'PR Bond',
          value: 'Yes (✓)',
          fullWidth: false,
        ),
      if (isPrBond)
        (
          label: 'PR Bond Date',
          value: _v(custody['prBondDate'] ?? custody['pr_bond_date']),
          fullWidth: false,
        ),
      if (isJail)
        (
          label: 'Jail',
          value: 'Yes (✓)',
          fullWidth: false,
        ),
      if (isJail)
        (
          label: 'Jail Date',
          value: _v(custody['jailDate'] ?? custody['jail_date']),
          fullWidth: false,
        ),
      if (isBail)
        (
          label: 'Bail Granted',
          value: 'Yes (✓)',
          fullWidth: false,
        ),
      if (isJail)
        (
          label: 'Jail Name / Details',
          value: _v(custody['mcrJail'] ?? custody['jailName']),
          fullWidth: false,
        ),
    ]);
    final suretyFields = _pairedSimpleFields(context, [
      (
        label: 'Surety Full Name',
        value: _v(surety['name'] ?? custody['suretyName']),
        fullWidth: false,
      ),
      (
        label: 'Surety Age',
        value: _v(surety['age'] ?? custody['suretyAge']),
        fullWidth: false,
      ),
      (
        label: 'Surety Gender',
        value: _v(surety['gender'] ?? custody['suretyGender']),
        fullWidth: false,
      ),
      (
        label: 'Surety Occupation',
        value: _v(surety['occupation'] ?? custody['suretyOccupation']),
        fullWidth: false,
      ),
      (
        label: 'Surety Mobile No.',
        value: _v(surety['mobile'] ?? custody['suretyMobile']),
        fullWidth: false,
      ),
      (
        label: 'Surety Aadhaar No.',
        value: _v(surety['aadhaar'] ?? custody['suretyAadhaar']),
        fullWidth: false,
      ),
      (
        label: 'Surety PAN No.',
        value: _v(surety['pan'] ?? custody['suretyPan']),
        fullWidth: false,
      ),
      (
        label: 'Relation with Accused',
        value: _v(surety['relationship'] ?? custody['suretyRelation']),
        fullWidth: false,
      ),
      (
        label: 'Surety Address',
        value: _v(surety['address'] ?? custody['suretyAddress']),
        fullWidth: true,
      ),
    ]);
    if (custodyFields.isNotEmpty || (isBail && suretyFields.isNotEmpty)) {
      children.add(
        _sectionShell(sIdx++, 'CUSTODY & REMAND (PCR / MCR)', accent, [
          if (custodyFields.isNotEmpty) ...custodyFields,
          if (isBail && suretyFields.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.lightBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SURETY NAME & KYC DETAILS',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyMid,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...suretyFields,
                ],
              ),
            ),
          ],
        ]),
      );
    }

    // ── 13. CCTV & CDR Investigation ───────────────────────────────────────
    final cctvFields = _pairedSimpleFields(context, [
      if (m['cctvChecked'] == true)
        (
          label: 'CCTV Checked',
          value: 'Yes (✔️)',
          fullWidth: false,
        ),
      (
        label: 'CDR Send Date',
        value: _v(m['cdrSend'] ?? m['cdrSent'] ?? m['cdr_sent_date']),
        fullWidth: false,
      ),
      (
        label: 'CDR Received Date',
        value: _v(m['cdrReceived'] ?? m['cdrRecv'] ?? m['cdr_received_date']),
        fullWidth: false,
      ),
    ]);
    if (cctvFields.isNotEmpty) {
      children.add(_sectionShell(sIdx++, 'CCTV & CDR INVESTIGATION', accent, cctvFields));
    }

    // ── 14. All Panchanama ─────────────────────────────────────────────────
    final panchanamaWidgets = _buildProceduralSection(context, procChecks, procDates, m);
    if (panchanamaWidgets.isNotEmpty) {
      children.add(_sectionShell(sIdx++, 'ALL PANCHANAMA', accent, panchanamaWidgets));
    }

    // ── 15. Evidence & Seizure ─────────────────────────────────────────────
    final flatObjectName = _v(m['object_name'] ?? r?.extraFields['object_name']);
    final flatSeizureDesc = _v(m['seizure_description'] ?? r?.extraFields['seizure_description']);
    final flatSeizurePerson = _v(m['seizure_person_name'] ?? r?.extraFields['seizure_person_name']);

    final seizureWidgets = <Widget>[];
    if (seizures.isNotEmpty) {
      for (var i = 0; i < seizures.length; i++) {
        final s = (seizures[i] is Map) ? (seizures[i] as Map) : <dynamic, dynamic>{};
        final fields = _pairedSimpleFields(context, [
          (
            label: 'Item #${i + 1}',
            value: _v(s['desc'] ?? s['object_name']),
            fullWidth: true,
          ),
          (
            label: 'Quantity / Weight',
            value: _v(s['quantity'] ?? s['qty']),
            fullWidth: false,
          ),
          (
            label: 'Serial / Model No.',
            value: _v(s['serialNo'] ?? s['serial']),
            fullWidth: false,
          ),
          (
            label: 'Estimated Value (INR)',
            value: _v(s['estValue'] ?? s['val']),
            fullWidth: false,
          ),
          (
            label: 'Recovery Date',
            value: _v(s['recoveryDate'] ?? s['recDt']),
            fullWidth: false,
          ),
          (
            label: 'Custody Location',
            value: _v(s['custodyLoc'] ?? s['custody']),
            fullWidth: false,
          ),
          (
            label: 'From Whom (Name)',
            value: _v(s['fromWhom'] ?? s['person_name']),
            fullWidth: true,
          ),
        ]);
        if (fields.isNotEmpty) {
          seizureWidgets.add(
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.lightBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(children: fields),
            ),
          );
        }
      }
    } else if (flatObjectName.isNotEmpty || flatSeizureDesc.isNotEmpty || flatSeizurePerson.isNotEmpty) {
      final fields = _pairedSimpleFields(context, [
        (label: 'Seized Object / Property', value: flatObjectName, fullWidth: false),
        (label: 'Seized From (Person)', value: flatSeizurePerson, fullWidth: false),
        (label: 'Seizure Description / Details', value: flatSeizureDesc, fullWidth: true),
      ]);
      if (fields.isNotEmpty) {
        seizureWidgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.lightBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Column(children: fields),
          ),
        );
      }
    }

    final fpTaken = m['fingerprintTaken'] == true || m['fingerprintTaken'] == 'yes' || m['fingerprintVal'] == 'yes';
    final nafisFp = m['nafisFingerprint'] == true || m['nafisFingerprint'] == 'yes';
    final eshVal = m['eshakshValue']?.toString().trim().toLowerCase();
    final eshDt = _v(m['eshakshDt']);
    final eshReason = _v(m['eshakshReason']);

    final evidenceMetaFields = _pairedSimpleFields(context, [
      if (eshVal == 'yes')
        (
          label: 'E-Shakshya',
          value: 'YES (RECORDED)',
          fullWidth: false,
        ),
      if (eshVal == 'yes' && eshDt.isNotEmpty)
        (
          label: 'E-Shakshya Date & Time',
          value: eshDt,
          fullWidth: false,
        )
      else if (eshVal == 'no' && eshReason.isNotEmpty)
        (
          label: 'Reason for No E-Shakshya',
          value: eshReason,
          fullWidth: true,
        ),
      if (fpTaken)
        (
          label: 'Fingerprint Taken',
          value: 'YES',
          fullWidth: false,
        ),
      if (nafisFp)
        (
          label: 'NAFIS Fingerprint',
          value: 'YES',
          fullWidth: false,
        ),
    ]);

    if (evidenceMetaFields.isNotEmpty || seizureWidgets.isNotEmpty) {
      children.add(
        _sectionShell(sIdx++, 'EVIDENCE & SEIZURE', accent, [
          if (evidenceMetaFields.isNotEmpty) ...evidenceMetaFields,
          if (evidenceMetaFields.isNotEmpty && seizureWidgets.isNotEmpty)
            const SizedBox(height: 12),
          if (seizureWidgets.isNotEmpty) ...[
            Text(
              'SEIZURE PROPERTY DETAILS',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.navyMid,
              ),
            ),
            const SizedBox(height: 6),
            ...seizureWidgets,
          ],
        ]),
      );
    }

    // ── 16. Preventive Action & Bonds ──────────────────────────────────────
    final prevItems = ((prev['items'] is List) ? (prev['items'] as List) : null) ??
        ((m['preventive_actions'] is List) ? (m['preventive_actions'] as List) : null);
    final prevWidgets = <Widget>[];
    if (prevItems != null && prevItems.isNotEmpty) {
      for (final it in prevItems) {
        if (it is! Map) continue;
        final pName = _v(it['person_name'] ?? it['name'] ?? it['accusedName'] ?? it['person']);
        final pAction = _v(it['action'] ?? it['action_type']);
        final pDate = _v(it['action_date'] ?? it['actionDate']);
        final pOut = _v(it['outward_number'] ?? it['outwardNumber']);
        final fields = _pairedSimpleFields(context, [
          (label: 'Accused / Person', value: pName, fullWidth: false),
          (label: 'Provision', value: pAction, fullWidth: false),
          (label: 'Action Date 📅', value: pDate, fullWidth: false),
          (label: 'Outward Number', value: pOut, fullWidth: false),
        ]);
        if (fields.isNotEmpty) {
          prevWidgets.add(
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: fields,
              ),
            ),
          );
        }
      }
    }
    final singlePrevFields = _pairedSimpleFields(context, [
      (
        label: 'Preventive Action Act / Section',
        value: _v(prev['action'] ?? prev['actionType']),
        fullWidth: false,
      ),
      (
        label: 'Action Date (📅)',
        value: _v(prev['actionDate']),
        fullWidth: false,
      ),
      (
        label: 'Outward Number',
        value: _v(prev['outwardNo'] ?? prev['outwardNumber']),
        fullWidth: false,
      ),
      (
        label: 'Bond Date 📅',
        value: _v(prev['bondDate']),
        fullWidth: false,
      ),
      (
        label: 'Bond Cancellation Date 📅',
        value: _v(prev['bondCancellation'] ?? prev['bondCancelDate']),
        fullWidth: false,
      ),
      (
        label: 'Reason for PR Bond',
        value: _v(prev['bondReason'] ?? prev['prBondReason']),
        fullWidth: true,
      ),
    ]);
    if (prevWidgets.isNotEmpty || singlePrevFields.isNotEmpty) {
      children.add(
        _sectionShell(sIdx++, 'PREVENTIVE ACTION & BONDS', accent, [
          if (prevWidgets.isNotEmpty) ...prevWidgets,
          if (singlePrevFields.isNotEmpty) ...singlePrevFields,
        ]),
      );
    }

    // ── 17. Discharge Accused ──────────────────────────────────────────────
    final disWidgets = <Widget>[];
    if (discharge.isNotEmpty) {
      for (final e in discharge.entries) {
        if (e.value != true) continue;
        final name = e.key.toString();
        final det = (disDetails[name] is Map) ? (disDetails[name] as Map) : {};
        disWidgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.successGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.successGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$name — Discharged',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.navyDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (det.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  if (det['date'] != null && det['date'].toString().trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 26, top: 2),
                      child: Text(
                        'Discharge Date: ${det['date']}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.navyDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (det['reason'] != null && det['reason'].toString().trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 26, top: 2),
                      child: Text(
                        'Reason: ${det['reason']}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.darkSubText,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      }
    }
    if (m['customDischargeList'] is List && (m['customDischargeList'] as List).isNotEmpty) {
      for (final cd in (m['customDischargeList'] as List)) {
        final cMap = (cd is Map) ? cd : <dynamic, dynamic>{'name': cd.toString()};
        final fields = _pairedSimpleFields(context, [
          (
            label: 'Person Name',
            value: _v(cMap['name']),
            fullWidth: false,
          ),
          (
            label: 'Discharge Date 📅',
            value: _v(cMap['date']),
            fullWidth: false,
          ),
          (
            label: 'Discharge Reason',
            value: _v(cMap['reason']),
            fullWidth: true,
          ),
        ]);
        if (fields.isNotEmpty) {
          disWidgets.add(
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.lightBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(children: fields),
            ),
          );
        }
      }
    }
    if (disWidgets.isNotEmpty) {
      children.add(_sectionShell(sIdx++, 'DISCHARGE ACCUSED', accent, disWidgets));
    }

    // ── 18. Scrutiny ───────────────────────────────────────────────────────
    final hasScrutinyData = [
      sc['sdpoSend'], sc['sdpoGrant'],
      sc['dcpSend'], sc['dcpGrant'],
      sc['addlCpSend'], sc['addlCpGrant'],
      sc['appSend'], sc['appGrant']
    ].any((x) => x != null && x.toString().trim().isNotEmpty && x.toString().trim() != '—' && x.toString().trim() != 'None');
    if (hasScrutinyData) {
      children.add(
        _sectionShell(sIdx++, 'SCRUTINY', accent, [
          _scrutinyStepUi(
            context,
            1,
            'SDPO / ACP Approval',
            true,
            send: _v(sc['sdpoSend']),
            grant: _v(sc['sdpoGrant']),
          ),
          _scrutinyStepUi(
            context,
            2,
            'Addl. SP / DCP Approval',
            true,
            send: _v(sc['dcpSend']),
            grant: _v(sc['dcpGrant']),
          ),
          _scrutinyStepUi(
            context,
            3,
            'Addl. CP Approval',
            true,
            send: _v(sc['addlCpSend']),
            grant: _v(sc['addlCpGrant']),
          ),
          _scrutinyStepUi(
            context,
            4,
            'APP Scrutiny',
            true,
            send: _v(sc['appSend']),
            grant: _v(sc['appGrant']),
            isLast: true,
          ),
        ]),
      );
    }

    // ── 19. Court Filing & Final Summary ───────────────────────────────────
    final courtFields = _pairedSimpleFields(context, [
      (
        label: 'A Final Number',
        value: _v(court['aFinalNo']),
        fullWidth: false,
      ),
      (
        label: 'B Final Number',
        value: _v(court['bFinalNo']),
        fullWidth: false,
      ),
      (
        label: 'C Final Number',
        value: _v(court['cFinalNo']),
        fullWidth: false,
      ),
      (
        label: 'NC Final Number',
        value: _v(court['ncFinalNo']),
        fullWidth: false,
      ),
      (
        label: 'Abated Summary No.',
        value: _v(court['abatedSummaryNo']),
        fullWidth: true,
      ),
      (
        label: 'Stay by High Court Date 📅',
        value: _v(court['stayHighCourtDate']),
        fullWidth: false,
      ),
      (
        label: 'Quashed by High Court Date 📅',
        value: _v(court['quashedHighCourtDate'] ?? court['quashDate']),
        fullWidth: false,
      ),
      if (court['finalClassification'] != null && court['finalClassification'].toString().trim().isNotEmpty && court['finalClassification'].toString().trim() != 'Pending')
        (
          label: 'Final Case Classification',
          value: _v(court['finalClassification']),
          fullWidth: false,
        ),
    ]);
    final hasChargeSheetData = (court['chargeSheetNumber']?.toString().trim().isNotEmpty ?? false) ||
        (court['chargeSheetDate']?.toString().trim().isNotEmpty ?? false) ||
        (court['ccStNumber']?.toString().trim().isNotEmpty ?? false);
    final hasVerdict = acquitted.isNotEmpty || convicted.isNotEmpty;
    if (!readOnly || hasChargeSheetData || courtFields.isNotEmpty || hasVerdict) {
      children.add(
        _sectionShell(sIdx++, 'COURT FILING & FINAL SUMMARY', accent, [
          _CourtFilingEditableSection(
            court: court,
            record: record,
            readOnly: readOnly,
            onSubmitted: onChargeSheetSubmitted,
          ),
          if (courtFields.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...courtFields,
          ],
          if (hasVerdict) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _verdictColumn('✓ ACQUITTED', acquitted, AppColors.successGreen),
                const SizedBox(width: 10),
                _verdictColumn('✗ CONVICTED', convicted, AppColors.dangerRed),
              ],
            ),
          ],
        ]),
      );
    }

    // ── 20. Audit & Additional Details ─────────────────────────────────────
    final extraWidgets = _buildExtraMapSection(context, sIdx++);
    if (extraWidgets.isNotEmpty) {
      children.addAll(extraWidgets);
    }

    // Fallback if completely empty
    if (children.length <= 2) {
      children.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.folder_open_outlined,
                size: 48,
                color: AppColors.lightSubText,
              ),
              const SizedBox(height: 12),
              Text(
                'No additional saved details found for this case.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.lightSubText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

}

class _CourtFilingEditableSection extends StatefulWidget {
  final Map court;
  final ModuleRecord? record;
  final bool readOnly;
  final VoidCallback? onSubmitted;

  const _CourtFilingEditableSection({
    required this.court,
    this.record,
    this.readOnly = false,
    this.onSubmitted,
  });

  @override
  State<_CourtFilingEditableSection> createState() =>
      _CourtFilingEditableSectionState();
}

class _CourtFilingEditableSectionState
    extends State<_CourtFilingEditableSection> {
  late final TextEditingController _numCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _ccCtrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final cMap = widget.court;
    final recCourt = (widget.record?.extraFields['court'] is Map)
        ? widget.record!.extraFields['court'] as Map
        : null;
    final initialNum = cMap['chargeSheetNumber']?.toString().trim() ??
        recCourt?['chargeSheetNumber']?.toString().trim() ??
        '';
    final initialDate = cMap['chargeSheetDate']?.toString().trim() ??
        recCourt?['chargeSheetDate']?.toString().trim() ??
        '';
    final initialCc = cMap['ccStNumber']?.toString().trim() ??
        recCourt?['ccStNumber']?.toString().trim() ??
        widget.record?.extraFields['ccStNumber']?.toString().trim() ??
        '';
    _numCtrl = TextEditingController(text: initialNum);
    _dateCtrl = TextEditingController(text: initialDate);
    _ccCtrl = TextEditingController(text: initialCc);
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    _dateCtrl.dispose();
    _ccCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    DateTime initial = now;
    if (_dateCtrl.text.isNotEmpty) {
      try {
        final p = _dateCtrl.text.split('/');
        if (p.length == 3) {
          initial = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
        }
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        _dateCtrl.text = formatted;
      });
    }
  }

  Future<void> _submitChargeSheet() async {
    final numVal = _numCtrl.text.trim();
    final dateVal = _dateCtrl.text.trim();
    final ccVal = _ccCtrl.text.trim();

    final hasCs = numVal.isNotEmpty && dateVal.isNotEmpty;
    final hasCc = ccVal.isNotEmpty;

    if (!hasCs && !hasCc) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TranslationHelper.translate(
              context,
              'Please enter Charge Sheet details (Number & Date) or CC / ST Number',
            ),
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (promptCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.successGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  TranslationHelper.translate(
                    promptCtx,
                    'Confirm Move to Disposal',
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TranslationHelper.translate(
                  promptCtx,
                  'Submitting Court Filing details will mark the case as Disposed and move it to the Disposal tab. Do you want to proceed?',
                ),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (numVal.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            '${TranslationHelper.translate(promptCtx, 'Charge Sheet No.')}: ',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyDark,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              numVal,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyMid,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (dateVal.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            '${TranslationHelper.translate(promptCtx, 'Charge Sheet Date')}: ',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyDark,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              dateVal,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyMid,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (ccVal.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            '${TranslationHelper.translate(promptCtx, 'CC / ST No.')}: ',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyDark,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              ccVal,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyMid,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(promptCtx, false),
              child: Text(
                TranslationHelper.translate(promptCtx, 'Cancel'),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightSubText,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(promptCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                TranslationHelper.translate(promptCtx, 'Move to Disposal'),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isSubmitting = true);

    try {
      if (numVal.isNotEmpty) widget.court['chargeSheetNumber'] = numVal;
      if (dateVal.isNotEmpty) widget.court['chargeSheetDate'] = dateVal;
      if (ccVal.isNotEmpty) widget.court['ccStNumber'] = ccVal;

      final currentRecord = widget.record;
      if (currentRecord != null) {
        final newCourt = Map<String, dynamic>.from(
          (currentRecord.extraFields['court'] is Map)
              ? currentRecord.extraFields['court'] as Map
              : {},
        );
        if (numVal.isNotEmpty) newCourt['chargeSheetNumber'] = numVal;
        if (dateVal.isNotEmpty) newCourt['chargeSheetDate'] = dateVal;
        if (ccVal.isNotEmpty) newCourt['ccStNumber'] = ccVal;

        final newExtra = Map<String, dynamic>.from(currentRecord.extraFields);
        newExtra['court'] = newCourt;
        newExtra['disposedAt'] = DateTime.now().toIso8601String();
        if (ccVal.isNotEmpty) newExtra['disposedCcStNumber'] = ccVal;
        if (numVal.isNotEmpty) newExtra['disposedChargeSheetNumber'] = numVal;

        if (newExtra[kCommonFormExtraFieldsKey] is Map) {
          final nested = Map<String, dynamic>.from(
            newExtra[kCommonFormExtraFieldsKey] as Map,
          );
          final nestedCourt = Map<String, dynamic>.from(
            (nested['court'] is Map) ? nested['court'] as Map : {},
          );
          if (numVal.isNotEmpty) nestedCourt['chargeSheetNumber'] = numVal;
          if (dateVal.isNotEmpty) nestedCourt['chargeSheetDate'] = dateVal;
          if (ccVal.isNotEmpty) nestedCourt['ccStNumber'] = ccVal;
          nested['court'] = nestedCourt;
          newExtra[kCommonFormExtraFieldsKey] = nested;
        }

        final updatedRecord = currentRecord.copyWith(
          status: 'Disposal',
          extraFields: newExtra,
        );

        if (!mounted) return;
        await context.read<FormIVProvider>().updateRecord(updatedRecord);
        if (!mounted) return;
        widget.onSubmitted?.call();

        if (mounted) {
          final summaryMsg = ccVal.isNotEmpty
              ? '${TranslationHelper.translate(context, 'Case moved to Disposal with CC/ST No.')} $ccVal'
              : '${TranslationHelper.translate(context, 'Case moved to Disposal with Charge Sheet No.')} $numVal';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                summaryMsg,
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update court filing: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readOnly) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _compactDisplayField(
                  TranslationHelper.translate(context, 'Charge Sheet No.'),
                  _numCtrl.text.trim().isEmpty ? '—' : _numCtrl.text.trim(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _compactDisplayField(
                  TranslationHelper.translate(context, 'Charge Sheet Date'),
                  _dateCtrl.text.trim().isEmpty ? '—' : _dateCtrl.text.trim(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _compactDisplayField(
                  TranslationHelper.translate(context, 'CC / ST Number'),
                  _ccCtrl.text.trim().isEmpty ? '—' : _ccCtrl.text.trim(),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  label: TranslationHelper.translate(
                    context,
                    'Charge Sheet Number',
                  ),
                  hint: 'e.g. 104/2026',
                  controller: _numCtrl,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDateField(
                  label: TranslationHelper.translate(
                    context,
                    'Charge Sheet Date',
                  ),
                  hint: 'DD/MM/YYYY',
                  controller: _dateCtrl,
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTextField(
                  label: TranslationHelper.translate(
                    context,
                    'CC Number / ST Number',
                  ),
                  hint: 'e.g. CC 120/2026',
                  controller: _ccCtrl,
                ),
              ),
            ],
          )
        else ...[
          _buildTextField(
            label: TranslationHelper.translate(context, 'Charge Sheet Number'),
            hint: 'e.g. 104/2026',
            controller: _numCtrl,
          ),
          const SizedBox(height: 12),
          _buildDateField(
            label: TranslationHelper.translate(context, 'Charge Sheet Date'),
            hint: 'DD/MM/YYYY',
            controller: _dateCtrl,
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: TranslationHelper.translate(
              context,
              'CC Number / ST Number',
            ),
            hint: 'e.g. CC 120/2026',
            controller: _ccCtrl,
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitChargeSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyMid,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSubmitting) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    const Icon(Icons.check_circle_outline_rounded, size: 16),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    TranslationHelper.translate(context, 'Submit'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                TranslationHelper.translate(
                  context,
                  'Submitting will mark the case as Disposed & move to Disposal tab.',
                ),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.lightSubText,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _compactDisplayField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.lightSubText,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.lightText,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.navyDark,
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.navyDark),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.lightSubText,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: AppColors.navyMid,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.navyDark,
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.navyDark),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.lightSubText,
              ),
              suffixIcon: const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: AppColors.navyMid,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: AppColors.navyMid,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
