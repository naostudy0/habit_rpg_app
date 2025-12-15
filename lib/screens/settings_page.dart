import 'package:flutter/material.dart';
import 'profile_edit_page.dart';
import 'email_change_page.dart';
import 'password_change_page.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 設定の状態管理
  bool _isDarkMode = false;
  String _selectedTimeFormat = '24時間';
  String _userEmail = '';
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  bool _isLoggingOut = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  // ユーザー設定を読み込む
  Future<void> _loadUserSettings() async {
    final email = await _authService.getUserEmail();
    final darkMode = await _authService.getDarkMode();
    final timeFormat = await _authService.getTimeFormat();

    if (mounted) {
      setState(() {
        _userEmail = email ?? '';
        _isDarkMode = darkMode;
        _selectedTimeFormat = timeFormat;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // アカウント設定セクション
          _buildSectionHeader('アカウント'),
          _buildAccountSection(),

          const SizedBox(height: 24),

          // 表示設定セクション
          _buildSectionHeader('表示'),
          _buildDisplaySection(),

          const SizedBox(height: 24),

          // その他セクション
          _buildSectionHeader('その他'),
          _buildOtherSection(),

          const SizedBox(height: 32),

          // ログアウトボタン
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('プロフィール編集'),
            subtitle: const Text('ユーザー名やアバターを変更'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileEditPage(),
                    ),
                  );
                },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('メールアドレス'),
            subtitle: Text(_userEmail.isEmpty ? '未設定' : _userEmail),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmailChangePage(),
                    ),
                  );
                },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('パスワード変更'),
            subtitle: const Text('セキュリティを向上'),
            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PasswordChangePage(),
                    ),
                  );
                },
          ),
        ],
      ),
    );
  }

  Widget _buildDisplaySection() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('ダークモード'),
            subtitle: const Text('ダークテーマを有効にする'),
            value: _isDarkMode,
            onChanged: (value) async {
              setState(() {
                _isDarkMode = value;
              });
              await _authService.saveDarkMode(value);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isDarkMode ? 'ダークモードを有効にしました' : 'ダークモードを無効にしました'),
                  ),
                );
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('時刻形式'),
            subtitle: Text(_selectedTimeFormat),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showTimeFormatDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOtherSection() {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.info),
        title: const Text('アプリについて'),
        subtitle: const Text('バージョン情報・ライセンス'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          _showAboutDialog();
        },
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoggingOut ? null : () {
          _showLogoutDialog();
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.red[300]!),
        ),
        child: _isLoggingOut
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red[600]!),
                ),
              )
            : Text(
                'ログアウト',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showTimeFormatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('時刻形式を選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('24時間形式'),
                value: '24時間',
                groupValue: _selectedTimeFormat,
                onChanged: (value) async {
                  setState(() {
                    _selectedTimeFormat = value!;
                  });
                  await _authService.saveTimeFormat(value!);
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('12時間形式'),
                value: '12時間',
                groupValue: _selectedTimeFormat,
                onChanged: (value) async {
                  setState(() {
                    _selectedTimeFormat = value!;
                  });
                  await _authService.saveTimeFormat(value!);
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ログアウト'),
          content: const Text('ログアウトしますか？'),
          actions: [
            TextButton(
              onPressed: _isLoggingOut
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: _isLoggingOut
                  ? null
                  : () async {
                      Navigator.of(context).pop();
                      await _handleLogout();
                    },
              child: const Text('ログアウト'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      // APIサービスでログアウト処理（トークン削除も含む）
      await _apiService.logout();

      if (mounted) {
        // ログイン画面に遷移
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログアウトしました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ログアウトエラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('アプリについて'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Habit RPG'),
              SizedBox(height: 8),
              Text('バージョン: 1.0.0'),
              SizedBox(height: 8),
              Text('習慣をゲーム化して楽しく続けましょう'),
              SizedBox(height: 16),
              Text('© 2025 Habit RPG Team'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }
}
