import 'package:flutter/material.dart';

/// ユーザーデータのモデルクラス
class User {
  final String uuid;
  final String name;
  final String email;
  final bool isDarkMode;
  final bool is24HourFormat;

  User({
    required this.uuid,
    required this.name,
    required this.email,
    this.isDarkMode = false,
    this.is24HourFormat = false,
  });

  /// JSONからUserオブジェクトを作成
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uuid: json['user_uuid'] ?? json['uuid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      isDarkMode: json['is_dark_mode'] ?? false,
      is24HourFormat: json['is_24_hour_format'] ?? false,
    );
  }

  /// UserオブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'user_uuid': uuid,
      'name': name,
      'email': email,
      'is_dark_mode': isDarkMode,
      'is_24_hour_format': is24HourFormat,
    };
  }

  /// Userのコピーを作成（一部のフィールドを変更）
  User copyWith({
    String? uuid,
    String? name,
    String? email,
    bool? isDarkMode,
    bool? is24HourFormat,
  }) {
    return User(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      email: email ?? this.email,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      is24HourFormat: is24HourFormat ?? this.is24HourFormat,
    );
  }

  @override
  String toString() {
    return 'User(uuid: $uuid, name: $name, email: $email, isDarkMode: $isDarkMode, is24HourFormat: $is24HourFormat)';
  }
}
