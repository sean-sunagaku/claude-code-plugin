---
name: design-discussion
description: >
  「こんな機能を作りたい」「この設計どうしよう」という技術的な意思決定を、
  5人の専門エージェントチームで壁打ちするスキル。
  実装アプローチの比較・技術設計の選択・アーキテクチャの意思決定に特化。
  Use when: 複数の実装方法があって迷っている時、設計の良し悪しを議論したい時、
  技術的トレードオフを整理したい時。
  Triggers: "設計壁打ち", "design discussion", "どう設計すべき",
  "実装アプローチを比較", "アーキテクチャ相談", "設計どうしよう",
  "技術選定したい", "ADR を作りたい", "設計の議論", "技術的トレードオフ"
allowed-tools: "Read, Write, Edit, Glob, Grep, Task, TeamCreate, TeamDelete, WebSearch, AskUserQuestion"
---

# Design Discussion - 技術設計壁打ちスキル

5つの専門エージェント（Solution Architect・Engineer・Product Manager・User Liaison・Devil's Advocate）が
**技術的トレードオフを議論・反論し合いながら**設計案を比較検討するスキル。
Facilitator（この SKILL.md 自身）がオーケストレーションし、User Liaison がユーザーへの質問を一元管理する。

## スキルのフォーカス（CRITICAL）

このスキルは **実装アプローチ・技術設計の比較** に特化している。

- **対象**: データベース設計、API 設計、アーキテクチャパターン、ライブラリ選定、実装戦略、パフォーマンス最適化手法など
- **対象外**: UI/UX デザイン、ビジュアルデザイン、ユーザーフロー（それらは feature-discussion スキルを使用）
- **成果物**: 比較表（MD）、議論ログ、アクションリスト、ADR（Architecture Decision Record）

## チーム構成

| ロール | ファイル | 専門領域 |
|--------|---------|---------|
| **Facilitator** | この SKILL.md | 議論進行・合意形成・記録 |
| **Solution Architect** | `agents/solution-architect.md` | 設計案生成・アーキテクチャ比較・推奨案決定 |
| **Engineer** | `agents/engineer.md` | 技術的実現性・コードベース調査・工数評価 |
| **Product Manager** | `agents/product-manager.md` | ビジネス価値・スコープ・優先度・制約条件 |
| **User Liaison** | `agents/user-liaison.md` | ユーザーへの質問一元管理・タイミング判定 |
| **Devil's Advocate** | `agents/devils-advocate.md` | 合意案への批判・リスク発掘・前提検証 |

## コア原則

1. **技術的客観性** - データと根拠で比較する。感情的な好み・馴染みで判断しない
2. **トレードオフを明示** - 「完璧な案」はない。各案の利点と欠点を等価に扱う
3. **コードファースト** - 質問前に既存コードを把握する
4. **意思決定の記録** - なぜその案を選んだかを ADR 形式で残す
5. **悪魔の代弁者を活用** - 全員が合意した後で必ず批判的レビューを行う
6. **実質的な議論のみ** - 「了解」だけの応答は不要。反論・提案・質問がある時のみ発言

## ワークフロー概要

```
Step 1: 課題・要件の明確化
  担当: Solution Architect + Product Manager + Engineer
  目的: 何を決定する必要があるか、制約条件は何かを明確化

    ↓

Step 2: 設計案の生成と初期評価
  担当: Solution Architect + Engineer + Product Manager
  目的: 2-4 の具体的な設計案を生成し、初期スコアリング

    ↓

Step 3: 深掘り比較・Devil's Advocate
  担当: 全員参加（Devil's Advocate が合意を破壊）
  目的: 各案の詳細な技術的比較、リスク分析、前提検証

    ↓

Step 4: 推奨案の決定・アクションプラン
  担当: Solution Architect + User Liaison（ユーザー承認）
  目的: 最終推奨案を決定し、ADR と実装アクションリストを生成
```

各ステップの詳細は `references/discussion_protocol.md` を参照。

## セッション開始

壁打ちセッション開始時、以下を実行:

1. **ドメインドキュメントを読み込み**（`docs/`, `.claude/` 配下の設計関連 MD を Glob で検索）
2. **既存の設計パターンを把握**（コードベースがあれば Engineer に初期調査を依頼）
3. **セッション名（discussion-slug）を生成**:
   - テーマを英語の kebab-case スラッグに変換
   - 日本語の場合は英訳してからスラッグ化
4. `.claude/design_discussion/sessions/<discussion-slug>/` ディレクトリを作成
5. `session.json` を作成（下記テンプレート）
6. `discussion_log.md` を作成
7. **議論深さモードを自動判定**:
   - Light: 明らかに 2 択で、制約が明確な場合
   - Standard: 3 案以上 or 影響範囲が広い場合（デフォルト）
   - Deep: アーキテクチャ全体に影響する、後戻りが難しい決定
8. **Agent Team を作成**（`references/discussion_protocol.md` のチームライフサイクル参照）
9. Step 1 を開始

### 初期 JSON テンプレート

```json
{
  "sessionId": "<discussion-slug>",
  "topic": "<設計テーマ>",
  "status": "in_progress",
  "mode": "<light|standard|deep>",
  "currentStep": 1,
  "createdAt": "<ISO8601>",
  "updatedAt": "<ISO8601>",
  "steps": {
    "1_clarification": false,
    "2_proposals": false,
    "3_comparison": false,
    "4_decision": false
  },
  "proposals": [],
  "selectedProposal": null
}
```

## セッション管理コマンド

| 発言 | アクション |
|------|----------|
| 「壁打ち開始：〇〇の設計」 | 新規セッション作成、Step 1 開始 |
| 「次のステップ」「進めて」 | 現在のステップを完了し次へ |
| 「戻って」「前のステップ」 | 前のステップに戻る |
| 「今どこ？」「進捗は？」 | 現在のステップと完了状況を表示 |
| 「もっと議論して」 | 現在のステップで追加の議論ラウンドを実行 |
| 「悪魔の代弁者を呼んで」 | Devil's Advocate による追加批判セッション |
| 「ADR を出して」 | 現在の議論状態から ADR ドラフトを生成 |
| 「一覧」「セッション一覧」 | 過去のセッション一覧を表示 |
| 「再開：〇〇」 | 指定セッションを再開 |

## 進行時の表示フォーマット

各ステップ開始時:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[設計壁打ち] <設計テーマ>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
現在: Step <N>/4 - <ステップ名>
進捗: [████░░░░░░] 40%
モード: <Light|Standard|Deep>
担当: <リードエージェント> + <サブエージェント>

エージェントチームが議論中...
```

議論結果提示時:
```
━━━━ チーム議論結果 ━━━━

合意: [全員が同意した点]
対立: [論点と各エージェントの立場]
リスク: [Devil's Advocate が発掘したリスク]

どう判断しますか？
```

ステップ完了時:
```
Step <N> 完了: <ステップ名>
   → <簡潔なサマリー>
   → 議論ラウンド: <N>回
   → 候補案: <N>件

次へ進みますか？（「次へ」で続行）
```

## セッション完了条件

全ステップが `true` の場合:
```json
{
  "status": "completed",
  "completedAt": "<ISO8601>",
  "decision": "<採用案の名前>",
  "steps": {
    "1_clarification": true,
    "2_proposals": true,
    "3_comparison": true,
    "4_decision": true
  }
}
```

**生成物**:
- `session.json` - セッション進捗管理
- `discussion_log.md` - ディスカッション議事録（エージェント間の議論含む）
- `1_clarification.md` - 課題・要件・制約の明確化結果
- `2_proposals.md` - 設計案一覧（2-4案）
- `3_comparison.md` - 比較表・深掘り結果・Devil's Advocate 指摘
- `4_decision.md` - 推奨案・ADR・アクションリスト

## リファレンスインデックス

詳細ドキュメントはトピック別に分離。必要なファイルだけ `Read` する:

| ファイル | 内容 |
|---------|------|
| `references/discussion_protocol.md` | R1-R4 ラウンド詳細、チームライフサイクル、収束条件、ユーザー判断追跡 |
| `references/step_details.md` | Step 1-4 の詳細フロー（担当・目的・完了条件） |
| `references/output_templates.md` | 成果物テンプレート（比較表・ADR・アクションリスト） |
| `references/agent_spawn_templates.md` | Step 1-4 のエージェント起動テンプレート |
| `references/quality_control.md` | Quality Gate 基準（ステップ別・共通） |
