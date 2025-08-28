import 'package:flutter/material.dart';
import 'screens/top_page.dart';
import 'screens/login_page.dart';
import 'screens/mypage.dart';
import 'screens/mypage_top.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit RPG',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const TopPage(),
        '/login': (context) => const LoginPage(),
        '/mypage': (context) => const MyPage(),
        '/mypage_top': (context) => const MyPageTop(),
      },
    );
  }
}
