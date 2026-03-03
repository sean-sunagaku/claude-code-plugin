---
name: team-implement
description: >
  承認済みの実装計画（Plan）を Agent Team で並列に実装するスキル。
  Plan をタスクに分割 → 依存関係を設定 → Wave ごとに並列エージェントを起動 →
  完了を待って次の Wave → 最後にビルド＆テスト検証。
  team-plan スキル（調査→計画）の後に使う「実装実行フェーズ」。
  Use when: 計画を並列に実装したい、チームで実装を進めたい、
  Wave 実行で効率よくコードを書きたい。
  Triggers: "team implement", "チームで実装", "並列実装",
  "plan を実装して", "wave 実行", "team-implement",
  "エージェントで実装", "実装フェーズ", "implement the plan"
---

# Team Implement

承認済みの実装計画を **Agent Team (TeamCreate + TaskCreate) で並列に実装**するスキル。

```
Plan 読み込み
  → タスク分解 + 依存関係 + Wave 構成
  → ユーザー承認
  → TeamCreate + TaskCreate
  → Wave ごとに並列エージェント起動（background）
  → 完了した Wave の依存解消 → 次の Wave 起動
  → ビルド＆テスト検証
  → 最終レポート + クリーンアップ
```

---

## Step 1: Plan の読み込みと確認

### Plan ファイルの特定

以下の優先順位で Plan を探す:

1. **ARGUMENTS にパスが指定されている場合**: そのパスを Read
2. **指定がない場合**: `.claude/plans/` ディレクトリから最新の `.md` ファイルを自動検出

```bash
# .claude/plans/ から最新ファイルを探す
ls -t .claude/plans/*.md | head -1
```

### Plan の内容確認

Plan を Read し、以下を抽出する:

- **変更対象ファイル一覧**: 各ファイルのパスと変更内容
- **実装ステップ**: 順序付きの実装手順
- **依存関係**: ステップ間の前後関係
- **テスト計画**: 実行すべきテストコマンド

Plan が見つからない、または承認済みか不明な場合はユーザーに確認する。

---

## Step 2: タスク分解と Wave 構成

Plan の実装ステップを **独立して並列実行できるタスク群** に分解する。

### 分解の原則

1. **ファイルの競合を避ける**: 同じファイルを変更するステップは同一タスクにまとめるか、依存関係を設定
2. **論理的なまとまり**: モデル変更、UI変更、バックエンド変更、テスト、翻訳など、ドメインごとにグループ化
3. **依存の最小化**: 並列度を最大化するために、不要な依存を作らない
4. **ビルド＆テストは最後**: 全コード変更タスクの後に置く

### Wave 構成の設計

タスクを依存関係に基づいて Wave（同時実行グループ）に分ける:

```
Wave 1: 依存なし（全て並列実行可能）
  例: モデル変更、バックエンド変更、翻訳ファイル更新

Wave 2: Wave 1 の完了に依存
  例: UI 変更（モデル変更に依存）、テスト（バックエンド変更に依存）

Wave 3: Wave 2 の完了に依存
  例: ビルド＆テスト検証
```

### ユーザーへの提示と承認

タスク分解結果を以下の形式でユーザーに提示し、AskUserQuestion で承認を得る:

```
## タスク分解案

### Wave 1（並列）
- Task 1: {タスク名} — {変更ファイル一覧} — {概要}
- Task 2: {タスク名} — {変更ファイル一覧} — {概要}

### Wave 2（Wave 1 完了後）
- Task 3: {タスク名} — 依存: Task 1 — {概要}

### Wave 3（最終検証）
- Task 4: ビルド＆テスト — 依存: Task 2, 3

合計: N タスク / M Wave / 推定エージェント数: X 体
```

---

## Step 3: コンテキスト収集

**承認後**、各タスクで変更するファイルを全て Read して文脈を収集する。
これはエージェントのプロンプトに含める**現在のファイル内容**として使う。

### 収集手順

1. Plan の「変更対象ファイル一覧」から全ファイルパスを抽出
2. 各ファイルを Read（並列可）
3. 大きなファイルは変更箇所周辺のみ抽出（offset + limit）
4. ファイル間の import/依存関係も確認（Grep で import 文を検索）

### 重要: エージェントプロンプトの品質はコンテキストで決まる

エージェントが高品質な変更を行うには、**現在のコードの正確な状態**が必要。
ファイルの Read を省略すると、エージェントが既存コードと整合しない変更を行うリスクがある。

---

## Step 4: チーム作成とエージェント起動

### 4a: TeamCreate

```
TeamCreate(
  team_name: "implement-{plan名の短縮形}",
  description: "Plan '{plan名}' の並列実装"
)
```

### 4b: TaskCreate（全タスク一括）

Step 2 で承認されたタスク分解に基づき、TaskCreate を実行。

```
# 例: 3タスク + ビルド検証
TaskCreate(subject: "Task 1: モデル変更", description: "...", activeForm: "モデルを変更中")
TaskCreate(subject: "Task 2: バックエンド変更", description: "...", activeForm: "バックエンドを変更中")
TaskCreate(subject: "Task 3: UI変更", description: "...", activeForm: "UIを変更中")
TaskCreate(subject: "Task 4: ビルド＆テスト", description: "...", activeForm: "ビルド＆テスト実行中")

# 依存関係の設定
TaskUpdate(taskId: "3", addBlockedBy: ["1"])  # UI は モデル完了後
TaskUpdate(taskId: "4", addBlockedBy: ["2", "3"])  # ビルドは全コード完了後
```

### 4c: Wave 1 エージェント起動

依存なし（blockedBy が空）のタスクを **1つのメッセージで全て並列に** 起動する。

```
# 全エージェントを同じメッセージ内で並列起動すること（逐次起動は禁止）
Task(
  name: "task-1-model",
  subagent_type: "general-purpose",
  team_name: "implement-xxx",
  mode: "bypassPermissions",
  run_in_background: true,
  prompt: "{詳細プロンプト}"
)

Task(
  name: "task-2-backend",
  subagent_type: "general-purpose",
  team_name: "implement-xxx",
  mode: "bypassPermissions",
  run_in_background: true,
  prompt: "{詳細プロンプト}"
)
```

---

## Step 5: エージェントプロンプトの構造

各エージェントのプロンプトは以下の構造で作成する。**具体的であるほど品質が上がる。**

```markdown
あなたは実装エージェントです。以下のタスクを実行してください。

## タスク概要
{何を実装するかの概要}

## 変更対象ファイル

### {ファイルパス1}
**現在の内容（関連部分）:**
```{言語}
{Read で取得した現在のコード}
```

**変更内容:**
- {具体的に何を変えるか}
- {追加するコード/削除するコード}

### {ファイルパス2}
...（同じ構造）

## 実装ルール
- Edit ツールで既存ファイルを変更すること（Write での全書き換えは避ける）
- 変更前に必ず Read でファイルの最新内容を確認すること
- 変更対象外のコードには一切手を加えないこと
- インデント・命名規則は既存コードに合わせること

## 完了条件
- 全ファイルの変更が完了していること
- 変更後のコードに構文エラーがないこと

## 完了時の報告
タスク完了後、以下を報告してください:
1. 変更したファイルの一覧
2. 各ファイルで行った変更の概要
3. 注意点や懸念事項（あれば）
```

### プロンプト品質チェックリスト

- [ ] 変更対象ファイルの**現在のコード**がプロンプトに含まれているか
- [ ] 変更内容が**コードレベルで具体的**か（「適切に修正」のような曖昧な指示はNG）
- [ ] 変更**しない**箇所が明確か
- [ ] 既存コードの命名規則・パターンが示されているか
- [ ] 完了条件が明確か

---

## Step 6: Wave 実行の監視と進行

### 完了の検知

バックグラウンドエージェントの完了は自動通知される。完了時:

1. TaskUpdate で該当タスクを `completed` に更新
2. TaskList で残タスクと依存状態を確認
3. 新たに blockedBy が空になったタスクがあれば、次の Wave として起動

### 次の Wave の起動

```
# TaskList で確認
TaskList()

# blockedBy が全て completed のタスクを見つけて起動
Task(
  name: "task-3-ui",
  subagent_type: "general-purpose",
  team_name: "implement-xxx",
  mode: "bypassPermissions",
  run_in_background: true,
  prompt: "{詳細プロンプト}"
)
```

### エラー時の対応

エージェントがエラーを報告した場合:

1. エラー内容を確認
2. **軽微な修正**: 新しいエージェントを起動して修正タスクを割り当て
3. **設計レベルの問題**: ユーザーに報告し、計画の修正を相談
4. **依存タスクへの影響**: 依存タスクの起動を保留し、修正完了後に再開

---

## Step 7: ビルド＆テスト検証

全コード変更タスクの完了後、ビルドとテストを実行する。

### ビルド＆テストコマンドの検出

Plan に記載されていればそれを使う。なければ以下で自動検出:

```bash
# package.json の scripts を確認
cat package.json | grep -E '"(build|test|lint)"'

# よくあるパターン
# - npm run build / npm test
# - cd functions && npm run build && npm test
# - npx tsc --noEmit
```

### 実行方法

ビルド＆テストも TeamCreate で作成したチームの一員として起動する:

```
Task(
  name: "build-verify",
  subagent_type: "general-purpose",
  team_name: "implement-xxx",
  mode: "bypassPermissions",
  run_in_background: true,
  prompt: "以下のコマンドを順番に実行し、結果を報告してください:
    {コマンド1}
    {コマンド2}
  成功/失敗の判定と、失敗時はエラー内容の全文を含めてください。"
)
```

### テスト失敗時

1. 失敗したテストの内容を確認
2. 原因を分析（エージェントの変更が原因か、既存の問題か）
3. **チーム内で**修正エージェントを起動して修正
4. 再度ビルド＆テストを実行（同じチーム内で新タスクとして追加）
5. 通過するまで繰り返す（最大3回。それ以上はユーザーに相談）

```
# テスト失敗時の修正フロー
TaskCreate(subject: "Fix: テスト失敗の修正", description: "...", activeForm: "テスト失敗を修正中")
Task(
  name: "fix-test-failure",
  subagent_type: "general-purpose",
  team_name: "implement-xxx",
  mode: "bypassPermissions",
  run_in_background: true,
  prompt: "{失敗内容と修正指示}"
)
```

---

## Step 8: 最終レポートとクリーンアップ

### 最終レポート

全タスク完了後、ユーザーに以下を報告:

```markdown
## 実装完了レポート

### 変更ファイル一覧
| ファイル | 変更内容 | タスク |
|---------|---------|-------|
| {パス} | {概要} | Task N |

### ビルド＆テスト結果
- ビルド: {成功/失敗}
- テスト: {X passed, Y failed}

### 注意事項
- {エージェントから報告された懸念点}

### 次のアクション
- {必要な追加作業があれば}
```

### クリーンアップ

```
# 1. 全エージェントに shutdown_request
SendMessage(type: "shutdown_request", recipient: "task-1-model", content: "実装完了")
SendMessage(type: "shutdown_request", recipient: "task-2-backend", content: "実装完了")
...

# 2. 全員シャットダウン後にチーム削除
TeamDelete()
```

---

## 注意事項

### 並列起動の徹底
同一 Wave のエージェントは**必ず1つのメッセージ内で全て同時に**起動する。
逐次起動は非効率であり禁止。

### エージェント数の目安
- **2〜4 タスク**: そのまま1エージェント/タスク
- **5〜8 タスク**: 関連タスクを統合して 3〜5 エージェントに
- **9 タスク以上**: 3〜4 Wave に分割し、各 Wave 2〜4 エージェント

### コスト意識
- 各エージェントはコンテキストウィンドウ全体を消費する
- プロンプトは必要十分な長さに（余分なファイルを含めない）
- 小さなタスク（1ファイル数行の変更）はエージェントに出さず自分で実行する

### agent-team スキルとの使い分け
- **agent-team**: 汎用的なチーム構築。設計パターンの選択から始まる
- **team-implement**: Plan ありきの実装実行。タスク分解→Wave実行に特化

### team-plan との連携
```
team-plan（調査→計画→承認）→ team-implement（実装→検証→完了）
```
team-plan で作成された Plan ファイルをそのまま入力として使える。
