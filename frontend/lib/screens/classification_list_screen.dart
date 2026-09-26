// lib/screens/classification_list_screen.dart
// Priority 4: Generic screen for each classification type from the drawer / dashboard,
// dynamically wired to GET /api/categories/{id}/cases/.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../modules/core/models/base_record.dart';
import '../services/case_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dynamic_form/dynamic_form_screen.dart';
import 'common_form_screen.dart';
import 'module_record_detail_screen.dart';

class ClassificationListScreen extends StatefulWidget {
  final String classificationType;

  const ClassificationListScreen({
    super.key,
    required this.classificationType,
  });

  @override
  State<ClassificationListScreen> createState() =>
      _ClassificationListScreenState();
}

class _ClassificationListScreenState extends State<ClassificationListScreen> {
  final CaseService _caseService = CaseService();
  String _filter = 'All';
  static const _filters = ['All', 'Pending', 'Active', 'Disposal'];

  List<ModuleRecord> _cases = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await _caseService.fetchCategoryCases(
        widget.classificationType,
      );
      if (!mounted) return;
      setState(() {
        _cases = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load cases: $e';
      });
    }
  }

  List<ModuleRecord> get _filteredCases {
    if (_filter == 'All') return _cases;
    final f = _filter.toLowerCase();
    return _cases.where((c) {
      final s = c.status.toLowerCase();
      if (f == 'disposal') {
        return s == 'disposal' || s == 'disposed' || s == 'resolved';
      }
      return s == f;
    }).toList();
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'disposal' || s == 'disposed' || s == 'resolved') {
      return AppColors.successGreen;
    }
    if (s == 'pending' || s == 'active') {
      return AppColors.infoBlue;
    }
    return AppColors.warningOrange;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCases;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.classificationType,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            Text(
              _isLoading
                  ? 'Loading records...'
                  : '${filtered.length} records found',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.lightSubText,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.navyMid),
            onPressed: _loadCases,
          ),
        ],
      ),
      body: Column(
        children: [
          // Classification type banner
          Container(
            margin: const EdgeInsets.all(AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.navyMid,
                  AppColors.navyMid.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyMid.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.folder_special_rounded,
                    color: AppColors.goldPrimary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.classificationType,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Classification Records',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${_cases.length}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status filter chips
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: _filters.map((f) {
                final isActive = _filter == f;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.navyMid : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isActive
                            ? AppColors.navyMid
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Text(
                      f,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isActive ? Colors.white : AppColors.lightText,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Case list / Loading / Empty states
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.lightSubText,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ElevatedButton(
                              onPressed: _loadCases,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.folder_open_rounded,
                                  size: 64,
                                  color: AppColors.lightSubText,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'No records found',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.lightSubText,
                                  ),
                                ),
                                Text(
                                  _cases.isEmpty
                                      ? 'No cases registered for this classification yet'
                                      : 'Try a different filter',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.lightSubText,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCases,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final c = filtered[i];
                                final statusColor = _statusColor(c.status);
                                final title = c.title.trim().isNotEmpty
                                    ? c.title
                                    : '${widget.classificationType} Case';
                                final idText = c.caseNumber.trim().isNotEmpty
                                    ? c.caseNumber
                                    : c.id;
                                final dateText = DateFormat('dd MMM yyyy')
                                    .format(c.incidentDate);
                                final officer =
                                    c.assignedOfficer.trim().isNotEmpty
                                        ? c.assignedOfficer
                                        : 'IO Assigned';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg),
                                    border: Border.all(
                                      color: AppColors.lightBorder,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.sm,
                                      ),
                                      leading: Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: AppColors.navyMid
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.md),
                                        ),
                                        child: const Icon(
                                          Icons.folder_rounded,
                                          color: AppColors.navyMid,
                                          size: 22,
                                        ),
                                      ),
                                      title: Text(
                                        title,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.lightText,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '$idText · $dateText · $officer',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: AppColors.lightSubText,
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.sm),
                                        ),
                                        child: Text(
                                          c.status.toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          AppTheme.fadeSlideRoute(
                                            page: ModuleRecordDetailScreen(
                                              record: c,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),

      // FAB to add new record
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            AppTheme.fadeSlideRoute(
              page: DynamicFormScreen(
                moduleLabel: widget.classificationType,
                moduleKey: 'form_1_5',
                subCategory: widget.classificationType,
              ),
            ),
          );
          _loadCases();
        },
        backgroundColor: AppColors.navyMid,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Record',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
