---
status: accepted
date: 2026-05-03
decision-makers: [CASL0]
---

# ADR-0007: AWS 認証情報をユーザー入力の IAM Access Key で扱う

## 背景と課題 (Context and Problem Statement)

`pocket_sync` はローカルファイルを S3 と同期するアプリで、S3 を呼ぶには AWS 認証情報が必要になる。本アプリは「自分の AWS バケットに自分のファイルを同期する」個人用ツールとして使う想定で、想定ユーザーは AWS アカウントを既に保有している（自分自身がメイン）。マルチユーザー配布や App Store 配布は当面の予定にない。

このユースケース下で、(1) どの AWS 認証モデルを採るか、(2) 認証情報を端末上にどう保管するか、(3) 将来モデルを切り替える余地をどう残すか を決める必要がある。

## 決定の駆動要因 (Decision Drivers)

* 自分自身（と少数の知人）が使う個人用ツール。一般配布は当面しない
* バックエンドサーバを持たない（持つ予定もない）
* OWASP MASVS-STORAGE / MASVS-AUTH に最低限沿う（[security.md](../../.claude/rules/security.md)）
* AWS 側の事前準備コストを最小化したい
* 将来「友人にも配る / 一般配布する」になった場合に乗り換え可能な構造を残したい

## 検討した選択肢 (Considered Options)

* **A. ユーザー入力の IAM Access Key 方式**: ユーザーが IAM User を自分で作り、Access Key ID / Secret Access Key を発行してアプリに貼り付ける。`flutter_secure_storage` で保管
* **B. Cognito 方式**: AWS Cognito User Pool + Identity Pool でサインアップ/サインインさせ、Identity Pool 経由で短期 AWS クレデンシャル (STS) を取得する
* **C. 自前バックエンド + STS**: 認証用バックエンドを別途立て、AssumeRole で短期クレデンシャルを発行する

## 決定 (Decision Outcome)

採用：**「A. ユーザー入力の IAM Access Key 方式」**。理由は、(1) 想定ユーザーが AWS アカウント保有者で「自分のキーを貼る」操作に違和感がない、(2) AWS Console 側の準備が IAM User 1 つ分（10 分）で済み、Cognito の User Pool / Identity Pool / IAM Role / メール送信設定（半日仕事）と比べて圧倒的に軽い、(3) `flutter_secure_storage` で OS の Keychain / Keystore に乗せれば MASVS-STORAGE は満たせる、の 3 点。

長期クレデンシャルである弱点は受け入れるが、再考トリガー条件を補足情報に明記しておく。

### 結果 (Consequences)

* Good: AWS 側の準備が IAM User 作成と最小権限ポリシーのアタッチだけ。アプリ側もフォーム + secure storage で済む
* Good: バックエンド不要、Cognito 等の外部依存もなし。アプリの可搬性が高い
* Good: 個人用ツールとしての UX が素直（自分の AWS の話なのでサインインを挟む必要がない）
* Bad: クレデンシャルが永続。漏洩しても気づいて手動 rotate するまで悪用が続く（MASVS-AUTH の「アクセストークンには有効期限を設定する」は構造的に満たせない）
* Bad: ユーザーが面倒で広い IAM 権限を付けると、漏洩時の被害が AWS アカウント全体に波及しうる。アプリ側からは強制できないため、最小権限ポリシーの雛形を README/docs で提供することで緩和する
* Bad: ユーザーごとの S3 prefix 隔離が IAM レベルでできない（バケット全体 = 一人のもの）。個人用前提では問題にならないが、配布する場合は B が必要
* Neutral: 監査ログには「IAM User X」しか残らず、端末単位の追跡はできない

### 確認方法 (Confirmation)

* Settings 画面に "AWS 認証情報" セクションが存在し、4 項目（Access Key ID / Secret Access Key / Region / Bucket Name）を入力できること
* Access Key ID と Secret Access Key が `flutter_secure_storage` 経由で保管されていること（grep で SharedPreferences に直接書かれていないことを確認）
* Secret 入力フィールドが `obscureText: true` で、表示トグルを持たないこと
* リリースビルドで Access Key / Secret がログ出力されないこと（`kDebugMode` ガード）
* IAM 最小権限ポリシーの雛形が README または `docs/` に掲載され、ユーザーがコピペで使えること

## 各選択肢の利点・欠点 (Pros and Cons of the Options)

### A. ユーザー入力の IAM Access Key 方式
* Good: AWS 側準備が IAM User 1 つ分（10 分）で完了
* Good: バックエンド不要、外部 SaaS 依存なし
* Good: 「自分の AWS を自分が使う」モデルに UX が素直
* Neutral: クレデンシャルが永続のため rotate はユーザー責任
* Bad: MASVS-AUTH の短期トークン要件を構造的に満たせない
* Bad: ユーザーごとの IAM 隔離ができないため一般配布には不適

### B. Cognito 方式
* Good: 短期トークン（1 時間）+ 自動更新でクレデンシャル漏洩時の影響窓が小さい
* Good: User Pool ID 単位で IAM 権限を `${cognito-identity.amazonaws.com:sub}` でユーザー隔離できる
* Good: 一般ユーザー向け配布でも違和感のないサインアップ/サインイン UX
* Bad: AWS Console 側の準備が User Pool + Identity Pool + IAM Role + SES（メール認証）まで広がり半日仕事
* Bad: アプリ実装も signup/signin/forgot-password など複数画面に増える
* Bad: Cognito サービスへの依存が増える（障害時の影響、リージョン制約等）

### C. 自前バックエンド + STS
* Good: 認証ロジックをアプリ外に集約でき、最も柔軟
* Good: バックエンドで監査・レート制限・即時失効が可能
* Bad: バックエンドの開発・運用コストが本アプリの規模に対して過大
* Bad: 個人ツールに対してオーバーキル

## 補足情報 (More Information)

* AWS 公式: [IAM access keys のベストプラクティス](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
* AWS 公式: [Amazon Cognito Identity Pools](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-identity.html)
* 関連 ADR: 本 ADR は同期処理の認証層を扱う。データ層・UI 層は ADR-0001 / ADR-0002 / ADR-0003 を参照
* 関連スコープ:
  - 本 ADR は「認証情報の入力・保管」までを扱う
  - 「接続テスト」「実 S3 操作」「Certificate Pinning」は別スコープで後続計画として扱う
* 再考のトリガー条件:
  - 「友人・家族など他者にも配る」要件が出た時 → B（Cognito）への移行 ADR を起票
  - 「ユーザーごとの S3 prefix 隔離」要件が出た時 → 同上
  - 「App Store / Play Store で一般配布する」判断をした時 → 同上
  - AWS 公式が IAM Access Key の利用方針を変更した時（公式ガイダンスで非推奨化される等）
