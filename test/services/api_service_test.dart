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
      final exception = ApiException(
        statusCode: 400,
        message: 'エラーメッセージ',
      );
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
}
