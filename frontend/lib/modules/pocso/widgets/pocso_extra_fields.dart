// lib/modules/pocso/widgets/pocso_extra_fields.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../screens/ad_form_screen.dart' show ACT_DATA;
import '../providers/pocso_provider.dart';

/// One POCSO victim entry (supports multiple victims)
class PocsoVictimData {
  String? anonymizedName;
  final TextEditingController ageController;
  String? ageProof;

  PocsoVictimData({
    this.anonymizedName,
    String initialAge = '',
    this.ageProof,
  }) : ageController = TextEditingController(text: initialAge);

  void dispose() {
    ageController.dispose();
  }
}

/// Dedicated POCSO case fields adhering strictly to statutory requirements:
/// 1. Legal Sections: Dedicated BNS & POCSO section selectors
/// 2. Victim Identity (Mandatory Anonymized): strictly dropdown/selector with 'ABC N'
/// 3. Victim Details: Multiple Victims support with "+ Add Victim", Age (2-digit) & Age Proof
/// 4. Medical: Victim & Accused (Y/N)
/// 5. Statements: 5 Y/N fields
/// 6. DNA/FSL Victim: 3 Y/N fields
/// 7. DNA/FSL Accused: 3 Y/N fields (separate from victim block)
class PocsoExtraFields extends StatefulWidget {
  final ValueChanged<String>? onVictimNameChanged;

  const PocsoExtraFields({
    super.key,
    this.onVictimNameChanged,
  });

  @override
  State<PocsoExtraFields> createState() => PocsoExtraFieldsState();
}

class PocsoExtraFieldsState extends State<PocsoExtraFields> {
  // ── Palette (matching common_form.dart) ────────────────────────────────────
  static const Color _kDark = Color(0xFF0F172A);
  static const Color _kTeal = Color(0xFF0EA5E9);
  static const Color _kGreen = Color(0xFF10B981);
  static const Color _kRed = Color(0xFFEF4444);
  static const Color _kSec = Color(0xFF64748B);
  static const Color _kMuted = Color(0xFF94A3B8);
  static const Color _kInputBg = Color(0xFFF8FAFC);
  static const Color _kBorder = Color(0xFFE2E8F0);

  // ── State variables ────────────────────────────────────────────────────────

  // 1. Legal Sections (BNS & POCSO separate)
  final Set<String> _bnsSections = <String>{};
  final Set<String> _pocsoSections = <String>{};

  // 2. Victims List (supports multiple victims, with null-safe getter)
  List<PocsoVictimData>? _victims;

  List<PocsoVictimData> get _effectiveVictims {
    _victims ??= [PocsoVictimData()];
    return _victims!;
  }

  // 3. Medical
  String? _medicalVictim; // 'yes' | 'no'
  String? _medicalAccused; // 'yes' | 'no'

  // 4. Statements
  String? _stmtVictim; // 'yes' | 'no'
  String? _stmtLadyOfficer; // 'yes' | 'no'
  String? _stmtCwc; // 'yes' | 'no'
  String? _stmt164Bnss; // 'yes' | 'no'
  String? _counselling; // 'yes' | 'no'

  // 5. DNA / FSL — Victim
  String? _dnaVictimTaken; // 'yes' | 'no'
  String? _dnaVictimSentFsl; // 'yes' | 'no'
  String? _dnaVictimFslReport; // 'yes' | 'no'

  // 6. DNA / FSL — Accused
  String? _dnaAccusedTaken; // 'yes' | 'no'
  String? _dnaAccusedSentFsl; // 'yes' | 'no'
  String? _dnaAccusedFslReport; // 'yes' | 'no'

  static const List<String> kAgeProofOptions = [
    'TC / Bonafide Certificate',
    'Aadhar Card',
    'Ossification Test',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (_effectiveVictims.isEmpty) {
      _effectiveVictims.add(PocsoVictimData());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_effectiveVictims.isNotEmpty &&
          _effectiveVictims.first.anonymizedName == null) {
        final options = _generateAnonymizedVictimOptions();
        if (options.isNotEmpty) {
          setState(() {
            _effectiveVictims.first.anonymizedName = options.first;
          });
          _notifyVictimNames();
        }
      }
    });
  }

  @override
  void dispose() {
    if (_victims != null) {
      for (final v in _victims!) {
        v.dispose();
      }
    }
    super.dispose();
  }

  void _notifyVictimNames() {
    final names = _effectiveVictims
        .map((v) => v.anonymizedName?.trim() ?? '')
        .where((n) => n.isNotEmpty)
        .join(', ');
    if (names.isNotEmpty) {
      widget.onVictimNameChanged?.call(names);
    }
  }

  void _addVictim() {
    final options = _generateAnonymizedVictimOptions();
    final usedNames = _effectiveVictims
        .map((v) => v.anonymizedName)
        .whereType<String>()
        .toSet();
    String? nextName;
    for (final opt in options) {
      if (!usedNames.contains(opt)) {
        nextName = opt;
        break;
      }
    }
    nextName ??= 'ABC ${_effectiveVictims.length + 1}';

    setState(() {
      _effectiveVictims.add(PocsoVictimData(anonymizedName: nextName));
    });
    _notifyVictimNames();
  }

  void _removeVictim(int index) {
    if (_effectiveVictims.length <= 1) return;
    setState(() {
      final removed = _effectiveVictims.removeAt(index);
      removed.dispose();
    });
    _notifyVictimNames();
  }

  /// Calculates dynamic sequential ABC options (ABC 1, ABC 2, ...) from system records.
  List<String> _generateAnonymizedVictimOptions() {
    int maxN = 0;
    try {
      final pocsoProv = context.read<PocsoProvider>();
      final re = RegExp(r'ABC\s*(\d+)', caseSensitive: false);
      for (final r in pocsoProv.records) {
        final extra = r.extraFields;
        final pExtra = extra['pocso_extra'];
        if (pExtra is Map) {
          final vList = pExtra['victims'];
          if (vList is List) {
            for (final v in vList) {
              if (v is Map) {
                final vName = v['anonymizedVictimName']?.toString() ?? '';
                final m = re.firstMatch(vName);
                if (m != null) {
                  final n = int.tryParse(m.group(1) ?? '0') ?? 0;
                  if (n > maxN) maxN = n;
                }
              }
            }
          }
          final vName = pExtra['anonymizedVictimName']?.toString() ?? '';
          final m = re.firstMatch(vName);
          if (m != null) {
            final n = int.tryParse(m.group(1) ?? '0') ?? 0;
            if (n > maxN) maxN = n;
          }
        }
        final m = re.firstMatch(r.title);
        if (m != null) {
          final n = int.tryParse(m.group(1) ?? '0') ?? 0;
          if (n > maxN) maxN = n;
        }
      }
    } catch (_) {}

    // Include any currently selected options in _effectiveVictims
    for (final v in _effectiveVictims) {
      if (v.anonymizedName != null) {
        final m = RegExp(r'ABC\s*(\d+)', caseSensitive: false)
            .firstMatch(v.anonymizedName!);
        if (m != null) {
          final n = int.tryParse(m.group(1) ?? '0') ?? 0;
          if (n > maxN) maxN = n;
        }
      }
    }

    final totalCount = maxN + 10;
    final list = <String>[];
    for (int i = 1; i <= (totalCount > 10 ? totalCount : 10); i++) {
      list.add('ABC $i');
    }
    return list;
  }

  // ── Serialization & Hydration ──────────────────────────────────────────────

  Map<String, dynamic> collectData() {
    final primaryVictim =
        _effectiveVictims.isNotEmpty ? _effectiveVictims.first : null;
    return {
      'bnsSections': _bnsSections.toList(),
      'pocsoSections': _pocsoSections.toList(),
      'victims': _effectiveVictims
          .map((v) => {
                'anonymizedVictimName': v.anonymizedName ?? '',
                'victimAge': v.ageController.text.trim(),
                'ageProof': v.ageProof ?? '',
              })
          .toList(),
      'anonymizedVictimName': primaryVictim?.anonymizedName ?? '',
      'victimAge': primaryVictim?.ageController.text.trim() ?? '',
      'ageProof': primaryVictim?.ageProof ?? '',
      'medicalVictim': _medicalVictim,
      'medicalAccused': _medicalAccused,
      'stmtVictim': _stmtVictim,
      'stmtLadyOfficer': _stmtLadyOfficer,
      'stmtCwc': _stmtCwc,
      'stmt164Bnss': _stmt164Bnss,
      'counselling': _counselling,
      'dnaVictimTaken': _dnaVictimTaken,
      'dnaVictimSentFsl': _dnaVictimSentFsl,
      'dnaVictimFslReport': _dnaVictimFslReport,
      'dnaAccusedTaken': _dnaAccusedTaken,
      'dnaAccusedSentFsl': _dnaAccusedSentFsl,
      'dnaAccusedFslReport': _dnaAccusedFslReport,
    };
  }

  void hydrateFrom(Map<dynamic, dynamic>? data) {
    if (data == null) return;
    final bnsRaw = data['bnsSections'];
    if (bnsRaw is List) {
      _bnsSections.clear();
      _bnsSections.addAll(bnsRaw.map((e) => e.toString()));
    }
    final pocsoRaw = data['pocsoSections'];
    if (pocsoRaw is List) {
      _pocsoSections.clear();
      _pocsoSections.addAll(pocsoRaw.map((e) => e.toString()));
    }

    final rawVictims = data['victims'];
    if (rawVictims is List && rawVictims.isNotEmpty) {
      for (final v in _effectiveVictims) {
        v.dispose();
      }
      _effectiveVictims.clear();
      for (final v in rawVictims) {
        if (v is Map) {
          _effectiveVictims.add(PocsoVictimData(
            anonymizedName: v['anonymizedVictimName']?.toString(),
            initialAge: v['victimAge']?.toString() ?? '',
            ageProof: v['ageProof']?.toString(),
          ));
        }
      }
    } else if (data['anonymizedVictimName'] != null ||
        data['victimAge'] != null) {
      for (final v in _effectiveVictims) {
        v.dispose();
      }
      _effectiveVictims.clear();
      _effectiveVictims.add(PocsoVictimData(
        anonymizedName: data['anonymizedVictimName']?.toString(),
        initialAge: data['victimAge']?.toString() ?? '',
        ageProof: data['ageProof']?.toString(),
      ));
    }
    if (_effectiveVictims.isEmpty) {
      _effectiveVictims.add(PocsoVictimData());
    }

    _medicalVictim = data['medicalVictim']?.toString();
    _medicalAccused = data['medicalAccused']?.toString();
    _stmtVictim = data['stmtVictim']?.toString();
    _stmtLadyOfficer = data['stmtLadyOfficer']?.toString();
    _stmtCwc = data['stmtCwc']?.toString();
    _stmt164Bnss = data['stmt164Bnss']?.toString();
    _counselling = data['counselling']?.toString();
    _dnaVictimTaken = data['dnaVictimTaken']?.toString();
    _dnaVictimSentFsl = data['dnaVictimSentFsl']?.toString();
    _dnaVictimFslReport = data['dnaVictimFslReport']?.toString();
    _dnaAccusedTaken = data['dnaAccusedTaken']?.toString();
    _dnaAccusedSentFsl = data['dnaAccusedSentFsl']?.toString();
    _dnaAccusedFslReport = data['dnaAccusedFslReport']?.toString();

    if (mounted) setState(() {});
  }

  // ── UI Helper Widgets ──────────────────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required Widget content,
    IconData? icon,
    Widget? action,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: _kTeal),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _kDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _yesNoChip(
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : _kInputBg,
          border: Border.all(
            color: selected ? color : _kBorder,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? color : _kSec,
          ),
        ),
      ),
    );
  }

  Widget _yesNoRow({
    required String title,
    required String? value,
    required ValueChanged<String?> onSelect,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kInputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kDark,
              ),
            ),
          ),
          _yesNoChip('Yes', value == 'yes', _kGreen, () {
            onSelect('yes');
          }),
          const SizedBox(width: 8),
          _yesNoChip('No', value == 'no', _kRed, () {
            onSelect('no');
          }),
        ],
      ),
    );
  }

  // ── 1. Legal Sections: BNS & POCSO ─────────────────────────────────────────
  Widget _buildLegalSections() {
    final bnsItems = (ACT_DATA['BNS']?['sections'] as List<dynamic>? ?? [])
        .map((s) => s as Map<String, dynamic>)
        .toList();
    final pocsoItems = (ACT_DATA['POCSO']?['sections'] as List<dynamic>? ?? [])
        .map((s) => s as Map<String, dynamic>)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BNS Selector
        const Text(
          'BNS ACT & SECTIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _kSec,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Select BNS Section to add...',
            hintStyle: const TextStyle(fontSize: 12, color: _kMuted),
            fillColor: _kInputBg,
            filled: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBorder),
            ),
          ),
          items: bnsItems.map((s) {
            final val = s['val'].toString();
            final label = s['label']?.toString() ?? val;
            return DropdownMenuItem<String>(
              value: val,
              child: Text(label, style: const TextStyle(fontSize: 12)),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null && !_bnsSections.contains(v)) {
              setState(() => _bnsSections.add(v));
            }
          },
        ),
        if (_bnsSections.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _bnsSections.map((sec) {
              return Chip(
                backgroundColor: _kTeal.withValues(alpha: 0.12),
                side: const BorderSide(color: _kTeal),
                label: Text(
                  'BNS $sec',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kTeal,
                  ),
                ),
                deleteIcon: const Icon(Icons.close, size: 14, color: _kTeal),
                onDeleted: () => setState(() => _bnsSections.remove(sec)),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 14),

        // POCSO Selector
        const Text(
          'POCSO ACT & SECTIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _kSec,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Select POCSO Section to add...',
            hintStyle: const TextStyle(fontSize: 12, color: _kMuted),
            fillColor: _kInputBg,
            filled: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBorder),
            ),
          ),
          items: pocsoItems.map((s) {
            final val = s['val'].toString();
            final label = s['label']?.toString() ?? val;
            return DropdownMenuItem<String>(
              value: val,
              child: Text(label, style: const TextStyle(fontSize: 12)),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null && !_pocsoSections.contains(v)) {
              setState(() => _pocsoSections.add(v));
            }
          },
        ),
        if (_pocsoSections.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _pocsoSections.map((sec) {
              return Chip(
                backgroundColor:
                    const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                side: const BorderSide(color: Color(0xFF8B5CF6)),
                label: Text(
                  'POCSO $sec',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                deleteIcon:
                    const Icon(Icons.close, size: 14, color: Color(0xFF8B5CF6)),
                onDeleted: () => setState(() => _pocsoSections.remove(sec)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ── 2. Victim Identity (Strictly Anonymized Dropdown) ───────────────────────
  Widget _buildVictimIdentity() {
    final primaryVictim =
        _effectiveVictims.isNotEmpty ? _effectiveVictims.first : null;
    final options = _generateAnonymizedVictimOptions();
    if (primaryVictim?.anonymizedName != null &&
        !options.contains(primaryVictim!.anonymizedName)) {
      options.add(primaryVictim.anonymizedName!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined,
                  size: 14, color: Color(0xFFB45309)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'MANDATORY: Victim identity is anonymized (ABC 1, ABC 2, ...). Free-text is prohibited.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ),
        DropdownButtonFormField<String>(
          key: ValueKey(
              'pocso_victim_name_primary_${primaryVictim?.anonymizedName}'),
          initialValue: primaryVictim?.anonymizedName,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Primary Victim Name (Anonymized)',
            labelStyle: const TextStyle(fontSize: 12, color: _kSec),
            fillColor: _kInputBg,
            filled: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBorder),
            ),
          ),
          items: options.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(
                opt,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                if (_effectiveVictims.isEmpty) {
                  _effectiveVictims.add(PocsoVictimData(anonymizedName: val));
                } else {
                  _effectiveVictims[0].anonymizedName = val;
                }
              });
              _notifyVictimNames();
            }
          },
        ),
      ],
    );
  }

  // ── 3. Victim Details (Multiple Victims Support) ───────────────────────────
  Widget _buildVictimDetails() {
    final options = _generateAnonymizedVictimOptions();
    final victims = _effectiveVictims;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < victims.length; i++) ...[
          Builder(
            builder: (context) {
              final victim = victims[i];
              final optList = List<String>.from(options);
              if (victim.anonymizedName != null &&
                  !optList.contains(victim.anonymizedName)) {
                optList.add(victim.anonymizedName!);
              }

              return Container(
                margin:
                    EdgeInsets.only(bottom: i == victims.length - 1 ? 0 : 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kInputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield_outlined,
                                  size: 13, color: _kTeal),
                              const SizedBox(width: 5),
                              Text(
                                'Victim #${i + 1} (${victim.anonymizedName ?? 'ABC ${i + 1}'})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _kTeal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (victims.length > 1)
                          InkWell(
                            onTap: () => _removeVictim(i),
                            borderRadius: BorderRadius.circular(16),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline,
                                      size: 16, color: _kRed),
                                  SizedBox(width: 2),
                                  Text(
                                    'Remove',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _kRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Victim Name Dropdown (Strictly Non-Editable / Anonymized Dropdown)
                    DropdownButtonFormField<String>(
                      key:
                          ValueKey('victim_name_${i}_${victim.anonymizedName}'),
                      initialValue: victim.anonymizedName,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Victim Name (Anonymized)',
                        labelStyle: const TextStyle(fontSize: 12, color: _kSec),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: _kBorder),
                        ),
                      ),
                      items: optList.map((opt) {
                        return DropdownMenuItem<String>(
                          value: opt,
                          child: Text(
                            opt,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _kDark,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => victim.anonymizedName = val);
                          _notifyVictimNames();
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Age field (numeric 2-digit)
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: victim.ageController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Age of Victim (2-digit)',
                              labelStyle:
                                  const TextStyle(fontSize: 12, color: _kSec),
                              hintText: 'e.g. 14',
                              hintStyle:
                                  const TextStyle(fontSize: 12, color: _kMuted),
                              fillColor: Colors.white,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: _kBorder),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Age Proof
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('age_proof_${i}_${victim.ageProof}'),
                            initialValue: victim.ageProof,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Age Proof',
                              labelStyle:
                                  const TextStyle(fontSize: 12, color: _kSec),
                              hintText: 'Select Age Proof',
                              hintStyle:
                                  const TextStyle(fontSize: 12, color: _kMuted),
                              fillColor: Colors.white,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: _kBorder),
                              ),
                            ),
                            items: kAgeProofOptions.map((opt) {
                              return DropdownMenuItem<String>(
                                value: opt,
                                child: Text(opt,
                                    style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => victim.ageProof = val),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _addVictimButton() {
    return InkWell(
      onTap: _addVictim,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _kTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kTeal.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: _kTeal),
            SizedBox(width: 4),
            Text(
              '+ Add Victim',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _kTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Medical Examination ────────────────────────────────────────────────
  Widget _buildMedical() {
    return Column(
      children: [
        _yesNoRow(
          title: 'Medical of Victim',
          value: _medicalVictim,
          onSelect: (v) => setState(() => _medicalVictim = v),
        ),
        _yesNoRow(
          title: 'Medical of Accused',
          value: _medicalAccused,
          onSelect: (v) => setState(() => _medicalAccused = v),
        ),
      ],
    );
  }

  // ── 5. Statements & Counselling ───────────────────────────────────────────
  Widget _buildStatements() {
    return Column(
      children: [
        _yesNoRow(
          title: "Victim's Statement",
          value: _stmtVictim,
          onSelect: (v) => setState(() => _stmtVictim = v),
        ),
        _yesNoRow(
          title: 'Statement Taken by Lady Officer',
          value: _stmtLadyOfficer,
          onSelect: (v) => setState(() => _stmtLadyOfficer = v),
        ),
        _yesNoRow(
          title: 'CWC Statement',
          value: _stmtCwc,
          onSelect: (v) => setState(() => _stmtCwc = v),
        ),
        _yesNoRow(
          title: '164 CrPC / 183 BNSS Statement',
          value: _stmt164Bnss,
          onSelect: (v) => setState(() => _stmt164Bnss = v),
        ),
        _yesNoRow(
          title: 'Counselling',
          value: _counselling,
          onSelect: (v) => setState(() => _counselling = v),
        ),
      ],
    );
  }

  // ── 6. DNA / FSL — Victim ──────────────────────────────────────────────────
  Widget _buildDnaVictim() {
    return Column(
      children: [
        _yesNoRow(
          title: 'DNA Sample of Victim Taken',
          value: _dnaVictimTaken,
          onSelect: (v) => setState(() => _dnaVictimTaken = v),
        ),
        _yesNoRow(
          title: 'Sent to FSL',
          value: _dnaVictimSentFsl,
          onSelect: (v) => setState(() => _dnaVictimSentFsl = v),
        ),
        _yesNoRow(
          title: 'FSL Report Received',
          value: _dnaVictimFslReport,
          onSelect: (v) => setState(() => _dnaVictimFslReport = v),
        ),
      ],
    );
  }

  // ── 7. DNA / FSL — Accused ─────────────────────────────────────────────────
  Widget _buildDnaAccused() {
    return Column(
      children: [
        _yesNoRow(
          title: 'DNA Sample of Accused Taken',
          value: _dnaAccusedTaken,
          onSelect: (v) => setState(() => _dnaAccusedTaken = v),
        ),
        _yesNoRow(
          title: 'Sent to FSL',
          value: _dnaAccusedSentFsl,
          onSelect: (v) => setState(() => _dnaAccusedSentFsl = v),
        ),
        _yesNoRow(
          title: 'FSL Report Received',
          value: _dnaAccusedFslReport,
          onSelect: (v) => setState(() => _dnaAccusedFslReport = v),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionCard(
          title: 'POCSO: LEGAL SECTIONS',
          icon: Icons.gavel_rounded,
          content: _buildLegalSections(),
        ),
        _sectionCard(
          title: 'POCSO: VICTIM IDENTITY (ANONYMIZED)',
          icon: Icons.person_pin_circle_outlined,
          content: _buildVictimIdentity(),
        ),
        _sectionCard(
          title: 'POCSO: VICTIM DETAILS',
          icon: Icons.badge_outlined,
          action: _addVictimButton(),
          content: _buildVictimDetails(),
        ),
        _sectionCard(
          title: 'POCSO: MEDICAL EXAMINATION',
          icon: Icons.local_hospital_outlined,
          content: _buildMedical(),
        ),
        _sectionCard(
          title: 'POCSO: STATEMENTS & COUNSELLING',
          icon: Icons.record_voice_over_outlined,
          content: _buildStatements(),
        ),
        _sectionCard(
          title: 'POCSO: DNA / FSL — VICTIM',
          icon: Icons.biotech_outlined,
          content: _buildDnaVictim(),
        ),
        _sectionCard(
          title: 'POCSO: DNA / FSL — ACCUSED',
          icon: Icons.biotech_outlined,
          content: _buildDnaAccused(),
        ),
      ],
    );
  }
}
