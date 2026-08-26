import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';
import '../utils/police_hierarchy_helper.dart';

/// Modal Dialog for State Super Admin and District Admin to Onboard Sub-Admins and Station Heads.
class CreateSubAdminDialog extends StatefulWidget {
  const CreateSubAdminDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const CreateSubAdminDialog(),
    );
  }

  @override
  State<CreateSubAdminDialog> createState() => _CreateSubAdminDialogState();
}

class _CreateSubAdminDialogState extends State<CreateSubAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _badgeCtrl = TextEditingController();

  String? _selectedRole;
  String? _selectedDesignation;
  String? _selectedDistrict;
  String? _selectedDivision;
  String? _selectedStation;

  List<String> _dbDistricts = [];
  List<String> _dbDivisions = [];
  List<String> _dbStations = [];
  bool _isLoadingLocations = true;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final isSuper = PoliceHierarchyHelper.isStateSuperAdmin(auth.designation, auth.roleId);
      setState(() {
        if (isSuper) {
          _selectedRole = 'District Admin';
        } else {
          _selectedRole = 'Division Admin';
        }
      });
      _fetchDistrictsFromDB();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  List<String> _safeParseStringList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }
    if (raw is Map && raw.containsKey('results') && raw['results'] is List) {
      return (raw['results'] as List).map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }
    return [];
  }

  List<String> _safeParseStationsList(dynamic raw) {
    if (raw == null) return [];
    List<dynamic> items = [];
    if (raw is List) {
      items = raw;
    } else if (raw is Map && raw.containsKey('results') && raw['results'] is List) {
      items = raw['results'] as List;
    }
    return items.map((e) {
      if (e is Map) {
        return e['station_name']?.toString() ?? e['name']?.toString() ?? '';
      }
      return e.toString();
    }).where((s) => s.trim().isNotEmpty).toList();
  }

  /// Fetch dynamic Districts list from PostgreSQL DB
  Future<void> _fetchDistrictsFromDB() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/stations/districts/'));
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        final list = _safeParseStringList(decoded);
        if (!mounted) return;
        setState(() {
          _dbDistricts = list.isNotEmpty ? list : ['Pune', 'Mumbai', 'Thane', 'Nagpur', 'Nashik', 'Chhatrapati Sambhajinagar'];
          _selectedDistrict = _dbDistricts.first;
          _isLoadingLocations = false;
        });
        _fetchDivisionsAndStations(_selectedDistrict!);
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _dbDistricts = ['Pune', 'Mumbai', 'Thane', 'Nagpur', 'Nashik', 'Chhatrapati Sambhajinagar'];
      _selectedDistrict = 'Pune';
      _isLoadingLocations = false;
    });
    _fetchDivisionsAndStations('Pune');
  }

  /// Fetch dynamic Divisions and Stations for a given District from DB
  Future<void> _fetchDivisionsAndStations(String district) async {
    try {
      // Fetch Divisions
      final divRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/stations/divisions/?district=${Uri.encodeComponent(district)}'));
      List<String> divs = [];
      if (divRes.statusCode == 200) {
        divs = _safeParseStringList(json.decode(divRes.body));
      }

      // Fetch Stations
      final stRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/stations/?district=${Uri.encodeComponent(district)}'));
      List<String> stns = [];
      if (stRes.statusCode == 200) {
        stns = _safeParseStationsList(json.decode(stRes.body));
      }

      if (!mounted) return;
      setState(() {
        _dbDivisions = divs.isNotEmpty ? divs : ['$district Division 1', '$district Division 2', '$district Central Division'];
        _selectedDivision = _dbDivisions.first;

        _dbStations = stns.isNotEmpty ? stns : ['$district Police Station', 'Shivajinagar Police Station', 'Hadapsar Police Station'];
        _selectedStation = _dbStations.first;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dbDivisions = ['$district Division 1', '$district Division 2'];
        _selectedDivision = _dbDivisions.first;
        _dbStations = ['Shivajinagar Police Station', 'Hadapsar Police Station'];
        _selectedStation = _dbStations.first;
      });
    }
  }

  List<String> _getAllowedRoleOptions(bool isSuperAdmin) {
    if (isSuperAdmin) {
      return ['District Admin', 'Division Admin', 'Station Head'];
    } else {
      return ['Division Admin', 'Station Head'];
    }
  }

  List<String> _getDesignationOptionsForRole(String? role) {
    if (role == 'District Admin') {
      return ['CP', 'JT. CP', 'Addl. CP', 'DCP', 'SP', 'Addl. SP'];
    } else if (role == 'Division Admin') {
      return ['DySP', 'ACP', 'SDPO', 'ASP'];
    } else if (role == 'Station Head') {
      return ['PI', 'Sr. PI', 'API', 'PSI'];
    }
    return ['PI', 'ACP', 'DCP', 'SP'];
  }

  Future<void> _submitOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final payload = {
        "email": _emailCtrl.text.trim().toLowerCase(),
        "password": "Auth@123",
        "full_name": _nameCtrl.text.trim(),
        "phone": _mobileCtrl.text.replaceAll(RegExp(r'\D'), ''),
        "badge_number": _badgeCtrl.text.trim(),
        "designation": _selectedDesignation ?? "PI",
        "role_id": _selectedRole?.toLowerCase().replaceAll(" ", "_") ?? "officer",
        "state_code": auth.stateCode.isNotEmpty ? auth.stateCode : "MH",
        "district": _selectedDistrict ?? "Pune",
        "zone": _selectedRole == 'Division Admin' ? _selectedDivision : null,
        "station_name": _selectedRole == 'Station Head' ? _selectedStation : "",
      };

      final response = await http.post(
        Uri.parse(ApiConfig.authRegister),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully onboarded ${_nameCtrl.text.trim()} as $_selectedRole!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      } else {
        final data = json.decode(response.body);
        setState(() {
          _isSubmitting = false;
          _errorMessage = data['error'] ?? 'Failed to onboard sub-admin.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Connection error: $e';
      });
    }
  }

  String? _getValidValue(List<String>? list, String? selected) {
    if (list == null || list.isEmpty) return null;
    if (selected != null && list.contains(selected)) {
      return selected;
    }
    return list.first;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSuper = PoliceHierarchyHelper.isStateSuperAdmin(auth.designation, auth.roleId);
    final allowedRoles = _getAllowedRoleOptions(isSuper);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.navyDark.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.navyDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSuper ? 'Onboard District / Sub-Admin' : 'Onboard Division / Station Head',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyDark,
                            ),
                          ),
                          Text(
                            isSuper ? 'State Super Admin Provisioning Portal' : 'District Command Provisioning Portal',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.lightSubText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Divider(height: 24),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.dangerRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: AppColors.dangerRed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.dangerRed),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Role Level Selection
                Text('Admin Role Level', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _getValidValue(allowedRoles, _selectedRole),
                  items: (allowedRoles ?? [])
                      .map((r) => DropdownMenuItem(value: r, child: Text(r, style: GoogleFonts.poppins(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedRole = val;
                        _selectedDesignation = _getDesignationOptionsForRole(val).first;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Officer Full Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                ),
                const SizedBox(height: 14),

                // Designation / Rank Dropdown
                Text('Police Rank / Designation', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _getValidValue(_getDesignationOptionsForRole(_selectedRole), _selectedDesignation),
                  items: _getDesignationOptionsForRole(_selectedRole)
                      .map((d) => DropdownMenuItem(value: d, child: Text(d, style: GoogleFonts.poppins(fontSize: 13))))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedDesignation = val),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),

                // ── DYNAMIC DURATION / JURISDICTION SELECTION FROM DB ──
                if (_isLoadingLocations)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyDark)),
                  )
                else ...[
                  // 1. District Dropdown (Always required for all admin levels)
                  Text('Assigned District Jurisdiction (DB)', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _getValidValue(_dbDistricts, _selectedDistrict),
                    items: (_dbDistricts ?? [])
                        .map((d) => DropdownMenuItem(value: d, child: Text(d, style: GoogleFonts.poppins(fontSize: 13))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDistrict = val);
                        _fetchDivisionsAndStations(val);
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Division Dropdown (Only shown when Role == 'Division Admin')
                  if (_selectedRole == 'Division Admin') ...[
                    Text('Assigned Division / Zone (DB)', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _getValidValue(_dbDivisions, _selectedDivision),
                      items: (_dbDivisions ?? [])
                          .map((div) => DropdownMenuItem(value: div, child: Text(div, style: GoogleFonts.poppins(fontSize: 13))))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedDivision = val),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 3. Station Dropdown (Only shown when Role == 'Station Head')
                  if (_selectedRole == 'Station Head') ...[
                    Text('Assigned Police Station (DB)', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _getValidValue(_dbStations, _selectedStation),
                      items: (_dbStations ?? [])
                          .map((stn) => DropdownMenuItem(value: stn, child: Text(stn, style: GoogleFonts.poppins(fontSize: 13))))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedStation = val),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ],

                // Contact Inputs Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _mobileCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.phone_android),
                        ),
                        validator: (v) => v == null || v.length != 10 ? 'Enter valid 10-digit mobile' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _badgeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Badge No. (Buckle No.)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Government Email Address',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isSubmitting ? null : _submitOnboarding,
                    icon: _isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_rounded, color: Colors.white),
                    label: Text(
                      _isSubmitting ? 'Onboarding...' : 'Create & Provision Account',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
