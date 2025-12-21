import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'api_service.dart';

/// エラータイプ
enum ErrorType {
  network, // ネットワークエラー
  api, // APIエラー
  validation, // バリデーションエラー
  authentication, // 認証エラー
  permission, // 権限エラー
  notFound, // リソースが見つからない
  server, // サーバーエラー
  unknown, // 不明なエラー
}

/// 共通エラーハンドリングサービス
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// エラータイプを判定
  ErrorType _getErrorType(dynamic error) {
    if (error is ApiException) {
      final statusCode = error.statusCode;
      if (statusCode == 401) {
        return ErrorType.authentication;
      } else if (statusCode == 403) {
        return ErrorType.permission;
      } else if (statusCode == 404) {
        return ErrorType.notFound;
      } else if (statusCode >= 500) {
        return ErrorType.server;
      } else if (statusCode >= 400) {
        if (error.errors != null && error.errors!.isNotEmpty) {
          return ErrorType.validation;
        }
        return ErrorType.api;
      }
      return ErrorType.api;
    } else if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('network')) {
      return ErrorType.network;
    }
    return ErrorType.unknown;
  }

  /// ユーザーフレンドリーなエラーメッセージを取得
  String getUserFriendlyMessage(dynamic error) {
    final errorType = _getErrorType(error);

    switch (errorType) {
      case ErrorType.network:
        return 'ネットワークに接続できません。インターネット接続を確認してください。';
      case ErrorType.authentication:
        return '認証に失敗しました。再度ログインしてください。';
      case ErrorType.permission:
        return 'この操作を実行する権限がありません。';
      case ErrorType.notFound:
        return 'リソースが見つかりませんでした。';
      case ErrorType.server:
        return 'サーバーでエラーが発生しました。しばらく時間をおいてから再度お試しください。';
      case ErrorType.validation:
        if (error is ApiException) {
          return error.getErrorMessage();
        }
        return '入力内容に誤りがあります。';
      case ErrorType.api:
        if (error is ApiException) {
          return error.getErrorMessage();
        }
        return 'リクエストの処理に失敗しました。';
      case ErrorType.unknown:
      default:
        return '予期しないエラーが発生しました。';
    }
  }

  /// エラーログを出力
  void logError(dynamic error, {String? context, StackTrace? stackTrace}) {
    final errorType = _getErrorType(error);
    final message = getUserFriendlyMessage(error);

    // ログレベルを整数値で指定（1000=SEVERE, 900=WARNING, 800=INFO）
    final logLevel = _getLogLevel(errorType);

    developer.log(
      'Error occurred: $message',
      name: 'ErrorHandler',
      error: error,
      stackTrace: stackTrace,
      level: logLevel,
    );

    // コンテキスト情報がある場合は追加でログ出力
    if (context != null) {
      developer.log(
        'Context: $context',
        name: 'ErrorHandler',
        level: 800, // INFO level
      );
    }
  }

  /// エラータイプに応じたログレベルを取得（整数値）
  int _getLogLevel(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.server:
      case ErrorType.unknown:
        return 1000; // SEVERE
      case ErrorType.authentication:
      case ErrorType.permission:
        return 900; // WARNING
      case ErrorType.network:
      case ErrorType.api:
      case ErrorType.validation:
      case ErrorType.notFound:
      default:
        return 800; // INFO
    }
  }

  /// エラーを処理してSnackBarを表示
  void handleError(
    BuildContext context,
    dynamic error, {
    String? contextMessage,
    StackTrace? stackTrace,
    Duration? duration,
  }) {
    // エラーログを出力
    logError(error, context: contextMessage, stackTrace: stackTrace);

    // ユーザーフレンドリーなメッセージを取得
    final message = getUserFriendlyMessage(error);
    final errorType = _getErrorType(error);

    // SnackBarの色を決定
    Color backgroundColor;
    switch (errorType) {
      case ErrorType.network:
      case ErrorType.server:
        backgroundColor = Colors.orange;
        break;
      case ErrorType.authentication:
      case ErrorType.permission:
        backgroundColor = Colors.amber;
        break;
      case ErrorType.validation:
        backgroundColor = Colors.blue;
        break;
      case ErrorType.api:
      case ErrorType.notFound:
      case ErrorType.unknown:
      default:
        backgroundColor = Colors.red;
        break;
    }

    // SnackBarを表示
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration ?? const Duration(seconds: 5),
          action: SnackBarAction(
            label: '閉じる',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  /// エラーを処理してダイアログを表示
  void handleErrorWithDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    String? contextMessage,
    StackTrace? stackTrace,
  }) {
    // エラーログを出力
    logError(error, context: contextMessage, stackTrace: stackTrace);

    // ユーザーフレンドリーなメッセージを取得
    final message = getUserFriendlyMessage(error);
    final errorType = _getErrorType(error);

    // ダイアログのタイトルを決定
    final dialogTitle = title ?? _getDialogTitle(errorType);

    // ダイアログを表示
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(dialogTitle),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          );
        },
      );
    }
  }

  /// エラータイプに応じたダイアログタイトルを取得
  String _getDialogTitle(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.network:
        return 'ネットワークエラー';
      case ErrorType.authentication:
        return '認証エラー';
      case ErrorType.permission:
        return '権限エラー';
      case ErrorType.notFound:
        return '見つかりません';
      case ErrorType.server:
        return 'サーバーエラー';
      case ErrorType.validation:
        return '入力エラー';
      case ErrorType.api:
        return 'エラー';
      case ErrorType.unknown:
      default:
        return 'エラーが発生しました';
    }
  }

  /// エラーメッセージのみを取得（ログ出力なし）
  String getErrorMessage(dynamic error) {
    return getUserFriendlyMessage(error);
  }

  /// 特定のフィールドのエラーメッセージを取得（ApiExceptionの場合）
  String? getFieldError(dynamic error, String field) {
    if (error is ApiException) {
      return error.getFieldError(field);
    }
    return null;
  }
}
