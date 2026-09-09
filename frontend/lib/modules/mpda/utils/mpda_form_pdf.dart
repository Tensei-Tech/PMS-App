import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../utils/common_form_pdf.dart';

class MpdaFormPdfHelper {
  /// Generates printable PDF bytes for an MPDA Proposal record.
  static Future<Uint8List> generatePdf({
    required Map<String, dynamic> data,
    String? policeStation,
    String? district,
  }) async {
    final formMap = (data['mpdaForm'] is Map<String, dynamic>)
        ? data['mpdaForm'] as Map<String, dynamic>
        : data;

    final proposal = formMap['proposal'] as Map<String, dynamic>? ?? {};
    final accused = formMap['accused'] as Map<String, dynamic>? ?? {};
    final gang = formMap['gangMembers'] as List<dynamic>? ?? [];
    final inv = formMap['investigation'] as Map<String, dynamic>? ?? {};
    final det = formMap['detention'] as Map<String, dynamic>? ?? {};
    final crime = formMap['crimeChart'] as Map<String, dynamic>? ?? {};

    final proposalNo = proposal['proposalNo'] ?? data['proposalNo'] ?? '—';
    final proposalYear =
        proposal['proposalYear'] ?? data['proposalYear'] ?? '—';
    final accusedName =
        accused['name'] ?? data['accusedName'] ?? data['title'] ?? '—';

    final subtitle = [
      if (policeStation != null && policeStation.isNotEmpty) policeStation,
      if (district != null && district.isNotEmpty) district,
      'Maharashtra Police · Preventive Detention',
    ].join(' · ');

    // Use common form PDF generator for structured A4 multi-page document
    return await generateFormPdf(
      {
        '1. MPDA Proposal & Category': {
          'Proposal No.': proposalNo,
          'Proposal Year': proposalYear,
          'MPDA Category': proposal['mpdaCategory'] ?? '—',
          if ((proposal['otherCategory']?.toString() ?? '').isNotEmpty)
            'Other Category Details': proposal['otherCategory'],
        },
        '2. Accused KYC Details': {
          'Full Name': accusedName,
          'Age': accused['age'] ?? '—',
          'Gender': accused['gender'] ?? '—',
          'Mobile No.': accused['mobile'] ?? '—',
          'Aadhaar Card No.': accused['aadhaar'] ?? '—',
          'PAN Card No.': accused['pan'] ?? '—',
          'Address / KYC': accused['address'] ?? '—',
        },
        if (gang.isNotEmpty)
          '3. Gang / Group Members': {
            for (int i = 0; i < gang.length; i++)
              'Member #${i + 1}':
                  'Name: ${gang[i]['name'] ?? '—'} | Role: ${gang[i]['role'] ?? '—'} | Phone: ${gang[i]['phone'] ?? '—'}'
          },
        '4. Investigating Officer & Sanction': {
          'IO Name': inv['ioName'] ?? '—',
          'IO Post': inv['ioPost'] ?? '—',
          'Proposal Outcome': inv['proposalOutcome'] ?? '—',
          'Outcome Decision Date': inv['outcomeDate'] ?? '—',
          'Detaining Authority': inv['detainingAuthority'] ?? '—',
          if ((inv['otherAuthority']?.toString() ?? '').isNotEmpty)
            'Other Authority Details': inv['otherAuthority'],
        },
        '5. Detention Status': {
          'Detained (Y/N)': det['isDetained'] ?? '—',
          'Detention Date': det['detentionDate'] ?? '—',
          'Detention Completion Date': det['detentionCompletionDate'] ?? '—',
          'Jail Name': det['jailName'] ?? '—',
          'Transfer Jail Name': det['transferJailName'] ?? '—',
          'Govt Confirmation (Y/N)': det['govtConfirmation'] ?? '—',
          'Govt Confirmation Date': det['govtConfirmationDate'] ?? '—',
          'Detention Order Revoked (Y/N)': det['detentionRevoked'] ?? '—',
          'Revocation Date': det['detentionRevokedDate'] ?? '—',
        },
        '6. Crime Chart Summary': {
          'Total Crime Count': crime['totalCrime'] ?? '000',
          'Serious Crimes Count': crime['seriousCrimes'] ?? '000',
        },
        if (crime['categories'] is Map)
          '7. Crime Chart Category Details': {
            for (final catEntry in (crime['categories'] as Map).entries)
              if (catEntry.value is List && (catEntry.value as List).isNotEmpty)
                catEntry.key.toString(): (catEntry.value as List)
                    .asMap()
                    .entries
                    .map((e) =>
                        'Case #${e.key + 1}: CR No. ${e.value['crNo'] ?? '—'}, Date: ${e.value['date'] ?? '—'}, PS: ${e.value['ps'] ?? '—'}')
                    .join('\n')
          },
      },
      formTitle:
          'MAHARASHTRA PREVENTION OF DANGEROUS ACTIVITIES (MPDA) PROPOSAL',
      formSubtitle: subtitle,
    );
  }

  /// Direct print method using the Printing package.
  static Future<void> printPdf({
    required Map<String, dynamic> data,
    String? policeStation,
    String? district,
  }) async {
    final bytes = await generatePdf(
      data: data,
      policeStation: policeStation,
      district: district,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name:
          'MPDA_Proposal_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
  }
}
