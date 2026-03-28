import 'package:flutter/material.dart';
import '../services/registration_flow_service.dart';
import 'registration_email_screen.dart';
import 'registration_otp_screen.dart';
import 'registration_password_setup_screen.dart';

/// 会員登録（メール・OTP・パスワード）のステップ切り替え。
class RegistrationFlowPage extends StatefulWidget {
  const RegistrationFlowPage({super.key});

  @override
  State<RegistrationFlowPage> createState() => _RegistrationFlowPageState();
}

class _RegistrationFlowPageState extends State<RegistrationFlowPage> {
  final RegistrationFlowService _flow = RegistrationFlowService();

  @override
  void initState() {
    super.initState();
    _flow.reset();
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  void _handlePopInvoked(bool didPop, Object? result) {
    if (didPop) {
      return;
    }
    if (_flow.canGoBack) {
      _flow.goBack();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _flow,
      builder: (context, _) {
        final step = _flow.currentStep;
        final canPopRoute =
            step == RegistrationStep.emailInput ||
            step == RegistrationStep.completed;

        return PopScope(
          canPop: canPopRoute,
          onPopInvokedWithResult: _handlePopInvoked,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: switch (step) {
              RegistrationStep.emailInput =>
                const KeyedSubtree(
                  key: ValueKey('reg_email'),
                  child: RegistrationEmailScreen(),
                ),
              RegistrationStep.otpVerification =>
                const KeyedSubtree(
                  key: ValueKey('reg_otp'),
                  child: RegistrationOtpScreen(),
                ),
              RegistrationStep.passwordSetup =>
                const KeyedSubtree(
                  key: ValueKey('reg_password'),
                  child: RegistrationPasswordSetupScreen(),
                ),
              RegistrationStep.completed => const KeyedSubtree(
                key: ValueKey('reg_done'),
                child: SizedBox.shrink(),
              ),
            },
          ),
        );
      },
    );
  }
}
