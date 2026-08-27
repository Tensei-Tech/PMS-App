// lib/screens/register_screen.dart
// Self-registration with posting location, identity photos, and active Mobile & Email OTP verification.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_config.dart';
import '../data/india_states.dart';
import '../data/maharashtra_police_stations_repository.dart';
import '../data/police_stations_repository.dart';
import '../data/india_districts_repository.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/validators.dart';
import '../widgets/searchable_picker_field.dart';
import 'pending_approval_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  String? _designation;
  String _selectedState = 'Maharashtra';
  String? _selectedUnitType;
  String? _selectedDistrict;
  String? _selectedStation;
  bool _locationDataReady = false;
  Map<String, List<String>> _districtsByState = {};

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

  List<String> _onboardedStates = ['Maharashtra', 'Gujarat'];

  Future<void> _bootstrapLocationData() async {
    try {
      final map = await IndiaDistrictsRepository.load();
      await MaharashtraPoliceStationsRepository.initialize();

      List<String> activeStates = [];
      try {
        final response = await http.get(Uri.parse(ApiConfig.masterStates));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final list = (data is Map && data.containsKey('results')) ? data['results'] as List : (data as List);
          for (final item in list) {
            if (item['is_active'] == true && item['state_name'] != null) {
              final sName = item['state_name'].toString().trim();
              if (!activeStates.contains(sName)) {
                activeStates.add(sName);
              }
            }
          }
        }
      } catch (_) {}

      if (activeStates.isEmpty) {
        activeStates = ['Gujarat', 'Maharashtra'];
      }

      if (!mounted) return;
      setState(() {
        _districtsByState = map;
        _onboardedStates = activeStates;
        if (!activeStates.contains(_selectedState) && activeStates.isNotEmpty) {
          _selectedState = activeStates.first;
        }
        _locationDataReady = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationDataReady = true);
    }
  }

  List<String> _districtsForSelection() {
    if (_selectedUnitType == null || _selectedState.trim().isEmpty) {
      return const [];
    }
    if (_selectedState == 'Maharashtra') {
      final districts = <String>{};
      for (final station in MaharashtraPoliceStationsRepository.getAllStations()) {
        if (station.type == _selectedUnitType) {
          districts.add(station.districtName);
        }
      }
      return districts.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }

    final rawList = _districtsByState[_selectedState] ??
        _districtsByState[_selectedState.toLowerCase()] ??
        _districtsByState[_selectedState.toUpperCase()];

    if (rawList == null) return const [];
    return (rawList ?? []).map((e) => e.toString()).toList();
  }

  List<String> _stationsForSelection() {
    if (_selectedDistrict == null || _selectedUnitType == null || _selectedState.trim().isEmpty) {
      return const [];
    }
    if (_selectedState == 'Maharashtra') {
      return MaharashtraPoliceStationsRepository.getStationNamesForSelection(
        district: _selectedDistrict!,
        unitType: _selectedUnitType!,
      );
    }
    final list = PoliceStationsRepository.forSelection(
      unitType: _selectedUnitType!,
      state: _selectedState,
      district: _selectedDistrict!,
    );
    return (list ?? []).map((e) => e.toString()).toList();
  }

  String _buildStationAddress() {
    final dist = _selectedDistrict?.trim() ?? '';
    final state = _selectedState.trim();
    final unit = _selectedUnitType?.trim() ?? '';
    return '$dist, $state • $unit';
  }

  bool get _unitTypeLockedByDesignation =>
      SeniorOfficerRoles.impliedUnitType(_designation) != null;

  void _clearLocationSelection() {
    _selectedDistrict = null;
    _selectedStation = null;
  }

  void _onUnitTypeChanged(String unitType) {
    setState(() {
      if (_unitTypeLockedByDesignation) return;
      if (_selectedUnitType != unitType) {
        _selectedUnitType = unitType;
        _clearLocationSelection();
      }
      if (_designation != null) {
        final allowed = (PoliceDesignations.forRegistration(unitType) ?? [])
            .map((e) => e.abbreviation)
            .toSet();
        if (!allowed.contains(_designation)) {
          _designation = null;
        }
      }
    });
  }

  void _onDesignationChanged(String? designation) {
    setState(() {
      _designation = designation;
      final implied = SeniorOfficerRoles.impliedUnitType(designation);
      if (implied != null && implied != _selectedUnitType) {
        _selectedUnitType = implied;
        _clearLocationSelection();
      }
    });
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

    if (_selectedUnitType == null || _selectedUnitType!.isEmpty) {
      _showSnack('Please select a Police Unit (Commissionerate or Superintendent).', AppColors.warningOrange);
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

                      // Card 1: Contact verification
                      _buildSectionCard(
                        icon: Icons.verified_user_rounded,
                        title: 'Contact verification',
                        subtitle: 'Verify your mobile number and government email.',
                        children: [
                          // 1. Mobile Input & Verification Row
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

                          // 2. Email Input & Verification Row
                          _buildCustomTextField(
                            controller: _emailCtrl,
                            hintText: 'Email',
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

                      // Card 2: Posting & profile
                      _buildSectionCard(
                        icon: Icons.badge_outlined,
                        title: 'Posting & profile',
                        subtitle: 'Enter full name, designation, and official posting details.',
                        children: [
                          _buildCustomTextField(
                            controller: _fullNameCtrl,
                            hintText: 'Full Name',
                            icon: Icons.person_outline_rounded,
                            validator: AppValidators.fullName,
                          ),
                          const SizedBox(height: 12),

                          // Designation Dropdown
                          _buildDesignationDropdown(),
                          const SizedBox(height: 12),

                          // Government ID
                          _buildCustomTextField(
                            controller: _govtIdCtrl,
                            hintText: 'Government ID',
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 12),

                          // State Selector
                          _buildStateSelector(),
                          const SizedBox(height: 16),

                          // Police Unit Selector Cards
                          Text(
                            'Police Unit',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildUnitCard(
                                  title: 'Commissionerate (CP)',
                                  icon: Icons.location_city_rounded,
                                  isSelected: _selectedUnitType == PoliceStationsRepository.commissionerate,
                                  onTap: () => _onUnitTypeChanged(PoliceStationsRepository.commissionerate),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildUnitCard(
                                  title: 'Superintendent (SP)',
                                  icon: Icons.account_balance_rounded,
                                  isSelected: _selectedUnitType == PoliceStationsRepository.superintendent,
                                  onTap: () => _onUnitTypeChanged(PoliceStationsRepository.superintendent),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedUnitType == null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Select Commissionerate (CP) or Superintendent (SP)',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFFD97706),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],

                          // District / Police Station picker fields (when unit type selected)
                          if (_selectedUnitType != null) ...[
                            const SizedBox(height: 14),
                            SearchablePickerField(
                              key: ValueKey('dist-$_selectedState-$_selectedUnitType'),
                              label: 'District / Commissionerate',
                              hintText: 'Search district',
                              leadingIcon: Icons.location_city_rounded,
                              items: _districtsForSelection(),
                              value: _selectedDistrict,
                              onChanged: (v) => setState(() {
                                _selectedDistrict = v;
                                _selectedStation = null;
                              }),
                              validator: (v) => v == null || v.trim().isEmpty ? 'District is required' : null,
                            ),
                            if (_selectedDistrict != null) ...[
                              const SizedBox(height: 12),
                              SearchablePickerField(
                                key: ValueKey('stn-$_selectedDistrict-$_selectedUnitType'),
                                label: 'Police Station',
                                hintText: 'Search police station',
                                leadingIcon: Icons.local_police_rounded,
                                items: _stationsForSelection(),
                                value: _selectedStation,
                                onChanged: (v) => setState(() => _selectedStation = v),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Police station is required' : null,
                              ),
                            ],
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

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

  Widget _buildDesignationDropdown() {
    const navyBrandColor = Color(0xFF1E2968);
    const borderColor = Color(0xFFE2E8F0);

    final items = _selectedUnitType != null && _selectedUnitType!.trim().isNotEmpty
        ? PoliceDesignations.forRegistration(_selectedUnitType)
        : PoliceDesignations.simplifiedRegistration();

    final safeValue = (_designation != null && items.any((d) => d.abbreviation == _designation))
        ? _designation
        : null;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      menuMaxHeight: 360,
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
      style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: 'Designation',
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
      items: (items ?? []).map((d) {
        return DropdownMenuItem<String>(
          value: d.abbreviation,
          child: Text(d.display, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: _onDesignationChanged,
      validator: (v) => v == null || v.trim().isEmpty ? 'Designation is required' : null,
    );
  }

  Widget _buildStateSelector() {
    const navyBrandColor = Color(0xFF1E2968);
    const borderColor = Color(0xFFE2E8F0);

    return DropdownButtonFormField<String>(
      value: _selectedState,
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
      items: _onboardedStates.map((st) {
        return DropdownMenuItem<String>(
          value: st,
          child: Text(st, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) {
          setState(() {
            _selectedState = v;
            _selectedDistrict = null;
            _selectedStation = null;
          });
        }
      },
    );
  }

  Widget _buildUnitCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const navyBrandColor = Color(0xFF1E2968);
    const borderColor = Color(0xFFE2E8F0);

    return InkWell(
      onTap: _unitTypeLockedByDesignation ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? navyBrandColor : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: navyBrandColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? navyBrandColor : const Color(0xFFCBD5E1),
                  width: isSelected ? 4.5 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
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
