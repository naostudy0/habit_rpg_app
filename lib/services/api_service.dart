import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/task.dart';
import '../models/task_suggestion.dart';
import '../models/user.dart';
import 'auth_service.dart';

// APIエラークラス
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException({required this.statusCode, required this.message, this.errors});

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

/// 会員登録APIのステータス正規化
enum RegistrationApiStatus {
  success,
  created,
  conflict,
  unprocessableEntity,
  tooManyRequests,
  networkError,
  unknownError,
}

RegistrationApiStatus normalizeRegistrationApiStatus(int statusCode) {
  switch (statusCode) {
    case 200:
      return RegistrationApiStatus.success;
    case 201:
      return RegistrationApiStatus.created;
    case 409:
      return RegistrationApiStatus.conflict;
    case 422:
      return RegistrationApiStatus.unprocessableEntity;
    case 429:
      return RegistrationApiStatus.tooManyRequests;
    case 0:
      return RegistrationApiStatus.networkError;
    default:
      return RegistrationApiStatus.unknownError;
  }
}

/// 会員登録APIの正規化済みレスポンス
class RegistrationApiResult {
  final int statusCode;
  final RegistrationApiStatus status;
  final String message;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? errors;

  const RegistrationApiResult({
    required this.statusCode,
    required this.status,
    required this.message,
    this.data,
    this.errors,
  });

  bool get isSuccess =>
      status == RegistrationApiStatus.success ||
      status == RegistrationApiStatus.created;

  bool get isConflict => status == RegistrationApiStatus.conflict;
  bool get isValidationError =>
      status == RegistrationApiStatus.unprocessableEntity;
  bool get isTooManyRequests => status == RegistrationApiStatus.tooManyRequests;
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
        body: jsonEncode({'email': email, 'password': password}),
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
          final userName =
              userData['name'] ??
              userData['username'] ??
              userData['user_name'] ??
              '';
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
      throw ApiException(statusCode: 0, message: 'ネットワークエラー: $e', errors: null);
    }
  }

  // 会員登録OTP送信API
  Future<RegistrationApiResult> sendRegistrationOtp(String email) async {
    return _postRegistrationApi(
      endpoint: '/api/auth/register/otp/send',
      body: {'email': email},
      successStatusCodes: const {200},
      defaultSuccessMessage: 'ワンタイムパスワードを送信しました。',
      defaultErrorMessage: 'ワンタイムパスワードの送信に失敗しました。',
    );
  }

  // 会員登録OTP検証API
  Future<RegistrationApiResult> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    return _postRegistrationApi(
      endpoint: '/api/auth/register/otp/verify',
      body: {'email': email, 'otp': otp},
      successStatusCodes: const {200},
      defaultSuccessMessage: 'ワンタイムパスワードを検証しました。',
      defaultErrorMessage: 'ワンタイムパスワードの検証に失敗しました。',
    );
  }

  // 会員登録完了API
  Future<RegistrationApiResult> completeRegistration({
    required String registrationToken,
    required String name,
    required String password,
  }) async {
    return _postRegistrationApi(
      endpoint: '/api/auth/register/complete',
      body: {
        'registration_token': registrationToken,
        'name': name,
        'password': password,
      },
      successStatusCodes: const {201},
      defaultSuccessMessage: '会員登録が完了しました。',
      defaultErrorMessage: '会員登録に失敗しました。',
    );
  }

  // ログアウトAPI
  Future<void> logout() async {
    try {
      final headers = await _headers;
      await http.post(Uri.parse('$_baseUrl/api/auth/logout'), headers: headers);
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
          if (responseData.containsKey('data') &&
              responseData['data'] is List) {
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
      throw ApiException(statusCode: 0, message: 'ネットワークエラー: $e', errors: null);
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
          'scheduled_date': scheduledDate.toIso8601String().split(
            'T',
          )[0], // YYYY-MM-DD形式
          'scheduled_time':
              '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}:00',
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
      throw ApiException(statusCode: 0, message: 'ネットワークエラー: $e', errors: null);
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
          'scheduled_date': scheduledDate.toIso8601String().split(
            'T',
          )[0], // YYYY-MM-DD形式
          'scheduled_time':
              '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}:00',
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
      throw ApiException(statusCode: 0, message: 'ネットワークエラー: $e', errors: null);
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
      throw ApiException(statusCode: 0, message: 'ネットワークエラー: $e', errors: null);
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
        body: jsonEncode({'is_completed': isCompleted}),
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
      throw ApiException(statusCode: 0, message: 'ネットワークエラー: $e', errors: null);
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
      throw ApiException(statusCode: 0, message: 'ネットワークエラー: $e', errors: null);
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
      throw ApiException(statusCode: 0, message: 'ネットワークエラー: $e', errors: null);
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
      throw ApiException(statusCode: 0, message: 'ネットワークエラー: $e', errors: null);
    }
  }

  // AI提案予定一覧取得API
  Future<List<TaskSuggestion>> getTaskSuggestions() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$_baseUrl/api/task-suggestions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // レスポンスの形式に応じてデータを取得
        List<dynamic> suggestionsData = [];
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') &&
              responseData['data'] is List) {
            suggestionsData = responseData['data'] as List;
          } else if (responseData.containsKey('result') &&
              responseData['result'] == true) {
            suggestionsData = responseData['data'] as List? ?? [];
          }
        } else if (responseData is List) {
          suggestionsData = responseData;
        }

        // TaskSuggestionモデルに変換
        final suggestions = <TaskSuggestion>[];
        for (final suggestionData in suggestionsData) {
          try {
            if (suggestionData is Map<String, dynamic>) {
              suggestions.add(TaskSuggestion.fromJson(suggestionData));
            }
          } catch (e) {
            // パースエラーはログに記録してスキップ
            // ignore: avoid_print
            print('TaskSuggestionのパースエラー: $e');
          }
        }
        return suggestions;
      } else {
        // エラーレスポンスをパース
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          statusCode: response.statusCode,
          message: errorData['message'] as String? ?? 'AI提案予定の取得に失敗しました',
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
      throw ApiException(statusCode: 0, message: 'ネットワークエラー: $e', errors: null);
    }
  }

  // AI提案予定削除API
  Future<void> deleteTaskSuggestion(String uuid) async {
    try {
      final headers = await _headers;
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/task-suggestions/$uuid'),
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
          message: errorData['message'] as String? ?? 'AI提案予定の削除に失敗しました',
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
      throw ApiException(statusCode: 0, message: 'ネットワークエラー: $e', errors: null);
    }
  }

  Future<RegistrationApiResult> _postRegistrationApi({
    required String endpoint,
    required Map<String, dynamic> body,
    required Set<int> successStatusCodes,
    required String defaultSuccessMessage,
    required String defaultErrorMessage,
  }) async {
    var statusCode = 0;
    var status = RegistrationApiStatus.networkError;
    var isSuccess = false;
    String fallbackMessage() =>
        isSuccess ? defaultSuccessMessage : defaultErrorMessage;

    try {
      final headers = await _headers;
      final response = await http
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      statusCode = response.statusCode;
      status = normalizeRegistrationApiStatus(statusCode);
      isSuccess = successStatusCodes.contains(statusCode);

      final responseData = _decodeJsonObject(response.body);

      return RegistrationApiResult(
        statusCode: statusCode,
        status: status,
        message: _extractMessage(responseData, fallback: fallbackMessage()),
        data: _extractDataMap(responseData),
        errors: _extractErrorsMap(responseData),
      );
    } on TimeoutException {
      return const RegistrationApiResult(
        statusCode: 0,
        status: RegistrationApiStatus.networkError,
        message: '通信がタイムアウトしました。時間をおいて再度お試しください。',
      );
    } on FormatException {
      return RegistrationApiResult(
        statusCode: statusCode,
        status: status,
        message: fallbackMessage(),
      );
    } catch (_) {
      return RegistrationApiResult(
        statusCode: statusCode,
        status: status,
        message: fallbackMessage(),
      );
    }
  }

  Map<String, dynamic> _decodeJsonObject(String body) {
    if (body.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }

    return {};
  }

  String _extractMessage(
    Map<String, dynamic> responseData, {
    required String fallback,
  }) {
    final message = responseData['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }
    return fallback;
  }

  Map<String, dynamic>? _extractDataMap(Map<String, dynamic> responseData) {
    final data = responseData['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  Map<String, dynamic>? _extractErrorsMap(Map<String, dynamic> responseData) {
    final errors = responseData['errors'];
    if (errors is Map<String, dynamic>) {
      return errors;
    }
    if (errors is Map) {
      return errors.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}
