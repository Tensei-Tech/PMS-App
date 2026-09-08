// lib/modules/nc/screens/nc_view_screen.dart
// Clean, structured read-only layout for Non-Cognizable (NC) cases.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../modules/core/models/base_record.dart';
import '../../../screens/ad_form_screen.dart' show ACT_DATA;
import '../../../theme/app_theme.dart';
import '../../../utils/module_pdf_helper.dart';
import '../../../utils/pdf_auth_gate.dart';
import 'nc_form_screen.dart';

typedef NCViewScreen = NcViewScreen;

class NcViewScreen extends StatelessWidget {
  final ModuleRecord record;
  final String moduleLabel;

  const NcViewScreen({
    super.key,
    required this.record,
    this.moduleLabel = 'Non-Cognizable (NC)',
  });

  @override
  Widget build(BuildContext context) {
    final extra = Map<String, dynamic>.from(record.extraFields);
    final ncMap = extra[kNcFormExtraFieldsKey] is Map
        ? Map<String, dynamic>.from(extra[kNcFormExtraFieldsKey] as Map)
        : <String, dynamic>{};

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          record.title.isNotEmpty ? record.title : 'NC Record Detail',
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
                  builder: (_) => NcFormScreen(
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
            child: NcViewDocumentView(
              record: record,
              ncMap: ncMap,
              moduleLabel: moduleLabel,
            ),
          ),
        ),
      ),
    );
  }
}

/// Embeddable Read-Only Document View for NC Records.
class NcViewDocumentView extends StatelessWidget {
  final ModuleRecord record;
  final Map<String, dynamic> ncMap;
  final String moduleLabel;

  const NcViewDocumentView({
    super.key,
    required this.record,
    required this.ncMap,
    this.moduleLabel = 'NC Record',
  });

  static const Color _kDark = Color(0xFF0f172a);
  static const Color _kSec = Color(0xFF64748b);
  static const Color _kTeal = Color(0xFF0ea5e9);
  static const Color _kBorder = Color(0xFFe2e8f0);
  static const Color _kCardBg = Colors.white;
  static const Color _kSubtleBg = Color(0xFFF8FAFC);

  String _val(dynamic v, {String fallback = 'N/A'}) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _secLabel(String actKey, String val) {
    final secs = ACT_DATA[actKey]?['sections'] as List<dynamic>? ?? [];
    for (final raw in secs) {
      if (raw is Map) {
        if (raw['val'] == val) return raw['label'] as String? ?? val;
      }
    }
    return val;
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: _kTeal),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kDark,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _row(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kSec,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                color: isHighlight ? _kTeal : _kDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _twoCol(String l1, String v1, String l2, String v2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 480) {
            return Column(
              children: [
                _row(l1, v1),
                _row(l2, v2),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(l1,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kSec)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text(v1,
                          style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: _kDark)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(l2,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kSec)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text(v2,
                          style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: _kDark)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 16, color: _kBorder, thickness: 0.6);

  // ── 1. Basic Details & Crime Spot ──────────────────────────────────────────
  Widget _buildBasicDetails() {
    final ncNum = _val(ncMap['ncNumber'] ?? record.caseNumber);
    final incidentDt = record.incidentDate;
    final fallbackDate =
        '${incidentDt.day.toString().padLeft(2, '0')}/${incidentDt.month.toString().padLeft(2, '0')}/${incidentDt.year}';
    final regDate = _val(ncMap['registrationDate'] ??
        ncMap['registrationDateTime'] ??
        fallbackDate);

    final spot = ncMap['crimeSpot'];
    String village = 'N/A';
    String area = 'N/A';
    String address = 'N/A';

    if (spot is Map) {
      village = _val(spot['village']);
      area = _val(spot['area']);
      address = _val(spot['address']);
    } else if (record.location.isNotEmpty) {
      address = record.location;
    }

    return _card(
      children: [
        _twoCol('NC. No.', ncNum, 'Registered Date', regDate),
        _divider(),
        _twoCol('Village / Town', village, 'Area Name', area),
        _row('Crime Spot Address', address),
      ],
    );
  }

  // ── 2. Acts & Sections ─────────────────────────────────────────────────────
  Widget _buildActsAndSections() {
    final charges = ncMap['charges'];
    final List<Map<String, dynamic>> chargeList = [];

    if (charges is Map) {
      for (final e in charges.entries) {
        if (e.value is Map) {
          chargeList.add(Map<String, dynamic>.from(e.value as Map));
        }
      }
    }

    if (chargeList.isEmpty) {
      return _card(
        children: [
          _row('Act & Section', 'N/A'),
        ],
      );
    }

    return _card(
      children: [
        ...chargeList.asMap().entries.map((e) {
          final idx = e.key + 1;
          final data = e.value;
          final actKey = data['act']?.toString() ?? '';
          final actLabel = actKey.isNotEmpty
              ? (ACT_DATA[actKey]?['label'] as String? ?? actKey)
              : 'N/A';
          final secs = data['sections'];
          final List<String> secList = [];
          if (secs is Iterable) {
            for (final s in secs) {
              if (s != null && s.toString().isNotEmpty)
                secList.add(s.toString());
            }
          }

          return Container(
            margin: EdgeInsets.only(bottom: idx < chargeList.length ? 12 : 0),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$idx',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        actLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _kDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (secList.isEmpty)
                  Text('No specific sections selected',
                      style: GoogleFonts.poppins(fontSize: 11, color: _kSec))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: secList.map((sec) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: _kTeal.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '§$sec  (${_secLabel(actKey, sec)})',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kDark,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── 3. Complainant KYC List ────────────────────────────────────────────────
  Widget _buildComplainantList() {
    final List<Map<String, dynamic>> list = [];
    if (ncMap['complainants'] is List &&
        (ncMap['complainants'] as List).isNotEmpty) {
      for (final item in ncMap['complainants'] as List) {
        if (item is Map) list.add(Map<String, dynamic>.from(item));
      }
    } else if (ncMap['complainant'] is Map) {
      list.add(Map<String, dynamic>.from(ncMap['complainant'] as Map));
    } else if (record.complainant.isNotEmpty) {
      list.add({'name': record.complainant});
    }

    if (list.isEmpty) {
      return _card(
        children: [
          _row('Complainant', 'N/A'),
        ],
      );
    }

    return Column(
      children: list.asMap().entries.map((e) {
        final idx = e.key + 1;
        final c = e.value;
        return _card(
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
                    'Complainant $idx',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _val(c['name']),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kDark,
                  ),
                ),
              ],
            ),
            _divider(),
            _twoCol('Age', _val(c['age']), 'Gender', _val(c['gender'])),
            _twoCol('Caste', _val(c['caste']), 'Profession',
                _val(c['profession'] ?? c['occ'])),
            _twoCol('Mobile Number', _val(c['mobile']), 'Aadhar Number',
                _val(c['aadhaar'])),
            _row('Address', _val(c['address'])),
          ],
        );
      }).toList(),
    );
  }

  // ── 4. Non-Applicant KYC List ──────────────────────────────────────────────
  Widget _buildNonApplicantList() {
    final List<Map<String, dynamic>> list = [];
    final rawList = ncMap['nonApplicants'] ?? ncMap['personsComplainedAgainst'];
    if (rawList is List && rawList.isNotEmpty) {
      for (final item in rawList) {
        if (item is Map) list.add(Map<String, dynamic>.from(item));
      }
    } else if (ncMap['personComplainedAgainst'] is Map) {
      list.add(
          Map<String, dynamic>.from(ncMap['personComplainedAgainst'] as Map));
    } else if (record.accused.isNotEmpty) {
      list.add({'name': record.accused});
    }

    if (list.isEmpty) {
      return _card(
        children: [
          _row('Non-Applicant', 'N/A'),
        ],
      );
    }

    return Column(
      children: list.asMap().entries.map((e) {
        final idx = e.key + 1;
        final a = e.value;
        return _card(
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Non-Applicant $idx',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _val(a['name']),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kDark,
                  ),
                ),
              ],
            ),
            _divider(),
            _twoCol('Age', _val(a['age']), 'Gender', _val(a['gender'])),
            _twoCol('Caste', _val(a['caste']), 'Profession',
                _val(a['profession'] ?? a['occ'])),
            _twoCol('Mobile Number', _val(a['mobile']), 'Aadhar Number',
                _val(a['aadhaar'])),
            _row('Address', _val(a['address'])),
          ],
        );
      }).toList(),
    );
  }

  // ── 5. Officer Details ─────────────────────────────────────────────────────
  Widget _buildOfficerDetails() {
    final io = ncMap['investigationOfficer'] is Map
        ? Map<String, dynamic>.from(ncMap['investigationOfficer'] as Map)
        : <String, dynamic>{};
    final rb = ncMap['registeredBy'] is Map
        ? Map<String, dynamic>.from(ncMap['registeredBy'] as Map)
        : <String, dynamic>{};

    return _card(
      children: [
        Text(
          'Investigation Officer (IO)',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _kDark,
          ),
        ),
        const SizedBox(height: 4),
        _twoCol('Name', _val(io['name'] ?? record.assignedOfficer),
            'Designation', _val(io['designation'])),
        _row('Mobile Number', _val(io['mobile'])),
        _divider(),
        Text(
          'Registered By',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _kDark,
          ),
        ),
        const SizedBox(height: 4),
        _twoCol(
            'Name', _val(rb['name']), 'Designation', _val(rb['designation'])),
        _row('Mobile Number', _val(rb['mobile'])),
      ],
    );
  }

  // ── 6. First Information Content ───────────────────────────────────────────
  Widget _buildFic() {
    final content =
        _val(ncMap['firstInformationContent'] ?? record.description);
    return _card(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kSubtleBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder),
          ),
          child: Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _kDark,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── 7. Preventive Details ──────────────────────────────────────────────────
  Widget _buildPreventiveDetails() {
    final prevCh = ncMap['preventiveCharges'];
    final List<Map<String, dynamic>> prevChargeList = [];

    if (prevCh is Map) {
      for (final e in prevCh.entries) {
        if (e.value is Map) {
          prevChargeList.add(Map<String, dynamic>.from(e.value as Map));
        }
      }
    }

    final prev = ncMap['preventiveDetails'] is Map
        ? Map<String, dynamic>.from(ncMap['preventiveDetails'] as Map)
        : <String, dynamic>{};

    final prevNumber = _val(prev['preventiveNumber']);
    final outNumber =
        _val(prev['outwardNumber'] ?? ncMap['caseOutward']?['number']);
    final prevDate =
        _val(prev['preventiveDate'] ?? ncMap['caseOutward']?['date']);
    final bondDate = _val(prev['bondDate']);
    final bondCancelDate = _val(prev['bondCancellationDate']);

    return _card(
      children: [
        if (prevChargeList.isNotEmpty) ...[
          Text(
            'Preventive Acts & Sections',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 8),
          ...prevChargeList.map((data) {
            final actKey = data['act']?.toString() ?? '';
            final actLabel = actKey.isNotEmpty
                ? (ACT_DATA[actKey]?['label'] as String? ?? actKey)
                : 'N/A';
            final secs = data['sections'];
            final List<String> secList = [];
            if (secs is Iterable) {
              for (final s in secs) {
                if (s != null && s.toString().isNotEmpty)
                  secList.add(s.toString());
              }
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kSubtleBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(actLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kDark)),
                  if (secList.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: secList
                          .map((sec) => Text('§$sec',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: _kTeal,
                                  fontWeight: FontWeight.w600)))
                          .toList(),
                    ),
                  ],
                ],
              ),
            );
          }),
          _divider(),
        ],
        _twoCol('Preventive No. / इस्तेगाशा नं.', prevNumber, 'Outward Number',
            outNumber),
        _twoCol('Preventive Date', prevDate, 'Bond Date', bondDate),
        _row('Bond Cancellation Date', bondCancelDate),
      ],
    );
  }

  // ── 8. Post-NC Action ──────────────────────────────────────────────────────
  Widget _buildPostNcAction() {
    final postNc = ncMap['postNcAction'] is Map
        ? Map<String, dynamic>.from(ncMap['postNcAction'] as Map)
        : <String, dynamic>{};

    final isCrimeRegistered =
        (postNc['crimeRegisteredAfterNc'] ?? ncMap['chargesAddedOnNc'])
                ?.toString()
                .toLowerCase() ==
            'yes';

    final crNo = _val(postNc['crNumber'] ?? ncMap['crNumberIfChargesAdded']);
    final act = _val(postNc['act']);
    final section = _val(postNc['section']);

    return _card(
      children: [
        _row(
          'Crime Registered after NC',
          isCrimeRegistered ? 'Yes' : 'No',
          isHighlight: isCrimeRegistered,
        ),
        if (isCrimeRegistered) ...[
          _divider(),
          _twoCol('Crime Number (CR no.)', crNo, 'Act', act),
          _row('Section', section),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
            'Basic Details & Crime Spot', Icons.description_outlined),
        _buildBasicDetails(),
        _sectionHeader('Acts & Sections Filed', Icons.gavel_outlined),
        _buildActsAndSections(),
        _sectionHeader('Complainant KYC Details', Icons.person_outline),
        _buildComplainantList(),
        _sectionHeader(
            'Non-Applicant KYC Details', Icons.person_search_outlined),
        _buildNonApplicantList(),
        _sectionHeader('Officer Details', Icons.badge_outlined),
        _buildOfficerDetails(),
        _sectionHeader('First Information Content', Icons.history_edu_outlined),
        _buildFic(),
        _sectionHeader('Preventive Details', Icons.shield_outlined),
        _buildPreventiveDetails(),
        _sectionHeader('Post-NC Action', Icons.assignment_turned_in_outlined),
        _buildPostNcAction(),
      ],
    );
  }
}
