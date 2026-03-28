# API仕様書

このドキュメントでは、Habit RPG Appで使用するAPIエンドポイントの仕様を説明します。

## ベースURL

開発環境: `http://habit_rpg_api.public.lvh.me`

本番環境: `http://habit_rpg_api.public.lvh.me`

**注意**: 実際のAPIエンドポイントは上記のベースURLに `/api` を追加した形式になります（例: `http://habit_rpg_api.public.lvh.me/api/auth/login`）。

## 認証

APIリクエストには認証トークンが必要です。トークンはHTTPヘッダーに含めて送信します。

```
Authorization: Bearer {token}
```

## 共通レスポンス形式

### 成功レスポンス

```json
{
  "data": { ... },
  "message": "成功メッセージ"
}
```

または

```json
{
  "result": true,
  "data": { ... }
}
```

### エラーレスポンス

```json
{
  "message": "エラーメッセージ",
  "errors": {
    "field_name": ["エラーメッセージ1", "エラーメッセージ2"]
  }
}
```

## エンドポイント一覧

### 認証関連

#### ログイン

**エンドポイント**: `POST /api/auth/login`

**リクエストボディ**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**レスポンス** (200 OK):
```json
{
  "token": "jwt_token_string",
  "expires_in": 3600,
  "data": {
    "name": "ユーザー名",
    "email": "user@example.com"
  }
}
```

**注意**: 実装では`data`内の`name`、`username`、`user_name`、`email`フィールドに対応しています。`uuid`は現在の実装では取得していません。

**エラーレスポンス**:
- 400 Bad Request: バリデーションエラー
- 401 Unauthorized: 認証失敗

#### ログアウト

**エンドポイント**: `POST /api/auth/logout`

**レスポンス** (200 OK): 空のレスポンス

#### 会員登録OTP送信

**エンドポイント**: `POST /api/auth/register/otp/send`

**リクエストボディ**:
```json
{
  "email": "user@example.com"
}
```

**レスポンス** (200 OK):
```json
{
  "message": "ワンタイムパスワードを送信しました。",
  "data": {
    "resend_available_at": "2026-03-27T12:01:00.000Z"
  }
}
```

`data` の返却条件:

- 通常の送信成功（200）では `resend_available_at`（ISO8601）を返します。
- レート制限（429 / throttling）では `retry_after`（秒）を返します。
- API仕様上は上記どちらか一方を返す想定です（排他的）。
- 後方互換のため、クライアント実装は両方を受け取っても動作し、`resend_available_at` を優先して扱います。

例（通常の送信成功）:
```json
{
  "message": "ワンタイムパスワードを送信しました。",
  "data": {
    "resend_available_at": "2026-03-27T12:01:00.000Z"
  }
}
```

例（レート制限）:
```json
{
  "message": "リクエストが多すぎます。",
  "data": {
    "retry_after": 45
  }
}
```

**エラーレスポンス**:
- 409 Conflict: 既存アカウント（重複メール）
- 422 Unprocessable Entity: メール形式不正
- 429 Too Many Requests: レート制限

#### 会員登録OTP検証

**エンドポイント**: `POST /api/auth/register/otp/verify`

**リクエストボディ**:
```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

**レスポンス** (200 OK):
```json
{
  "message": "ワンタイムパスワードを検証しました。",
  "data": {
    "registration_token": "reg_token_xxx"
  }
}
```

**エラーレスポンス**:
- 422 Unprocessable Entity: 誤OTP / 期限切れ
- 429 Too Many Requests: 試行回数超過

#### 会員登録完了

**エンドポイント**: `POST /api/auth/register/complete`

**リクエストボディ**:
```json
{
  "registration_token": "reg_token_xxx",
  "name": "ユーザー名",
  "password": "password123"
}
```

**レスポンス** (201 Created):
```json
{
  "message": "会員登録が完了しました。"
}
```

**エラーレスポンス**:
- 409 Conflict: 既存アカウント（重複メール）
- 422 Unprocessable Entity: name/password バリデーションエラー
- 429 Too Many Requests: 試行回数超過

`409 Conflict` が返る主なタイミング（`registration_token` / OTP verification との関係）:

- OTP verification が成功して `registration_token` を取得した後でも、最終登録時に重複チェックで 409 になる場合があります。
- 典型例は、OTP verification 後から `/api/auth/register/complete` 呼び出しまでの間に、別セッションや別端末で同じメールアドレスが先に登録されたケースです（レースコンディション）。
- トークン期限切れやトークン無効は 409 ではなく、通常は 422（入力/状態不正）として扱う想定です。クライアントは 422 受信時に再送・再認証フローへ戻します。

`409` は「完全に回避できる」エラーではなく、並行操作がある環境では発生し得る想定エラーです。  
クライアントは必ずハンドリングし、ログイン導線を提示してください（本アプリでは「ログインへ」ボタンを表示）。

---

### タスク関連

#### タスク一覧取得

**エンドポイント**: `GET /api/tasks`

**レスポンス** (200 OK):
```json
{
  "data": [
    {
      "uuid": "task-uuid",
      "title": "タスクタイトル",
      "scheduled_date": "2025-12-21",
      "scheduled_time": "14:30:00",
      "memo": "メモ内容",
      "is_completed": false,
      "created_at": "2025-12-21T10:00:00Z",
      "updated_at": "2025-12-21T10:00:00Z"
    }
  ]
}
```

または配列形式:
```json
[
  {
    "uuid": "task-uuid",
    "title": "タスクタイトル",
    ...
  }
]
```

#### タスク作成

**エンドポイント**: `POST /api/tasks`

**リクエストボディ**:
```json
{
  "title": "タスクタイトル",
  "scheduled_date": "2025-12-21",
  "scheduled_time": "14:30:00",
  "memo": "メモ内容（オプション）"
}
```

**レスポンス** (200/201 Created):
```json
{
  "data": {
    "uuid": "task-uuid",
    "title": "タスクタイトル",
    "scheduled_date": "2025-12-21",
    "scheduled_time": "14:30:00",
    "memo": "メモ内容",
    "is_completed": false,
    "created_at": "2025-12-21T10:00:00Z",
    "updated_at": "2025-12-21T10:00:00Z"
  }
}
```

**エラーレスポンス**:
- 400 Bad Request: バリデーションエラー
- 401 Unauthorized: 認証エラー

#### タスク更新

**エンドポイント**: `PUT /api/tasks/{uuid}`

**リクエストボディ**:
```json
{
  "title": "更新後のタスクタイトル",
  "scheduled_date": "2025-12-22",
  "scheduled_time": "15:00:00",
  "memo": "更新後のメモ内容（オプション）"
}
```

**レスポンス** (200 OK):
```json
{
  "data": {
    "uuid": "task-uuid",
    "title": "更新後のタスクタイトル",
    ...
  }
}
```

または 204 No Content（レスポンスボディなし）

**エラーレスポンス**:
- 400 Bad Request: バリデーションエラー
- 401 Unauthorized: 認証エラー
- 404 Not Found: タスクが見つからない

#### タスク削除

**エンドポイント**: `DELETE /api/tasks/{uuid}`

**レスポンス** (200/204 No Content): 空のレスポンス

**エラーレスポンス**:
- 401 Unauthorized: 認証エラー
- 404 Not Found: タスクが見つからない

#### タスク完了状態切り替え

**エンドポイント**: `PATCH /api/tasks/{uuid}/complete`

**リクエストボディ**:
```json
{
  "is_completed": true
}
```

**レスポンス** (200 OK):
```json
{
  "data": {
    "uuid": "task-uuid",
    "title": "タスクタイトル",
    "is_completed": true,
    ...
  }
}
```

**エラーレスポンス**:
- 400 Bad Request: バリデーションエラー
- 401 Unauthorized: 認証エラー
- 404 Not Found: タスクが見つからない

---

### ユーザー関連

#### ユーザー情報取得

**エンドポイント**: `GET /api/user`

**レスポンス** (200 OK):
```json
{
  "data": {
    "user_uuid": "user-uuid",
    "name": "ユーザー名",
    "email": "user@example.com",
    "is_dark_mode": false,
    "is_24_hour_format": false
  }
}
```

**エラーレスポンス**:
- 401 Unauthorized: 認証エラー

#### ユーザー情報更新

**エンドポイント**: `PUT /api/user`

**リクエストボディ** (すべてオプション):
```json
{
  "name": "新しいユーザー名",
  "email": "newemail@example.com",
  "password": "newpassword",
  "is_dark_mode": true,
  "is_24_hour_format": true
}
```

**レスポンス** (200 OK):
```json
{
  "data": {
    "user_uuid": "user-uuid",
    "name": "新しいユーザー名",
    "email": "newemail@example.com",
    "is_dark_mode": true,
    "is_24_hour_format": true
  }
}
```

**エラーレスポンス**:
- 400 Bad Request: バリデーションエラー
- 401 Unauthorized: 認証エラー

#### アカウント削除

**エンドポイント**: `DELETE /api/user`

**レスポンス** (200/204 No Content): 空のレスポンス

**エラーレスポンス**:
- 401 Unauthorized: 認証エラー

---

### AI提案関連

#### AI提案タスク一覧取得

**エンドポイント**: `GET /api/task-suggestions`

**レスポンス** (200 OK):
```json
{
  "data": [
    {
      "uuid": "suggestion-uuid",
      "title": "提案されたタスクタイトル",
      "memo": "メモ内容",
      "created_at": "2025-12-21T10:00:00Z",
      "updated_at": "2025-12-21T10:00:00Z"
    }
  ]
}
```

または

```json
{
  "result": true,
  "data": [ ... ]
}
```

**エラーレスポンス**:
- 401 Unauthorized: 認証エラー

#### AI提案タスク削除

**エンドポイント**: `DELETE /api/task-suggestions/{uuid}`

**レスポンス** (200/204 No Content): 空のレスポンス

**エラーレスポンス**:
- 401 Unauthorized: 認証エラー
- 404 Not Found: 提案が見つからない

---

## データ形式

### 日付形式

- `scheduled_date`: `YYYY-MM-DD`形式（例: `2025-12-21`）

### 時刻形式

- `scheduled_time`: `HH:mm:ss`形式（例: `14:30:00`）

### 日時形式

- `created_at`, `updated_at`: ISO8601形式（例: `2025-12-21T10:00:00Z`）

---

## エラーハンドリング

APIクライアントでは、`ApiException`クラスを使用してエラーを処理します。

```dart
try {
  await apiService.createTask(...);
} on ApiException catch (e) {
  // エラーメッセージを取得
  final message = e.getErrorMessage();

  // 特定のフィールドのエラーを取得
  final fieldError = e.getFieldError('title');

  // すべてのエラーメッセージを取得
  final allErrors = e.getAllErrorMessages();
}
```

## ステータスコード

- `200 OK`: リクエスト成功
- `201 Created`: リソース作成成功
- `204 No Content`: リクエスト成功（レスポンスボディなし）
- `400 Bad Request`: バリデーションエラー
- `401 Unauthorized`: 認証エラー
- `404 Not Found`: リソースが見つからない
- `500 Internal Server Error`: サーバーエラー
