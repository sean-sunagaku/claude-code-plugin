---
name: subagent-best-practices
description: >
  Claude Code の SubAgent（agents/*.md）を正しく定義するためのベストプラクティスガイド。
  YAML frontmatter、ツール選択、3-Phase 構造、コンテキスト受け渡し、アンチパターンを網羅。
  Use when: agents/*.md を書く、SubAgent 定義を改善する、エージェントの動作が想定外、
  コンテキストが渡らない、ツール選択に迷う。
  Triggers: "subagent", "agent definition", "agents/*.md", "エージェント定義",
  "サブエージェント", "3-Phase", "context passing", "コンテキスト渡し",
  "tool selection", "ツール選択", "subagent_type", "bypassPermissions"
---

# SubAgent Best Practices

Claude Code の `agents/*.md` ファイルで SubAgent を正しく定義するための実践ガイド。
チーム設計・通信プロトコル・タスク管理は **agent-team-guide** スキルを参照。
このスキルは「個別 SubAgent の定義品質」に特化している。

## SubAgent とは

SubAgent は `agents/*.md` ファイルで定義された特化型エージェント。

```
my-skill/
└── agents/
    ├── researcher.md      ← SubAgent 定義
    ├── writer.md
    └── context-manager.md
```

Claude Code は `agents/*.md` を自動認識し、`subagent_type: "my-skill:researcher"` で起動できる。
SubAgent は**親のコンテキストを持たない**。起動時のプロンプトが唯一の情報源。

### subagent_type の種類

| 値 | 動作 |
|----|------|
| `"my-skill:researcher"` | `agents/researcher.md` を読んで起動 |
| `"general-purpose"` | `agents/*.md` を使わず、プロンプトでロールを定義 |
| `"Explore"` | コードベース探索に特化した組み込みタイプ |

---

## YAML Frontmatter の書き方

```yaml
---
name: researcher                    # 必須: kebab-case の識別名
description: >                      # 必須: 役割の1〜3行説明
  Market research specialist.
  Part of the app-naming team.
tools: Read, Grep, Glob, WebSearch, # 推奨: 許可ツールのリスト
       SendMessage, TaskList, TaskGet, TaskUpdate
model: sonnet                       # 推奨: haiku / sonnet / opus / inherit
---
```

### name

- `subagent_type: "my-skill:{name}"` の `{name}` 部分に対応
- kebab-case 推奨（`context-manager`, `bias-reviewer`）
- SendMessage の送信元名として使われる

### description

- エージェントの役割と所属チームを 1〜3 行で説明
- `subagent_type` 指定時のマッチングに使われる
- 自動委譲を強化する場合は "Use proactively" / "MUST BE USED" を含める

```yaml
# 自動委譲を意図した description の例
description: >
  Expert code review specialist. Use proactively after writing or modifying code.
  Triggers: "review", "check", "レビュー"
```

### tools の選び方

| 役割タイプ | 推奨 tools |
|-----------|-----------|
| 調査系 | `Read, Grep, Glob, WebSearch, SendMessage, TaskList, TaskGet, TaskUpdate` |
| 執筆系 | `Read, Grep, Glob, Write, Edit, SendMessage, TaskList, TaskGet, TaskUpdate` |
| 実行系 | `Read, Grep, Glob, Write, Edit, Bash, SendMessage, TaskList, TaskGet, TaskUpdate` |
| 分析系（読み取り専用） | `Read, Grep, Glob, SendMessage, TaskList, TaskGet, TaskUpdate` |
| コンテキスト管理専任 | `Read, Write, Edit, SendMessage, TaskList, TaskGet, TaskUpdate` |

**全エージェント必須**: `SendMessage, TaskList, TaskGet, TaskUpdate`（チーム通信・タスク管理に必須）

**重要制限**: MCP ツール（`mcp__pencil__*` 等）は `agents/*.md` からアクセスできない。
MCP が必要な場合は `subagent_type: "general-purpose"` でプロンプト内に役割を定義する。

### model の選び方

| 値 | モデル | 適した役割 |
|----|--------|-----------|
| `haiku` | claude-haiku-4-5 | 記録・転記・単純ファイル操作（context-manager 等） |
| `sonnet` | claude-sonnet-4-6 | 通常の調査・執筆・分析（デフォルト推奨） |
| `opus` | claude-opus-4-6 | 複雑な設計判断・最終品質レビュー |
| `inherit` | 親セッションと同じ | チーム全体で統一モデルを使いたい場合 |

---

## agents/*.md の本文構造（3-Phase）

全エージェントに **初期化 → フィードバック対応 → 最終化** の3フェーズ構造を持たせる。

```markdown
### Phase 1: 初期化
1. TaskList → TaskGet(blockedBy確認) → TaskUpdate(in_progress)
2. 初期作業を実行 → 関連エージェントに SendMessage

### Phase 2: フィードバック対応
- 実質的なフィードバックのみ返信（ACK 不要）
- ブロック中でも他エージェントの成果物にフィードバック可

### Phase 3: 最終化
1. TaskUpdate(status: "completed")  ← 先にブロック解除
2. → team-lead: タスク #N 完了。{成果物パス}

## コミュニケーションルール
- ACK 返信不要
- 2人以上から反応があれば次のフェーズに進む（全員を待たない）
```

各 Phase の詳細実装パターンは [references/phase-design.md](references/phase-design.md) を参照。

---

## ツール選択クイックリファレンス

### 許可リスト（tools）vs 禁止リスト（disallowedTools）

```yaml
# 推奨: tools で許可リストを明示（意図が明確）
tools: Read, Grep, Glob, WebSearch, SendMessage, TaskList, TaskGet, TaskUpdate

# 用途: 一部のツールだけ禁止したい場合
disallowedTools:
  - Bash
  - Write
```

### よくある tools の設定ミス

| 問題 | 原因 | 対策 |
|------|------|------|
| WebSearch が使えない | tools に未記載 | 調査系には明示的に追加 |
| ファイル書き込みができない | Write/Edit が未記載 | 執筆系には Write, Edit を追加 |
| タスクが見つからない | TaskList が未記載 | 全エージェントに必須 |
| 他エージェントに通信できない | SendMessage が未記載 | 全エージェントに必須 |
| コスト過多 | 全員 opus | 役割に合わせて haiku/sonnet を使う |

詳細は [references/tool-selection.md](references/tool-selection.md) を参照。

---

## コンテキストの渡し方

SubAgent は**親のコンテキストを持たない**。起動時のプロンプトが唯一の情報源。
以下を全て含めること（省略すると SubAgent が必要な情報を持てない）:

```
Task(
  subagent_type: "my-skill:researcher",
  name: "researcher",
  team_name: "my-skill",
  mode: "bypassPermissions",
  run_in_background: true,
  prompt: """
あなたは my-skill チームの researcher です。

## プロダクト情報           ← ユーザーからヒアリングした全情報（省略厳禁）
アプリ名: MyApp
カテゴリ: フィットネス
ターゲット: 30代男性

## コンテキスト
- ファイルパス: .claude/my-skill/20250222_myapp/
- チームメンバー:
  - architect: セグメント設計担当
  - writer: ペルソナ執筆担当
  - context-manager: ファイル I/O 専任

## 既存コンテキスト（前回セッションがある場合）
{context.md の内容をここに展開}

agents/researcher.md の手順に従って作業を開始してください。
"""
)
```

### よくある「コンテキストが渡らない」バグ

| 症状 | 原因 | 対策 |
|------|------|------|
| エージェントがプロダクト情報を知らない | プロンプトに含め忘れ | 全情報を展開する |
| 前回の作業が引き継がれない | context.md を渡し忘れ | 既存コンテキストセクションを追加 |
| チームメンバーを知らない | 構成情報がない | 全メンバーの名前と役割を記載 |
| ファイルパスを間違える | パスを省略 | 絶対パスで明示 |

詳細パターンは [references/context-patterns.md](references/context-patterns.md) を参照。

---

## よくあるアンチパターン

| 問題 | 原因 | 対策 |
|------|------|------|
| エージェントがタスクを見つけられない | owner 未設定 | TaskUpdate で必ず owner を設定 |
| 後続タスクが永遠に待機 | completed にし忘れ | Phase 3 に「completed にする」を明記 |
| 全員が停滞する | 全員を待ってから次へ | 「2人以上から反応があれば次へ」を明記 |
| ACK だけの返信が大量発生 | 「無視禁止」ルールを厳格適用 | 「実質的な返信のみ」に変更 |
| MCP ツールが使えない | agents/*.md で定義 | `general-purpose` に変更 |
| コンテキストが渡らない | プロンプトに情報を含め忘れ | チェックリストで必須項目を確認 |
| コストが高い | 全員 opus | 役割別に haiku/sonnet を使い分ける |
| エラーがデバッグできない | ログがない | PostToolUse Hook でログを有効化 |

詳細は [references/antipatterns.md](references/antipatterns.md) を参照。

---

## MCP ツールを使う場合の例外

MCP ツール（`mcp__pencil__*`, `mcp__devin__*` 等）は `agents/*.md` では使えない。

### 対処法: general-purpose で起動

```
Task(
  subagent_type: "general-purpose",   # ← agents/*.md を使わない
  team_name: "ui-design",
  name: "designer",
  mode: "bypassPermissions",
  run_in_background: true,
  prompt: """
あなたは designer として ui-design チームのデザイン担当です。

## 役割
mcp__pencil__batch_design を使って UI デザインを実装する。

## 作業手順
1. TaskList で自分のタスク（owner: designer）を確認
2. TaskUpdate で in_progress に変更
...（通常のエージェント手順）
"""
)
```

`general-purpose` では全設定（role, tools, model）をプロンプト内で定義する必要がある。

---

## 詳細リファレンス

トピック別に分離。必要なファイルだけ Read する:

- **フル実装テンプレート + 役割別実例**: [references/agent-template.md](references/agent-template.md)
  - コピーして使える agents/*.md テンプレート
  - researcher / writer / reviewer / context-manager の実例
  - frontmatter 全フィールド解説

- **ツール選択マトリクス（詳細版）**: [references/tool-selection.md](references/tool-selection.md)
  - 各ツールの用途・制約
  - MCP 使用時の回避策パターン
  - Bash 使用可否の判断基準

- **コンテキスト渡し・永続化パターン**: [references/context-patterns.md](references/context-patterns.md)
  - プロンプト構造テンプレート
  - コンテキストファイル設計（.claude/{skill}/{date}_{project}/）
  - context-manager エージェント専用パターン
  - セッション跨ぎの知識永続化

- **3-Phase 詳細設計**: [references/phase-design.md](references/phase-design.md)
  - 各 Phase でやるべきこと・やってはいけないこと
  - 早期フィードバックパターン（ブロック中でも貢献）
  - 「待ちすぎない」実装パターン

- **アンチパターン集**: [references/antipatterns.md](references/antipatterns.md)
  - 症状 / 原因 / Before / After の形式で 10〜15 件
  - agents/*.md 定義固有の失敗パターン
