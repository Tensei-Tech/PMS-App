import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// Import the paginated case list view, which handles its own fetching
import 'disposal_case_list_view.dart';

class FilteredDisposalScreen extends StatelessWidget {
  final String title;
  final String? ioUid;
  final String? startDate;
  final String? endDate;
  final String? crimeType;

  const FilteredDisposalScreen({
    super.key,
    required this.title,
    this.ioUid,
    this.startDate,
    this.endDate,
    this.crimeType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Column(
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
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: DisposalCaseListView(
                ioUid: ioUid,
                startDate: startDate,
                endDate: endDate,
                crimeType: crimeType,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
