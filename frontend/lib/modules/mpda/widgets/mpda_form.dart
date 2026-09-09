import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ── Palette (matches common_form.dart & screenshots) ─────────────────────────
const Color _kDark = Color(0xFF0F172A);
const Color _kMid = Color(0xFF1E293B);
const Color _kTeal = Color(0xFF0EA5E9);
const Color _kGreen = Color(0xFF10B981);
const Color _kRed = Color(0xFFEF4444);
const Color _kSec = Color(0xFF64748B);
const Color _kMuted = Color(0xFF94A3B8);
const Color _kInputBg = Color(0xFFF8FAFC);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kPageBg = Color(0xFFF4F7F9);

const _tsLabel = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: _kDark,
  letterSpacing: 0.3,
);
const _tsSection = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: _kDark,
  letterSpacing: 0.3,
);
const _tsMuted = TextStyle(fontSize: 11, color: _kMuted);

/// Representation of a single Crime Record entry within a Crime Chart category.
class CrimeEntry {
  final TextEditingController crNoController;
  final TextEditingController dateController;
  final TextEditingController psController;

  CrimeEntry({
    String crNo = '',
    String date = '',
    String ps = '',
  })  : crNoController = TextEditingController(text: crNo),
        dateController = TextEditingController(text: date),
        psController = TextEditingController(text: ps);

  Map<String, String> toMap() => {
        'crNo': crNoController.text.trim(),
        'date': dateController.text.trim(),
        'ps': psController.text.trim(),
      };

  void dispose() {
    crNoController.dispose();
    dateController.dispose();
    psController.dispose();
  }
}

/// Representation of a Gang / Group Member entry.
class GangMemberEntry {
  final TextEditingController nameController;
  final TextEditingController roleController;
  final TextEditingController phoneController;

  GangMemberEntry({
    String name = '',
    String role = '',
    String phone = '',
  })  : nameController = TextEditingController(text: name),
        roleController = TextEditingController(text: role),
        phoneController = TextEditingController(text: phone);

  Map<String, String> toMap() => {
        'name': nameController.text.trim(),
        'role': roleController.text.trim(),
        'phone': phoneController.text.trim(),
      };

  void dispose() {
    nameController.dispose();
    roleController.dispose();
    phoneController.dispose();
  }
}

/// The main MPDA Form widget managing all controllers and UI rendering.
class MpdaFormView extends StatefulWidget {
  final GlobalKey<MpdaFormViewState> formKey;
  final Map<String, dynamic>? initialData;
  final String? defaultStation;
  final bool isReadOnly;
  final VoidCallback? onExportPdf;
  final VoidCallback? onSave;

  const MpdaFormView({
    super.key,
    required this.formKey,
    this.initialData,
    this.defaultStation,
    this.isReadOnly = false,
    this.onExportPdf,
    this.onSave,
  });

  @override
  State<MpdaFormView> createState() => MpdaFormViewState();
}

class MpdaFormViewState extends State<MpdaFormView> {
  String saveBarText = 'All changes unsaved';

  // -------------------------------------------------------------
  // 1. MPDA PROPOSAL DETAILS & CATEGORY
  // -------------------------------------------------------------
  final TextEditingController proposalNoController = TextEditingController();
  String selectedProposalYear = DateTime.now().year.toString();

  // MPDA Categories: Dangerous Person, Bootlegger, Drug Offender, Slumlord,
  // Video Pirate, Sand Smuggler, Black-Marketing, Other
  static const List<String> mpdaCategoryOptions = [
    'Dangerous Person',
    'Bootlegger',
    'Drug Offender',
    'Slumlord',
    'Video Pirate',
    'Sand Smuggler',
    'Black-Marketing',
    'Other',
  ];
  String? selectedMpdaCategory = 'Dangerous Person';
  final TextEditingController otherCategoryController = TextEditingController();

  // -------------------------------------------------------------
  // 2. ACCUSED DETAILS & KYC
  // -------------------------------------------------------------
  final TextEditingController accusedNameController = TextEditingController();
  final TextEditingController accusedAgeController = TextEditingController();
  String selectedAccusedGender = 'Male';
  final TextEditingController accusedMobileController = TextEditingController();
  final TextEditingController accusedAadhaarController =
      TextEditingController();
  final TextEditingController accusedPanController = TextEditingController();
  final TextEditingController accusedAddressController =
      TextEditingController();

  // -------------------------------------------------------------
  // 3. GANG / GROUP MEMBERS (Dynamic & Extensible beyond 5)
  // -------------------------------------------------------------
  final List<GangMemberEntry> gangMembers = [];

  // -------------------------------------------------------------
  // 4. INVESTIGATING OFFICER & SANCTION PROPOSAL OUTCOME
  // -------------------------------------------------------------
  final TextEditingController ioNameController = TextEditingController();
  final TextEditingController ioPostController = TextEditingController();

  // Outcome: Pending / Granted / Rejected
  String? proposalOutcome = 'Pending';
  final TextEditingController outcomeDateController = TextEditingController();

  // Detaining Authority: DM / CP / Other
  static const List<String> detainingAuthorityOptions = ['DM', 'CP', 'Other'];
  String? selectedDetainingAuthority = 'DM';
  final TextEditingController otherAuthorityController =
      TextEditingController();

  // -------------------------------------------------------------
  // 5. DETENTION STATUS
  // -------------------------------------------------------------
  String isDetained = 'No'; // Yes / No
  final TextEditingController detentionDateController = TextEditingController();
  final TextEditingController detentionCompletionDateController =
      TextEditingController();
  final TextEditingController jailNameController = TextEditingController();
  final TextEditingController transferJailNameController =
      TextEditingController();

  String govtConfirmation = 'No'; // Yes / No
  final TextEditingController govtConfirmationDateController =
      TextEditingController();

  String detentionRevoked = 'No'; // Yes / No
  final TextEditingController detentionRevokedDateController =
      TextEditingController();

  // -------------------------------------------------------------
  // 6. CRIME CHART SUMMARY & 12 INDEPENDENT CRIME CATEGORIES
  // -------------------------------------------------------------
  final TextEditingController totalCrimeController =
      TextEditingController(text: '000');
  final TextEditingController seriousCrimesController =
      TextEditingController(text: '000');

  // The 12 independent crime categories
  final Map<String, List<CrimeEntry>> crimeCategories = {
    'Crimes Against the Body': [],
    'Crimes Against Property': [],
    'Crimes Against Women': [],
    'Extortion': [],
    'Murder': [],
    'Attempted Murder': [],
    'Robbery / दरोडा': [],
    'Assault / मारामारी': [],
    'Arms Act': [],
    'NDPS': [],
    'Prohibition': [],
    'Other Special': [],
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _hydrateFromData(widget.initialData!);
    }
  }

  void clearForm() {
    proposalNoController.clear();
    selectedProposalYear = DateTime.now().year.toString();
    selectedMpdaCategory = 'Dangerous Person';
    otherCategoryController.clear();

    accusedNameController.clear();
    accusedAgeController.clear();
    selectedAccusedGender = 'Male';
    accusedMobileController.clear();
    accusedAadhaarController.clear();
    accusedPanController.clear();
    accusedAddressController.clear();

    for (final m in gangMembers) {
      m.dispose();
    }
    gangMembers.clear();

    ioNameController.clear();
    ioPostController.clear();
    proposalOutcome = 'Pending';
    outcomeDateController.clear();
    selectedDetainingAuthority = 'DM';
    otherAuthorityController.clear();

    isDetained = 'No';
    detentionDateController.clear();
    detentionCompletionDateController.clear();
    jailNameController.clear();
    transferJailNameController.clear();
    govtConfirmation = 'No';
    govtConfirmationDateController.clear();
    detentionRevoked = 'No';
    detentionRevokedDateController.clear();

    totalCrimeController.text = '000';
    seriousCrimesController.text = '000';

    for (final list in crimeCategories.values) {
      for (final e in list) {
        e.dispose();
      }
      list.clear();
    }

    saveBarText = 'Form Cleared';
    setState(() {});
  }

  void saveDraft() {
    saveBarText = 'Saved (${DateFormat('hh:mm a').format(DateTime.now())})';
    setState(() {});
    if (widget.onSave != null) {
      widget.onSave!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Draft saved locally', style: GoogleFonts.poppins()),
          backgroundColor: _kTeal,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _hydrateFromData(Map<String, dynamic> rawData) {
    final data = (rawData['mpdaForm'] is Map<String, dynamic>)
        ? (rawData['mpdaForm'] as Map<String, dynamic>)
        : rawData;

    // 1. Proposal Details
    final proposal = data['proposal'] as Map<String, dynamic>? ?? {};
    proposalNoController.text =
        (proposal['proposalNo'] ?? rawData['proposalNo'] ?? '').toString();
    selectedProposalYear = (proposal['proposalYear'] ??
            rawData['proposalYear'] ??
            DateTime.now().year.toString())
        .toString();

    final cat =
        (proposal['mpdaCategory'] ?? rawData['mpdaCategory'])?.toString();
    if (cat != null && mpdaCategoryOptions.contains(cat)) {
      selectedMpdaCategory = cat;
    } else if (cat != null && cat.isNotEmpty) {
      selectedMpdaCategory = 'Other';
      otherCategoryController.text = cat;
    }
    if (selectedMpdaCategory == 'Other') {
      otherCategoryController.text =
          (proposal['otherCategory'] ?? otherCategoryController.text)
              .toString();
    }

    // 2. Accused KYC
    final accused = data['accused'] as Map<String, dynamic>? ?? {};
    accusedNameController.text =
        (accused['name'] ?? rawData['accusedName'] ?? rawData['title'] ?? '')
            .toString();
    accusedAgeController.text =
        (accused['age'] ?? rawData['accusedAge'] ?? '').toString();
    selectedAccusedGender =
        (accused['gender'] ?? rawData['accusedGender'] ?? 'Male').toString();
    accusedMobileController.text =
        (accused['mobile'] ?? rawData['accusedMobile'] ?? '').toString();
    accusedAadhaarController.text =
        (accused['aadhaar'] ?? rawData['accusedAadhaar'] ?? '').toString();
    accusedPanController.text =
        (accused['pan'] ?? rawData['accusedPan'] ?? '').toString();
    accusedAddressController.text =
        (accused['address'] ?? rawData['accusedAddress'] ?? '').toString();

    // 3. Gang Members
    final membersRaw =
        (data['gangMembers'] ?? rawData['gangMembers']) as List<dynamic>? ?? [];
    gangMembers.clear();
    for (final m in membersRaw) {
      if (m is Map<String, dynamic>) {
        gangMembers.add(GangMemberEntry(
          name: (m['name'] ?? '').toString(),
          role: (m['role'] ?? '').toString(),
          phone: (m['phone'] ?? '').toString(),
        ));
      }
    }

    // 4. IO & Proposal Outcome
    final inv = data['investigation'] as Map<String, dynamic>? ?? {};
    ioNameController.text =
        (inv['ioName'] ?? rawData['ioName'] ?? '').toString();
    ioPostController.text =
        (inv['ioPost'] ?? rawData['ioPost'] ?? '').toString();

    proposalOutcome =
        (inv['proposalOutcome'] ?? rawData['proposalOutcome'] ?? 'Pending')
            .toString();
    outcomeDateController.text =
        (inv['outcomeDate'] ?? rawData['outcomeDate'] ?? '').toString();

    final detAuth = (inv['detainingAuthority'] ?? rawData['detainingAuthority'])
        ?.toString();
    if (detAuth != null && detainingAuthorityOptions.contains(detAuth)) {
      selectedDetainingAuthority = detAuth;
    } else if (detAuth != null && detAuth.isNotEmpty) {
      selectedDetainingAuthority = 'Other';
      otherAuthorityController.text = detAuth;
    }
    if (selectedDetainingAuthority == 'Other') {
      otherAuthorityController.text =
          (inv['otherAuthority'] ?? otherAuthorityController.text).toString();
    }

    // 5. Detention Status
    final det = data['detention'] as Map<String, dynamic>? ?? {};
    isDetained =
        (det['isDetained'] ?? rawData['isDetained'] ?? 'No').toString();
    detentionDateController.text =
        (det['detentionDate'] ?? rawData['detentionDate'] ?? '').toString();
    detentionCompletionDateController.text = (det['detentionCompletionDate'] ??
            rawData['detentionCompletionDate'] ??
            '')
        .toString();
    jailNameController.text =
        (det['jailName'] ?? rawData['jailName'] ?? '').toString();
    transferJailNameController.text =
        (det['transferJailName'] ?? rawData['transferJailName'] ?? '')
            .toString();
    govtConfirmation =
        (det['govtConfirmation'] ?? rawData['govtConfirmation'] ?? 'No')
            .toString();
    govtConfirmationDateController.text =
        (det['govtConfirmationDate'] ?? rawData['govtConfirmationDate'] ?? '')
            .toString();
    detentionRevoked =
        (det['detentionRevoked'] ?? rawData['detentionRevoked'] ?? 'No')
            .toString();
    detentionRevokedDateController.text =
        (det['detentionRevokedDate'] ?? rawData['detentionRevokedDate'] ?? '')
            .toString();

    // 6. Crime Chart
    final chart = data['crimeChart'] as Map<String, dynamic>? ?? {};
    totalCrimeController.text =
        (chart['totalCrime'] ?? rawData['totalCrime'] ?? '000').toString();
    seriousCrimesController.text =
        (chart['seriousCrimes'] ?? rawData['seriousCrimes'] ?? '000')
            .toString();

    final catsData = chart['categories'] as Map<String, dynamic>? ?? {};
    for (final entry in crimeCategories.entries) {
      final key = entry.key;
      entry.value.clear();
      final listRaw = (catsData[key] ?? rawData[key]) as List<dynamic>? ?? [];
      for (final item in listRaw) {
        if (item is Map<String, dynamic>) {
          entry.value.add(CrimeEntry(
            crNo: (item['crNo'] ?? '').toString(),
            date: (item['date'] ?? '').toString(),
            ps: (item['ps'] ?? '').toString(),
          ));
        }
      }
    }

    saveBarText = 'Loaded from record';
  }

  @override
  void dispose() {
    proposalNoController.dispose();
    otherCategoryController.dispose();
    accusedNameController.dispose();
    accusedAgeController.dispose();
    accusedMobileController.dispose();
    accusedAadhaarController.dispose();
    accusedPanController.dispose();
    accusedAddressController.dispose();

    for (final m in gangMembers) {
      m.dispose();
    }

    ioNameController.dispose();
    ioPostController.dispose();
    outcomeDateController.dispose();
    otherAuthorityController.dispose();

    detentionDateController.dispose();
    detentionCompletionDateController.dispose();
    jailNameController.dispose();
    transferJailNameController.dispose();
    govtConfirmationDateController.dispose();
    detentionRevokedDateController.dispose();

    totalCrimeController.dispose();
    seriousCrimesController.dispose();

    for (final list in crimeCategories.values) {
      for (final entry in list) {
        entry.dispose();
      }
    }
    super.dispose();
  }

  /// Exports the structured MPDA document map.
  Map<String, dynamic> buildDocumentMap() {
    final categoriesMap = <String, List<Map<String, String>>>{};
    for (final entry in crimeCategories.entries) {
      categoriesMap[entry.key] = entry.value.map((e) => e.toMap()).toList();
    }

    final categoryFinal = selectedMpdaCategory == 'Other'
        ? (otherCategoryController.text.trim().isEmpty
            ? 'Other'
            : otherCategoryController.text.trim())
        : (selectedMpdaCategory ?? '');

    final authorityFinal = selectedDetainingAuthority == 'Other'
        ? (otherAuthorityController.text.trim().isEmpty
            ? 'Other'
            : otherAuthorityController.text.trim())
        : (selectedDetainingAuthority ?? '');

    return {
      'mpdaForm': {
        'proposal': {
          'proposalNo': proposalNoController.text.trim(),
          'proposalYear': selectedProposalYear,
          'mpdaCategory': categoryFinal,
          'otherCategory': otherCategoryController.text.trim(),
        },
        'accused': {
          'name': accusedNameController.text.trim(),
          'age': accusedAgeController.text.trim(),
          'gender': selectedAccusedGender,
          'mobile': accusedMobileController.text.trim(),
          'aadhaar': accusedAadhaarController.text.trim(),
          'pan': accusedPanController.text.trim(),
          'address': accusedAddressController.text.trim(),
        },
        'gangMembers': gangMembers.map((m) => m.toMap()).toList(),
        'investigation': {
          'ioName': ioNameController.text.trim(),
          'ioPost': ioPostController.text.trim(),
          'proposalOutcome': proposalOutcome,
          'outcomeDate': outcomeDateController.text.trim(),
          'detainingAuthority': authorityFinal,
          'otherAuthority': otherAuthorityController.text.trim(),
        },
        'detention': {
          'isDetained': isDetained,
          'detentionDate': detentionDateController.text.trim(),
          'detentionCompletionDate':
              detentionCompletionDateController.text.trim(),
          'jailName': jailNameController.text.trim(),
          'transferJailName': transferJailNameController.text.trim(),
          'govtConfirmation': govtConfirmation,
          'govtConfirmationDate': govtConfirmationDateController.text.trim(),
          'detentionRevoked': detentionRevoked,
          'detentionRevokedDate': detentionRevokedDateController.text.trim(),
        },
        'crimeChart': {
          'totalCrime': totalCrimeController.text.trim().padLeft(3, '0'),
          'seriousCrimes': seriousCrimesController.text.trim().padLeft(3, '0'),
          'categories': categoriesMap,
        },
      },
      // Convenience keys for Hub query & filtering compatibility
      'proposalNo': proposalNoController.text.trim(),
      'proposalYear': selectedProposalYear,
      'mpdaCategory': categoryFinal,
      'accusedName': accusedNameController.text.trim(),
      'title': accusedNameController.text.trim().isNotEmpty
          ? accusedNameController.text.trim()
          : 'MPDA Proposal #${proposalNoController.text.trim()}/$selectedProposalYear',
      'proposalOutcome': proposalOutcome,
      'outcomeDate': outcomeDateController.text.trim(),
      'detainingAuthority': authorityFinal,
      'isDetained': isDetained,
      'detentionDate': detentionDateController.text.trim(),
      'detentionCompletionDate': detentionCompletionDateController.text.trim(),
      'jailName': jailNameController.text.trim(),
      'transferJailName': transferJailNameController.text.trim(),
      'govtConfirmation': govtConfirmation,
      'govtConfirmationDate': govtConfirmationDateController.text.trim(),
      'detentionRevoked': detentionRevoked,
      'detentionRevokedDate': detentionRevokedDateController.text.trim(),
      'totalCrime': totalCrimeController.text.trim(),
      'seriousCrimes': seriousCrimesController.text.trim(),
    };
  }

  // -------------------------------------------------------------
  // HELPER PICKERS
  // -------------------------------------------------------------
  Future<void> _pickDate(TextEditingController controller) async {
    if (widget.isReadOnly) return;
    DateTime initial = DateTime.now();
    if (controller.text.trim().isNotEmpty) {
      try {
        initial = DateFormat('dd/MM/yyyy').parse(controller.text.trim());
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1980),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kMid,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // -------------------------------------------------------------
  // BUILD UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kPageBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top Save/Action Bar (Matches screenshots & common_form) ──
          Container(
            color: _kCardBg,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    saveBarText,
                    style: _tsMuted,
                  ),
                ),
                _barBtn('Clear', Icons.refresh_outlined, clearForm, _kRed),
                const SizedBox(width: 8),
                _barBtn('Save Draft', Icons.save_outlined, saveDraft, _kTeal),
                if (widget.onExportPdf != null) ...[
                  const SizedBox(width: 8),
                  _barBtn(
                      'Generate MPDA Proposal PDF',
                      Icons.picture_as_pdf_outlined,
                      widget.onExportPdf!,
                      _kTeal),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),

          // ── Form Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _card(1, 'MPDA Proposal Details & Category',
                          _buildProposalContent()),
                      _card(2, 'Accused Details & KYC',
                          _buildAccusedKycContent()),
                      _card(
                        3,
                        'Gang / Group Members',
                        _buildGangMembersContent(),
                        trailingHeader: (!widget.isReadOnly)
                            ? _addBtn('+ Add Member', () {
                                setState(() {
                                  gangMembers.add(GangMemberEntry());
                                });
                              })
                            : null,
                      ),
                      _card(4, 'Investigating Officer & Sanction',
                          _buildIoContent()),
                      _card(5, 'Detention Status',
                          _buildDetentionStatusContent()),
                      _card(6, 'Crime Chart (Summary & 12 Categories)',
                          _buildCrimeChartContent()),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barBtn(String label, IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _kTeal.withValues(alpha: 0.08),
          border: Border.all(color: _kTeal.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _kTeal,
          ),
        ),
      ),
    );
  }

  // ─── Section Card Wrapper (Exact replica of Image 1 & 2) ──────────────────
  Widget _card(int idx, String title, Widget body, {Widget? trailingHeader}) {
    final leadingBadge = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: _kMid,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '$idx',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _kBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                leadingBadge,
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: _tsSection),
                ),
                if (trailingHeader != null) trailingHeader,
              ],
            ),
            const SizedBox(height: 14),
            body,
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // SECTION 1: PROPOSAL DETAILS & MPDA CATEGORY
  // -------------------------------------------------------------
  Widget _buildProposalContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildTextField(
                label: 'MPDA Proposal No.',
                controller: proposalNoController,
                hintText: 'e.g. 12/MPDA',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildYearDropdown(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDropdownField<String>(
          label: 'MPDA Category',
          value: selectedMpdaCategory,
          items: mpdaCategoryOptions,
          onChanged: (val) {
            setState(() {
              selectedMpdaCategory = val;
            });
          },
        ),
        if (selectedMpdaCategory == 'Other') ...[
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Specify Other MPDA Category',
            controller: otherCategoryController,
            hintText: 'Enter category details',
            maxLength: 100,
          ),
        ],
      ],
    );
  }

  Widget _buildYearDropdown() {
    final currentYear = DateTime.now().year;
    final years = List.generate(15, (i) => (currentYear - 5 + i).toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Proposal Year', style: _tsLabel),
        const SizedBox(height: 5),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _kInputBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedProposalYear,
              items: years
                  .map((y) => DropdownMenuItem(
                        value: y,
                        child: Text(y,
                            style:
                                const TextStyle(fontSize: 12, color: _kDark)),
                      ))
                  .toList(),
              onChanged: widget.isReadOnly
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() => selectedProposalYear = val);
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // SECTION 2: ACCUSED KYC
  // -------------------------------------------------------------
  Widget _buildAccusedKycContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          label: 'Accused Name *',
          controller: accusedNameController,
          hintText: 'Full Name of the Accused',
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: _buildTextField(
                label: 'Age',
                controller: accusedAgeController,
                hintText: 'e.g. 32',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildDropdownField<String>(
                label: 'Gender',
                value: selectedAccusedGender,
                items: const ['Male', 'Female', 'Other'],
                onChanged: (val) {
                  if (val != null) setState(() => selectedAccusedGender = val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildTextField(
                label: 'Mobile No.',
                controller: accusedMobileController,
                hintText: '10-digit mobile',
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Aadhaar Card No.',
                controller: accusedAadhaarController,
                hintText: '12-digit UID',
                keyboardType: TextInputType.number,
                maxLength: 12,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'PAN Card No.',
                controller: accusedPanController,
                hintText: 'e.g. ABCDE1234F',
                maxLength: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Address / KYC Details',
          controller: accusedAddressController,
          hintText: 'Residential Address, Landmark, Native Place',
          maxLines: 2,
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // SECTION 3: GANG / GROUP MEMBERS (Extensible 1,2,3,4,5...+)
  // -------------------------------------------------------------
  Widget _buildGangMembersContent() {
    if (gangMembers.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: const Text(
          'No gang/group members added yet. Tap "+ Add Member" to add 1, 2, 3, 4, 5, or more associates.',
          style: TextStyle(
              fontSize: 12, color: _kMuted, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gangMembers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final member = gangMembers[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kInputBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _kMid,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Member #${index + 1}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kDark),
                  ),
                  const Spacer(),
                  if (!widget.isReadOnly)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: _kRed, size: 18),
                      tooltip: 'Remove Member',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          final removed = gangMembers.removeAt(index);
                          removed.dispose();
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildTextField(
                      label: 'Member Name',
                      controller: member.nameController,
                      hintText: 'Full Name / Alias',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      label: 'Role / Alias',
                      controller: member.roleController,
                      hintText: 'e.g. Shooter / Informer',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      label: 'Phone / Contact',
                      controller: member.phoneController,
                      hintText: 'Phone No.',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // SECTION 4: INVESTIGATING OFFICER & SANCTION
  // -------------------------------------------------------------
  Widget _buildIoContent() {
    final isDecided =
        proposalOutcome == 'Granted' || proposalOutcome == 'Rejected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                label: 'IO Name (Investigating Officer)',
                controller: ioNameController,
                hintText: 'Name of IO',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'IO Post (Designation)',
                controller: ioPostController,
                hintText: 'e.g. PI / API / PSI',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildDropdownField<String>(
                label: 'Proposal Outcome',
                value: proposalOutcome,
                items: const ['Pending', 'Granted', 'Rejected'],
                onChanged: (val) {
                  setState(() {
                    proposalOutcome = val;
                    if (val == 'Pending') {
                      outcomeDateController.clear();
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                label: 'Date of Decision 📅',
                controller: outcomeDateController,
                enabled: isDecided,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDropdownField<String>(
          label: 'Detaining Authority',
          value: selectedDetainingAuthority,
          items: detainingAuthorityOptions,
          onChanged: (val) {
            setState(() => selectedDetainingAuthority = val);
          },
        ),
        if (selectedDetainingAuthority == 'Other') ...[
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Specify Other Detaining Authority',
            controller: otherAuthorityController,
            hintText: 'Enter Detaining Authority name/title',
            maxLength: 100,
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------
  // SECTION 5: DETENTION STATUS
  // -------------------------------------------------------------
  Widget _buildDetentionStatusContent() {
    final isDet = isDetained == 'Yes';
    final isGovt = govtConfirmation == 'Yes';
    final isRev = detentionRevoked == 'Yes';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildYesNoToggle(
                label: 'Detained (Y/N)',
                value: isDetained,
                onChanged: (val) {
                  setState(() {
                    isDetained = val;
                    if (val == 'No') {
                      detentionDateController.clear();
                      detentionCompletionDateController.clear();
                      jailNameController.clear();
                      transferJailNameController.clear();
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                label: 'Detention Date 📅',
                controller: detentionDateController,
                enabled: isDet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDateField(
          label: 'Detention Completion Date 📅',
          controller: detentionCompletionDateController,
          enabled: isDet,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Jail Name',
                controller: jailNameController,
                hintText: 'e.g. Yerwada Central Jail',
                enabled: isDet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Transfer Jail Name',
                controller: transferJailNameController,
                hintText: 'e.g. Arthur Road Jail (if transferred)',
                enabled: isDet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildYesNoToggle(
                label: 'Govt Confirmation (Y/N)',
                value: govtConfirmation,
                onChanged: (val) {
                  setState(() {
                    govtConfirmation = val;
                    if (val == 'No') {
                      govtConfirmationDateController.clear();
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                label: 'Govt Confirmation Date 📅',
                controller: govtConfirmationDateController,
                enabled: isGovt,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildYesNoToggle(
                label: 'Detention Order Revoked (Y/N)',
                value: detentionRevoked,
                onChanged: (val) {
                  setState(() {
                    detentionRevoked = val;
                    if (val == 'No') {
                      detentionRevokedDateController.clear();
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                label: 'Revocation Date 📅',
                controller: detentionRevokedDateController,
                enabled: isRev,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // SECTION 6: CRIME CHART (Numeric counts & 12 independent categories)
  // -------------------------------------------------------------
  Widget _buildCrimeChartContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Total Crime (3-digit format e.g. 000)',
                controller: totalCrimeController,
                hintText: '000',
                keyboardType: TextInputType.number,
                maxLength: 3,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Serious Crimes (3-digit format e.g. 000)',
                controller: seriousCrimesController,
                hintText: '000',
                keyboardType: TextInputType.number,
                maxLength: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          '12 Detailed Crime Categories (Repeatable CR No. / Date / PS entries)',
          style: _tsLabel,
        ),
        const SizedBox(height: 8),
        ...crimeCategories.keys
            .map((catName) => _buildCrimeCategoryItem(catName)),
      ],
    );
  }

  Widget _buildCrimeCategoryItem(String catName) {
    final entries = crimeCategories[catName]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kInputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: entries.isNotEmpty ? _kTeal.withValues(alpha: 0.5) : _kBorder,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: entries.isNotEmpty,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: entries.isNotEmpty ? _kMid : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${entries.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: entries.isNotEmpty ? Colors.white : _kSec,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  catName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        entries.isNotEmpty ? FontWeight.w700 : FontWeight.w500,
                    color: _kDark,
                  ),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isReadOnly)
                _addBtn('+ Add CR', () {
                  setState(() {
                    entries.add(CrimeEntry(ps: widget.defaultStation ?? ''));
                  });
                }),
              const SizedBox(width: 6),
              const Icon(Icons.expand_more, size: 20, color: _kSec),
            ],
          ),
          children: [
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 14, right: 14, bottom: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No case records added yet. Tap "+ Add CR" to begin.',
                    style: TextStyle(
                        fontSize: 11,
                        color: _kMuted,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  children: List.generate(entries.length, (idx) {
                    final item = entries[idx];
                    return Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _kMid.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _kMid),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: _buildTextField(
                              label: 'CR No.',
                              controller: item.crNoController,
                              hintText: 'e.g. 104/2026',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: _buildDateField(
                              label: 'Date 📅',
                              controller: item.dateController,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: _buildTextField(
                              label: 'Police Station (PS)',
                              controller: item.psController,
                              hintText: 'e.g. Shivaji Nagar PS',
                            ),
                          ),
                          if (!widget.isReadOnly) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: _kRed, size: 18),
                              tooltip: 'Remove',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  final rem = entries.removeAt(idx);
                                  rem.dispose();
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // REUSABLE FIELD WRAPPERS & STYLES (MATCHES SCREENSHOTS)
  // -------------------------------------------------------------
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    bool enabled = true,
  }) {
    final active = enabled && !widget.isReadOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: active
              ? _tsLabel
              : const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kMuted,
                  letterSpacing: 0.3),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          enabled: active,
          readOnly: !active,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          style: TextStyle(fontSize: 12, color: active ? _kDark : _kMuted),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 12, color: _kMuted),
            counterText: '',
            isDense: true,
            filled: true,
            fillColor: active ? _kInputBg : const Color(0xFFF1F5F9),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: active
                      ? _kBorder
                      : const Color(0xFFE2E8F0).withValues(alpha: 0.6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBorder),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kTeal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
  }) {
    final active = enabled && !widget.isReadOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: active
              ? _tsLabel
              : const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kMuted,
                  letterSpacing: 0.3),
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: active ? () => _pickDate(controller) : null,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: active ? _kInputBg : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active
                    ? _kBorder
                    : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? 'DD/MM/YYYY' : controller.text,
                    style: TextStyle(
                      fontSize: 12,
                      color: controller.text.isEmpty
                          ? _kMuted
                          : (active ? _kDark : _kMuted),
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: active ? _kTeal : _kMuted.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _tsLabel),
        const SizedBox(height: 5),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: widget.isReadOnly ? Colors.grey.shade100 : _kInputBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: items.contains(value) ? value : null,
              hint: Text('Select $label',
                  style: const TextStyle(fontSize: 12, color: _kMuted)),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString(),
                      style: const TextStyle(fontSize: 12, color: _kDark)),
                );
              }).toList(),
              onChanged: widget.isReadOnly ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYesNoToggle({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    final isYes = value.toLowerCase() == 'yes';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _tsLabel),
        const SizedBox(height: 5),
        Row(
          children: [
            _yesNoChip('Yes', isYes, _kGreen, () => onChanged('Yes')),
            const SizedBox(width: 8),
            _yesNoChip('No', !isYes, _kRed, () => onChanged('No')),
          ],
        ),
      ],
    );
  }

  Widget _yesNoChip(
      String label, bool active, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: widget.isReadOnly ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.12) : _kInputBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color : _kBorder,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? color : _kSec,
          ),
        ),
      ),
    );
  }
}
