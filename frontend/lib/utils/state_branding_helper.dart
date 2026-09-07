// lib/utils/state_branding_helper.dart
// Dynamic state police branding, motto, emblem badges, and state collaboration helper.

import 'package:flutter/material.dart';

class StateBrandingInfo {
  final String stateCode;
  final String stateName;
  final String policeForceTitle;
  final String shortForceTitle;
  final String motto;
  final String mottoEnglish;
  final IconData emblemIcon;
  final String? logoAssetPath;
  final Color primaryColor;
  final Color accentColor;

  const StateBrandingInfo({
    required this.stateCode,
    required this.stateName,
    required this.policeForceTitle,
    String? shortForceTitle,
    required this.motto,
    required this.mottoEnglish,
    this.emblemIcon = Icons.security_rounded,
    this.logoAssetPath,
    this.primaryColor = const Color(0xFF0A2540),
    this.accentColor = const Color(0xFFFFB703),
  }) : shortForceTitle = shortForceTitle ?? '$stateCode Police';
}

class StateBrandingHelper {
  static const Map<String, StateBrandingInfo> _knownStates = {
    'MH': StateBrandingInfo(
      stateCode: 'MH',
      stateName: 'Maharashtra',
      policeForceTitle: 'Maharashtra Police',
      motto: 'सद्रक्षणाय खलनिग्रहणाय',
      mottoEnglish: 'To protect the good and punish the evil',
      emblemIcon: Icons.shield_rounded,
      logoAssetPath: 'assets/icons/maharashtra_police_logo.jpg',
      primaryColor: Color(0xFF0A2540),
      accentColor: Color(0xFFFFB703),
    ),
    'GJ': StateBrandingInfo(
      stateCode: 'GJ',
      stateName: 'Gujarat',
      policeForceTitle: 'Gujarat Police',
      motto: 'सेवा शांति सुरक्षा',
      mottoEnglish: 'Service, Peace, Security',
      emblemIcon: Icons.local_police_rounded,
      primaryColor: Color(0xFF1A237E),
      accentColor: Color(0xFFFF9800),
    ),
    'KA': StateBrandingInfo(
      stateCode: 'KA',
      stateName: 'Karnataka',
      policeForceTitle: 'Karnataka State Police',
      motto: 'ಕರ್ತವ್ಯ ನಿಷ್ಠೆ',
      mottoEnglish: 'Duty and Fidelity',
      emblemIcon: Icons.security_rounded,
      primaryColor: Color(0xFF4A148C),
      accentColor: Color(0xFFFFD54F),
    ),
    'DL': StateBrandingInfo(
      stateCode: 'DL',
      stateName: 'Delhi',
      policeForceTitle: 'Delhi Police',
      motto: 'शांति सेवा न्याय',
      mottoEnglish: 'Peace, Service, Justice',
      emblemIcon: Icons.verified_user_rounded,
      primaryColor: Color(0xFFB71C1C),
      accentColor: Color(0xFF2196F3),
    ),
    'MP': StateBrandingInfo(
      stateCode: 'MP',
      stateName: 'Madhya Pradesh',
      policeForceTitle: 'MP Police',
      motto: 'देश भक्ति, जन सेवा',
      mottoEnglish: 'Patriotism and Public Service',
      emblemIcon: Icons.policy_rounded,
      primaryColor: Color(0xFF3E2723),
      accentColor: Color(0xFFFFB300),
    ),
    'RJ': StateBrandingInfo(
      stateCode: 'RJ',
      stateName: 'Rajasthan',
      policeForceTitle: 'Rajasthan Police',
      motto: 'सेवा परमो धर्म:',
      mottoEnglish: 'Service is Supreme Duty',
      emblemIcon: Icons.shield_outlined,
      primaryColor: Color(0xFFE65100),
      accentColor: Color(0xFFFFD54F),
    ),
    'UP': StateBrandingInfo(
      stateCode: 'UP',
      stateName: 'Uttar Pradesh',
      policeForceTitle: 'UP Police',
      motto: 'सुरक्षा आपकी, संकल्प हमारा',
      mottoEnglish: 'Your Safety, Our Resolve',
      emblemIcon: Icons.gavel_rounded,
      primaryColor: Color(0xFF880E4F),
      accentColor: Color(0xFFFFC107),
    ),
    'TN': StateBrandingInfo(
      stateCode: 'TN',
      stateName: 'Tamil Nadu',
      policeForceTitle: 'Tamil Nadu Police',
      motto: 'வாய்மையே வெல்லும்',
      mottoEnglish: 'Truth Alone Triumphs',
      emblemIcon: Icons.military_tech_rounded,
      primaryColor: Color(0xFF004D40),
      accentColor: Color(0xFFFFB703),
    ),
    'KL': StateBrandingInfo(
      stateCode: 'KL',
      stateName: 'Kerala',
      policeForceTitle: 'Kerala Police',
      motto: 'மிருது பாவே த்ருட க்ருத்யே',
      mottoEnglish: 'Soft in Manner, Firm in Action',
      emblemIcon: Icons.admin_panel_settings_rounded,
      primaryColor: Color(0xFF1B5E20),
      accentColor: Color(0xFFFFD54F),
    ),
  };

  /// Get state branding info dynamically based on state code or name
  static StateBrandingInfo getBranding(String? stateCodeOrName) {
    if (stateCodeOrName == null || stateCodeOrName.trim().isEmpty) {
      return _knownStates['MH']!;
    }

    final code = stateCodeOrName.trim().toUpperCase();
    if (_knownStates.containsKey(code)) {
      return _knownStates[code]!;
    }

    // Try finding by state name matching
    for (final info in _knownStates.values) {
      if (info.stateName.toLowerCase() ==
          stateCodeOrName.trim().toLowerCase()) {
        return info;
      }
    }

    // Dynamic fallback for any state
    final name = stateCodeOrName.trim();
    return StateBrandingInfo(
      stateCode: code.length <= 4 ? code : 'ST',
      stateName: name,
      policeForceTitle: name.endsWith('Police') ? name : '$name Police',
      motto: 'जन सेवा, सुरक्षा, कर्तव्य',
      mottoEnglish: 'Public Service, Security, Duty',
      emblemIcon: Icons.shield_rounded,
    );
  }
}
