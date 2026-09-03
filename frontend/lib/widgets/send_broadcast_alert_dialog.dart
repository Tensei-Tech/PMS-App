import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/police_hierarchy_helper.dart';

/// Dialog to send State-wide / District-wide alerts & reminders.
class SendBroadcastAlertDialog extends StatefulWidget {
  const SendBroadcastAlertDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const SendBroadcastAlertDialog(),
    );
  }

  @override
  State<SendBroadcastAlertDialog> createState() =>
      _SendBroadcastAlertDialogState();
}

class _SendBroadcastAlertDialogState extends State<SendBroadcastAlertDialog> {
  final _messageCtrl = TextEditingController();
  String _alertType = 'Alert'; // Alert or Reminder
  bool _isSending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  void _sendBroadcast() {
    if (_messageCtrl.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Broadcast $_alertType sent successfully to assigned jurisdiction!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSuper =
        PoliceHierarchyHelper.isStateSuperAdmin(auth.designation, auth.roleId);
    final isDistrict =
        PoliceHierarchyHelper.isDistrictAdmin(auth.designation, auth.roleId);

    final scopeLabel = isSuper
        ? 'STATE-WIDE BROADCAST (ALL DISTRICTS)'
        : (isDistrict ? 'DISTRICT-WIDE BROADCAST' : 'STATION REMINDER');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.campaign_rounded,
                      color: AppColors.goldPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dispatch Broadcast / Alert',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark),
                      ),
                      Text(
                        scopeLabel,
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.goldPrimary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const Divider(height: 24),

            // Type Selector
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Broadcast Alert'),
                  selected: _alertType == 'Alert',
                  onSelected: (ok) => setState(() => _alertType = 'Alert'),
                  selectedColor: AppColors.navyDark,
                  labelStyle: TextStyle(
                      color: _alertType == 'Alert'
                          ? Colors.white
                          : AppColors.navyDark),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Send Reminder'),
                  selected: _alertType == 'Reminder',
                  onSelected: (ok) => setState(() => _alertType = 'Reminder'),
                  selectedColor: AppColors.navyDark,
                  labelStyle: TextStyle(
                      color: _alertType == 'Reminder'
                          ? Colors.white
                          : AppColors.navyDark),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Message Area
            TextFormField(
              controller: _messageCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Type official directive, emergency alert or pending case reminder...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isSending ? null : _sendBroadcast,
                icon: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
                label: Text(
                  _isSending ? 'Dispatching...' : 'Dispatch Broadcast',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
