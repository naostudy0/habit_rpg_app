import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_rpg_app/services/api_service.dart';
import 'package:habit_rpg_app/services/auth_service.dart';

void main() {
  group('ApiService', () {
    late AuthService authService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authService = AuthService();
    });

    tearDown(() async {
      await authService.logout();
    });
  });

  group('ApiException', () {
    test('エラーメッセージを取得できる', () {
      final exception = ApiException(statusCode: 400, message: 'エラーメッセージ');
      expect(exception.message, 'エラーメッセージ');
      expect(exception.statusCode, 400);
    });

    test('バリデーションエラーのメッセージを取得できる', () {
      final exception = ApiException(
        statusCode: 422,
        message: 'バリデーションエラー',
        errors: {
          'title': ['タイトルは必須です'],
          'email': ['メールアドレスの形式が不正です'],
        },
      );
      expect(exception.getErrorMessage(), 'タイトルは必須です');
      expect(exception.getFieldError('title'), 'タイトルは必須です');
      expect(exception.getFieldError('email'), 'メールアドレスの形式が不正です');
      expect(exception.getAllErrorMessages().length, 2);
    });
  });

  group('RegistrationApiStatus', () {
    test('会員登録APIのステータスコードを正規化できる', () {
      expect(
        normalizeRegistrationApiStatus(200),
        RegistrationApiStatus.success,
      );
      expect(
        normalizeRegistrationApiStatus(201),
        RegistrationApiStatus.created,
      );
      expect(
        normalizeRegistrationApiStatus(409),
        RegistrationApiStatus.conflict,
      );
      expect(
        normalizeRegistrationApiStatus(422),
        RegistrationApiStatus.unprocessableEntity,
      );
      expect(
        normalizeRegistrationApiStatus(429),
        RegistrationApiStatus.tooManyRequests,
      );
      expect(
        normalizeRegistrationApiStatus(0),
        RegistrationApiStatus.networkError,
      );
      expect(
        normalizeRegistrationApiStatus(500),
        RegistrationApiStatus.unknownError,
      );
    });
  });

  group('RegistrationApiResult', () {
    test('画面判定用のヘルパーが正しく動作する', () {
      const createdResult = RegistrationApiResult(
        statusCode: 201,
        status: RegistrationApiStatus.created,
        message: '会員登録が完了しました。',
      );
      const conflictResult = RegistrationApiResult(
        statusCode: 409,
        status: RegistrationApiStatus.conflict,
        message: 'このメールアドレスはすでに登録されています。',
      );
      const tooManyRequestsResult = RegistrationApiResult(
        statusCode: 429,
        status: RegistrationApiStatus.tooManyRequests,
        message: '再送上限に達しました。',
      );

      expect(createdResult.isSuccess, true);
      expect(createdResult.isConflict, false);
      expect(conflictResult.isSuccess, false);
      expect(conflictResult.isConflict, true);
      expect(tooManyRequestsResult.isTooManyRequests, true);
      expect(tooManyRequestsResult.isValidationError, false);
    });
  });

  group('ApiService registration mapping', () {
    late AuthService authService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authService = AuthService();
    });

    tearDown(() async {
      await authService.logout();
    });

    ApiService buildService(
      Future<http.Response> Function(http.Request request) handler,
    ) {
      final mockClient = MockClient(handler);
      return ApiService(httpClient: mockClient, authService: authService);
    }

    test('sendRegistrationOtp: 主要HTTPステータスを正規化できる', () async {
      final cases = <int, RegistrationApiStatus>{
        200: RegistrationApiStatus.success,
        409: RegistrationApiStatus.conflict,
        422: RegistrationApiStatus.unprocessableEntity,
        429: RegistrationApiStatus.tooManyRequests,
        500: RegistrationApiStatus.unknownError,
      };

      for (final entry in cases.entries) {
        final service = buildService((request) async {
          expect(request.url.path, '/api/auth/register/otp/send');
          final decoded = jsonDecode(request.body) as Map<String, dynamic>;
          expect(decoded['email'], 'new-user@example.com');
          return http.Response(
            jsonEncode({'message': 'status-${entry.key}'}),
            entry.key,
          );
        });

        final result = await service.sendRegistrationOtp(
          '  new-user@example.com  ',
        );
        expect(result.statusCode, entry.key);
        expect(result.status, entry.value);
        expect(result.message, 'status-${entry.key}');
      }
    });

    test('sendRegistrationOtp: ネットワーク例外は networkError にマッピングされる', () async {
      final service = buildService((_) async {
        throw Exception('network down');
      });

      final result = await service.sendRegistrationOtp('user@example.com');
      expect(result.statusCode, 0);
      expect(result.status, RegistrationApiStatus.networkError);
      expect(result.message, 'ワンタイムパスワードの送信に失敗しました。');
    });

    test('sendRegistrationOtp: 空文字はHTTPリクエストせず422を返す', () async {
      final service = buildService((_) async {
        fail('HTTP request should not be made for empty email');
      });

      final result = await service.sendRegistrationOtp('');
      expect(result.statusCode, 422);
      expect(result.status, RegistrationApiStatus.unprocessableEntity);
      expect(result.isValidationError, isTrue);
    });

    test('sendRegistrationOtp: 不正形式メールはHTTPリクエストせず422を返す', () async {
      final service = buildService((_) async {
        fail('HTTP request should not be made for invalid email');
      });

      final result = await service.sendRegistrationOtp('not-an-email');
      expect(result.statusCode, 422);
      expect(result.status, RegistrationApiStatus.unprocessableEntity);
      expect(result.isValidationError, isTrue);
    });

    test('sendRegistrationOtp: 長すぎるメールはHTTPリクエストせず422を返す', () async {
      final service = buildService((_) async {
        fail('HTTP request should not be made for very long email');
      });
      final longEmail = '${List.filled(1001, 'a').join()}@example.com';

      final result = await service.sendRegistrationOtp(longEmail);
      expect(result.statusCode, 422);
      expect(result.status, RegistrationApiStatus.unprocessableEntity);
      expect(result.isValidationError, isTrue);
    });

    test('verifyRegistrationOtp: 200成功を正規化できる', () async {
      final service = buildService((request) async {
        expect(request.url.path, '/api/auth/register/otp/verify');
        return http.Response(
          jsonEncode({
            'message': 'verified',
            'data': {'registration_token': 'reg-token-123'},
          }),
          200,
        );
      });

      final result = await service.verifyRegistrationOtp(
        email: 'new-user@example.com',
        otp: '123456',
      );
      expect(result.statusCode, 200);
      expect(result.status, RegistrationApiStatus.success);
      expect(result.data?['registration_token'], 'reg-token-123');
      expect(result.isValidationError, isFalse);
    });

    test('verifyRegistrationOtp: 422時に errors を保持する', () async {
      late String requestPath;
      late String requestBody;
      final service = buildService((request) async {
        requestPath = request.url.path;
        requestBody = request.body;
        return http.Response(
          jsonEncode({
            'message': 'validation failed',
            'errors': {
              'otp': ['invalid otp'],
            },
          }),
          422,
        );
      });

      final result = await service.verifyRegistrationOtp(
        email: ' new-user@example.com ',
        otp: '123456',
      );
      expect(result.statusCode, 422);
      expect(result.status, RegistrationApiStatus.unprocessableEntity);
      expect(result.isValidationError, isTrue);
      expect(result.errors?['otp'], ['invalid otp']);
      expect(requestPath, '/api/auth/register/otp/verify');
      final decoded = jsonDecode(requestBody) as Map<String, dynamic>;
      expect(decoded['email'], 'new-user@example.com');
      expect(decoded['otp'], '123456');
    });

    test('verifyRegistrationOtp: 409/429/500を正規化できる', () async {
      final cases = <int, RegistrationApiStatus>{
        409: RegistrationApiStatus.conflict,
        429: RegistrationApiStatus.tooManyRequests,
        500: RegistrationApiStatus.unknownError,
      };

      for (final entry in cases.entries) {
        final service = buildService((_) async {
          return http.Response(
            jsonEncode({'message': 'status-${entry.key}'}),
            entry.key,
          );
        });

        final result = await service.verifyRegistrationOtp(
          email: 'new-user@example.com',
          otp: '123456',
        );
        expect(result.statusCode, entry.key);
        expect(result.status, entry.value);
        expect(result.isValidationError, isFalse);
      }
    });

    test('verifyRegistrationOtp: ネットワーク例外は networkError にマッピングされる', () async {
      final service = buildService((_) async {
        throw Exception('network down');
      });

      final result = await service.verifyRegistrationOtp(
        email: 'new-user@example.com',
        otp: '123456',
      );
      expect(result.statusCode, 0);
      expect(result.status, RegistrationApiStatus.networkError);
      expect(result.isValidationError, isFalse);
    });

    test('completeRegistration: 201成功と name trim を確認できる', () async {
      late String requestPath;
      late String requestBody;
      final service = buildService((request) async {
        requestPath = request.url.path;
        requestBody = request.body;
        return http.Response(
          jsonEncode({
            'message': 'registration completed',
            'data': {'user_id': 10},
          }),
          201,
        );
      });

      final result = await service.completeRegistration(
        registrationToken: 'token-123',
        name: '  Test User  ',
        password: 'Password123!',
      );
      expect(result.statusCode, 201);
      expect(result.status, RegistrationApiStatus.created);
      expect(result.isSuccess, isTrue);
      expect(result.data?['user_id'], 10);
      expect(requestPath, '/api/auth/register/complete');
      final decoded = jsonDecode(requestBody) as Map<String, dynamic>;
      expect(decoded['registration_token'], 'token-123');
      expect(decoded['name'], 'Test User');
      expect(decoded['password'], 'Password123!');
    });

    test('completeRegistration: 409/429/500を正規化できる', () async {
      final cases = <int, RegistrationApiStatus>{
        409: RegistrationApiStatus.conflict,
        429: RegistrationApiStatus.tooManyRequests,
        500: RegistrationApiStatus.unknownError,
      };

      for (final entry in cases.entries) {
        final service = buildService((request) async {
          expect(request.url.path, '/api/auth/register/complete');
          return http.Response(
            jsonEncode({'message': 'status-${entry.key}'}),
            entry.key,
          );
        });

        final result = await service.completeRegistration(
          registrationToken: 'token-123',
          name: 'Tester',
          password: 'Password123!',
        );
        expect(result.statusCode, entry.key);
        expect(result.status, entry.value);
        expect(result.message, 'status-${entry.key}');
      }
    });

    test('completeRegistration: 422時に errors を保持する', () async {
      final service = buildService((_) async {
        return http.Response(
          jsonEncode({
            'message': 'validation failed',
            'errors': {
              'name': ['name is invalid'],
            },
          }),
          422,
        );
      });

      final result = await service.completeRegistration(
        registrationToken: 'token-123',
        name: 'Tester',
        password: 'Password123!',
      );
      expect(result.statusCode, 422);
      expect(result.status, RegistrationApiStatus.unprocessableEntity);
      expect(result.isValidationError, isTrue);
      expect(result.errors?['name'], ['name is invalid']);
    });

    test('completeRegistration: ネットワーク例外は networkError にマッピングされる', () async {
      final service = buildService((_) async {
        throw Exception('network down');
      });

      final result = await service.completeRegistration(
        registrationToken: 'token-123',
        name: 'Tester',
        password: 'Password123!',
      );
      expect(result.statusCode, 0);
      expect(result.status, RegistrationApiStatus.networkError);
    });
  });
}
