import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_rpg_app/screens/task_create_page.dart';

void main() {
  group('TaskCreatePage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('タスク作成ページが正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskCreatePage(),
        ),
      );

      // タイトルが表示されているか確認
      expect(find.text('新しい予定'), findsOneWidget);

      // タイトル入力フィールドが表示されているか確認
      expect(find.text('タイトル'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));

      // 日時セクションが表示されているか確認
      expect(find.text('日時'), findsOneWidget);

      // メモセクションが表示されているか確認
      expect(find.text('メモ'), findsOneWidget);

      // 登録ボタンが表示されているか確認
      expect(find.text('予定を登録'), findsOneWidget);
    });

    testWidgets('初期値が設定されている場合、タイトルとメモが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskCreatePage(
            initialTitle: 'テストタイトル',
            initialMemo: 'テストメモ',
          ),
        ),
      );

      await tester.pump();

      // 初期値が表示されているか確認
      expect(find.text('テストタイトル'), findsOneWidget);
      expect(find.text('テストメモ'), findsOneWidget);
    });

    testWidgets('タイトルを入力できる', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskCreatePage(),
        ),
      );

      // タイトル入力フィールドを見つける
      final titleField = find.byType(TextFormField).first;
      await tester.enterText(titleField, '新しいタスク');

      // 入力された値を確認
      expect(find.text('新しいタスク'), findsOneWidget);
    });

    testWidgets('メモを入力できる', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskCreatePage(),
        ),
      );

      // メモ入力フィールドを見つける（2番目のTextFormField）
      final memoField = find.byType(TextFormField).last;
      await tester.enterText(memoField, 'これはテストメモです');

      // 入力された値を確認
      expect(find.text('これはテストメモです'), findsOneWidget);
    });

    testWidgets('空のタイトルでバリデーションエラーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskCreatePage(),
        ),
      );

      // フォームを送信
      final submitButton = find.text('予定を登録');
      await tester.tap(submitButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // バリデーションエラーが表示されることを確認
      expect(find.text('タイトルを入力してください'), findsOneWidget);
    });
  });
}
