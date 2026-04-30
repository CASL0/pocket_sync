---
description: OWASP MASVS v2に基づくモバイルアプリセキュリティルール（Flutter/Dart）
paths:
  - "**/*"
---

# Security Rules（OWASP MASVS v2）

## MASVS-STORAGE: データの安全な保存

### 機密データの保存
- 認証情報・APIキー・トークン・個人情報は `flutter_secure_storage` を使いKeychain（iOS）/ Keystore（Android）に保存する
- `SharedPreferences` や通常ファイルに機密データを平文で保存しない
- バックアップ対象から機密データを除外する（Android: `android:allowBackup="false"` または `BackupAgent` で除外）
- アプリのキャッシュディレクトリに機密データを書き込まない

### ログ・デバッグ出力
- 認証情報・トークン・個人情報・機密データをログに出力しない
- リリースビルドでは `debugPrint` / `print` を無効化する（`kDebugMode` でガードする）
- クラッシュレポートに機密データが含まれないようにする

### クリップボード
- パスワード・トークン等の機密フィールドはクリップボードへのコピーを制限する（`obscureText: true` のフィールドには `enableInteractiveSelection: false`）

---

## MASVS-CRYPTO: 暗号化

### アルゴリズム
- 独自の暗号アルゴリズムを実装しない
- 非推奨アルゴリズム（MD5・SHA-1・DES・3DES・RC4・ECBモード）を使用しない
- 対称暗号化にはAES-256-GCMを使用する
- ハッシュにはSHA-256以上を使用する
- パスワードの保存にはbcrypt・scrypt・Argon2を使用する

### 鍵管理
- 暗号鍵・シークレットをソースコードにハードコードしない
- 暗号鍵はKeychain / Keystoreで管理する
- 乱数生成には `Random.secure()` を使用する（`math.Random()` は暗号用途に使わない）

---

## MASVS-AUTH: 認証・認可

### 認証情報
- APIキー・シークレット・証明書をソースコードやgitリポジトリにコミットしない
- 認証情報は環境変数または安全なストレージから取得する
- `.env` ファイルを `.gitignore` に追加し、誤ってコミットしない

### セッション管理
- アクセストークンには有効期限を設定する
- リフレッシュトークンの失効・ローテーションを実装する
- ログアウト時にはローカルのトークン・セッション情報を完全に削除する
- 生体認証（Face ID / 指紋）をローカル認証として活用する場合は `local_auth` パッケージを使用する

---

## MASVS-NETWORK: ネットワーク通信

### TLS
- すべての通信はHTTPS（TLS 1.2以上）を使用する
- 自己署名証明書・無効な証明書を本番環境で許可しない
- `BadCertificateCallback` でtrueを返すコードをリリースビルドに含めない
- HTTP平文通信（`http://`）を使用しない

### Certificate Pinning
- MITM攻撃対策として重要な通信にはCertificate Pinningを実装する
- `http` パッケージのカスタム `HttpClient` またはDioのInterceptorで実装する

### データ検証
- サーバーからのレスポンスをそのままUIに表示する前にバリデーションする
- JSONデコード時の例外を適切にハンドリングする

---

## MASVS-PLATFORM: プラットフォーム連携

### Intent / URL Scheme
- Deep Link（カスタムURLスキーム）のパラメーターを信頼せず必ずバリデーションする
- Intentを通じて受信したデータはサニタイズしてから処理する
- Universal Links（iOS）/ App Links（Android）を使いカスタムスキームより優先する

### WebView
- WebViewでJavaScriptを有効にする場合は信頼できたコンテンツのみ表示する
- `WebView` に任意のURLを渡さない（許可リストで制限する）
- `allowFileAccessFromFileURLs` / `allowUniversalAccessFromFileURLs` を有効にしない

### 権限
- 必要最小限の権限のみをマニフェストに宣言する
- 権限は使用する直前にリクエストし、目的を明示する

---

## MASVS-CODE: コード品質

### 入力バリデーション
- ユーザー入力はすべてバリデーション・サニタイズしてから使用する
- SQLインジェクション・パスインジェクション・コマンドインジェクションに注意する
- ファイルパスにユーザー入力を使う場合はパストラバーサルを防ぐ

### 依存関係
- `flutter pub outdated` を定期的に実行し、脆弱性のある依存を更新する
- 不要な依存パッケージを削除する
- `dart pub audit`（または `flutter pub audit`）で既知の脆弱性を確認する

### コード品質
- `dart analyze` の警告・エラーをゼロに保つ
- `very_good_analysis` のlintルールに従う
- デバッグコード・フラグをリリースビルドに含めない（`kDebugMode` でガードする）

---

## MASVS-RESILIENCE: 耐タンパー性

### 難読化
- リリースビルドでは難読化を有効にする
  ```
  flutter build apk --obfuscate --split-debug-info=build/debug-info
  flutter build ipa --obfuscate --split-debug-info=build/debug-info
  ```

### ビルド設定
- デバッグビルドと本番ビルドで異なるAPIエンドポイント・設定を使う（`--dart-define` または `flavor` で分離）
- デバッグ用の特権機能（管理者メニュー・テスト用APIキー等）を本番ビルドに含めない

---

## MASVS-PRIVACY: プライバシー

### データ最小化
- 機能に必要な最小限のデータのみ収集する
- 不要になったデータは速やかに削除する

### ユーザー同意
- 個人データの収集・利用については明示的なユーザー同意を得る
- プライバシーポリシーを明示する

### トラッキング
- サードパーティのアナリティクス・広告SDKが収集するデータを把握し、プライバシーポリシーに反映する
- iOS App Tracking Transparency（ATT）フレームワークに準拠する
