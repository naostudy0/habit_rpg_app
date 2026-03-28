import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../services/loading_service.dart';
import '../widgets/loading_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _errorHandler = ErrorHandler();
  final _loadingService = LoadingService();
  String? _emailError;
  String? _passwordError;

  static const String _loadingOperation = 'login';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      _loadingService.setLoading(_loadingOperation, true);

      // エラーメッセージをクリア
      setState(() {
        _emailError = null;
        _passwordError = null;
      });

      try {
        final email = _emailController.text.trim();
        await _apiService.login(
          email,
          _passwordController.text,
        );

        // ログイン成功時の処理
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ログインに成功しました'),
              backgroundColor: Colors.green,
            ),
          );

          // マイページに遷移
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/mypage_top',
            (route) => false,
          );
        }
      } catch (e) {
        // エラー時の処理
        if (mounted) {
          // フィールドごとのエラーメッセージを設定
          setState(() {
            _emailError = _errorHandler.getFieldError(e, 'email');
            _passwordError = _errorHandler.getFieldError(e, 'password');
          });

          // フィールドエラーがない場合は、一般的なエラーメッセージを表示
          if (_emailError == null && _passwordError == null) {
            _errorHandler.handleError(context, e, contextMessage: 'ログイン');
          } else {
            // フィールドエラーがある場合は、フォームを再検証してエラーを表示
            _formKey.currentState?.validate();
          }
        }
      } finally {
        _loadingService.setLoading(_loadingOperation, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      operation: _loadingOperation,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ログイン'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Habit RPG',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                    errorText: _emailError,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    // サーバーからのエラーメッセージがある場合はそれを優先
                    if (_emailError != null) {
                      return _emailError;
                    }
                    if (value == null || value.trim().isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    if (!value.trim().contains('@')) {
                      return '有効なメールアドレスを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    errorText: _passwordError,
                  ),
                  obscureText: true,
                  validator: (value) {
                    // サーバーからのエラーメッセージがある場合はそれを優先
                    if (_passwordError != null) {
                      return _passwordError;
                    }
                    if (value == null || value.isEmpty) {
                      return 'パスワードを入力してください';
                    }
                    if (value.length < 8) {
                      return 'パスワードは8文字以上で入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loadingService.isLoading(_loadingOperation)
                        ? null
                        : _handleLogin,
                    child: _loadingService.isLoading(_loadingOperation)
                        ? const SimpleLoadingIndicator(
                            color: Colors.white,
                            size: 20,
                          )
                        : const Text('ログイン', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loadingService.isLoading(_loadingOperation)
                      ? null
                      : () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        ),
                  child: const Text('TOPページへ戻る'),
                ),
                TextButton(
                  onPressed: _loadingService.isLoading(_loadingOperation)
                      ? null
                      : () => Navigator.pushNamed(context, '/register'),
                  child: const Text('新規登録はこちら'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
