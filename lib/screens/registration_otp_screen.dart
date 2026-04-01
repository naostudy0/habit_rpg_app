import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/loading_service.dart';
import '../services/registration_flow_service.dart';
import '../utils/registration_response_parsing.dart';
import '../widgets/loading_widget.dart';

typedef VerifyRegistrationOtpRequest =
    Future<RegistrationApiResult> Function({
      required String email,
      required String otp,
    });
typedef SendRegistrationOtpRequest =
    Future<RegistrationApiResult> Function(String email);

class RegistrationOtpScreen extends StatefulWidget {
  final VerifyRegistrationOtpRequest? verifyRegistrationOtpRequest;
  final SendRegistrationOtpRequest? sendRegistrationOtpRequest;
  final RegistrationFlowService? flowService;
  final LoadingService? loadingService;

  const RegistrationOtpScreen({
    super.key,
    this.verifyRegistrationOtpRequest,
    this.sendRegistrationOtpRequest,
    this.flowService,
    this.loadingService,
  });

  @override
  State<RegistrationOtpScreen> createState() => _RegistrationOtpScreenState();
}

class _RegistrationOtpScreenState extends State<RegistrationOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _apiService = ApiService();
  late final LoadingService _loadingService;
  late final RegistrationFlowService _flow;

  static const String _loadingOperation = 'registration_otp_step';
  static const Duration _defaultResendCooldown = Duration(seconds: 60);

  Timer? _tickTimer;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _loadingService = widget.loadingService ?? LoadingService();
    _flow = widget.flowService ?? RegistrationFlowService();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  String _formatRemaining(Duration d) {
    if (d <= Duration.zero) {
      return '';
    }
    final total = d.inSeconds;
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _serverError = null);
    _loadingService.setLoading(_loadingOperation, true);

    try {
      final verifyRegistrationOtp =
          widget.verifyRegistrationOtpRequest ??
          _apiService.verifyRegistrationOtp;
      final result = await verifyRegistrationOtp(
        email: _flow.email,
        otp: _otpController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      if (result.isSuccess) {
        final token = parseRegistrationTokenFromData(result.data);
        if (token == null) {
          setState(() {
            _serverError = '登録トークンを取得できませんでした。最初からやり直してください。';
          });
          return;
        }
        _flow.moveToPasswordSetup(registrationToken: token);
        return;
      }

      setState(() {
        _serverError = registrationVerifyOtpErrorMessage(result);
      });
    } catch (e, st) {
      debugPrint('verifyRegistrationOtp failed: $e\n$st');
      if (!mounted) {
        return;
      }
      setState(() {
        _serverError = 'ワンタイムパスワードの検証に失敗しました。時間をおいて再度お試しください。';
      });
    } finally {
      _loadingService.setLoading(_loadingOperation, false);
    }
  }

  Future<void> _resend() async {
    if (!_flow.canResendOtp()) {
      return;
    }

    setState(() => _serverError = null);
    _loadingService.setLoading(_loadingOperation, true);

    try {
      final sendRegistrationOtp =
          widget.sendRegistrationOtpRequest ?? _apiService.sendRegistrationOtp;
      final result = await sendRegistrationOtp(_flow.email);

      if (!mounted) {
        return;
      }

      if (result.isSuccess) {
        final resendAt =
            parseResendAvailableAtFromData(result.data) ??
            DateTime.now().add(_defaultResendCooldown);
        _flow.updateResendAvailableAt(resendAt);
        return;
      }

      final resendAt = parseResendAvailableAtFromData(result.data);
      if (resendAt != null) {
        _flow.updateResendAvailableAt(resendAt);
      }

      setState(() {
        _serverError = registrationSendOtpErrorMessage(result);
      });
    } catch (e, st) {
      debugPrint('sendRegistrationOtp (resend) failed: $e\n$st');
      if (!mounted) {
        return;
      }
      setState(() {
        _serverError = 'ワンタイムパスワードの再送に失敗しました。時間をおいて再度お試しください。';
      });
    } finally {
      _loadingService.setLoading(_loadingOperation, false);
    }
  }

  bool get _anyLoading => _loadingService.isLoading(_loadingOperation);

  @override
  Widget build(BuildContext context) {
    final remaining = _flow.resendRemaining();
    final canResend = _flow.canResendOtp();
    final cooldownText = canResend ? '' : _formatRemaining(remaining);

    return LoadingWidget(
      operation: _loadingOperation,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ワンタイムパスワード入力'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            key: const Key('otp_back_button'),
            icon: const Icon(Icons.arrow_back),
            onPressed: _anyLoading ? null : () => _flow.goBack(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${_flow.email}\nに送信したコードを入力してください。',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  key: const Key('otp_input'),
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'ワンタイムパスワード',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.pin),
                    counterText: '',
                    errorText: _serverError,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'コードを入力してください';
                    }
                    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
                      return 'ワンタイムパスワードは6桁で入力してください';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (_serverError != null) {
                      setState(() => _serverError = null);
                    }
                  },
                ),
                if (cooldownText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '再送まであと $cooldownText',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  key: const Key('otp_resend_button'),
                  onPressed: (!_anyLoading && canResend) ? _resend : null,
                  child: const Text('コードを再送する'),
                ),
                const Spacer(),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    key: const Key('otp_verify_button'),
                    onPressed: _anyLoading ? null : _verify,
                    child: Text(
                      _loadingService.isLoading(_loadingOperation)
                          ? '確認中...'
                          : '確認して次へ',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
