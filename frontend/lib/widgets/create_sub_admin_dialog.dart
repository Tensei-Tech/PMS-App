import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';
import '../services/case_service.dart';
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
  final _divisionCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stationCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(text: 'Admin@123');

  bool _obscurePassword = true;

  String? _selectedRole = 'District Admin';
  String? _selectedDesignation = 'CP';
  String? _selectedDistrict = 'Pune';
  String? _selectedStation;

  List<String> _dbDistricts = [];
  List<String> _dbStations = [];
  bool _isLoadingLocations = true;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      setState(() {
        _selectedRole = _getAllowedRoleOptions(auth).first;
        _selectedDesignation =
            _getDesignationOptionsForRole(_selectedRole).first;
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
    _divisionCtrl.dispose();
    _cityCtrl.dispose();
    _stationCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Fetch dynamic Districts list from PostgreSQL DB: GET /api/districts/
  Future<void> _fetchDistrictsFromDB() async {
    setState(() => _isLoadingLocations = true);
    try {
      final data = await CaseService().fetchDistricts();
      var list = data
          .map((e) => (e['name'] ?? '').toString().trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (!mounted) return;
      // District and division admins onboard only inside their own district.
      final auth = context.read<AuthProvider>();
      if (_districtIsFixed(auth)) {
        list = [auth.district];
      }
      if (list.isNotEmpty) {
        setState(() {
          _dbDistricts = list;
          _selectedDistrict = _dbDistricts.first;
          _isLoadingLocations = false;
        });
        _fetchStations(_selectedDistrict!);
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CreateSubAdminDialog] Error fetching districts: $e');
      }
    }
    if (!mounted) return;
    setState(() => _isLoadingLocations = false);
  }

  /// Fetch the Stations of a District from DB: GET /api/stations/?district_id=...
  Future<void> _fetchStations(String district) async {
    try {
      final stnsData = await CaseService().fetchStations(districtId: district);
      List<String> stns = stnsData
          .map((s) => (s['name'] ?? '').toString().trim())
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (!mounted) return;
      setState(() {
        _dbStations = stns;
        if (_dbStations.isNotEmpty) {
          _selectedStation = _dbStations.first;
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CreateSubAdminDialog] Error fetching stations: $e');
      }
    }
  }

  // The role decides, as on the server: a city or district admin with
  // designation DG is not a state admin.
  bool _isStateCaller(AuthProvider auth) =>
      PoliceHierarchyHelper.adminLevelOf(auth.designation, auth.roleId) ==
      AdminLevel.stateAdmin;

  /// A city (police commissionerate) admin works like a district admin; the
  /// city is kept as their district until cities get their own list.
  bool _isCityCaller(AuthProvider auth) =>
      !_isStateCaller(auth) && auth.roleId.toLowerCase() == 'city_admin';

  bool _isDistrictCaller(AuthProvider auth) =>
      !_isStateCaller(auth) &&
      ['district_admin', 'city_admin'].contains(auth.roleId.toLowerCase());

  bool _isDivisionCaller(AuthProvider auth) =>
      !_isStateCaller(auth) &&
      !_isDistrictCaller(auth) &&
      ['division_admin', 'supervisor'].contains(auth.roleId.toLowerCase());

  /// Each admin onboards only the levels below them, in the order
  /// state > district or city > division (a sub-division) > station:
  /// state -> district, city, division, station head; district or city ->
  /// division, station head; division -> station head.
  List<String> _getAllowedRoleOptions(AuthProvider auth) {
    if (_isStateCaller(auth)) {
      return ['District Admin', 'City Admin', 'Division Admin', 'Station Head'];
    }
    if (_isDistrictCaller(auth)) {
      return ['Division Admin', 'Station Head'];
    }
    return ['Station Head'];
  }

  /// City designations: for a City Admin and everyone a city admin onboards.
  static const _cityDesignations = [
    'DG',
    'ADG',
    'CP',
    'Jt.CP',
    'Addl. CP',
    'DCP',
    'ACP',
    'PI',
    'API',
    'PSI',
  ];

  /// District designations: for a District Admin and everyone a district
  /// admin onboards.
  static const _districtDesignations = [
    'DG',
    'ADG',
    'IG',
    'DIG',
    'SP',
    'Addl. SP',
    'SDPO',
    'PI',
    'API',
    'PSI',
  ];

  /// The station of a new station head: picked from the DB list, or typed
  /// when the district or city has no stations in the DB yet.
  String _stationFor() =>
      _dbStations.isEmpty ? _stationCtrl.text.trim() : (_selectedStation ?? '');

  /// District and division admins onboard only inside their own district.
  bool _districtIsFixed(AuthProvider auth) =>
      (_isDistrictCaller(auth) || _isDivisionCaller(auth)) &&
      auth.district.isNotEmpty;

  /// The sub-division the new account belongs to: the one typed for a new
  /// division admin, or a division admin's own for their station heads.
  String _divisionFor(AuthProvider auth) {
    if (_selectedRole == 'Division Admin') return _divisionCtrl.text.trim();
    if (_isDivisionCaller(auth)) return auth.divisionName;
    return '';
  }

  bool _showsDivisionPicker(AuthProvider auth) =>
      _selectedRole == 'Division Admin';

  List<String> _getDesignationOptionsForRole(String? role) {
    final auth = context.read<AuthProvider>();
    if (role == 'City Admin' || _isCityCaller(auth)) {
      return _cityDesignations;
    }
    if (role == 'District Admin' ||
        auth.roleId.toLowerCase() == 'district_admin') {
      return _districtDesignations;
    }
    // A division admin sits under a city or a district: either list.
    if (role == 'Division Admin') {
      return {..._cityDesignations, ..._districtDesignations}.toList();
    }
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
        "role_id":
            _selectedRole?.toLowerCase().replaceAll(" ", "_") ?? "officer",
        "state_code": auth.stateCode.isNotEmpty ? auth.stateCode : "MH",
        // A city admin's city goes in 'district' until cities get a list.
        "district": _selectedRole == 'City Admin'
            ? _cityCtrl.text.trim()
            : (_selectedDistrict ?? "Pune"),
        "division_name": _divisionFor(auth),
        "zone": _selectedRole == 'Division Admin' ? _divisionFor(auth) : null,
        "station_name": _selectedRole == 'Station Head' ? _stationFor() : "",
      };

      // Send the admin's own token: the backend activates the account at once
      // only when the logged-in admin is allowed to approve it.
      final token = await ApiService().getAuthToken();
      final response = await http.post(
        Uri.parse(ApiConfig.authRegister),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully onboarded ${_nameCtrl.text.trim()} as $_selectedRole!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      } else if (response.statusCode == 202) {
        // Saved and waiting in Pending Approvals, for this admin or anyone
        // above them in the area to approve.
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_nameCtrl.text.trim()} was created. Approve it in Officer Approvals (Pending).'),
            backgroundColor: Colors.orange.shade800,
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
    final allowedRoles = _getAllowedRoleOptions(auth);

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
                          child: const Icon(Icons.admin_panel_settings_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Onboard ${allowedRoles.join(' / ')}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              Text(
                                _isStateCaller(auth)
                                    ? 'State Super Admin Provisioning Portal'
                                    : _isDivisionCaller(auth)
                                        ? 'Division Command Provisioning Portal'
                                        : 'District Command Provisioning Portal',
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerRed.withValues(alpha: 0.08),
                          border: Border.all(
                              color:
                                  AppColors.dangerRed.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 16, color: AppColors.dangerRed),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.dangerRed,
                                    fontWeight: FontWeight.w500),
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
                            _buildSectionHeader(Icons.account_tree_outlined,
                                'Jurisdiction & Hierarchy'),
                            const SizedBox(height: 10),

                            // Role Level
                            _buildInputLabel('Admin Role Level'),
                            DropdownButtonFormField<String>(
                              initialValue:
                                  _getValidValue(allowedRoles, _selectedRole),
                              isExpanded: true,
                              items: allowedRoles
                                  .map((r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(r,
                                          style: GoogleFonts.poppins(
                                              fontSize: 12.5))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedRole = val;
                                    _selectedDesignation =
                                        _getDesignationOptionsForRole(val)
                                            .first;
                                  });
                                }
                              },
                              decoration: _buildInputDecoration(
                                  prefixIcon: Icons.military_tech_outlined),
                            ),
                            const SizedBox(height: 10),

                            // Police Rank / Designation
                            _buildInputLabel('Police Rank / Designation'),
                            DropdownButtonFormField<String>(
                              initialValue: _getValidValue(
                                  _getDesignationOptionsForRole(_selectedRole),
                                  _selectedDesignation),
                              isExpanded: true,
                              items:
                                  _getDesignationOptionsForRole(_selectedRole)
                                      .map((d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(d,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12.5))))
                                      .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedDesignation = val),
                              decoration: _buildInputDecoration(
                                  prefixIcon: Icons.badge_outlined),
                            ),
                            const SizedBox(height: 10),

                            // District Jurisdiction
                            _buildInputLabel(_selectedRole == 'City Admin'
                                ? 'City (Police Commissionerate)'
                                : 'Assigned District Jurisdiction (DB)'),
                            if (_selectedRole == 'City Admin')
                              // Cities have no list in the DB yet: type it.
                              TextFormField(
                                controller: _cityCtrl,
                                style: GoogleFonts.poppins(fontSize: 12.5),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Enter the city'
                                        : null,
                                decoration: _buildInputDecoration(
                                    hintText: 'City name, e.g. Pune City',
                                    prefixIcon: Icons.location_city_outlined),
                              )
                            else if (_isLoadingLocations)
                              const SizedBox(
                                height: 42,
                                child: Center(
                                    child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.navyDark))),
                              )
                            else
                              DropdownButtonFormField<String>(
                                initialValue: _getValidValue(
                                    _dbDistricts, _selectedDistrict),
                                isExpanded: true,
                                items: _dbDistricts
                                    .map((d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(d,
                                            style: GoogleFonts.poppins(
                                                fontSize: 12.5))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedDistrict = val);
                                    _fetchStations(val);
                                  }
                                },
                                decoration: _buildInputDecoration(
                                    prefixIcon: Icons.location_city_outlined),
                              ),
                            const SizedBox(height: 10),

                            // Dynamic sub-jurisdiction or district command badge to maintain perfect height symmetry
                            if (_showsDivisionPicker(auth)) ...[
                              // A division is a sub-division of the district
                              // above; the list of them is not in the DB yet.
                              _buildInputLabel(
                                  'Sub-Division Name (within the district)'),
                              TextFormField(
                                controller: _divisionCtrl,
                                style: GoogleFonts.poppins(fontSize: 12.5),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Enter the sub-division name'
                                        : null,
                                decoration: _buildInputDecoration(
                                    hintText: 'e.g. Shirdi Sub-Division',
                                    prefixIcon: Icons.hub_outlined),
                              ),
                            ] else if (_selectedRole == 'Station Head' &&
                                _dbStations.isEmpty) ...[
                              // No stations in the DB for this district or
                              // city yet (e.g. a new city): type the name.
                              _buildInputLabel('Police Station Name'),
                              TextFormField(
                                controller: _stationCtrl,
                                style: GoogleFonts.poppins(fontSize: 12.5),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Enter the police station'
                                        : null,
                                decoration: _buildInputDecoration(
                                    hintText:
                                        'e.g. Shivajinagar Police Station',
                                    prefixIcon: Icons.local_police_outlined),
                              ),
                            ] else if (_selectedRole == 'Station Head') ...[
                              _buildInputLabel('Assigned Police Station (DB)'),
                              DropdownButtonFormField<String>(
                                initialValue: _getValidValue(
                                    _dbStations, _selectedStation),
                                isExpanded: true,
                                items: _dbStations
                                    .map((stn) => DropdownMenuItem(
                                        value: stn,
                                        child: Text(stn,
                                            style: GoogleFonts.poppins(
                                                fontSize: 12.5))))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedStation = val),
                                decoration: _buildInputDecoration(
                                    prefixIcon: Icons.local_police_outlined),
                              ),
                            ] else ...[
                              _buildInputLabel('Jurisdiction Scope'),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.navyDark
                                      .withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.blueGrey.shade100),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.verified_user_outlined,
                                        size: 18, color: AppColors.navyMid),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Full District Command: Supervises all divisions & stations',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            color: AppColors.navyDark,
                                            fontWeight: FontWeight.w500),
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
                            _buildSectionHeader(Icons.person_outline_rounded,
                                'Officer Identity & Credentials'),
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
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Full name is required'
                                  : null,
                            ),
                            const SizedBox(height: 10),

                            // Mobile & Badge side-by-side
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('Mobile Number'),
                                      TextFormField(
                                        controller: _mobileCtrl,
                                        keyboardType: TextInputType.phone,
                                        style:
                                            GoogleFonts.poppins(fontSize: 12.5),
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(10)
                                        ],
                                        decoration: _buildInputDecoration(
                                          hintText: '10-digit number',
                                          prefixIcon:
                                              Icons.phone_android_rounded,
                                        ),
                                        validator: (v) =>
                                            v == null || v.length != 10
                                                ? 'Enter 10-digits'
                                                : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('Badge / Buckle No.'),
                                      TextFormField(
                                        controller: _badgeCtrl,
                                        style:
                                            GoogleFonts.poppins(fontSize: 12.5),
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
                              validator: (v) => v == null || !v.contains('@')
                                  ? 'Enter valid email'
                                  : null,
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
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: AppColors.lightSubText,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) => v == null || v.length < 6
                                  ? 'Min 6 characters'
                                  : null,
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
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.lightSubText,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 11),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Cancel',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navyDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 11),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                          ),
                          onPressed: _isSubmitting ? null : _submitOnboarding,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 18),
                          label: Text(
                            _isSubmitting
                                ? 'Provisioning...'
                                : 'Create & Provision Account',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.white),
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

  InputDecoration _buildInputDecoration(
      {String? hintText, IconData? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon,
              size: 17, color: AppColors.navyMid.withValues(alpha: 0.8))
          : null,
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
