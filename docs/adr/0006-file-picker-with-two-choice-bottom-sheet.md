---
status: accepted
date: 2026-05-01
decision-makers: [CASL0]
---

# ADR-0006: ファイル/写真の選択 UI に 2 択ボトムシート + プラットフォーム公式ピッカーを採用する

## 背景と課題 (Context and Problem Statement)

`pocket_sync` は端末のローカルファイルを S3 と同期するアプリで、ユーザーが同期対象を選ぶための「ファイル選択」導線が必要になる。対象は通常のドキュメントだけでなく写真・動画も含み、両 OS（Android / iOS）で一貫した UX を提供したい。一方で iOS の OS レベル API は **「Files アプリのドキュメント」と「Photos ライブラリの写真」を 1 つのピッカーに統合する公式手段を提供していない**（プライバシー設計のため `UIDocumentPickerViewController` と `PHPickerViewController` が分離されている）。この制約下で、両 OS で一貫し、かつ実行時パーミッションを最小化した選択導線をどう実装するかを決める必要がある。

## 決定の駆動要因 (Decision Drivers)

* OWASP MASVS-PLATFORM に従い、実行時パーミッションを最小化したい（[security.md](../../.claude/rules/security.md) 参照）
* Android / iOS で UX を可能な限り揃えたい（CLAUDE.md の対象プラットフォーム前提）
* iOS の API 制約：Photos ライブラリと Files の統合ピッカーは公式に存在しない
* 標準的・低リスクな依存パッケージで実装したい（コード生成や独自プラットフォームコードを避ける）
* 将来の拡張（フォルダ単位選択、自動同期）を阻害しない

## 検討した選択肢 (Considered Options)

* **A. プラットフォーム公式ピッカー × 2 を、共通の 2 択ボトムシートで束ねる**（`file_picker` + `image_picker`）
* **B. ファイル選択のみに絞る**（写真は Files アプリ経由で選んでもらう前提、`file_picker` 一本）
* **C. サードパーティの統合ピッカーパッケージを採用する**（例: `wechat_assets_picker` 等で写真とファイルを 1 UI に集約）
* **D. プラットフォーム別 UI**（Android は SAF 1 ピッカーで完結、iOS だけ 2 択 UI を出す）

## 決定 (Decision Outcome)

採用：**「A. プラットフォーム公式ピッカー × 2 を、共通の 2 択ボトムシートで束ねる」**。理由は、(1) iOS の API 制約により公式 1 ピッカー化は不可能、(2) 公式ピッカー（iOS の PHPicker / UIDocumentPicker、Android の Photo Picker / SAF）はいずれも実行時パーミッション不要で MASVS の最小権限原則に整合、(3) 両 OS で同じ 2 択 UI にすれば iOS の制約に引きずられず一貫した UX を提供できる、の 3 点。

### 結果 (Consequences)

* Good: `Photos` 系・`Files` 系どちらの選択導線でも実行時パーミッションが不要になる（PHPicker は iOS 14+、Photo Picker は Android 13+ / Play Services 経由で API 19+）
* Good: iOS の API 制約に UX 全体が引きずられない。Android 側で「無理に 1 ピッカーに見せる」必要もなく、保守性が高い
* Good: メジャーで広く使われている `file_picker` / `image_picker` で済み、独自プラットフォームコード不要
* Bad: ユーザー操作が 1 ステップ増える（FAB タップ → ボトムシート → ピッカー）
* Bad: 「フォルダを選ぶ」「自動同期で常時アクセスする」拡張に進む際は、SAF の永続パーミッション（`takePersistableUriPermission`）や iOS のセキュリティスコープ付きブックマーク保存といった別設計が必要。本 ADR の範囲外
* Neutral: 古い OS（iOS 13 以下、Android 12 以下）をサポートする場合は `NSPhotoLibraryUsageDescription` や `READ_MEDIA_IMAGES` 等の追加対応が必要。最低サポート OS が PHPicker / Photo Picker 利用可能なバージョン以上であることを別途確定する（pubspec.yaml の SDK 制約と Flutter 既定値に依存）

### 確認方法 (Confirmation)

* `lib/ui/features/files/` 配下のファイル選択導線が `showModalBottomSheet` ベースの 2 択 UI を経由していることをコードレビューで確認
* `AndroidManifest.xml` および `Info.plist` に `READ_MEDIA_*` / `NSPhotoLibraryUsageDescription` 等の写真関連パーミッション宣言が**含まれていない**こと（grep で機械チェック可能）
* 実機テストで、いずれの導線でも OS のパーミッションダイアログが出ないことを確認

## 各選択肢の利点・欠点 (Pros and Cons of the Options)

### A. 公式ピッカー × 2 + 2 択ボトムシート
* Good: 両 OS でパーミッション不要
* Good: iOS の API 制約に正面から従うため、将来の OS 更新でも壊れにくい
* Good: 多くのチャット・SNS アプリで採用され、ユーザーに馴染みのある UX
* Neutral: タップが 1 ステップ増える
* Bad: 「すべてが 1 つのピッカーに見える」UX にはならない

### B. ファイル選択のみに絞る
* Good: 実装が最も単純（パッケージ 1 つ）
* Bad: iOS で Photos ライブラリの写真を選ぶには、ユーザーが先に Files へ書き出す必要がある。ユースケース（写真同期）にとって致命的に不便
* Bad: Android 側でも Photo Picker の利点を捨てることになる

### C. サードパーティ統合ピッカー
* Good: 1 UI で写真とファイルを混在表示できる可能性がある
* Bad: 多くのパッケージは Photos ライブラリ全体への読取権限を要求する（MASVS-PLATFORM の最小権限に反する）
* Bad: メンテナンス・セキュリティ監査の負荷が増える。OS 更新追随が遅れるリスク
* Bad: iOS の OS 制約を「ライブラリ全体権限を取る」ことで回避しているケースがあり、プライバシー的に望ましくない

### D. プラットフォーム別 UI
* Good: Android 単独で見れば SAF だけで写真もファイルも選べるので最短実装
* Bad: 両 OS で UI が異なり、ドキュメント・サポート・テスト負荷が増える
* Bad: A と比べて Android 側のコード量・デザイン工数の節約幅は小さく、トレードオフが見合わない

## 補足情報 (More Information)

* PHPicker (iOS 14+): <https://developer.apple.com/documentation/photokit/phpickerviewcontroller>
* Android Photo Picker: <https://developer.android.com/training/data-storage/shared/photopicker>
* Storage Access Framework: <https://developer.android.com/guide/topics/providers/document-provider>
* 関連 ADR: 本 ADR は同期対象ファイルの「入力」側を扱う。表示側は [ADR-0001](0001-unified-file-view-with-sync-status.md) / [ADR-0002](0002-sync-status-as-sealed-class.md) を参照
* 再考のトリガー条件:
  - 「フォルダ単位で同期したい」「アプリを開いていない時に自動同期したい」要件が来た時 → 永続パーミッション設計を伴う別 ADR を起票
  - Apple / Google が公式に統合ピッカー API を出した時
