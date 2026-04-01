import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_rpg_app/screens/registration_otp_screen.dart';
import 'package:habit_rpg_app/services/api_service.dart';
import 'package:habit_rpg_app/services/loading_service.dart';
import 'package:habit_rpg_app/services/registration_flow_service.dart';

void main() {
  group('RegistrationOtpScreen', () {
    late RegistrationFlowService flow;
    late LoadingService loading;

    Future<void> pumpScreen(
      WidgetTester tester, {
      VerifyRegistrationOtpRequest? verifyRegistrationOtp,
      SendRegistrationOtpRequest? sendRegistrationOtp,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationOtpScreen(
            verifyRegistrationOtpRequest:
                verifyRegistrationOtp ??
                ({required String email, required String otp}) async =>
                    const RegistrationApiResult(
                      statusCode: 200,
                      status: RegistrationApiStatus.success,
                      message: 'ok',
                      data: {'registration_token': 'token-default'},
                    ),
            sendRegistrationOtpRequest:
                sendRegistrationOtp ??
                (_) async => const RegistrationApiResult(
                  statusCode: 200,
                  status: RegistrationApiStatus.success,
                  message: 'ok',
                  data: {'retry_after': 60},
                ),
            flowService: flow,
            loadingService: loading,
          ),
        ),
      );
    }

    setUp(() {
      flow = RegistrationFlowService();
      loading = LoadingService();
      flow.removeAllListeners();
      flow.reset();
      loading.clearAll();
      flow.moveToOtpVerification(
        email: 'new-user@example.com',
        resendAvailableAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
    });

    testWidgets('正しいOTPで registration_token を受け取り passwordSetup に遷移する', (
      WidgetTester tester,
    ) async {
      String? requestedEmail;
      String? requestedOtp;

      await pumpScreen(
        tester,
        verifyRegistrationOtp:
            ({required String email, required String otp}) async {
              requestedEmail = email;
              requestedOtp = otp;
              return const RegistrationApiResult(
                statusCode: 200,
                status: RegistrationApiStatus.success,
                message: 'ok',
                data: {'registration_token': 'token-123'},
              );
            },
      );

      expect(flow.currentStep, RegistrationStep.otpVerification);
      await tester.enterText(find.byKey(const Key('otp_input')), '123456');
      await tester.tap(find.byKey(const Key('otp_verify_button')));
      await tester.pumpAndSettle();

      expect(requestedEmail, 'new-user@example.com');
      expect(requestedOtp, '123456');
      expect(flow.currentStep, RegistrationStep.passwordSetup);
      expect(flow.registrationToken, 'token-123');
    });

    testWidgets('再送成功時にクールダウン情報が反映される', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        sendRegistrationOtp: (_) async => const RegistrationApiResult(
          statusCode: 200,
          status: RegistrationApiStatus.success,
          message: 'ok',
          data: {'retry_after': 120},
        ),
      );

      await tester.tap(find.byKey(const Key('otp_resend_button')));
      await tester.pumpAndSettle();

      expect(flow.currentStep, RegistrationStep.otpVerification);
      expect(flow.canResendOtp(), isFalse);
      expect(flow.resendRemaining().inSeconds, greaterThanOrEqualTo(110));
      expect(find.textContaining('再送まであと'), findsOneWidget);
    });

    testWidgets('誤OTP(422)時にメッセージを表示して状態維持する', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        verifyRegistrationOtp:
            ({required String email, required String otp}) async =>
                const RegistrationApiResult(
                  statusCode: 422,
                  status: RegistrationApiStatus.unprocessableEntity,
                  message: 'validation',
                ),
      );

      await tester.enterText(find.byKey(const Key('otp_input')), '123456');
      await tester.tap(find.byKey(const Key('otp_verify_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('コードが正しくないか有効期限切れです。再入力するか、コードを再送してください。'),
        findsOneWidget,
      );
      expect(flow.currentStep, RegistrationStep.otpVerification);
    });

    testWidgets('試行超過(429)時にメッセージを表示して状態維持する', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        verifyRegistrationOtp:
            ({required String email, required String otp}) async =>
                const RegistrationApiResult(
                  statusCode: 429,
                  status: RegistrationApiStatus.tooManyRequests,
                  message: 'too many requests',
                ),
      );

      await tester.enterText(find.byKey(const Key('otp_input')), '123456');
      await tester.tap(find.byKey(const Key('otp_verify_button')));
      await tester.pumpAndSettle();

      expect(find.text('試行回数の上限に達しました。しばらく待ってからコードを再送してください。'), findsOneWidget);
      expect(flow.currentStep, RegistrationStep.otpVerification);
    });

    testWidgets('OTP検証API例外時にユーザー向けエラーを表示する', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        verifyRegistrationOtp:
            ({required String email, required String otp}) async {
              throw Exception('network down');
            },
      );

      await tester.enterText(find.byKey(const Key('otp_input')), '123456');
      await tester.tap(find.byKey(const Key('otp_verify_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('ワンタイムパスワードの検証に失敗しました。時間をおいて再度お試しください。'),
        findsOneWidget,
      );
      expect(flow.currentStep, RegistrationStep.otpVerification);
    });

    testWidgets('再送失敗(429)時にメッセージを表示して状態維持する', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        sendRegistrationOtp: (_) async => const RegistrationApiResult(
          statusCode: 429,
          status: RegistrationApiStatus.tooManyRequests,
          message: 'too many requests',
        ),
      );

      await tester.tap(find.byKey(const Key('otp_resend_button')));
      await tester.pumpAndSettle();

      expect(find.text('送信が集中しています。しばらく待ってから再送してください。'), findsOneWidget);
      expect(flow.currentStep, RegistrationStep.otpVerification);
    });

    testWidgets('再送API例外時にユーザー向けエラーを表示する', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        sendRegistrationOtp: (_) async {
          throw Exception('network down');
        },
      );

      await tester.tap(find.byKey(const Key('otp_resend_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('ワンタイムパスワードの再送に失敗しました。時間をおいて再度お試しください。'),
        findsOneWidget,
      );
      expect(flow.currentStep, RegistrationStep.otpVerification);
    });

    testWidgets('ローディング中は戻る/重複操作が抑止される', (WidgetTester tester) async {
      final completer = Completer<RegistrationApiResult>();
      var verifyCallCount = 0;
      var resendCallCount = 0;

      await pumpScreen(
        tester,
        verifyRegistrationOtp: ({required String email, required String otp}) {
          verifyCallCount += 1;
          return completer.future;
        },
        sendRegistrationOtp: (_) async {
          resendCallCount += 1;
          return const RegistrationApiResult(
            statusCode: 200,
            status: RegistrationApiStatus.success,
            message: 'ok',
            data: {'retry_after': 60},
          );
        },
      );

      await tester.enterText(find.byKey(const Key('otp_input')), '123456');
      await tester.tap(find.byKey(const Key('otp_verify_button')));
      await tester.pump();

      expect(verifyCallCount, 1);
      expect(resendCallCount, 0);

      final verifyButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('otp_verify_button')),
      );
      final resendButton = tester.widget<TextButton>(
        find.byKey(const Key('otp_resend_button')),
      );
      final backButton = tester.widget<IconButton>(
        find.byKey(const Key('otp_back_button')),
      );
      expect(verifyButton.onPressed, isNull);
      expect(resendButton.onPressed, isNull);
      expect(backButton.onPressed, isNull);

      completer.complete(
        const RegistrationApiResult(
          statusCode: 200,
          status: RegistrationApiStatus.success,
          message: 'ok',
          data: {'registration_token': 'token-after-loading'},
        ),
      );
      await tester.pumpAndSettle();

      expect(flow.currentStep, RegistrationStep.passwordSetup);
      expect(flow.registrationToken, 'token-after-loading');
    });
  });
}
