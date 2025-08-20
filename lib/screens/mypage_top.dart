import 'package:flutter/material.dart';
import 'task_create_page.dart';

class MyPageTop extends StatelessWidget {
  const MyPageTop({super.key});

  @override
  Widget build(BuildContext context) {
    // 仮のユーザー名（後で実際のユーザー情報に置き換え）
    const String userName = "ユーザー";

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: 設定ページへの遷移
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('設定ページへ遷移予定')),
              );
            },
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
                              '$userNameさん',
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
                  // TODO: 予定一覧ページへの遷移
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('予定一覧ページへ遷移予定')),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // 統計・進捗ボタン
            Card(
              elevation: 4,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  '統計・進捗',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('習慣の達成状況を確認'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: 統計・進捗ページへの遷移
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('統計・進捗ページへ遷移予定')),
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
                onTap: () {
                  // TODO: 設定ページへの遷移
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('設定ページへ遷移予定')),
                  );
                },
              ),
            ),

            const Spacer(),

            // ログアウトボタン
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // TODO: ログアウト処理
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
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
}
