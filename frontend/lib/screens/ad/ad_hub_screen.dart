// lib/screens/ad/ad_hub_screen.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../widgets/custom_pdf_preview_dialog.dart';
import '../../widgets/dynamic_form/dynamic_form_screen.dart';
import '../../widgets/module_hub_screen_app_bar.dart';
import '../../widgets/pdf_document_view_screen.dart';

/// Hub for A.D. (Accidental Death), built like the N.C. hub.
///
/// The sub-tabs (Suicide / Other ...) are the A.D. tab's child categories; each
/// has its own Total / Pending / Disposal tabs, counts and list. Everything
/// shown comes from the backend: labels, sub-tabs and messages from
/// `/api/ad/config/`, counts from `/api/ad/counts/`, list cards (`card_rows`)
/// from `/api/ad/`, the form from the "AD Form Fields" template.
class AdHubScreen extends StatefulWidget {
  final String categoryName;
  final String moduleKey;

  const AdHubScreen({
    super.key,
    required this.categoryName,
    required this.moduleKey,
  });

  @override
  State<AdHubScreen> createState() => _AdHubScreenState();
}

class _AdHubScreenState extends State<AdHubScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _tabKeys = ['total', 'pending', 'disposal'];

  final AdService _service = AdService();
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _debounce;

  Map<String, dynamic> _config = {};
  Map<String, dynamic> _counts = {};
  final Map<String, List<Map<String, dynamic>>> _items = {};
  final Map<String, String?> _nextCursor = {};
  final Map<String, bool> _loading = {};
  String _query = '';
  String? _category;

  String get _tab => _tabKeys[_tabController.index];

  List<Map<String, dynamic>> get _subCategories =>
      (_config['sub_categories'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((m) => (m['code']?.toString() ?? '').isNotEmpty)
          .toList();

  String get _categoryName =>
      _subCategories
          .where((c) => c['code'] == _category)
          .map((c) => c['name']?.toString() ?? '')
          .firstOrNull ??
      '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabKeys.length, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          if (!_items.containsKey(_tab)) _loadFirstPage(_tab);
          setState(() {});
        }
      });
    _scrollCtrl.addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final cfg = await _service.fetchConfig(forceRefresh: true);
    if (!mounted) return;
    setState(() => _config = cfg);
    final subs = _subCategories;
    if (subs.isNotEmpty) await _selectCategory(subs.first['code'].toString());
  }

  Future<void> _selectCategory(String code) async {
    setState(() {
      _category = code;
      _counts = {};
      _items.clear();
    });
    await _reloadAll();
  }

  String _cfg(String group, String key) {
    final g = _config[group];
    final v = g is Map ? g[key]?.toString() : null;
    if ((v == null || v.isEmpty) && kDebugMode && _config.isNotEmpty) {
      debugPrint('[AdHubScreen] Warning: missing config value $group.$key');
    }
    return v ?? '';
  }

  String _cfgTop(String key) => _config[key]?.toString() ?? '';

  Future<void> _refreshCounts() async {
    final cat = _category;
    if (cat == null) return;
    final c = await _service.fetchCounts(cat);
    if (mounted && cat == _category) setState(() => _counts = c);
  }

  Future<void> _loadFirstPage(String tab) async {
    final cat = _category;
    if (cat == null) return;
    setState(() {
      _loading[tab] = true;
      _items[tab] = [];
      _nextCursor[tab] = null;
    });
    final page = await _service.fetchPage(category: cat, tab: tab, q: _query);
    if (!mounted || cat != _category) return;
    setState(() {
      _items[tab] = _asRows(page['results']);
      _nextCursor[tab] = page['next_cursor']?.toString();
      _loading[tab] = false;
    });
  }

  Future<void> _loadMore() async {
    final cat = _category;
    final tab = _tab;
    final cursor = _nextCursor[tab];
    if (cat == null || cursor == null || _loading[tab] == true) return;
    setState(() => _loading[tab] = true);
    final page = await _service.fetchPage(
        category: cat, tab: tab, q: _query, cursor: cursor);
    if (!mounted || cat != _category) return;
    setState(() {
      _items[tab] = [...?_items[tab], ..._asRows(page['results'])];
      _nextCursor[tab] = page['next_cursor']?.toString();
      _loading[tab] = false;
    });
  }

  List<Map<String, dynamic>> _asRows(dynamic raw) => raw is List
      ? raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
      : <Map<String, dynamic>>[];

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _query = value.trim();
      _items.clear();
      _loadFirstPage(_tab);
    });
  }

  Future<void> _reloadAll() async {
    _items.clear();
    await Future.wait([_refreshCounts(), _loadFirstPage(_tab)]);
  }

  void _showMessage(String text, {bool error = false}) {
    if (text.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text, style: GoogleFonts.poppins()),
      backgroundColor: error ? AppColors.dangerRed : AppColors.successGreen,
    ));
  }

  Future<void> _openForm({dynamic id}) async {
    final cat = _category;
    if (cat == null) return;
    Map<String, dynamic>? formData;
    if (id != null) {
      final detail = await _service.fetchDetail(id);
      if (!mounted) return;
      final fd = detail?['form_data'];
      if (fd is! Map) return;
      formData = Map<String, dynamic>.from(fd);
    }
    final result = await Navigator.push<bool>(
      context,
      AppTheme.fadeSlideRoute(
        page: DynamicFormScreen(
          categoryId: cat,
          moduleLabel: _categoryName,
          moduleKey: widget.moduleKey,
          initialData: formData,
          sectionsInDisplayOrder: true,
          onSubmitCustom: (payload, isEdit) async {
            final res = id == null
                ? await _service.create(cat, payload)
                : await _service.update(id, payload);
            if (res.isSuccess) return null;
            return {'error': res.errorMessage ?? ''};
          },
        ),
      ),
    );
    if (result == true) await _reloadAll();
  }

  /// View shows the A.D. exactly as its PDF looks, read-only.
  Future<void> _openView(Map<String, dynamic> item) async {
    final bytes = await _service.fetchPdfBytes(item['id']);
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      _showMessage(_cfg('messages', 'pdf_failed_message'), error: true);
      return;
    }
    await PdfDocumentViewScreen.open(context,
        pdfBytes: bytes, moduleName: widget.categoryName);
  }

  Future<void> _openPdf(Map<String, dynamic> item) async {
    final bytes = await _service.fetchPdfBytes(item['id']);
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      _showMessage(_cfg('messages', 'pdf_failed_message'), error: true);
      return;
    }
    final title = [
      widget.categoryName,
      _categoryName,
      item['case_number']?.toString() ?? ''
    ].where((s) => s.isNotEmpty).join(' - ');
    await CustomPdfPreviewDialog.show(
      context: context,
      title: title,
      fileName: '${title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}.pdf',
      buildPdf: (_) async => bytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final addLabel = _cfg('action_labels', 'add');
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: TranslationHelper.translate(context, widget.categoryName),
        subtitle: _categoryName.isEmpty
            ? ''
            : '${TranslationHelper.translate(context, _categoryName)} · ${_counts['total'] ?? ''}',
        onBackPressed: () => Navigator.pop(context),
        actionWidget: addLabel.isEmpty || _category == null
            ? null
            : ElevatedButton.icon(
                onPressed: () => _openForm(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyMid,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  TranslationHelper.translate(context, addLabel),
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
      ),
      body: Column(
        children: [
          _buildSubCategoryBar(),
          _buildStatusTabBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: _cfgTop('search_placeholder'),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.navyMid),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
          ),
          if (_tab == 'pending') _buildPendingDefinition(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  /// Sub-tabs (Suicide / Other ...) from the A.D. tab's child categories.
  /// Sub-tabs (Suicide / Other ...) styled with clean pill buttons.
  Widget _buildSubCategoryBar() {
    final subs = _subCategories;
    if (subs.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          for (final c in subs) ...[
            Builder(builder: (context) {
              final isSelected = c['code'] == _category;
              return InkWell(
                onTap: () {
                  if (c['code'] != _category) {
                    _selectCategory(c['code'].toString());
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.navyMid : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.navyMid
                          : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    TranslationHelper.translate(context, c['name'].toString()),
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.navyDark,
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  /// Status tab bar styled with exact colors matching Form I-V cases.
  Widget _buildStatusTabBar() {
    final tabs = [
      (
        key: 'total',
        label: _cfg('sub_tab_labels', 'total').isNotEmpty
            ? _cfg('sub_tab_labels', 'total')
            : 'Total Cases',
        count: _counts['total'] ?? 0,
        badgeBg: const Color(0xFFE8F1FC),
        badgeFg: const Color(0xFF1976D2),
      ),
      (
        key: 'pending',
        label: _cfg('sub_tab_labels', 'pending').isNotEmpty
            ? _cfg('sub_tab_labels', 'pending')
            : 'Pending',
        count: _counts['pending'] ?? 0,
        badgeBg: const Color(0xFFFFF3E0),
        badgeFg: const Color(0xFFE65100),
      ),
      (
        key: 'disposal',
        label: _cfg('sub_tab_labels', 'disposal').isNotEmpty
            ? _cfg('sub_tab_labels', 'disposal')
            : 'Disposal',
        count: _counts['disposal'] ?? 0,
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
                  final isSelected = _tab == item.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: InkWell(
                      onTap: () {
                        final idx = _tabKeys.indexOf(item.key);
                        if (idx != -1 && idx != _tabController.index) {
                          _tabController.animateTo(idx);
                        }
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
                                    ? AppColors.navyDark
                                    : AppColors.lightSubText,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: item.badgeBg,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                '${item.count ?? 0}',
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
        ],
      ),
    );
  }

  Widget _buildList() {
    final items = _items[_tab] ?? const [];
    final loading = _loading[_tab] == true;
    if (items.isEmpty && loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _reloadAll,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            Center(
              child: Text(
                _cfgTop('empty_list_message'),
                style: GoogleFonts.poppins(color: AppColors.lightSubText),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _reloadAll,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: items.length + (_nextCursor[_tab] != null ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return _buildCard(items[i], i + 1);
        },
      ),
    );
  }

  /// Pending tab: what "Pending" means (text from module_settings).
  Widget _buildPendingDefinition() {
    final text = _cfgTop('pending_definition');
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.warningOrange.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.warningOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              TranslationHelper.translate(context, text),
              style: GoogleFonts.poppins(
                  fontSize: 12.5, color: AppColors.navyDark, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider({double margin = 8}) {
    return Container(
      width: 1,
      height: 28,
      margin: EdgeInsets.symmetric(horizontal: margin),
      color: const Color(0xFFE2E8F0),
    );
  }

  IconData _iconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('ad no') ||
        l.contains('ad_no') ||
        l.contains('case_no') ||
        l.contains('no.')) {
      return Icons.tag_rounded;
    }
    if (l.contains('identity')) {
      return Icons.badge_outlined;
    }
    if (l.contains('name') || l.contains('deceased')) {
      return Icons.person_outline_rounded;
    }
    if (l.contains('cause') || l.contains('death')) {
      return Icons.health_and_safety_outlined;
    }
    if (l.contains('pm') || l.contains('post mortem')) {
      return Icons.medical_services_outlined;
    }
    if (l.contains('sdm') || l.contains('grant')) {
      return Icons.fact_check_outlined;
    }
    if (l.contains('date')) {
      return Icons.calendar_today_outlined;
    }
    if (l.contains('spot') ||
        l.contains('place') ||
        l.contains('village') ||
        l.contains('location')) {
      return Icons.place_outlined;
    }
    if (l.contains('station') || l.contains('police')) {
      return Icons.local_police_outlined;
    }
    if (l.contains('io') || l.contains('officer')) {
      return Icons.shield_outlined;
    }
    return Icons.info_outline_rounded;
  }

  Widget _buildFieldColumn({
    required BuildContext context,
    required String label,
    required String value,
    IconData? icon,
    Color? iconColor,
    Color? valueColor,
    VoidCallback? onTap,
    double? width,
  }) {
    final shown =
        (value.trim().isEmpty || value.trim() == '-') ? '-' : value.trim();
    final parts = shown.split('\n');

    final content = SizedBox(
      height: 40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 11.0,
                  color: iconColor ?? const Color(0xFF64748B),
                ),
                const SizedBox(width: 3.5),
              ],
              Flexible(
                child: Text(
                  TranslationHelper.translate(context, label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 9.0,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1.5),
          for (final (i, part) in parts.indexed) ...[
            if (i > 0) const SizedBox(height: 1),
            Tooltip(
              message: part,
              child: Text(
                part,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: parts.length > 1 ? 10.0 : 11.5,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.navyDark,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final wrapped =
        width != null ? SizedBox(width: width, child: content) : content;

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: wrapped,
        ),
      );
    }
    return wrapped;
  }

  Widget _buildCompactActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    Color? borderColor,
    Color? bgColor,
  }) {
    final fgColor = color ?? AppColors.navyDark;
    return Tooltip(
      message: TranslationHelper.translate(context, label),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 38,
          width: 42,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: borderColor ?? const Color(0xFFCBD5E1),
              width: 1.1,
            ),
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
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 8.0,
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

  Widget _buildCard(Map<String, dynamic> item, int serial) {
    final isDisposal = item['is_disposal'] == true;
    final Color statusBg =
        isDisposal ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);
    final Color statusBorder =
        isDisposal ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A);
    final Color statusColor =
        isDisposal ? const Color(0xFF16A34A) : const Color(0xFFD97706);

    final serialLabel = _cfgTop('serial_label');
    final cardRows = (item['card_rows'] as List? ?? const [])
        .whereType<List>()
        .where((r) => r.length >= 2 && (r[0]?.toString() ?? '').isNotEmpty)
        .toList();

    final viewLabel = _cfg('action_labels', 'view').isNotEmpty
        ? _cfg('action_labels', 'view')
        : 'View';
    final editLabel = _cfg('action_labels', 'edit').isNotEmpty
        ? _cfg('action_labels', 'edit')
        : 'Edit';
    final pdfLabel = _cfg('action_labels', 'pdf').isNotEmpty
        ? _cfg('action_labels', 'pdf')
        : 'PDF';

    Widget buildDetailsRow(bool isExpandedMode) {
      final divMargin = isExpandedMode ? 8.0 : 4.0;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 0. Sr. No. Badge (Fixed height 38, neutral slate styling)
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            alignment: Alignment.center,
            child: Text(
              serialLabel.isEmpty
                  ? '$serial'
                  : '${TranslationHelper.translate(context, serialLabel)} $serial',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.navyDark,
              ),
            ),
          ),

          // 1. Dynamic Field Columns
          for (final f in cardRows) ...[
            _buildDivider(margin: divMargin),
            () {
              final label = f[0]?.toString() ?? '';
              final rawVal = f[1]?.toString() ?? '';
              final icon = _iconForLabel(label);
              final l = label.toLowerCase();
              final int flex = (l.contains('name') || l.contains('deceased'))
                  ? 4
                  : (l.contains('cause') ||
                          l.contains('death') ||
                          l.contains('identity') ||
                          l.contains('sdm') ||
                          l.contains('pm'))
                      ? 3
                      : 2;
              final double width =
                  (l.contains('name') || l.contains('deceased'))
                      ? 150
                      : (l.contains('cause') ||
                              l.contains('death') ||
                              l.contains('pm') ||
                              l.contains('sdm'))
                          ? 140
                          : (l.contains('identity'))
                              ? 125
                              : 105;

              return isExpandedMode
                  ? Expanded(
                      flex: flex,
                      child: _buildFieldColumn(
                        context: context,
                        label: label,
                        value: rawVal,
                        icon: icon,
                      ),
                    )
                  : _buildFieldColumn(
                      context: context,
                      width: width,
                      label: label,
                      value: rawVal,
                      icon: icon,
                    );
            }(),
          ],

          _buildDivider(margin: divMargin),

          // 2. Status Badge (Disposal / Pending in last before actions)
          Container(
            height: 34,
            width: isExpandedMode ? 105 : 95,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    TranslationHelper.translate(
                      context,
                      item['status_label']?.toString() ??
                          (isDisposal ? 'Disposal' : 'Pending'),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildDivider(margin: divMargin),

          // 3. Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactActionButton(
                context: context,
                icon: Icons.visibility_outlined,
                label: viewLabel,
                onTap: () => _openView(item),
              ),
              const SizedBox(width: 6),
              _buildCompactActionButton(
                context: context,
                icon: Icons.edit_outlined,
                label: editLabel,
                onTap: () => _openForm(id: item['id']),
              ),
              const SizedBox(width: 6),
              _buildCompactActionButton(
                context: context,
                icon: Icons.picture_as_pdf_outlined,
                label: pdfLabel,
                onTap: () => _openPdf(item),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide =
              constraints.maxWidth >= (cardRows.length > 4 ? 1280 : 1000);
          if (isWide) {
            return buildDetailsRow(true);
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: buildDetailsRow(false),
          );
        },
      ),
    );
  }
}
