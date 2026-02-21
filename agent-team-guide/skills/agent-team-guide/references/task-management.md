# タスク管理パターン

## タスク作成と依存関係

### 基本パターン: 段階的依存

```
Task 1: 初期化（依存なし）           ← context-manager
Task 2: 設計（blockedBy: ["1"]）     ← architect
Task 3: 調査（blockedBy: ["1"]）     ← researcher（Task 2 と並列！）
Task 4: 実装（blockedBy: ["2", "3"]）← writer
Task 5: レビュー（blockedBy: ["4"]） ← reviewer
Task 6: 統合レポート（blockedBy: ["1","2","3","4","5"]）← team-lead
```

**ポイント**: 並列可能なタスクは依存を切る。Task 2 と Task 3 は独立なので並列実行。

### TaskCreate のベストプラクティス

```
TaskCreate(
  subject: "セグメント設計・ペルソナフレームワーク策定",     # 命令形で具体的に
  description: "プロダクト情報からユーザーセグメントを3〜5定義し、
    ペルソナフレームワーク（属性体系）を設計する。
    成果物: round-01/segments.md",                         # 成果物を明記
  activeForm: "セグメント設計中"                            # 進行中の表示テキスト
)
```

**subject**: 命令形で、何をするか具体的に書く（"設計" ではなく "セグメント設計・ペルソナフレームワーク策定"）
**description**: エージェントがタスク詳細を読んで理解できるレベル。成果物のファイルパスも含める
**activeForm**: 進行中スピナーに表示されるテキスト。「〜中」の形（"セグメント設計中"）

### タスク作成→依存設定→オーナー設定

**1つのメッセージで全タスク作成**:

```
TaskCreate({ subject: "コンテキストファイル初期化", description: "...", activeForm: "初期化中" })
TaskCreate({ subject: "セグメント設計", description: "...", activeForm: "セグメント設計中" })
TaskCreate({ subject: "市場リサーチ", description: "...", activeForm: "市場リサーチ中" })
TaskCreate({ subject: "ペルソナ執筆", description: "...", activeForm: "ペルソナ執筆中" })
TaskCreate({ subject: "バイアスレビュー", description: "...", activeForm: "バイアスレビュー中" })
TaskCreate({ subject: "統合レポート作成", description: "...", activeForm: "レポート作成中" })
```

**次のメッセージで依存関係とオーナーを設定**:

```
TaskUpdate({ taskId: "1", owner: "context-manager" })
TaskUpdate({ taskId: "2", owner: "persona-architect", addBlockedBy: ["1"] })
TaskUpdate({ taskId: "3", owner: "user-researcher", addBlockedBy: ["1"] })
TaskUpdate({ taskId: "4", owner: "persona-writer", addBlockedBy: ["2", "3"] })
TaskUpdate({ taskId: "5", owner: "bias-reviewer", addBlockedBy: ["4"] })
TaskUpdate({ taskId: "6", owner: "team-lead", addBlockedBy: ["1","2","3","4","5"] })
```

**なぜ 2 ステップ**: TaskCreate の戻り値で taskId が確定してから addBlockedBy を設定する。

## エージェント側のタスク操作

各エージェントは以下の手順でタスクを処理:

```
1. TaskList → 自分のタスクを見つける（owner が自分のもの）
2. TaskGet(taskId) → 詳細を読む
3. blockedBy が空か確認。空でなければ「待機中も他のフィードバックは受け付ける」
4. TaskUpdate(taskId, status: "in_progress")
5. 作業実行
6. TaskUpdate(taskId, status: "completed")
7. SendMessage で team-lead に完了報告
8. TaskList → 次のタスクがあるか確認
```

**重要**: ステップ 7 の完了報告を忘れるとリーダーが進捗を把握できない。

## 早期フィードバックの設計

タスクの公式な依存関係とは別に、エージェントが「待機中でも」フィードバック可能にする。
**これが品質を最も向上させるパターン**。

### 具体例（persona-creation での実績）

```markdown
## 作業手順（bias-reviewer の例）
1. タスク #5 は #4（ペルソナ執筆）完了待ち
2. ただし、persona-architect からセグメント設計が共有されたら:
   - 待機中でもセグメントのバイアスをチェック
   - 問題があれば即座にフィードバックを送る
3. → 後工程の手戻りを事前に防げる
```

### 早期フィードバックの書き方（エージェント定義内）

```markdown
### Phase 2: フィードバック対応（待機中も含む）
- 自分のタスクが blockedBy で待機中でも、以下のメッセージにはフィードバックを返す:
  - {agent-a} からの {成果物名}
  - {agent-b} からの {成果物名}
- フィードバックは `→ {agent-name}: {具体的指摘}` の形式で送る
```

## よくある失敗パターン

| 失敗 | 原因 | 対策 |
|------|------|------|
| 全タスクが直列 | 過剰な依存関係 | 並列可能なタスクの依存を外す |
| エージェントがタスクを見つけられない | owner 未設定 | TaskUpdate で必ず owner を設定 |
| blockedBy が解除されない | 前タスクが completed にならない | エージェント定義に「completed にする」手順を明記 |
| リーダーのタスクだけ残る | 完了通知なし | エージェントに「完了時 team-lead に SendMessage」を指示 |
| タスク description が空 | TaskCreate 時に省略 | description に成果物・アクション・ファイルパスを含める |
| activeForm が未設定 | TaskCreate 時に省略 | 「〜中」の形で進行状態を表示する |
