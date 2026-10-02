import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import 'filtered_disposal_screen.dart';

class DisposalHubScreen extends StatefulWidget {
  final String stationName;

  const DisposalHubScreen({
    super.key,
    required this.stationName,
  });

  @override
  State<DisposalHubScreen> createState() => _DisposalHubScreenState();
}

class _DisposalHubScreenState extends State<DisposalHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BackendCaseService _backend = BackendCaseService();

  List<Map<String, dynamic>>? _crimeWiseData;
  List<Map<String, dynamic>>? _timeWiseData;
  List<Map<String, dynamic>>? _ioWiseData;

  bool _isLoadingCrime = false;
  bool _isLoadingTime = false;
  bool _isLoadingIO = false;
  String? _errorCrime;
  String? _errorTime;
  String? _errorIO;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadCrimeWise();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index == 0) {
      _loadCrimeWise();
    } else if (_tabController.index == 1) {
      _loadTimeWise();
    } else if (_tabController.index == 2) {
      _loadIOWise();
    }
  }

  Future<void> _loadCrimeWise() async {
    setState(() {
      _isLoadingCrime = true;
      _errorCrime = null;
      _crimeWiseData = null; // Clear cached data
    });

    final data = await _backend.fetchDisposalCrimeTypeWise();

    if (mounted) {
      setState(() {
        _isLoadingCrime = false;
        if (data != null) {
          _crimeWiseData = data;
        } else {
          _errorCrime = "Failed to load crime-wise data from backend.";
        }
      });
    }
  }

  Future<void> _loadTimeWise() async {
    setState(() {
      _isLoadingTime = true;
      _errorTime = null;
      _timeWiseData = null; // Clear cached data
    });

    final data = await _backend.fetchDisposalTimeWise();

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
      _ioWiseData = null; // Clear cached data
    });

    final data = await _backend.fetchDisposalIOWise();

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
      return const Center(child: Text("No data found"));
    }

    return RefreshIndicator(
      onRefresh: _loadTimeWise,
      color: AppColors.navyMid,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _timeWiseData!.length,
        itemBuilder: (context, index) {
          final item = _timeWiseData![index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  AppTheme.fadeSlideRoute(
                    page: FilteredDisposalScreen(
                      title: 'Time Wise - ${item['period'] ?? ''}',
                      startDate: item['start_date']?.toString(),
                      endDate: item['end_date']?.toString(),
                    ),
                  ),
                );
              },
              title: Text(
                item['period'] ?? '',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.navyMid.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${item['count'] ?? 0} Cases',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyMid,
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
      return const Center(child: Text("No data found"));
    }

    return RefreshIndicator(
      onRefresh: _loadIOWise,
      color: AppColors.navyMid,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ioWiseData!.length,
        itemBuilder: (context, index) {
          final item = _ioWiseData![index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  AppTheme.fadeSlideRoute(
                    page: FilteredDisposalScreen(
                      title: 'IO Wise - ${item['io_name'] ?? 'Unknown'}',
                      ioUid: item['io_uid']?.toString(),
                    ),
                  ),
                );
              },
              title: Text(
                item['io_name'] ?? 'Unknown',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${item['io_rank'] ?? ''} - ${item['station_name'] ?? ''}',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.navyMid.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${item['disposal_count'] ?? 0} Cases',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyMid,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCaseWiseTab() {
    if (_isLoadingCrime) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navyMid));
    }
    if (_errorCrime != null) {
      return Center(
          child: Text(_errorCrime!,
              style: GoogleFonts.poppins(color: Colors.red)));
    }
    if (_crimeWiseData == null || _crimeWiseData!.isEmpty) {
      return const Center(child: Text("No data found"));
    }

    return RefreshIndicator(
      onRefresh: _loadCrimeWise,
      color: AppColors.navyMid,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _crimeWiseData!.length,
        itemBuilder: (context, index) {
          final item = _crimeWiseData![index];
          final typeKey = item['crime_type'] as String;
          final typeName = item['crime_type_name'] as String;
          final count = item['count'] as int;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  AppTheme.fadeSlideRoute(
                    page: FilteredDisposalScreen(
                      title: 'Case Wise - $typeName',
                      crimeType: typeKey,
                    ),
                  ),
                );
              },
              title: Text(
                typeName,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.navyMid.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count Cases',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyMid,
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
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyDark),
        title: Text(
          'Disposal',
          style: GoogleFonts.poppins(
            color: AppColors.navyDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
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
      body: TabBarView(
        controller: _tabController,
        // Using NeverScrollableScrollPhysics to prevent swipe, forcing tab taps
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Tab 1: Case Wise
          _buildCaseWiseTab(),

          // Tab 2: Time Wise
          _buildTimeWiseTab(),

          // Tab 3: IO Wise
          _buildIOWiseTab(),
        ],
      ),
    );
  }
}
