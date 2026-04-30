---
status: accepted
date: 2026-04-30
decision-makers: [CASL0]
consulted: []
informed: []
---

# ADR-0004: ルーティングに go_router を採用する

## 背景と課題 (Context and Problem Statement)

本プロジェクトは BottomNav 2タブ（Files / Activity）構成で、各タブから FileDetail / ConflictResolver へ push、Settings は AppBar action から push という画面遷移を想定する（個別画面の詳細は後続 ADR で扱う）。実装にはルーティング基盤が必要だが、現状は `MaterialApp` の単一 `home` のスキャフォールドのみ。対象プラットフォームは Android / iOS のみ（Web / デスクトップは対象外）。将来認証を導入する際の redirect ガードや、Deep Linking（Universal Links / App Links）対応も視野に入れた選定が要る。

## 決定の駆動要因 (Decision Drivers)

* 宣言的なルート定義（命令的 push/pop に閉じない）
* BottomNav の各タブで独立したナビゲーションスタックの状態保持
* 認証導入時の route guard / redirect 機能
* Deep Linking（Universal Links / App Links）対応の容易さ
* Flutter チームによる長期メンテナンスの担保
* 学習資料・コミュニティ規模
* MVVM / Provider 採用（ADR-0003）との親和性 — ルーティング層が状態管理に干渉しないこと
* 採用パッケージのスコープが狭く、後から差し替え可能であること

## 検討した選択肢 (Considered Options)

* **Option 1: go_router**（Flutter チーム + Material チームが共同メンテ）
* **Option 2: auto_route**（コード生成ベースの型安全ルーティング）
* **Option 3: beamer**（URL Location ベース、Web に強い）
* **Option 4: Navigator 2.0 (raw Router/RouterDelegate)**（外部依存なしの素の宣言的 API）
* **Option 5: Navigator 1.0 (push/pop)**（最小限、命令的）

## 決定 (Decision Outcome)

採用：「Option 1: go_router」。

理由：Flutter チームと Material チームが共同でメンテしており長期サポートが期待できる。`StatefulShellRoute.indexedStack` により BottomNav 各タブのナビゲーションスタックを宣言的に保持できる（Files / Activity のタブ切替で各履歴が維持される）。`redirect` callback で認証導入時のガードを宣言的に書ける。Deep Linking が標準サポート。文字列パスのコンパイル時検証が無いという欠点はあるものの、本プロジェクト規模では実用的な障壁にならず、auto_route のコード生成運用コストを払う動機が現時点では弱い。

### 結果 (Consequences)

* Good: ルーティングが単一の `GoRouter` 定義に集約され、ルート構造が一目で把握できる
* Good: BottomNav タブ切替時の状態保持が標準機能で実現できる
* Good: 認証導入時の redirect ガードが宣言的に追加できる
* Good: Deep Linking 対応が標準で、ネイティブ側設定（Manifest / Plist / AASA）に集中できる
* Good: ルーティングと状態管理（Provider）が独立しており、互いに引きずられない
* Bad: 文字列パスがコンパイル時に検証されない（`/files/123` のタイポは実行時エラー）
* Bad: 非常に細かい遷移挙動（独自トランジション・ネスト深層の制御）を求める場合、go_router の API 抽象を学ぶ必要がある

### 確認方法 (Confirmation)

* `pubspec.yaml` に `go_router` 依存があること
* `lib/main.dart` が `MaterialApp.router(routerConfig: ...)` を使っていること
* ルート定義が単一の `GoRouter` インスタンスに集約されていること（feature ディレクトリに散在しないこと）
* BottomNav が `StatefulShellRoute.indexedStack` で実装され、`StatefulNavigationShell` を消費していること

## 各選択肢の利点・欠点 (Pros and Cons of the Options)

### Option 1: go_router

* Good: Flutter チーム + Material チームが共同メンテ。長期サポート見込み
* Good: `StatefulShellRoute.indexedStack` で BottomNav 状態保持を標準サポート
* Good: `redirect` callback で auth ガードを宣言的に記述
* Good: Deep Linking が標準サポート
* Good: Material / Cupertino のページトランジションを自動で適用
* Good: 学習資料・StackOverflow 例・Cookbook が豊富
* Good: パッケージのスコープがルーティングに限定されており、後で差し替えしやすい
* Neutral: 文字列パスはコンパイル時検証されない（`auto_route` との対比で唯一の弱み）
* Bad: 非常に細かい遷移制御を求める場合、Navigator 2.0 を直接書く方が自由度は高い

### Option 2: auto_route

* Good: コード生成（`build_runner`）で型安全なルート定義 — タイポがコンパイル時に検出される
* Good: 引数を型付きで渡せる（文字列パラメータの手動パースが不要）
* Good: ネスト・タブ・ガード機能が強力で表現力が高い
* Bad: コード生成のセットアップと運用コスト（`build_runner watch` の常駐、生成物の管理）
* Bad: コミュニティ規模・StackOverflow 例が go_router より小さい
* Bad: 独自アノテーションと Builder 概念の学習コストが高い
* Bad: 個人プロジェクト規模では「ルートの型安全性」のメリットが、ビルド時間と運用負荷を上回りにくい

### Option 3: beamer

* Good: URL-driven な location-based routing で、Web SPA との相性が特に良い（本プロジェクトはモバイルのみのため恩恵は限定的）
* Good: ネストルーティングが `BeamLocation` 単位で宣言的
* Good: 戻る挙動を URL 履歴ベースで設計しやすい
* Bad: コミュニティ規模・採用例が go_router より大幅に小さい
* Bad: 主要メンテナがコミュニティドリブンで、Flutter チーム maintain の go_router と比べると長期サポートに不確実性
* Neutral: `BeamLocation` 概念の学習が必要 — go_router の `GoRoute` より抽象が一段深い

### Option 4: Navigator 2.0 (raw Router/RouterDelegate)

* Good: 外部依存ゼロで、完全な制御が得られる
* Good: 仕様が Flutter SDK 同梱で長期的に消えない
* Bad: `Router` / `RouterDelegate` / `RouteInformationParser` / `BackButtonDispatcher` のボイラープレートが膨大
* Bad: BottomNav + 各タブ状態保持を自前で IndexedStack ベースで実装するのは大変
* Bad: Deep Linking 対応も自前 — go_router が標準で持つ機能を全部書くことになる
* Bad: Flutter 公式ドキュメントですら「complex」と認めており、個人プロジェクトには重すぎる

### Option 5: Navigator 1.0 (push/pop)

* Good: 何も学ばずに使える、最もシンプル
* Good: Flutter SDK 同梱で外部依存ゼロ
* Bad: 宣言的でない（命令的 `Navigator.push` / `pop`）。ルート構造がコード全体に散在する
* Bad: Deep Linking は手動実装が必要
* Bad: Auth redirect ガードを宣言的に書けない（各画面で個別チェック）
* Bad: BottomNav の各タブ状態保持を自前で `IndexedStack` 管理する必要
* Bad: 認証導入時の改修負荷が大きい

## 補足情報 (More Information)

* 対象プラットフォーム: Android / iOS のみ（Web / デスクトップは対象外。Web 対応が必要になった場合は別途 ADR で再検討する）
* 実装方針:
  - `StatefulShellRoute.indexedStack` で BottomNav 2タブ（Files / Activity）の状態保持
  - 各タブから `FileDetail` / `ConflictResolver` を push、`Settings` は AppBar action から push
* 認証導入時の方針:
  - `GoRouter` の `redirect` callback で signed-in / signed-out を判定し、未認証時は `/sign-in` にリダイレクト
* 参考: Flutter 公式 Navigation and routing → <https://docs.flutter.dev/ui/navigation>
* 参考: go_router README → <https://pub.dev/packages/go_router>
* 再考トリガー: ルート数が30を超えたタイミング、または「文字列パスのタイポによる実行時エラー」が複数回発生した場合に auto_route 移行を再評価する
