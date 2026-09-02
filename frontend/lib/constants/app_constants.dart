// lib/constants/app_constants.dart

class ApiConstants {
  // Replace this with the URL after deploying your Google Apps Script
  static const String feedbackWebAppUrl =
      'https://script.google.com/macros/s/AKfycbyfUGMndPd6MP21_38jCQShSYX8qSc1XdpLC13FzujiS03L-ShW_iG55IUaZ5dwy0yXpg/exec';

  // Request timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys for Tokens
  static const String jwtAccessTokenKey = 'jwt_access_token';
  static const String jwtRefreshTokenKey = 'jwt_refresh_token';
}
