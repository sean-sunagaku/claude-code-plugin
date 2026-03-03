# Planning

機能検討・技術設計の議論・実装計画の策定

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| **team-plan** | `/team-plan` | 5つの専門エージェント（コード調査・依存分析・パターン分析・ソリューション設計・計画書作成）がチームでコードベースを調査・議論・合意形成し、Plan Modeで実装計画を作成する。調査エージェントはExploreサブエージェントを無制限に並列起動可能 |
| **team-implement** | `/team-implement` |  承認済みの実装計画（Plan）を Agent Team で並列に実装するスキル。 Plan をタスクに分割 → 依存関係を設定 → Wave ごとに並列エージェントを起動 → 完了を待って次の Wave → 最後にビルド＆テスト検証。 team-plan スキル（調査→計画）の後に使う「実装実行フェーズ」。 |
| **feature-discussion** [Beta] | `/feature-discussion` | 6つの専門エージェント（PM・UXアナリスト・エンジニア・デザイナー・行動心理学者・User Liaison）が議論・反論し合いながら新機能を検討するスキル。User Liaisonがユーザーへの質問を一元管理し、議論中に適切なタイミングでユーザー入力を取得。課題の深掘りから要件定義、UI設計プロンプト生成まで5ステップで段階的に進行。5軸スコアリング、Devil's Advocate、Quality Gate搭載 |
| **design-discussion** | `/design-discussion` | 5人の専門エージェントチーム（solution-architect・engineer・product-manager・user-liaison・devil's-advocate）で技術設計を壁打ちするスキル。実装アプローチの比較・技術設計の選択・アーキテクチャの意思決定に特化。ADR形式で決定を記録 |

### team-plan

5つの専門エージェント（コード調査・依存分析・パターン分析・ソリューション設計・計画書作成）がチームでコードベースを調査・議論・合意形成し、Plan Modeで実装計画を作成する。調査エージェントはExploreサブエージェントを無制限に並列起動可能

5つの専門エージェントがチームでコードベースを調査・議論し、

```
/team-plan
```

### team-implement

 承認済みの実装計画（Plan）を Agent Team で並列に実装するスキル。 Plan をタスクに分割 → 依存関係を設定 → Wave ごとに並列エージェントを起動 → 完了を待って次の Wave → 最後にビルド＆テスト検証。 team-plan スキル（調査→計画）の後に使う「実装実行フェーズ」。

承認済みの実装計画を **Agent Team (TeamCreate + TaskCreate) で並列に実装**するスキル。

```
/team-implement
```

### feature-discussion [Beta]

6つの専門エージェント（PM・UXアナリスト・エンジニア・デザイナー・行動心理学者・User Liaison）が議論・反論し合いながら新機能を検討するスキル。User Liaisonがユーザーへの質問を一元管理し、議論中に適切なタイミングでユーザー入力を取得。課題の深掘りから要件定義、UI設計プロンプト生成まで5ステップで段階的に進行。5軸スコアリング、Devil's Advocate、Quality Gate搭載

6つの専門エージェント（PM・UXアナリスト・エンジニア・デザイナー・行動心理学者・User Liaison）が**議論・反論し合いながら**新機能を検討するスキル。

```
/feature-discussion
```

### design-discussion

5人の専門エージェントチーム（solution-architect・engineer・product-manager・user-liaison・devil's-advocate）で技術設計を壁打ちするスキル。実装アプローチの比較・技術設計の選択・アーキテクチャの意思決定に特化。ADR形式で決定を記録

5つの専門エージェント（Solution Architect・Engineer・Product Manager・User Liaison・Devil's Advocate）が

```
/design-discussion
```

---

[< Back to top](../README.md)
