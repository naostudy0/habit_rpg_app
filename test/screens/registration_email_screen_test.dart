import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_rpg_app/screens/registration_email_screen.dart';
import 'package:habit_rpg_app/services/api_service.dart';
import 'package:habit_rpg_app/services/loading_service.dart';
import 'package:habit_rpg_app/services/registration_flow_service.dart';

void main() {
  group('RegistrationEmailScreen', () {
    late RegistrationFlowService flow;
    late LoadingService loading;
    final sentEmails = <String>[];

    Future<void> pumpScreen(
      WidgetTester tester, {
      required SendRegistrationOtpRequest sendRegistrationOtp,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationEmailScreen(
            sendRegistrationOtpRequest: sendRegistrationOtp,
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
      sentEmails.clear();
    });

    testWidgets('有効なメール入力で OTP送信処理が呼ばれる', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        sendRegistrationOtp: (email) async {
          sentEmails.add(email);
          return const RegistrationApiResult(
            statusCode: 200,
            status: RegistrationApiStatus.success,
            message: 'ok',
            data: {'retry_after': 60},
          );
        },
      );

      await tester.enterText(
        find.byKey(const Key('email_input')),
        '  new-user@example.com  ',
      );
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();

      expect(sentEmails, ['new-user@example.com']);
    });

    testWidgets('クライアント側バリデーションNG時は送信処理を呼ばない', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        sendRegistrationOtp: (email) async {
          sentEmails.add(email);
          return const RegistrationApiResult(
            statusCode: 200,
            status: RegistrationApiStatus.success,
            message: 'ok',
            data: {'retry_after': 60},
          );
        },
      );

      await tester.enterText(find.byKey(const Key('email_input')), '');
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();
      expect(find.text('メールアドレスを入力してください'), findsOneWidget);
      expect(sentEmails, isEmpty);
      expect(flow.currentStep, RegistrationStep.emailInput);

      await tester.enterText(find.byKey(const Key('email_input')), '   ');
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();
      expect(find.text('メールアドレスを入力してください'), findsOneWidget);
      expect(sentEmails, isEmpty);
      expect(flow.currentStep, RegistrationStep.emailInput);

      await tester.enterText(
        find.byKey(const Key('email_input')),
        'invalid-email',
      );
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();
      expect(find.text('有効なメールアドレスを入力してください'), findsOneWidget);
      expect(sentEmails, isEmpty);
      expect(flow.currentStep, RegistrationStep.emailInput);
    });

    testWidgets('成功時に OTP画面へ遷移する', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        sendRegistrationOtp: (email) async => const RegistrationApiResult(
          statusCode: 200,
          status: RegistrationApiStatus.success,
          message: 'ok',
          data: {'retry_after': 60},
        ),
      );

      expect(flow.currentStep, RegistrationStep.emailInput);
      expect(flow.email, isEmpty);

      await tester.enterText(
        find.byKey(const Key('email_input')),
        'next@example.com',
      );
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();

      expect(flow.currentStep, RegistrationStep.otpVerification);
      expect(flow.email, 'next@example.com');
      expect(flow.resendAvailableAt, isNotNull);
    });

    testWidgets('409時に既存登録メッセージを表示する', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        sendRegistrationOtp: (_) async => const RegistrationApiResult(
          statusCode: 409,
          status: RegistrationApiStatus.conflict,
          message: 'conflict',
        ),
      );

      await tester.enterText(
        find.byKey(const Key('email_input')),
        'dup@example.com',
      );
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('このメールアドレスは既に登録済みです。ログイン画面からログインしてください。'),
        findsOneWidget,
      );
      expect(flow.currentStep, RegistrationStep.emailInput);
    });

    testWidgets('422時に再入力メッセージを表示する', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        sendRegistrationOtp: (_) async => const RegistrationApiResult(
          statusCode: 422,
          status: RegistrationApiStatus.unprocessableEntity,
          message: 'validation',
        ),
      );

      await tester.enterText(
        find.byKey(const Key('email_input')),
        'bad@example.com',
      );
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();

      expect(find.text('メールアドレスの形式を確認して、もう一度入力してください。'), findsOneWidget);
      expect(flow.currentStep, RegistrationStep.emailInput);
    });

    testWidgets('429時に待機メッセージを表示する', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        sendRegistrationOtp: (_) async => const RegistrationApiResult(
          statusCode: 429,
          status: RegistrationApiStatus.tooManyRequests,
          message: 'too many requests',
        ),
      );

      await tester.enterText(
        find.byKey(const Key('email_input')),
        'slow@example.com',
      );
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();

      expect(find.text('送信が集中しています。しばらく待ってから再送してください。'), findsOneWidget);
      expect(flow.currentStep, RegistrationStep.emailInput);
    });

    testWidgets('API例外時にユーザー向けエラーを表示する', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        sendRegistrationOtp: (_) async {
          throw Exception('network down');
        },
      );

      await tester.enterText(
        find.byKey(const Key('email_input')),
        'error@example.com',
      );
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('ワンタイムパスワードの送信に失敗しました。時間をおいて再度お試しください。'),
        findsOneWidget,
      );
      expect(flow.currentStep, RegistrationStep.emailInput);
    });

    testWidgets('ローディング中は重複送信を抑止する', (WidgetTester tester) async {
      final completer = Completer<RegistrationApiResult>();
      var callCount = 0;

      await pumpScreen(
        tester,
        sendRegistrationOtp: (_) {
          callCount += 1;
          return completer.future;
        },
      );

      await tester.enterText(
        find.byKey(const Key('email_input')),
        'once@example.com',
      );
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pump();

      expect(callCount, 1);
      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('send_otp_button')),
      );
      expect(button.onPressed, isNull);

      completer.complete(
        const RegistrationApiResult(
          statusCode: 200,
          status: RegistrationApiStatus.success,
          message: 'ok',
          data: {'retry_after': 60},
        ),
      );
      await tester.pumpAndSettle();

      expect(flow.currentStep, RegistrationStep.otpVerification);
    });
  });
}
