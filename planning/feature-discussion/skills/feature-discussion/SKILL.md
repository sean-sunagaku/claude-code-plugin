---
name: feature-discussion
description: 機能検討・プロダクト機能設計の壁打ちスキル。Mode A「壁打ち開始：〇〇機能」で1機能を深掘り、Mode B「アプリの機能を考えたい」でアプリ全体の機能セットを設計。ペルソナ・競合分析・トンマナを統合して議論。
allowed-tools: "Read, Write, Edit, Glob, Grep, Task, TeamCreate, TeamDelete, WebSearch, AskUserQuestion"
---

# Feature Discussion - Agent Team 機能検討スキル

6つの専門エージェント（PM・UXアナリスト・エンジニア・デザイナー・行動心理学者・User Liaison）が**議論・反論し合いながら**機能を検討するスキル。
Facilitator（このSKILL.md自身）がオーケストレーションし、User Liaisonがユーザーへの質問を一元管理する。

## 2つのモード

### Mode A: 機能壁打ち (Feature Discussion)

**1つの具体的な機能**について深掘りする。既存アプリへの機能追加・改善が対象。

**トリガー**: 「壁打ち開始：〇〇機能」「〇〇を追加したい」「〇〇の改善」

### Mode B: プロダクト機能設計 (Product Feature Planning)

**アプリ全体の機能セット**を設計する。競合分析・ペルソナ作成後に「何を作るべきか」を議論する。

**トリガー**: 「アプリの機能を考えたい」「何を作るべきか」「機能一覧を決めたい」「プロダクト企画」「機能設計」

**前提**: product-discovery, competitive-analysis, personas が完了済みであること。

### モード自動判定

ユーザーの発言から自動判定。判定結果をユーザーに通知し、誤っていれば修正する。

| パターン | 判定 |
|---------|------|
| 「壁打ち開始：〇〇」「〇〇機能」「〇〇を追加」「〇〇の改善」 | Mode A |
| 「アプリの機能を考えたい」「何を作るべきか」「機能一覧」「機能設計」「プロダクト企画」「全体設計」 | Mode B |

## 前提条件（CRITICAL）

### 共通: ペルソナ

**ペルソナが事前に作成済みであること**。

セッション開始時、以下をチェック：
1. `Glob`で `docs/personas/**/*.md` または `.claude/personas/*.md` を検索
2. ペルソナファイルが見つかった場合 → 読み込んで全エージェントにコンテキストとして渡す
3. ペルソナファイルが見つからない場合 → ユーザーに案内：

```
ペルソナが見つかりませんでした。
先に `/persona-creation` でペルソナを作成してください。
ペルソナがあると、各エージェントがユーザー視点で議論できます。
```

### Mode B 追加: リサーチ資料

Mode B ではペルソナに加えて、以下の資料を自動検出・読み込む。
全て必須ではないが、あるほど議論の質が上がる。

| 資料 | 検索パス | 用途 |
|------|---------|------|
| プロダクトコンテキスト | `docs/product-context.md`, `.claude/product-discovery/` | プロダクトビジョン・課題仮説・ビジネスモデル |
| 競合分析 | `.claude/competitive-analysis/`, `docs/competitive-analysis/` | 競合の強み弱み・差別化ポイント・ERRC |
| トンマナ | `.claude/app-tone-manner/*/TONE_MANNER_REPORT.md` | ブランドパーソナリティ・デザイン変数 |
| 市場調査 | `.claude/market-research/`, `docs/market-research/` | 市場規模・トレンド・ユーザー需要 |
| ユーザージャーニー | `.claude/user-journey/`, `docs/user-journey/` | ユーザー行動パターン・タッチポイント |

**読み込み優先度**: ペルソナ（必須） > プロダクトコンテキスト > 競合分析 > その他

見つからない資料がある場合：
```
以下の資料が見つかりませんでした（推奨）：
- 競合分析 → `/competitive-analysis` で作成できます
- プロダクトコンテキスト → `/product-discovery` で作成できます

資料なしでも進められますが、議論の精度が下がります。
このまま進めますか？
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
3. **コードファーストの調査** - 質問前にコードを把握する（Mode A）/ リサーチ資料を把握する（Mode B）
4. **ペルソナドリブン** - 常にペルソナの視点で評価する
5. **各ステップを確実に完了** - 進捗をJSONで管理
6. **行動の現実を直視する** - ユーザーが合理的に行動する前提を疑う
7. **待ちすぎない** - 2人以上のエージェントから反応があれば次へ進む
8. **実質的な議論のみ** - 「了解」だけの応答は不要。反論・提案・質問がある時のみ発言
9. **競合との差別化** - Mode B では常に「競合と何が違うか」を意識する

## ワークフロー概要

### Mode A: 機能壁打ち

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

### Mode B: プロダクト機能設計

```
Step P1: コンテキスト統合
  担当: PM（リード）+ UX Analyst + Behavioral Psychologist
  目的: 全リサーチ資料を統合し、「誰の何を解決するプロダクトか」を全員で合意
  入力: product-context, competitive-analysis, personas, tone-manner
  PM: プロダクトビジョンを言語化
  UX: ペルソナのJTBD（Jobs-to-be-Done）を整理
  BP: ペルソナの行動パターンから「本当に必要な価値」を抽出

    ↓
Step P2: 機能アイデア発想
  担当: 全員参加
  目的: ペルソナのJTBD・競合ギャップ・ビジョンから機能候補を網羅的にリストアップ
  PM: ビジネス価値の高い機能を提案
  UX: ペルソナが求める機能を提案（ペルソナ別に）
  Engineer: 技術的に差別化できる機能を提案
  Designer: UX的にインパクトのある機能を提案
  BP: 習慣形成に必要な機能を提案（Hook Model）
  AT: 初見ユーザーが求める基本機能を確認

    ↓
Step P3: 機能優先度決定
  担当: PM（リード）+ UX Analyst + Engineer + Behavioral Psychologist
  目的: 全機能候補を優先度マトリクスで評価・グルーピング
  PM: Impact/Effort マトリクス、ビジネス価値スコアリング
  UX: ペルソナ価値スコア（各ペルソナ別）
  Engineer: 技術的実現性・工数見積もり
  BP: 習慣形成への貢献度、行動実現性スコア

    ↓
Step P4: MVP機能セット定義
  担当: PM + UX Analyst + Engineer + Behavioral Psychologist + Affordance Tester
  目的: MVP/Phase2/Phase3 に分類し、各機能の概要要件を定義
  PM: MVP の線引き判断
  UX: 各ペルソナのコアジャーニーがMVPで完結するか確認
  Engineer: 技術的依存関係から実装順序を提案
  BP: MVPで習慣ループ（きっかけ→行動→報酬）が成立するか検証
  AT: MVPの機能セットだけで初見ユーザーが価値を理解できるか検証

    ↓
Step P5: 画面構成 & UI設計プロンプト生成
  担当: Designer（リード）+ UX Analyst + Engineer + Behavioral Psychologist + Affordance Tester
  目的: 画面マップ・ナビゲーション構造・各画面のUI設計プロンプトを生成
  Designer: 画面一覧・遷移図・各画面のレイアウト（ASCII art）
  UX: ペルソナ別の導線設計（ペルソナごとの「最初に見る画面」「主要フロー」）
  Engineer: 技術的に必要な画面（設定、認証など）を補完
  BP: 認知負荷チェック、初回体験フローの設計
  AT: 認知的ウォークスルー、画面遷移の自明性評価
```

各ステップの詳細は `references/step_details.md` を参照。

## 各ステップの議論フロー（CRITICAL）

**Mode A / Mode B 共通。各ステップで以下の順序を実行する**。詳細は `references/discussion_protocol.md` を参照。

1. **整合性チェック**: 前ステップの成果物との矛盾を検出（`references/quality_control.md`）
2. **R1 チーム議論**: 担当エージェントを Agent Teams で起動、SendMessage で最初から相互に議論・反論・スコアリングまで実施
3. **R2 Devil's Advocate**: 全員が合意案を破壊しにかかる
4. **R3 統合**: 合意・対立・懸念・質問をまとめてユーザーに提示
5. **Quality Gate**: 品質基準を満たしているかチェック（`references/quality_control.md`）

議論深さモード（Light/Standard/Deep）でラウンド回数を調整。詳細は `references/discussion_depth.md` を参照。

## セッション開始

### 共通手順

1. **モードを自動判定**（「2つのモード」セクション参照）→ ユーザーに通知
2. **ペルソナファイルをチェック**（前提条件セクション参照）
3. **セッション名（slug）を生成**:
   - Mode A: 機能名を英語のkebab-caseスラッグに変換
   - Mode B: `product-planning-<日付>` または プロダクト名のスラッグ
4. `.claude/feature_discussion/sessions/<slug>/` ディレクトリを作成
5. `session.json` を作成（モード別テンプレート）
6. `discussion_log.md` を作成
7. **議論深さモードを自動判定**（`references/discussion_depth.md` 参照）
8. **Agent Team を作成**（`references/discussion_protocol.md` の「チームライフサイクル」参照）

### Mode A 追加手順

9. **ドメインドキュメントを読み込み**（`references/external_research.md` 参照）
10. Step 1 を開始

### Mode B 追加手順

9. **リサーチ資料を読み込み**（前提条件 Mode B セクション参照）
   - product-context, competitive-analysis, personas, tone-manner, market-research, user-journey
   - 全て読み込んで要約をエージェントコンテキストに含める
10. **読み込んだ資料のサマリーをユーザーに表示**:
```
━━━━ 読み込んだリサーチ資料 ━━━━

  ペルソナ: 3名（拓真・彩・隼人）
  プロダクトコンテキスト: あり（課題仮説・ビジネスモデル定義済み）
  競合分析: あり（直接競合3社・間接競合5社）
  トンマナ: あり（Intellectual but Approachable）
  市場調査: なし（→ 推奨: `/market-research`）
  ユーザージャーニー: なし

上記の資料をもとに、機能設計を始めます。
```
11. Step P1 を開始

### 初期JSONテンプレート

#### Mode A
```json
{
  "sessionId": "<feature-slug>",
  "feature": "<機能名>",
  "sessionMode": "feature",
  "status": "in_progress",
  "depthMode": "<light|standard|deep>",
  "currentStep": 1,
  "personas": ["<ペルソナファイルのパス>"],
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

#### Mode B
```json
{
  "sessionId": "<product-slug>",
  "product": "<プロダクト名>",
  "sessionMode": "product-planning",
  "status": "in_progress",
  "depthMode": "<standard|deep>",
  "currentStep": "P1",
  "personas": ["<ペルソナファイルのパス>"],
  "researchSources": {
    "productContext": "<パス or null>",
    "competitiveAnalysis": "<パス or null>",
    "toneAndManner": "<パス or null>",
    "marketResearch": "<パス or null>",
    "userJourney": "<パス or null>"
  },
  "createdAt": "<ISO8601>",
  "updatedAt": "<ISO8601>",
  "steps": {
    "P1_context_synthesis": false,
    "P2_feature_ideation": false,
    "P3_prioritization": false,
    "P4_mvp_definition": false,
    "P5_screen_architecture": false
  }
}
```

## セッション管理コマンド

| 発言 | アクション |
|------|----------|
| 「壁打ち開始：〇〇機能」 | Mode A: 新規セッション作成、Step 1 開始 |
| 「アプリの機能を考えたい」「機能設計」 | Mode B: 新規セッション作成、Step P1 開始 |
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
📋 Feature Discussion: <機能名 or プロダクト名>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
モード: <Mode A: 機能壁打ち | Mode B: プロダクト機能設計>
現在: Step <N or PN>/5 - <ステップ名>
進捗: [██████░░░░] 60%
深さ: <Light|Standard|Deep>
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
✅ Step <N or PN> 完了: <ステップ名>
   → <簡潔なサマリー>
   → 議論ラウンド: <N>回
   → 対立解決: <N>件

次へ進みますか？（「次へ」で続行）
```

## 壁打ちの心得

### エージェント議論のルール

1. **遠慮しない** - 他のエージェントの提案に問題があれば率直に指摘する
2. **根拠を示す** - 反論には必ず理由（技術的制約、ペルソナデータ、ビジネス指標、競合データ）を付ける
3. **建設的に** - 否定だけでなく、代替案も提示する
4. **ペルソナを忘れない** - 議論が技術寄りになったらUX Analystがペルソナ視点に引き戻す
5. **競合を意識する（Mode B）** - 「競合と同じことをやっても意味がない」を常に意識する

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

### Mode A
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

### Mode B
全ステップが `true` の場合：
```json
{
  "status": "completed",
  "completedAt": "<ISO8601>",
  "steps": {
    "P1_context_synthesis": true,
    "P2_feature_ideation": true,
    "P3_prioritization": true,
    "P4_mvp_definition": true,
    "P5_screen_architecture": true
  }
}
```

**生成物**:
- `session.json` - セッション進捗管理
- `discussion_log.md` - ディスカッション議事録（エージェント間の議論含む）
- `P1_context_synthesis.md` - コンテキスト統合結果（プロダクトビジョン・JTBD・競合ギャップ）
- `P2_feature_ideation.md` - 機能アイデア一覧（ペルソナ別・カテゴリ別）
- `P3_prioritization.md` - 機能優先度マトリクス（スコアリング付き）
- `P4_mvp_definition.md` - MVP機能セット定義（概要要件・ペルソナジャーニー検証）
- `P5_screen_architecture.md` - 画面構成・遷移図・各画面UI設計プロンプト

## リファレンスインデックス

詳細ドキュメントはトピック別に分離。必要なファイルだけ `Read` する：

| ファイル | 内容 |
|---------|------|
| `references/discussion_protocol.md` | 議論プロトコル R1-R4、チームライフサイクル、収束条件、ユーザー判断追跡 |
| `references/user_question_protocol.md` | ユーザーへの質問の共通プロトコル（全エージェント共通）、User Liaison 経由のフォーマット |
| `references/agent_spawn_templates.md` | Mode A Step 1-5 / Mode B Step P1-P5 のエージェント起動テンプレート |
| `references/step_details.md` | Mode A Step 1-5 / Mode B Step P1-P5 の詳細フロー |
| `references/quality_control.md` | Quality Gate（共通・固有基準）、ステップ間整合性チェック |
| `references/discussion_depth.md` | 議論深さモード（Light/Standard/Deep）、自動判定ルール |
| `references/external_research.md` | ドメインドキュメント連携、競合リサーチ、次スキル連携 |
| `references/discussion_log_format.md` | 議事録の記録フォーマット（ラウンド別） |
| `references/output_templates.md` | 成果物テンプレート（Mode A / Mode B） |
