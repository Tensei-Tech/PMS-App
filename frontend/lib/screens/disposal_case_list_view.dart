import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';

class DisposalCaseListView extends StatefulWidget {
  final String? ioUid;
  final String? startDate;
  final String? endDate;
  final String? crimeType;

  const DisposalCaseListView({
    super.key,
    this.ioUid,
    this.startDate,
    this.endDate,
    this.crimeType,
  });

  @override
  State<DisposalCaseListView> createState() => _DisposalCaseListViewState();
}

class _DisposalCaseListViewState extends State<DisposalCaseListView> {
  final BackendCaseService _backend = BackendCaseService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _records = [];
      _hasMore = true;
    });

    try {
      final dataMap = await _backend.fetchDisposalCases(
        ioUid: widget.ioUid,
        startDate: widget.startDate,
        endDate: widget.endDate,
        crimeType: widget.crimeType,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      if (dataMap != null && dataMap.containsKey('results')) {
        final results = List<Map<String, dynamic>>.from(dataMap['results']);
        final count = dataMap['count'] ?? results.length;
        
        setState(() {
          _records = results;
          _totalCount = count as int;
          _hasMore = dataMap['next'] != null || _records.length < _totalCount;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load disposal cases.";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;

    try {
      final dataMap = await _backend.fetchDisposalCases(
        ioUid: widget.ioUid,
        startDate: widget.startDate,
        endDate: widget.endDate,
        crimeType: widget.crimeType,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      if (dataMap != null && dataMap.containsKey('results')) {
        final results = List<Map<String, dynamic>>.from(dataMap['results']);
        
        setState(() {
          _records.addAll(results);
          _hasMore = dataMap['next'] != null || _records.length < _totalCount;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _hasMore = false; // Stop trying if error on pagination
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasMore = false;
        _isLoadingMore = false;
      });
    }
  }

  Widget _buildHeaderRow() {
    return Container(
      color: AppColors.navyMid,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          _buildHeaderCell("SR. No", flex: 1),
          _buildHeaderCell("CR. No", flex: 2),
          _buildHeaderCell("Section and Act", flex: 3),
          _buildHeaderCell("CC & ST. No", flex: 2),
          _buildHeaderCell("IO Name", flex: 2),
          _buildHeaderCell("Police Station Name", flex: 2),
          _buildHeaderCell("Crime Sub-tab Name", flex: 2),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataRow(Map<String, dynamic> record, int index) {
    final bgColor = index % 2 == 0 ? Colors.white : AppColors.lightBg;
    
    // Extract Section and Act from extra_fields or directly
    final extra = record['extra_fields'] ?? {};
    final act = extra['act'] ?? record['act'] ?? '';
    final section = extra['section'] ?? record['section'] ?? '';
    final sectionAct = (section.toString().isNotEmpty || act.toString().isNotEmpty)
        ? '$section $act'.trim()
        : '—';
        
    final ccStNo = record['cc_st_no']?.toString() ?? '';

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          _buildDataCell((record['sr_no'] ?? '').toString(), flex: 1),
          _buildDataCell((record['case_number'] ?? '').toString(), flex: 2),
          _buildDataCell(sectionAct, flex: 3),
          _buildDataCell(ccStNo.isNotEmpty ? ccStNo : '—', flex: 2),
          _buildDataCell((record['assigned_officer'] ?? '').toString(), flex: 2),
          _buildDataCell((record['station_name'] ?? '').toString(), flex: 2),
          _buildDataCell((record['crime_type_name'] ?? '').toString(), flex: 2),
        ],
      ),
    );
  }

  Widget _buildDataCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.poppins(
            color: AppColors.navyDark, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _records.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navyMid));
    }
    if (_error != null && _records.isEmpty) {
      return Center(
          child: Text(_error!, style: GoogleFonts.poppins(color: Colors.red)));
    }
    if (_records.isEmpty) {
      return const Center(child: Text("No disposal cases found"));
    }

    // Group records by crime type
    final List<Map<String, dynamic>> groups = [];
    String? currentGroup;
    List<Map<String, dynamic>> currentItems = [];
    
    for (var record in _records) {
      final crime = record['crime_type_name']?.toString() ?? 'Other';
      if (crime != currentGroup) {
        if (currentGroup != null) {
          groups.add({'group': currentGroup, 'items': currentItems});
        }
        currentGroup = crime;
        currentItems = [record];
      } else {
        currentItems.add(record);
      }
    }
    if (currentGroup != null) {
      groups.add({'group': currentGroup, 'items': currentItems});
    }

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      color: AppColors.navyMid,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: groups.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == groups.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.navyMid)),
            );
          }

          final groupName = groups[index]['group'] as String;
          final items = groups[index]['items'] as List<Map<String, dynamic>>;

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    groupName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: constraints.maxWidth > 1000 ? constraints.maxWidth : 1000,
                        child: Column(
                          children: [
                            _buildHeaderRow(),
                            ...items.asMap().entries.map((e) => _buildDataRow(e.value, e.key)),
                          ],
                        ),
                      ),
                    );
                  }
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
