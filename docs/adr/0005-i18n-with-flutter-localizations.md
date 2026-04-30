---
status: accepted
date: 2026-05-01
decision-makers: [CASL0]
consulted: []
informed: []
---

# ADR-0005: 国際化 (i18n) に flutter_localizations + ARB を採用する

## 背景と課題 (Context and Problem Statement)

現状アプリ内の UI 文字列はすべて Dart コードにハードコードされている（`Text('設定')` 等）。本プロジェクトは日本語が一次言語だが、将来の英語化やストア提出時のローカライズ要件、テスト時の文字列重複検証などを見据えると、UI 文字列を外部リソースとして管理する仕組みを早期に導入したい。Flutter には公式の `flutter_localizations` + ARB ベースのソリューションがあるが、3rd party の代替案も存在するため、どれを採用するかを決める必要がある。

## 決定の駆動要因 (Decision Drivers)

* Flutter 公式・SDK 同梱で長期サポートが期待できること
* Material / Cupertino 標準ウィジェットのローカライズ（"Cancel" → "キャンセル" 等）と統合されること
* コンパイル時にキー名のタイポを検出できる型安全性
* ICU MessageFormat（placeholder / plural / select）対応
* 生成物がプロジェクト内に可視化され、IDE ナビゲートやコードレビューしやすいこと
* `very_good_analysis` lint と整合すること
* 既存テストへの影響を最小化できること

## 検討した選択肢 (Considered Options)

* **Option 1: flutter_localizations + ARB**（Flutter 公式、SDK同梱）
* **Option 2: easy_localization**（3rd party、JSONベース、ホットリロード対応）
* **Option 3: slang**（3rd party、コード生成、型安全ネスト構造）
* **Option 4: 何もしない**（ハードコード継続）

## 決定 (Decision Outcome)

採用：「Option 1: flutter_localizations + ARB」。

サブ決定として：
- **テンプレート言語: 日本語**（`lib/l10n/app_ja.arb`）— 本プロジェクトは日本語が一次言語であり、ARB の説明文・キー名も日本語起点で書く方が整合する
- **サポート言語: `ja`（必須）+ `en`（将来用）** — 英語化を前提に始めはしないが、キーが定義されると同時に空の `app_en.arb` を作成しておくことで、将来の英語化が翻訳作業のみで済む
- **`synthetic-package: false`** — 生成物を `lib/l10n/app_localizations.dart` に出して可視化。近年の Flutter 推奨方針で、ビルドツール連携と IDE ナビゲートが安定

理由：Flutter チームと Material チームが共同でメンテしており SDK 同梱なので長期サポートが確実。Material/Cupertino 標準ウィジェットの "OK" / "Cancel" 等が言語に応じて自動翻訳される。コード生成型なので `AppLocalizations.of(context)!.fooKey` のキー誤りがコンパイル時に検出される。3rd party の easy_localization は文字列キーで参照するため型安全性が無く、slang はネスト構造で見やすいが Material 統合が別途必要。本プロジェクト規模では公式ツールのシンプルさが勝る。

### 結果 (Consequences)

* Good: ハードコード文字列が UI コードから消え、検索・置換・翻訳作業が `lib/l10n/*.arb` に集中する
* Good: Material 標準ウィジェット（DatePicker、SnackBar の閉じるボタン等）が自動的に日本語化される
* Good: コード生成型でキー誤りがコンパイル時に検出される
* Good: `synthetic-package: false` で生成物が見えるため、PR レビューで翻訳の差分確認しやすい
* Good: 将来英語化する際は `app_en.arb` のキーを翻訳するだけで済む
* Bad: ARB ファイルは JSON ライクで、メタ記述（`@key` の `description` / `placeholders` 等）が冗長
* Bad: 言語切替時にホットリロードでは反映されないことがある（再起動が必要）
* Bad: 大量キーになると ARB のフラット構造が煩雑（ネスト構造を持つ slang ほど整理しやすくない）

### 確認方法 (Confirmation)

* `pubspec.yaml` に `flutter_localizations` (sdk) と `intl` 依存があること
* `pubspec.yaml` の `flutter:` セクションに `generate: true` があること
* プロジェクトルートに `l10n.yaml` が存在し、`template-arb-file: app_ja.arb`、`synthetic-package: false` が指定されていること
* `lib/l10n/app_ja.arb` と `lib/l10n/app_en.arb` が存在すること
* `lib/main.dart` の `MaterialApp.router` に `AppLocalizations.delegate` と `GlobalMaterialLocalizations.delegate` 系が登録されていること
* `supportedLocales` に `Locale('ja')` と `Locale('en')` が含まれること
* UI コード（`lib/ui/` 配下）にハードコードされた日本語文字列が無いこと（コードレビューで確認）

## 各選択肢の利点・欠点 (Pros and Cons of the Options)

### Option 1: flutter_localizations + ARB

* Good: Flutter SDK 同梱で長期保証
* Good: Material / Cupertino 標準ウィジェットのローカライズが自動
* Good: コード生成でキー誤りをコンパイル時に検出
* Good: ICU MessageFormat（placeholder / plural / select）標準対応
* Good: IDE プラグインや i18n エディタの選択肢が豊富
* Neutral: ARB ファイルは JSON 系なのでメタ記述が冗長
* Bad: ホットリロード時に言語切替の挙動が直感的でない場合がある
* Bad: 大量キーになると ARB のフラット構造で管理が煩雑

### Option 2: easy_localization

* Good: JSON 構造でネスト可能、整理しやすい
* Good: ホットリロード対応で開発体験が良い
* Good: ランタイムでの言語切替が容易
* Bad: 3rd party、メンテナンスがコミュニティ依存
* Bad: コンパイル時の型安全性が無い（キーは文字列リテラル参照）
* Bad: Material 標準の自動ローカライズと別の仕組みなので連携設定が必要

### Option 3: slang

* Good: コード生成で完全に型安全（ネスト構造も型に反映）
* Good: 高度な機能（plural / gender / fallback）が充実
* Good: ランタイムコストが小さい
* Bad: 3rd party
* Bad: 学習コストは中程度（独自概念）
* Bad: Material 統合が別途必要で、Flutter 公式ツールチェインから外れる

### Option 4: 何もしない（ハードコード継続）

* Good: 何も追加しない、即時の作業量ゼロ
* Bad: 文字列がコードに散在し、検索・修正・翻訳が困難
* Bad: 将来の英語化が大規模リファクタになる
* Bad: Material 標準ウィジェットの言語が固定（"Cancel" 等が英語のまま）
* Bad: テストで日本語リテラルが大量に登場し、表記ゆれの温床になる

## 補足情報 (More Information)

* **生成方針**: `synthetic-package: false` により `lib/l10n/app_localizations.dart` および各言語の `app_localizations_<locale>.dart` が生成される。これらは git でコミットしない（`.gitignore` 推奨、生成物のため）
* **テスト方針**: widget テスト時は `MaterialApp` に `localizationsDelegates` と `supportedLocales` を渡し、`pumpAndSettle` で localization のロードを待つ。テスト内のリテラル日本語は ARB の値と一致させる（または `AppLocalizations` インスタンスから取得する）
* **キー命名規約**: ARB ファイル内のキーは lowerCamelCase（例: `settingsTitle`, `fileListTitle`）。`@<key>` ブロックに `description` を必須記述。
* **再考トリガー**: キー数が 500 を超え ARB のフラット構造が辛くなった時、または ICU MessageFormat の表現力では足りない（複雑なネスト・条件分岐）と判明した時に slang への移行を再評価する
* **参考**: Flutter 公式 Internationalization → <https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization>
