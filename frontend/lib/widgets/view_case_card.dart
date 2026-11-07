import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../modules/core/models/base_record.dart';
import '../screens/ad_record_detail_screen.dart';
import '../screens/module_record_detail_screen.dart';
import '../theme/app_theme.dart';
import '../utils/ad_disposal_helper.dart';
import '../utils/module_pdf_helper.dart';
import '../utils/translation_helper.dart';

/// Clean string trimming helper with fallback.
String _safeTrim(dynamic val, [String fallback = '']) {
  if (val == null) return fallback;
  final s = val.toString().trim();
  return s.isEmpty ? fallback : s;
}

void _openCaseDetail(BuildContext context, ModuleRecord record) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => record.moduleKey == 'ad'
          ? AdRecordDetailScreen(record: record)
          : ModuleRecordDetailScreen(record: record),
    ),
  );
}

/// Modern unified data table for case lists in My Cases and Dashboard.
class ViewCaseTable extends StatelessWidget {
  const ViewCaseTable({
    super.key,
    required this.records,
    this.isDisposedTab = false,
    this.startIndex = 1,
  });

  final List<ModuleRecord> records;
  final bool isDisposedTab;
  final int startIndex;

  static const double _minTableWidth = 910.0;

  Widget _buildHeaderCell(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        TranslationHelper.translate(context, title),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, bool isExpanded) {
    return Container(
      height: 42,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 0. Sr. No. (#)
          SizedBox(
            width: 38,
            child: Text(
              '#',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ),

          // 1. CR / Case No.
          isExpanded
              ? Expanded(
                  flex: 3,
                  child: _buildHeaderCell(context, 'CR / Case No.'),
                )
              : SizedBox(
                  width: 132,
                  child: _buildHeaderCell(context, 'CR / Case No.'),
                ),

          // 2. Category
          isExpanded
              ? Expanded(
                  flex: 3,
                  child: _buildHeaderCell(context, 'Category'),
                )
              : SizedBox(
                  width: 110,
                  child: _buildHeaderCell(context, 'Category'),
                ),

          // 3. Subject / Title
          isExpanded
              ? Expanded(
                  flex: 5,
                  child: _buildHeaderCell(context, 'Subject / Title'),
                )
              : SizedBox(
                  width: 190,
                  child: _buildHeaderCell(context, 'Subject / Title'),
                ),

          // 4. Registered Date
          isExpanded
              ? Expanded(
                  flex: 3,
                  child: _buildHeaderCell(context, 'Registered Date'),
                )
              : SizedBox(
                  width: 110,
                  child: _buildHeaderCell(context, 'Registered Date'),
                ),

          // 5. Officer / Location
          isExpanded
              ? Expanded(
                  flex: 4,
                  child: _buildHeaderCell(context, 'Officer / Location'),
                )
              : SizedBox(
                  width: 130,
                  child: _buildHeaderCell(context, 'Officer / Location'),
                ),

          // 6. Status
          SizedBox(
            width: 95,
            child: Text(
              TranslationHelper.translate(context, 'Status'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ),

          // 7. Actions
          SizedBox(
            width: 85,
            child: Text(
              TranslationHelper.translate(context, 'Actions'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextCell(
    String text, {
    bool isBold = false,
    Color color = AppColors.navyDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: text,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: TranslationHelper.translate(context, tooltip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 30,
          width: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 15, color: AppColors.navyDark),
        ),
      ),
    );
  }

  Widget _buildDataRow({
    required BuildContext context,
    required ModuleRecord record,
    required int index,
    required bool isLast,
    required bool isExpanded,
  }) {
    final rawStatus = _safeTrim(record.status);
    final isDisposal = isDisposedTab ||
        isRecordDisposal(record) ||
        rawStatus.toLowerCase() == 'disposal' ||
        rawStatus.toLowerCase() == 'closed' ||
        rawStatus.toLowerCase() == 'resolved' ||
        rawStatus.toLowerCase() == 'disposed';

    final String displayStatus;
    if (isDisposedTab || isDisposal) {
      displayStatus = 'Disposal';
    } else if (rawStatus.toLowerCase() == 'detected' ||
        rawStatus.toLowerCase() == 'pending' ||
        rawStatus.toLowerCase() == 'open' ||
        rawStatus.toLowerCase() == 'active' ||
        rawStatus.isEmpty) {
      displayStatus = 'Pending';
    } else {
      displayStatus = rawStatus;
    }

    final lowerStatus = displayStatus.toLowerCase();
    final Color statusBg;
    final Color statusBorder;
    final Color statusColor;

    if (isDisposal ||
        lowerStatus == 'disposal' ||
        lowerStatus == 'closed' ||
        lowerStatus == 'resolved' ||
        lowerStatus == 'disposed') {
      statusBg = const Color(0xFFF0FDF4);
      statusBorder = const Color(0xFFBBF7D0);
      statusColor = const Color(0xFF16A34A);
    } else if (lowerStatus == 'pending' ||
        lowerStatus == 'open' ||
        lowerStatus == 'active') {
      statusBg = const Color(0xFFFFFBEB);
      statusBorder = const Color(0xFFFDE68A);
      statusColor = const Color(0xFFD97706);
    } else {
      statusBg = const Color(0xFFF8FAFC);
      statusBorder = const Color(0xFFCBD5E1);
      statusColor = const Color(0xFF475569);
    }

    final firLabel = _safeTrim(record.caseNumber, '—');
    String cat = _safeTrim(record.firestoreCategoryDisplayName);
    if (cat.isEmpty) {
      cat = _safeTrim(record.moduleKey).toUpperCase();
    }
    final categoryName = cat.isNotEmpty ? cat : 'CASE';
    final displayTitle = _safeTrim(record.title, 'Untitled Case');

    String dateStr = '—';
    try {
      dateStr = DateFormat('dd/MM/yyyy').format(record.createdAt);
    } catch (_) {}

    final officer = _safeTrim(record.assignedOfficer);
    final location = _safeTrim(record.location);
    final officerOrLocation = officer.isNotEmpty && officer != '—'
        ? officer
        : (location.isNotEmpty && location != '—' ? location : '—');

    return _HoverableTableRow(
      isLast: isLast,
      onTap: () => _openCaseDetail(context, record),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 0. Sr. No.
            SizedBox(
              width: 38,
              child: Text(
                '$index',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),

            // 1. CR / Case No.
            isExpanded
                ? Expanded(
                    flex: 3,
                    child: _buildTextCell(
                      firLabel,
                      isBold: true,
                      color: AppColors.navyDark,
                    ),
                  )
                : SizedBox(
                    width: 132,
                    child: _buildTextCell(
                      firLabel,
                      isBold: true,
                      color: AppColors.navyDark,
                    ),
                  ),

            // 2. Category
            isExpanded
                ? Expanded(
                    flex: 3,
                    child: _buildTextCell(
                      TranslationHelper.translate(context, categoryName),
                      color: AppColors.navyDark,
                    ),
                  )
                : SizedBox(
                    width: 110,
                    child: _buildTextCell(
                      TranslationHelper.translate(context, categoryName),
                      color: AppColors.navyDark,
                    ),
                  ),

            // 3. Subject / Title
            isExpanded
                ? Expanded(
                    flex: 5,
                    child: _buildTextCell(
                      displayTitle,
                      color: AppColors.navyDark,
                    ),
                  )
                : SizedBox(
                    width: 190,
                    child: _buildTextCell(
                      displayTitle,
                      color: AppColors.navyDark,
                    ),
                  ),

            // 4. Registered Date
            isExpanded
                ? Expanded(
                    flex: 3,
                    child: _buildTextCell(
                      dateStr,
                      color: const Color(0xFF475569),
                    ),
                  )
                : SizedBox(
                    width: 110,
                    child: _buildTextCell(
                      dateStr,
                      color: const Color(0xFF475569),
                    ),
                  ),

            // 5. Officer / Location
            isExpanded
                ? Expanded(
                    flex: 4,
                    child: _buildTextCell(
                      officerOrLocation,
                      color: const Color(0xFF475569),
                    ),
                  )
                : SizedBox(
                    width: 130,
                    child: _buildTextCell(
                      officerOrLocation,
                      color: const Color(0xFF475569),
                    ),
                  ),

            // 6. Status Badge
            SizedBox(
              width: 95,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5.5,
                        height: 5.5,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          TranslationHelper.translate(context, displayStatus),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 7. Actions
            SizedBox(
              width: 85,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    context: context,
                    icon: Icons.visibility_outlined,
                    tooltip: 'View',
                    onTap: () => _openCaseDetail(context, record),
                  ),
                  const SizedBox(width: 6),
                  _buildActionButton(
                    context: context,
                    icon: Icons.picture_as_pdf_outlined,
                    tooltip: 'PDF',
                    onTap: () => ModulePdfHelper.generatePdf(record, context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _minTableWidth;

        Widget tableBody(bool isExpanded) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderRow(context, isExpanded),
              for (int i = 0; i < records.length; i++)
                _buildDataRow(
                  context: context,
                  record: records[i],
                  index: startIndex + i,
                  isLast: i == records.length - 1,
                  isExpanded: isExpanded,
                ),
            ],
          );
        }

        Widget content;
        if (isWide) {
          content = tableBody(true);
        } else {
          content = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: _minTableWidth,
              child: tableBody(false),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: content,
          ),
        );
      },
    );
  }
}

/// Hoverable table row with subtle highlight and bottom border.
class _HoverableTableRow extends StatefulWidget {
  final Widget child;
  final bool isLast;
  final VoidCallback onTap;

  const _HoverableTableRow({
    required this.child,
    required this.isLast,
    required this.onTap,
  });

  @override
  State<_HoverableTableRow> createState() => _HoverableTableRowState();
}

class _HoverableTableRowState extends State<_HoverableTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF8FAFC) : Colors.white,
            border: widget.isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                  ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Shimmer placeholder table skeleton matching [ViewCaseTable].
class ViewCaseTableSkeleton extends StatelessWidget {
  const ViewCaseTableSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          children: [
            Container(
              height: 42,
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 110,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Container(
                    width: 90,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (int i = 0; i < 6; i++)
              Container(
                height: 48,
                decoration: BoxDecoration(
                  border: i == 5
                      ? null
                      : const Border(
                          bottom:
                              BorderSide(color: Color(0xFFF1F5F9), width: 1),
                        ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      width: 100,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 32),
                    Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Compatibility wrapper for existing single-card usages.
class ViewCaseCard extends StatelessWidget {
  const ViewCaseCard({
    super.key,
    required this.record,
    required this.index,
    this.isDisposedTab = false,
  });

  final ModuleRecord record;
  final int index;
  final bool isDisposedTab;

  @override
  Widget build(BuildContext context) {
    return ViewCaseTable(
      records: [record],
      isDisposedTab: isDisposedTab,
      startIndex: index,
    );
  }
}

/// Backwards compatibility alias for skeleton.
typedef ViewCaseCardSkeleton = ViewCaseTableSkeleton;

/// Empty state widget for case lists.
class ViewEmptyState extends StatelessWidget {
  const ViewEmptyState({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, size: 34, color: iconColor.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            Text(
              TranslationHelper.translate(context, title),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              TranslationHelper.translate(context, message),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.lightSubText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
