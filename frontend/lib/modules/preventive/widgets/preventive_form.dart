// lib/modules/preventive/widgets/preventive_form.dart
// Dedicated Preventive & Istegasha Entry Form matching Form 1 to 5 styling.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../screens/ad_form_screen.dart' show ACT_DATA;
import '../../../widgets/voice_dictation_button.dart';

// ── Palette matching Form 1 to 5 design system ──────────────────────────────
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

/// Accused entry model for Preventive Form
class PreventiveAccusedEntry {
  final TextEditingController name = TextEditingController();
  String actionType = 'Arrested'; // 'Arrested', 'Notice Issued', 'Not Arrested'
  String bondTaken = 'No'; // 'Yes', 'No'
  final TextEditingController bondDetails = TextEditingController();

  void dispose() {
    name.dispose();
    bondDetails.dispose();
  }

  void clear() {
    name.clear();
    actionType = 'Arrested';
    bondTaken = 'No';
    bondDetails.clear();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.text.trim(),
      'actionType': actionType,
      'bondTaken': bondTaken,
      'bondDetails': bondDetails.text.trim(),
    };
  }

  void fromMap(Map<String, dynamic> m) {
    name.text = m['name']?.toString() ?? '';
    actionType = m['actionType']?.toString() ?? 'Arrested';
    bondTaken = m['bondTaken']?.toString() ?? 'No';
    bondDetails.text = m['bondDetails']?.toString() ?? '';
  }
}

class PreventiveForm extends StatefulWidget {
  final VoidCallback? onSave;
  final VoidCallback? onExportPdf;
  final bool readOnly;

  const PreventiveForm({
    super.key,
    this.onSave,
    this.onExportPdf,
    this.readOnly = false,
  });

  @override
  State<PreventiveForm> createState() => PreventiveFormState();
}

class PreventiveFormState extends State<PreventiveForm> {
  late final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> scrollProgress = ValueNotifier(0);
  String saveBarText = 'All changes unsaved';

  // 1. Case & Crime Reference
  final _crimeNoCtrl = TextEditingController();
  final _regDateCtrl = TextEditingController();
  String _crimeCategory = 'Theft';
  final _customCrimeCategoryCtrl = TextEditingController();
  String _caseStatus = 'Under Investigation';

  // 2. Sections & Acts
  String _selectedAct = 'BNS';
  final List<String> _selectedSections = [];
  final _sectionSearchCtrl = TextEditingController();
  final _otherSectionsCtrl = TextEditingController();

  // 3. Accused list
  final List<PreventiveAccusedEntry> _accusedEntries = [
    PreventiveAccusedEntry()
  ];

  // 4. Preventive / Istegasha Details
  final _preventiveNoCtrl = TextEditingController();
  final _preventiveDateCtrl = TextEditingController();
  final _outwardNoCtrl = TextEditingController();
  final _ioNameCtrl = TextEditingController();

  // 5. Risk Flag & Action Status
  String _riskFlag = '🚨 High Priority'; // '🚨 High Priority', '🛑 Sensitive'
  String _preventiveActionStatus = '🟢 Preventive Action Completed';
  // '🟢 Preventive Action Completed', '🟡 Partially Completed', '🔴 No Preventive Action Recorded'
  final _remarksCtrl = TextEditingController();

  static const List<String> _kCrimeCategories = [
    'Theft',
    'Assault',
    'Cyber',
    'POCSO',
    'NDPS',
    'Hurt',
    'Murder',
    'Robbery',
    'Gambling',
    'Prohibition',
    'Other',
  ];

  static const List<String> _kCaseStatuses = [
    'Under Investigation',
    'Chargesheeted',
  ];

  static const List<String> _kRiskFlags = [
    '🚨 High Priority',
    '🛑 Sensitive',
  ];

  static const List<String> _kActionStatuses = [
    '🟢 Preventive Action Completed',
    '🟡 Partially Completed',
    '🔴 No Preventive Action Recorded',
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      scrollProgress.value =
          max > 0 ? (_scroll.offset / max).clamp(0.0, 1.0) : 0;
    });

    // Default dates
    final now = DateTime.now();
    _regDateCtrl.text = DateFormat('dd/MM/yyyy').format(now);
    _preventiveDateCtrl.text = DateFormat('dd/MM/yyyy').format(now);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _crimeNoCtrl.dispose();
    _regDateCtrl.dispose();
    _customCrimeCategoryCtrl.dispose();
    _sectionSearchCtrl.dispose();
    _otherSectionsCtrl.dispose();
    for (final a in _accusedEntries) {
      a.dispose();
    }
    _preventiveNoCtrl.dispose();
    _preventiveDateCtrl.dispose();
    _outwardNoCtrl.dispose();
    _ioNameCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  // ── Accused list helpers ───────────────────────────────────────────────────
  void _addAccused() {
    if (widget.readOnly) return;
    setState(() {
      _accusedEntries.add(PreventiveAccusedEntry());
      _markUnsaved();
    });
  }

  void _removeAccused(int index) {
    if (widget.readOnly || _accusedEntries.length <= 1) return;
    setState(() {
      final removed = _accusedEntries.removeAt(index);
      removed.dispose();
      _markUnsaved();
    });
  }

  void _markUnsaved() {
    if (saveBarText != 'All changes unsaved') {
      setState(() => saveBarText = 'All changes unsaved');
    }
  }

  // ── Public Data Serialization & Hydration ──────────────────────────────────
  Map<String, dynamic> buildDocumentMap() {
    final effectiveCategory = _crimeCategory == 'Other' &&
            _customCrimeCategoryCtrl.text.trim().isNotEmpty
        ? _customCrimeCategoryCtrl.text.trim()
        : _crimeCategory;

    return {
      'caseRef': {
        'crimeNo': _crimeNoCtrl.text.trim(),
        'regDate': _regDateCtrl.text.trim(),
        'crimeCategory': effectiveCategory,
        'caseStatus': _caseStatus,
      },
      'sections': {
        'act': _selectedAct,
        'selectedSections': List<String>.from(_selectedSections),
        'otherSections': _otherSectionsCtrl.text.trim(),
      },
      'accusedList': _accusedEntries.map((a) => a.toMap()).toList(),
      'istegasha': {
        'preventiveNo': _preventiveNoCtrl.text.trim(),
        'preventiveDate': _preventiveDateCtrl.text.trim(),
        'outwardNo': _outwardNoCtrl.text.trim(),
        'ioName': _ioNameCtrl.text.trim(),
      },
      'riskAndStatus': {
        'riskFlag': _riskFlag,
        'actionStatus': _preventiveActionStatus,
        'remarks': _remarksCtrl.text.trim(),
      },
      // Convenience root fields for instant list indexing
      'crimeNo': _crimeNoCtrl.text.trim(),
      'caseNumber': _crimeNoCtrl.text.trim(),
      'preventiveNo': _preventiveNoCtrl.text.trim(),
      'accusedNames': _accusedEntries
          .map((a) => a.name.text.trim())
          .where((n) => n.isNotEmpty)
          .join(', '),
      'ioName': _ioNameCtrl.text.trim(),
      'assignedOfficer': _ioNameCtrl.text.trim(),
      'priority': _riskFlag,
      'status': _caseStatus,
      'actionStatus': _preventiveActionStatus,
    };
  }

  void hydrateFromDocumentMap(Map<String, dynamic> doc) {
    final formMap = (doc['preventiveForm'] is Map<String, dynamic>)
        ? doc['preventiveForm'] as Map<String, dynamic>
        : doc;

    final caseRef = formMap['caseRef'] as Map<String, dynamic>? ?? {};
    final sections = formMap['sections'] as Map<String, dynamic>? ?? {};
    final accusedList = formMap['accusedList'] as List<dynamic>? ?? [];
    final istegasha = formMap['istegasha'] as Map<String, dynamic>? ?? {};
    final riskAndStatus =
        formMap['riskAndStatus'] as Map<String, dynamic>? ?? {};

    setState(() {
      _crimeNoCtrl.text = caseRef['crimeNo']?.toString() ??
          doc['crimeNo']?.toString() ??
          doc['caseNumber']?.toString() ??
          doc['case_number']?.toString() ??
          '';
      _regDateCtrl.text = caseRef['regDate']?.toString() ?? '';

      final cat = caseRef['crimeCategory']?.toString() ?? 'Theft';
      if (_kCrimeCategories.contains(cat)) {
        _crimeCategory = cat;
        _customCrimeCategoryCtrl.clear();
      } else {
        _crimeCategory = 'Other';
        _customCrimeCategoryCtrl.text = cat;
      }

      final st =
          caseRef['caseStatus']?.toString() ?? doc['status']?.toString() ?? '';
      if (_kCaseStatuses.contains(st)) {
        _caseStatus = st;
      }

      _selectedAct = sections['act']?.toString() ?? 'BNS';
      _selectedSections.clear();
      if (sections['selectedSections'] is List) {
        _selectedSections.addAll(
          (sections['selectedSections'] as List).map((e) => e.toString()),
        );
      }
      _otherSectionsCtrl.text = sections['otherSections']?.toString() ?? '';

      for (final a in _accusedEntries) {
        a.dispose();
      }
      _accusedEntries.clear();
      if (accusedList.isNotEmpty) {
        for (final item in accusedList) {
          if (item is Map) {
            final entry = PreventiveAccusedEntry();
            entry.fromMap(Map<String, dynamic>.from(item));
            _accusedEntries.add(entry);
          }
        }
      }
      if (_accusedEntries.isEmpty) {
        final legacyAccused =
            doc['accused']?.toString() ?? doc['accusedNames']?.toString() ?? '';
        final entry = PreventiveAccusedEntry();
        entry.name.text = legacyAccused;
        _accusedEntries.add(entry);
      }

      _preventiveNoCtrl.text = istegasha['preventiveNo']?.toString() ??
          doc['preventiveNo']?.toString() ??
          '';
      _preventiveDateCtrl.text = istegasha['preventiveDate']?.toString() ?? '';
      _outwardNoCtrl.text = istegasha['outwardNo']?.toString() ?? '';
      _ioNameCtrl.text = istegasha['ioName']?.toString() ??
          doc['assignedOfficer']?.toString() ??
          doc['assigned_officer']?.toString() ??
          '';

      final rf = riskAndStatus['riskFlag']?.toString() ??
          doc['priority']?.toString() ??
          '';
      if (_kRiskFlags.contains(rf)) {
        _riskFlag = rf;
      } else if (rf.toLowerCase().contains('high')) {
        _riskFlag = '🚨 High Priority';
      } else if (rf.toLowerCase().contains('sensitive')) {
        _riskFlag = '🛑 Sensitive';
      }

      final actSt = riskAndStatus['actionStatus']?.toString() ??
          doc['actionStatus']?.toString() ??
          '';
      if (_kActionStatuses.contains(actSt)) {
        _preventiveActionStatus = actSt;
      } else if (actSt.toLowerCase().contains('partial')) {
        _preventiveActionStatus = '🟡 Partially Completed';
      } else if (actSt.toLowerCase().contains('no')) {
        _preventiveActionStatus = '🔴 No Preventive Action Recorded';
      }

      _remarksCtrl.text = riskAndStatus['remarks']?.toString() ??
          doc['description']?.toString() ??
          '';
      saveBarText = 'Saved';
    });
  }

  void clearForm() {
    if (widget.readOnly) return;
    setState(() {
      _crimeNoCtrl.clear();
      _regDateCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      _crimeCategory = 'Theft';
      _customCrimeCategoryCtrl.clear();
      _caseStatus = 'Under Investigation';
      _selectedAct = 'BNS';
      _selectedSections.clear();
      _sectionSearchCtrl.clear();
      _otherSectionsCtrl.clear();
      for (final a in _accusedEntries) {
        a.dispose();
      }
      _accusedEntries.clear();
      _accusedEntries.add(PreventiveAccusedEntry());
      _preventiveNoCtrl.clear();
      _preventiveDateCtrl.text =
          DateFormat('dd/MM/yyyy').format(DateTime.now());
      _outwardNoCtrl.clear();
      _ioNameCtrl.clear();
      _riskFlag = '🚨 High Priority';
      _preventiveActionStatus = '🟢 Preventive Action Completed';
      _remarksCtrl.clear();
      saveBarText = 'Form cleared';
    });
  }

  // ── Date Picker Helper ─────────────────────────────────────────────────────
  Future<void> _pickDate(TextEditingController ctrl) async {
    if (widget.readOnly) return;
    DateTime initial = DateTime.now();
    try {
      if (ctrl.text.trim().isNotEmpty) {
        final parts = ctrl.text.trim().split('/');
        if (parts.length == 3) {
          initial = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1980),
      lastDate: DateTime(2040),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kTeal,
              onPrimary: Colors.white,
              onSurface: _kDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        ctrl.text = DateFormat('dd/MM/yyyy').format(picked);
        _markUnsaved();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Progress Bar
        ValueListenableBuilder<double>(
          valueListenable: scrollProgress,
          builder: (_, p, __) => LinearProgressIndicator(
            value: p,
            minHeight: 3,
            backgroundColor: _kBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(_kTeal),
          ),
        ),

        // Sub-Header Bar (Save state + Quick Action buttons)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  saveBarText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _kSec,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                if (!widget.readOnly) ...[
                  OutlinedButton.icon(
                    onPressed: clearForm,
                    icon:
                        const Icon(Icons.refresh_rounded, size: 14, color: _kSec),
                    label: Text('Clear',
                        style: GoogleFonts.inter(fontSize: 12, color: _kSec)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _kBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => saveBarText = 'Draft saved locally');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Draft saved locally'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_as_rounded,
                        size: 14, color: _kTeal),
                    label: Text('Save Draft',
                        style: GoogleFonts.inter(fontSize: 12, color: _kTeal)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _kTeal),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton.icon(
                  onPressed: widget.onExportPdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded,
                      size: 14, color: _kTeal),
                  label: Text('Generate Preventive Form PDF',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _kTeal,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _kTeal, width: 1.2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
        ),

        const Divider(height: 1, color: _kBorder),

        // Scrollable Form Content
        Expanded(
          child: Container(
            color: _kPageBg,
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Case & Crime Reference
                      _buildCard(
                        secNum: '1',
                        title: 'Case & Crime Reference',
                        marathiTitle: 'गुन्हा व खटला संदर्भ',
                        icon: Icons.folder_copy_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildTextField(
                                    label: 'Crime No. / FIR No. / NC no. *',
                                    hint: 'e.g. 142/2026 or NC 88/2026',
                                    controller: _crimeNoCtrl,
                                    required: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: _buildDateField(
                                    label: 'Registration Date *',
                                    controller: _regDateCtrl,
                                    onTap: () => _pickDate(_regDateCtrl),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Crime Category
                            _buildLabel('Crime Category (गुन्ह्याचा प्रकार)'),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _kCrimeCategories.map((cat) {
                                final isSelected = _crimeCategory == cat;
                                return ChoiceChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: widget.readOnly
                                      ? null
                                      : (val) {
                                          if (val) {
                                            setState(() {
                                              _crimeCategory = cat;
                                              _markUnsaved();
                                            });
                                          }
                                        },
                                  selectedColor: _kTeal.withValues(alpha: 0.15),
                                  backgroundColor: _kInputBg,
                                  side: BorderSide(
                                    color: isSelected ? _kTeal : _kBorder,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  labelStyle: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected ? _kTeal : _kDark,
                                  ),
                                );
                              }).toList(),
                            ),
                            if (_crimeCategory == 'Other') ...[
                              const SizedBox(height: 10),
                              _buildTextField(
                                label: 'Specify Other Category',
                                hint: 'Enter crime category',
                                controller: _customCrimeCategoryCtrl,
                              ),
                            ],
                            const SizedBox(height: 14),

                            // Case Status
                            _buildLabel('Case Status (खटल्याची स्थिती)'),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _kCaseStatuses.map((st) {
                                final isSelected = _caseStatus == st;
                                return ChoiceChip(
                                  label: Text(st),
                                  selected: isSelected,
                                  onSelected: widget.readOnly
                                      ? null
                                      : (val) {
                                          if (val) {
                                            setState(() {
                                              _caseStatus = st;
                                              _markUnsaved();
                                            });
                                          }
                                        },
                                  selectedColor: const Color(0xFFE0E7FF),
                                  backgroundColor: _kInputBg,
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFF4F46E5)
                                        : _kBorder,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  labelStyle: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF4F46E5)
                                        : _kDark,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section 2: Sections & Acts Filter
                      _buildCard(
                        secNum: '2',
                        title: 'Sections & Acts (filter by section)',
                        marathiTitle: 'कलमे व कायदे (BNS / इतर कायदे)',
                        icon: Icons.gavel_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Act Selector Chips
                            _buildLabel('Select Act / कायदे निवडा'),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ACT_DATA.keys.map((actKey) {
                                  final actInfo = ACT_DATA[actKey];
                                  final label = actInfo?['label'] ?? actKey;
                                  final isSelected = _selectedAct == actKey;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(label),
                                      selected: isSelected,
                                      onSelected: widget.readOnly
                                          ? null
                                          : (val) {
                                              if (val) {
                                                setState(() {
                                                  _selectedAct = actKey;
                                                  _markUnsaved();
                                                });
                                              }
                                            },
                                      selectedColor:
                                          _kTeal.withValues(alpha: 0.15),
                                      backgroundColor: _kInputBg,
                                      side: BorderSide(
                                        color: isSelected ? _kTeal : _kBorder,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                      labelStyle: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected ? _kTeal : _kDark,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Filter / Search section
                            _buildTextField(
                              label: 'Search Sections in $_selectedAct',
                              hint:
                                  'Type section number or name to filter (e.g. 100, 303, hurt)...',
                              controller: _sectionSearchCtrl,
                              onChanged: (_) => setState(() {}),
                              prefixIcon: Icons.search_rounded,
                            ),
                            const SizedBox(height: 10),

                            // Filtered Sections Grid / Chips
                            _buildSectionPickerChips(),
                            const SizedBox(height: 12),

                            // Selected Sections Badges
                            if (_selectedSections.isNotEmpty) ...[
                              _buildLabel('Selected Sections:'),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _selectedSections.map((sec) {
                                  return Chip(
                                    label: Text(
                                      '$_selectedAct $sec',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _kDark,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFFEEF2FF),
                                    side: const BorderSide(
                                        color: Color(0xFFC7D2FE)),
                                    deleteIcon: widget.readOnly
                                        ? null
                                        : const Icon(Icons.close_rounded,
                                            size: 14, color: _kRed),
                                    onDeleted: widget.readOnly
                                        ? null
                                        : () {
                                            setState(() {
                                              _selectedSections.remove(sec);
                                              _markUnsaved();
                                            });
                                          },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Other Acts / Custom Sections textfield
                            _buildTextField(
                              label: 'Other Acts / Custom Sections (इतर कलमे)',
                              hint:
                                  'e.g. Sec 110/117 BNSS, Sec 107 CrPC, Sec 56/57 MP Act',
                              controller: _otherSectionsCtrl,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section 3: Accused & Action Details
                      _buildCard(
                        secNum: '3',
                        title: 'Accused & Preventive Action Details',
                        marathiTitle: 'आरोपी व प्रतिबंधक कारवाई तपशील',
                        icon: Icons.people_alt_rounded,
                        trailing: widget.readOnly
                            ? null
                            : ElevatedButton.icon(
                                onPressed: _addAccused,
                                icon: const Icon(Icons.person_add_alt_1_rounded,
                                    size: 14, color: Colors.white),
                                label: Text(
                                  '+ Add Accused',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _kTeal,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < _accusedEntries.length; i++)
                              _buildAccusedRowCard(i, _accusedEntries[i]),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section 4: Preventive & Istegasha Details
                      _buildCard(
                        secNum: '4',
                        title: 'Preventive & Istegasha Details',
                        marathiTitle: 'प्रतिबंधक / इस्तेगाशा तपशील',
                        icon: Icons.shield_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Preventive No. / इस्तेगाशा नंबर *',
                                    hint: 'e.g. IST/04/2026 or Prev No. 12',
                                    controller: _preventiveNoCtrl,
                                    required: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDateField(
                                    label: 'Date of Preventive *',
                                    controller: _preventiveDateCtrl,
                                    onTap: () => _pickDate(_preventiveDateCtrl),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Outward Number (जावक क्रमांक)',
                                    hint: 'e.g. OW/PS/452/2026',
                                    controller: _outwardNoCtrl,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    label:
                                        'Investigating Officer (IO) / अमलदार',
                                    hint: 'e.g. PSI Patil / ASI Deshmukh',
                                    controller: _ioNameCtrl,
                                    suffix: VoiceDictationButton(
                                      controller: _ioNameCtrl,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section 5: Risk Flag & Action Status
                      _buildCard(
                        secNum: '5',
                        title: 'Risk Flag & Preventive Action Status',
                        marathiTitle: 'जोखीम ध्वज व कारवाई स्थिती',
                        icon: Icons.warning_amber_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Risk Flag Chips
                            _buildLabel('Risk Flag (जोखीम वर्ग)'),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: _kRiskFlags.map((flag) {
                                final isSelected = _riskFlag == flag;
                                final isHigh = flag.contains('High');
                                final isSensitive = flag.contains('Sensitive');

                                Color activeBg = _kTeal.withValues(alpha: 0.12);
                                Color activeBorder = _kTeal;
                                Color activeText = _kTeal;

                                if (isHigh) {
                                  activeBg = const Color(0xFFFEE2E2);
                                  activeBorder = _kRed;
                                  activeText = _kRed;
                                } else if (isSensitive) {
                                  activeBg = const Color(0xFFFEF3C7);
                                  activeBorder = _kAmber;
                                  activeText = const Color(0xFFD97706);
                                }

                                return ChoiceChip(
                                  label: Text(flag),
                                  selected: isSelected,
                                  onSelected: widget.readOnly
                                      ? null
                                      : (val) {
                                          if (val) {
                                            setState(() {
                                              _riskFlag = flag;
                                              _markUnsaved();
                                            });
                                          }
                                        },
                                  selectedColor: activeBg,
                                  backgroundColor: _kInputBg,
                                  side: BorderSide(
                                    color: isSelected ? activeBorder : _kBorder,
                                    width: isSelected ? 1.8 : 1,
                                  ),
                                  labelStyle: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected ? activeText : _kDark,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // Action Status Options
                            _buildLabel(
                                'Preventive Action Status (कारवाई स्थिती)'),
                            const SizedBox(height: 6),
                            Column(
                              children: _kActionStatuses.map((actionSt) {
                                final isSelected =
                                    _preventiveActionStatus == actionSt;
                                final isCompleted =
                                    actionSt.contains('Completed');
                                final isPartial =
                                    actionSt.contains('Partially');
                                final isNoAction =
                                    actionSt.contains('No Preventive');

                                Color borderColor = _kBorder;
                                Color bg = _kInputBg;
                                if (isSelected) {
                                  if (isCompleted) {
                                    borderColor = _kGreen;
                                    bg = const Color(0xFFECFDF5);
                                  } else if (isPartial) {
                                    borderColor = _kAmber;
                                    bg = const Color(0xFFFFFBEB);
                                  } else if (isNoAction) {
                                    borderColor = _kRed;
                                    bg = const Color(0xFFFEF2F2);
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: widget.readOnly
                                        ? null
                                        : () {
                                            setState(() {
                                              _preventiveActionStatus =
                                                  actionSt;
                                              _markUnsaved();
                                            });
                                          },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: bg,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border(
                                          top: BorderSide(
                                              color: borderColor,
                                              width: isSelected ? 1.5 : 1),
                                          bottom: BorderSide(
                                              color: borderColor,
                                              width: isSelected ? 1.5 : 1),
                                          left: BorderSide(
                                              color: borderColor,
                                              width: isSelected ? 3.5 : 1),
                                          right: BorderSide(
                                              color: borderColor,
                                              width: isSelected ? 1.5 : 1),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected
                                                ? Icons
                                                    .radio_button_checked_rounded
                                                : Icons
                                                    .radio_button_off_rounded,
                                            size: 18,
                                            color: isSelected
                                                ? (isCompleted
                                                    ? _kGreen
                                                    : isPartial
                                                        ? _kAmber
                                                        : _kRed)
                                                : _kMuted,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              actionSt,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: _kDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),

                            // Remarks
                            _buildTextField(
                              label:
                                  'Remarks / Action Summary (तपशील व टिप्पण्या)',
                              hint:
                                  'Enter preventive order details, court hearing or bond conditions...',
                              controller: _remarksCtrl,
                              maxLines: 3,
                              suffix: VoiceDictationButton(
                                controller: _remarksCtrl,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Accused Individual Row Card ───────────────────────────────────────────
  Widget _buildAccusedRowCard(int index, PreventiveAccusedEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kInputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
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
                  'Accused ${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              if (!widget.readOnly && _accusedEntries.length > 1)
                IconButton(
                  onPressed: () => _removeAccused(index),
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: _kRed),
                  tooltip: 'Remove Accused',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Accused Name
          _buildTextField(
            label: 'Accused Name (आरोपीचे नाव) *',
            hint: 'Enter full name of accused ${index + 1}',
            controller: entry.name,
            required: true,
            suffix: VoiceDictationButton(
              controller: entry.name,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Arrested / Notice Issued
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Action / Status'),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        'Arrested',
                        'Notice Issued',
                        'Not Arrested',
                      ].map((type) {
                        final isSel = entry.actionType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSel,
                          onSelected: widget.readOnly
                              ? null
                              : (val) {
                                  if (val) {
                                    setState(() {
                                      entry.actionType = type;
                                      _markUnsaved();
                                    });
                                  }
                                },
                          selectedColor: const Color(0xFFDCFCE7),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSel ? _kGreen : _kBorder,
                            width: isSel ? 1.5 : 1,
                          ),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight:
                                isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? const Color(0xFF15803D) : _kDark,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Bond Taken Y/N
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Bond Taken (जामीन/बंधपत्र)'),
                    const SizedBox(height: 4),
                    Row(
                      children: ['Yes', 'No'].map((b) {
                        final isSel = entry.bondTaken == b;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(b),
                            selected: isSel,
                            onSelected: widget.readOnly
                                ? null
                                : (val) {
                                    if (val) {
                                      setState(() {
                                        entry.bondTaken = b;
                                        _markUnsaved();
                                      });
                                    }
                                  },
                            selectedColor: isSel && b == 'Yes'
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSel
                                  ? (b == 'Yes' ? _kGreen : _kSec)
                                  : _kBorder,
                              width: isSel ? 1.5 : 1,
                            ),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? _kDark : _kMuted,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (entry.bondTaken == 'Yes') ...[
            const SizedBox(height: 8),
            _buildTextField(
              label: 'Bond Amount / Surety Details',
              hint: 'e.g. ₹15,000 personal bond with one surety',
              controller: entry.bondDetails,
            ),
          ],
        ],
      ),
    );
  }

  // ── Section Picker Chips ───────────────────────────────────────────────────
  Widget _buildSectionPickerChips() {
    final actInfo = ACT_DATA[_selectedAct];
    final sections = (actInfo?['sections'] as List<dynamic>?) ?? const [];
    final filterQuery = _sectionSearchCtrl.text.trim().toLowerCase();

    final filtered = sections
        .where((sec) {
          if (sec is! Map) return false;
          final val = sec['val']?.toString().toLowerCase() ?? '';
          final label = sec['label']?.toString().toLowerCase() ?? '';
          return filterQuery.isEmpty ||
              val.contains(filterQuery) ||
              label.contains(filterQuery);
        })
        .take(15)
        .toList();

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'No matching sections found for "$filterQuery". You can type in custom sections below.',
          style: GoogleFonts.inter(fontSize: 11, color: _kMuted),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _kInputBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: filtered.map((sec) {
          final val = sec['val']?.toString() ?? '';
          final label = sec['label']?.toString() ?? val;
          final isSelected = _selectedSections.contains(val);

          return ActionChip(
            label: Text(label),
            backgroundColor:
                isSelected ? const Color(0xFFC7D2FE) : Colors.white,
            side: BorderSide(
              color: isSelected ? const Color(0xFF4F46E5) : _kBorder,
            ),
            labelStyle: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF312E81) : _kDark,
            ),
            avatar: isSelected
                ? const Icon(Icons.check, size: 12, color: Color(0xFF312E81))
                : const Icon(Icons.add, size: 12, color: _kSec),
            onPressed: widget.readOnly
                ? null
                : () {
                    setState(() {
                      if (isSelected) {
                        _selectedSections.remove(val);
                      } else {
                        _selectedSections.add(val);
                      }
                      _markUnsaved();
                    });
                  },
          );
        }).toList(),
      ),
    );
  }

  // ── Card Container ─────────────────────────────────────────────────────────
  Widget _buildCard({
    required String secNum,
    required String title,
    required String marathiTitle,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: _kBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _kMid,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    secNum,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon, size: 18, color: _kTeal),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kDark,
                        ),
                      ),
                      Text(
                        marathiTitle,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _kSec,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),

          // Section Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  // ── Inputs Builders ────────────────────────────────────────────────────────
  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: _tsLabel,
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: _kRed,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool required = false,
    int maxLines = 1,
    IconData? prefixIcon,
    Widget? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          readOnly: widget.readOnly,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 12, color: _kDark),
          onChanged: (val) {
            _markUnsaved();
            if (onChanged != null) onChanged(val);
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 11, color: _kMuted),
            isDense: true,
            filled: true,
            fillColor: _kInputBg,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 16, color: _kSec)
                : null,
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _kTeal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        const SizedBox(height: 5),
        InkWell(
          onTap: widget.readOnly ? null : onTap,
          borderRadius: BorderRadius.circular(6),
          child: IgnorePointer(
            child: TextField(
              controller: controller,
              style: GoogleFonts.inter(fontSize: 12, color: _kDark),
              decoration: InputDecoration(
                hintText: 'DD/MM/YYYY',
                hintStyle: GoogleFonts.inter(fontSize: 11, color: _kMuted),
                isDense: true,
                filled: true,
                fillColor: _kInputBg,
                suffixIcon: const Icon(Icons.calendar_month_rounded,
                    size: 18, color: _kTeal),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: _kBorder),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
