import 'package:flutter/material.dart';
import '../services/settings_service.dart';

/// 時刻フォーマット用のユーティリティクラス
class TimeFormatter {
  /// TimeOfDayを文字列にフォーマット（24時間形式設定に基づく）
  static String formatTime(TimeOfDay time) {
    final settingsService = SettingsService();
    final is24Hour = settingsService.is24HourFormat;

    if (is24Hour) {
      // 24時間形式
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      // 12時間形式（AM/PM）
      final hour = time.hour == 0
          ? 12
          : time.hour > 12
          ? time.hour - 12
          : time.hour;
      final period = time.hour < 12 ? 'AM' : 'PM';
      return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }

  /// TimeOfDayを文字列にフォーマット（24時間形式を強制）
  static String formatTime24Hour(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// TimeOfDayを文字列にフォーマット（12時間形式を強制）
  static String formatTime12Hour(TimeOfDay time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
        ? time.hour - 12
        : time.hour;
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
