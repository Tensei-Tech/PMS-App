// lib/modules/nc/widgets/nc_form.dart
// Standalone NC registration form — comprehensive implementation matching specification.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../screens/ad_form_screen.dart' show ACT_DATA;
import '../../../widgets/base_form/base_form.dart';
import '../../../widgets/voice_dictation_button.dart';

// ── Palette (matches app design system) ──────────────────────────────────────
const Color _kDark = Color(0xFF0f172a);
const Color _kMid = Color(0xFF1e293b);
const Color _kTeal = Color(0xFF0ea5e9);
const Color _kGreen = Color(0xFF10b981);
const Color _kRed = Color(0xFFef4444);
const Color _kAmber = Color(0xFFf59e0b);
const Color _kSec = Color(0xFF64748b);
const Color _kMuted = Color(0xFF94a3b8);
const Color _kInputBg = Color(0xFFf8fafc);
const Color _kBorder = Color(0xFFe2e8f0);
const Color _kCardBg = Color(0xFFffffff);
const Color _kPageBg = Color(0xFFf4f7f9);

const _tsLabel = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: _kDark,
  letterSpacing: 0.3,
);
const _tsSection = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w800,
  color: _kDark,
  letterSpacing: 0.5,
);
const _tsMuted = TextStyle(fontSize: 11, color: _kMuted);
const _tsBody = TextStyle(fontSize: 12, color: _kDark);

const _kGenders = ['Male', 'Female', 'Other'];

/// KYC Entry Model for Complainants & Non-Applicants (supports up to 3 entries)
class NcPersonKycEntry {
  final TextEditingController name = TextEditingController();
  final TextEditingController age = TextEditingController();
  String gender = 'Male';
  final TextEditingController caste = TextEditingController();
  final TextEditingController profession = TextEditingController();
  final TextEditingController mobile = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController aadhaar = TextEditingController();

  void dispose() {
    name.dispose();
    age.dispose();
    caste.dispose();
    profession.dispose();
    mobile.dispose();
    address.dispose();
    aadhaar.dispose();
  }

  void clear() {
    name.clear();
    age.clear();
    gender = 'Male';
    caste.clear();
    profession.clear();
    mobile.clear();
    address.clear();
    aadhaar.clear();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.text.trim(),
      'age': age.text.trim(),
      'gender': gender,
      'caste': caste.text.trim(),
      'profession': profession.text.trim(),
      'mobile': mobile.text.trim(),
      'address': address.text.trim(),
      'aadhaar': aadhaar.text.trim(),
    };
  }

  void fromMap(Map<String, dynamic> m) {
    name.text = m['name']?.toString() ?? '';
    age.text = m['age']?.toString() ?? '';
    final g = m['gender']?.toString();
    if (g != null && _kGenders.contains(g)) {
      gender = g;
    }
    caste.text = m['caste']?.toString() ?? '';
    profession.text = (m['profession'] ?? m['occ'])?.toString() ?? '';
    mobile.text = m['mobile']?.toString() ?? '';
    address.text = m['address']?.toString() ?? '';
    aadhaar.text = m['aadhaar']?.toString() ?? '';
  }
}

class NcForm extends StatefulWidget {
  const NcForm({super.key});

  @override
  State<NcForm> createState() => NcFormState();
}

class NcFormState extends State<NcForm> {
  late final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> scrollProgress = ValueNotifier(0);
  String saveBarText = 'All changes unsaved';

  // 1. Basic Details
  final _ncNumber = TextEditingController();
  final _regDate = TextEditingController();
  final _spotVillage = TextEditingController();
  final _spotArea = TextEditingController();
  final _spotAddress = TextEditingController();

  // Act & Section (Primary charges)
  int _chargeSeq = 0;
  final Map<String, Map<String, dynamic>> _chargeData = {};

  // 2. Complainant KYC (Max 3 entries)
  final List<NcPersonKycEntry> _complainants = [NcPersonKycEntry()];

  // 3. Non-Applicant KYC (Max 3 entries)
  final List<NcPersonKycEntry> _nonApplicants = [NcPersonKycEntry()];

  // 4. Officer Details
  final _ioName = TextEditingController();
  final _ioDesig = TextEditingController(text: 'PSI');
  final _ioMobile = TextEditingController();

  final _registrarName = TextEditingController();
  final _regDesig = TextEditingController(text: 'HC');
  final _regMobile = TextEditingController();

  // 5. First Information Content (max 50 chars, max 3 lines)
  final _fic = TextEditingController();
  int _ficCharCount = 0;

  // 6. Preventive Details
  int _prevChargeSeq = 0;
  final Map<String, Map<String, dynamic>> _preventiveChargeData = {};
  final _preventiveNumber = TextEditingController();
  final _preventiveOutwardNumber = TextEditingController();
  final _preventiveDate = TextEditingController();
  final _bondDate = TextEditingController();
  final _bondCancelDate = TextEditingController();

  // 7. Post-NC Action (Conditional Visibility)
  String? _crimeRegisteredAfterNc; // 'yes' or 'no'
  final _postNcCrNo = TextEditingController();
  int _postNcChargeSeq = 0;
  final Map<String, Map<String, dynamic>> _postNcChargeData = {};

  @override
  void initState() {
    super.initState();
    _fic.addListener(() {
      if (mounted) {
        setState(() {
          _ficCharCount = _fic.text.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    scrollProgress.dispose();
    _ncNumber.dispose();
    _regDate.dispose();
    _spotVillage.dispose();
    _spotArea.dispose();
    _spotAddress.dispose();

    for (final c in _complainants) {
      c.dispose();
    }
    for (final a in _nonApplicants) {
      a.dispose();
    }

    _ioName.dispose();
    _ioDesig.dispose();
    _ioMobile.dispose();

    _registrarName.dispose();
    _regDesig.dispose();
    _regMobile.dispose();

    _fic.dispose();

    _preventiveNumber.dispose();
    _preventiveOutwardNumber.dispose();
    _preventiveDate.dispose();
    _bondDate.dispose();
    _bondCancelDate.dispose();

    _postNcCrNo.dispose();

    super.dispose();
  }

  bool _onScrollNotif(ScrollNotification n) {
    final mx = n.metrics.maxScrollExtent;
    if (mx <= 0) {
      scrollProgress.value = 0;
      return false;
    }
    final p = (n.metrics.pixels / mx).clamp(0.0, 1.0);
    if ((p - scrollProgress.value).abs() > 0.004) scrollProgress.value = p;
    return false;
  }

  void saveDraft() {
    setState(
        () => saveBarText = 'Draft saved · ${TimeOfDay.now().format(context)}');
  }

  void clearForm() {
    _ncNumber.clear();
    _regDate.clear();
    _spotVillage.clear();
    _spotArea.clear();
    _spotAddress.clear();

    _chargeData.clear();
    _chargeSeq = 0;

    for (final c in _complainants) {
      c.dispose();
    }
    _complainants
      ..clear()
      ..add(NcPersonKycEntry());

    for (final a in _nonApplicants) {
      a.dispose();
    }
    _nonApplicants
      ..clear()
      ..add(NcPersonKycEntry());

    _ioName.clear();
    _ioDesig.text = 'PSI';
    _ioMobile.clear();

    _registrarName.clear();
    _regDesig.text = 'HC';
    _regMobile.clear();

    _fic.clear();
    _ficCharCount = 0;

    _preventiveChargeData.clear();
    _prevChargeSeq = 0;
    _preventiveNumber.clear();
    _preventiveOutwardNumber.clear();
    _preventiveDate.clear();
    _bondDate.clear();
    _bondCancelDate.clear();

    _crimeRegisteredAfterNc = null;
    _postNcCrNo.clear();
    _postNcChargeData.clear();
    _postNcChargeSeq = 0;

    saveBarText = 'All changes unsaved';
    setState(() {});
  }

  String _formatDateDdMmYyyy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  DateTime? _parseDateDdMmYyyy(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final p = s.split('/');
    if (p.length != 3) return null;
    final d = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final y = int.tryParse(p[2]);
    if (d == null || m == null || y == null) return null;
    try {
      final dt = DateTime(y, m, d);
      if (dt.year != y || dt.month != m || dt.day != d) return null;
      return dt;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDateFor(TextEditingController ctrl) async {
    final now = DateTime.now();
    final parsed = _parseDateDdMmYyyy(ctrl.text);
    final initial = parsed != null &&
            !parsed.isBefore(DateTime(1950)) &&
            !parsed.isAfter(now.add(const Duration(days: 3650)))
        ? parsed
        : now;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: now.add(const Duration(days: 3650)),
      initialDate: initial,
    );
    if (!mounted || picked == null) return;
    setState(() {
      ctrl.text = _formatDateDdMmYyyy(picked);
    });
  }

  // ── Charge Helpers (Primary) ───────────────────────────────────────────────
  void addChargeRow() {
    _chargeSeq++;
    _chargeData['charge-$_chargeSeq'] = {
      'act': '',
      'sections': <String>{},
    };
    setState(() {});
  }

  void _removeCharge(String id) {
    _chargeData.remove(id);
    setState(() {});
  }

  void _onActChange(String id, String act) {
    _chargeData[id]!['act'] = act;
    _chargeData[id]!['sections'] = <String>{};
    setState(() {});
  }

  void _addSection(String id, String val) {
    (_chargeData[id]!['sections'] as Set<String>).add(val);
    setState(() {});
  }

  void _removeSection(String id, String val) {
    (_chargeData[id]!['sections'] as Set<String>).remove(val);
    setState(() {});
  }

  // ── Preventive Charge Helpers ──────────────────────────────────────────────
  void addPreventiveChargeRow() {
    _prevChargeSeq++;
    _preventiveChargeData['prev-charge-$_prevChargeSeq'] = {
      'act': '',
      'sections': <String>{},
    };
    setState(() {});
  }

  void _removePreventiveCharge(String id) {
    _preventiveChargeData.remove(id);
    setState(() {});
  }

  void _onPreventiveActChange(String id, String act) {
    _preventiveChargeData[id]!['act'] = act;
    _preventiveChargeData[id]!['sections'] = <String>{};
    setState(() {});
  }

  void _addPreventiveSection(String id, String val) {
    (_preventiveChargeData[id]!['sections'] as Set<String>).add(val);
    setState(() {});
  }

  void _removePreventiveSection(String id, String val) {
    (_preventiveChargeData[id]!['sections'] as Set<String>).remove(val);
    setState(() {});
  }

  // ── Post-NC Charge Helpers ─────────────────────────────────────────────────
  void addPostNcChargeRow() {
    _postNcChargeSeq++;
    _postNcChargeData['post-charge-$_postNcChargeSeq'] = {
      'act': '',
      'sections': <String>{},
    };
    setState(() {});
  }

  void _removePostNcCharge(String id) {
    _postNcChargeData.remove(id);
    setState(() {});
  }

  void _onPostNcActChange(String id, String act) {
    _postNcChargeData[id]!['act'] = act;
    _postNcChargeData[id]!['sections'] = <String>{};
    setState(() {});
  }

  void _addPostNcSection(String id, String val) {
    (_postNcChargeData[id]!['sections'] as Set<String>).add(val);
    setState(() {});
  }

  void _removePostNcSection(String id, String val) {
    (_postNcChargeData[id]!['sections'] as Set<String>).remove(val);
    setState(() {});
  }

  // ── Dynamic Complainants (Max 3) ───────────────────────────────────────────
  void _addComplainant() {
    if (_complainants.length < 3) {
      setState(() {
        _complainants.add(NcPersonKycEntry());
      });
    }
  }

  void _removeComplainant(int index) {
    if (_complainants.length > 1) {
      setState(() {
        final item = _complainants.removeAt(index);
        item.dispose();
      });
    }
  }

  // ── Dynamic Non-Applicants (Max 3) ─────────────────────────────────────────
  void _addNonApplicant() {
    if (_nonApplicants.length < 3) {
      setState(() {
        _nonApplicants.add(NcPersonKycEntry());
      });
    }
  }

  void _removeNonApplicant(int index) {
    if (_nonApplicants.length > 1) {
      setState(() {
        final item = _nonApplicants.removeAt(index);
        item.dispose();
      });
    }
  }

  String _s(dynamic v) => v == null ? '' : v.toString();

  String _secLabel(String actKey, String val) {
    final secs = ACT_DATA[actKey]?['sections'] as List<dynamic>? ?? [];
    for (final raw in secs) {
      if (raw is Map) {
        if (raw['val'] == val) return raw['label'] as String? ?? val;
      }
    }
    return val;
  }

  /// Hydrates state from map.
  void hydrateFromNcMap(Map<String, dynamic> m) {
    clearForm();

    _ncNumber.text = _s(m['ncNumber']);
    _regDate.text = _s(m['registrationDate'] ?? m['registrationDateTime']);

    final spot = m['crimeSpot'];
    if (spot is Map) {
      _spotVillage.text = _s(spot['village']);
      _spotArea.text = _s(spot['area']);
      _spotAddress.text = _s(spot['address']);
    } else if (spot is String) {
      _spotAddress.text = spot;
    }

    // Charges
    final ch = m['charges'];
    if (ch is Map) {
      for (final e in ch.entries) {
        _chargeSeq++;
        final id = 'charge-$_chargeSeq';
        final raw = e.value as Map?;
        if (raw == null) continue;
        final secs = raw['sections'];
        _chargeData[id] = {
          'act': _s(raw['act']),
          'sections': <String>{
            if (secs is Iterable)
              for (final s in secs) s.toString(),
          },
        };
      }
    }

    // Complainants (supports list of KYC or single map)
    final comps = m['complainants'];
    if (comps is List && comps.isNotEmpty) {
      for (final c in _complainants) {
        c.dispose();
      }
      _complainants.clear();
      for (final raw in comps) {
        if (raw is Map) {
          final entry = NcPersonKycEntry();
          entry.fromMap(Map<String, dynamic>.from(raw));
          _complainants.add(entry);
        }
      }
      if (_complainants.isEmpty) _complainants.add(NcPersonKycEntry());
    } else if (m['complainant'] is Map) {
      _complainants.first
          .fromMap(Map<String, dynamic>.from(m['complainant'] as Map));
    }

    // Non-Applicants (supports list of KYC or single map)
    final againsts = m['nonApplicants'] ?? m['personsComplainedAgainst'];
    if (againsts is List && againsts.isNotEmpty) {
      for (final a in _nonApplicants) {
        a.dispose();
      }
      _nonApplicants.clear();
      for (final raw in againsts) {
        if (raw is Map) {
          final entry = NcPersonKycEntry();
          entry.fromMap(Map<String, dynamic>.from(raw));
          _nonApplicants.add(entry);
        }
      }
      if (_nonApplicants.isEmpty) _nonApplicants.add(NcPersonKycEntry());
    } else if (m['personComplainedAgainst'] is Map) {
      _nonApplicants.first.fromMap(
          Map<String, dynamic>.from(m['personComplainedAgainst'] as Map));
    }

    // Officer Details
    final io = m['investigationOfficer'];
    if (io is Map) {
      _ioName.text = _s(io['name']);
      _ioDesig.text = _s(io['designation']).isEmpty ? 'PSI' : _s(io['designation']);
      _ioMobile.text = _s(io['mobile']);
    }

    final rb = m['registeredBy'];
    if (rb is Map) {
      _registrarName.text = _s(rb['name']);
      _regDesig.text = _s(rb['designation']).isEmpty ? 'HC' : _s(rb['designation']);
      _regMobile.text = _s(rb['mobile']);
    }

    // First Information Content
    final rawFic = _s(m['firstInformationContent']);
    _fic.text = rawFic.length > 50 ? rawFic.substring(0, 50) : rawFic;
    _ficCharCount = _fic.text.length;

    // Preventive Details
    final prevCh = m['preventiveCharges'];
    if (prevCh is Map) {
      for (final e in prevCh.entries) {
        _prevChargeSeq++;
        final id = 'prev-charge-$_prevChargeSeq';
        final raw = e.value as Map?;
        if (raw == null) continue;
        final secs = raw['sections'];
        _preventiveChargeData[id] = {
          'act': _s(raw['act']),
          'sections': <String>{
            if (secs is Iterable)
              for (final s in secs) s.toString(),
          },
        };
      }
    }
    final prev = m['preventiveDetails'];
    if (prev is Map) {
      _preventiveNumber.text = _s(prev['preventiveNumber']);
      _preventiveOutwardNumber.text = _s(prev['outwardNumber']);
      _preventiveDate.text = _s(prev['preventiveDate']);
      _bondDate.text = _s(prev['bondDate']);
      _bondCancelDate.text = _s(prev['bondCancellationDate']);
    } else if (m['preventives'] is List && (m['preventives'] as List).isNotEmpty) {
      final firstP = (m['preventives'] as List).first;
      if (firstP is Map) {
        _preventiveOutwardNumber.text = _s(firstP['outwardNumber']);
        _preventiveDate.text = _s(firstP['outwardDate']);
        _bondDate.text = _s(firstP['bondDate']);
        _bondCancelDate.text = _s(firstP['bondCancellation']);
      }
    }

    // Post-NC Action
    final postNc = m['postNcAction'];
    if (postNc is Map) {
      _crimeRegisteredAfterNc = _s(postNc['crimeRegisteredAfterNc']).toLowerCase();
      _postNcCrNo.text = _s(postNc['crNumber']);
      final pCharges = postNc['charges'];
      if (pCharges is Map) {
        for (final e in pCharges.entries) {
          _postNcChargeSeq++;
          final id = 'post-charge-$_postNcChargeSeq';
          final raw = e.value as Map?;
          if (raw == null) continue;
          final secs = raw['sections'];
          _postNcChargeData[id] = {
            'act': _s(raw['act']),
            'sections': <String>{
              if (secs is Iterable)
                for (final s in secs) s.toString(),
            },
          };
        }
      } else if (postNc['act'] != null && _s(postNc['act']).isNotEmpty) {
        _postNcChargeSeq++;
        final id = 'post-charge-$_postNcChargeSeq';
        final act = _s(postNc['act']);
        final sec = _s(postNc['section']);
        _postNcChargeData[id] = {
          'act': act,
          'sections': <String>{if (sec.isNotEmpty) sec},
        };
      }
    } else {
      final ca = m['chargesAddedOnNc']?.toString().toLowerCase();
      if (ca == 'yes' || ca == 'no') _crimeRegisteredAfterNc = ca;
      _postNcCrNo.text = _s(m['crNumberIfChargesAdded']);
    }

    saveBarText = 'Loaded from record';
    setState(() {});
  }

  /// Builds document map from user inputs.
  Map<String, dynamic> buildDocumentMap() {
    final primaryComplainant = _complainants.isNotEmpty ? _complainants.first.toMap() : {};
    final primaryNonApplicant = _nonApplicants.isNotEmpty ? _nonApplicants.first.toMap() : {};

    // Extract first act and section for Post-NC Action compatibility
    String postNcFirstAct = '';
    String postNcFirstSection = '';
    if (_postNcChargeData.isNotEmpty) {
      final firstC = _postNcChargeData.values.first;
      postNcFirstAct = firstC['act']?.toString() ?? '';
      final secs = firstC['sections'] as Set<String>? ?? {};
      postNcFirstSection = secs.isNotEmpty ? secs.join(', ') : '';
    }

    return {
      'ncNumber': _ncNumber.text.trim(),
      'registrationDate': _regDate.text.trim(),
      'registrationDateTime': _regDate.text.trim(),
      'crimeSpot': {
        'village': _spotVillage.text.trim(),
        'area': _spotArea.text.trim(),
        'address': _spotAddress.text.trim(),
      },
      'charges': _chargeData.map((k, v) => MapEntry(k, {
            'act': v['act'],
            'sections': (v['sections'] as Set<String>).toList(),
          })),
      'complainants': _complainants.map((c) => c.toMap()).toList(),
      'nonApplicants': _nonApplicants.map((a) => a.toMap()).toList(),
      // Legacy single entries for compatibility
      'complainant': primaryComplainant,
      'personComplainedAgainst': primaryNonApplicant,
      'investigationOfficer': {
        'name': _ioName.text.trim(),
        'designation': _ioDesig.text.trim(),
        'mobile': _ioMobile.text.trim(),
      },
      'registeredBy': {
        'name': _registrarName.text.trim(),
        'designation': _regDesig.text.trim(),
        'mobile': _regMobile.text.trim(),
      },
      'firstInformationContent': _fic.text.trim(),
      'preventiveCharges': _preventiveChargeData.map((k, v) => MapEntry(k, {
            'act': v['act'],
            'sections': (v['sections'] as Set<String>).toList(),
          })),
      'preventiveDetails': {
        'preventiveNumber': _preventiveNumber.text.trim(),
        'outwardNumber': _preventiveOutwardNumber.text.trim(),
        'preventiveDate': _preventiveDate.text.trim(),
        'bondDate': _bondDate.text.trim(),
        'bondCancellationDate': _bondCancelDate.text.trim(),
      },
      'postNcAction': {
        'crimeRegisteredAfterNc': _crimeRegisteredAfterNc ?? 'no',
        'crNumber': _crimeRegisteredAfterNc == 'yes' ? _postNcCrNo.text.trim() : '',
        'act': postNcFirstAct,
        'section': postNcFirstSection,
        'charges': _postNcChargeData.map((k, v) => MapEntry(k, {
              'act': v['act'],
              'sections': (v['sections'] as Set<String>).toList(),
            })),
      },
      // Backward compatibility flags
      'chargesAddedOnNc': _crimeRegisteredAfterNc,
      'crNumberIfChargesAdded':
          _crimeRegisteredAfterNc == 'yes' ? _postNcCrNo.text.trim() : '',
    };
  }

  // ── UI Components & Builders ───────────────────────────────────────────────
  InputDecoration _d(String label) => InputDecoration(
        labelText: label,
        labelStyle: _tsLabel,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        filled: true,
        fillColor: _kInputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kTeal, width: 1.5),
        ),
      );

  Widget _row(List<Widget> children) =>
      StandardFormFieldRow(children: children);

  Widget _tf(
    String label,
    TextEditingController ctrl, {
    int? maxLines,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return StandardTextField(
      label: label,
      controller: ctrl,
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }

  Widget _dateField(
    String label,
    TextEditingController ctrl,
  ) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      style: _tsBody,
      decoration: _d(label).copyWith(
        suffixIcon: IconButton(
          icon:
              const Icon(Icons.calendar_today_rounded, size: 18, color: _kTeal),
          tooltip: 'Pick date',
          onPressed: () => _pickDateFor(ctrl),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minHeight: 32, minWidth: 36),
        ),
      ),
      onTap: () => _pickDateFor(ctrl),
    );
  }

  Widget _genderDropdown({
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: _kGenders.contains(selected) ? selected : 'Male',
      decoration: _d('Gender'),
      style: _tsBody,
      dropdownColor: Colors.white,
      items: _kGenders
          .map((g) => DropdownMenuItem(
                value: g,
                child: Text(g, style: _tsBody),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }

  Widget _chipSelector({
    required String label,
    required List<String> items,
    required String? selected,
    required ValueChanged<String> onSelect,
    Color activeColor = _kTeal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _tsLabel),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((item) {
              final active = selected == item;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => onSelect(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: active
                          ? activeColor.withValues(alpha: 0.1)
                          : _kInputBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? activeColor : _kBorder,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? activeColor : _kSec,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _yesNo(String label, String? val, void Function(String) onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _tsLabel),
        const SizedBox(height: 4),
        Row(
          children: [
            _yesNoChip('Yes', val == 'yes', _kGreen, () => onPick('yes')),
            const SizedBox(width: 8),
            _yesNoChip('No', val == 'no', _kRed, () => onPick('no')),
          ],
        ),
      ],
    );
  }

  Widget _yesNoChip(
      String label, bool active, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.12) : _kInputBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? color : _kBorder, width: active ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? color : _kSec,
          ),
        ),
      ),
    );
  }

  Widget _addBtn(String label, VoidCallback? onTap) => Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add, size: 14),
          label: Text(label, style: const TextStyle(fontSize: 11)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            foregroundColor: onTap != null ? _kTeal : _kMuted,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );

  Widget _emptyBox(String t) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: _kInputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder, style: BorderStyle.solid),
        ),
        child: Text(t, textAlign: TextAlign.center, style: _tsMuted),
      );

  Widget _subHeader(String t) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Text(t,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _kSec,
              letterSpacing: 1,
            )),
      );

  Widget _divider() =>
      const Divider(height: 16, thickness: 0.5, color: _kBorder);

  Widget _card(int idx, String title, Widget body, {bool startOpen = false}) {
    final leadingBadge = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: _kMid,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text('$idx',
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      ),
    );
    final themed = Theme.of(context).copyWith(dividerColor: Colors.transparent);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _kBorder),
      ),
      child: Theme(
        data: themed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  leadingBadge,
                  const SizedBox(width: 10),
                  Expanded(child: Text(title, style: _tsSection)),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [body],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── §1 Basic Details & Charges ─────────────────────────────────────────────
  Widget _sBasicDetails() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row([
            _tf('NC. No. (Manual Entry)', _ncNumber),
            _dateField('Registered Date (dd/mm/yyyy)', _regDate),
          ]),
          const SizedBox(height: 8),
          const Text('Crime Spot', style: _tsLabel),
          const SizedBox(height: 4),
          _row([
            _tf('Village / Town', _spotVillage),
            _tf('Area Name', _spotArea),
          ]),
          _row([
            _tf('Full Address', _spotAddress, maxLines: 2),
          ]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Acts & Sections Filed', style: _tsLabel),
              _addBtn('+ Add Charge', addChargeRow),
            ],
          ),
          if (_chargeData.isEmpty)
            _emptyBox('No charges. Tap + Add Charge to begin.')
          else ...[
            ..._chargeData.entries.toList().asMap().entries.map((e) {
              final id = e.value.key;
              final data = e.value.value;
              final num = e.key + 1;
              return _chargeCard(
                id: id,
                num: num,
                data: data,
                onRemove: () => _removeCharge(id),
                onActChange: (act) => _onActChange(id, act),
                onAddSection: (sec) => _addSection(id, sec),
                onRemoveSection: (sec) => _removeSection(id, sec),
              );
            }),
            _divider(),
            _subHeader('CHARGE SUMMARY'),
            ..._chargeData.entries.toList().asMap().entries.map((e) {
              final num = e.key + 1;
              final data = e.value.value;
              final act = data['act']?.toString() ?? '';
              final secs = (data['sections'] as Set<String>?) ?? {};
              final actLabel = act.isNotEmpty
                  ? (ACT_DATA[act]?['label'] as String? ?? act)
                  : '—';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2, right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('#$num',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(actLabel,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _kDark)),
                          if (secs.isEmpty)
                            const Text('No sections selected', style: _tsMuted)
                          else
                            Wrap(
                              spacing: 4,
                              children: secs
                                  .map((v) => Text(
                                        _secLabel(act, v),
                                        style: const TextStyle(
                                            fontSize: 10, color: _kTeal),
                                      ))
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      );

  Widget _chargeCard({
    required String id,
    required int num,
    required Map<String, dynamic> data,
    required VoidCallback onRemove,
    required ValueChanged<String> onActChange,
    required ValueChanged<String> onAddSection,
    required ValueChanged<String> onRemoveSection,
  }) {
    final actKey = data['act']?.toString() ?? '';
    final hasAct = actKey.isNotEmpty && ACT_DATA.containsKey(actKey);
    final secs = (data['sections'] as Set<String>?) ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Charge #$num',
                    style: _tsSection.copyWith(fontSize: 11)),
              ),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 16, color: _kRed),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _chipSelector(
            label: 'Act / Law',
            items: ACT_DATA.keys
                .map((k) => ACT_DATA[k]!['label'] as String)
                .toList(),
            selected: hasAct ? (ACT_DATA[actKey]!['label'] as String) : null,
            onSelect: (label) {
              final key = ACT_DATA.entries
                  .firstWhere((e) => e.value['label'] == label)
                  .key;
              onActChange(key);
            },
          ),
          if (hasAct) ...[
            const SizedBox(height: 4),
            Text(
              ACT_DATA[actKey]?['hint'] as String? ?? '',
              style: const TextStyle(
                  fontSize: 10, color: _kAmber, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            const Text('Section(s) — tap to add', style: _tsLabel),
            const SizedBox(height: 4),
            _NcSectionSearchPicker(
              actKey: actKey,
              selected: secs,
              onAdd: onAddSection,
              onRemove: onRemoveSection,
            ),
          ],
        ],
      ),
    );
  }

  // ── §2 Complainant KYC (Max 3 Entries) ──────────────────────────────────────
  Widget _sComplainantKyc() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Complainants (${_complainants.length}/3)',
              style: _tsLabel,
            ),
            if (_complainants.length < 3)
              _addBtn('+ Add Complainant', _addComplainant)
            else
              Text('(Max 3 reached)', style: _tsMuted.copyWith(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 6),
        ..._complainants.asMap().entries.map((e) {
          final index = e.key;
          final person = e.value;
          return _personKycCard(
            title: 'Complainant ${index + 1}',
            person: person,
            isRemovable: _complainants.length > 1,
            onRemove: () => _removeComplainant(index),
          );
        }),
      ],
    );
  }

  // ── §3 Non-Applicant KYC (Max 3 Entries) ───────────────────────────────────
  Widget _sNonApplicantKyc() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Non-Applicants (${_nonApplicants.length}/3)',
              style: _tsLabel,
            ),
            if (_nonApplicants.length < 3)
              _addBtn('+ Add Non-Applicant', _addNonApplicant)
            else
              Text('(Max 3 reached)', style: _tsMuted.copyWith(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 6),
        ..._nonApplicants.asMap().entries.map((e) {
          final index = e.key;
          final person = e.value;
          return _personKycCard(
            title: 'Non-Applicant ${index + 1}',
            person: person,
            isRemovable: _nonApplicants.length > 1,
            onRemove: () => _removeNonApplicant(index),
          );
        }),
      ],
    );
  }

  Widget _personKycCard({
    required String title,
    required NcPersonKycEntry person,
    required bool isRemovable,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kInputBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kMid,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
              const Spacer(),
              if (isRemovable)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: _kRed),
                  tooltip: 'Remove',
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _row([
            _tf('Name', person.name),
            _tf('Age (Years)', person.age, keyboardType: TextInputType.number),
          ]),
          _row([
            _genderDropdown(
              selected: person.gender,
              onChanged: (g) => setState(() => person.gender = g),
            ),
            _tf('Caste', person.caste),
          ]),
          _row([
            _tf('Profession / Occupation', person.profession),
            _tf('Mobile Number', person.mobile,
                keyboardType: TextInputType.phone),
          ]),
          _row([
            _tf('Address', person.address, maxLines: 2),
          ]),
          _row([
            _tf('Aadhar Card Number (Not mandatory)', person.aadhaar,
                keyboardType: TextInputType.number),
          ]),
        ],
      ),
    );
  }

  // ── §4 Officer Details ─────────────────────────────────────────────────────
  Widget _sOfficerDetails() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Investigation Officer (IO)', style: _tsLabel),
          const SizedBox(height: 6),
          _row([
            _tf('IO Name', _ioName),
            _tf('IO Designation', _ioDesig),
            _tf('IO Mobile Number', _ioMobile,
                keyboardType: TextInputType.phone),
          ]),
          const SizedBox(height: 14),
          const Text('Registered By', style: _tsLabel),
          const SizedBox(height: 6),
          _row([
            _tf('Registered By Name', _registrarName),
            _tf('Designation', _regDesig),
            _tf('Mobile Number', _regMobile,
                keyboardType: TextInputType.phone),
          ]),
        ],
      );

  // ── §5 First Information Content ───────────────────────────────────────────
  Widget _sFic() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('First Information Content / हकीकत (Max 50 characters)',
                  style: _tsLabel),
              VoiceDictationButton(
                controller: _fic,
                label: 'बोलून लिहा (Voice)',
                onSpeechCompleted: () {
                  if (_fic.text.length > 50) {
                    _fic.text = _fic.text.substring(0, 50);
                  }
                  setState(() => _ficCharCount = _fic.text.length);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _fic,
            maxLines: 3,
            maxLength: 50,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            style: _tsBody,
            inputFormatters: [
              LengthLimitingTextInputFormatter(50),
            ],
            decoration: _d('Enter First Information Content (Strict 50 chars limit)').copyWith(
              counterText: '$_ficCharCount / 50 characters',
              counterStyle: TextStyle(
                fontSize: 10,
                color: _ficCharCount >= 50 ? _kRed : _kMuted,
                fontWeight: _ficCharCount >= 50 ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      );

  // ── §6 Preventive Details ──────────────────────────────────────────────────
  Widget _sPreventiveDetails() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Acts & Sections Filed', style: _tsLabel),
              _addBtn('+ Add Charge', addPreventiveChargeRow),
            ],
          ),
          if (_preventiveChargeData.isEmpty)
            _emptyBox('No charges. Tap + Add Charge to begin.')
          else ...[
            ..._preventiveChargeData.entries.toList().asMap().entries.map((e) {
              final id = e.value.key;
              final data = e.value.value;
              final num = e.key + 1;
              return _chargeCard(
                id: id,
                num: num,
                data: data,
                onRemove: () => _removePreventiveCharge(id),
                onActChange: (act) => _onPreventiveActChange(id, act),
                onAddSection: (sec) => _addPreventiveSection(id, sec),
                onRemoveSection: (sec) => _removePreventiveSection(id, sec),
              );
            }),
          ],
          const SizedBox(height: 10),
          _row([
            _tf('Preventive number / इस्तेगाशा नंबर', _preventiveNumber),
            _tf('Outward number', _preventiveOutwardNumber),
          ]),
          _row([
            _dateField('Preventive Date (dd/mm/yyyy)', _preventiveDate),
            _dateField('Bond Date (dd/mm/yyyy)', _bondDate),
          ]),
          _row([
            _dateField('Bond Cancellation Date (dd/mm/yyyy)', _bondCancelDate),
          ]),
        ],
      );

  // ── §7 Post-NC Action (Conditional Visibility) ─────────────────────────────
  Widget _sPostNcAction() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _yesNo(
            'Crime registered after NC',
            _crimeRegisteredAfterNc,
            (v) {
              setState(() {
                _crimeRegisteredAfterNc = v;
                if (v == 'yes' && _postNcChargeData.isEmpty) {
                  addPostNcChargeRow();
                }
              });
            },
          ),
          if (_crimeRegisteredAfterNc == 'yes') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kInputBg,
                border: Border.all(color: _kTeal.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Post-NC Registration Details', style: _tsSection),
                  const SizedBox(height: 8),
                  _row([
                    _tf('Crime Number (CR no.) *', _postNcCrNo),
                  ]),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Acts & Sections Filed', style: _tsLabel),
                      _addBtn('+ Add Charge', addPostNcChargeRow),
                    ],
                  ),
                  if (_postNcChargeData.isEmpty)
                    _emptyBox('No charges. Tap + Add Charge to begin.')
                  else ...[
                    ..._postNcChargeData.entries.toList().asMap().entries.map((e) {
                      final id = e.value.key;
                      final data = e.value.value;
                      final num = e.key + 1;
                      return _chargeCard(
                        id: id,
                        num: num,
                        data: data,
                        onRemove: () => _removePostNcCharge(id),
                        onActChange: (act) => _onPostNcActChange(id, act),
                        onAddSection: (sec) => _addPostNcSection(id, sec),
                        onRemoveSection: (sec) => _removePostNcSection(id, sec),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      );

  Widget _barBtn(String label, IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _kPageBg,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotif,
        child: Column(
          children: [
            ValueListenableBuilder<double>(
              valueListenable: scrollProgress,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 3,
                color: _kTeal,
                backgroundColor: _kBorder,
              ),
            ),
            Container(
              color: _kCardBg,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(saveBarText, style: _tsMuted)),
                  _barBtn('Clear', Icons.refresh_outlined, clearForm, _kRed),
                  const SizedBox(width: 6),
                  _barBtn('Save Draft', Icons.save_outlined, saveDraft, _kTeal),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                children: [
                  BaseFormContent.scrollSections(
                    children: [
                      _card(1, 'Basic Details', _sBasicDetails(),
                          startOpen: true),
                      _card(2, 'Complainant KYC (Max 3)', _sComplainantKyc()),
                      _card(3, 'Non-Applicant KYC (Max 3)', _sNonApplicantKyc()),
                      _card(4, 'Officer Details', _sOfficerDetails()),
                      _card(5, 'First Information Content', _sFic()),
                      _card(6, 'Preventive Details', _sPreventiveDetails()),
                      _card(7, 'Post-NC Action', _sPostNcAction()),
                      const SizedBox(height: 80),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Searchable Section Picker (exact matching pattern from common_form.dart)
class _NcSectionSearchPicker extends StatefulWidget {
  const _NcSectionSearchPicker({
    required this.actKey,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
  });
  final String actKey;
  final Set<String> selected;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<_NcSectionSearchPicker> createState() => _NcSectionSearchPickerState();
}

class _NcSectionSearchPickerState extends State<_NcSectionSearchPicker> {
  final _ctrl = TextEditingController();
  String _query = '';
  bool _open = true;

  @override
  void didUpdateWidget(covariant _NcSectionSearchPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actKey != widget.actKey) {
      _ctrl.clear();
      _query = '';
      _open = true;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections =
        (ACT_DATA[widget.actKey]?['sections'] as List<dynamic>? ?? [])
            .map((r) => r as Map<String, dynamic>)
            .toList();

    final filtered = _query.isEmpty
        ? sections
        : sections.where((s) {
            final lbl = (s['label'] as String? ?? '').toLowerCase();
            final val = (s['val'] as String? ?? '').toLowerCase();
            final q = _query.toLowerCase();
            return lbl.contains(q) || val.contains(q);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selected.isNotEmpty)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: widget.selected.map((v) {
              final sec = sections.firstWhere((s) => s['val'] == v,
                  orElse: () => {'val': v, 'label': v, 'cat': ''});
              return InputChip(
                label: Text(
                  '§${sec['val']}',
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700),
                ),
                tooltip: sec['label'] as String? ?? v,
                onDeleted: () => widget.onRemove(v),
                deleteIconColor: _kSec,
                backgroundColor: _kTeal.withValues(alpha: 0.08),
                side: const BorderSide(color: _kTeal, width: 0.8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              );
            }).toList(),
          ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _ctrl,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Search sections…',
            hintStyle: _tsMuted,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: _kInputBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _kBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _kBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _kTeal, width: 1.5)),
            prefixIcon: const Icon(Icons.search, size: 15, color: _kSec),
          ),
          onChanged: (v) => setState(() {
            _query = v;
            _open = true;
          }),
          onTap: () => setState(() => _open = true),
        ),
        if (_open && filtered.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kBorder),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ],
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: filtered.length.clamp(0, 50),
              itemBuilder: (_, i) {
                final s = filtered[i];
                final v = s['val'] as String;
                final isSelected = widget.selected.contains(v);
                return InkWell(
                  onTap: isSelected
                      ? null
                      : () {
                          widget.onAdd(v);
                          _ctrl.clear();
                          setState(() {
                            _query = '';
                            _open = false;
                          });
                        },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _kTeal.withValues(alpha: 0.07) : null,
                      border: const Border(
                          bottom: BorderSide(color: _kBorder, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          margin: const EdgeInsets.only(right: 8),
                          child: Text(
                            '§$v',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? _kTeal : _kSec,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            s['label'] as String? ?? v,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? _kTeal : _kDark,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check, size: 14, color: _kTeal),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
