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

    testWidgets('409時にログイン誘導ボタンが表示され、ログイン画面へ遷移できる', (
      WidgetTester tester,
    ) async {
      Future<RegistrationApiResult> completeRegistration({
        required String registrationToken,
        required String name,
        required String password,
      }) async {
        return const RegistrationApiResult(
          statusCode: 409,
          status: RegistrationApiStatus.conflict,
          message: 'conflict',
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          routes: {'/login': (_) => const Scaffold(body: Text('ログイン画面'))},
          home: RegistrationPasswordSetupScreen(
            completeRegistrationRequest: completeRegistration,
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'new-user');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.tap(find.text('登録を完了'));
      await tester.pumpAndSettle();

      expect(find.text('このメールアドレスは既に登録済みです。ログイン画面へ進んでください。'), findsOneWidget);
      expect(find.text('ログインへ'), findsOneWidget);

      await tester.tap(find.text('ログインへ'));
      await tester.pumpAndSettle();

      expect(find.text('ログイン画面'), findsOneWidget);
    });

    testWidgets('正常系ではフローがcompletedへ進む', (WidgetTester tester) async {
      Future<RegistrationApiResult> completeRegistration({
        required String registrationToken,
        required String name,
        required String password,
      }) async {
        return const RegistrationApiResult(
          statusCode: 201,
          status: RegistrationApiStatus.created,
          message: 'ok',
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationPasswordSetupScreen(
            completeRegistrationRequest: completeRegistration,
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'new-user');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.tap(find.text('登録を完了'));
      await tester.pumpAndSettle();

      expect(flow.currentStep, RegistrationStep.completed);
    });
  });
}
