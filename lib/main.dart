import 'package:flutter/material.dart';
import 'screens/top_page.dart';
import 'screens/login_page.dart';
import 'screens/mypage.dart';
import 'screens/mypage_top.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _settingsService.initialize();
    _settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit RPG',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _settingsService.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthCheckWrapper(child: TopPage()),
        '/login': (context) => const LoginPage(),
        '/mypage': (context) => const MyPage(),
        '/mypage_top': (context) => const MyPageTop(),
      },
    );
  }
}

// 認証状態をチェックするラッパーウィジェット
class AuthCheckWrapper extends StatefulWidget {
  final Widget child;

  const AuthCheckWrapper({super.key, required this.child});

  @override
  State<AuthCheckWrapper> createState() => _AuthCheckWrapperState();
}

class _AuthCheckWrapperState extends State<AuthCheckWrapper> {
  final AuthService _authService = AuthService();
  bool _isChecking = true;
  bool _isAuthenticated = false;

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
        _isChecking = false;
      });

      // 認証済みの場合はマイページトップに遷移
      if (isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/mypage_top');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return widget.child;
  }
}
