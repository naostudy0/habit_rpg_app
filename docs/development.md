# 開発ガイドライン

このドキュメントでは、Habit RPG Appの開発におけるガイドラインを説明します。

## 開発環境のセットアップ

### 必要なツール

- Flutter SDK 3.41.6以上
- Dart SDK 3.11.0以上
- Git
- IDE（VS Code、Android Studio、IntelliJ IDEAなど）

### セットアップ手順

1. Flutter SDKをインストール
2. リポジトリをクローン
3. 依存関係をインストール: `flutter pub get`
4. 環境設定ファイルを作成: `lib/config/environment.dart`
5. アプリを実行: `flutter run`

## ブランチ戦略

### ブランチ命名規則

- `feature/`: 新機能開発
- `bug/`: バグ修正
- `docs/`: ドキュメント更新
- `refactor/`: リファクタリング
- `test/`: テスト追加・修正
- `ci/`: CI/CD設定

ブランチ名の形式: `種類/issue番号-説明`

例:
- `feature/27-common-loading-management`
- `bug/54-name-update`
- `test/39-add-test-code`
- `ci/60-auto-fullter-test`

### コミットメッセージ

明確で簡潔なコミットメッセージを心がけます。

形式:
```
[種類] 変更内容の簡潔な説明

詳細な説明（必要に応じて）
```

種類:
- `feat`: 新機能
- `bug`: バグ修正
- `docs`: ドキュメント
- `style`: コードスタイル（フォーマットなど）
- `refactor`: リファクタリング
- `test`: テスト
- `ci`: CI/CD設定
- `chore`: その他（ビルド設定など）

コミットメッセージの形式: `種類: 説明 #issue番号`

例:
```
feat: 共通ローディング状態管理 #27

- LoadingServiceの実装
- グローバルなローディング状態の管理
- ローディングウィジェットの追加
```

```
bug: 設定ページの名前更新エラー #54
```

```
ci: GitHub Actionsでプルリクエスト時に自動テスト実行を設定 #60
```

## コードレビュー

### レビューのポイント

- コードの可読性
- パフォーマンス
- エラーハンドリング
- テストの網羅性
- ドキュメントの更新

### レビュープロセス

1. プルリクエストを作成
2. レビューを依頼
3. フィードバックに対応
4. 承認後にマージ

## テスト

### テストの種類

#### ユニットテスト

各サービスやユーティリティのテストを`test/`ディレクトリに配置します。

```dart
// test/services/api_service_test.dart
void main() {
  group('ApiService', () {
    test('should return tasks list', () async {
      // テストコード
    });
  });
}
```

#### ウィジェットテスト

ウィジェットの動作をテストします。

```dart
// test/widget_test.dart
void main() {
  testWidgets('TaskListPage displays tasks', (WidgetTester tester) async {
    // テストコード
  });
}
```

#### 統合テスト

アプリ全体の動作をテストします。サービス間の連携やモデルの変換など、複数のコンポーネントが協調して動作することを確認します。

```dart
// test/integration_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete app flow', (WidgetTester tester) async {
    // テストコード
  });
}
```

### テストの実行

```bash
# すべてのテストを実行
flutter test

# 特定のテストファイルを実行
flutter test test/services/api_service_test.dart

# カバレッジを取得
flutter test --coverage
```

## デバッグ

### ログ出力

デバッグ時は`print`を使用しますが、本番コードでは削除またはコメントアウトします。

```dart
// デバッグ用（本番では削除）
// ignore: avoid_print
print('Debug: $value');
```

### デバッグモードでの実行

```bash
flutter run --debug
```

### プロファイルモードでの実行

```bash
flutter run --profile
```

## パフォーマンス

### ベストプラクティス

- 不要な再ビルドを避ける
- 大きなリストは`ListView.builder`を使用
- 画像は適切なサイズにリサイズ
- ネットワークリクエストは適切にキャッシュ

### パフォーマンス測定

```bash
flutter run --profile
```

Flutter DevToolsを使用してパフォーマンスを分析します。

## エラーハンドリング

### エラー処理の原則

1. ユーザーフレンドリーなエラーメッセージを表示
2. エラーの詳細はログに記録
3. ネットワークエラーは適切に処理
4. 予期しないエラーはキャッチして処理

### エラーハンドリングの例

```dart
try {
  await apiService.createTask(...);
} on ApiException catch (e) {
  // APIエラーの処理
  final message = e.getErrorMessage();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
} catch (e) {
  // 予期しないエラーの処理
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('予期しないエラーが発生しました')),
  );
}
```

## 依存関係の管理

### パッケージの追加

```bash
flutter pub add package_name
```

### パッケージの更新

```bash
flutter pub upgrade
```

### パッケージの削除

`pubspec.yaml`から削除後、以下を実行:

```bash
flutter pub get
```

## ビルドとデプロイ

### デバッグビルド

```bash
flutter build apk --debug
flutter build ios --debug
```

### リリースビルド

```bash
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```

### ビルド前の確認事項

- 環境変数の設定確認
- テストの実行
- リントチェック: `flutter analyze`
- コードフォーマット: `dart format .`

## コードフォーマット

### 自動フォーマット

```bash
dart format .
```

### リントチェック

```bash
flutter analyze
```

## ドキュメント

### コードコメント

必要に応じて簡潔なコメントを追加します。

```dart
// 予定作成API
Future<Task> createTask({
  required String title,
  required DateTime scheduledDate,
  required TimeOfDay scheduledTime,
  String? memo,
}) async {
  // 実装
}
```

クラスや重要なメソッドには簡潔なドキュメントコメントを追加することもあります。

```dart
/// 予定データのモデルクラス
class Task {
  // ...
}
```

### ドキュメントの更新

以下の変更時はドキュメントも更新します:

- API仕様の変更
- アーキテクチャの変更
- 新機能の追加
- 設定の変更

## セキュリティ

### ベストプラクティス

- 認証トークンは安全に保存
- 環境変数はバージョン管理に含めない
- 機密情報はハードコードしない
- HTTPSを使用（本番環境）

### 環境変数の管理

`lib/config/environment.dart`は`.gitignore`に含まれています。本番環境の設定は安全に管理してください。

## トラブルシューティング

### よくある問題

#### 依存関係のエラー

```bash
flutter clean
flutter pub get
```

#### ビルドエラー

```bash
flutter clean
flutter pub get
flutter run
```

#### キャッシュの問題

```bash
flutter clean
```

## 参考資料

- [Flutter公式ドキュメント](https://docs.flutter.dev/)
- [Dart公式ドキュメント](https://dart.dev/)
- [Flutter Best Practices](https://docs.flutter.dev/development/best-practices)
