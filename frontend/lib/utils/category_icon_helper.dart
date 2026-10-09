import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Centralized category icon helper matching the dashboard's SVG artwork
/// with seamless Material Rounded fallbacks for categories without SVGs.
class CategoryIconHelper {
  const CategoryIconHelper._();

  /// Resolves matching dashboard SVG path from assets/icons/ if available.
  static String? getSvgPath(String category) {
    final k = category.trim().toLowerCase();

    switch (k) {
      case 'theft':
      case 'thefts':
      case 'robbery':
      case 'chain snatching':
        return 'assets/icons/theft.svg';
      case 'hurt':
      case 'hurts':
        return 'assets/icons/hurt.svg';
      case 'sand theft':
        return 'assets/icons/sandtheft.svg';
      case 'two/four wheeler':
      case 'two/four wheeler theft':
      case '2-4 wheeler':
      case '2/4 wheeler':
      case 'vehicle theft':
        return 'assets/icons/2-4wheeler.svg';
      case 'kidnapping':
      case 'kidnapping/missing':
        return 'assets/icons/kidnapping.svg';
      case 'missing':
        return 'assets/icons/missing.svg';
      case 'crime against women':
      case 'crime against woman':
      case 'crimes against women':
      case '498 (a) ipc':
      case '498a':
      case '498 (a)':
      case '498 ipc':
        return 'assets/icons/crimewomen.svg';
      case 'accident':
      case 'normal accident':
      case 'road accident':
      case 'other road accident':
      case 'death due to rash driving':
        return 'assets/icons/accident.svg';
      case 'coin':
      case 'coins':
        return 'assets/icons/coin.svg';
      case 'ipc (a) 304':
      case '304':
      case '304 ipc':
      case '304 (a) ipc':
      case '304a':
      case 'a.d.':
      case 'a.d':
      case 'ad':
        return 'assets/icons/ad.svg';
      case 'n.c.':
      case 'n.c':
      case 'nc':
        return 'assets/icons/nc.svg';
      case 'dacoity':
      case 'arrested':
        return 'assets/icons/arrested.svg';
      case 'absconded':
        return 'assets/icons/absconded.svg';
      case 'st drugs':
      case 'ndps':
        return 'assets/icons/ndps.svg';
      case 'prohibition':
        return 'assets/icons/prohibiton.svg';
      case 'gambling':
        return 'assets/icons/gambling.svg';
      case 'pocso':
        return 'assets/icons/pocso.svg';
      case 'gowans':
      case 'gowansh':
        return 'assets/icons/gowans.svg';
      case 'it act':
        return 'assets/icons/itact.svg';
      case 'm.v act':
      case 'mv act':
      case 'm.v. act':
        return 'assets/icons/mvact.svg';
      case 'uapa':
        return 'assets/icons/uapa.svg';
      case 'mcoca':
      case 'macoca':
        return 'assets/icons/macoca.svg';
      case 'mpda':
        return 'assets/icons/mpda.svg';
      case 'pending':
        return 'assets/icons/pending.svg';
      case 'disposal':
        return 'assets/icons/disposal.svg';
      case 'detected':
        return 'assets/icons/detected.svg';
      case 'undetected':
        return 'assets/icons/undetected.svg';
      case 'monthly':
        return 'assets/icons/monthly.svg';
      case 'juvenile':
        return 'assets/icons/juvenile.svg';
      case 'victim':
        return 'assets/icons/victim.svg';
      case 'muddemal':
        return 'assets/icons/muddemal.svg';
      case 'rti':
        return 'assets/icons/rti.svg';
      case 'tadipar':
        return 'assets/icons/tadipar.svg';
      case 'cctns':
        return 'assets/icons/cctns.svg';
      case 'licence':
        return 'assets/icons/licence.svg';
      case 'repeat offender':
        return 'assets/icons/repeatoffender.svg';
      case 'dar':
        return 'assets/icons/dar.svg';
      case 'irda':
        return 'assets/icons/IRDA.svg';
      case 'itsso':
        return 'assets/icons/itsso.svg';
    }

    if (k.contains('accident')) {
      return 'assets/icons/accident.svg';
    }
    if (k.contains('sand')) {
      return 'assets/icons/sandtheft.svg';
    }
    if (k.contains('wheeler') || k.contains('motor')) {
      return 'assets/icons/2-4wheeler.svg';
    }
    if (k.contains('women') || k.contains('woman')) {
      return 'assets/icons/crimewomen.svg';
    }
    if (k.contains('theft')) {
      return 'assets/icons/theft.svg';
    }
    if (k.contains('hurt')) {
      return 'assets/icons/hurt.svg';
    }
    if (k.contains('kidnap')) {
      return 'assets/icons/kidnapping.svg';
    }
    if (k.contains('missing')) {
      return 'assets/icons/missing.svg';
    }
    if (k.contains('coin')) {
      return 'assets/icons/coin.svg';
    }
    if (k.contains('drug') || k.contains('ndps')) {
      return 'assets/icons/ndps.svg';
    }
    if (k.contains('gambl')) {
      return 'assets/icons/gambling.svg';
    }
    if (k.contains('pocso')) {
      return 'assets/icons/pocso.svg';
    }
    if (k.contains('cow') || k.contains('gowan')) {
      return 'assets/icons/gowans.svg';
    }
    if (k.contains('cyber') || k.contains('it act')) {
      return 'assets/icons/itact.svg';
    }
    if (k.contains('mv act') || k.contains('traffic')) {
      return 'assets/icons/mvact.svg';
    }

    return null;
  }

  /// Returns fallback [IconData] when no SVG exists.
  static IconData getIcon(String category) {
    final normalized = category.trim().toLowerCase();

    switch (normalized) {
      case 'murder':
        return Icons.dangerous_rounded;
      case 'attempt to murder':
        return Icons.warning_amber_rounded;
      case 'hbt':
      case 'house breaking':
        return Icons.home_work_rounded;
      case 'riot':
        return Icons.campaign_rounded;
      case 'unlawful assembly':
        return Icons.group_remove_rounded;
      case 'cbt':
        return Icons.article_rounded;
      case 'cheating':
        return Icons.description_rounded;
      case 'mischief':
        return Icons.report_rounded;
      case 'assault on public servant':
        return Icons.badge_rounded;
      case 'rape':
        return Icons.shield_rounded;
      case 'molestation':
        return Icons.front_hand_rounded;
      case 'extortion':
        return Icons.request_quote_rounded;
      case 'other ipc':
      case 'ipc':
        return Icons.balance_rounded;
      case 'suicide':
        return Icons.local_hospital_rounded;
      case 'sec 156(3)/175 (3)(bnss)':
      case 'sec 156(3)/175(3)(bnss)':
      case 'sec 156(3)/175(3)':
        return Icons.policy_rounded;
      case 'all':
      case 'all cases':
        return Icons.grid_view_rounded;
      default:
        return Icons.balance_rounded;
    }
  }

  /// Builds the icon widget matching dashboard styling (SVG first, Icon fallback).
  static Widget buildWidget(
    String category, {
    required Color color,
    double size = 22,
  }) {
    final svg = getSvgPath(category);
    if (svg != null) {
      return Center(
        child: SvgPicture.asset(
          svg,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      );
    }
    return Center(
      child: Icon(
        getIcon(category),
        size: size,
        color: color,
      ),
    );
  }

  /// Legacy builder for IconData instances.
  static Widget buildIcon(
    IconData icon, {
    required Color color,
    double size = 20,
  }) {
    return Center(
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
}
