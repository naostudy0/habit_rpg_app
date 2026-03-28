# 会員登録フロー仕様（フロントエンド）

このドキュメントは、Flutter 側の会員登録フロー実装を保守しやすくするための設計メモです。  
対象コードは `lib/screens/registration_*`、`lib/services/registration_flow_service.dart`、`lib/services/api_service.dart`、`lib/utils/registration_response_parsing.dart` です。

## 1. 画面遷移（Route と Step）

- 入口 Route: `/register`
- `main.dart` で `RegistrationFlowPage` を表示
- `RegistrationFlowPage` は `RegistrationFlowService.currentStep` で画面を切り替え

Step 遷移:

1. `emailInput` (`RegistrationEmailScreen`)
2. `otpVerification` (`RegistrationOtpScreen`)
3. `passwordSetup` (`RegistrationPasswordSetupScreen`)
4. `completed` (`RegistrationCompletedScreen`)

戻る遷移:

- `passwordSetup -> otpVerification`
- `otpVerification -> emailInput`
- `emailInput` と `completed` はフロー内で戻らない（Route 戻るのみ）

## 2. API 連携ポイント

`ApiService` の会員登録関連メソッド:

- `sendRegistrationOtp(email)`
  - `POST /api/auth/register/otp/send`
  - body: `{ "email": "<trim済みメール>" }`
- `verifyRegistrationOtp(email, otp)`
  - `POST /api/auth/register/otp/verify`
  - body: `{ "email": "<trim済みメール>", "otp": "<6桁コード>" }`
- `completeRegistration(registrationToken, name, password)`
  - `POST /api/auth/register/complete`
  - body: `{ "registration_token": "...", "name": "...", "password": "..." }`

共通レスポンスは `RegistrationApiResult` に正規化され、`status`（`success / created / conflict / unprocessableEntity / tooManyRequests / networkError / unknownError`）で画面側分岐を行います。

## 3. Token / 状態保持ポリシー

- OTP 検証成功時、`data.registration_token` を `parseRegistrationTokenFromData` で抽出
- `RegistrationFlowService.moveToPasswordSetup(registrationToken: ...)` でメモリ保持
- `registration_token` は永続化しない（`shared_preferences` 未保存）
- クリアされるタイミング:
  - `goBack()` で `passwordSetup` から戻る時
  - `completeRegistration()` 実行時
  - `reset()` 実行時

補足:

- メールアドレスは `RegistrationFlowService.email` に保持し、Email 画面再表示時も復元される
- OTP 再送クールダウン時刻は `resendAvailableAt` として保持される

## 4. エラー表示ポリシー（画面文言統一）

方針:

- API の生メッセージを直接表示しすぎず、画面向け固定文言に寄せる
- 主要異常系 `409 / 422 / 429` は次アクション（再入力・再送・待機）が分かる文言を優先

実装箇所:

- OTP送信/再送失敗: `registrationSendOtpErrorMessage`
- OTP検証失敗: `registrationVerifyOtpErrorMessage`
- 登録完了失敗: `mapRegistrationCompleteFailure`

代表ルール:

- `409`（既存アカウント）:
  - 「既に登録済み」メッセージ
  - パスワード設定画面では「ログインへ」導線を表示
- `422`（入力不正）:
  - Email/OTP は再入力誘導の固定文言
  - パスワード設定は `name` / `password` のフィールド別に表示
- `429`（試行超過・レート制限）:
  - 待機・再送を促す固定文言
- `networkError`:
  - `result.message` があれば優先、なければ接続確認文言
- その他:
  - 汎用失敗メッセージにフォールバック

## 5. ローディング・操作ガード

- `LoadingService` を操作単位で使用
  - `registration_send_otp`
  - `registration_otp_step`
  - `registration_complete`
- ローディング中は送信ボタンや戻る操作を無効化
- `mounted` チェック後に `setState` / 遷移を実施して dispose 後アクセスを防止

## 6. 保守時チェックリスト

仕様変更時は以下を同時更新する:

1. `docs/registration_flow.md`（このファイル）
2. `docs/api.md`（登録API仕様）
3. 関連テスト
   - `test/services/registration_flow_service_test.dart`
   - `test/utils/registration_response_parsing_test.dart`
   - `test/screens/registration_password_setup_screen_test.dart`
