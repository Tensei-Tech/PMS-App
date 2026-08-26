// lib/providers/case_provider.dart
import 'package:flutter/material.dart';
import '../services/backend_case_service.dart';

class CaseRecord {
  final String id;
  final String title;
  final String category;
  final String description;
  final String caseNumber;
  final String complainant;
  final String accused;
  final String location;
  final DateTime incidentDate;
  final String priority;
  final String status;
  final String assignedOfficer;

  CaseRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.caseNumber,
    required this.complainant,
    required this.accused,
    required this.location,
    required this.incidentDate,
    required this.priority,
    required this.status,
    required this.assignedOfficer,
  });

  factory CaseRecord.fromMap(Map<String, dynamic> map) {
    return CaseRecord(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? map['case_number'] ?? 'Untitled Case',
      category: map['category'] ?? map['crime_type'] ?? 'General',
      description: map['description'] ?? '',
      caseNumber: map['case_number'] ?? map['case_no'] ?? '',
      complainant: map['complainant_name'] ?? map['complainant'] ?? '',
      accused: map['accused_name'] ?? map['accused'] ?? '',
      location: map['location'] ?? map['crime_location'] ?? '',
      incidentDate: map['incident_date'] != null
          ? DateTime.tryParse(map['incident_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      priority: map['priority'] ?? 'Medium',
      status: map['status'] ?? 'Open',
      assignedOfficer: map['assigned_officer'] ?? map['assigned_officer_name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'case_number': caseNumber,
      'title': title,
      'category': category,
      'description': description,
      'complainant_name': complainant,
      'accused_name': accused,
      'location': location,
      'incident_date': incidentDate.toIso8601String(),
      'priority': priority,
      'status': status,
      'assigned_officer_name': assignedOfficer,
    };
  }

  CaseRecord copyWith({
    String? title,
    String? category,
    String? description,
    String? caseNumber,
    String? complainant,
    String? accused,
    String? location,
    DateTime? incidentDate,
    String? priority,
    String? status,
    String? assignedOfficer,
  }) {
    return CaseRecord(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      caseNumber: caseNumber ?? this.caseNumber,
      complainant: complainant ?? this.complainant,
      accused: accused ?? this.accused,
      location: location ?? this.location,
      incidentDate: incidentDate ?? this.incidentDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedOfficer: assignedOfficer ?? this.assignedOfficer,
    );
  }
}

class CaseProvider extends ChangeNotifier {
  final BackendCaseService _backendService = BackendCaseService();
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final List<CaseRecord> _cases = [
    CaseRecord(
      id: '1',
      title: 'Theft at Market Road',
      caseNumber: 'FIR/2024/0451',
      category: 'Theft',
      description: 'Laptops and electronics stolen from a shop at midnight.',
      complainant: 'John Doe',
      accused: 'Unknown',
      location: 'Market Road, Sector 4',
      incidentDate: DateTime.now().subtract(const Duration(days: 1)),
      priority: 'High',
      status: 'Open',
      assignedOfficer: 'SI Ramesh',
    ),
    CaseRecord(
      id: '2',
      title: 'Missing Person Report',
      caseNumber: 'FIR/2024/0448',
      category: 'Missing',
      description: 'A 12-year old boy missing since yesterday evening.',
      complainant: 'Sara Smith',
      accused: 'N/A',
      location: 'Green Park colony',
      incidentDate: DateTime.now().subtract(const Duration(days: 2)),
      priority: 'High',
      status: 'Active',
      assignedOfficer: 'SI Priya',
    ),
    CaseRecord(
      id: '3',
      title: 'Road Dispute & Hurt',
      caseNumber: 'FIR/2024/0445',
      category: 'Hurt',
      description: 'Fight occurred between two drivers regarding parking.',
      complainant: 'Michael Ross',
      accused: 'Harvey Specter',
      location: 'Lawyer Street',
      incidentDate: DateTime.now().subtract(const Duration(days: 3)),
      priority: 'Medium',
      status: 'Resolved',
      assignedOfficer: 'SI Kumar',
    ),
  ];

  List<CaseRecord> get allCases => List.unmodifiable(_cases);

  List<CaseRecord> getCasesByCategory(String category) {
    if (category == 'Form I-V' || category == 'Form VI') {
      return _cases.where((c) => c.category == category || c.category == 'Theft').toList();
    }
    return _cases.where((c) => c.category == category).toList();
  }

  /// Sync case records from Django REST backend API
  Future<void> syncFromBackend({String? stationName, String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteCasesData = await _backendService.fetchCases(
        stationName: stationName,
        status: status,
      );

      if (remoteCasesData != null && remoteCasesData.isNotEmpty) {
        final remoteCases = remoteCasesData.map((data) => CaseRecord.fromMap(data)).toList();
        
        // Merge or update local list
        for (var remoteCase in remoteCases) {
          final index = _cases.indexWhere((c) => c.id == remoteCase.id || c.caseNumber == remoteCase.caseNumber);
          if (index != -1) {
            _cases[index] = remoteCase;
          } else {
            _cases.insert(0, remoteCase);
          }
        }
      }
    } catch (e) {
      _errorMessage = 'Could not sync cases from backend server.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCase(CaseRecord newCase) async {
    _cases.insert(0, newCase);
    notifyListeners();

    // Try posting to Django backend asynchronously
    try {
      final created = await _backendService.createCase(newCase.toMap());
      if (created != null && created.containsKey('id')) {
        final idx = _cases.indexWhere((c) => c.id == newCase.id || c.caseNumber == newCase.caseNumber);
        if (idx != -1) {
          _cases[idx] = CaseRecord.fromMap(created);
          notifyListeners();
        }
      }
    } catch (_) {
      // Retained in local memory list safely
    }
  }

  Future<void> updateCase(CaseRecord updatedCase) async {
    final index = _cases.indexWhere((c) => c.id == updatedCase.id);
    if (index != -1) {
      _cases[index] = updatedCase;
      notifyListeners();
    }

    try {
      await _backendService.updateCase(updatedCase.id, updatedCase.toMap());
    } catch (_) {}
  }

  Future<void> deleteCase(String id) async {
    _cases.removeWhere((c) => c.id == id);
    notifyListeners();

    try {
      await _backendService.deleteCase(id);
    } catch (_) {}
  }
}
