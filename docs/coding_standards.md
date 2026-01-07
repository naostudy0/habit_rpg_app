# コーディング規約

このドキュメントでは、Habit RPG Appのコーディング規約を説明します。

## 一般原則

- 可読性を最優先にする
- 一貫性を保つ
- DRY（Don't Repeat Yourself）原則に従う
- 明確な命名規則を使用する

## 命名規則

### ファイル名

- スネークケース（`snake_case`）を使用
- ファイル名は内容を表す明確な名前にする

例:
- `api_service.dart`
- `task_list_page.dart`
- `user.dart`

### クラス名

- パスカルケース（`PascalCase`）を使用
- 明確で説明的な名前を使用

例:
```dart
class ApiService { }
class TaskListPage extends StatefulWidget { }
class User { }
```

### 変数名・メソッド名

- キャメルケース（`camelCase`）を使用
- 明確で説明的な名前を使用

例:
```dart
final String userName;
final List<Task> taskList;

Future<void> createTask() async { }
bool isValidEmail(String email) { }
```

### 定数

- `lowerCamelCase`を使用し、`const`キーワードを使用

例:
```dart
static const String apiBaseUrl = 'https://api.example.com';
static const int maxRetryCount = 3;
```

### プライベートメンバー

- アンダースコア（`_`）で始める

例:
```dart
class ApiService {
  final String _baseUrl;

  Future<void> _handleError() { }
}
```

## コードスタイル

### インデント

- 2スペースを使用（タブは使用しない）

### 行の長さ

- 1行は80文字以内を推奨（最大120文字）

### 空行

- クラスやメソッドの間に1行空ける
- 関連するコードブロックの間に適切に空行を入れる

### インポート

- インポートは以下の順序で整理:
  1. Dart SDKのインポート
  2. Flutterパッケージのインポート
  3. サードパーティパッケージのインポート
  4. プロジェクト内のインポート

- 各グループの間に空行を入れる

例:
```dart
// Dart SDKのインポート
import 'dart:convert';

// Flutterパッケージのインポート
import 'package:flutter/material.dart';

// サードパーティパッケージのインポート
import 'package:http/http.dart' as http;

// プロジェクト内のインポート
import '../models/task.dart';
import '../services/api_service.dart';
```

**注意**: 各グループが存在しない場合は、そのグループをスキップします。例えば、Dart SDKやサードパーティパッケージのインポートがない場合は、Flutterパッケージとプロジェクト内のインポートのみを記述します。

## クラスとメソッド

### クラスの構造

クラスは以下の順序で定義:

1. 定数
2. フィールド（public → private）
3. コンストラクタ
4. ファクトリコンストラクタ
5. ゲッター・セッター
6. メソッド（public → private）

例:
```dart
class Task {
  // 定数
  static const int maxTitleLength = 255;

  // フィールド
  final String uuid;
  final String title;

  // コンストラクタ
  Task({
    required this.uuid,
    required this.title,
  });

  // ファクトリコンストラクタ
  factory Task.fromJson(Map<String, dynamic> json) {
    // 実装
  }

  // メソッド
  Map<String, dynamic> toJson() {
    // 実装
  }
}
```

### メソッドの長さ

- 1メソッドは50行以内を推奨
- 長いメソッドは適切に分割する

### パラメータ

- パラメータが多い場合は名前付きパラメータを使用
- 必須パラメータは`required`キーワードを使用

例:
```dart
Future<Task> createTask({
  required String title,
  required DateTime scheduledDate,
  String? memo,
}) async {
  // 実装
}
```

## エラーハンドリング

### 例外処理

- 特定の例外をキャッチする場合は`on`を使用
- 一般的な例外は`catch`を使用

例:
```dart
try {
  await apiService.createTask(...);
} on ApiException catch (e) {
  // APIエラーの処理
} catch (e) {
  // 予期しないエラーの処理
}
```

### エラーメッセージ

- ユーザー向けのエラーメッセージは明確で分かりやすく
- 技術的な詳細はログに記録

## コメント

### ドキュメントコメント

- 公開APIには`///`を使用したドキュメントコメントを追加
- パラメータと戻り値の説明を含める

例:
```dart
/// タスクを作成します
///
/// [title] タスクのタイトル（必須）
/// [scheduledDate] 予定日（必須）
/// [memo] メモ（オプション）
///
/// 戻り値: 作成されたタスク
///
/// 例外: [ApiException] APIエラーが発生した場合
Future<Task> createTask({
  required String title,
  required DateTime scheduledDate,
  String? memo,
}) async {
  // 実装
}
```

### インラインコメント

- 複雑なロジックには説明コメントを追加
- 自明なコードにはコメントを追加しない

例:
```dart
// 日付文字列をDateTimeに変換（YYYY-MM-DD形式を想定）
final scheduledDate = DateTime.parse(dateString);
```

## 型

### 型の明示

- 可能な限り型を明示する
- 推論可能な場合でも、可読性のために型を明示することがある

例:
```dart
final String userName = 'John';
final List<Task> tasks = [];
```

### Null安全性

- Null安全性を活用する
- Nullable型は`?`を使用
- Nullチェックは適切に行う

例:
```dart
String? optionalString;

if (optionalString != null) {
  // Nullチェック後の処理
}

final length = optionalString?.length ?? 0;
```

## ウィジェット

### ウィジェットの構造

- 大きなウィジェットは適切に分割する
- 再利用可能なウィジェットは`widgets/`に配置

### Buildメソッド

- `build`メソッドは簡潔に保つ
- 複雑なUIは別メソッドに分割

例:
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _buildAppBar(),
    body: _buildBody(),
  );
}

Widget _buildAppBar() {
  // AppBarの実装
}

Widget _buildBody() {
  // Bodyの実装
}
```

## 非同期処理

### Futureとasync/await

- `async/await`を優先的に使用
- `.then()`は必要な場合のみ使用

例:
```dart
// 推奨
Future<void> loadData() async {
  final data = await apiService.getData();
  // 処理
}

// 避ける
Future<void> loadData() {
  apiService.getData().then((data) {
    // 処理
  });
}
```

### エラーハンドリング

- 非同期処理には必ずエラーハンドリングを追加

例:
```dart
Future<void> loadTasks() async {
  try {
    final tasks = await apiService.getTasks();
    setState(() {
      _tasks = tasks;
    });
  } catch (e) {
    // エラー処理
  }
}
```

## 状態管理

### StatefulWidget

- 状態が必要な場合のみ`StatefulWidget`を使用
- 状態が不要な場合は`StatelessWidget`を使用

### setState

- `setState`は必要な場合のみ呼び出す
- 複数の状態更新は1つの`setState`にまとめる

例:
```dart
void updateTask(Task task) {
  setState(() {
    _tasks.add(task);
    _isLoading = false;
  });
}
```

## テスト

### テストファイル

- テストファイルは`test/`ディレクトリに配置
- ファイル名は`*_test.dart`形式

### テストの構造

- `group`を使用してテストをグループ化
- テスト名は明確で説明的に

例:
```dart
void main() {
  group('ApiService', () {
    group('getTasks', () {
      test('should return list of tasks', () async {
        // テストコード
      });

      test('should throw ApiException on error', () async {
        // テストコード
      });
    });
  });
}
```

## リントルール

プロジェクトでは`flutter_lints`パッケージを使用しています。`analysis_options.yaml`で設定を確認してください。

### 主要なルール

- `avoid_print`: 本番コードでは`print`を避ける（デバッグ目的で必要な場合は`// ignore: avoid_print`コメントを使用）
- `prefer_const_constructors`: constコンストラクタを優先
- `prefer_single_quotes`: シングルクォートを優先
- `always_declare_return_types`: 戻り値の型を明示

## コードレビュー

### レビュー時の確認事項

- 命名規則に従っているか
- エラーハンドリングが適切か
- テストが追加されているか
- ドキュメントが更新されているか
- パフォーマンスに問題がないか

## 自動フォーマット

コードは自動フォーマットツールを使用して整形します。

```bash
dart format .
```

IDEの設定で保存時に自動フォーマットを有効にすることも推奨します。

## 参考資料

- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Style Guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
