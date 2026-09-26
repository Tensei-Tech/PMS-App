import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'form_date_pickers.dart';
import 'form_paper_page.dart';
import 'form_view_scaffold.dart';

/// Editable Transit Remand Requisition Form (Left-aligned Letter format).
class TransitRemandFormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const TransitRemandFormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<TransitRemandFormView> createState() => TransitRemandFormViewState();
}

class TransitRemandFormViewState extends State<TransitRemandFormView> {
  // Header fields
  final _outwardNoCtrl = TextEditingController();
  final _outwardYearCtrl = TextEditingController();
  final _psNameCtrl = TextEditingController();
  final _psCityCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  // Addressee fields
  final _courtLine1Ctrl = TextEditingController();
  final _courtLine2Ctrl = TextEditingController();

  // Report fields
  final _officerNameCtrl = TextEditingController();
  final _officerRankCtrl = TextEditingController();
  final _officerPsCtrl = TextEditingController();

  // Subject
  final _subjectHoursCtrl = TextEditingController();

  // Body text
  final _bodyCtrl = TextEditingController();

  // Footer / Sign-off
  final _signOffNameCtrl = TextEditingController();

  @override
  void dispose() {
    _outwardNoCtrl.dispose();
    _outwardYearCtrl.dispose();
    _psNameCtrl.dispose();
    _psCityCtrl.dispose();
    _dateCtrl.dispose();
    _courtLine1Ctrl.dispose();
    _courtLine2Ctrl.dispose();
    _officerNameCtrl.dispose();
    _officerRankCtrl.dispose();
    _officerPsCtrl.dispose();
    _subjectHoursCtrl.dispose();
    _bodyCtrl.dispose();
    _signOffNameCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    final fullDate = _dateCtrl.text.trim();
    final fullOutward =
        '${_outwardNoCtrl.text.trim()}/${_outwardYearCtrl.text.trim()}';

    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'outwardNo': _outwardNoCtrl.text.trim(),
      'outwardYear': _outwardYearCtrl.text.trim(),
      'fullOutward': fullOutward,
      'psName': _psNameCtrl.text.trim(),
      'psCity': _psCityCtrl.text.trim(),
      'dateDay': '',
      'dateMonthYear': '',
      'date': fullDate,
      'courtLine1': _courtLine1Ctrl.text.trim(),
      'courtLine2': _courtLine2Ctrl.text.trim(),
      'officerName': _officerNameCtrl.text.trim(),
      'officerRank': _officerRankCtrl.text.trim(),
      'officerPs': _officerPsCtrl.text.trim(),
      'subjectHours': _subjectHoursCtrl.text.trim(),
      'body': _bodyCtrl.text.trim(),
      'signOffName': _signOffNameCtrl.text.trim(),

      // Legacy compatibility mappings for case title & search indexing
      'eFirNo': '',
      'eDate': fullDate,
      'm1Date': fullDate,
      'eArrestedName': '',
      'm1AccusedName': '',
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    if (data.containsKey('outwardNo')) {
      _outwardNoCtrl.text = data['outwardNo']?.toString() ?? '';
    }
    if (data.containsKey('outwardYear')) {
      _outwardYearCtrl.text = data['outwardYear']?.toString() ?? '2021';
    }
    if (data.containsKey('psName')) {
      _psNameCtrl.text = data['psName']?.toString() ?? '';
    }
    if (data.containsKey('psCity')) {
      _psCityCtrl.text = data['psCity']?.toString() ?? '';
    }
    if (data.containsKey('date')) {
      _dateCtrl.text = data['date']?.toString() ?? '';
    } else {
      final day = data['dateDay']?.toString() ?? '';
      final my = data['dateMonthYear']?.toString() ?? '';
      _dateCtrl.text = '$day $my'.trim();
    }
    if (data.containsKey('courtLine1')) {
      _courtLine1Ctrl.text = data['courtLine1']?.toString() ?? '';
    }
    if (data.containsKey('courtLine2')) {
      _courtLine2Ctrl.text = data['courtLine2']?.toString() ?? '';
    }
    if (data.containsKey('officerName')) {
      _officerNameCtrl.text = data['officerName']?.toString() ?? '';
    }
    if (data.containsKey('officerRank')) {
      _officerRankCtrl.text = data['officerRank']?.toString() ?? '';
    }
    if (data.containsKey('officerPs')) {
      _officerPsCtrl.text = data['officerPs']?.toString() ?? '';
    }
    if (data.containsKey('subjectHours')) {
      _subjectHoursCtrl.text = data['subjectHours']?.toString() ?? '72';
    }
    if (data.containsKey('body')) {
      _bodyCtrl.text = data['body']?.toString() ?? '';
    }
    if (data.containsKey('signOffName')) {
      _signOffNameCtrl.text = data['signOffName']?.toString() ?? '';
    }
    if (mounted) setState(() {});
  }

  Widget _buildEditableUnderline({
    required TextEditingController controller,
    String? hintText,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    TextAlign textAlign = TextAlign.start,
  }) {
    final style = GoogleFonts.lora(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: Colors.black87,
    );

    return TextField(
      controller: controller,
      readOnly: widget.readOnly,
      textAlign: textAlign,
      style: style,
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: style.copyWith(color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black54, width: 0.8),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black45, width: 0.8),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black87, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.lora(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
    final boldLabel = GoogleFonts.lora(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        FormPaperPage(
          children: [
            // ── Left-Aligned Header Block ──
            SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Outward No. ', style: boldLabel),
                      Expanded(
                        child: _buildEditableUnderline(
                          controller: _outwardNoCtrl,
                          hintText: '      ',
                        ),
                      ),
                      Text(' /', style: boldLabel),
                      SizedBox(
                        width: 48,
                        child: _buildEditableUnderline(
                          controller: _outwardYearCtrl,
                          hintText: '2021',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildEditableUnderline(
                    controller: _psNameCtrl,
                    hintText: 'Police Station',
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 6),
                  _buildEditableUnderline(
                    controller: _psCityCtrl,
                    hintText: 'District / City',
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Date - ', style: boldLabel),
                      formDatePickerField(
                        context,
                        controller: _dateCtrl,
                        width: 140,
                        readOnly: widget.readOnly,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── To Section ──
            Text('To,', style: titleStyle),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Hon.-', style: boldLabel),
                Expanded(
                  child: _buildEditableUnderline(
                    controller: _courtLine1Ctrl,
                    hintText: '----------------------------------------',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildEditableUnderline(
              controller: _courtLine2Ctrl,
              hintText: '---------------------------------------------------',
            ),

            const SizedBox(height: 20),

            // ── Report Section ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report- ', style: boldLabel),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildEditableUnderline(
                              controller: _officerNameCtrl,
                              hintText: 'Jitendra S. Girnar',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(', ', style: boldLabel),
                          Expanded(
                            flex: 3,
                            child: _buildEditableUnderline(
                              controller: _officerRankCtrl,
                              hintText: 'Police Sub Inpector',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildEditableUnderline(
                        controller: _officerPsCtrl,
                        hintText: 'Wakad Police Station, Pimpri Chichwad.',
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Subject Section ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Sub- To get Transit Remand for ', style: boldLabel),
                SizedBox(
                  width: 45,
                  child: _buildEditableUnderline(
                    controller: _subjectHoursCtrl,
                    hintText: '72',
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(' hrs.', style: boldLabel),
              ],
            ),

            const SizedBox(height: 20),

            // ── Left-Aligned Symbol ──
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '---000---',
                style: GoogleFonts.lora(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Respected Sir & Editable Document Body ──
            Text('Respected Sir,', style: boldLabel),
            const SizedBox(height: 8),

            TextField(
              controller: _bodyCtrl,
              readOnly: widget.readOnly,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textAlign: TextAlign.left,
              style: GoogleFonts.lora(
                fontSize: 13.5,
                height: 1.55,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black54, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 4,
                ),
              ),
            ),

            const SizedBox(height: 36),

            // ── Left-Aligned Signature / Sign-Off ──
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Faithfully', style: boldLabel),
                    const SizedBox(height: 20),
                    _buildEditableUnderline(
                      controller: _signOffNameCtrl,
                      hintText: '                      ',
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ],
    );
  }
}
