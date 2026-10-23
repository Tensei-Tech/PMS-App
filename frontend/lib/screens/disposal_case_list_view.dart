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
      color: AppColors.navyDark,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
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
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataRow(Map<String, dynamic> record, int index) {
    final bgColor = index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFD);

    final extra = record['extra_fields'] ?? {};
    final act = extra['act'] ?? record['act'] ?? '';
    final section = extra['section'] ?? record['section'] ?? '';
    final sectionAct =
        (section.toString().isNotEmpty || act.toString().isNotEmpty)
            ? '$section $act'.trim()
            : '—';

    final ccStNo = record['cc_st_no']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildDataCell((record['sr_no'] ?? '${index + 1}').toString(),
              flex: 1),
          _buildDataCell((record['case_number'] ?? '—').toString(), flex: 2),
          _buildDataCell(sectionAct, flex: 3),
          _buildDataCell(ccStNo.isNotEmpty ? ccStNo : '—', flex: 2),
          _buildDataCell((record['assigned_officer'] ?? '—').toString(),
              flex: 2),
          _buildDataCell((record['station_name'] ?? '—').toString(), flex: 2),
          _buildDataCell((record['crime_type_name'] ?? '—').toString(), flex: 2),
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
          color: AppColors.navyDark,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _records.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navyMid),
      );
    }
    if (_error != null && _records.isEmpty) {
      return Center(
        child: Text(
          _error!,
          style: GoogleFonts.poppins(color: AppColors.dangerRed),
        ),
      );
    }
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.navyMid.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 48,
                color: AppColors.navyMid,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Disposal Cases Found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'There are no disposal records matching this filter.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.lightSubText,
              ),
            ),
          ],
        ),
      );
    }

    // Group records cleanly by crime type into a Map
    final Map<String, List<Map<String, dynamic>>> groupMap = {};
    for (var record in _records) {
      final crime = record['crime_type_name']?.toString() ?? 'Other';
      groupMap.putIfAbsent(crime, () => []).add(record);
    }
    final groups = groupMap.entries.toList();

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      color: AppColors.navyMid,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: groups.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == groups.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.navyMid),
              ),
            );
          }

          final groupName = groups[index].key;
          final items = groups[index].value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.crimeType == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              const Color(0xFF2E7D32).withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.category_outlined,
                            size: 13,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            groupName,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyDark,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: AppColors.lightSubText,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${items.length} ${items.length == 1 ? 'Case' : 'Cases'}',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: constraints.maxWidth > 1000
                            ? constraints.maxWidth
                            : 1000,
                        child: Column(
                          children: [
                            _buildHeaderRow(),
                            ...items
                                .asMap()
                                .entries
                                .map((e) => _buildDataRow(e.value, e.key)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
