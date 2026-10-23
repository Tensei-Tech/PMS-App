// lib/screens/nc/nc_hub_screen.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/nc_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../widgets/custom_pdf_preview_dialog.dart';
import '../../widgets/dynamic_form/dynamic_form_screen.dart';
import '../../widgets/module_hub_screen_app_bar.dart';
import '../../widgets/pdf_document_view_screen.dart';

/// Hub for the independent N.C. module.
///
/// Everything shown comes from the backend: tab labels, button labels, search
/// hint, empty message and limits from `/api/nc/config/`; counts from
/// `/api/nc/counts/`; the form from the "NC Form" field template. The list is
/// keyset-paginated (`next_cursor`), loading more as the user scrolls.
class NcHubScreen extends StatefulWidget {
  final String categoryName;
  final String? categoryCode;
  final String moduleKey;

  const NcHubScreen({
    super.key,
    required this.categoryName,
    this.categoryCode,
    required this.moduleKey,
  });

  @override
  State<NcHubScreen> createState() => _NcHubScreenState();
}

class _NcHubScreenState extends State<NcHubScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _tabKeys = ['total', 'pending', 'disposal'];

  final NcService _service = NcService();
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

  String get _tab => _tabKeys[_tabController.index];

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
    await Future.wait([_refreshCounts(), _loadFirstPage(_tab)]);
  }

  String _cfg(String group, String key) {
    final g = _config[group];
    final v = g is Map ? g[key]?.toString() : null;
    if ((v == null || v.isEmpty) && kDebugMode && _config.isNotEmpty) {
      debugPrint('[NcHubScreen] Warning: missing config value $group.$key');
    }
    return v ?? '';
  }

  String _cfgTop(String key) => _config[key]?.toString() ?? '';

  Map<String, int>? get _maxLengths {
    final m = _config['field_max_lengths'];
    if (m is! Map) return null;
    return m.map((k, v) => MapEntry(k.toString(), int.tryParse('$v') ?? 0))
      ..removeWhere((_, v) => v <= 0);
  }

  Future<void> _refreshCounts() async {
    final c = await _service.fetchCounts();
    if (mounted) setState(() => _counts = c);
  }

  Future<void> _loadFirstPage(String tab) async {
    setState(() {
      _loading[tab] = true;
      _items[tab] = [];
      _nextCursor[tab] = null;
    });
    final page = await _service.fetchPage(tab: tab, q: _query);
    if (!mounted) return;
    setState(() {
      _items[tab] = _asRows(page['results']);
      _nextCursor[tab] = page['next_cursor']?.toString();
      _loading[tab] = false;
    });
  }

  Future<void> _loadMore() async {
    final tab = _tab;
    final cursor = _nextCursor[tab];
    if (cursor == null || _loading[tab] == true) return;
    setState(() => _loading[tab] = true);
    final page = await _service.fetchPage(tab: tab, q: _query, cursor: cursor);
    if (!mounted) return;
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

  Future<void> _openForm({dynamic id, bool readOnly = false}) async {
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
          categoryId: widget.categoryCode,
          moduleLabel: widget.categoryName,
          moduleKey: widget.moduleKey,
          initialData: formData,
          readOnly: readOnly,
          fieldMaxLengths: _maxLengths,
          sectionsInDisplayOrder: true,
          onSubmitCustom: readOnly
              ? null
              : (payload, isEdit) async {
                  final res = id == null
                      ? await _service.create(payload)
                      : await _service.update(id, payload);
                  if (res.isSuccess) return null;
                  return {'error': res.errorMessage ?? ''};
                },
        ),
      ),
    );
    if (result == true) await _reloadAll();
  }

  /// View shows the NC exactly as its PDF looks, read-only.
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
    final title = [widget.categoryName, item['nc_no']?.toString() ?? '']
        .where((s) => s.isNotEmpty)
        .join(' - ');
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
        subtitle: '${_counts['total'] ?? ''}',
        onBackPressed: () => Navigator.pop(context),
        actionWidget: addLabel.isEmpty
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
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.navyMid,
              labelColor: AppColors.navyDark,
              unselectedLabelColor: AppColors.lightSubText,
              labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500, fontSize: 13),
              tabs: _tabKeys.map((k) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(TranslationHelper.translate(
                          context, _cfg('sub_tab_labels', k))),
                      const SizedBox(width: 6),
                      _CountBadge(count: _counts[k]),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
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

  /// One field of a card: small label on top, value below ('-' when empty).
  Widget _fieldTile(String label, String value, double? width) {
    final shown = value.isEmpty ? '-' : value;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.translate(context, label),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.lightSubText,
                height: 1.2),
          ),
          const SizedBox(height: 1),
          // A merged box (e.g. Outward No. / Date) shows each value on its own
          // line, with a thin divider between them
          for (final (i, part) in shown.split('\n').indexed) ...[
            if (i > 0)
              const Divider(height: 7, thickness: 1, color: Color(0xFFE2E8F0)),
            Tooltip(
              message: part,
              child: Text(
                part,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: value.isEmpty
                        ? AppColors.lightSubText
                        : AppColors.navyDark),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// All fields in ONE line, sharing the width equally (labels may take two
  /// lines). Only on a narrow screen (phone) do the boxes wrap.
  Widget _fieldGrid(List<List> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 5.0;
      final maxW = constraints.maxWidth;
      if ((maxW - gap * (rows.length - 1)) / rows.length >= 72) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(
                  child: _fieldTile(rows[i][0]?.toString() ?? '',
                      rows[i][1]?.toString() ?? '', null),
                ),
              ],
            ],
          ),
        );
      }
      final perLine = (maxW / 112).floor().clamp(1, rows.length);
      final tileW = (maxW - gap * (perLine - 1)) / perLine;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final r in rows)
            _fieldTile(r[0]?.toString() ?? '', r[1]?.toString() ?? '', tileW),
        ],
      );
    });
  }

  Widget _buildCard(Map<String, dynamic> item, int serial) {
    final isDisposal = item['is_disposal'] == true;
    final statusColor =
        isDisposal ? AppColors.successGreen : AppColors.warningOrange;
    final serialLabel = _cfgTop('serial_label');
    final cardRows = (item['card_rows'] as List? ?? const [])
        .whereType<List>()
        .where((r) => r.length >= 2 && (r[0]?.toString() ?? '').isNotEmpty)
        .toList();
    final preventiveRows = (item['preventive_rows'] as List? ?? const [])
        .whereType<List>()
        .where((r) => r.isNotEmpty)
        .toList();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: statusColor, width: 3)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: serial, status and actions on one line
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.navyMid.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    serialLabel.isEmpty
                        ? '$serial'
                        : '${TranslationHelper.translate(context, serialLabel)} $serial',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.navyMid),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['status_label']?.toString() ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
                const SizedBox(width: 4),
                _actionButton(
                    'view', Icons.visibility_rounded, () => _openView(item)),
                _actionButton('edit', Icons.edit_rounded,
                    () => _openForm(id: item['id'])),
                _actionButton(
                    'pdf', Icons.picture_as_pdf_rounded, () => _openPdf(item)),
              ],
            ),
            const SizedBox(height: 8),
            // Main fields and every Preventive row's fields in ONE line of boxes
            _fieldGrid([
              ...cardRows,
              for (final row in preventiveRows)
                ...row.whereType<List>().where((p) => p.length >= 2),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String key, IconData icon, VoidCallback onTap) {
    final label = _cfg('action_labels', key);
    if (label.isEmpty) return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13),
      label: Text(TranslationHelper.translate(context, label),
          style: GoogleFonts.poppins(fontSize: 11)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navyMid,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final dynamic count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.navyDark.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${count ?? ''}',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.navyDark,
        ),
      ),
    );
  }
}
