import 'package:flutter_test/flutter_test.dart';
import 'package:habit_rpg_app/services/registration_flow_service.dart';

void main() {
  group('RegistrationFlowService', () {
    late RegistrationFlowService service;

    setUp(() {
      service = RegistrationFlowService();
      service.removeAllListeners();
      service.reset();
    });

    test('初期状態が正しい', () {
      expect(service.currentStep, RegistrationStep.emailInput);
      expect(service.email, '');
      expect(service.registrationToken, isNull);
      expect(service.resendAvailableAt, isNull);
      expect(service.canGoBack, false);
      expect(service.hasEmail, false);
      expect(service.hasRegistrationToken, false);
    });

    test('OTP送信成功でotpVerificationに遷移し状態が更新される', () {
      final resendAt = DateTime.now().add(const Duration(seconds: 60));

      service.moveToOtpVerification(
        email: ' user@example.com ',
        resendAvailableAt: resendAt,
      );

      expect(service.currentStep, RegistrationStep.otpVerification);
      expect(service.email, 'user@example.com');
      expect(service.resendAvailableAt, resendAt);
      expect(service.registrationToken, isNull);
      expect(service.canGoBack, true);
      expect(service.hasEmail, true);
    });

    test('OTP検証成功でpasswordSetupに遷移しregistrationTokenを保持する', () {
      service.moveToOtpVerification(
        email: 'user@example.com',
        resendAvailableAt: DateTime.now(),
      );

      service.moveToPasswordSetup(registrationToken: ' token-123 ');

      expect(service.currentStep, RegistrationStep.passwordSetup);
      expect(service.registrationToken, 'token-123');
      expect(service.hasRegistrationToken, true);
      expect(service.canGoBack, true);
    });

    test('moveToPasswordSetupは空白トークンでArgumentErrorを投げて状態を維持する', () {
      final resendAt = DateTime.now().add(const Duration(seconds: 60));
      service.moveToOtpVerification(
        email: 'user@example.com',
        resendAvailableAt: resendAt,
      );

      expect(
        () => service.moveToPasswordSetup(registrationToken: ''),
        throwsArgumentError,
      );
      expect(
        () => service.moveToPasswordSetup(registrationToken: '   '),
        throwsArgumentError,
      );

      expect(service.currentStep, RegistrationStep.otpVerification);
      expect(service.registrationToken, isNull);
      expect(service.email, 'user@example.com');
      expect(service.resendAvailableAt, resendAt);
    });

    test('passwordSetupから戻るとotpVerificationに戻りtokenを破棄する', () {
      service.moveToOtpVerification(
        email: 'user@example.com',
        resendAvailableAt: DateTime.now(),
      );
      service.moveToPasswordSetup(registrationToken: 'token-123');

      service.goBack();

      expect(service.currentStep, RegistrationStep.otpVerification);
      expect(service.registrationToken, isNull);
      expect(service.email, 'user@example.com');
    });

    test('otpVerificationから戻るとemailInputに戻る', () {
      final resendAt = DateTime.now().add(const Duration(seconds: 60));
      service.moveToOtpVerification(
        email: 'user@example.com',
        resendAvailableAt: resendAt,
      );

      service.goBack();

      expect(service.currentStep, RegistrationStep.emailInput);
      expect(service.email, 'user@example.com');
      expect(service.resendAvailableAt, isNull);
    });

    test('emailInputからgoBackしても状態が変わらない', () {
      service.setEmail('user@example.com');

      service.goBack();

      expect(service.currentStep, RegistrationStep.emailInput);
      expect(service.email, 'user@example.com');
      expect(service.registrationToken, isNull);
      expect(service.resendAvailableAt, isNull);
    });

    test('本登録完了でcompletedに遷移し機密状態をクリアする', () {
      service.moveToOtpVerification(
        email: 'user@example.com',
        resendAvailableAt: DateTime.now(),
      );
      service.moveToPasswordSetup(registrationToken: 'token-123');

      service.completeRegistration();

      expect(service.currentStep, RegistrationStep.completed);
      expect(service.registrationToken, isNull);
      expect(service.resendAvailableAt, isNull);
      expect(service.canGoBack, false);
    });

    test('completedからgoBackしても状態が変わらない', () {
      service.moveToOtpVerification(
        email: 'user@example.com',
        resendAvailableAt: DateTime.now(),
      );
      service.moveToPasswordSetup(registrationToken: 'token-123');
      service.completeRegistration();

      service.goBack();

      expect(service.currentStep, RegistrationStep.completed);
      expect(service.email, 'user@example.com');
      expect(service.registrationToken, isNull);
      expect(service.resendAvailableAt, isNull);
    });

    test('resend可能判定と残り時間が正しく計算される', () {
      final now = DateTime(2026, 3, 27, 12, 0, 0);
      service.moveToOtpVerification(
        email: 'user@example.com',
        resendAvailableAt: now.add(const Duration(seconds: 30)),
      );

      expect(service.canResendOtp(now: now), false);
      expect(service.resendRemaining(now: now), const Duration(seconds: 30));
      expect(
        service.canResendOtp(now: now.add(const Duration(seconds: 30))),
        true,
      );
      expect(
        service.resendRemaining(now: now.add(const Duration(seconds: 30))),
        Duration.zero,
      );
      expect(
        service.canResendOtp(now: now.add(const Duration(seconds: 31))),
        true,
      );
      expect(
        service.resendRemaining(now: now.add(const Duration(seconds: 31))),
        Duration.zero,
      );
    });

    test('singletonとして同じインスタンスを返す', () {
      final another = RegistrationFlowService();
      expect(identical(service, another), true);
    });

    test('dispose呼び出し後もsingletonの状態更新が可能', () {
      var notifyCount = 0;
      final unregister = service.registerListener(() {
        notifyCount++;
      });

      service.dispose();
      service.setEmail('user@example.com');
      unregister();

      expect(service.email, 'user@example.com');
      expect(notifyCount, 1);
    });
  });
}
