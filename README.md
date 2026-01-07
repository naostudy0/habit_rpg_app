# Habit RPG App

AIがあなたの過去の行動から「続けられる習慣」を提案する、RPG風 習慣管理アプリ  
（ポートフォリオ）

## 概要

Habit RPG Appは、日々の習慣や予定をRPG要素で楽しく管理できるFlutterアプリです。

最大の特徴は、Docker上で動作するLLM（大規模言語モデル）を用いて、過去の予定データを分析し、その人に合った新しい習慣・予定をAIが提案する点です。

本アプリは AI駆動開発の学習・実践 を目的として個人で開発したポートフォリオであり、
バックエンド（Laravel / Docker / AI連携）を主軸に設計・実装しています。


- AIによる予定生成ロジックは Laravel側で実装
- Flutterは主にUI・API連携を担当（※バックエンドエンジニアのため、Flutterの実装は必要十分レベル）

## コンセプト

- 習慣化が苦手な人でも「ゲーム感覚」で続けられる
- 過去の行動履歴をもとに、無理のない現実的な習慣をAIが提案
- LLMを実サービス想定で扱うため、Docker環境にAIを組み込んだ構成を採用

## 主な機能

- ユーザー認証（ログイン・ログアウト）

- 予定・習慣管理
  - 作成 / 編集 / 削除
  - 完了状態の切り替え

- 予定一覧表示
  - リスト表示
  - カレンダー表示

- AIによる予定・習慣提案
  - 過去の予定データを元にLLMが提案
  - Laravel側でプロンプト設計・生成処理を実装

- ユーザープロフィール管理
  - プロフィール編集
  - メールアドレス変更
  - パスワード変更

- 設定管理
  - ダークモード
  - 時刻形式

## システム構成（概要）

```
Flutter（フロントエンド）
        ↓ HTTP API
Laravel（バックエンド / API）
        ↓
Docker上のLLM
```

- Flutter：UI・状態管理・API通信
- Laravel：認証、予定管理、AIプロンプト生成、レスポンス整形
- Docker：LLM実行環境を含むバックエンド基盤

詳細は[アーキテクチャドキュメント](docs/architecture.md)を参照してください。

## 技術スタック（フロントエンド）

- フレームワーク: Flutter 3.8.1+
- 言語: Dart
- 状態管理: StatefulWidget（シンプルさを重視）
- HTTP通信: http
- ローカルストレージ: shared_preferences
- 対応プラットフォーム: iOS / Android / Web / macOS / Linux / Windows

## 技術スタック（バックエンド・インフラ）

- バックエンド: Laravel
- 実行環境: Docker
- AI / LLM: Dockerコンテナ上で稼働

### 設計方針

- APIファースト
- AIロジックはLaravel側に集約
- 実務利用を想定した構成

## 必要な環境（Flutter）

- Flutter SDK 3.8.1以上
- Dart SDK 3.8.1以上
- 各プラットフォームの開発環境
  - iOS: Xcode
  - Android: Android Studio など

※ バックエンド（Laravel / Docker / LLM）のセットアップは別リポジトリまたは別READMEを参照してください。

## セットアップ（Flutter）

詳細なセットアップ手順や開発ガイドラインについては[開発ガイドライン](docs/development.md)を参照してください。

### 1. リポジトリのクローン

```bash
git clone https://github.com/naostudy0/habit_rpg_app.git
cd habit_rpg_app
```

### 2. 依存関係のインストール

```bash
flutter pub get
```

### 3. 環境設定

`lib/config/environment.example.dart` を参考に
`lib/config/environment.dart` を作成してください。

```bash
cp lib/config/environment.example.dart lib/config/environment.dart
```

APIのベースURL（Laravel側）を設定します。API仕様の詳細は[API仕様書](docs/api.md)を参照してください。

### 4. アプリの起動

```bash
# デバッグ実行
flutter run

# プラットフォーム指定
flutter run -d ios
flutter run -d android
flutter run -d chrome
```

## ビルド

### iOS

```bash
flutter build ios
```

### Android

```bash
flutter build apk
# または
flutter build appbundle
```

### Web

```bash
flutter build web
```

## テスト

```bash
# 全テスト実行
flutter test

# 個別実行
flutter test test/services/api_service_test.dart
```

テストの詳細については[開発ガイドライン](docs/development.md)を参照してください。

## プロジェクト構造

```
lib/
├── config/          # 環境設定
├── models/          # データモデル
├── screens/         # 画面
├── services/        # API通信・ロジック
├── utils/           # ユーティリティ
└── widgets/         # 共通ウィジェット
```

詳細な構造や各レイヤーの責務については[アーキテクチャドキュメント](docs/architecture.md)を参照してください。

## ドキュメント

プロジェクトの詳細なドキュメントは`docs/`ディレクトリにあります：

- [API仕様書](docs/api.md) - APIエンドポイントの仕様と使用方法
- [アーキテクチャドキュメント](docs/architecture.md) - アーキテクチャと設計思想
- [コーディング規約](docs/coding_standards.md) - コーディング規約とスタイルガイド
- [開発ガイドライン](docs/development.md) - 開発環境のセットアップと開発フロー

## このプロジェクトについて

本プロジェクトは、ポートフォリオとして個人で開発したアプリケーションです。
実務を想定した設計・技術選定を行っていますが、商用サービスとしての提供は行っていません。

- AI駆動開発の学習・実践が主目的です
- バックエンド（Laravel / Docker / AI連携）に注力しています
- Flutterは実務利用を想定した最低限＋αの実装です

また、習慣管理 × RPG × AI を段階的に発展させていくことを前提に、
拡張しやすいバックエンド設計を意識しています。

## 今後追加予定の機能

- AIを活用した経験値・レベルシステム
  - 予定・習慣の内容や継続状況に応じて経験値を付与
  - ユーザーの行動傾向を踏まえた成長バランスをAIが調整

## ライセンス

本リポジトリは個人のポートフォリオ目的で公開しています。
