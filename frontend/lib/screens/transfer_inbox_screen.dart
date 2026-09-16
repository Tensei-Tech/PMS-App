import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../utils/translation_helper.dart';
import '../widgets/assign_officer_dialog.dart';
import '../widgets/module_hub_screen_app_bar.dart';

class TransferInboxScreen extends StatefulWidget {
  const TransferInboxScreen({super.key});

  @override
  State<TransferInboxScreen> createState() => _TransferInboxScreenState();
}

class _TransferInboxScreenState extends State<TransferInboxScreen> {
  // Mock data for the inbox
  final List<Map<String, String>> _mockInbox = [
    {
      'caseNumber': 'FIR 0042/2026',
      'title': 'Vehicle Theft',
      'fromStation': 'Dadar Police Station',
      'transferredBy': 'PI Ramesh Singh',
      'date': '2026-09-12',
      'remark':
          'Jurisdiction transfer as incident occurred near Bandra border.',
    },
    {
      'caseNumber': 'NC 1102/2026',
      'title': 'Public Disturbance',
      'fromStation': 'Colaba Police Station',
      'transferredBy': 'API Sanjay Gupta',
      'date': '2026-09-11',
      'remark': 'Suspects relocated to Bandra area, transferring file.',
    }
  ];

  void _openAssignDialog(Map<String, String> caseItem) async {
    final assigned = await AssignOfficerDialog.show(
      context,
      caseNumber: caseItem['caseNumber']!,
      title: caseItem['title']!,
    );

    if (assigned == true) {
      setState(() {
        _mockInbox.remove(caseItem);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: TranslationHelper.translate(context, 'Transfer Inbox'),
        subtitle: '${_mockInbox.length} pending cases',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: _mockInbox.isEmpty
          ? Center(
              child: Text(
                TranslationHelper.translate(context, 'No pending transfers.'),
                style: GoogleFonts.poppins(
                    color: AppColors.lightSubText, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _mockInbox.length,
              itemBuilder: (context, index) {
                final item = _mockInbox[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openAssignDialog(item),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['caseNumber']!,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.warningOrange
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Pending Assignment',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warningOrange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['title']!,
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: AppColors.navyMid),
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(Icons.arrow_circle_right_rounded,
                                  size: 16, color: AppColors.lightSubText),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'From: ${item['fromStation']}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, color: AppColors.navyMid),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded,
                                  size: 16, color: AppColors.lightSubText),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'By: ${item['transferredBy']} on ${item['date']}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppColors.lightSubText),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Remark: ${item['remark']}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.navyMid,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () => _openAssignDialog(item),
                              icon: const Icon(Icons.assignment_ind_rounded,
                                  size: 18),
                              label: Text(
                                TranslationHelper.translate(
                                    context, 'Review & Assign'),
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navyDark,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
