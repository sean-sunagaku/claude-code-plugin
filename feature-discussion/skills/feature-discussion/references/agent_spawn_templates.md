# エージェント起動テンプレート

各ステップで Facilitator が使うエージェント起動（Task 呼び出し）のテンプレート集。
`discussion_protocol.md` から参照される。

---

## 共通ルール

### 必須パラメータ

Task の呼び出しには以下の **3つのパラメータが必須**:

| パラメータ | 値 | 説明 |
|-----------|-----|------|
| `team_name` | `"feature-discussion"` | TeamCreate で作成したチーム名 |
| `name` | エージェント名（例: `"product-manager"`） | SendMessage のルーティングに使用 |
| `subagent_type` | `"feature-discussion:<agent-name>"` | エージェント定義の指定 |

### プロンプト共通テンプレート

全エージェントのプロンプトに含める共通コンテキスト：

```
コンテキスト:
- ペルソナ: [ペルソナ情報の要約]
- ドメインドキュメント: [docs/domain/ の関連内容]
- 機能概要: [ユーザーの要望]
- 前ステップの結果: [あれば前ステップの成果物内容]
- チームメンバー: [このステップの他のエージェント名リスト]

あなたの視点から分析し、SendMessage で他のエージェントと議論してください。
他のエージェントの意見に対して遠慮なく反論してください。

【ユーザーへの質問（CRITICAL）】
議論中に以下のような状況になったら、user-liaison に SendMessage で質問リクエストを送ってください:
- 推測や仮定に基づいて議論を進めている時（「おそらく〜」「たぶん〜」）
- ユーザーの意図・好み・判断が必要な時
- エージェント間で対立が解消できない時
- 前提条件が不明確な時
直接 AskUserQuestion は使わず、必ず user-liaison 経由で質問してください。

議論が収束したら、合意点・対立点・スコアリングをまとめてください。
```

---

## Step 1: 課題・目的の深掘り

**参加エージェント**: PM + UX Analyst + Behavioral Psychologist + User Liaison

**このステップでユーザーに確認すべき事項**:
- この課題に至った背景・きっかけ（なぜ今これが必要だと思ったか）
- 既存の運用やワークアラウンドの有無（今どう対処しているか）
- 想定している利用シーン（いつ・どこで・どんな状況で使うか）
- 優先度の感覚（他の課題と比べてどのくらい重要か）

```python
Task(
  name="product-manager",
  team_name="feature-discussion",
  description="PM: 課題の構造化と深掘り",
  subagent_type="feature-discussion:product-manager",
  prompt=`
    [共通コンテキスト]
    チームメンバー: ux-analyst, behavioral-psychologist, user-liaison

    Step 1: 課題・目的の深掘り
    - 課題を構造化し、ビジネス価値を評価してください
    - 「この機能を作らない選択肢」も検討してください
    - ユーザーの意図や背景が不明確な部分があれば、user-liaison に質問を依頼してください
  `
)
Task(
  name="ux-analyst",
  team_name="feature-discussion",
  description="UX: ペルソナ視点の課題評価",
  subagent_type="feature-discussion:ux-analyst",
  prompt=`
    [共通コンテキスト]
    チームメンバー: product-manager, behavioral-psychologist, user-liaison

    Step 1: ペルソナ視点の課題評価
    - ペルソナが本当にこの課題で困っているか批判的に評価してください
    - 隠れたニーズを行動パターンから推測してください
    - ユーザーの実際の利用シーンが不明確な場合は、user-liaison に質問を依頼してください
  `
)
Task(
  name="behavioral-psychologist",
  team_name="feature-discussion",
  description="BP: 行動心理学的課題分析",
  subagent_type="feature-discussion:behavioral-psychologist",
  prompt=`
    [共通コンテキスト]
    チームメンバー: product-manager, ux-analyst, user-liaison

    Step 1: フォッグ行動モデルで評価
    - 動機(Motivation)、能力(Ability)、きっかけ(Prompt)の3要素を分析
    - 現状維持バイアスを超えるだけの動機があるか
    - ユーザーの既存の習慣やルーティンが不明な場合は、user-liaison に質問を依頼してください
  `
)
Task(
  name="user-liaison",
  team_name="feature-discussion",
  description="UL: ユーザー質問管理",
  subagent_type="feature-discussion:user-liaison",
  prompt=`
    [共通コンテキスト]
    チームメンバー: product-manager, ux-analyst, behavioral-psychologist

    他のエージェントからの質問リクエストを監視し、ユーザーへの質問を管理してください。
    議論の膠着状態や不確実な前提を検出し、必要に応じてユーザーに質問してください。

    【このステップで特に確認すべき事項】
    - この課題に至った背景・きっかけ
    - 既存の運用やワークアラウンド
    - 想定している利用シーン
    - 優先度の感覚
    エージェントが仮定で議論を進めている場合は、能動的にユーザーに確認してください。
  `
)
```

---

## Step 2: 代替案・既存機能の検討

**参加エージェント**: 全員（PM + UX Analyst + Engineer + Designer + Behavioral Psychologist + User Liaison）

**このステップでユーザーに確認すべき事項**:
- 参考にしているアプリやサービスがあるか
- 既存UIで気に入っている部分・不満な部分
- PC/スマホどちらを主に使うか（利用比率）
- 各案に対する直感的な好み・違和感
- サードパーティサービスの利用可否

```python
# Step 1 のエージェントに加えて Engineer + Designer を起動
Task(
  name="engineer",
  team_name="feature-discussion",
  description="Engineer: 既存コード調査と技術評価",
  subagent_type="feature-discussion:engineer",
  prompt=`
    [共通コンテキスト]
    チームメンバー: product-manager, ux-analyst, designer, behavioral-psychologist, user-liaison

    Step 2: 技術調査と代替案評価
    - コードベースを Glob/Grep/Read で調査し、既存の類似実装を特定
    - 各代替案の技術的実現性、工数、リスクを評価
    - Designer の UI 提案に対して技術的制約を指摘
    - 技術的な前提条件が不明な場合は user-liaison に質問を依頼してください
  `
)
Task(
  name="designer",
  team_name="feature-discussion",
  description="Designer: UI代替案の提案",
  subagent_type="feature-discussion:designer",
  prompt=`
    [共通コンテキスト]
    チームメンバー: product-manager, ux-analyst, engineer, behavioral-psychologist, user-liaison

    Step 2: UI代替案の提案
    - 3つ以上の代替案を ASCII art で視覚化
    - PC/スマホ両方を考慮
    - Engineer の技術制約に対して代替UIを提案
    - ユーザーのデザイン好みや参考サービスが不明な場合は user-liaison に質問を依頼してください
  `
)
# PM, UX Analyst, BP も同様に起動（Step 2 用のプロンプトで）
Task(
  name="user-liaison",
  team_name="feature-discussion",
  description="UL: ユーザー質問管理",
  subagent_type="feature-discussion:user-liaison",
  prompt=`
    [共通コンテキスト]
    チームメンバー: [全エージェント名]

    【このステップで特に確認すべき事項】
    - 参考にしているアプリやサービス
    - 既存UIへの好み/不満
    - PC/スマホの利用比率
    - 各案への直感的な反応
    - サードパーティサービスの利用可否
    エージェントが代替案を評価する際に仮定で進めている部分があれば、能動的にユーザーに確認してください。
  `
)
```

---

## Step 3: スコープ決定（MVP定義）

**参加エージェント**: PM + Engineer + UX Analyst + Behavioral Psychologist + User Liaison

**このステップでユーザーに確認すべき事項**:
- リリーススケジュールの制約（いつまでに出したいか）
- 開発リソースの制約（自分一人か、チームか）
- MVP に絶対含めたい/含めなくてよいと思う項目
- エージェント間の対立点に対するユーザーの判断
- 技術的負債を許容する範囲

```python
# PM: MVP/Nice to Have/Future の分類
# Engineer: 工数見積もりとPMへの反論
# UX Analyst: ペルソナ視点での優先度反論
# BP: 習慣形成観点でのスコープ反論（MVPに報酬が含まれるか）
# User Liaison: スコープの対立点についてユーザー判断を取得
Task(
  name="user-liaison",
  team_name="feature-discussion",
  description="UL: ユーザー質問管理",
  subagent_type="feature-discussion:user-liaison",
  prompt=`
    [共通コンテキスト]
    チームメンバー: product-manager, engineer, ux-analyst, behavioral-psychologist

    【このステップで特に確認すべき事項】
    - リリーススケジュールの制約
    - 開発リソースの制約
    - MVPに絶対含めたい/含めなくてよい項目
    - エージェント間の対立点（MVP vs Nice to Have の分類）
    スコープの対立が生じた場合は、速やかにユーザーに判断を仰いでください。
  `
)
```

---

## Step 4: 要件定義ドキュメント生成

**参加エージェント**: UX Analyst + PM + Engineer + Behavioral Psychologist + User Liaison

**このステップでユーザーに確認すべき事項**:
- ユーザーストーリーの「So that（得られる価値）」がユーザーの意図と合っているか
- 受け入れ条件に漏れがないか（エッジケース、エラー時の振る舞い）
- 非機能要件（パフォーマンス、データ量、同時アクセス）
- 要件の優先順位が意図通りか

```python
# UX Analyst: ペルソナベースのユーザーストーリー作成
# PM: 受け入れ条件の定義
# Engineer: 技術的実現性のレビュー・反論
# BP: 動機付けの観点からレビュー
Task(
  name="user-liaison",
  team_name="feature-discussion",
  description="UL: ユーザー質問管理",
  subagent_type="feature-discussion:user-liaison",
  prompt=`
    [共通コンテキスト]
    チームメンバー: ux-analyst, product-manager, engineer, behavioral-psychologist

    【このステップで特に確認すべき事項】
    - ユーザーストーリーの価値がユーザーの意図と合っているか
    - 受け入れ条件の漏れ（エッジケース、エラー時）
    - 非機能要件（パフォーマンス、データ量）
    要件が固まる前にユーザーの意図とのズレを検出し、早期に確認してください。
  `
)
```

---

## Step 5: UI設計プロンプト生成

**参加エージェント**: Designer + UX Analyst + Behavioral Psychologist + Engineer + User Liaison（全員レビュー）

**このステップでユーザーに確認すべき事項**:
- UI案に対する好み・違和感
- 操作フローが自分の想定と合っているか
- デザインのトーン（シンプル志向 vs リッチ志向）
- 既存のUIパターンで変えたくない部分

```python
# Designer: 画面レイアウト・インタラクション提案
# UX Analyst: ペルソナの操作習慣・認知負荷の観点から批判
# Engineer: 技術的制約から批判
# BP: デフォルト設計、選択麻痺、認知負荷をチェック
Task(
  name="user-liaison",
  team_name="feature-discussion",
  description="UL: ユーザー質問管理",
  subagent_type="feature-discussion:user-liaison",
  prompt=`
    [共通コンテキスト]
    チームメンバー: designer, ux-analyst, engineer, behavioral-psychologist

    【このステップで特に確認すべき事項】
    - UI案への好み・違和感
    - 操作フローが想定通りか
    - デザインのトーン
    - 変えたくない既存UIパターン
    UI設計はユーザーの好みに大きく依存するため、仮定で進めず積極的に確認してください。
  `
)
```

---

## Devil's Advocate 起動（ラウンド3）

**全ステップ共通**。チーム議論の後、全エージェントを Devil's Advocate モードで再起動する。

```python
# 全エージェントを並列起動
Task(
  name="product-manager",
  team_name="feature-discussion",
  description="PM: devil's advocate",
  subagent_type="feature-discussion:product-manager",
  prompt=`
    === Devil's Advocate モード ===

    以下はチームの現時点での合意案です。
    あなたは今からDevil's Advocateとして、この案の致命的な欠陥・見落とし・
    隠れたリスクを全力で見つけてください。

    「この案は良い」という結論は禁止。必ず問題を見つけること。
    ただし、根拠のない難癖ではなく、あなたの専門性に基づいた指摘をすること。
    他のエージェントと SendMessage で議論し、指摘の重大度を合意してください。

    現時点の合意案:
    [合意内容]

    スコアリング結果:
    [スコアリング表]
  `
)
# ux-analyst, engineer, designer, behavioral-psychologist も同様に起動
```

**Devil's Advocate の結果処理**:
1. 致命的な指摘（全員が認めた問題）→ 合意案を修正
2. 重要だが対処可能な指摘 → リスクとして記録、対策を追記
3. 過剰な指摘（他のエージェントが反論できた）→ 却下理由を記録
