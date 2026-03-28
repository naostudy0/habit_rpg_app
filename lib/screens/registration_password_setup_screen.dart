import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/loading_service.dart';
import '../services/registration_flow_service.dart';
import '../utils/registration_response_parsing.dart';
import '../widgets/loading_widget.dart';

typedef CompleteRegistrationRequest =
    Future<RegistrationApiResult> Function({
      required String registrationToken,
      required String name,
      required String password,
    });

class RegistrationPasswordSetupScreen extends StatefulWidget {
  final CompleteRegistrationRequest? completeRegistrationRequest;
  final RegistrationFlowService? flowService;
  final LoadingService? loadingService;

  const RegistrationPasswordSetupScreen({
    super.key,
    this.completeRegistrationRequest,
    this.flowService,
    this.loadingService,
  });

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
  late final LoadingService _loadingService;
  late final RegistrationFlowService _flow;

  static const String _loadingOperation = 'registration_complete';

  String? _serverErrorName;
  String? _serverErrorPassword;
  String? _formError;
  bool _showLoginAction = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadingService = widget.loadingService ?? LoadingService();
    _flow = widget.flowService ?? RegistrationFlowService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    _isSubmitting = true;

    if (!_formKey.currentState!.validate()) {
      _isSubmitting = false;
      return;
    }

    final token = _flow.registrationToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _formError = 'セッションが無効です。最初からやり直してください。';
      });
      _isSubmitting = false;
      return;
    }

    setState(() {
      _serverErrorName = null;
      _serverErrorPassword = null;
      _formError = null;
      _showLoginAction = false;
    });
    _loadingService.setLoading(_loadingOperation, true);

    try {
      final completeRegistration =
          widget.completeRegistrationRequest ??
          _apiService.completeRegistration;
      final result = await completeRegistration(
        registrationToken: token,
        name: _nameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (result.isSuccess) {
        _flow.completeRegistration();
        return;
      }

      setState(() => _applyCompleteFailure(result));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _formError = '会員登録に失敗しました。時間をおいて再度お試しください。';
      });
    } finally {
      _loadingService.setLoading(_loadingOperation, false);
      _isSubmitting = false;
    }
  }

  void _applyCompleteFailure(RegistrationApiResult result) {
    final ui = mapRegistrationCompleteFailure(result);
    _serverErrorName = ui.nameError;
    _serverErrorPassword = ui.passwordError;
    _formError = ui.formError;
    _showLoginAction = ui.showLoginAction;
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
                if (_formError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _formError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_showLoginAction)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/login', (route) => false);
                        },
                        child: const Text('ログインへ'),
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                TextFormField(
                  key: const Key('username_field'),
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: '表示名',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    errorText: _serverErrorName,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '表示名を入力してください';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (_serverErrorName != null ||
                        _formError != null ||
                        _showLoginAction) {
                      setState(() {
                        _serverErrorName = null;
                        _formError = null;
                        _showLoginAction = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('password_field'),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    errorText: _serverErrorPassword,
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
                    if (_serverErrorPassword != null ||
                        _formError != null ||
                        _showLoginAction) {
                      setState(() {
                        _serverErrorPassword = null;
                        _formError = null;
                        _showLoginAction = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('password_confirm_field'),
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
                          () => _obscurePasswordConfirm =
                              !_obscurePasswordConfirm,
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
                    key: const Key('registration_submit_button'),
                    onPressed:
                        (_loadingService.isLoading(_loadingOperation) ||
                            _isSubmitting)
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
