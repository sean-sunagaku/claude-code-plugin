---
name: aso-optimize
description: >
  App Store / Google Play のメタデータ最適化（ASO）を、4つの専門エージェントチームで実行するスキル。
  キーワード調査、宣伝テキスト作成、競合分析、多言語ローカライゼーションの4観点から
  App Store 向けテキスト一式（タイトル、サブタイトル、キーワード、説明文、宣伝テキスト、What's New）を
  生成し、最終レポート(MD)を出力する。多言語対応（日本語・英語+他言語）。
  Use when: App Store の説明文を書きたい、ASO対策したい、キーワード選定したい、
  宣伝文章を作りたい、App Store テキストを多言語化したい、What's New を書きたい。
  Triggers: "ASO", "App Store", "宣伝文", "説明文", "キーワード", "サブタイトル",
  "What's New", "promotional text", "app description", "keyword optimization",
  "ストア掲載", "メタデータ", "アプリ紹介文", "Google Play", "多言語ASO"
---

# ASO Optimize Skill

4つの専門エージェントがチームで議論・フィードバックし合い、App Store / Google Play 向けの最適なメタデータを作成する。

## ワークフロー

1. ユーザーからアプリ情報をヒアリング
2. Agent Team を作成し、4エージェントを並列起動
3. 2〜3ラウンドの議論・フィードバック
4. 最終レポート + 各言語のメタデータ一式を MD ファイルで出力

## Step 1: ヒアリング

以下を確認する（不明ならユーザーに質問）:

- **アプリの概要**: 何をするアプリか、コア機能、差別化ポイント
- **アプリ名**: 決定済みの名前（未定なら app-naming スキルを先に使用）
- **ターゲット**: 年齢層、性別、興味関心
- **カテゴリ**: App Store のカテゴリ（ライフスタイル、ヘルスケア、エンタメ等）
- **対象地域・言語**: どの国/言語向けにテキストを作成するか
- **競合アプリ**: 知っていれば競合アプリ名（なくてもOK）
- **アップデート内容**: What's New が必要な場合、今回の変更内容
- **現行テキスト**: 既にストアに掲載中のテキストがあれば確認

## Step 2: チーム作成とエージェント起動

TeamCreate で `aso-optimize` チームを作成。以下4エージェントを **1つのメッセージで並列に** Task ツールで起動する。

| name | 役割 | 主な調査手段 |
|------|------|------------|
| `aso-strategist` | ASO 全体戦略・競合分析・構成設計 | WebSearch |
| `keyword-researcher` | キーワード調査・選定・最適化 | WebSearch |
| `copywriter` | App Store テキスト全要素の作成 | アプリ情報分析 |
| `localizer` | 多言語ローカライゼーション・文化適応 | WebSearch |

各エージェントは `agents/` ディレクトリにサブエージェントとして定義済み。

### タスク作成

TaskCreate で5つのタスクを作成:

1. aso-strategist: 競合分析 + ASO 全体戦略立案
2. keyword-researcher: キーワード調査・選定
3. copywriter: App Store テキスト一式の作成
4. localizer: 多言語ローカライゼーション
5. 統合レポート: タスク1〜4完了後（`addBlockedBy: ["1","2","3","4"]`）

### 起動設定

各エージェントのプロンプトに `{APP_INFO}` を埋め込んで起動する。

```
subagent_type: "aso-strategist"  # agents/ で定義済みのサブエージェント名
team_name: "aso-optimize"
mode: "bypassPermissions"
run_in_background: true
```

## Step 3: 議論の進行

エージェントは自律的に議論する:

```
Round 1: aso-strategist が競合分析＋戦略 → keyword-researcher がキーワード選定 → copywriter がドラフト作成 → localizer が翻訳
Round 2: 各エージェントが相互フィードバック → キーワード修正・テキスト改善
Round 3: 最終版を確定、スコアリング
```

リーダーは基本見守り。エージェントが詰まった場合のみ介入。

## Step 4: 最終レポート出力

全報告が揃ったら統合レポートを MD で出力する。テンプレートは [references/report-template.md](references/report-template.md) を参照。

出力先: プロジェクトルートに `ASO_REPORT.md`

### App Store メタデータの文字数制限

| 要素 | 文字数制限 | 備考 |
|------|-----------|------|
| アプリ名 | 30文字 | 最も重要。ブランド名+主要キーワード |
| サブタイトル | 30文字 | 補助キーワード。名前と重複しない |
| キーワードフィールド | 100文字 | カンマ区切り。名前/サブタイトルと重複しない |
| 宣伝テキスト | 170文字 | 審査不要。頻繁に更新可。CTA重要 |
| 説明文 | 4000文字 | 最初の3行が最重要（折りたたみ前） |
| What's New | 4000文字 | 簡潔に。ユーザーメリット中心 |

## Step 5: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除
