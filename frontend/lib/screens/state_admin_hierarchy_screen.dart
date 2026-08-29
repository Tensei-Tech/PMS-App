// lib/screens/state_admin_hierarchy_screen.dart
// Unified State Admin Hierarchy Directory (Divisions, Districts, & Police Stations).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class StateAdminHierarchyScreen extends StatefulWidget {
  const StateAdminHierarchyScreen({super.key});

  @override
  State<StateAdminHierarchyScreen> createState() => _StateAdminHierarchyScreenState();
}

class _StateAdminHierarchyScreenState extends State<StateAdminHierarchyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _divisions = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _stations = [];
  String _stationSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchHierarchyDirectory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHierarchyDirectory() async {
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
          _divisions = (data['divisions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _districts = (data['districts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _stations = (data['stations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.errorMessage ?? 'Failed to load state admin hierarchy';
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
        title: Text(
          'State Admin Hierarchy',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        toolbarHeight: 52,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.goldLight, size: 20),
            onPressed: _fetchHierarchyDirectory,
            tooltip: 'Refresh Directory',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldPrimary,
          indicatorWeight: 3,
          labelColor: AppColors.goldLight,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          labelStyle: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(icon: Icon(Icons.location_city_rounded, size: 18), text: 'Divisions'),
            Tab(icon: Icon(Icons.map_rounded, size: 18), text: 'Districts'),
            Tab(icon: Icon(Icons.local_police_rounded, size: 18), text: 'Stations'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navyDark))
          : _errorMessage != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDivisionsTab(),
                    _buildDistrictsTab(),
                    _buildStationsTab(),
                  ],
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
            const Icon(Icons.error_outline_rounded, size: 44, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.navyDark),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _fetchHierarchyDirectory,
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

  // ── 1. DIVISIONS TAB VIEW ──
  Widget _buildDivisionsTab() {
    if (_divisions.isEmpty) {
      return _buildEmptyState('No Divisions found in system.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _divisions.length,
      itemBuilder: (context, index) {
        final div = _divisions[index];
        final name = div['name'] ?? 'Division';
        final admins = (div['admins'] as List?)?.cast<Map<String, dynamic>>() ?? [];

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
              child: Icon(Icons.location_city_rounded, color: Colors.amber.shade800, size: 18),
            ),
            title: Text(
              name,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navyDark),
            ),
            subtitle: Text(
              '${admins.length} Division Admin(s) assigned',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
            ),
            children: [
              if (admins.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'No Division Admin assigned to this Division.',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500),
                  ),
                )
              else
                Column(
                  children: admins.map((admin) => _buildAdminTile(admin, roleLabel: 'Division Admin')).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── 2. DISTRICTS TAB VIEW ──
  Widget _buildDistrictsTab() {
    if (_districts.isEmpty) {
      return _buildEmptyState('No Districts found in system.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _districts.length,
      itemBuilder: (context, index) {
        final dist = _districts[index];
        final name = dist['name'] ?? 'District';
        final divName = dist['division_name'] ?? '';
        final admins = (dist['admins'] as List?)?.cast<Map<String, dynamic>>() ?? [];

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
              child: Icon(Icons.map_rounded, color: Colors.blue.shade700, size: 18),
            ),
            title: Text(
              name,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navyDark),
            ),
            subtitle: Text(
              divName.isNotEmpty ? 'Division: $divName • ${admins.length} District Admin(s)' : '${admins.length} District Admin(s)',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
            ),
            children: [
              if (admins.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'No District Admin assigned to this District.',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500),
                  ),
                )
              else
                Column(
                  children: admins.map((admin) => _buildAdminTile(admin, roleLabel: 'District Admin')).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── 3. STATIONS TAB VIEW ──
  Widget _buildStationsTab() {
    final filtered = _stations.where((st) {
      final name = (st['name'] ?? '').toString().toLowerCase();
      final dist = (st['district'] ?? '').toString().toLowerCase();
      final query = _stationSearchQuery.toLowerCase().trim();
      return name.contains(query) || dist.contains(query);
    }).toList();

    return Column(
      children: [
        // Station Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _stationSearchQuery = val;
              });
            },
            style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.navyDark),
            decoration: InputDecoration(
              hintText: 'Search police stations or districts...',
              hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.navyDark),
              suffixIcon: _stationSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _stationSearchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
              ? _buildEmptyState(_stationSearchQuery.isEmpty ? 'No Police Stations found.' : 'No stations match "$_stationSearchQuery".')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final st = filtered[index];
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.teal.shade50,
                          child: Icon(Icons.local_police_rounded, color: Colors.teal.shade700, size: 18),
                        ),
                        title: Text(
                          name,
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navyDark),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (dist.isNotEmpty)
                              Text(
                                'District: $dist',
                                style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade600),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              head != null ? 'Head: ${head['name']} (${head['designation']})' : 'Head: Unassigned',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: head != null ? AppColors.navyDark : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAdminTile(Map<String, dynamic> admin, {required String roleLabel}) {
    final name = admin['name'] ?? 'Officer';
    final desig = admin['designation'] ?? roleLabel;
    final badge = admin['badge_number'] ?? '';
    final phone = admin['phone'] ?? '';
    final status = admin['account_status'] ?? 'active';

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.navyDark.withValues(alpha: 0.1),
          child: const Icon(Icons.person_rounded, size: 16, color: AppColors.navyDark),
        ),
        title: Text(
          '$name ($desig)',
          style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.navyDark),
        ),
        subtitle: Text(
          'Badge: ${badge.isNotEmpty ? badge : "N/A"} • Phone: ${phone.isNotEmpty ? phone : "N/A"}',
          style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade600),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: status == 'active' ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: status == 'active' ? Colors.green.shade800 : Colors.orange.shade800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
