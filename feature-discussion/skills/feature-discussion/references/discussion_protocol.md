# 議論プロトコル

各ステップで実行する「議論ラウンド」の詳細。
ラウンド1〜3は必須、ラウンド4（Devil's Advocate）はステップに応じて実行。
対立が解決しない場合はラウンド2〜3を最大2回繰り返す（マルチラウンド）。

---

## ラウンド 1: 初期提案（並列）

ステップに関係するエージェントを**並列で**起動し、それぞれの視点から提案を出す。
**Behavioral Psychologist も並列で参加**し、行動心理学の観点から初期評価を行う。

```
# 例: Step 1 では PM + UX Analyst + Behavioral Psychologist を並列起動
Task(subagent_type="general-purpose", prompt=`
  [agents/product-manager.md の内容]

  コンテキスト:
  - ペルソナ: [ペルソナ情報]
  - ドメインドキュメント: [docs/domain/ の関連内容]
  - 機能概要: [ユーザーの要望]
  - 前ステップの結果: [あれば]

  あなたの視点から提案してください。
  出力の最後にスコアリング評価を含めてください。
`)
```

## ラウンド 2: クロスレビュー・反論（並列）

各エージェントに**他のエージェントの提案を渡し、批判・反論**させる。

```
Task(subagent_type="general-purpose", prompt=`
  [agents/engineer.md の内容]

  以下は他のエージェントの提案です。
  あなたの視点から、問題点・リスク・見落としを指摘してください。
  遠慮なく反論してください。

  PM提案: [ラウンド1の結果]
  Designer提案: [ラウンド1の結果]
  Behavioral Psychologist分析: [ラウンド1の結果]
`)
```

**マルチラウンド**: 対立が2件以上残っている場合、反論結果を再び全エージェントに渡して
ラウンド2を繰り返す（最大2回まで）。各ラウンドで対立が減っていくことを確認する。

## ラウンド 3: スコアリング評価（並列）

全エージェントが各提案/案を**5段階で定量評価**する。

**スコアリング基準**（各エージェントが全項目を評価）:
| 評価軸 | 説明 | 主な評価者 |
|--------|------|----------|
| ビジネス価値 | ユーザー・事業への影響度 | PM |
| ペルソナ適合度 | ペルソナのニーズとの一致度 | UX Analyst |
| 技術的実現性 | 実装の容易さ・リスクの低さ | Engineer |
| UX品質 | 操作性・視覚的品質 | Designer |
| 行動実現性 | ユーザーが実際に行動するか | Behavioral Psychologist |

**スコアリング出力フォーマット**:
```
| 案 | ビジネス価値 | ペルソナ適合 | 技術実現性 | UX品質 | 行動実現性 | 平均 |
|----|------------|-----------|----------|--------|----------|------|
| A  | 4          | 5         | 3        | 4      | 2        | 3.6  |
| B  | 3          | 4         | 5        | 3      | 4        | 3.8  |
| C  | 5          | 3         | 2        | 5      | 3        | 3.6  |
```

**重要**: スコアが低い項目には必ず理由を付記する。
特に**行動実現性が3以下の場合**は、Behavioral Psychologistの指摘を重点的に検討する。

## ラウンド 4: Devil's Advocate（全員）

**各ステップの最終ラウンドとして実行**。
全エージェントが「全力で反論モード」に切り替わり、現時点の合意案を破壊しにかかる。

```
Task(subagent_type="general-purpose", prompt=`
  [agents/xxx.md の内容]

  === Devil's Advocate モード ===

  以下はチームの現時点での合意案です。
  あなたは今からDevil's Advocateとして、この案の致命的な欠陥・見落とし・
  隠れたリスクを全力で見つけてください。

  「この案は良い」という結論は禁止。必ず問題を見つけること。
  ただし、根拠のない難癖ではなく、あなたの専門性に基づいた指摘をすること。

  現時点の合意案:
  [合意内容]

  スコアリング結果:
  [スコアリング表]
`)
```

**Devil's Advocate の結果処理**:
1. 致命的な指摘（全員が認めた問題）→ 合意案を修正
2. 重要だが対処可能な指摘 → リスクとして記録、対策を追記
3. 過剰な指摘（他のエージェントが反論できた）→ 却下理由を記録

## ラウンド 5: 統合・ユーザー提示

Facilitator（SKILL.md）が：
1. 合意点をまとめる
2. 対立点を明示する
3. スコアリング結果を提示する
4. Devil's Advocate で発見された懸念を提示する
5. ASK_USER の質問をまとめて提示する
6. ユーザーに判断を求める

**ユーザーへの提示フォーマット**:
```
━━━━ チーム議論結果 ━━━━

📊 スコアリング:
  | 案 | ビジネス | ペルソナ | 技術 | UX | 行動 | 平均 |
  |----|---------|---------|------|-----|------|------|
  | A  | 4       | 5       | 3    | 4   | 2    | 3.6  |
  | B  | 3       | 4       | 5    | 3   | 4    | 3.8  |

✅ 合意:
  - [全員が同意した点]

⚡ 対立:
  1. [論点A]
     - PM: 「〇〇すべき」（理由: ...）
     - Engineer: 「△△のリスクがある」（理由: ...）
     - Behavioral Psychologist: 「ユーザーは△△の行動を取らない」（理由: ...）

⚠️ Devil's Advocate 懸念:
  - [致命的ではないが注意すべき点]

❓ チームからの質問:
  - [ASK_USER の質問]

どちらの方向で進めますか？
```

---

## エージェント起動パターン

### 並列起動（ラウンド1: 初期提案）

```python
# Step 1の例: PM + UX Analyst + Behavioral Psychologist を並列起動
Task(
  description="PM: analyze problem",
  subagent_type="general-purpose",
  prompt="[agents/product-manager.md の内容]\n\nコンテキスト:\n- ペルソナ: [...]\n- ドメインドキュメント: [...]\n\n提案してください。スコアリング評価を含めてください。"
)
Task(
  description="UX: evaluate from persona",
  subagent_type="general-purpose",
  prompt="[agents/ux-analyst.md の内容]\n\nコンテキスト:\n...\n\n提案してください。スコアリング評価を含めてください。"
)
Task(
  description="BP: behavioral analysis",
  subagent_type="general-purpose",
  prompt="[agents/behavioral-psychologist.md の内容]\n\nコンテキスト:\n...\n\nフォッグ行動モデルで評価してください。スコアリング評価を含めてください。"
)
```

### クロスレビュー起動（ラウンド2: 反論）

```python
# 全エージェントに他の提案を渡して反論させる（並列）
Task(
  description="Engineer: challenge proposals",
  subagent_type="general-purpose",
  prompt="[agents/engineer.md の内容]\n\n他の提案:\nPM: [...]\nDesigner: [...]\nBP: [...]\n\n遠慮なく反論してください。"
)
Task(
  description="BP: challenge proposals",
  subagent_type="general-purpose",
  prompt="[agents/behavioral-psychologist.md の内容]\n\n他の提案:\nPM: [...]\nEngineer: [...]\nDesigner: [...]\n\n行動心理学の観点から問題点を指摘してください。"
)
# ... 他のエージェントも同様
```

### Devil's Advocate 起動（ラウンド4）

```python
# 全エージェントを並列でDevil's Advocateモードで起動
Task(
  description="PM: devil's advocate",
  subagent_type="general-purpose",
  prompt="[agents/product-manager.md の内容]\n\n=== Devil's Advocate モード ===\n現時点の合意案:\n[...]\nスコアリング:\n[...]\n\nこの案の致命的な欠陥を全力で見つけてください。"
)
# ... 全エージェント同様に並列起動
```

---

## ASK_USER 処理

各エージェントは出力に `ASK_USER:` セクションを含めることができる。
Facilitatorは以下のように処理する：

1. 全エージェントの出力から `ASK_USER:` を収集
2. 重複する質問をマージ
3. 優先度順に並べ替え（議論がブロックされている質問を優先）
4. ユーザーに質問をまとめて提示

**提示フォーマット**:
```
━━━━ チームからの質問 ━━━━

以下の点について、判断をお願いします：

1. [質問]（PM・Engineerが回答を必要としています）
   → 背景: [なぜこの情報が必要か]

2. [質問]（Behavioral Psychologistが回答を必要としています）
   → 背景: [なぜこの情報が必要か]
```

---

## ユーザー判断の追跡

対立点をユーザーが判断した場合、**判断内容と理由を必ず記録する**。
「なぜこう決めたのか」を後から追跡できるようにする。

### 記録タイミング

- ユーザーが対立点について判断を下した時
- ユーザーがエージェントの提案を却下/採用した時
- ユーザーがスコープ・優先度を変更した時

### 記録フォーマット

Facilitator はユーザーの判断を受けたら、必ず以下を `discussion_log.md` に追記する：

```markdown
## ユーザー判断 - YYYY-MM-DD HH:MM

### 判断内容
- ✅ 採用: [採用された内容]
- ❌ 却下: [却下された内容]

### 対立の背景
- [Agent A]: 「[主張]」（理由: [...]）
- [Agent B]: 「[主張]」（理由: [...]）

### ユーザーの判断理由
> [ユーザーの発言から判断理由を抽出。不明な場合は質問する]

### 影響範囲
- [この判断が影響するステップ/成果物]

---
```

### 理由が不明な場合

ユーザーが理由を述べずに判断した場合、Facilitator は必ず確認する：

```
その判断の理由を教えていただけますか？
後で振り返る時に「なぜこう決めたか」が分かると助かります。

例:
- 「技術的リスクを避けたいから」
- 「ペルソナの使い方に合ってるから」
- 「直感的にこっちが良い」（これでもOK）
```

### 成果物への反映

各ステップの成果物（`1_purpose.md` 〜 `5_ui_prompt.md`）にも「ユーザー判断記録」セクションを含める。
テンプレートは `references/output_templates.md` を参照。

---

## ディスカッション議事録（CRITICAL）

各ラウンドの結果を `discussion_log.md` に追記する。

**詳細フォーマット**: `references/discussion_log_format.md` を参照
**成果物テンプレート**: `references/output_templates.md` を参照

**議事録にはエージェント間の議論も記録する**:
```markdown
## Step 2 ラウンド2: クロスレビュー - 2026-02-25 14:30

### Engineer → Designer への反論
> Designerの案Bはドロワーを使っているが、既存の@dnd-kitとの干渉リスクがある。
> 案Aのアコーディオン方式のほうが技術的に安全。

### Designer → Engineer への反駁
> アコーディオン方式はペルソナの操作習慣と合わない。
> @dnd-kitとの干渉は、ドロワーをポータルで描画すれば回避可能。

### 合意点
- ドロワー採用、ただしポータル描画で実装

---
```

**ディレクトリ構造**:
```
.claude/feature_discussion/sessions/<feature-slug>/
├── session.json          # セッション進捗管理
├── discussion_log.md     # ディスカッション議事録（エージェント間の議論含む）
├── 1_purpose.md         # Step 1の結果
├── 2_alternatives.md    # Step 2の結果
├── 3_scope.md           # Step 3の結果
├── 4_requirements.md    # Step 4の結果
└── 5_ui_prompt.md       # Step 5の結果
```
