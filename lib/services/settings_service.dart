import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 設定管理サービス
class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _keyIsDarkMode = 'is_dark_mode';
  static const String _keyLanguage = 'language';
  static const String _keyDateFormat = 'date_format';
  static const String _keyTimeFormat = 'time_format';

  bool _isDarkMode = false;
  String _language = 'ja';
  String _dateFormat = 'yyyy/MM/dd';
  bool _is24HourFormat = false;

  // Getters
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  String get language => _language;
  String get dateFormat => _dateFormat;
  bool get is24HourFormat => _is24HourFormat;

  /// 設定を初期化（SharedPreferencesから読み込み）
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // ダークモード設定
    _isDarkMode = prefs.getBool(_keyIsDarkMode) ?? false;

    // 言語
    _language = prefs.getString(_keyLanguage) ?? 'ja';

    // 日付形式
    _dateFormat = prefs.getString(_keyDateFormat) ?? 'yyyy/MM/dd';

    // 時刻形式
    _is24HourFormat = prefs.getBool(_keyTimeFormat) ?? false;

    notifyListeners();
  }

  /// ダークモードを設定
  Future<void> setIsDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsDarkMode, isDark);
    notifyListeners();
  }

  /// 言語を設定
  Future<void> setLanguage(String language) async {
    _language = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, language);
    notifyListeners();
  }

  /// 日付形式を設定
  Future<void> setDateFormat(String format) async {
    _dateFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDateFormat, format);
    notifyListeners();
  }

  /// 時刻形式を設定（24時間形式かどうか）
  Future<void> setIs24HourFormat(bool is24Hour) async {
    _is24HourFormat = is24Hour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTimeFormat, is24Hour);
    notifyListeners();
  }

  /// すべての設定をリセット
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsDarkMode);
    await prefs.remove(_keyLanguage);
    await prefs.remove(_keyDateFormat);
    await prefs.remove(_keyTimeFormat);

    _isDarkMode = false;
    _language = 'ja';
    _dateFormat = 'yyyy/MM/dd';
    _is24HourFormat = false;

    notifyListeners();
  }
}
