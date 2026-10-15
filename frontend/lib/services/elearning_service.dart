import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'api_service.dart';

class ELearningRecord {
  final String id;
  final String officerUid;
  final String officerName;
  final String badgeNumber;
  final String designation;
  final String stationName;
  final String district;
  final String courseName;
  final String platform;
  final String status;
  final String dateOfCompletion;
  final String certificateNo;
  final String? certificateUrl;
  final String remarks;

  ELearningRecord({
    required this.id,
    required this.officerUid,
    required this.officerName,
    required this.badgeNumber,
    required this.designation,
    required this.stationName,
    required this.district,
    required this.courseName,
    required this.platform,
    required this.status,
    required this.dateOfCompletion,
    required this.certificateNo,
    this.certificateUrl,
    required this.remarks,
  });

  factory ELearningRecord.fromJson(Map<String, dynamic> json) {
    return ELearningRecord(
      id: json['id']?.toString() ?? '',
      officerUid: json['officer_uid']?.toString() ?? '',
      officerName: json['officer_name']?.toString() ?? 'Police Personnel',
      badgeNumber: json['badge_number']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      stationName: json['station_name']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      courseName: json['course_name']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Completed',
      dateOfCompletion: json['date_of_completion']?.toString() ?? '',
      certificateNo: json['certificate_no']?.toString() ?? '',
      certificateUrl: json['certificate_url']?.toString(),
      remarks: json['remarks']?.toString() ?? '',
    );
  }
}

class InchargeAnalyticsSummary {
  final int totalStationPersonnel;
  final int personnelCompletedAtLeastOne;
  final int personnelNotCompletedAny;
  final int totalCourseCompletions;
  final double completionPercentage;

  InchargeAnalyticsSummary({
    required this.totalStationPersonnel,
    required this.personnelCompletedAtLeastOne,
    required this.personnelNotCompletedAny,
    required this.totalCourseCompletions,
    required this.completionPercentage,
  });

  factory InchargeAnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return InchargeAnalyticsSummary(
      totalStationPersonnel:
          (json['total_station_personnel'] as num?)?.toInt() ?? 0,
      personnelCompletedAtLeastOne:
          (json['personnel_completed_at_least_one'] as num?)?.toInt() ?? 0,
      personnelNotCompletedAny:
          (json['personnel_not_completed_any'] as num?)?.toInt() ?? 0,
      totalCourseCompletions:
          (json['total_course_completions'] as num?)?.toInt() ?? 0,
      completionPercentage:
          (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OfficerCompletionStat {
  final String officerUid;
  final String officerName;
  final String badgeNumber;
  final String designation;
  final String stationName;
  final int completedCoursesCount;

  OfficerCompletionStat({
    required this.officerUid,
    required this.officerName,
    required this.badgeNumber,
    required this.designation,
    required this.stationName,
    required this.completedCoursesCount,
  });

  factory OfficerCompletionStat.fromJson(Map<String, dynamic> json) {
    return OfficerCompletionStat(
      officerUid: json['officer_uid']?.toString() ?? '',
      officerName: json['officer_name']?.toString() ?? 'Officer',
      badgeNumber: json['badge_number']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      stationName: json['station_name']?.toString() ?? '',
      completedCoursesCount:
          (json['completed_courses_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class OfficerNotDoneStat {
  final String officerUid;
  final String officerName;
  final String badgeNumber;
  final String designation;
  final String stationName;
  final String status;

  OfficerNotDoneStat({
    required this.officerUid,
    required this.officerName,
    required this.badgeNumber,
    required this.designation,
    required this.stationName,
    required this.status,
  });

  factory OfficerNotDoneStat.fromJson(Map<String, dynamic> json) {
    return OfficerNotDoneStat(
      officerUid: json['officer_uid']?.toString() ?? '',
      officerName: json['officer_name']?.toString() ?? 'Officer',
      badgeNumber: json['badge_number']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      stationName: json['station_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Not Completed Any Course',
    );
  }
}

class InchargeAnalyticsResponse {
  final String stationName;
  final InchargeAnalyticsSummary summary;
  final List<OfficerCompletionStat> individualCompletions;
  final List<OfficerNotDoneStat> officersNotCompleted;

  InchargeAnalyticsResponse({
    required this.stationName,
    required this.summary,
    required this.individualCompletions,
    required this.officersNotCompleted,
  });

  factory InchargeAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};
    final completionsList =
        (json['individual_officer_completions'] as List<dynamic>?) ?? [];
    final notCompletedList =
        (json['officers_not_completed'] as List<dynamic>?) ?? [];

    return InchargeAnalyticsResponse(
      stationName: json['station_name']?.toString() ?? '',
      summary: InchargeAnalyticsSummary.fromJson(summaryJson),
      individualCompletions: completionsList
          .map((item) =>
              OfficerCompletionStat.fromJson(item as Map<String, dynamic>))
          .toList(),
      officersNotCompleted: notCompletedList
          .map((item) =>
              OfficerNotDoneStat.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CourseEntry {
  final String id;
  final String name;
  final String platform;
  final String description;
  final String category;
  final double? durationHours;
  final bool isMandatory;

  CourseEntry({
    required this.id,
    required this.name,
    required this.platform,
    required this.description,
    required this.category,
    this.durationHours,
    required this.isMandatory,
  });

  factory CourseEntry.fromJson(Map<String, dynamic> json) {
    return CourseEntry(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      platform: json['platform']?.toString() ?? 'iGOT Karmayogi',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      durationHours: (json['duration_hours'] as num?)?.toDouble(),
      isMandatory: json['is_mandatory'] as bool? ?? true,
    );
  }
}

class ELearningService {
  static final ELearningService _instance = ELearningService._internal();
  factory ELearningService() => _instance;
  ELearningService._internal();

  final ApiService _api = ApiService();

  /// Fetch course completion records with serial numbers
  Future<List<ELearningRecord>> fetchRecords({
    String? station,
    String? officerUid,
    String? courseName,
    String? platform,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (station != null && station.isNotEmpty) {
        queryParams['station'] = station;
      }
      if (officerUid != null && officerUid.isNotEmpty) {
        queryParams['officer_uid'] = officerUid;
      }
      if (courseName != null && courseName.isNotEmpty) {
        queryParams['course_name'] = courseName;
      }
      if (platform != null && platform.isNotEmpty) {
        queryParams['platform'] = platform;
      }

      final res = await _api.get(
        ApiConfig.elearningRecords,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (res.isSuccess && res.data != null) {
        List<dynamic> rawList = [];
        if (res.data is List) {
          rawList = res.data;
        } else if (res.data is Map && res.data['results'] is List) {
          rawList = res.data['results'];
        }
        return rawList
            .map((e) => ELearningRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ELearningService] fetchRecords error: $e');
    }
    return [];
  }

  /// Submit course completion for the currently authenticated officer
  /// The user's inbuilt name is automatically populated by the backend session
  Future<bool> submitCourseCompletion({
    required String courseName,
    required String platform,
    required String dateOfCompletion,
    String? certificateNo,
    String? remarks,
  }) async {
    try {
      final payload = {
        'course_name': courseName,
        'platform': platform,
        'date_of_completion': dateOfCompletion,
        if (certificateNo != null && certificateNo.isNotEmpty)
          'certificate_no': certificateNo,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      };

      final res = await _api.post(
        ApiConfig.elearningSubmit,
        body: payload,
      );

      return res.isSuccess;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ELearningService] submitCourseCompletion error: $e');
      }
      return false;
    }
  }

  /// Incharge Analytics for Police Station
  Future<InchargeAnalyticsResponse?> fetchInchargeAnalytics(
      {String? station}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (station != null && station.isNotEmpty) {
        queryParams['station'] = station;
      }

      final res = await _api.get(
        ApiConfig.elearningAnalytics,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (res.isSuccess &&
          res.data != null &&
          res.data is Map<String, dynamic>) {
        return InchargeAnalyticsResponse.fromJson(
            res.data as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ELearningService] fetchInchargeAnalytics error: $e');
      }
    }
    return null;
  }

  /// Fetch course catalog (available courses for the station)
  Future<List<CourseEntry>> fetchCourses(
      {String? platform, String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (platform != null && platform.isNotEmpty) {
        queryParams['platform'] = platform;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final res = await _api.get(
        ApiConfig.elearningCourses,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (res.isSuccess && res.data != null) {
        List<dynamic> rawList = [];
        if (res.data is List) {
          rawList = res.data;
        } else if (res.data is Map && res.data['results'] is List) {
          rawList = res.data['results'];
        }
        return rawList
            .map((e) => CourseEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ELearningService] fetchCourses error: $e');
    }
    return [];
  }

  /// Create a new course in the catalog (Admin/Incharge only)
  Future<bool> createCourse({
    required String name,
    required String platform,
    String description = '',
    String category = 'General',
    double? durationHours,
    bool isMandatory = true,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name,
        'platform': platform,
        'description': description,
        'category': category,
        'is_mandatory': isMandatory,
        if (durationHours != null) 'duration_hours': durationHours,
      };

      final res = await _api.post(
        ApiConfig.elearningCourses,
        body: payload,
      );

      return res.isSuccess;
    } catch (e) {
      if (kDebugMode) debugPrint('[ELearningService] createCourse error: $e');
      return false;
    }
  }
}
