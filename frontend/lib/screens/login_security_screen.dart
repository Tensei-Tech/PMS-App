import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';

import '../services/biometric_service.dart';

class LoginSecurityScreen extends StatefulWidget {
  const LoginSecurityScreen({super.key});

  @override
  State<LoginSecurityScreen> createState() => _LoginSecurityScreenState();
}

class _LoginSecurityScreenState extends State<LoginSecurityScreen> {
  final BiometricService _biometricService = BiometricService();
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  bool _isChangingPassword = false;
  bool _isProcessingBiometric = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _oldPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
      }
    });
  }

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleBiometric(bool val, SettingsProvider settings) async {
    if (_isProcessingBiometric) return;

    final auth = context.read<AuthProvider>();
    final userEmail = auth.email;

    if (mounted) setState(() => _isProcessingBiometric = true);

    try {
      if (val) {
        // Enforce live hardware sensor check before enabling
        final bool isAvailable = await _biometricService.isBiometricAvailable();
        if (!isAvailable) {
          if (mounted) {
            _snack(
              'Biometric hardware sensor is unavailable or no fingerprints are enrolled on this device.',
              AppColors.dangerRed,
            );
          }
          return;
        }

        final bool authenticated = await _biometricService.authenticate(
          localizedReason:
              'Scan fingerprint to verify biometric setup for your account ($userEmail)',
        );

        if (!authenticated) {
          if (mounted) {
            _snack(
              'Biometric verification cancelled or failed. Setup aborted.',
              AppColors.warningOrange,
            );
          }
          return;
        }

        await _biometricService.setBiometricConfiguredForUser(userEmail, true);
        await settings.setBiometricEnabled(true);
        if (mounted) {
          _snack(
            'Biometric authentication verified and enabled for your profile.',
            AppColors.successGreen,
          );
        }
      } else {
        await _biometricService.setBiometricConfiguredForUser(userEmail, false);
        await settings.setBiometricEnabled(false);
        if (mounted) {
          _snack(
            'Biometric login disabled for your profile.',
            AppColors.navyDark,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _snack('Could not update biometric setting.', AppColors.dangerRed);
      }
    } finally {
      if (mounted) setState(() => _isProcessingBiometric = false);
    }
  }

  void _changePassword(AuthProvider auth) async {
    final oldPassword = _oldPasswordCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    if (oldPassword.isEmpty) {
      _snack('Please enter your current password.', AppColors.warningOrange);
      return;
    }
    if (newPassword.length < 6) {
      _snack(
        'New password must be at least 6 characters.',
        AppColors.warningOrange,
      );
      return;
    }
    if (oldPassword == newPassword) {
      _snack(
        'New password cannot be the same as current password.',
        AppColors.warningOrange,
      );
      return;
    }
    if (newPassword != confirmPassword) {
      _snack(
        'New password and confirm password do not match.',
        AppColors.warningOrange,
      );
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      final ok = await auth.changePassword(oldPassword, newPassword);
      if (!mounted) return;
      if (ok) {
        _oldPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
        _snack('Password updated successfully!', AppColors.successGreen);
      } else {
        _snack('Current password is incorrect.', AppColors.dangerRed);
      }
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          'Login & Security',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyDark),
      ),
      body: Column(
        children: [
          _buildHeroHeaderBanner(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                top: AppSpacing.lg,
                bottom: AppSpacing.xxl,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChangePasswordSection(auth),
                        const SizedBox(height: AppSpacing.lg),
                        _buildBiometricSection(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSecurityNoticeCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeaderBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.lg),
          bottomRight: Radius.circular(AppRadius.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.md,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.goldPrimary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.goldPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Account Security & Credentials',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage your password and biometric authentication settings',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordSection(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Change Password', Icons.lock_reset_rounded),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: _cardDecoration(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPasswordInputField(
                label: 'CURRENT PASSWORD',
                hintText: 'Enter current password',
                controller: _oldPasswordCtrl,
                isObscured: !_showOldPassword,
                onToggleVisibility: () =>
                    setState(() => _showOldPassword = !_showOldPassword),
                disableAutofill: true,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildPasswordInputField(
                label: 'NEW PASSWORD',
                hintText: 'Minimum 6 characters',
                controller: _newPasswordCtrl,
                isObscured: !_showNewPassword,
                onToggleVisibility: () =>
                    setState(() => _showNewPassword = !_showNewPassword),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildPasswordInputField(
                label: 'CONFIRM NEW PASSWORD',
                hintText: 'Re-enter new password',
                controller: _confirmPasswordCtrl,
                isObscured: !_showConfirmPassword,
                onToggleVisibility: () => setState(
                  () => _showConfirmPassword = !_showConfirmPassword,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isChangingPassword
                      ? null
                      : () => _changePassword(auth),
                  icon: _isChangingPassword
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 20,
                        ),
                  label: Text(
                    _isChangingPassword
                        ? 'Updating Password...'
                        : 'Update Password',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyMid,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required bool isObscured,
    required VoidCallback onToggleVisibility,
    bool disableAutofill = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.lightSubText,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isObscured,
          enableSuggestions: !disableAutofill,
          autocorrect: false,
          enableInteractiveSelection: true,
          autofillHints: disableAutofill
              ? null
              : const [AutofillHints.newPassword],
          style: GoogleFonts.poppins(
            color: AppColors.navyDark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.navyMid,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isObscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.lightSubText,
                size: 20,
              ),
              onPressed: onToggleVisibility,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: AppColors.navyMid.withValues(alpha: 0.15),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: AppColors.navyMid.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.navyMid, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Biometric Authentication',
          Icons.fingerprint_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: _cardDecoration(),
          child: Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              final isEnabled = settings.isBiometricEnabled;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isProcessingBiometric
                      ? null
                      : () => _toggleBiometric(!isEnabled, settings),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isEnabled
                                ? AppColors.successGreen.withValues(alpha: 0.12)
                                : AppColors.navyMid.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            Icons.fingerprint_rounded,
                            color: isEnabled
                                ? AppColors.successGreen
                                : AppColors.navyMid,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable Fingerprint Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEnabled
                                    ? 'Biometric authentication active for instant unlock'
                                    : 'Use device biometrics for instant unlock',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: isEnabled
                                      ? AppColors.successGreen
                                      : AppColors.lightSubText,
                                  fontWeight: isEnabled
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isEnabled,
                          activeThumbColor: AppColors.successGreen,
                          activeTrackColor: AppColors.successGreen.withValues(
                            alpha: 0.3,
                          ),
                          onChanged: _isProcessingBiometric
                              ? null
                              : (val) => _toggleBiometric(val, settings),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityNoticeCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyMid.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.navyMid.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.navyMid, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Security Notice: Keep your password confidential. Your credentials are protected with industry-standard encryption.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.navyDark.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.navyMid.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 18, color: AppColors.navyMid),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(
        color: AppColors.navyMid.withValues(alpha: 0.08),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
