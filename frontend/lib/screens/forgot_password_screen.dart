// lib/screens/forgot_password_screen.dart
// Forgot Password / PIN screen matching exact UI design.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  static const String _mockOtp = '123456';
  bool _otpSent = false;
  bool _emailOtpVerified = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  int _secondsLeft = 0;
  Timer? _timer;
  String? _otpError;

  @override
  void dispose() {
    _timer?.cancel();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: color,
      ),
    );
  }

  void _sendOtp() {
    final email = _emailCtrl.text.trim();
    if (AppValidators.govtEmail(email) != null) {
      _showSnack(
        'Please enter a valid government email address.',
        AppColors.warningOrange,
      );
      return;
    }

    setState(() {
      _otpSent = true;
      _emailOtpVerified = false;
      _otpError = null;
      _secondsLeft = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });

    // Auto-fill dev OTP
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _otpCtrl.text = _mockOtp);
    });

    _showSnack('OTP sent to $email (Dev Mode: 123456)', AppColors.infoBlue);
  }

  void _verifyOtp() {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _otpError = 'Enter 6-digit OTP');
      return;
    }
    if (code != _mockOtp) {
      setState(() => _otpError = 'Invalid OTP. Enter 123456');
      return;
    }

    setState(() {
      _emailOtpVerified = true;
      _otpError = null;
    });
    _timer?.cancel();
    _showSnack(
      'Identity verified! Please set your new password or PIN.',
      AppColors.successGreen,
    );
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_emailOtpVerified) {
      _showSnack(
        'Please verify your email via OTP first.',
        AppColors.warningOrange,
      );
      return;
    }

    if (_newPasswordCtrl.text.trim() != _confirmPasswordCtrl.text.trim()) {
      _showSnack('Passwords do not match.', AppColors.dangerRed);
      return;
    }

    setState(() => _loading = true);

    try {
      await context.read<AuthProvider>().resetPin(_newPasswordCtrl.text.trim());

      if (!mounted) return;
      setState(() => _loading = false);

      _showSnack('Password / PIN reset successfully!', AppColors.successGreen);
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack('Failed to reset password: $e', AppColors.dangerRed);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navyBrandColor = Color(0xFF1E2968);
    const borderColor = Color(0xFFE2E8F0);
    const subtitleColor = Color(0xFF64748B);

    final bool isEmailValid =
        _emailCtrl.text.contains('@') && _emailCtrl.text.contains('.');

    return Theme(
      data: AppTheme.lightTheme(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Back Navigation Button
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EDF5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: navyBrandColor,
                            size: 20,
                          ),
                          tooltip: 'Back to Login',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Centered Header Badge & Title
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFBBF24),
                              ),
                              child: const Icon(
                                Icons.lock_reset_rounded,
                                color: Color(0xFF0F172A),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Forgot Password / PIN?',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Verify your Government Email ID to reset your login password or PIN.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: subtitleColor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Main Card Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Step 1 Section Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.shield_rounded,
                                    color: navyBrandColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Step 1 of 2 — Verify Identity',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        'Enter your registered Government Email ID',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_emailOtpVerified)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.successGreen.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.successGreen
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 14,
                                          color: AppColors.successGreen,
                                        ),
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
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Government Email ID Input
                            TextFormField(
                              controller: _emailCtrl,
                              enabled: !_emailOtpVerified,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) => setState(() {}),
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                color: const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Government Email ID',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  color: const Color(0xFF94A3B8),
                                ),
                                prefixIcon: const Icon(
                                  Icons.mail_rounded,
                                  color: navyBrandColor,
                                  size: 19,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: borderColor,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: borderColor,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: navyBrandColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: AppValidators.govtEmail,
                            ),
                            const SizedBox(height: 14),

                            // Email OTP Sub-Card Box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Email OTP',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (_otpSent && !_emailOtpVerified)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade100,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Dev OTP: 123456',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.brown.shade800,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'For dev mode, OTP is auto-filled as 123456.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color: subtitleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Pre-send State: Send OTP Button (Matching image 2)
                                  if (!_otpSent && !_emailOtpVerified) ...[
                                    ElevatedButton.icon(
                                      onPressed: isEmailValid ? _sendOtp : null,
                                      icon: const Icon(
                                        Icons.send_rounded,
                                        size: 14,
                                      ),
                                      label: Text(
                                        'Send OTP',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isEmailValid
                                            ? navyBrandColor
                                            : const Color(0xFFD6DCF0),
                                        foregroundColor: isEmailValid
                                            ? Colors.white
                                            : const Color(0xFF64748B),
                                        disabledBackgroundColor: const Color(
                                          0xFFD6DCF0,
                                        ),
                                        disabledForegroundColor: const Color(
                                          0xFF64748B,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ],

                                  // OTP Sent State: Input + Verify + Resend
                                  if (_otpSent && !_emailOtpVerified) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _otpCtrl,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                6,
                                              ),
                                            ],
                                            style: GoogleFonts.poppins(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 2,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: '• • • • • •',
                                              hintStyle: GoogleFonts.poppins(
                                                fontSize: 13.5,
                                                letterSpacing: 2,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              filled: true,
                                              fillColor: const Color(
                                                0xFFF8FAFC,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: borderColor,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: borderColor,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: navyBrandColor,
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton(
                                          onPressed: _verifyOtp,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: navyBrandColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 11,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            'Verify OTP',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_otpError != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        _otpError!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: AppColors.dangerRed,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (_secondsLeft > 0)
                                          Text(
                                            'Resend available in ${_secondsLeft}s',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: subtitleColor,
                                            ),
                                          )
                                        else
                                          GestureDetector(
                                            onTap: _sendOtp,
                                            child: Text(
                                              'Resend OTP',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: navyBrandColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],

                                  // Verified State
                                  if (_emailOtpVerified) ...[
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.successGreen,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Email OTP verified successfully.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.successGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Step 2 Section: Set New Password / PIN (When Step 1 Verified)
                            if (_emailOtpVerified) ...[
                              const SizedBox(height: 20),
                              const Divider(color: borderColor),
                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: navyBrandColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Step 2 of 2 — Set New Password / PIN',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          'Create and confirm your new password or PIN (min 6 chars).',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            color: subtitleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // New Password Input
                              TextFormField(
                                controller: _newPasswordCtrl,
                                obscureText: _obscureNew,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  color: const Color(0xFF0F172A),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter new Password / PIN',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: navyBrandColor,
                                    size: 19,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureNew
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: subtitleColor,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureNew = !_obscureNew,
                                    ),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: borderColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: borderColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: navyBrandColor,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (v) => v == null || v.length < 6
                                    ? 'Minimum 6 characters required'
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              // Confirm Password Input
                              TextFormField(
                                controller: _confirmPasswordCtrl,
                                obscureText: _obscureConfirm,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  color: const Color(0xFF0F172A),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Confirm new Password / PIN',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: navyBrandColor,
                                    size: 19,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: subtitleColor,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: borderColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: borderColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: navyBrandColor,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Please confirm password';
                                  }
                                  if (v != _newPasswordCtrl.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Reset Password Action Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _resetPassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: navyBrandColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Reset Password / PIN',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ],
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
}
