import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_rpg_app/services/auth_service.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      // 各テスト前にSharedPreferencesをクリア
      SharedPreferences.setMockInitialValues({});
      authService = AuthService();
    });

    tearDown(() async {
      // 各テスト後にログアウトしてクリーンアップ
      await authService.logout();
    });

    group('saveToken', () {
      test('トークンを保存できる', () async {
        await authService.saveToken('test_token');
        final token = await authService.getToken();
        expect(token, 'test_token');
      });

      test('トークンと有効期限を保存できる', () async {
        await authService.saveToken('test_token', expiresIn: 3600);
        final token = await authService.getToken();
        final isValid = await authService.isTokenValid();
        expect(token, 'test_token');
        expect(isValid, true);
      });

      test('トークン保存時に認証状態がtrueになる', () async {
        await authService.saveToken('test_token');
        final isAuthenticated = await authService.isAuthenticated();
        expect(isAuthenticated, true);
      });
    });

    group('getToken', () {
      test('保存されていないトークンはnullを返す', () async {
        final token = await authService.getToken();
        expect(token, isNull);
      });

      test('保存されたトークンを取得できる', () async {
        await authService.saveToken('test_token');
        final token = await authService.getToken();
        expect(token, 'test_token');
      });
    });

    group('isTokenValid', () {
      test('有効期限が設定されていない場合は有効とみなす', () async {
        await authService.saveToken('test_token');
        final isValid = await authService.isTokenValid();
        expect(isValid, true);
      });

      test('有効期限が未来の場合は有効', () async {
        await authService.saveToken('test_token', expiresIn: 3600);
        final isValid = await authService.isTokenValid();
        expect(isValid, true);
      });

      test('有効期限が過去の場合は無効', () async {
        await authService.saveToken('test_token', expiresIn: -3600);
        final isValid = await authService.isTokenValid();
        expect(isValid, false);
      });
    });

    group('hasToken', () {
      test('トークンが存在しない場合はfalse', () async {
        final hasToken = await authService.hasToken();
        expect(hasToken, false);
      });

      test('トークンが存在する場合はtrue', () async {
        await authService.saveToken('test_token');
        final hasToken = await authService.hasToken();
        expect(hasToken, true);
      });
    });

    group('isAuthenticated', () {
      test('トークンがない場合はfalse', () async {
        final isAuthenticated = await authService.isAuthenticated();
        expect(isAuthenticated, false);
      });

      test('有効なトークンがある場合はtrue', () async {
        await authService.saveToken('test_token', expiresIn: 3600);
        final isAuthenticated = await authService.isAuthenticated();
        expect(isAuthenticated, true);
      });

      test('有効期限切れのトークンの場合はfalse', () async {
        await authService.saveToken('test_token', expiresIn: -3600);
        final isAuthenticated = await authService.isAuthenticated();
        expect(isAuthenticated, false);
      });
    });

    group('saveUserInfo', () {
      test('ユーザー情報を保存できる', () async {
        await authService.saveUserInfo('テストユーザー', 'test@example.com');
        final userName = await authService.getUserName();
        final userEmail = await authService.getUserEmail();
        expect(userName, 'テストユーザー');
        expect(userEmail, 'test@example.com');
      });
    });

    group('getUserName', () {
      test('保存されていないユーザー名はnullを返す', () async {
        final userName = await authService.getUserName();
        expect(userName, isNull);
      });

      test('保存されたユーザー名を取得できる', () async {
        await authService.saveUserInfo('テストユーザー', 'test@example.com');
        final userName = await authService.getUserName();
        expect(userName, 'テストユーザー');
      });
    });

    group('getUserEmail', () {
      test('保存されていないメールアドレスはnullを返す', () async {
        final userEmail = await authService.getUserEmail();
        expect(userEmail, isNull);
      });

      test('保存されたメールアドレスを取得できる', () async {
        await authService.saveUserInfo('テストユーザー', 'test@example.com');
        final userEmail = await authService.getUserEmail();
        expect(userEmail, 'test@example.com');
      });
    });

    group('saveDarkMode', () {
      test('ダークモード設定を保存できる', () async {
        await authService.saveDarkMode(true);
        final isDarkMode = await authService.getDarkMode();
        expect(isDarkMode, true);
      });

      test('ライトモード設定を保存できる', () async {
        await authService.saveDarkMode(false);
        final isDarkMode = await authService.getDarkMode();
        expect(isDarkMode, false);
      });
    });

    group('getDarkMode', () {
      test('保存されていない場合はfalseを返す', () async {
        final isDarkMode = await authService.getDarkMode();
        expect(isDarkMode, false);
      });
    });

    group('saveTimeFormat', () {
      test('時刻形式設定を保存できる', () async {
        await authService.saveTimeFormat('12時間');
        final timeFormat = await authService.getTimeFormat();
        expect(timeFormat, '12時間');
      });
    });

    group('getTimeFormat', () {
      test('保存されていない場合はデフォルト値を返す', () async {
        final timeFormat = await authService.getTimeFormat();
        expect(timeFormat, '24時間');
      });
    });

    group('logout', () {
      test('ログアウト時にトークンとユーザー情報が削除される', () async {
        await authService.saveToken('test_token', expiresIn: 3600);
        await authService.saveUserInfo('テストユーザー', 'test@example.com');

        await authService.logout();

        final token = await authService.getToken();
        final userName = await authService.getUserName();
        final userEmail = await authService.getUserEmail();
        final isAuthenticated = await authService.isAuthenticated();

        expect(token, isNull);
        expect(userName, isNull);
        expect(userEmail, isNull);
        expect(isAuthenticated, false);
      });
    });

    group('getTokenExpiry', () {
      test('有効期限が設定されていない場合はnullを返す', () async {
        await authService.saveToken('test_token');
        final expiry = await authService.getTokenExpiry();
        expect(expiry, isNull);
      });

      test('有効期限を取得できる', () async {
        await authService.saveToken('test_token', expiresIn: 3600);
        final expiry = await authService.getTokenExpiry();
        expect(expiry, isNotNull);
        expect(expiry!.isAfter(DateTime.now()), true);
      });
    });
  });
}
