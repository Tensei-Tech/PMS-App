import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../modules/core/models/base_record.dart';
import '../../../providers/auth_provider.dart';
import '../../../screens/module_hub_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/pdf_auth_gate.dart';
import '../../../utils/translation_helper.dart';
import '../providers/mpda_provider.dart';
import '../utils/mpda_form_pdf.dart';
import '../widgets/mpda_form.dart';

const String kMpdaFormExtraFieldsKey = 'mpdaForm';

class MpdaFormScreen extends StatefulWidget {
  final String moduleLabel;
  final String? subCategory;
  final ModuleRecord? existingRecord;
  final bool? readOnly;

  const MpdaFormScreen({
    super.key,
    required this.moduleLabel,
    this.subCategory,
    this.existingRecord,
    this.readOnly = false,
  });

  @override
  State<MpdaFormScreen> createState() => _MpdaFormScreenState();
}

class _MpdaFormScreenState extends State<MpdaFormScreen> {
  final GlobalKey<MpdaFormViewState> _mpdaFormKey =
      GlobalKey<MpdaFormViewState>();
  bool _isSaving = false;

  bool get _isEdit => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final provider = context.read<MpdaProvider>();
      final station = auth.activeStation.isNotEmpty
          ? auth.activeStation
          : (auth.stationName.isNotEmpty
              ? auth.stationName
              : (auth.homeStationName.isNotEmpty ? auth.homeStationName : ''));
      if (station.isNotEmpty) {
        provider.setStationId(station, createdBy: auth.uid);
      }
    });
  }

  Future<void> _exportPdf() async {
    final form = _mpdaFormKey.currentState;
    if (form == null) return;

    final doc = form.buildDocumentMap();
    final auth = context.read<AuthProvider>();
    final stationName = _isEdit
        ? widget.existingRecord!.stationName
        : auth.stationName.isNotEmpty
            ? auth.stationName
            : context.read<MpdaProvider>().stationId;

    await runWithPdfAuthGate(
      context,
      () => MpdaFormPdfHelper.printPdf(
        data: doc,
        policeStation: stationName,
        district: auth.district,
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final form = _mpdaFormKey.currentState;
    if (form == null) return;

    final auth = context.read<AuthProvider>();
    final provider = context.read<MpdaProvider>();

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

    final docMap = form.buildDocumentMap();
    final extra = Map<String, dynamic>.from(
      widget.existingRecord?.extraFields ?? {},
    );
    extra[kMpdaFormExtraFieldsKey] = docMap['mpdaForm'] ?? docMap;
    extra.addAll(docMap);
    extra['moduleDisplayName'] = widget.moduleLabel;
    extra['lastEditedByUid'] = auth.uid;
    extra['lastEditedByName'] = auth.displayName;
    extra['lastEditedByDesignation'] = auth.designation;
    extra['lastEditedAt'] = DateTime.now().toIso8601String();

    final accusedName = (docMap['accusedName']?.toString() ?? '').trim();
    final proposalNo = (docMap['proposalNo']?.toString() ?? '').trim();
    final proposalYear = (docMap['proposalYear']?.toString() ?? '').trim();

    String title;
    if (accusedName.isNotEmpty && proposalNo.isNotEmpty) {
      title = '$accusedName (MPDA No. $proposalNo/$proposalYear)';
    } else if (accusedName.isNotEmpty) {
      title = accusedName;
    } else if (proposalNo.isNotEmpty) {
      title = 'MPDA Proposal #$proposalNo/$proposalYear';
    } else {
      title = 'MPDA Proposal';
    }

    final outcome = docMap['proposalOutcome']?.toString() ?? 'Pending';
    String status = 'Open';
    if (outcome == 'Granted') {
      status = 'Approved';
    } else if (outcome == 'Rejected') {
      status = 'Rejected';
    } else if (docMap['detentionRevoked'] == 'Yes') {
      status = 'Revoked';
    }

    DateTime incidentDate = DateTime.now();
    final outDateStr = docMap['outcomeDate']?.toString().trim() ?? '';
    if (outDateStr.isNotEmpty) {
      final parts = outDateStr.split('/');
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
      moduleKey: 'mpda',
      title: title,
      caseNumber: proposalNo.isNotEmpty ? '$proposalNo/$proposalYear' : '',
      description:
          'MPDA Proposal — Category: ${docMap['mpdaCategory'] ?? '—'} | Authority: ${docMap['detainingAuthority'] ?? '—'}',
      complainant: docMap['investigation']?['ioName']?.toString() ?? '',
      accused: accusedName,
      location: docMap['jailName']?.toString() ?? '',
      incidentDate:
          _isEdit ? widget.existingRecord!.incidentDate : incidentDate,
      priority: 'High',
      status: status,
      assignedOfficer:
          _isEdit ? widget.existingRecord!.assignedOfficer : auth.displayName,
      subCategory: widget.subCategory,
      createdAt: _isEdit ? widget.existingRecord!.createdAt : DateTime.now(),
      extraFields: extra,
      stationName: stationName,
      createdBy: createdBy,
      assignedOfficerUid:
          _isEdit ? widget.existingRecord!.assignedOfficerUid : auth.uid,
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
              ? 'MPDA Proposal updated successfully!'
              : 'MPDA Proposal registered successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppColors.successGreen,
      ));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Failed to save record: $e',
          style: GoogleFonts.poppins(),
        ),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.navyDark, size: 20),
        ),
        title: Text(
          widget.readOnly == true
              ? 'View MPDA Proposal'
              : (_isEdit ? 'Edit MPDA Proposal' : 'New MPDA Entry'),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
          ),
        ),
      ),
      body: MpdaFormView(
        formKey: _mpdaFormKey,
        initialData: widget.existingRecord?.extraFields,
        defaultStation: context.read<AuthProvider>().stationName,
        isReadOnly: widget.readOnly == true,
        onExportPdf: _exportPdf,
        onSave: _submit,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.readOnly != true) ...[
                SizedBox(
                  width: 95,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            TranslationHelper.translate(context, 'Done'),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              SizedBox(
                width: widget.readOnly == true ? 180 : 110,
                height: 46,
                child: OutlinedButton(
                  onPressed: _exportPdf,
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFF1E293B), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf_outlined,
                          color: Color(0xFF1E293B), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        TranslationHelper.translate(context,
                            widget.readOnly == true ? 'Download PDF' : 'PDF'),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.readOnly != true) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 125,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ModuleHubScreen(
                            moduleLabel: widget.moduleLabel,
                            moduleKey: 'mpda',
                            subCategory: widget.subCategory,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFF1E293B), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_rounded,
                            color: Color(0xFF1E293B), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          TranslationHelper.translate(context, 'History'),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
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
