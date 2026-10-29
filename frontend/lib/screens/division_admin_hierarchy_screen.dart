// lib/screens/division_admin_hierarchy_screen.dart
// Division Admin directory: the police stations their division is made of,
// with each station's head. A division sits below its district or city, so
// no districts are listed here.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/officer_details_dialog.dart';

class DivisionAdminHierarchyScreen extends StatefulWidget {
  const DivisionAdminHierarchyScreen({super.key});

  @override
  State<DivisionAdminHierarchyScreen> createState() =>
      _DivisionAdminHierarchyScreenState();
}

class _DivisionAdminHierarchyScreenState
    extends State<DivisionAdminHierarchyScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _stations = [];
  String _assignedDivisionName = 'Division Range';

  @override
  void initState() {
    super.initState();
    _fetchDivisionHierarchyDirectory();
  }

  Future<void> _fetchDivisionHierarchyDirectory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.get(
        ApiConfig.hierarchyDirectory,
        timeout: ApiConstants.longReceiveTimeout,
      );
      if (!mounted) return;

      if (response.isSuccess && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        setState(() {
          _stations =
              (data['stations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _assignedDivisionName =
              data['assigned_division']?.toString() ?? 'Division Range';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.errorMessage ??
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.local_police_rounded,
                  size: 18,
                  color: AppColors.goldLight,
                ),
                const SizedBox(width: 8),
                Text(
                  _isLoading
                      ? 'Police Stations'
                      : 'Police Stations (${_stations.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.navyDark),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _buildStationsTab(),
    );
  }

  Widget _buildStationsTab() {
    if (_stations.isEmpty) {
      return _buildEmptyState(
        'No police stations in $_assignedDivisionName yet.',
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
            onTap: head == null ? null : () => _showOfficer(head),
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

  /// Shows an officer's profile and assignment (read-only).
  void _showOfficer(Map<String, dynamic> officer) {
    OfficerDetailsDialog.show(context, officerData: officer);
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
