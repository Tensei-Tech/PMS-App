// lib/screens/division_admin_hierarchy_screen.dart
// Dedicated Division Admin Hierarchy Directory (Districts & Stations only for assigned division range).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DivisionAdminHierarchyScreen extends StatefulWidget {
  const DivisionAdminHierarchyScreen({super.key});

  @override
  State<DivisionAdminHierarchyScreen> createState() =>
      _DivisionAdminHierarchyScreenState();
}

class _DivisionAdminHierarchyScreenState
    extends State<DivisionAdminHierarchyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _stations = [];
  String _assignedDivisionName = 'Division Range';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDivisionHierarchyDirectory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDivisionHierarchyDirectory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.get(ApiConfig.hierarchyDirectory);
      if (!mounted) return;

      if (response.isSuccess && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        setState(() {
          _districts =
              (data['districts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _stations =
              (data['stations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _assignedDivisionName =
              data['assigned_division']?.toString() ?? 'Division Range';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response.errorMessage ??
              'Failed to load division hierarchy directory';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Division Admin Directory',
              style: GoogleFonts.poppins(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              _assignedDivisionName,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: AppColors.goldLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        toolbarHeight: 52,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.goldLight,
              size: 20,
            ),
            onPressed: _fetchDivisionHierarchyDirectory,
            tooltip: 'Refresh Directory',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldPrimary,
          indicatorWeight: 3,
          labelColor: AppColors.goldLight,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          labelStyle: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.map_rounded, size: 18), text: 'Districts'),
            Tab(
              icon: Icon(Icons.local_police_rounded, size: 18),
              text: 'Stations',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.navyDark),
            )
          : _errorMessage != null
          ? _buildErrorView()
          : TabBarView(
              controller: _tabController,
              children: [_buildDistrictsTab(), _buildStationsTab()],
            ),
    );
  }

  Widget _buildDistrictsTab() {
    if (_districts.isEmpty) {
      return _buildEmptyState(
        'No districts assigned under $_assignedDivisionName.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _districts.length,
      itemBuilder: (ctx, idx) {
        final dist = _districts[idx];
        final name = dist['name'] ?? 'District';
        final admins =
            (dist['admins'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade50,
              child: Icon(
                Icons.map_rounded,
                color: Colors.blue.shade700,
                size: 18,
              ),
            ),
            title: Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            subtitle: Text(
              '${admins.length} District Admin(s) assigned',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            children: admins.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'No District Admin currently assigned.',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ]
                : admins
                      .map(
                        (adm) => _buildOfficerListTile(adm, 'District Admin'),
                      )
                      .toList(),
          ),
        );
      },
    );
  }

  Widget _buildStationsTab() {
    if (_stations.isEmpty) {
      return _buildEmptyState(
        'No police stations assigned under $_assignedDivisionName.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _stations.length,
      itemBuilder: (ctx, idx) {
        final st = _stations[idx];
        final name = st['name'] ?? 'Police Station';
        final dist = st['district'] ?? '';
        final head = st['head'] as Map<String, dynamic>?;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.teal.shade50,
              child: Icon(
                Icons.local_police_rounded,
                color: Colors.teal.shade700,
                size: 18,
              ),
            ),
            title: Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dist.isNotEmpty)
                  Text(
                    'District: $dist',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  head != null
                      ? 'Head: ${head['name']} (${head['designation']})'
                      : 'Head: Unassigned',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: head != null
                        ? AppColors.navyDark
                        : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOfficerListTile(
    Map<String, dynamic> officer,
    String defaultRole,
  ) {
    final name = officer['name'] ?? 'Officer';
    final desig = officer['designation'] ?? defaultRole;
    final badge = officer['badge_number'] ?? '';
    final phone = officer['phone'] ?? '';
    final status = officer['account_status'] ?? 'active';

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.navyDark.withValues(alpha: 0.1),
          child: const Icon(
            Icons.person_rounded,
            size: 16,
            color: AppColors.navyDark,
          ),
        ),
        title: Text(
          '$name ($desig)',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.navyDark,
          ),
        ),
        subtitle: Text(
          'Badge: ${badge.isNotEmpty ? badge : "N/A"} • Phone: ${phone.isNotEmpty ? phone : "N/A"}',
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: status == 'active'
                ? Colors.green.shade50
                : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: status == 'active'
                  ? Colors.green.shade800
                  : Colors.orange.shade800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 44,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _fetchDivisionHierarchyDirectory,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyDark,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
