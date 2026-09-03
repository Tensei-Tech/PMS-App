// lib/screens/admin_panel_screen.dart
// Compact & Space-Optimized State / Division Admin Control Dashboard.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/police_hierarchy_helper.dart';
import '../widgets/create_sub_admin_dialog.dart';
import 'pending_approvals_screen.dart';
import 'state_admin_hierarchy_screen.dart';
import 'division_admin_hierarchy_screen.dart';
import 'district_admin_hierarchy_screen.dart';
import 'station_admin_panel_screen.dart';
import 'state_audit_log_screen.dart';
import 'division_audit_log_screen.dart';
import 'district_audit_log_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final ApiService _apiService = ApiService();
  int _pendingCount = 0;
  bool _isLoadingPending = false;

  @override
  void initState() {
    super.initState();
    _fetchPendingCount();
  }

  Future<void> _fetchPendingCount() async {
    if (!mounted) return;
    setState(() => _isLoadingPending = true);
    try {
      final res = await _apiService.get(ApiConfig.authPendingApprovals);
      if (!mounted) return;
      if (res.isSuccess && res.data is List) {
        setState(() {
          _pendingCount = (res.data as List).length;
          _isLoadingPending = false;
        });
      } else {
        setState(() => _isLoadingPending = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = (auth.roleId).toLowerCase();

    final isStateAdmin = PoliceHierarchyHelper.isStateSuperAdmin(
            auth.designation, auth.roleId) ||
        role == 'state_admin' ||
        role == 'state_super_admin' ||
        role == 'master_admin';

    final isDivAdmin =
        !isStateAdmin && (role == 'division_admin' || role == 'supervisor');
    final isDistrictAdmin =
        !isStateAdmin && !isDivAdmin && (role == 'district_admin');
    final isStationAdmin = !isStateAdmin &&
        !isDivAdmin &&
        !isDistrictAdmin &&
        (role == 'station_head' || role == 'station_admin');

    // If caller is Station Head / Station Admin, render Station Command Panel
    if (isStationAdmin) {
      return const StationAdminPanelScreen();
    }

    final headerTitle = isStateAdmin
        ? 'State Command & Control Center'
        : isDivAdmin
            ? 'Division Command & Control Center'
            : 'District Command & Control Center';

    final headerSubtitle = isStateAdmin
        ? 'Manage registration approvals, sub-admin creation, and state hierarchy directory.'
        : isDivAdmin
            ? 'Manage officer approvals, station head creation, and districts/stations in your division.'
            : 'Manage station head creation and police stations inside your district.';

    final createAdminTitle = isStateAdmin
        ? 'Create Sub-Admin (District / Div / Station)'
        : isDivAdmin
            ? 'Create Station Head / Sub-Admin'
            : 'Create Station Head (SHO / PI)';

    final createAdminSubtitle = isStateAdmin
        ? 'Provision District Admins, Division Admins, or Station Heads with administrative grants.'
        : isDivAdmin
            ? 'Provision Station Heads (SHO/PI) and sub-division admins inside your assigned division.'
            : 'Provision Station Heads (SHO/PI) across police stations in your assigned district.';

    final hierarchyTitle = isStateAdmin
        ? 'State Admin Hierarchy & Directory'
        : isDivAdmin
            ? 'Division Hierarchy & Directory'
            : 'District Stations & Directory';

    final hierarchySubtitle = isStateAdmin
        ? 'View all 6 Divisions, Districts, and Station Heads across Maharashtra Police.'
        : isDivAdmin
            ? 'View districts and police stations assigned under your division range.'
            : 'View police stations and Station Heads (SHO) assigned under your district.';

    final panelTitle = isStateAdmin
        ? 'State Admin Panel'
        : isDivAdmin
            ? 'Division Admin Panel'
            : 'District Admin Panel';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          panelTitle,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── COMPACT TOP HEADER BANNER ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navyDark, AppColors.navyMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyDark.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.4),
                          width: 1.2),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded,
                        color: AppColors.goldLight, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          headerSubtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 8),
              child: Text(
                'ADMINISTRATIVE TOOLS',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                  letterSpacing: 0.6,
                ),
              ),
            ),

            // ── CARD 1: PENDING APPROVALS ──
            _buildCompactControlCard(
              title: 'Officer Approvals (Pending)',
              subtitle:
                  'Review & approve pending officer registration and access requests across jurisdiction.',
              icon: Icons.how_to_reg_rounded,
              color: Colors.orange.shade700,
              badgeCount: _pendingCount,
              isLoadingBadge: _isLoadingPending,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PendingApprovalsScreen()),
                );
                _fetchPendingCount();
              },
            ),
            const SizedBox(height: 8),

            // ── CARD 2: CREATE SUB-ADMIN ──
            _buildCompactControlCard(
              title: createAdminTitle,
              subtitle: createAdminSubtitle,
              icon: Icons.person_add_alt_1_rounded,
              color: Colors.blue.shade700,
              onTap: () => CreateSubAdminDialog.show(context),
            ),
            const SizedBox(height: 8),

            // ── CARD 3: HIERARCHY DIRECTORY ──
            _buildCompactControlCard(
              title: hierarchyTitle,
              subtitle: hierarchySubtitle,
              icon: Icons.account_tree_rounded,
              color: Colors.teal.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => isStateAdmin
                        ? const StateAdminHierarchyScreen()
                        : isDivAdmin
                            ? const DivisionAdminHierarchyScreen()
                            : const DistrictAdminHierarchyScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // ── CARD 4: AUDIT LOGS & SECURITY STREAM ──
            _buildCompactControlCard(
              title: 'Audit Logs & Security Stream',
              subtitle: isStateAdmin
                  ? 'View state-wide security events, logins, and system activity with live search.'
                  : isDivAdmin
                      ? 'View security events and officer actions across your division.'
                      : 'View security events and officer actions inside your district.',
              icon: Icons.manage_search_rounded,
              color: Colors.purple.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => isStateAdmin
                        ? const StateAuditLogScreen()
                        : isDivAdmin
                            ? const DivisionAuditLogScreen()
                            : const DistrictAuditLogScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactControlCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
    bool isLoadingBadge = false,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyDark,
                            ),
                          ),
                        ),
                        if (isLoadingBadge)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.orange),
                          )
                        else if (badgeCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$badgeCount',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: Colors.grey.shade700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
