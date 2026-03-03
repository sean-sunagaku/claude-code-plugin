# SubAgent 定義アンチパターン集

SubAgent（agents/*.md）の定義に特有の失敗パターン。チーム設計ではなく、
個別エージェント定義の品質に関わる問題に絞っている。

## 目次
1. [YAML Frontmatter 関連](#yaml-frontmatter-関連)
2. [ツール設定関連](#ツール設定関連)
3. [3-Phase 構造関連](#3-phase-構造関連)
4. [コンテキスト受け渡し関連](#コンテキスト受け渡し関連)
5. [コミュニケーション関連](#コミュニケーション関連)

---

## YAML Frontmatter 関連

### AP-01: description に "Use when" / "Triggers" がない

**症状**: スキルのトリガー検索でエージェントがマッチしない

**原因**: description が単なる役割説明のみで、スキル呼び出し条件が記述されていない

```yaml
# BAD
---
name: researcher
description: >
  Market research specialist for the app-naming team.
---

# GOOD
---
name: researcher
description: >
  Market research specialist for the app-naming team.
  Use when: conducting market research, analyzing competitors.
  Triggers: "research", "market analysis", "competitor", "調査"
---
```

---

### AP-02: name が subagent_type と一致していない

**症状**: `subagent_type: "my-skill:researcher"` で起動しようとしてエージェントが見つからない

**原因**: `agents/researcher.md` の `name` フィールドが "researcher" 以外になっている

```yaml
# BAD（ファイル名は researcher.md だが name が違う）
---
name: my-researcher   # ← subagent_type の後半と不一致
---

# GOOD
---
name: researcher      # ← agents/researcher.md なら "researcher"
---
```

---

### AP-03: model を全員 opus にしている

**症状**: スキル実行コストが過大になる

**原因**: 役割に関係なく全エージェントを opus に設定している

```yaml
# BAD
---
name: context-manager
model: opus   # ← ファイル書き込み専任に opus は過剰
---

# GOOD
---
name: context-manager
model: haiku  # ← 単純なファイル操作は haiku で十分
---
```

**役割別推奨モデル**:
- `haiku`: 記録・転記・単純ファイル操作（context-manager 等）
- `sonnet`: 通常の調査・執筆・分析（デフォルト）
- `opus`: 複雑な設計判断・最終品質レビュー

---

## ツール設定関連

### AP-04: SendMessage / TaskList / TaskGet / TaskUpdate が未記載

**症状**: エージェントが他エージェントと通信できない、タスクが見つからない

**原因**: `tools` に通信・タスク系ツールを含め忘れた

```yaml
# BAD
---
name: writer
tools: Read, Write, Edit
---

# GOOD
---
name: writer
tools: Read, Write, Edit, SendMessage, TaskList, TaskGet, TaskUpdate
---
```

これら 4 つは全エージェントに必須。

---

### AP-05: 調査系エージェントに Write/Bash を付与している

**症状**: 調査専任のはずのエージェントがファイルを書き換えたり意図しないコマンドを実行する

**原因**: 「全部使えるようにしておく」という方針でツールを追加しすぎた

```yaml
# BAD
---
name: researcher
tools: Read, Grep, Glob, Write, Edit, Bash, WebSearch, SendMessage, TaskList, TaskGet, TaskUpdate
---

# GOOD
---
name: researcher
tools: Read, Grep, Glob, WebSearch, SendMessage, TaskList, TaskGet, TaskUpdate
# Write/Edit/Bash は不要。調査結果の書き込みは context-manager に依頼する
---
```

---

### AP-06: MCP ツールを agents/*.md で指定している

**症状**: エージェントが MCP ツールを使えない（設定が無視される）

**原因**: agents/*.md の tools フィールドに `mcp__pencil__*` 等を書いても効果がない

```yaml
# BAD（効果がない）
---
name: designer
tools: Read, mcp__pencil__batch_design, SendMessage, TaskList, TaskGet, TaskUpdate
---
```

```
# GOOD: general-purpose で起動して prompt 内で役割を定義
Task(
  subagent_type: "general-purpose",
  name: "designer",
  prompt: """
あなたは designer として ui-design チームのデザイン担当です。
mcp__pencil__batch_design を使って UI デザインを実装する。
...
"""
)
```

---

## 3-Phase 構造関連

### AP-07: Phase 1 で TaskUpdate(in_progress) の前に作業を開始する

**症状**: タスクが `pending` のまま作業が進み、他エージェントが重複して作業を開始する

**原因**: TaskUpdate を「後でやる」と思って作業を先に始めてしまう

```markdown
# BAD
### Phase 1: 初期化
1. TaskList でタスクを確認
2. 作業を開始する  ← in_progress にする前に作業
3. TaskUpdate(status: "in_progress")

# GOOD
### Phase 1: 初期化
1. TaskList でタスクを確認
2. TaskGet(taskId) でタスク詳細と blockedBy を確認
3. TaskUpdate(taskId, status: "in_progress")  ← 作業前に必ず更新
4. 作業を開始する
```

---

### AP-08: Phase 3 で TaskUpdate(completed) を忘れる

**症状**: 後続タスクが永遠に `pending` のまま解放されない

**原因**: 「完了報告を送った」で満足して TaskUpdate を忘れた

```markdown
# BAD
### Phase 3: 最終化
1. 成果物を確認
2. → team-lead: 完了しました  ← TaskUpdate がない

# GOOD
### Phase 3: 最終化
1. 成果物を確認
2. TaskUpdate(taskId, status: "completed")  ← 先にブロック解除
3. → team-lead: タスク #N を完了しました。{成果サマリー}
```

---

### AP-09: Phase 3 の完了報告に成果物パスがない

**症状**: team-lead や後続エージェントが成果物の場所を把握できない

**原因**: 「完了した」という事実だけ報告し、何をどこに作ったかを省略した

```
# BAD
→ team-lead: タスク #4 を完了しました。

# GOOD
→ team-lead: タスク #4 を完了しました。
  成果: .claude/persona-creation/round-01/personas/ に 3 件のペルソナを執筆
    - persona-01.md: フィットネス入門者（30代男性）
    - persona-02.md: 健康意識の高い主婦（40代女性）
    - persona-03.md: アスリート志望の学生（20代）
  次のステップ: bias-reviewer によるレビュー待ち
```

---

### AP-10: Phase 2 で ACK だけ返信し続ける

**症状**: メッセージが大量に飛び交うが実質的な作業が進まない

**原因**: 「返信しないのは失礼」という意識から、情報価値のない返信を送り続けている

```
# BAD
→ researcher: 調査結果を受け取りました。ありがとうございます。（ACK のみ）
→ architect: セグメント設計を確認しました。参考にします。（ACK のみ）

# GOOD
返信すべきケース:
- フィードバック・指摘がある場合
- 質問がある場合
- 修正完了の報告（変更内容を含む）
- 緊急の問題を発見した場合

返信不要なケース:
- 「了解しました」だけ
- 「受け取りました」だけ
- 内容に異論がなく次のアクションもない
```

---

## コンテキスト受け渡し関連

### AP-11: Task() のプロンプトにプロダクト情報を含めない

**症状**: エージェントが「プロダクト情報がありません」とエラーを返す、または全く的外れな作業をする

**原因**: SubAgent は親のコンテキストを持たないことを忘れて、情報を省略した

```python
# BAD
Task(
  subagent_type: "app-naming:researcher",
  prompt: "agents/researcher.md の手順に従ってください"
)

# GOOD
Task(
  subagent_type: "app-naming:researcher",
  prompt: """
あなたは app-naming チームの researcher です。

## プロダクト情報
アプリ名: MyApp
カテゴリ: フィットネス
ターゲット: 30代男性
主な機能: 運動記録、カロリー計算

## コンテキスト
- ファイルパス: /Users/user/project/.claude/app-naming/20250222_myapp/
- チームメンバー:
  - naming-specialist: 命名候補の生成担当
  - context-manager: ファイル I/O 専任
  - team-lead: 完了報告先

agents/researcher.md の手順に従って作業を開始してください。
"""
)
```

---

### AP-12: チームメンバー構成を省略する

**症状**: エージェントが SendMessage で誰に送ればいいかわからない、または間違った宛先に送る

**原因**: プロンプトにチームメンバーの名前と役割を記載しなかった

```python
# BAD
prompt: """
調査完了後に結果を architect に共有してください。
"""
# → 「architect」という名前のエージェントが実際に存在するか不明

# GOOD
prompt: """
## チームメンバー
- persona-architect: セグメント設計担当（調査結果を送る先）
- persona-writer: ペルソナ執筆担当
- context-manager: ファイル記録専任（Write/Edit の依頼先）
- team-lead: 完了報告先
"""
```

---

### AP-13: ファイルパスに相対パスを使う

**症状**: 異なるエージェント間でファイルの場所が食い違う、ファイルが見つからない

**原因**: cwd が異なるエージェント間では相対パスが機能しない

```
# BAD
- ファイルパス: .claude/persona-creation/20250222_myapp/

# GOOD
- ファイルパス: /Users/user/project/.claude/persona-creation/20250222_myapp/
```

SubAgent 起動時のプロンプトには常に絶対パスを使う。

---

## コミュニケーション関連

### AP-14: フィードバックを宛先不明で送る

**症状**: 誰も対応せず問題が放置される

**原因**: 「フィードバックをください」と書いたが、誰に送るかが不明

```
# BAD
「このペルソナのバイアスチェックをお願いします」（宛先なし）

# GOOD
→ bias-reviewer: persona-01.md の職業描写にバイアスがないか確認してください。
  特にジェンダーに関する記述（3行目〜5行目）を重点的にレビューお願いします。
```

---

### AP-15: 修正内容を明示せずに「修正しました」と報告する

**症状**: 依頼者が何が変わったかわからず再レビューできない

**原因**: 「修正した」という事実だけを伝えて、変更内容を省略した

```
# BAD
→ bias-reviewer: ご指摘を反映しました。確認をお願いします。

# GOOD
→ bias-reviewer: ご指摘の職業描写のバイアスを修正しました。
  変更内容:
  - Before: 「彼女は主婦として家事をこなしながら...」
  - After:  「彼女はフリーランスデザイナーとして...」
  再確認をお願いします。
```
