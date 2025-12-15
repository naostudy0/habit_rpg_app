import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _isAuthenticatedKey = 'is_authenticated';

  // トークンを保存
  Future<void> saveToken(String token, {int? expiresIn}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setBool(_isAuthenticatedKey, true);

    // 有効期限を設定（秒単位で受け取る）
    if (expiresIn != null) {
      final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
      await prefs.setString(_tokenExpiryKey, expiryTime.toIso8601String());
    }
  }

  // トークンを取得
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // トークンが有効かチェック
  Future<bool> isTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString(_tokenExpiryKey);

    // 有効期限が設定されていない場合は有効とみなす
    if (expiryString == null) {
      return await hasToken();
    }

    try {
      final expiryTime = DateTime.parse(expiryString);
      return DateTime.now().isBefore(expiryTime);
    } catch (e) {
      // パースエラーの場合は有効期限切れとみなす
      return false;
    }
  }

  // トークンが存在するかチェック
  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  // 認証状態を確認
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuthenticated = prefs.getBool(_isAuthenticatedKey) ?? false;

    if (!isAuthenticated) {
      return false;
    }

    // トークンが存在し、有効期限が切れていないか確認
    if (!await hasToken()) {
      return false;
    }

    return await isTokenValid();
  }

  // ログアウト（トークンを削除）
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.setBool(_isAuthenticatedKey, false);
  }

  // トークンの有効期限を取得
  Future<DateTime?> getTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString(_tokenExpiryKey);

    if (expiryString == null) {
      return null;
    }

    try {
      return DateTime.parse(expiryString);
    } catch (e) {
      return null;
    }
  }
}
