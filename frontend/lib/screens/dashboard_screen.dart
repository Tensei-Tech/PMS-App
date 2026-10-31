// lib/screens/dashboard_screen.dart
// Issues 5,6,7,8,9,11: Responsive layout, Drawer with 16 classifications,
// Profile icon dropdown, News carousel, functional search, "Case Types" rename.

import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:khakhi_diary/providers/settings_provider.dart';
import 'package:khakhi_diary/providers/notification_provider.dart';

import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../data/india_districts_repository.dart';
import '../data/india_states.dart';
import '../data/maharashtra_police_stations_repository.dart';
import '../l10n/app_localizations.dart';
import '../modules/absconded/providers/absconded_provider.dart';
import '../modules/accident/providers/accident_provider.dart';
import '../modules/accidental_death/providers/accidental_death_provider.dart';
import '../modules/application/providers/application_provider.dart';
import '../modules/arrested/providers/arrested_provider.dart';
import '../modules/bnss/providers/bnss_provider.dart';
import '../modules/coin/providers/coin_provider.dart';
import '../modules/core/models/base_record.dart';
import '../modules/crime_women/providers/crime_women_provider.dart';
import '../modules/detected/providers/detected_provider.dart';
import '../modules/disposal/providers/disposal_provider.dart';
import '../modules/form_iv/providers/form_iv_provider.dart';
import '../modules/form_vi/providers/form_vi_provider.dart';
import '../modules/gowans/providers/gowans_provider.dart';
import '../modules/hurt/providers/hurt_provider.dart';
import '../modules/it_act/providers/it_act_provider.dart';
import '../modules/juvenile/providers/juvenile_provider.dart';
import '../modules/kidnapping/providers/kidnapping_provider.dart';
import '../modules/mcoca/providers/mcoca_provider.dart';
import '../modules/missing/providers/missing_provider.dart';
import '../modules/missing/screens/missing_form_screen.dart';
import '../modules/monthly/providers/monthly_provider.dart';
import '../modules/mpda/providers/mpda_provider.dart';
import '../modules/muddemal/providers/muddemal_provider.dart';
import '../modules/muddemal/screens/muddemal_main_screen.dart';
import '../modules/nc/providers/nc_provider.dart';
import '../modules/nc/screens/nc_form_screen.dart';
import '../modules/ndps/providers/ndps_provider.dart';
import '../modules/passport/providers/passport_provider.dart';
import '../modules/passport/widgets/passport_add_edit_dialog.dart';
import '../modules/licence/providers/licence_provider.dart';
import '../modules/licence/screens/licence_hub_screen.dart';
import '../modules/pending/providers/pending_provider.dart';
import '../modules/pocso/providers/pocso_provider.dart';
import '../modules/preventive/providers/preventive_provider.dart';
import '../modules/preventive/screens/preventive_form_screen.dart';
import '../modules/sam_warrant/providers/sam_warrant_provider.dart';
import '../modules/sand_theft/providers/sand_theft_provider.dart';
import '../modules/theft/providers/theft_provider.dart';
import '../modules/traffic/providers/traffic_provider.dart';
import '../modules/two_four_wheeler/providers/two_four_wheeler_provider.dart';
import '../modules/uapa/providers/uapa_provider.dart';
import '../modules/undetected/providers/undetected_provider.dart';
import '../modules/victim/providers/victim_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/news_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../services/backend_case_service.dart';
import '../widgets/pending_time_wise_card.dart';
import '../utils/app_constants.dart';
import '../utils/case_visibility_ui.dart';
import '../utils/common_form_module.dart';
import '../utils/module_pdf_helper.dart';
import '../utils/pdf_helper.dart';
import '../utils/police_hierarchy_helper.dart';
import '../utils/police_rbac_helper.dart';
import '../utils/state_branding_helper.dart';
import '../utils/state_language_helper.dart';
import '../utils/translation_helper.dart';
import '../utils/universal_search.dart';
import '../widgets/app_logo.dart';
import 'pending_hub_screen.dart';
import 'itsso_hub_screen.dart';
import 'dar_hub_screen.dart';
import 'irad_hub_screen.dart';
import 'undetected_hub_screen.dart';
import 'detected_hub_screen.dart';
import 'disposal_hub_screen.dart';
import 'arrested_hub_screen.dart';
import 'juvenile_hub_screen.dart';
import 'victim_hub_screen.dart';
import 'repeat_offender_summary_screen.dart';
import 'elearning_screen.dart';
import '../widgets/bell_icon_widget.dart';
import '../widgets/form_iv_category_button.dart';
import '../widgets/searchable_picker_field.dart';
import '../widgets/send_broadcast_alert_dialog.dart';
import '../utils/app_data_cache.dart';
import '../utils/category_icon_helper.dart';
import '../utils/category_navigation_helper.dart';
import '../services/case_service.dart';
import '../widgets/send_reminder_dialog.dart';
import '../widgets/state_police_banner_dialog.dart';
import '../widgets/voice_search_dialog.dart';
import 'about_app_screen.dart';
import 'absconded_hub_screen.dart';
import 'ad_record_detail_screen.dart';
import 'add_members_screen.dart';
import 'admin_panel_screen.dart';
import 'analytics_performance_screen.dart';
import 'app_settings_screen.dart';
import 'case_detail_screen.dart';
import 'case_form_screen.dart';
import 'common_form_screen.dart';
import 'feedback_form_screen.dart';
import 'form_i_v_selection_screen.dart';
import 'category_subtabs_screen.dart';
import 'form_vi_selection_screen.dart';
import 'help_support_screen.dart';
import 'hurt_cases_screen.dart';
import 'login_security_screen.dart';
import 'module_form_screen.dart';
import 'module_hub_screen.dart';
import 'module_record_detail_screen.dart';
import 'my_cases_screen.dart';
import 'pending_transfers_screen.dart';
import '../widgets/dynamic_form/dynamic_form_screen.dart';
import '../widgets/logout_confirm_dialog.dart';
// Navigation targets for Hamburger Menu
import 'profile_screen.dart';
import 'station_access_grants_screen.dart';

String? _getDashboardSvgPath(String label) {
  final clean = label.toLowerCase().replaceAll(RegExp(r'[\s/._\\]+'), '');
  for (final tool in ServiceData.dashboardTools) {
    if (label.toLowerCase() == tool.label.toLowerCase() ||
        (tool.moduleKey != null && clean == tool.moduleKey!.toLowerCase())) {
      if (tool.assetPath != null && tool.assetPath!.isNotEmpty) {
        return tool.assetPath;
      }
    }
  }
  switch (clean) {
    case 'itov':
    case '1to5':
      return 'assets/icons/1to5.svg';
    case 'vi':
    case '6':
      return 'assets/icons/6.svg';
    case 'pending':
      return 'assets/icons/pending.svg';
    case 'gambling':
      return 'assets/icons/gambling.svg';
    case 'juvenile':
      return 'assets/icons/juvenile.svg';
    case 'sandtheft':
      return 'assets/icons/sandtheft.svg';
    case 'undetected':
      return 'assets/icons/undetected.svg';
    case 'hurt':
      return 'assets/icons/hurt.svg';
    case 'kidnappingmissing':
    case 'kidnapping':
      return 'assets/icons/kidnapping.svg';
    case 'missing':
      return 'assets/icons/missing.svg';
    case 'nc':
      return 'assets/icons/nc.svg';
    case 'arrested':
      return 'assets/icons/arrested.svg';
    case 'pocso':
      return 'assets/icons/pocso.svg';
    case 'crimeagainstwomen':
      return 'assets/icons/crimewomen.svg';
    case 'victim':
      return 'assets/icons/victim.svg';
    case 'ad':
      return 'assets/icons/ad.svg';
    case 'prohibition':
      return 'assets/icons/prohibiton.svg';
    case 'theft':
      return 'assets/icons/theft.svg';
    case 'twofourwheelertheft':
    case 'twofourwheelerstolen':
    case '24wheeler':
      return 'assets/icons/2-4wheeler.svg';
    case 'samwarrant':
    case 'samwarrants':
      return 'assets/icons/sam-warrants.svg';
    case 'muddemal':
    case 'propertyrecovery':
      return 'assets/icons/muddemal.svg';
    case 'rti':
      return 'assets/icons/rti.svg';
    case 'passportpvr':
    case 'passportpvrlic':
    case 'passport':
      return 'assets/icons/passport.svg';
    case 'ndps':
      return 'assets/icons/ndps.svg';
    case 'gowansh':
    case 'gowans':
      return 'assets/icons/gowans.svg';
    case 'itact':
      return 'assets/icons/itact.svg';
    case 'mcoca':
    case 'macoca':
      return 'assets/icons/macoca.svg';
    case 'uapa':
      return 'assets/icons/uapa.svg';
    case 'mpda':
      return 'assets/icons/mpda.svg';
    case 'coin':
      return 'assets/icons/coin.svg';
    case 'mvact':
      return 'assets/icons/mvact.svg';
    case 'accident':
      return 'assets/icons/accident.svg';
    case 'detected':
      return 'assets/icons/detected.svg';
    case 'disposal':
      return 'assets/icons/disposal.svg';
    case 'monthly':
      return 'assets/icons/monthly.svg';
    case 'absconded':
      return 'assets/icons/absconded.svg';
    case 'cctns':
      return 'assets/icons/cctns.svg';
    case 'licence':
      return 'assets/icons/licence.svg';
    case 'repeatoffender':
      return 'assets/icons/repeatoffender.svg';
    case 'dar':
    case 'darirad':
      return 'assets/icons/dar.svg';
    case 'irad':
    case 'irda':
      return 'assets/icons/IRAD.svg';
    case 'itsso':
      return 'assets/icons/itsso.svg';
    case 'murderattempttomurder':
    case 'murder':
    case 'attempttomurder':
    case 'atttomurder':
      return 'assets/icons/murder.svg';
    case 'dacoityrobbery':
    case 'dacoity':
    case 'decoity':
    case 'proofdacoity':
    case 'proofdecoity':
      return 'assets/icons/dacoity.svg';
    case 'chainsnatching':
    case 'snatching':
      return 'assets/icons/chain_snatching.svg';
    default:
      if (clean.contains('passport')) return 'assets/icons/passport.svg';
      if (clean.contains('murder')) return 'assets/icons/murder.svg';
      if (clean.contains('dacoity') || clean.contains('decoity')) {
        return 'assets/icons/dacoity.svg';
      }
      if (clean.contains('snatch')) {
        return 'assets/icons/chain_snatching.svg';
      }
      return null;
  }
}

Widget _buildGridIcon(
    String label, dynamic fallback, Color color, double size) {
  final labelTrim = label.replaceAll('\n', ' ').trim();
  final svgPath = _getDashboardSvgPath(labelTrim);
  if (svgPath != null) {
    // Optical balancing:
    // Solid filled badges (1-5, 6, NC, RTI, DAR, MPDA, ITSSO, IRAD) have heavy ink mass; scale to balance with line art
    final isSolidBadge = svgPath.contains('1to5') ||
        svgPath.contains('6.svg') ||
        svgPath.contains('nc.svg') ||
        svgPath.contains('rti.svg') ||
        svgPath.contains('dar.svg') ||
        svgPath.contains('mpda.svg') ||
        svgPath.contains('itsso.svg') ||
        svgPath.contains('IRAD.svg');
    // Tall icons need a slight height factor to match square icon visual mass
    final isTall = svgPath.contains('juvenile') ||
        svgPath.contains('crimewomen') ||
        svgPath.contains('victim') ||
        svgPath.contains('passport') ||
        svgPath.contains('mvact');
    // Wide icons need a slight constraint so they don't crowd card borders
    final isWide = svgPath.contains('2-4wheeler') ||
        svgPath.contains('accident') ||
        svgPath.contains('chain_snatching');

    final double scale =
        isSolidBadge ? 1.20 : (isTall ? 1.50 : (isWide ? 1.34 : 1.42));

    return SvgPicture.asset(
      svgPath,
      width: size * scale,
      height: size * scale,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
  final glyphSize = size * 1.42;
  if (fallback is IconData)
    // ignore: curly_braces
    //
    // _in_flow_control_structures
    // ignore: curly_braces_in_flow_control_structures
    return Icon(fallback, color: color, size: glyphSize);
  return FaIcon(fallback, color: color, size: glyphSize);
}

class CardsIconPainter extends CustomPainter {
  final Color color;
  CardsIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background card
    canvas.save();
    canvas.translate(w * 0.65, h * 0.45);
    canvas.rotate(0.3);
    final bgRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w * 0.55, height: h * 0.75),
        const Radius.circular(3));
    canvas.drawRRect(bgRect, Paint()..color = color);
    canvas.restore();

    // Foreground card
    canvas.save();
    canvas.translate(w * 0.35, h * 0.55);
    canvas.rotate(-0.15);
    final fgRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w * 0.6, height: h * 0.8),
        const Radius.circular(3));

    canvas.drawRRect(fgRect, Paint()..color = Colors.white);
    canvas.drawRRect(fgRect, Paint()..color = color);

    final spadePaint = Paint()..color = Colors.white;
    final path = Path();
    final sh = h * 0.3;
    final sw = w * 0.25;

    path.moveTo(0, -sh * 0.5);
    path.cubicTo(sw * 0.8, -sh * 0.1, sw * 0.8, sh * 0.3, sw * 0.4, sh * 0.3);
    path.cubicTo(sw * 0.2, sh * 0.3, 0, sh * 0.1, 0, sh * 0.1);
    path.cubicTo(0, sh * 0.1, -sw * 0.2, sh * 0.3, -sw * 0.4, sh * 0.3);
    path.cubicTo(-sw * 0.8, sh * 0.3, -sw * 0.8, -sh * 0.1, 0, -sh * 0.5);

    path.moveTo(0, sh * 0.1);
    path.lineTo(sw * 0.2, sh * 0.6);
    path.lineTo(-sw * 0.2, sh * 0.6);
    path.close();

    canvas.drawPath(path, spadePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class JuvenileIconPainter extends CustomPainter {
  final Color color;
  JuvenileIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final headCenterY = h * 0.25;
    final headRadius = w * 0.2;

    // main head
    canvas.drawCircle(Offset(w * 0.5, headCenterY), headRadius, paint);

    // Ears
    canvas.drawCircle(Offset(w * 0.28, headCenterY), headRadius * 0.35, paint);
    canvas.drawCircle(Offset(w * 0.72, headCenterY), headRadius * 0.35, paint);

    // Hair swirl
    final hairPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;

    final hairPath = Path();
    hairPath.moveTo(w * 0.5, headCenterY - headRadius);
    hairPath.cubicTo(
        w * 0.55,
        headCenterY - headRadius - h * 0.1,
        w * 0.4,
        headCenterY - headRadius - h * 0.1,
        w * 0.48,
        headCenterY - headRadius - h * 0.03);
    canvas.drawPath(hairPath, hairPaint);

    // White strokes for face features
    final whiteStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;

    // Left eye (U curve)
    final leftEyePath = Path();
    leftEyePath.moveTo(w * 0.37, headCenterY - h * 0.02);
    leftEyePath.quadraticBezierTo(
        w * 0.42, headCenterY + h * 0.04, w * 0.47, headCenterY - h * 0.02);
    canvas.drawPath(leftEyePath, whiteStroke);

    // Right eye
    final rightEyePath = Path();
    rightEyePath.moveTo(w * 0.53, headCenterY - h * 0.02);
    rightEyePath.quadraticBezierTo(
        w * 0.58, headCenterY + h * 0.04, w * 0.63, headCenterY - h * 0.02);
    canvas.drawPath(rightEyePath, whiteStroke);

    // Smile
    final smilePath = Path();
    smilePath.moveTo(w * 0.42, headCenterY + h * 0.07);
    smilePath.quadraticBezierTo(
        w * 0.5, headCenterY + h * 0.12, w * 0.58, headCenterY + h * 0.07);
    canvas.drawPath(smilePath, whiteStroke);

    // Bottom part: Scale of Justice
    final barY = headCenterY + headRadius + h * 0.02; // Top bar y position
    final scaleBottom = h * 0.95;

    // Top bar
    canvas.drawLine(
        Offset(w * 0.25, barY), Offset(w * 0.75, barY), strokePaint);

    // Central stand (down from bar)
    canvas.drawLine(Offset(w * 0.5, barY),
        Offset(w * 0.5, scaleBottom - h * 0.08), strokePaint);

    // Base (Trapezoid)
    final basePath = Path();
    basePath.moveTo(w * 0.38, scaleBottom - h * 0.08);
    basePath.lineTo(w * 0.62, scaleBottom - h * 0.08);
    basePath.lineTo(w * 0.7, scaleBottom);
    basePath.lineTo(w * 0.3, scaleBottom);
    basePath.close();
    canvas.drawPath(basePath, paint);

    // Strings
    final stringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final panY = h * 0.78; // Y where strings meet the pan

    // Left strings
    canvas.drawLine(
        Offset(w * 0.25, barY), Offset(w * 0.15, panY), stringPaint);
    canvas.drawLine(
        Offset(w * 0.25, barY), Offset(w * 0.35, panY), stringPaint);

    // Left pan (semi circle)
    final leftPanPath = Path();
    leftPanPath.arcTo(
      Rect.fromLTRB(w * 0.15, panY - (w * 0.1), w * 0.35, panY + (w * 0.1)),
      0,
      3.14159265359,
      false,
    );
    leftPanPath.close();
    canvas.drawPath(leftPanPath, paint);

    // Right strings
    canvas.drawLine(
        Offset(w * 0.75, barY), Offset(w * 0.65, panY), stringPaint);
    canvas.drawLine(
        Offset(w * 0.75, barY), Offset(w * 0.85, panY), stringPaint);

    // Right pan
    final rightPanPath = Path();
    rightPanPath.arcTo(
      Rect.fromLTRB(w * 0.65, panY - (w * 0.1), w * 0.85, panY + (w * 0.1)),
      0,
      3.14159265359,
      false,
    );
    rightPanPath.close();
    canvas.drawPath(rightPanPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SandTheftIconPainter extends CustomPainter {
  final Color color;
  SandTheftIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final chassisYTop = h * 0.75;
    final chassisYBot = h * 0.85;

    // 1. Wheels
    final r = w * 0.12;
    canvas.drawCircle(Offset(w * 0.25, h * 0.8), r, strokePaint);
    canvas.drawCircle(Offset(w * 0.75, h * 0.8), r, strokePaint);

    // 2. Chassis
    // Left segment
    canvas.drawLine(Offset(w * 0.05, chassisYTop),
        Offset(w * 0.13, chassisYTop), strokePaint);
    canvas.drawLine(Offset(w * 0.05, chassisYBot),
        Offset(w * 0.13, chassisYBot), strokePaint);
    canvas.drawLine(Offset(w * 0.05, chassisYTop),
        Offset(w * 0.05, chassisYBot), strokePaint);

    // Middle segment
    canvas.drawLine(Offset(w * 0.37, chassisYTop),
        Offset(w * 0.63, chassisYTop), strokePaint);
    canvas.drawLine(Offset(w * 0.37, chassisYBot),
        Offset(w * 0.63, chassisYBot), strokePaint);

    // Right segment
    canvas.drawLine(Offset(w * 0.87, chassisYTop),
        Offset(w * 0.95, chassisYTop), strokePaint);
    canvas.drawLine(Offset(w * 0.87, chassisYBot),
        Offset(w * 0.95, chassisYBot), strokePaint);
    canvas.drawLine(Offset(w * 0.95, chassisYTop),
        Offset(w * 0.95, chassisYBot), strokePaint);

    // 3. Cab
    final cabPath = Path();
    cabPath.moveTo(w * 0.6, chassisYTop);
    cabPath.lineTo(w * 0.6, h * 0.3);
    cabPath.lineTo(w * 0.8, h * 0.3);
    cabPath.lineTo(w * 0.95, h * 0.55);
    cabPath.lineTo(w * 0.95, chassisYTop);
    canvas.drawPath(cabPath, strokePaint);

    // Cab window
    final winPath = Path();
    winPath.moveTo(w * 0.68, h * 0.38);
    winPath.lineTo(w * 0.78, h * 0.38);
    winPath.lineTo(w * 0.86, h * 0.52);
    winPath.lineTo(w * 0.68, h * 0.52);
    winPath.close();
    canvas.drawPath(winPath, strokePaint);

    // 4. Dump Bed
    final bedPath = Path();
    bedPath.moveTo(w * 0.15, chassisYTop);
    bedPath.lineTo(w * 0.05, h * 0.4);
    bedPath.lineTo(w * 0.45, h * 0.2);
    bedPath.lineTo(w * 0.55, h * 0.15);
    bedPath.lineTo(w * 0.55, h * 0.5);
    bedPath.close();
    canvas.drawPath(bedPath, strokePaint);

    // 5. Hydraulic Arm
    canvas.drawLine(
        Offset(w * 0.4, chassisYTop), Offset(w * 0.35, h * 0.6), strokePaint);

    // 6. Sand load (wavy line)
    final sandPath = Path();
    sandPath.moveTo(w * 0.1, h * 0.45);
    sandPath.quadraticBezierTo(w * 0.2, h * 0.35, w * 0.3, h * 0.45);
    sandPath.quadraticBezierTo(w * 0.4, h * 0.55, w * 0.5, h * 0.45);
    canvas.drawPath(sandPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class UndetectedIconPainter extends CustomPainter {
  final Color color;
  UndetectedIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final handlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22
      ..strokeCap = StrokeCap.round;

    final whiteStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = w * 0.6;
    final cy = h * 0.4;
    final r = w * 0.35;

    // Handle
    final handleStartX = cx - r * 0.707;
    final handleStartY = cy + r * 0.707;
    final handleEndX = w * 0.15;
    final handleEndY = h * 0.85;

    // Draw handle
    canvas.drawLine(Offset(handleStartX, handleStartY),
        Offset(handleEndX, handleEndY), handlePaint);

    // Gap
    final gapWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.butt;

    canvas.drawLine(Offset(handleStartX - w * 0.15, handleStartY - h * 0.15),
        Offset(handleStartX + w * 0.15, handleStartY + h * 0.15), gapWhite);

    // Draw outer circle
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // Inner white ring
    canvas.drawCircle(
        Offset(cx, cy),
        r * 0.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.07);

    // X mark
    final xSize = r * 0.3;
    canvas.drawLine(Offset(cx - xSize, cy - xSize),
        Offset(cx + xSize, cy + xSize), whiteStroke);
    canvas.drawLine(Offset(cx + xSize, cy - xSize),
        Offset(cx - xSize, cy + xSize), whiteStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HurtIconPainter extends CustomPainter {
  final Color color;
  HurtIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Knife Handle
    canvas.drawLine(
        Offset(w * 0.82, h * 0.15),
        Offset(w * 0.55, h * 0.42),
        Paint()
          ..color = color
          ..strokeWidth = w * 0.12
          ..strokeCap = StrokeCap.round);

    // 2. Knife Blade
    final blade = Path();
    blade.moveTo(w * 0.62, h * 0.3); // Top-right
    blade.lineTo(w * 0.15, h * 0.77); // Tip
    blade.quadraticBezierTo(
        w * 0.3, h * 0.85, w * 0.52, h * 0.5); // Bottom curve
    blade.close();
    canvas.drawPath(blade, paint);

    // 3. Knife Guards (White Cuts)
    final cutPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.butt;

    canvas.drawLine(
        Offset(w * 0.58, h * 0.28), Offset(w * 0.72, h * 0.42), cutPaint);
    canvas.drawLine(
        Offset(w * 0.54, h * 0.32), Offset(w * 0.68, h * 0.46), cutPaint);

    // 4. Blood Splat
    final splat = Path();
    splat.moveTo(w * 0.35, h * 0.5);
    splat.cubicTo(
        w * 0.35, h * 0.4, w * 0.55, h * 0.4, w * 0.55, h * 0.5); // Top bulge
    splat.cubicTo(
        w * 0.65, h * 0.5, w * 0.65, h * 0.65, w * 0.6, h * 0.65); // Right drip
    splat.cubicTo(w * 0.55, h * 0.65, w * 0.5, h * 0.55, w * 0.45,
        h * 0.6); // Inner curve
    splat.cubicTo(
        w * 0.4, h * 0.75, w * 0.3, h * 0.75, w * 0.3, h * 0.7); // Left drip
    splat.cubicTo(
        w * 0.3, h * 0.6, w * 0.25, h * 0.6, w * 0.35, h * 0.5); // Close

    canvas.drawPath(
        splat,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.04
          ..strokeJoin = StrokeJoin.round);
    canvas.drawPath(splat, paint);

    // 5. Blood Drops
    void drawDrop(double cx, double cy, double s) {
      final drop = Path();
      drop.moveTo(cx, cy - s);
      drop.quadraticBezierTo(cx + s, cy, cx + s, cy + s * 0.5);
      drop.arcToPoint(Offset(cx - s, cy + s * 0.5),
          radius: Radius.circular(s), clockwise: true);
      drop.quadraticBezierTo(cx - s, cy, cx, cy - s);
      canvas.drawPath(drop, paint);

      final inner = Path();
      final innerS = s * 0.4;
      final innerCy = cy + s * 0.35;
      inner.moveTo(cx, innerCy - innerS);
      inner.quadraticBezierTo(
          cx + innerS, innerCy, cx + innerS, innerCy + innerS * 0.5);
      inner.arcToPoint(Offset(cx - innerS, innerCy + innerS * 0.5),
          radius: Radius.circular(innerS), clockwise: true);
      inner.quadraticBezierTo(cx - innerS, innerCy, cx, innerCy - innerS);
      canvas.drawPath(
          inner,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.015);
    }

    drawDrop(w * 0.5, h * 0.78, w * 0.06);
    drawDrop(w * 0.62, h * 0.88, w * 0.045);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class KidnappingIconPainter extends CustomPainter {
  final Color color;
  KidnappingIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // --- PERSON ---
    final pStrokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Head
    canvas.drawCircle(Offset(w * 0.75, h * 0.18), w * 0.12, fillPaint);

    // Torso
    canvas.drawLine(
        Offset(w * 0.75, h * 0.32),
        Offset(w * 0.75, h * 0.62),
        Paint()
          ..color = color
          ..strokeWidth = w * 0.2
          ..strokeCap = StrokeCap.round);

    // Legs
    canvas.drawLine(
        Offset(w * 0.67, h * 0.6), Offset(w * 0.67, h * 0.95), pStrokePaint);
    canvas.drawLine(
        Offset(w * 0.83, h * 0.6), Offset(w * 0.83, h * 0.95), pStrokePaint);

    // Arms
    final arms = Path();
    arms.moveTo(w * 0.52, h * 0.15); // left hand
    arms.lineTo(w * 0.52, h * 0.35); // left elbow
    arms.lineTo(w * 0.75, h * 0.38); // shoulders
    arms.lineTo(w * 0.98, h * 0.35); // right elbow
    arms.lineTo(w * 0.98, h * 0.15); // right hand
    canvas.drawPath(arms, pStrokePaint);

    // --- GUN ---
    // Barrel
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(w * 0.08, h * 0.45, w * 0.48, h * 0.57),
            Radius.circular(w * 0.02)),
        fillPaint);

    // Sight bump
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(w * 0.1, h * 0.41, w * 0.15, h * 0.45),
            Radius.circular(w * 0.01)),
        fillPaint);

    // Grip
    final grip = Path();
    grip.moveTo(w * 0.18, h * 0.57); // top right
    grip.lineTo(w * 0.1, h * 0.88); // bottom right
    grip.lineTo(w * 0.0, h * 0.88); // bottom left
    grip.lineTo(w * 0.08, h * 0.57); // top left
    grip.close();
    canvas.drawPath(grip, fillPaint);
    canvas.drawPath(grip, strokePaint..strokeWidth = w * 0.02);

    // Trigger guard
    final guard = Path();
    guard.moveTo(w * 0.18, h * 0.57);
    guard.lineTo(w * 0.18, h * 0.65);
    guard.lineTo(w * 0.35, h * 0.65);
    guard.lineTo(w * 0.35, h * 0.57);
    canvas.drawPath(guard, strokePaint..strokeWidth = w * 0.035);

    // Trigger
    canvas.drawLine(Offset(w * 0.25, h * 0.57), Offset(w * 0.23, h * 0.61),
        strokePaint..strokeWidth = w * 0.02);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ADIconPainter extends CustomPainter {
  final Color color;
  ADIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. Puddle
    final puddle = Path();
    puddle.moveTo(w * 0.32, h * 0.63);
    puddle.cubicTo(w * 0.32, h * 0.85, w * 0.55, h * 1.0, w * 0.55, h * 0.75);
    puddle.cubicTo(w * 0.75, h * 0.75, w * 0.8, h * 0.5, w * 0.58, h * 0.37);
    puddle.close();
    canvas.drawPath(puddle, fillPaint);

    // 2. Small drop
    canvas.drawCircle(Offset(w * 0.7, h * 0.82), w * 0.05, fillPaint);

    // 3. Diagonal Line
    canvas.drawLine(
        Offset(w * 0.1, h * 0.85),
        Offset(w * 0.7, h * 0.25),
        Paint()
          ..color = color
          ..strokeWidth = w * 0.05
          ..strokeCap = StrokeCap.round);

    // 4. Person Head
    canvas.drawCircle(Offset(w * 0.7, h * 0.18), w * 0.08, fillPaint);

    // 5. Torso
    canvas.drawLine(
        Offset(w * 0.62, h * 0.28),
        Offset(w * 0.42, h * 0.48),
        Paint()
          ..color = color
          ..strokeWidth = w * 0.13
          ..strokeCap = StrokeCap.round);

    // 6. Arms
    // Left arm (front)
    final lArm = Path();
    lArm.moveTo(w * 0.58, h * 0.32); // Start lower on torso
    lArm.lineTo(w * 0.35, h * 0.32); // Left
    lArm.lineTo(w * 0.35, h * 0.46); // Down
    canvas.drawPath(lArm, strokePaint);

    // Right arm (back)
    final rArm = Path();
    rArm.moveTo(w * 0.62, h * 0.28); // Start at shoulder
    rArm.lineTo(w * 0.72, h * 0.45); // Down-right
    rArm.lineTo(w * 0.88, h * 0.28); // Up-right
    canvas.drawPath(rArm, strokePaint);

    // 7. Legs
    // Left leg (in air)
    final lLeg = Path();
    lLeg.moveTo(w * 0.42, h * 0.48); // Start at pelvis
    lLeg.lineTo(w * 0.18, h * 0.48); // Left
    lLeg.lineTo(w * 0.15, h * 0.65); // Down
    canvas.drawPath(lLeg, strokePaint);

    // Right leg (slipping)
    final rLeg = Path();
    rLeg.moveTo(w * 0.42, h * 0.48);
    rLeg.lineTo(w * 0.32, h * 0.62); // Down-left to the line
    canvas.drawPath(rLeg, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Clears settings caches only when the user, state or active station changed
/// or they are stale, instead of on every dashboard visit.
void _ensureFreshCaches(AuthProvider auth) {
  AppDataCache.ensureFresh(AppDataCache.scopeFor(
    uid: auth.uid,
    stateCode: auth.stateCode,
    station: auth.activeStation,
  ));
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Settings caches survive dashboard visits; they are cleared only for a
    // different user/state/station or when stale (see AppDataCache).
    _ensureFreshCaches(context.read<AuthProvider>());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().refreshProfileFromFirestore();
    });
  }

  void _onNavTap(int index) {
    if (index == 2) {
      _showAddBottomSheet();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _showAddBottomSheet() {
    final isDark = context.read<ThemeProvider>().isDark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCaseBottomSheet(isDark: isDark),
    );
  }

  // ✅ _updateModuleProviders REMOVED — handled globally by main.dart
  // _syncStationToAllProviders in main.dart injects stationId + createdBy
  // into all providers automatically on login/PIN verify/registration.

  @override
  Widget build(BuildContext context) {
    const bool isDark = false;
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    // ✅ Station injection removed from here — handled in main.dart globally

    final size = MediaQuery.of(context).size;
    final isWide = size.width >= Breakpoints.tablet;

    final pages = [
      _HomeTab(isDark: isDark, auth: auth, onViewAll: () => _onNavTap(3)),
      const _WantedTab(isDark: isDark),
      const _ViewTab(isDark: isDark),
      const _CalendarTab(isDark: isDark),
    ];

    final int pageIndex;
    if (_currentIndex < 2) {
      pageIndex = _currentIndex;
    } else if (_currentIndex == 3) {
      pageIndex = 2;
    } else {
      pageIndex = 3;
    }

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      resizeToAvoidBottomInset: false,
      drawer: !isWide
          ? _buildClassificationDrawer(isWide)
          : null, // Wide screens have persistent profile sidebar, no drawer needed
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: isWide
              ? _buildWideLayout(auth, l10n, pages, pageIndex)
              : _buildNarrowLayout(auth, l10n, pages, pageIndex),
        ),
      ),
      bottomNavigationBar: isWide ? null : _buildBottomNavBar(auth, l10n),
    );
  }

  Widget _buildWideLayout(AuthProvider auth, AppLocalizations l10n,
      List<Widget> pages, int pageIndex) {
    return Row(
      children: [
        _buildWebProfileSidebar(auth,
            l10n), // Persistent profile menu on wide screens (tablet + web)
        Expanded(
          child: Column(
            children: [
              _buildAppBar(auth, showHamburger: false),
              Expanded(
                child: IndexedStack(
                  index: pageIndex,
                  children: pages,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(AuthProvider auth, AppLocalizations l10n,
      List<Widget> pages, int pageIndex) {
    return Column(
      children: [
        _buildAppBar(auth, showHamburger: true),
        Expanded(
          child: IndexedStack(
            index: pageIndex,
            children: pages,
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(AuthProvider auth, {required bool showHamburger}) {
    final l10n = AppLocalizations.of(
        context)!; // WEB FIX: reuse localized labels for top nav on web
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 420;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallPhone ? 8 : 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showHamburger)
            Builder(
              builder: (ctx) => IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: AppColors.navyDark),
              ),
            ),
          Expanded(
            child: Builder(
              builder: (ctx) {
                final stateCode = auth.currentUser?.stateCode ?? auth.stateCode;
                final stateBranding =
                    StateBrandingHelper.getBranding(stateCode);
                final screenWidth = MediaQuery.of(ctx).size.width;
                final isVeryNarrow = screenWidth < 380;
                final forceTitleText = isVeryNarrow
                    ? stateBranding.shortForceTitle
                    : stateBranding.policeForceTitle;

                return InkWell(
                  onTap: () => StatePoliceBannerDialog.show(ctx, auth),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppLogo(
                            size: isSmallPhone ? 32 : 38,
                            logoUrl: auth.currentUser?.departmentLogoUrl,
                          ),
                          SizedBox(width: isSmallPhone ? 4 : 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.khakhiDiary.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallPhone ? 11.5 : 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              Text(
                                l10n.safeSwiftSecure,
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallPhone ? 7.5 : 8.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.navyMid,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          // Dynamic State Police Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  stateBranding.primaryColor
                                      .withValues(alpha: 0.08),
                                  stateBranding.accentColor
                                      .withValues(alpha: 0.18),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: stateBranding.accentColor
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (stateBranding.logoAssetPath != null)
                                  ClipOval(
                                    child: Image.asset(
                                      stateBranding.logoAssetPath!,
                                      width: isSmallPhone ? 20 : 24,
                                      height: isSmallPhone ? 20 : 24,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        stateBranding.emblemIcon,
                                        size: isSmallPhone ? 16 : 18,
                                        color: stateBranding.primaryColor,
                                      ),
                                    ),
                                  )
                                else
                                  Icon(
                                    stateBranding.emblemIcon,
                                    size: isSmallPhone ? 16 : 18,
                                    color: stateBranding.primaryColor,
                                  ),
                                const SizedBox(width: 3),
                                Text(
                                  forceTitleText,
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallPhone ? 10 : 11,
                                    fontWeight: FontWeight.w700,
                                    color: stateBranding.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: stateBranding.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: isSmallPhone ? 4 : 6),
          if (MediaQuery.of(context).size.width >= Breakpoints.tablet) ...[
            // Show top nav items on wide screens (tablet + web)
            const SizedBox(width: 14),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _topNavItem(Icons.home_rounded, l10n.home, 0),
                    const SizedBox(width: 8),
                    _topNavItem(Icons.gps_fixed_rounded, l10n.wanted, 1),
                    const SizedBox(width: 8),
                    _topNavItem(Icons.folder_rounded, l10n.view, 3),
                    const SizedBox(width: 8),
                    _topNavItem(Icons.calendar_month_rounded, l10n.calendar, 4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          const BellIconWidget(),
        ],
      ),
    );
  }

  Widget _topNavItem(IconData icon, String label, int index) {
    // WEB FIX: top navigation items beside title for web parity
    final isActive = _currentIndex == index; // WEB FIX: highlight current tab
    return InkWell(
      // WEB FIX: mouse + touch support on web
      onTap: () => _onNavTap(index), // WEB FIX: reuse existing navigation logic
      borderRadius:
          BorderRadius.circular(AppRadius.lg), // WEB FIX: match pill style
      child: Container(
        // WEB FIX
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // WEB FIX
        decoration: BoxDecoration(
          // WEB FIX
          color: isActive
              ? AppColors.navyMid.withValues(alpha: 0.08)
              : const Color(0xFFF4F6FB), // WEB FIX: subtle active state
          borderRadius: BorderRadius.circular(AppRadius.lg), // WEB FIX
          border: Border.all(
            // WEB FIX
            color: isActive
                ? AppColors.navyMid.withValues(alpha: 0.25)
                : AppColors.lightBorder, // WEB FIX
          ), // WEB FIX
        ), // WEB FIX
        child: Row(
          // WEB FIX
          mainAxisSize: MainAxisSize.min, // WEB FIX
          children: [
            // WEB FIX
            Icon(icon, size: 18, color: AppColors.navyDark), // WEB FIX
            const SizedBox(width: 8), // WEB FIX
            Text(
              // WEB FIX
              label, // WEB FIX
              style: GoogleFonts.poppins(
                // WEB FIX
                fontSize: 13, // WEB FIX
                fontWeight: FontWeight.w600, // WEB FIX
                color: AppColors.navyDark, // WEB FIX
              ), // WEB FIX
            ), // WEB FIX
          ], // WEB FIX
        ), // WEB FIX
      ), // WEB FIX
    ); // WEB FIX
  }

  Widget _buildDrawerHeader(AuthProvider auth, AppLocalizations l10n,
      {double headerHeight = 180}) {
    // RESPONSIVE FIX: get top padding for status bar / notch
    final topPadding = MediaQuery.of(context).padding.top;
    // Scale avatar and font sizes based on header height
    final isCompact = headerHeight < 160;
    final avatarRadius = isCompact ? 22.0 : 26.0;
    final avatarIconSize = isCompact ? 26.0 : 30.0;
    final nameFontSize = isCompact ? 15.0 : 17.0;
    final topInset = isCompact ? (topPadding + 10) : (topPadding + 14);

    final initial =
        auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'O';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        AppTheme.fadeSlideRoute(page: const ProfileScreen()),
      ),
      child: Container(
        width: double.infinity,
        height: headerHeight + topPadding,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E21), AppColors.navyMid],
          ),
        ),
        child: Stack(
          children: [
            // Background Decorative Element
            Positioned(
              right: -30,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                topInset,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Stylized Avatar with Gold Glow and Shield Badge Overlay
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.goldPrimary
                                    .withValues(alpha: 0.6),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.goldPrimary
                                      .withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: avatarRadius,
                              backgroundColor: AppColors.goldPrimary,
                              child: auth.profilePhoto.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        auth.profilePhoto,
                                        fit: BoxFit.cover,
                                        width: avatarRadius * 2,
                                        height: avatarRadius * 2,
                                        errorBuilder: (ctx, err, stack) => Text(
                                          initial,
                                          style: GoogleFonts.poppins(
                                            fontSize: avatarIconSize * 0.65,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.navyDark,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      initial,
                                      style: GoogleFonts.poppins(
                                        fontSize: avatarIconSize * 0.65,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.navyDark,
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.navyDark,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_user_rounded,
                                color: AppColors.goldPrimary,
                                size: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Name & Station / Designation Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              auth.displayName.isNotEmpty
                                  ? auth.displayName
                                  : 'Officer',
                              style: GoogleFonts.poppins(
                                fontSize: nameFontSize,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (auth.stationName.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.15)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.location_on_rounded,
                                          size: 10,
                                          color: AppColors.goldLight,
                                        ),
                                        const SizedBox(width: 3),
                                        Flexible(
                                          child: Text(
                                            auth.stationName.toUpperCase(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.4,
                                              color: Colors.white
                                                  .withValues(alpha: 0.9),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (auth.designation.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldPrimary
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.goldPrimary
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Text(
                                      auth.designation.toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.goldLight,
                                        letterSpacing: 0.4,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        TranslationHelper.translate(context, 'View Profile'),
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: AppColors.goldPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.goldPrimary,
                        size: 15,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet() {
    final activeLang = context.read<SettingsProvider>().locale.languageCode;
    final langs = [
      ('English', 'Nagaland, Arunachal Pradesh, Meghalaya', 'en'),
      (
        'Hindi (हिंदी)',
        'Uttar Pradesh, Bihar, Madhya Pradesh, Rajasthan, Haryana, Himachal, Jharkhand, Chhattisgarh, Uttarakhand',
        'hi'
      ),
      ('Marathi (मराठी)', 'Maharashtra', 'mr'),
      ('Gujarati (ગુજરાતી)', 'Gujarat', 'gu'),
      ('Bengali (বাংলা)', 'West Bengal, Tripura', 'bn'),
      ('Telugu (తెలుగు)', 'Andhra Pradesh, Telangana', 'te'),
      ('Tamil (தமிழ்)', 'Tamil Nadu, Puducherry', 'ta'),
      ('Kannada (ಕನ್ನಡ)', 'Karnataka', 'kn'),
      ('Malayalam (മലയാളം)', 'Kerala, Lakshadweep', 'ml'),
      ('Punjabi (ਪੰਜਾਬੀ)', 'Punjab', 'pa'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.infoBlue.withValues(alpha: 0.12),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.language_rounded,
                      color: AppColors.infoBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  TranslationHelper.translate(context, 'Select Language'),
                  style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark),
                ),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: langs.length,
                itemBuilder: (ctx, i) {
                  final l = langs[i];
                  final isSelected = activeLang == l.$3;
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 2),
                      title: Text(
                        l.$1,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.infoBlue
                              : AppColors.navyDark,
                        ),
                      ),
                      subtitle: Text(
                        l.$2,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.lightSubText,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.infoBlue, size: 22)
                          : const Icon(Icons.chevron_right_rounded,
                              color: AppColors.goldPrimary, size: 22),
                      onTap: () {
                        context.read<SettingsProvider>().setLanguage(l.$3);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            'Language set to ${l.$1}',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: AppColors.infoBlue,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ));
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStationSwitcher(BuildContext context, AuthProvider auth) {
    final firestore = FirestoreService();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StationSwitcherSheet(
        firestore: firestore,
        auth: auth,
      ),
    );
  }

  Widget _buildClassificationDrawer(bool isWide) {
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive drawer width: 85% of screen or 280, whichever is smaller
    final drawerWidth = screenWidth < 330 ? screenWidth * 0.85 : 280.0;
    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.white,
      child: SafeArea(
        top: false, // header handles its own top padding
        child: _buildProfileMenuContent(
            auth, l10n), // WEB FIX: reuse same menu for drawer + web sidebar
      ),
    );
  }

  Widget _buildWebProfileSidebar(AuthProvider auth, AppLocalizations l10n) {
    // WEB FIX: persistent profile menu sidebar on wide web
    return SizedBox(
      // WEB FIX: fixed sidebar width to match Drawer width
      width: 280, // WEB FIX: match drawer width
      child: Material(
        // WEB FIX: ensure proper ink + theme on web
        color: Colors.white, // WEB FIX: keep same drawer background
        child: _buildProfileMenuContent(
            auth, l10n), // WEB FIX: exact same menu as Android drawer
      ),
    );
  }

  Widget _buildProfileMenuContent(AuthProvider auth, AppLocalizations l10n) {
    // WEB FIX: shared drawer/sidebar content for parity
    // RESPONSIVE FIX: use LayoutBuilder to adapt to available space
    return LayoutBuilder(
      builder: (context, constraints) {
        final settings = context.watch<SettingsProvider>();
        final lang = settings.locale.languageCode;
        final availableHeight = constraints.maxHeight;
        // Scale header: use ~28% of space but clamp between 130-180
        final headerHeight = (availableHeight * 0.28).clamp(130.0, 180.0);
        return Column(
          children: [
            _buildDrawerHeader(auth, l10n, headerHeight: headerHeight),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                physics: const BouncingScrollPhysics(),
                children: [
                  // ── ROLE-BASED UNIFIED ADMIN PANEL ──
                  if (PoliceHierarchyHelper.hasAdminAuthority(
                      auth.designation, auth.roleId)) ...[
                    _drawerItem(
                      Icons.admin_panel_settings_rounded,
                      MenuLocalizations.get(lang, 'adminPanel'),
                      // Like the other items: the menu stays open, so Back
                      // returns to it.
                      () => Navigator.push(
                        context,
                        AppTheme.fadeSlideRoute(page: const AdminPanelScreen()),
                      ),
                    ),
                  ],
                  if (PoliceHierarchyHelper.canSendAlerts(
                          auth.designation, auth.roleId) ||
                      PoliceHierarchyHelper.canSendReminders(
                          auth.designation, auth.roleId)) ...[
                    _drawerItem(
                      Icons.campaign_rounded,
                      PoliceHierarchyHelper.isStateSuperAdmin(
                              auth.designation, auth.roleId)
                          ? MenuLocalizations.get(lang, 'sendAlertsState')
                          : (PoliceHierarchyHelper.isDistrictAdmin(
                                  auth.designation, auth.roleId)
                              ? MenuLocalizations.get(
                                  lang, 'sendAlertsDistrict')
                              : MenuLocalizations.get(lang, 'sendReminderIO')),
                      () => SendBroadcastAlertDialog.show(context),
                    ),
                    const Divider(height: 1),
                  ],
                  // ── Switch Policestation (senior officers only) ──
                  if (SeniorOfficerRoles.canSwitchLocation(
                      auth.designation)) ...[
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -1),
                        leading: Icon(
                          Icons.swap_horiz_rounded,
                          size: 20,
                          color: auth.isViewingOtherStation
                              ? AppColors.goldPrimary
                              : AppColors.lightText,
                        ),
                        title: Text(
                          MenuLocalizations.get(lang, 'switchStation'),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: auth.isViewingOtherStation
                                ? AppColors.goldPrimary
                                : AppColors.lightText,
                          ),
                        ),
                        subtitle: Text(
                          auth.isViewingOtherStation
                              ? 'Viewing: ${auth.stationName}'
                              : auth.stationName,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: auth.isViewingOtherStation
                                ? AppColors.goldPrimary.withValues(alpha: 0.8)
                                : AppColors.lightSubText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: auth.isViewingOtherStation
                            ? GestureDetector(
                                onTap: () {
                                  auth.resetToHomeStation();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.dangerRed
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Text(
                                    MenuLocalizations.get(lang, 'reset'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dangerRed,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                        onTap: () => _showStationSwitcher(context, auth),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  if (SeniorOfficerRoles.canSwitchLocation(auth.designation) ||
                      auth.isSupervisor ||
                      auth.isAdmin) ...[
                    _drawerItem(
                      Icons.analytics_rounded,
                      MenuLocalizations.get(lang, 'crimeAnalytics'),
                      () => Navigator.push(
                        context,
                        AppTheme.fadeSlideRoute(
                          page: const AnalyticsPerformanceScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  if (TransferRequestRoles.canApproveTransfers(
                      auth.designation)) ...[
                    _drawerItem(
                      Icons.pending_actions_rounded,
                      TransferRequestRoles.isPiOrApi(auth.designation)
                          ? MenuLocalizations.get(lang, 'pendingTransfers')
                          : MenuLocalizations.get(lang, 'pendingPiTransfers'),
                      () => Navigator.push(
                        context,
                        AppTheme.fadeSlideRoute(
                          page: const PendingTransfersScreen(),
                        ),
                      ),
                    ),
                  ],
                  if (TransferRequestRoles.isPiOrApi(auth.designation)) ...[
                    _drawerItem(
                      Icons.dashboard_customize_rounded,
                      MenuLocalizations.get(lang, 'accessGrants'),
                      () => Navigator.push(
                        context,
                        AppTheme.fadeSlideRoute(
                          page: const StationAccessGrantsScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  if (TransferRequestRoles.canAssignOfficers(auth.designation))
                    _drawerItem(
                      Icons.person_add_rounded,
                      MenuLocalizations.get(lang, 'assignOfficer'),
                      () => Navigator.push(
                        context,
                        AppTheme.fadeSlideRoute(
                            page: const AssignOfficerScreen()),
                      ),
                    ),
                  if (TransferRequestRoles.canAssignOfficers(auth.designation))
                    const Divider(height: 1),
                  _drawerItem(
                    Icons.folder_shared_outlined,
                    MenuLocalizations.get(lang, 'myCases'),
                    () => Navigator.push(
                      context,
                      AppTheme.fadeSlideRoute(page: const MyCasesScreen()),
                    ),
                  ),
                  const Divider(height: 1),
                  _drawerItem(
                    Icons.lock_person_rounded,
                    l10n.loginSecurity,
                    () => Navigator.push(
                      context,
                      AppTheme.fadeSlideRoute(
                          page: const LoginSecurityScreen()),
                    ),
                  ),
                  _drawerItem(
                    Icons.settings_rounded,
                    l10n.appSettings,
                    () => Navigator.push(
                      context,
                      AppTheme.fadeSlideRoute(page: const AppSettingsScreen()),
                    ),
                  ),
                  _drawerItem(
                    Icons.language_rounded,
                    'Language / भाषा',
                    () => _showLanguageSheet(),
                  ),
                  const Divider(height: 1),
                  _drawerItem(
                    Icons.feedback_rounded,
                    l10n.feedback,
                    () => Navigator.push(
                      context,
                      AppTheme.fadeSlideRoute(page: const FeedbackFormScreen()),
                    ),
                  ),
                  _drawerItem(
                    Icons.help_rounded,
                    l10n.helpSupport,
                    () => Navigator.push(
                      context,
                      AppTheme.fadeSlideRoute(page: const HelpSupportScreen()),
                    ),
                  ),
                  _drawerItem(
                    Icons.info_rounded,
                    l10n.aboutApp,
                    () => Navigator.push(
                      context,
                      AppTheme.fadeSlideRoute(page: const AboutAppScreen()),
                    ),
                  ),
                  const Divider(height: 1),
                  _drawerItem(
                    Icons.logout_rounded,
                    l10n.logout,
                    () async {
                      // Ask first; nothing happens on Cancel.
                      if (!await confirmLogout(context, label: l10n.logout) ||
                          !context.mounted) {
                        return;
                      }
                      context
                          .read<SettingsProvider>()
                          .setSkipBiometricAutoTrigger(
                              true); // keep same logout flow
                      auth.logout(); // keep same logout logic
                    },
                    color: AppColors.dangerRed,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    final c = color ?? AppColors.lightText;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(
            vertical: -1), // RESPONSIVE FIX: tighter spacing for small screens
        leading: Icon(icon, size: 20, color: c),
        title: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w500, color: c)),
        onTap: onTap, // Removed Navigator.pop to keep drawer open (Persistence)
      ),
    );
  }

  Widget _buildBottomNavBar(AuthProvider auth, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5)),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, l10n.home, 0),
              _navItem(Icons.gps_fixed_rounded, l10n.wanted, 1),
              GestureDetector(
                onTap: () => _onNavTap(2),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.navyMid.withValues(alpha: 0.5),
                          blurRadius: 14,
                          spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 28),
                ),
              ),
              _navItem(Icons.folder_rounded, l10n.view, 3),
              _navItem(Icons.calendar_month_rounded, l10n.calendar, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    const activeColor = AppColors.navyMid;
    const inactiveColor = AppColors.lightSubText;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? activeColor : inactiveColor, size: 24),
            const SizedBox(height: 3),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? activeColor : inactiveColor)),
          ],
        ),
      ),
    );
  }
}

// ── HOME TAB ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final bool isDark;
  final AuthProvider auth;
  final VoidCallback? onViewAll;
  const _HomeTab({required this.isDark, required this.auth, this.onViewAll});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final FirestoreService _firestore = FirestoreService();
  List<ModuleRecord> _recentRecords = [];
  StreamSubscription? _recentSub;

  Map<String, dynamic> _mapRecordToCaseMap(ModuleRecord r) {
    Color iconColor;
    IconData icon;

    switch (r.moduleKey) {
      case 'form_1_5':
        iconColor = const Color(0xFFE91E63);
        icon = Icons.description_rounded;
        break;
      case 'form_6':
        iconColor = const Color(0xFF9C27B0);
        icon = Icons.assignment_rounded;
        break;
      case 'nc':
        iconColor = const Color(0xFF673AB7);
        icon = Icons.security_rounded;
        break;
      case 'preventive':
        iconColor = const Color(0xFF3F51B5);
        icon = Icons.shield_rounded;
        break;
      case 'ad':
        iconColor = const Color(0xFF2196F3);
        icon = Icons.account_balance_rounded;
        break;
      case 'missing':
        iconColor = const Color(0xFF03A9F4);
        icon = Icons.person_search_rounded;
        break;
      case 'kidnapping':
        iconColor = const Color(0xFF00BCD4);
        icon = Icons.warning_rounded;
        break;
      case 'theft':
        iconColor = const Color(0xFF009688);
        icon = Icons.no_encryption_rounded;
        break;
      case 'sand_theft':
        iconColor = const Color(0xFF4CAF50);
        icon = Icons.terrain_rounded;
        break;
      case 'hurt':
        iconColor = const Color(0xFF8BC34A);
        icon = Icons.local_hospital_rounded;
        break;
      case 'pocso':
        iconColor = const Color(0xFFCDDC39);
        icon = Icons.child_care_rounded;
        break;
      case 'passport':
        iconColor = const Color(0xFFFFEB3B);
        icon = Icons.badge_rounded;
        break;
      default:
        iconColor = AppColors.goldPrimary;
        icon = Icons.folder_rounded;
    }

    Color statusColor;
    switch (r.status.toLowerCase()) {
      case 'open':
        statusColor = AppColors.warningOrange;
        break;
      case 'active':
        statusColor = AppColors.infoBlue;
        break;
      case 'resolved':
        statusColor = AppColors.successGreen;
        break;
      default:
        statusColor = AppColors.infoBlue;
    }

    return {
      'title': r.title,
      'id': r.caseNumber,
      'type': r.moduleKey,
      'date': DateFormat('dd MMM yyyy').format(r.incidentDate),
      'status': r.status,
      'statusColor': statusColor,
      'iconColor': iconColor.toARGB32(),
      'icon': icon,
      'record': r,
    };
  }

  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  final SearchFilters _searchFilters = SearchFilters();
  DateTime? _explicitSearchDate;

  /// Memoizes live search across rebuilds triggered by unrelated widgets (e.g. news).
  int? _searchRecordsFingerprint;
  List<SearchResult>? _cachedLiveSearchResults;

  // Current news slide; only the dots listen to it, so the carousel's
  // auto-play does not rebuild the whole dashboard every few seconds
  final ValueNotifier<int> _carouselPage = ValueNotifier<int>(0);
  final CarouselSliderController _carouselCtrl = CarouselSliderController();

  // Tracks the station the recent-cases stream is currently scoped to.
  // The parent passes the SAME AuthProvider instance on every rebuild, so
  // comparing oldWidget.auth.stationName to widget.auth.stationName is
  // always equal. We instead compare against this snapshot to detect a
  // real station switch and re-subscribe so dashboard data is strictly
  // for the currently selected station only.
  String? _subscribedStationName;
  List<Map<String, dynamic>> _backendCategories = [];

  @override
  void initState() {
    super.initState();
    // DashboardScreen already refreshed stale caches for this user/station.
    _loadDashboardTools();
    _loadBackendCategories();
    // MPDA detention end reminders of this station (bell badge + list)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final notifications =
            Provider.of<NotificationProvider>(context, listen: false);
        notifications.loadDetentionReminders();
        notifications.loadRtiReminders();
      } on ProviderNotFoundException {
        // Screen used without the notification provider (tests)
      }
    });
  }

  /// Database tiles (MPDA, History Sheeter ...) come from this list, so a
  /// failed or dropped request is retried instead of leaving them out.
  Future<void> _loadDashboardTools() async {
    try {
      final toolsData = await CaseService().fetchDashboardTools();
      if (toolsData.isNotEmpty) {
        final dynamicTools = toolsData
            .map((t) => ServiceData.fromJson(t))
            .where((t) => t.isActive)
            .toList();
        if (dynamicTools.isNotEmpty) {
          for (final tool in dynamicTools) {
            if (tool.assetPath != null && tool.assetPath!.endsWith('.svg')) {
              CategoryIconHelper.registerSvgPath(tool.label, tool.assetPath!);
              if (tool.moduleKey != null) {
                CategoryIconHelper.registerSvgPath(
                    tool.moduleKey!, tool.assetPath!);
              }
              if (tool.categoryCode != null) {
                CategoryIconHelper.registerSvgPath(
                    tool.categoryCode!, tool.assetPath!);
              }
            }
          }
          if (mounted) {
            setState(() {
              ServiceData.dashboardTools = dynamicTools;
            });
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[_HomeTab] _loadDashboardTools error: $e');
      }
    }
  }

  Future<void> _loadBackendCategories({int attempt = 1}) async {
    const maxAttempts = 4;
    try {
      await _loadDashboardTools();
      final cats = await CaseService().fetchAllCategories();
      if (!mounted) return;
      if (cats.isNotEmpty) {
        setState(() {
          _backendCategories = cats;
        });
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[_HomeTab] _loadBackendCategories error: $e');
      }
    }
    if (attempt < maxAttempts && mounted) {
      await Future.delayed(Duration(seconds: attempt * 2));
      if (mounted) await _loadBackendCategories(attempt: attempt + 1);
    }
  }

  @override
  void didUpdateWidget(covariant _HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureRecentStreamForCurrentStation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureRecentStreamForCurrentStation();
  }

  void _ensureRecentStreamForCurrentStation() {
    final activeStation = widget.auth.stationName;
    if (_subscribedStationName == activeStation) return;
    _clearSearchStateOnStationSwitch();
    _subscribedStationName = activeStation;
    _ensureFreshCaches(widget.auth);
    _initRecentStream();
  }

  /// Resets dashboard search UI when the active station changes.
  void _clearSearchStateOnStationSwitch() {
    _debounce?.cancel();
    final hadSearchState = _searchQuery.isNotEmpty ||
        _explicitSearchDate != null ||
        _searchCtrl.text.isNotEmpty;
    if (!hadSearchState) return;

    _searchCtrl.clear();
    _invalidateSearchCache();
    if (mounted) {
      setState(() {
        _searchQuery = '';
        _explicitSearchDate = null;
      });
    }
  }

  void _invalidateSearchCache() {
    _searchRecordsFingerprint = null;
    _cachedLiveSearchResults = null;
  }

  bool get _hasActiveSearch =>
      _searchQuery.isNotEmpty || _explicitSearchDate != null;

  String _moduleDisplayLabel(ModuleRecord record) {
    final name = record.firestoreCategoryDisplayName.trim();
    if (name.isNotEmpty) return name;
    return record.moduleKey.replaceAll('_', ' ');
  }

  String _statusBadgeLabel(String status) {
    final s = status.trim().toLowerCase();
    if (s == 'closed' || s == 'resolved') return 'Disposed';
    if (s == 'open' || s == 'active' || s == 'pending') return 'Pending';
    return status.isEmpty ? 'Active' : status;
  }

  Color _statusBadgeColor(String badgeLabel) {
    switch (badgeLabel.toLowerCase()) {
      case 'disposed':
        return AppColors.successGreen;
      case 'pending':
        return AppColors.warningOrange;
      default:
        return AppColors.infoBlue;
    }
  }

  List<ModuleRecord> _providerRecords<T>(
    BuildContext context, {
    required List<ModuleRecord> Function(T provider) select,
    required bool listen,
  }) {
    if (listen) {
      return select(context.watch<T>());
    }
    return select(context.read<T>());
  }

  List<(String, String, List<ModuleRecord>)> _moduleSourcesFrom(
    BuildContext context, {
    required bool listen,
  }) {
    List<ModuleRecord> rec<T>(
      List<ModuleRecord> Function(T provider) select,
    ) =>
        _providerRecords(context, select: select, listen: listen);

    return [
      ('Form I-V', 'form_1_5', rec<FormIVProvider>((p) => p.records)),
      ('Form VI', 'form_6', rec<FormVIProvider>((p) => p.records)),
      ('NC', 'nc', rec<NcProvider>((p) => p.records)),
      ('Preventive', 'preventive', rec<PreventiveProvider>((p) => p.records)),
      ('AD', 'ad', rec<AdProvider>((p) => p.records)),
      ('Missing', 'missing', rec<MissingProvider>((p) => p.records)),
      (
        'Kidnapping/Missing',
        'kidnapping',
        rec<KidnappingProvider>((p) => p.records)
      ),
      ('Theft', 'theft', rec<TheftProvider>((p) => p.records)),
      ('Sand Theft', 'sand_theft', rec<SandTheftProvider>((p) => p.records)),
      ('Hurt', 'hurt', rec<HurtProvider>((p) => p.records)),
      ('POCSO', 'pocso', rec<PocsoProvider>((p) => p.records)),
      ('Passport/PVR', 'passport', rec<PassportProvider>((p) => p.records)),
      ('Licence', 'licence', rec<LicenceProvider>((p) => p.records)),
      ('Monthly', 'monthly', rec<MonthlyProvider>((p) => p.records)),
      ('Pending', 'pending', rec<PendingProvider>((p) => p.records)),
      ('Detected', 'detected', rec<DetectedProvider>((p) => p.records)),
      ('Undetected', 'undetected', rec<UndetectedProvider>((p) => p.records)),
      ('Disposal', 'disposal', rec<DisposalProvider>((p) => p.records)),
      (
        'Two/Four Wheeler Theft',
        'two_four_wheeler',
        rec<TwoFourWheelerProvider>((p) => p.records),
      ),
      ('Arrested', 'arrested', rec<ArrestedProvider>((p) => p.records)),
      (
        'Absconded',
        'absconded',
        () {
          final absRecs = rec<AbscondedProvider>((p) => p.records);
          final formIVRecs = rec<FormIVProvider>((p) => p.records);
          final combined = <String, ModuleRecord>{};
          for (final r in formIVRecs) {
            combined[r.id] = r;
          }
          for (final r in absRecs) {
            combined[r.id] = r;
          }
          return combined.values.toList();
        }(),
      ),
      (
        'Crime against Women',
        'crime_women',
        rec<CrimeWomenProvider>((p) => p.records),
      ),
      ('Juvenile', 'juvenile', rec<JuvenileProvider>((p) => p.records)),
      ('Victim', 'victim', rec<VictimProvider>((p) => p.records)),
      ('Accident', 'accident', rec<AccidentProvider>((p) => p.records)),
      ('Traffic', 'traffic', rec<TrafficProvider>((p) => p.records)),
      (
        'Application',
        'application',
        rec<ApplicationProvider>((p) => p.records)
      ),
      ('Sam Warrant', 'sam_warrant', rec<SamWarrantProvider>((p) => p.records)),
      ('Muddemal', 'muddemal', rec<MuddemalProvider>((p) => p.records)),
      ('BNSS', 'bnss', rec<BnssProvider>((p) => p.records)),
      ('NDPS', 'ndps', rec<NdpsProvider>((p) => p.records)),
      ('Gowansh', 'gowans', rec<GowansProvider>((p) => p.records)),
      ('IT Act', 'it_act', rec<ItActProvider>((p) => p.records)),
      ('MCOCA', 'mcoca', rec<McocaProvider>((p) => p.records)),
      ('UAPA', 'uapa', rec<UapaProvider>((p) => p.records)),
      ('MPDA', 'mpda', rec<MpdaProvider>((p) => p.records)),
      ('Coin', 'coin', rec<CoinProvider>((p) => p.records)),
    ];
  }

  int _moduleSourcesFingerprint(
    List<(String, String, List<ModuleRecord>)> sources,
  ) {
    return Object.hashAll(sources.map((source) {
      final records = source.$3;
      if (records.isEmpty) return Object.hash(source.$2, 0);
      var bucket = records.length;
      for (final record in records) {
        bucket = Object.hash(
          bucket,
          record.id,
          record.status,
          record.title,
          record.caseNumber,
          record.complainant,
          record.accused,
        );
      }
      return Object.hash(source.$2, bucket);
    }));
  }

  List<SearchResult> _resolveLiveSearchResults(BuildContext context) {
    final moduleSources = _moduleSourcesFrom(context, listen: true);
    final recordsFingerprint = _moduleSourcesFingerprint(moduleSources);
    final memoKey = Object.hash(
      _searchQuery,
      _explicitSearchDate?.millisecondsSinceEpoch,
      _searchFilters.activeCount,
      recordsFingerprint,
    );
    if (memoKey == _searchRecordsFingerprint &&
        _cachedLiveSearchResults != null) {
      return _cachedLiveSearchResults!;
    }

    final results = UniversalSearch.search(
      query: _searchQuery,
      moduleSources: moduleSources,
      filters: _searchFilters,
      exactDate: _explicitSearchDate,
    );
    _searchRecordsFingerprint = memoKey;
    _cachedLiveSearchResults = results;
    return results;
  }

  void _initRecentStream() {
    _recentSub?.cancel();
    _recentSub = null;
    final activeStation = widget.auth.stationName;
    if (activeStation.isEmpty) {
      if (mounted && _recentRecords.isNotEmpty) {
        setState(() => _recentRecords = []);
      }
      return;
    }
    if (mounted) setState(() => _recentRecords = []);

    _recentSub =
        _firestore.getRecentCasesStream(100, activeStation).listen((data) {
      if (!mounted) return;
      final mode = CaseVisibility.resolveFor(widget.auth);
      final filtered = CaseVisibility.filterRecords(
        data,
        uid: widget.auth.uid,
        mode: mode,
      );
      setState(() => _recentRecords = filtered.take(10).toList());
    });
  }

  @override
  void dispose() {
    _recentSub?.cancel();
    _carouselPage.dispose();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    try {
      _carouselCtrl.stopAutoPlay();
    } catch (_) {}
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppTimeouts.searchDebounce, () {
      if (!mounted) return;
      final q = value.trim();
      if (q.isEmpty && _explicitSearchDate == null) {
        setState(() {
          _searchQuery = '';
          _explicitSearchDate = null;
          _invalidateSearchCache();
        });
        return;
      }

      final parsedDate = UniversalSearch.tryParseNaturalDate(q);
      if (parsedDate != null && _explicitSearchDate == null) {
        setState(() {
          _explicitSearchDate = parsedDate;
          _searchQuery = q;
          _invalidateSearchCache();
        });
        return;
      }

      setState(() {
        _searchQuery = q;
        _invalidateSearchCache();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = context.watch<NewsProvider>();
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= Breakpoints.tablet;

    final recentCases = _recentRecords
        .where((r) => r.moduleKey != 'form_1_5')
        .map(_mapRecordToCaseMap)
        .toList();
    final top3Cases = recentCases.take(3).toList();
    final width = MediaQuery.of(context).size.width;
    final caseGridCols = width > 1200 ? 3 : (width > 800 ? 2 : 1);
    final searchResults = _hasActiveSearch
        ? _resolveLiveSearchResults(context)
        : const <SearchResult>[];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? AppSpacing.xl : AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSearchBar(),
              const SizedBox(height: AppSpacing.md),
              _buildNewsCarousel(newsProvider, isWide),
              if (_hasActiveSearch) ...[
                const SizedBox(height: AppSpacing.md),
                _buildMatchingModuleTabs(_searchQuery),
                if (searchResults.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildSearchResults(searchResults),
                ] else if (_matchingModulesCount(_searchQuery) == 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildNoResults(),
                ],
              ],
            ]),
          ),
        ),
        if (!_hasActiveSearch) ...[
          SliverPadding(
            padding: EdgeInsets.symmetric(
                horizontal: isWide ? AppSpacing.xl : AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: _buildThreePartClassification(isWide),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? AppSpacing.xl : AppSpacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _sectionHeader('Recent Cases', 'Latest record'),
                  const SizedBox(height: AppSpacing.md),
                  if (top3Cases.isEmpty) _buildNoRecentCases(),
                ],
              ),
            ),
          ),
          if (top3Cases.isNotEmpty) ...[
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? AppSpacing.xl : AppSpacing.lg,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: caseGridCols,
                  mainAxisExtent: 128,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _caseCard(top3Cases[i]),
                  childCount: top3Cases.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: () => _showTop10CasesModal(
                      context,
                      recentCases.take(10).toList(),
                    ),
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.navyDark,
                    ),
                    label: Text(
                      'See More',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 10),
                      side: const BorderSide(
                          color: AppColors.navyDark, width: 1.5),
                      shape: const StadiumBorder(),
                      backgroundColor: Colors.white,
                      elevation: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildNewsCarousel(NewsProvider news, bool isWide) {
    return Column(
      children: [
        RepaintBoundary(
          child: CarouselSlider.builder(
            carouselController: _carouselCtrl,
            itemCount: news.items.length,
            options: CarouselOptions(
              height: 160,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: AppTimeouts.carouselInterval,
              autoPlayAnimationDuration: const Duration(milliseconds: 600),
              autoPlayCurve: Curves.easeInOut,
              onPageChanged: (index, reason) => _carouselPage.value = index,
            ),
            itemBuilder: (context, i, _) {
              final item = news.items[i];
              final color = Color(item.iconColorHex);
              return _newsCard(item, color);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ValueListenableBuilder<int>(
          valueListenable: _carouselPage,
          builder: (context, page, _) => AnimatedSmoothIndicator(
            activeIndex: page,
            count: news.items.length,
            effect: ExpandingDotsEffect(
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: AppColors.navyMid,
              dotColor: AppColors.navyMid.withValues(alpha: 0.25),
            ),
          ),
        ),
      ],
    );
  }

  Widget _newsCard(NewsItem item, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(item.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(TranslationHelper.translate(context, item.tag),
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
                const SizedBox(height: 6),
                Text(TranslationHelper.translate(context, item.title),
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(TranslationHelper.translate(context, item.description),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final FocusNode _searchFocusNode = FocusNode();

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocusNode,
        autofocus: false,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        enableSuggestions: true,
        autocorrect: true,
        onChanged: _onSearchChanged,
        style: GoogleFonts.poppins(color: AppColors.lightText, fontSize: 14),
        decoration: InputDecoration(
          hintText: TranslationHelper.translate(context,
              'Search cases or type module (e.g. Murder, Theft, Missing)...'),
          hintStyle:
              GoogleFonts.poppins(color: AppColors.lightSubText, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.navyMid, size: 22),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  color: AppColors.lightSubText,
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _explicitSearchDate = null);
                    _onSearchChanged('');
                  },
                ),
              IconButton(
                icon: const Icon(Icons.mic_rounded, color: AppColors.navyMid),
                tooltip: 'Speak / Voice Search',
                onPressed: () async {
                  final spoken = await VoiceSearchDialog.show(context);
                  if (spoken != null && spoken.trim().isNotEmpty) {
                    var cleanSpoken = spoken.trim();
                    while (cleanSpoken.endsWith('.') ||
                        cleanSpoken.endsWith(',') ||
                        cleanSpoken.endsWith('?') ||
                        cleanSpoken.endsWith('!')) {
                      cleanSpoken = cleanSpoken
                          .substring(0, cleanSpoken.length - 1)
                          .trim();
                    }
                    if (cleanSpoken.isEmpty) return;

                    final parsedDate =
                        UniversalSearch.tryParseNaturalDate(cleanSpoken);
                    if (parsedDate != null) {
                      final formatted =
                          DateFormat('dd MMM yyyy').format(parsedDate);
                      setState(() {
                        _explicitSearchDate = parsedDate;
                        _searchQuery = formatted;
                        _searchCtrl.text = formatted;
                        _invalidateSearchCache();
                      });
                    } else {
                      _searchCtrl.text = cleanSpoken;
                      _onSearchChanged(cleanSpoken);
                    }
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.calendar_month_rounded,
                    color: _explicitSearchDate != null
                        ? AppColors.goldPrimary
                        : AppColors.navyMid),
                onPressed: () => _showSearchDatePicker(context),
                tooltip: 'Select Custom Date',
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 16),
        ),
      ),
    );
  }

  static const List<Classification> _extraSearchClassifications = [
    Classification('Prohibition', 'admin_panel', 'mpda'),
    Classification('Gambling', 'monetization_on', 'coin'),
    Classification('RTI', 'description', 'application'),
    Classification('M.V Act', 'traffic', 'traffic'),
  ];

  List<({String title, String subtext, IconData icon, VoidCallback onTap})>
      _matchingMenuShortcuts(String q) {
    final cleanQ = q.toLowerCase().trim();
    if (cleanQ.isEmpty) return [];

    final shortcuts = <({
      String title,
      String subtext,
      List<String> keywords,
      IconData icon,
      VoidCallback onTap
    })>[
      (
        title: 'Total Cases',
        subtext: 'Station Cases (All)',
        keywords: [
          'total cases',
          'total case',
          'all cases',
          'all case',
          'total',
          'station cases'
        ],
        icon: Icons.folder_open_rounded,
        onTap: () => Navigator.push(
            context,
            AppTheme.fadeSlideRoute(
                page: const MyCasesScreen(initialTab: MyCasesTab.total))),
      ),
      (
        title: 'Pending Cases',
        subtext: 'Pending Investigation',
        keywords: ['pending cases', 'pending case', 'pending investigation'],
        icon: Icons.hourglass_top_rounded,
        onTap: () => Navigator.push(
            context,
            AppTheme.fadeSlideRoute(
                page: const MyCasesScreen(initialTab: MyCasesTab.pending))),
      ),
      (
        title: 'Disposal Cases',
        subtext: 'Resolved / Disposed',
        keywords: [
          'disposal cases',
          'disposal case',
          'disposed cases',
          'disposal',
          'disposed',
          'closed cases'
        ],
        icon: Icons.task_alt_rounded,
        onTap: () => Navigator.push(
            context,
            AppTheme.fadeSlideRoute(
                page: const MyCasesScreen(initialTab: MyCasesTab.disposal))),
      ),
      (
        title: 'Pending PI Transfers',
        subtext: 'Transfers',
        keywords: [
          'pending pi transfers',
          'pending transfers',
          'transfer',
          'transfers',
          'pi transfer'
        ],
        icon: Icons.pending_actions_rounded,
        onTap: () => Navigator.push(context,
            AppTheme.fadeSlideRoute(page: const PendingTransfersScreen())),
      ),
      (
        title: 'Assign Officer',
        subtext: 'Team & IO',
        keywords: [
          'assign officer',
          'assign',
          'officer assignment',
          'add members'
        ],
        icon: Icons.person_add_rounded,
        onTap: () => Navigator.push(context,
            AppTheme.fadeSlideRoute(page: const AssignOfficerScreen())),
      ),
      (
        title: 'My Cases',
        subtext: 'Station Cases',
        keywords: ['my cases', 'assigned cases', 'station cases', 'cases tab'],
        icon: Icons.folder_shared_outlined,
        onTap: () => Navigator.push(
            context, AppTheme.fadeSlideRoute(page: const MyCasesScreen())),
      ),
      (
        title: 'Login & Security',
        subtext: 'Security & PIN',
        keywords: [
          'login & security',
          'login and security',
          'security',
          'password',
          'change password',
          'pin',
          'login'
        ],
        icon: Icons.lock_person_rounded,
        onTap: () => Navigator.push(context,
            AppTheme.fadeSlideRoute(page: const LoginSecurityScreen())),
      ),
      (
        title: 'App Settings',
        subtext: 'Settings & Theme',
        keywords: [
          'app settings',
          'settings',
          'dark mode',
          'theme',
          'language'
        ],
        icon: Icons.settings_rounded,
        onTap: () => Navigator.push(
            context, AppTheme.fadeSlideRoute(page: const AppSettingsScreen())),
      ),
      (
        title: 'Feedback',
        subtext: 'Feedback Form',
        keywords: ['feedback', 'feedback form', 'suggest', 'report issue'],
        icon: Icons.feedback_rounded,
        onTap: () => Navigator.push(
            context, AppTheme.fadeSlideRoute(page: const FeedbackFormScreen())),
      ),
      (
        title: 'Help & Support',
        subtext: 'Support & Helpline',
        keywords: [
          'help & support',
          'help and support',
          'support',
          'help',
          'helpline',
          'contact'
        ],
        icon: Icons.help_rounded,
        onTap: () => Navigator.push(
            context, AppTheme.fadeSlideRoute(page: const HelpSupportScreen())),
      ),
      (
        title: 'About App',
        subtext: 'App Info',
        keywords: ['about app', 'about', 'about pms', 'tensei tech'],
        icon: Icons.info_rounded,
        onTap: () => Navigator.push(
            context, AppTheme.fadeSlideRoute(page: const AboutAppScreen())),
      ),
      (
        title: 'Dashboard access grants',
        subtext: 'Grants',
        keywords: [
          'dashboard access grants',
          'access grants',
          'station grants',
          'grants'
        ],
        icon: Icons.dashboard_customize_rounded,
        onTap: () => Navigator.push(context,
            AppTheme.fadeSlideRoute(page: const StationAccessGrantsScreen())),
      ),
      (
        title: 'Profile',
        subtext: 'Officer Profile',
        keywords: ['profile', 'my profile', 'user profile', 'officer profile'],
        icon: Icons.account_circle_rounded,
        onTap: () => Navigator.push(
            context, AppTheme.fadeSlideRoute(page: const ProfileScreen())),
      ),
    ];

    return shortcuts
        .where((s) {
          final t = s.title.toLowerCase();
          final sub = s.subtext.toLowerCase();
          final hasKeyword =
              s.keywords.any((k) => k.contains(cleanQ) || cleanQ.contains(k));
          return t.contains(cleanQ) ||
              sub.contains(cleanQ) ||
              cleanQ.contains(t) ||
              cleanQ.contains(sub) ||
              hasKeyword;
        })
        .map((s) =>
            (title: s.title, subtext: s.subtext, icon: s.icon, onTap: s.onTap))
        .toList();
  }

  int _matchingModulesCount(String query) {
    if (query.trim().isEmpty) return 0;
    var q = query.trim().toLowerCase();
    while (q.endsWith('.') ||
        q.endsWith(',') ||
        q.endsWith('?') ||
        q.endsWith('!')) {
      q = q.substring(0, q.length - 1).trim();
    }
    if (q.isEmpty) return 0;

    final matchingFormIV = formIVCaseCategories
        .where((cat) => cat.toLowerCase().contains(q))
        .length;
    final allClasses = [...Classification.all, ..._extraSearchClassifications];
    final matchingClass = allClasses
        .where((c) => c.name.replaceAll('\n', ' ').toLowerCase().contains(q))
        .length;
    final matchingMenu = _matchingMenuShortcuts(q).length;
    return matchingFormIV + matchingClass + matchingMenu;
  }

  Widget _buildMatchingModuleTabs(String query) {
    if (query.trim().isEmpty) return const SizedBox.shrink();
    var q = query.trim().toLowerCase();
    while (q.endsWith('.') ||
        q.endsWith(',') ||
        q.endsWith('?') ||
        q.endsWith('!')) {
      q = q.substring(0, q.length - 1).trim();
    }
    if (q.isEmpty) return const SizedBox.shrink();

    final matchingFormIV = formIVCaseCategories.where((cat) {
      return cat.toLowerCase().contains(q);
    }).toList();

    final allClasses = [...Classification.all, ..._extraSearchClassifications];
    final matchingClassifications = allClasses.where((c) {
      final name = c.name.replaceAll('\n', ' ').toLowerCase();
      return name.contains(q);
    }).toList();

    final matchingMenus = _matchingMenuShortcuts(q);

    if (matchingFormIV.isEmpty &&
        matchingClassifications.isEmpty &&
        matchingMenus.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: AppColors.goldPrimary.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flash_on_rounded,
                    size: 16, color: AppColors.goldDark),
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Navigation & Modules',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              const Spacer(),
              Text(
                'Tap to open directly',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.lightSubText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final menu in matchingMenus)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: menu.onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF1E3C72).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(menu.icon, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            menu.title,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.goldPrimary.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              menu.subtext,
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              for (final cat in matchingFormIV)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () {
                      CategoryNavigationHelper.handleDashboardCategoryTap(
                        context: context,
                        categoryName: cat,
                        moduleKey: 'form_1_5',
                        readOnly: false,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF2193B0).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.article_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            cat,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Form I-V',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              for (final item in matchingClassifications)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => _openClassificationItem(context, item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.navyDark,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navyDark.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _classIcon(item.iconName) is IconData
                                ? _classIcon(item.iconName) as IconData
                                : Icons.folder_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            TranslationHelper.translate(
                                context, item.name.replaceAll('\n', ' ')),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSearchDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navyMid,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.navyDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = DateFormat('dd MMM yyyy').format(picked);
      setState(() {
        _explicitSearchDate = picked;
        _searchCtrl.text = formatted;
      });
      _onSearchChanged(formatted);
    }
  }

  Widget _buildSearchResults(List<SearchResult> searchResults) {
    final grouped = UniversalSearch.groupByModule(searchResults);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(
                  '${searchResults.length} result${searchResults.length == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark)),
              const SizedBox(width: 6),
              Text('for "$_searchQuery"',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.lightSubText)),
            ],
          ),
        ),
        ...grouped.entries.map((entry) {
          final moduleKey = entry.key;
          final items = entry.value;
          return _SearchModuleGroup(
            isDark: widget.isDark,
            moduleLabel: items.first.record.firestoreCategoryDisplayName,
            moduleKey: moduleKey,
            results: items,
          );
        }),
      ],
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.lightSubText),
          const SizedBox(height: 8),
          Text('No results found for "$_searchQuery"',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.lightSubText)),
        ],
      ),
    );
  }

  dynamic _classIcon(String name) {
    switch (name) {
      case 'calendar_month':
        return Icons.calendar_month_rounded;
      case 'pending_actions':
        return FontAwesomeIcons.solidClock;
      case 'search':
        return Icons.search_rounded;
      case 'visibility_off':
        return Icons.visibility_off_rounded;
      case 'delete_forever':
        return Icons.delete_forever_rounded;
      case 'article':
        return Icons.article_rounded;
      case 'gavel':
        return Icons.gavel_rounded;
      case 'handcuffs':
        return Icons.link_rounded;
      case 'directions_run':
        return Icons.directions_run_rounded;
      case 'child_care':
        return Icons.child_care_rounded;
      case 'healing':
        return Icons.healing_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'woman':
        return Icons.woman_rounded;
      case 'description':
        return Icons.description_rounded;
      case 'badge':
        return Icons.badge_rounded;
      case 'assignment':
        return Icons.assignment_rounded;
      case 'traffic':
        return Icons.traffic_rounded;
      case 'inventory':
        return Icons.inventory_2_rounded;
      case 'two_wheeler':
        return Icons.two_wheeler_rounded;
      case 'admin_panel':
        return Icons.admin_panel_settings_rounded;
      case 'folder_special':
        return Icons.folder_special_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  String _iconNameForStandalone(String? name, String? code) {
    final n = (name ?? '').toLowerCase();
    final c = (code ?? '').toLowerCase();
    if (n.contains('history') || c.contains('history')) {
      return 'assignment';
    }
    if (n.contains('mpda') || c.contains('mpda')) {
      return 'admin_panel';
    }
    if (n.contains('rti') || c.contains('rti')) {
      return 'description';
    }
    return 'folder_special';
  }

  Widget _buildThreePartClassification(bool isWide) {
    final width = MediaQuery.of(context).size.width;

    int cols = 4;
    if (width > 1200) {
      cols = 10;
    } else if (width > 900) {
      cols = 8;
    } else if (width > 600) {
      cols = 6;
    }

    final itemsPerGroup = cols * 3;
    // Standalone categories from /api/categories/ (active rows with group == null && parent_category == null)
    final List<Map<String, dynamic>> standaloneBackendRows =
        _backendCategories.where((c) {
      final isActive = c['is_active'] != false;
      final isStandalone = c['group'] == null && c['parent_category'] == null;
      return isActive && isStandalone;
    }).toList();

    // Dashboard-only ordering/labels tweaks (do not modify global constants):
    // - Add Prohibition + Gambling tiles (Part 6 categories)
    // - Display "Traffic" as "M.V Act" (dashboard only)
    // - Show RTI next to Sam/Warrant (dashboard only)
    final List<Classification> cases = [
      ...Classification.casesGroup,
      const Classification('Prohibition', 'admin_panel', 'prohibition'),
      const Classification('Gambling', 'monetization_on', 'gambling'),
    ];

    final List<Classification> services = [
      for (final c in Classification.servicesGroup)
        if (c.name == 'Traffic')
          const Classification('M.V Act', 'traffic', 'traffic')
        else if (c.name == 'Application')
          () {
            final rtiRow = standaloneBackendRows.firstWhere(
              (r) =>
                  (r['category_name']?.toString() ?? '').toUpperCase() ==
                      'RTI' ||
                  (r['category_code']?.toString() ?? '').toUpperCase() ==
                      'STAND_RTI',
              orElse: () => <String, dynamic>{},
            );
            return Classification(
              'RTI',
              'description',
              'application',
              categoryId: rtiRow['category_id'] ?? rtiRow['id'],
              categoryCode: rtiRow['category_code']?.toString(),
            );
          }()
        else
          c,
    ];

    // Move RTI so it sits next to Sam/Warrant (keep all other ordering intact).
    final rtiIndex = services.indexWhere((c) => c.name == 'RTI');
    final samIndex = services.indexWhere((c) => c.name == 'Sam/Warrant');
    if (rtiIndex != -1 && samIndex != -1 && rtiIndex != samIndex + 1) {
      final rti = services.removeAt(rtiIndex);
      final insertAt = samIndex + 1;
      services.insert(insertAt, rti);
    }

    // Labels already shown by the fixed tiles above. Backend standalone rows
    // that match one of these (e.g. "A.D." vs "A.D", "Coin" vs "COIN",
    // "Missing" inside "Kidnapping/Missing", "Sec 156(3)/175(3)(BNSS)" vs
    // "CRPC 156(3)/BNSS 175(3)") must not be added a second time.
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    String digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
    final shownLabels = [
      ...Classification.statsGroup.map((c) => c.name),
      ...cases.map((c) => c.name),
      ...services.map((c) => c.name),
      ...ServiceData.dashboardTools.map((t) => t.label),
      PassportLicenceScreen.licenceLabel, // a tab inside Passport/PVR/Licence
      'DAR', 'IRAD', // tabs inside DAR/IRAD
      'NAFIS', // a tab inside NAFIS/Fingerprint
    ];
    final shownNorm = shownLabels.map(norm).toList();
    final shownDigits = shownLabels.map(digits).toList();
    bool alreadyShown(String name) {
      final n = norm(name);
      final d = digits(name);
      for (var i = 0; i < shownNorm.length; i++) {
        if (n == shownNorm[i]) return true;
        if (n.length >= 4 && shownNorm[i].contains(n)) return true;
        if (d.length >= 4 && d == shownDigits[i]) return true;
      }
      return false;
    }

    // Build standalone category tiles from /api/categories/ (active rows)
    final List<Classification> standaloneTiles = [];
    for (final cat in standaloneBackendRows) {
      final name = cat['category_name']?.toString() ?? '';
      final code = cat['category_code']?.toString();
      final id = cat['category_id'] ?? cat['id'];

      // RTI is integrated into the services RTI tile above
      if (name.toUpperCase() == 'RTI' ||
          (code != null && code.toUpperCase() == 'STAND_RTI')) {
        continue;
      }

      // Already represented by a fixed dashboard tile
      if (alreadyShown(name)) continue;

      standaloneTiles.add(
        Classification(
          name,
          _iconNameForStandalone(name, code),
          (code ?? 'standalone').toLowerCase(),
          categoryId: id,
          categoryCode: code,
        ),
      );
    }

    // Place every case tile by its database category: tiles whose category is
    // in "1 to 5" (group 1) sit with the case tiles, tiles whose category is in
    // Part 6 (group 2) get their own section in Part 6 order, everything else
    // (RTI, Sam/Warrant, Muddemal, hubs ...) stays with the services.
    String tileLabel(Classification c) =>
        c.name.split(RegExp(r'\s+')).join(' ');

    int? groupOf(Classification c) {
      final twin = CategoryNavigationHelper.findGroupTwin(
          _backendCategories, tileLabel(c));
      if (twin == null) return null;
      final g = twin['group'] ?? twin['group_id'];
      return g is Map ? int.tryParse('${g['group_id']}') : int.tryParse('$g');
    }

    int part6Order(Classification c) {
      final twin = CategoryNavigationHelper.findGroupTwin(
          _backendCategories, tileLabel(c));
      return int.tryParse('${twin?['display_order']}') ?? 1 << 30;
    }

    final caseSection = <Classification>[];
    final part6Section = <Classification>[];
    final serviceSection = <Classification>[];
    for (final c in cases) {
      (groupOf(c) == 2 ? part6Section : caseSection).add(c);
    }
    for (final c in services) {
      final g = groupOf(c);
      if (g == 2) {
        part6Section.add(c);
      } else if (g == 1) {
        caseSection.add(c);
      } else {
        serviceSection.add(c);
      }
    }
    part6Section.sort((a, b) => part6Order(a).compareTo(part6Order(b)));
    serviceSection.addAll(standaloneTiles);

    final sections = <List<Classification>>[
      Classification.statsGroup,
      caseSection,
      part6Section,
      serviceSection,
      [
        for (final tool in ServiceData.dashboardTools)
          Classification(
            tool.label,
            tool.assetPath ?? 'service_tool',
            tool.moduleKey ?? 'service_tool',
            categoryCode: tool.categoryCode,
            categoryId: tool.categoryId,
          ),
      ],
    ];
    // Sections keep their order but flow on continuously, so no row is left
    // half empty; the grid is split into blocks of three rows.
    final displayItems = [for (final section in sections) ...section];
    final List<List<Classification>> groups = [];
    for (int i = 0; i < displayItems.length; i += itemsPerGroup) {
      groups.add(displayItems.sublist(
          i, (i + itemsPerGroup).clamp(0, displayItems.length)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.lightBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: List.generate(groups.length, (gi) {
                final group = groups[gi];
                final isLast = gi == groups.length - 1;
                return Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        childAspectRatio: 0.82,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: group.length,
                      itemBuilder: (context, i) {
                        return _buildClassificationGridItem(context, group[i]);
                      },
                    ),
                    if (!isLast) ...[
                      const SizedBox(height: 10),
                      const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.lightBorder),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  void _openClassificationItem(BuildContext context, Classification item) {
    final label = item.name.replaceAll('\n', ' ');
    if (label.toUpperCase() == 'ITSSO') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const ItssoHubScreen(stationName: 'All Stations'),
        ),
      );
      return;
    }
    if (label.toUpperCase() == DarIradScreen.title) {
      // Two tabs: DAR and IRAD
      final auth = context.read<AuthProvider>();
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: DarIradScreen(stationName: auth.stationName),
        ),
      );
      return;
    }
    if (label.toUpperCase() == 'DAR' || item.moduleKey.toLowerCase() == 'dar') {
      final auth = context.read<AuthProvider>();
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: DarHubScreen(stationName: auth.stationName),
        ),
      );
      return;
    }
    if (label.toUpperCase() == 'IRAD' ||
        label.toUpperCase() == 'IRDA' ||
        item.moduleKey.toLowerCase() == 'irad' ||
        item.moduleKey.toLowerCase() == 'irda') {
      final auth = context.read<AuthProvider>();
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: IradHubScreen(stationName: auth.stationName),
        ),
      );
      return;
    }
    if (item.name == 'I to V') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const FormIVSelectionScreen(
            mode: FormIVSelectionMode.browse,
          ),
        ),
      );
    } else if (item.name == 'VI') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const FormVISelectionScreen(
            mode: FormVISelectionMode.browse,
          ),
        ),
      );
    } else if (item.name == 'Forms') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const ModuleHubScreen(
            moduleLabel: 'Forms',
            moduleKey: 'form_1_5',
            readOnly: true,
          ),
        ),
      );
    } else if (item.name == 'Pending') {
      final auth = context.read<AuthProvider>();
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: PendingHubScreen(stationName: auth.stationName),
        ),
      );
    } else if (item.name == 'Undetected' || item.moduleKey == 'undetected') {
      final auth = context.read<AuthProvider>();
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: UndetectedHubScreen(stationName: auth.stationName),
        ),
      );
    } else if (item.name == 'Detected') {
      final auth = context.read<AuthProvider>();
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: DetectedHubScreen(stationName: auth.stationName),
        ),
      );
    } else if (item.name == 'Disposal') {
      final auth = context.read<AuthProvider>();
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: DisposalHubScreen(stationName: auth.stationName),
        ),
      );
    } else if (item.name == 'Arrested') {
      final auth = context.read<AuthProvider>();
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: ArrestedHubScreen(stationName: auth.stationName),
        ),
      );
    } else if (item.name == 'Repeat Offender') {
      final auth = context.read<AuthProvider>();
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: RepeatOffenderSummaryScreen(stationName: auth.stationName),
        ),
      );
    } else if (item.name == 'NAFIS' ||
        item.name == NafisFingerprintScreen.title ||
        item.moduleKey == 'nafis') {
      // Two tabs: NAFIS and Fingerprint
      final auth = context.read<AuthProvider>();
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: NafisFingerprintScreen(stationName: auth.stationName),
        ),
      );
    } else if (item.name == 'E-Learning' ||
        item.moduleKey == 'elearning' ||
        item.name == 'E Learning') {
      final auth = context.read<AuthProvider>();
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: ELearningScreen(stationName: auth.stationName),
        ),
      );
    } else if (label.toLowerCase() == 'licence' ||
        label.toLowerCase() == 'license' ||
        item.name.toLowerCase() == 'licence' ||
        item.name.toLowerCase() == 'license' ||
        item.moduleKey == 'licence') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: LicenceHubScreen(stationName: widget.auth.stationName),
        ),
      );
    } else if (label.toLowerCase().contains('passport') ||
        item.name.toLowerCase().contains('passport') ||
        item.moduleKey == 'passport') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: PassportLicenceScreen(stationName: widget.auth.stationName),
        ),
      );
    } else if (item.moduleKey == 'service_tool' ||
        ServiceData.dashboardTools.any((t) =>
            t.label.toLowerCase() == label.toLowerCase() ||
            (t.moduleKey != null && t.moduleKey == item.moduleKey))) {
      final cleanLabel = label.trim().toLowerCase();
      if (cleanLabel == 'history sheeter' || cleanLabel == 'history sheet') {
        CategoryNavigationHelper.handleDashboardCategoryTap(
          context: context,
          categoryName: item.name,
          moduleKey: item.moduleKey,
          categoryId: item.categoryId,
          categoryCode: item.categoryCode,
          readOnly: false,
        );
      } else {
        Navigator.push(
          context,
          AppTheme.fadeSlideRoute(
            page: CaseFormScreen(categoryName: label),
          ),
        );
      }
    } else if (item.moduleKey == 'chain_snatching') {
      // Same tab, case list and form as inside "1 to 5"
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const FormIVSelectionScreen(
            openCategory: 'Chain Snatching',
            customTitle: 'Chain Snatching',
            mode: FormIVSelectionMode.browse,
          ),
        ),
      );
    } else if (item.moduleKey == 'kidnapping') {
      // The combined "Kidnapping/Missing" tab of "1 to 5"
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const FormIVSelectionScreen(
            openCategory: 'Kidnapping/Missing',
            customTitle: 'Kidnapping/Missing',
            mode: FormIVSelectionMode.browse,
          ),
        ),
      );
    } else if (CategorySubtabsScreen.forTile(item.moduleKey) != null) {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
            page: CategorySubtabsScreen.forTile(item.moduleKey)!),
      );
    } else if (item.moduleKey == 'hurt' || item.name == 'Hurt') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const HurtCasesScreen(),
        ),
      );
    } else if (item.moduleKey == 'absconded' || item.name == 'Absconded') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: AbscondedHubScreen(stationName: widget.auth.stationName),
        ),
      );
    } else if (item.moduleKey == 'juvenile' || item.name == 'Juvenile') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: JuvenileHubScreen(stationName: widget.auth.stationName),
        ),
      );
    } else if (item.moduleKey == 'victim' || item.name == 'Victim') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: VictimHubScreen(stationName: widget.auth.stationName),
        ),
      );
    } else if (item.moduleKey == 'muddemal' || item.name == 'Muddemal') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const MuddemalMainScreen(),
        ),
      );
    } else {
      final isStatsItem = [
        'Monthly',
        'Pending',
        'Disposal',
        'Sam/Warrant',
        'Sam Warrant'
      ].contains(item.name);
      if (isStatsItem) {
        Navigator.push(
          context,
          AppTheme.fadeSlideRoute(
            page: ModuleHubScreen(
              moduleLabel: item.name.replaceAll('\n', ' '),
              moduleKey: item.moduleKey,
              readOnly: true,
            ),
          ),
        );
      } else {
        CategoryNavigationHelper.handleDashboardCategoryTap(
          context: context,
          categoryName: item.name,
          moduleKey: item.moduleKey,
          categoryId: item.categoryId,
          categoryCode: item.categoryCode,
          readOnly: false,
        );
      }
    }
  }

  Widget _buildClassificationGridItem(
      BuildContext context, Classification item) {
    final label = item.name.replaceAll('\n', ' ');
    ServiceData? matchedTool;
    for (final t in ServiceData.dashboardTools) {
      if (t.label.toLowerCase() == label.toLowerCase() ||
          (t.moduleKey != null && t.moduleKey == item.moduleKey)) {
        matchedTool = t;
        break;
      }
    }

    return GestureDetector(
      onTap: () => _openClassificationItem(context, item),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.navyDark.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final side = constraints.maxWidth < constraints.maxHeight
                      ? constraints.maxWidth
                      : constraints.maxHeight;
                  final baseSize = (side * 0.44).clamp(18.0, 30.0);
                  return Center(
                    child: _buildGridIcon(
                        item.name,
                        matchedTool?.icon ?? _classIcon(item.iconName),
                        AppColors.navyMid,
                        baseSize),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Fixed two-line label area: one- and two-line labels take the same
          // height, so every icon box in a row has the same size and position.
          SizedBox(
            height: MediaQuery.textScalerOf(context).scale(9.5 * 1.2) * 2 + 2,
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                TranslationHelper.translate(context, item.name),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    color: AppColors.lightText),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle,
      {VoidCallback? onViewAll}) {
    return GestureDetector(
      onTap: onViewAll,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark)),
              Text(subtitle,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.lightSubText)),
            ],
          ),
          const Spacer(),
          if (onViewAll != null)
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 18, color: AppColors.navyMid),
        ],
      ),
    );
  }

  Widget _caseCard(Map<String, dynamic> c) {
    final iconColor = Color(c['iconColor'] as int);
    final record = c['record'] as ModuleRecord?;
    final rawStatus = c['status'] as String? ?? '';
    final badgeLabel = _statusBadgeLabel(rawStatus);
    final badgeColor = _statusBadgeColor(badgeLabel);
    final moduleLabel = record != null
        ? _moduleDisplayLabel(record)
        : (c['type'] as String? ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lightBorder.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border(
            left: BorderSide(color: badgeColor, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (record != null) {
                      Navigator.push(
                        context,
                        AppTheme.fadeSlideRoute(
                            page: CaseDetailScreen(
                                caseData: record, showFloatingActions: false)),
                      );
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                              color: iconColor.withValues(alpha: 0.2)),
                        ),
                        child: Icon(c['icon'] as IconData,
                            color: iconColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (moduleLabel.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.navyMid.withValues(alpha: 0.08),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  moduleLabel.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: AppColors.navyMid,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            Text(c['title'] as String,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navyDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text('${c['id']} • ${c['date']}',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.lightSubText)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                              color: badgeColor.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          badgeLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (record != null)
                IconButton(
                  tooltip: 'Download PDF',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: const Icon(Icons.picture_as_pdf_outlined,
                      color: AppColors.dangerRed, size: 22),
                  onPressed: () => PdfHelper.generateCasePdf(record),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoRecentCases() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      width: double.infinity,
      child: Column(
        children: [
          Icon(Icons.history_rounded,
              size: 48,
              color: widget.isDark
                  ? AppColors.darkSubText.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No cases registered yet',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppColors.lightSubText)),
        ],
      ),
    );
  }

  void _showTop10CasesModal(
      BuildContext context, List<Map<String, dynamic>> top10) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded,
                      color: AppColors.goldPrimary),
                  const SizedBox(width: 12),
                  Text('Top 10 Recent Cases',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: top10.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _caseCard(top10[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DEAD CODE — home grid now navigates to FormIVSelectionScreen. Pending
  // user confirmation before removal.
  // ignore: unused_element
  void _showFormIVBottomSheet(BuildContext context, {bool isAdding = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(Icons.description_rounded,
                      color: AppColors.goldPrimary),
                  const SizedBox(width: 12),
                  Text('Form I-V Cases',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FormIVCategoryButtonGrid(
                labels: formIVCaseCategories,
                scrollable: true,
                padding: const EdgeInsets.all(24),
                onLabelTap: (label) {
                  Navigator.pop(context);
                  if (isAdding) {
                    if (label == 'A.D.') {
                      // A.D. has sub-tabs (Suicide / Other): pick one first
                      CategoryNavigationHelper.handleDashboardCategoryTap(
                        context: context,
                        categoryName: label,
                        moduleKey: 'form_1_5',
                        readOnly: false,
                      );
                    } else if (label == 'N.C.') {
                      Navigator.push(
                        context,
                        AppTheme.fadeSlideRoute(
                            page: NcFormScreen(moduleLabel: label)),
                      );
                    } else if (label == 'Missing') {
                      Navigator.push(
                        context,
                        AppTheme.fadeSlideRoute(
                            page: MissingFormScreen(moduleLabel: label)),
                      );
                    } else if (label == 'Preventive') {
                      Navigator.push(
                        context,
                        AppTheme.fadeSlideRoute(
                            page: PreventiveFormScreen(moduleLabel: label)),
                      );
                    } else if (isTabLinkedToCommonFormBaseline(
                        moduleKey: 'form_1_5', categoryName: label)) {
                      Navigator.push(
                        context,
                        AppTheme.fadeSlideRoute(
                          page: CommonFormScreen(
                            moduleLabel: label,
                            moduleKey: 'form_1_5',
                            subCategory: label,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        AppTheme.fadeSlideRoute(
                          page: DynamicFormScreen(
                            moduleLabel: label,
                            moduleKey: 'form_1_5',
                            subCategory: label,
                          ),
                        ),
                      );
                    }
                  } else {
                    CategoryNavigationHelper.handleDashboardCategoryTap(
                      context: context,
                      categoryName: label,
                      moduleKey: 'form_1_5',
                      readOnly: false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── WANTED TAB ───────────────────────────────────────────────────────────────
class _WantedTab extends StatelessWidget {
  final bool isDark;
  const _WantedTab({required this.isDark});

  static const _wantedPersons = [
    {
      'name': 'Rajesh Kumar',
      'id': 'WNT/2024/001',
      'crime': 'Robbery & Assault',
      'reward': '₹50,000',
      'dangerous': true
    },
    {
      'name': 'Mohan Singh',
      'id': 'WNT/2024/002',
      'crime': 'Sand Theft',
      'reward': '₹25,000',
      'dangerous': false
    },
    {
      'name': 'Priya Das',
      'id': 'WNT/2024/003',
      'crime': 'Fraud & Cheating',
      'reward': '₹30,000',
      'dangerous': false
    },
    {
      'name': 'Abdul Hamid',
      'id': 'WNT/2024/004',
      'crime': 'Kidnapping/Missing',
      'reward': '₹1,00,000',
      'dangerous': true
    },
    {
      'name': 'Sunita Devi',
      'id': 'WNT/2024/005',
      'crime': 'Missing Case Suspect',
      'reward': '₹15,000',
      'dangerous': false
    },
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.dangerRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border:
                  Border.all(color: AppColors.dangerRed.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed_rounded, color: AppColors.dangerRed),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Wanted List — Active warrants issued',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dangerRed)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.dangerRed,
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: Text('${_wantedPersons.length}',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final p = _wantedPersons[i];
                final dangerous = (p['dangerous'] as bool?) ?? false;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: dangerous
                          ? AppColors.dangerRed.withValues(alpha: 0.4)
                          : AppColors.lightBorder,
                      width: dangerous ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.dangerRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: AppColors.dangerRed, size: 26),
                          ),
                          if (dangerous)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                    color: AppColors.dangerRed,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.warning_rounded,
                                    color: Colors.white, size: 10),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name'] as String,
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navyDark)),
                            Text(p['crime'] as String,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.lightSubText)),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.tag,
                                  size: 12, color: AppColors.infoBlue),
                              Text(p['id'] as String,
                                  style: GoogleFonts.poppins(
                                      fontSize: 11, color: AppColors.infoBlue)),
                            ]),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(p['reward'] as String,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.successGreen)),
                          Text('Reward',
                              style: GoogleFonts.poppins(
                                  fontSize: 10, color: AppColors.lightSubText)),
                        ],
                      ),
                    ],
                  ),
                );
              },
              childCount: _wantedPersons.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ── VIEW TAB ─────────────────────────────────────────────────────────────────
class _ViewTab extends StatefulWidget {
  final bool isDark;
  const _ViewTab({required this.isDark});

  @override
  State<_ViewTab> createState() => _ViewTabState();
}

class _ViewTabState extends State<_ViewTab> {
  final FirestoreService _firestore = FirestoreService();
  int _selectedTabIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  static const List<(int, IconData, String)> _tabs = [
    (0, Icons.folder_open_rounded, 'All'),
    (1, Icons.pending_actions_outlined, 'Pending'),
    (2, Icons.check_circle_outline_rounded, 'Disposed'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Stream<List<ModuleRecord>>? _stream;
  String? _streamKey;

  Stream<List<ModuleRecord>> _getStream(
      AuthProvider auth, CaseVisibilityMode mode) {
    if (_selectedTabIndex == 1) {
      return _firestore.getPendingCasesStream(auth.activeStation).map(
            (records) => CaseVisibility.filterRecords(
              records,
              uid: auth.uid,
              officerName: auth.displayName,
              mode: mode,
            ),
          );
    } else if (_selectedTabIndex == 2) {
      return _firestore.getDisposalCasesStream(auth.activeStation).map(
            (records) => CaseVisibility.filterRecords(
              records,
              uid: auth.uid,
              officerName: auth.displayName,
              mode: mode,
            ),
          );
    }
    return _firestore.getStationCasesStream(auth.activeStation).map(
          (records) => CaseVisibility.filterRecords(
            records,
            uid: auth.uid,
            officerName: auth.displayName,
            mode: mode,
          ),
        );
  }

  List<ModuleRecord> _filterRecords(List<ModuleRecord> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;

    return all.where((r) {
      return r.title.toLowerCase().contains(q) ||
          r.caseNumber.toLowerCase().contains(q) ||
          r.complainant.toLowerCase().contains(q) ||
          r.location.toLowerCase().contains(q) ||
          r.assignedOfficer.toLowerCase().contains(q) ||
          r.firestoreCategoryDisplayName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final mode = CaseVisibility.resolveFor(auth);

    // Same stream across rebuilds; a new one only when the tab, station,
    // officer or visibility mode changes (a new stream flashes "loading")
    final streamKey = '$_selectedTabIndex|${auth.activeStation}|${auth.uid}|'
        '${auth.displayName}|$mode';
    if (_stream == null || _streamKey != streamKey) {
      _streamKey = streamKey;
      _stream = _getStream(auth, mode);
    }

    return StreamBuilder<List<ModuleRecord>>(
      stream: _stream,
      builder: (context, snapshot) {
        final allRecords = snapshot.data ?? [];
        final filtered = _filterRecords(allRecords);
        final isLoading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Segmented Tab Selector (All, Pending, Disposed) ──────────────────
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: AppSpacing.md),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.lightBg,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: Row(
                        children: _tabs.map((t) {
                          final isSelected = _selectedTabIndex == t.$1;
                          return Expanded(
                            child: InkWell(
                              onTap: () {
                                if (_selectedTabIndex != t.$1) {
                                  setState(() => _selectedTabIndex = t.$1);
                                }
                              },
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.navyDark
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.navyDark
                                                .withValues(alpha: 0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      t.$2,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.navyDark
                                              .withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      t.$3,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.navyDark
                                                .withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Search Field & Count ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.md, AppSpacing.md, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _query = v),
                          style: GoogleFonts.poppins(
                              fontSize: 13.5, color: AppColors.navyDark),
                          decoration: InputDecoration(
                            hintText:
                                'Search by FIR, title, location, category…',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: AppColors.lightSubText,
                            ),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: AppColors.navyMid, size: 20),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _query = '');
                                    },
                                    icon: const Icon(Icons.close_rounded,
                                        color: AppColors.lightSubText,
                                        size: 18),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: const BorderSide(
                                  color: AppColors.lightBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: const BorderSide(
                                  color: AppColors.lightBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: const BorderSide(
                                  color: AppColors.navyMid, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _query.isNotEmpty
                              ? 'Found ${filtered.length} of ${allRecords.length} records'
                              : 'Total: ${filtered.length} records',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightSubText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Loading / Empty State or Records List ────────────────────────────
            if (isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.navyMid,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _query.isNotEmpty
                                ? Icons.search_off_rounded
                                : Icons.folder_open_rounded,
                            size: 48,
                            color: AppColors.navyMid.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _query.isNotEmpty
                                ? 'No matching cases'
                                : 'No records found in database',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _query.isNotEmpty
                                ? 'Try searching with a different keyword.'
                                : 'Cases created for this station will appear here from the database.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.lightSubText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final c = filtered[i];
                          final isDisposed =
                              c.status.toLowerCase() == 'closed' ||
                                  c.status.toLowerCase() == 'disposal' ||
                                  c.status.toLowerCase() == 'resolved' ||
                                  c.status.toLowerCase() == 'disposed';
                          final displayStatus =
                              isDisposed ? 'Disposal' : 'Pending';
                          final accentColor =
                              _selectedTabIndex == 2 || isDisposed
                                  ? AppColors.successGreen
                                  : _selectedTabIndex == 1
                                      ? AppColors.warningOrange
                                      : AppColors.infoBlue;
                          final statusColor = isDisposed
                              ? AppColors.successGreen
                              : AppColors.warningOrange;

                          final displayTitle = c.title.trim().isNotEmpty
                              ? c.title.trim()
                              : 'Untitled Case';
                          final firLabel = c.caseNumber.trim().isNotEmpty
                              ? c.caseNumber.trim()
                              : 'No FIR / case number';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.lightBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    AppTheme.fadeSlideRoute(
                                      page: c.moduleKey == 'ad'
                                          ? AdRecordDetailScreen(record: c)
                                          : ModuleRecordDetailScreen(record: c),
                                    ),
                                  );
                                },
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        width: 4,
                                        decoration: BoxDecoration(
                                          color: accentColor,
                                          borderRadius:
                                              const BorderRadius.horizontal(
                                            left: Radius.circular(AppRadius.md),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Top Row: FIR and Status Badge
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.navyMid
                                                          .withValues(
                                                              alpha: 0.08),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              AppRadius.sm),
                                                    ),
                                                    child: Text(
                                                      firLabel,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            AppColors.navyDark,
                                                      ),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: statusColor
                                                          .withValues(
                                                              alpha: 0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              AppRadius.full),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 6,
                                                          height: 6,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: statusColor,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          displayStatus,
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 10.5,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: statusColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),

                                              // Case Title
                                              Text(
                                                displayTitle,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.navyDark,
                                                ),
                                              ),
                                              const SizedBox(height: 3),

                                              // Category Pill
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.goldPrimary
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  c.firestoreCategoryDisplayName,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.goldDark,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),

                                              // Metadata row
                                              Wrap(
                                                spacing: 12,
                                                runSpacing: 4,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .calendar_today_rounded,
                                                        size: 12,
                                                        color: AppColors
                                                            .lightSubText,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        DateFormat(
                                                                'dd MMM yyyy')
                                                            .format(
                                                                c.incidentDate),
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 11,
                                                          color: AppColors
                                                              .lightSubText,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (c.location.isNotEmpty)
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .location_on_rounded,
                                                          size: 12,
                                                          color: AppColors
                                                              .lightSubText,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          c.location,
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 11,
                                                            color: AppColors
                                                                .lightSubText,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  if (c.assignedOfficer
                                                      .isNotEmpty)
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.person_rounded,
                                                          size: 12,
                                                          color: AppColors
                                                              .lightSubText,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          c.assignedOfficer,
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 11,
                                                            color: AppColors
                                                                .lightSubText,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                              const Divider(height: 20),

                                              // Actions Row: Edit (Guarded), Reminder (Senior Only), PDF, View
                                              Builder(builder: (ctx) {
                                                final canEdit = PoliceRbacHelper
                                                    .canEditRecord(c, auth);
                                                final canSendReminder =
                                                    PoliceRbacHelper
                                                        .canSendReminder(auth);

                                                return Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: [
                                                    if (canEdit)
                                                      _buildCardAction(
                                                        icon: Icons
                                                            .edit_note_rounded,
                                                        label: 'Edit',
                                                        color:
                                                            AppColors.infoBlue,
                                                        onTap: () {
                                                          final isLinked =
                                                              isTabLinkedToCommonFormBaseline(
                                                            moduleKey:
                                                                c.moduleKey,
                                                            categoryName: c
                                                                .firestoreCategoryDisplayName,
                                                          );
                                                          final page = isLinked
                                                              ? CommonFormScreen(
                                                                  moduleKey: c
                                                                      .moduleKey,
                                                                  moduleLabel: c
                                                                      .firestoreCategoryDisplayName,
                                                                  existingRecord:
                                                                      c,
                                                                )
                                                              : DynamicFormScreen(
                                                                  moduleKey: c
                                                                      .moduleKey,
                                                                  moduleLabel: c
                                                                      .firestoreCategoryDisplayName,
                                                                  existingRecord:
                                                                      c,
                                                                );
                                                          Navigator.push(
                                                            context,
                                                            AppTheme
                                                                .fadeSlideRoute(
                                                                    page: page),
                                                          );
                                                        },
                                                      ),
                                                    if (canSendReminder)
                                                      _buildCardAction(
                                                        icon: Icons
                                                            .notifications_active_outlined,
                                                        label: 'Reminder',
                                                        color: AppColors
                                                            .warningOrange,
                                                        onTap: () {
                                                          SendReminderDialog
                                                              .show(context, c);
                                                        },
                                                      ),
                                                    _buildCardAction(
                                                      icon: Icons
                                                          .picture_as_pdf_rounded,
                                                      label: 'PDF',
                                                      color:
                                                          AppColors.dangerRed,
                                                      onTap: () {
                                                        ModulePdfHelper
                                                            .generatePdf(c);
                                                      },
                                                    ),
                                                    _buildCardAction(
                                                      icon: Icons
                                                          .visibility_rounded,
                                                      label: 'View',
                                                      color:
                                                          AppColors.goldPrimary,
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          AppTheme
                                                              .fadeSlideRoute(
                                                            page: c.moduleKey ==
                                                                    'ad'
                                                                ? AdRecordDetailScreen(
                                                                    record: c)
                                                                : ModuleRecordDetailScreen(
                                                                    record: c),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                );
                                              }),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCardAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CALENDAR TAB ─────────────────────────────────────────────────────────────
// Shows the same Time Wise breakdown as the Pending hub.
class _CalendarTab extends StatefulWidget {
  final bool isDark;
  const _CalendarTab({required this.isDark});

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  final BackendCaseService _backend = BackendCaseService();
  List<Map<String, dynamic>>? _timeWiseData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _backend.fetchPendingTimeWise();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (data != null) {
          _timeWiseData = data;
          _error = null;
        } else if (_timeWiseData == null) {
          _error = 'Failed to load time-wise pending data.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navyMid),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: GoogleFonts.poppins(color: AppColors.dangerRed),
        ),
      );
    }

    // The "(Total)" row only repeats the first two periods added together.
    final items = (_timeWiseData ?? const <Map<String, dynamic>>[])
        .where((item) => item['period']?.toString() != 'Under 3 months (Total)')
        .toList();
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.navyMid,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 100),
        children: [
          // All cards in one row. Cards share the width equally, and
          // scroll sideways once they would be narrower than minCardWidth
          // (small phones).
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              const minCardWidth = 112.0;
              final cards = <Widget>[
                for (final item in items)
                  PendingTimeWiseCard(
                    period: item['period']?.toString() ?? '',
                    count: (item['count'] as num?)?.toInt() ?? 0,
                    vertical: true,
                    showTitlePrefix: false,
                  ),
                // Pick any date range and list the pending cases in it.
                const PendingTimeWiseCard.custom(showTitlePrefix: false),
              ];
              final count = cards.length;
              final fitWidth =
                  (constraints.maxWidth - gap * (count - 1)) / count;
              final cardWidth =
                  fitWidth < minCardWidth ? minCardWidth : fitWidth;
              final row = Row(
                children: [
                  for (var i = 0; i < count; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    SizedBox(width: cardWidth, child: cards[i]),
                  ],
                ],
              );
              return fitWidth < minCardWidth
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: row,
                    )
                  : row;
            },
          ),
        ],
      ),
    );
  }
}

// ── Dashboard AppBar station switcher ─────────────────────────────────────────

// ignore: unused_element
class _DashboardStationSwitcher extends StatefulWidget {
  const _DashboardStationSwitcher({required this.auth});

  final AuthProvider auth;

  @override
  State<_DashboardStationSwitcher> createState() =>
      _DashboardStationSwitcherState();
}

class _DashboardStationSwitcherState extends State<_DashboardStationSwitcher> {
  final FirestoreService _firestore = FirestoreService();
  List<String> _stations = [];
  bool _loading = false;

  bool get _canSwitch =>
      SeniorOfficerRoles.canSwitchLocation(widget.auth.designation);

  @override
  void initState() {
    super.initState();
    if (_canSwitch) _loadStations();
  }

  @override
  void didUpdateWidget(covariant _DashboardStationSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_canSwitch &&
        oldWidget.auth.designation != widget.auth.designation &&
        _stations.isEmpty) {
      _loadStations();
    }
  }

  Future<void> _loadStations() async {
    setState(() => _loading = true);
    final names = await _firestore.getPoliceStationNames();
    if (!mounted) return;
    setState(() {
      _stations = names;
      _loading = false;
    });
  }

  List<String> _dropdownItems(String active) {
    final items = <String>{..._stations};
    if (active.trim().isNotEmpty) items.add(active.trim());
    final sorted = items.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    final active = auth.activeStation.trim();
    final screenWidth = MediaQuery.of(context).size.width;
    final maxSwitcherWidth =
        screenWidth < 380 ? 110.0 : (screenWidth < 480 ? 130.0 : 220.0);
    final labelStyle = GoogleFonts.poppins(
      fontSize: screenWidth < 400 ? 10 : 11,
      fontWeight: FontWeight.w600,
      color: AppColors.navyDark,
    );

    if (!_canSwitch) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxSwitcherWidth),
        child: Text(
          active.isNotEmpty ? active : '—',
          style: labelStyle.copyWith(color: AppColors.navyMid),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
        ),
      );
    }

    final items = _dropdownItems(active);
    final value = active.isNotEmpty && items.contains(active) ? active : null;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxSwitcherWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: auth.isViewingOtherStation
              ? AppColors.goldPrimary.withValues(alpha: 0.12)
              : const Color(0xFFF4F6FB),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: auth.isViewingOtherStation
                ? AppColors.goldPrimary.withValues(alpha: 0.45)
                : AppColors.lightBorder,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth < 400 ? 6 : 10),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(
                _loading ? 'Loading…' : 'Select station',
                style: labelStyle.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.navyMid,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                size: screenWidth < 400 ? 18 : 24,
                color: auth.isViewingOtherStation
                    ? AppColors.goldPrimary
                    : AppColors.navyMid,
              ),
              items: items
                  .map(
                    (station) => DropdownMenuItem<String>(
                      value: station,
                      child: Text(
                        station,
                        style: labelStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _loading
                  ? null
                  : (selected) {
                      if (selected == null || selected.isEmpty) return;
                      auth.switchStation(selected);
                    },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Station Switcher Bottom Sheet ─────────────────────────────────────────────

/// One district/commissionerate zone with selectable station (or location) names.
class _SwitcherZone {
  const _SwitcherZone({required this.zoneName, required this.entries});

  final String zoneName;
  final List<String> entries;
}

class _StationSwitcherSheet extends StatefulWidget {
  final FirestoreService firestore;
  final AuthProvider auth;

  const _StationSwitcherSheet({
    required this.firestore,
    required this.auth,
  });

  @override
  State<_StationSwitcherSheet> createState() => _StationSwitcherSheetState();
}

class _StationSwitcherSheetState extends State<_StationSwitcherSheet> {
  static const String _otherZoneName = 'Other Locations';

  List<_SwitcherZone> _zones = [];
  List<_SwitcherZone> _visibleZones = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _loading = true);

    try {
      await MaharashtraPoliceStationsRepository.initialize();
    } catch (_) {
      // CSV unavailable — still attempt Firestore-only grouping below.
    }

    final rawNames = await _collectRawAccessibleNames();
    final zones = _buildZones(rawNames);

    if (!mounted) return;
    setState(() {
      _zones = zones;
      _loading = false;
    });
    _applySearchFilter();
  }

  /// Fresh name set on every sheet open (Firestore re-fetched for non CP/SP roles).
  Future<Set<String>> _collectRawAccessibleNames() async {
    final designation = widget.auth.designation;
    final isCp = SeniorOfficerRoles.isCpLevel(designation);
    final isSp = SeniorOfficerRoles.isSpLevel(designation);
    final additional = widget.auth.additionalStations;
    final home = widget.auth.homeStationName.trim();

    final names = <String>{};
    if (home.isNotEmpty) names.add(home);
    names.addAll(additional.where((s) => s.trim().isNotEmpty));

    if (isCp || isSp) {
      final currentArea = _resolveCurrentArea(widget.auth.stationName);
      if (currentArea.isEmpty) {
        return names;
      }
      for (final station
          in MaharashtraPoliceStationsRepository.getStationsForDistrict(
        currentArea,
      )) {
        if (isCp && station.type != 'Commissionerate Police') continue;
        if (isSp && station.type != 'Superintendent of Police') continue;
        names.add(station.stationName);
      }
    } else if (SeniorOfficerRoles.canSwitchLocation(designation)) {
      final fetched = await widget.firestore.getPoliceStationNames();
      names.addAll(fetched.where((s) => s.trim().isNotEmpty));
    } else {
      final fetched = await widget.firestore.getAllStationNames();
      names.addAll(fetched.where((s) => s.trim().isNotEmpty));
    }

    names.removeWhere((s) => s.trim().isEmpty);
    return names;
  }

  List<_SwitcherZone> _buildZones(Set<String> rawNames) {
    if (!MaharashtraPoliceStationsRepository.isLoaded) {
      if (rawNames.isEmpty) return const [];
      final entries = rawNames.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return [_SwitcherZone(zoneName: _otherZoneName, entries: entries)];
    }

    final designation = widget.auth.designation;
    final isCp = SeniorOfficerRoles.isCpLevel(designation);
    final isSp = SeniorOfficerRoles.isSpLevel(designation);
    final additional = widget.auth.additionalStations;
    final currentArea = _resolveCurrentArea(widget.auth.stationName);

    final zoneEntries = <String, Set<String>>{};
    void addEntry(String zone, String entry) {
      if (entry.trim().isEmpty) return;
      zoneEntries.putIfAbsent(zone, () => {}).add(entry.trim());
    }

    String zoneForEntry(String name) =>
        _resolveDistrictForName(name) ?? _otherZoneName;

    bool districtExpanded(String district) {
      if (currentArea.isNotEmpty &&
          district.toLowerCase() == currentArea.toLowerCase()) {
        return true;
      }
      return additional
          .any((a) => a.trim().toLowerCase() == district.toLowerCase());
    }

    void addDistrictStations(String district) {
      if (!districtExpanded(district)) return;
      for (final station
          in MaharashtraPoliceStationsRepository.getStationsForDistrict(
        district,
      )) {
        if (isCp && station.type != 'Commissionerate Police') continue;
        if (isSp && station.type != 'Superintendent of Police') continue;
        addEntry(district, station.stationName);
      }
    }

    for (final name in rawNames) {
      if (_isDistrictName(name)) {
        final district = _canonicalDistrictName(name)!;
        addEntry(district, district);
        addDistrictStations(district);
      } else {
        addEntry(zoneForEntry(name), name);
      }
    }

    if (currentArea.isNotEmpty && _isDistrictName(currentArea)) {
      addDistrictStations(currentArea);
    }

    final sortedZoneNames = zoneEntries.keys.toList()
      ..sort(
        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );

    return sortedZoneNames
        .map((zoneName) {
          final entries = zoneEntries[zoneName]!.toList()
            ..sort(_compareSwitcherEntries);
          return _SwitcherZone(zoneName: zoneName, entries: entries);
        })
        .where((zone) => zone.entries.isNotEmpty)
        .toList();
  }

  int _compareSwitcherEntries(String a, String b) {
    final aIsDistrict = _isDistrictName(a);
    final bIsDistrict = _isDistrictName(b);
    if (aIsDistrict && !bIsDistrict) return -1;
    if (!aIsDistrict && bIsDistrict) return 1;
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  void _applySearchFilter() {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) {
      if (!mounted) return;
      setState(() => _visibleZones = _zones);
      return;
    }

    final filtered = <_SwitcherZone>[];
    for (final zone in _zones) {
      if (zone.zoneName.toLowerCase().contains(q)) {
        filtered.add(zone);
        continue;
      }
      final matchingEntries = zone.entries
          .where((entry) => entry.toLowerCase().contains(q))
          .toList();
      if (matchingEntries.isNotEmpty) {
        filtered.add(
          _SwitcherZone(zoneName: zone.zoneName, entries: matchingEntries),
        );
      }
    }

    if (!mounted) return;
    setState(() => _visibleZones = filtered);
  }

  bool _isDistrictName(String name) {
    final value = name.trim();
    if (value.isEmpty) return false;
    if (!MaharashtraPoliceStationsRepository.isLoaded) return false;
    return MaharashtraPoliceStationsRepository.getDistricts().any(
      (d) => d.toLowerCase() == value.toLowerCase(),
    );
  }

  String? _canonicalDistrictName(String name) {
    final value = name.trim();
    if (value.isEmpty || !MaharashtraPoliceStationsRepository.isLoaded) {
      return null;
    }
    for (final district in MaharashtraPoliceStationsRepository.getDistricts()) {
      if (district.toLowerCase() == value.toLowerCase()) return district;
    }
    return null;
  }

  String? _resolveDistrictForName(String name) {
    final value = name.trim();
    if (value.isEmpty) return null;

    final asDistrict = _canonicalDistrictName(value);
    if (asDistrict != null) return asDistrict;

    if (!MaharashtraPoliceStationsRepository.isLoaded) return null;
    for (final station
        in MaharashtraPoliceStationsRepository.getAllStations()) {
      if (station.stationName.toLowerCase() == value.toLowerCase()) {
        return station.districtName;
      }
    }
    return null;
  }

  String _resolveCurrentArea(String activeName) {
    return _resolveDistrictForName(activeName) ?? '';
  }

  void _onSearch(String q) {
    setState(() => _search = q);
    _applySearchFilter();
  }

  bool get _hasVisibleEntries =>
      _visibleZones.any((zone) => zone.entries.isNotEmpty);

  Future<void> _confirmDeleteLocation(String location) async {
    final homeStation = widget.auth.homeStationName;
    if (location.trim().isEmpty) return;
    if (location == homeStation) return;
    if (!widget.auth.additionalStations.contains(location)) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Location'),
        content: const Text('Are you sure you want to remove this location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    if (SeniorOfficerRoles.canSwitchLocation(widget.auth.designation)) {
      await MaharashtraPoliceStationsRepository.initialize();
    }
    final active = widget.auth.stationName;
    final activeArea = _resolveCurrentArea(active);
    final isDeletingActive = active == location ||
        activeArea.toLowerCase() == location.toLowerCase();

    await widget.auth.removeStation(location);

    if (isDeletingActive) {
      widget.auth.switchStation(homeStation);
    }

    _loadStations();
  }

  Future<void> _onAddLocation() async {
    final isCp = SeniorOfficerRoles.isCpLevel(widget.auth.designation);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddLocationSheet(isCpLevel: isCp),
    );

    if (result != null && result.isNotEmpty) {
      await widget.auth.addStation(result);
      _loadStations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeStation = widget.auth.stationName;
    final homeStation = widget.auth.homeStationName;
    final canAdd =
        SeniorOfficerRoles.canSwitchLocation(widget.auth.designation);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.navyMid.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.navyMid, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Switch Policestation',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                      Text(
                        'Select a station to view its data',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.lightSubText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: _onSearch,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search zone or station...',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.lightSubText),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 20, color: AppColors.navyMid),
                filled: true,
                fillColor: const Color(0xFFF4F6FB),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.navyMid),
            )
          else if (!_hasVisibleEntries)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  const Icon(Icons.location_off_rounded,
                      size: 40, color: AppColors.lightSubText),
                  const SizedBox(height: 8),
                  Text(
                    _search.trim().isNotEmpty
                        ? 'No zones or stations match "${_search.trim()}"'
                        : 'No stations found',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.lightSubText),
                  ),
                  if (canAdd) ...[
                    const SizedBox(height: 16),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.add_location_alt_rounded,
                          size: 20,
                          color: AppColors.goldPrimary,
                        ),
                        title: Text(
                          'Add Location',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.goldPrimary,
                          ),
                        ),
                        onTap: _onAddLocation,
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  for (var zi = 0; zi < _visibleZones.length; zi++) ...[
                    if (zi > 0)
                      const Divider(height: 1, indent: 20, endIndent: 20),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Text(
                        _visibleZones[zi].zoneName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    for (final station in _visibleZones[zi].entries)
                      _buildStationTile(
                        station: station,
                        activeStation: activeStation,
                        homeStation: homeStation,
                      ),
                  ],
                  if (canAdd)
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.add_location_alt_rounded,
                          size: 20,
                          color: AppColors.goldPrimary,
                        ),
                        title: Text(
                          'Add Location',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.goldPrimary,
                          ),
                        ),
                        onTap: _onAddLocation,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStationTile({
    required String station,
    required String activeStation,
    required String homeStation,
  }) {
    final isActive = station == activeStation;
    final isHome = station == homeStation;
    final isAddedLocation =
        widget.auth.additionalStations.contains(station) && !isHome;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        selected: isActive,
        selectedTileColor: AppColors.navyMid.withValues(alpha: 0.08),
        leading: Icon(
          isActive
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_off_rounded,
          size: 20,
          color: isActive ? AppColors.navyMid : AppColors.lightSubText,
        ),
        title: Text(
          station,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppColors.navyDark : AppColors.lightText,
          ),
        ),
        trailing: (isHome || isAddedLocation)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isHome)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        'Home',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                    ),
                  if (isAddedLocation)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: Colors.red,
                      onPressed: () => _confirmDeleteLocation(station),
                    ),
                ],
              )
            : null,
        onTap: () {
          widget.auth.switchStation(station);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Add Location Bottom Sheet ──────────────────────────────────────────────────
class _AddLocationSheet extends StatefulWidget {
  /// When true, the picker is labeled as "City" (CP-level / commissionerate).
  /// When false, it is labeled as "District" (SP-level / rural). The
  /// underlying data source is the same — only the label differs.
  final bool isCpLevel;
  const _AddLocationSheet({this.isCpLevel = true});

  @override
  State<_AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends State<_AddLocationSheet> {
  // Senior officers operate at the city (CP) or district (SP) level: only
  // state + area are needed. Reuses the same data source as the
  // registration form's district picker.
  String? _state = 'Maharashtra'; // Default to Maharashtra
  String? _city;

  Map<String, List<String>> _districtsByState = {};
  List<String> _maharashtraDistricts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final map = await IndiaDistrictsRepository.load();
    await MaharashtraPoliceStationsRepository.initialize();
    if (!mounted) return;
    setState(() {
      _districtsByState = map;
      _maharashtraDistricts =
          MaharashtraPoliceStationsRepository.getDistricts();
      _loading = false;
    });
  }

  List<String> _getCities() {
    if (_state == 'Maharashtra') return _maharashtraDistricts;
    return _districtsByState[_state] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add New Location',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child:
                          CircularProgressIndicator(color: AppColors.navyMid),
                    ),
                  )
                else ...[
                  SearchablePickerField(
                    label: 'State',
                    hintText: 'Select State',
                    items: IndiaStates.all,
                    value: _state,
                    onChanged: (v) => setState(() {
                      _state = v;
                      _city = null;
                    }),
                    leadingIcon: Icons.map_rounded,
                  ),
                  SearchablePickerField(
                    label: widget.isCpLevel ? 'City' : 'District',
                    hintText:
                        widget.isCpLevel ? 'Select City' : 'Select District',
                    items: _getCities(),
                    value: _city,
                    onChanged: (v) => setState(() => _city = v),
                    enabled: _state != null,
                    leadingIcon: widget.isCpLevel
                        ? Icons.location_city_rounded
                        : Icons.map_rounded,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _city == null
                          ? null
                          : () => Navigator.pop(context, _city),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Confirm & Add Location',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Case Bottom Sheet ─────────────────────────────────────────────────────
class _AddCaseBottomSheet extends StatefulWidget {
  final bool isDark;
  const _AddCaseBottomSheet({required this.isDark});

  @override
  State<_AddCaseBottomSheet> createState() => _AddCaseBottomSheetState();
}

class _AddCaseBottomSheetState extends State<_AddCaseBottomSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = Classification.addMenuAll
        .where((item) =>
            item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_task_rounded,
                      color: AppColors.goldPrimary, size: 24),
                ),
                const SizedBox(width: 16),
                Text('Unified Police Entry Menu',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDark)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.navyDark),
                decoration: InputDecoration(
                  hintText: 'Search entry types...',
                  hintStyle:
                      GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 18, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.82,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _buildGridItem(context, filteredItems[i]),
                      childCount: filteredItems.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, Classification item) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (item.moduleKey == 'form_1_5') {
          Navigator.push(
              context,
              AppTheme.fadeSlideRoute(
                  page: const FormIVSelectionScreen(
                mode: FormIVSelectionMode.add,
              )));
        } else if (item.moduleKey == 'ad') {
          // A.D. has sub-tabs (Suicide / Other): pick one first
          CategoryNavigationHelper.handleDashboardCategoryTap(
            context: context,
            categoryName: 'A.D.',
            moduleKey: 'form_1_5',
          );
        } else if (item.moduleKey == 'nc') {
          // N.C. is an independent module: route through target_category_code
          CategoryNavigationHelper.handleDashboardCategoryTap(
            context: context,
            categoryName: item.name,
            moduleKey: item.moduleKey,
          );
        } else if (item.moduleKey == 'kidnapping') {
          // The combined "Kidnapping/Missing" tab of "1 to 5"
          Navigator.push(
              context,
              AppTheme.fadeSlideRoute(
                page: const FormIVSelectionScreen(
                  openCategory: 'Kidnapping/Missing',
                  customTitle: 'Kidnapping/Missing',
                  mode: FormIVSelectionMode.add,
                ),
              ));
        } else if (item.moduleKey == 'missing') {
          Navigator.push(
              context,
              AppTheme.fadeSlideRoute(
                page: MissingFormScreen(
                  moduleLabel: item.name,
                ),
              ));
        } else if (item.moduleKey == 'preventive') {
          Navigator.push(
              context,
              AppTheme.fadeSlideRoute(
                page: PreventiveFormScreen(
                  moduleLabel: item.name,
                ),
              ));
        } else if (item.moduleKey == 'passport') {
          PassportAddEditDialog.show(context);
        } else if (item.moduleKey == 'muddemal' || item.name == 'Muddemal') {
          Navigator.push(
              context,
              AppTheme.fadeSlideRoute(
                page: const MuddemalMainScreen(),
              ));
        } else if (moduleUsesCommonCrimeForm(item.moduleKey, item.name)) {
          Navigator.push(
              context,
              AppTheme.fadeSlideRoute(
                  page: CommonFormScreen(
                moduleLabel: item.name,
                moduleKey: item.moduleKey,
                subCategory: item.name,
              )));
        } else {
          Navigator.push(
              context,
              AppTheme.fadeSlideRoute(
                  page: ModuleFormScreen(
                moduleLabel: item.name,
                moduleKey: item.moduleKey,
                subCategory: item.name,
              )));
        }
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Center(
                child: _buildGridIcon(
                  item.name,
                  _classIconFromName(item.iconName),
                  AppColors.goldPrimary,
                  28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            TranslationHelper.translate(context, item.name),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppColors.navyDark,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Search Results grouped by module ─────────────────────────────────────────
class _SearchModuleGroup extends StatelessWidget {
  final bool isDark;
  final String moduleLabel;
  final String moduleKey;
  final List<SearchResult> results;

  const _SearchModuleGroup({
    required this.isDark,
    required this.moduleLabel,
    required this.moduleKey,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final shown = results.take(5).toList();
    final overflow = results.length - 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => CategoryNavigationHelper.handleDashboardCategoryTap(
            context: context,
            categoryName: moduleLabel,
            moduleKey: moduleKey,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8, top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.navyMid.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.navyMid.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.folder_copy_rounded,
                  size: 15, color: AppColors.goldPrimary),
              const SizedBox(width: 8),
              Text(moduleLabel.toUpperCase(),
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.goldPrimary)),
              const Spacer(),
              Text('${results.length} match${results.length == 1 ? '' : 'es'}',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightSubText)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 11, color: AppColors.goldPrimary),
            ]),
          ),
        ),
        ...shown.map((r) => _resultCard(context, r)),
        if (overflow > 0)
          GestureDetector(
            onTap: () => CategoryNavigationHelper.handleDashboardCategoryTap(
              context: context,
              categoryName: moduleLabel,
              moduleKey: moduleKey,
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Text('+ $overflow more in $moduleLabel →',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldPrimary)),
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _resultCard(BuildContext context, SearchResult r) {
    final record = r.record;
    final sc = _statusColor(record.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(record.title,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Row(children: [
              Text(record.caseNumber,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.infoBlue,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('• ${DateFormat('dd MMM yyyy').format(record.incidentDate)}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.lightSubText)),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: sc.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sc.withValues(alpha: 0.3)),
          ),
          child: Text(record.status == 'Open' ? 'Pending' : record.status,
              style: GoogleFonts.poppins(
                  fontSize: 10, fontWeight: FontWeight.w700, color: sc)),
        ),
      ]),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Open':
        return AppColors.warningOrange;
      case 'Active':
        return AppColors.infoBlue;
      case 'Resolved':
        return AppColors.successGreen;
      case 'Closed':
        return const Color(0xFF607D8B);
      default:
        return AppColors.lightSubText;
    }
  }
}

dynamic _classIconFromName(String name) {
  switch (name) {
    case 'search':
      return Icons.search_rounded;
    case 'visibility_off':
      return Icons.visibility_off_rounded;
    case 'delete_forever':
      return Icons.delete_forever_rounded;
    case 'gavel':
      return Icons.gavel_rounded;
    case 'handcuffs':
      return Icons.link_rounded;
    case 'directions_run':
      return Icons.directions_run_rounded;
    case 'child_care':
      return Icons.child_care_rounded;
    case 'child_friendly':
      return Icons.child_friendly_rounded;
    case 'healing':
      return Icons.healing_rounded;
    case 'shield':
      return Icons.shield_rounded;
    case 'woman':
      return Icons.woman_rounded;
    case 'description':
      return Icons.description_rounded;
    case 'article':
      return Icons.article_rounded;
    case 'badge':
      return Icons.badge_rounded;
    case 'assignment':
      return Icons.assignment_rounded;
    case 'traffic':
      return Icons.traffic_rounded;
    case 'inventory':
      return Icons.inventory_2_rounded;
    case 'two_wheeler':
      return Icons.two_wheeler_rounded;
    case 'calendar_month':
      return Icons.calendar_month_rounded;
    case 'pending_actions':
      return FontAwesomeIcons.solidClock;
    case 'local_hospital':
      return Icons.local_hospital_rounded;
    case 'no_encryption':
      return Icons.no_encryption_rounded;
    case 'terrain':
      return Icons.terrain_rounded;
    case 'report':
      return Icons.report_rounded;
    case 'security':
      return Icons.security_rounded;
    case 'person_search':
      return Icons.person_search_rounded;
    case 'car_crash':
      return Icons.car_crash_rounded;
    case 'balance':
      return Icons.balance_rounded;
    case 'medication':
      return Icons.medication_rounded;
    case 'home_work':
      return Icons.home_work_rounded;
    case 'computer':
      return Icons.computer_rounded;
    case 'policy':
      return Icons.policy_rounded;
    case 'account_balance':
      return Icons.account_balance_rounded;
    case 'admin_panel':
      return Icons.admin_panel_settings_rounded;
    case 'monetization_on':
      return Icons.monetization_on_rounded;
    default:
      return Icons.folder_rounded;
  }
}
