// lib/screens/state_audit_log_screen.dart
// State Admin Audit Logs Screen (State-wide security event stream with multi-field search and category filtering).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/police_hierarchy_helper.dart';

class StateAuditLogScreen extends StatefulWidget {
  const StateAuditLogScreen({super.key});

  @override
  State<StateAuditLogScreen> createState() => _StateAuditLogScreenState();
}

class _StateAuditLogScreenState extends State<StateAuditLogScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _logs = [];
  String _searchQuery = '';
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'All Events'},
    {'id': 'auth', 'label': 'Auth & Login'},
    {'id': 'admin', 'label': 'Admin Grants'},
    {'id': 'case', 'label': 'Case Activity'},
    {'id': 'security', 'label': 'Security Alerts'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAuditLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final endpoint =
          '${ApiConfig.baseUrl}/core/audit-logs/?q=${Uri.encodeComponent(_searchQuery)}&category=$_selectedCategory';
      final response = await _apiService.get(endpoint);
      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        List rawList = [];
        if (response.data is List) {
          rawList = response.data as List;
        } else if (response.data is Map && response.data['results'] is List) {
          rawList = response.data['results'] as List;
        }

        setState(() {
          _logs = rawList.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.errorMessage ?? 'Failed to load audit logs';
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
    final auth = context.watch<AuthProvider>();
    final role = (auth.roleId).toLowerCase();

    final isStateAdmin = PoliceHierarchyHelper.isStateSuperAdmin(
          auth.designation,
          auth.roleId,
        ) ||
        role == 'state_admin' ||
        role == 'state_super_admin' ||
        role == 'master_admin';
    final isDivAdmin =
        !isStateAdmin && (role == 'division_admin' || role == 'supervisor');
    final isDistrictAdmin =
        !isStateAdmin && !isDivAdmin && (role == 'district_admin');

    final screenTitle = isStateAdmin
        ? 'State Audit Trail & Logs'
        : isDivAdmin
            ? 'Division Audit Trail & Logs'
            : isDistrictAdmin
                ? 'District Audit Trail & Logs'
                : 'Station Audit Trail & Logs';

    final screenSubtitle = isStateAdmin
        ? 'State-wide security event stream (Maharashtra Police HQ)'
        : isDivAdmin
            ? 'Division security stream (${auth.divisionName.isNotEmpty ? auth.divisionName : 'Division Range'})'
            : isDistrictAdmin
                ? 'District security stream (${auth.district.isNotEmpty ? auth.district : 'District Range'})'
                : 'Station security stream (${auth.stationName.isNotEmpty ? auth.stationName : 'Police Station'})';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              screenTitle,
              style: GoogleFonts.poppins(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              screenSubtitle,
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
            onPressed: _fetchAuditLogs,
            tooltip: 'Refresh Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onSubmitted: (val) {
                    _searchQuery = val;
                    _fetchAuditLogs();
                  },
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppColors.navyDark,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Search event, officer name, email, IP or action...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.navyDark,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery = '';
                              _fetchAuditLogs();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
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
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(cat['label']!),
                          selected: isSelected,
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color:
                                isSelected ? Colors.white : AppColors.navyDark,
                          ),
                          selectedColor: AppColors.navyDark,
                          backgroundColor: const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSelected: (val) {
                            setState(() => _selectedCategory = cat['id']!);
                            _fetchAuditLogs();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.navyDark),
                  )
                : _errorMessage != null
                    ? _buildErrorView()
                    : _logs.isEmpty
                        ? _buildEmptyState(
                            'No audit log records match your current filters.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _logs.length,
                            itemBuilder: (ctx, idx) =>
                                _buildAuditCard(_logs[idx]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditCard(Map<String, dynamic> log) {
    final event = log['event']?.toString() ?? 'Security Event';
    final userName =
        log['user_name']?.toString() ?? log['uid']?.toString() ?? 'System User';
    final role = log['user_role']?.toString() ?? 'Officer';
    final details = log['action_details']?.toString() ?? '';
    final category = log['category']?.toString() ?? 'general';
    final station = log['station_name']?.toString() ?? '';
    final district = log['district_name']?.toString() ?? '';
    final createdAt = log['created_at']?.toString() ?? '';

    String formattedDate = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (_) {
        formattedDate = createdAt;
      }
    }

    String locationLabel = 'State Jurisdiction';
    if (station.isNotEmpty && district.isNotEmpty) {
      locationLabel = '$station • $district';
    } else if (station.isNotEmpty) {
      locationLabel = station;
    } else if (district.isNotEmpty) {
      locationLabel = 'District: $district';
    }

    Color catColor = AppColors.navyDark;
    IconData catIcon = Icons.security_rounded;
    if (category == 'auth') {
      catColor = Colors.blue.shade700;
      catIcon = Icons.lock_clock_rounded;
    } else if (category == 'admin') {
      catColor = Colors.purple.shade700;
      catIcon = Icons.admin_panel_settings_rounded;
    } else if (category == 'case') {
      catColor = Colors.teal.shade700;
      catIcon = Icons.folder_shared_rounded;
    } else if (category == 'security') {
      catColor = Colors.red.shade700;
      catIcon = Icons.warning_amber_rounded;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () => _showAuditDetails(log),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: catColor.withValues(alpha: 0.1),
                child: Icon(catIcon, color: catColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$userName ($role) • $locationLabel',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAuditDetails(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audit Event Details',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(height: 12),
              _dialogRow('Event:', log['event']?.toString() ?? 'N/A'),
              _dialogRow('Category:', log['category']?.toString() ?? 'N/A'),
              _dialogRow('User:', '${log['user_name']} (${log['user_role']})'),
              _dialogRow('Email:', log['user_email']?.toString() ?? 'N/A'),
              _dialogRow(
                'Location:',
                '${log['station_name'] ?? ''} ${log['district_name'] ?? ''}',
              ),
              _dialogRow(
                'IP Address:',
                log['ip_address']?.toString() ?? '127.0.0.1',
              ),
              _dialogRow('Timestamp:', log['created_at']?.toString() ?? 'N/A'),
              if ((log['action_details']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Action Summary:',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  log['action_details'].toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              val,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.navyDark,
              ),
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
            Icon(
              Icons.history_toggle_off_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
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
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.navyDark),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _fetchAuditLogs,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyDark,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
