# ツール選択マトリクス＋MCP対応

## 目次
1. [ツール選択マトリクス（詳細版）](#ツール選択マトリクス詳細版)
2. [各ツールの用途と制約](#各ツールの用途と制約)
3. [MCP 使用時の回避策パターン](#mcp-使用時の回避策パターン)
4. [Bash 使用可否の判断基準](#bash-使用可否の判断基準)
5. [disallowedTools の活用法](#disallowedtools-の活用法)

---

## ツール選択マトリクス（詳細版）

### 役割タイプ別の推奨セット

| 役割タイプ | 必須 | 追加 | 除外推奨 |
|-----------|------|------|---------|
| 調査系 | Read, Grep, Glob, SendMessage, TaskList, TaskGet, TaskUpdate | WebSearch, WebFetch | Write, Edit, Bash |
| 執筆系 | Read, Grep, Glob, Write, Edit, SendMessage, TaskList, TaskGet, TaskUpdate | — | Bash, WebSearch |
| 実行系 | Read, Grep, Glob, Write, Edit, Bash, SendMessage, TaskList, TaskGet, TaskUpdate | — | — |
| 分析系（読み取り専用） | Read, Grep, Glob, SendMessage, TaskList, TaskGet, TaskUpdate | — | Write, Edit, Bash, WebSearch |
| コンテキスト管理専任 | Read, Write, Edit, SendMessage, TaskList, TaskGet, TaskUpdate | — | Bash, WebSearch, Grep, Glob |
| 品質レビュー | Read, Grep, Glob, SendMessage, TaskList, TaskGet, TaskUpdate | — | Write, Edit, Bash |
| MCP 使用 | general-purpose で起動（agents/*.md 不可） | — | — |

### チーム通信・タスク管理（全エージェント必須）

```yaml
# 省略すると協調動作できない
SendMessage   # エージェント間通信
TaskList      # タスク一覧確認
TaskGet       # タスク詳細取得
TaskUpdate    # タスク状態更新（in_progress / completed）
```

`TaskCreate` は通常リーダーが担当するため、個別エージェントには不要。
動的にサブタスクを作成する設計の場合のみ追加する。

---

## 各ツールの用途と制約

### 読み取り系

| ツール | 用途 | 制約 |
|--------|------|------|
| `Read` | ファイル内容の読み取り | ディレクトリは読めない（ls は Bash または Glob） |
| `Grep` | ファイル内の文字列検索 | `grep`/`rg` コマンドより高精度 |
| `Glob` | ファイル名パターン検索 | `find` コマンドの代替 |
| `WebSearch` | Web 検索 | 外部ネットワーク接続が必要 |
| `WebFetch` | URL のコンテンツ取得 | HTML を Markdown に変換して返す |

### 書き込み系

| ツール | 用途 | 制約 |
|--------|------|------|
| `Write` | ファイルの新規作成・上書き | 既存ファイルを上書きするので注意 |
| `Edit` | ファイルの部分編集 | 編集前に Read が必要 |

### 実行系

| ツール | 用途 | 制約 |
|--------|------|------|
| `Bash` | シェルコマンド実行 | セキュリティリスクあり（後述の判断基準参照） |

### 通信・タスク系

| ツール | 用途 | 制約 |
|--------|------|------|
| `SendMessage` | エージェント間メッセージ送信 | チームに参加していないと送受信できない |
| `TaskList` | 全タスク一覧取得 | チーム全体のタスクが見える |
| `TaskGet` | 特定タスクの詳細取得 | taskId が必要 |
| `TaskUpdate` | タスク状態・属性の更新 | status, owner, addBlockedBy 等 |
| `TaskCreate` | 新規タスクの作成 | 通常はリーダーが使用 |

---

## MCP 使用時の回避策パターン

### 制約の理解

`agents/*.md` で定義した SubAgent は MCP ツールにアクセスできない:

```yaml
# BAD: agents/designer.md に書いても動作しない
---
name: designer
tools: mcp__pencil__batch_design  # ← 効果なし
---
```

### 解決策: general-purpose で起動

```
Task(
  subagent_type: "general-purpose",  # agents/*.md を使わない
  team_name: "ui-design",
  name: "designer",
  mode: "bypassPermissions",
  run_in_background: true,
  prompt: """
あなたは designer として ui-design チームのデザイン担当です。

## 役割
mcp__pencil__batch_design と mcp__pencil__batch_get を使って
UI デザインを Pencil (.pen ファイル) に実装する。

## 作業手順

### Phase 1: 初期化
1. TaskList で owner: designer のタスクを確認
2. TaskUpdate で in_progress に変更
3. mcp__pencil__get_editor_state で現在のエディタ状態を確認

### Phase 2: デザイン実装
4. mcp__pencil__batch_get でコンポーネントを確認
5. mcp__pencil__batch_design でデザインを実装
6. mcp__pencil__get_screenshot でビジュアル確認
7. → reviewer: デザイン実装完了。レビューお願いします。

### Phase 3: 完了
8. TaskUpdate(status: "completed")
9. → team-lead: タスク完了。デザイン実装しました。

## コミュニケーションルール
- ACK 不要
- デザイン変更後は必ずスクリーンショットで確認
"""
)
```

### general-purpose を使う場合の注意

- 全設定（role, tools, model）をプロンプト内で定義する
- 利用可能な MCP ツールは起動環境で有効なものが全て使える
- `agents/*.md` の再利用性がなくなるため、一般的な定義は agents/*.md に残す

---

## Bash 使用可否の判断基準

### Bash を使うべき場面

```yaml
tools: ..., Bash, ...
```

- スクリプト実行（Python, Node.js 等）
- パッケージ管理（npm install, pip install）
- テスト実行（pytest, jest）
- ビルド処理
- ディレクトリ作成（`mkdir -p`）
- ファイル一覧（`ls`）—— ただし Glob で代替できることが多い

### Bash を避けるべき場面

```yaml
# 以下は専用ツールで代替できる
# grep/rg → Grep ツール
# find → Glob ツール
# cat/head/tail → Read ツール
# sed/awk → Edit ツール
```

調査系・執筆系エージェントに Bash を付与すると:
- セキュリティリスクが増える
- 不要なシステム操作が起きる可能性がある
- 専用ツールの方が Claude の意図通りに動作する

### Bash が必要かの判断フロー

```
シェルコマンドが必要？
├── Yes: 専用ツールで代替できる？
│         ├── Yes → 専用ツールを使う（Read/Write/Edit/Grep/Glob）
│         └── No  → Bash を追加
└── No → Bash は不要
```

---

## disallowedTools の活用法

`tools`（許可リスト）と `disallowedTools`（禁止リスト）の使い分け:

```yaml
# 方法 1: tools で許可リストを明示（推奨）
# 意図が明確で、余計なツールを渡さない
tools: Read, Grep, Glob, WebSearch, SendMessage, TaskList, TaskGet, TaskUpdate

# 方法 2: disallowedTools で一部だけ禁止
# 既存設定の一部を制限したい場合に有効
disallowedTools:
  - Bash
  - Write
```

### disallowedTools が有効な場面

- `settings.json` で全体的にツールを許可しているが、特定エージェントだけ制限したい
- `general-purpose` で起動するが、Bash だけは禁止したい

```yaml
# general-purpose エージェントで Write を禁止する例
# （読み取り専用の調査エージェントとして使う）
---
name: read-only-analyst
disallowedTools:
  - Write
  - Edit
  - Bash
---
```
