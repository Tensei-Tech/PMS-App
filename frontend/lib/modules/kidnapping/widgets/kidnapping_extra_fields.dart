import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KidnappingExtraFields extends StatefulWidget {
  const KidnappingExtraFields({super.key});

  @override
  State<KidnappingExtraFields> createState() => KidnappingExtraFieldsState();
}

class KidnappingExtraFieldsState extends State<KidnappingExtraFields> {
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
    for (final c in [
      _kidnappedName,
      _kidnappedAge,
      _kidnappedOccupation,
      _kidnappedMobile,
      _kidnappedAadhaar,
      _kidnappedReligion,
      _kidnappedCaste,
      _kidnappedRelation,
      _foundDate,
      _foundTime,
      _foundSdNo,
      _statementDate,
      _statementTime,
      _custodyOtherText,
      _custodyName,
      _custodyAge,
      _custodyMobile,
      _custodyAadhaar,
      _custodyRelation,
      _custodyAddress,
      _bnssDate,
      _bnssTime,
      _cwcDate,
      _cwcTime,
      _medicalDate,
      _medicalTime,
      _inCameraDate,
      _inCameraTime,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'kidnappedName': _kidnappedName.text.trim(),
      'kidnappedAge': _kidnappedAge.text.trim(),
      'kidnappedGender': _kidnappedGender,
      'kidnappedOccupation': _kidnappedOccupation.text.trim(),
      'kidnappedMobile': _kidnappedMobile.text.trim(),
      'kidnappedAadhaar': _kidnappedAadhaar.text.trim(),
      'kidnappedReligion': _kidnappedReligion.text.trim(),
      'kidnappedCaste': _kidnappedCaste.text.trim(),
      'kidnappedRelation': _kidnappedRelation.text.trim(),
      'personFound': _personFound,
      'foundDate': _foundDate.text.trim(),
      'foundTime': _foundTime.text.trim(),
      'foundSdNo': _foundSdNo.text.trim(),
      'statementRecorded': _statementRecorded,
      'statementDate': _statementDate.text.trim(),
      'statementTime': _statementTime.text.trim(),
      'custodyTo': _custodyTo,
      'custodyOtherText': _custodyOtherText.text.trim(),
      'custodyName': _custodyName.text.trim(),
      'custodyAge': _custodyAge.text.trim(),
      'custodyGender': _custodyGender,
      'custodyMobile': _custodyMobile.text.trim(),
      'custodyAadhaar': _custodyAadhaar.text.trim(),
      'custodyRelation': _custodyRelation.text.trim(),
      'custodyAddress': _custodyAddress.text.trim(),
      'bnss183Recorded': _bnss183Recorded,
      'bnssDate': _bnssDate.text.trim(),
      'bnssTime': _bnssTime.text.trim(),
      'cwcRecorded': _cwcRecorded,
      'cwcDate': _cwcDate.text.trim(),
      'cwcTime': _cwcTime.text.trim(),
      'medicalExamDone': _medicalExamDone,
      'medicalDate': _medicalDate.text.trim(),
      'medicalTime': _medicalTime.text.trim(),
      'inCameraRecorded': _inCameraRecorded,
      'inCameraDate': _inCameraDate.text.trim(),
      'inCameraTime': _inCameraTime.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    _kidnappedName.text = _asString(data['kidnappedName']);
    _kidnappedAge.text = _asString(data['kidnappedAge']);
    _kidnappedGender = _asString(data['kidnappedGender']).isEmpty
        ? null
        : _asString(data['kidnappedGender']);
    _kidnappedOccupation.text = _asString(data['kidnappedOccupation']);
    _kidnappedMobile.text = _asString(data['kidnappedMobile']);
    _kidnappedAadhaar.text = _asString(data['kidnappedAadhaar']);
    _kidnappedReligion.text = _asString(data['kidnappedReligion']);
    _kidnappedCaste.text = _asString(data['kidnappedCaste']);
    _kidnappedRelation.text = _asString(data['kidnappedRelation']);

    _personFound = _asBool(data['personFound']);
    _foundDate.text = _asString(data['foundDate']);
    _foundTime.text = _asString(data['foundTime']);
    _foundSdNo.text = _asString(data['foundSdNo']);
    _statementRecorded = _asBool(data['statementRecorded']);
    _statementDate.text = _asString(data['statementDate']);
    _statementTime.text = _asString(data['statementTime']);
    _custodyTo = _asString(data['custodyTo']).isEmpty
        ? null
        : _asString(data['custodyTo']);
    _custodyOtherText.text = _asString(data['custodyOtherText']);
    _custodyName.text = _asString(data['custodyName']);
    _custodyAge.text = _asString(data['custodyAge']);
    _custodyGender = _asString(data['custodyGender']).isEmpty
        ? null
        : _asString(data['custodyGender']);
    _custodyMobile.text = _asString(data['custodyMobile']);
    _custodyAadhaar.text = _asString(data['custodyAadhaar']);
    _custodyRelation.text = _asString(data['custodyRelation']);
    _custodyAddress.text = _asString(data['custodyAddress']);

    _bnss183Recorded = _asBool(data['bnss183Recorded']);
    _bnssDate.text = _asString(data['bnssDate']);
    _bnssTime.text = _asString(data['bnssTime']);

    _cwcRecorded = _asBool(data['cwcRecorded']);
    _cwcDate.text = _asString(data['cwcDate']);
    _cwcTime.text = _asString(data['cwcTime']);

    _medicalExamDone = _asBool(data['medicalExamDone']);
    _medicalDate.text = _asString(data['medicalDate']);
    _medicalTime.text = _asString(data['medicalTime']);

    _inCameraRecorded = _asBool(data['inCameraRecorded']);
    _inCameraDate.text = _asString(data['inCameraDate']);
    _inCameraTime.text = _asString(data['inCameraTime']);

    setState(() {});
  }

  String _asString(dynamic value) => value?.toString() ?? '';

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return false;
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Color(0xFF64748B),
      ),
      floatingLabelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0EA5E9),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
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
              color: selected ? activeColor.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
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
      style: GoogleFonts.poppins(),
      decoration: _inputDecoration(
        label,
      ).copyWith(suffixIcon: const Icon(Icons.calendar_today_outlined)),
      onTap: () => _pickDate(controller),
    );
  }

  Widget _timeField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: GoogleFonts.poppins(),
      decoration: _inputDecoration(
        label,
      ).copyWith(suffixIcon: const Icon(Icons.access_time_rounded)),
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
                  first: TextFormField(
                    controller: _kidnappedName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                    decoration: _inputDecoration('Name'),
                  ),
                  second: TextFormField(
                    controller: _kidnappedAge,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                    decoration: _inputDecoration('Age'),
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
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                    items: const ['Male', 'Female', 'Other']
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _kidnappedGender = v),
                  ),
                  second: TextFormField(
                    controller: _kidnappedOccupation,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                    decoration: _inputDecoration('Occupation'),
                  ),
                ),
                const SizedBox(height: 12),
                _responsiveTwoFieldRow(
                  context: context,
                  first: TextFormField(
                    controller: _kidnappedMobile,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                    decoration: _inputDecoration('Mobile Number'),
                  ),
                  second: TextFormField(
                    controller: _kidnappedAadhaar,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                    decoration: _inputDecoration('Aadhaar Number'),
                  ),
                ),
                const SizedBox(height: 12),
                _responsiveTwoFieldRow(
                  context: context,
                  first: TextFormField(
                    controller: _kidnappedReligion,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                    decoration: _inputDecoration('Religion'),
                  ),
                  second: TextFormField(
                    controller: _kidnappedCaste,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                    decoration: _inputDecoration('Caste'),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _kidnappedRelation,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                  decoration: _inputDecoration('Relation with Complainant'),
                ),
              ],
            ),
          ),
          _sectionCard(
            'Found Status',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _yesNoToggle(
                  label: '',
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
                      TextFormField(
                        controller: _foundSdNo,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                        decoration: _inputDecoration(
                          'SD No. / Station Diary No.',
                        ),
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
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
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
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _custodyTo = v),
                      ),
                      const SizedBox(height: 12),
                      _animatedSwitch(
                        _custodyTo == 'Other',
                        TextFormField(
                          controller: _custodyOtherText,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                          decoration: _inputDecoration('Please Specify'),
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
                                first: TextFormField(
                                  controller: _custodyName,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                                  decoration: _inputDecoration('Name'),
                                ),
                                second: TextFormField(
                                  controller: _custodyAge,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                                  decoration: _inputDecoration('Age'),
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
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                                  items: const ['Male', 'Female', 'Other']
                                      .map(
                                        (e) => DropdownMenuItem<String>(
                                          value: e,
                                          child: Text(
                                            e,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _custodyGender = v),
                                ),
                                second: TextFormField(
                                  controller: _custodyMobile,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                                  decoration: _inputDecoration('Mobile Number'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _responsiveTwoFieldRow(
                                context: context,
                                first: TextFormField(
                                  controller: _custodyAadhaar,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                                  decoration: _inputDecoration(
                                    'Aadhaar Number',
                                  ),
                                ),
                                second: TextFormField(
                                  controller: _custodyRelation,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                                  decoration: _inputDecoration('Relationship'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _custodyAddress,
                                maxLines: 3,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                                decoration: _inputDecoration('Full Address'),
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
                  label: 'Statement Recorded before Child Welfare Committee (CWC)?',
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
