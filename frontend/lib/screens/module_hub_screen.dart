// ignore_for_file: unused_element, unused_field, unused_local_variable, dead_code, use_build_context_synchronously
// lib/screens/module_hub_screen.dart
// Reusable screen for ALL 12 modules — strictly isolated data per module.

import 'package:flutter/material.dart';
import 'itsso_hub_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/case_status_constants.dart';
import '../modules/absconded/providers/absconded_provider.dart';
import '../modules/accident/providers/accident_provider.dart';
import '../modules/accidental_death/providers/accidental_death_provider.dart';
import '../modules/application/providers/application_provider.dart';
import '../modules/arrested/providers/arrested_provider.dart';
import '../modules/bnss/providers/bnss_provider.dart';
import '../modules/coin/providers/coin_provider.dart';
import '../modules/core/models/base_record.dart';
import '../modules/core/providers/base_module_provider.dart';
import '../modules/crime_women/providers/crime_women_provider.dart';
import '../modules/detected/providers/detected_provider.dart';
import '../modules/disposal/providers/disposal_provider.dart';
import '../modules/form_iv/providers/form_iv_provider.dart';
import '../modules/form_vi/providers/form_vi_provider.dart';
import '../modules/gowans/providers/gowans_provider.dart';
import '../modules/hurt/providers/hurt_provider.dart';
import '../modules/it_act/providers/it_act_provider.dart';
import '../modules/juvenile/providers/juvenile_provider.dart';
import '../modules/kidnapping/providers/kidnapping_provider.dart';
import '../modules/mcoca/providers/mcoca_provider.dart';
import '../modules/missing/providers/missing_provider.dart';
import '../modules/missing/screens/missing_form_screen.dart';
import '../modules/monthly/providers/monthly_provider.dart';
import '../modules/mpda/providers/mpda_provider.dart';
import '../modules/mpda/screens/mpda_form_screen.dart';
import '../modules/muddemal/providers/muddemal_provider.dart';
import '../modules/nc/providers/nc_provider.dart';
import '../modules/nc/screens/nc_form_screen.dart';
import '../modules/ndps/providers/ndps_provider.dart';
import '../modules/passport/providers/passport_provider.dart';
import '../widgets/summons_warrant_report_table.dart';
import '../widgets/monthly_crime_comparative_table.dart';
import '../widgets/add_warrant_case_dialog.dart';
import '../modules/pending/providers/pending_provider.dart';
import '../modules/pocso/providers/pocso_provider.dart';
import '../modules/preventive/providers/preventive_provider.dart';
import '../modules/preventive/screens/preventive_form_screen.dart';
import '../modules/preventive/screens/preventive_view_screen.dart';
import '../modules/sam_warrant/providers/sam_warrant_provider.dart';
import '../modules/sand_theft/providers/sand_theft_provider.dart';
import '../modules/st_drugs/providers/st_drugs_provider.dart';
import '../modules/theft/providers/theft_provider.dart';
import '../modules/traffic/providers/traffic_provider.dart';
import '../modules/two_four_wheeler/providers/two_four_wheeler_provider.dart';
import '../modules/uapa/providers/uapa_provider.dart';
import '../modules/undetected/providers/undetected_provider.dart';
import '../modules/victim/providers/victim_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/ad_disposal_helper.dart';
import '../utils/common_form_module.dart';
import '../utils/module_pdf_helper.dart';
import '../utils/pdf_auth_gate.dart';
import '../utils/translation_helper.dart';
import '../widgets/forms_accordion_list.dart';
import '../widgets/module_hub_report_card.dart';
import '../widgets/module_hub_screen_app_bar.dart';
import '../widgets/read_only_module_record_hub_card.dart';
import 'absconded_hub_screen.dart';
import 'victim_hub_screen.dart';
import 'ad_form_screen.dart';
import 'ad_record_detail_screen.dart';
import 'common_form_screen.dart';
import 'form_i_v_selection_screen.dart';
import 'form_vi_selection_screen.dart' hide FormIVEmptyCasesState;
import 'hurt_cases_screen.dart';
import 'module_form_screen.dart';
import 'module_record_detail_screen.dart';
import '../widgets/dynamic_form/dynamic_form_screen.dart';
import 'filtered_pending_screen.dart';
import 'pending_io_wise_screens.dart';
import 'pending_summary_screen.dart';
import '../services/backend_case_service.dart';
import '../utils/pending_table_firestore_mapper.dart';

class _CategoryMeta {
  final String label;
  final String moduleKey;
  final String? subCategory;
  int count;
  int solvedCount = 0;

  _CategoryMeta({
    required this.label,
    required this.moduleKey,
    this.subCategory,
    required this.count,
  });
}

class ModuleHubScreen extends StatefulWidget {
  final String moduleLabel;
  final String moduleKey;
  final String? subCategory;
  final bool readOnly;

  const ModuleHubScreen({
    super.key,
    required this.moduleLabel,
    required this.moduleKey,
    this.subCategory,
    this.readOnly = false,
  });

  @override
  State<ModuleHubScreen> createState() => _ModuleHubScreenState();
}

class _ModuleHubScreenState extends State<ModuleHubScreen> {
  String _filter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  late int _reportMonth;
  late int _reportYear;
  DateTimeRange? _selectedDateRange;
  FormIVDateField _dateField = FormIVDateField.incidentDate;
  FormIVDateSortOrder _dateSortOrder = FormIVDateSortOrder.newestFirst;

  String? _pendingCategory;
  String? _pendingTimeRange;
  String? _pendingViewMode;

  static const List<String> _pendingHubTimeRanges = [
    'Select time range',
    'More than 1 year',
    '6 to 12 months',
    '3 to 6 months',
    'More than 3 months',
    'Within 3 months',
    '1 month',
  ];

  static const List<String> _pendingHubViewModes = [
    'Case Wise',
    'IO Wise',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _reportMonth = now.month;
    _reportYear = now.year;
    if (widget.moduleKey == 'detected' || widget.moduleKey == 'undetected') {
      _filter = 'All';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _readProvider(context).ensureInitialized();
      }
    });
  }

  @override
  void didUpdateWidget(ModuleHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moduleKey != widget.moduleKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _readProvider(context).ensureInitialized();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Watch the correct typed provider so UI rebuilds on data changes.
  BaseModuleProvider _watchProvider(BuildContext context) {
    switch (widget.moduleKey) {
      case 'form_1_5':
        return context.watch<FormIVProvider>();
      case 'form_6':
        return context.watch<FormVIProvider>();
      case 'nc':
        return context.watch<NcProvider>();
      case 'preventive':
        return context.watch<PreventiveProvider>();
      case 'ad':
        return context.watch<AdProvider>();
      case 'missing':
        return context.watch<MissingProvider>();
      case 'kidnapping':
        return context.watch<KidnappingProvider>();
      case 'theft':
        return context.watch<TheftProvider>();
      case 'sand_theft':
        return context.watch<SandTheftProvider>();
      case 'hurt':
        return context.watch<HurtProvider>();
      case 'pocso':
        return context.watch<PocsoProvider>();
      case 'passport':
        return context.watch<PassportProvider>();
      case 'monthly':
        return context.watch<MonthlyProvider>();
      case 'pending':
        return context.watch<PendingProvider>();
      case 'detected':
        return context.watch<DetectedProvider>();
      case 'undetected':
        return context.watch<UndetectedProvider>();
      case 'disposal':
        return context.watch<DisposalProvider>();
      case 'two_four_wheeler':
        return context.watch<TwoFourWheelerProvider>();
      case 'arrested':
        return context.watch<ArrestedProvider>();
      case 'absconded':
        return context.watch<AbscondedProvider>();
      case 'crime_women':
        return context.watch<CrimeWomenProvider>();
      case 'juvenile':
        return context.watch<JuvenileProvider>();
      case 'victim':
        return context.watch<VictimProvider>();
      case 'accident':
        return context.watch<AccidentProvider>();
      case 'traffic':
        return context.watch<TrafficProvider>();
      case 'application':
        return context.watch<ApplicationProvider>();
      case 'sam_warrant':
        return context.watch<SamWarrantProvider>();
      case 'muddemal':
        return context.watch<MuddemalProvider>();
      case 'bnss':
        return context.watch<BnssProvider>();
      case 'ndps':
        return context.watch<NdpsProvider>();
      case 'gowans':
        return context.watch<GowansProvider>();
      case 'it_act':
        return context.watch<ItActProvider>();
      case 'mcoca':
        return context.watch<McocaProvider>();
      case 'uapa':
        return context.watch<UapaProvider>();
      case 'mpda':
        return context.watch<MpdaProvider>();
      case 'coin':
        return context.watch<CoinProvider>();
      case 'st_drugs':
        return context.watch<StDrugsProvider>();
      default:
        return context.watch<FormIVProvider>();
    }
  }

  /// Read (no listen) version for delete/update calls inside callbacks.
  BaseModuleProvider _readProvider(BuildContext context) {
    switch (widget.moduleKey) {
      case 'form_1_5':
        return context.read<FormIVProvider>();
      case 'form_6':
        return context.read<FormVIProvider>();
      case 'nc':
        return context.read<NcProvider>();
      case 'preventive':
        return context.read<PreventiveProvider>();
      case 'ad':
        return context.read<AdProvider>();
      case 'missing':
        return context.read<MissingProvider>();
      case 'kidnapping':
        return context.read<KidnappingProvider>();
      case 'theft':
        return context.read<TheftProvider>();
      case 'sand_theft':
        return context.read<SandTheftProvider>();
      case 'hurt':
        return context.read<HurtProvider>();
      case 'pocso':
        return context.read<PocsoProvider>();
      case 'passport':
        return context.read<PassportProvider>();
      case 'monthly':
        return context.read<MonthlyProvider>();
      case 'pending':
        return context.read<PendingProvider>();
      case 'detected':
        return context.read<DetectedProvider>();
      case 'undetected':
        return context.read<UndetectedProvider>();
      case 'disposal':
        return context.read<DisposalProvider>();
      case 'two_four_wheeler':
        return context.read<TwoFourWheelerProvider>();
      case 'arrested':
        return context.read<ArrestedProvider>();
      case 'absconded':
        return context.read<AbscondedProvider>();
      case 'crime_women':
        return context.read<CrimeWomenProvider>();
      case 'juvenile':
        return context.read<JuvenileProvider>();
      case 'victim':
        return context.read<VictimProvider>();
      case 'accident':
        return context.read<AccidentProvider>();
      case 'traffic':
        return context.read<TrafficProvider>();
      case 'application':
        return context.read<ApplicationProvider>();
      case 'sam_warrant':
        return context.read<SamWarrantProvider>();
      case 'muddemal':
        return context.read<MuddemalProvider>();
      case 'bnss':
        return context.read<BnssProvider>();
      case 'ndps':
        return context.read<NdpsProvider>();
      case 'gowans':
        return context.read<GowansProvider>();
      case 'it_act':
        return context.read<ItActProvider>();
      case 'mcoca':
        return context.read<McocaProvider>();
      case 'uapa':
        return context.read<UapaProvider>();
      case 'mpda':
        return context.read<MpdaProvider>();
      case 'coin':
        return context.read<CoinProvider>();
      case 'st_drugs':
        return context.read<StDrugsProvider>();
      default:
        return context.read<FormIVProvider>();
    }
  }

  bool _isReportMode = false;

  List<ModuleRecord> _getConsolidatedRecords(BuildContext context) {
    final records = <ModuleRecord>[];
    // We only include crime/service modules, excluding stats modules to avoid recursion
    records.addAll(context.watch<FormIVProvider>().records);
    records.addAll(context.watch<FormVIProvider>().records);
    records.addAll(context.watch<NcProvider>().records);
    records.addAll(context.watch<PreventiveProvider>().records);
    records.addAll(context.watch<AdProvider>().records);
    records.addAll(context.watch<MissingProvider>().records);
    records.addAll(context.watch<KidnappingProvider>().records);
    records.addAll(context.watch<TheftProvider>().records);
    records.addAll(context.watch<SandTheftProvider>().records);
    records.addAll(context.watch<HurtProvider>().records);
    records.addAll(context.watch<PocsoProvider>().records);
    records.addAll(context.watch<PassportProvider>().records);
    records.addAll(context.watch<TwoFourWheelerProvider>().records);
    records.addAll(context.watch<ArrestedProvider>().records);
    records.addAll(context.watch<AbscondedProvider>().records);
    records.addAll(context.watch<CrimeWomenProvider>().records);
    records.addAll(context.watch<JuvenileProvider>().records);
    records.addAll(context.watch<VictimProvider>().records);
    records.addAll(context.watch<AccidentProvider>().records);
    records.addAll(context.watch<TrafficProvider>().records);
    records.addAll(context.watch<ApplicationProvider>().records);
    records.addAll(context.watch<SamWarrantProvider>().records);
    records.addAll(context.watch<MuddemalProvider>().records);
    records.addAll(context.watch<BnssProvider>().records);
    records.addAll(context.watch<NdpsProvider>().records);
    records.addAll(context.watch<GowansProvider>().records);
    records.addAll(context.watch<ItActProvider>().records);
    records.addAll(context.watch<McocaProvider>().records);
    records.addAll(context.watch<UapaProvider>().records);
    records.addAll(context.watch<MpdaProvider>().records);
    records.addAll(context.watch<CoinProvider>().records);
    return records;
  }

  void _openNewEntryForm(BuildContext context) {
    if (widget.moduleKey == 'sam_warrant') {
      AddWarrantCaseDialog.show(
        context,
        initialYear: _reportYear,
        initialMonth: _reportMonth,
      ).then((added) {
        if (added == true && mounted) {
          setState(() {});
        }
      });
      return;
    }
    if (widget.moduleKey == 'ad') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(page: const ADFormScreen()),
      );
      return;
    }
    if (widget.moduleKey == 'nc') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: NcFormScreen(
            moduleLabel: widget.moduleLabel,
            subCategory: widget.subCategory,
          ),
        ),
      );
      return;
    }
    if (widget.moduleKey == 'missing') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: MissingFormScreen(
            moduleLabel: widget.moduleLabel,
            subCategory: widget.subCategory,
          ),
        ),
      );
      return;
    }
    if (widget.moduleKey == 'preventive') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: PreventiveFormScreen(
            moduleLabel: widget.moduleLabel,
            subCategory: widget.subCategory,
          ),
        ),
      );
      return;
    }
    if (widget.moduleKey == 'mpda') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: MpdaFormScreen(
            moduleLabel: widget.moduleLabel,
            subCategory: widget.subCategory,
          ),
        ),
      );
      return;
    }
    if (widget.moduleKey == 'form_1_5' && widget.subCategory == null) {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const FormIVSelectionScreen(
            mode: FormIVSelectionMode.add,
          ),
        ),
      );
    } else if (widget.moduleKey == 'form_6' && widget.subCategory == null) {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const FormVISelectionScreen(
            mode: FormVISelectionMode.add,
          ),
        ),
      );
    } else {
      final page = moduleUsesCommonCrimeForm(
              widget.moduleKey, widget.subCategory ?? widget.moduleLabel)
          ? CommonFormScreen(
              moduleLabel: widget.moduleLabel,
              moduleKey: widget.moduleKey,
              subCategory: widget.subCategory,
            )
          : ModuleFormScreen(
              moduleLabel: widget.moduleLabel,
              moduleKey: widget.moduleKey,
              subCategory: widget.subCategory,
            );
      Navigator.push(context, AppTheme.fadeSlideRoute(page: page));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moduleKey.toLowerCase() == 'itsso') {
      // Return the new ItssOHubScreen instead of the default module list
      return const ItssoHubScreen(stationName: 'All Stations');
    }
    if (widget.moduleKey == 'hurt') {
      return HurtCasesScreen(readOnly: widget.readOnly);
    }
    if (widget.moduleKey == 'absconded') {
      final auth = context.watch<AuthProvider>();
      return AbscondedHubScreen(stationName: auth.stationName);
    }
    if (widget.moduleKey == 'victim') {
      final auth = context.watch<AuthProvider>();
      return VictimHubScreen(stationName: auth.stationName);
    }

    List<ModuleRecord> allRecords;
    int totalCount;

    if (widget.moduleKey == 'pending') {
      // Aggregate across ALL categories and show only active (non-disposed) cases
      final consolidated = _getConsolidatedRecords(context);
      allRecords = consolidated
          .where((r) => isRecordPending(r) && r.moduleKey != 'nc')
          .toList();
      totalCount = allRecords.length;
    } else if (widget.moduleKey == 'disposal') {
      // Aggregate across ALL categories and show only disposal/closed cases
      final consolidated = _getConsolidatedRecords(context);
      allRecords = consolidated.where(isRecordDisposal).toList();
      totalCount = allRecords.length;
    } else if (widget.moduleKey == 'monthly') {
      allRecords = _getConsolidatedRecords(context);
      totalCount = allRecords.length;
    } else if (widget.moduleKey == 'absconded') {
      final abscondedRecords = context.watch<AbscondedProvider>().records;
      final formIVRecords = context.watch<FormIVProvider>().records;

      final combined = <String, ModuleRecord>{};
      for (final r in formIVRecords) {
        combined[r.id] = r;
      }
      for (final r in abscondedRecords) {
        combined[r.id] = r;
      }

      final recordsList = combined.values.toList();
      if (widget.subCategory != null && widget.subCategory!.isNotEmpty) {
        allRecords = recordsList
            .where((r) => r.subCategory == widget.subCategory)
            .toList();
      } else {
        allRecords = recordsList;
      }
      allRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      totalCount = allRecords.length;
    } else if (widget.moduleKey == 'mpda') {
      final provider = _watchProvider(context);
      allRecords = provider.records;
      totalCount = provider.records.length;
    } else {
      final provider = _watchProvider(context);
      allRecords = provider.getFilteredRecords(widget.subCategory);
      totalCount = provider.getFilteredTotalCount(widget.subCategory);
    }

    int disposalCount = widget.moduleKey == 'absconded'
        ? allRecords.where((r) => isAbscondedDisposal(r)).length
        : allRecords.where(isRecordDisposal).length;
    int pendingCount = allRecords.length - disposalCount;

    final List<ModuleRecord> filtered;
    // Filtering logic combined
    if (widget.moduleKey == 'absconded') {
      if (_filter == 'Disposal' ||
          _filter == 'Closed' ||
          _filter == 'Resolved') {
        filtered = allRecords.where((r) => isAbscondedDisposal(r)).toList();
      } else if (_filter == 'Pending' ||
          _filter == 'Open' ||
          _filter == 'Active') {
        filtered = allRecords.where((r) => !isAbscondedDisposal(r)).toList();
      } else {
        filtered = allRecords;
      }
    } else {
      if (_filter == 'Disposal' ||
          _filter == 'Closed' ||
          _filter == 'Resolved') {
        filtered = allRecords.where(isRecordDisposal).toList();
      } else if (_filter == 'Pending' ||
          _filter == 'Open' ||
          _filter == 'Active') {
        filtered = allRecords.where(isRecordPending).toList();
      } else {
        filtered = _filter == 'All'
            ? allRecords
            : allRecords.where((r) => r.status == _filter).toList();
      }
    }

    final bool isTheftOrFormIVStyle = widget.moduleKey == 'theft' ||
        widget.moduleLabel == 'Theft' ||
        widget.moduleKey == 'sand_theft' ||
        widget.moduleKey == 'two_four_wheeler';

    FormIVStatusTab selectedTab;
    if (_filter == CaseStatus.pending) {
      selectedTab = FormIVStatusTab.pending;
    } else if (_filter == CaseStatus.disposal) {
      selectedTab = FormIVStatusTab.disposal;
    } else {
      selectedTab = FormIVStatusTab.total;
    }

    List<ModuleRecord> displayRecords = List<ModuleRecord>.from(filtered);
    if (isTheftOrFormIVStyle) {
      if (_selectedDateRange != null) {
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
        );
        displayRecords = displayRecords.where((r) {
          final targetDate = _dateField == FormIVDateField.incidentDate
              ? r.incidentDate
              : r.createdAt;
          return targetDate
                  .isAfter(start.subtract(const Duration(seconds: 1))) &&
              targetDate.isBefore(end.add(const Duration(seconds: 1)));
        }).toList();
      }
      displayRecords.sort((a, b) {
        final dateA = _dateField == FormIVDateField.incidentDate
            ? a.incidentDate
            : a.createdAt;
        final dateB = _dateField == FormIVDateField.incidentDate
            ? b.incidentDate
            : b.createdAt;
        return _dateSortOrder == FormIVDateSortOrder.newestFirst
            ? dateB.compareTo(dateA)
            : dateA.compareTo(dateB);
      });
    }

    // Important: keep this so stats match filtered date range
    if (isTheftOrFormIVStyle && _selectedDateRange != null) {
      totalCount = displayRecords.length;
      disposalCount = widget.moduleKey == 'absconded'
          ? displayRecords.where((r) => isAbscondedDisposal(r)).length
          : displayRecords.where(isRecordDisposal).length;
      pendingCount = totalCount - disposalCount;
    }

    final bool showAddButton = !(widget.readOnly ||
        widget.moduleKey == 'detected' ||
        widget.moduleKey == 'undetected' ||
        widget.moduleKey == 'disposal');

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: _buildAppBar(context, totalCount),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.moduleKey != 'form_1_5' &&
              widget.moduleKey != 'disposal' &&
              widget.moduleKey != 'monthly' &&
              widget.moduleKey != 'sam_warrant' &&
              widget.moduleKey != 'pending')
            _buildStatsRow(totalCount, disposalCount, pendingCount),
          if (isTheftOrFormIVStyle) _buildToolbar(displayRecords.length),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                if (widget.moduleKey == 'monthly') ...[
                  // Monthly module is report-only (no records section).
                  SliverToBoxAdapter(
                      child: _buildMonthlyReport(context, allRecords)),
                ] else if (widget.moduleKey == 'sam_warrant') ...[
                  // Sam/Warrant module is report-only (fetching dynamically from database).
                  SliverToBoxAdapter(
                      child: _buildSamWarrantModuleReportOnly(context)),
                ] else if (widget.moduleKey == 'pending') ...[
                  SliverToBoxAdapter(
                      child: _buildPendingModuleReportOnly(context)),
                ] else if (widget.moduleLabel == 'Forms' &&
                    widget.moduleKey == 'form_1_5') ...[
                  SliverToBoxAdapter(
                      child: _buildFormsModuleReportOnly(context)),
                ] else ...[
                  if (widget.moduleKey == 'disposal')
                    SliverToBoxAdapter(child: _buildModuleTabs()),
                  if (_isReportMode && widget.moduleKey == 'disposal')
                    SliverToBoxAdapter(
                        child: _buildMonthlyReport(context, allRecords))
                  else ...[
                    if (displayRecords.isEmpty)
                      SliverToBoxAdapter(
                        child: isTheftOrFormIVStyle
                            ? FormIVEmptyCasesState(
                                category: (widget.subCategory != null &&
                                        widget.subCategory!.isNotEmpty)
                                    ? widget.subCategory!
                                    : widget.moduleLabel,
                                readOnly: true,
                                statusTab: selectedTab,
                                onNewCase: null,
                                selectedDateRange: _selectedDateRange,
                                onClearDateFilter: () =>
                                    setState(() => _selectedDateRange = null),
                              )
                            : _buildEmpty(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _buildCard(ctx, displayRecords[i],
                                index: i + 1),
                            childCount: displayRecords.length,
                          ),
                        ),
                      ),
                  ],
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, int total) {
    final transTitle = TranslationHelper.translate(context, widget.moduleLabel);
    final recordWord = total == 1 ? 'record' : 'records';
    final transRecord = TranslationHelper.translate(context, recordWord);
    final transReg = TranslationHelper.translate(context, 'registered');

    final bool isTheftOrFormIVStyle = widget.moduleKey == 'theft' ||
        widget.moduleLabel == 'Theft' ||
        widget.moduleKey == 'sand_theft' ||
        widget.moduleKey == 'two_four_wheeler';

    final categoryName =
        (widget.subCategory != null && widget.subCategory!.isNotEmpty)
            ? TranslationHelper.translate(context, widget.subCategory!)
            : transTitle;
    final caseWord = total == 1 ? 'case' : 'cases';
    final transCase = TranslationHelper.translate(context, caseWord);
    final subtitle = isTheftOrFormIVStyle
        ? '$categoryName · $total $transCase'
        : (widget.moduleKey == 'sam_warrant'
            ? TranslationHelper.translate(context, 'Summons & Warrant Report')
            : '$total $transRecord $transReg');

    final bool showAddButton = !(widget.readOnly ||
        widget.moduleKey == 'detected' ||
        widget.moduleKey == 'undetected' ||
        widget.moduleKey == 'disposal');

    Widget? actionWidget;
    if (showAddButton) {
      actionWidget = ElevatedButton.icon(
        onPressed: () => _openNewEntryForm(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyMid,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: 16),
        label: Text(
          TranslationHelper.translate(context, 'Add Case'),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ModuleHubScreenAppBar(
      title: transTitle,
      subtitle: subtitle,
      actionWidget: actionWidget,
      backgroundColor: (widget.moduleKey == 'detected' ||
              widget.moduleKey == 'undetected' ||
              widget.moduleKey == 'disposal')
          ? AppColors.navyDark
          : null,
    );
  }

  Widget _buildModuleTabs() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
      child: Row(
        children: [
          _tabControl('Records', !_isReportMode,
              () => setState(() => _isReportMode = false)),
          const SizedBox(width: 12),
          _tabControl('Report', _isReportMode,
              () => setState(() => _isReportMode = true)),
        ],
      ),
    );
  }

  Widget _tabControl(String label, bool active, VoidCallback onTap) {
    const color = AppColors.navyMid;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? color : (Colors.white),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: active ? color : (AppColors.lightBorder)),
          ),
          child: Center(
            child: Text(TranslationHelper.translate(context, label),
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? Colors.white : (AppColors.lightSubText))),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyReport(BuildContext context, List<ModuleRecord> records) {
    // For the "Monthly" module, show report-only (no category record tiles),
    // matching the clean Monthly layout used in the Calendar screen.
    if (widget.moduleKey == 'monthly') {
      return _buildMonthlyModuleReportOnly(context, records);
    }

    // Show ALL cases regardless of status (open, pending, closed) or incident date
    final now = DateTime.now();
    final monthRecords = records;

    // Grouping by category with meta-info for navigation
    final Map<String, _CategoryMeta> catMeta = {};
    for (var r in monthRecords) {
      final label = r.firestoreCategoryDisplayName;
      final sub = r.subCategory;

      final key = '${r.moduleKey}_${sub ?? ""}';
      if (!catMeta.containsKey(key)) {
        catMeta[key] = _CategoryMeta(
            label: label, moduleKey: r.moduleKey, subCategory: sub, count: 0);
      }
      catMeta[key]!.count++;
      // Count solved: Resolved or Closed
      if (r.status == 'Resolved' || r.status == 'Closed') {
        catMeta[key]!.solvedCount++;
      }
    }

    // Sort alphabetically by label
    final sortedMetas = catMeta.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    // For the PDF helper, we still need Map<String, int>
    final Map<String, int> countsForPdf = {
      for (var m in sortedMetas) m.label: m.count
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Registration Summary',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark)),
                  Text(DateFormat('MMMM yyyy').format(now),
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.goldPrimary)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => ModulePdfHelper.generateSummaryReportPdf(
                  countsForPdf,
                  widget.moduleKey == 'disposal'
                      ? 'Monthly Disposal Report'
                      : widget.moduleKey == 'pending'
                          ? 'Pending Cases Report'
                          : 'Monthly Registration Report',
                  DateFormat('MMMM yyyy').format(now),
                ),
                icon: const Icon(Icons.assessment_outlined,
                    size: 16, color: Colors.white),
                label: Text('Summary',
                    style:
                        GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyMid,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (sortedMetas.isEmpty)
            _buildEmptyReport()
          else
            ...sortedMetas.map((meta) => _buildReportTile(
                    meta.label, meta.count, solvedCount: meta.solvedCount,
                    onTap: () {
                  Navigator.push(
                      context,
                      AppTheme.fadeSlideRoute(
                          page: ModuleHubScreen(
                        moduleLabel: meta.label,
                        moduleKey: meta.moduleKey,
                        subCategory: meta.subCategory,
                        readOnly: true,
                      )));
                })),
        ],
      ),
    );
  }

  String _pendingHubSubtitle(BuildContext context) {
    if (_pendingCategory == null) {
      return TranslationHelper.translate(context, 'Select a category');
    }
    final transCategory =
        TranslationHelper.translate(context, _pendingCategory!);
    if (_pendingTimeRange == null) {
      final transSelectTime =
          TranslationHelper.translate(context, 'Select time range');
      return '$transCategory — $transSelectTime';
    }
    final transTimeRange =
        TranslationHelper.translate(context, _pendingTimeRange!);
    return '$transCategory — $transTimeRange';
  }

  Widget _buildPendingModuleReportOnly(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return ModuleHubReportCard(
      title: TranslationHelper.translate(context, 'Pending Reports'),
      subtitle: _pendingHubSubtitle(context),
      showFilterRow: false,
      filterRow: const SizedBox.shrink(),
      onSummaryTap: () {
        Navigator.push(
          context,
          AppTheme.fadeSlideRoute(
            page: PendingSummaryScreen(stationName: auth.stationName),
          ),
        );
      },
      wrapCategoryButtonsInCard: false,
      categoryButtons: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: FutureBuilder<List<Map<String, dynamic>>?>(
          future: BackendCaseService().fetchPendingCases(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: AppColors.navyMid),
                ),
              );
            }

            final data = snapshot.data ?? [];
            final records = data.map((m) => ModuleRecord.fromMap(m)).toList();
            final mappedRows =
                pendingModuleRecordsToTableRows(records, DateTime.now());

            final Map<String, int> categoryCounts = {};
            for (final r in mappedRows) {
              final head = r['head']?.trim().isNotEmpty == true
                  ? r['head']!.trim()
                  : 'Other';
              categoryCounts[head] = (categoryCounts[head] ?? 0) + 1;
            }

            final categories = categoryCounts.keys.toList()..sort();

            if (categories.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    TranslationHelper.translate(
                        context, 'No pending categories found in database'),
                    style: GoogleFonts.poppins(
                      color: AppColors.lightSubText,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final bool isSmallScreen = constraints.maxWidth < 600;
                final double gap = isSmallScreen ? 12 : 16;
                final int columns = constraints.maxWidth > 1000
                    ? 4
                    : (constraints.maxWidth > 600 ? 3 : 2);
                double itemWidth =
                    (constraints.maxWidth - (gap * (columns - 1))) / columns;
                if (itemWidth < 0) itemWidth = 0;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  alignment: WrapAlignment.start,
                  children: categories.map((cat) {
                    final transCategory =
                        TranslationHelper.translate(context, cat);
                    final count = categoryCounts[cat] ?? 0;

                    return SizedBox(
                      width: itemWidth,
                      height: 64,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.grey.shade200, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navyDark.withValues(alpha: 0.04),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: PopupMenuButton<String>(
                            offset: const Offset(0, 68),
                            tooltip: transCategory,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: Colors.grey.shade200, width: 1),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 10 : 16),
                              child: Row(
                                children: [
                                  Container(
                                    padding:
                                        EdgeInsets.all(isSmallScreen ? 6 : 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.navyMid
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.folder_open_rounded,
                                      color: AppColors.navyMid,
                                      size: isSmallScreen ? 16 : 18,
                                    ),
                                  ),
                                  SizedBox(width: isSmallScreen ? 8 : 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          transCategory,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: isSmallScreen ? 12 : 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.navyDark,
                                            height: 1.2,
                                          ),
                                        ),
                                        Text(
                                          '$count ${count == 1 ? "case" : "cases"}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.lightSubText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: isSmallScreen ? 4 : 8),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.navyDark
                                        .withValues(alpha: 0.5),
                                    size: isSmallScreen ? 18 : 20,
                                  ),
                                ],
                              ),
                            ),
                            onSelected: (val) {
                              setState(() {
                                _pendingCategory = cat;
                              });
                              if (val == 'IO Wise') {
                                Navigator.push(
                                  context,
                                  AppTheme.fadeSlideRoute(
                                    page: PendingIoWiseByCategoryScreen(
                                        category: cat),
                                  ),
                                );
                              } else {
                                setState(() {
                                  _pendingTimeRange = val;
                                });
                                String? startDate;
                                String? endDate;
                                final now = DateTime.now();
                                if (val == 'More than 1 year') {
                                  endDate = DateFormat('yyyy-MM-dd').format(
                                      now.subtract(const Duration(days: 365)));
                                } else if (val == '6 to 12 months') {
                                  startDate = DateFormat('yyyy-MM-dd').format(
                                      now.subtract(const Duration(days: 365)));
                                  endDate = DateFormat('yyyy-MM-dd').format(
                                      now.subtract(const Duration(days: 180)));
                                } else if (val == '3 to 6 months') {
                                  startDate = DateFormat('yyyy-MM-dd').format(
                                      now.subtract(const Duration(days: 180)));
                                  endDate = DateFormat('yyyy-MM-dd').format(
                                      now.subtract(const Duration(days: 90)));
                                } else if (val == 'Within 3 months') {
                                  startDate = DateFormat('yyyy-MM-dd').format(
                                      now.subtract(const Duration(days: 90)));
                                  endDate =
                                      DateFormat('yyyy-MM-dd').format(now);
                                } else if (val == '1 month') {
                                  startDate = DateFormat('yyyy-MM-dd').format(
                                      now.subtract(const Duration(days: 30)));
                                  endDate =
                                      DateFormat('yyyy-MM-dd').format(now);
                                }
                                Navigator.push(
                                  context,
                                  AppTheme.fadeSlideRoute(
                                    page: FilteredPendingScreen(
                                      title: '$cat - $val',
                                      category: cat,
                                      startDate: startDate,
                                      endDate: endDate,
                                    ),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              final List<String> options = [
                                ..._pendingHubTimeRanges
                                    .where((t) => t != 'Select time range'),
                                'IO Wise',
                              ];
                              return options.map((String choice) {
                                return PopupMenuItem<String>(
                                  value: choice,
                                  child: Text(
                                    TranslationHelper.translate(
                                        context, choice),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ),
      child: null,
    );
  }

  Widget _buildFormsModuleReportOnly(BuildContext context) {
    void onFormSelect(FormsListEntry entry, {FormsSubSection? subSection}) {
      final subCategory = subSection?.subCategoryOverride ?? entry.subCategory;
      final moduleLabel = subSection != null
          ? (entry.title == subSection.label
              ? entry.title
              : '${entry.title} — ${subSection.label}')
          : entry.title;
      if (subSection == null) {
        debugPrint('Opened ${entry.title} (subCategory: $subCategory)');
      } else {
        debugPrint(
          'Opened ${entry.title} — ${subSection.label} '
          '(${subSection.pageRange}, subCategory: $subCategory)',
        );
      }
      final page = CommonFormScreen(
        moduleLabel: moduleLabel,
        moduleKey: 'form_1_5',
        subCategory: subCategory,
        formSection: subSection?.sectionId,
        pageRange: subSection?.pageRange,
      );
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(page: page),
      );
    }

    return ModuleHubReportCard(
      title: TranslationHelper.translate(context, 'Forms Categories'),
      subtitle:
          '${kFormsHierarchyMock.length} ${TranslationHelper.translate(context, 'form types')}',
      showSummaryButton: false,
      showFilterRow: false,
      filterRow: const SizedBox.shrink(),
      categoryButtons: FormsAccordionList(
        entries: kFormsHierarchyMock,
        onSelect: onFormSelect,
      ),
    );
  }

  Widget _buildMonthlyModuleReportOnly(
      BuildContext context, List<ModuleRecord> allRecords) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final transMonth =
        TranslationHelper.translate(context, months[_reportMonth - 1]);
    final monthYearLabel = '$transMonth $_reportYear';

    // Reuse the Calendar monthly table builder from dashboard (static helper).
    // We call into the same logic by generating a table locally and using the same PDF helper.
    // (intentionally unused) monthRecords was previously used for PDF export here.

    final monthDropdown = Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _reportMonth,
          isDense: true,
          menuMaxHeight: 260,
          borderRadius: BorderRadius.circular(10),
          alignment: AlignmentDirectional.centerStart,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: AppColors.navyMid),
          items: List.generate(
            12,
            (i) => DropdownMenuItem(
              value: i + 1,
              child: Text(
                TranslationHelper.translate(context, months[i]),
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          onChanged: (val) =>
              setState(() => _reportMonth = val ?? _reportMonth),
        ),
      ),
    );

    final yearDropdown = Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _reportYear,
          isDense: true,
          menuMaxHeight: 260,
          borderRadius: BorderRadius.circular(10),
          alignment: AlignmentDirectional.centerStart,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: AppColors.navyMid),
          items: List.generate(
            5,
            (i) => DropdownMenuItem(
              value: DateTime.now().year - i,
              child: Text(
                '${DateTime.now().year - i}',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          onChanged: (val) => setState(() => _reportYear = val ?? _reportYear),
        ),
      ),
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.lightBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row: Title/subtitle + Month/Year controls
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TranslationHelper.translate(
                              context, 'Monthly Reports'),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                          ),
                        ),
                        Text(
                          monthYearLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.goldPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        monthDropdown,
                        const SizedBox(width: 8),
                        yearDropdown,
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Dynamic Monthly Crime Comparative Table from database API
                MonthlyCrimeComparativeTable(
                  selectedYear: _reportYear,
                  selectedMonth: _reportMonth,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportTile(String category, int count,
      {int solvedCount = 0, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.lightBorder),
          boxShadow: [
            if (onTap != null)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(TranslationHelper.translate(context, category),
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightText)),
                  const SizedBox(width: 6),
                  if (onTap != null)
                    Icon(Icons.open_in_new_rounded,
                        size: 13,
                        color: (AppColors.navyMid).withValues(alpha: 0.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Total cases badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.goldPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                  '$count ${TranslationHelper.translate(context, count == 1 ? 'Case' : 'Cases')}',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.goldPrimary)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('|',
                  style: TextStyle(
                      color: Color(0xFFCCD0D5), fontWeight: FontWeight.w300)),
            ),
            // Solved badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$solvedCount Solved',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.successGreen)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSamWarrantModuleReportOnly(BuildContext context) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final transMonth =
        TranslationHelper.translate(context, months[_reportMonth - 1]);
    final monthYearLabel = '$transMonth $_reportYear';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.lightBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationHelper.translate(
                          context, 'Summons & Warrant Report'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                    Text(
                      monthYearLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Month/Year selector (compact)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _reportMonth,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.navyMid),
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(
                              TranslationHelper.translate(context, months[i]),
                              style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _reportMonth = v);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _reportYear,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColors.navyMid),
                      items: List.generate(
                        5,
                        (i) {
                          final y = DateTime.now().year - i;
                          return DropdownMenuItem(
                            value: y,
                            child: Text(
                              '$y',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _reportYear = v);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Dynamic Summons & Warrant Report Table from database API
            SummonsWarrantReportTable(
              selectedYear: _reportYear,
              selectedMonth: _reportMonth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReport() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.analytics_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No cases registered this month',
                style: GoogleFonts.poppins(color: AppColors.lightSubText)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(int total, int disposal, int pending) {
    FormIVStatusTab selectedTab;
    if (_filter == CaseStatus.pending) {
      selectedTab = FormIVStatusTab.pending;
    } else if (_filter == CaseStatus.disposal) {
      selectedTab = FormIVStatusTab.disposal;
    } else {
      selectedTab = FormIVStatusTab.total;
    }

    return FormIVStatusTabBar(
      selectedTab: selectedTab,
      totalCount: total,
      pendingCount: pending,
      disposalCount: disposal,
      onTabChanged: (tab) {
        setState(() {
          switch (tab) {
            case FormIVStatusTab.total:
              _filter = 'All';
              break;
            case FormIVStatusTab.pending:
              _filter = CaseStatus.pending;
              break;
            case FormIVStatusTab.disposal:
              _filter = CaseStatus.disposal;
              break;
          }
        });
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.lightBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.navyMid.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_special_rounded,
                size: 40,
                color: AppColors.navyMid,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${TranslationHelper.translate(context, 'No')} ${TranslationHelper.translate(context, widget.moduleLabel)} ${TranslationHelper.translate(context, 'records yet')}',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              TranslationHelper.translate(
                  context, 'No registered entries found in this category.'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.lightSubText,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext ctx, ModuleRecord record, {int? index}) {
    if (widget.moduleKey == 'theft' ||
        widget.moduleLabel == 'Theft' ||
        widget.moduleKey == 'sand_theft' ||
        widget.moduleKey == 'two_four_wheeler') {
      return _buildCompactCaseCard(ctx, record);
    }
    if (widget.readOnly) {
      return ReadOnlyModuleRecordHubCard(record: record);
    }
    if (widget.moduleKey == 'preventive' || record.moduleKey == 'preventive') {
      return _PreventiveModuleCaseCard(
        record: record,
        subCategory: widget.subCategory,
        readOnly: widget.readOnly,
        onDelete: () => _confirmDelete(ctx, record),
        index: index,
      );
    }
    final isDetailFormHistory = record.subCategory == 'Crime Detail Form' ||
        record.subCategory == 'Property & Seizure Form';
    if (isDetailFormHistory) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.lightBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      record.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 13, color: AppColors.lightSubText),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy').format(record.incidentDate),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.lightSubText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: AppColors.lightSubText),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('hh:mm a').format(record.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.lightSubText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: AppColors.lightBorder),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _actionBtn(
                      Icons.visibility_rounded,
                      'View',
                      AppColors.goldPrimary,
                      () {
                        final isLinked = isTabLinkedToCommonFormBaseline(
                          moduleKey: widget.moduleKey,
                          categoryName: record.subCategory,
                        );
                        final page = isLinked
                            ? CommonFormScreen(
                                moduleLabel:
                                    record.firestoreCategoryDisplayName,
                                moduleKey: widget.moduleKey,
                                subCategory: record.subCategory,
                                existingRecord: record,
                                readOnly: true,
                              )
                            : DynamicFormScreen(
                                moduleLabel:
                                    record.firestoreCategoryDisplayName,
                                moduleKey: widget.moduleKey,
                                subCategory: record.subCategory,
                                existingRecord: record,
                                readOnly: true,
                              );
                        Navigator.push(
                          ctx,
                          AppTheme.fadeSlideRoute(page: page),
                        );
                      },
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: AppColors.lightBorder,
                    ),
                    _actionBtn(
                      Icons.picture_as_pdf_rounded,
                      'PDF',
                      AppColors.dangerRed,
                      () {
                        ModulePdfHelper.generatePdf(record, ctx);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    final isDetectedCard = widget.moduleKey == 'detected' ||
        record.moduleKey == 'detected' ||
        widget.moduleKey == 'undetected' ||
        record.moduleKey == 'undetected';
    final isThreeStatusModule = isDetectedCard ||
        widget.moduleKey == 'mpda' ||
        record.moduleKey == 'mpda';
    final String displayStatus;
    final Color sc;
    if (isThreeStatusModule) {
      final isDisposal = isRecordDisposal(record);
      displayStatus = isDisposal ? CaseStatus.disposal : CaseStatus.pending;
      sc = isDisposal ? AppColors.successGreen : AppColors.warningOrange;
    } else {
      displayStatus = record.status;
      sc = _statusColor(record.status);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: isDetectedCard
              ? BoxDecoration(
                  color: AppColors.navyDark.withValues(alpha: 0.06),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg)),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.infoBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(record.caseNumber,
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.infoBlue)),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sc.withValues(alpha: 0.3)),
                  ),
                  child: Text(displayStatus,
                      style: GoogleFonts.poppins(
                          fontSize: 9, fontWeight: FontWeight.w700, color: sc)),
                ),
              ]),
              const SizedBox(height: 10),
              Text(record.title,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark)),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  record.firestoreCategoryDisplayName,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (record.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(record.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.lightSubText)),
              ],
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.person_rounded,
                    size: 13, color: AppColors.lightSubText),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(record.assignedOfficer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.lightSubText)),
                ),
                const Icon(Icons.calendar_today_rounded,
                    size: 13, color: AppColors.lightSubText),
                const SizedBox(width: 4),
                Text(DateFormat('dd MMM yyyy').format(record.incidentDate),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.lightSubText)),
              ]),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.lightBorder),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _actionBtn(Icons.edit_note_rounded, 'Edit', AppColors.infoBlue, () {
              if (widget.moduleKey == 'ad') {
                Navigator.push(
                  ctx,
                  AppTheme.fadeSlideRoute(
                    page: ADFormScreen(existingRecord: record),
                  ),
                );
                return;
              }
              if (widget.moduleKey == 'nc') {
                Navigator.push(
                  ctx,
                  AppTheme.fadeSlideRoute(
                    page: NcFormScreen(
                      moduleLabel: record.firestoreCategoryDisplayName,
                      subCategory: widget.subCategory,
                      existingRecord: record,
                    ),
                  ),
                );
                return;
              }
              if (widget.moduleKey == 'missing') {
                Navigator.push(
                  ctx,
                  AppTheme.fadeSlideRoute(
                    page: MissingFormScreen(
                      moduleLabel: record.firestoreCategoryDisplayName,
                      subCategory: widget.subCategory,
                      existingRecord: record,
                    ),
                  ),
                );
                return;
              }
              if (widget.moduleKey == 'preventive' ||
                  record.moduleKey == 'preventive') {
                Navigator.push(
                  ctx,
                  AppTheme.fadeSlideRoute(
                    page: PreventiveFormScreen(
                      moduleLabel: record.firestoreCategoryDisplayName,
                      subCategory: widget.subCategory,
                      existingRecord: record,
                    ),
                  ),
                );
                return;
              }
              if (widget.moduleKey == 'mpda' || record.moduleKey == 'mpda') {
                Navigator.push(
                  ctx,
                  AppTheme.fadeSlideRoute(
                    page: MpdaFormScreen(
                      moduleLabel: record.firestoreCategoryDisplayName,
                      subCategory: widget.subCategory,
                      existingRecord: record,
                    ),
                  ),
                );
                return;
              }
              final page = moduleUsesCommonCrimeForm(widget.moduleKey,
                      record.subCategory ?? record.firestoreCategoryDisplayName)
                  ? CommonFormScreen(
                      moduleLabel: record.firestoreCategoryDisplayName,
                      moduleKey: widget.moduleKey,
                      subCategory: record.subCategory,
                      existingRecord: record,
                    )
                  : ModuleFormScreen(
                      moduleLabel: record.firestoreCategoryDisplayName,
                      moduleKey: widget.moduleKey,
                      subCategory: record.subCategory,
                      existingRecord: record,
                    );
              Navigator.push(ctx, AppTheme.fadeSlideRoute(page: page));
            }),
            Container(width: 1, height: 24, color: AppColors.lightBorder),
            _actionBtn(Icons.picture_as_pdf_rounded, 'PDF', AppColors.dangerRed,
                () {
              ModulePdfHelper.generatePdf(record, ctx);
            }),
            Container(width: 1, height: 24, color: AppColors.lightBorder),
            _actionBtn(Icons.visibility_rounded, 'View', AppColors.goldPrimary,
                () {
              Navigator.push(
                  ctx,
                  AppTheme.fadeSlideRoute(
                    page: widget.moduleKey == 'ad'
                        ? AdRecordDetailScreen(
                            record: record,
                          )
                        : ModuleRecordDetailScreen(
                            record: record,
                          ),
                  ));
            }),
            Container(width: 1, height: 24, color: AppColors.lightBorder),
            _actionBtn(
                Icons.delete_outline_rounded, 'Delete', AppColors.warningOrange,
                () {
              _confirmDelete(ctx, record);
            }),
          ]),
        ),
      ]),
    );
  }

  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            ),
          ]),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, ModuleRecord record) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('Delete Record',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: AppColors.dangerRed)),
        content: Text('Delete "${record.title}"? This cannot be undone.',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final provider = record.moduleKey == 'form_1_5'
                    ? ctx.read<FormIVProvider>()
                    : _readProvider(ctx);
                await provider.deleteRecord(record.id);
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text('Record deleted', style: GoogleFonts.poppins()),
                  backgroundColor: AppColors.successGreen,
                ));
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text('Failed to delete record: $e',
                      style: GoogleFonts.poppins()),
                  backgroundColor: AppColors.dangerRed,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _handleEdit(BuildContext ctx, ModuleRecord record) {
    if (widget.moduleKey == 'ad') {
      Navigator.push(
        ctx,
        AppTheme.fadeSlideRoute(
          page: ADFormScreen(existingRecord: record),
        ),
      );
      return;
    }
    if (widget.moduleKey == 'nc') {
      Navigator.push(
        ctx,
        AppTheme.fadeSlideRoute(
          page: NcFormScreen(
            moduleLabel: record.firestoreCategoryDisplayName,
            subCategory: widget.subCategory,
            existingRecord: record,
          ),
        ),
      );
      return;
    }
    if (widget.moduleKey == 'missing') {
      Navigator.push(
        ctx,
        AppTheme.fadeSlideRoute(
          page: MissingFormScreen(
            moduleLabel: record.firestoreCategoryDisplayName,
            subCategory: widget.subCategory,
            existingRecord: record,
          ),
        ),
      );
      return;
    }
    if (widget.moduleKey == 'preventive' || record.moduleKey == 'preventive') {
      Navigator.push(
        ctx,
        AppTheme.fadeSlideRoute(
          page: PreventiveFormScreen(
            moduleLabel: record.firestoreCategoryDisplayName,
            subCategory: widget.subCategory,
            existingRecord: record,
          ),
        ),
      );
      return;
    }
    if (widget.moduleKey == 'mpda' || record.moduleKey == 'mpda') {
      Navigator.push(
        ctx,
        AppTheme.fadeSlideRoute(
          page: MpdaFormScreen(
            moduleLabel: record.firestoreCategoryDisplayName,
            subCategory: widget.subCategory,
            existingRecord: record,
          ),
        ),
      );
      return;
    }
    final page = moduleUsesCommonCrimeForm(widget.moduleKey)
        ? CommonFormScreen(
            moduleLabel: record.firestoreCategoryDisplayName,
            moduleKey: widget.moduleKey,
            subCategory: record.subCategory,
            existingRecord: record,
          )
        : ModuleFormScreen(
            moduleLabel: record.firestoreCategoryDisplayName,
            moduleKey: widget.moduleKey,
            subCategory: record.subCategory,
            existingRecord: record,
          );
    Navigator.push(ctx, AppTheme.fadeSlideRoute(page: page));
  }

  void _handleView(BuildContext ctx, ModuleRecord record) {
    Navigator.push(
      ctx,
      AppTheme.fadeSlideRoute(
        page: widget.moduleKey == 'ad'
            ? AdRecordDetailScreen(record: record)
            : ModuleRecordDetailScreen(record: record),
      ),
    );
  }

  void _handlePdf(BuildContext ctx, ModuleRecord record) {
    runWithPdfAuthGate(
      ctx,
      () => ModulePdfHelper.generatePdf(record, ctx),
    );
  }

  Map<String, dynamic> _getDoc(ModuleRecord record) {
    if (record.extraFields[kCommonFormExtraFieldsKey] is Map) {
      return Map<String, dynamic>.from(
        record.extraFields[kCommonFormExtraFieldsKey] as Map,
      );
    }
    return record.extraFields;
  }

  String _getCrNo(ModuleRecord record, Map<String, dynamic> doc) {
    if (record.caseNumber.trim().isNotEmpty) {
      final s = record.caseNumber.trim();
      return s.startsWith('CR ') ? s.substring(3).trim() : s;
    }
    final cr = doc['crNo']?.toString().trim();
    if (cr != null && cr.isNotEmpty) {
      return cr.startsWith('CR ') ? cr.substring(3).trim() : cr;
    }
    final parts = record.title.split('—');
    if (parts.length > 1 && parts.last.trim().isNotEmpty) {
      final s = parts.last.trim();
      return s.startsWith('CR ') ? s.substring(3).trim() : s;
    }
    return record.title.isNotEmpty ? record.title : '—';
  }

  String _getSectionAct(ModuleRecord record, Map<String, dynamic> doc) {
    final charges = doc['charges'] ?? record.extraFields['charges'];
    if (charges is Map && charges.isNotEmpty) {
      final parts = <String>[];
      for (final val in charges.values) {
        if (val is Map) {
          final act = val['act']?.toString().trim() ?? '';
          final sections = val['sections'];
          String secStr = '';
          if (sections is List && sections.isNotEmpty) {
            secStr = sections
                .map((s) => s.toString().trim())
                .where((s) => s.isNotEmpty && s != '{}' && s != '[]')
                .join(', ');
          }
          if (secStr.isNotEmpty && act.isNotEmpty) {
            parts.add('$act $secStr');
          } else if (secStr.isNotEmpty) {
            parts.add(secStr);
          } else if (act.isNotEmpty) {
            parts.add(act);
          }
        } else if (val is String) {
          final s = val.trim();
          if (s.isNotEmpty && s != '{}' && s != '[]') {
            parts.add(s);
          }
        }
      }
      if (parts.isNotEmpty) {
        return parts.join(' | ');
      }
    }

    for (final key in [
      'bnsSection',
      'kalam',
      'sections',
      'act',
      'ipc_sections',
      'section',
    ]) {
      final val = doc[key] ?? record.extraFields[key];
      if (val != null) {
        final s = val.toString().trim();
        if (s.isNotEmpty && s != '{}' && s != '[]') {
          return s;
        }
      }
    }

    return '—';
  }

  String _getNameOfAccused(ModuleRecord record, Map<String, dynamic> doc) {
    if (record.accused.trim().isNotEmpty) {
      return record.accused.trim();
    }
    if (doc['isUnknownUntraced'] == true) {
      return 'Unknown / Untraced';
    }

    final names = <String>{};
    if (doc['allAccusedNames'] is List) {
      for (final n in doc['allAccusedNames']) {
        if (n is String && n.trim().isNotEmpty) names.add(n.trim());
      }
    }

    void addFromList(dynamic list, String key) {
      if (list is List) {
        for (final item in list) {
          if (item is Map && item[key] != null) {
            final n = item[key].toString().trim();
            if (n.isNotEmpty) names.add(n);
          }
        }
      }
    }

    addFromList(doc['accused'], 'name');
    addFromList(doc['suspectedAccused'], 'name');
    addFromList(doc['arrestRelease'], 'accusedName');

    if (names.isNotEmpty) return names.join(', ');

    for (final key in [
      'accusedName',
      'm1AccusedName',
      'm_accusedName',
      'eArrestedName',
      'accusedNameAddress',
    ]) {
      final val = doc[key] ?? record.extraFields[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return '—';
  }

  String _getCrimeDate(ModuleRecord record, Map<String, dynamic> doc) {
    final regDate = doc['regDate']?.toString().trim();
    if (regDate != null && regDate.isNotEmpty) {
      return regDate;
    }
    try {
      return DateFormat('dd/MM/yyyy').format(record.incidentDate);
    } catch (_) {
      return DateFormat('dd MMM yyyy').format(record.incidentDate);
    }
  }

  Widget _buildCompactCaseCard(BuildContext ctx, ModuleRecord record) {
    final doc = _getDoc(record);
    final crNo = _getCrNo(record, doc);
    final sectionAct = _getSectionAct(record, doc);
    final accusedName = _getNameOfAccused(record, doc);
    final crimeDate = _getCrimeDate(record, doc);

    final isDisposal = isRecordDisposal(record);
    final displayStatus = isDisposal ? CaseStatus.disposal : CaseStatus.pending;
    final statusColor =
        isDisposal ? AppColors.successGreen : AppColors.warningOrange;

    final categoryLabel = record.subCategory?.trim().isNotEmpty == true
        ? TranslationHelper.translate(ctx, record.subCategory!.trim())
        : TranslationHelper.translate(ctx, record.firestoreCategoryDisplayName);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 820;
                if (!isWide) {
                  return _buildCompactMobileCardContent(
                    ctx: ctx,
                    crNo: crNo,
                    categoryLabel: categoryLabel,
                    sectionAct: sectionAct,
                    accusedName: accusedName,
                    crimeDate: crimeDate,
                    statusColor: statusColor,
                    displayStatus: displayStatus,
                    record: record,
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. CR No. Pill
                    SizedBox(
                      width: 82,
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CR ',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                crNo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (categoryLabel.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 86,
                        child: Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: AppColors.goldPrimary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.goldPrimary.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            categoryLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.goldPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Vertical Divider
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 18,
                      color: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 8),

                    // 2. Section / Act
                    SizedBox(
                      width: 140,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.gavel_rounded,
                            size: 13,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sec: ',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Expanded(
                            child: Tooltip(
                              message: sectionAct,
                              child: Text(
                                sectionAct,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Vertical Divider
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 18,
                      color: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 8),

                    // 3. Name of Accused
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Accused: ',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Expanded(
                            child: Tooltip(
                              message: accusedName,
                              child: Text(
                                accusedName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Vertical Divider
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 18,
                      color: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 8),

                    // 4. Crime Date
                    SizedBox(
                      width: 106,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12.5,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              crimeDate,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Vertical Divider
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 18,
                      color: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 8),

                    // 5. Status Badge
                    Container(
                      width: 74,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        TranslationHelper.translate(context, displayStatus),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 6. Action Buttons: Edit, View, PDF, Delete
                    if (!widget.readOnly) ...[
                      _buildCompactIconBtn(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        onTap: () => _handleEdit(ctx, record),
                      ),
                      const SizedBox(width: 6),
                    ],
                    _buildCompactIconBtn(
                      icon: Icons.visibility_outlined,
                      label: 'View',
                      onTap: () => _handleView(ctx, record),
                    ),
                    const SizedBox(width: 6),
                    _buildCompactIconBtn(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'PDF',
                      onTap: () => _handlePdf(ctx, record),
                    ),
                    if (!widget.readOnly) ...[
                      const SizedBox(width: 6),
                      _buildCompactIconBtn(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        onTap: () => _confirmDelete(ctx, record),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactIconBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final fg = color ?? const Color(0xFF1E293B);
    return Tooltip(
      message: TranslationHelper.translate(context, label),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 28,
          width: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 15, color: fg),
        ),
      ),
    );
  }

  Widget _buildCompactMobileCardContent({
    required BuildContext ctx,
    required String crNo,
    required String categoryLabel,
    required String sectionAct,
    required String accusedName,
    required String crimeDate,
    required Color statusColor,
    required String displayStatus,
    required ModuleRecord record,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CR ',
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    crNo,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            if (categoryLabel.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  categoryLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldPrimary,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                TranslationHelper.translate(ctx, displayStatus),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Sec: $sectionAct',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Accused: $accusedName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              crimeDate,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!widget.readOnly) ...[
              _buildCompactIconBtn(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () => _handleEdit(ctx, record),
              ),
              const SizedBox(width: 6),
            ],
            _buildCompactIconBtn(
              icon: Icons.visibility_outlined,
              label: 'View',
              onTap: () => _handleView(ctx, record),
            ),
            const SizedBox(width: 6),
            _buildCompactIconBtn(
              icon: Icons.picture_as_pdf_outlined,
              label: 'PDF',
              onTap: () => _handlePdf(ctx, record),
            ),
            if (!widget.readOnly) ...[
              const SizedBox(width: 6),
              _buildCompactIconBtn(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                onTap: () => _confirmDelete(ctx, record),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildToolbar(int count) {
    final hasDateFilter = _selectedDateRange != null;
    final dateText = hasDateFilter
        ? '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}'
        : TranslationHelper.translate(context, 'Date Filter');

    final categoryName =
        (widget.subCategory != null && widget.subCategory!.isNotEmpty)
            ? widget.subCategory!
            : widget.moduleLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Categories back button
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_back_rounded,
                        size: 14,
                        color: AppColors.navyDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        TranslationHelper.translate(context, 'Categories'),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Breadcrumb: Theft / <category> <count badge>
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TranslationHelper.translate(context, widget.moduleLabel),
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1976D2),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '/',
                      style: GoogleFonts.poppins(
                        color: AppColors.lightSubText,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    TranslationHelper.translate(context, categoryName),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FC),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Date Filter & Sort Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Calendar Date Picker Button
              InkWell(
                onTap: _pickDateRange,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    hasDateFilter ? 8 : 10,
                    6,
                    hasDateFilter ? 4 : 10,
                    6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        hasDateFilter ? const Color(0xFFE8F1FC) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasDateFilter
                          ? const Color(0xFF1976D2)
                          : const Color(0xFFCBD5E1),
                      width: hasDateFilter ? 1.3 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: hasDateFilter
                            ? const Color(0xFF1976D2).withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 15,
                        color: hasDateFilter
                            ? const Color(0xFF1976D2)
                            : AppColors.navyMid,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateText,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight:
                              hasDateFilter ? FontWeight.w600 : FontWeight.w500,
                          color: hasDateFilter
                              ? const Color(0xFF1976D2)
                              : AppColors.navyDark,
                        ),
                      ),
                      if (hasDateFilter) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () =>
                              setState(() => _selectedDateRange = null),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Sort Popup
              PopupMenuButton<String>(
                tooltip: TranslationHelper.translate(context, 'Sort by Date'),
                onSelected: (val) {
                  setState(() {
                    switch (val) {
                      case 'newest_incident':
                        _dateField = FormIVDateField.incidentDate;
                        _dateSortOrder = FormIVDateSortOrder.newestFirst;
                        break;
                      case 'oldest_incident':
                        _dateField = FormIVDateField.incidentDate;
                        _dateSortOrder = FormIVDateSortOrder.oldestFirst;
                        break;
                      case 'newest_created':
                        _dateField = FormIVDateField.createdAt;
                        _dateSortOrder = FormIVDateSortOrder.newestFirst;
                        break;
                      case 'oldest_created':
                        _dateField = FormIVDateField.createdAt;
                        _dateSortOrder = FormIVDateSortOrder.oldestFirst;
                        break;
                    }
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'newest_incident',
                    child: Row(
                      children: [
                        Icon(
                          _dateField == FormIVDateField.incidentDate &&
                                  _dateSortOrder ==
                                      FormIVDateSortOrder.newestFirst
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: const Color(0xFF1976D2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Incident Date (Newest first)',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'oldest_incident',
                    child: Row(
                      children: [
                        Icon(
                          _dateField == FormIVDateField.incidentDate &&
                                  _dateSortOrder ==
                                      FormIVDateSortOrder.oldestFirst
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: const Color(0xFF1976D2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Incident Date (Oldest first)',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'newest_created',
                    child: Row(
                      children: [
                        Icon(
                          _dateField == FormIVDateField.createdAt &&
                                  _dateSortOrder ==
                                      FormIVDateSortOrder.newestFirst
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: const Color(0xFF1976D2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Filing Date (Newest first)',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'oldest_created',
                    child: Row(
                      children: [
                        Icon(
                          _dateField == FormIVDateField.createdAt &&
                                  _dateSortOrder ==
                                      FormIVDateSortOrder.oldestFirst
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: const Color(0xFF1976D2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Filing Date (Oldest first)',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _dateSortOrder == FormIVDateSortOrder.newestFirst
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 14,
                        color: AppColors.navyMid,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _dateSortOrder == FormIVDateSortOrder.newestFirst
                            ? TranslationHelper.translate(context, 'Newest')
                            : TranslationHelper.translate(context, 'Oldest'),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 18,
                        color: AppColors.navyDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF1976D2),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Open':
        return AppColors.warningOrange;
      case 'Active':
        return AppColors.infoBlue;
      case 'Resolved':
        return AppColors.successGreen;
      case 'Closed':
        return const Color(0xFF607D8B);
      default:
        return AppColors.lightSubText;
    }
  }
}

/// Dedicated Horizontal Single-Row Case Card for Preventive Module
/// Matching Form I-V layout with 8 horizontal fields & labeled action buttons
class _PreventiveModuleCaseCard extends StatelessWidget {
  final ModuleRecord record;
  final String? subCategory;
  final bool readOnly;
  final VoidCallback? onDelete;
  final int? index;

  const _PreventiveModuleCaseCard({
    required this.record,
    this.subCategory,
    required this.readOnly,
    this.onDelete,
    this.index,
  });

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

  @override
  Widget build(BuildContext context) {
    final extra = Map<String, dynamic>.from(record.extraFields);
    final prevMap = extra[kPreventiveFormExtraFieldsKey] is Map
        ? Map<String, dynamic>.from(extra[kPreventiveFormExtraFieldsKey] as Map)
        : extra;

    final caseRef = prevMap['caseRef'] is Map
        ? Map<String, dynamic>.from(prevMap['caseRef'] as Map)
        : <String, dynamic>{};
    final sections = prevMap['sections'] is Map
        ? Map<String, dynamic>.from(prevMap['sections'] as Map)
        : <String, dynamic>{};
    final accusedList = prevMap['accusedList'] is List
        ? (prevMap['accusedList'] as List)
        : <dynamic>[];
    final istegasha = prevMap['istegasha'] is Map
        ? Map<String, dynamic>.from(prevMap['istegasha'] as Map)
        : <String, dynamic>{};

    // 1. SR. CR. No.
    String crNo =
        (caseRef['crimeNo'] ?? prevMap['crimeNo'] ?? record.caseNumber)
            .toString()
            .trim();
    if (crNo.isEmpty) crNo = record.id;

    // 2. Crime Category
    String categoryLabel = (caseRef['crimeCategory'] ??
            caseRef['category'] ??
            prevMap['crimeCategory'] ??
            prevMap['category'] ??
            record.extraFields['crimeCategory'] ??
            record.extraFields['category'] ??
            '')
        .toString()
        .trim();
    if (categoryLabel.isEmpty || categoryLabel.toLowerCase() == 'preventive') {
      final fallback = (record.extraFields['crimeCategory'] ??
              record.extraFields['category'] ??
              '')
          .toString()
          .trim();
      if (fallback.isNotEmpty && fallback.toLowerCase() != 'preventive') {
        categoryLabel = fallback;
      } else if (record.firestoreCategoryDisplayName.isNotEmpty &&
          record.firestoreCategoryDisplayName.toLowerCase() != 'preventive') {
        categoryLabel = record.firestoreCategoryDisplayName;
      } else {
        categoryLabel = 'Theft';
      }
    }

    // 3. Sec. Act
    String sectionAct = '';
    final secList = sections['selectedSections'] is List
        ? (sections['selectedSections'] as List).join(', ')
        : (sections['selectedSections']?.toString() ?? '');
    final act = (sections['act'] ?? prevMap['act'] ?? '').toString().trim();
    if (secList.isNotEmpty && act.isNotEmpty) {
      sectionAct = '$secList $act';
    } else if (secList.isNotEmpty) {
      sectionAct = secList;
    } else if (act.isNotEmpty) {
      sectionAct = act;
    } else if (record.description.trim().isNotEmpty) {
      sectionAct = record.description.trim();
    } else if (sections['ipcSections'] != null &&
        sections['ipcSections'].toString().trim().isNotEmpty) {
      sectionAct = '$secList $act';
    } else if (sections['otherSections'] != null &&
        sections['otherSections'].toString().trim().isNotEmpty) {
      sectionAct = sections['otherSections'].toString().trim();
    } else if (prevMap['otherSections'] != null &&
        prevMap['otherSections'].toString().trim().isNotEmpty) {
      sectionAct = prevMap['otherSections'].toString().trim();
    } else {
      sectionAct = '—';
    }

    // 4. Accused Name
    String accusedName = record.accused.trim();
    if (accusedName.isEmpty) {
      final rawAccused = prevMap['accusedNames'] ?? prevMap['accused'];
      if (rawAccused != null && rawAccused.toString().trim().isNotEmpty) {
        accusedName = rawAccused.toString().trim();
      } else if (accusedList.isNotEmpty) {
        final names = accusedList
            .map((a) => a is Map ? (a['name']?.toString() ?? '') : a.toString())
            .where((n) => n.trim().isNotEmpty)
            .toList();
        if (names.isNotEmpty) {
          accusedName = names.join(', ');
        }
      }
    }
    if (accusedName.isEmpty) accusedName = '—';

    // 5. Arrest Date
    String arrestDate = '';
    final regDate = caseRef['regDate'] ?? prevMap['regDate'];
    if (regDate != null && regDate.toString().trim().isNotEmpty) {
      arrestDate = regDate.toString().trim();
    } else if (accusedList.isNotEmpty &&
        accusedList.first is Map &&
        accusedList.first['arrestDate'] != null &&
        accusedList.first['arrestDate'].toString().trim().isNotEmpty) {
      arrestDate = accusedList.first['arrestDate'].toString().trim();
    } else {
      arrestDate = DateFormat('dd/MM/yyyy').format(record.incidentDate);
    }

    // 6. Preventive Sec. Act
    String prevSecAct = '';
    final prevAct = istegasha['preventiveSectionAct'] ??
        prevMap['preventiveSectionAct'] ??
        record.extraFields['preventiveSectionAct'] ??
        record.extraFields['preventiveSecAct'] ??
        istegasha['act'] ??
        prevMap['preventiveAct'] ??
        prevMap['preventiveSecAct'] ??
        prevMap['act'];
    if (prevAct != null && prevAct.toString().trim().isNotEmpty) {
      prevSecAct = prevAct.toString().trim();
    } else {
      prevSecAct = '107 Crpc/126 BNSS';
    }

    // 7. Preventive No.
    String prevNo = (istegasha['preventiveNo'] ??
            prevMap['preventiveNo'] ??
            record.extraFields['preventiveNo'] ??
            '')
        .toString()
        .trim();
    if (prevNo.isEmpty) prevNo = '—';

    // 8. IO Name
    String ioName = (istegasha['ioName'] ??
            prevMap['ioName'] ??
            prevMap['assignedOfficer'] ??
            record.assignedOfficer)
        .toString()
        .trim();
    if (ioName.isEmpty) ioName = '—';

    // Status Color (Disposal = Green, Pending/Other = Red)
    final isDisposal = record.status == 'Disposal' ||
        record.status == 'Closed' ||
        record.status == 'Resolved' ||
        record.status.toLowerCase().contains('completed');
    final Color statusColor =
        isDisposal ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
    final Color statusBg =
        isDisposal ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final Color statusBorder =
        isDisposal ? const Color(0xFFA5D6A7) : const Color(0xFFFFCDD2);

    Widget buildRowContent(bool isExpandedMode) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 0. Sr. No. (Badge colored by case status: Red for Pending, Green for Disposal)
          if (index != null) ...[
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
          ],

          // 1. CR No. (Badge)
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                Text(
                  'CR No.',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  crNo,
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

          // 2. Crime Category (Badge)
          if (categoryLabel.isNotEmpty) ...[
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
                    'Crime Category',
                    style: GoogleFonts.poppins(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    categoryLabel,
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
          ],

          // Vertical Divider
          _buildDivider(),

          // 3. Section & Act
          isExpandedMode
              ? Expanded(
                  flex: 4,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Section & Act',
                    value: sectionAct,
                    icon: Icons.gavel_rounded,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  label: 'Section & Act',
                  value: sectionAct,
                  icon: Icons.gavel_rounded,
                ),

          // Vertical Divider
          _buildDivider(),

          // 4. Accused Name
          isExpandedMode
              ? Expanded(
                  flex: 4,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Accused Name',
                    value: accusedName,
                    icon: Icons.person_outline_rounded,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  label: 'Accused Name',
                  value: accusedName,
                  icon: Icons.person_outline_rounded,
                ),

          // Vertical Divider
          _buildDivider(),

          // 5. Arrest Date
          isExpandedMode
              ? Expanded(
                  flex: 3,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Arrest Date',
                    value: arrestDate,
                    icon: Icons.calendar_today_outlined,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  label: 'Arrest Date',
                  value: arrestDate,
                  icon: Icons.calendar_today_outlined,
                ),

          // Vertical Divider
          _buildDivider(),

          // 6. Preventive Section Act
          isExpandedMode
              ? Expanded(
                  flex: 5,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Preventive Section Act',
                    value: prevSecAct,
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF0EA5E9),
                    valueColor: const Color(0xFF0284C7),
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  label: 'Preventive Section Act',
                  value: prevSecAct,
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFF0EA5E9),
                  valueColor: const Color(0xFF0284C7),
                ),

          // Vertical Divider
          _buildDivider(),

          // 7. Preventive No.
          isExpandedMode
              ? Expanded(
                  flex: 3,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Preventive No.',
                    value: prevNo,
                    icon: Icons.tag_rounded,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  label: 'Preventive No.',
                  value: prevNo,
                  icon: Icons.tag_rounded,
                ),

          // Vertical Divider
          _buildDivider(),

          // 8. IO Name
          isExpandedMode
              ? Expanded(
                  flex: 4,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Investigating Officer',
                    value: ioName,
                    icon: Icons.badge_outlined,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  label: 'Investigating Officer',
                  value: ioName,
                  icon: Icons.badge_outlined,
                ),

          const SizedBox(width: 8),

          // 9. Status Badge
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
                    record.status,
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

          // 10. Labeled Action Buttons: Edit, View, PDF
          if (!readOnly) ...[
            _buildLabeledActionButton(
              context: context,
              icon: Icons.edit_outlined,
              label: 'Edit',
              color: AppColors.infoBlue,
              onTap: () {
                Navigator.push(
                  context,
                  AppTheme.fadeSlideRoute(
                    page: PreventiveFormScreen(
                      moduleLabel: record.firestoreCategoryDisplayName,
                      subCategory: subCategory,
                      existingRecord: record,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 5),
          ],
          _buildLabeledActionButton(
            context: context,
            icon: Icons.visibility_outlined,
            label: 'View',
            color: AppColors.goldPrimary,
            onTap: () {
              Navigator.push(
                context,
                AppTheme.fadeSlideRoute(
                  page: PreventiveDetailViewScreen(
                    record: record,
                    moduleLabel: record.firestoreCategoryDisplayName,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 5),
          _buildLabeledActionButton(
            context: context,
            icon: Icons.picture_as_pdf_outlined,
            label: 'PDF',
            color: AppColors.dangerRed,
            onTap: () => ModulePdfHelper.generatePdf(record, context),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1150;
          if (isWide) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: buildRowContent(true),
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: buildRowContent(false),
            ),
          );
        },
      ),
    );
  }
}
