import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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

  bool isLoading = true;

  final String baseUrl = const String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8000/api');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    setState(() => isLoading = true);
    try {
      final apiService = ApiService();

      final caseRes = await apiService.get('$baseUrl/itsso/cases/');
      if (caseRes.isSuccess && caseRes.data != null) {
        var decoded = caseRes.data;
        caseWiseData = decoded is Map ? decoded['results'] : decoded;
      }

      final timeRes = await apiService.get('$baseUrl/itsso/time-wise/');
      if (timeRes.isSuccess && timeRes.data != null) {
        timeWiseData = timeRes.data;
      }

      final ioRes = await apiService.get('$baseUrl/itsso/io-wise/');
      if (ioRes.isSuccess && ioRes.data != null) {
        ioWiseData = ioRes.data;
      }
    } catch (e) {
      debugPrint("Error fetching ITSSO data: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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
          'ITSSO (POCSO)',
          style: GoogleFonts.poppins(
              color: AppColors.navyDark,
              fontWeight: FontWeight.w700,
              fontSize: 16),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.navyMid,
          unselectedLabelColor: AppColors.lightSubText,
          indicatorColor: AppColors.navyMid,
          labelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Case Wise'),
            Tab(text: 'Time Wise'),
            Tab(text: 'IO Wise'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.navyMid))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCaseWiseTab(),
                _buildTimeWiseTab(),
                _buildIOWiseTab(),
              ],
            ),
    );
  }

  Widget _buildCaseWiseTab() {
    if (caseWiseData.isEmpty)
      return const Center(child: Text("No POCSO cases found."));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, color: AppColors.navyDark),
        dataTextStyle: GoogleFonts.poppins(color: Colors.black87),
        columns: const [
          DataColumn(label: Text('Sr. No.')),
          DataColumn(label: Text('CR No.')),
          DataColumn(label: Text('Section/Act')),
          DataColumn(label: Text('Charge Sheet Date')),
          DataColumn(label: Text('IO Name')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Action')),
        ],
        rows: caseWiseData.map((caseItem) {
          bool isGreen = caseItem['itsso_status_color'] == 'Green';
          return DataRow(
            cells: [
              DataCell(Text(caseItem['sr_no']?.toString() ?? '-')),
              DataCell(Text(caseItem['case_number']?.toString() ?? '-')),
              DataCell(Text(caseItem['section_act']?.toString() ?? '-')),
              DataCell(
                  Text(caseItem['charge_sheet_date']?.toString() ?? 'Pending')),
              DataCell(Text(
                  caseItem['assigned_officer']?.toString() ?? 'Unassigned')),
              DataCell(
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isGreen ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    caseItem['itsso_status']?.toString() ?? 'Pending',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ),
              DataCell(
                (caseItem['action_required'] == true)
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          minimumSize: const Size(80, 30),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  "Reminder sent to IO for case ${caseItem['case_number']}")));
                        },
                        child: Text('Remind to IO',
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    : const Text('-'),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeWiseTab() {
    if (timeWiseData.isEmpty)
      return const Center(child: Text("No data available."));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: timeWiseData.length,
      itemBuilder: (context, index) {
        final item = timeWiseData[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(item['period'] ?? '',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navyMid.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${item['count']} Cases',
                style: GoogleFonts.poppins(
                    color: AppColors.navyMid, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIOWiseTab() {
    if (ioWiseData.isEmpty)
      return const Center(child: Text("No IO data available."));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ioWiseData.length,
      itemBuilder: (context, index) {
        final item = ioWiseData[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
                backgroundColor: AppColors.navyMid,
                child: Icon(Icons.person, color: Colors.white)),
            title: Text(item['io_name'] ?? 'Unassigned',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Text(item['station_name'] ?? '',
                style: GoogleFonts.poppins(fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navyMid.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${item['itsso_count']} Cases',
                style: GoogleFonts.poppins(
                    color: AppColors.navyMid, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}
