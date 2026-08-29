// lib/screens/pending_approvals_screen.dart
// PostgreSQL-powered officer registration approval screen for superiors in hierarchy.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/pending_approvals_scope.dart';

/// Pending officer registration / access requests for superiors in hierarchy.
class PendingApprovalsScreen extends StatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
  final ApiService _apiService = ApiService();
  final Set<String> _processingUids = {};
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getPendingOfficerApprovals();
      if (!mounted) return;

      if (response.isSuccess && response.data is List) {
        setState(() {
          _pendingRequests = (response.data as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.errorMessage ?? 'Failed to load requests';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approve(String uid, String name) async {
    if (_processingUids.contains(uid)) return;
    setState(() => _processingUids.add(uid));

    try {
      final response = await _apiService.approveOrRejectOfficer(uid, action: 'approve');
      if (!mounted) return;

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$name approved successfully.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        _fetchRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.errorMessage ?? 'Approval failed',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Approval error: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _processingUids.remove(uid));
    }
  }

  Future<void> _reject(String uid, String name) async {
    if (_processingUids.contains(uid)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Reject registration?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Reject $name\'s access request?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _processingUids.add(uid));
    try {
      final response = await _apiService.approveOrRejectOfficer(uid, action: 'reject');
      if (!mounted) return;

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$name rejected.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.warningOrange,
          ),
        );
        _fetchRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.errorMessage ?? 'Rejection failed',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rejection error: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _processingUids.remove(uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canReview = PendingApprovalsScope.canReviewRegistrations(auth);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.navyDark, size: 20),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Approvals',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            Text(
              PendingApprovalsScope.scopeDescription(auth),
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.lightSubText,
              ),
            ),
          ],
        ),
      ),
      body: !canReview
          ? _AccessDeniedState(designation: auth.designation)
          : RefreshIndicator(
              onRefresh: _fetchRequests,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _EmptyState(
                          icon: _errorMessage!.contains('Authentication')
                              ? Icons.lock_outline_rounded
                              : Icons.error_outline_rounded,
                          title: _errorMessage!.contains('Authentication')
                              ? 'Sign In Required'
                              : 'Could not load requests',
                          subtitle: _errorMessage!.contains('Authentication')
                              ? 'Please sign in with your officer credentials to view pending registration approvals.'
                              : _errorMessage!,
                        )
                      : _pendingRequests.isEmpty
                          ? const _EmptyState(
                              icon: Icons.check_circle_outline_rounded,
                              title: 'No pending approvals',
                              subtitle:
                                  'Registration requests in your jurisdiction will appear here.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              itemCount: _pendingRequests.length,
                              itemBuilder: (context, index) {
                                final req = _pendingRequests[index];
                                final uid = req['registration_uid']?.toString() ?? '';
                                final title = req['title']?.toString() ?? 'Registration Request';
                                final body = req['body']?.toString() ?? '';
                                final station = req['target_station']?.toString() ?? '';
                                final district = req['target_district']?.toString() ?? '';
                                final busy = _processingUids.contains(uid);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    side: const BorderSide(color: AppColors.lightBorder),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor: AppColors.warningOrange.withValues(alpha: 0.15),
                                              child: Icon(Icons.person_rounded,
                                                  color: AppColors.warningOrange, size: 24),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.navyDark,
                                                    ),
                                                  ),
                                                  if (body.isNotEmpty)
                                                    Text(
                                                      body,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                        color: AppColors.infoBlue,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.warningOrange.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'Pending',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.warningOrange,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (station.isNotEmpty) ...[
                                          _InfoRow(
                                            icon: Icons.location_city_rounded,
                                            label: 'Station',
                                            value: station,
                                          ),
                                          const SizedBox(height: 6),
                                        ],
                                        if (district.isNotEmpty) ...[
                                          _InfoRow(
                                            icon: Icons.map_rounded,
                                            label: 'District',
                                            value: district,
                                          ),
                                          const SizedBox(height: 6),
                                        ],
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: busy ? null : () => _reject(uid, title),
                                                icon: const Icon(Icons.close_rounded, size: 18),
                                                label: Text(
                                                  'Reject',
                                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.dangerRed,
                                                  side: BorderSide(
                                                    color: AppColors.dangerRed.withValues(alpha: 0.5),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: FilledButton.icon(
                                                onPressed: busy ? null : () => _approve(uid, title),
                                                icon: busy
                                                    ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    : const Icon(Icons.check_rounded, size: 18),
                                                label: Text(
                                                  'Approve',
                                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                                ),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: AppColors.successGreen,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.lightSubText),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.lightSubText,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: AppColors.navyDark.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.lightSubText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessDeniedState extends StatelessWidget {
  const _AccessDeniedState({required this.designation});

  final String designation;

  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: Icons.lock_outline_rounded,
      title: 'Approvals not available',
      subtitle: designation.trim().isEmpty
          ? 'Your role cannot review registration requests.'
          : '$designation officers cannot review registration requests.',
    );
  }
}
