// lib/screens/register_screen.dart
// Self-registration with posting location, identity photos, and active Mobile & Email OTP verification.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/state_language_helper.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/validators.dart';
import '../widgets/searchable_picker_field.dart';
import 'pending_approval_screen.dart';

/// Dynamic Police Rank & Role capability model loaded directly from PostgreSQL
class RankRoleConfig {
  final String code;
  final String title;
  final String displayName;
  final int rankLevel;
  final String roleType;
  final List<String> allowedCategories;
  final List<String> allowedAdminRoles;
  final String requiredHierarchyLevel;
  final String approvingAuthority;
  final String? impliedUnitType;

  RankRoleConfig({
    required this.code,
    required this.title,
    required this.displayName,
    required this.rankLevel,
    required this.roleType,
    required this.allowedCategories,
    required this.allowedAdminRoles,
    required this.requiredHierarchyLevel,
    required this.approvingAuthority,
    this.impliedUnitType,
  });

  factory RankRoleConfig.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic raw, {List<String> fallback = const []}) {
      dynamic value = raw;
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return fallback;
        try {
          value = jsonDecode(trimmed);
        } catch (_) {
          return fallback;
        }
      }
      if (value is List) {
        final result = value
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
        return result.isNotEmpty ? result : fallback;
      }
      return fallback;
    }

    final cats = parseStringList(json['allowed_categories'], fallback: ['field_officer']);
    final roles = parseStringList(json['allowed_admin_roles']);

    return RankRoleConfig(
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? json['title']?.toString() ?? json['code']?.toString() ?? '',
      rankLevel: json['rank_level'] is int
          ? json['rank_level'] as int
          : int.tryParse(json['rank_level']?.toString() ?? '12') ?? 12,
      roleType: json['role_type']?.toString() ?? 'staff_only',
      allowedCategories: cats,
      allowedAdminRoles: roles,
      requiredHierarchyLevel: json['required_hierarchy_level']?.toString() ?? 'station',
      approvingAuthority: json['approving_authority']?.toString() ?? 'station_admin',
      impliedUnitType: json['implied_unit_type']?.toString(),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  String _registrationCategory = 'field_officer';
  String _selectedAdminRole = 'district_admin';

  String? _designation;
  String? _selectedUnitType;
  XFile? _idCardFile;
  XFile? _selfieFile;
  Uint8List? _idCardPreviewBytes;
  Uint8List? _selfiePreviewBytes;

  final _fullNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _govtIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // OTP Verification State
  static const String _mockOtp = '123456';
  final _mobileOtpCtrl = TextEditingController();
  final _emailOtpCtrl = TextEditingController();

  bool _mobileVerified = false;
  bool _emailVerified = false;
  bool _mobileOtpSent = false;
  bool _emailOtpSent = false;

  int _mobileSecondsLeft = 0;
  int _emailSecondsLeft = 0;
  Timer? _mobileTimer;
  Timer? _emailTimer;

  String? _mobileOtpError;
  String? _emailOtpError;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _bootstrapLocationData();
    _fetchRankConfigs();

    _mobileCtrl.addListener(() {
      if (mounted && _mobileVerified && _mobileCtrl.text.length != 10) {
        setState(() {
          _mobileVerified = false;
          _mobileOtpSent = false;
          _mobileOtpCtrl.clear();
        });
      }
    });

    _emailCtrl.addListener(() {
      if (mounted && _emailVerified) {
        setState(() {
          _emailVerified = false;
          _emailOtpSent = false;
          _emailOtpCtrl.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _mobileTimer?.cancel();
    _emailTimer?.cancel();
    _fullNameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _govtIdCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _mobileOtpCtrl.dispose();
    _emailOtpCtrl.dispose();
    super.dispose();
  }

  List<Map<String, String>> _dynamicStates = [];
  List<String> _dynamicDivisions = [];
  List<String> _dynamicDistricts = [];
  List<String> _dynamicStations = [];
  List<RankRoleConfig> _rankConfigs = [];
  bool _loadingRankConfigs = false;

  String? _selectedStateCode = 'MH';
  String _selectedState = 'Maharashtra';
  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedStation;

  Future<void> _fetchRankConfigs() async {
    setState(() => _loadingRankConfigs = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/master/hierarchy/rank-configs/'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List data = (decoded is List)
            ? decoded
            : ((decoded is Map && decoded.containsKey('results')) ? decoded['results'] as List : []);
        final list = data
            .map((item) => RankRoleConfig.fromJson(item as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _rankConfigs = list;
            _loadingRankConfigs = false;
          });
          if (_designation != null && _designation!.isNotEmpty) {
            _onDesignationChanged(_designation);
          }
        }
        return;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[RegisterScreen] Failed to load rank configs: $e');
    }
    if (mounted) setState(() => _loadingRankConfigs = false);
  }

  Future<void> _bootstrapLocationData() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.masterStates));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data is Map && data.containsKey('results')) ? data['results'] as List : (data as List);
        final states = <Map<String, String>>[];
        for (final item in list) {
          if (item['is_active'] == true && item['state_name'] != null) {
            states.add({
              'code': item['state_code'].toString(),
              'name': item['state_name'].toString(),
            });
          }
        }
        if (states.isNotEmpty) {
          _dynamicStates = states;
          final mhState = states.firstWhere((s) => s['code'] == 'MH', orElse: () => states.first);
          _selectedStateCode = mhState['code'];
          _selectedState = mhState['name']!;
        }
      }
    } catch (_) {}

    final stCode = _selectedStateCode ?? 'MH';
    await _fetchDynamicDivisions(stCode);
    await _fetchDynamicDistricts(stCode);
  }

  Future<void> _fetchDynamicDivisions(String stateCode) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/master/hierarchy/divisions/?state_code=$stateCode'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List data = (decoded is List) ? decoded : ((decoded is Map && decoded.containsKey('results')) ? decoded['results'] as List : []);
        final divisions = data
            .map((e) => (e is Map ? (e['name'] ?? '') : e).toString().trim())
            .where((s) => s.isNotEmpty && s != 'null')
            .toList()
          ..sort();
        if (mounted) {
          setState(() {
            _dynamicDivisions = divisions;
          });
        }
        return;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching divisions: $e');
    }
  }

  Future<void> _fetchDynamicDistricts(String stateCode) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/master/hierarchy/districts/?state_code=$stateCode'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List data = (decoded is List) ? decoded : ((decoded is Map && decoded.containsKey('results')) ? decoded['results'] as List : []);
        final districts = data
            .map((e) => (e is Map ? (e['name'] ?? '') : e).toString().trim())
            .where((s) => s.isNotEmpty && s != 'null')
            .toList()
          ..sort();
        if (mounted) {
          setState(() {
            _dynamicDistricts = districts;
          });
        }
        return;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching districts: $e');
    }
  }

  Future<void> _fetchDynamicStations(String districtName) async {
    if (districtName.trim().isEmpty) return;
    try {
      final encodedDist = Uri.encodeComponent(districtName.trim());
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/master/hierarchy/stations/?district=$encodedDist'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List data = (decoded is List) ? decoded : ((decoded is Map && decoded.containsKey('results')) ? decoded['results'] as List : []);
        final stations = data
            .map((e) => (e is Map ? (e['name'] ?? e['station_name'] ?? '') : e).toString().trim())
            .where((s) => s.isNotEmpty && s != 'null')
            .toList()
          ..sort();
        if (mounted) {
          setState(() {
            _dynamicStations = stations;
          });
        }
        return;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching stations: $e');
    }
  }

  List<String> _divisionsForSelection() => _dynamicDivisions;
  List<String> _districtsForSelection() => _dynamicDistricts;
  List<String> _stationsForSelection() => _dynamicStations;

  String _buildStationAddress() {
    final dist = _selectedDistrict?.trim() ?? '';
    final state = _selectedState.trim();
    final unit = _selectedUnitType?.trim() ?? '';
    return '$dist, $state • $unit';
  }

  void _clearLocationSelection() {
    _selectedDistrict = null;
    _selectedStation = null;
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: color,
      ),
    );
  }

  // ── OTP Handlers ──

  void _sendMobileOtp() {
    final mobile = _mobileCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (mobile.length != 10) {
      _showSnack('Please enter a valid 10-digit mobile number.', AppColors.warningOrange);
      return;
    }

    setState(() {
      _mobileOtpSent = true;
      _mobileVerified = false;
      _mobileOtpError = null;
      _mobileSecondsLeft = 60;
    });

    _mobileTimer?.cancel();
    _mobileTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_mobileSecondsLeft <= 1) {
        t.cancel();
        setState(() => _mobileSecondsLeft = 0);
      } else {
        setState(() => _mobileSecondsLeft--);
      }
    });

    // Auto-fill dev OTP for seamless development
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _mobileOtpCtrl.text = _mockOtp);
    });

    _showSnack('OTP sent to +91 $mobile (Dev Mode: 123456)', AppColors.infoBlue);
  }

  void _verifyMobileOtp() {
    final code = _mobileOtpCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _mobileOtpError = 'Enter 6-digit OTP');
      return;
    }
    if (code != _mockOtp) {
      setState(() => _mobileOtpError = 'Invalid OTP. Enter 123456');
      return;
    }

    setState(() {
      _mobileVerified = true;
      _mobileOtpError = null;
      _mobileOtpSent = false;
    });
    _mobileTimer?.cancel();
    _showSnack('Mobile number verified successfully!', AppColors.successGreen);
  }

  void _sendEmailOtp() {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (!email.contains('@') || !email.contains('.')) {
      _showSnack('Please enter a valid government email address.', AppColors.warningOrange);
      return;
    }

    setState(() {
      _emailOtpSent = true;
      _emailVerified = false;
      _emailOtpError = null;
      _emailSecondsLeft = 60;
    });

    _emailTimer?.cancel();
    _emailTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_emailSecondsLeft <= 1) {
        t.cancel();
        setState(() => _emailSecondsLeft = 0);
      } else {
        setState(() => _emailSecondsLeft--);
      }
    });

    // Auto-fill dev OTP for seamless development
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _emailOtpCtrl.text = _mockOtp);
    });

    _showSnack('OTP sent to $email (Dev Mode: 123456)', AppColors.infoBlue);
  }

  void _verifyEmailOtp() {
    final code = _emailOtpCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _emailOtpError = 'Enter 6-digit OTP');
      return;
    }
    if (code != _mockOtp) {
      setState(() => _emailOtpError = 'Invalid OTP. Enter 123456');
      return;
    }

    setState(() {
      _emailVerified = true;
      _emailOtpError = null;
      _emailOtpSent = false;
    });
    _emailTimer?.cancel();
    _showSnack('Email address verified successfully!', AppColors.successGreen);
  }

  Future<void> _pickImage({required bool isIdCard}) async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        if (isIdCard) {
          _idCardFile = file;
          _idCardPreviewBytes = bytes;
        } else {
          _selfieFile = file;
          _selfiePreviewBytes = bytes;
        }
      });
    } catch (e) {
      _showSnack('Could not pick image: $e', AppColors.dangerRed);
    }
  }

  void _clearImage({required bool isIdCard}) {
    setState(() {
      if (isIdCard) {
        _idCardFile = null;
        _idCardPreviewBytes = null;
      } else {
        _selfieFile = null;
        _selfiePreviewBytes = null;
      }
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('Please correct the highlighted errors.', AppColors.warningOrange);
      return;
    }

    if (!_mobileVerified) {
      _showSnack('Please verify your Mobile Number with OTP first.', AppColors.warningOrange);
      return;
    }

    if (!_emailVerified) {
      _showSnack('Please verify your Government Email with OTP first.', AppColors.warningOrange);
      return;
    }

    if (_passwordCtrl.text.trim() != _confirmPasswordCtrl.text.trim()) {
      _showSnack('Passwords do not match.', AppColors.dangerRed);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthProvider>();
      final email = _emailCtrl.text.trim().toLowerCase();
      final mobile = _mobileCtrl.text.replaceAll(RegExp(r'\D'), '');

      final result = await auth.registerWithPin(
        fullName: _fullNameCtrl.text.trim(),
        designation: _designation ?? 'PI',
        email: email,
        phone: mobile,
        pin: _passwordCtrl.text.trim(),
        idCardFile: _idCardFile,
        selfieFile: _selfieFile,
        stationName: _selectedStation ?? '',
        stationAddress: _buildStationAddress(),
        stationLandline: '',
        district: _selectedDistrict ?? '',
        govtId: _govtIdCtrl.text.trim().isNotEmpty ? _govtIdCtrl.text.trim() : email,
      );

      if (!mounted) return;

      if (!result.success) {
        final errorMsg = result.errorMessage ?? 'Registration failed. Please try again.';
        _showSnack(errorMsg, AppColors.dangerRed);
        return;
      }

      _showSnack('Registration submitted successfully for approval.', AppColors.successGreen);

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      try {
        await auth.signOutToLogin();
      } catch (_) {}

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        AppTheme.fadeSlideRoute(page: const PendingApprovalScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Registration failed: $e', AppColors.dangerRed);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navyBrandColor = Color(0xFF1E2968);
    const subtitleColor = Color(0xFF64748B);

    return Theme(
      data: AppTheme.lightTheme(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Navigation & Header
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EDF5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                                }
                              },
                              icon: const Icon(Icons.arrow_back_rounded, color: navyBrandColor, size: 20),
                              tooltip: 'Back to Login',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: navyBrandColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.local_police_rounded,
                              color: Color(0xFFFFB300),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registration',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                'Officer account registration portal',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: subtitleColor,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Card 1: Personal & Contact Information
                      _buildSectionCard(
                        icon: Icons.person_rounded,
                        title: 'Personal & Contact Information',
                        subtitle: 'Enter full name, official government ID, and verify contact details.',
                        children: [
                          _buildCustomTextField(
                            controller: _fullNameCtrl,
                            hintText: 'Full Name',
                            icon: Icons.person_outline_rounded,
                            validator: AppValidators.fullName,
                          ),
                          const SizedBox(height: 12),
                          _buildCustomTextField(
                            controller: _govtIdCtrl,
                            hintText: 'Government ID / Seva Number',
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 12),

                          // Mobile Input & Verification Row
                          _buildCustomTextField(
                            controller: _mobileCtrl,
                            hintText: 'Mobile Number',
                            icon: Icons.smartphone_rounded,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: AppValidators.phone,
                            onChanged: (_) => setState(() {}),
                            suffixIcon: _buildOtpFieldSuffix(
                              isVerified: _mobileVerified,
                              isEligible: _mobileCtrl.text.replaceAll(RegExp(r'\D'), '').length == 10,
                              onGetOtp: _sendMobileOtp,
                            ),
                          ),
                          if (_mobileOtpSent && !_mobileVerified) ...[
                            const SizedBox(height: 10),
                            _buildInlineOtpBox(
                              title: 'Mobile OTP Verification',
                              controller: _mobileOtpCtrl,
                              secondsLeft: _mobileSecondsLeft,
                              errorMessage: _mobileOtpError,
                              onVerify: _verifyMobileOtp,
                              onResend: _sendMobileOtp,
                            ),
                          ],
                          const SizedBox(height: 12),

                          // Email Input & Verification Row
                          _buildCustomTextField(
                            controller: _emailCtrl,
                            hintText: 'Official Email',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email address' : null,
                            onChanged: (_) => setState(() {}),
                            suffixIcon: _buildOtpFieldSuffix(
                              isVerified: _emailVerified,
                              isEligible: _emailCtrl.text.contains('@') && _emailCtrl.text.contains('.'),
                              onGetOtp: _sendEmailOtp,
                            ),
                          ),
                          if (_emailOtpSent && !_emailVerified) ...[
                            const SizedBox(height: 10),
                            _buildInlineOtpBox(
                              title: 'Email OTP Verification',
                              controller: _emailOtpCtrl,
                              secondsLeft: _emailSecondsLeft,
                              errorMessage: _emailOtpError,
                              onVerify: _verifyEmailOtp,
                              onResend: _sendEmailOtp,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Card 2: Registration Category & Rank / Designation
                      _buildSectionCard(
                        icon: Icons.military_tech_rounded,
                        title: 'Role Category & Designation',
                        subtitle: 'Select official rank first to unlock jurisdiction options.',
                        children: [
                          // Mandatory Designation Selection FIRST
                          _buildDesignationDropdown(),

                          if (_designation == null || _designation!.isEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Please select your official Designation / Rank above to view role category and location options.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_isStaffOnlyRank) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.shield_rounded, color: Color(0xFF16A34A), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Rank $_designation is assigned as Field Officer Staff.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        color: const Color(0xFF15803D),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 14),
                            _buildCategorySelectorCard(),
                            if (_registrationCategory == 'admin_officer') ...[
                              _buildAdminRoleSelector(),
                            ],
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Card 3: Posting Location & Unit Hierarchy (Unlocked after Designation is selected)
                      if (_designation != null && _designation!.isNotEmpty) ...[
                        _buildSectionCard(
                          icon: Icons.account_tree_rounded,
                          title: 'Posting & Location Hierarchy',
                          subtitle: 'Select your administrative jurisdiction scope.',
                          children: [
                            _buildDynamicLocationSection(),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Card 3: Account Security
                      _buildSectionCard(
                        icon: Icons.shield_outlined,
                        title: 'Account Security',
                        subtitle: 'Create a password or PIN (minimum 6 characters) to secure your login.',
                        children: [
                          _buildCustomTextField(
                            controller: _passwordCtrl,
                            hintText: 'Create Password / PIN',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18,
                                color: subtitleColor,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildCustomTextField(
                            controller: _confirmPasswordCtrl,
                            hintText: 'Confirm Password / PIN',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18,
                                color: subtitleColor,
                              ),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please confirm your password';
                              if (v != _passwordCtrl.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Card 4: Identity photos (optional)
                      _buildSectionCard(
                        icon: Icons.photo_camera_outlined,
                        title: 'Identity photos (optional)',
                        subtitle: 'Attach official ID and verification photos for faster supervisor approval.',
                        children: [
                          // 1. Police ID Card
                          Text(
                            'Police ID Card',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Clear photo or scan of your official department ID card',
                            style: GoogleFonts.poppins(fontSize: 12, color: subtitleColor),
                          ),
                          const SizedBox(height: 8),
                          _buildUploadBox(
                            isIdCard: true,
                            previewBytes: _idCardPreviewBytes,
                            hasFile: _idCardFile != null,
                          ),
                          const SizedBox(height: 16),

                          // 2. User Photo / Selfie
                          Text(
                            'User Photo / Selfie',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Recent portrait photo for profile verification',
                            style: GoogleFonts.poppins(fontSize: 12, color: subtitleColor),
                          ),
                          const SizedBox(height: 8),
                          _buildUploadBox(
                            isIdCard: false,
                            previewBytes: _selfiePreviewBytes,
                            hasFile: _selfieFile != null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Register Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navyBrandColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  'Register',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Footer: Already have an account? Login
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: subtitleColor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                                }
                              },
                              child: Text(
                                'Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: navyBrandColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpFieldSuffix({
    required bool isVerified,
    required bool isEligible,
    required VoidCallback onGetOtp,
  }) {
    const navyBrandColor = Color(0xFF1E2968);

    if (isVerified) {
      return Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.successGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.successGreen),
            const SizedBox(width: 4),
            Text(
              'Verified',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.successGreen,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: TextButton(
        onPressed: onGetOtp,
        style: TextButton.styleFrom(
          foregroundColor: isEligible ? navyBrandColor : const Color(0xFF94A3B8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: isEligible ? navyBrandColor.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          'Get OTP',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isEligible ? navyBrandColor : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineOtpBox({
    required String title,
    required TextEditingController controller,
    required int secondsLeft,
    required String? errorMessage,
    required VoidCallback onVerify,
    required VoidCallback onResend,
  }) {
    const navyBrandColor = Color(0xFF1E2968);
    const borderColor = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_clock_outlined, size: 16, color: navyBrandColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Dev OTP: 123456',
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown.shade800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, letterSpacing: 2),
                  decoration: InputDecoration(
                    hintText: '• • • • • •',
                    hintStyle: GoogleFonts.poppins(fontSize: 13.5, letterSpacing: 2, color: const Color(0xFF94A3B8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: navyBrandColor, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyBrandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text('Verify OTP', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              errorMessage,
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.dangerRed, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              if (secondsLeft > 0)
                Text(
                  'Resend available in ${secondsLeft}s',
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B)),
                )
              else
                GestureDetector(
                  onTap: onResend,
                  child: Text(
                    'Resend OTP',
                    style: GoogleFonts.poppins(fontSize: 11, color: navyBrandColor, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    const navyBrandColor = Color(0xFF1E2968);
    const borderColor = Color(0xFFE2E8F0);
    const subtitleColor = Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: navyBrandColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: subtitleColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    const navyBrandColor = Color(0xFF1E2968);
    const borderColor = Color(0xFFE2E8F0);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: navyBrandColor, size: 19),
        suffixIcon: suffixIcon,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: navyBrandColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.dangerRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.dangerRed, width: 1.5),
        ),
      ),
    );
  }

  RankRoleConfig? get _currentRankConfig {
    if (_designation == null || _designation!.isEmpty) return null;
    final d = _designation!.trim();
    return _rankConfigs.where((r) => r.code == d || r.displayName == d || r.title == d).firstOrNull;
  }

  bool get _isStaffOnlyRank {
    final cfg = _currentRankConfig;
    if (cfg == null) return false;
    // Rank is staff only if DB does not allow admin_officer OR allowed_admin_roles is empty
    return !cfg.allowedCategories.contains('admin_officer') || cfg.allowedAdminRoles.isEmpty;
  }

  List<String> get _allowedAdminRolesForRank {
    return _currentRankConfig?.allowedAdminRoles ?? [];
  }

  void _onDesignationChanged(String? val) {
    if (val == null) return;
    setState(() {
      _designation = val;
      final config = _rankConfigs.where((r) => r.code == val || r.displayName == val).firstOrNull;
      if (config != null) {
        if (config.impliedUnitType != null && config.impliedUnitType!.isNotEmpty && config.impliedUnitType != _selectedUnitType) {
          _selectedUnitType = config.impliedUnitType;
          _clearLocationSelection();
        }
        if (config.allowedCategories.length == 1) {
          _registrationCategory = config.allowedCategories.first;
          _selectedAdminRole = '';
        } else {
          final allowed = config.allowedAdminRoles;
          if (allowed.isNotEmpty && !allowed.contains(_selectedAdminRole)) {
            _selectedAdminRole = allowed.first;
          }
        }
      }
    });
  }

  Widget _buildDesignationDropdown() {
    const navyBrandColor = Color(0xFF1E2968);
    const borderColor = Color(0xFFE2E8F0);

    if (_loadingRankConfigs || _rankConfigs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 10),
            Text('Loading designations from database...', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B))),
          ],
        ),
      );
    }

    final items = _rankConfigs;
    final safeValue = (_designation != null && items.any((d) => d.code == _designation))
        ? _designation
        : null;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      menuMaxHeight: 360,
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
      style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: 'Designation / Official Rank *',
        hintStyle: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.badge_outlined, color: navyBrandColor, size: 19),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: navyBrandColor, width: 1.5),
        ),
      ),
      items: items.map((d) {
        return DropdownMenuItem<String>(
          value: d.code,
          child: Text(d.displayName, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: _onDesignationChanged,
      validator: (v) => v == null || v.trim().isEmpty ? 'Designation is required' : null,
    );
  }

  Map<String, bool> get _requiredLocationScope {
    if (_registrationCategory == 'admin_officer') {
      switch (_selectedAdminRole) {
        case 'state_admin':
          return {'division': false, 'district': false, 'station': false};
        case 'division_admin':
          return {'division': true, 'district': false, 'station': false};
        case 'district_admin':
          return {'division': true, 'district': true, 'station': false};
        case 'station_admin':
        default:
          return {'division': true, 'district': true, 'station': true};
      }
    } else {
      final reqLevel = _currentRankConfig?.requiredHierarchyLevel ?? 'station';
      switch (reqLevel) {
        case 'state':
          return {'division': false, 'district': false, 'station': false};
        case 'division':
          return {'division': true, 'district': false, 'station': false};
        case 'district':
          return {'division': true, 'district': true, 'station': false};
        case 'station':
        default:
          return {'division': true, 'district': true, 'station': true};
      }
    }
  }

  Widget _buildCategorySelectorCard() {
    final allowed = _currentRankConfig?.allowedCategories ?? ['field_officer', 'admin_officer'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registration Category',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (allowed.contains('field_officer'))
              Expanded(
                child: _buildCategoryCard(
                  title: 'Field Officer',
                  subtitle: 'Station / Unit Staff',
                  icon: Icons.shield_rounded,
                  isSelected: _registrationCategory == 'field_officer',
                  onTap: () {
                    setState(() {
                      _registrationCategory = 'field_officer';
                      _selectedStation = null;
                    });
                  },
                ),
              ),
            if (allowed.contains('field_officer') && allowed.contains('admin_officer'))
              const SizedBox(width: 12),
            if (allowed.contains('admin_officer'))
              Expanded(
                child: _buildCategoryCard(
                  title: 'Admin Officer',
                  subtitle: 'Jurisdiction Lead',
                  icon: Icons.admin_panel_settings_rounded,
                  isSelected: _registrationCategory == 'admin_officer',
                  onTap: () {
                    setState(() {
                      _registrationCategory = 'admin_officer';
                      _selectedStation = null;
                    });
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const navyBrandColor = Color(0xFF1E2968);
    const borderColor = Color(0xFFE2E8F0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? navyBrandColor.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? navyBrandColor : borderColor,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? navyBrandColor : const Color(0xFF64748B), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? navyBrandColor : const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminRoleSelector() {
    final allowed = _allowedAdminRolesForRank;
    if (allowed.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Select Administrative Level',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (allowed.contains('division_admin'))
              _buildRolePill('division_admin', 'Division Admin (Range)', Icons.map_rounded),
            if (allowed.contains('district_admin'))
              _buildRolePill('district_admin', 'District Admin (SP/CP)', Icons.location_city_rounded),
            if (allowed.contains('station_admin'))
              _buildRolePill('station_admin', 'Station Admin (SHO)', Icons.local_police_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildRolePill(String roleKey, String label, IconData icon) {
    const navyBrandColor = Color(0xFF1E2968);
    final isSelected = _selectedAdminRole == roleKey;

    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : navyBrandColor),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF1E293B),
        ),
      ),
      selected: isSelected,
      selectedColor: navyBrandColor,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? navyBrandColor : const Color(0xFFCBD5E1)),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedAdminRole = roleKey;
            _selectedStation = null;
          });
        }
      },
    );
  }

  Widget _buildDynamicLocationSection() {
    final scope = _requiredLocationScope;
    final needsDivision = scope['division'] ?? true;
    final needsDistrict = scope['district'] ?? true;
    final needsStation = scope['station'] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStateSelector(),
        const SizedBox(height: 12),

        // Division / Range Dropdown (Visible if required)
        if (needsDivision) ...[
          SearchablePickerField(
            key: ValueKey('div-$_selectedState'),
            label: 'Division / Range',
            hintText: _dynamicDivisions.isNotEmpty
                ? 'Select Division / Range'
                : 'Loading Divisions...',
            leadingIcon: Icons.map_rounded,
            items: _divisionsForSelection(),
            value: _selectedDivision,
            onChanged: (v) => setState(() {
              _selectedDivision = v;
              _selectedDistrict = null;
              _selectedStation = null;
            }),
            validator: (v) => v == null || v.trim().isEmpty ? 'Division / Range is required' : null,
          ),
          const SizedBox(height: 12),
        ],

        // District Dropdown (Visible if required)
        if (needsDistrict) ...[
          SearchablePickerField(
            key: ValueKey('dist-$_selectedState-$_selectedDivision-$_selectedUnitType'),
            label: 'District / Commissionerate (${_dynamicDistricts.length} Active)',
            hintText: _selectedDivision != null || !needsDivision
                ? 'Search district'
                : 'Select Division / Range first',
            leadingIcon: Icons.location_city_rounded,
            items: _districtsForSelection(),
            value: _selectedDistrict,
            onChanged: (v) {
              setState(() {
                _selectedDistrict = v;
                _selectedStation = null;
              });
              _fetchDynamicStations(v);
            },
            validator: (v) => v == null || v.trim().isEmpty ? 'District is required' : null,
          ),
          const SizedBox(height: 12),
        ],

        // Police Station Dropdown (Visible if required)
        if (needsStation) ...[
          SearchablePickerField(
            key: ValueKey('stn-$_selectedDistrict-$_selectedDivision-$_selectedUnitType'),
            label: 'Police Station (${_dynamicStations.length} Available)',
            hintText: _selectedDistrict != null
                ? 'Search police station'
                : 'Select District first to view stations',
            leadingIcon: Icons.local_police_rounded,
            items: _stationsForSelection(),
            value: _selectedStation,
            onChanged: (v) => setState(() => _selectedStation = v),
            validator: (v) => v == null || v.trim().isEmpty ? 'Police station is required' : null,
          ),
          const SizedBox(height: 12),
        ],

        // Summary Info Banner for Admin Levels
        if (!needsStation) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    !needsDistrict
                        ? (!needsDivision
                            ? 'State Super Admin registration scope covers all divisions & districts statewide.'
                            : 'Division Admin registration scope covers all districts under selected division.')
                        : 'District Admin registration scope covers all police stations under selected district.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF1E40AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStateSelector() {
    const navyBrandColor = Color(0xFF1E2968);
    const borderColor = Color(0xFFE2E8F0);

    return DropdownButtonFormField<String>(
      initialValue: _selectedState,
      isExpanded: true,
      menuMaxHeight: 360,
      icon: const Icon(Icons.search, color: Color(0xFF64748B), size: 18),
      style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: 'State',
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
        prefixIcon: const Icon(Icons.menu_book_outlined, color: navyBrandColor, size: 19),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: navyBrandColor, width: 1.5),
        ),
      ),
      items: (_dynamicStates.isNotEmpty
              ? _dynamicStates.map((s) => s['name']!).toList()
              : ['Maharashtra', 'Gujarat'])
          .map((st) {
        return DropdownMenuItem<String>(
          value: st,
          child: Text(st, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) {
          final match = _dynamicStates.firstWhere(
            (s) => s['name'] == v,
            orElse: () => {'code': 'MH', 'name': v},
          );
          setState(() {
            _selectedState = v;
            _selectedStateCode = match['code'];
            _selectedDivision = null;
            _selectedDistrict = null;
            _selectedStation = null;
            _dynamicStations = [];
          });
          _fetchDynamicDivisions(match['code']!);
          _fetchDynamicDistricts(match['code']!);

          // Automatically set/update the app's default language/locale based on the selected state
          final langCode = StateLanguageHelper.getLanguageCodeForState(v);
          context.read<SettingsProvider>().setLanguage(langCode);
        }
      },
    );
  }

  Widget _buildUploadBox({
    required bool isIdCard,
    required Uint8List? previewBytes,
    required bool hasFile,
  }) {
    const navyBrandColor = Color(0xFF1E2968);
    const subtitleColor = Color(0xFF64748B);

    if (hasFile && previewBytes != null) {
      return Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.memory(previewBytes, fit: BoxFit.cover),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                  onPressed: () => _clearImage(isIdCard: isIdCard),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _pickImage(isIdCard: isIdCard),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: navyBrandColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to upload image',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Supports JPG, PNG (Clear photo/scan)',
              style: GoogleFonts.poppins(fontSize: 11, color: subtitleColor),
            ),
          ],
        ),
      ),
    );
  }
}
