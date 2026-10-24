// lib/modules/muddemal/screens/muddemal_main_screen.dart
// Production-ready Digital Muddemal / Property Management Module.
// Features: CR selection, dynamic multiple properties, backend valuation,
// FSL alerts (7, 15, 30 days), custody chain, disposals, and backend-driven analytics.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../models/muddemal_models.dart';
import '../providers/muddemal_provider.dart';
import '../widgets/muddemal_property_form_dialog.dart';
import '../widgets/muddemal_property_detail_dialog.dart';

class MuddemalMainScreen extends StatefulWidget {
  final String? initialCrNumber;
  final String? initialCaseId;

  const MuddemalMainScreen({
    super.key,
    this.initialCrNumber,
    this.initialCaseId,
  });

  @override
  State<MuddemalMainScreen> createState() => _MuddemalMainScreenState();
}

class _MuddemalMainScreenState extends State<MuddemalMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryFilter;
  String? _selectedSourceModuleFilter;
  String? _selectedStatusFilter;
  String _statusTab = 'All'; // 'All', 'Pending', 'Disposal'
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final provider = context.read<MuddemalProvider>();

      final station = auth.activeStation.isNotEmpty
          ? auth.activeStation
          : (auth.stationName.isNotEmpty ? auth.stationName : 'All Stations');

      await provider.loadInitialMetadata(stationName: station);

      if (widget.initialCaseId != null && widget.initialCrNumber != null) {
        await provider.selectCase(
          caseId: widget.initialCaseId!,
          crNumber: widget.initialCrNumber!,
          stationName: station,
        );
      }

      await provider.loadFSLAlerts();
      await provider.loadDashboards();
    });

    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAutoSync(MuddemalProvider provider) async {
    setState(() => _isSyncing = true);
    try {
      await provider.syncAllSources();
      await provider.loadFSLAlerts();
      await provider.loadDashboards();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Successfully auto-synced seized properties from Crime, Prohibition, Gambling & other PMS modules.',
            ),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-sync error: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MuddemalProvider>();
    final properties = provider.properties;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navyDark,
            size: 20,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Muddemal',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            Text(
              '${properties.length} records registered',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.lightSubText,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const MuddemalPropertyFormDialog(),
                );
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
              label: Text(
                TranslationHelper.translate(context, 'Add Property'),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: const StadiumBorder(),
                elevation: 3,
                shadowColor: AppColors.navyDark.withValues(alpha: 0.3),
              ),
            ),
          ),
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.navyDark,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.navyDark),
            tooltip: 'Refresh Properties',
            onPressed: _isSyncing ? null : () => _handleAutoSync(provider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── TOP STATUS TABS ROW (Total Cases, Pending, Disposal) ──
          _buildStatusTabs(provider),

          // ── MAIN CONTENT (Records, Alerts, Reports) ───────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPropertiesTab(provider),
                _buildAlertsTab(provider),
                _buildDashboardsTab(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TOP STATUS TABS ROW (Total Cases, Pending, Disposal)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildStatusTabs(MuddemalProvider provider) {
    final totalCount = provider.properties.length;
    final disposalCount = provider.properties.where((p) {
      final s = p.propertyStatus.toLowerCase();
      final d = p.disposalStatus.toLowerCase();
      return s.contains('disposal') ||
          s.contains('returned') ||
          s.contains('released') ||
          d.contains('disposed') ||
          d.contains('returned') ||
          d.contains('released');
    }).length;
    final pendingCount = totalCount - disposalCount;

    final tabs = [
      (
        key: 'All',
        label: 'Total Cases',
        count: totalCount,
        badgeBg: const Color(0xFFE8F1FC),
        badgeFg: const Color(0xFF1976D2),
      ),
      (
        key: 'Pending',
        label: 'Pending',
        count: pendingCount,
        badgeBg: const Color(0xFFFFF3E0),
        badgeFg: const Color(0xFFE65100),
      ),
      (
        key: 'Disposal',
        label: 'Disposal',
        count: disposalCount,
        badgeBg: const Color(0xFFE8F5E9),
        badgeFg: const Color(0xFF2E7D32),
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                children: tabs.map((item) {
                  final isSelected = _statusTab == item.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _statusTab = item.key;
                          if (_tabController.index != 0) {
                            _tabController.animateTo(0);
                          }
                        });
                      },
                      hoverColor: Colors.transparent,
                      splashColor: AppColors.navyMid.withValues(alpha: 0.08),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF1976D2)
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              TranslationHelper.translate(context, item.label),
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF1976D2)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.badgeBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${item.count}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: item.badgeFg,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSubTabPill(
                  index: 0,
                  icon: Icons.list_alt_rounded,
                  label: 'Records',
                ),
                const SizedBox(width: 6),
                _buildSubTabPill(
                  index: 1,
                  icon: Icons.notifications_active_rounded,
                  label: 'FSL Alerts',
                  badgeCount: provider.fslAlerts['summary']?['total_alerts'],
                ),
                const SizedBox(width: 6),
                _buildSubTabPill(
                  index: 2,
                  icon: Icons.analytics_rounded,
                  label: 'Reports',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabPill({
    required int index,
    required IconData icon,
    required String label,
    dynamic badgeCount,
  }) {
    final isSelected = _tabController.index == index;
    final int count = (badgeCount is num) ? badgeCount.toInt() : 0;

    return InkWell(
      onTap: () {
        _tabController.animateTo(index);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyMid : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.navyMid : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
            const SizedBox(width: 5),
            Text(
              TranslationHelper.translate(context, label),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.dangerRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.dangerRed : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 1: CENTRALIZED REGISTERS & PROPERTIES LIST
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildPropertiesTab(MuddemalProvider provider) {
    if (provider.isLoading && provider.properties.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter properties client-side based on active filter dropdowns, tab & search
    final properties = provider.properties.where((p) {
      // 1. Status Tab filter
      if (_statusTab == 'Pending') {
        final s = p.propertyStatus.toLowerCase();
        final d = p.disposalStatus.toLowerCase();
        final isDisposed = s.contains('disposal') ||
            s.contains('returned') ||
            s.contains('released') ||
            d.contains('disposed') ||
            d.contains('returned') ||
            d.contains('released');
        if (isDisposed) return false;
      } else if (_statusTab == 'Disposal') {
        final s = p.propertyStatus.toLowerCase();
        final d = p.disposalStatus.toLowerCase();
        final isDisposed = s.contains('disposal') ||
            s.contains('returned') ||
            s.contains('released') ||
            d.contains('disposed') ||
            d.contains('returned') ||
            d.contains('released');
        if (!isDisposed) return false;
      }

      // 2. Search query filter
      if (_searchQuery.isNotEmpty) {
        final matchDesc = p.description.toLowerCase().contains(_searchQuery);
        final matchUid = p.propertyUid.toLowerCase().contains(_searchQuery);
        final matchCr = p.crNumber.toLowerCase().contains(_searchQuery);
        final matchDisplayCr =
            p.displayCrNumber.toLowerCase().contains(_searchQuery);
        final matchFrom = p.seizedFrom.toLowerCase().contains(_searchQuery);
        final matchOwner = p.ownerName.toLowerCase().contains(_searchQuery);
        final matchCat = p.categoryName.toLowerCase().contains(_searchQuery);
        final matchModule =
            p.sourceModuleDisplayName.toLowerCase().contains(_searchQuery) ||
                p.sourceModule.toLowerCase().contains(_searchQuery);
        if (!matchDesc &&
            !matchUid &&
            !matchCr &&
            !matchDisplayCr &&
            !matchFrom &&
            !matchOwner &&
            !matchCat &&
            !matchModule) {
          return false;
        }
      }

      // 3. Category filter dropdown
      if (_selectedCategoryFilter != null &&
          _selectedCategoryFilter!.isNotEmpty) {
        if (p.categoryCode != _selectedCategoryFilter) return false;
      }

      // 4. Status filter dropdown
      if (_selectedStatusFilter != null && _selectedStatusFilter!.isNotEmpty) {
        if (p.propertyStatus != _selectedStatusFilter) return false;
      }

      // 5. Source module filter
      if (_selectedSourceModuleFilter != null &&
          _selectedSourceModuleFilter!.isNotEmpty &&
          _selectedSourceModuleFilter!.toLowerCase() != 'all') {
        if (p.sourceModule.toLowerCase() !=
            _selectedSourceModuleFilter!.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();

    final hasFilters = _searchQuery.isNotEmpty ||
        _selectedCategoryFilter != null ||
        _selectedStatusFilter != null ||
        _selectedSourceModuleFilter != null ||
        _statusTab != 'All';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── TOP METRIC / VALUATION CARDS ROW (Matching Image 1) ────
        _buildValuationCards(provider, properties),

        // ── TOOLBAR (Search + Notch Dropdowns - Matching Image 2) ──
        _buildToolbar(provider, properties.length, provider.properties.length),

        // ── CASES COUNT STRIP (Matching Image 3) ───────────────────
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          alignment: Alignment.center,
          child: Text(
            hasFilters
                ? '${properties.length} / ${provider.properties.length} ${TranslationHelper.translate(context, 'cases')}'
                : '${properties.length} ${TranslationHelper.translate(context, 'cases')}',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
        ),

        // ── PROPERTIES LIST / EMPTY STATE ──────────────────────────
        Expanded(
          child: properties.isEmpty
              ? _buildEmptyState(
                  hasFilters: hasFilters,
                  onReset: () {
                    setState(() {
                      _searchCtrl.clear();
                      _searchQuery = '';
                      _selectedCategoryFilter = null;
                      _selectedStatusFilter = null;
                      _selectedSourceModuleFilter = null;
                      _statusTab = 'All';
                    });
                  },
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  itemCount: properties.length,
                  itemBuilder: (context, i) {
                    final p = properties[i];
                    return _buildPropertyCaseCard(p, i + 1);
                  },
                ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TOP VALUATION / METRIC CARDS ROW (Exact Match to Image 1)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildValuationCards(
      MuddemalProvider provider, List<MuddemalPropertyItem> currentList) {
    double stolen = 0;
    double recovered = 0;
    double seized = 0;
    int inCustodyCount = 0;

    final vals = provider.liveValuations;
    final bool hasActiveFilters = _searchQuery.isNotEmpty ||
        _selectedCategoryFilter != null ||
        _selectedStatusFilter != null ||
        _selectedSourceModuleFilter != null ||
        _statusTab != 'All';

    if (!hasActiveFilters && vals.isNotEmpty) {
      stolen = (vals['total_stolen_value'] is num)
          ? (vals['total_stolen_value'] as num).toDouble()
          : 0.0;
      recovered = (vals['recovered_property_value'] is num)
          ? (vals['recovered_property_value'] as num).toDouble()
          : 0.0;
      seized = (vals['total_seized_property_value'] is num)
          ? (vals['total_seized_property_value'] as num).toDouble()
          : 0.0;
      inCustodyCount = provider.inMuddemalRoomCount;
    } else {
      for (final p in currentList) {
        final isStolen = p.categoryCode == 'STOLEN_PROPERTY' ||
            p.propertyStatus == 'Stolen – Not Recovered' ||
            p.propertyStatus == 'Recovered';
        if (isStolen) {
          stolen += p.totalItemValue;
          if (p.propertyStatus == 'Recovered') {
            recovered += p.totalItemValue;
          }
        } else {
          seized += p.totalItemValue;
        }
        if (p.currentCustodyLocation.contains('Muddemal Room') ||
            p.currentCustodyLocation.contains('मालखाना')) {
          inCustodyCount++;
        }
      }
    }

    final nf = NumberFormat('#,##,###');

    final card1 = _buildMetricCard(
      title: 'Total Seized Value',
      value: '₹${nf.format(seized.round())}',
      icon: Icons.inventory_2_outlined,
      iconColor: const Color(0xFF1D4ED8),
      iconContainerBg: const Color(0xFFDBEAFE),
      cardBg: const Color(0xFFF0F6FF),
      cardBorder: const Color(0xFFBFDBFE),
    );

    final card3 = _buildMetricCard(
      title: 'Stolen vs Recovered',
      value:
          '₹${nf.format(stolen.round())} / ₹${nf.format(recovered.round())}',
      icon: Icons.mobile_friendly_rounded,
      iconColor: const Color(0xFFDC2626),
      iconContainerBg: const Color(0xFFFFE4E6),
      cardBg: const Color(0xFFFFF1F2),
      cardBorder: const Color(0xFFFECDD3),
    );

    final card4 = _buildMetricCard(
      title: 'In Custody (मालखाना)',
      value: '$inCustodyCount Properties',
      icon: Icons.warehouse_outlined,
      iconColor: const Color(0xFF0284C7),
      iconContainerBg: const Color(0xFFE0F2FE),
      cardBg: const Color(0xFFF0F9FF),
      cardBorder: const Color(0xFFBAE6FD),
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 850;
          if (isWide) {
            return Row(
              children: [
                Expanded(child: card1),
                const SizedBox(width: 12),
                Expanded(child: card3),
                const SizedBox(width: 12),
                Expanded(child: card4),
              ],
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                card1,
                const SizedBox(width: 12),
                card3,
                const SizedBox(width: 12),
                card4,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconContainerBg,
    required Color cardBg,
    required Color cardBorder,
  }) {
    return Container(
      height: 58,
      constraints: const BoxConstraints(minWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconContainerBg,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  TranslationHelper.translate(context, title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // DYNAMIC BACKEND-DRIVEN FILTER TOOLBAR (Exact Match to Image 2)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildToolbar(
      MuddemalProvider provider, int displayCount, int totalCount) {
    final categories = provider.categories;
    final sourceModules = provider.sourceModules;
    final statuses = provider.propertyStatusOptions;

    final hasFilters = _searchQuery.isNotEmpty ||
        _selectedCategoryFilter != null ||
        _selectedStatusFilter != null ||
        _selectedSourceModuleFilter != null;

    final searchWidget = Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? const Color(0xFF0284C7)
              : const Color(0xFFCBD5E1),
          width: _searchQuery.isNotEmpty ? 1.4 : 1.0,
        ),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: TranslationHelper.translate(
            context,
            provider.searchHintLabel,
          ),
          hintStyle: GoogleFonts.poppins(
            fontSize: 11.5,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: Color(0xFF0284C7),
          ),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? InkWell(
                  onTap: () => _searchCtrl.clear(),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        ),
      ),
    );

    final sourceModuleWidget = _buildNotchDropdown<String?>(
      label: provider.sourceModuleLabel,
      icon: Icons.hub_outlined,
      value: _selectedSourceModuleFilter,
      isActive: _selectedSourceModuleFilter != null,
      width: 215,
      menuWidth: 320,
      selectedItemBuilder: (context) {
        return [
          Row(
            children: [
              const Icon(Icons.hub_outlined,
                  size: 16, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  TranslationHelper.translate(
                      context, provider.allSourceModulesLabel),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          ...sourceModules.where((m) => m['code'] != 'all').map((m) {
            final code = m['code']?.toString() ?? '';
            final name = m['display_name']?.toString() ?? code;
            return Row(
              children: [
                const Icon(Icons.hub_outlined,
                    size: 16, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            );
          }),
        ];
      },
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hub_outlined,
                  size: 16, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Text(
                TranslationHelper.translate(
                    context, provider.allSourceModulesLabel),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        ...sourceModules.where((m) => m['code'] != 'all').map((m) {
          final code = m['code']?.toString() ?? '';
          final name = m['display_name']?.toString() ?? code;
          return DropdownMenuItem<String?>(
            value: code,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hub_outlined,
                    size: 16, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      onChanged: (val) {
        setState(() => _selectedSourceModuleFilter = val);
      },
    );

    final categoryWidget = _buildNotchDropdown<String?>(
      label: provider.propertyCategoryLabel,
      icon: Icons.category_rounded,
      value: _selectedCategoryFilter,
      isActive: true, // Deep navy outline border matching Image 2
      activeBorderColor: const Color(0xFF1E3A8A),
      width: 240,
      menuWidth: 360,
      selectedItemBuilder: (context) {
        return [
          Row(
            children: [
              const Icon(Icons.category_rounded,
                  size: 16, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${provider.allCategoriesLabel} (${categories.length})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          ...categories.map((cat) {
            return Row(
              children: [
                const Icon(Icons.category_rounded,
                    size: 16, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cat.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            );
          }),
        ];
      },
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.category_rounded,
                  size: 16, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Text(
                '${provider.allCategoriesLabel} (${categories.length})',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        ...categories.map((cat) {
          return DropdownMenuItem<String?>(
            value: cat.categoryCode,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.category_rounded,
                    size: 16, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Text(
                  cat.categoryName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      onChanged: (val) {
        setState(() => _selectedCategoryFilter = val);
      },
    );

    final statusWidget = _buildNotchDropdown<String?>(
      label: provider.propertyStatusLabel,
      icon: Icons.shield_outlined,
      value: _selectedStatusFilter,
      isActive: _selectedStatusFilter != null,
      width: 200,
      menuWidth: 300,
      selectedItemBuilder: (context) {
        return [
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: 16, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  TranslationHelper.translate(
                      context, provider.allStatusesLabel),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          ...statuses.map((s) {
            final code = s['code'] ?? '';
            final label = s['label'] ?? code;
            return Row(
              children: [
                const Icon(Icons.shield_outlined,
                    size: 16, color: Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            );
          }),
        ];
      },
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined,
                  size: 16, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Text(
                TranslationHelper.translate(
                    context, provider.allStatusesLabel),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        ...statuses.map((s) {
          final code = s['code'] ?? '';
          final label = s['label'] ?? code;
          return DropdownMenuItem<String?>(
            value: code,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined,
                    size: 16, color: Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      onChanged: (val) {
        setState(() => _selectedStatusFilter = val);
      },
    );

    final clearFiltersWidget = hasFilters
        ? InkWell(
            onTap: () {
              setState(() {
                _searchCtrl.clear();
                _searchQuery = '';
                _selectedCategoryFilter = null;
                _selectedStatusFilter = null;
                _selectedSourceModuleFilter = null;
                _statusTab = 'All';
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.filter_alt_off_rounded,
                    size: 15,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    TranslationHelper.translate(context, provider.clearFiltersLabel),
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1080;
          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(minWidth: 260, maxWidth: 320),
                  child: searchWidget,
                ),
                const SizedBox(width: 12),
                sourceModuleWidget,
                const SizedBox(width: 12),
                categoryWidget,
                const SizedBox(width: 12),
                statusWidget,
                if (hasFilters) ...[
                  const SizedBox(width: 12),
                  clearFiltersWidget,
                ],
              ],
            );
          }
          return Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.start,
            children: [
              ConstrainedBox(
                constraints:
                    const BoxConstraints(minWidth: 240, maxWidth: 320),
                child: searchWidget,
              ),
              sourceModuleWidget,
              categoryWidget,
              statusWidget,
              if (hasFilters) clearFiltersWidget,
            ],
          );
        },
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // REUSABLE NOTCH-LABEL DROPDOWN COMPONENT (Matching Image 2 Style)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildNotchDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool isActive = false,
    Color? activeBorderColor,
    double width = 210,
    double? menuWidth,
    DropdownButtonBuilder? selectedItemBuilder,
  }) {
    final borderColor = isActive
        ? (activeBorderColor ?? const Color(0xFF1E3A8A))
        : const Color(0xFFCBD5E1);
    final labelColor = isActive
        ? (activeBorderColor ?? const Color(0xFF1E3A8A))
        : const Color(0xFF64748B);

    return SizedBox(
      width: width,
      height: 42,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: TranslationHelper.translate(context, label),
          labelStyle: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: labelColor,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          isDense: true,
          contentPadding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: borderColor, width: isActive ? 1.5 : 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: borderColor, width: isActive ? 1.5 : 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: activeBorderColor ?? const Color(0xFF1E3A8A),
              width: 1.8,
            ),
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isDense: true,
            isExpanded: true,
            menuWidth: menuWidth,
            menuMaxHeight: 460,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(8),
            elevation: 4,
            selectedItemBuilder: selectedItemBuilder,
            icon: const Icon(
              Icons.arrow_drop_down_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // DEDICATED HORIZONTAL CASE CARD (Matching Preventive Module Layout in Image 3)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildPropertyCaseCard(MuddemalPropertyItem p, int index) {
    final isDisposal = p.propertyStatus.toLowerCase().contains('disposal') ||
        p.propertyStatus.toLowerCase().contains('returned') ||
        p.propertyStatus.toLowerCase().contains('released') ||
        p.disposalStatus.toLowerCase().contains('disposed') ||
        p.disposalStatus.toLowerCase().contains('returned') ||
        p.disposalStatus.toLowerCase().contains('released');
    final Color statusColor =
        isDisposal ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
    final Color statusBg =
        isDisposal ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final Color statusBorder =
        isDisposal ? const Color(0xFFA5D6A7) : const Color(0xFFFFCDD2);

    final accusedOrOwner = p.seizedFrom.isNotEmpty
        ? p.seizedFrom
        : (p.ownerName.isNotEmpty ? p.ownerName : '—');

    Widget buildRowContent(bool isExpandedMode) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 0. Sr. No. Box (Red for Pending, Green for Disposal)
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusBorder),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sr.No',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: statusColor.withValues(alpha: 0.85),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$index',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // 1. CR No. Pill with Dynamic Source Tab
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CR No.',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                        height: 1.0,
                      ),
                    ),
                    if (p.sourceModuleDisplayName.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          p.sourceModuleDisplayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3730A3),
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  p.displayCrNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // 1b. Dedicated Source Tab Pill (Dynamic from Database: e.g. Crime (Murder), Crime (Theft), etc.)
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFFC7D2FE),
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tab_rounded, size: 9, color: Color(0xFF4338CA)),
                    const SizedBox(width: 3),
                    Text(
                      'Source Tab',
                      style: GoogleFonts.poppins(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4338CA),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  p.sourceModuleDisplayName.isNotEmpty
                      ? p.sourceModuleDisplayName
                      : 'Crime',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF312E81),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // 2. Property Category (Gold pill)
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFFFDE68A),
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  p.categoryLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF92400E),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          _buildDivider(),

          // 3. Property Description
          isExpandedMode
              ? Expanded(
                  flex: 5,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Property Description',
                    value: p.description,
                    icon: Icons.inventory_2_outlined,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  label: 'Property Description',
                  value: p.description,
                  icon: Icons.inventory_2_outlined,
                ),

          _buildDivider(),

          // 4. Seized From / Accused
          isExpandedMode
              ? Expanded(
                  flex: 4,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Seized From / Accused',
                    value: accusedOrOwner,
                    icon: Icons.person_outline_rounded,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  label: 'Seized From / Accused',
                  value: accusedOrOwner,
                  icon: Icons.person_outline_rounded,
                ),

          _buildDivider(),

          // 5. Seizure Date
          isExpandedMode
              ? Expanded(
                  flex: 3,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Seizure Date',
                    value: p.seizureDate ?? '—',
                    icon: Icons.calendar_today_outlined,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  label: 'Seizure Date',
                  value: p.seizureDate ?? '—',
                  icon: Icons.calendar_today_outlined,
                ),

          _buildDivider(),

          // 6. Valuation
          isExpandedMode
              ? Expanded(
                  flex: 3,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Valuation',
                    value:
                        '₹${NumberFormat('#,##,###').format(p.totalItemValue)}',
                    icon: Icons.currency_rupee_rounded,
                    valueColor: AppColors.navyDark,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  label: 'Valuation',
                  value:
                      '₹${NumberFormat('#,##,###').format(p.totalItemValue)}',
                  icon: Icons.currency_rupee_rounded,
                  valueColor: AppColors.navyDark,
                ),

          _buildDivider(),

          // 7. Custody Location
          isExpandedMode
              ? Expanded(
                  flex: 4,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Custody Location',
                    value: p.currentCustodyLocation,
                    icon: Icons.location_on_outlined,
                    iconColor: const Color(0xFF0EA5E9),
                    valueColor: const Color(0xFF0284C7),
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  label: 'Custody Location',
                  value: p.currentCustodyLocation,
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xFF0EA5E9),
                  valueColor: const Color(0xFF0284C7),
                ),

          const SizedBox(width: 8),

          // 8. Status Badge
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: statusBorder,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Status',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: statusColor.withValues(alpha: 0.85),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  TranslationHelper.translate(
                    context,
                    p.propertyStatus,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 9. Labeled Action Buttons: Edit, View
          _buildLabeledActionButton(
            context: context,
            icon: Icons.edit_outlined,
            label: 'Edit',
            color: AppColors.infoBlue,
            onTap: () async {
              showDialog(
                context: context,
                builder: (_) => MuddemalPropertyFormDialog(
                  existingProperty: p,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          _buildLabeledActionButton(
            context: context,
            icon: Icons.visibility_outlined,
            label: 'View',
            color: const Color(0xFFE65100),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => MuddemalPropertyDetailDialog(
                  property: p,
                ),
              );
            },
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1050;
          if (isWide) {
            return buildRowContent(true);
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1050),
              child: buildRowContent(false),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildFieldColumn({
    required BuildContext context,
    required String label,
    required String value,
    IconData? icon,
    Color? iconColor,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 11.5, color: iconColor ?? const Color(0xFF64748B)),
              const SizedBox(width: 3.5),
            ],
            Flexible(
              child: Text(
                TranslationHelper.translate(context, label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Tooltip(
          message: value,
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF0F172A),
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final fgColor = color ?? const Color(0xFF1E293B);
    return Tooltip(
      message: TranslationHelper.translate(context, label),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 38,
          width: 38,
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: fgColor),
              const SizedBox(height: 1.5),
              Text(
                TranslationHelper.translate(context, label),
                maxLines: 1,
                style: GoogleFonts.poppins(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required bool hasFilters,
    required VoidCallback onReset,
  }) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.lightBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 38,
                color: Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasFilters
                  ? 'No Matching Properties'
                  : 'No Properties Registered',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'No records match the given CR No., Accused, Description, or filter criteria.'
                  : 'Seized properties will appear here once registered or synced from cases.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.lightSubText,
                height: 1.4,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  TranslationHelper.translate(context, 'Reset All Filters'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 2: FSL ALERTS & CHAIN OF CUSTODY
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildAlertsTab(MuddemalProvider provider) {
    final alerts = provider.fslAlerts;
    final summary = (alerts['summary'] is Map)
        ? Map<String, dynamic>.from(alerts['summary'] as Map)
        : <String, dynamic>{};

    final sendAlerts = (alerts['send_pending_alerts'] is List)
        ? (alerts['send_pending_alerts'] as List).whereType<Map>().toList()
        : [];
    final reportAlerts = (alerts['report_pending_alerts'] is List)
        ? (alerts['report_pending_alerts'] as List).whereType<Map>().toList()
        : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Threshold summary banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FSL Escalation Alerts (Backend Configured Thresholds: 7, 15, 30 Days)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: () => provider.loadFSLAlerts(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAlertStatCard(
                      'Critical (≥ 30 Days)',
                      summary['critical_30_days']?.toString() ?? '0',
                      AppColors.dangerRed,
                      Icons.warning_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildAlertStatCard(
                      'Warning (15-29 Days)',
                      summary['warning_15_days']?.toString() ?? '0',
                      AppColors.warningOrange,
                      Icons.access_time_filled_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildAlertStatCard(
                      'Alert (7-14 Days)',
                      summary['alert_7_days']?.toString() ?? '0',
                      const Color(0xFFD97706),
                      Icons.alarm_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildAlertStatCard(
                      'Total Pending',
                      summary['total_alerts']?.toString() ?? '0',
                      AppColors.navyMid,
                      Icons.biotech_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 1: FSL Send Pending
          _buildAlertSectionHeader(
            'FSL Dispatch Pending (Examination Required but not dispatched)',
            sendAlerts.length,
            AppColors.warningOrange,
          ),
          const SizedBox(height: 10),
          if (sendAlerts.isEmpty)
            _buildEmptyAlertCard('No properties pending FSL dispatch.')
          else
            ...sendAlerts.map((a) => _buildAlertItemCard(a, isSendPending: true)),

          const SizedBox(height: 24),

          // Section 2: FSL Report Pending
          _buildAlertSectionHeader(
            'FSL Report Pending (Dispatched to Lab but report not yet received)',
            reportAlerts.length,
            const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 10),
          if (reportAlerts.isEmpty)
            _buildEmptyAlertCard('No laboratory reports currently pending.')
          else
            ...reportAlerts
                .map((a) => _buildAlertItemCard(a, isSendPending: false)),
        ],
      ),
    );
  }

  Widget _buildAlertStatCard(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.lightSubText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          '$title ($count)',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertItemCard(Map a, {required bool isSendPending}) {
    final days = a['days_pending'] ?? 0;
    Color tierColor = AppColors.navyMid;
    if (days >= 30) {
      tierColor = AppColors.dangerRed;
    } else if (days >= 15) {
      tierColor = AppColors.warningOrange;
    } else if (days >= 7) {
      tierColor = const Color(0xFFD97706);
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: tierColor.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: tierColor.withOpacity(0.12),
              child: Icon(Icons.alarm_rounded, color: tierColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${a['property_uid']} — ${a['category_name']}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.navyDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: tierColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$days Days Pending',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a['description']?.toString() ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.navyDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'CR: ${a['cr_number']} | IO: ${a['io_name']} | Station: ${a['station_name']}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.lightSubText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAlertCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.lightSubText),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 3: DASHBOARDS & REPORTS
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildDashboardsTab(MuddemalProvider provider) {
    final stolen = provider.stolenDashboard;
    final seized = provider.seizedDashboard;
    final pending = provider.pendingDashboard;
    final myReport = provider.monthlyYearlyReport;

    final categories = (seized['all_categories_breakdown'] is List)
        ? (seized['all_categories_breakdown'] as List)
            .whereType<Map>()
            .toList()
        : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Muddemal Executive Analytics & Audit Reports',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              DropdownButton<int>(
                value: provider.selectedYear,
                items: [2024, 2025, 2026]
                    .map((y) => DropdownMenuItem(value: y, child: Text('Year $y')))
                    .toList(),
                onChanged: (y) {
                  if (y != null) provider.setYear(y);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // DASHBOARD A: Stolen Property
          _buildDashboardHeader('A. Stolen Property & Recovery Dashboard', Icons.security_rounded),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildDashCard('Total Theft Cases', stolen['total_theft_cases']?.toString() ?? '0', AppColors.navyMid),
              const SizedBox(width: 10),
              _buildDashCard('Total Stolen Value', '₹${NumberFormat('#,##,###').format(stolen['total_stolen_property_value'] ?? 0)}', AppColors.dangerRed),
              const SizedBox(width: 10),
              _buildDashCard('Recovered Value', '₹${NumberFormat('#,##,###').format(stolen['recovered_property_value'] ?? 0)}', AppColors.successGreen),
              const SizedBox(width: 10),
              _buildDashCard('Recovery Rate', stolen['recovery_percentage']?.toString() ?? 'N/A', const Color(0xFF0891B2)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildDashCard('100% Recovery Cases', stolen['cases_with_100_recovery']?.toString() ?? '0', AppColors.successGreen),
              const SizedBox(width: 10),
              _buildDashCard('Partial Recovery Cases', stolen['cases_with_partial_recovery']?.toString() ?? '0', AppColors.warningOrange),
              const SizedBox(width: 10),
              _buildDashCard('Zero Recovery Cases', stolen['cases_with_zero_recovery']?.toString() ?? '0', AppColors.dangerRed),
            ],
          ),
          const SizedBox(height: 24),

          // DASHBOARD B: Seized Property Breakdown
          _buildDashboardHeader('B. Seized Property Dashboard (Total Value: ₹${NumberFormat('#,##,###').format(seized['total_seized_property_value'] ?? 0)})', Icons.inventory_2_rounded),
          const SizedBox(height: 10),
          if (categories.isEmpty)
            _buildEmptyAlertCard('No property categories data.')
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((c) {
                return Container(
                  width: 240,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['category_name']?.toString() ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Count: ${c['count']}',
                              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.lightSubText)),
                          Text(
                            '₹${NumberFormat('#,##,###').format(c['total_value'] ?? 0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),

          // DASHBOARD C: Pending Muddemal
          _buildDashboardHeader('C. Pending Muddemal Dashboard', Icons.pending_actions_rounded),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildDashCard('FSL Send Pending', pending['fsl_send_pending_count']?.toString() ?? '0', AppColors.warningOrange),
              const SizedBox(width: 10),
              _buildDashCard('FSL Report Pending', pending['fsl_report_pending_count']?.toString() ?? '0', const Color(0xFF7C3AED)),
              const SizedBox(width: 10),
              _buildDashCard('Disposal Pending', pending['disposal_pending_count']?.toString() ?? '0', AppColors.dangerRed),
              const SizedBox(width: 10),
              _buildDashCard('Vehicles Pending', pending['vehicles_pending_disposal_count']?.toString() ?? '0', AppColors.navyMid),
              const SizedBox(width: 10),
              _buildDashCard('Pending > 30 Days', pending['long_pending_over_30_days']?.toString() ?? '0', AppColors.dangerRed),
            ],
          ),
          const SizedBox(height: 24),

          // DASHBOARD D: Month-wise and Year-wise Trend Table
          _buildDashboardHeader('D. Month-wise Report (${provider.selectedYear})', Icons.calendar_view_month_rounded),
          const SizedBox(height: 10),
          _buildMonthlyTable(myReport),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.navyMid),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
          ),
        ),
      ],
    );
  }

  Widget _buildDashCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.lightSubText)),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTable(Map report) {
    final months = (report['monthly_report'] is List)
        ? (report['monthly_report'] as List).whereType<Map>().toList()
        : [];

    if (months.isEmpty) {
      return _buildEmptyAlertCard('No monthly report data available.');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
      ),
      child: Table(
        border: TableBorder.symmetric(
            inside: BorderSide(color: AppColors.lightBorder.withOpacity(0.4))),
        children: [
          TableRow(
            decoration: BoxDecoration(color: AppColors.navyMid.withOpacity(0.06)),
            children: [
              _buildCell('Month', isHeader: true),
              _buildCell('Stolen Value', isHeader: true),
              _buildCell('Recovered Value', isHeader: true),
              _buildCell('Not Recovered', isHeader: true),
              _buildCell('Recovery %', isHeader: true),
              _buildCell('Seized Value', isHeader: true),
              _buildCell('Pending Items', isHeader: true),
            ],
          ),
          ...months.map((m) {
            return TableRow(
              children: [
                _buildCell(m['month_name']?.toString() ?? ''),
                _buildCell('₹${NumberFormat('#,##,###').format(m['total_stolen_value'] ?? 0)}'),
                _buildCell('₹${NumberFormat('#,##,###').format(m['recovered_value'] ?? 0)}'),
                _buildCell('₹${NumberFormat('#,##,###').format(m['not_recovered_value'] ?? 0)}'),
                _buildCell(m['recovery_percentage']?.toString() ?? 'N/A'),
                _buildCell('₹${NumberFormat('#,##,###').format(m['seized_property_value'] ?? 0)}'),
                _buildCell(m['pending_property_count']?.toString() ?? '0'),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          color: isHeader ? AppColors.navyMid : AppColors.navyDark,
        ),
      ),
    );
  }
}
