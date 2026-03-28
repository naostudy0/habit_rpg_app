import '../services/api_service.dart';

/// 会員登録APIの `data` から再送可能時刻を解釈する。
///
/// バックエンドが `resend_available_at`（ISO8601）または
/// `retry_after`（秒）のみ返す場合にも対応する。
DateTime? parseResendAvailableAtFromData(
  Map<String, dynamic>? data, {
  DateTime? reference,
}) {
  final now = reference ?? DateTime.now();
  if (data == null) {
    return null;
  }

  final iso = data['resend_available_at'];
  if (iso is String && iso.isNotEmpty) {
    try {
      return DateTime.parse(iso);
    } catch (_) {
      // 続けてフォールバック
    }
  }

  final retryAfter = data['retry_after'];
  if (retryAfter is int) {
    return now.add(Duration(seconds: retryAfter));
  }
  if (retryAfter is num) {
    return now.add(Duration(seconds: retryAfter.toInt()));
  }

  final cooldown = data['cooldown_seconds'];
  if (cooldown is int) {
    return now.add(Duration(seconds: cooldown));
  }
  if (cooldown is num) {
    return now.add(Duration(seconds: cooldown.toInt()));
  }

  return null;
}

/// OTP検証成功レスポンスの `data` から登録トークンを取得する。
String? parseRegistrationTokenFromData(Map<String, dynamic>? data) {
  if (data == null) {
    return null;
  }
  final token = data['registration_token'];
  if (token is String && token.trim().isNotEmpty) {
    return token.trim();
  }
  return null;
}

/// OTP送信API失敗時に画面へ表示するメッセージ。
String registrationSendOtpErrorMessage(RegistrationApiResult result) {
  if (result.isSuccess) {
    return '';
  }
  if (result.isConflict) {
    return 'このメールアドレスは既に登録済みです。ログイン画面からログインしてください。';
  }
  if (result.isTooManyRequests) {
    return '送信が集中しています。しばらく待ってから再送してください。';
  }
  if (result.isValidationError) {
    return 'メールアドレスの形式を確認して、もう一度入力してください。';
  }
  if (result.status == RegistrationApiStatus.networkError) {
    return result.message.isNotEmpty
        ? result.message
        : '通信に失敗しました。接続を確認してください。';
  }
  return 'ワンタイムパスワードの送信に失敗しました。時間をおいて再度お試しください。';
}

/// OTP検証API失敗時に画面へ表示するメッセージ（誤コード・期限切れ・試行超過など）。
String registrationVerifyOtpErrorMessage(RegistrationApiResult result) {
  if (result.isSuccess) {
    return '';
  }
  if (result.isTooManyRequests) {
    return '試行回数の上限に達しました。しばらく待ってからコードを再送してください。';
  }
  if (result.isValidationError) {
    return 'コードが正しくないか有効期限切れです。再入力するか、コードを再送してください。';
  }
  if (result.status == RegistrationApiStatus.networkError) {
    return result.message.isNotEmpty
        ? result.message
        : '通信に失敗しました。接続を確認してください。';
  }
  return 'ワンタイムパスワードの検証に失敗しました。時間をおいて再度お試しください。';
}
