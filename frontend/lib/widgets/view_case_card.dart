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

/// Modern horizontal single-row card for My Cases view.
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

  Widget _buildDivider({double margin = 6}) {
    return Container(
      width: 1,
      height: 26,
      margin: EdgeInsets.symmetric(horizontal: margin),
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
    double? width,
  }) {
    final s = _safeTrim(value);
    final shown = (s.isEmpty || s == '-') ? '—' : s;
    final translatedLabel = label.startsWith('# ')
        ? '# ${TranslationHelper.translate(context, label.substring(2))}'
        : TranslationHelper.translate(context, label);

    final content = SizedBox(
      height: 38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
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
                  translatedLabel,
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
            message: shown,
            child: Text(
              shown,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.navyDark,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );

    return width != null ? SizedBox(width: width, child: content) : content;
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

  void _openCaseDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => record.moduleKey == 'ad'
            ? AdRecordDetailScreen(record: record)
            : ModuleRecordDetailScreen(record: record),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDisposal = isRecordDisposal(record) || isDisposedTab;
    final Color statusBg =
        isDisposal ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);
    final Color statusBorder =
        isDisposal ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A);
    final Color statusColor =
        isDisposal ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final String displayStatus = isDisposal ? 'Disposal' : 'Pending';

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

    Widget buildDetailsRow(bool isExpandedMode) {
      final divMargin = isExpandedMode ? 8.0 : 4.0;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 0. Sr. No. Badge
          Container(
            height: 38,
            width: 36,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
          ),
          _buildDivider(margin: divMargin),

          // 1. # CR / Case No.
          isExpandedMode
              ? Expanded(
                  flex: 3,
                  child: _buildFieldColumn(
                    context: context,
                    label: '# CR / Case No.',
                    value: firLabel,
                    valueColor: AppColors.infoBlue,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 110,
                  label: '# CR / Case No.',
                  value: firLabel,
                  valueColor: AppColors.infoBlue,
                ),

          _buildDivider(margin: divMargin),

          // 2. Category badge
          Container(
            height: 38,
            width: isExpandedMode ? 140 : 120,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  TranslationHelper.translate(context, 'Category'),
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF92400E),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Tooltip(
                  message: categoryName,
                  child: Text(
                    TranslationHelper.translate(context, categoryName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF78350F),
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildDivider(margin: divMargin),

          // 3. Subject / Title
          isExpandedMode
              ? Expanded(
                  flex: 5,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Subject / Title',
                    value: displayTitle,
                    icon: Icons.description_outlined,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 160,
                  label: 'Subject / Title',
                  value: displayTitle,
                  icon: Icons.description_outlined,
                ),

          _buildDivider(margin: divMargin),

          // 4. Registered Date
          isExpandedMode
              ? Expanded(
                  flex: 3,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Registered Date',
                    value: dateStr,
                    icon: Icons.calendar_today_outlined,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 105,
                  label: 'Registered Date',
                  value: dateStr,
                  icon: Icons.calendar_today_outlined,
                ),

          _buildDivider(margin: divMargin),

          // 5. Officer / Location
          isExpandedMode
              ? Expanded(
                  flex: 4,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Officer / Location',
                    value: officerOrLocation,
                    icon: Icons.person_outline_rounded,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 135,
                  label: 'Officer / Location',
                  value: officerOrLocation,
                  icon: Icons.person_outline_rounded,
                ),

          _buildDivider(margin: divMargin),

          // 6. Status Badge
          Container(
            height: 38,
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
                    TranslationHelper.translate(context, displayStatus),
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

          // 7. Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactActionButton(
                context: context,
                icon: Icons.visibility_outlined,
                label: 'View',
                onTap: () => _openCaseDetail(context),
              ),
              const SizedBox(width: 6),
              _buildCompactActionButton(
                context: context,
                icon: Icons.picture_as_pdf_outlined,
                label: 'PDF',
                onTap: () => ModulePdfHelper.generatePdf(record, context),
              ),
            ],
          ),
        ],
      );
    }

    Widget buildMobileCard() {
      return InkWell(
        onTap: () => _openCaseDetail(context),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Sr No, CR No, Category chip, and Status Pill on right
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 24,
                    width: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$index',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      firLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.infoBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFFCD34D),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      TranslationHelper.translate(context, categoryName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF78350F),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          TranslationHelper.translate(context, displayStatus),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Subject / Title
              Text(
                displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyDark,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),

              // Row 3: Meta info (Date, Officer) and Action buttons (View & PDF)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 11.5,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 12.5,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      officerOrLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildCompactActionButton(
                    context: context,
                    icon: Icons.visibility_outlined,
                    label: 'View',
                    onTap: () => _openCaseDetail(context),
                  ),
                  const SizedBox(width: 6),
                  _buildCompactActionButton(
                    context: context,
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF',
                    onTap: () => ModulePdfHelper.generatePdf(record, context),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          if (isWide) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: buildDetailsRow(true),
            );
          }
          return buildMobileCard();
        },
      ),
    );
  }
}

/// Shimmer placeholder skeleton matching [ViewCaseCard].
class ViewCaseCardSkeleton extends StatelessWidget {
  const ViewCaseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        if (isMobile) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 90,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 38,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 38,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 90,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 80,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
