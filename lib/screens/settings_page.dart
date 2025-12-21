import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';
import '../services/loading_service.dart';
import '../services/settings_service.dart';
import '../widgets/loading_widget.dart';
import '../models/user.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final ErrorHandler _errorHandler = ErrorHandler();
  final LoadingService _loadingService = LoadingService();
  final SettingsService _settingsService = SettingsService();

  User? _user;
  bool _isInitialLoading = true;
  String? _errorMessage;

  // アカウント設定用のコントローラー
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

  static const String _loadingOperation = 'load_user';
  static const String _loadingOperationUpdate = 'update_user';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _settingsService.initialize();
    _settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ユーザー情報を取得
  Future<void> _loadUser() async {
    setState(() {
      _errorMessage = null;
    });
    _loadingService.setLoading(_loadingOperation, true);

    try {
      final user = await _apiService.getUser();
      setState(() {
        _user = user;
        _nameController.text = user.name;
        _emailController.text = user.email;
        _isInitialLoading = false;
      });
      // バックエンドから取得したダークモード設定を反映
      if (user.isDarkMode != _settingsService.isDarkMode) {
        await _settingsService.setIsDarkMode(user.isDarkMode);
      }
      // バックエンドから取得した24時間形式設定を反映
      if (user.is24HourFormat != _settingsService.is24HourFormat) {
        await _settingsService.setIs24HourFormat(user.is24HourFormat);
      }
    } catch (e) {
      setState(() {
        _errorMessage = _errorHandler.getErrorMessage(e);
        _isInitialLoading = false;
      });
      _errorHandler.logError(e, context: 'ユーザー情報取得');
    } finally {
      _loadingService.setLoading(_loadingOperation, false);
    }
  }

  // ユーザー情報を更新
  Future<void> _updateUser() async {
    if (_user == null) return;

    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();
    final passwordConfirm = _passwordConfirmController.text.trim();

    // バリデーション
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('名前を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.isNotEmpty && password != passwordConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('パスワードが一致しません'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _loadingService.setLoading(_loadingOperationUpdate, true);

    try {
      // メールアドレスは変更できないため、既存のメールアドレスを使用
      final updatedUser = await _apiService.updateUser(
        name: name,
        email: _user!.email,
        password: password.isNotEmpty ? password : null,
      );

      setState(() {
        _user = updatedUser;
      });

      // AuthServiceのユーザー情報も更新
      await _authService.saveUserInfo(updatedUser.name, updatedUser.email);

      _passwordController.clear();
      _passwordConfirmController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを更新しました'),
            backgroundColor: Colors.green,
          ),
        );
        // 更新成功を呼び出し元に通知
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _errorHandler.handleError(
          context,
          e,
          contextMessage: 'プロフィール更新',
        );
      }
    } finally {
      _loadingService.setLoading(_loadingOperationUpdate, false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('設定'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isInitialLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && _user == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'エラーが発生しました',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadUser,
                          icon: const Icon(Icons.refresh),
                          label: const Text('再試行'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // アカウント設定セクション
                      _buildAccountSection(),
                      const SizedBox(height: 24),
                      // 表示設定セクション
                      _buildDisplaySection(),
                    ],
                  ),
      ),
    );
  }

  // アカウント設定セクション
  Widget _buildAccountSection() {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'アカウント設定',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 名前
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '名前',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                // メールアドレス
                TextField(
                  controller: _emailController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'メールアドレス',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    helperText: 'メールアドレスは変更できません',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // パスワード
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '新しいパスワード（変更する場合のみ）',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    helperText: '変更しない場合は空欄のままにしてください',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                // パスワード確認
                TextField(
                  controller: _passwordConfirmController,
                  decoration: const InputDecoration(
                    labelText: 'パスワード確認',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                // 更新ボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loadingService.isLoading(_loadingOperationUpdate)
                        ? null
                        : _updateUser,
                    child: _loadingService.isLoading(_loadingOperationUpdate)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('プロフィールを更新'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 表示設定セクション
  Widget _buildDisplaySection() {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.display_settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '表示設定',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // テーマ設定（ダーク/ライトのトグル）
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6),
            title: const Text('ダークモード'),
            subtitle: const Text('ダークテーマを有効にする'),
            value: _settingsService.isDarkMode,
            onChanged: (bool value) async {
              await _settingsService.setIsDarkMode(value);
              // APIにも反映
              if (_user != null) {
                try {
                  await _apiService.updateUser(isDarkMode: value);
                  // ユーザー情報を再取得して反映
                  await _loadUser();
                } catch (e) {
                  // エラーが発生した場合は元に戻す
                  await _settingsService.setIsDarkMode(!value);
                  if (mounted) {
                    _errorHandler.handleError(
                      context,
                      e,
                      contextMessage: 'テーマ設定の更新',
                    );
                  }
                }
              }
            },
          ),
          const Divider(height: 1),
          // 時刻形式設定
          SwitchListTile(
            secondary: const Icon(Icons.access_time),
            title: const Text('24時間形式'),
            subtitle: const Text('時刻を24時間形式で表示'),
            value: _settingsService.is24HourFormat,
            onChanged: (bool value) async {
              await _settingsService.setIs24HourFormat(value);
              // APIにも反映
              if (_user != null) {
                try {
                  await _apiService.updateUser(is24HourFormat: value);
                  // ユーザー情報を再取得して反映
                  await _loadUser();
                } catch (e) {
                  // エラーが発生した場合は元に戻す
                  await _settingsService.setIs24HourFormat(!value);
                  if (mounted) {
                    _errorHandler.handleError(
                      context,
                      e,
                      contextMessage: '24時間形式設定の更新',
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

}
