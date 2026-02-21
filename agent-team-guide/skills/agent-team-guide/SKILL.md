---
name: agent-team-guide
description: >
  Agent Teams スキルを設計・構築するためのベストプラクティスガイド。
  サブエージェント定義、SendMessage 通信プロトコル、タスク依存管理、
  PostToolUse Hook によるログ、MCP ツール統合、コンテキストファイル設計を網羅。
  7つの実績あるチームスキル（app-naming, ui-review, logo-design, persona-creation,
  skill-creator-team, ui-variations, aso-optimize）から抽出したパターン集。
  Use when: Agent Teams を使ったスキルを新規作成したい、
  既存のチームスキルの品質を改善したい、エージェント間通信のデバッグ、
  チームスキルの設計パターンを知りたい。
  Triggers: "agent team", "チームスキル", "エージェントチーム",
  "サブエージェント定義", "SendMessage パターン", "チーム設計",
  "エージェント間通信", "team skill", "swarm pattern"
---

# Agent Team Guide

7つの実績あるチームスキルから抽出した Agent Teams 設計パターン集。
新規チームスキルの作成と、既存スキルの品質監査の両方に使える。

## このスキルの使い方

**新規作成**: SKILL.md テンプレート → エージェント定義 → タスク設計 → テスト の順で構築
**品質監査**: [references/quality-checklist.md](references/quality-checklist.md) を既存スキルに適用し、改善点を特定

## チームスキルのディレクトリ構成

```
my-team-skill/
├── SKILL.md                    <- リーダーの手順書（ワークフロー全体）
├── agents/                     <- サブエージェント定義
│   ├── role-a.md
│   ├── role-b.md
│   └── context-manager.md      <- ファイル I/O 専任を推奨
├── references/                 <- テンプレート・ドメイン知識
│   └── report-template.md
└── scripts/                    <- 初期化・ユーティリティ
    └── init.sh
```

## 設計の5原則

1. **エージェント数は 3〜6 体**: 少なすぎると並列の意味なし、多すぎると通信爆発
2. **MECE な役割分担**: 各エージェントの責務が重複しない
3. **3-Phase ワークフロー**: 全エージェントが init → active → finalize の構造
4. **実質的通信のみ**: ACK だけの返信は不要。相手の次アクションに繋がる内容がある時のみ返信
5. **待ちすぎない**: 全員のフィードバックを待たない。2人以上から反応があれば次へ進む
6. **コンテキストファイルで永続化**: セッション跨ぎの知識蓄積

## SKILL.md テンプレート

```markdown
## Step 1: ヒアリング
以下を確認する（不明ならユーザーに質問）:
- **項目A**: {具体的に何を聞くか}
- **項目B**: ...

## Step 2: チーム作成とエージェント起動

TeamCreate で `{skill-name}` チームを作成。
以下 N エージェントを **1つのメッセージで並列に** Task ツールで起動する。

| name | 役割 | 主な手段 |
|------|------|---------|
| `role-a` | ... | 分析 |
| `role-b` | ... | WebSearch |

### タスク作成
TaskCreate で N+1 個のタスクを作成:
1. context-manager: 初期化（依存なし）
2. role-a: ...（`addBlockedBy: ["1"]`）
3. role-b: ...（依存なし or `addBlockedBy: ["1"]`）
4. ...（`addBlockedBy: ["2","3"]`）
5. 統合レポート（`addBlockedBy: ["1","2","3","4"]`）

### 起動設定（全エージェント共通）
subagent_type: "{skill-name}:{role-name}"
team_name: "{skill-name}"
mode: "bypassPermissions"
run_in_background: true

プロンプトに含める情報:
- ユーザーからヒアリングした全情報
- コンテキストファイルパス
- 既存の context.md 内容（あれば）

## Step 3: フィードバックループ

### フィードバックプロトコル
1. 自分の作業完了後、即座に関連エージェントへ共有
2. **実質的な内容のある返信のみ送る** - 「了解しました」「ありがとうございます」だけのACK返信は不要。フィードバック・質問・修正報告など、相手の次アクションに繋がる内容がある場合のみ返信する
3. 重大問題は即座に全員へ緊急通知
4. フィードバックを受けたら修正し、変更内容を共有
5. **待ちすぎない** - フィードバックを全員から集める必要はない。2人以上から反応があれば次のフェーズに進む

### Round 1: {概要}
{エージェント間の通信フロー}

### Round 2: {概要}
...

### Round 3: {概要}
...

### 緊急通知パターン
- **role-a**: {どんな問題を検知したら} → {誰にどうアクションを求めるか}
- **role-b**: ...

## Step 4: 最終レポート出力
テンプレート: [references/report-template.md](references/report-template.md)

## Step 5: クリーンアップ
1. 全エージェントに shutdown_request を送信
2. 全員シャットダウン後に TeamDelete でチーム削除
```

## リーダーの行動指針（SKILL.md 実行時）

エージェント起動後のリーダー（メインの Claude）の動き方:

1. **見守りが基本**: エージェントが自律的に議論する間は介入しない
2. **介入タイミング**: エージェントが詰まった時、矛盾が解消されない時、同じメッセージが繰り返される時
3. **TaskList で進捗確認**: 全タスクが completed になるまで待機
4. **最終統合**: 全報告を統合してレポートを作成（最終タスクはリーダー担当）
5. **シャットダウン**: 全員に `shutdown_request` → 承認確認後 `TeamDelete`

## MCP ツールを使うエージェント

MCP ツール（`mcp__pencil__*` 等）は agents/*.md からアクセスできない。
MCP が必要なエージェントは `subagent_type: "general-purpose"` で起動し、プロンプト内で役割を定義する:

```
Task(
  subagent_type: "general-purpose",
  team_name: "my-team",
  prompt: "あなたは ui-designer として... mcp__pencil__batch_design を使って..."
)
```

## よくある落とし穴

| 問題 | 原因 | 対策 |
|------|------|------|
| エージェントがタスクを見つけられない | owner 未設定 | TaskUpdate で必ず owner を設定 |
| ACK だけの返信が大量に発生 | 「無視禁止」を厳格に適用しすぎ | 「実質的な内容のある返信のみ」に変更 |
| エージェントが全員の返信を待ちすぎる | 「待ちすぎない」ルールがない | 2人以上から反応があれば次フェーズへ進む |
| エージェントが暇すぎる | 過剰な依存関係 | 並列可能なタスクの依存を外す + 早期フィードバック設計 |
| 最終タスクだけ残る | 完了通知なし | エージェントに「完了時リーダーに報告」を指示 |
| デバッグが困難 | ログがない | PostToolUse Hook (`agent-teams-log` プラグイン) を有効化 |
| MCP ツールが使えない | agents/*.md で定義 | `subagent_type: "general-purpose"` に変更 |

## 詳細リファレンス

トピック別に分離。必要なファイルだけ Read する:

- **エージェント定義の書き方**: [references/agent-definitions.md](references/agent-definitions.md)
  - YAML frontmatter、3-Phase 構造、SendMessage テンプレート、起動パラメータ
- **通信パターン**: [references/communication-patterns.md](references/communication-patterns.md)
  - Broadcast/Directed/Subteam/Hybrid モデル、SendMessage 構文、通信効率ルール
- **タスク管理**: [references/task-management.md](references/task-management.md)
  - 依存チェーン、TaskCreate のベストプラクティス、早期フィードバック
- **Hook 統合**: [references/hooks-integration.md](references/hooks-integration.md)
  - PostToolUse でエージェント通信を自動ログ、リアルタイム監視
- **品質チェックリスト**: [references/quality-checklist.md](references/quality-checklist.md)
  - 30項目のレビュー観点（監査手順付き）

## 関連スキル

- **SubAgent 定義の品質向上**: `subagent-best-practices` スキル（`~/.claude/skills/subagent-best-practices/`）
  - 個別の agents/*.md の書き方に特化したベストプラクティス
  - Frontmatter 全フィールド解説、ツール選択マトリクス、3-Phase 詳細設計、アンチパターン集
  - 本スキル（agent-team-guide）がチーム全体の設計を扱うのに対し、subagent-best-practices は個別エージェント定義の品質に特化
