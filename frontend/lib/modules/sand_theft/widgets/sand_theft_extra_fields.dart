// lib/modules/sand_theft/widgets/sand_theft_extra_fields.dart
// ─────────────────────────────────────────────────────────────────────────────
// Sand Theft Extra Fields — sand theft specific sections
// Directly below Section 4 Stolen Property:
//  1. Seized Vehicle / Property:
//     - 1. Number of Vehicle
//     - 2. Name of Vehicle
//     - 3. Types of Vehicle:
//          - Company Name (Dropdown)
//          - Type of Vehicle (Dropdown)
//     - 4. Owner Name & Address
//     - 5. Driver Name & Address
//     - Engine Num & Chechis Number
//     - Reg Number & Unique Identification Mark
//     - Purchase Date
//     - 6. Photo Copy YES/NO & 7. Ownership Doc YES/NO
//  2. Applicable Sections (Dropdown from PDF: BNS 303-331 & Mining Acts)
//  3. Spot Type (Exact place of sand theft, Type of location)
//  4. Spot Investigation Details (Y/N toggles)
//  5. Investigation Verification Checks (Y/N toggles)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
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

// ── Dropdown Constants ─────────────────────────────────────────────────────────
const List<String> kVehicleCompanies = [
  'Tata Motors',
  'Mahindra & Mahindra',
  'Ashok Leyland',
  'Eicher Motors',
  'BharatBenz',
  'JCB India',
  'John Deere',
  'Sonalika Tractors',
  'Swaraj Tractors',
  'Force Motors',
  'Hyundai Construction',
  'Caterpillar (CAT)',
  'Kubota',
  'Escorts / Farmtrac',
  'Volvo',
  'Other',
];

const List<String> kVehicleTypes = [
  'Tipper',
  'Truck / Dumper',
  'Tractor with Trolley',
  'Tractor',
  'Excavator / JCB / Poclain',
  'Boat / Barge / Suction Dredger',
  'Tempo / Pickup / LCV',
  'Trailer',
  'Bullock Cart',
  'Other',
];

const List<Map<String, String>> kSandTheftSections = [
  {'sec': '303(1)', 'desc': 'Theft'},
  {'sec': '303(2)', 'desc': 'Theft'},
  {'sec': '304(1)', 'desc': 'Snatching'},
  {'sec': '304(2)', 'desc': 'Snatching'},
  {
    'sec': '305',
    'desc':
        'Theft in a dwelling house, or means of transportation or place of worship, etc.'
  },
  {
    'sec': '306',
    'desc': 'Theft by clerk or servant of property in possession of master'
  },
  {
    'sec': '307',
    'desc':
        'Theft after preparation made for causing death, hurt or restraint in order to committing of theft'
  },
  {'sec': '308(1)', 'desc': 'Extortion'},
  {'sec': '308(2)', 'desc': 'Extortion'},
  {'sec': '308(3)', 'desc': 'Extortion'},
  {'sec': '308(4)', 'desc': 'Extortion'},
  {'sec': '308(5)', 'desc': 'Extortion'},
  {'sec': '308(6)', 'desc': 'Extortion'},
  {'sec': '308(7)', 'desc': 'Extortion'},
  {'sec': '309(1)', 'desc': 'Robbery'},
  {'sec': '309(2)', 'desc': 'Robbery'},
  {'sec': '309(3)', 'desc': 'Robbery'},
  {'sec': '309(4)', 'desc': 'Robbery'},
  {'sec': '309(5)', 'desc': 'Robbery'},
  {'sec': '309(6)', 'desc': 'Robbery'},
  {'sec': '310(1)', 'desc': 'Dacoity'},
  {'sec': '310(2)', 'desc': 'Dacoity'},
  {'sec': '310(3)', 'desc': 'Dacoity'},
  {'sec': '310(4)', 'desc': 'Dacoity'},
  {'sec': '310(5)', 'desc': 'Dacoity'},
  {'sec': '310(6)', 'desc': 'Dacoity'},
  {
    'sec': '311',
    'desc': 'Robbery, or dacoity, with attempt to cause death or grievous hurt'
  },
  {
    'sec': '312',
    'desc': 'Attempt to commit robbery or dacoity when armed with deadly weapon'
  },
  {
    'sec': '313',
    'desc': 'Punishment for belonging to gang of robbers, etc.'
  },
  {'sec': '314', 'desc': 'Dishonest misappropriation of property'},
  {
    'sec': '315',
    'desc':
        'Dishonest misappropriation of property possessed by deceased person at the time of his death'
  },
  {'sec': '316(1)', 'desc': 'Criminal breach of trust'},
  {'sec': '316(2)', 'desc': 'Criminal breach of trust'},
  {'sec': '316(3)', 'desc': 'Criminal breach of trust'},
  {'sec': '316(4)', 'desc': 'Criminal breach of trust'},
  {'sec': '316(5)', 'desc': 'Criminal breach of trust'},
  {'sec': '317(1)', 'desc': 'Stolen property'},
  {'sec': '317(2)', 'desc': 'Stolen property'},
  {'sec': '317(3)', 'desc': 'Stolen property'},
  {'sec': '317(4)', 'desc': 'Stolen property'},
  {'sec': '317(5)', 'desc': 'Stolen property'},
  {'sec': '318(1)', 'desc': 'Cheating'},
  {'sec': '318(2)', 'desc': 'Cheating'},
  {'sec': '318(3)', 'desc': 'Cheating'},
  {'sec': '318(4)', 'desc': 'Cheating'},
  {'sec': '319(1)', 'desc': 'Cheating by personation'},
  {'sec': '319(2)', 'desc': 'Cheating by personation'},
  {
    'sec': '320',
    'desc':
        'Dishonest or fraudulent removal or concealment of property to prevent distribution among creditors'
  },
  {
    'sec': '321',
    'desc':
        'Dishonestly or fraudulently preventing debt being available for creditors'
  },
  {
    'sec': '322',
    'desc':
        'Dishonest or fraudulent execution of deed of transfer containing false statement of consideration'
  },
  {
    'sec': '323',
    'desc': 'Dishonest or fraudulent removal or concealment of property'
  },
  {'sec': '324(1)', 'desc': 'Mischief'},
  {'sec': '324(2)', 'desc': 'Mischief'},
  {'sec': '324(3)', 'desc': 'Mischief'},
  {'sec': '324(4)', 'desc': 'Mischief'},
  {'sec': '324(5)', 'desc': 'Mischief'},
  {'sec': '324(6)', 'desc': 'Mischief'},
  {'sec': '325', 'desc': 'Mischief by killing or maiming animal'},
  {
    'sec': '326(a)',
    'desc': 'Mischief by injury, inundation, fire or explosive substance, etc.'
  },
  {
    'sec': '326(b)',
    'desc': 'Mischief by injury, inundation, fire or explosive substance, etc.'
  },
  {
    'sec': '326(c)',
    'desc': 'Mischief by injury, inundation, fire or explosive substance, etc.'
  },
  {
    'sec': '326(d)',
    'desc': 'Mischief by injury, inundation, fire or explosive substance, etc.'
  },
  {
    'sec': '326(e)',
    'desc': 'Mischief by injury, inundation, fire or explosive substance, etc.'
  },
  {
    'sec': '326(f)',
    'desc': 'Mischief by injury, inundation, fire or explosive substance, etc.'
  },
  {
    'sec': '326(g)',
    'desc': 'Mischief by injury, inundation, fire or explosive substance, etc.'
  },
  {
    'sec': '327(1)',
    'desc':
        'Mischief with intent to destroy or make unsafe a rail, aircraft, decked vessel or one of twenty tons burden'
  },
  {
    'sec': '327(2)',
    'desc':
        'Mischief with intent to destroy or make unsafe a rail, aircraft, decked vessel or one of twenty tons burden'
  },
  {
    'sec': '328',
    'desc':
        'Punishment for intentionally running vessel aground or ashore with intent to commit theft, etc.'
  },
  {'sec': '329(1)', 'desc': 'Criminal trespass and house-trespass'},
  {'sec': '329(2)', 'desc': 'Criminal trespass and house-trespass'},
  {'sec': '329(3)', 'desc': 'Criminal trespass and house-trespass'},
  {'sec': '329(4)', 'desc': 'Criminal trespass and house-trespass'},
  {'sec': '330(1)', 'desc': 'House-trespass and house-breaking'},
  {'sec': '330(2)(a)', 'desc': 'House-trespass and house-breaking'},
  {'sec': '330(2)(b)', 'desc': 'House-trespass and house-breaking'},
  {'sec': '330(2)(c)', 'desc': 'House-trespass and house-breaking'},
  {'sec': '330(2)(d)', 'desc': 'House-trespass and house-breaking'},
  {'sec': '330(2)(e)', 'desc': 'House-trespass and house-breaking'},
  {'sec': '330(2)(f)', 'desc': 'House-trespass and house-breaking'},
  {'sec': '331(1)', 'desc': 'Punishment for house-trespass or house-breaking'},
  {'sec': '331(2)', 'desc': 'Punishment for house-trespass or house-breaking'},
  {'sec': '331(3)', 'desc': 'Punishment for house-trespass or house-breaking'},
  {'sec': '331(4)', 'desc': 'Punishment for house-trespass or house-breaking'},
  {'sec': '331(5)', 'desc': 'Punishment for house-trespass or house-breaking'},
  {'sec': '331(6)', 'desc': 'Punishment for house-trespass or house-breaking'},
  {'sec': '331(7)', 'desc': 'Punishment for house-trespass or house-breaking'},
  {'sec': '331(8)', 'desc': 'Punishment for house-trespass or house-breaking'},
  {
    'sec': 'MMDR 4(1), 21(1)',
    'desc':
        'Mines & Minerals (Development & Regulation) Act - Illegal Mining/Transport'
  },
  {
    'sec': 'MLRC 48(7), 48(8)',
    'desc': 'Maharashtra Land Revenue Code - Illegal Extraction/Removal of Sand'
  },
  {
    'sec': 'EPA 15',
    'desc': 'Environment (Protection) Act - Penalty for Environmental Damage'
  },
];

// ── Location Types ────────────────────────────────────────────────────────────
const List<String> _kLocationTypes = [
  'River Bed / Sand Ghat',
  'Mine / Quarry',
  'Road / Highway',
  'Vehicle',
  'Godown / Stockyard',
  'Public Place',
  'Other',
];

// ── Seized Vehicle Entry ───────────────────────────────────────────────────────
class _SeizedVehicleEntry {
  final TextEditingController numberOfVehicles = TextEditingController();
  final TextEditingController vehicleName = TextEditingController();
  final TextEditingController companyName = TextEditingController();
  final TextEditingController vehicleType = TextEditingController();
  final TextEditingController ownerName = TextEditingController();
  final TextEditingController ownerAddress = TextEditingController();
  final TextEditingController driverName = TextEditingController();
  final TextEditingController driverAddress = TextEditingController();

  final TextEditingController engineNumber = TextEditingController();
  final TextEditingController chassisNumber = TextEditingController();
  final TextEditingController registrationNumber = TextEditingController();
  final TextEditingController uniqueIdMark = TextEditingController();
  final TextEditingController purchaseDate = TextEditingController();
  bool photoCopy = false;
  bool ownershipDoc = false;

  void dispose() {
    numberOfVehicles.dispose();
    vehicleName.dispose();
    companyName.dispose();
    vehicleType.dispose();
    ownerName.dispose();
    ownerAddress.dispose();
    driverName.dispose();
    driverAddress.dispose();
    engineNumber.dispose();
    chassisNumber.dispose();
    registrationNumber.dispose();
    uniqueIdMark.dispose();
    purchaseDate.dispose();
  }

  Map<String, dynamic> toMap() => {
        'numberOfVehicles': numberOfVehicles.text.trim(),
        'vehicleName': vehicleName.text.trim(),
        'companyName': companyName.text.trim(),
        'vehicleType': vehicleType.text.trim(),
        'ownerName': ownerName.text.trim(),
        'ownerAddress': ownerAddress.text.trim(),
        'driverName': driverName.text.trim(),
        'driverAddress': driverAddress.text.trim(),
        'engineNumber': engineNumber.text.trim(),
        'chassisNumber': chassisNumber.text.trim(),
        'registrationNumber': registrationNumber.text.trim(),
        'uniqueIdMark': uniqueIdMark.text.trim(),
        'purchaseDate': purchaseDate.text.trim(),
        'photoCopy': photoCopy,
        'ownershipDoc': ownershipDoc,
      };

  void updateFrom(Map<String, dynamic> m) {
    numberOfVehicles.text = m['numberOfVehicles']?.toString() ??
        m['vehicleNumber']?.toString() ??
        '';
    vehicleName.text =
        m['vehicleName']?.toString() ?? m['name']?.toString() ?? '';
    companyName.text = m['companyName']?.toString() ??
        m['companyNameOther']?.toString() ??
        '';
    vehicleType.text = m['vehicleType']?.toString() ??
        m['vehicleTypeOther']?.toString() ??
        '';
    ownerName.text = m['ownerName']?.toString() ?? '';
    ownerAddress.text = m['ownerAddress']?.toString() ?? '';
    driverName.text = m['driverName']?.toString() ?? '';
    driverAddress.text = m['driverAddress']?.toString() ?? '';

    engineNumber.text = m['engineNumber']?.toString() ??
        m['vehicleEngineNumber']?.toString() ??
        '';
    chassisNumber.text = m['chassisNumber']?.toString() ??
        m['vehicleChassisNumber']?.toString() ??
        '';
    registrationNumber.text = m['registrationNumber']?.toString() ??
        m['vehicleRegNumber']?.toString() ??
        '';
    uniqueIdMark.text = m['uniqueIdMark']?.toString() ??
        m['vehicleUniqueIdMark']?.toString() ??
        '';
    purchaseDate.text = m['purchaseDate']?.toString() ??
        m['vehiclePurchaseDate']?.toString() ??
        '';
    photoCopy =
        _toBool(m['photoCopy'] ?? m['vehiclePhotoCopy'] ?? m['vehiclePhoto']);
    ownershipDoc = _toBool(m['ownershipDoc'] ?? m['vehicleOwnershipDoc']);
  }

  static _SeizedVehicleEntry fromMap(Map<String, dynamic> m) {
    final e = _SeizedVehicleEntry();
    e.updateFrom(m);
    return e;
  }

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    if (v is num) return v != 0;
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SandTheftExtraFields widget
// ─────────────────────────────────────────────────────────────────────────────
class SandTheftExtraFields extends StatefulWidget {
  const SandTheftExtraFields({super.key});

  @override
  State<SandTheftExtraFields> createState() => SandTheftExtraFieldsState();
}

class SandTheftExtraFieldsState extends State<SandTheftExtraFields> {
  // ── 1. Seized Vehicle List (Always initialized with 1 entry) ────────────────
  final List<_SeizedVehicleEntry> _seizedVehicles = [_SeizedVehicleEntry()];

  // ── 2. Applicable Sections ──────────────────────────────────────────────────
  final Set<String> _selectedSections = {'303(1)'};
  String? _sectionDropdownValue;

  // ── 3. Spot Type ────────────────────────────────────────────────────────────
  final _exactPlace = TextEditingController();
  String? _locationType;
  final _locationTypeOther = TextEditingController();

  // ── 4. Spot Investigation Details ───────────────────────────────────────────
  bool _spotPhotoTaken = false;
  bool _spotVideoTaken = false;
  bool _footprintFound = false;
  bool _fingerprintFound = false;

  // ── 5. Investigation Verification Checks ───────────────────────────────────
  bool _witnessExamined = false;
  bool _socialMediaChecked = false;
  bool _bankAccountChecked = false;
  bool _tollPlazaChecked = false;
  bool _fasTagChecked = false;
  bool _anprChecked = false;

  @override
  void dispose() {
    for (final e in _seizedVehicles) {
      e.dispose();
    }
    _exactPlace.dispose();
    _locationTypeOther.dispose();
    super.dispose();
  }

  // ── Data collection / hydration ──────────────────────────────────────────────
  Map<String, dynamic> collectData() {
    final firstVeh = _seizedVehicles.isNotEmpty ? _seizedVehicles.first : null;
    return {
      // §1 Seized Vehicle
      'seizedVehicles': _seizedVehicles.map((e) => e.toMap()).toList(),
      // Flat keys for direct access & export compatibility
      'numberOfVehicles': firstVeh?.numberOfVehicles.text.trim() ?? '',
      'vehicleName': firstVeh?.vehicleName.text.trim() ?? '',
      'companyName': firstVeh?.companyName.text.trim() ?? '',
      'vehicleType': firstVeh?.vehicleType.text.trim() ?? '',
      'ownerName': firstVeh?.ownerName.text.trim() ?? '',
      'ownerAddress': firstVeh?.ownerAddress.text.trim() ?? '',
      'driverName': firstVeh?.driverName.text.trim() ?? '',
      'driverAddress': firstVeh?.driverAddress.text.trim() ?? '',
      'vehicleEngineNumber': firstVeh?.engineNumber.text.trim() ?? '',
      'vehicleChassisNumber': firstVeh?.chassisNumber.text.trim() ?? '',
      'vehicleRegNumber': firstVeh?.registrationNumber.text.trim() ?? '',
      'vehicleUniqueIdMark': firstVeh?.uniqueIdMark.text.trim() ?? '',
      'vehiclePurchaseDate': firstVeh?.purchaseDate.text.trim() ?? '',
      'vehiclePhotoCopy': firstVeh?.photoCopy ?? false,
      'vehiclePhoto': firstVeh?.photoCopy ?? false,
      'vehicleOwnershipDoc': firstVeh?.ownershipDoc ?? false,

      // §2 Applicable Sections
      'selectedSections': _selectedSections.toList(),

      // §3 Spot Type
      'exactPlace': _exactPlace.text.trim(),
      'locationType': _locationType,
      'locationTypeOther': _locationTypeOther.text.trim(),

      // §4 Spot Investigation
      'spotPhotoTaken': _spotPhotoTaken,
      'spotVideoTaken': _spotVideoTaken,
      'footprintFound': _footprintFound,
      'fingerprintFound': _fingerprintFound,

      // §5 Verification Checks
      'witnessExamined': _witnessExamined,
      'socialMediaChecked': _socialMediaChecked,
      'bankAccountChecked': _bankAccountChecked,
      'tollPlazaChecked': _tollPlazaChecked,
      'fasTagChecked': _fasTagChecked,
      'anprChecked': _anprChecked,
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    // §1 Seized Vehicle
    final rawVehicles = data['seizedVehicles'];
    if (rawVehicles is List && rawVehicles.isNotEmpty) {
      while (_seizedVehicles.length > rawVehicles.length) {
        _seizedVehicles.removeLast().dispose();
      }
      for (int i = 0; i < rawVehicles.length; i++) {
        final item = rawVehicles[i];
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          if (i < _seizedVehicles.length) {
            _seizedVehicles[i].updateFrom(m);
          } else {
            _seizedVehicles.add(_SeizedVehicleEntry.fromMap(m));
          }
        }
      }
    } else if (data['vehicleEngineNumber'] != null ||
        data['vehicleRegNumber'] != null ||
        data['vehicleName'] != null ||
        data['engineNumber'] != null ||
        data['numberOfVehicles'] != null) {
      if (_seizedVehicles.isEmpty) {
        _seizedVehicles.add(_SeizedVehicleEntry.fromMap(data));
      } else {
        _seizedVehicles.first.updateFrom(data);
      }
    }

    // Always ensure at least 1 entry exists
    if (_seizedVehicles.isEmpty) {
      _seizedVehicles.add(_SeizedVehicleEntry());
    }

    // §2 Applicable Sections
    _selectedSections.clear();
    final rawSecs = data['selectedSections'];
    if (rawSecs is List) {
      _selectedSections.addAll(rawSecs.map((e) => e.toString()));
    }
    if (_selectedSections.isEmpty) {
      _selectedSections.add('303(1)');
    }

    // §3 Spot Type
    _exactPlace.text = _asString(data['exactPlace']);
    _locationType = _asStringOrNull(data['locationType']);
    _locationTypeOther.text = _asString(data['locationTypeOther']);

    // §4 Spot Investigation
    _spotPhotoTaken = _asBool(data['spotPhotoTaken']);
    _spotVideoTaken = _asBool(data['spotVideoTaken']);
    _footprintFound = _asBool(data['footprintFound']);
    _fingerprintFound = _asBool(data['fingerprintFound']);

    // §5 Verification Checks
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _sectionTitle(String title, {IconData? icon}) {
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
        if (icon != null) ...[
          Icon(icon, color: _kAmber, size: 20),
          const SizedBox(width: 8),
        ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // §1. Seized Vehicle (placed directly below Section 4 Stolen Property)
  Widget _buildSeizedVehicleSection() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Seized Vehicle', icon: Icons.directions_car_outlined),
          const SizedBox(height: 14),
          ..._seizedVehicles.asMap().entries.map((entry) {
            final i = entry.key;
            final v = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_seizedVehicles.length > 1) ...[
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
                            'Vehicle ${i + 1}',
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
                          tooltip: 'Remove Vehicle',
                          onPressed: () => setState(() {
                            v.dispose();
                            _seizedVehicles.removeAt(i);
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // 1. Number of Vehicle & 2. Name of Vehicle
                  _rowTwo(
                    TextFormField(
                      controller: v.numberOfVehicles,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration:
                          _dec('1. Number of Vehicle (e.g. 1 or MH12AB1234)'),
                    ),
                    TextFormField(
                      controller: v.vehicleName,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: _dec('2. Name of Vehicle (e.g. Tipper Truck)'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. Types of vehicle (Company Name & Type of Vehicle with Dropdown + Manual Input)
                  _rowTwo(
                    TextFormField(
                      controller: v.companyName,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: _dec('Company Name (Make)').copyWith(
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down,
                              color: _kSec, size: 24),
                          tooltip: 'Select Company',
                          onSelected: (val) {
                            setState(() {
                              if (val != 'Other') {
                                v.companyName.text = val;
                              }
                            });
                          },
                          itemBuilder: (context) => kVehicleCompanies
                              .map((c) => PopupMenuItem(
                                    value: c,
                                    child: Text(c,
                                        style:
                                            GoogleFonts.poppins(fontSize: 12)),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: v.vehicleType,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: _dec('Type of Vehicle').copyWith(
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down,
                              color: _kSec, size: 24),
                          tooltip: 'Select Type of Vehicle',
                          onSelected: (val) {
                            setState(() {
                              if (val != 'Other') {
                                v.vehicleType.text = val;
                              }
                            });
                          },
                          itemBuilder: (context) => kVehicleTypes
                              .map((t) => PopupMenuItem(
                                    value: t,
                                    child: Text(t,
                                        style:
                                            GoogleFonts.poppins(fontSize: 12)),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 4. Owner Name & Address
                  _rowTwo(
                    TextFormField(
                      controller: v.ownerName,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: _dec('4. Owner Name'),
                    ),
                    TextFormField(
                      controller: v.ownerAddress,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: _dec('Owner Address'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 5. Driver Name & Address
                  _rowTwo(
                    TextFormField(
                      controller: v.driverName,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: _dec('5. Driver Name'),
                    ),
                    TextFormField(
                      controller: v.driverAddress,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: _dec('Driver Address'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Engine Num & Chechis number
                  _rowTwo(
                    TextFormField(
                      controller: v.engineNumber,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: _dec('Engine Num'),
                    ),
                    TextFormField(
                      controller: v.chassisNumber,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: _dec('Chechis Number'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Reg Number & Unique Identification mark
                  _rowTwo(
                    TextFormField(
                      controller: v.registrationNumber,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: _dec('Reg Number'),
                    ),
                    TextFormField(
                      controller: v.uniqueIdMark,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: _dec('Unique Identification Mark'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Purchase Date
                  _dateField('Purchase Date', v.purchaseDate),
                  const SizedBox(height: 14),

                  // 6. Photo copy & 7. Ownership Doc y/n
                  _rowTwo(
                    _yesNo(
                      label: '6. Photo Copy',
                      value: v.photoCopy,
                      onChanged: (val) => setState(() => v.photoCopy = val),
                    ),
                    _yesNo(
                      label: '7. Ownership Doc (Y/N)',
                      value: v.ownershipDoc,
                      onChanged: (val) => setState(() => v.ownershipDoc = val),
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
                  setState(() => _seizedVehicles.add(_SeizedVehicleEntry())),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(
                'Add Another Seized Vehicle',
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

  // §2. Applicable Sections (Dropdown list from attached PDF)
  Widget _buildSectionsDropdownSection() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Applicable Sections (BNS & Acts)',
              icon: Icons.gavel_outlined),
          const SizedBox(height: 12),

          // Dropdown for Section selection
          DropdownButtonFormField<String>(
            initialValue: _sectionDropdownValue,
            isExpanded: true,
            hint: Text(
              'Select Section to Add (BNS 303–331 / MMDR / EPA / MLRC)',
              style: GoogleFonts.poppins(fontSize: 11.5, color: _kSec),
            ),
            style: GoogleFonts.poppins(fontSize: 12, color: _kDark),
            decoration: _dec('Add Section from Dropdown'),
            items: kSandTheftSections.map((item) {
              final sec = item['sec']!;
              final desc = item['desc']!;
              return DropdownMenuItem<String>(
                value: sec,
                child: Text(
                  'Sec $sec — $desc',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedSections.add(val);
                  _sectionDropdownValue = null;
                });
              }
            },
          ),
          const SizedBox(height: 12),

          Text(
            'SELECTED SECTIONS:',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kSec,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),

          if (_selectedSections.isEmpty)
            Text(
              'No sections added. Choose from dropdown above.',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: _kSec,
                  fontStyle: FontStyle.italic),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedSections.map((sec) {
                final match = kSandTheftSections.firstWhere(
                  (item) => item['sec'] == sec,
                  orElse: () => {'sec': sec, 'desc': 'Section $sec'},
                );
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kTeal.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sec ${match['sec']} — ${match['desc']}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kTeal,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => setState(() => _selectedSections.remove(sec)),
                        child: const Icon(Icons.close, size: 14, color: _kRed),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // §3. Spot Type
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
            decoration:
                _dec('Exact Place of Sand Theft (River Bed / Ghat / Road)'),
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
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
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
                      decoration:
                          _dec('Other Location (max 25 chars)').copyWith(
                        counterText: '${_locationTypeOther.text.length}/25',
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

  // §4. Spot Investigation Details
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

  // §5. Investigation Verification Checks
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kTeal.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.terrain_outlined,
                            color: _kTeal, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'SAND THEFT — SPECIFIC DETAILS',
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

          // §1. Seized Vehicle (directly below Section 4 Stolen Property)
          _buildSeizedVehicleSection(),

          // §2. Applicable Sections (Dropdown from PDF)
          _buildSectionsDropdownSection(),

          // §3. Spot Type
          _buildSpotTypeSection(),

          // §4. Spot Investigation Details
          _buildSpotInvestigationSection(),

          // §5. Investigation Verification Checks
          _buildInvestigationChecksSection(),
        ],
      ),
    );
  }
}
