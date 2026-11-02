import 'package:flutter/material.dart';

import 'category_subtabs_screen.dart';
import 'disposal_hub_screen.dart';

/// The dashboard's Disposal tile: Form 1 to 5 and Form 6,
/// formatted as sub-tabs matching NAFIS/Fingerprint, DAR/IRAD, and Passport/PVR/Licence.
/// Opens on Form 1 to 5 with a switch to Form 6; each shows the Disposal Hub
/// (Case Wise, Time Wise, IO Wise) filtered by that group.
class DisposalSelectionScreen extends StatelessWidget {
  final String stationName;

  const DisposalSelectionScreen({super.key, required this.stationName});

  static const String title = 'Disposal';

  @override
  Widget build(BuildContext context) {
    return ModuleTabsScreen(
      title: title,
      tabs: [
        (
          'Form 1 to 5',
          Icons.description_rounded,
          (_) => DisposalHubScreen(
                stationName: stationName,
                groupId: 1,
                groupTitle: 'Form 1 to 5',
              ),
        ),
        (
          'Form 6',
          Icons.gavel_rounded,
          (_) => DisposalHubScreen(
                stationName: stationName,
                groupId: 2,
                groupTitle: 'Form 6',
              ),
        ),
      ],
    );
  }
}
