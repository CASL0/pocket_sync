---
status: accepted
date: 2026-04-30
decision-makers: [CASL0]
consulted: []
informed: []
---

# ADR-0003: 状態管理に Provider + ChangeNotifier を採用する

## 背景と課題 (Context and Problem Statement)

本プロジェクトは MVVM アーキテクチャを採用しており（[main.dart](../../lib/main.dart) と [counter_view_model.dart](../../lib/ui/features/counter/view_models/counter_view_model.dart) で既に稼働中）、ViewModel が UI に状態変化を通知する仕組みが必要。Flutter の状態管理は選択肢が多く、どれを正式採用するかを明文化していなかった。既に Provider + ChangeNotifier で実装が動いているため、これを正式採用とするか、別のソリューションに乗り換えるかを判断する必要がある。

## 決定の駆動要因 (Decision Drivers)

* MVVM パターン（View ← ViewModel ← Repository ← Model）との親和性
* 個人プロジェクト規模に対する複雑度のバランス
* Flutter 公式の推奨度合いと長期サポート、慣習との整合性
* 既存実装からの移行コスト
* テスト容易性（DI で差し替えやすいか、Service Locator 依存ではないか）
* very_good_analysis（プロジェクトのlint設定）との整合性
* パッケージのスコープ（状態管理だけか、ルーティング・DIまで巻き込むか）

## 検討した選択肢 (Considered Options)

* **Option 1: Provider + ChangeNotifier**（現在の実装）
* **Option 2: Riverpod**（Provider の進化形、コンパイル時安全性とコード生成）
* **Option 3: flutter_bloc**（Stream/Cubitベース、Very Good Ventures の標準）
* **Option 4: signals.dart**（リアクティブ・シグナルベース）
* **Option 5: GetX**（状態管理 + DI + ルーティング + ユーティリティの all-in-one）

## 決定 (Decision Outcome)

採用：「Option 1: Provider + ChangeNotifier」。

理由：既に MVVM ベースで実装・稼働しており、ChangeNotifier は ViewModel の責務（状態保持と変更通知）と素直に対応する。プロジェクト規模はまだ小さく、Riverpod や Bloc が解決する課題（コンパイル時依存解析・複雑な非同期フロー管理）は現時点で顕在化していない。GetX は all-in-one で生産性は高いが、Flutter 慣習との乖離（context を介さないナビゲーション・Service Locator パターン）と、状態管理だけ後で差し替えにくいロックインが MVVM 採用の方針と合わない。Provider は Flutter 公式が長く推奨してきた選択肢で、学習資料が豊富。

### 結果 (Consequences)

* Good: 既存コードを変更せずに済む（移行コストゼロ）
* Good: ChangeNotifier は Flutter 標準クラスで、外部依存が増えない感覚で扱える
* Good: MVVM の ViewModel 層と概念が一致しており、設計の見通しが良い
* Good: 状態管理・DI・ルーティングを独立して選べる柔軟性がある
* Bad: 大規模化したとき、Provider の `context.read` / `context.watch` の呼び分けが手動になる
* Bad: Riverpod のような型安全な依存グラフは持てない
* Bad: 非同期状態（loading / error / data）の表現は ChangeNotifier 内で手書きになる

### 確認方法 (Confirmation)

* `pubspec.yaml` の状態管理依存が `provider` のみであること
* ViewModel が `ChangeNotifier` を継承していること（コードレビューで確認）
* `lib/ui/features/<feature>/view_models/` 配下に ViewModel が配置されていること（プロジェクト構造の慣習）

## 各選択肢の利点・欠点 (Pros and Cons of the Options)

### Option 1: Provider + ChangeNotifier

* Good: Flutter 公式推奨。学習資料が豊富
* Good: ChangeNotifier は Flutter SDK 同梱でフレームワークと統合的
* Good: MVVM の ViewModel と素直に対応する
* Good: 既に実装済みで移行コストゼロ
* Good: 状態管理だけのパッケージで、ルーティング等は別途自由に選べる
* Neutral: 大規模化した場合の設計指針は自分で決める必要がある
* Bad: コンパイル時の依存解析が無い（実行時エラーになりうる）

### Option 2: Riverpod

* Good: コンパイル時に依存グラフが検証される
* Good: コード生成（riverpod_generator）で型安全な Provider が書ける
* Good: 非同期状態 (`AsyncValue`) が標準で表現できる
* Bad: 既存の Provider 実装をすべて書き換える必要がある
* Bad: 学習コストが高い（特にコード生成を使う場合）
* Bad: 概念（Provider, ConsumerWidget, ref）が増えて MVVM の見通しが多少ぼやける

### Option 3: flutter_bloc

* Good: テスト容易性が極めて高い（Bloc/Cubit 単独でテスト可能）
* Good: very_good_analysis を提供する Very Good Ventures の標準スタック
* Good: イベント駆動で複雑な状態遷移を整理しやすい
* Bad: MVVM より MVI / Cubit パターン寄りで、設計の方向転換が必要
* Bad: ボイラープレートが多い（State, Event, Bloc の3クラス）
* Bad: 既存実装を全面書き換え

### Option 4: signals.dart

* Good: リアクティブで宣言的な API
* Good: 細粒度のリビルド制御ができ、パフォーマンスが良い
* Bad: コミュニティ規模が他3つより小さく、長期サポートが不透明
* Bad: 既存実装を書き換えが必要
* Bad: MVVM の ViewModel 概念との対応が他より弱い

### Option 5: GetX

* Good: 状態管理・DI・ルーティング・スナックバー・ダイアログ・i18n が1パッケージで揃い、立ち上げが速い
* Good: `.obs` と `Obx` による細粒度リアクティブで、ボイラープレートが極めて少ない
* Good: 学習・実装の即効性が高く、プロトタイピング向き
* Bad: Flutter 公式の慣習から外れる設計（`BuildContext` を介さないナビゲーション・スナックバー）。フレームワーク標準と GetX の世界の使い分けが認知負荷になる
* Bad: Service Locator パターン（`Get.put` / `Get.find`）依存で、コンストラクタ注入と比べてテスト時の差し替え可視性が低い
* Bad: all-in-one 設計のため、状態管理だけ別の選択肢に差し替えるのが難しく、ロックインが強い
* Bad: GetxController を中心とする独自パターンで、本プロジェクトが採用している MVVM の ViewModel 概念とは設計思想がずれる
* Neutral: パッケージの設計思想・メンテナンス姿勢について Flutter コミュニティ内で議論が分かれている経緯がある（採用判断時に各自の評価が必要）

## 補足情報 (More Information)

* 規模拡大時の再考トリガー: ViewModel が10個を超えた頃、または非同期状態管理が複雑化したタイミングで Riverpod 移行を再検討する
* 本決定は ADR-0001（統一ビュー + 同期ステータス）と ADR-0002（sealed class）と独立しており、状態管理を切り替えてもこれらの決定は引き継げる
