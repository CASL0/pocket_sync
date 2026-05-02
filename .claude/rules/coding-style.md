---
description: Effective Dart に基づく Dart / Flutter のコーディング規約
paths:
  - "lib/**/*.dart"
  - "test/**/*.dart"
---

# Coding Style Rules（Effective Dart 準拠）

[Effective Dart](https://dart.dev/effective-dart) の Style / Documentation / Usage / Design に基づく規約。`analysis_options.yaml` で適用している `very_good_analysis` が機械的に検出できない領域を中心にまとめる。

---

## Style — 命名と整形

### 識別子

| 種別 | 命名規則 | 例 |
|------|----------|-----|
| クラス・enum・typedef・extension・mixin | `UpperCamelCase` | `SyncStatus`, `FileListView` |
| ライブラリ・パッケージ・ディレクトリ・ファイル | `lowercase_with_underscores` | `sync_status.dart`, `file_detail/` |
| import の prefix | `lowercase_with_underscores` | `as path_helper` |
| 変数・関数・パラメータ・名前付き引数 | `lowerCamelCase` | `currentSyncStatus`, `uploadFile()` |
| 定数（`const` / `static const` / enum 値） | `lowerCamelCase` | `defaultBucketName`（`kDefault` や `SCREAMING_CAPS` は使わない） |

### 頭字語の扱い

- 2 文字の頭字語は大文字: `IOSink`, `S3Client` の `IO` / `S3`
- 3 文字以上の頭字語は通常の単語として扱う: `HttpClient`, `JsonDecoder`, `AwsS3Client`（`HTTPClient` ではなく `HttpClient`）

### プライベート

- ライブラリ外に出さない宣言は先頭に `_` を付ける（`_buildHeader()`）。`@protected` や `@visibleForTesting` で代用しない。

### 整形

- 1 行 80 列。`mise exec -- dart format .` に従い手動で整えない。
- カスケード `..` は意味のある連鎖がある場合に使う。1 個しかないなら通常のメソッド呼び出しで書く。
- 末尾カンマは付ける。`dart format` がツリー状にインデントしてくれて diff が読みやすくなる。

---

## Documentation — コメントとドキュメントコメント

- ドキュメントコメントは `///` で書く。`/** */` は使わない。
- 1 行目はピリオドで終わる **要約文**。詳細は段落を空けて続ける。

  ```dart
  /// 指定したファイルを S3 にアップロードする。
  ///
  /// 進捗は [onProgress] で 0.0 〜 1.0 の範囲で通知される。
  /// 通信失敗時は [SyncException] を投げる。
  Future<void> uploadFile(File file, {void Function(double)? onProgress});
  ```

- パラメータ・戻り値・例外は別セクションを立てず、文章中に `[paramName]` で参照する形で織り込む。
- 三人称現在形で書く（"Uploads ..." / 日本語なら「アップロードする」）。"will upload" や "I'll upload" のような書き方をしない。
- TODO は `// TODO(handle): 説明` の形式で書き、Issue 番号や担当を明記する。

- 通常のコメントは「**なぜ**そう書いたか」を残すために使う。**何を**しているかはコードと識別子で語らせる。自明な処理にコメントを付けない。

---

## Usage — 言語機能の使い方

### import

- 自プロジェクトのファイルを参照するときは常に **package import** を使う（`import 'package:pocket_sync/...';`）。`very_good_analysis` の `always_use_package_imports` で機械的に強制される。
- `test/` から `lib/` を参照するときも同じく package import。
- 同じファイルに対する相対 import と package import の混在は禁止（型の同一性が壊れる）。
- 自動生成された ARB 由来のロケールファイル（`app_localizations_*.dart`）は flutter gen-l10n が相対 import で生成する。これは生成物なので手で触らない。

### 文字列

- 文字列の連結は `+` ではなく **補間** を使う。`'こんにちは ${user.name} さん'`。
- 単純な変数なら波括弧を省略可（`'$name'`）。プロパティアクセスやメソッド呼び出しがあるときは `${user.name}` のように書く。
- 隣接する文字列リテラル（adjacent string literals）で長文を改行して書く:

  ```dart
  throw SyncException(
    'アップロードに失敗しました。'
    'ネットワーク接続を確認してください。',
  );
  ```

### コレクション

- 空のコレクションは `List()` ではなく `[]` / `{}` リテラルで作る。
- リスト・マップの構築は spread (`...`) と collection-if / collection-for を使う:

  ```dart
  final actions = [
    const _RefreshAction(),
    if (canUpload) const _UploadAction(),
    ...extraActions,
  ];
  ```

### null と条件

- `??` / `??=` / `?.` を使う。`x == null ? y : x` のような書き方はしない。
- `bool? flag` を `if (flag == true)` で扱うのは可だが、ドメイン上 `null` がありえないなら型を `bool` にする。
- `late` は遅延初期化が本当に必要なときだけ使う。コンストラクタで初期化できるなら `final` を優先する。

### 型

- パブリック API（`lib/` 内で他ファイルから見える宣言）には **必ず型注釈を書く**。`var` で済まさない。
- ローカル変数は推論に任せて `var` / `final` を使ってよい。原則 `final` を優先し、再代入する変数だけ `var`。
- `dynamic` は外部由来の JSON など型が決まらないときだけ。意味は `Object?` で済むことが多いので、まず `Object?` を検討する。
- 関数型は typedef で名前を付ける。コールバックを取る引数の型は `void Function(double progress)` のように **パラメータ名を含める**（IDE のヒントが読みやすくなる）。

### 非同期

- 非同期関数の戻り値は明示する。値を返さない非同期関数は `Future<void>`。
- `async` は `await` を実際に使う関数にだけ付ける。単に `Future` を返すだけなら `async` を付けず素通しする方が軽い。
- `await` の付け忘れに注意。`Future` を返す関数を呼んでいるのに `await` していないと、エラーが握りつぶされる。意図的に fire-and-forget するときは `unawaited(...)`（`package:meta` ではなく `dart:async` 由来）でその意図を明示する。
- 並列に走らせたいときは `Future.wait([...])` を使う。直列の `await` を並べると不要な待ち時間が発生する。

---

## Design — API 設計

### コンストラクタ

- 新しいインスタンスを生成しないコンストラクタ（キャッシュを返す等）は `factory` にする。生成のみなら通常の生成コンストラクタで足りる。
- 名前付きコンストラクタは `ClassName.fromJson(...)` のように **目的が分かる名前** を付ける。

### 真偽値パラメータ

- bool は `{required bool value}` のように **名前付き引数** で受ける（`very_good_analysis` の `avoid_positional_boolean_parameters` で強制）。呼び出し側で `enabled: true` のように意味が読めるようにする。

### コレクションを返す関数

- 「ない」を表現するために `null` を返さない。**空のコレクション** を返す。
- 公開 API がリストを返すときは `List<Foo>` のような可変型を露出するか `Iterable<Foo>` で抽象化するかを意識する。呼び出し側に変更されたくない場合は `List.unmodifiable(...)` を返す。

### getter / setter

- getter には副作用を持たせない。重い計算（O(n) を超える、I/O を伴う、例外を投げうる）が必要なら getter ではなくメソッドにする。
- 対称な操作は `setFoo()` ではなく setter で書く（getter があるなら setter で書く）。

### 例外

- 例外は失敗を表す。制御フローの分岐に例外を使わない。
- アサート目的（不変条件違反）には `ArgumentError` / `StateError` / `assert(...)` を使う。
- 自前の例外型は `Exception` を実装する。`Error` は **回復不能なバグ** を表すサブクラスなので、利用者に catch を期待する場合は使わない。

### イミュータビリティ

- ドメインモデルは `@immutable` を付け、`final` フィールドだけで構成する。`==` / `hashCode` / `copyWith` を手書きする（ADR-0003 によりコード生成未導入）。
- `const` コンストラクタを定義できるなら定義する。呼び出し側も可能なら `const` 付きで生成する。
