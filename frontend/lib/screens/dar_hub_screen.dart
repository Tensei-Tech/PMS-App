import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';
import '../modules/core/models/base_record.dart';
import '../widgets/dynamic_form/dynamic_form_screen.dart';

class DarHubScreen extends StatefulWidget {
  final String? stationName;
  const DarHubScreen({super.key, this.stationName});

  @override
  State<DarHubScreen> createState() => _DarHubScreenState();
}

class _DarHubScreenState extends State<DarHubScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // Summary Metrics
  int _totalDar = 0;
  int _darFilled = 0;
  int _darPending = 0;

  // Cases List
  List<dynamic> _cases = [];

  // Filter & Search
  String _statusFilter = 'all'; // 'all', 'pending', 'filled'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchDarData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDarData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final qp = <String>[];
      if (_statusFilter != 'all') {
        qp.add('status=$_statusFilter');
      }
      if (widget.stationName != null &&
          widget.stationName!.isNotEmpty &&
          widget.stationName != 'All Stations') {
        qp.add('station_name=${Uri.encodeComponent(widget.stationName!)}');
      }
      if (_searchQuery.trim().isNotEmpty) {
        qp.add('search=${Uri.encodeComponent(_searchQuery.trim())}');
      }

      final queryStr = qp.isNotEmpty ? '?${qp.join('&')}' : '';
      final url = '${ApiConfig.cases}dar/$queryStr';

      final res = await _apiService.get(url);

      if (res.isSuccess && res.data != null) {
        final data = res.data;
        if (data is Map) {
          final stats = (data['stats'] is Map)
              ? data['stats']
              : ((data['summary'] is Map) ? data['summary'] : data);
          final casesList = (data['results'] is List)
              ? data['results']
              : (data['cases'] is List ? data['cases'] : []);

          int total = int.tryParse(stats['total_dar']?.toString() ?? '') ??
              (data['total_count'] is int ? data['total_count'] : 0);
          int filled = int.tryParse(stats['dar_filled']?.toString() ?? '') ??
              int.tryParse(stats['dar_form_filled']?.toString() ?? '') ?? 0;
          int pending = int.tryParse(stats['dar_pending']?.toString() ?? '') ??
              int.tryParse(stats['dar_form_pending']?.toString() ?? '') ?? 0;

          // Calculate from cases if summary is 0 but cases are loaded
          if (total == 0 && casesList.isNotEmpty) {
            total = casesList.length;
            filled = 0;
            pending = 0;
            for (final c in casesList) {
              final st = (c['status'] ?? '').toString().toLowerCase();
              if (st == 'filled' || st == 'completed') {
                filled++;
              } else {
                pending++;
              }
            }
          }

          setState(() {
            _totalDar = total;
            _darFilled = filled;
            _darPending = pending;
            _cases = casesList;
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _errorMessage = res.errorMessage ?? 'Failed to load DAR cases';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendReminderToIO(String caseId, String crNo, String ioName) async {
    try {
      final url = '${ApiConfig.cases}dar/$caseId/remind/';
      final res = await _apiService.post(url, body: {});

      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder sent to IO for case $crNo',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.errorMessage ?? 'Failed to send reminder',
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
          content: Text('Error sending reminder: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  Future<void> _openNewCaseForm() async {
    await Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: const DynamicFormScreen(
          moduleLabel: 'DAR',
          moduleKey: 'dar',
          subCategory: 'Road Accident',
        ),
      ),
    );
    if (mounted) {
      _fetchDarData();
    }
  }

  Future<void> _openCaseForm(Map<String, dynamic> caseData) async {
    final caseId = caseData['id']?.toString() ?? '';
    final crNo = caseData['cr_no']?.toString() ??
        caseData['case_number']?.toString() ??
        '';
    final existingExtra = (caseData['extra_fields'] is Map)
        ? Map<String, dynamic>.from(caseData['extra_fields'])
        : (caseData['fields'] is Map
            ? Map<String, dynamic>.from(caseData['fields'])
            : <String, dynamic>{});

    await Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: DynamicFormScreen(
          moduleLabel: 'DAR',
          moduleKey: (caseData['module_key']?.toString().isNotEmpty == true)
              ? caseData['module_key'].toString()
              : 'dar',
          subCategory: (caseData['sub_category']?.toString().isNotEmpty == true)
              ? caseData['sub_category'].toString()
              : 'Road Accident',
          existingRecord: ModuleRecord(
            id: caseId,
            caseNumber: crNo,
            title: caseData['act_and_section']?.toString() ?? '',
            moduleKey: (caseData['module_key']?.toString().isNotEmpty == true)
                ? caseData['module_key'].toString()
                : 'dar',
            description: caseData['description']?.toString() ?? '',
            complainant: caseData['complainant']?.toString() ?? '',
            accused: caseData['accused']?.toString() ?? '',
            location: caseData['location']?.toString() ?? '',
            incidentDate: DateTime.tryParse(caseData['incident_date']?.toString() ?? '') ?? DateTime.now(),
            priority: 'Medium',
            assignedOfficer: caseData['io_name']?.toString() ?? '',
            assignedOfficerUid: caseData['io_uid']?.toString() ?? '',
            status: caseData['status']?.toString() ?? 'Pending',
            createdAt: DateTime.tryParse(caseData['created_at']?.toString() ?? '') ?? DateTime.now(),
            subCategory: (caseData['sub_category']?.toString().isNotEmpty == true)
                ? caseData['sub_category'].toString()
                : 'Road Accident',
            extraFields: existingExtra,
            createdBy: '',
            stationName: caseData['station_name']?.toString() ?? widget.stationName ?? '',
          ),
        ),
      ),
    );
    if (mounted) {
      _fetchDarData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyDark),
        title: Text(
          'DAR (Detailed Accident Report)',
          style: GoogleFonts.poppins(
            color: AppColors.navyDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: _openNewCaseForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyMid,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Add Case',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.navyMid),
            tooltip: 'Refresh',
            onPressed: _fetchDarData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.navyMid),
            )
          : RefreshIndicator(
              onRefresh: _fetchDarData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error message if any
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.dangerRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.dangerRed),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(
                                    color: AppColors.dangerRed, fontSize: 13),
                              ),
                            ),
                            TextButton(
                              onPressed: _fetchDarData,
                              child: Text('Retry',
                                  style: GoogleFonts.poppins(
                                      color: AppColors.navyMid,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),

                    // 1. Three Summary Cards
                    _buildSummaryCards(),

                    const SizedBox(height: 16),

                    // 2. Search & Filter Bar
                    _buildSearchAndFilterBar(),

                    const SizedBox(height: 16),

                    // 3. Cases Table
                    _buildCasesTable(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewCaseForm,
        backgroundColor: AppColors.navyMid,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Case',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 700
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'Total DAR',
                count: _totalDar,
                icon: Icons.assignment_rounded,
                color: AppColors.navyMid,
                isActive: _statusFilter == 'all',
                onTap: () {
                  setState(() => _statusFilter = 'all');
                  _fetchDarData();
                },
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'DAR Form Filled',
                count: _darFilled,
                icon: Icons.check_circle_rounded,
                color: AppColors.successGreen,
                isActive: _statusFilter == 'filled',
                onTap: () {
                  setState(() => _statusFilter = 'filled');
                  _fetchDarData();
                },
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'DAR Form Pending',
                count: _darPending,
                icon: Icons.pending_actions_rounded,
                color: AppColors.dangerRed,
                isActive: _statusFilter == 'pending',
                onTap: () {
                  setState(() => _statusFilter = 'pending');
                  _fetchDarData();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isActive ? color : AppColors.lightBorder,
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isActive ? 0.12 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightSubText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by CR No. or IO Name...',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.lightSubText),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.navyMid, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _fetchDarData();
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: AppColors.lightBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
              ),
              onSubmitted: (val) {
                setState(() => _searchQuery = val);
                _fetchDarData();
              },
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyMid,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            onPressed: () {
              setState(() => _searchQuery = _searchController.text);
              _fetchDarData();
            },
            child: Text(
              'Search',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyMid,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(
              'Add Case',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onPressed: _openNewCaseForm,
          ),
        ],
      ),
    );
  }

  Widget _buildCasesTable() {
    if (_cases.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Column(
          children: [
            const Icon(Icons.folder_open_rounded,
                size: 48, color: AppColors.lightSubText),
            const SizedBox(height: 12),
            Text(
              'No Road Accident DAR cases found.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cases will appear here once registered under Road Accident categories.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.lightSubText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppColors.navyMid.withValues(alpha: 0.05),
            ),
            headingTextStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.navyDark,
            ),
            dataTextStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black87,
            ),
            columns: const [
              DataColumn(label: Text('Sr. No.')),
              DataColumn(label: Text('CR No.')),
              DataColumn(label: Text('Act and Section')),
              DataColumn(label: Text('IO Name')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Action / Remind to IO')),
            ],
            rows: _cases.map((c) {
              final srNo = c['sr_no']?.toString() ?? '-';
              final crNo = c['cr_no']?.toString() ??
                  c['case_number']?.toString() ??
                  '-';
              final actSec = c['act_and_section']?.toString() ?? '-';
              final ioName = c['io_name']?.toString() ?? '-';
              final status = c['status']?.toString() ?? 'Pending';
              final isFilled = status.toLowerCase() == 'filled' ||
                  status.toLowerCase() == 'completed';
              final canRemind = c['can_remind'] == true;
              final caseId = c['id']?.toString() ?? '';

              return DataRow(
                cells: [
                  DataCell(Text(srNo)),
                  DataCell(
                    InkWell(
                      onTap: () => _openCaseForm(c),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              crNo,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AppColors.navyMid,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.open_in_new_rounded,
                                size: 14, color: AppColors.navyMid),
                          ],
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(actSec)),
                  DataCell(Text(ioName)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFilled
                            ? AppColors.successGreen
                            : AppColors.dangerRed,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    canRemind
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                            ),
                            icon: const Icon(Icons.notifications_active_rounded,
                                size: 14),
                            label: const Text('Remind to IO'),
                            onPressed: () =>
                                _sendReminderToIO(caseId, crNo, ioName),
                          )
                        : Text(
                            'Completed',
                            style: GoogleFonts.poppins(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
