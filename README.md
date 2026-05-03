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
- **永続化**: [shared_preferences](https://pub.dev/packages/shared_preferences)（非機密設定）+ [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)（AWS 認証情報、[ADR-0007](docs/adr/0007-aws-auth-with-user-supplied-iam-access-key.md)）
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

## AWS 側のセットアップ

本アプリは「自分の AWS バケットに自分のファイルを同期する」個人用ツールを想定し、ユーザーが発行した IAM Access Key を直接アプリに入力する方式を採る（[ADR-0007](docs/adr/0007-aws-auth-with-user-supplied-iam-access-key.md)）。漏洩時の被害を最小化するため、**専用の IAM ユーザーを 1 つ作り、対象バケットへの最小権限ポリシーだけアタッチする**ことを強く推奨する。

### 最小権限ポリシー雛形

`pocket-sync-data` 部分を実際のバケット名に置き換えて IAM ポリシーとして適用する。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListBucketContents",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::pocket-sync-data"
    },
    {
      "Sid": "ReadWriteObjects",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetObjectAttributes"
      ],
      "Resource": "arn:aws:s3:::pocket-sync-data/*"
    }
  ]
}
```

このポリシーでカバーする範囲:

- バケット内のオブジェクト一覧の取得
- 個別オブジェクトの取得・配置・削除
- メタデータ（サイズ・更新時刻）の確認

含まれていない権限は意図的なもの（バケット作成・削除、ポリシー変更、他のバケットへのアクセスなど）。

### 推奨手順

1. AWS Console → S3 で同期先バケットを作成（**Block Public Access 全 ON**）
2. IAM → Policies で上記 JSON を `pocket-sync-app-access` 等の名前で作成
3. IAM → Users で `pocket-sync-app` ユーザーを作成（コンソールアクセス OFF）し、上記ポリシーをアタッチ
4. 作成したユーザーで Access Key を発行（用途: "Application running outside AWS"）
5. アプリの設定画面 > 「AWS 認証情報」に Access Key ID / Secret Access Key / リージョン / バケット名を入力

万が一 Secret が漏洩したら、IAM Console で該当 Access Key を即座に Deactivate / Delete して再発行する。

## ドキュメント

- [CLAUDE.md](CLAUDE.md) — Claude Code 等の AI エージェント向けプロジェクトガイド
- [docs/adr/](docs/adr/) — アーキテクチャ決定記録（[MADR v4](https://adr.github.io/madr/) 形式）
- [.claude/rules/git.md](.claude/rules/git.md) — Conventional Commits / GitHub Flow / semantic-release
- [.claude/rules/security.md](.claude/rules/security.md) — OWASP MASVS v2 準拠の遵守事項
- [.claude/rules/coding-style.md](.claude/rules/coding-style.md) — Effective Dart ベースの追加コーディング規約
