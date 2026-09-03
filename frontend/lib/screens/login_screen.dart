// lib/screens/login_screen.dart
// Clean Email + Password Login Screen for Officer Portal.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';

import '../services/biometric_service.dart';
import '../services/lockout_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/validators.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';
import '../widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final BiometricService _biometricService = BiometricService();
  final _formKey = GlobalKey<FormState>();
  final _govtEmailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Brute-force lockout state
  final LockoutService _lockoutService = LockoutService();
  bool _isLockedOut = false;
  String _lockoutCountdown = '';
  Timer? _lockoutTimer;

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    _slideCtrl.forward();
    WidgetsBinding.instance.addObserver(this);

    _checkLockout();
    _loadStoredEmail();
  }

  Future<void> _checkLockout() async {
    final status = await _lockoutService.checkStatus();
    if (!mounted) return;
    if (status.isLocked) {
      setState(() {
        _isLockedOut = true;
        _lockoutCountdown = status.remainingLabel;
      });
      _lockoutTimer?.cancel();
      _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        final s = await _lockoutService.checkStatus();
        if (!mounted) return;
        if (s.isLocked) {
          setState(() => _lockoutCountdown = s.remainingLabel);
        } else {
          _lockoutTimer?.cancel();
          setState(() {
            _isLockedOut = false;
            _lockoutCountdown = '';
          });
        }
      });
    } else {
      setState(() => _isLockedOut = false);
    }
  }

  Future<void> _loadStoredEmail() async {
    final auth = context.read<AuthProvider>();
    final storedEmail = await auth.getStoredGovtEmail();
    if (mounted && storedEmail.isNotEmpty) {
      setState(() {
        _govtEmailCtrl.text = storedEmail;
      });
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _govtEmailCtrl.dispose();
    _passwordCtrl.dispose();
    _lockoutTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLockedOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account locked. Try again in $_lockoutCountdown.',
              style: GoogleFonts.poppins()),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final email = _govtEmailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    final loginError = await auth.loginByEmailAndPin(email: email, pin: password);
    if (loginError != null) await _checkLockout();

    if (!mounted) return;

    if (loginError == null) {
      setState(() => _isLoading = false);
      Navigator.pushAndRemoveUntil(
        context,
        AppTheme.fadeSlideRoute(page: const DashboardScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loginError, style: GoogleFonts.poppins()),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  Future<void> _handleBiometricLogin() async {
    final email = _govtEmailCtrl.text.trim();

    if (email.isEmpty) {
      _showBiometricAlertDialog(
        title: 'Email / Government ID Required',
        message: 'Please enter your Government Email or ID in the input box first before using biometric sign-in.',
      );
      return;
    }

    final bool isConfigured = await _biometricService.isBiometricConfiguredForUser(email);
    if (!isConfigured) {
      _showBiometricAlertDialog(
        title: 'Biometric Not Configured for Profile',
        message: 'Biometric login has not been set up for "$email" yet.\n\nPlease log in using your Password first, then navigate to Sidebar > Login Security Settings to setup your Fingerprint.',
      );
      return;
    }

    final bool isAvailable = await _biometricService.isBiometricAvailable();
    if (!isAvailable) {
      _showBiometricAlertDialog(
        title: 'Biometric Sensor Unavailable',
        message: 'No biometric hardware sensor detected or no fingerprints are enrolled on this device.',
      );
      return;
    }

    final bool authenticated = await _biometricService.authenticate(
      localizedReason: 'Scan fingerprint to sign in as $email',
    );

    if (!mounted) return;

    if (authenticated) {
      if (_passwordCtrl.text.trim().isNotEmpty) {
        _handleLogin();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric verified for $email! Enter your Password to complete sign-in.', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Biometric authentication failed or cancelled.', style: GoogleFonts.poppins()),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  void _showBiometricAlertDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
              child: Icon(Icons.fingerprint_rounded, color: Colors.orange.shade800, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navyDark),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade800, height: 1.35),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Understood', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 768;
            final l10n = AppLocalizations.of(context);

            return Stack(
              children: [
                // Background design
                Container(
                  color: AppColors.lightBg,
                ),
                Positioned(
                  top: -120,
                  right: -100,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.navyMid.withValues(alpha: 0.05),
                    ),
                  ),
                ),

                // Main content layout
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? AppSpacing.lg : AppSpacing.xl * 2,
                      vertical: AppSpacing.xl,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Card(
                          elevation: isCompact ? 0 : 4,
                          shadowColor: Colors.black.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            side: isCompact
                                ? BorderSide.none
                                : const BorderSide(
                                    color: AppColors.lightBorder, width: 1),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(
                              isCompact ? AppSpacing.lg : AppSpacing.xl,
                            ),
                            child: _buildLoginForm(isCompact, l10n),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isCompact, AppLocalizations? l10n) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo & Title
            Center(
              child: Column(
                children: [
                  const AppLogo(size: 64),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Sign In',
                    style: GoogleFonts.poppins(
                      fontSize: isCompact ? 20 : 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Enter your Government Email and Password',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.lightSubText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: isCompact ? AppSpacing.md : AppSpacing.lg),

            // Lockout Warning Banner
            if (_isLockedOut) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.dangerRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.dangerRed.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_clock_rounded,
                        color: AppColors.dangerRed, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Temporarily Locked',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dangerRed,
                            ),
                          ),
                          Text(
                            'Too many failed attempts. Try again in $_lockoutCountdown.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.dangerRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Email field
            TextFormField(
              controller: _govtEmailCtrl,
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              style: GoogleFonts.poppins(
                  color: AppColors.lightText, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Government Email / ID',
                hintText: 'name@department.gov.in',
                prefixIcon: const Icon(Icons.badge_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.lightBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide:
                        const BorderSide(color: AppColors.navyMid, width: 2)),
              ),
              validator: AppValidators.govtEmail,
            ),
            const SizedBox(height: AppSpacing.md),

            // Password Field
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              style: GoogleFonts.poppins(
                  color: AppColors.navyDark, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.navyMid,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.lightBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide:
                        const BorderSide(color: AppColors.navyMid, width: 2)),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 6),

            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    AppTheme.fadeSlideRoute(
                        page: const ForgotPasswordScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyMid,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: isCompact ? 48 : 54,
              child: ElevatedButton(
                onPressed: (_isLoading || _isLockedOut) ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyMid,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.navyMid.withValues(alpha: 0.5),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Biometric Sign-In Button
            SizedBox(
              width: double.infinity,
              height: isCompact ? 44 : 48,
              child: OutlinedButton.icon(
                onPressed: (_isLoading || _isLockedOut) ? null : _handleBiometricLogin,
                icon: const Icon(Icons.fingerprint_rounded, color: AppColors.navyDark, size: 20),
                label: Text(
                  'Sign In with Biometrics',
                  style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.navyDark),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.navyDark, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: AppSpacing.md),
              const Center(
                  child: CircularProgressIndicator(color: AppColors.navyMid)),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Registration link
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    l10n?.dontHaveAccount ?? "Don't have an account?",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.lightSubText,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.register,
                      (_) => false,
                    ),
                    child: Text(
                      l10n?.register ?? 'Register',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.navyMid,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
