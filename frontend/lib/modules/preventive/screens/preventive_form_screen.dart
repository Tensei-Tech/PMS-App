// lib/modules/preventive/screens/preventive_form_screen.dart
// Preventive entry and edit screen matching Form 1 to 5 styling.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../modules/core/models/base_record.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/pdf_auth_gate.dart';
import '../../../widgets/custom_pdf_preview_dialog.dart';
import '../providers/preventive_provider.dart';
import '../utils/preventive_form_pdf.dart';
import '../widgets/preventive_form.dart';

const String kPreventiveFormExtraFieldsKey = 'preventiveForm';

class PreventiveFormScreen extends StatefulWidget {
  final String moduleLabel;
  final String? subCategory;
  final ModuleRecord? existingRecord;
  final bool readOnly;

  const PreventiveFormScreen({
    super.key,
    required this.moduleLabel,
    this.subCategory,
    this.existingRecord,
    this.readOnly = false,
  });

  @override
  State<PreventiveFormScreen> createState() => _PreventiveFormScreenState();
}

class _PreventiveFormScreenState extends State<PreventiveFormScreen> {
  final GlobalKey<PreventiveFormState> _formKey = GlobalKey<PreventiveFormState>();
  bool _isSaving = false;

  bool get _isEdit => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final provider = context.read<PreventiveProvider>();
      final station = auth.activeStation.isNotEmpty
          ? auth.activeStation
          : (auth.stationName.isNotEmpty
              ? auth.stationName
              : (auth.homeStationName.isNotEmpty ? auth.homeStationName : ''));
      if (station.isNotEmpty) {
        provider.setStationId(station, createdBy: auth.uid);
      }

      final existing = widget.existingRecord;
      if (existing != null) {
        final nested = existing.extraFields[kPreventiveFormExtraFieldsKey] ??
            existing.extraFields;
        final form = _formKey.currentState;
        if (form != null && nested is Map) {
          form.hydrateFromDocumentMap(Map<String, dynamic>.from(nested));
        }
      }
    });
  }

  Future<void> _exportPdf() async {
    final form = _formKey.currentState;
    if (form == null) return;

    final doc = form.buildDocumentMap();
    final auth = context.read<AuthProvider>();
    final stationName = _isEdit
        ? widget.existingRecord!.stationName
        : auth.stationName.isNotEmpty
            ? auth.stationName
            : context.read<PreventiveProvider>().stationId;

    final crimeNo = doc['crimeNo']?.toString().trim() ?? '';
    final title = crimeNo.isNotEmpty
        ? 'Preventive Report - $crimeNo'
        : 'Preventive Action Report';

    await runWithPdfAuthGate(
      context,
      () => CustomPdfPreviewDialog.show(
        context: context,
        title: title,
        fileName: '${title.replaceAll(' ', '_')}.pdf',
        buildPdf: (format) => PreventiveFormPdfHelper.generatePdf(
          data: doc,
          policeStation: stationName,
          district: auth.district,
          format: format,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final form = _formKey.currentState;
    if (form == null) return;

    final docMap = form.buildDocumentMap();
    final crimeNo = (docMap['crimeNo']?.toString() ?? '').trim();
    final preventiveNo = (docMap['preventiveNo']?.toString() ?? '').trim();

    if (crimeNo.isEmpty && preventiveNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Crime No. / FIR No. / NC No. or Preventive No.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final provider = context.read<PreventiveProvider>();

    final stationName = _isEdit && widget.existingRecord!.stationName.isNotEmpty
        ? widget.existingRecord!.stationName
        : auth.activeStation.isNotEmpty
            ? auth.activeStation
            : auth.stationName.isNotEmpty
                ? auth.stationName
                : auth.homeStationName.isNotEmpty
                    ? auth.homeStationName
                    : provider.stationId.isNotEmpty
                        ? provider.stationId
                        : 'Default Station';

    final createdBy = _isEdit && widget.existingRecord!.createdBy.isNotEmpty
        ? widget.existingRecord!.createdBy
        : auth.uid;

    final extra = Map<String, dynamic>.from(widget.existingRecord?.extraFields ?? {});
    extra[kPreventiveFormExtraFieldsKey] = docMap;
    extra.addAll(docMap);
    extra['moduleDisplayName'] = widget.moduleLabel;
    extra['lastEditedByUid'] = auth.uid;
    extra['lastEditedByName'] = auth.displayName;
    extra['lastEditedByDesignation'] = auth.designation;
    extra['lastEditedAt'] = DateTime.now().toIso8601String();

    final accusedNames = (docMap['accusedNames']?.toString() ?? '').trim();
    final title = accusedNames.isNotEmpty
        ? '$accusedNames ${crimeNo.isNotEmpty ? '(Crime: $crimeNo)' : ''}'
        : (crimeNo.isNotEmpty
            ? 'Crime #$crimeNo (Prev No: $preventiveNo)'
            : 'Preventive Action #$preventiveNo');

    DateTime incidentDate = DateTime.now();
    final regDateStr = docMap['caseRef']?['regDate']?.toString().trim() ?? '';
    if (regDateStr.isNotEmpty) {
      final parts = regDateStr.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          try {
            incidentDate = DateTime(y, m, d);
          } catch (_) {}
        }
      }
    }

    final record = ModuleRecord(
      id: _isEdit
          ? widget.existingRecord!.id
          : '${DateTime.now().millisecondsSinceEpoch}',
      moduleKey: 'preventive',
      title: title,
      caseNumber: crimeNo.isNotEmpty ? crimeNo : preventiveNo,
      description:
          'Preventive / Istegasha: ${docMap['preventiveNo'] ?? '—'} | Category: ${docMap['caseRef']?['crimeCategory'] ?? '—'} | Action: ${docMap['actionStatus'] ?? '—'}',
      complainant: docMap['caseRef']?['crimeCategory']?.toString() ?? 'State',
      accused: accusedNames,
      location: docMap['assignedOfficer']?.toString() ?? '',
      incidentDate: _isEdit ? widget.existingRecord!.incidentDate : incidentDate,
      priority: docMap['priority']?.toString() ?? 'Standard',
      status: docMap['status']?.toString() ?? 'Under Investigation',
      assignedOfficer: docMap['assignedOfficer']?.toString() ?? auth.displayName,
      subCategory: widget.subCategory,
      createdAt: _isEdit ? widget.existingRecord!.createdAt : DateTime.now(),
      extraFields: extra,
      stationName: stationName,
      createdBy: createdBy,
      assignedOfficerUid: _isEdit ? widget.existingRecord!.assignedOfficerUid : auth.uid,
    );

    setState(() => _isSaving = true);

    try {
      if (_isEdit) {
        await provider.updateRecord(record);
      } else {
        await provider.addRecord(record);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          _isEdit
              ? 'Preventive record updated successfully!'
              : 'Preventive record registered successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppColors.successGreen,
      ));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save record: $e', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navyDark, size: 20),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.readOnly
                  ? 'View Preventive Entry'
                  : (_isEdit ? 'Edit Preventive Entry' : 'New Preventive Entry'),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            Text(
              'Preventative Action · Istegasha Record (प्रतिबंधक कारवाई / इस्तेगाशा नोंद)',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: PreventiveForm(
        key: _formKey,
        onSave: _submit,
        onExportPdf: _exportPdf,
        readOnly: widget.readOnly,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                label: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFF0EA5E9)),
                label: Text(
                  'PDF Preview',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0EA5E9),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0EA5E9)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
              if (!widget.readOnly) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                  label: Text(
                    _isSaving ? 'Saving...' : (_isEdit ? 'Update Record' : 'Done / Save Record'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
