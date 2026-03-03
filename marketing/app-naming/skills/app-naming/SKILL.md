---
name: app-naming
description: >
  アプリ名・サービス名の命名を、5つの専門エージェントチームで多角的に評価・決定するスキル。
  ブランディング、商標/法的リスク、デジタルプレゼンス(SEO/ASO/SNS)、国際展開(多言語/発音)の
  4観点から候補を提案・調査・議論し、コンテキストファイルと議事録で次回セッションへ引き継ぐ。
  Use when: アプリ名を決めたい、サービス名を変更したい、プロダクト名を検討したい、
  ネーミングブレスト、名前の商標チェック、アプリ名のリネーム。
  Triggers: "アプリ名", "サービス名", "プロダクト名", "ネーミング", "名前を決め",
  "リネーム", "rename", "app name", "naming", "ブランド名", "商標チェック"
---

# App Naming Skill

5つの専門エージェントがチームで相互フィードバックしながら議論し、最適なアプリ名を決定する。
コンテキストファイルで過去の候補・却下理由・学びを蓄積し、次のラウンドに引き継ぐ。

## ワークフロー

1. ユーザーからアプリ情報をヒアリング
2. Agent Team を作成し、5エージェントを並列起動
3. コンテキスト作成 → 候補提案 → 相互フィードバック → 絞り込み
4. 議事録（全体 + ラウンド別）と最終レポートを MD で出力

## コンテキストファイル構成

各セッションで以下のファイルを作成・管理する:

```
.claude/app-naming/{YYYY-MM-DD}_{project}/
├── context.md              ← 全体コンテキスト（アプリ情報・学びの蓄積）
├── SUMMARY.md              ← 全ラウンドを横断するサマリー
└── round-{N}/              ← N は 01, 02, 03... の2桁ゼロ埋め
    ├── context.md          ← このラウンドの目的・制約・方針
    ├── log.md              ← このラウンドの議事録（時系列・決定事項）
    └── candidates.md       ← このラウンドで評価した候補と評価結果
```

これにより:
- 次回ネーミングセッション時に `context.md` を読めばすぐにコンテキストを復元できる
- 各ラウンドの `log.md` で「なぜその候補を却下したか」を追跡できる
- `candidates.md` で評価スコアの変遷を管理できる

## Step 1: ヒアリング

以下を確認する（不明ならユーザーに質問）:

- **アプリの概要**: 何をするアプリか、コア機能
- **ターゲット**: 年齢層、言語、地域
- **名前の方向性**: 日本語名/英語名/造語/指定なし
- **国際展開**: 日本市場限定か、海外展開予定か
- **現行名**: リネームの場合、現在の名前と変更理由
- **好みのトーン**: クール/親しみやすい/プロフェッショナル
- **避けたいパターン**: あれば

## Step 2: チーム作成とエージェント起動

TeamCreate で `app-naming` チームを作成。以下5エージェントを **1つのメッセージで並列に** Task ツールで起動する。

| name | 役割 | 主な調査手段 |
|------|------|------------|
| `context-manager` | コンテキストファイル・議事録の作成と管理 | Write/Edit |
| `brand-strategist` | 候補15個提案・ブランド評価・絞り込み | アプリ情報分析 |
| `legal-researcher` | 商標・App Store競合・ドメイン調査 | WebSearch |
| `digital-presence` | SEO・ASO・SNSアカウント評価 | WebSearch |
| `global-checker` | 多言語の意味・発音・国際展開チェック | WebSearch |

### タスク作成

TaskCreate で6つのタスクを作成:

1. context-manager: コンテキストファイルとラウンド議事録の初期作成
2. brand-strategist: 候補15個提案 → フィードバック受けてブラッシュアップ（タスク1完了後: `addBlockedBy: ["1"]`）
3. legal-researcher: 商標・競合・ドメイン調査
4. digital-presence: SEO・ASO・SNS調査
5. global-checker: 多言語チェック
6. 統合レポート + 最終候補確定: タスク1〜5完了後（`addBlockedBy: ["1","2","3","4","5"]`）

### 起動設定

```
subagent_type: "context-manager"  # agents/ で定義済みのサブエージェント名
team_name: "app-naming"
mode: "bypassPermissions"
run_in_background: true
```

プロンプトに含める情報（全エージェント共通）:
- アプリ概要、ターゲット、名前の方向性、国際展開計画
- コンテキストファイルパス: `.claude/app-naming/{date}_{project}/`
- 既存の context.md がある場合はその内容も含める（前回の学びを引き継ぐ）

## Step 3: エージェント間フィードバックループ

エージェント同士が**能動的に**コミュニケーションし、複数ラウンドで相互フィードバックを行う。
リーダーは基本見守り。エージェントが詰まった場合のみ介入。

### フィードバックプロトコル（全エージェント共通ルール）

1. **自分の調査が終わったら即座に全員へ共有**: 全5エージェントに SendMessage で送る
2. **他のエージェントから受け取ったメッセージには必ず返信する**: 同意・反論・質問いずれかを返す（無視禁止）
3. **「使用不可」は即座に警告**: legal-researcher / global-checker は問題発見次第すぐ全員に通知
4. **フィードバックを受けたら提案を修正する**: 修正後に変更内容を全員に共有

### Round 1: 候補提案と初期調査（並列進行）

```
[brand-strategist]
  → 全員に: 候補15個を送信し「各観点で評価してください」と依頼

[legal-researcher]
  → brand-strategistに: 「使用不可」候補を即座に警告
  → 全員に: リスクレベル付きの調査結果

[digital-presence]
  → brand-strategistに: SEO/ASO スコア上位候補を共有
  → global-checkerに: 「この候補のSNS取得状況はどうか」

[global-checker]
  → brand-strategistに: 「使用不可」候補を即座に警告（ネガティブ意味あり）
  → legal-researcherに: 「この候補は中国語でXXという意味がある、商標でも問題ないか？」

[brand-strategist（受信後）]
  → 全員に: 問題のある候補を除外した修正版（上位10候補）を再送
```

### Round 2: 絞り込みと深堀り

```
[brand-strategist]
  → 全員に: 「上位5候補に絞りました。これで最終スコアリングをお願いします」

[legal-researcher / digital-presence / global-checker]
  → 各自の最終スコア（10点満点）を確定し brand-strategist に送信
  → 他エージェントのスコアに異議があれば議論

[brand-strategist]
  → 全員に: 総合スコアランキング（1〜5位）を作成して共有
```

### Round 3: 最終スコアリング

```
全エージェント → 全員に: 最終推奨を以下のフォーマットで送信

  推奨: {候補名}
  スコア: ブランド/法的/デジタル/グローバル = 各10点満点
  総合: XX/40点
  推奨理由: {簡潔に}
  懸念点: {あれば}

最高スコアの候補 or 複数エージェントが推す候補をリーダーが採用
```

## Step 4: 最終レポート出力

全報告が揃ったら統合レポートを MD で出力する。テンプレートは [references/report-template.md](references/report-template.md) を参照。

出力先: プロジェクトルートに `APP_NAMING_REPORT.md`

レポートに含める:
- 最終推奨候補（上位3〜5個）とその総合スコア
- 却下した候補と却下理由
- 各エージェントのスコアリング結果
- 次のラウンドへの推奨事項

## Step 5: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除

---

## Shell Scripts リファレンス

スキルと同梱の scripts でコンテキストファイルの初期化・管理が簡単になる。

### init.sh - プロジェクト初期化

```bash
bash scripts/init.sh <project-name>

# 例
bash scripts/init.sh miravy
# → .claude/app-naming/2026-02-18_miravy/ を作成
```

作成されるファイル:
```
.claude/app-naming/{date}_{project}/
├── context.md              ← アプリ情報を記入する
├── SUMMARY.md
└── round-01/
    ├── context.md
    ├── log.md
    └── candidates.md       ← 候補と評価結果テーブル
```

### new-round.sh - 新ラウンド作成

```bash
bash scripts/new-round.sh <project-dir>

# 例
bash scripts/new-round.sh ~/.claude/app-naming/2026-02-18_miravy
# → round-02/ を作成
```

### status.sh - 進捗確認

```bash
# 全プロジェクト表示
bash scripts/status.sh

# 特定プロジェクト
bash scripts/status.sh ~/.claude/app-naming/2026-02-18_miravy
```

### finalize.sh - 最終候補まとめ

```bash
bash scripts/finalize.sh <project-dir> <round-number>

# 例: round-02 の結果で最終化
bash scripts/finalize.sh ~/.claude/app-naming/2026-02-18_miravy 02
```
