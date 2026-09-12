import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../modules/core/models/base_record.dart';
import '../theme/app_theme.dart';
import '../utils/translation_helper.dart';

class TransferCaseFormScreen extends StatefulWidget {
  final ModuleRecord record;

  const TransferCaseFormScreen({super.key, required this.record});

  @override
  State<TransferCaseFormScreen> createState() => _TransferCaseFormScreenState();
}

class _TransferCaseFormScreenState extends State<TransferCaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _outwardNoController = TextEditingController();
  final _remarkController = TextEditingController();

  String? _selectedState = 'Maharashtra';
  String? _selectedDistrict = 'Mumbai';
  String? _selectedStation;

  DateTime _outwardDate = DateTime.now();

  @override
  void dispose() {
    _outwardNoController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedStation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translate(
                context, 'Please select a destination station')),
            backgroundColor: AppColors.dangerRed,
          ),
        );
        return;
      }

      // MOCK: Show success and pop with a 'transferred' result.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translate(
              context, 'Case Transferred Successfully (Mock)')),
          backgroundColor: AppColors.successGreen,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.navyDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          TranslationHelper.translate(context, 'Transfer Case'),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Destination Location'),
                  const SizedBox(height: 16),
                  _buildDropdown('State', ['Maharashtra'], _selectedState,
                      (val) => setState(() => _selectedState = val)),
                  const SizedBox(height: 16),
                  _buildDropdown(
                      'District',
                      ['Mumbai', 'Pune', 'Nagpur'],
                      _selectedDistrict,
                      (val) => setState(() {
                            _selectedDistrict = val;
                            _selectedStation = null;
                          })),
                  const SizedBox(height: 16),
                  _buildDropdown(
                      'Station',
                      [
                        'Colaba Police Station',
                        'Dadar Police Station',
                        'Bandra Police Station'
                      ],
                      _selectedStation,
                      (val) => setState(() => _selectedStation = val)),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Transfer Details'),
                  const SizedBox(height: 16),
                  _buildTextField('Outward No.', _outwardNoController,
                      required: true),
                  const SizedBox(height: 16),
                  _buildDatePicker(context, 'Outward Date'),
                  const SizedBox(height: 16),
                  _buildTextField(
                      'Remark / Reason for Transfer', _remarkController,
                      maxLines: 3),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Order Memo Upload'),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Mock file upload
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('File upload mocked.')),
                      );
                    },
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Select Document'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      foregroundColor: AppColors.goldPrimary,
                      side: const BorderSide(color: AppColors.goldPrimary),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        TranslationHelper.translate(context, 'Submit Transfer'),
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      TranslationHelper.translate(context, title),
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.navyDark,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: TranslationHelper.translate(context, label),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool required = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: TranslationHelper.translate(context, label) +
            (required ? ' *' : ''),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator:
          required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _buildDatePicker(BuildContext context, String label) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _outwardDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) setState(() => _outwardDate = date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: TranslationHelper.translate(context, label),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_outwardDate.toLocal()}'.split(' ')[0]),
            const Icon(Icons.calendar_today_rounded,
                size: 18, color: AppColors.lightSubText),
          ],
        ),
      ),
    );
  }
}
