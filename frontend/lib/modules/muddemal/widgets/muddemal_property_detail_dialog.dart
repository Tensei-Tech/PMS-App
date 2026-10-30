// ignore_for_file: deprecated_member_use, prefer_const_constructors, use_build_context_synchronously
// lib/modules/muddemal/widgets/muddemal_property_detail_dialog.dart
// Detailed view for an individual Muddemal property:
// Dynamic extra attributes, chain of custody timeline, FSL tracking, disposal actions, and audit trail.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../models/muddemal_models.dart';
import '../providers/muddemal_provider.dart';
import '../../../providers/auth_provider.dart';
import 'muddemal_property_form_dialog.dart';

class MuddemalPropertyDetailDialog extends StatefulWidget {
  final MuddemalPropertyItem property;

  const MuddemalPropertyDetailDialog({super.key, required this.property});

  @override
  State<MuddemalPropertyDetailDialog> createState() =>
      _MuddemalPropertyDetailDialogState();
}

class _MuddemalPropertyDetailDialogState
    extends State<MuddemalPropertyDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MuddemalPropertyItem _property;
  List<Map<String, dynamic>> _auditTrail = [];
  bool _loadingAudit = false;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
    _tabController = TabController(length: 5, vsync: this);
    _loadAuditTrail();
  }

  Future<void> _loadAuditTrail() async {
    setState(() => _loadingAudit = true);
    final provider = context.read<MuddemalProvider>();
    final logs = await provider.fetchAuditTrail(_property.id);
    if (mounted) {
      setState(() {
        _auditTrail = logs;
        _loadingAudit = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Recovered':
      case 'Returned to Owner':
      case 'Released on Supurdnama':
        return AppColors.successGreen;
      case 'Stolen – Not Recovered':
        return AppColors.dangerRed;
      case 'Partially Recovered':
      case 'FSL Report Pending':
        return AppColors.warningOrange;
      case 'Sent to FSL':
        return const Color(0xFF7C3AED);
      case 'Produced Before Court':
        return const Color(0xFF0891B2);
      default:
        return AppColors.navyMid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MuddemalProvider>();
    // Synchronize latest property from provider if available
    final latestProp = provider.properties.firstWhere(
      (p) => p.id == _property.id,
      orElse: () => _property,
    );
    _property = latestProp;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.lightSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 900),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            () {
                              try {
                                final d = _property.displayCrNumber;
                                if (d.isNotEmpty) return d;
                              } catch (_) {}
                              final u = _property.propertyUid;
                              final match = RegExp(r'(CR-[0-9A-Za-z]+/\d{4})')
                                  .firstMatch(u);
                              if (match != null) return match.group(1)!;
                              return u.isNotEmpty ? u : 'CR-Property';
                            }(),
                            style: GoogleFonts.poppins(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_property.propertyStatus)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    _getStatusColor(_property.propertyStatus),
                              ),
                            ),
                            child: Text(
                              _property.propertyStatus,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    _getStatusColor(_property.propertyStatus),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Category: ${_property.categoryName} | Source Tab: ${_property.sourceModuleDisplayName.isNotEmpty ? _property.sourceModuleDisplayName : 'Crime'} | Register: ${_property.registerNo}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.lightSubText,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: Text('Edit',
                            style: GoogleFonts.poppins(fontSize: 12)),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => MuddemalPropertyFormDialog(
                              existingProperty: _property,
                            ),
                          );
                          if (ok == true && mounted) {
                            final provider = context.read<MuddemalProvider>();
                            final updated = provider.properties
                                .where((p) => p.id == _property.id)
                                .firstOrNull;
                            if (updated != null) {
                              setState(() => _property = updated);
                            }
                            _loadAuditTrail();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // KPI Metric Cards
              Row(
                children: [
                  _buildMetricCard(
                    'Assessed Valuation',
                    '₹${NumberFormat('#,##,###').format(_property.totalItemValue)}',
                    Icons.currency_rupee_rounded,
                    AppColors.goldDark,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    'Quantity & Unit',
                    '${_property.quantity} ${_property.unit}',
                    Icons.straighten_rounded,
                    AppColors.navyMid,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    'Seized / Recovered From',
                    _property.seizedFrom.isNotEmpty
                        ? _property.seizedFrom
                        : 'N/A',
                    Icons.person_pin_circle_rounded,
                    AppColors.infoBlue,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    'FSL Required',
                    _property.fslRequired ? 'Yes (Forensic)' : 'No',
                    Icons.biotech_rounded,
                    _property.fslRequired
                        ? const Color(0xFF7C3AED)
                        : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: AppColors.navyMid,
                unselectedLabelColor: AppColors.lightSubText,
                indicatorColor: AppColors.navyMid,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13),
                tabs: [
                  Tab(
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      text:
                          context.read<MuddemalProvider>().attributesTabLabel),
                  const Tab(
                      icon: Icon(Icons.timeline_rounded, size: 18),
                      text: 'Custody Chain'),
                  const Tab(
                      icon: Icon(Icons.biotech_rounded, size: 18),
                      text: 'FSL History'),
                  const Tab(
                      icon: Icon(Icons.gavel_rounded, size: 18),
                      text: 'Disposal & Supurdnama'),
                  const Tab(
                      icon: Icon(Icons.history_edu_rounded, size: 18),
                      text: 'Audit Trail'),
                ],
              ),
              const SizedBox(height: 12),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAttributesTab(),
                    _buildCustodyChainTab(),
                    _buildFslTab(),
                    _buildDisposalTab(),
                    _buildAuditTrailTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.lightSubText),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: Dynamic Attributes (Common Master Form + Category-Specific Attributes)
  Widget _buildAttributesTab() {
    final currencyFormat = NumberFormat('#,##,###');
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Common Master Form (Exact 21 Fields)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.navyDark.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.navyDark.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_rounded,
                      size: 18, color: AppColors.navyMid),
                  const SizedBox(width: 8),
                  Text(
                    'Common Master Form Details',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.navyDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
                'CR No.',
                _property.displayCrNumber.isNotEmpty
                    ? _property.displayCrNumber
                    : _property.propertyUid),
            _buildDetailRow(
                'Section-Act',
                _property.actSection.isNotEmpty
                    ? _property.actSection
                    : 'IPC / BNS'),
            _buildDetailRow(
                'Nature / Type of Crime',
                _property.natureOfCrime.isNotEmpty
                    ? _property.natureOfCrime
                    : 'Case Property'),
            _buildDetailRow('IO Name',
                _property.ioName.isNotEmpty ? _property.ioName : '—'),
            _buildDetailRow('Date of Seizure/Stolen',
                _property.seizureDate ?? 'Not Recorded'),
            _buildDetailRow(
                'Property / Muddemal Description', _property.description),
            _buildDetailRow(
                'Quantity', '${_property.quantity} ${_property.unit}'),
            _buildDetailRow('Value of Property',
                '₹${currencyFormat.format(_property.unitValue)}'),
            _buildDetailRow('Total Property Value',
                '₹${currencyFormat.format(_property.totalItemValue)}'),
            _buildDetailRow('Owner Name',
                _property.ownerName.isNotEmpty ? _property.ownerName : '—'),
            _buildDetailRow('From Whom Seized / Recovered',
                _property.seizedFrom.isNotEmpty ? _property.seizedFrom : '—'),
            _buildDetailRow(
                'Not Recovered', _property.notRecovered ? 'Yes' : 'No'),
            _buildDetailRow(
                'FSL Required', _property.fslRequired ? 'Yes' : 'No'),
            _buildDetailRow(
                'FSL Sent Date', _property.fslSentDate ?? 'Not Sent'),
            _buildDetailRow('FSL Report Received',
                _property.fslReportReceived ? 'Yes' : 'No'),
            _buildDetailRow('FSL Report Received Date',
                _property.fslReportReceivedDate ?? 'Pending'),
            _buildDetailRow(
                'Disposal Date', _property.disposalDate ?? 'Pending'),
            _buildDetailRow('Destroyed', _property.destroyed ? 'Yes' : 'No'),
            _buildDetailRow('Remarks',
                _property.remarks.isNotEmpty ? _property.remarks : '—'),
            _buildDetailRow('Released on Supurdnama',
                _property.releasedOnSupurdnama ? 'Yes' : 'No'),
            _buildDetailRow(
                'Returned to Owner', _property.returnedToOwner ? 'Yes' : 'No'),

            const Divider(height: 28),

            // Section 2: Category-Specific Dynamic Attributes
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.goldDark.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.goldDark.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category_rounded,
                      size: 18, color: AppColors.goldDark),
                  const SizedBox(width: 8),
                  Text(
                    '${context.read<MuddemalProvider>().categorySpecificInfoLabel} (${_property.categoryName})',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.navyDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (_property.categoryAttributes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Text(
                  'No additional ${_property.categoryName.toLowerCase()} details or information recorded for this item.',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.lightSubText),
                ),
              )
            else
              ..._property.categoryAttributes.entries.map((e) {
                final formattedKey = e.key
                    .replaceAll('_', ' ')
                    .split(' ')
                    .map((w) => w.isNotEmpty
                        ? '${w[0].toUpperCase()}${w.substring(1)}'
                        : '')
                    .join(' ');
                return _buildDetailRow(
                    formattedKey, e.value?.toString() ?? '—');
              }),
          ],
        ),
      ),
    );
  }

  // TAB 2: Custody Chain (Movements)
  Widget _buildCustodyChainTab() {
    final movements = _property.movements;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Complete Append-Only Chain of Custody (${movements.length} movements):',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark,
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt_rounded, size: 16),
              label: Text('Record Movement',
                  style: GoogleFonts.poppins(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyMid,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () => _showRecordMovementDialog(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: movements.isEmpty
              ? Center(
                  child: Text(
                    'No custody movements recorded yet.',
                    style: GoogleFonts.poppins(color: AppColors.lightSubText),
                  ),
                )
              : ListView.builder(
                  itemCount: movements.length,
                  itemBuilder: (context, i) {
                    final m = movements[i];
                    return Card(
                      elevation: 0,
                      color: Colors.grey.withOpacity(0.04),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                            color:
                                AppColors.lightBorder.withValues(alpha: 0.5)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.navyMid.withOpacity(0.1),
                          child: const Icon(Icons.swap_horiz_rounded,
                              color: AppColors.navyMid),
                        ),
                        title: Text(
                          '${m.fromLocation} ➔ ${m.toLocation}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.navyDark,
                          ),
                        ),
                        subtitle: Text(
                          'Type: ${m.movementType} | Officer: ${m.responsibleOfficer} | Ref: ${m.referenceNo.isNotEmpty ? m.referenceNo : '—'}\nDate: ${m.movementDate.split('T').first}',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.lightSubText),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 3: FSL History
  Widget _buildFslTab() {
    final fslList = _property.fslRecords;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Forensic Science Laboratory (FSL) History:',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text('Dispatch to FSL',
                  style: GoogleFonts.poppins(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () => _showRecordFslDialog(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: fslList.isEmpty
              ? Center(
                  child: Text(
                    _property.fslRequired
                        ? 'FSL required but no dispatch recorded yet (Alert Active).'
                        : 'No FSL examination recorded for this property.',
                    style: GoogleFonts.poppins(color: AppColors.lightSubText),
                  ),
                )
              : ListView.builder(
                  itemCount: fslList.length,
                  itemBuilder: (context, i) {
                    final f = fslList[i];
                    final isPending = f.reportReceivedStatus == 'Pending';
                    return Card(
                      elevation: 0,
                      color: isPending
                          ? AppColors.warningOrange.withOpacity(0.06)
                          : AppColors.successGreen.withOpacity(0.06),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isPending
                              ? AppColors.warningOrange.withValues(alpha: 0.3)
                              : AppColors.successGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isPending
                                  ? Icons.pending_actions_rounded
                                  : Icons.verified_rounded,
                              color: isPending
                                  ? AppColors.warningOrange
                                  : AppColors.successGreen,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Ref: ${f.fslReferenceNo}',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppColors.navyDark,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isPending
                                              ? AppColors.warningOrange
                                              : AppColors.successGreen,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          f.reportReceivedStatus,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Dispatched: ${f.dispatchDate} | Details: ${f.dispatchDetails}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.lightSubText),
                                  ),
                                  if (!isPending) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Report Received: ${f.reportReceivedDate ?? '—'} | Report Ref: ${f.reportReference}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.successGreen,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isPending)
                              TextButton.icon(
                                icon: const Icon(Icons.check_circle_outline,
                                    size: 16),
                                label: Text('Receive Report',
                                    style: GoogleFonts.poppins(fontSize: 11)),
                                onPressed: () => _showReceiveReportDialog(f.id),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 4: Disposal & Supurdnama
  Widget _buildDisposalTab() {
    final disposals = _property.disposals;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Final Disposal & Supurdnama Records:',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.handshake_rounded, size: 16),
              label: Text('Record Disposal / Release',
                  style: GoogleFonts.poppins(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyDark,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () => _showRecordDisposalDialog(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: disposals.isEmpty
              ? Center(
                  child: Text(
                    'Property is currently in active custody (Not Disposed / Released).',
                    style: GoogleFonts.poppins(color: AppColors.lightSubText),
                  ),
                )
              : ListView.builder(
                  itemCount: disposals.length,
                  itemBuilder: (context, i) {
                    final d = disposals[i];
                    return Card(
                      elevation: 0,
                      color: AppColors.successGreen.withOpacity(0.06),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                            color:
                                AppColors.successGreen.withValues(alpha: 0.3)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.verified_rounded,
                            color: AppColors.successGreen),
                        title: Text(
                          d.disposalType,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.navyDark,
                          ),
                        ),
                        subtitle: Text(
                          'Court Order: ${d.courtOrderReference.isNotEmpty ? d.courtOrderReference : 'N/A'}\nDisposal Date: ${d.disposalDate} | Auth: ${d.authorizationDetails}',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.lightSubText),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAuditTrailTab() {
    if (_loadingAudit) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_auditTrail.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded,
                size: 48, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No audit records yet.',
                style: GoogleFonts.poppins(color: AppColors.lightSubText)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _auditTrail.length,
      itemBuilder: (ctx, i) {
        final log = _auditTrail[i];
        final action = log['action']?.toString() ?? 'ACTION';
        final by = log['performed_by_name']?.toString() ??
            log['performed_by']?.toString() ??
            'System';
        final createdAt = log['created_at']?.toString() ?? '';
        final details = log['details'] is Map ? log['details'] as Map : {};

        return Card(
          elevation: 0,
          color: Colors.grey.withValues(alpha: 0.04),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side:
                BorderSide(color: AppColors.lightBorder.withValues(alpha: 0.5)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.goldPrimary.withValues(alpha: 0.15),
              child: const Icon(Icons.shield_outlined,
                  color: AppColors.goldDark, size: 20),
            ),
            title: Text(action,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.navyDark)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('By: $by | $createdAt',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.lightSubText)),
                if (details.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      details.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join(', '),
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.navyMid),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.lightSubText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.navyDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog to record custody movement
  void _showRecordMovementDialog() {
    final provider = context.read<MuddemalProvider>();
    final auth = context.read<AuthProvider>();
    final locations = provider.movementLocations;
    final types = provider.movementTypes;
    final statuses = provider.propertyStatuses;

    final defaultFrom = _property.currentCustodyLocation.isNotEmpty
        ? _property.currentCustodyLocation
        : (locations.isNotEmpty ? locations.first : '');
    final defaultTo = locations.length > 1
        ? locations[1]
        : (locations.isNotEmpty ? locations.first : '');
    final fromCtrl = TextEditingController(text: defaultFrom);
    final toCtrl = TextEditingController(text: defaultTo);
    String movementType = types.isNotEmpty ? types.first : '';
    final defaultOfficer = auth.displayName.isNotEmpty
        ? auth.displayName
        : (auth.fullName.isNotEmpty ? auth.fullName : '');
    final officerCtrl = TextEditingController(text: defaultOfficer);
    final refCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    String newStatus = statuses.contains('Produced Before Court')
        ? 'Produced Before Court'
        : (statuses.isNotEmpty ? statuses.first : '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('Record Custody Movement',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: types.contains(movementType)
                      ? movementType
                      : (types.isNotEmpty ? types.first : null),
                  decoration:
                      const InputDecoration(labelText: 'Movement Type *'),
                  items: types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      setStateDialog(() => movementType = v ?? movementType),
                ),
                const SizedBox(height: 10),
                TextFormField(
                    controller: fromCtrl,
                    decoration:
                        const InputDecoration(labelText: 'From Location *')),
                const SizedBox(height: 10),
                TextFormField(
                    controller: toCtrl,
                    decoration:
                        const InputDecoration(labelText: 'To Location *')),
                const SizedBox(height: 10),
                TextFormField(
                    controller: officerCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Responsible Officer *')),
                const SizedBox(height: 10),
                TextFormField(
                    controller: refCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Receipt / Reference No')),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                TextFormField(
                    controller: remarksCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Remarks / Movement Notes')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: statuses.contains(newStatus)
                      ? newStatus
                      : (statuses.isNotEmpty
                          ? statuses.first
                          : 'Produced Before Court'),
                  decoration: const InputDecoration(
                      labelText: 'Update Property Status To:'),
                  items: statuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) =>
                      setStateDialog(() => newStatus = v ?? newStatus),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyMid,
                  foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await provider.recordMovement(_property.id, {
                  'from_location': fromCtrl.text.trim(),
                  'to_location': toCtrl.text.trim(),
                  'movement_type': movementType,
                  'responsible_officer': officerCtrl.text.trim(),
                  'reference_no': refCtrl.text.trim(),
                  'remarks': remarksCtrl.text.trim(),
                  'new_property_status': newStatus,
                });
                if (ok && mounted) {
                  _loadAuditTrail();
                }
              },
              child: const Text('Save Movement'),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog to record FSL dispatch
  void _showRecordFslDialog() async {
    final provider = context.read<MuddemalProvider>();
    final reasons = provider.fslDispatchReasons;
    final defaultReason = reasons.isNotEmpty ? reasons.first : '';

    final refCtrl = TextEditingController();
    final detailsCtrl = TextEditingController(text: defaultReason);

    // Asynchronously fetch atomic backend-generated FSL reference
    final nextRef = await provider.getNextFslReference(_property.id);
    if (nextRef != null && nextRef.isNotEmpty) {
      refCtrl.text = nextRef;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('Dispatch Property to FSL',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                  controller: refCtrl,
                  decoration: const InputDecoration(
                      labelText: 'FSL Reference / Dispatch No *',
                      hintText: 'Auto-generated by backend')),
              const SizedBox(height: 10),
              if (reasons.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: reasons.contains(detailsCtrl.text)
                      ? detailsCtrl.text
                      : reasons.first,
                  decoration: const InputDecoration(
                      labelText: 'Dispatch Reason (Database Options)'),
                  items: reasons
                      .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setStateDialog(() => detailsCtrl.text = v);
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
              TextFormField(
                  controller: detailsCtrl,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Dispatch Details *')),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await provider.recordFSL(_property.id, {
                  'fsl_reference_no': refCtrl.text.trim(),
                  'dispatch_details': detailsCtrl.text.trim(),
                });
                if (ok && mounted) {
                  _loadAuditTrail();
                }
              },
              child: const Text('Confirm Dispatch'),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog to receive FSL report
  void _showReceiveReportDialog(int fslRecordId) {
    final provider = context.read<MuddemalProvider>();
    final statuses = provider.fslReportStatuses;
    final repRefCtrl = TextEditingController();
    String reportStatus =
        statuses.isNotEmpty ? statuses.first.code : 'Received';
    final remarksCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('Receive FSL Report',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: statuses.any((s) => s.code == reportStatus)
                    ? reportStatus
                    : (statuses.isNotEmpty ? statuses.first.code : null),
                decoration: const InputDecoration(labelText: 'Report Status *'),
                items: statuses
                    .map((s) => DropdownMenuItem(
                        value: s.code,
                        child: Text(s.label)))
                    .toList(),
                onChanged: (v) =>
                    setStateDialog(() => reportStatus = v ?? reportStatus),
              ),
            const SizedBox(height: 10),
            TextFormField(
                controller: repRefCtrl,
                decoration: const InputDecoration(
                    labelText: 'Lab Report Reference Number *')),
            const SizedBox(height: 10),
            TextFormField(
                controller: remarksCtrl,
                decoration:
                    const InputDecoration(labelText: 'Findings / Remarks')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await provider.recordFSL(_property.id, {
                'fsl_record_id': fslRecordId,
                'report_received_status': reportStatus,
                'report_reference': repRefCtrl.text.trim(),
                'remarks': remarksCtrl.text.trim(),
              });
              if (ok && mounted) {
                _loadAuditTrail();
              }
            },
            child: const Text('Save Report'),
          ),
        ],
      ),
    ),
  );
  }

  // Dialog to record Disposal / Supurdnama
  void _showRecordDisposalDialog() {
    final provider = context.read<MuddemalProvider>();
    final dTypes = provider.disposalTypes;
    final authorities = provider.disposalAuthorities;

    String disposalType = dTypes.isNotEmpty ? dTypes.first : '';
    final courtOrderCtrl = TextEditingController();
    final ownerNameCtrl = TextEditingController(text: _property.ownerName);
    final contactCtrl = TextEditingController();
    final bondCtrl = TextEditingController(
        text: _property.totalItemValue > 0
            ? _property.totalItemValue.toStringAsFixed(0)
            : '');
    final defaultAuth =
        authorities.isNotEmpty ? authorities.first.label : '';
    final authCtrl = TextEditingController(text: defaultAuth);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('Record Disposal / Supurdnama',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: dTypes.contains(disposalType)
                      ? disposalType
                      : (dTypes.isNotEmpty ? dTypes.first : null),
                  decoration:
                      const InputDecoration(labelText: 'Disposal Type *'),
                  items: dTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      setStateDialog(() => disposalType = v ?? disposalType),
                ),
                const SizedBox(height: 10),
                TextFormField(
                    controller: courtOrderCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Court Order Reference *')),
                const SizedBox(height: 10),
                TextFormField(
                    controller: ownerNameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Recipient / Owner Name *')),
                const SizedBox(height: 10),
                TextFormField(
                    controller: contactCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Recipient Mobile / Contact')),
                if (disposalType.contains('Supurdnama')) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: bondCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Supurdnama Bond Amount (₹)')),
                ],
                const SizedBox(height: 10),
                TextFormField(
                    controller: authCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Authorizing Court / Officer')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyDark,
                  foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await provider.recordDisposal(_property.id, {
                  'disposal_type': disposalType,
                  'court_order_reference': courtOrderCtrl.text.trim(),
                  'authorization_details': authCtrl.text.trim(),
                  'owner_recipient_details': {
                    'name': ownerNameCtrl.text.trim(),
                    'contact': contactCtrl.text.trim(),
                  },
                  'supurdnama_details': {
                    'bond_amount': double.tryParse(bondCtrl.text.trim()) ?? 0.0,
                  },
                });
                if (ok && mounted) {
                  _loadAuditTrail();
                }
              },
              child: const Text('Confirm Disposal'),
            ),
          ],
        ),
      ),
    );
  }
}
