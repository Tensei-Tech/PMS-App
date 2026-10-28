// lib/screens/district_admin_hierarchy_screen.dart
// District / City Admin Hierarchy Directory, laid out like the State Admin
// hierarchy: a Divisions tab (each division with its admins and police
// stations) and a Police Stations tab (each station with its Station Head).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DistrictAdminHierarchyScreen extends StatefulWidget {
  const DistrictAdminHierarchyScreen({super.key});

  @override
  State<DistrictAdminHierarchyScreen> createState() =>
      _DistrictAdminHierarchyScreenState();
}

class _DistrictAdminHierarchyScreenState
    extends State<DistrictAdminHierarchyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _divisions = [];
  List<Map<String, dynamic>> _stations = [];
  String _assignedDistrictName = 'District Range';
  String _stationSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDistrictHierarchyDirectory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDistrictHierarchyDirectory() async {
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
          _divisions =
              (data['divisions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _stations =
              (data['stations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _assignedDistrictName = data['assigned_district']?.toString() ??
              data['assigned_division']?.toString() ??
              'District Range';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.errorMessage ??
              'Failed to load district hierarchy directory';
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
              'District Admin Hierarchy',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              _assignedDistrictName,
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
            onPressed: _fetchDistrictHierarchyDirectory,
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
          tabs: [
            Tab(
              icon: const Icon(Icons.location_city_rounded, size: 18),
              text: 'Divisions (${_divisions.length})',
            ),
            Tab(
              icon: const Icon(Icons.local_police_rounded, size: 18),
              text: 'Police Stations (${_stations.length})',
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
                  children: [
                    _buildDivisionsTab(),
                    _buildStationsTab(),
                  ],
                ),
    );
  }

  // ── 1. DIVISIONS TAB: each division with its admins and police stations ──
  Widget _buildDivisionsTab() {
    if (_divisions.isEmpty) {
      return _buildEmptyState(
          'No divisions yet. Create a Division Admin from Admin Panel → Create Division Admin / Station Head.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _divisions.length,
      itemBuilder: (context, index) {
        final div = _divisions[index];
        final name = div['name'] ?? 'Division';
        final admins =
            (div['admins'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        // A division is a group of police stations.
        final stations = (div['stations'] as List?)?.cast<String>() ?? [];

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
              backgroundColor: Colors.amber.shade50,
              child: Icon(
                Icons.location_city_rounded,
                color: Colors.amber.shade800,
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
              '${admins.length} Division Admin(s) • ${stations.length} Police Station(s)',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            children: [
              if (admins.isEmpty)
                _buildNote('No Division Admin assigned to this Division.')
              else
                ...admins.map(
                  (admin) =>
                      _buildAdminTile(admin, roleLabel: 'Division Admin'),
                ),
              if (stations.isNotEmpty) ...[
                _buildSubHeader('Police Stations in this Division'),
                ...stations.map(_buildStationRow),
              ],
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  // ── 2. POLICE STATIONS TAB: each station with its Station Head ──
  Widget _buildStationsTab() {
    final query = _stationSearchQuery.toLowerCase().trim();
    final filtered = _stations
        .where(
            (st) => (st['name'] ?? '').toString().toLowerCase().contains(query))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _stationSearchQuery = val),
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppColors.navyDark,
            ),
            decoration: InputDecoration(
              hintText: 'Search police stations in $_assignedDistrictName...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.navyDark,
              ),
              suffixIcon: _stationSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _stationSearchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(
                  _stationSearchQuery.isEmpty
                      ? 'No police stations found in $_assignedDistrictName.'
                      : 'No stations match "$_stationSearchQuery".',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final st = filtered[idx];
                    final name = st['name'] ?? 'Police Station';
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
                        subtitle: Text(
                          head != null
                              ? 'Station Head (SHO): ${head['name']} (${head['designation']})'
                              : 'Station Head: Unassigned (Pending SHO)',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: head != null
                                ? AppColors.navyDark
                                : Colors.orange.shade800,
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

  Widget _buildSubHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildStationRow(String station) {
    final head = _stations.firstWhere(
      (st) =>
          (st['name'] ?? '').toString().toLowerCase() == station.toLowerCase(),
      orElse: () => const {},
    )['head'] as Map<String, dynamic>?;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(Icons.local_police_rounded,
          size: 16, color: Colors.teal.shade700),
      title: Text(
        station,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.navyDark,
        ),
      ),
      subtitle: Text(
        head != null
            ? 'Station Head: ${head['name']} (${head['designation']})'
            : 'Station Head: Unassigned',
        style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildNote(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500),
      ),
    );
  }

  Widget _buildAdminTile(
    Map<String, dynamic> admin, {
    required String roleLabel,
  }) {
    final name = admin['name'] ?? 'Officer';
    final desig = admin['designation'] ?? roleLabel;
    final badge = (admin['badge_number'] ?? '').toString();
    final phone = (admin['phone'] ?? '').toString();
    final status = (admin['account_status'] ?? 'active').toString();

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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_rounded,
                size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: Colors.grey.shade600,
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
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _fetchDistrictHierarchyDirectory,
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
