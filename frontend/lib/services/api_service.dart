import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'api_config.dart';

/// Response wrapper for API calls
class ApiResponse {
  final bool isSuccess;
  final int statusCode;
  final dynamic data;
  final String? errorMessage;

  ApiResponse({
    required this.isSuccess,
    required this.statusCode,
    this.data,
    this.errorMessage,
  });

  factory ApiResponse.success(dynamic data, {int statusCode = 200}) {
    return ApiResponse(
      isSuccess: true,
      statusCode: statusCode,
      data: data,
    );
  }

  factory ApiResponse.error(String message, {int statusCode = 500}) {
    return ApiResponse(
      isSuccess: false,
      statusCode: statusCode,
      errorMessage: message,
    );
  }
}

/// Service class for interacting with the Django REST API backend
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _secureStorage = const FlutterSecureStorage();

  /// Retrieve active Auth token (Firebase ID token or backend JWT token)
  Future<String?> _getAuthToken() async {
    try {
      // 1. Try Firebase Auth current user ID token
      final fbUser = fb.FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        final token = await fbUser.getIdToken();
        if (token != null && token.isNotEmpty) {
          return token;
        }
      }

      // 2. Fallback to stored Django JWT access token
      final jwtToken = await _secureStorage.read(key: ApiConstants.jwtAccessTokenKey);
      if (jwtToken != null && jwtToken.isNotEmpty) {
        return jwtToken;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ApiService] Error retrieving auth token: $e');
    }
    return null;
  }

  /// Helper to build standard HTTP headers
  Future<Map<String, String>> _buildHeaders({Map<String, String>? customHeaders}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await _getAuthToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  /// Perform a GET request
  Future<ApiResponse> get(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      Uri uri = Uri.parse(url);
      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters.map((k, v) => MapEntry(k, v.toString())));
      }

      final requestHeaders = await _buildHeaders(customHeaders: headers);
      final response = await http.get(uri, headers: requestHeaders).timeout(ApiConstants.receiveTimeout);

      return _processResponse(response);
    } on SocketException {
      return ApiResponse.error('No Internet connection or server unavailable.', statusCode: 503);
    } on http.ClientException catch (e) {
      return ApiResponse.error('Network client error: ${e.message}', statusCode: 500);
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e', statusCode: 500);
    }
  }

  /// Perform a POST request
  Future<ApiResponse> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final uri = Uri.parse(url);
      final requestHeaders = await _buildHeaders(customHeaders: headers);
      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await http
          .post(uri, headers: requestHeaders, body: encodedBody)
          .timeout(ApiConstants.receiveTimeout);

      return _processResponse(response);
    } on SocketException {
      return ApiResponse.error('No Internet connection or server unavailable.', statusCode: 503);
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e', statusCode: 500);
    }
  }

  /// Perform a PUT request
  Future<ApiResponse> put(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final uri = Uri.parse(url);
      final requestHeaders = await _buildHeaders(customHeaders: headers);
      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await http
          .put(uri, headers: requestHeaders, body: encodedBody)
          .timeout(ApiConstants.receiveTimeout);

      return _processResponse(response);
    } on SocketException {
      return ApiResponse.error('No Internet connection or server unavailable.', statusCode: 503);
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e', statusCode: 500);
    }
  }

  /// Perform a PATCH request
  Future<ApiResponse> patch(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final uri = Uri.parse(url);
      final requestHeaders = await _buildHeaders(customHeaders: headers);
      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await http
          .patch(uri, headers: requestHeaders, body: encodedBody)
          .timeout(ApiConstants.receiveTimeout);

      return _processResponse(response);
    } on SocketException {
      return ApiResponse.error('No Internet connection or server unavailable.', statusCode: 503);
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e', statusCode: 500);
    }
  }

  /// Perform a DELETE request
  Future<ApiResponse> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(url);
      final requestHeaders = await _buildHeaders(customHeaders: headers);

      final response = await http.delete(uri, headers: requestHeaders).timeout(ApiConstants.receiveTimeout);

      return _processResponse(response);
    } on SocketException {
      return ApiResponse.error('No Internet connection or server unavailable.', statusCode: 503);
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e', statusCode: 500);
    }
  }

  /// Check connectivity and health of Django backend API
  Future<bool> checkHealth() async {
    try {
      final response = await get(ApiConfig.baseUrl);
      // Even 404 or 401 means server is up and listening
      return response.statusCode != 503 && response.statusCode != 0;
    } catch (_) {
      return false;
    }
  }

  /// Process HTTP response into ApiResponse model
  ApiResponse _processResponse(http.Response response) {
    dynamic bodyData;
    if (response.body.isNotEmpty) {
      try {
        bodyData = jsonDecode(response.body);
      } catch (_) {
        bodyData = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse.success(bodyData, statusCode: response.statusCode);
    } else {
      String message = 'HTTP Error ${response.statusCode}';
      if (bodyData is Map && bodyData.containsKey('detail')) {
        message = bodyData['detail'].toString();
      } else if (bodyData is Map && bodyData.containsKey('error')) {
        message = bodyData['error'].toString();
      } else if (bodyData is String) {
        message = bodyData;
      }
      return ApiResponse.error(message, statusCode: response.statusCode);
    }
  }
}
