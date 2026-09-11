// lib/modules/theft/widgets/theft_extra_fields.dart
// ─────────────────────────────────────────────────────────────────────────────
// Theft Extra Fields — all theft-specific sections
// Sections:
//  1. Common fields are handled by CommonForm (middleSlot placement)
//  2. Stolen Property List (repeatable)
//  3. Recovered Property
//  4. Type of Theft (checkboxes, multi-select)
//  5. Spot Type
//  6. Spot Investigation Details (Y/N toggles)
//  7. Conditional: Vehicle Details (if Vehicle Theft selected)
//  8. Conditional: Cash Details (if Cash selected)
//  9. Conditional: Jewellery Details (if Precious Metal, Jewellery selected)
// 10. Investigation Verification Checks (Y/N toggles)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Palette (matches app palette) ────────────────────────────────────────────
const Color _kBg = Color(0xFFF4F7F9);
const Color _kCard = Colors.white;
const Color _kTeal = Color(0xFF0EA5E9);
const Color _kGreen = Color(0xFF10B981);
const Color _kRed = Color(0xFFEF4444);
const Color _kDark = Color(0xFF0F172A);
const Color _kFill = Color(0xFFF8FAFC);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kSec = Color(0xFF64748B);
const Color _kAmber = Color(0xFFF59E0B);

// ── Stolen Property Entry ─────────────────────────────────────────────────────
class _StolenPropertyEntry {
  final TextEditingController name = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController value = TextEditingController();

  void dispose() {
    name.dispose();
    description.dispose();
    value.dispose();
  }

  Map<String, dynamic> toMap() => {
        'name': name.text.trim(),
        'description': description.text.trim(),
        'value': value.text.trim(),
      };

  static _StolenPropertyEntry fromMap(Map<String, dynamic> m) {
    final e = _StolenPropertyEntry();
    e.name.text = m['name']?.toString() ?? '';
    e.description.text = m['description']?.toString() ?? '';
    e.value.text = m['value']?.toString() ?? '';
    return e;
  }
}

// ── Ornament Entry ────────────────────────────────────────────────────────────
class _OrnamentEntry {
  final TextEditingController name = TextEditingController();
  final TextEditingController metal = TextEditingController();
  final TextEditingController value = TextEditingController();

  void dispose() {
    name.dispose();
    metal.dispose();
    value.dispose();
  }

  Map<String, dynamic> toMap() => {
        'name': name.text.trim(),
        'metal': metal.text.trim(),
        'value': value.text.trim(),
      };

  static _OrnamentEntry fromMap(Map<String, dynamic> m) {
    final e = _OrnamentEntry();
    e.name.text = m['name']?.toString() ?? '';
    e.metal.text = m['metal']?.toString() ?? '';
    e.value.text = m['value']?.toString() ?? '';
    return e;
  }
}

// ── Vehicle Sub-options ───────────────────────────────────────────────────────
const List<String> _kVehicleSubTypes = [
  'Two Wheeler',
  'Four Wheeler',
  'Three Wheeler',
  'Bicycle',
];

// ── Location Types ────────────────────────────────────────────────────────────
const List<String> _kLocationTypes = [
  'House',
  'Shop',
  'Office',
  'Factory',
  'Godown',
  'Vehicle',
  'Public Place',
  'Religious Place',
  'Other',
];

// ─────────────────────────────────────────────────────────────────────────────
// TheftExtraFields widget
// ─────────────────────────────────────────────────────────────────────────────
class TheftExtraFields extends StatefulWidget {
  const TheftExtraFields({super.key});

  @override
  State<TheftExtraFields> createState() => TheftExtraFieldsState();
}

class TheftExtraFieldsState extends State<TheftExtraFields> {
  // ── 2. Stolen Property List ─────────────────────────────────────────────────
  final List<_StolenPropertyEntry> _stolenProps = [];

  // ── 3. Recovered Property ───────────────────────────────────────────────────
  String? _recoveredPropertyName; // must come from stolen list
  final _recoveredDate = TextEditingController();
  final _recoveredFrom = TextEditingController();
  bool _returnToOwner = false;
  final _whoGaveIt = TextEditingController();

  // ── 4. Type of Theft (multi-select checkboxes) ──────────────────────────────
  final Set<String> _theftTypes = {};
  // Vehicle sub-options
  final Set<String> _vehicleSubTypes = {};
  // "Other" free text for Type of Theft
  final _theftTypeOther = TextEditingController();

  // ── 5. Spot Type ────────────────────────────────────────────────────────────
  final _exactPlace = TextEditingController();
  String? _locationType;
  final _locationTypeOther = TextEditingController();

  // ── 6. Spot Investigation Details ───────────────────────────────────────────
  bool _spotPhotoTaken = false;
  bool _spotVideoTaken = false;
  bool _footprintFound = false;
  bool _fingerprintFound = false;

  // ── 7. Vehicle Details (conditional) ────────────────────────────────────────
  final _engineNumber = TextEditingController();
  final _chassisNumber = TextEditingController();
  final _registrationNumber = TextEditingController();
  final _uniqueIdMark = TextEditingController();
  final _purchaseDate = TextEditingController();
  bool _vehiclePhoto = false;
  bool _ownershipDoc = false;

  // ── 8. Cash Details (conditional) ───────────────────────────────────────────
  final _cashTotal = TextEditingController();
  final _cashNoteCount = TextEditingController();

  // ── 9. Jewellery Details (conditional) ──────────────────────────────────────
  bool _goldPresent = false;
  bool _silverPresent = false;
  bool _platinumPresent = false;
  final _otherMetalName = TextEditingController();
  final List<_OrnamentEntry> _ornaments = [];

  // ── 10. Investigation Verification Checks ───────────────────────────────────
  bool _witnessExamined = false;
  bool _socialMediaChecked = false;
  bool _bankAccountChecked = false;
  bool _tollPlazaChecked = false;
  bool _fasTagChecked = false;
  bool _anprChecked = false;

  // ── Helpers ─────────────────────────────────────────────────────────────────
  bool get _vehicleSelected => _theftTypes.contains('Vehicle Theft');
  bool get _cashSelected => _theftTypes.contains('Cash');
  bool get _jewellerySelected =>
      _theftTypes.contains('Precious Metal, Jewellery');
  bool get _otherTheftTypeSelected => _theftTypes.contains('Other');

  double get _stolenTotalValue {
    double total = 0;
    for (final e in _stolenProps) {
      total += double.tryParse(e.value.text.trim()) ?? 0;
    }
    return total;
  }

  double get _ornamentTotalValue {
    double total = 0;
    for (final e in _ornaments) {
      total += double.tryParse(e.value.text.trim()) ?? 0;
    }
    return total;
  }

  List<String> get _stolenPropertyNames =>
      _stolenProps.map((e) => e.name.text.trim()).where((n) => n.isNotEmpty).toList();

  @override
  void dispose() {
    for (final e in _stolenProps) {
      e.dispose();
    }
    for (final e in _ornaments) {
      e.dispose();
    }
    for (final c in [
      _recoveredDate,
      _recoveredFrom,
      _whoGaveIt,
      _theftTypeOther,
      _exactPlace,
      _locationTypeOther,
      _engineNumber,
      _chassisNumber,
      _registrationNumber,
      _uniqueIdMark,
      _purchaseDate,
      _cashTotal,
      _cashNoteCount,
      _otherMetalName,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Data collection / hydration ──────────────────────────────────────────────
  Map<String, dynamic> collectData() {
    return {
      // §2 Stolen Property
      'stolenProps': _stolenProps.map((e) => e.toMap()).toList(),
      'stolenTotalValue': _stolenTotalValue,
      // §3 Recovered Property
      'recoveredPropertyName': _recoveredPropertyName,
      'recoveredDate': _recoveredDate.text.trim(),
      'recoveredFrom': _recoveredFrom.text.trim(),
      'returnToOwner': _returnToOwner,
      'whoGaveIt': _whoGaveIt.text.trim(),
      // §4 Type of Theft
      'theftTypes': _theftTypes.toList(),
      'vehicleSubTypes': _vehicleSubTypes.toList(),
      'theftTypeOther': _theftTypeOther.text.trim(),
      // §5 Spot Type
      'exactPlace': _exactPlace.text.trim(),
      'locationType': _locationType,
      'locationTypeOther': _locationTypeOther.text.trim(),
      // §6 Spot Investigation
      'spotPhotoTaken': _spotPhotoTaken,
      'spotVideoTaken': _spotVideoTaken,
      'footprintFound': _footprintFound,
      'fingerprintFound': _fingerprintFound,
      // §7 Vehicle Details
      'vehicleEngineNumber': _engineNumber.text.trim(),
      'vehicleChassisNumber': _chassisNumber.text.trim(),
      'vehicleRegNumber': _registrationNumber.text.trim(),
      'vehicleUniqueIdMark': _uniqueIdMark.text.trim(),
      'vehiclePurchaseDate': _purchaseDate.text.trim(),
      'vehiclePhoto': _vehiclePhoto,
      'vehicleOwnershipDoc': _ownershipDoc,
      // §8 Cash Details
      'cashTotal': _cashTotal.text.trim(),
      'cashNoteCount': _cashNoteCount.text.trim(),
      // §9 Jewellery Details
      'jewelleryGold': _goldPresent,
      'jewellerySilver': _silverPresent,
      'jewelleryPlatinum': _platinumPresent,
      'jewelleryOtherMetal': _otherMetalName.text.trim(),
      'ornaments': _ornaments.map((e) => e.toMap()).toList(),
      'ornamentTotalValue': _ornamentTotalValue,
      // §10 Verification Checks
      'witnessExamined': _witnessExamined,
      'socialMediaChecked': _socialMediaChecked,
      'bankAccountChecked': _bankAccountChecked,
      'tollPlazaChecked': _tollPlazaChecked,
      'fasTagChecked': _fasTagChecked,
      'anprChecked': _anprChecked,
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    // §2 Stolen Property
    for (final e in _stolenProps) {
      e.dispose();
    }
    _stolenProps.clear();
    final rawProps = data['stolenProps'];
    if (rawProps is List) {
      for (final item in rawProps) {
        if (item is Map) {
          _stolenProps.add(
            _StolenPropertyEntry.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    // §3 Recovered Property
    _recoveredPropertyName = _asStringOrNull(data['recoveredPropertyName']);
    _recoveredDate.text = _asString(data['recoveredDate']);
    _recoveredFrom.text = _asString(data['recoveredFrom']);
    _returnToOwner = _asBool(data['returnToOwner']);
    _whoGaveIt.text = _asString(data['whoGaveIt']);

    // §4 Type of Theft
    _theftTypes.clear();
    final rawTypes = data['theftTypes'];
    if (rawTypes is List) {
      _theftTypes.addAll(rawTypes.map((e) => e.toString()));
    }
    _vehicleSubTypes.clear();
    final rawVehSub = data['vehicleSubTypes'];
    if (rawVehSub is List) {
      _vehicleSubTypes.addAll(rawVehSub.map((e) => e.toString()));
    }
    _theftTypeOther.text = _asString(data['theftTypeOther']);

    // §5 Spot Type
    _exactPlace.text = _asString(data['exactPlace']);
    _locationType = _asStringOrNull(data['locationType']);
    _locationTypeOther.text = _asString(data['locationTypeOther']);

    // §6 Spot Investigation
    _spotPhotoTaken = _asBool(data['spotPhotoTaken']);
    _spotVideoTaken = _asBool(data['spotVideoTaken']);
    _footprintFound = _asBool(data['footprintFound']);
    _fingerprintFound = _asBool(data['fingerprintFound']);

    // §7 Vehicle
    _engineNumber.text = _asString(data['vehicleEngineNumber']);
    _chassisNumber.text = _asString(data['vehicleChassisNumber']);
    _registrationNumber.text = _asString(data['vehicleRegNumber']);
    _uniqueIdMark.text = _asString(data['vehicleUniqueIdMark']);
    _purchaseDate.text = _asString(data['vehiclePurchaseDate']);
    _vehiclePhoto = _asBool(data['vehiclePhoto']);
    _ownershipDoc = _asBool(data['vehicleOwnershipDoc']);

    // §8 Cash
    _cashTotal.text = _asString(data['cashTotal']);
    _cashNoteCount.text = _asString(data['cashNoteCount']);

    // §9 Jewellery
    _goldPresent = _asBool(data['jewelleryGold']);
    _silverPresent = _asBool(data['jewellerySilver']);
    _platinumPresent = _asBool(data['jewelleryPlatinum']);
    _otherMetalName.text = _asString(data['jewelleryOtherMetal']);
    for (final e in _ornaments) {
      e.dispose();
    }
    _ornaments.clear();
    final rawOrn = data['ornaments'];
    if (rawOrn is List) {
      for (final item in rawOrn) {
        if (item is Map) {
          _ornaments.add(
            _OrnamentEntry.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    // §10 Verification
    _witnessExamined = _asBool(data['witnessExamined']);
    _socialMediaChecked = _asBool(data['socialMediaChecked']);
    _bankAccountChecked = _asBool(data['bankAccountChecked']);
    _tollPlazaChecked = _asBool(data['tollPlazaChecked']);
    _fasTagChecked = _asBool(data['fasTagChecked']);
    _anprChecked = _asBool(data['anprChecked']);

    if (mounted) setState(() {});
  }

  String _asString(dynamic v) => v?.toString() ?? '';
  String? _asStringOrNull(dynamic v) {
    final s = v?.toString() ?? '';
    return s.isEmpty ? null : s;
  }

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    if (v is num) return v != 0;
    return false;
  }

  // ── UI helpers ───────────────────────────────────────────────────────────────
  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _kSec,
        letterSpacing: 0.5,
      ),
      filled: true,
      fillColor: _kFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kTeal, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: _kTeal,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _kDark,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(Widget child, {EdgeInsets? padding}) {
    return Card(
      elevation: 0,
      color: _kCard,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _kBorder),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _yesNo({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _kSec,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildYNButton(
                text: 'YES',
                selected: value,
                color: _kGreen,
                onPressed: () => onChanged(true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildYNButton(
                text: 'NO',
                selected: !value,
                color: _kRed,
                onPressed: () => onChanged(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYNButton({
    required String text,
    required bool selected,
    required Color color,
    required VoidCallback onPressed,
  }) {
    if (selected) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(42),
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle:
              GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        child: Text(text),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(42),
        foregroundColor: _kSec,
        side: const BorderSide(color: _kBorder),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle:
            GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      child: Text(text),
    );
  }

  Widget _rowTwo(Widget a, Widget b) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 420) {
          return Column(
            children: [a, const SizedBox(height: 10), b],
          );
        }
        return Row(
          children: [
            Expanded(child: a),
            const SizedBox(width: 10),
            Expanded(child: b),
          ],
        );
      },
    );
  }

  Widget _theftCheckbox(String label) {
    final selected = _theftTypes.contains(label);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() {
        if (selected) {
          _theftTypes.remove(label);
          if (label == 'Vehicle Theft') _vehicleSubTypes.clear();
        } else {
          _theftTypes.add(label);
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? _kTeal : Colors.transparent,
                border: Border.all(
                    color: selected ? _kTeal : _kBorder, width: 2),
                borderRadius: BorderRadius.circular(5),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? _kDark : _kSec,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleSubCheckbox(String label) {
    final selected = _vehicleSubTypes.contains(label);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() {
        if (selected) {
          _vehicleSubTypes.remove(label);
        } else {
          _vehicleSubTypes.add(label);
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: selected ? _kAmber : Colors.transparent,
                border: Border.all(
                    color: selected ? _kAmber : _kBorder, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? _kDark : _kSec,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(TextEditingController c) async {
    final initial = _parseDate(c.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => c.text = _fmtDate(picked));
    }
  }

  DateTime? _parseDate(String s) {
    final parts = s.split('-');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
  }

  Widget _dateField(String label, TextEditingController c) {
    return TextFormField(
      controller: c,
      readOnly: true,
      style: GoogleFonts.poppins(fontSize: 12),
      decoration: _dec(label).copyWith(
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
      ),
      onTap: () => _pickDate(c),
    );
  }

  // ── Sections ─────────────────────────────────────────────────────────────────
  Widget _buildStolenPropertySection() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Stolen Property List'),
          const SizedBox(height: 12),
          // Total Value display
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calculate_outlined,
                    color: Color(0xFF16A34A), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Total Value: ',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                Text(
                  'Rs. ${_stolenTotalValue.toStringAsFixed(0)}/-',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Stolen property entries
          ..._stolenProps.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kTeal,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Item ${i + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: _kRed, size: 20),
                        tooltip: 'Remove',
                        onPressed: () => setState(() {
                          e.dispose();
                          _stolenProps.removeAt(i);
                          // Clear recovered property if it referenced this
                          final names = _stolenPropertyNames;
                          if (_recoveredPropertyName != null &&
                              !names.contains(_recoveredPropertyName)) {
                            _recoveredPropertyName = null;
                          }
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: e.name,
                    style: GoogleFonts.poppins(fontSize: 12),
                    decoration: _dec('Name'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: e.description,
                    style: GoogleFonts.poppins(fontSize: 12),
                    maxLines: 2,
                    decoration: _dec('Description'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: e.value,
                    style: GoogleFonts.poppins(fontSize: 12),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'))
                    ],
                    decoration: _dec('Value (Rs.)'),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _stolenProps.add(_StolenPropertyEntry())),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(
                'Add Stolen Item',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kTeal,
                side: const BorderSide(color: _kTeal),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveredPropertySection() {
    final names = _stolenPropertyNames;
    // Ensure selected value is still valid
    if (_recoveredPropertyName != null &&
        !names.contains(_recoveredPropertyName)) {
      _recoveredPropertyName = null;
    }

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Recovered Property'),
          const SizedBox(height: 12),
          // Recovered Property Name — from Stolen Property list
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RECOVERED PROPERTY NAME',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kSec,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              if (names.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Color(0xFFF97316), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Add stolen items above first — recovered property must be selected from the stolen property list.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFFC2410C),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: names.map((name) {
                    final sel = _recoveredPropertyName == name;
                    return FilterChip(
                      label: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: sel
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: sel ? Colors.white : _kDark,
                        ),
                      ),
                      selected: sel,
                      onSelected: (_) => setState(
                          () => _recoveredPropertyName = sel ? null : name),
                      selectedColor: _kTeal,
                      backgroundColor: _kFill,
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                          color: sel ? _kTeal : _kBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    );
                  }).toList(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _rowTwo(
            _dateField('Recovered Date', _recoveredDate),
            TextFormField(
              controller: _recoveredFrom,
              style: GoogleFonts.poppins(fontSize: 12),
              decoration: _dec('Recovered From'),
            ),
          ),
          const SizedBox(height: 12),
          _yesNo(
            label: 'Return to Owner',
            value: _returnToOwner,
            onChanged: (v) => setState(() => _returnToOwner = v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _whoGaveIt,
            style: GoogleFonts.poppins(fontSize: 12),
            decoration: _dec('Who gave it to? (Person who handed over)'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOfTheftSection() {
    const allTypes = [
      'Precious Metal, Jewellery',
      'Any Metal (Copper, Iron, Scrap)',
      'Diamond and Precious Stone',
      'Vehicle Theft',
      'Cattle / Animal',
      'Cash',
      'ATM and Banking Related',
      'Mobile and Electronic Instrument',
      'Metal Wire / Cable Theft',
      'Agricultural Produce Theft',
      'Idol / Antique Theft',
      'Petrol, Diesel, Fuel Theft',
      'Document Theft',
      'Sand / Mineral Theft',
      'Other',
    ];

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Type of Theft'),
          const SizedBox(height: 10),
          Text(
            'Select all that apply:',
            style: GoogleFonts.poppins(fontSize: 11, color: _kSec),
          ),
          const SizedBox(height: 8),
          ...allTypes.map((type) {
            if (type == 'Vehicle Theft') {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _theftCheckbox(type),
                  // Vehicle sub-types — animated
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _vehicleSelected
                        ? Container(
                            margin: const EdgeInsets.only(
                                left: 30, top: 4, bottom: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFFED7AA)),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vehicle Type:',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFC2410C),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ..._kVehicleSubTypes
                                    .map(_vehicleSubCheckbox),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            }
            if (type == 'Other') {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _theftCheckbox(type),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _otherTheftTypeSelected
                        ? Padding(
                            padding: const EdgeInsets.only(
                                left: 30, top: 6, bottom: 4),
                            child: TextFormField(
                              controller: _theftTypeOther,
                              style: GoogleFonts.poppins(fontSize: 12),
                              maxLength: 25,
                              decoration: _dec(
                                      'Other Theft Type (max 25 chars)')
                                  .copyWith(
                                counterText: '${_theftTypeOther.text.length}/25',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            }
            return _theftCheckbox(type);
          }),
        ],
      ),
    );
  }

  Widget _buildSpotTypeSection() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Spot Type'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _exactPlace,
            style: GoogleFonts.poppins(fontSize: 12),
            maxLines: 2,
            decoration: _dec('Exact Place of Theft'),
          ),
          const SizedBox(height: 14),
          Text(
            'TYPE OF LOCATION',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kSec,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _kLocationTypes.map((loc) {
              final sel = _locationType == loc;
              return ChoiceChip(
                label: Text(
                  loc,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight:
                        sel ? FontWeight.w700 : FontWeight.w400,
                    color: sel ? Colors.white : _kDark,
                  ),
                ),
                selected: sel,
                onSelected: (_) =>
                    setState(() => _locationType = sel ? null : loc),
                selectedColor: _kTeal,
                backgroundColor: _kFill,
                checkmarkColor: Colors.white,
                side: BorderSide(color: sel ? _kTeal : _kBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              );
            }).toList(),
          ),
          // "Other" location free text
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _locationType == 'Other'
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                      controller: _locationTypeOther,
                      style: GoogleFonts.poppins(fontSize: 12),
                      maxLength: 25,
                      decoration: _dec('Other Location (max 25 chars)')
                          .copyWith(
                        counterText:
                            '${_locationTypeOther.text.length}/25',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotInvestigationSection() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Spot Investigation Details'),
          const SizedBox(height: 14),
          _rowTwo(
            _yesNo(
              label: 'Spot Photo Taken',
              value: _spotPhotoTaken,
              onChanged: (v) => setState(() => _spotPhotoTaken = v),
            ),
            _yesNo(
              label: 'Spot Video Taken',
              value: _spotVideoTaken,
              onChanged: (v) => setState(() => _spotVideoTaken = v),
            ),
          ),
          const SizedBox(height: 14),
          _rowTwo(
            _yesNo(
              label: 'Footprint Found',
              value: _footprintFound,
              onChanged: (v) => setState(() => _footprintFound = v),
            ),
            _yesNo(
              label: 'Fingerprint Found',
              value: _fingerprintFound,
              onChanged: (v) => setState(() => _fingerprintFound = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSection() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car_outlined,
                  color: _kAmber, size: 20),
              const SizedBox(width: 8),
              Expanded(child: _sectionTitle('Stolen Vehicle Details')),
            ],
          ),
          const SizedBox(height: 12),
          _rowTwo(
            TextFormField(
              controller: _engineNumber,
              style: GoogleFonts.poppins(fontSize: 12),
              decoration: _dec('Engine Number'),
            ),
            TextFormField(
              controller: _chassisNumber,
              style: GoogleFonts.poppins(fontSize: 12),
              decoration: _dec('Chassis Number'),
            ),
          ),
          const SizedBox(height: 10),
          _rowTwo(
            TextFormField(
              controller: _registrationNumber,
              style: GoogleFonts.poppins(fontSize: 12),
              decoration: _dec('Registration Number'),
            ),
            TextFormField(
              controller: _uniqueIdMark,
              style: GoogleFonts.poppins(fontSize: 12),
              decoration: _dec('Unique Identification Mark'),
            ),
          ),
          const SizedBox(height: 10),
          _dateField('Purchase Date', _purchaseDate),
          const SizedBox(height: 14),
          _rowTwo(
            _yesNo(
              label: 'Photo Available',
              value: _vehiclePhoto,
              onChanged: (v) => setState(() => _vehiclePhoto = v),
            ),
            _yesNo(
              label: 'Ownership Document',
              value: _ownershipDoc,
              onChanged: (v) => setState(() => _ownershipDoc = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashSection() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_rupee_outlined,
                  color: _kGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(child: _sectionTitle('Stolen Cash Details')),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cashTotal,
            style: GoogleFonts.poppins(fontSize: 12),
            keyboardType: TextInputType.number,
            decoration: _dec('Total Rupees or Any Currency'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _cashNoteCount,
            style: GoogleFonts.poppins(fontSize: 12),
            keyboardType: TextInputType.number,
            decoration: _dec('Count of Notes (optional)'),
          ),
        ],
      ),
    );
  }

  Widget _buildJewellerySection() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.diamond_outlined, color: _kAmber, size: 20),
              const SizedBox(width: 8),
              Expanded(child: _sectionTitle('Stolen Jewellery Details')),
            ],
          ),
          const SizedBox(height: 12),
          // Metal flags
          _rowTwo(
            _yesNo(
              label: 'Gold',
              value: _goldPresent,
              onChanged: (v) => setState(() => _goldPresent = v),
            ),
            _yesNo(
              label: 'Silver',
              value: _silverPresent,
              onChanged: (v) => setState(() => _silverPresent = v),
            ),
          ),
          const SizedBox(height: 12),
          _rowTwo(
            _yesNo(
              label: 'Platinum',
              value: _platinumPresent,
              onChanged: (v) => setState(() => _platinumPresent = v),
            ),
            TextFormField(
              controller: _otherMetalName,
              style: GoogleFonts.poppins(fontSize: 12),
              decoration: _dec('Other Metal Name (e.g. abc)'),
            ),
          ),
          const SizedBox(height: 16),
          // Ornament total value display
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calculate_outlined,
                    color: Color(0xFFD97706), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Ornament Total: ',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD97706),
                  ),
                ),
                Text(
                  'Rs. ${_ornamentTotalValue.toStringAsFixed(0)}/-',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Ornament entries
          ..._ornaments.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kAmber,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Ornament ${i + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: _kRed, size: 20),
                        tooltip: 'Remove',
                        onPressed: () => setState(() {
                          e.dispose();
                          _ornaments.removeAt(i);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: e.name,
                    style: GoogleFonts.poppins(fontSize: 12),
                    decoration: _dec('Name of Ornament'),
                  ),
                  const SizedBox(height: 8),
                  _rowTwo(
                    TextFormField(
                      controller: e.metal,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: _dec('Metal of Ornament'),
                    ),
                    TextFormField(
                      controller: e.value,
                      style: GoogleFonts.poppins(fontSize: 12),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'))
                      ],
                      decoration: _dec('Value of Ornament (Rs.)'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _ornaments.add(_OrnamentEntry())),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(
                'Add Ornament',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kAmber,
                side: const BorderSide(color: _kAmber),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestigationChecksSection() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Investigation Verification Checks'),
          const SizedBox(height: 14),
          _rowTwo(
            _yesNo(
              label: 'Witness Examined',
              value: _witnessExamined,
              onChanged: (v) => setState(() => _witnessExamined = v),
            ),
            _yesNo(
              label: 'Social Media Checked',
              value: _socialMediaChecked,
              onChanged: (v) => setState(() => _socialMediaChecked = v),
            ),
          ),
          const SizedBox(height: 12),
          _rowTwo(
            _yesNo(
              label: 'Bank Account Checked',
              value: _bankAccountChecked,
              onChanged: (v) => setState(() => _bankAccountChecked = v),
            ),
            _yesNo(
              label: 'Toll Plaza Data Checked',
              value: _tollPlazaChecked,
              onChanged: (v) => setState(() => _tollPlazaChecked = v),
            ),
          ),
          const SizedBox(height: 12),
          _rowTwo(
            _yesNo(
              label: 'FASTag Data Checked',
              value: _fasTagChecked,
              onChanged: (v) => setState(() => _fasTagChecked = v),
            ),
            _yesNo(
              label: 'ANPR Data Checked',
              value: _anprChecked,
              onChanged: (v) => setState(() => _anprChecked = v),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider heading
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
            child: Row(
              children: [
                const Expanded(child: Divider(color: _kBorder, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _kTeal.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_police_outlined,
                            color: _kTeal, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'THEFT — SPECIFIC DETAILS',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _kTeal,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: _kBorder, thickness: 1)),
              ],
            ),
          ),

          // §2 Stolen Property List
          _buildStolenPropertySection(),

          // §3 Recovered Property
          _buildRecoveredPropertySection(),

          // §4 Type of Theft
          _buildTypeOfTheftSection(),

          // §5 Spot Type
          _buildSpotTypeSection(),

          // §6 Spot Investigation Details
          _buildSpotInvestigationSection(),

          // §7 Conditional: Vehicle Details
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _vehicleSelected
                ? _buildVehicleSection()
                : const SizedBox.shrink(),
          ),

          // §8 Conditional: Cash Details
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _cashSelected
                ? _buildCashSection()
                : const SizedBox.shrink(),
          ),

          // §9 Conditional: Jewellery Details
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _jewellerySelected
                ? _buildJewellerySection()
                : const SizedBox.shrink(),
          ),

          // §10 Investigation Verification Checks
          _buildInvestigationChecksSection(),
        ],
      ),
    );
  }
}
