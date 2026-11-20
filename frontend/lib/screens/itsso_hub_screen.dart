import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/dynamic_map_pdf.dart';
import '../utils/excel_export_helper.dart';
import '../utils/pdf_unicode_fonts.dart';
import '../widgets/app_error_popup.dart';
import '../widgets/app_success_popup.dart';
import '../widgets/custom_pdf_preview_dialog.dart';
import 'filtered_pending_screen.dart';

class ItssoHubScreen extends StatefulWidget {
  final String stationName;
  const ItssoHubScreen({super.key, required this.stationName});

  @override
  State<ItssoHubScreen> createState() => _ItssoHubScreenState();
}

class _ItssoHubScreenState extends State<ItssoHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> caseWiseData = [];
  List<dynamic> timeWiseData = [];
  List<dynamic> ioWiseData = [];

  final Set<String> _remindedCaseIds = {};
  final Set<String> _sendingCaseIds = {};

  bool isLoading = true;
  String? error;

  String get baseUrl => ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    fetchAllData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  Future<void> fetchAllData() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final apiService = ApiService();

      final caseRes = await apiService.get('$baseUrl/itsso/cases/');
      if (caseRes.isSuccess && caseRes.data != null) {
        var decoded = caseRes.data;
        caseWiseData = decoded is Map ? (decoded['results'] ?? []) : decoded;
      }

      final timeRes = await apiService.get('$baseUrl/itsso/time-wise/');
      if (timeRes.isSuccess && timeRes.data != null) {
        timeWiseData = timeRes.data is List ? timeRes.data : [];
      }

      final ioRes = await apiService.get('$baseUrl/itsso/io-wise/');
      if (ioRes.isSuccess && ioRes.data != null) {
        ioWiseData = ioRes.data is List ? ioRes.data : [];
      }
    } catch (e) {
      debugPrint("Error fetching ITSSO data: $e");
      error = "Failed to load ITSSO data.";
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return RefreshIndicator(
      onRefresh: fetchAllData,
      color: AppColors.navyMid,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.navyMid.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 44,
                    color: AppColors.navyMid.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppColors.lightSubText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _getSectionAct(Map<String, dynamic> item) {
    final direct = item['section_act']?.toString().trim();
    if (direct != null && direct.isNotEmpty && direct != '—' && direct != '-') {
      return direct;
    }
    final ef = item['extra_fields'];
    if (ef is Map) {
      final act = ef['section_act'] ??
          ef['section'] ??
          ef['act_section'] ??
          ef['acts_sections'] ??
          ef['act'] ??
          ef['sections'];
      if (act != null && act.toString().trim().isNotEmpty) {
        return ExcelExportHelper.formatSectionAct(act);
      }
    }
    final title = (item['title'] ?? item['description'] ?? item['head'] ?? item['sub_category'] ?? '').toString().trim();
    if (title.isNotEmpty && title.toLowerCase() != 'pocso') return title;
    return '—';
  }

  static String _getChargeSheetInfo(Map<String, dynamic> item) {
    final cs = item['charge_sheet_date']?.toString().trim();
    if (cs != null && cs.isNotEmpty && cs != 'Pending' && cs != '—' && cs != '-') {
      return cs;
    }
    final ef = item['extra_fields'];
    if (ef is Map) {
      final csNo = ef['charge_sheet_number'] ??
          ef['charge_sheet_no'] ??
          ef['cc_st_number'] ??
          ef['ccStNumber'];
      if (csNo != null && csNo.toString().trim().isNotEmpty) {
        return csNo.toString();
      }
      final csDate = ef['charge_sheet_date'] ?? ef['chargeSheetDate'] ?? ef['cs_date'];
      if (csDate != null && csDate.toString().trim().isNotEmpty) {
        return csDate.toString().split('T')[0];
      }
    }
    return 'Pending';
  }

  void _exportExcel() {
    if (caseWiseData.isEmpty) return;
    final headers = [
      'Sr. No.',
      'CR No.',
      'Section/Act',
      'Charge Sheet / CC No.',
      'IO Name',
      'Status',
      'Action'
    ];
    final rows = caseWiseData.asMap().entries.map((entry) {
      final index = entry.key;
      final c = entry.value is Map<String, dynamic>
          ? entry.value as Map<String, dynamic>
          : Map<String, dynamic>.from(entry.value as Map);
      final isGreen = c['itsso_status_color']?.toString().toLowerCase() == 'green' ||
          c['itsso_status']?.toString().toLowerCase() == 'chargesheeted';
      return [
        c['sr_no']?.toString() ?? '${index + 1}',
        c['case_number']?.toString() ?? '—',
        _getSectionAct(c),
        _getChargeSheetInfo(c),
        c['assigned_officer']?.toString() ?? 'Unassigned',
        c['itsso_status']?.toString() ?? (isGreen ? 'Chargesheeted' : 'Pending'),
        isGreen ? '—' : 'Remind to IO',
      ];
    }).toList();

    ExcelExportHelper.exportTableToCsv(
      headers: headers,
      rows: rows,
      filename: 'ITSSO_Cases_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
  }

  Future<void> _exportPdf() async {
    if (caseWiseData.isEmpty) return;
    final rows = caseWiseData.asMap().entries.map((entry) {
      final index = entry.key;
      final c = entry.value is Map<String, dynamic>
          ? entry.value as Map<String, dynamic>
          : Map<String, dynamic>.from(entry.value as Map);
      final isGreen = c['itsso_status_color']?.toString().toLowerCase() == 'green' ||
          c['itsso_status']?.toString().toLowerCase() == 'chargesheeted';
      return {
        'Sr. No.': c['sr_no']?.toString() ?? '${index + 1}',
        'CR No.': c['case_number']?.toString() ?? '—',
        'Section/Act': _getSectionAct(c),
        'Charge Sheet / CC No.': _getChargeSheetInfo(c),
        'IO Name': c['assigned_officer']?.toString() ?? 'Unassigned',
        'Status': c['itsso_status']?.toString() ?? (isGreen ? 'Chargesheeted' : 'Pending'),
        'Action': isGreen ? '—' : 'Remind to IO',
      };
    }).toList();

    final theme = await PdfUnicodeFonts.openSansTheme();
    final doc = DynamicMapPdf.buildLandscapeDataTableDocument(
      theme: theme,
      title: 'ITSSO (POCSO) — Case Wise Records',
      rows: rows,
      prependSerial: false,
      columnOrder: const [
        'Sr. No.',
        'CR No.',
        'Section/Act',
        'Charge Sheet / CC No.',
        'IO Name',
        'Status',
        'Action',
      ],
    );

    await CustomPdfPreviewDialog.show(
      context: context,
      title: 'ITSSO — Cases',
      fileName: 'ITSSO_Cases_${DateTime.now().millisecondsSinceEpoch}.pdf',
      buildPdf: (_) async => doc.save(),
    );
  }

  Future<void> _sendReminder(
    Map<String, dynamic> c,
    String crNo,
    String ioName,
  ) async {
    final caseId = (c['id'] ?? '').toString();
    if (caseId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_rounded,
                  color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Remind to IO',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.navyDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send a supervisory reminder to the Investigating Officer to enter the Charge Sheet Number for this POCSO case?',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.navyDark,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CR No: $crNo',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Assigned IO: $ioName',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.lightSubText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.lightSubText),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Send Reminder',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _sendingCaseIds.add(caseId);
    });

    try {
      await ApiService().post(
        '$baseUrl/itsso/cases/$caseId/action/',
        body: {},
      );
      if (mounted) {
        setState(() {
          _sendingCaseIds.remove(caseId);
          _remindedCaseIds.add(caseId);
        });
        AppSuccessPopup.show(
          context,
          title: 'Reminder Sent',
          message: "Reminder sent to IO for case $crNo",
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sendingCaseIds.remove(caseId);
        });
        AppErrorPopup.show(
          context,
          title: 'Error',
          message: 'Failed to send reminder: $e',
        );
      }
    }
  }

  Widget _buildCaseWiseTab() {
    if (caseWiseData.isEmpty) {
      return _buildEmptyState(
        title: "No POCSO Cases Found",
        subtitle: "Cases registered under POCSO will appear here",
        icon: Icons.category_outlined,
      );
    }

    final Set<String> remindedSet = _remindedCaseIds;
    final Set<String> sendingSet = _sendingCaseIds;

    return RefreshIndicator(
      onRefresh: fetchAllData,
      color: AppColors.navyMid,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double cellFontSize = 11.5;
          const double headerFontSize = 11.5;

          final availableWidth = constraints.maxWidth - 32.0;
          final isMobile = availableWidth < 750;
          final double tableWidth;
          final Map<int, TableColumnWidth> columnWidths;

          if (isMobile) {
            const srWidth = 48.0;
            final colUnitW = (availableWidth - srWidth) / 4.5;
            final colActionW = math.max(colUnitW * 1.2, 115.0);
            tableWidth = srWidth + (colUnitW * 5) + colActionW;

            columnWidths = <int, TableColumnWidth>{
              0: const FixedColumnWidth(srWidth),
              1: FixedColumnWidth(colUnitW),
              2: FixedColumnWidth(colUnitW * 1.1),
              3: FixedColumnWidth(colUnitW * 1.1),
              4: FixedColumnWidth(colUnitW * 1.2),
              5: FixedColumnWidth(colUnitW),
              6: FixedColumnWidth(colActionW),
            };
          } else {
            tableWidth = math.max(availableWidth, 900.0);
            columnWidths = const <int, TableColumnWidth>{
              0: FixedColumnWidth(65),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.3),
              3: FlexColumnWidth(1.4),
              4: FlexColumnWidth(1.6),
              5: FlexColumnWidth(1.2),
              6: FlexColumnWidth(1.3),
            };
          }

          Widget headerCell(String s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                color: AppColors.navyDark,
                alignment: Alignment.center,
                child: Text(
                  s,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: GoogleFonts.poppins(
                    fontSize: headerFontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
              );

          Widget dataCell(Widget child, {Alignment align = Alignment.center}) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                alignment: align,
                child: child,
              );

          Widget textCell(String s, {Alignment align = Alignment.center}) =>
              dataCell(
                Text(
                  s.isEmpty ? '—' : s,
                  textAlign: align == Alignment.center
                      ? TextAlign.center
                      : TextAlign.left,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.poppins(
                    fontSize: cellFontSize,
                    fontWeight: FontWeight.w500,
                    color: AppColors.lightText,
                    height: 1.15,
                  ),
                ),
                align: align,
              );

          final headers = <Widget>[
            headerCell('Sr. No.'),
            headerCell('CR No.'),
            headerCell('Section/Act'),
            headerCell('Charge Sheet / CC No.'),
            headerCell('IO Name'),
            headerCell('Status'),
            headerCell('Action'),
          ];

          TableRow rowFor(int idx, Map<String, dynamic> c) {
            final bg = idx.isEven ? Colors.white : const Color(0xFFF8FAFD);
            final caseId = (c['id'] ?? '').toString();
            final srNo = c['sr_no']?.toString() ?? '${idx + 1}';
            final crNo = (c['case_number'] ?? '—').toString();
            final secAct = _getSectionAct(c);
            final csInfo = _getChargeSheetInfo(c);
            final io = (c['assigned_officer'] ?? 'Unassigned').toString();
            final isGreen = c['itsso_status_color']?.toString().toLowerCase() == 'green' ||
                c['itsso_status']?.toString().toLowerCase() == 'chargesheeted';
            final statusText = c['itsso_status']?.toString() ?? (isGreen ? 'Chargesheeted' : 'Pending');

            final isReminded = remindedSet.contains(caseId);
            final isSending = sendingSet.contains(caseId);
            final actionRequired = (c['action_required'] == true) && !isGreen;

            Widget actionWidget;
            if (isGreen) {
              actionWidget = textCell('—');
            } else if (isReminded) {
              actionWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEF7EC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF31C48D)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 13, color: Color(0xFF0E9F6E)),
                    const SizedBox(width: 4),
                    Text(
                      'Reminded',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0E9F6E),
                      ),
                    ),
                  ],
                ),
              );
            } else if (actionRequired) {
              actionWidget = ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(85, 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: isSending
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.notifications_active_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                label: Text(
                  isSending ? 'Sending...' : 'Remind to IO',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                onPressed: isSending ? null : () => _sendReminder(c, crNo, io),
              );
            } else {
              actionWidget = textCell('—');
            }

            final statusWidget = Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isGreen
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isGreen
                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                      : const Color(0xFFEF4444).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                statusText,
                style: GoogleFonts.poppins(
                  color: isGreen
                      ? const Color(0xFF047857)
                      : const Color(0xFFB91C1C),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            );

            return TableRow(
              decoration: BoxDecoration(color: bg),
              children: [
                textCell(srNo),
                textCell(crNo),
                textCell(secAct),
                textCell(csInfo),
                textCell(io),
                dataCell(statusWidget),
                dataCell(actionWidget),
              ],
            );
          }

          final headerTable = Container(
            decoration: const BoxDecoration(color: AppColors.navyDark),
            child: Table(
              columnWidths: columnWidths,
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: const TableBorder(
                verticalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: AppColors.navyDark),
                  children: headers,
                ),
              ],
            ),
          );

          final bodyTable = Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: Table(
              columnWidths: columnWidths,
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: const TableBorder(
                horizontalInside: BorderSide(color: Color(0xFFEDF2F7), width: 1),
                verticalInside: BorderSide(color: Color(0xFFEDF2F7), width: 1),
              ),
              children: [
                for (var i = 0; i < caseWiseData.length; i++)
                  rowFor(
                    i,
                    caseWiseData[i] is Map<String, dynamic>
                        ? caseWiseData[i] as Map<String, dynamic>
                        : Map<String, dynamic>.from(caseWiseData[i] as Map),
                  ),
              ],
            ),
          );

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.only(bottom: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          headerTable,
                          bodyTable,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeWiseTab() {
    if (timeWiseData.isEmpty) {
      return _buildEmptyState(
        title: "No Time Intervals Found",
        subtitle: "Duration-wise breakdown will appear here",
        icon: Icons.schedule_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: fetchAllData,
      color: AppColors.navyMid,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: timeWiseData.length,
        itemBuilder: (context, index) {
          final item = timeWiseData[index];
          final p = item['period']?.toString() ?? '';
          final count = (item['count'] as num?)?.toInt() ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  final now = DateTime.now();
                  DateTime? start, end;

                  if (p == 'Under 1 month') {
                    start = now.subtract(const Duration(days: 30));
                  } else if (p == '1 to 3 months') {
                    start = now.subtract(const Duration(days: 90));
                    end = now.subtract(const Duration(days: 30));
                  } else if (p == '3 to 6 months') {
                    start = now.subtract(const Duration(days: 180));
                    end = now.subtract(const Duration(days: 90));
                  } else if (p == '6 to 12 months') {
                    start = now.subtract(const Duration(days: 365));
                    end = now.subtract(const Duration(days: 180));
                  } else if (p == 'More than 1 year') {
                    end = now.subtract(const Duration(days: 365));
                  } else if (p == 'Under 3 months (Total)') {
                    start = now.subtract(const Duration(days: 90));
                  }

                  Navigator.push(
                    context,
                    AppTheme.fadeSlideRoute(
                      page: FilteredPendingScreen(
                        title: 'ITSSO (POCSO) - $p',
                        category: 'pocso',
                        startDate: start?.toIso8601String().split('T')[0],
                        endDate: end?.toIso8601String().split('T')[0],
                        isVictim: true,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.navyMid,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          p,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.navyMid.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.navyMid.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          '$count ${count == 1 ? 'Case' : 'Cases'}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.navyMid,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.lightSubText,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIOWiseTab() {
    if (ioWiseData.isEmpty) {
      return _buildEmptyState(
        title: "No Officers Found",
        subtitle:
            "POCSO cases mapped to investigating officers will appear here",
        icon: Icons.badge_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: fetchAllData,
      color: AppColors.navyMid,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: ioWiseData.length,
        itemBuilder: (context, index) {
          final item = ioWiseData[index];
          final ioName = item['io_name']?.toString() ?? 'Unassigned';
          final ioRank = item['io_rank']?.toString() ?? '';
          final stationName = item['station_name']?.toString() ?? '';
          final count =
              (item['itsso_count'] ?? item['count'] as num?)?.toInt() ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    AppTheme.fadeSlideRoute(
                      page: FilteredPendingScreen(
                        title: 'ITSSO (POCSO) - $ioName',
                        category: 'pocso',
                        ioUid: item['io_uid']?.toString() ?? ioName,
                        isVictim: true,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.navyDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ioName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: AppColors.navyDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ioRank.isNotEmpty || stationName.isNotEmpty
                                  ? '$ioRank • $stationName'
                                  : 'Investigating Officer',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.lightSubText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.navyMid.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.navyMid.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          '$count ${count == 1 ? 'Case' : 'Cases'}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.navyMid,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.lightSubText,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyDark),
        title: Text(
          'ITSSO',
          style: GoogleFonts.poppins(
            color: AppColors.navyDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          if (_tabController.index == 0 && caseWiseData.isNotEmpty) ...[
            GestureDetector(
              onTap: _exportExcel,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF107C41),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF107C41).withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.table_chart_rounded,
                        color: Colors.white, size: 15),
                    const SizedBox(width: 5),
                    Text(
                      'Excel',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _exportPdf,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.navyMid,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navyMid.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.white, size: 15),
                    const SizedBox(width: 5),
                    Text(
                      'PDF',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              controller: _tabController,
              labelColor: AppColors.navyMid,
              unselectedLabelColor: AppColors.lightSubText,
              indicatorColor: AppColors.navyMid,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Case Wise'),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule_rounded, size: 16),
                      SizedBox(width: 8),
                      Text('Time Wise'),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('IO Wise'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.navyMid),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildCaseWiseTab(),
                    _buildTimeWiseTab(),
                    _buildIOWiseTab(),
                  ],
                ),
              ),
      ),
    );
  }
}
