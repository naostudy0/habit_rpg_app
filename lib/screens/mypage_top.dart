import 'package:flutter/material.dart';
import 'task_create_page.dart';
import 'task_list_page.dart';
import 'task_calendar_page.dart';
import 'settings_page.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';
import '../models/task_suggestion.dart';

class MyPageTop extends StatefulWidget {
  const MyPageTop({super.key});

  @override
  State<MyPageTop> createState() => _MyPageTopState();
}

class _MyPageTopState extends State<MyPageTop> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final ErrorHandler _errorHandler = ErrorHandler();
  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;
  String _userName = 'ユーザー';

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isAuthenticated = await _authService.isAuthenticated();

    if (mounted) {
      // ユーザー名を取得
      final userName = await _authService.getUserName();

      setState(() {
        _isAuthenticated = isAuthenticated;
        _isCheckingAuth = false;
        _userName = userName ?? 'ユーザー';
      });

      // 認証されていない場合はログイン画面にリダイレクト
      if (!isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        });
      } else {
        // 認証されている場合は、AI提案予定を取得
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkTaskSuggestions();
        });
      }
    }
  }

  Future<void> _checkTaskSuggestions() async {
    try {
      final suggestions = await _apiService.getTaskSuggestions();

      if (mounted && suggestions.isNotEmpty) {
        // 最初の提案を表示
        final suggestion = suggestions.first;
        _showSuggestionDialog(suggestion);
      }
    } catch (e) {
      // エラーは無視（提案がない場合もエラーになる可能性があるため）
      // ignore: avoid_print
      print('AI提案予定の取得エラー: $e');
    }
  }

  Future<void> _showSuggestionDialog(TaskSuggestion suggestion) async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber),
              SizedBox(width: 8),
              Text('AIからの提案'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '以下の予定を追加しますか？',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (suggestion.memo != null && suggestion.memo!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        suggestion.memo!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // NGを選択した場合、提案を削除
                Navigator.of(context).pop(false);
                await _deleteSuggestion(suggestion);
              },
              child: const Text(
                'NG',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      // OKを選択した場合、予定追加画面に遷移
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskCreatePage(
            initialTitle: suggestion.title,
            initialMemo: suggestion.memo,
          ),
        ),
      ).then((_) {
        // 予定追加画面から戻ってきたら、提案を削除
        _deleteSuggestion(suggestion);
      });
    }
  }

  Future<void> _deleteSuggestion(TaskSuggestion suggestion) async {
    try {
      await _apiService.deleteTaskSuggestion(suggestion.uuid);
    } catch (e) {
      // エラーは無視（既に削除されている可能性があるため）
      // ignore: avoid_print
      print('AI提案予定の削除エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 認証チェック中はローディング表示
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 認証されていない場合は何も表示しない（リダイレクト中）
    if (!_isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
              // 設定ページで名前が更新された場合は、ユーザー名を再取得
              if (result == true && mounted) {
                final userName = await _authService.getUserName();
                setState(() {
                  _userName = userName ?? 'ユーザー';
                });
              }
            },
            tooltip: '設定',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ユーザー情報セクション
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: const Icon(
                          Icons.person,
                          size: 35,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_userNameさん',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'ようこそ！今日も頑張りましょう',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ナビゲーションセクション
            const Text(
              'メニュー',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 予定追加ボタン
            Card(
              elevation: 4,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_task,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  '予定を追加',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('新しい習慣やタスクを追加'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TaskCreatePage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // 予定一覧ボタン
            Card(
              elevation: 4,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.list_alt,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  '予定一覧',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('登録済みの習慣やタスクを確認'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TaskListPage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // カレンダーボタン
            Card(
              elevation: 4,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  'カレンダー',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('予定をカレンダー形式で確認'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TaskCalendarPage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // 設定ボタン
            Card(
              elevation: 4,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  '設定',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('アプリの設定を変更'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                  // 設定ページで名前が更新された場合は、ユーザー名を再取得
                  if (result == true && mounted) {
                    final userName = await _authService.getUserName();
                    setState(() {
                      _userName = userName ?? 'ユーザー';
                    });
                  }
                },
              ),
            ),

            const Spacer(),

            // ログアウトボタン
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await _handleLogout();
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
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
    }
  }
}
