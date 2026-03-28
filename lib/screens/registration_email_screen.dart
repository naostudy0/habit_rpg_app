import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/loading_service.dart';
import '../services/registration_flow_service.dart';
import '../utils/registration_response_parsing.dart';
import '../widgets/loading_widget.dart';

class RegistrationEmailScreen extends StatefulWidget {
  const RegistrationEmailScreen({super.key});

  @override
  State<RegistrationEmailScreen> createState() =>
      _RegistrationEmailScreenState();
}

class _RegistrationEmailScreenState extends State<RegistrationEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _apiService = ApiService();
  final _loadingService = LoadingService();
  final _flow = RegistrationFlowService();
  late final VoidCallback _emailListener;

  static const String _loadingOperation = 'registration_send_otp';
  static const Duration _defaultResendCooldown = Duration(seconds: 60);

  String? _serverError;

  @override
  void initState() {
    super.initState();
    _emailController.text = _flow.email;
    _emailListener = () {
      _flow.setEmail(_emailController.text);
    };
    _emailController.addListener(_emailListener);
  }

  @override
  void dispose() {
    _emailController.removeListener(_emailListener);
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _serverError = null);
    _loadingService.setLoading(_loadingOperation, true);

    try {
      final email = _emailController.text.trim();
      final result = await _apiService.sendRegistrationOtp(email);

      if (!mounted) {
        return;
      }

      if (result.isSuccess) {
        final resendAt =
            parseResendAvailableAtFromData(result.data) ??
            DateTime.now().add(_defaultResendCooldown);
        _flow.moveToOtpVerification(email: email, resendAvailableAt: resendAt);
        return;
      }

      setState(() {
        _serverError = registrationSendOtpErrorMessage(result);
      });
    } catch (e, st) {
      debugPrint('sendRegistrationOtp failed: $e\n$st');
      if (!mounted) {
        return;
      }
      setState(() {
        _serverError = 'ワンタイムパスワードの送信に失敗しました。時間をおいて再度お試しください。';
      });
    } finally {
      _loadingService.setLoading(_loadingOperation, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      operation: _loadingOperation,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('新規登録'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _loadingService.isLoading(_loadingOperation)
                ? null
                : () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '登録するメールアドレスを入力してください。\n'
                  'ワンタイムパスワードを送信します。',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                    errorText: _serverError,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    if (!value.contains('@')) {
                      return '有効なメールアドレスを入力してください';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (_serverError != null) {
                      setState(() => _serverError = null);
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loadingService.isLoading(_loadingOperation)
                        ? null
                        : _submit,
                    child: Text(
                      _loadingService.isLoading(_loadingOperation)
                          ? '送信中...'
                          : 'ワンタイムパスワードを送信',
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
