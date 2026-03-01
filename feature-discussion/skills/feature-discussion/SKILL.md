---
name: feature-discussion
description: 既存アプリへの新機能追加を壁打ちで検討するスキル。「この機能どうしよう」「新機能を考えたい」「要件を整理したい」「壁打ちしたい」などと言及した時に使用。課題の深掘りから要件定義、UI設計プロンプト生成まで段階的に進行。
allowed-tools: "Read, Write, Edit, Glob, Grep, Task, TeamCreate, TeamDelete, WebSearch, AskUserQuestion"
---

# Feature Discussion - Agent Team 機能検討スキル

6つの専門エージェント（PM・UXアナリスト・エンジニア・デザイナー・行動心理学者・User Liaison）が**議論・反論し合いながら**新機能を検討するスキル。
Facilitator（このSKILL.md自身）がオーケストレーションし、User Liaisonがユーザーへの質問を一元管理する。

## 前提条件（CRITICAL）

**ペルソナが事前に作成済みであること**。

セッション開始時、以下をチェック：
1. `Glob`で `docs/personas/*.md` または `.claude/personas/*.md` を検索
2. ペルソナファイルが見つかった場合 → 読み込んで全エージェントにコンテキストとして渡す
3. ペルソナファイルが見つからない場合 → ユーザーに案内：

```
ペルソナが見つかりませんでした。
先に `/persona-creation` でペルソナを作成してください。
ペルソナがあると、各エージェントがユーザー視点で議論できます。
```

## チーム構成

| ロール | ファイル | 専門領域 |
|--------|---------|---------|
| **Facilitator** | この SKILL.md | 議論進行・合意形成・記録 |
| **User Liaison** | `agents/user-liaison.md` | ユーザーへの質問一元管理・タイミング判定・回答ルーティング |
| **Product Manager** | `agents/product-manager.md` | 課題構造化・優先度・スコープ・ビジネス価値 |
| **UX Analyst** | `agents/ux-analyst.md` | ペルソナ視点評価・ユーザーストーリー・行動分析 |
| **Engineer** | `agents/engineer.md` | コードベース調査・技術的実現性・工数評価 |
| **Designer** | `agents/designer.md` | UI/UX案・インタラクション設計・代替UI |
| **Behavioral Psychologist** | `agents/behavioral-psychologist.md` | 認知バイアス・習慣形成・動機付け・意思決定 |
| **Affordance Tester** | `agents/affordance-tester.md` | 初見理解度・アフォーダンス・ラベル自明性・認知的ウォークスルー |

## コア原則

1. **議論ファースト** - エージェント同士が反論・批判し合い、アイデアを磨く
2. **すぐに解決策を出さない** - まず「なぜ？」を深掘りする
3. **コードファーストの調査** - 質問前にコードを把握する
4. **ペルソナドリブン** - 常にペルソナの視点で評価する
5. **各ステップを確実に完了** - 進捗をJSONで管理
6. **行動の現実を直視する** - ユーザーが合理的に行動する前提を疑う
7. **待ちすぎない** - 2人以上のエージェントから反応があれば次へ進む
8. **実質的な議論のみ** - 「了解」だけの応答は不要。反論・提案・質問がある時のみ発言

## ワークフロー概要

```
Step 1: 課題・目的の深掘り
  担当: PM + UX Analyst + Behavioral Psychologist
  BP: 「この課題は本当に行動レベルの問題か？」を問う

    ↓
Step 2: 代替案・既存機能の検討
  担当: 全員参加
  BP: 各案の「行動実現性」を評価、習慣ループの有無をチェック
  AT: 各案の「初見理解度」を評価、ラベル・操作の自明性をチェック

    ↓
Step 3: スコープ決定
  担当: PM + Engineer + UX Analyst + Behavioral Psychologist
  BP: MVP段階で習慣ループの「報酬」が含まれているかチェック

    ↓
Step 4: 要件定義
  担当: UX Analyst + PM + Engineer + Behavioral Psychologist + Affordance Tester
  BP: ユーザーストーリーの動機が内発的かチェック
  AT: 操作フローの各ステップで初見ユーザーが迷わないかチェック

    ↓
Step 5: UI設計プロンプト生成
  担当: Designer + UX Analyst + Behavioral Psychologist + Affordance Tester + 全員レビュー
  BP: 認知負荷、選択麻痺、デフォルト設計をチェック
  AT: 認知的ウォークスルーを実施、各UI要素の初見理解度をスコアリング
```

各ステップの詳細は `references/step_details.md` を参照。

## 各ステップの議論フロー（CRITICAL）

**各ステップで以下の順序を実行する**。詳細は `references/discussion_protocol.md` を参照。

1. **整合性チェック**: 前ステップの成果物との矛盾を検出（`references/quality_control.md`）
2. **R1 チーム議論**: 担当エージェントを Agent Teams で起動、SendMessage で最初から相互に議論・反論・スコアリングまで実施
3. **R2 Devil's Advocate**: 全員が合意案を破壊しにかかる
4. **R3 統合**: 合意・対立・懸念・質問をまとめてユーザーに提示
5. **Quality Gate**: 品質基準を満たしているかチェック（`references/quality_control.md`）

議論深さモード（Light/Standard/Deep）でラウンド回数を調整。詳細は `references/discussion_depth.md` を参照。

## セッション開始

壁打ちセッション開始時、以下を実行：

1. **ペルソナファイルをチェック**（前提条件セクション参照）
2. **ドメインドキュメントを読み込み**（`references/external_research.md` 参照）
3. **セッション名（feature-slug）を生成**:
   - 機能名を英語のkebab-caseスラッグに変換
   - 日本語の場合は英訳してからスラッグ化
4. `.claude/feature_discussion/sessions/<feature-slug>/` ディレクトリを作成
5. `session.json` を作成
6. `discussion_log.md` を作成
7. **議論深さモードを自動判定**（`references/discussion_depth.md` 参照）- ユーザーへの確認は不要、自動判定結果を通知のみ
8. **Agent Team を作成**（`references/discussion_protocol.md` の「チームライフサイクル」参照）
9. Step 1 を開始

### 初期JSONテンプレート

```json
{
  "sessionId": "<feature-slug>",
  "feature": "<機能名>",
  "status": "in_progress",
  "mode": "<light|standard|deep>",
  "currentStep": 1,
  "personas": ["<読み込んだペルソナファイルのパス>"],
  "createdAt": "<ISO8601>",
  "updatedAt": "<ISO8601>",
  "steps": {
    "1_purpose": false,
    "2_alternatives": false,
    "3_scope": false,
    "4_requirements": false,
    "5_ui_prompt": false
  }
}
```

## セッション管理コマンド

| 発言 | アクション |
|------|----------|
| 「壁打ち開始：〇〇機能」 | 新規セッション作成、ペルソナチェック、Step 1開始 |
| 「次のステップ」「進めて」 | 現在のステップを完了し次へ |
| 「戻って」「前のステップ」 | 前のステップに戻る |
| 「今どこ？」「進捗は？」 | 現在のステップと完了状況を表示 |
| 「もっと議論して」 | 現在のステップで追加の議論ラウンドを実行 |
| 「一覧」「セッション一覧」 | 過去のセッション一覧を表示 |
| 「再開：〇〇」 | 指定セッションを再開 |

## 進行時の表示フォーマット

各ステップ開始時：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Feature Discussion: <機能名>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
現在: Step <N>/5 - <ステップ名>
進捗: [██████░░░░] 60%
モード: <Light|Standard|Deep>
担当: <リードエージェント> + <サブエージェント>
ペルソナ: <読み込んだペルソナ名>

エージェントチームが議論中...
```

議論結果提示時：
```
━━━━ チーム議論結果 ━━━━

✅ 合意: [全員が同意した点]
⚡ 対立: [論点と各エージェントの立場]

どう判断しますか？
```

ステップ完了時：
```
✅ Step <N> 完了: <ステップ名>
   → <簡潔なサマリー>
   → 議論ラウンド: <N>回
   → 対立解決: <N>件

次へ進みますか？（「次へ」で続行）
```

## 壁打ちの心得

### エージェント議論のルール

1. **遠慮しない** - 他のエージェントの提案に問題があれば率直に指摘する
2. **根拠を示す** - 反論には必ず理由（技術的制約、ペルソナデータ、ビジネス指標）を付ける
3. **建設的に** - 否定だけでなく、代替案も提示する
4. **ペルソナを忘れない** - 議論が技術寄りになったらUX Analystがペルソナ視点に引き戻す

### Facilitatorの役割

1. **傾聴する** - まずユーザーの話を聞く
2. **議論を促す** - エージェント間の意見対立を恐れない
3. **整理する** - 合意点と対立点を構造化して返す
4. **理由を記録する** - ユーザーの判断理由を必ず確認し記録する（`references/discussion_protocol.md`）
5. **記録する** - 全ての議論を議事録に残す

**注**: ユーザーへの質問は Facilitator ではなく **User Liaison** が担当する。Facilitator は議論の進行と記録に集中する。

### User Liaisonの役割

1. **質問のゲートキーパー** - 各エージェントからの質問リクエストを受け取り、ユーザーに聞くべきか判定する
2. **質問の統合** - 重複する質問をまとめ、ユーザーの認知負荷を下げる
3. **適切なタイミング** - 議論がブロックされた時に即座に、関連質問はバッチで質問する
4. **回答のルーティング** - ユーザーの回答を関連エージェントに共有する
5. **能動的モニタリング** - 議論の膠着状態や不確実な前提を検出し、ユーザーに確認する

## セッション完了条件

全ステップが `true` の場合：
```json
{
  "status": "completed",
  "completedAt": "<ISO8601>",
  "steps": {
    "1_purpose": true,
    "2_alternatives": true,
    "3_scope": true,
    "4_requirements": true,
    "5_ui_prompt": true
  }
}
```

**生成物**:
- `session.json` - セッション進捗管理
- `discussion_log.md` - ディスカッション議事録（エージェント間の議論含む）
- `1_purpose.md` - 課題・目的の深掘り結果
- `2_alternatives.md` - 代替案検討結果（チーム議論付き）
- `3_scope.md` - スコープ定義結果（対立解決記録付き）
- `4_requirements.md` - 要件定義書（ペルソナベース）
- `5_ui_prompt.md` - UI設計プロンプト（レビュー済み）

## リファレンスインデックス

詳細ドキュメントはトピック別に分離。必要なファイルだけ `Read` する：

| ファイル | 内容 |
|---------|------|
| `references/discussion_protocol.md` | 議論プロトコル R1-R4、チームライフサイクル、収束条件、ユーザー判断追跡 |
| `references/user_question_protocol.md` | ユーザーへの質問の共通プロトコル（全エージェント共通）、User Liaison 経由のフォーマット |
| `references/agent_spawn_templates.md` | Step 1-5 のエージェント起動テンプレート、Devil's Advocate 起動パターン |
| `references/step_details.md` | Step 1-5 の詳細フロー（担当・目的・フロー・完了条件） |
| `references/quality_control.md` | Quality Gate（共通・固有基準）、ステップ間整合性チェック |
| `references/discussion_depth.md` | 議論深さモード（Light/Standard/Deep）、自動判定ルール |
| `references/external_research.md` | ドメインドキュメント連携、競合リサーチ、次スキル連携 |
| `references/discussion_log_format.md` | 議事録の記録フォーマット（ラウンド別） |
| `references/output_templates.md` | 成果物テンプレート（`1_purpose.md` 〜 `5_ui_prompt.md`） |
