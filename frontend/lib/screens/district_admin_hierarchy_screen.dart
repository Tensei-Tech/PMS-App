// lib/screens/district_admin_hierarchy_screen.dart
// Dedicated District Admin Hierarchy Directory (Police Stations & Station Heads in assigned district).

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
    extends State<DistrictAdminHierarchyScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _stations = [];
  String _assignedDistrictName = 'District Range';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDistrictHierarchyDirectory();
  }

  @override
  void dispose() {
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
    final filteredStations = _stations.where((st) {
      final name = (st['name'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase().trim();
      return name.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'District Admin Directory',
              style: GoogleFonts.poppins(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'District: $_assignedDistrictName',
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.goldLight, size: 20),
            onPressed: _fetchDistrictHierarchyDirectory,
            tooltip: 'Refresh Directory',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.navyDark))
          : _errorMessage != null
              ? _buildErrorView()
              : Column(
                  children: [
                    // Station Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: GoogleFonts.poppins(
                            fontSize: 12.5, color: AppColors.navyDark),
                        decoration: InputDecoration(
                          hintText:
                              'Search police stations in $_assignedDistrictName...',
                          hintStyle: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey.shade500),
                          prefixIcon: const Icon(Icons.search_rounded,
                              size: 18, color: AppColors.navyDark),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon:
                                      const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filteredStations.isEmpty
                          ? _buildEmptyState(_searchQuery.isEmpty
                              ? 'No police stations found in $_assignedDistrictName.'
                              : 'No stations match "$_searchQuery".')
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filteredStations.length,
                              itemBuilder: (ctx, idx) {
                                final st = filteredStations[idx];
                                final name = st['name'] ?? 'Police Station';
                                final head =
                                    st['head'] as Map<String, dynamic>?;

                                return Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.teal.shade50,
                                      child: Icon(Icons.local_police_rounded,
                                          color: Colors.teal.shade700,
                                          size: 18),
                                    ),
                                    title: Text(
                                      name,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.navyDark),
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
            Icon(Icons.folder_open_rounded,
                size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500),
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
            const Icon(Icons.error_outline_rounded,
                size: 44, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: AppColors.navyDark),
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
