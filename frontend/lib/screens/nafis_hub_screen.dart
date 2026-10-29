import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import 'nafis_summary_screen.dart';
import '../modules/core/models/base_record.dart';
import '../utils/arrested_table_firestore_mapper.dart';
import '../utils/excel_export_helper.dart';
import '../widgets/nafis_cases_data_table.dart';

class NAFISHubScreen extends StatefulWidget {
  final String stationName;

  const NAFISHubScreen({
    super.key,
    required this.stationName,
  });

  @override
  State<NAFISHubScreen> createState() => _NAFISHubScreenState();
}

class _NAFISHubScreenState extends State<NAFISHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BackendCaseService _backend = BackendCaseService();

  List<Map<String, dynamic>>? _timeWiseData;
  List<Map<String, dynamic>>? _ioWiseData;
  List<Map<String, dynamic>>? _caseWiseList;
  List<ModuleRecord>? _caseRecords;

  bool _isLoadingTime = false;
  bool _isLoadingIO = false;
  bool _isLoadingCase = false;
  String? _errorTime;
  String? _errorIO;
  String? _errorCase;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadCaseWise();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index == 0 && _caseWiseList == null && !_isLoadingCase) {
      _loadCaseWise();
    } else if (_tabController.index == 1 &&
        _timeWiseData == null &&
        !_isLoadingTime) {
      _loadTimeWise();
    } else if (_tabController.index == 2 &&
        _ioWiseData == null &&
        !_isLoadingIO) {
      _loadIOWise();
    }
  }

  Future<void> _loadCaseWise() async {
    setState(() {
      _isLoadingCase = true;
      _errorCase = null;
    });

    final dataList = await _backend.fetchNAFISCases();

    if (mounted) {
      if (dataList != null) {
        _caseWiseList = dataList;
        final records = dataList.map((m) => ModuleRecord.fromMap(m)).toList();
        _caseRecords = records;
        final mappedRows = arrestedTableRowsAll(records, DateTime.now());

        final enrichedRows = <Map<String, dynamic>>[];
        for (var i = 0; i < mappedRows.length; i++) {
          final r = Map<String, dynamic>.from(mappedRows[i]);
          if (i < records.length) {
            final m = records[i];
            final rawM = i < dataList.length ? dataList[i] : null;
            r['nafis_status'] = rawM?['nafis_status'] ??
                m.extraFields['nafis_status'] ??
                'Pending';
            r['nafis_status_color'] = rawM?['nafis_status_color'] ??
                m.extraFields['nafis_status_color'] ??
                'red';
            r['io_name'] = m.assignedOfficer.isNotEmpty
                ? m.assignedOfficer
                : (r['io'] ?? '—');
            r['accused_name'] =
                m.accused.isNotEmpty ? m.accused : (r['accused_name'] ?? '—');
          }
          enrichedRows.add(r);
        }

        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final r in enrichedRows) {
          final head = r['head']?.toString().trim().isNotEmpty == true
              ? r['head']!.toString().trim()
              : 'All Categories';
          grouped.putIfAbsent(head, () => []).add(r);
        }

        setState(() {
          _isLoadingCase = false;
        });
      } else {
        setState(() {
          _isLoadingCase = false;
          _errorCase = "Failed to load NAFIS cases.";
        });
      }
    }
  }

  Future<void> _loadTimeWise() async {
    setState(() {
      _isLoadingTime = true;
      _errorTime = null;
    });

    final data = await _backend.fetchNAFISTimeWise();

    if (mounted) {
      setState(() {
        _isLoadingTime = false;
        if (data != null) {
          _timeWiseData = data;
        } else {
          _errorTime = "Failed to load time-wise data from backend.";
        }
      });
    }
  }

  Future<void> _loadIOWise() async {
    setState(() {
      _isLoadingIO = true;
      _errorIO = null;
    });

    final data = await _backend.fetchNAFISIOWise();

    if (mounted) {
      setState(() {
        _isLoadingIO = false;
        if (data != null) {
          _ioWiseData = data;
        } else {
          _errorIO = "Failed to load IO-wise data from backend.";
        }
      });
    }
  }

  Widget _buildCaseWiseTab() {
    if (_isLoadingCase) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navyMid));
    }
    if (_errorCase != null) {
      return Center(
          child:
              Text(_errorCase!, style: GoogleFonts.poppins(color: Colors.red)));
    }
    if (_caseWiseList == null || _caseWiseList!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fingerprint_rounded,
              size: 48,
              color: AppColors.navyMid.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              "No NAFIS cases found",
              style: GoogleFonts.poppins(color: AppColors.lightSubText),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCaseWise,
      color: AppColors.navyMid,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        physics: const AlwaysScrollableScrollPhysics(),
        child: NAFISCasesDataTable(
          realDataRows: _caseWiseList,
          rawRecords: _caseRecords,
        ),
      ),
    );
  }

  Widget _buildTimeWiseTab() {
    if (_isLoadingTime) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navyMid));
    }
    if (_errorTime != null) {
      return Center(
          child:
              Text(_errorTime!, style: GoogleFonts.poppins(color: Colors.red)));
    }
    if (_timeWiseData == null || _timeWiseData!.isEmpty) {
      return const Center(child: Text("No time-wise data found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _timeWiseData!.length,
      itemBuilder: (context, index) {
        final item = _timeWiseData![index];
        final period = item['period'] ?? '';
        final count = item['count'] ?? 0;

        return Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.navyMid.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.access_time_rounded,
                color: AppColors.navyMid,
                size: 22,
              ),
            ),
            title: Text(
              period,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.navyDark,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color:
                    count > 0 ? const Color(0xFFFFEBEE) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: count > 0
                      ? const Color(0xFFEF5350)
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: count > 0
                      ? const Color(0xFFC62828)
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIOWiseTab() {
    if (_isLoadingIO) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navyMid));
    }
    if (_errorIO != null) {
      return Center(
          child:
              Text(_errorIO!, style: GoogleFonts.poppins(color: Colors.red)));
    }
    if (_ioWiseData == null || _ioWiseData!.isEmpty) {
      return const Center(child: Text("No IO data found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ioWiseData!.length,
      itemBuilder: (context, index) {
        final item = _ioWiseData![index];
        final ioName = item['io_name'] ?? 'Unassigned';
        final station = item['station_name'] ?? '';
        final count = item['pending_count'] ?? 0;

        return Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.navyMid.withValues(alpha: 0.1),
              child: const Icon(Icons.person_rounded, color: AppColors.navyMid),
            ),
            title: Text(
              ioName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.navyDark,
              ),
            ),
            subtitle: Text(
              station,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.lightSubText,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    count > 0 ? const Color(0xFFFFEBEE) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: count > 0
                      ? const Color(0xFFEF5350)
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                '$count Pending',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: count > 0
                      ? const Color(0xFFC62828)
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF673AB7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fingerprint_rounded,
                color: Color(0xFF673AB7),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NAFIS',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
                Text(
                  'National Automated Fingerprint Identification',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.lightSubText,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined,
                color: Color(0xFF107C41)),
            tooltip: 'Export to Excel',
            onPressed: () {
              if (_caseWiseList != null && _caseWiseList!.isNotEmpty) {
                ExcelExportHelper.exportNafisToExcel(dataset: _caseWiseList!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('NAFIS cases exported to Excel successfully.'),
                    backgroundColor: Color(0xFF107C41),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No NAFIS cases to export.')),
                );
              }
            },
          ),
          IconButton(
            icon:
                const Icon(Icons.table_chart_rounded, color: AppColors.navyMid),
            tooltip: 'All Cases Summary',
            onPressed: () {
              Navigator.push(
                context,
                AppTheme.fadeSlideRoute(
                  page: NAFISSummaryScreen(stationName: widget.stationName),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.navyMid,
          unselectedLabelColor: AppColors.lightSubText,
          indicatorColor: AppColors.navyMid,
          indicatorWeight: 3,
          labelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: "Case Wise"),
            Tab(text: "Time Wise"),
            Tab(text: "IO Wise"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCaseWiseTab(),
          _buildTimeWiseTab(),
          _buildIOWiseTab(),
        ],
      ),
    );
  }
}
