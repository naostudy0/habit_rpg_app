import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_rpg_app/screens/registration_flow_page.dart';
import 'package:habit_rpg_app/services/loading_service.dart';
import 'package:habit_rpg_app/services/registration_flow_service.dart';

void main() {
  group('RegistrationFlowPage', () {
    late RegistrationFlowService flow;
    late LoadingService loading;

    Future<void> pumpHostApp(
      WidgetTester tester, {
      void Function(RegistrationFlowService flowService)? onFlowDispose,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RegistrationFlowPage(
                          flowService: flow,
                          loadingService: loading,
                          onFlowDispose: onFlowDispose,
                        ),
                      ),
                    );
                  },
                  child: const Text('open-flow'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open-flow'));
      await tester.pumpAndSettle();
    }

    setUp(() {
      flow = RegistrationFlowService();
      loading = LoadingService();
      flow.removeAllListeners();
      flow.reset();
      loading.clearAll();
    });

    testWidgets('ステップごとに正しい画面が表示される', (WidgetTester tester) async {
      await pumpHostApp(tester);

      expect(find.byKey(const ValueKey('reg_email')), findsOneWidget);

      flow.moveToOtpVerification(
        email: 'new-user@example.com',
        resendAvailableAt: DateTime.now(),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('reg_otp')), findsOneWidget);

      flow.moveToPasswordSetup(registrationToken: 'token-123');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('reg_password')), findsOneWidget);

      flow.completeRegistration();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('reg_done')), findsOneWidget);
    });

    testWidgets('戻れるステップでは1段戻る', (WidgetTester tester) async {
      await pumpHostApp(tester);

      flow.moveToOtpVerification(
        email: 'new-user@example.com',
        resendAvailableAt: DateTime.now(),
      );
      flow.moveToPasswordSetup(registrationToken: 'token-123');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('reg_password')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(flow.currentStep, RegistrationStep.otpVerification);
      expect(find.byKey(const ValueKey('reg_otp')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(flow.currentStep, RegistrationStep.emailInput);
      expect(find.byKey(const ValueKey('reg_email')), findsOneWidget);
    });

    testWidgets('先頭ステップではページを閉じる', (WidgetTester tester) async {
      await pumpHostApp(tester);
      expect(find.byKey(const ValueKey('reg_email')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('open-flow'), findsOneWidget);
      expect(find.byKey(const ValueKey('reg_email')), findsNothing);
    });

    testWidgets('ローディング中は先頭ステップで戻る操作を無効化する', (WidgetTester tester) async {
      await pumpHostApp(tester);
      expect(find.byKey(const ValueKey('reg_email')), findsOneWidget);

      loading.setLoading('registration_send_otp', true);
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.byKey(const ValueKey('reg_email')), findsOneWidget);
      expect(find.text('open-flow'), findsNothing);
      expect(flow.currentStep, RegistrationStep.emailInput);
    });

    testWidgets('ローディング中は戻れるステップでも戻らない', (WidgetTester tester) async {
      await pumpHostApp(tester);

      flow.moveToOtpVerification(
        email: 'new-user@example.com',
        resendAvailableAt: DateTime.now(),
      );
      await tester.pumpAndSettle();
      expect(flow.currentStep, RegistrationStep.otpVerification);
      expect(find.byKey(const ValueKey('reg_otp')), findsOneWidget);

      loading.setLoading('registration_send_otp', true);
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(flow.currentStep, RegistrationStep.otpVerification);
      expect(find.byKey(const ValueKey('reg_otp')), findsOneWidget);
      expect(find.text('open-flow'), findsNothing);
    });

    testWidgets('dispose時にonFlowDisposeコールバックが呼ばれる', (
      WidgetTester tester,
    ) async {
      var disposed = false;
      await pumpHostApp(
        tester,
        onFlowDispose: (_) {
          disposed = true;
        },
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(disposed, isTrue);
    });

    testWidgets('DIなしでも開閉時に例外なく動作する', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RegistrationFlowPage(),
                      ),
                    );
                  },
                  child: const Text('open-default-flow'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open-default-flow'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('reg_email')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('open-default-flow'), findsOneWidget);
      expect(find.byKey(const ValueKey('reg_email')), findsNothing);
    });
  });
}
