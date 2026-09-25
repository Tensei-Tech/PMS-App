// lib/screens/standalone_selection_screen.dart
// Priority 2: Standalone categories screen dynamically wired to
// GET /api/categories/?standalone=true (all 26 standalone tabs).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../modules/core/models/base_record.dart';
import '../services/case_service.dart';
import '../theme/app_theme.dart';
import '../utils/translation_helper.dart';
import '../widgets/module_hub_screen_app_bar.dart';
import 'common_form_screen.dart';
import 'module_record_detail_screen.dart';

/// Offline fallback list of all 26 standalone category names from database master
const List<String> kDefaultStandaloneCategories = [
  'Normal Accident',
  'Road Accident',
  'Death Due to Rash Driving',
  'Other Road Accident',
  'Theft',
  'Kidnapping',
  'Hurt',
  'Sand Theft',
  'Two/Four Wheeler Theft',
  'Missing',
  'Crime Against Women',
  'Accident',
  'Sec 156(3)/175(3)(BNSS)',
  'Coin',
  'Suicide',
  'A.D.',
  'N.C.',
  'ST Drugs',
  'Prohibition',
  'Gambling',
  'POCSO',
  'NDPS',
  'Gowans',
  'IT Act',
  'M.V Act',
  'UAPA',
];

class StandaloneSelectionScreen extends StatefulWidget {
  final bool readOnly;

  const StandaloneSelectionScreen({
    super.key,
    this.readOnly = false,
  });

  @override
  State<StandaloneSelectionScreen> createState() =>
      _StandaloneSelectionScreenState();
}

class _StandaloneSelectionScreenState extends State<StandaloneSelectionScreen> {
  final CaseService _caseService = CaseService();
  List<String> _displayCategories = [];
  bool _isLoading = true;
  bool _isUsingFallback = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  String? _selectedCategory;
  List<ModuleRecord> _categoryCases = [];
  bool _isLoadingCases = false;

  @override
  void initState() {
    super.initState();
    _loadStandaloneCategories();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStandaloneCategories() async {
    setState(() => _isLoading = true);
    try {
      final cats = await _caseService.fetchStandaloneCategories();
      if (!mounted) return;
      if (cats.isNotEmpty) {
        final names = cats
            .map((c) =>
                (c['category_name'] ?? c['name'] ?? '').toString().trim())
            .where((n) => n.isNotEmpty)
            .toSet()
            .toList();
        setState(() {
          _displayCategories = names;
          _isLoading = false;
          _isUsingFallback = false;
        });
      } else {
        setState(() {
          _displayCategories = List.from(kDefaultStandaloneCategories);
          _isLoading = false;
          _isUsingFallback = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _displayCategories = List.from(kDefaultStandaloneCategories);
        _isLoading = false;
        _isUsingFallback = true;
      });
    }
  }

  List<String> get _filteredCategories {
    if (_searchQuery.trim().isEmpty) {
      return _displayCategories;
    }
    final q = _searchQuery.toLowerCase().trim();
    return _displayCategories
        .where((c) => c.toLowerCase().contains(q))
        .toList();
  }

  void _onCategoryTap(String category) async {
    setState(() {
      _selectedCategory = category;
      _isLoadingCases = true;
    });

    try {
      final cases = await _caseService.fetchCategoryCases(category);
      if (!mounted) return;
      setState(() {
        _categoryCases = cases;
        _isLoadingCases = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categoryCases = [];
        _isLoadingCases = false;
      });
    }
  }

  void _onNewCase() {
    final category = _selectedCategory ??
        (_filteredCategories.isNotEmpty
            ? _filteredCategories.first
            : 'Theft');
    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: CommonFormScreen(
          moduleLabel: category,
          moduleKey: 'form_1_5',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _selectedCategory != null
        ? '${TranslationHelper.translate(context, _selectedCategory!)} · ${_categoryCases.length} cases'
        : '${_filteredCategories.length} ${TranslationHelper.translate(context, 'categories')} (Standalone)';

    final actionWidget = !widget.readOnly
        ? ElevatedButton.icon(
            onPressed: _onNewCase,
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
          )
        : null;

    return PopScope(
      canPop: _selectedCategory == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedCategory != null) {
          setState(() => _selectedCategory = null);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBg,
        appBar: ModuleHubScreenAppBar(
          title: TranslationHelper.translate(context, 'Standalone Categories'),
          subtitle: subtitle,
          actionWidget: actionWidget,
          onBackPressed: () {
            if (_selectedCategory != null) {
              setState(() => _selectedCategory = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (kDebugMode && _isUsingFallback)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: Colors.amber.shade900),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'DEBUG NOTICE: Using offline fallback standalone category list.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_isLoading && _displayCategories.isEmpty)
              const LinearProgressIndicator(minHeight: 2),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: TranslationHelper.translate(
                      context, 'Search standalone categories...'),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.navyMid),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.navyMid, width: 1.5),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // Category Count Chip Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.navyDark.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Total Standalone: ${_filteredCategories.length} tabs',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_selectedCategory != null)
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _selectedCategory = null),
                      icon: const Icon(Icons.view_module_rounded, size: 16),
                      label: Text(
                        'View All Tabs',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 16, color: Color(0xFFE2E8F0)),

            // Main Content: Grid or Detail Cases
            Expanded(
              child: _selectedCategory == null
                  ? _buildCategoryGrid(context)
                  : _buildSelectedCategoryCases(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final categories = _filteredCategories;
    if (categories.isEmpty) {
      return Center(
        child: Text(
          'No standalone categories found',
          style: GoogleFonts.poppins(
              fontSize: 14, color: AppColors.lightSubText),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    int cols = 2;
    if (width > 1200) {
      cols = 5;
    } else if (width > 900) {
      cols = 4;
    } else if (width > 600) {
      cols = 3;
    }

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final catName = categories[index];
                return _buildCategoryCard(catName);
              },
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCategoryCard(String name) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _onCategoryTap(name),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.folder_special_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    TranslationHelper.translate(context, name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 13,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCategoryCases(BuildContext context) {
    if (_isLoadingCases) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categoryCases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No cases recorded for $_selectedCategory',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.lightSubText,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _onNewCase,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Create Case in $_selectedCategory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyMid,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _categoryCases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final rec = _categoryCases[i];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            title: Text(
              rec.caseNumber.isNotEmpty
                  ? rec.caseNumber
                  : 'Case #${rec.id}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.navyDark,
              ),
            ),
            subtitle: Text(
              '${rec.complainant.isNotEmpty ? 'Complainant: ${rec.complainant} · ' : ''}${DateFormat('dd MMM yyyy').format(rec.incidentDate)}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.lightSubText,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                AppTheme.fadeSlideRoute(
                  page: ModuleRecordDetailScreen(
                    record: rec,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
