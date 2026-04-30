# CLAUDE.md

このファイルは、本リポジトリで作業する Claude Code (claude.ai/code) へのガイドです。

## プロジェクト概要

`pocket_sync` は端末上のファイルを S3 と同期する Flutter アプリ。対象プラットフォームは **Android と iOS のみ**。Web / デスクトップ向けの依存（例: `flutter_web_plugins`）やプラットフォーム固有コードは追加しない。

## ツールチェイン (mise)

Flutter SDK は [mise.toml](mise.toml) でバージョン固定されており、**PATH には載っていない**。Flutter / Dart 系コマンドはすべて mise 経由で実行する:

```bash
mise exec -- flutter pub get
mise exec -- flutter run
mise exec -- flutter test
mise exec -- flutter test test/path/to/specific_test.dart      # 単一ファイル
mise exec -- flutter test --name "matches description"          # 単一テスト
mise exec -- flutter test --coverage                            # coverage/lcov.info を出力
mise exec -- flutter analyze                                    # Flutter固有のlintを含む静的解析（推奨）
mise exec -- dart analyze                                       # Pure Dart静的解析。flutter analyzeとほぼ同等の結果
mise exec -- flutter gen-l10n                                   # ARBファイル変更後に手動で再生成する場合
mise exec -- dart format .
```

`flutter pub outdated` / `flutter pub upgrade` も同様に `mise exec --` 経由で実行する。`flutter analyze` と `dart analyze` は本プロジェクト構成ではほぼ同じ結果になるが、Flutter 固有の lint まで網羅するなら前者を使う。

## アーキテクチャ

### MVVM のレイヤー構成 ([docs/adr/0003](docs/adr/0003-state-management-with-provider.md) 参照)

[lib/](lib/) 配下は 3 層に分かれている:

- **`lib/domain/models/`** — イミュータブルなドメインモデル (`@immutable`、`copyWith` / `==` / `hashCode` は手書き。コード生成はまだ導入していない)。
- **`lib/data/repositories/`** — データソース。Repository はバックエンドストアをコンストラクタ注入で受け取る (例: `SettingsRepository({required SharedPreferences prefs})`)。永続化キーは `static const` として Repository 内に置く。
- **`lib/ui/features/<feature>/views/`** + **`lib/ui/features/<feature>/view_models/`** — feature 単位の UI。ViewModel は `ChangeNotifier` を継承する。View は `provider` 経由で ViewModel を read / watch する。
- **`lib/ui/core/`** — feature 横断の共通ウィジェット (例: `ScaffoldWithNavBar`)。

[test/](test/) 配下も同じ構成をミラーする。

### 依存の結線

Repository と ViewModel の組み立ては **`main()` だけで行う**。`SharedPreferences.getInstance()` を await してから `MultiProvider` に注入し、`SettingsRepository`（プレーンな `Provider`）と `SettingsViewModel`（`ChangeNotifierProvider`）として公開する。新しいシングルトンを追加するときも main.dart に集約する — Service Locator パターンは導入しない。

ViewModel は **先にローカル状態を更新して `notifyListeners()` を呼び**、その後 Repository へ書き込む。書き込み失敗時は前の状態にロールバックして再度 `notifyListeners()` し、例外を rethrow する ([settings_view_model.dart](lib/ui/features/settings/view_models/settings_view_model.dart) 参照)。新しいミューテータを追加するときもこの「楽観的更新 + 失敗時ロールバック」の形を維持する。

### ルーティング ([docs/adr/0004](docs/adr/0004-routing-with-go-router.md) 参照)

`GoRouter` インスタンスは [lib/routing/app_router.dart](lib/routing/app_router.dart) に **1 つだけ**存在し、`main.dart` の `MaterialApp.router` から消費される。ルート定義を feature ディレクトリに分散させない。

- `StatefulShellRoute.indexedStack` で BottomNav (Files / Activity) を構築し、各タブのナビゲーションスタックを保持する。
- `/settings` のような最上位画面は **shell の外側** に置いて BottomNav を覆うように push する。
- タブ切替は `navigationShell.goBranch(index, initialLocation: index == currentIndex)`。アクティブなタブを再タップするとそのタブのルートに pop される。
- 画面遷移は `context.push('/settings')` などで行う。パスパラメータは `state.pathParameters['id']!` で取り出す。

### 同期ステータスのモデリング ([docs/adr/0001](docs/adr/0001-unified-file-view-with-sync-status.md), [0002](docs/adr/0002-sync-status-as-sealed-class.md) 参照)

ファイル一覧は **1 画面の統一ビュー** で、ローカル / リモート別の画面は作らない。ファイルごとの同期状態は `sealed class SyncStatus` とそのサブクラス (`Synced`, `LocalOnly`, `Uploading(progress)`, `Conflict(local, remote)`, `SyncError(reason, retryable)`, …) で表現する。UI 側は `default:` を **書かずに** `switch` 式で網羅的に分岐する。新しい状態を追加したときにコンパイルエラーで未対応箇所が炙り出される構造を維持するため。

### 国際化 (i18n) ([docs/adr/0005](docs/adr/0005-i18n-with-flutter-localizations.md) 参照)

UI 文字列は **すべて [lib/l10n/app_ja.arb](lib/l10n/app_ja.arb)（テンプレート）に集約**する。直接 `Text('...')` に日本語を書かない。サポート言語は `ja`（一次）と `en`（将来用）。

- View 内では `final l10n = context.l10n;` を取得し、`l10n.<key>` で参照する。`AppLocalizations.of(context)!` を直接書かない。
- `context.l10n` extension は [lib/l10n/l10n_extension.dart](lib/l10n/l10n_extension.dart) で定義され、delegate 未登録時は `FlutterError` で原因を明示する。
- 新規キー追加時は `app_ja.arb` に `<key>` と `@<key>` の `description` を必須記述、`app_en.arb` に同キーの英訳を追加 → `mise exec -- flutter gen-l10n` で再生成（`flutter pub get` でも生成される）。
- `lib/l10n/app_localizations.dart` および `app_localizations_<locale>.dart` は **生成物で `.gitignore` 対象**。手書きしない。
- placeholder 付きキーは `"keyName": "Hello {name}"` のように書き、`@keyName.placeholders.name.type` を ARB メタで指定する。
- テスト時は `MaterialApp(locale: const Locale('ja'), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, …)` で日本語ロケールを強制する。`platformDispatcher.localeTestValue` は安定しないので使わない。

## コーディング規約

- **Lint**: [analysis_options.yaml](analysis_options.yaml) で `very_good_analysis` を適用。フォーマッタは **80 列**設定なので `dart format .` で 80 列に折り返される。`public_member_api_docs` と `sort_pub_dependencies` は意図的に無効化している。
- **UI 文字列は ARB に集約** (ADR-0005)。`Text('...')` に日本語を直書きしない。詳細は上記「国際化 (i18n)」セクション。
- **bool パラメータ**は named の `{required bool value}` 形式 (very_good_analysis の named-bool ルール)。
- **コード生成は未導入**。ADR なしに `freezed` / `json_serializable` を持ち込まない。ドメインモデルは equality を手書きする。
- ADR は [docs/adr/](docs/adr/) に MADR v4 形式で置く。新規作成は `adr-creator` skill ([.claude/skills/adr-creator/](.claude/skills/adr-creator/)) を使い、[docs/adr/README.md](docs/adr/README.md) に索引を追記する。

## プロジェクトルール ([.claude/rules/](.claude/rules/))

以下は遵守事項。詳細は各ファイルを参照。

- **[git.md](.claude/rules/git.md)** — GitHub Flow (`main` から切って PR で戻す)、Conventional Commits (`feat` / `fix` / `docs` / `chore` / …)。`main` へのマージで semantic-release が走るため、コミット type がリリースバージョンを決める (`feat` → minor、`fix` / `perf` → patch、`BREAKING CHANGE` → major)。
- **[security.md](.claude/rules/security.md)** — OWASP MASVS v2。特に: 認証情報・トークンは `flutter_secure_storage` (Keychain / Keystore) に保存し、**`SharedPreferences` には絶対に置かない**。HTTP 平文通信禁止。リリースビルドに `BadCertificateCallback => true` を含めない。デバッグログは `kDebugMode` でガードする。
- **[coding-style.md](.claude/rules/coding-style.md)** — [Effective Dart](https://dart.dev/effective-dart) 準拠の命名・ドキュメント・言語機能利用・API 設計のルール。`very_good_analysis` で機械チェックされない部分（頭字語の扱い、`///` ドキュメントの書き方、`lib/` 内は相対 import、空コレクションを返し `null` を返さない、`async` の付け方、getter に副作用を持たせない 等）を補完する。
