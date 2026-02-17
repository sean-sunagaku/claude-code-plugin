---
name: app-naming
description: >
  アプリ名・サービス名の命名を、4つの専門エージェントチームで多角的に評価・決定するスキル。
  ブランディング、商標/法的リスク、デジタルプレゼンス(SEO/ASO/SNS)、国際展開(多言語/発音)の
  4観点から候補を提案・調査・議論し、最終レポート(MD)を出力する。
  Use when: アプリ名を決めたい、サービス名を変更したい、プロダクト名を検討したい、
  ネーミングブレスト、名前の商標チェック、アプリ名のリネーム。
  Triggers: "アプリ名", "サービス名", "プロダクト名", "ネーミング", "名前を決め",
  "リネーム", "rename", "app name", "naming", "ブランド名", "商標チェック"
---

# App Naming Skill

4つの専門エージェントがチームで議論・フィードバックし合い、最適なアプリ名を決定する。

## ワークフロー

1. ユーザーからアプリ情報をヒアリング
2. Agent Team を作成し、4エージェントを並列起動
3. 2〜3ラウンドの議論・フィードバック
4. 最終レポートを MD ファイルで出力

## Step 1: ヒアリング

以下を確認する（不明ならユーザーに質問）:

- **アプリの概要**: 何をするアプリか、コア機能
- **ターゲット**: 年齢層、言語、地域
- **名前の方向性**: 日本語名/英語名/造語/指定なし
- **国際展開**: 日本市場限定か、海外展開予定か
- **現行名**: リネームの場合、現在の名前と変更理由

## Step 2: チーム作成とエージェント起動

TeamCreate で `app-naming` チームを作成。以下4エージェントを **1つのメッセージで並列に** Task ツールで起動する。

| name | 役割 | 主な調査手段 |
|------|------|------------|
| `brand-strategist` | 候補15個提案・ブランド評価 | アプリ情報分析 |
| `legal-researcher` | 商標・App Store競合・ドメイン調査 | WebSearch |
| `digital-presence` | SEO・ASO・SNSアカウント評価 | WebSearch |
| `global-checker` | 多言語の意味・発音・国際展開チェック | WebSearch |

各エージェントは `agents/` ディレクトリにサブエージェントとして定義済み。
プラグインインストール時に自動で認識される。

### タスク作成

TaskCreate で5つのタスクを作成:

1. brand-strategist: 候補提案 → フィードバック受けてブラッシュアップ
2. legal-researcher: 商標・競合・ドメイン調査
3. digital-presence: SEO・ASO・SNS調査
4. global-checker: 多言語チェック
5. 統合レポート: タスク1〜4完了後（`addBlockedBy: ["1","2","3","4"]`）

### 起動設定

各エージェントのプロンプトに `{APP_DESCRIPTION}` を埋め込んで起動する。

```
subagent_type: "brand-strategist"  # agents/ で定義済みのサブエージェント名
team_name: "app-naming"
mode: "bypassPermissions"
run_in_background: true
```

## Step 3: 議論の進行

エージェントは自律的に議論する:

```
Round 1: brand-strategist が15候補を提案 → 3人が各観点で評価
Round 2: フィードバックを踏まえ候補を修正・追加 → 再評価
Round 3: 最終候補を絞り込み、スコアリング
```

リーダーは基本見守り。エージェントが詰まった場合のみ介入。

## Step 4: 最終レポート出力

全報告が揃ったら統合レポートを MD で出力する。テンプレートは [references/report-template.md](references/report-template.md) を参照。

出力先: プロジェクトルートに `APP_NAMING_REPORT.md`

## Step 5: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除
