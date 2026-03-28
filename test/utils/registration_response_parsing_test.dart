import 'package:flutter_test/flutter_test.dart';
import 'package:habit_rpg_app/services/api_service.dart';
import 'package:habit_rpg_app/utils/registration_response_parsing.dart';

void main() {
  group('parseResendAvailableAtFromData', () {
    test('resend_available_at が ISO8601 のときパースする', () {
      final ref = DateTime.utc(2026, 3, 27, 12, 0, 0);
      final at = parseResendAvailableAtFromData({
        'resend_available_at': '2026-03-27T12:01:00.000Z',
      }, reference: ref);
      expect(at, DateTime.parse('2026-03-27T12:01:00.000Z'));
    });

    test('壊れた resend_available_at は retry_after にフォールバックする', () {
      final ref = DateTime.utc(2026, 3, 27, 12, 0, 0);
      final at = parseResendAvailableAtFromData({
        'resend_available_at': 'not-a-date',
        'retry_after': 45,
      }, reference: ref);
      expect(at, ref.add(const Duration(seconds: 45)));
    });

    test('retry_after が秒数のとき reference から加算する', () {
      final ref = DateTime.utc(2026, 3, 27, 12, 0, 0);
      final at = parseResendAvailableAtFromData({
        'retry_after': 45,
      }, reference: ref);
      expect(at, ref.add(const Duration(seconds: 45)));
    });

    test('cooldown_seconds にも対応する', () {
      final ref = DateTime.utc(2026, 3, 27, 12, 0, 0);
      final at = parseResendAvailableAtFromData({
        'cooldown_seconds': 30,
      }, reference: ref);
      expect(at, ref.add(const Duration(seconds: 30)));
    });

    test('data が null のとき null', () {
      expect(parseResendAvailableAtFromData(null), isNull);
    });
  });

  group('parseRegistrationTokenFromData', () {
    test('registration_token を返す', () {
      expect(
        parseRegistrationTokenFromData({'registration_token': ' abc '}),
        'abc',
      );
    });

    test('空や欠落のとき null', () {
      expect(parseRegistrationTokenFromData(null), isNull);
      expect(
        parseRegistrationTokenFromData({'registration_token': ''}),
        isNull,
      );
    });
  });

  group('registrationSendOtpErrorMessage', () {
    test('成功時は空文字', () {
      const r = RegistrationApiResult(
        statusCode: 200,
        status: RegistrationApiStatus.success,
        message: 'ok',
      );
      expect(registrationSendOtpErrorMessage(r), '');
    });

    test('409 はログイン誘導の固定文言', () {
      const r = RegistrationApiResult(
        statusCode: 409,
        status: RegistrationApiStatus.conflict,
        message: '既に登録済みです',
      );
      expect(
        registrationSendOtpErrorMessage(r),
        'このメールアドレスは既に登録済みです。ログイン画面からログインしてください。',
      );
    });

    test('422 は再入力促しの固定文言', () {
      const r = RegistrationApiResult(
        statusCode: 422,
        status: RegistrationApiStatus.unprocessableEntity,
        message: 'validation',
        errors: {
          'email': ['形式が不正です'],
        },
      );
      expect(
        registrationSendOtpErrorMessage(r),
        'メールアドレスの形式を確認して、もう一度入力してください。',
      );
    });

    test('networkError は接続確認の文言', () {
      const r = RegistrationApiResult(
        statusCode: 0,
        status: RegistrationApiStatus.networkError,
        message: '',
      );
      expect(
        registrationSendOtpErrorMessage(r),
        '通信に失敗しました。接続を確認してください。',
      );
    });

    test('unknownError はデフォルト失敗文言', () {
      const r = RegistrationApiResult(
        statusCode: 500,
        status: RegistrationApiStatus.unknownError,
        message: '',
      );
      expect(
        registrationSendOtpErrorMessage(r),
        'ワンタイムパスワードの送信に失敗しました。時間をおいて再度お試しください。',
      );
    });

    test('想定外ステータスコード(418)はデフォルト失敗文言', () {
      const r = RegistrationApiResult(
        statusCode: 418,
        status: RegistrationApiStatus.unknownError,
        message: '',
      );
      expect(
        registrationSendOtpErrorMessage(r),
        'ワンタイムパスワードの送信に失敗しました。時間をおいて再度お試しください。',
      );
    });
  });

  group('registrationVerifyOtpErrorMessage', () {
    test('429 は試行超過の文言', () {
      const r = RegistrationApiResult(
        statusCode: 429,
        status: RegistrationApiStatus.tooManyRequests,
        message: '',
      );
      expect(
        registrationVerifyOtpErrorMessage(r),
        '試行回数の上限に達しました。しばらく待ってからコードを再送してください。',
      );
    });

    test('422 は再入力/再送案内の固定文言', () {
      const r = RegistrationApiResult(
        statusCode: 422,
        status: RegistrationApiStatus.unprocessableEntity,
        message: 'ng',
        errors: {
          'otp': ['コードが違います'],
        },
      );
      expect(
        registrationVerifyOtpErrorMessage(r),
        'コードが正しくないか有効期限切れです。再入力するか、コードを再送してください。',
      );
    });

    test('networkError は接続確認の文言', () {
      const r = RegistrationApiResult(
        statusCode: 0,
        status: RegistrationApiStatus.networkError,
        message: '',
      );
      expect(
        registrationVerifyOtpErrorMessage(r),
        '通信に失敗しました。接続を確認してください。',
      );
    });

    test('unknownError はデフォルト失敗文言', () {
      const r = RegistrationApiResult(
        statusCode: 500,
        status: RegistrationApiStatus.unknownError,
        message: '',
      );
      expect(
        registrationVerifyOtpErrorMessage(r),
        'ワンタイムパスワードの検証に失敗しました。時間をおいて再度お試しください。',
      );
    });
  });
}
