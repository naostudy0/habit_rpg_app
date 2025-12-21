import 'package:flutter/material.dart';

/// 予定データのモデルクラス
class Task {
  final String uuid;
  final String title;
  final DateTime scheduledDate;
  final TimeOfDay scheduledTime;
  final String? memo;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.uuid,
    required this.title,
    required this.scheduledDate,
    required this.scheduledTime,
    this.memo,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// JSONからTaskオブジェクトを作成
  factory Task.fromJson(Map<String, dynamic> json) {
    try {
      // UUIDの取得
      final uuid = json['uuid'] ?? json['id'] ?? '';
      if (uuid.isEmpty) {
        throw TaskParseException('UUIDが見つかりません');
      }

      // タイトルの取得
      final title = json['title'] ?? json['name'] ?? '';
      if (title.isEmpty) {
        throw TaskParseException('タイトルが見つかりません');
      }

      // 日付の取得とパース
      final dateValue = json['scheduled_date'] ?? json['date'] ?? json['scheduled_at'];
      if (dateValue == null) {
        throw TaskParseException('予定日が見つかりません');
      }
      final scheduledDate = _parseDate(dateValue);
      if (scheduledDate == null) {
        throw TaskParseException('予定日の形式が不正です: $dateValue');
      }

      // 時刻の取得とパース
      final timeValue = json['scheduled_time'] ?? json['time'];
      if (timeValue == null) {
        throw TaskParseException('予定時刻が見つかりません');
      }
      final scheduledTime = _parseTime(timeValue);
      if (scheduledTime == null) {
        throw TaskParseException('予定時刻の形式が不正です: $timeValue');
      }

      // メモの取得
      final memo = json['memo'] ?? json['description'];

      // 完了状態の取得
      final isCompleted = json['is_completed'] ?? json['isCompleted'] ?? false;

      // 作成日時の取得とパース
      final createdAtValue = json['created_at'] ?? json['createdAt'];
      final createdAt = createdAtValue != null
          ? _parseDateTime(createdAtValue)
          : DateTime.now();

      // 更新日時の取得とパース
      final updatedAtValue = json['updated_at'] ?? json['updatedAt'];
      final updatedAt = updatedAtValue != null
          ? _parseDateTime(updatedAtValue)
          : DateTime.now();

      return Task(
        uuid: uuid.toString(),
        title: title.toString(),
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        memo: memo?.toString(),
        isCompleted: isCompleted is bool ? isCompleted : false,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      if (e is TaskParseException) {
        rethrow;
      }
      throw TaskParseException('Taskのパースに失敗しました: $e');
    }
  }

  /// TaskオブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0], // YYYY-MM-DD形式
      'scheduled_time':
          '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}:00',
      if (memo != null && memo!.isNotEmpty) 'memo': memo,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 日付文字列をDateTimeに変換
  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      try {
        // YYYY-MM-DD形式またはISO8601形式をパース
        final dateOnly = dateValue.split('T')[0].split(' ')[0];
        final parts = dateOnly.split('-');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
        // ISO8601形式の場合は直接パース
        return DateTime.parse(dateOnly);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // 時刻文字列をTimeOfDayに変換
  static TimeOfDay? _parseTime(dynamic timeValue) {
    if (timeValue == null) return null;
    if (timeValue is TimeOfDay) return timeValue;
    if (timeValue is String) {
      try {
        final parts = timeValue.split(':');
        if (parts.length >= 2) {
          return TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // 日時文字列をDateTimeに変換
  static DateTime _parseDateTime(dynamic dateTimeValue) {
    if (dateTimeValue is DateTime) return dateTimeValue;
    if (dateTimeValue is String) {
      try {
        return DateTime.parse(dateTimeValue);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// バリデーション
  void validate() {
    if (uuid.isEmpty) {
      throw TaskValidationException('UUIDは必須です');
    }
    if (title.trim().isEmpty) {
      throw TaskValidationException('タイトルは必須です');
    }
    if (title.length > 255) {
      throw TaskValidationException('タイトルは255文字以内で入力してください');
    }
    if (memo != null && memo!.length > 1000) {
      throw TaskValidationException('メモは1000文字以内で入力してください');
    }
  }

  /// Taskのコピーを作成（一部のフィールドを変更）
  Task copyWith({
    String? uuid,
    String? title,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
    String? memo,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      memo: memo ?? this.memo,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Task(uuid: $uuid, title: $title, scheduledDate: $scheduledDate, scheduledTime: $scheduledTime, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}

/// Taskのパースエラー
class TaskParseException implements Exception {
  final String message;

  TaskParseException(this.message);

  @override
  String toString() => 'TaskParseException: $message';
}

/// Taskのバリデーションエラー
class TaskValidationException implements Exception {
  final String message;

  TaskValidationException(this.message);

  @override
  String toString() => 'TaskValidationException: $message';
}
