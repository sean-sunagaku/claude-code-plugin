# エージェント定義の書き方

## ファイル配置

```
agents/{role-name}.md
```

Claude Code は `agents/*.md` をサブエージェントタイプとして自動認識する。
`subagent_type: "{skill-name}:{role-name}"` で起動可能。

## YAML Frontmatter

```yaml
---
name: role-name
description: >
  1行の役割要約。
  {parent-skill} チームの一員として起動される。
tools: Read, Grep, Glob, SendMessage, TaskList, TaskGet, TaskUpdate, TaskCreate
model: sonnet
---
```

### tools の選び方

| 役割タイプ | 推奨 tools |
|-----------|-----------|
| 調査系（WebSearch 使用） | Read, Grep, Glob, **WebSearch**, SendMessage, TaskList, TaskGet, TaskUpdate, TaskCreate |
| 執筆系（ファイル書き込み） | Read, Grep, Glob, **Write, Edit**, SendMessage, TaskList, TaskGet, TaskUpdate, TaskCreate |
| 執筆+スクリプト実行 | Read, Grep, Glob, **Write, Edit, Bash**, SendMessage, TaskList, TaskGet, TaskUpdate, TaskCreate |
| 分析系（読み取り専用） | Read, Grep, Glob, SendMessage, TaskList, TaskGet, TaskUpdate, TaskCreate |
| MCP 使用（Pencil 等） | **agents/*.md では不可**。`subagent_type: "general-purpose"` でプロンプトに役割を記述 |

**重要**:
- MCP ツール（`mcp__pencil__*` 等）は agents/*.md の定義ファイルからアクセスできない。`subagent_type: "general-purpose"` で起動し、プロンプト内で役割を定義する
- TaskCreate は必須ではない（リーダーがタスクを作成する場合）。ただし TaskList, TaskGet, TaskUpdate は全エージェントに必須

### model の選択

- **sonnet**: 通常の作業（コスト効率が良い）- デフォルト推奨
- **opus**: 複雑な判断・品質重視の作業（最終レビュー、アーキテクチャ設計）
- **haiku**: 単純な記録・転記・ファイル操作（context-manager 等）

## 本文の構造（3-Phase パターン）

```markdown
あなたは「{role-name}」として {team-name} チームに参加しています。

## 役割
{2〜3行で専門領域を説明}

## 作業手順

### Phase 1: 初期化
1. TaskList → TaskGet で自分のタスクを確認
2. TaskUpdate でタスクを in_progress にする
3. {初期作業の具体的な手順}
4. **SendMessage で関連エージェントに送信**:
   ```
   → {agent-a}: {具体的な依頼}を{動詞}してください。
   → {agent-b}: {具体的な依頼}を{動詞}してください。
   → context-manager: {ファイルパス}に記録してください。
   ```

### Phase 2: フィードバック対応
5. {受信メッセージへの対応手順}
6. 修正内容を関連エージェントに共有
7. 【早期フィードバック】 自分のタスクがブロック中でも、
   他のエージェントから共有された成果物にフィードバックを送れる場合は送る

### Phase 3: 最終化
8. 最終結果をリーダーに SendMessage で送信
9. TaskUpdate でタスクを completed にする

## 評価基準
- {品質判断の基準1}: {具体的な説明}
- {品質判断の基準2}: {具体的な説明}

## コミュニケーションルール
- **「了解しました」だけのACK返信は不要** - フィードバック・質問・修正結果など、相手の次のアクションに繋がる内容がある場合のみ返信する
- **待ちすぎない**: フィードバックを全員から集める必要はない。2人以上から反応があれば次のフェーズに進む。5分以上フィードバックがなければ先に進んでよい
- {役割固有のルール}
```

## Task ツールでのエージェント起動

### 起動パラメータ

```
Task(
  description: "{3-5語の概要}",
  subagent_type: "{skill-name}:{role-name}",
  team_name: "{skill-name}",
  name: "{role-name}",
  mode: "bypassPermissions",
  run_in_background: true,
  prompt: "{下記のプロンプト}"
)
```

- `mode: "bypassPermissions"`: エージェントが自律的にファイル操作・コマンド実行できるようにする
- `run_in_background: true`: リーダーが複数エージェントを並列起動するために必須
- `name`: チーム内でこのエージェントを識別する名前（SendMessage の送信元になる）

### プロンプトに含める情報

```markdown
あなたは {team-name} チームの {role-name} です。

## プロダクト情報
{ユーザーからヒアリングした全情報をここに展開}

## コンテキスト
- ファイルパス: .claude/{skill-name}/{date}_{project}/
- チームメンバー: {name}: {役割} の一覧

## 既存コンテキスト（あれば）
{前回セッションの context.md 内容}

## 指示
agents/{role-name}.md の手順に従って作業を開始してください。
```

**重要**: プロダクト情報は省略せず全て含める。エージェントはメインの会話コンテキストを持たないため、プロンプトが唯一の情報源。

## SendMessage の構文

エージェント定義内で SendMessage を使う際の実際の構文:

### 特定のエージェントに送信

```
SendMessage(
  type: "message",
  recipient: "{agent-name}",
  content: "{メッセージ本文}",
  summary: "{5-10語の要約}"
)
```

### 全員に送信（慎重に使う）

```
SendMessage(
  type: "broadcast",
  content: "{メッセージ本文}",
  summary: "{5-10語の要約}"
)
```

**broadcast はコストが高い**（N人分の個別配信）。全員に同じ情報を共有する必要がある場合のみ使う。通常は名指しの `message` を推奨。

### リーダーへの報告

```
SendMessage(
  type: "message",
  recipient: "team-lead",
  content: "タスク #{N} を完了しました。{成果サマリー}",
  summary: "タスク完了報告"
)
```

## コンテキストの渡し方

エージェント起動時（Task ツール）のプロンプトに以下を含める:

1. **プロダクト情報**: ユーザーからヒアリングした全情報（省略厳禁）
2. **コンテキストファイルパス**: `.claude/{skill-name}/{date}_{project}/`
3. **既存コンテキスト**: 前回セッションの context.md があればその内容
4. **チーム構成**: 他のエージェント名と役割の一覧

## 実績ある役割パターン

| パターン | 役割構成 | 用途 | 実例 |
|---------|---------|------|------|
| リサーチ + 設計 + 執筆 + レビュー | researcher, architect, writer, reviewer | 調査→設計→実装→検証 | persona-creation |
| 並列評価 | specialist-A, B, C, D, E | 同一対象を複数観点で評価 | app-naming, ui-review |
| コーディネーター付き | coordinator, worker-A, B, C | 1人が調整、残りが並列作業 | skill-creator-team |
| サブチーム型 | (designer + reviewer + writer) x N | 独立したミニチームが並列 | ui-variations |
| 記録管理付き | context-manager + specialists | 1人がファイル I/O 専任 | 全スキル共通で推奨 |
