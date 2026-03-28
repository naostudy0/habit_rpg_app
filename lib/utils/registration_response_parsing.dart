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

String? _firstFieldError(RegistrationApiResult result, String field) {
  final errors = result.errors;
  if (errors == null) {
    return null;
  }
  final list = errors[field];
  if (list is List && list.isNotEmpty && list.first is String) {
    return list.first as String;
  }
  return null;
}

/// OTP送信API失敗時に画面へ表示するメッセージ。
String registrationSendOtpErrorMessage(RegistrationApiResult result) {
  if (result.isSuccess) {
    return '';
  }
  if (result.isConflict) {
    return result.message.isNotEmpty
        ? result.message
        : 'このメールアドレスはすでに登録されています。';
  }
  if (result.isTooManyRequests) {
    return result.message.isNotEmpty
        ? result.message
        : '送信回数が上限に達しました。しばらく時間をおいてからお試しください。';
  }
  if (result.isValidationError) {
    final emailErr = _firstFieldError(result, 'email');
    if (emailErr != null) {
      return emailErr;
    }
    return result.message.isNotEmpty
        ? result.message
        : 'メールアドレスを確認してください。';
  }
  if (result.status == RegistrationApiStatus.networkError) {
    return result.message.isNotEmpty
        ? result.message
        : '通信に失敗しました。接続を確認してください。';
  }
  return result.message.isNotEmpty
      ? result.message
      : 'ワンタイムパスワードの送信に失敗しました。';
}

/// OTP検証API失敗時に画面へ表示するメッセージ（誤コード・期限切れ・試行超過など）。
String registrationVerifyOtpErrorMessage(RegistrationApiResult result) {
  if (result.isSuccess) {
    return '';
  }
  if (result.isTooManyRequests) {
    return result.message.isNotEmpty
        ? result.message
        : '試行回数が上限に達しました。しばらく時間をおいてからお試しください。';
  }
  if (result.isValidationError) {
    final otpErr = _firstFieldError(result, 'otp');
    if (otpErr != null) {
      return otpErr;
    }
    return result.message.isNotEmpty
        ? result.message
        : 'ワンタイムパスワードが正しくないか、有効期限が切れています。';
  }
  if (result.status == RegistrationApiStatus.networkError) {
    return result.message.isNotEmpty
        ? result.message
        : '通信に失敗しました。接続を確認してください。';
  }
  return result.message.isNotEmpty
      ? result.message
      : 'ワンタイムパスワードの検証に失敗しました。';
}
