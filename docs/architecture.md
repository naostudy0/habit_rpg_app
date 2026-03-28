# アーキテクチャドキュメント

このドキュメントでは、Habit RPG Appのアーキテクチャと設計思想について説明します。

## アーキテクチャ概要

Habit RPG Appは、Flutterフレームワークを使用したモバイルアプリケーションです。レイヤードアーキテクチャを採用し、責務を明確に分離しています。

## プロジェクト構造

```
lib/
├── config/              # 設定ファイル
│   ├── environment.dart          # 環境設定（.gitignoreに含まれる）
│   └── environment.example.dart # 環境設定のテンプレート
├── models/              # データモデル
│   ├── task.dart
│   ├── task_suggestion.dart
│   └── user.dart
├── screens/             # 画面コンポーネント
│   ├── email_change_page.dart
│   ├── feedback_page.dart
│   ├── help_support_page.dart
│   ├── login_page.dart
│   ├── mypage.dart
│   ├── mypage_top.dart
│   ├── password_change_page.dart
│   ├── profile_edit_page.dart
│   ├── registration_completed_screen.dart
│   ├── registration_email_screen.dart
│   ├── registration_flow_page.dart  # RegistrationFlowPage
│   ├── registration_otp_screen.dart
│   ├── registration_password_setup_screen.dart
│   ├── settings_page.dart
│   ├── task_calendar_page.dart
│   ├── task_create_page.dart
│   ├── task_edit_page.dart
│   ├── task_list_page.dart
│   └── top_page.dart
├── services/            # ビジネスロジック・API通信
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── error_handler.dart
│   ├── loading_service.dart
│   ├── registration_flow_service.dart # RegistrationFlowService
│   └── settings_service.dart
├── utils/               # ユーティリティ
│   ├── registration_response_parsing.dart
│   └── time_formatter.dart
├── widgets/             # 再利用可能なウィジェット
│   └── loading_widget.dart  # LoadingWidget, LoadingOverlay, SimpleLoadingIndicator
└── main.dart            # エントリーポイント
```

## レイヤー構成

### 1. Presentation Layer（プレゼンテーション層）

画面コンポーネント（`screens/`）とウィジェット（`widgets/`）で構成されます。

**責務**:
- UIの表示とユーザーインタラクションの処理
- ユーザー入力の検証
- 状態管理（StatefulWidgetを使用）

**特徴**:
- 各画面は独立したStatefulWidgetとして実装
- ビジネスロジックはService層に委譲
- 再利用可能なウィジェットは`widgets/`に配置

**主要なウィジェット**:
- `LoadingWidget`: `LoadingService`と連携してローディング状態を表示
- `LoadingOverlay`: 指定されたローディング状態に応じてオーバーレイを表示
- `SimpleLoadingIndicator`: シンプルなローディングインジケーター

### 2. Service Layer（サービス層）

ビジネスロジックとAPI通信を担当します（`services/`）。

**主要なサービス**:

#### ApiService
- API通信の一元管理
- 認証トークンの自動付与
- エラーハンドリング
- レスポンスのパースとモデルへの変換

#### AuthService
- 認証状態の管理
- トークンの保存・取得・検証
- ユーザー情報のローカル保存

#### SettingsService
- アプリ設定の管理
- テーマモードの管理（ダークモード/ライトモード）
- 時刻形式の管理（24時間形式/12時間形式）
- 設定変更の通知（ChangeNotifierを継承）

**注意**: `language`と`dateFormat`の設定は実装されていますが、現在のアプリでは使用されていません。

#### ErrorHandler
- エラーの統一的な処理
- ユーザーフレンドリーなエラーメッセージの表示
- エラータイプの分類（ネットワーク、認証、バリデーションなど）

#### LoadingService
- ローディング状態の管理（ChangeNotifierを継承）
- グローバルなローディング状態の管理
- 操作単位でのローディング状態の管理

**責務**:
- API通信の実装
- データの変換とバリデーション
- ローカルストレージへのアクセス
- ビジネスロジックの実装

### 3. Model Layer（モデル層）

データモデルを定義します（`models/`）。

**主要なモデル**:

#### Task
- タスクのデータ構造
- JSONシリアライゼーション
- バリデーション

#### User
- ユーザー情報のデータ構造
- JSONシリアライゼーション

#### TaskSuggestion
- AI提案タスクのデータ構造
- JSONシリアライゼーション

**責務**:
- データ構造の定義
- JSONとの相互変換
- データのバリデーション

### 4. Utility Layer（ユーティリティ層）

共通のユーティリティ関数を提供します（`utils/`）。

**責務**:
- 日時フォーマット
- その他の共通処理

### 5. Configuration Layer（設定層）

アプリケーションの設定を管理します（`config/`）。

**責務**:
- 環境変数の管理
- APIエンドポイントの設定

## データフロー

```
ユーザー操作
    ↓
Screen (UI)
    ↓
Service (ビジネスロジック)
    ↓
ApiService (API通信)
    ↓
Backend API
    ↓
ApiService (レスポンス処理)
    ↓
Model (データ変換)
    ↓
Service (状態更新)
    ↓
Screen (UI更新)
```

## 状態管理

現在はFlutterの標準的な`StatefulWidget`を使用しています。

- 各画面でローカル状態を管理
- グローバルな状態は`SettingsService`（ChangeNotifier）で管理
- 認証状態は`AuthService`で管理
- ローディング状態は`LoadingService`（ChangeNotifier）で管理

`SettingsService`と`LoadingService`は`ChangeNotifier`を継承しており、`notifyListeners()`を呼び出すことで状態変更を通知します。

## 会員登録フロー（メール認証 + OTP）

会員登録は `/register` を入口に、以下のステップで進行します。

1. メール入力
2. OTP入力・検証
3. 表示名/パスワード設定
4. 完了（ログイン導線）

ステップ状態は `RegistrationFlowService` が保持し、`RegistrationFlowPage` が `currentStep` を監視して画面を切り替えます。  
詳細仕様（token保持、主要異常系の表示方針、再送クールダウン）は [会員登録フロー仕様](registration_flow.md) を参照してください。

## 依存関係の注入

シングルトンパターンを使用してサービスを管理しています。

```dart
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
}
```

## エラーハンドリング

### ApiException

APIエラーは`ApiException`クラスで統一的に処理します。

```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;
}
```

### エラー処理の流れ

1. APIリクエストでエラーが発生
2. `ApiException`をスロー
3. Screen層でキャッチしてユーザーに表示

## 認証フロー

1. ユーザーがログイン情報を入力
2. `ApiService.login()`でAPIにリクエスト
3. レスポンスからトークンを取得
4. `AuthService.saveToken()`でトークンを保存
5. 以降のAPIリクエストで自動的にトークンを付与

## ローカルストレージ

`shared_preferences`を使用して以下の情報を保存します:

### AuthServiceで管理
- 認証トークン
- トークンの有効期限
- 認証状態フラグ
- ユーザー名・メールアドレス

### SettingsServiceで管理
- ダークモード設定（`isDarkMode`）
- 時刻形式設定（`is24HourFormat` - 24時間形式/12時間形式）

**注意**: `language`と`dateFormat`の設定は実装されていますが、現在のアプリでは使用されていません。

## ルーティング

`main.dart`でルーティングを定義しています。

```dart
routes: {
  '/': (context) => const AuthCheckWrapper(child: TopPage()),
  '/login': (context) => const LoginPage(),
  '/register': (context) => const RegistrationFlowPage(),
  '/mypage': (context) => const MyPage(),
  '/mypage_top': (context) => const MyPageTop(),
}
```

### AuthCheckWrapper

`AuthCheckWrapper`は認証状態をチェックするラッパーウィジェットです。

- アプリ起動時に認証状態を確認
- 認証済みの場合は自動的に`/mypage_top`に遷移
- 未認証の場合は`TopPage`を表示
- 認証チェック中はローディングインジケーターを表示

## テーマ管理

Material 3を使用し、`SettingsService`でテーマモードを管理します。

- ライトテーマ
- ダークテーマ

`SettingsService`の`isDarkMode`フラグで管理され、`themeMode`プロパティを通じて`ThemeMode.dark`または`ThemeMode.light`のいずれかが`MaterialApp`に適用されます。

設定変更時は`notifyListeners()`が呼ばれ、`MyApp`の`_onSettingsChanged`コールバックで`setState()`が実行されることで、アプリ全体のテーマが更新されます。

## テスト戦略

### ユニットテスト

- `test/services/`: サービスのテスト
- `test/screens/`: 画面のテスト

### 統合テスト

- `test/integration_test.dart`: 統合テスト
