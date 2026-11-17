import '../widgets/module_hub_screen_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';
import '../modules/core/models/base_record.dart';
import '../widgets/app_error_popup.dart';
import '../widgets/app_success_popup.dart';
import '../widgets/dynamic_form/dynamic_form_screen.dart';
import '../widgets/sub_tab_host.dart';

class IradHubScreen extends StatefulWidget {
  final String? stationName;
  const IradHubScreen({super.key, this.stationName});

  @override
  State<IradHubScreen> createState() => _IradHubScreenState();
}

class _IradHubScreenState extends State<IradHubScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // Summary Metrics
  int _totalIrad = 0;
  int _iradFilled = 0;
  int _iradPending = 0;

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
    _fetchIradData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchIradData() async {
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
      final url = '${ApiConfig.cases}irad/$queryStr';

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

          int total = int.tryParse(stats['total_irad']?.toString() ?? '') ??
              (data['total_count'] is int ? data['total_count'] : 0);
          int filled = int.tryParse(stats['irad_filled']?.toString() ?? '') ??
              int.tryParse(stats['irad_form_filled']?.toString() ?? '') ??
              0;
          int pending = int.tryParse(stats['irad_pending']?.toString() ?? '') ??
              int.tryParse(stats['irad_form_pending']?.toString() ?? '') ??
              0;

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
            _totalIrad = total;
            _iradFilled = filled;
            _iradPending = pending;
            _cases = casesList;
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _errorMessage = res.errorMessage ?? 'Failed to load IRAD cases';
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

  Future<void> _sendReminderToIO(
      String caseId, String crNo, String ioName) async {
    try {
      final url = '${ApiConfig.cases}irad/$caseId/remind/';
      final res = await _apiService.post(url, body: {});

      if (!mounted) return;
      if (res.isSuccess) {
        AppSuccessPopup.show(
          context,
          title: 'Reminder Sent',
          message: 'Reminder sent to IO for case $crNo',
        );
      } else {
        AppErrorPopup.show(
          context,
          title: 'Reminder Failed',
          message: res.errorMessage ?? 'Failed to send reminder',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppErrorPopup.show(
        context,
        title: 'Error',
        message: 'Error sending reminder: $e',
      );
    }
  }

  Future<void> _openNewCaseForm() async {
    await Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: const DynamicFormScreen(
          moduleLabel: 'IRAD',
          moduleKey: 'irad',
          subCategory: 'Road Accident',
        ),
      ),
    );
    if (mounted) {
      _fetchIradData();
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
          moduleLabel: 'IRAD',
          moduleKey: (caseData['module_key']?.toString().isNotEmpty == true)
              ? caseData['module_key'].toString()
              : 'irad',
          subCategory: (caseData['sub_category']?.toString().isNotEmpty == true)
              ? caseData['sub_category'].toString()
              : 'Road Accident',
          existingRecord: ModuleRecord(
            id: caseId,
            caseNumber: crNo,
            title: caseData['act_and_section']?.toString() ?? '',
            moduleKey: (caseData['module_key']?.toString().isNotEmpty == true)
                ? caseData['module_key'].toString()
                : 'irad',
            description: caseData['description']?.toString() ?? '',
            complainant: caseData['complainant']?.toString() ?? '',
            accused: caseData['accused']?.toString() ?? '',
            location: caseData['location']?.toString() ?? '',
            incidentDate: DateTime.tryParse(
                    caseData['incident_date']?.toString() ?? '') ??
                DateTime.now(),
            priority: 'Medium',
            assignedOfficer: caseData['io_name']?.toString() ?? '',
            assignedOfficerUid: caseData['io_uid']?.toString() ?? '',
            status: caseData['status']?.toString() ?? 'Pending',
            createdAt:
                DateTime.tryParse(caseData['created_at']?.toString() ?? '') ??
                    DateTime.now(),
            subCategory:
                (caseData['sub_category']?.toString().isNotEmpty == true)
                    ? caseData['sub_category'].toString()
                    : 'Road Accident',
            extraFields: existingExtra,
            createdBy: '',
            stationName: caseData['station_name']?.toString() ??
                widget.stationName ??
                '',
          ),
        ),
      ),
    );
    if (mounted) {
      _fetchIradData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        // Tab switch when opened from a two-tab dashboard tile.
        bottom: SubTabHost.appBarBottom(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navyDark,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'IRAD (Integrated Road Accident Database)',
              style: GoogleFonts.poppins(
                color: AppColors.navyDark,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              'National Database Collision Records',
              style: GoogleFonts.poppins(
                color: AppColors.lightSubText,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          ModuleHubScreenAppBar.buildAddCaseButton(
            context: context,
            onPressed: _openNewCaseForm,
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.navyMid, size: 20),
            tooltip: 'Refresh',
            onPressed: _fetchIradData,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.navyMid),
            )
          : RefreshIndicator(
              onRefresh: _fetchIradData,
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
                              onPressed: _fetchIradData,
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
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;

        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: isCompact ? 'Total' : 'Total IRAD',
                count: _totalIrad,
                icon: Icons.assignment_outlined,
                activeColor: const Color(0xFF1976D2),
                iconBg: const Color(0xFFE8F1FC),
                iconFg: const Color(0xFF1976D2),
                isActive: _statusFilter == 'all',
                isCompact: isCompact,
                onTap: () {
                  setState(() => _statusFilter = 'all');
                  _fetchIradData();
                },
              ),
            ),
            SizedBox(width: isCompact ? 8 : 14),
            Expanded(
              child: _buildMetricCard(
                title: isCompact ? 'Filled' : 'IRAD Form Filled',
                count: _iradFilled,
                icon: Icons.check_circle_outline_rounded,
                activeColor: const Color(0xFF2E7D32),
                iconBg: const Color(0xFFE8F5E9),
                iconFg: const Color(0xFF2E7D32),
                isActive: _statusFilter == 'filled',
                isCompact: isCompact,
                onTap: () {
                  setState(() => _statusFilter = 'filled');
                  _fetchIradData();
                },
              ),
            ),
            SizedBox(width: isCompact ? 8 : 14),
            Expanded(
              child: _buildMetricCard(
                title: isCompact ? 'Pending' : 'IRAD Form Pending',
                count: _iradPending,
                icon: Icons.pending_actions_rounded,
                activeColor: const Color(0xFFE65100),
                iconBg: const Color(0xFFFFF3E0),
                iconFg: const Color(0xFFE65100),
                isActive: _statusFilter == 'pending',
                isCompact: isCompact,
                onTap: () {
                  setState(() => _statusFilter = 'pending');
                  _fetchIradData();
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
    required Color activeColor,
    required Color iconBg,
    required Color iconFg,
    required bool isActive,
    required bool isCompact,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 16,
          vertical: isCompact ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFFE2E8F0),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? activeColor.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isCompact ? 6 : 10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(
                  isCompact ? AppRadius.sm : AppRadius.md,
                ),
              ),
              child: Icon(
                icon,
                color: iconFg,
                size: isCompact ? 16 : 22,
              ),
            ),
            SizedBox(width: isCompact ? 6 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: isCompact ? 10.5 : 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightSubText,
                    ),
                  ),
                  SizedBox(height: isCompact ? 1 : 2),
                  Text(
                    count.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: isCompact ? 18 : 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.navyMid, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: AppColors.navyDark),
              decoration: InputDecoration(
                hintText: 'Search by CR No. or IO Name...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.lightSubText,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (val) {
                setState(() => _searchQuery = val);
                _fetchIradData();
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.lightSubText),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
                _fetchIradData();
              },
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyMid,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              setState(() => _searchQuery = _searchController.text);
              _fetchIradData();
            },
            child: Text(
              'Search',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCasesTable() {
    if (_cases.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F1FC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 36,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'No Road Accident IRAD cases found.',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cases will appear here once registered under Road Accident categories.',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AppColors.lightSubText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  horizontalMargin: 20,
                  columnSpacing: 24,
                  headingRowHeight: 46,
                  dataRowMaxHeight: 52,
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  headingTextStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: AppColors.navyDark,
                    letterSpacing: 0.2,
                  ),
                  dataTextStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.navyDark,
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
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F1FC),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    crNo,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: const Color(0xFF1976D2),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 12,
                                    color: Color(0xFF1976D2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Text(
                              actSec,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text(ioName)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: isFilled
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFF3E0),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: isFilled
                                    ? const Color(0xFFC8E6C9)
                                    : const Color(0xFFFFE0B2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isFilled
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFE65100),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isFilled ? 'Filled' : 'Pending',
                                  style: GoogleFonts.poppins(
                                    color: isFilled
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFE65100),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          canRemind
                              ? OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFE65100),
                                    backgroundColor: const Color(0xFFFFF3E0),
                                    side: const BorderSide(
                                      color: Color(0xFFFFCC80),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    shape: const StadiumBorder(),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(
                                    Icons.notifications_active_outlined,
                                    size: 13,
                                    color: Color(0xFFE65100),
                                  ),
                                  label: Text(
                                    'Remind IO',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFE65100),
                                    ),
                                  ),
                                  onPressed: () =>
                                      _sendReminderToIO(caseId, crNo, ioName),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: Color(0xFF2E7D32),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Completed',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
