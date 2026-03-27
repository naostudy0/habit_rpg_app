import 'package:flutter/material.dart';

/// 会員登録フローの画面ステップ
enum RegistrationStep { emailInput, otpVerification, passwordSetup, completed }

/// 会員登録フローの状態管理サービス
///
/// singleton で保持することで、画面の再描画や一時的な戻る操作でも
/// ステップ状態が破綻しにくい構成にする。
class RegistrationFlowService extends ChangeNotifier {
  static final RegistrationFlowService _instance =
      RegistrationFlowService._internal();
  factory RegistrationFlowService() => _instance;
  RegistrationFlowService._internal();

  @override
  // ignore: must_call_super
  void dispose() {
    // singleton のため外部から dispose されると以降の notifyListeners が壊れる。
    // 外部呼び出しは no-op にして保護する。
  }

  // ignore: unused_element
  void _disposeInternal() {
    super.dispose();
  }

  RegistrationStep _currentStep = RegistrationStep.emailInput;
  String _email = '';
  String? _registrationToken;
  DateTime? _resendAvailableAt;

  RegistrationStep get currentStep => _currentStep;
  String get email => _email;
  String? get registrationToken => _registrationToken;
  DateTime? get resendAvailableAt => _resendAvailableAt;

  bool get hasEmail => _email.trim().isNotEmpty;
  bool get hasRegistrationToken =>
      _registrationToken != null && _registrationToken!.isNotEmpty;

  bool get canGoBack =>
      _currentStep == RegistrationStep.otpVerification ||
      _currentStep == RegistrationStep.passwordSetup;

  bool canResendOtp({DateTime? now}) {
    final current = now ?? DateTime.now();
    return _resendAvailableAt == null || !current.isBefore(_resendAvailableAt!);
  }

  Duration resendRemaining({DateTime? now}) {
    final current = now ?? DateTime.now();
    if (_resendAvailableAt == null || !current.isBefore(_resendAvailableAt!)) {
      return Duration.zero;
    }
    return _resendAvailableAt!.difference(current);
  }

  void setEmail(String email) {
    final normalized = email.trim();
    if (_email == normalized) {
      return;
    }

    _email = normalized;
    notifyListeners();
  }

  /// OTP送信成功時の状態更新
  void moveToOtpVerification({
    required String email,
    required DateTime resendAvailableAt,
  }) {
    _email = email.trim();
    _resendAvailableAt = resendAvailableAt;
    _registrationToken = null;
    _currentStep = RegistrationStep.otpVerification;
    notifyListeners();
  }

  void updateResendAvailableAt(DateTime resendAvailableAt) {
    _resendAvailableAt = resendAvailableAt;
    notifyListeners();
  }

  /// OTP検証成功時の状態更新
  void moveToPasswordSetup({required String registrationToken}) {
    final token = registrationToken.trim();
    if (token.isEmpty) {
      throw ArgumentError('registrationToken must not be empty');
    }

    _registrationToken = token;
    _currentStep = RegistrationStep.passwordSetup;
    notifyListeners();
  }

  /// 本登録完了時の状態更新
  void completeRegistration() {
    _registrationToken = null;
    _resendAvailableAt = null;
    _currentStep = RegistrationStep.completed;
    notifyListeners();
  }

  /// 1ステップ戻る
  ///
  /// - passwordSetup -> otpVerification
  /// - otpVerification -> emailInput
  /// - emailInput / completed は変更なし
  void goBack() {
    switch (_currentStep) {
      case RegistrationStep.passwordSetup:
        _registrationToken = null;
        _currentStep = RegistrationStep.otpVerification;
        notifyListeners();
        return;
      case RegistrationStep.otpVerification:
        _registrationToken = null;
        _resendAvailableAt = null;
        _currentStep = RegistrationStep.emailInput;
        notifyListeners();
        return;
      case RegistrationStep.emailInput:
      case RegistrationStep.completed:
        return;
    }
  }

  /// フロー状態を初期化
  void reset() {
    _currentStep = RegistrationStep.emailInput;
    _email = '';
    _registrationToken = null;
    _resendAvailableAt = null;
    notifyListeners();
  }
}
