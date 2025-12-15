import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _isAuthenticatedKey = 'is_authenticated';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _darkModeKey = 'dark_mode';
  static const String _timeFormatKey = 'time_format';

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

  // ユーザー情報を保存
  Future<void> saveUserInfo(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
  }

  // ユーザー名を取得
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // ユーザーメールアドレスを取得
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // ダークモード設定を保存
  Future<void> saveDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, isDarkMode);
  }

  // ダークモード設定を取得
  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  // 時刻形式設定を保存
  Future<void> saveTimeFormat(String timeFormat) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timeFormatKey, timeFormat);
  }

  // 時刻形式設定を取得
  Future<String> getTimeFormat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_timeFormatKey) ?? '24時間';
  }

  // ログアウト（トークンとユーザー情報を削除）
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
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
