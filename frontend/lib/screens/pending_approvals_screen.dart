// lib/screens/pending_approvals_screen.dart
// PostgreSQL-powered officer registration approval screen for superiors in hierarchy.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/pending_approvals_scope.dart';
import '../widgets/officer_details_dialog.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchRequests();
      }
    });
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      if (!auth.isInitialized) {
        int attempts = 0;
        while (!auth.isInitialized && attempts < 30) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }
      }

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
        setState(() {
          _pendingRequests.removeWhere((r) => r['registration_uid'] == uid || r['id'] == uid || r['id'] == 'off-$uid' || r['id'] == 'pub-$uid');
        });
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
        setState(() {
          _pendingRequests.removeWhere((r) => r['registration_uid'] == uid || r['id'] == uid || r['id'] == 'off-$uid' || r['id'] == 'pub-$uid');
        });
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              itemCount: _pendingRequests.length,
                              itemBuilder: (context, index) {
                                final req = _pendingRequests[index];
                                final uid = req['registration_uid']?.toString() ?? req['id']?.toString() ?? '';
                                final rawTitle = req['title']?.toString() ?? 'Registration Request';
                                final body = req['body']?.toString() ?? '';
                                final station = req['target_station']?.toString() ?? req['station_name']?.toString() ?? '';
                                final district = req['target_district']?.toString() ?? req['district']?.toString() ?? '';
                                final busy = _processingUids.contains(uid);

                                // Extract clean Officer Name and Designation
                                String officerTitle = req['name']?.toString() ?? '';
                                String desig = req['designation']?.toString() ?? '';
                                if (officerTitle.isEmpty) {
                                  if (body.startsWith('Officer ')) {
                                    final parts = body.replaceFirst('Officer ', '').split(' registered');
                                    officerTitle = parts[0];
                                  } else {
                                    officerTitle = rawTitle.replaceAll('New Officer System-Wide ', '').replaceAll(' Registration Pending', '');
                                  }
                                }

                                String locationTag = '';
                                if (station.isNotEmpty && district.isNotEmpty) {
                                  locationTag = '$station • $district';
                                } else if (station.isNotEmpty) {
                                  locationTag = station;
                                } else if (district.isNotEmpty) {
                                  locationTag = 'District: $district';
                                } else {
                                  locationTag = 'State Jurisdiction Request';
                                }

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  elevation: 1,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  child: InkWell(
                                    onTap: () => OfficerDetailsDialog.show(
                                      context,
                                      officerData: req,
                                      onApprove: _approve,
                                      onReject: _reject,
                                      isBusy: busy,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: AppColors.navyDark.withValues(alpha: 0.08),
                                                child: const Icon(Icons.person_rounded, color: AppColors.navyDark, size: 18),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      officerTitle,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.navyDark,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 1),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.location_on_rounded, size: 12, color: Colors.grey.shade600),
                                                        const SizedBox(width: 3),
                                                        Expanded(
                                                          child: Text(
                                                            locationTag,
                                                            style: GoogleFonts.poppins(
                                                              fontSize: 11,
                                                              color: Colors.grey.shade700,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.visibility_rounded, size: 18, color: AppColors.navyDark),
                                                tooltip: 'View Officer Registration Details',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                onPressed: () => OfficerDetailsDialog.show(
                                                  context,
                                                  officerData: req,
                                                  onApprove: _approve,
                                                  onReject: _reject,
                                                  isBusy: busy,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade700.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Pending',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.orange.shade800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  height: 32,
                                                  child: OutlinedButton.icon(
                                                    onPressed: busy ? null : () => _reject(uid, officerTitle),
                                                    icon: const Icon(Icons.close_rounded, size: 14),
                                                    label: Text(
                                                      'Reject',
                                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11.5),
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: AppColors.dangerRed,
                                                      side: BorderSide(
                                                        color: AppColors.dangerRed.withValues(alpha: 0.4),
                                                      ),
                                                      padding: EdgeInsets.zero,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: SizedBox(
                                                  height: 32,
                                                  child: FilledButton.icon(
                                                    onPressed: busy ? null : () => _approve(uid, officerTitle),
                                                    icon: busy
                                                        ? const SizedBox(
                                                            width: 14,
                                                            height: 14,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: Colors.white,
                                                            ),
                                                          )
                                                        : const Icon(Icons.check_rounded, size: 14),
                                                    label: Text(
                                                      'Approve',
                                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11.5),
                                                    ),
                                                    style: FilledButton.styleFrom(
                                                      backgroundColor: AppColors.successGreen,
                                                      foregroundColor: Colors.white,
                                                      padding: EdgeInsets.zero,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
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
