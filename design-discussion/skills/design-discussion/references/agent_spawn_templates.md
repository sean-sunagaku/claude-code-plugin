# エージェント起動テンプレート

各ステップで Facilitator が使うエージェント起動（Task 呼び出し）のテンプレート集。

---

## 共通ルール

### 必須パラメータ

| パラメータ | 値 | 説明 |
|-----------|-----|------|
| `team_name` | `"design-discussion"` | TeamCreate で作成したチーム名 |
| `name` | エージェント名 | SendMessage のルーティングに使用 |
| `subagent_type` | `"design-discussion:<agent-name>"` | エージェント定義の指定 |
| `mode` | `"bypassPermissions"` | 権限バイパス |
| `run_in_background` | `true` | 並列実行のため |

### プロンプト共通テンプレート

全エージェントのプロンプトに含める共通コンテキスト:

```
コンテキスト:
- 設計テーマ: [ユーザーの設計課題]
- 作業ディレクトリ: [絶対パス]
- ドメインドキュメント: [docs/ や .claude/ 配下の関連 MD]
- 前ステップの結果: [あれば前ステップの成果物内容]
- チームメンバー: [このステップの他のエージェント名リスト]

あなたの視点から分析し、SendMessage で他のエージェントと議論してください。
他のエージェントの意見に対して遠慮なく反論してください。

【ユーザーへの質問（CRITICAL）】
議論中に以下のような状況になったら、user-liaison に SendMessage で質問リクエストを送ってください:
- 推測や仮定に基づいて議論を進めている時
- ユーザーの意図・好み・判断が必要な時
- エージェント間で対立が解消できない時
- 技術スタックや制約条件が不明な時
直接 AskUserQuestion は使わず、必ず user-liaison 経由で質問してください。

議論が収束したら、合意点・対立点・スコアリングをまとめてください。
```

---

## Step 1: 課題・要件の明確化

**参加エージェント**: solution-architect + engineer + product-manager + user-liaison

**このステップでユーザーに確認すべき事項**:
- 解決したい技術的問題の背景と動機
- 変更できない制約条件（技術スタック、期限、コスト）
- 成功基準（何が実現できれば「完了」か）
- 既存システムとの統合要件

```python
Task(
  name="solution-architect",
  team_name="design-discussion",
  description="Solution Architect: 設計課題の構造化",
  subagent_type="design-discussion:solution-architect",
  mode="bypassPermissions",
  run_in_background=True,
  prompt="""
    [共通コンテキスト]
    チームメンバー: engineer, product-manager, user-liaison

    Step 1: 設計課題の明確化
    - ユーザーの設計課題を構造化してください
    - 「何を決定する必要があるか」「何が制約条件か」を整理してください
    - engineer に「現在のコードベースを調査してほしい」とリクエストしてください
    - 不明点があれば user-liaison に質問を依頼してください
  """
)

Task(
  name="engineer",
  team_name="design-discussion",
  description="Engineer: コードベース初期調査",
  subagent_type="design-discussion:engineer",
  mode="bypassPermissions",
  run_in_background=True,
  prompt="""
    [共通コンテキスト]
    チームメンバー: solution-architect, product-manager, user-liaison

    Step 1: コードベース初期調査
    - Glob/Grep/Read でコードベースを調査してください
    - 設計課題に関連するファイル・モジュールを特定してください
    - 技術的制約条件（ライブラリ、フレームワーク、既存パターン）を把握してください
    - 変更が影響する範囲を報告してください
  """
)

Task(
  name="product-manager",
  team_name="design-discussion",
  description="Product Manager: ビジネス要件の整理",
  subagent_type="design-discussion:product-manager",
  mode="bypassPermissions",
  run_in_background=True,
  prompt="""
    [共通コンテキスト]
    チームメンバー: solution-architect, engineer, user-liaison

    Step 1: ビジネス要件の整理
    - 設計の成功基準をビジネス観点で定義してください
    - 「設計しない」選択肢のビジネスリスクを評価してください
    - 期限・コスト・リソースの制約を確認してください
    - 不明な要件があれば user-liaison に質問を依頼してください
  """
)

Task(
  name="user-liaison",
  team_name="design-discussion",
  description="User Liaison: ユーザー質問管理",
  subagent_type="design-discussion:user-liaison",
  mode="bypassPermissions",
  run_in_background=True,
  prompt="""
    [共通コンテキスト]
    チームメンバー: solution-architect, engineer, product-manager

    他のエージェントからの質問リクエストを監視し、ユーザーへの質問を管理してください。

    【このステップで特に確認すべき事項】
    - 設計の背景・動機（なぜ今これが必要か）
    - 変更できない技術的制約
    - 成功基準と完了の定義
    - 期限・コストの制約
    エージェントが仮定で議論を進めている場合は、能動的にユーザーに確認してください。
  """
)
```

---

## Step 2: 設計案の生成と初期評価

**参加エージェント**: solution-architect（リード）+ engineer + product-manager + user-liaison

**このステップでユーザーに確認すべき事項**:
- 参考にしている設計パターンやサービスがあるか
- 特定の技術・ライブラリへのこだわりや忌避感
- 「現状維持」が選択肢に含まれるか

```python
Task(
  name="solution-architect",
  team_name="design-discussion",
  description="Solution Architect: 設計案の提案",
  subagent_type="design-discussion:solution-architect",
  mode="bypassPermissions",
  run_in_background=True,
  prompt="""
    [共通コンテキスト]
    前ステップの結果: [1_clarification.md の内容]
    チームメンバー: engineer, product-manager, user-liaison

    Step 2: 設計案の生成（必ず2案以上、最大4案）
    - 各案を ASCII art やコード例で具体的に示してください
    - 「現状維持」案も含めてください
    - 各案の主なメリット・デメリットを整理してください
    - engineer に各案の実現可能性を確認してください
  """
)

Task(
  name="engineer",
  team_name="design-discussion",
  description="Engineer: 設計案の技術評価",
  subagent_type="design-discussion:engineer",
  mode="bypassPermissions",
  run_in_background=True,
  prompt="""
    [共通コンテキスト]
    前ステップの結果: [1_clarification.md の内容]
    チームメンバー: solution-architect, product-manager, user-liaison

    Step 2: 各設計案の技術評価
    - Solution Architect の案に対して技術的実現性を評価してください
    - 各案の工数を3点見積もり（楽観/最頻/悲観）で示してください
    - 既存コードとの整合性を評価してください
    - 技術的リスクを具体的に指摘してください
  """
)

Task(
  name="product-manager",
  team_name="design-discussion",
  description="Product Manager: 設計案のビジネス評価",
  subagent_type="design-discussion:product-manager",
  mode="bypassPermissions",
  run_in_background=True,
  prompt="""
    [共通コンテキスト]
    前ステップの結果: [1_clarification.md の内容]
    チームメンバー: solution-architect, engineer, user-liaison

    Step 2: 各設計案のビジネス価値評価
    - 各案のビジネス価値を評価してください
    - 過剰設計の案があれば指摘してください（YAGNI原則）
    - 「最もシンプルで価値を提供できる案」を特定してください
  """
)

Task(
  name="user-liaison",
  team_name="design-discussion",
  description="User Liaison: ユーザー質問管理",
  subagent_type="design-discussion:user-liaison",
  mode="bypassPermissions",
  run_in_background=True,
  prompt="""
    [共通コンテキスト]
    チームメンバー: solution-architect, engineer, product-manager

    【このステップで特に確認すべき事項】
    - 参考にしている設計パターンやアーキテクチャ
    - 特定の技術スタックへのこだわり・忌避感
    - 現状維持が選択肢に含まれるか
    エージェントが技術的な前提を仮定で進めている場合は確認してください。
  """
)
```

---

## Step 3: 深掘り比較・Devil's Advocate

**参加エージェント**: 全員（devils-advocate が R3 を担当）

**このステップでユーザーに確認すべき事項**:
- スコアリング結果への感想（重要視する評価軸）
- Devil's Advocate 指摘への許容度（リスクを受け入れるか否か）
- 対立点への判断

```python
# R1: チーム議論（solution-architect + engineer + product-manager + user-liaison）
# Step 2 の起動テンプレートと同様に起動し、Step 3 の深掘り指示を与える

Task(
  name="solution-architect",
  team_name="design-discussion",
  description="Solution Architect: 詳細比較の主導",
  subagent_type="design-discussion:solution-architect",
  mode="bypassPermissions",
  run_in_background=True,
  prompt="""
    [共通コンテキスト]
    前ステップの結果: [2_candidates.md の内容]
    チームメンバー: engineer, product-manager, user-liaison, devils-advocate

    Step 3: 詳細比較・深掘り
    - 各案の保守性・拡張性を詳細に評価してください
    - 5軸のスコアリングを完成させてください
    - Engineer と Product Manager の評価を統合してください
    - devils-advocate の批判に対して応答してください
  """
)

Task(
  name="engineer",
  team_name="design-discussion",
  description="Engineer: 詳細技術比較",
  subagent_type="design-discussion:engineer",
  mode="bypassPermissions",
  run_in_background=True,
  prompt="""
    [共通コンテキスト]
    前ステップの結果: [2_candidates.md の内容]
    チームメンバー: solution-architect, product-manager, user-liaison, devils-advocate

    Step 3: 技術的深掘り比較
    - 各案のパフォーマンス・スケーラビリティ・セキュリティを詳細に評価してください
    - 工数の3点見積もりを最終確定してください
    - devils-advocate の技術的批判に対して具体的なデータで反論または認めてください
    - 移行コスト（現状から各案への移行難易度）を評価してください
  """
)

Task(
  name="product-manager",
  team_name="design-discussion",
  description="Product Manager: ビジネス影響の深掘り",
  subagent_type="design-discussion:product-manager",
  mode="bypassPermissions",
  run_in_background=True,
  prompt="""
    [共通コンテキスト]
    前ステップの結果: [2_candidates.md の内容]
    チームメンバー: solution-architect, engineer, user-liaison, devils-advocate

    Step 3: ビジネス影響の深掘り
    - 各案の長期的なビジネスリスクを評価してください
    - ユーザーへの影響（機能変更、パフォーマンス改善など）を具体的に評価してください
    - devils-advocate のビジネス的批判に対して応答してください
    - 「やらない」選択肢のリスクを最終評価してください
  """
)

Task(
  name="user-liaison",
  team_name="design-discussion",
  description="User Liaison: ユーザー質問管理",
  subagent_type="design-discussion:user-liaison",
  mode="bypassPermissions",
  run_in_background=True,
  prompt="""
    [共通コンテキスト]
    チームメンバー: solution-architect, engineer, product-manager, devils-advocate

    【このステップで特に確認すべき事項】
    - スコアリング結果に対するユーザーの感想（重視する評価軸はどれか）
    - Devil's Advocate の指摘をどこまで許容するか（リスク許容度）
    - エージェント間で対立が残っている場合、その対立点への判断
    議論が膠着状態になったら能動的にユーザーに判断を求めてください。
  """
)

# R3: Devil's Advocate（別ラウンドで起動）
Task(
  name="devils-advocate",
  team_name="design-discussion",
  description="Devil's Advocate: 合意案の批判",
  subagent_type="design-discussion:devils-advocate",
  mode="bypassPermissions",
  run_in_background=True,
  prompt="""
    [共通コンテキスト]
    チームメンバー: solution-architect, engineer, product-manager

    現時点の合意案に対して、以下を実行してください:
    1. 致命的な欠陥・見落としを全力で発掘する
    2. 前提条件の崩壊シナリオを提示する
    3. 最悪ケースシナリオを3つ挙げる
    4. 各指摘の重大度（致命的/重大/軽微）を分類する

    現時点の合意案:
    [合意内容を挿入]

    スコアリング結果:
    [スコアリング表を挿入]
  """
)
```

---

## Step 4: 推奨案の決定・アクションプラン

**参加エージェント**: solution-architect（リード）+ user-liaison（ユーザー承認）

```python
Task(
  name="solution-architect",
  team_name="design-discussion",
  description="Solution Architect: 推奨案の決定とADR作成",
  subagent_type="design-discussion:solution-architect",
  mode="bypassPermissions",
  run_in_background=True,
  prompt="""
    [共通コンテキスト]
    前ステップの結果: [3_comparison.md の内容]
    チームメンバー: user-liaison

    Step 4: 推奨案の決定とアクションプラン
    - スコアリングと議論の結果から推奨案を決定してください
    - 選定理由を明確に説明してください
    - ADR（Architecture Decision Record）ドラフトを作成してください
    - 実装アクションリストを作成してください
    - user-liaison を通じてユーザーの承認を得てください
  """
)

Task(
  name="user-liaison",
  team_name="design-discussion",
  description="User Liaison: 最終承認の取得",
  subagent_type="design-discussion:user-liaison",
  mode="bypassPermissions",
  run_in_background=True,
  prompt="""
    [共通コンテキスト]
    チームメンバー: solution-architect

    Step 4: ユーザーへの最終提案
    - Solution Architect が作成した推奨案をユーザーに提示してください
    - 却下した案と理由を含めてください
    - ユーザーの最終判断を取得してください
    - 判断理由を記録してください
  """
)
```
