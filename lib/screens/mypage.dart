import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isAuthenticated = await _authService.isAuthenticated();

    if (mounted) {
      setState(() {
        _isAuthenticated = isAuthenticated;
        _isCheckingAuth = false;
      });

      // 認証されていない場合はログイン画面にリダイレクト
      if (!isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 認証チェック中はローディング表示
    if (_isCheckingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 認証されていない場合は何も表示しない（リダイレクト中）
    if (!_isAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.person, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'マイページ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('ログイン成功！', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
