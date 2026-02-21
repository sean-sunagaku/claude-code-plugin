# 3-Phase 詳細設計パターン

## 目次
1. [Phase 1: 初期化の詳細](#phase-1-初期化の詳細)
2. [Phase 2: フィードバック対応の詳細](#phase-2-フィードバック対応の詳細)
3. [Phase 3: 最終化の詳細](#phase-3-最終化の詳細)
4. [早期フィードバックパターン](#早期フィードバックパターン)
5. [「待ちすぎない」実装パターン](#待ちすぎない実装パターン)
6. [各 Phase でやってはいけないこと](#各-phase-でやってはいけないこと)

---

## Phase 1: 初期化の詳細

### 必須ステップの順序

```markdown
### Phase 1: 初期化
1. TaskList で自分のタスクを探す（owner が自分の名前のもの）
2. TaskGet(taskId) でタスク詳細・blockedBy を確認
3. blockedBy が空になっているか確認（空でなければ前タスクの完了を待つ）
4. TaskUpdate(taskId, status: "in_progress") でタスクを開始
5. {役割固有の初期作業}
6. 関連エージェントに SendMessage で共有・依頼
```

### TaskList でタスクを見つける方法

```
TaskList の結果例:
#1 [completed] コンテキスト初期化 (context-manager)
#2 [in_progress] セグメント設計 (persona-architect)     ← 自分がこれ
#3 [pending] 市場調査 (user-researcher)
#4 [pending] ペルソナ執筆 (persona-writer) [blocked by #2, #3]

自分が persona-architect なら:
→ owner が "persona-architect" のタスク #2 を見つける
→ TaskGet(taskId: "2") で詳細を確認
→ blockedBy が空（タスク #1 は completed）なので開始できる
```

### blockedBy の確認

```
# blockedBy が残っている場合:
TaskGet で blockedBy を確認:
  blockedBy: ["1"]  ← まだブロックされている

対応:
1. 前タスクの完了を待つ（ポーリングよりも SendMessage で確認）
2. → context-manager: タスク #1 はまだ完了していますか？
3. ブロック中でも Phase 2 のフィードバック受け付けは行う（後述）
```

### Phase 1 の完了基準

- [ ] 自分のタスクを `in_progress` に更新した
- [ ] 初期作業を実行した
- [ ] 関連エージェントに依頼を送った
- [ ] context-manager にファイル記録を依頼した（必要な場合）

---

## Phase 2: フィードバック対応の詳細

### 返信すべき時 vs しなくてよい時

| 返信すべき | 返信不要 |
|-----------|---------|
| フィードバックがある | 「了解しました」だけ |
| 修正指摘がある | 「受け取りました」だけ |
| 質問がある | 内容に異論がなく次のアクションもない |
| 修正完了の報告（変更内容あり） | 単なる進捗確認への応答 |
| 緊急の問題発見 | 情報を受け取っただけで作業が変わらない |

### フィードバックの返信テンプレート

```
# フィードバックを送る場合:
→ {agent-name}:
  **問題点**: {具体的な問題}
  **提案**: {具体的な改善案}
  修正後に再共有してください。

# 修正完了を報告する場合:
→ {agent-name}:
  ご指摘の {修正点} を反映しました。
  変更内容: {Before} → {After}
  再確認をお願いします。
```

### フィードバックを名指しで送る

```
# BAD: 宛先不明
「フィードバックをください」

# GOOD: 名指しで具体的に
→ bias-reviewer: ペルソナ01の職業描写にバイアスがないか確認してください。
→ persona-architect: セグメント設計でこの属性は考慮済みですか？
```

---

## Phase 3: 最終化の詳細

### 必須ステップの順序

```markdown
### Phase 3: 最終化
N-1. → context-manager: {成果物パス}を context.md の完了リストに追加してください
N.   TaskUpdate(taskId: {自分のタスクID}, status: "completed")
N+1. SendMessage(
       type: "message",
       recipient: "team-lead",
       content: "タスク #{N} を完了しました。{1〜3行の成果サマリー}",
       summary: "{5-10語の要約}"
     )
```

### よくあるミス: 順序が逆

```
# BAD: completed にする前に SendMessage
SendMessage(recipient: "team-lead", content: "完了しました")
TaskUpdate(status: "completed")  ← 後続タスクのブロック解除が遅れる

# GOOD: completed にしてから SendMessage
TaskUpdate(status: "completed")  ← 先にブロック解除
SendMessage(recipient: "team-lead", ...)
```

### 完了報告のフォーマット

```
# 良い完了報告:
タスク #4 を完了しました。
成果: .claude/persona-creation/round-01/personas/ に 3 件のペルソナを執筆
  - persona-01.md: フィットネス入門者（30代男性）
  - persona-02.md: 健康意識の高い主婦（40代女性）
  - persona-03.md: アスリート志望の学生（20代）
次のステップ: bias-reviewer によるレビュー待ち

# 悪い完了報告:
タスクが終わりました。
```

### Phase 3 の完了基準

- [ ] context-manager に成果物の記録を依頼した
- [ ] `TaskUpdate(status: "completed")` を実行した
- [ ] team-lead に完了報告を送った
- [ ] 後続タスクが自動的にアンブロックされることを確認（TaskList で確認）

---

## 早期フィードバックパターン

### 概念: ブロック中でも貢献できる

```
Task 1: context-manager (completed)
Task 2: persona-architect (in_progress)    ← 設計中
Task 3: user-researcher (in_progress)      ← 調査中
Task 4: persona-writer (pending) [blocked by #2, #3]  ← 待機中
Task 5: bias-reviewer (pending) [blocked by #4]       ← 待機中
```

bias-reviewer はタスク #4 待ちで「まだ自分の番ではない」状態だが、
persona-architect から「セグメント設計ができました」と共有されたら、
**待機中でもセグメントのバイアスをレビューできる**。

### 早期フィードバックの実装

```markdown
## 作業手順（bias-reviewer の例）

### Phase 1: 初期化
1. TaskList で自分のタスク（#5）を確認
2. blockedBy: ["4"] なのでブロック中
3. TaskUpdate(status: "in_progress")  ← ブロック中でも開始状態にする
4. フィードバック受け付けモードで待機

### Phase 2: 早期フィードバック（ブロック中でも実施）
5. persona-architect から「セグメント設計を完了しました」が届いたら:
   - .claude/persona-creation/round-01/segments.md を Read
   - バイアスの観点でレビュー
   - → persona-architect: セグメント3の属性定義に注意点があります: ...
6. persona-writer からペルソナが届いたら即座にレビュー
```

### 早期フィードバックで防げること

- 後工程での大幅な手戻り
- 「設計が完全に固まってから」レビューする非効率
- バイアスが最終成果物まで残るリスク

---

## 「待ちすぎない」実装パターン

### ルール: 2人以上から反応があれば次へ

```
# チームが 5人の場合:
architect が broadcast で設計を共有
→ researcher から返信 (1人)
→ writer から返信 (2人)   ← ここで次のフェーズへ進む
（残り 2人の返信は Phase 2 で対応）
```

### エージェント定義への記述方法

```markdown
## コミュニケーションルール
- **待ちすぎない**: フィードバックを全員から集める必要はない。
  2人以上から反応があれば次のフェーズに進む。
  5分以上フィードバックがなければ先に進んでよい。
- 残りのフィードバックは Phase 2 で引き続き受け付ける
```

### タイムアウト処理の実装

```markdown
### Phase 1: 初期化
4. 成果物を broadcast で共有（または関係者に SendMessage）
5. フィードバック収集:
   - 2人以上から反応があれば Phase 2 へ進む
   - 5分以上フィードバックがなければ Phase 2 へ進む
   - 0人でも 10分経過したら先に進む
```

### 全員待ちが発生する原因と対策

| 原因 | 対策 |
|------|------|
| エージェント定義に「全員のフィードバックを集める」と書いてある | 「2人以上で次へ」に変更 |
| broadcast の後に「返信を待ちます」と書いてある | タイムアウト条件を追加 |
| フィードバックの収集終了条件が不明 | 具体的な人数と時間を明記 |

---

## 各 Phase でやってはいけないこと

### Phase 1 でやってはいけないこと

```
# BAD: in_progress にする前に作業開始
作業実行 ← タスクがまだ pending 状態
TaskUpdate(status: "in_progress")  ← 後から更新

# BAD: blockedBy を確認せずに開始
TaskUpdate(status: "in_progress")
作業実行  ← 前タスクがまだ完了していないのに開始
```

### Phase 2 でやってはいけないこと

```
# BAD: ACK だけの返信
→ researcher: 調査結果を受け取りました。ありがとうございます。  ← 不要

# BAD: 全員の返信を待つ
フィードバックを全員から受け取るまで次へ進まない  ← チームが停滞

# BAD: 修正内容を言わずに「修正しました」と報告
→ bias-reviewer: ご指摘を反映しました。  ← 何を修正したか不明
```

### Phase 3 でやってはいけないこと

```
# BAD: completed にし忘れる
作業完了
SendMessage(recipient: "team-lead", content: "完了しました")
← TaskUpdate(status: "completed") がない → 後続タスクがブロックされたまま

# BAD: team-lead への完了報告を忘れる
TaskUpdate(status: "completed")
← SendMessage がない → team-lead が進捗を把握できない

# BAD: 成果物のパスを報告しない
タスク #4 を完了しました。  ← 何を作ったかが不明
```
