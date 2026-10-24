// ignore_for_file: deprecated_member_use, prefer_const_constructors, use_build_context_synchronously
// lib/modules/muddemal/widgets/muddemal_cross_module_import_dialog.dart
// Discovers properties seized across other PMS modules and enables one-click idempotent linking.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../providers/muddemal_provider.dart';

class MuddemalCrossModuleImportDialog extends StatefulWidget {
  final String caseId;
  final String crNumber;

  const MuddemalCrossModuleImportDialog({
    super.key,
    required this.caseId,
    required this.crNumber,
  });

  @override
  State<MuddemalCrossModuleImportDialog> createState() =>
      _MuddemalCrossModuleImportDialogState();
}

class _MuddemalCrossModuleImportDialogState
    extends State<MuddemalCrossModuleImportDialog> {
  final Set<String> _linkingIds = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MuddemalProvider>();
    final discovered = provider.discoveredProperties;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.lightSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 750),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.infoBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.hub_rounded,
                            color: AppColors.infoBlue, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cross-Module Property Discovery',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyDark,
                            ),
                          ),
                          Text(
                            'Discovered seized & stolen articles for CR: ${widget.crNumber}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.lightSubText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 28),
              Expanded(
                child: discovered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 50, color: Colors.grey.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text(
                              'No seized properties detected in source crime records.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.lightSubText,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: discovered.length,
                        itemBuilder: (context, i) {
                          final item = discovered[i];
                          final isLinking =
                              _linkingIds.contains(item.sourceRecordId);

                          return Card(
                            elevation: 0,
                            color: item.isAlreadyLinked
                                ? AppColors.successGreen.withOpacity(0.04)
                                : Colors.grey.withOpacity(0.04),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: item.isAlreadyLinked
                                    ? AppColors.successGreen
                                        .withValues(alpha: 0.3)
                                    : AppColors.lightBorder
                                        .withValues(alpha: 0.6),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: item.isAlreadyLinked
                                        ? AppColors.successGreen
                                            .withOpacity(0.12)
                                        : AppColors.navyMid.withOpacity(0.08),
                                    child: Icon(
                                      item.isAlreadyLinked
                                          ? Icons.check_circle_rounded
                                          : Icons.link_rounded,
                                      color: item.isAlreadyLinked
                                          ? AppColors.successGreen
                                          : AppColors.navyMid,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              item.title,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: AppColors.navyDark,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.navyMid
                                                    .withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                item.inferredCategoryCode,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.navyMid,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.description,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppColors.lightSubText,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Source: ${item.rawSource} | Seized From: ${item.seizedFrom.isNotEmpty ? item.seizedFrom : 'N/A'} | Val: ₹${NumberFormat('#,##,###').format(item.totalItemValue)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppColors.lightSubText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (item.isAlreadyLinked)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.successGreen
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: AppColors.successGreen
                                                .withOpacity(0.3)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'LINKED',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.successGreen,
                                            ),
                                          ),
                                          if (item.linkedPropertyUid != null)
                                            Text(
                                              item.linkedPropertyUid!,
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.navyDark,
                                              ),
                                            ),
                                        ],
                                      ),
                                    )
                                  else
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.navyMid,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      icon: isLinking
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white),
                                            )
                                          : const Icon(Icons.add_link_rounded,
                                              size: 16),
                                      label: Text(
                                        'Link to Muddemal',
                                        style:
                                            GoogleFonts.poppins(fontSize: 12),
                                      ),
                                      onPressed: isLinking
                                          ? null
                                          : () async {
                                              final messenger =
                                                  ScaffoldMessenger.of(context);
                                              setState(() {
                                                _linkingIds
                                                    .add(item.sourceRecordId);
                                              });
                                              final ok = await provider
                                                  .linkDiscoveredProperty(
                                                      widget.caseId, item);
                                              if (mounted) {
                                                setState(() {
                                                  _linkingIds.remove(
                                                      item.sourceRecordId);
                                                });
                                                if (ok) {
                                                  messenger.showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Source property linked to Muddemal Register.'),
                                                      backgroundColor: AppColors
                                                          .successGreen,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
