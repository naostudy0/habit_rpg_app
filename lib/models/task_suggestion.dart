/// AIが提案した予定データのモデルクラス
class TaskSuggestion {
  final String uuid;
  final String title;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskSuggestion({
    required this.uuid,
    required this.title,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// JSONからTaskSuggestionオブジェクトを作成
  factory TaskSuggestion.fromJson(Map<String, dynamic> json) {
    try {
      // UUIDの取得
      final uuid = json['uuid'] ?? json['task_suggestion_uuid'] ?? '';
      if (uuid.isEmpty) {
        throw TaskSuggestionParseException('UUIDが見つかりません');
      }

      // タイトルの取得
      final title = json['title'] ?? '';
      if (title.isEmpty) {
        throw TaskSuggestionParseException('タイトルが見つかりません');
      }

      // メモの取得
      final memo = json['memo'];

      // 作成日時の取得とパース
      final createdAtValue = json['created_at'];
      final createdAt = createdAtValue != null
          ? _parseDateTime(createdAtValue)
          : DateTime.now();

      // 更新日時の取得とパース
      final updatedAtValue = json['updated_at'];
      final updatedAt = updatedAtValue != null
          ? _parseDateTime(updatedAtValue)
          : DateTime.now();

      return TaskSuggestion(
        uuid: uuid.toString(),
        title: title.toString(),
        memo: memo?.toString(),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      if (e is TaskSuggestionParseException) {
        rethrow;
      }
      throw TaskSuggestionParseException('TaskSuggestionのパースに失敗しました: $e');
    }
  }

  /// TaskSuggestionオブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      if (memo != null && memo!.isNotEmpty) 'memo': memo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
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

  @override
  String toString() {
    return 'TaskSuggestion(uuid: $uuid, title: $title, memo: $memo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskSuggestion && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}

/// TaskSuggestionのパースエラー
class TaskSuggestionParseException implements Exception {
  final String message;

  TaskSuggestionParseException(this.message);

  @override
  String toString() => 'TaskSuggestionParseException: $message';
}
