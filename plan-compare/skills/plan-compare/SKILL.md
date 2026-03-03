---
name: plan-compare
description: |
  複数の実装アプローチを並列チームで設計・議論し、比較して最適な計画を選ぶスキル。
  各アプローチに専門グループ（architect, critic, risk-analyst）が付き、グループ内で議論して計画を洗練する。
  「どのアプローチがいいか比較したい」「複数の実装方法を検討したい」「計画を並べて比べたい」
  「実装方針を複数出して」「アプローチを比較」「どっちがいいか調べて」と言われた時に使用。
  実装タスクで迷いがある時、設計の選択肢が複数ある時にも積極的に使う。
---

# Plan Compare

1つの実装タスクに対して複数の実装アプローチを並列で設計・議論し、
比較レポートで最適な計画を選択して実装に進むスキル。

**重要: このスキルを読んだあなた（メインの Claude）が直接チームを作成し、エージェントを起動する。
サブエージェントに TeamCreate を委任してはいけない（サブエージェントは TeamCreate を使えない）。**

## Architecture

フラットチーム構成。あなたが TeamCreate で1つのチームを作り、
全エージェントをその中に spawn する。各グループは SendMessage で議論する。

```
あなた (team lead / coordinator)
  │
  │  TeamCreate("plan-compare-{slug}")
  │
  ├─ Phase 1: Explore agent でコードベース調査（チーム外、先行実行）
  │
  ├─ Phase 2: 全エージェントを一斉に spawn
  │   Group 1: plan-1-architect ←→ plan-1-critic ←→ plan-1-risk
  │   Group 2: plan-2-architect ←→ plan-2-critic ←→ plan-2-risk
  │   Group 3: plan-3-architect ←→ plan-3-critic ←→ plan-3-risk
  │
  ├─ Phase 3: 全グループ完了後、comparison agent で比較
  │
  └─ Phase 4: ユーザー選択 → 実装
```

## Workflow

### Phase 1: コードベース調査

チーム作成の **前に** Explore エージェントでコードベースを調査する。
（Explore はチームに属さないスタンドアロン呼び出し）

```
Agent(subagent_type="Explore") で以下を調査:
- タスクに関連するファイル・モジュールの特定
- 現在の実装パターン・アーキテクチャ
- 依存関係・制約事項
- テストの状態
```

調査結果をもとに:
1. 出力ディレクトリ `.claude/plans/plan-compare-{task-slug}/` を作成する
2. 調査結果を `{output_dir}/research.md` に保存する
3. 実装可能なアプローチを N個 決定する

アプローチの数は以下を基準に判断する:
- 明確に異なる技術選択がある → その数だけ（例: REST vs GraphQL vs tRPC = 3つ）
- 段階的な複雑さの違い → 3つ（シンプル / バランス / 本格的）
- 設計パターンの違い → その数だけ（最低2つ、最大5つ）

### Phase 2: チーム作成とエージェント起動

**あなた自身が** 以下の手順を実行する。サブエージェントには委任しない。

#### Step 1: チーム作成

```
TeamCreate(team_name="plan-compare-{task-slug}")
```

#### Step 2: タスク作成

各グループ（N個）について、4つのタスクを作成する。
タスクの依存関係が正しくないと議論が成り立たないので注意。

```
Group {n} のタスク:

  TaskCreate: "plan-{n}-architect: {approach_name} の初期設計を提案"
    → TaskUpdate で owner を "plan-{n}-architect" に設定

  TaskCreate: "plan-{n}-critic: 設計をレビュー"
    → TaskUpdate で owner を "plan-{n}-critic"、addBlockedBy で上記タスクを指定

  TaskCreate: "plan-{n}-risk: リスク分析"
    → TaskUpdate で owner を "plan-{n}-risk"、addBlockedBy で architect のタスクを指定

  TaskCreate: "plan-{n}-architect: フィードバック反映 → 最終版作成"
    → TaskUpdate で owner を "plan-{n}-architect"、addBlockedBy で critic と risk のタスクを指定
```

3グループなら計12タスクを作成する。

#### Step 3: 全エージェントを一斉に spawn

**1つのメッセージで全エージェントを並列起動する。**
Agent ツールを N×3 回呼び出す（3グループなら9回）。

各エージェントの起動パラメータ:

```
Agent(
  subagent_type="pc-plan-architect",  // or pc-plan-critic, pc-plan-risk
  name="plan-{n}-architect",          // チーム内での名前
  team_name="plan-compare-{task-slug}",
  prompt="{下記のテンプレート}"
)
```

#### エージェントへのプロンプトテンプレート

**architect 用:**
```
## タスク
{ユーザーのタスク}

## コードベース調査結果
以下のファイルを読んでください: {output_dir}/research.md

## あなたの担当
- アプローチ名: {approach_name}
- アプローチ方針: {approach_description}
- あなたの役割: architect（設計担当）

## あなたのグループメンバー
- plan-{n}-architect: 設計担当（あなた）
- plan-{n}-critic: 批評担当
- plan-{n}-risk: リスク分析担当

## ワークフロー
1. TaskList でタスクを確認し、自分のタスクを in_progress にする
2. コードベースを調査し、担当アプローチの実装設計を具体化する
3. 設計案を SendMessage で plan-{n}-critic と plan-{n}-risk に送る
4. タスクを completed にする
5. TaskList で次のタスク（フィードバック反映）を確認する
6. critic と risk からのフィードバックを待ち、反映して最終版を作成する
7. 最終計画書を {output_dir}/plan-{n}-{approach_slug}.md に Write で出力する
8. タスクを completed にする

## 計画書フォーマット
# {アプローチ名}
## 概要
## 実装手順（ステップバイステップ、対象ファイル・変更内容を含む）
## 変更対象ファイル（テーブル形式）
## 技術的な詳細
## リスクと対策（critic/risk の指摘を踏まえて）
## 見送った代替案（議論で検討したが採用しなかった選択肢）

## 重要
- SendMessage は自分のグループメンバー（plan-{n}-critic, plan-{n}-risk）にだけ送ること
- 他のグループ（plan-{m}-*）には送らない
```

**critic 用:**
```
## タスク
{ユーザーのタスク}

## コードベース調査結果
以下のファイルを読んでください: {output_dir}/research.md

## あなたの担当
- アプローチ名: {approach_name}
- あなたの役割: critic（批評担当）

## あなたのグループメンバー
- plan-{n}-architect: 設計担当
- plan-{n}-critic: 批評担当（あなた）
- plan-{n}-risk: リスク分析担当

## ワークフロー
1. TaskList でタスクを確認し、architect のタスク完了を待つ
2. architect から SendMessage で設計案が届く
3. 自分のタスクを in_progress にする
4. 設計案を批判的に評価する（実現性、シンプルさ、保守性、テスト容易性）
5. 関連コードを自分でも Grep/Glob で裏取りする
6. フィードバックを SendMessage で plan-{n}-architect に送る
7. タスクを completed にする

## フィードバック形式
良い点 / 懸念点 / 改善提案 の3セクションで構造化する

## 重要
- SendMessage は自分のグループメンバーにだけ送ること
- 際限なく批判せず、1ラウンドで収束させる
```

**risk 用:**
```
## タスク
{ユーザーのタスク}

## コードベース調査結果
以下のファイルを読んでください: {output_dir}/research.md

## あなたの担当
- アプローチ名: {approach_name}
- あなたの役割: risk-analyst（リスク分析担当）

## あなたのグループメンバー
- plan-{n}-architect: 設計担当
- plan-{n}-critic: 批評担当
- plan-{n}-risk: リスク分析担当（あなた）

## ワークフロー
1. TaskList でタスクを確認し、architect のタスク完了を待つ
2. architect から SendMessage で設計案が届く
3. 自分のタスクを in_progress にする
4. 影響範囲を調査する（Grep で参照箇所、Glob で関連ファイル）
5. リスク分析を SendMessage で plan-{n}-architect に送る
6. タスクを completed にする

## リスク分析形式
影響範囲 / リスク一覧（高/中/低） / マイグレーション要件 / ロールバック計画

## 重要
- SendMessage は自分のグループメンバーにだけ送ること
- リスクには必ず対策案をセットで提示する
```

#### Step 4: 議論の監視

エージェントを起動したら、TaskList を定期的に確認して進捗を監視する。
全グループの最終タスク（architect のフィードバック反映）が completed になったら Phase 3 に進む。

### Phase 3: 比較分析

全グループの計画書が完成したら:

1. チームメンバー全員に shutdown_request を送る
2. TeamDelete でチームを片付ける
3. 比較エージェントを起動する（チーム外のスタンドアロン呼び出し）

```
Agent(subagent_type="general-purpose") で:
- 全プランファイル + research.md を読み込み
- 以下の観点で比較:
  - 実装の複雑さ（変更ファイル数・ステップ数）
  - 変更のリスク（破壊的変更の有無）
  - 保守性・拡張性
  - 実装コスト（工数の見積もり）
  - テスト容易性
  - 既存パターンとの整合性
- 比較マトリクスを作成
- 推奨アプローチとその理由を明記
- {output_dir}/comparison.md に出力
```

### Phase 4: ユーザー選択と実装

1. 比較レポートの要点をユーザーに提示する
2. AskUserQuestion でどのプランで進めるか確認する

```
AskUserQuestion:
  question: "どのアプローチで実装しますか？"
  options: [各プランの名前 + 1行サマリー]
```

3. ユーザーが選択したら:
   a. 選択されたプランの内容を Plan mode の plan ファイルにコピー
   b. EnterPlanMode で Plan mode に移行
   c. プランの詳細を plan ファイルに展開（必要に応じて AskUserQuestion で不明点を確認）
   d. ExitPlanMode でユーザーの承認を得る
   e. 承認後、実装を開始（実装中も随時 AskUserQuestion で確認）

## Output Directory

```
.claude/plans/plan-compare-{task-slug}/
  research.md                    ← コードベース調査結果
  plan-1-{approach-slug}.md      ← プラン 1
  plan-2-{approach-slug}.md      ← プラン 2
  plan-3-{approach-slug}.md      ← プラン 3
  comparison.md                  ← 比較レポート
```

## Error Handling

- グループの1つが失敗した場合: 他のグループの結果だけで比較を進める（最低2つあれば続行）
- コードベース調査で十分な情報が得られない場合: AskUserQuestion でユーザーに追加情報を求める
- 全グループが同じアプローチに収束した場合: その旨をユーザーに伝え、1つのプランとして扱う
- エージェントが応答しない場合: 60秒待っても TaskList で進捗がなければ、そのグループをスキップ

## Notes

- 全エージェントは `model: opus` で起動する（CLAUDE.md のルール）
- グループ内の通信は SendMessage で行い、グループ外には送信しない
- エージェントは `.claude/agents/` に定義: pc-plan-architect, pc-plan-critic, pc-plan-risk
- **TeamCreate はあなた（メイン Claude）が直接実行する。サブエージェントには委任しない。**
- Phase 1 の Explore と Phase 3 の比較はチーム外のスタンドアロン呼び出しで行う
