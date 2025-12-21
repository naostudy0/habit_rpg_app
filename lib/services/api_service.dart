import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/task.dart';
import '../models/user.dart';
import 'auth_service.dart';

// APIエラークラス
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  // エラーメッセージを取得（バリデーションエラーの場合は最初のエラーを返す）
  String getErrorMessage() {
    if (errors != null && errors!.isNotEmpty) {
      // バリデーションエラーの場合、最初のエラーメッセージを返す
      for (final key in errors!.keys) {
        final errorList = errors![key];
        if (errorList is List && errorList.isNotEmpty) {
          return errorList.first as String;
        }
      }
    }
    return message;
  }

  // 特定のフィールドのエラーメッセージを取得
  String? getFieldError(String field) {
    if (errors != null && errors!.containsKey(field)) {
      final errorList = errors![field];
      if (errorList is List && errorList.isNotEmpty) {
        return errorList.first as String;
      }
    }
    return null;
  }

  // すべてのエラーメッセージを取得
  List<String> getAllErrorMessages() {
    final errorMessages = <String>[];
    if (errors != null) {
      for (final key in errors!.keys) {
        final errorList = errors![key];
        if (errorList is List) {
          for (final error in errorList) {
            errorMessages.add(error as String);
          }
        }
      }
    }
    if (errorMessages.isEmpty) {
      errorMessages.add(message);
    }
    return errorMessages;
  }

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = EnvironmentConfig.baseUrl;
  final AuthService _authService = AuthService();

  // ヘッダーの設定（認証トークンを自動付与）
  Future<Map<String, String>> get _headers async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // 認証トークンが存在する場合は追加
    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ログインAPI
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // レスポンスからトークンを取得して保存
        if (responseData['token'] != null) {
          final token = responseData['token'] as String;
          final expiresIn = responseData['expires_in'] as int?;
          await _authService.saveToken(token, expiresIn: expiresIn);
        }

        // ユーザー情報を保存
        if (responseData['data'] != null) {
          final userData = responseData['data'] as Map<String, dynamic>;
          final userName = userData['name'] ?? userData['username'] ?? userData['user_name'] ?? '';
          final userEmail = userData['email'] ?? '';
          if (userName.isNotEmpty && userEmail.isNotEmpty) {
            await _authService.saveUserInfo(userName, userEmail);
          }
        }

        return responseData;
      } else {
        // エラーレスポンスをパース
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          statusCode: response.statusCode,
          message: errorData['message'] as String? ?? 'ログインに失敗しました',
          errors: errorData['errors'] as Map<String, dynamic>?,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e is FormatException) {
        // JSONパースエラーの場合
        throw ApiException(
          statusCode: 0,
          message: 'サーバーからの応答を解析できませんでした',
          errors: null,
        );
      }
      throw ApiException(
        statusCode: 0,
        message: 'ネットワークエラー: $e',
        errors: null,
      );
    }
  }

  // ログアウトAPI
  Future<void> logout() async {
    try {
      final headers = await _headers;
      await http.post(
        Uri.parse('$_baseUrl/api/auth/logout'),
        headers: headers,
      );
    } catch (e) {
      // エラーが発生してもローカルのトークンは削除する
      // ignore: avoid_print
      print('ログアウトAPIエラー: $e');
    } finally {
      // ローカルのトークンを削除
      await _authService.logout();
    }
  }

  // 予定一覧取得API
  Future<List<Task>> getTasks() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tasks'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // レスポンスの形式に応じてデータを取得
        List<dynamic> tasksData = [];
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') && responseData['data'] is List) {
            tasksData = responseData['data'] as List;
          }
        } else if (responseData is List) {
          tasksData = responseData;
        }

        // Taskモデルに変換
        final tasks = <Task>[];
        for (final taskData in tasksData) {
          try {
            if (taskData is Map<String, dynamic>) {
              tasks.add(Task.fromJson(taskData));
            }
          } catch (e) {
            // パースエラーはログに記録してスキップ
            // ignore: avoid_print
            print('Taskのパースエラー: $e');
          }
        }
        return tasks;
      } else {
        // エラーレスポンスをパース
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          statusCode: response.statusCode,
          message: errorData['message'] as String? ?? '予定一覧の取得に失敗しました',
          errors: errorData['errors'] as Map<String, dynamic>?,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e is FormatException) {
        // JSONパースエラーの場合
        throw ApiException(
          statusCode: 0,
          message: 'サーバーからの応答を解析できませんでした',
          errors: null,
        );
      }
      throw ApiException(
        statusCode: 0,
        message: 'ネットワークエラー: $e',
        errors: null,
      );
    }
  }

  // 予定作成API
  Future<Task> createTask({
    required String title,
    required DateTime scheduledDate,
    required TimeOfDay scheduledTime,
    String? memo,
  }) async {
    try {
      final headers = await _headers;

      final response = await http.post(
        Uri.parse('$_baseUrl/api/tasks'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'scheduled_date': scheduledDate.toIso8601String().split('T')[0], // YYYY-MM-DD形式
          'scheduled_time': '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}:00',
          if (memo != null && memo.isNotEmpty) 'memo': memo,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // レスポンスからTaskデータを取得
        final taskData = responseData['data'] ?? responseData;
        if (taskData is Map<String, dynamic>) {
          return Task.fromJson(taskData);
        } else {
          throw ApiException(
            statusCode: response.statusCode,
            message: '予定データの形式が不正です',
            errors: null,
          );
        }
      } else {
        // エラーレスポンスをパース
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          statusCode: response.statusCode,
          message: errorData['message'] as String? ?? '予定の作成に失敗しました',
          errors: errorData['errors'] as Map<String, dynamic>?,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e is FormatException) {
        // JSONパースエラーの場合
        throw ApiException(
          statusCode: 0,
          message: 'サーバーからの応答を解析できませんでした',
          errors: null,
        );
      }
      throw ApiException(
        statusCode: 0,
        message: 'ネットワークエラー: $e',
        errors: null,
      );
    }
  }

  // 予定更新API
  Future<Task> updateTask({
    required String uuid,
    required String title,
    required DateTime scheduledDate,
    required TimeOfDay scheduledTime,
    String? memo,
  }) async {
    try {
      final headers = await _headers;

      final response = await http.put(
        Uri.parse('$_baseUrl/api/tasks/$uuid'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'scheduled_date': scheduledDate.toIso8601String().split('T')[0], // YYYY-MM-DD形式
          'scheduled_time': '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}:00',
          if (memo != null && memo.isNotEmpty) 'memo': memo,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204 No Contentの場合は、既存のTaskデータから更新されたTaskを作成
        if (response.body.isEmpty) {
          // 更新されたデータを取得するために、再度取得するか、リクエストデータから作成
          // ここでは簡易的に、リクエストデータからTaskを作成
          return Task(
            uuid: uuid,
            title: title,
            scheduledDate: scheduledDate,
            scheduledTime: scheduledTime,
            memo: memo,
            isCompleted: false, // 既存の状態を保持する必要がある場合は、別途取得が必要
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final taskData = responseData['data'] ?? responseData;
        if (taskData is Map<String, dynamic>) {
          return Task.fromJson(taskData);
        } else {
          throw ApiException(
            statusCode: response.statusCode,
            message: '予定データの形式が不正です',
            errors: null,
          );
        }
      } else {
        // エラーレスポンスをパース
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          statusCode: response.statusCode,
          message: errorData['message'] as String? ?? '予定の更新に失敗しました',
          errors: errorData['errors'] as Map<String, dynamic>?,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e is FormatException) {
        // JSONパースエラーの場合
        throw ApiException(
          statusCode: 0,
          message: 'サーバーからの応答を解析できませんでした',
          errors: null,
        );
      }
      throw ApiException(
        statusCode: 0,
        message: 'ネットワークエラー: $e',
        errors: null,
      );
    }
  }

  // 予定削除API
  Future<void> deleteTask(String uuid) async {
    try {
      final headers = await _headers;
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/tasks/$uuid'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 削除成功
        return;
      } else {
        // エラーレスポンスをパース
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          statusCode: response.statusCode,
          message: errorData['message'] as String? ?? '予定の削除に失敗しました',
          errors: errorData['errors'] as Map<String, dynamic>?,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e is FormatException) {
        // JSONパースエラーの場合
        throw ApiException(
          statusCode: 0,
          message: 'サーバーからの応答を解析できませんでした',
          errors: null,
        );
      }
      throw ApiException(
        statusCode: 0,
        message: 'ネットワークエラー: $e',
        errors: null,
      );
    }
  }

  // 予定完了状態切り替えAPI
  Future<Task> toggleTaskCompletion({
    required String uuid,
    required bool isCompleted,
  }) async {
    try {
      final headers = await _headers;
      final response = await http.patch(
        Uri.parse('$_baseUrl/api/tasks/$uuid/complete'),
        headers: headers,
        body: jsonEncode({
          'is_completed': isCompleted,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final taskData = responseData['data'] ?? responseData;
        if (taskData is Map<String, dynamic>) {
          return Task.fromJson(taskData);
        } else {
          throw ApiException(
            statusCode: response.statusCode,
            message: '予定データの形式が不正です',
            errors: null,
          );
        }
      } else {
        // エラーレスポンスをパース
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          statusCode: response.statusCode,
          message: errorData['message'] as String? ?? '予定の完了状態の切り替えに失敗しました',
          errors: errorData['errors'] as Map<String, dynamic>?,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e is FormatException) {
        // JSONパースエラーの場合
        throw ApiException(
          statusCode: 0,
          message: 'サーバーからの応答を解析できませんでした',
          errors: null,
        );
      }
      throw ApiException(
        statusCode: 0,
        message: 'ネットワークエラー: $e',
        errors: null,
      );
    }
  }

  // ユーザー情報を取得
  Future<User> getUser() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$_baseUrl/api/user'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = responseData['data'] ?? responseData;
        return User.fromJson(userData as Map<String, dynamic>);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          statusCode: response.statusCode,
          message: errorData['message'] as String? ?? 'ユーザー情報の取得に失敗しました',
          errors: errorData['errors'] as Map<String, dynamic>?,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e is FormatException) {
        throw ApiException(
          statusCode: 0,
          message: 'サーバーからの応答を解析できませんでした',
          errors: null,
        );
      }
      throw ApiException(
        statusCode: 0,
        message: 'ネットワークエラー: $e',
        errors: null,
      );
    }
  }

  // ユーザー情報を更新
  Future<User> updateUser({
    String? name,
    String? email,
    String? password,
    bool? isDarkMode,
    bool? is24HourFormat,
  }) async {
    try {
      final headers = await _headers;
      final body = <String, dynamic>{};

      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (password != null) body['password'] = password;
      if (isDarkMode != null) body['is_dark_mode'] = isDarkMode;
      if (is24HourFormat != null) body['is_24_hour_format'] = is24HourFormat;

      final response = await http.put(
        Uri.parse('$_baseUrl/api/user'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = responseData['data'] ?? responseData;
        return User.fromJson(userData as Map<String, dynamic>);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          statusCode: response.statusCode,
          message: errorData['message'] as String? ?? 'ユーザー情報の更新に失敗しました',
          errors: errorData['errors'] as Map<String, dynamic>?,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e is FormatException) {
        throw ApiException(
          statusCode: 0,
          message: 'サーバーからの応答を解析できませんでした',
          errors: null,
        );
      }
      throw ApiException(
        statusCode: 0,
        message: 'ネットワークエラー: $e',
        errors: null,
      );
    }
  }

  // アカウント削除
  Future<void> deleteAccount() async {
    try {
      final headers = await _headers;
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/user'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          statusCode: response.statusCode,
          message: errorData['message'] as String? ?? 'アカウントの削除に失敗しました',
          errors: errorData['errors'] as Map<String, dynamic>?,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e is FormatException) {
        throw ApiException(
          statusCode: 0,
          message: 'サーバーからの応答を解析できませんでした',
          errors: null,
        );
      }
      throw ApiException(
        statusCode: 0,
        message: 'ネットワークエラー: $e',
        errors: null,
      );
    }
  }
}
