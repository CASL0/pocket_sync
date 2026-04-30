# pocket_sync

端末ストレージ上のファイルを Amazon S3 と同期するモバイルアプリ。

> **ステータス**: 開発中。設定画面までを実装済みで、ファイル同期機能は未着手。

## 対象プラットフォーム

- Android
- iOS

Web / デスクトップは対象外。

## 技術スタック

- **Flutter**（バージョンは [mise.toml](mise.toml) で固定）
- **状態管理**: [Provider](https://pub.dev/packages/provider) + `ChangeNotifier`（[ADR-0003](docs/adr/0003-state-management-with-provider.md)）
- **ルーティング**: [go_router](https://pub.dev/packages/go_router) + `StatefulShellRoute.indexedStack`（[ADR-0004](docs/adr/0004-routing-with-go-router.md)）
- **永続化**: [shared_preferences](https://pub.dev/packages/shared_preferences)（非機密設定）。認証情報は `flutter_secure_storage` 予定
- **国際化**: `flutter_localizations` + ARB（[ADR-0005](docs/adr/0005-i18n-with-flutter-localizations.md)、対応言語: ja / en）
- **Lint**: [very_good_analysis](https://pub.dev/packages/very_good_analysis) + [Effective Dart](https://dart.dev/effective-dart) 準拠の追加ルール（[.claude/rules/coding-style.md](.claude/rules/coding-style.md)）

## セットアップ

[mise](https://mise.jdx.dev/) で Flutter SDK を管理しているため、Flutter コマンドは `mise exec --` 経由で実行する。

```bash
mise install                       # mise.toml に従って Flutter SDK をインストール
mise exec -- flutter pub get       # 依存を解決
mise exec -- flutter run           # 接続中のデバイスでアプリを起動
```

## 開発

```bash
mise exec -- flutter test                   # テスト実行
mise exec -- flutter test --coverage        # カバレッジ計測（coverage/lcov.info）
mise exec -- flutter analyze                # 静的解析
mise exec -- dart format .                  # フォーマット（80列）
mise exec -- flutter gen-l10n               # ARB ファイル変更後にローカライズを再生成
```

## プロジェクト構造

```
lib/
├── domain/models/            # ドメインモデル (@immutable)
├── data/repositories/        # データアクセス。外部ストアはコンストラクタ注入
├── routing/app_router.dart   # 単一の GoRouter インスタンス
├── l10n/                     # ARB ファイル + 拡張（生成物は .gitignore 対象）
├── main.dart                 # DI と MaterialApp.router の組み立て
└── ui/
    ├── core/                 # feature 横断の共通ウィジェット
    └── features/<feature>/
        ├── view_models/      # ChangeNotifier ベースの ViewModel
        └── views/            # View（context.watch / context.read で消費）
```

詳細なアーキテクチャ方針は [CLAUDE.md](CLAUDE.md) と各 ADR を参照。

## ドキュメント

- [CLAUDE.md](CLAUDE.md) — Claude Code 等の AI エージェント向けプロジェクトガイド
- [docs/adr/](docs/adr/) — アーキテクチャ決定記録（[MADR v4](https://adr.github.io/madr/) 形式）
- [.claude/rules/git.md](.claude/rules/git.md) — Conventional Commits / GitHub Flow / semantic-release
- [.claude/rules/security.md](.claude/rules/security.md) — OWASP MASVS v2 準拠の遵守事項
- [.claude/rules/coding-style.md](.claude/rules/coding-style.md) — Effective Dart ベースの追加コーディング規約
