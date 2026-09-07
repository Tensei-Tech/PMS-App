// lib/widgets/officer_details_dialog.dart
// Executive Officer Registration Form Details Dialog with Smart N/A and Not Submitted tags.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class OfficerDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> officerData;
  final Function(String uid, String name)? onApprove;
  final Function(String uid, String name)? onReject;
  final bool isBusy;

  const OfficerDetailsDialog({
    super.key,
    required this.officerData,
    this.onApprove,
    this.onReject,
    this.isBusy = false,
  });

  static void show(
    BuildContext context, {
    required Map<String, dynamic> officerData,
    Function(String uid, String name)? onApprove,
    Function(String uid, String name)? onReject,
    bool isBusy = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => OfficerDetailsDialog(
        officerData: officerData,
        onApprove: onApprove,
        onReject: onReject,
        isBusy: isBusy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = officerData['registration_uid']?.toString() ??
        officerData['uid']?.toString() ??
        '';
    final name = officerData['name']?.toString() ??
        officerData['title']?.toString() ??
        'Officer';
    final desig = officerData['designation']?.toString() ?? '';
    final email = officerData['email']?.toString() ?? '';
    final phone = officerData['phone']?.toString() ?? '';
    final badge = officerData['badge_number']?.toString() ??
        officerData['govt_id']?.toString() ??
        '';
    final roleId = officerData['role_id']?.toString() ?? '';
    final station = officerData['target_station']?.toString() ??
        officerData['station_name']?.toString() ??
        '';
    final district = officerData['target_district']?.toString() ??
        officerData['district']?.toString() ??
        '';
    final divName = officerData['division_name']?.toString() ?? '';
    final photoUrl = officerData['photo_url']?.toString() ?? '';
    final idCardUrl = officerData['id_card_url']?.toString() ?? '';

    // Smart logic for Station/Division applicability based on role
    final isStateLevel = roleId.contains('state') ||
        roleId.contains('dgp') ||
        roleId.contains('master') ||
        desig.toLowerCase().contains('ig') ||
        desig.toLowerCase().contains('cp');
    final isDivLevel = roleId.contains('div') ||
        desig.toLowerCase().contains('dig') ||
        desig.toLowerCase().contains('sp');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Column(
          children: [
            // ── DIALOG HEADER ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.navyDark,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.goldPrimary.withValues(
                      alpha: 0.2,
                    ),
                    child: const Icon(
                      Icons.badge_rounded,
                      color: AppColors.goldLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Officer Registration Details',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Full registration submission review',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── BODY CONTENT ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.navyDark.withValues(
                              alpha: 0.1,
                            ),
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl.isEmpty
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 28,
                                    color: AppColors.navyDark,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isNotEmpty
                                      ? name
                                      : 'Officer Registration Request',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navyDark,
                                  ),
                                ),
                                if (desig.isNotEmpty)
                                  Text(
                                    desig,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.orange.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    'STATUS: PENDING APPROVAL',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _sectionTitle('PERSONAL & CONTACT INFORMATION'),
                    const SizedBox(height: 8),

                    _detailRow('Full Name', name),
                    _detailRow('Government Email', email),
                    _detailRow('Phone Number', phone),
                    _detailRow('Rank / Designation', desig),
                    _detailRow('Badge No. / Govt ID', badge),

                    const SizedBox(height: 16),
                    _sectionTitle('JURISDICTION & ASSIGNMENT'),
                    const SizedBox(height: 8),

                    _detailRow('State Jurisdiction', 'Maharashtra (MH)'),
                    _detailRow(
                      'Police Division',
                      divName.isNotEmpty
                          ? divName
                          : (isStateLevel
                              ? 'Not Applicable (State Admin)'
                              : ''),
                    ),
                    _detailRow(
                      'District Range',
                      district.isNotEmpty
                          ? district
                          : (isStateLevel
                              ? 'Not Applicable (State Admin)'
                              : ''),
                    ),
                    _detailRow(
                      'Police Station',
                      station.isNotEmpty
                          ? station
                          : ((isStateLevel || isDivLevel)
                              ? 'Not Applicable (High Rank / Command)'
                              : ''),
                    ),

                    const SizedBox(height: 16),
                    _sectionTitle('VERIFICATION DOCUMENTS'),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _documentPreview(
                            label: 'Profile Photo',
                            url: photoUrl,
                            icon: Icons.portrait_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _documentPreview(
                            label: 'Official ID Card',
                            url: idCardUrl,
                            icon: Icons.badge_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── FOOTER ACTION BUTTONS ──
            if (onApprove != null || onReject != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    if (onReject != null)
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: OutlinedButton.icon(
                            onPressed: isBusy
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    onReject!(uid, name);
                                  },
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: Text(
                              'Reject Request',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.dangerRed,
                              side: BorderSide(
                                color: AppColors.dangerRed.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (onReject != null && onApprove != null)
                      const SizedBox(width: 12),
                    if (onApprove != null)
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: FilledButton.icon(
                            onPressed: isBusy
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    onApprove!(uid, name);
                                  },
                            icon: isBusy
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 16),
                            label: Text(
                              'Approve Officer',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.successGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: AppColors.navyDark,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final isEmpty = value.trim().isEmpty;
    final isNotApplicable = value.contains('Not Applicable');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isNotApplicable
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Not Applicable',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  )
                : isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Not Submitted',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _documentPreview({
    required String label,
    required String url,
    required IconData icon,
  }) {
    final hasUrl = url.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 84,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasUrl
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) =>
                      _noDocWidget('Image Load Error'),
                )
              : _noDocWidget('Not Submitted'),
        ),
      ],
    );
  }

  Widget _noDocWidget(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 20,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 2),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
