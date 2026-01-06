import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_rpg_app/services/auth_service.dart';
import 'package:habit_rpg_app/services/api_service.dart';
import 'package:habit_rpg_app/models/task.dart';
import 'package:habit_rpg_app/models/task_suggestion.dart';

void main() {
  group('統合テスト', () {
    late AuthService authService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authService = AuthService();
    });

    tearDown(() async {
      await authService.logout();
    });

    group('認証フロー', () {
      test('トークン保存と認証状態の確認が連携して動作する', () async {
        // トークンを保存
        await authService.saveToken('test_token', expiresIn: 3600);
        await authService.saveUserInfo('テストユーザー', 'test@example.com');

        // 認証状態を確認
        final isAuthenticated = await authService.isAuthenticated();
        expect(isAuthenticated, true);

        // ユーザー情報を取得
        final userName = await authService.getUserName();
        final userEmail = await authService.getUserEmail();
        expect(userName, 'テストユーザー');
        expect(userEmail, 'test@example.com');

        // ログアウト
        await authService.logout();

        // 認証状態がfalseになることを確認
        final isAuthenticatedAfterLogout = await authService.isAuthenticated();
        expect(isAuthenticatedAfterLogout, false);
      });
    });

    group('モデル変換', () {
      test('TaskモデルのJSON変換が正しく動作する', () {
        final now = DateTime.now();
        final task = Task(
          uuid: 'test-uuid',
          title: 'テストタスク',
          scheduledDate: now,
          scheduledTime: const TimeOfDay(hour: 10, minute: 30),
          memo: 'テストメモ',
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
        );

        // JSONに変換
        final json = task.toJson();
        expect(json['uuid'], 'test-uuid');
        expect(json['title'], 'テストタスク');
        expect(json['memo'], 'テストメモ');
        expect(json['is_completed'], false);

        // JSONから復元
        final restoredTask = Task.fromJson(json);
        expect(restoredTask.uuid, 'test-uuid');
        expect(restoredTask.title, 'テストタスク');
        expect(restoredTask.memo, 'テストメモ');
        expect(restoredTask.isCompleted, false);
      });

      test('TaskSuggestionモデルのJSON変換が正しく動作する', () {
        final now = DateTime.now();
        final suggestion = TaskSuggestion(
          uuid: 'test-uuid',
          title: 'テスト提案',
          memo: 'テストメモ',
          createdAt: now,
          updatedAt: now,
        );

        // JSONに変換
        final json = suggestion.toJson();
        expect(json['uuid'], 'test-uuid');
        expect(json['title'], 'テスト提案');
        expect(json['memo'], 'テストメモ');

        // JSONから復元
        final restoredSuggestion = TaskSuggestion.fromJson(json);
        expect(restoredSuggestion.uuid, 'test-uuid');
        expect(restoredSuggestion.title, 'テスト提案');
        expect(restoredSuggestion.memo, 'テストメモ');
      });
    });

    group('エラーハンドリング', () {
      test('ApiExceptionのエラーメッセージ取得が正しく動作する', () {
        final exception = ApiException(
          statusCode: 400,
          message: 'エラーメッセージ',
          errors: {
            'title': ['タイトルは必須です'],
            'email': ['メールアドレスの形式が不正です'],
          },
        );

        // エラーメッセージを取得
        expect(exception.getErrorMessage(), 'タイトルは必須です');
        expect(exception.getFieldError('title'), 'タイトルは必須です');
        expect(exception.getFieldError('email'), 'メールアドレスの形式が不正です');
        expect(exception.getAllErrorMessages().length, 2);
      });
    });
  });
}
