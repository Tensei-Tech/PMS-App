// lib/providers/news_provider.dart
// Manages the carousel news/law-update announcements shown on the dashboard.

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';

class NewsItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String iconName;
  final int iconColorHex;
  final String
  tag; // e.g. "New Law", "Circular", "Amendment", "Alert", "Notice"
  final int order;
  final DateTime? updatedAt;

  const NewsItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.iconName = 'info',
    required this.iconColorHex,
    required this.tag,
    this.order = 0,
    this.updatedAt,
  });

  static IconData iconFromName(String? name) {
    switch (name?.toLowerCase().trim()) {
      case 'gavel':
        return Icons.gavel_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'videocam':
        return Icons.videocam_rounded;
      case 'security':
        return Icons.security_rounded;
      case 'campaign':
        return Icons.campaign_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'policy':
        return Icons.policy_rounded;
      case 'article':
        return Icons.article_rounded;
      case 'local_police':
        return Icons.local_police_rounded;
      case 'handshake':
        return Icons.handshake_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  factory NewsItem.fromMap(String docId, Map<String, dynamic> map) {
    final name =
        map['icon_name']?.toString() ??
        map['iconName']?.toString() ??
        'article';
    final colorHex = map['iconColorHex'] is int
        ? map['iconColorHex'] as int
        : (int.tryParse(
                map['icon_color_hex']?.toString() ??
                    map['iconColorHex']?.toString() ??
                    '',
              ) ??
              0xFF1976D2);

    DateTime? updated;
    if (map['updatedAt'] != null || map['updated_at'] != null) {
      final raw = map['updatedAt'] ?? map['updated_at'];
      if (raw is DateTime) {
        updated = raw;
      } else if (raw is String) {
        updated = DateTime.tryParse(raw);
      }
    }

    return NewsItem(
      id: docId,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      iconName: name,
      icon: iconFromName(name),
      iconColorHex: colorHex,
      tag: map['tag']?.toString() ?? 'Notice',
      order: (map['order'] is num) ? (map['order'] as num).toInt() : 0,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'iconName': iconName,
      'iconColorHex': iconColorHex,
      'tag': tag,
      'order': order,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  NewsItem copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    String? iconName,
    int? iconColorHex,
    String? tag,
    int? order,
    DateTime? updatedAt,
  }) {
    return NewsItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      iconName: iconName ?? this.iconName,
      iconColorHex: iconColorHex ?? this.iconColorHex,
      tag: tag ?? this.tag,
      order: order ?? this.order,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Fallback static news items shown when offline or initializing
const List<NewsItem> defaultNewsItems = [
  NewsItem(
    id: 'bnss_2023',
    title: 'Bhartiya Nagarik Suraksha Sanhita (BNSS) 2023 Guidelines',
    description:
        'New procedural mandatory timelines for FIR registration, forensic data collection, and electronic evidence recording are now enforced state-wide.',
    icon: Icons.gavel_rounded,
    iconName: 'gavel',
    iconColorHex: 0xFF1565C0, // Blue
    tag: 'New Law',
    order: 1,
  ),
  NewsItem(
    id: 'zero_fir',
    title: 'Mandatory Zero FIR Registration Directive',
    description:
        'All police stations must register Zero FIR immediately upon receipt of cognizable offense complaints, regardless of territorial jurisdiction.',
    icon: Icons.shield_rounded,
    iconName: 'shield',
    iconColorHex: 0xFFD32F2F, // Red
    tag: 'Directive',
    order: 2,
  ),
  NewsItem(
    id: 'e_evidence',
    title: 'Section 63 BSA Electronic Evidence Certification',
    description:
        'All digital evidence, CCTV recordings, and call logs must be accompanied by mandatory Section 63 Certificate (formerly 65B) at the time of charge-sheet submission.',
    icon: Icons.videocam_rounded,
    iconName: 'videocam',
    iconColorHex: 0xFF2E7D32, // Green
    tag: 'Circular',
    order: 3,
  ),
  NewsItem(
    id: 'cyber_sop',
    title: 'Standard Operating Procedure for Online Financial Frauds',
    description:
        'Immediate freezing of beneficiary accounts through 1930 Portal Integration within the first Golden Hour is now mandatory for IOs.',
    icon: Icons.security_rounded,
    iconName: 'security',
    iconColorHex: 0xFFED6C02, // Orange
    tag: 'SOP Update',
    order: 4,
  ),
  NewsItem(
    id: 'posh_guidelines',
    title: 'Enhanced Safety Protocol & FAST-Track Chargesheets',
    description:
        'Cases involving crimes against women and children require mandatory completion of investigation within 60 days under BNSS Section 193.',
    icon: Icons.campaign_rounded,
    iconName: 'campaign',
    iconColorHex: 0xFF7B1FA2, // Purple
    tag: 'Important Notice',
    order: 5,
  ),
];

class NewsProvider extends ChangeNotifier {
  List<NewsItem> _items = List.of(defaultNewsItems);
  bool _isLoading = false;
  String? _errorMessage;

  NewsProvider() {
    fetchAnnouncements();
  }

  List<NewsItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch announcements from Django REST API backend
  Future<void> fetchAnnouncements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService().get(ApiConfig.announcements);
      if (res.statusCode == 200 &&
          res.data is List &&
          (res.data as List).isNotEmpty) {
        _items = (res.data as List)
            .map(
              (item) => NewsItem.fromMap(
                item['id'].toString(),
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('[NewsProvider] Error fetching announcements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Master Admin creates a new announcement
  Future<void> addAnnouncement(NewsItem item) async {
    try {
      final payload = {
        'title': item.title,
        'description': item.description,
        'icon_name': item.iconName,
        'icon_color_hex': item.iconColorHex.toRadixString(16),
        'tag': item.tag,
        'order': item.order,
        'is_active': true,
      };
      await ApiService().post(ApiConfig.announcements, data: payload);
      await fetchAnnouncements();
    } catch (e) {
      debugPrint('[NewsProvider] Error adding announcement: $e');
      _items.add(item);
      notifyListeners();
    }
  }

  /// Master Admin updates an existing announcement
  Future<void> updateAnnouncement(NewsItem item) async {
    try {
      final payload = {
        'title': item.title,
        'description': item.description,
        'icon_name': item.iconName,
        'icon_color_hex': item.iconColorHex.toRadixString(16),
        'tag': item.tag,
        'order': item.order,
      };
      await ApiService().put(
        '${ApiConfig.announcements}${item.id}/',
        data: payload,
      );
      await fetchAnnouncements();
    } catch (e) {
      debugPrint('[NewsProvider] Error updating announcement: $e');
      final idx = _items.indexWhere((i) => i.id == item.id);
      if (idx >= 0) {
        _items[idx] = item;
        notifyListeners();
      }
    }
  }

  /// Master Admin deletes an announcement
  Future<void> deleteAnnouncement(String id) async {
    try {
      await ApiService().delete('${ApiConfig.announcements}$id/');
      await fetchAnnouncements();
    } catch (e) {
      debugPrint('[NewsProvider] Error deleting announcement: $e');
      _items.removeWhere((i) => i.id == id);
      if (_items.isEmpty) {
        _items = List.of(defaultNewsItems);
      }
      notifyListeners();
    }
  }

  /// Reset to defaults
  Future<void> seedDefaultsToFirestore() async {
    _items = List.of(defaultNewsItems);
    notifyListeners();
  }
}
