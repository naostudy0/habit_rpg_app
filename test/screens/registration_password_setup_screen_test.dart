import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_rpg_app/screens/registration_password_setup_screen.dart';
import 'package:habit_rpg_app/services/api_service.dart';
import 'package:habit_rpg_app/services/loading_service.dart';
import 'package:habit_rpg_app/services/registration_flow_service.dart';

void main() {
  group('RegistrationPasswordSetupScreen', () {
    late RegistrationFlowService flow;
    late LoadingService loading;

    Future<void> pumpScreen(
      WidgetTester tester, {
      required CompleteRegistrationRequest completeRegistration,
      Map<String, WidgetBuilder> routes = const {},
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: routes,
          home: RegistrationPasswordSetupScreen(
            completeRegistrationRequest: completeRegistration,
            flowService: flow,
            loadingService: loading,
          ),
        ),
      );
    }

    Future<void> fillValidForm(WidgetTester tester) async {
      await tester.enterText(
        find.byKey(const Key('username_field')),
        'new-user',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('password_confirm_field')),
        'password123',
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
        resendAvailableAt: DateTime.now(),
      );
      flow.moveToPasswordSetup(registrationToken: 'token-123');
    });

    testWidgets('初期状態でpasswordSetupにいる', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        completeRegistration:
            ({
              required String registrationToken,
              required String name,
              required String password,
            }) async => const RegistrationApiResult(
              statusCode: 201,
              status: RegistrationApiStatus.created,
              message: 'ok',
            ),
      );

      expect(flow.currentStep, RegistrationStep.passwordSetup);
      expect(find.byKey(const Key('username_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('password_confirm_field')), findsOneWidget);
    });

    testWidgets('空入力でバリデーションエラーが表示される', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        completeRegistration:
            ({
              required String registrationToken,
              required String name,
              required String password,
            }) async => const RegistrationApiResult(
              statusCode: 201,
              status: RegistrationApiStatus.created,
              message: 'ok',
            ),
      );

      await tester.tap(find.byKey(const Key('registration_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('表示名を入力してください'), findsOneWidget);
      expect(find.text('パスワードを入力してください'), findsOneWidget);
      expect(find.text('確認用パスワードを入力してください'), findsOneWidget);
      expect(flow.currentStep, RegistrationStep.passwordSetup);
    });

    testWidgets('短すぎるパスワードでバリデーションエラーが表示される', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        completeRegistration:
            ({
              required String registrationToken,
              required String name,
              required String password,
            }) async => const RegistrationApiResult(
              statusCode: 201,
              status: RegistrationApiStatus.created,
              message: 'ok',
            ),
      );

      await tester.enterText(
        find.byKey(const Key('username_field')),
        'new-user',
      );
      await tester.enterText(find.byKey(const Key('password_field')), 'short');
      await tester.enterText(
        find.byKey(const Key('password_confirm_field')),
        'short',
      );
      await tester.tap(find.byKey(const Key('registration_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('パスワードは8文字以上で入力してください'), findsOneWidget);
      expect(flow.currentStep, RegistrationStep.passwordSetup);
    });

    testWidgets('確認用パスワード不一致でバリデーションエラーが表示される', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        completeRegistration:
            ({
              required String registrationToken,
              required String name,
              required String password,
            }) async => const RegistrationApiResult(
              statusCode: 201,
              status: RegistrationApiStatus.created,
              message: 'ok',
            ),
      );

      await tester.enterText(
        find.byKey(const Key('username_field')),
        'new-user',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('password_confirm_field')),
        'password321',
      );
      await tester.tap(find.byKey(const Key('registration_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('パスワードが一致しません'), findsOneWidget);
      expect(flow.currentStep, RegistrationStep.passwordSetup);
    });

    testWidgets('409時にログイン誘導ボタンが表示され、ログイン画面へ遷移できる', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        routes: {'/login': (_) => const Scaffold(body: Text('ログイン画面'))},
        completeRegistration:
            ({
              required String registrationToken,
              required String name,
              required String password,
            }) async => const RegistrationApiResult(
              statusCode: 409,
              status: RegistrationApiStatus.conflict,
              message: 'conflict',
            ),
      );

      await fillValidForm(tester);
      await tester.tap(find.byKey(const Key('registration_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('このメールアドレスは既に登録済みです。ログイン画面へ進んでください。'), findsOneWidget);
      expect(find.text('ログインへ'), findsOneWidget);
      expect(flow.currentStep, RegistrationStep.passwordSetup);

      await tester.tap(find.text('ログインへ'));
      await tester.pumpAndSettle();

      expect(find.text('ログイン画面'), findsOneWidget);
    });

    testWidgets('API例外時はフォームエラーを表示する', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        completeRegistration:
            ({
              required String registrationToken,
              required String name,
              required String password,
            }) async {
              throw Exception('network down');
            },
      );

      await fillValidForm(tester);
      await tester.tap(find.byKey(const Key('registration_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('会員登録に失敗しました。時間をおいて再度お試しください。'), findsOneWidget);
      expect(flow.currentStep, RegistrationStep.passwordSetup);
    });

    testWidgets('400レスポンス時は汎用エラーメッセージを表示する', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        completeRegistration:
            ({
              required String registrationToken,
              required String name,
              required String password,
            }) async => const RegistrationApiResult(
              statusCode: 400,
              status: RegistrationApiStatus.unknownError,
              message: '',
            ),
      );

      await fillValidForm(tester);
      await tester.tap(find.byKey(const Key('registration_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('会員登録に失敗しました。時間をおいて再度お試しください。'), findsOneWidget);
      expect(flow.currentStep, RegistrationStep.passwordSetup);
    });

    testWidgets('500レスポンス時は汎用エラーメッセージを表示する', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        completeRegistration:
            ({
              required String registrationToken,
              required String name,
              required String password,
            }) async => const RegistrationApiResult(
              statusCode: 500,
              status: RegistrationApiStatus.unknownError,
              message: '',
            ),
      );

      await fillValidForm(tester);
      await tester.tap(find.byKey(const Key('registration_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('会員登録に失敗しました。時間をおいて再度お試しください。'), findsOneWidget);
      expect(flow.currentStep, RegistrationStep.passwordSetup);
    });

    testWidgets('正常系ではフローがcompletedへ進む', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        completeRegistration:
            ({
              required String registrationToken,
              required String name,
              required String password,
            }) async => const RegistrationApiResult(
              statusCode: 201,
              status: RegistrationApiStatus.created,
              message: 'ok',
            ),
      );

      await fillValidForm(tester);
      await tester.tap(find.byKey(const Key('registration_submit_button')));
      await tester.pumpAndSettle();

      expect(flow.currentStep, RegistrationStep.completed);
    });
  });
}
