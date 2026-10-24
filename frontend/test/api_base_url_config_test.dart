import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/services/api_config.dart';

void main() {
  group('config/prod.json', () {
    test('sets an https API_BASE_URL ending in /api', () {
      final config = json.decode(File('config/prod.json').readAsStringSync())
          as Map<String, dynamic>;
      final url = config['API_BASE_URL'] as String? ?? '';
      expect(url, startsWith('https://'));
      expect(url, endsWith('/api'));
      expect(url, isNot(contains('127.0.0.1')));
      expect(url, isNot(contains('localhost')));
    });
  });

  group('ApiConfig', () {
    test('is not flagged as a misconfigured release in tests', () {
      expect(ApiConfig.isMissingInRelease, isFalse);
    });

    test('serverHost is the host of baseUrl', () {
      expect(ApiConfig.serverHost, Uri.parse(ApiConfig.baseUrl).host);
    });
  });

  group('AuthProvider.loginErrorMessage', () {
    const host = 'example.test';

    test('blocked cleartext http', () {
      final msg = AuthProvider.loginErrorMessage(
          StateError('Insecure HTTP is not allowed by platform: http://x'),
          host);
      expect(msg, contains('insecure server address'));
    });

    test('unreachable server', () {
      final msg = AuthProvider.loginErrorMessage(
          http.ClientException('Connection refused'), host);
      expect(msg, contains('Could not reach the server at $host'));
    });

    test('TLS handshake failure', () {
      final msg = AuthProvider.loginErrorMessage(
          const HandshakeException('CERTIFICATE_VERIFY_FAILED'), host);
      expect(msg, contains('secure connection'));
    });

    test('non-JSON reply', () {
      final msg = AuthProvider.loginErrorMessage(
          const FormatException('Unexpected character'), host);
      expect(msg, contains('could not read'));
    });

    test('anything else names the error type', () {
      final msg = AuthProvider.loginErrorMessage(Exception('boom'), host);
      expect(msg, contains('Login failed on this device'));
    });
  });
}
