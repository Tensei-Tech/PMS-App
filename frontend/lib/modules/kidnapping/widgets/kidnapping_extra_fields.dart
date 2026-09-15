import 'package:flutter/material.dart';

class KidnappingExtraFields extends StatefulWidget {
  final void Function(String label, TextEditingController ctrl, [String section])? onActiveFieldTap;

  const KidnappingExtraFields({super.key, this.onActiveFieldTap});

  @override
  State<KidnappingExtraFields> createState() => KidnappingExtraFieldsState();
}

class KidnappingExtraFieldsState extends State<KidnappingExtraFields> {
  Map<String, dynamic> collectData() => getPayload();
  void hydrateFrom(Map<String, dynamic> data) => loadFromPayload(data);
  Widget _tf({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1E293B),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onTap: () {
        widget.onActiveFieldTap?.call(label, controller, 'Kidnapping Details');
      },
      decoration: _inputDecoration(label),
    );
  }

  static const Color _inputBorder = Color(0xFFE2E8F0);

  final _kidnappedName = TextEditingController();
  final _kidnappedAge = TextEditingController();
  String? _kidnappedGender;
  final _kidnappedOccupation = TextEditingController();
  final _kidnappedMobile = TextEditingController();
  final _kidnappedAadhaar = TextEditingController();
  final _kidnappedReligion = TextEditingController();
  final _kidnappedCaste = TextEditingController();
  final _kidnappedRelation = TextEditingController();

  bool _personFound = false;
  final _foundDate = TextEditingController();
  final _foundTime = TextEditingController();
  final _foundSdNo = TextEditingController();
  bool _statementRecorded = false;
  final _statementDate = TextEditingController();
  final _statementTime = TextEditingController();
  String? _custodyTo;
  final _custodyOtherText = TextEditingController();
  final _custodyName = TextEditingController();
  final _custodyAge = TextEditingController();
  String? _custodyGender;
  final _custodyMobile = TextEditingController();
  final _custodyAadhaar = TextEditingController();
  final _custodyRelation = TextEditingController();
  final _custodyAddress = TextEditingController();

  bool _bnss183Recorded = false;
  final _bnssDate = TextEditingController();
  final _bnssTime = TextEditingController();

  bool _cwcRecorded = false;
  final _cwcDate = TextEditingController();
  final _cwcTime = TextEditingController();

  bool _medicalExamDone = false;
  final _medicalDate = TextEditingController();
  final _medicalTime = TextEditingController();

  bool _inCameraRecorded = false;
  final _inCameraDate = TextEditingController();
  final _inCameraTime = TextEditingController();

  @override
  void dispose() {
    _kidnappedName.dispose();
    _kidnappedAge.dispose();
    _kidnappedOccupation.dispose();
    _kidnappedMobile.dispose();
    _kidnappedAadhaar.dispose();
    _kidnappedReligion.dispose();
    _kidnappedCaste.dispose();
    _kidnappedRelation.dispose();
    _foundDate.dispose();
    _foundTime.dispose();
    _foundSdNo.dispose();
    _statementDate.dispose();
    _statementTime.dispose();
    _custodyOtherText.dispose();
    _custodyName.dispose();
    _custodyAge.dispose();
    _custodyMobile.dispose();
    _custodyAadhaar.dispose();
    _custodyRelation.dispose();
    _custodyAddress.dispose();
    _bnssDate.dispose();
    _bnssTime.dispose();
    _cwcDate.dispose();
    _cwcTime.dispose();
    _medicalDate.dispose();
    _medicalTime.dispose();
    _inCameraDate.dispose();
    _inCameraTime.dispose();
    super.dispose();
  }

  Map<String, dynamic> getPayload() {
    return {
      'kidnapped_person_kyc': {
        'name': _kidnappedName.text.trim(),
        'age': _kidnappedAge.text.trim(),
        'gender': _kidnappedGender ?? '',
        'occupation': _kidnappedOccupation.text.trim(),
        'mobile_number': _kidnappedMobile.text.trim(),
        'aadhaar_number': _kidnappedAadhaar.text.trim(),
        'religion': _kidnappedReligion.text.trim(),
        'caste': _kidnappedCaste.text.trim(),
        'relation_with_complainant': _kidnappedRelation.text.trim(),
      },
      'person_found_details': {
        'person_found': _personFound,
        'found_date': _foundDate.text.trim(),
        'found_time': _foundTime.text.trim(),
        'station_diary_no': _foundSdNo.text.trim(),
        'statement_recorded': _statementRecorded,
        'statement_date': _statementDate.text.trim(),
        'statement_time': _statementTime.text.trim(),
        'custody_given_to': _custodyTo ?? '',
        'custody_other_specify': _custodyOtherText.text.trim(),
        'custody_kyc': {
          'name': _custodyName.text.trim(),
          'age': _custodyAge.text.trim(),
          'gender': _custodyGender ?? '',
          'mobile_number': _custodyMobile.text.trim(),
          'aadhaar_number': _custodyAadhaar.text.trim(),
          'relationship': _custodyRelation.text.trim(),
          'full_address': _custodyAddress.text.trim(),
        },
      },
      'statement_under_183_bnss': {
        'statement_recorded': _bnss183Recorded,
        'statement_date': _bnssDate.text.trim(),
        'statement_time': _bnssTime.text.trim(),
      },
      'statement_before_cwc': {
        'statement_recorded': _cwcRecorded,
        'statement_date': _cwcDate.text.trim(),
        'statement_time': _cwcTime.text.trim(),
      },
      'medical_examination': {
        'examination_conducted': _medicalExamDone,
        'examination_date': _medicalDate.text.trim(),
        'examination_time': _medicalTime.text.trim(),
      },
      'in_camera_statement': {
        'statement_recorded': _inCameraRecorded,
        'statement_date': _inCameraDate.text.trim(),
        'statement_time': _inCameraTime.text.trim(),
      },
    };
  }

  void loadFromPayload(Map<String, dynamic> data) {
    setState(() {
      final kyc = (data['kidnapped_person_kyc'] as Map<String, dynamic>?) ?? {};
      _kidnappedName.text = kyc['name'] ?? '';
      _kidnappedAge.text = kyc['age'] ?? '';
      _kidnappedGender = kyc['gender']?.toString().isNotEmpty == true
          ? kyc['gender']
          : null;
      _kidnappedOccupation.text = kyc['occupation'] ?? '';
      _kidnappedMobile.text = kyc['mobile_number'] ?? '';
      _kidnappedAadhaar.text = kyc['aadhaar_number'] ?? '';
      _kidnappedReligion.text = kyc['religion'] ?? '';
      _kidnappedCaste.text = kyc['caste'] ?? '';
      _kidnappedRelation.text = kyc['relation_with_complainant'] ?? '';

      final found =
          (data['person_found_details'] as Map<String, dynamic>?) ?? {};
      _personFound = found['person_found'] == true;
      _foundDate.text = found['found_date'] ?? '';
      _foundTime.text = found['found_time'] ?? '';
      _foundSdNo.text = found['station_diary_no'] ?? '';
      _statementRecorded = found['statement_recorded'] == true;
      _statementDate.text = found['statement_date'] ?? '';
      _statementTime.text = found['statement_time'] ?? '';
      _custodyTo = found['custody_given_to']?.toString().isNotEmpty == true
          ? found['custody_given_to']
          : null;
      _custodyOtherText.text = found['custody_other_specify'] ?? '';

      final cKyc = (found['custody_kyc'] as Map<String, dynamic>?) ?? {};
      _custodyName.text = cKyc['name'] ?? '';
      _custodyAge.text = cKyc['age'] ?? '';
      _custodyGender = cKyc['gender']?.toString().isNotEmpty == true
          ? cKyc['gender']
          : null;
      _custodyMobile.text = cKyc['mobile_number'] ?? '';
      _custodyAadhaar.text = cKyc['aadhaar_number'] ?? '';
      _custodyRelation.text = cKyc['relationship'] ?? '';
      _custodyAddress.text = cKyc['full_address'] ?? '';

      final bnss =
          (data['statement_under_183_bnss'] as Map<String, dynamic>?) ?? {};
      _bnss183Recorded = bnss['statement_recorded'] == true;
      _bnssDate.text = bnss['statement_date'] ?? '';
      _bnssTime.text = bnss['statement_time'] ?? '';

      final cwc = (data['statement_before_cwc'] as Map<String, dynamic>?) ?? {};
      _cwcRecorded = cwc['statement_recorded'] == true;
      _cwcDate.text = cwc['statement_date'] ?? '';
      _cwcTime.text = cwc['statement_time'] ?? '';

      final med = (data['medical_examination'] as Map<String, dynamic>?) ?? {};
      _medicalExamDone = med['examination_conducted'] == true;
      _medicalDate.text = med['examination_date'] ?? '';
      _medicalTime.text = med['examination_time'] ?? '';

      final inCam =
          (data['in_camera_statement'] as Map<String, dynamic>?) ?? {};
      _inCameraRecorded = inCam['statement_recorded'] == true;
      _inCameraDate.text = inCam['statement_date'] ?? '';
      _inCameraTime.text = inCam['statement_time'] ?? '';
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
      ),
    );
  }

  Widget _sectionCard(String title, Widget body) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: body,
          ),
        ],
      ),
    );
  }

  Widget _yesNoToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    Widget buildChip(String text, bool selected, VoidCallback onTap) {
      const activeColor = Color(0xFF0EA5E9);
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? activeColor.withValues(alpha: 0.1)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? activeColor : const Color(0xFFE2E8F0),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? activeColor : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            buildChip('YES', value, () => onChanged(true)),
            buildChip('NO', !value, () => onChanged(false)),
          ],
        ),
      ],
    );
  }

  Widget _animatedSwitch(bool flag, Widget child) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: flag
          ? Container(key: ValueKey(flag), child: child)
          : const SizedBox.shrink(key: ValueKey(false)),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d-$m-$y';
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initial = _parseDate(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => controller.text = _formatDate(picked));
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final initial = _parseTime(controller.text) ?? TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => controller.text = _formatTime(picked));
    }
  }

  Widget _dateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
      decoration: _inputDecoration(
        label,
      ).copyWith(suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16)),
      onTap: () => _pickDate(controller),
    );
  }

  Widget _timeField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
      decoration: _inputDecoration(
        label,
      ).copyWith(suffixIcon: const Icon(Icons.access_time_rounded, size: 16)),
      onTap: () => _pickTime(controller),
    );
  }

  Widget _responsiveTwoFieldRow({
    required BuildContext context,
    required Widget first,
    required Widget second,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 400) {
      return Column(children: [first, const SizedBox(height: 12), second]);
    }
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    );
  }

  String _custodyKycTitle() {
    if ((_custodyTo ?? '').isEmpty) return 'CUSTODY KYC DETAILS';
    if (_custodyTo == 'Other') {
      final t = _custodyOtherText.text.trim();
      return t.isEmpty ? 'OTHER KYC DETAILS' : '${t.toUpperCase()} KYC DETAILS';
    }
    return '${_custodyTo!.toUpperCase()} KYC DETAILS';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          _sectionCard(
            'Kidnapped Person KYC',
            Column(
              children: [
                _responsiveTwoFieldRow(
                  context: context,
                  first: _tf(
                    label: 'Name',
                    controller: _kidnappedName,
                  ),
                  second: _tf(
                    label: 'Age',
                    controller: _kidnappedAge,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 12),
                _responsiveTwoFieldRow(
                  context: context,
                  first: DropdownButtonFormField<String>(
                    key: ValueKey(
                      'kidnappedGender_${_kidnappedGender ?? ''}',
                    ),
                    initialValue: _kidnappedGender,
                    decoration: _inputDecoration('Gender'),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B)),
                    items: const ['Male', 'Female', 'Other']
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1E293B))),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _kidnappedGender = v),
                  ),
                  second: _tf(
                    label: 'Occupation',
                    controller: _kidnappedOccupation,
                  ),
                ),
                const SizedBox(height: 12),
                _responsiveTwoFieldRow(
                  context: context,
                  first: _tf(
                    label: 'Mobile Number',
                    controller: _kidnappedMobile,
                    keyboardType: TextInputType.phone,
                  ),
                  second: _tf(
                    label: 'Aadhaar Number',
                    controller: _kidnappedAadhaar,
                  ),
                ),
                const SizedBox(height: 12),
                _responsiveTwoFieldRow(
                  context: context,
                  first: _tf(
                    label: 'Religion',
                    controller: _kidnappedReligion,
                  ),
                  second: _tf(
                    label: 'Caste',
                    controller: _kidnappedCaste,
                  ),
                ),
                const SizedBox(height: 12),
                _tf(
                  label: 'Relation with Complainant',
                  controller: _kidnappedRelation,
                ),
              ],
            ),
          ),
          _sectionCard(
            'Person Found Details',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _yesNoToggle(
                  label: 'Is kidnapped person found?',
                  value: _personFound,
                  onChanged: (v) => setState(() => _personFound = v),
                ),
                const SizedBox(height: 12),
                _animatedSwitch(
                  _personFound,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _responsiveTwoFieldRow(
                        context: context,
                        first: _dateField('Found Date', _foundDate),
                        second: _timeField('Found Time', _foundTime),
                      ),
                      const SizedBox(height: 12),
                      _tf(
                        label: 'SD No. / Station Diary No.',
                        controller: _foundSdNo,
                      ),
                      const SizedBox(height: 14),
                      _yesNoToggle(
                        label: 'Statement of kidnapped person recorded?',
                        value: _statementRecorded,
                        onChanged: (v) =>
                            setState(() => _statementRecorded = v),
                      ),
                      const SizedBox(height: 12),
                      _animatedSwitch(
                        _statementRecorded,
                        Column(
                          children: [
                            _responsiveTwoFieldRow(
                              context: context,
                              first: _dateField(
                                'Statement Date',
                                _statementDate,
                              ),
                              second: _timeField(
                                'Statement Time',
                                _statementTime,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        key: ValueKey('custodyTo_${_custodyTo ?? ''}'),
                        initialValue: _custodyTo,
                        decoration: _inputDecoration('Custody Given To'),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B)),
                        items: const [
                          'Parents',
                          'Relative',
                          'Friend',
                          'Shelter Home',
                          'Other',
                        ]
                            .map(
                              (e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1E293B)),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _custodyTo = v),
                      ),
                      const SizedBox(height: 12),
                      _animatedSwitch(
                        _custodyTo == 'Other',
                        _tf(
                          label: 'Please Specify',
                          controller: _custodyOtherText,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _animatedSwitch(
                        (_custodyTo ?? '').isNotEmpty,
                        Container(
                          key: ValueKey(_custodyKycTitle()),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _inputBorder),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  _custodyKycTitle(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              _responsiveTwoFieldRow(
                                context: context,
                                first: _tf(
                                  label: 'Name',
                                  controller: _custodyName,
                                ),
                                second: _tf(
                                  label: 'Age',
                                  controller: _custodyAge,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _responsiveTwoFieldRow(
                                context: context,
                                first: DropdownButtonFormField<String>(
                                  key: ValueKey(
                                    'custodyGender_${_custodyGender ?? ''}',
                                  ),
                                  initialValue: _custodyGender,
                                  decoration: _inputDecoration('Gender'),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1E293B)),
                                  items: const ['Male', 'Female', 'Other']
                                      .map(
                                        (e) => DropdownMenuItem<String>(
                                          value: e,
                                          child: Text(
                                            e,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1E293B)),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _custodyGender = v),
                                ),
                                second: _tf(
                                  label: 'Mobile Number',
                                  controller: _custodyMobile,
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _responsiveTwoFieldRow(
                                context: context,
                                first: _tf(
                                  label: 'Aadhaar Number',
                                  controller: _custodyAadhaar,
                                ),
                                second: _tf(
                                  label: 'Relationship',
                                  controller: _custodyRelation,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _tf(
                                label: 'Full Address',
                                controller: _custodyAddress,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _sectionCard(
            '183 BNSS',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _yesNoToggle(
                  label: 'Statement Recorded under 183 BNSS?',
                  value: _bnss183Recorded,
                  onChanged: (v) => setState(() => _bnss183Recorded = v),
                ),
                const SizedBox(height: 12),
                _animatedSwitch(
                  _bnss183Recorded,
                  _responsiveTwoFieldRow(
                    context: context,
                    first: _dateField('Statement Date', _bnssDate),
                    second: _timeField('Statement Time', _bnssTime),
                  ),
                ),
              ],
            ),
          ),
          _sectionCard(
            'CWC Statement',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _yesNoToggle(
                  label:
                      'Statement Recorded before Child Welfare Committee (CWC)?',
                  value: _cwcRecorded,
                  onChanged: (v) => setState(() => _cwcRecorded = v),
                ),
                const SizedBox(height: 12),
                _animatedSwitch(
                  _cwcRecorded,
                  _responsiveTwoFieldRow(
                    context: context,
                    first: _dateField('CWC Statement Date', _cwcDate),
                    second: _timeField('CWC Statement Time', _cwcTime),
                  ),
                ),
              ],
            ),
          ),
          _sectionCard(
            'Medical Examination',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _yesNoToggle(
                  label: 'Medical Examination Conducted?',
                  value: _medicalExamDone,
                  onChanged: (v) => setState(() => _medicalExamDone = v),
                ),
                const SizedBox(height: 12),
                _animatedSwitch(
                  _medicalExamDone,
                  _responsiveTwoFieldRow(
                    context: context,
                    first: _dateField('Medical Examination Date', _medicalDate),
                    second: _timeField(
                      'Medical Examination Time',
                      _medicalTime,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _sectionCard(
            'In-Camera Statement',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _yesNoToggle(
                  label: 'In-Camera Statement Recorded?',
                  value: _inCameraRecorded,
                  onChanged: (v) => setState(() => _inCameraRecorded = v),
                ),
                const SizedBox(height: 12),
                _animatedSwitch(
                  _inCameraRecorded,
                  _responsiveTwoFieldRow(
                    context: context,
                    first: _dateField('Statement Date', _inCameraDate),
                    second: _timeField('Statement Time', _inCameraTime),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
