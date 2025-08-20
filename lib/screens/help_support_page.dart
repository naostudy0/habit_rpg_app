import 'package:flutter/material.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': '予定の追加方法を教えてください',
      'answer': 'マイページの「予定を追加」ボタンをタップして、タイトル、日時、メモを入力してください。登録ボタンを押すと予定が保存されます。',
    },
    {
      'question': '予定の編集はできますか？',
      'answer': 'はい、予定一覧から編集したい予定をタップすると、編集画面に遷移します。タイトル、日時、メモを変更できます。',
    },
    {
      'question': '通知の設定を変更したい',
      'answer': '設定ページの「通知」セクションで、通知のON/OFF、サウンド、バイブレーションの設定を変更できます。',
    },
    {
      'question': 'データのバックアップはできますか？',
      'answer': '設定ページの「データ管理」セクションで、自動バックアップの設定やデータエクスポートが可能です。',
    },
    {
      'question': 'パスワードを忘れた場合',
      'answer': 'ログイン画面の「パスワードを忘れた場合」から、メールアドレスを入力してパスワードリセットメールを送信できます。',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ヘルプ・サポート'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 検索バー
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ヘルプを検索...',
                border: InputBorder.none,
                icon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('音声検索機能は開発中です')),
                    );
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // クイックアクセス
          const Text(
            'クイックアクセス',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickAccessSection(),
          
          const SizedBox(height: 32),
          
          // よくある質問
          const Text(
            'よくある質問',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildFAQSection(),
          
          const SizedBox(height: 32),
          
          // お問い合わせ
          const Text(
            'お問い合わせ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildContactSection(),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildQuickAccessCard(
          icon: Icons.play_circle,
          title: '使い方ガイド',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('使い方ガイドページへ遷移予定')),
            );
          },
        ),
        _buildQuickAccessCard(
          icon: Icons.video_library,
          title: '動画チュートリアル',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('動画チュートリアルページへ遷移予定')),
            );
          },
        ),
        _buildQuickAccessCard(
          icon: Icons.bug_report,
          title: 'バグ報告',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('バグ報告ページへ遷移予定')),
            );
          },
        ),
        _buildQuickAccessCard(
          icon: Icons.feedback,
          title: '機能リクエスト',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('機能リクエストページへ遷移予定')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _faqs.length,
      itemBuilder: (context, index) {
        final faq = _faqs[index];
        return ExpansionTile(
          title: Text(
            faq['question'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                faq['answer'],
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('メールでお問い合わせ'),
              subtitle: const Text('support@habit-rpg.com'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('メールアプリが開きます')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('チャットサポート'),
              subtitle: const Text('オンラインでサポートを受ける'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('チャットサポートページへ遷移予定')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('電話サポート'),
              subtitle: const Text('0120-XXX-XXX（平日 9:00-18:00）'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('電話アプリが開きます')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
