import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/loading_service.dart';
import '../services/registration_flow_service.dart';
import '../widgets/loading_widget.dart';

class RegistrationPasswordSetupScreen extends StatefulWidget {
  const RegistrationPasswordSetupScreen({super.key});

  @override
  State<RegistrationPasswordSetupScreen> createState() =>
      _RegistrationPasswordSetupScreenState();
}

class _RegistrationPasswordSetupScreenState
    extends State<RegistrationPasswordSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _apiService = ApiService();
  final _loadingService = LoadingService();
  final _flow = RegistrationFlowService();

  static const String _loadingOperation = 'registration_complete';

  String? _serverError;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final token = _flow.registrationToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _serverError = 'セッションが無効です。最初からやり直してください。';
      });
      return;
    }

    setState(() => _serverError = null);
    _loadingService.setLoading(_loadingOperation, true);

    try {
      final result = await _apiService.completeRegistration(
        registrationToken: token,
        name: _nameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (result.isSuccess) {
        _flow.completeRegistration();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('会員登録が完了しました。ログインしてください。'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        return;
      }

      setState(() {
        _serverError = _messageForCompleteFailure(result);
      });
    } finally {
      _loadingService.setLoading(_loadingOperation, false);
    }
  }

  String _messageForCompleteFailure(RegistrationApiResult result) {
    if (result.isValidationError) {
      final nameErr = _fieldError(result, 'name');
      if (nameErr != null) {
        return nameErr;
      }
      final passErr = _fieldError(result, 'password');
      if (passErr != null) {
        return passErr;
      }
      return result.message.isNotEmpty
          ? result.message
          : '入力内容を確認してください。';
    }
    if (result.isTooManyRequests) {
      return result.message.isNotEmpty
          ? result.message
          : '試行回数が上限に達しました。しばらく時間をおいてからお試しください。';
    }
    if (result.status == RegistrationApiStatus.networkError) {
      return result.message.isNotEmpty
          ? result.message
          : '通信に失敗しました。接続を確認してください。';
    }
    return result.message.isNotEmpty
        ? result.message
        : '会員登録に失敗しました。';
  }

  String? _fieldError(RegistrationApiResult result, String field) {
    final errors = result.errors;
    if (errors == null) {
      return null;
    }
    final list = errors[field];
    if (list is List && list.isNotEmpty && list.first is String) {
      return list.first as String;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      operation: _loadingOperation,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('パスワード設定'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _loadingService.isLoading(_loadingOperation)
                ? null
                : () => _flow.goBack(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  '表示名とパスワードを設定して登録を完了してください。',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '表示名',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '表示名を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    errorText: _serverError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワードを入力してください';
                    }
                    if (value.length < 8) {
                      return 'パスワードは8文字以上で入力してください';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (_serverError != null) {
                      setState(() => _serverError = null);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordConfirmController,
                  obscureText: _obscurePasswordConfirm,
                  decoration: InputDecoration(
                    labelText: 'パスワード（確認）',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePasswordConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscurePasswordConfirm = !_obscurePasswordConfirm,
                        );
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '確認用パスワードを入力してください';
                    }
                    if (value != _passwordController.text) {
                      return 'パスワードが一致しません';
                    }
                    return null;
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
                          ? '登録中...'
                          : '登録を完了',
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
