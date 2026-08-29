import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'api_config.dart';
import 'secure_storage.dart';

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

/// Core API Service handling HTTP operations for Django REST framework.
class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  final _secureStorage = SecureStorage.instance;
  static String? _cachedAuthToken;

  /// Explicitly set the active JWT token in-memory and in secure storage
  Future<void> setAuthToken(String token) async {
    _cachedAuthToken = token;
    await _secureStorage.write(key: ApiConstants.jwtAccessTokenKey, value: token);
  }

  /// Explicitly clear the active JWT token
  Future<void> clearAuthToken() async {
    _cachedAuthToken = null;
    await _secureStorage.delete(key: ApiConstants.jwtAccessTokenKey);
  }

  /// Retrieve active Auth token (backend JWT token)
  Future<String?> getAuthToken() async {
    return _getAuthToken();
  }

  /// Check if a JWT token is expired based on its 'exp' claim
  bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      String payload = parts[1];
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final data = json.decode(decoded) as Map<String, dynamic>;
      if (!data.containsKey('exp')) return false;
      final exp = data['exp'] as num;
      final nowSec = DateTime.now().millisecondsSinceEpoch / 1000;
      return nowSec >= exp;
    } catch (_) {
      return false;
    }
  }

  /// Retrieve active Auth token (backend JWT token)
  Future<String?> _getAuthToken() async {
    if (_cachedAuthToken != null && _cachedAuthToken!.isNotEmpty) {
      return _cachedAuthToken;
    }
    try {
      final jwtToken = await _secureStorage.read(key: ApiConstants.jwtAccessTokenKey);
      if (jwtToken != null && jwtToken.isNotEmpty) {
        _cachedAuthToken = jwtToken;
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
    dynamic data,
  }) async {
    try {
      final uri = Uri.parse(url);
      final requestHeaders = await _buildHeaders(customHeaders: headers);
      final rawBody = data ?? body;
      final encodedBody = rawBody != null ? jsonEncode(rawBody) : null;

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
    dynamic data,
  }) async {
    try {
      final uri = Uri.parse(url);
      final requestHeaders = await _buildHeaders(customHeaders: headers);
      final rawBody = data ?? body;
      final encodedBody = rawBody != null ? jsonEncode(rawBody) : null;

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
    dynamic data,
  }) async {
    try {
      final uri = Uri.parse(url);
      final requestHeaders = await _buildHeaders(customHeaders: headers);
      final rawBody = data ?? body;
      final encodedBody = rawBody != null ? jsonEncode(rawBody) : null;

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

  /// Fetch pending officer registration approval requests from PostgreSQL backend
  Future<ApiResponse> getPendingOfficerApprovals() async {
    return await get(ApiConfig.authPendingApprovals);
  }

  /// Approve or Reject an officer's registration in PostgreSQL backend
  Future<ApiResponse> approveOrRejectOfficer(String uid, {required String action}) async {
    return await post(
      ApiConfig.authApproveRegistration(uid),
      body: {'action': action},
    );
  }

  /// Fetch dynamic Police Rank and Capability configurations from PostgreSQL
  Future<ApiResponse> getMasterRankConfigs() async {
    return await get('${ApiConfig.baseUrl}/master/hierarchy/rank-configs/');
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
      } else if (bodyData is Map && bodyData.containsKey('message')) {
        message = bodyData['message'].toString();
      } else if (bodyData is String && bodyData.isNotEmpty) {
        final trimmed = bodyData.trim();
        if (trimmed.startsWith('<') || trimmed.length > 250) {
          message = 'Server Error (${response.statusCode}): Unexpected response';
        } else {
          message = trimmed;
        }
      }
      return ApiResponse.error(message, statusCode: response.statusCode);
    }
  }
}
