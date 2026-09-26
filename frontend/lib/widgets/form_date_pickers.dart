import 'package:flutter/material.dart';

Widget formDatePickerField(
  BuildContext context, {
  required TextEditingController controller,
  TextEditingController? dayCtrl,
  TextEditingController? monthCtrl,
  TextEditingController? yearCtrl,
  double? width,
  String hintText = 'Select Date',
  bool readOnly = false,
}) {
  return SizedBox(
    width: width ?? 140,
    child: TextFormField(
      controller: controller,
      readOnly: true, // always readonly, using onTap
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 12,
        ),
        suffixIcon:
            const Icon(Icons.calendar_today, size: 16, color: Colors.black87),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF333333), width: 1.0),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1976D2), width: 1.5),
        ),
      ),
      onTap: readOnly
          ? null
          : () async {
              DateTime initialDate = DateTime.now();
              if (controller.text.isNotEmpty) {
                try {
                  final parts = controller.text.split(RegExp(r'[/.-]'));
                  if (parts.length >= 3) {
                    int d = int.parse(parts[0]);
                    int m = int.parse(parts[1]);
                    int y = int.parse(parts[2]);
                    if (y < 100) y += 2000;
                    initialDate = DateTime(y, m, d);
                  }
                } catch (_) {}
              }
              final picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                final d = picked.day.toString().padLeft(2, '0');
                final m = picked.month.toString().padLeft(2, '0');
                final y = picked.year.toString();
                controller.text = '$d/$m/$y';
                if (dayCtrl != null) dayCtrl.text = d;
                if (monthCtrl != null) monthCtrl.text = m;
                if (yearCtrl != null) yearCtrl.text = y;
              }
            },
    ),
  );
}

Widget formTimePickerField(
  BuildContext context, {
  required TextEditingController controller,
  double? width,
  String hintText = 'Select Time',
  bool readOnly = false,
}) {
  return SizedBox(
    width: width ?? 140,
    child: TextFormField(
      controller: controller,
      readOnly: true, // always readonly, using onTap
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 12,
        ),
        suffixIcon: const Icon(Icons.access_time, size: 16, color: Colors.black87),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF333333), width: 1.0),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1976D2), width: 1.5),
        ),
      ),
      onTap: readOnly
          ? null
          : () async {
              TimeOfDay initialTime = TimeOfDay.now();
              if (controller.text.isNotEmpty) {
                try {
                  final cleanStr =
                      controller.text.replaceAll(RegExp(r'[^\d:]'), '');
                  final parts = cleanStr.split(':');
                  if (parts.length >= 2) {
                    int h = int.parse(parts[0]);
                    int m = int.parse(parts[1]);
                    if (controller.text.toLowerCase().contains('pm') && h < 12)
                      // ignore: curly_braces_in_flow_control_structures
                      h += 12;
                    if (controller.text.toLowerCase().contains('am') && h == 12)
                      // ignore: curly_braces_in_flow_control_structures
                      h = 0;
                    initialTime = TimeOfDay(hour: h, minute: m);
                  }
                } catch (_) {}
              }
              final picked = await showTimePicker(
                context: context,
                initialTime: initialTime,
              );
              if (picked != null) {
                // ignore: use_build_context_synchronously
                controller.text = picked.format(context);
              }
            },
    ),
  );
}
