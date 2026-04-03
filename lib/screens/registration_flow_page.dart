import 'package:flutter/material.dart';
import '../services/loading_service.dart';
import '../services/registration_flow_service.dart';
import 'registration_completed_screen.dart';
import 'registration_email_screen.dart';
import 'registration_otp_screen.dart';
import 'registration_password_setup_screen.dart';

/// 会員登録（メール・OTP・パスワード）のステップ切り替え。
class RegistrationFlowPage extends StatefulWidget {
  final RegistrationFlowService? flowService;
  final LoadingService? loadingService;
  final void Function(RegistrationFlowService flowService)? onFlowDispose;

  const RegistrationFlowPage({
    super.key,
    this.flowService,
    this.loadingService,
    this.onFlowDispose,
  });

  @override
  State<RegistrationFlowPage> createState() => _RegistrationFlowPageState();
}

class _RegistrationFlowPageState extends State<RegistrationFlowPage> {
  late final RegistrationFlowService _flow;
  late final LoadingService _loadingService;
  late final bool _ownsFlowService;
  late final bool _ownsLoadingService;

  bool get _isSharedLoadingService =>
      identical(_loadingService, LoadingService());

  bool get _isLoading => _loadingService.isAnyLoading;

  @override
  void initState() {
    super.initState();
    _ownsFlowService = widget.flowService == null;
    _ownsLoadingService = widget.loadingService == null;
    _flow = widget.flowService ?? RegistrationFlowService();
    _loadingService = widget.loadingService ?? LoadingService();
    _flow.reset();
  }

  @override
  void didUpdateWidget(covariant RegistrationFlowPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(
      identical(oldWidget.flowService, widget.flowService),
      'RegistrationFlowPage does not support swapping flowService after mount.',
    );
    assert(
      identical(oldWidget.loadingService, widget.loadingService),
      'RegistrationFlowPage does not support swapping loadingService after mount.',
    );
  }

  @override
  void dispose() {
    widget.onFlowDispose?.call(_flow);
    if (_ownsFlowService) {
      _flow.dispose();
    }
    // LoadingService は singleton のため、共有インスタンスは破棄しない。
    if (_ownsLoadingService && !_isSharedLoadingService) {
      _loadingService.dispose();
    }
    super.dispose();
  }

  void _handlePopInvoked(bool didPop, Object? result) {
    if (didPop) {
      return;
    }
    if (_isLoading) {
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
      listenable: Listenable.merge([_flow, _loadingService]),
      builder: (context, _) {
        final step = _flow.currentStep;
        final canPopRoute =
            step == RegistrationStep.emailInput ||
            step == RegistrationStep.completed;
        final canPop = canPopRoute && !_isLoading;

        return PopScope(
          canPop: canPop,
          onPopInvokedWithResult: _handlePopInvoked,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: switch (step) {
              RegistrationStep.emailInput => const KeyedSubtree(
                key: ValueKey('reg_email'),
                child: RegistrationEmailScreen(),
              ),
              RegistrationStep.otpVerification => const KeyedSubtree(
                key: ValueKey('reg_otp'),
                child: RegistrationOtpScreen(),
              ),
              RegistrationStep.passwordSetup => const KeyedSubtree(
                key: ValueKey('reg_password'),
                child: RegistrationPasswordSetupScreen(),
              ),
              RegistrationStep.completed => const KeyedSubtree(
                key: ValueKey('reg_done'),
                child: RegistrationCompletedScreen(),
              ),
            },
          ),
        );
      },
    );
  }
}
