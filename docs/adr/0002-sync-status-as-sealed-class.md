---
status: accepted
date: 2026-04-30
decision-makers: [CASL0]
consulted: []
informed: []
---

# ADR-0002: 同期ステータスを sealed class で表現する

## 背景と課題 (Context and Problem Statement)

ADR-0001 で「ファイル一覧は統一ビュー + 同期ステータスで表現する」と決めた。これに伴い、各ファイルの同期状態を型として定義する必要がある。状態は単純な「同期済み/未同期」の2値ではなく、「アップロード中（進捗あり）」「競合（両方の更新時刻あり）」「エラー（理由あり）」など、状態ごとに付随情報の種類が異なる。型でこれをどう表現するかを決める。

## 決定の駆動要因 (Decision Drivers)

* 状態ごとに異なる付随情報（進捗率、競合の詳細、エラー理由）を型安全に持てること
* UI 側で switch 文の網羅性チェックが効くこと（全状態への対応漏れを防ぐ）
* シリアライズ・デシリアライズが容易であること（ローカルメタデータDB保存のため）
* 状態が増えたときの拡張コストが低いこと
* Dart 3 のパターンマッチングと相性が良いこと

## 検討した選択肢 (Considered Options)

* **Option 1: フラットな enum**（`synced`, `localOnly`, `uploading`, `conflict`, `error` などを単一の enum で列挙）
* **Option 2: enum + 別フィールド**（`SyncStatus` enum と、進捗・エラー情報を別の nullable フィールドで持つ）
* **Option 3: sealed class + サブクラス**（各状態を sealed class のサブクラスとして定義し、必要な情報を各サブクラスが保持）

## 決定 (Decision Outcome)

採用：「Option 3: sealed class + サブクラス」。

理由：状態によって必要な付随情報が大きく異なる（進捗率は転送中のみ、エラー理由はエラー時のみ、競合タイムスタンプは競合時のみ）。enum + nullable では「アップロード中なのに progress が null」のような不正な組み合わせが型で防げないが、sealed class なら状態ごとに必要なデータを必須として定義でき、Dart 3 の `switch` 式で網羅性チェックも効く。

### 結果 (Consequences)

* Good: 不正な状態組み合わせがコンパイル時に防がれる
* Good: UI 側で `switch` 式の網羅性が保証され、新しい状態を追加すると未対応箇所がコンパイルエラーとして可視化される
* Good: 各状態に必要なデータだけを持てるためメモリ効率が良い
* Bad: シリアライズに `freezed` などのコード生成が必要（手書きは煩雑）
* Bad: enum と比べてボイラープレートが増える（クラス定義 + パターンマッチ）

### 確認方法 (Confirmation)

* `lib/domain/models/sync_status.dart` に `sealed class SyncStatus` が定義され、すべての状態がサブクラスとして表現されていること
* UI 層で `SyncStatus` を扱う箇所が `switch` 式（exhaustive）を使っており、`default:` を含まないこと
* ユニットテストで全状態のシリアライズ・デシリアライズが検証されていること

## 各選択肢の利点・欠点 (Pros and Cons of the Options)

### Option 1: フラットな enum

* Good: 最も簡潔。シリアライズも文字列1つで済む
* Good: 学習コストがほぼ無い
* Bad: 進捗・エラー理由などの付随情報を持てない
* Bad: 状態と付随情報を別管理にすると、整合性をコードで保証できない

### Option 2: enum + 別フィールド

* Good: enum のシンプルさを残しつつ、付随情報も持てる
* Bad: 「アップロード中なのに progress が null」のような不正状態を型で防げない
* Bad: ファイルクラスのフィールドが増えて見通しが悪くなる
* Bad: 状態が増えるたびにファイルクラス側にもフィールド追加が必要

### Option 3: sealed class + サブクラス

* Good: 状態と付随情報が型で結びつく
* Good: Dart 3 パターンマッチで網羅性が保証される
* Good: 状態追加時の影響範囲がコンパイラで明示される
* Neutral: シリアライズに freezed 等のコード生成を入れるのが現実的
* Bad: ボイラープレートが多い（特に手書きの場合）

## 補足情報 (More Information)

想定する状態の初期セット：

```dart
sealed class SyncStatus {
  const SyncStatus();
}

class Synced extends SyncStatus {
  final DateTime lastSyncedAt;
  const Synced(this.lastSyncedAt);
}

class LocalOnly extends SyncStatus {
  const LocalOnly();
}

class RemoteOnly extends SyncStatus {
  const RemoteOnly();
}

class Uploading extends SyncStatus {
  final double progress; // 0.0 .. 1.0
  const Uploading(this.progress);
}

class Downloading extends SyncStatus {
  final double progress;
  const Downloading(this.progress);
}

class Conflict extends SyncStatus {
  final DateTime localModifiedAt;
  final DateTime remoteModifiedAt;
  const Conflict({required this.localModifiedAt, required this.remoteModifiedAt});
}

class SyncError extends SyncStatus {
  final String reason;
  final bool retryable;
  const SyncError({required this.reason, required this.retryable});
}
```

* シリアライズ方式（freezed / 手書き）の決定は別 ADR で扱う
* 競合解決ポリシー（last-write-wins / ユーザー選択 / 自動マージ）も別 ADR で扱う
