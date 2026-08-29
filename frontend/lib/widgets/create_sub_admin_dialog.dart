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
  final _passwordCtrl = TextEditingController(text: 'Admin@123');

  bool _obscurePassword = true;

  String? _selectedRole = 'District Admin';
  String? _selectedDesignation = 'CP';
  String? _selectedDistrict = 'Pune';
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
        _selectedDesignation = _getDesignationOptionsForRole(_selectedRole).first;
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
    _passwordCtrl.dispose();
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
    AdminLevel level = AdminLevel.stationAdmin;
    if (role == 'State Admin' || role == 'State Super Admin') {
      level = AdminLevel.stateAdmin;
    } else if (role == 'District Admin') {
      level = AdminLevel.districtAdmin;
    } else if (role == 'Division Admin') {
      level = AdminLevel.divisionAdmin;
    } else if (role == 'Station Head' || role == 'Station Admin') {
      level = AdminLevel.stationAdmin;
    }
    return PoliceHierarchyHelper.getAllowedDesignations(level);
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
        "password": _passwordCtrl.text.trim(),
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
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 780,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.navyMid.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
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
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.lightSubText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          tooltip: 'Close',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            padding: const EdgeInsets.all(6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),

                    // Error Alert (if any)
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerRed.withValues(alpha: 0.08),
                          border: Border.all(color: AppColors.dangerRed.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.dangerRed),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.dangerRed, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Two-Column Balanced Form (Hierarchy Left, Officer Details Right)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 620;

                        final leftColumn = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(Icons.account_tree_outlined, 'Jurisdiction & Hierarchy'),
                            const SizedBox(height: 10),

                            // Role Level
                            _buildInputLabel('Admin Role Level'),
                            DropdownButtonFormField<String>(
                              value: _getValidValue(allowedRoles, _selectedRole),
                              isExpanded: true,
                              items: (allowedRoles ?? [])
                                  .map((r) => DropdownMenuItem(value: r, child: Text(r, style: GoogleFonts.poppins(fontSize: 12.5))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedRole = val;
                                    _selectedDesignation = _getDesignationOptionsForRole(val).first;
                                  });
                                }
                              },
                              decoration: _buildInputDecoration(prefixIcon: Icons.military_tech_outlined),
                            ),
                            const SizedBox(height: 10),

                            // Police Rank / Designation
                            _buildInputLabel('Police Rank / Designation'),
                            DropdownButtonFormField<String>(
                              value: _getValidValue(_getDesignationOptionsForRole(_selectedRole), _selectedDesignation),
                              isExpanded: true,
                              items: _getDesignationOptionsForRole(_selectedRole)
                                  .map((d) => DropdownMenuItem(value: d, child: Text(d, style: GoogleFonts.poppins(fontSize: 12.5))))
                                  .toList(),
                              onChanged: (val) => setState(() => _selectedDesignation = val),
                              decoration: _buildInputDecoration(prefixIcon: Icons.badge_outlined),
                            ),
                            const SizedBox(height: 10),

                            // District Jurisdiction
                            _buildInputLabel('Assigned District Jurisdiction (DB)'),
                            if (_isLoadingLocations)
                              const SizedBox(
                                height: 42,
                                child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyDark))),
                              )
                            else
                              DropdownButtonFormField<String>(
                                value: _getValidValue(_dbDistricts, _selectedDistrict),
                                isExpanded: true,
                                items: (_dbDistricts ?? [])
                                    .map((d) => DropdownMenuItem(value: d, child: Text(d, style: GoogleFonts.poppins(fontSize: 12.5))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedDistrict = val);
                                    _fetchDivisionsAndStations(val);
                                  }
                                },
                                decoration: _buildInputDecoration(prefixIcon: Icons.location_city_outlined),
                              ),
                            const SizedBox(height: 10),

                            // Dynamic sub-jurisdiction or district command badge to maintain perfect height symmetry
                            if (_selectedRole == 'Division Admin') ...[
                              _buildInputLabel('Assigned Division / Zone (DB)'),
                              DropdownButtonFormField<String>(
                                value: _getValidValue(_dbDivisions, _selectedDivision),
                                isExpanded: true,
                                items: (_dbDivisions ?? [])
                                    .map((div) => DropdownMenuItem(value: div, child: Text(div, style: GoogleFonts.poppins(fontSize: 12.5))))
                                    .toList(),
                                onChanged: (val) => setState(() => _selectedDivision = val),
                                decoration: _buildInputDecoration(prefixIcon: Icons.hub_outlined),
                              ),
                            ] else if (_selectedRole == 'Station Head') ...[
                              _buildInputLabel('Assigned Police Station (DB)'),
                              DropdownButtonFormField<String>(
                                value: _getValidValue(_dbStations, _selectedStation),
                                isExpanded: true,
                                items: (_dbStations ?? [])
                                    .map((stn) => DropdownMenuItem(value: stn, child: Text(stn, style: GoogleFonts.poppins(fontSize: 12.5))))
                                    .toList(),
                                onChanged: (val) => setState(() => _selectedStation = val),
                                decoration: _buildInputDecoration(prefixIcon: Icons.local_police_outlined),
                              ),
                            ] else ...[
                              _buildInputLabel('Jurisdiction Scope'),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.navyDark.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blueGrey.shade100),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.verified_user_outlined, size: 18, color: AppColors.navyMid),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Full District Command: Supervises all divisions & stations',
                                        style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.navyDark, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );

                        final rightColumn = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(Icons.person_outline_rounded, 'Officer Identity & Credentials'),
                            const SizedBox(height: 10),

                            // Officer Full Name
                            _buildInputLabel('Officer Full Name'),
                            TextFormField(
                              controller: _nameCtrl,
                              style: GoogleFonts.poppins(fontSize: 12.5),
                              decoration: _buildInputDecoration(
                                hintText: 'e.g. Ramesh K. Patil',
                                prefixIcon: Icons.person_rounded,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                            ),
                            const SizedBox(height: 10),

                            // Mobile & Badge side-by-side
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('Mobile Number'),
                                      TextFormField(
                                        controller: _mobileCtrl,
                                        keyboardType: TextInputType.phone,
                                        style: GoogleFonts.poppins(fontSize: 12.5),
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                                        decoration: _buildInputDecoration(
                                          hintText: '10-digit number',
                                          prefixIcon: Icons.phone_android_rounded,
                                        ),
                                        validator: (v) => v == null || v.length != 10 ? 'Enter 10-digits' : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('Badge / Buckle No.'),
                                      TextFormField(
                                        controller: _badgeCtrl,
                                        style: GoogleFonts.poppins(fontSize: 12.5),
                                        decoration: _buildInputDecoration(
                                          hintText: 'e.g. MH-1244',
                                          prefixIcon: Icons.pin_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Email Address
                            _buildInputLabel('Government Email Address'),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.poppins(fontSize: 12.5),
                              decoration: _buildInputDecoration(
                                hintText: 'officer@mahapolice.gov.in',
                                prefixIcon: Icons.alternate_email_rounded,
                              ),
                              validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
                            ),
                            const SizedBox(height: 10),

                            // Password Field (With Show / Hide Toggle)
                            _buildInputLabel('Login Password'),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.poppins(fontSize: 12.5),
                              decoration: _buildInputDecoration(
                                hintText: 'Initial access password',
                                prefixIcon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 18,
                                    color: AppColors.lightSubText,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                            ),
                          ],
                        );

                        if (isCompact) {
                          return Column(
                            children: [
                              leftColumn,
                              const SizedBox(height: 14),
                              rightColumn,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: leftColumn),
                            const SizedBox(width: 20),
                            Expanded(child: rightColumn),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),

                    // Actions Footer Row
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        OutlinedButton(
                          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.lightSubText,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navyDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                          ),
                          onPressed: _isSubmitting ? null : _submitOnboarding,
                          icon: _isSubmitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          label: Text(
                            _isSubmitting ? 'Provisioning...' : 'Create & Provision Account',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.navyMid),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.navyMid,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? hintText, IconData? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 17, color: AppColors.navyMid.withValues(alpha: 0.8)) : null,
      suffixIcon: suffixIcon,
      fillColor: const Color(0xFFF8FAFC),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.navyMid, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.dangerRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.dangerRed, width: 1.5),
      ),
    );
  }
}
