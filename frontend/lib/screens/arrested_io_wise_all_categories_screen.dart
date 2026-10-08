// lib/screens/arrested_io_wise_all_categories_screen.dart
// Arrested Cases — IO Wise across all dashboard categories (live backend records).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../modules/core/models/base_record.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import '../utils/arrested_io_wise_logic.dart';
import '../widgets/read_only_module_record_hub_card.dart';
import '../utils/translation_helper.dart';

class ArrestedIoWiseAllCategoriesScreen extends StatefulWidget {
  const ArrestedIoWiseAllCategoriesScreen({super.key});

  @override
  State<ArrestedIoWiseAllCategoriesScreen> createState() =>
      _ArrestedIoWiseAllCategoriesScreenState();
}

class _ArrestedIoWiseAllCategoriesScreenState
    extends State<ArrestedIoWiseAllCategoriesScreen> {
  final _backend = BackendCaseService();
  bool _isLoading = true;
  String? _error;
  List<ModuleRecord> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dataList = await _backend.fetchArrestedCases();
      if (!mounted) return;

      if (dataList != null) {
        final records = dataList.map((m) => ModuleRecord.fromMap(m)).toList();
        final filtered = records
            .where((r) =>
                r.moduleKey != 'nc' &&
                arrestedIoWiseEligibleAnyDashboardCategory(r))
            .toList();

        setState(() {
          _filtered = filtered;
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = "Failed to load cases from backend";
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

  @override
  Widget build(BuildContext context) {
    final title =
        '${TranslationHelper.translate(context, 'IO Wise Arrested')} — ${TranslationHelper.translate(context, 'All Categories')}';

    Widget buildBody() {
      if (_isLoading) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.navyMid));
      }
      if (_error != null) {
        return Center(
          child: Text(
            _error!,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.lightSubText),
          ),
        );
      }

      final buckets = <String, List<ModuleRecord>>{};
      for (final r in _filtered) {
        final io = arrestedIoWiseIoDisplayName(r)!;
        buckets.putIfAbsent(io, () => []).add(r);
      }

      final names = buckets.keys.toList()..sort((a, b) => a.compareTo(b));

      if (names.isEmpty) {
        return Center(
          child: Text(
            TranslationHelper.translate(context, 'No IO Wise arrested cases'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.lightSubText,
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        itemCount: names.length,
        itemBuilder: (_, i) {
          final io = names[i];
          final ioCases = buckets[io]!;
          final count = ioCases.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    AppTheme.fadeSlideRoute(
                      page: ArrestedIoWiseAllCategoriesDetailScreen(
                        ioDisplayName: io,
                        cases: ioCases,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${TranslationHelper.translate(context, 'IO Name')}: $io',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ),
                      Text(
                        '${TranslationHelper.translate(context, 'Cases')}: $count',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyMid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.navyMid, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: buildBody()),
          ],
        ),
      ),
    );
  }
}

class ArrestedIoWiseAllCategoriesDetailScreen extends StatelessWidget {
  const ArrestedIoWiseAllCategoriesDetailScreen({
    super.key,
    required this.ioDisplayName,
    required this.cases,
  });

  final String ioDisplayName;
  final List<ModuleRecord> cases;

  @override
  Widget build(BuildContext context) {
    final mine = List<ModuleRecord>.from(cases);
    mine.sort((a, b) => b.incidentDate.compareTo(a.incidentDate));

    final title = '$ioDisplayName — All categories';

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.navyMid, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: mine.isEmpty
                  ? Center(
                      child: Text(
                        'No cases match this officer',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightSubText,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, 24),
                      itemCount: mine.length,
                      itemBuilder: (_, i) =>
                          ReadOnlyModuleRecordHubCard(record: mine[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
