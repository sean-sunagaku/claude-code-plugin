# コンテキスト渡し・永続化パターン

## 目次
1. [プロンプト構造テンプレート](#プロンプト構造テンプレート)
2. [コンテキストファイル設計](#コンテキストファイル設計)
3. [context-manager エージェント専用パターン](#context-manager-エージェント専用パターン)
4. [セッション跨ぎの知識永続化](#セッション跨ぎの知識永続化)
5. [よくある「コンテキストが渡らない」バグ](#よくあるコンテキストが渡らないバグ)

---

## プロンプト構造テンプレート

SubAgent は親のコンテキストを持たない。Task() の prompt が唯一の情報源。

### 完全版プロンプトテンプレート

```
あなたは {team-name} チームの {role-name} です。

## プロダクト情報
{ユーザーからヒアリングした全情報を展開}
例:
- アプリ名: MyApp
- カテゴリ: フィットネス
- ターゲットユーザー: 30代男性
- 主な機能: 運動記録、カロリー計算
- 競合: Strava, Nike Run Club
- 差別化ポイント: AI パーソナルコーチング

## コンテキスト
- ファイルパス: {絶対パス}/.claude/{skill-name}/{YYYYMMDD}_{project-slug}/
- チームメンバー:
  - {agent-a}: {役割の1行説明}
  - {agent-b}: {役割の1行説明}
  - context-manager: ファイル I/O 専任
  - team-lead: 最終報告先

## 既存コンテキスト（前回セッションがある場合）
{context.md の内容をここに展開}
※ 前回セッションがない場合はこのセクションを省略

agents/{role-name}.md の手順に従って作業を開始してください。
```

### 必須セクションのチェックリスト

- [ ] プロダクト情報（ユーザーからヒアリングした全情報）
- [ ] コンテキストファイルパス（絶対パス）
- [ ] チームメンバーの名前と役割
- [ ] 既存コンテキスト（前回セッションがある場合）
- [ ] 参照するエージェント定義ファイル

---

## コンテキストファイル設計

### 推奨ディレクトリ構成

```
{project}/.claude/{skill-name}/{YYYYMMDD}_{project-slug}/
├── context.md              ← 状態サマリー（最新状態を常に反映）
├── round-01/               ← ラウンド別の作業ファイル
│   ├── research.md
│   ├── segments.md
│   └── personas/
│       ├── persona-01.md
│       └── persona-02.md
├── round-02/               ← フィードバック反映後
│   └── personas/
└── final/                  ← 最終成果物
    └── report.md
```

### context.md の構造

```markdown
# {スキル名} - {プロジェクト名} コンテキスト

## 最終更新: {YYYY-MM-DD HH:MM}

## プロジェクト情報
- アプリ名: {name}
- 作業開始: {date}
- ステータス: {active / paused / completed}

## 完了済みタスク
- [x] 市場調査（round-01/research.md）
- [x] セグメント設計（round-01/segments.md）
- [ ] ペルソナ執筆（進行中）

## 現在のフェーズ
{何をやっている最中か}

## 次のステップ
1. {次にやること}
2. {その次}

## 重要な決定事項
- {決定事項1}: {理由}
- {決定事項2}: {理由}

## ファイル一覧
- round-01/research.md: 競合調査結果
- round-01/segments.md: 3つのユーザーセグメント定義
```

### context.md を更新するタイミング

1. 各タスク完了時（context-manager が更新）
2. 重要な決定が行われた時
3. フェーズ移行時（round-01 → round-02 等）

---

## context-manager エージェント専用パターン

### 設計原則

context-manager は**ファイル I/O の唯一の書き込み専任**。
複数エージェントが同時に同じファイルに書き込むと競合が発生するため、
全書き込みを context-manager に集約する。

### context-manager への依頼パターン

```
# 各エージェントからの依頼形式:
→ context-manager: round-01/research.md に以下を記録してください:
  [記録内容]

→ context-manager: context.md を以下の内容で更新してください:
  - 完了済みタスクに「市場調査」を追加
  - 現在のフェーズを「セグメント設計中」に変更
```

### context-manager の応答パターン

```
# 記録完了後:
researcher に返信:
記録しました: .claude/{skill}/{date}/round-01/research.md

# context.md 更新後:
persona-architect に返信:
context.md を更新しました。完了済み: 市場調査。現フェーズ: セグメント設計中。
```

### context-manager が直接書き込むファイルの例

```python
# Phase 1 での初期化
ディレクトリ作成:
  .claude/{skill}/{date}_{project}/
  .claude/{skill}/{date}_{project}/round-01/
  .claude/{skill}/{date}_{project}/final/

context.md 初期化:
  # {skill-name} - {project-name} コンテキスト
  ## ステータス: active
  ## 開始日: {today}
```

---

## セッション跨ぎの知識永続化

### セッション A → B の引き継ぎフロー

```
セッション A:
1. エージェントが作業を完了
2. context-manager が context.md に全成果物のパスとサマリーを記録
3. context.md の最終状態がセッション B へのインプットになる

セッション B:
1. リーダーが context.md を Read
2. 前回の状態を把握
3. 各エージェント起動時のプロンプトに context.md の内容を展開
4. エージェントが前回の続きから作業開始
```

### リーダーの context.md 読み込みパターン

```python
# SKILL.md での実装例

# 既存コンテキストを確認
import os
context_dir = f".claude/{skill_name}"
latest = get_latest_session(context_dir)  # 最新セッションディレクトリを取得

if latest:
    context = Read(f"{latest}/context.md")
    existing_context = f"## 既存コンテキスト\n{context}"
else:
    existing_context = ""

# エージェント起動プロンプトに既存コンテキストを含める
Task(
  prompt: f"""
...
{existing_context}
...
"""
)
```

### 永続化すべき情報

| 情報タイプ | 場所 | 理由 |
|-----------|------|------|
| 完了タスクの一覧 | context.md | 次回の重複作業を防ぐ |
| 成果物ファイルのパス | context.md | 次回エージェントが参照できる |
| 重要な決定事項 | context.md | 前回の判断を再現できる |
| 実際の成果物データ | round-XX/*.md | 次回エージェントが Read できる |
| ユーザーのフィードバック | context.md | 修正方針を引き継げる |

---

## よくある「コンテキストが渡らない」バグ

### バグ 1: プロダクト情報の省略

**症状**: エージェントが「プロダクト情報がありません」とエラーを返す

```
# BAD: プロダクト情報なし
Task(prompt: "agents/researcher.md の手順に従ってください")

# GOOD: 全情報を展開
Task(prompt: """
あなたは app-naming チームの researcher です。

## プロダクト情報
アプリ名: MyApp
カテゴリ: フィットネス
ターゲット: 30代男性
...

agents/researcher.md の手順に従ってください。
""")
```

### バグ 2: コンテキストファイルパスの省略

**症状**: エージェントが作成したファイルの場所が不明で、他エージェントが参照できない

```
# BAD: パスなし
Task(prompt: "調査結果をファイルに保存してください")

# GOOD: 絶対パスを指定
Task(prompt: """
## コンテキスト
- ファイルパス: /Users/user/project/.claude/app-naming/20250222_myapp/
- 調査結果は round-01/research.md に保存してください
""")
```

### バグ 3: チームメンバー構成の省略

**症状**: エージェントが他エージェントに SendMessage できない（宛先不明）

```
# BAD: チーム構成なし
Task(prompt: "調査完了後に結果を共有してください")

# GOOD: 全メンバーと役割を記載
Task(prompt: """
## チームメンバー
- architect: セグメント設計担当（調査結果を送る先）
- writer: ペルソナ執筆担当
- context-manager: ファイル記録専任
- team-lead: 完了報告先
""")
```

### バグ 4: 前回セッションのコンテキスト未引き継ぎ

**症状**: 前回やった調査を再度実施してしまう

```
# BAD: 既存コンテキスト未読
Task(prompt: "新規プロジェクトとして作業してください")

# GOOD: 既存コンテキストを展開
context = Read(".claude/app-naming/20250221_myapp/context.md")
Task(prompt: f"""
## 既存コンテキスト（前回セッション）
{context}

前回の続きから作業してください。
""")
```

### バグ 5: context.md の更新忘れ

**症状**: セッション B でセッション A の成果物がどこにあるかわからない

```
# 対策: context-manager の Phase 1 に初期化を必須化
## Phase 1: 初期化
1. TaskList でタスクを確認
2. コンテキストディレクトリを作成
3. context.md を初期化（テンプレートに従って）
4. → team-lead: 初期化完了。{パス}

# 対策: 各エージェントの Phase 3 に記録依頼を必須化
## Phase 3: 最終化
8. → context-manager: {ファイルパス}を context.md の完了リストに追加してください
9. TaskUpdate(status: "completed")
10. → team-lead: 完了報告
```
