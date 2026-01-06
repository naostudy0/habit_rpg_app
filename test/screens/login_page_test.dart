import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_rpg_app/screens/login_page.dart';

void main() {
  group('LoginPage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('ログインページが正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // AppBarのタイトルが表示されているか確認
      expect(find.text('ログイン'), findsWidgets);

      // メールアドレス入力フィールドが表示されているか確認
      expect(find.byType(TextFormField), findsNWidgets(2));

      // ログインボタンが表示されているか確認（AppBarのタイトルとボタンのテキストの両方が「ログイン」）
      expect(find.text('ログイン'), findsNWidgets(2));
    });

    testWidgets('メールアドレスとパスワードを入力できる', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // メールアドレス入力フィールドを見つける
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');

      // パスワード入力フィールドを見つける
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'password123');

      // 入力された値を確認
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('空のメールアドレスでバリデーションエラーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pump();

      // ElevatedButtonを探す
      final loginButton = find.byType(ElevatedButton);
      expect(loginButton, findsOneWidget);

      // ボタンをタップしてフォームの検証を実行
      await tester.tap(loginButton);

      // フォームの検証が実行されるまで待機（複数回pumpして確実に）
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // バリデーションエラーが表示されることを確認
      expect(find.text('メールアドレスを入力してください'), findsOneWidget);
    });

    testWidgets('空のパスワードでバリデーションエラーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pump();

      // メールアドレスのみ入力
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // ElevatedButtonを探す
      final loginButton = find.byType(ElevatedButton);
      expect(loginButton, findsOneWidget);

      // ボタンをタップしてフォームの検証を実行
      await tester.tap(loginButton);

      // フォームの検証が実行されるまで待機
      await tester.pump();

      // バリデーションエラーが表示されることを確認
      expect(find.text('パスワードを入力してください'), findsOneWidget);
    });
  });
}
