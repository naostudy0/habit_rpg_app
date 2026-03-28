import 'package:flutter_test/flutter_test.dart';
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
}
