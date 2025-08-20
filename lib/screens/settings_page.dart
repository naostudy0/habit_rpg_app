import 'package:flutter/material.dart';
import 'profile_edit_page.dart';
import 'email_change_page.dart';
import 'password_change_page.dart';
import 'help_support_page.dart';
import 'feedback_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 設定の状態管理
  bool _isDarkMode = false;
  bool _isNotificationEnabled = true;
  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;
  bool _isAutoBackupEnabled = false;
  String _selectedLanguage = '日本語';
  String _selectedTimeFormat = '24時間';

  @override
  Widget build(BuildContext context) {
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

          // 通知設定セクション
          _buildSectionHeader('通知'),
          _buildNotificationSection(),

          const SizedBox(height: 24),

          // データ管理セクション
          _buildSectionHeader('データ管理'),
          _buildDataSection(),

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
            subtitle: const Text('user@example.com'),
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
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isDarkMode ? 'ダークモードを有効にしました' : 'ダークモードを無効にしました'),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('言語'),
            subtitle: Text(_selectedLanguage),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showLanguageDialog();
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

  Widget _buildNotificationSection() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('通知'),
            subtitle: const Text('プッシュ通知を有効にする'),
            value: _isNotificationEnabled,
            onChanged: (value) {
              setState(() {
                _isNotificationEnabled = value;
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: const Text('サウンド'),
            subtitle: const Text('通知音を再生する'),
            value: _isSoundEnabled && _isNotificationEnabled,
            onChanged: _isNotificationEnabled ? (value) {
              setState(() {
                _isSoundEnabled = value;
              });
            } : null,
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('バイブレーション'),
            subtitle: const Text('通知時にバイブレーション'),
            value: _isVibrationEnabled && _isNotificationEnabled,
            onChanged: _isNotificationEnabled ? (value) {
              setState(() {
                _isVibrationEnabled = value;
              });
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.backup),
            title: const Text('自動バックアップ'),
            subtitle: const Text('データを自動的にバックアップ'),
            value: _isAutoBackupEnabled,
            onChanged: (value) {
              setState(() {
                _isAutoBackupEnabled = value;
              });
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('データエクスポート'),
            subtitle: const Text('データをファイルに出力'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('データエクスポート機能は開発中です')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('データ削除'),
            subtitle: const Text('すべてのデータを削除'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showDeleteDataDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOtherSection() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('ヘルプ・サポート'),
            subtitle: const Text('使い方やよくある質問'),
            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpSupportPage(),
                    ),
                  );
                },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('フィードバック'),
            subtitle: const Text('ご意見・ご要望をお聞かせください'),
            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FeedbackPage(),
                    ),
                  );
                },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('アプリについて'),
            subtitle: const Text('バージョン情報・ライセンス'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          _showLogoutDialog();
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.red[300]!),
        ),
        child: Text(
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

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('言語を選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('日本語'),
                value: '日本語',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'English',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
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
                onChanged: (value) {
                  setState(() {
                    _selectedTimeFormat = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: const Text('12時間形式'),
                value: '12時間',
                groupValue: _selectedTimeFormat,
                onChanged: (value) {
                  setState(() {
                    _selectedTimeFormat = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('データ削除'),
          content: const Text('すべてのデータを削除しますか？\nこの操作は取り消せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('データを削除しました（仮実装）'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('削除'),
            ),
          ],
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              child: const Text('ログアウト'),
            ),
          ],
        );
      },
    );
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
