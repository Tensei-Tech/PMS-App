// lib/modules/preventive/screens/preventive_view_screen.dart
// Clean, structured read-only layout for Preventive / Istegasha cases.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../modules/core/models/base_record.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/module_pdf_helper.dart';
import '../../../utils/pdf_auth_gate.dart';
import 'preventive_form_screen.dart';

typedef PreventiveViewScreen = PreventiveDetailViewScreen;

class PreventiveDetailViewScreen extends StatelessWidget {
  final ModuleRecord record;
  final String moduleLabel;

  const PreventiveDetailViewScreen({
    super.key,
    required this.record,
    this.moduleLabel = 'Preventive Action',
  });

  @override
  Widget build(BuildContext context) {
    final extra = Map<String, dynamic>.from(record.extraFields);
    final prevMap = extra[kPreventiveFormExtraFieldsKey] is Map
        ? Map<String, dynamic>.from(
            extra[kPreventiveFormExtraFieldsKey] as Map)
        : extra;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          record.title.isNotEmpty ? record.title : 'Preventive Record Detail',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.navyDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.navyDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined,
                color: AppColors.navyMid),
            onPressed: () => runWithPdfAuthGate(
              context,
              () => ModulePdfHelper.generatePdf(record),
            ),
          ),
          IconButton(
            tooltip: 'Edit Entry',
            icon: const Icon(Icons.edit_outlined, color: AppColors.navyMid),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PreventiveFormScreen(
                    moduleLabel: moduleLabel,
                    existingRecord: record,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: PreventiveViewDocumentView(
              record: record,
              prevMap: prevMap,
              moduleLabel: moduleLabel,
            ),
          ),
        ),
      ),
    );
  }
}

/// Embeddable Read-Only Document View for Preventive Records.
class PreventiveViewDocumentView extends StatelessWidget {
  final ModuleRecord record;
  final Map<String, dynamic> prevMap;
  final String moduleLabel;

  const PreventiveViewDocumentView({
    super.key,
    required this.record,
    required this.prevMap,
    this.moduleLabel = 'Preventive Action',
  });

  static const Color _kDark = Color(0xFF0F172A);
  static const Color _kSec = Color(0xFF64748B);
  static const Color _kTeal = Color(0xFF0EA5E9);
  static const Color _kBorder = Color(0xFFE2E8F0);
  static const Color _kCardBg = Colors.white;
  static const Color _kSubtleBg = Color(0xFFF8FAFC);
  static const Color _kGreen = Color(0xFF10B981);
  static const Color _kRed = Color(0xFFEF4444);
  static const Color _kAmber = Color(0xFFF59E0B);

  String _val(dynamic v, {String fallback = '—'}) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  @override
  Widget build(BuildContext context) {
    final formMap = (prevMap['preventiveForm'] is Map<String, dynamic>)
        ? prevMap['preventiveForm'] as Map<String, dynamic>
        : prevMap;

    final caseRef = formMap['caseRef'] as Map<String, dynamic>? ?? {};
    final sections = formMap['sections'] as Map<String, dynamic>? ?? {};
    final accusedList = formMap['accusedList'] as List<dynamic>? ?? [];
    final istegasha = formMap['istegasha'] as Map<String, dynamic>? ?? {};
    final riskAndStatus =
        formMap['riskAndStatus'] as Map<String, dynamic>? ?? {};

    final fallbackCrimeNo = record.caseNumber.trim().isNotEmpty
        ? record.caseNumber
        : record.title;
    final crimeNo = _val(
      caseRef['crimeNo'] ?? prevMap['crimeNo'] ?? fallbackCrimeNo,
    );
    final regDate = _val(caseRef['regDate'] ?? prevMap['regDate']);
    final crimeCategory = _val(
      caseRef['crimeCategory'] ??
          prevMap['crimeCategory'] ??
          record.subCategory,
      fallback: 'Theft',
    );
    final caseStatus = _val(
      caseRef['caseStatus'] ?? prevMap['caseStatus'] ?? record.status,
      fallback: 'Under Investigation',
    );

    final selectedAct = _val(sections['act'] ?? prevMap['act'], fallback: 'BNS');
    final List<String> selectedSectionsList = [];
    if (sections['selectedSections'] is List) {
      selectedSectionsList.addAll(
        (sections['selectedSections'] as List).map((e) => e.toString()),
      );
    } else if (prevMap['selectedSections'] is List) {
      selectedSectionsList.addAll(
        (prevMap['selectedSections'] as List).map((e) => e.toString()),
      );
    }
    final otherSections =
        _val(sections['otherSections'] ?? prevMap['otherSections']);

    final preventiveNo = _val(
      istegasha['preventiveNo'] ??
          prevMap['preventiveNo'] ??
          record.extraFields['preventiveNo'],
    );
    final preventiveDate = _val(
      istegasha['preventiveDate'] ?? prevMap['preventiveDate'],
    );
    final outwardNo =
        _val(istegasha['outwardNo'] ?? prevMap['outwardNo']);
    final ioName = _val(
      istegasha['ioName'] ??
          prevMap['ioName'] ??
          record.assignedOfficer,
    );

    final riskFlag = _val(
      riskAndStatus['riskFlag'] ??
          prevMap['riskFlag'] ??
          record.priority,
      fallback: '🚨 High Priority',
    );
    final actionStatus = _val(
      riskAndStatus['actionStatus'] ??
          prevMap['actionStatus'] ??
          prevMap['status'],
      fallback: '🟢 Preventive Action Completed',
    );
    final remarks =
        _val(riskAndStatus['remarks'] ?? prevMap['remarks'] ?? record.description);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Top Status Badges Card ──────────────────────────────────────────
        _buildStatusHeaderCard(riskFlag, actionStatus),
        const SizedBox(height: 16),

        // ── 1. Case & Crime Reference ───────────────────────────────────────
        _buildCard(
          title: 'Case & Crime Reference',
          marathiTitle: 'गुन्हा व खटला संदर्भ',
          icon: Icons.folder_copy_rounded,
          children: [
            _buildGridRow([
              _FieldData('Crime No. / FIR No. / NC no.', crimeNo, isBold: true),
              _FieldData('Registration Date', regDate),
            ]),
            _buildDivider(),
            _buildGridRow([
              _FieldData('Crime Category', crimeCategory, isChip: true),
              _FieldData('Case Status', caseStatus, isStatusChip: true),
            ]),
          ],
        ),
        const SizedBox(height: 16),

        // ── 2. Sections & Acts (Filter by Section) ──────────────────────────
        _buildCard(
          title: 'Sections (BNS / Other Acts)',
          marathiTitle: 'कलमे व कायदे (BNS / इतर कायदे)',
          icon: Icons.gavel_rounded,
          children: [
            _buildField('Primary Act', selectedAct, isBold: true),
            if (selectedSectionsList.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildSectionsBadgeWrap(selectedAct, selectedSectionsList),
            ],
            if (otherSections != '—') ...[
              _buildDivider(),
              _buildField('Other Acts / Custom Sections', otherSections),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // ── 3. Accused Name(s) & Preventive Action Details ──────────────────
        _buildCard(
          title: 'Accused Name(s) & Action Status',
          marathiTitle: 'आरोपीचे नाव व कारवाई स्थिती',
          icon: Icons.people_alt_rounded,
          children: [
            if (accusedList.isNotEmpty) ...[
              for (int i = 0; i < accusedList.length; i++)
                _buildAccusedItem(i + 1, accusedList[i]),
            ] else ...[
              _buildField(
                'Accused Name(s)',
                _val(
                  record.extraFields['accusedNames'] ??
                      record.extraFields['accused'] ??
                      '—',
                ),
                isBold: true,
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // ── 4. Preventive / Istegasha Details ───────────────────────────────
        _buildCard(
          title: 'Preventive & Istegasha Details',
          marathiTitle: 'प्रतिबंधक / इस्तेगाशा तपशील',
          icon: Icons.shield_outlined,
          children: [
            _buildGridRow([
              _FieldData(
                'Preventive No. / इस्तेगाशा नंबर',
                preventiveNo,
                isBold: true,
              ),
              _FieldData('Date of Preventive', preventiveDate),
            ]),
            _buildDivider(),
            _buildGridRow([
              _FieldData('Outward Number', outwardNo),
              _FieldData('Investigating Officer (IO)', ioName, isBold: true),
            ]),
          ],
        ),

        // ── 5. Remarks / Action Summary (if available) ──────────────────────
        if (remarks != '—') ...[
          const SizedBox(height: 16),
          _buildCard(
            title: 'Remarks / Action Summary',
            marathiTitle: 'तपशील व टिप्पण्या',
            icon: Icons.notes_rounded,
            children: [
              _buildField('Action Summary / Order Details', remarks),
            ],
          ),
        ],

        const SizedBox(height: 30),
      ],
    );
  }

  // ── Header Status Badges Card ─────────────────────────────────────────────
  Widget _buildStatusHeaderCard(String riskFlag, String actionStatus) {
    final isHigh = riskFlag.contains('High');
    final isSensitive = riskFlag.contains('Sensitive');

    Color riskBg = const Color(0xFFFEE2E2);
    Color riskBorder = _kRed;
    Color riskText = _kRed;

    if (isSensitive) {
      riskBg = const Color(0xFFFEF3C7);
      riskBorder = _kAmber;
      riskText = const Color(0xFFD97706);
    } else if (!isHigh) {
      riskBg = _kTeal.withValues(alpha: 0.12);
      riskBorder = _kTeal;
      riskText = _kTeal;
    }

    final isCompleted = actionStatus.contains('Completed');
    final isPartial = actionStatus.contains('Partially');
    Color actionBg = const Color(0xFFFEF2F2);
    Color actionBorder = _kRed;
    Color actionText = _kRed;

    if (isCompleted) {
      actionBg = const Color(0xFFECFDF5);
      actionBorder = _kGreen;
      actionText = const Color(0xFF047857);
    } else if (isPartial) {
      actionBg = const Color(0xFFFFFBEB);
      actionBorder = _kAmber;
      actionText = const Color(0xFFB45309);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Risk Flag
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Risk Flag: ',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSec,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: riskBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: riskBorder, width: 1.2),
                ),
                child: Text(
                  riskFlag,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: riskText,
                  ),
                ),
              ),
            ],
          ),

          // Action Status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Action Status: ',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSec,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: actionBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: actionBorder, width: 1.2),
                ),
                child: Text(
                  actionStatus,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: actionText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sections Wrap Badge ───────────────────────────────────────────────────
  Widget _buildSectionsBadgeWrap(String act, List<String> sections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Applied Sections',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kSec,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sections.map((sec) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Text(
                '$act $sec',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3730A3),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Accused Individual Item Card ──────────────────────────────────────────
  Widget _buildAccusedItem(int index, dynamic item) {
    if (item is! Map) return const SizedBox.shrink();
    final map = Map<String, dynamic>.from(item);
    final name = _val(map['name'], fallback: 'Accused $index');
    final actionType = _val(map['actionType'], fallback: 'Arrested');
    final bondTaken = _val(map['bondTaken'], fallback: 'No');
    final bondDetails = _val(map['bondDetails'], fallback: '');

    final isArrested = actionType == 'Arrested';
    final isNotice = actionType == 'Notice Issued';
    final isBondYes = bondTaken == 'Yes';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSubtleBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kDark,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Accused $index',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Action Status Chip
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Action / Status',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _kSec,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isArrested
                            ? const Color(0xFFDCFCE7)
                            : (isNotice
                                ? const Color(0xFFE0E7FF)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: isArrested
                              ? _kGreen
                              : (isNotice
                                  ? const Color(0xFF6366F1)
                                  : _kBorder),
                        ),
                      ),
                      child: Text(
                        actionType,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isArrested
                              ? const Color(0xFF15803D)
                              : (isNotice
                                  ? const Color(0xFF4338CA)
                                  : _kSec),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Bond Taken Chip
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bond Taken (Y/N)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _kSec,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isBondYes
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: isBondYes ? _kGreen : _kBorder,
                        ),
                      ),
                      child: Text(
                        'Bond Taken: $bondTaken',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isBondYes
                              ? const Color(0xFF15803D)
                              : _kSec,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isBondYes && bondDetails.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Bond Details: $bondDetails',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _kDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Card Builder Helper ───────────────────────────────────────────────────
  Widget _buildCard({
    required String title,
    required String marathiTitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: Border(bottom: BorderSide(color: _kBorder)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 17, color: _kTeal),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kDark,
                          ),
                        ),
                        TextSpan(
                          text: '  ·  $marathiTitle',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _kSec,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ── Grid & Field Helpers ──────────────────────────────────────────────────
  Widget _buildGridRow(List<_FieldData> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 500) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _buildFieldFromData(fields[i]),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < fields.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(child: _buildFieldFromData(fields[i])),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFieldFromData(_FieldData data) {
    if (data.isChip) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kSec,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _kTeal.withValues(alpha: 0.5)),
            ),
            child: Text(
              data.value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _kTeal,
              ),
            ),
          ),
        ],
      );
    }
    if (data.isStatusChip) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kSec,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF818CF8)),
            ),
            child: Text(
              data.value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4338CA),
              ),
            ),
          ),
        ],
      );
    }
    return _buildField(data.label, data.value, isBold: data.isBold);
  }

  Widget _buildField(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kSec,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: _kDark,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: _kBorder),
    );
  }
}

class _FieldData {
  final String label;
  final String value;
  final bool isBold;
  final bool isChip;
  final bool isStatusChip;

  _FieldData(
    this.label,
    this.value, {
    this.isBold = false,
    this.isChip = false,
    this.isStatusChip = false,
  });
}
