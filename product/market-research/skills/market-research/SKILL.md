---
name: market-research
description: >
  8つの専門エージェント（市場規模分析・トレンド調査・競合インテリジェンス・投資シグナル・日本市場・ユーザー需要分析・規制調査・データ検証）が
  ディスカッション型でアプリ/デジタルプロダクトの市場調査を実施するスキル。
  エージェント同士が対話・批判し合い、data-critic がライブモデレーターとして矛盾を検出・収束を判定する。
  トライアンギュレーション（データ・方法論・調査者・理論の4種類）をディスカッションに組み込み、
  確証バイアスを排除した信頼度付きレポートを出力する。
  Gate 1（全員参加の合意形成）→ Gate 2（最終検証 + Devil's Advocate）の2段階ゲートで品質を担保。
  コンテキストファイルで過去のセッションを引き継げる。
  Use when: 市場調査をしたい、TAM/SAM/SOMを算出したい、市場の成長性を調べたい、
  参入タイミングを判断したい、競合市場を分析したい、規制リスクを調べたい。
  Triggers: "市場調査", "market research", "TAM", "SAM", "SOM", "市場規模",
  "市場分析", "market analysis", "参入", "market entry", "市場性",
  "market viability", "市場トレンド", "market trend"
---

# Market Research Skill

8つの専門エージェントがディスカッション型で市場調査を実施し、
トライアンギュレーション検証済みの信頼度付き市場レポートを出力する。

エージェント同士が対話・批判し合いながら調査し、data-critic がライブモデレーターとして
矛盾を検出・収束を判定する。独立並列調査では見つからない矛盾を、リアルタイムの対話で解消する。

**重要原則: ユーザーへのレポート出力は常に詳細に。**
中間レポート・最終レポートを問わず、数字だけのサマリー表ではなく、
各主張に「なぜそう言えるのか」の根拠（出典・算出ロジック・交差検証結果）を必ず添える。
ユーザーが判断材料にできるレベルの詳細さを常に維持する。

## ワークフロー概要

```
Step 1: ヒアリング（必須情報 + 調査深度の合意）
Step 2: チーム作成・エージェント起動
Step 3: Phase 1 ディスカッション → Gate 1 → Phase 2 ディスカッション → Gate 2
Step 4: ファイル検証
Step 5: 統合レポート作成
Step 6: ユーザーへの最終報告
Step 7: クリーンアップ
```

## コンテキストファイル構成

保存先はユーザーが選択可能（Step 1 ヒアリングで確認）:

**A) リポジトリトップ（推奨）** — プロジェクトと一緒にバージョン管理したい場合:
```
{repo_root}/market-research/
├── MARKET_REPORT.md         <- 統合レポート（後続スキルがまず読むファイル）
├── context.md               <- プロジェクト情報・セッション引き継ぎ用
├── market-size.md           <- TAM/SAM/SOM 詳細計算（ディスカッション反映版）
├── trends.md                <- トレンド・成長率・ドライバー分析（ディスカッション反映版）
├── competitors.md           <- 競合深堀り + 逆算TAM
├── funding-signals.md       <- VC投資トレンド + EXIT事例
├── japan-market.md          <- 日本市場独自データ
├── demand-insights.md       <- ユーザー需要・課題・ペインポイント（ディスカッション反映版）
├── regulatory.md            <- 規制・参入障壁（ディスカッション反映版）
└── critique.md              <- ディスカッション経緯 + Gate 判定 + Devil's Advocate
```

**B) ホームディレクトリ** — リポジトリを汚したくない場合:
```
~/.claude/market-research/{YYYY-MM-DD}_{project}/
└── （同上のファイル構成）
```

---

## Step 1: ヒアリング

AskUserQuestion でユーザーから情報を収集する。不明な項目は推測せず必ず質問する。

### 必須（欠けていたら質問）

- **カテゴリ**: アプリのカテゴリ（例: フィットネス、家計管理）
- **ターゲット**: 想定ターゲット（例: 30代女性、子育て世帯）
- **地域**: 対象地域（例: 日本、日本+東南アジア）

### 任意（精度向上のため推奨 — ユーザーに「あれば教えてください」と提示）

- **収益モデル仮説**: フリーミアム / サブスク / 買い切り等
- **既知の競合**: 知っている競合アプリ名
- **既存リサーチ**: 既存調査データのパス
- **懸念リスク**: 特に懸念しているリスク
- **アプリ概要**: アプリの概要説明

### 調査設定（ユーザーに確認）

AskUserQuestion で以下を確認:

**「レポートの保存先を選んでください」**
- 選択肢1: 「リポジトリトップ（推奨）」→ `{cwd}/market-research/` に保存。`mkdir -p {cwd}/market-research/` で作成
- 選択肢2: 「ホームディレクトリ」→ `init.sh` で `~/.claude/market-research/{date}_{project}/` に作成

**「調査の進め方を確認させてください」**
- 選択肢1: 「途中で確認したい（推奨）」→ Gate 1 でユーザーチェックポイントを設ける
- 選択肢2: 「一気に最後まで」→ Gate 1 のユーザー確認をスキップ
- 選択肢3: 「重要な発見があれば都度教えて」→ Gate 1 + 各エージェントの重要発見時に報告

---

## Step 2: チーム作成とエージェント起動

TeamCreate で `market-research` チームを作成。

| name | 役割 | Phase | 主な手段 |
|------|------|-------|---------|
| `market-size-analyst` | TAM/SAM/SOM算出、Porter's Five Forces | Phase 1 | WebSearch, 数値計算 |
| `trend-researcher` | トレンド・タイミング調査、Sequoia Arc分類 | Phase 1 | WebSearch |
| `competitor-intelligence-analyst` | 競合深堀り + 逆算TAM | Phase 1 | WebSearch |
| `funding-signal-analyst` | VC投資トレンド + EXIT事例 | Phase 1 | WebSearch |
| `japan-market-specialist` | 日本市場独自データ | Phase 1 | WebSearch |
| `demand-analyst` | ユーザー需要・課題調査（レビュー、SNS、JTBD） | Phase 2 | WebSearch |
| `regulatory-researcher` | 規制・参入障壁・コンプライアンスコスト | Phase 2 | WebSearch |
| `data-critic` | ライブモデレーター + 検証ゲートキーパー | Phase 1 & 2 | 分析・批判的思考 |

各エージェントは `agents/` ディレクトリにサブエージェントとして定義済み。

### タスク作成

TaskCreate で以下を作成:

```
1. market-size-analyst: TAM/SAM/SOM算出 + Porter's Five Forces
2. trend-researcher: トレンド・タイミング調査
3. competitor-intelligence-analyst: 競合深堀り + 逆算TAM
4. funding-signal-analyst: VC投資トレンド + EXIT事例
5. japan-market-specialist: 日本市場独自データ
6. data-critic Phase 1 モデレーション: ディスカッションモデレート + Gate 1 合意形成
   （addBlockedBy は設定しない。Phase 1 エージェントと同時起動し、ライブモデレートする）
7. demand-analyst: ユーザー需要・課題調査（addBlockedBy: ["6"]）
8. regulatory-researcher: 規制・参入障壁調査（addBlockedBy: ["6"]）、7と並列
9. data-critic Gate 2: 最終検証 + Devil's Advocate（addBlockedBy: ["7", "8"]）
10. 統合レポート作成（addBlockedBy: ["9"]）
```

### 起動設定

```
subagent_type: "market-size-analyst"  # agents/ で定義済み
team_name: "market-research"
mode: "bypassPermissions"
run_in_background: true
```

プロンプトに含める情報（全エージェント共通）:
- カテゴリ、ターゲット、地域、その他ヒアリング情報
- **ベースディレクトリの絶対パス**（⚠️必須）: ユーザーが選択した保存先の絶対パスをそのまま使う
  - リポジトリトップの場合: `{cwd}/market-research/`（例: `/Users/user/my-app/market-research/`）
  - ホームディレクトリの場合: `init.sh` が出力する絶対パス（例: `~/.claude/market-research/2026-03-03_my-app/`）
  - ⚠️ Write ツールは絶対パスのみ受け付ける
- 「全ファイルは Write ツールで絶対パスに書き込むこと」を明記
- ユーザーが選んだ調査設定（中間確認あり/なし）
- **ディスカッションプロトコルの確認**: 各エージェント定義に埋め込み済みだが、「他エージェントと積極的に対話すること」を再度明記

---

## Step 3: ディスカッション型ラウンド進行

### ディスカッションプロトコル（全 Phase 共通）

全フェーズで以下の3ステップサイクルを繰り返す:

```
┌─────────────────────────────────────────────────┐
│ Step A: 独立調査                                  │
│   各エージェントが WebSearch で自分の担当領域を調査   │
│   初期発見をファイルに書き出し                       │
│                                                   │
│ Step B: 共有 + 批判                               │
│   各エージェントが主要発見を SendMessage で全員に共有  │
│   他エージェントが矛盾・疑問を指摘（批判テンプレート） │
│   data-critic が矛盾を可視化しモデレート            │
│                                                   │
│ Step C: 防御 / 修正 + 追加調査                     │
│   批判を受けたエージェントが根拠を提示して防御        │
│   または追加調査して修正                            │
│   修正結果をファイルに反映                          │
│                                                   │
│ → 収束条件を満たすまで Step B-C を繰り返す          │
└─────────────────────────────────────────────────┘
```

#### 批判テンプレート

```
[CHALLENGE] → {対象エージェント名}
主張: {相手の主張を要約}
問題: {矛盾・疑問の具体的内容}
根拠: {自分のデータ/ロジック}
提案: {修正案 or 追加調査すべき点}
```

#### 防御テンプレート

```
[DEFEND] ← {批判元エージェント名}
批判: {受けた批判の要約}
回答: {根拠を提示して防御 / 批判を受け入れて修正}
修正: {ファイルを修正した場合の変更点}
```

#### 収束条件

```
収束条件（固定ラウンド数なし、自然収束）:
- 全エージェントの主要発見が共有済み
- 全ての [CHALLENGE] に対する [DEFEND] が完了
- 新しい批判が2巡連続で出なくなった
- 未解決の矛盾が明示的に記録された
→ data-critic が「収束」を宣言し、Gate に進む
```

### Phase 1: 定量調査ディスカッション

5つの調査エージェント + data-critic（ライブモデレーター）が全員同時起動。
SendMessage で対話しながら調査する。

```
[Phase 1 エージェント — 全て並列起動]
├── market-size-analyst: TAM/SAM/SOM + Porter's → market-size.md
├── trend-researcher: CAGR + タイミング → trends.md
├── competitor-intelligence-analyst: 競合深堀り + 逆算TAM → competitors.md
├── funding-signal-analyst: VC投資トレンド → funding-signals.md
├── japan-market-specialist: 日本市場独自データ → japan-market.md
└── data-critic: ライブモデレーター（矛盾検出、議論促進、収束判定）
```

主要なディスカッション軸:
```
market-size-analyst ←→ competitor-intelligence-analyst（TAM の交差検証）
market-size-analyst ←→ japan-market-specialist（日本市場 TAM の検証）
trend-researcher ←→ funding-signal-analyst（成長率 vs 投資トレンドの整合性）
japan-market-specialist ←→ trend-researcher（日本独自トレンドの検証）
data-critic がモデレーター（全会話を監視、矛盾を指摘）
```

### Gate 1: 全員参加の合意形成

Phase 1 のディスカッションが収束した後、data-critic が全員参加の合意形成をファシリテート:

```
1. data-critic がディスカッション結果をサマリー化:
   - 合意した数値（全員の合意点）
   - 未解決の矛盾（どのエージェントが何を主張しているか）
   - データ信頼度スコア

2. 各エージェントがサマリーを確認:
   - 合意: 「この数値で OK」
   - 異議: 「この点はまだ合意していない。理由: ...」

3. 未解決の矛盾がある場合:
   - 追加のディスカッション（最大2巡）
   - それでも解消しない場合は「合意の上の不一致」として記録し、
     レポートにレンジ（楽観/悲観）として反映

4. data-critic が Gate 1 の最終判定（PASS / FAIL）
```

**ユーザーチェックポイント（調査設定が「途中で確認」の場合）:**

チームリーダーは Gate 1 PASS 後に、全ファイル（market-size.md, trends.md, competitors.md, funding-signals.md, japan-market.md）を **Read で全文読み込み**、根拠と出典を含む詳細な中間レポートをユーザーに提示する。

**重要: 数字だけのサマリー表は不十分。各主張に「なぜそう言えるのか」の根拠を必ず添える。**
**ディスカッションの論点（どこで合意し、どこで意見が分かれたか）も含める。**

提示する中間レポートの構成:

```
## Phase 1 中間レポート

### 1. 市場規模（TAM/SAM/SOM）
- TAM: 値 + 算出ロジック（トップダウン/ボトムアップ/逆算TAM の3方向比較）
  - 3推計の一致度（乖離率）
  - 主要出典（レポート名 + 発行年）
  - ディスカッションの論点（どこで合意/意見分岐があったか）
- SAM: 値 + 絞り込みフィルタの根拠
- SOM: 値 + フェーズ別の成長シナリオ

### 2. 競争環境（Porter's Five Forces + 競合インテリジェンス）
- 各 Force のスコア + 核心的根拠
- 直接競合プロファイル（売上・ユーザー数・強み・弱み）
- 逆算TAM と market-size-analyst TAM の比較結果

### 3. 投資シグナル
- VC投資トレンド（過去3年）
- 注目EXIT事例
- 市場温度評価（成長率 vs 投資の整合性）

### 4. 日本市場の独自分析
- 日本市場TAM（独自算出 vs グローバル按分の比較）
- 日本独自のトレンド
- 日本のアプリ市場特性

### 5. 成長トレンドと CAGR
- CAGR 一覧（複数出典で交差検証）
- 成長ドライバー Top 3

### 6. 参入タイミング評価
- Sequoia Arc / Gartner / Bill Gross の各根拠

### 7. data-critic 検証結果
- ディスカッションの合意点・論点
- 信頼度スコア
- 総合判定（PASS/FAIL）

### 8. 主要リスクまとめ
```

AskUserQuestion:
「Phase 1（市場規模・トレンド・競合・投資・日本市場）の暫定結果です。」
- 選択肢1: 「このまま進めて」→ Phase 2 開始
- 選択肢2: 「方向修正したい」→ ユーザーのフィードバックを聞いて Phase 2 の指示に反映
- 選択肢3: 「ここで止める」→ 暫定レポートを出力して終了

### Phase 2: 定性・規制調査ディスカッション

Phase 1 の全エージェントもディスカッションに参加し続け、demand-analyst と regulatory-researcher が新規参加する。

```
[Phase 2 エージェント — demand-analyst と regulatory-researcher を新規起動]
├── demand-analyst: ユーザー需要・課題 → demand-insights.md
├── regulatory-researcher: 規制・参入障壁 → regulatory.md
├── market-size-analyst: Phase 1 からの継続参加（需要との整合性議論）
├── trend-researcher: Phase 1 からの継続参加（規制とトレンドの議論）
├── competitor-intelligence-analyst: Phase 1 からの継続参加（競合レビューと需要の交差検証）
├── funding-signal-analyst: Phase 1 からの継続参加（規制リスクと投資の議論）
├── japan-market-specialist: Phase 1 からの継続参加（日本の需要特性）
└── data-critic: ライブモデレーター継続
```

主要なディスカッション軸:
```
demand-analyst ←→ market-size-analyst（需要と市場規模の整合性）
demand-analyst ←→ competitor-intelligence-analyst（競合レビューと需要の交差検証）
demand-analyst ←→ japan-market-specialist（日本ユーザーの需要特性）
regulatory-researcher ←→ trend-researcher（規制変化と成長トレンドの関連）
regulatory-researcher ←→ funding-signal-analyst（規制リスクと投資動向の関連）
data-critic がモデレーター
```

### Gate 2: 全員参加の最終検証 + Devil's Advocate

Phase 2 のディスカッション収束後:

```
1. 全体合意形成（Gate 1 と同じ構造）
   - data-critic が全ファイルのサマリーを作成
   - 全エージェントが確認 → 合意/異議

2. Devil's Advocate ラウンド
   - data-critic が全エージェントに Devil's Advocate モードへの切り替えを宣言
   - 全エージェントが「この市場がダメな理由」を提出:
     [DEVILS_ADVOCATE]
     現在の合意: {合意内容}
     反論: {なぜダメか}
     根拠: {データ/ロジック}
     最悪シナリオ: {この反論が正しければ何が起きるか}
     深刻度: Fatal / Major / Minor

3. Devil's Advocate の処理:
   - Fatal: 合意を修正（再ディスカッション）
   - Major: リスクとして記録 + 軽減策を議論
   - Minor: 懸念事項として記録

4. data-critic が最終判定（PASS / FAIL）
```

---

## フィードバックプロトコル（全エージェント共通ルール）

1. **ディスカッションプロトコルに従う**: 批判/防御テンプレートを使用して構造化された議論を行う
2. **自分の作業が完了したら即座に関連エージェントへ共有**（完了時メッセージテンプレートに従う）
3. **他エージェントの発見を積極的に批判する**: 矛盾・疑問を見つけたら [CHALLENGE] テンプレートで指摘
4. **批判を受けたら必ず回答する**: [DEFEND] テンプレートで防御または修正
5. **実質的な内容のある返信のみ送る** - 「了解しました」だけの ACK メッセージは不要
6. **data-critic の矛盾指摘・収束宣言は最優先**: 問題発見次第すぐ対応
7. **フィードバックを受けたら修正し、変更内容を共有する**
8. **全成果物は必ずファイルに書き出す** - Write → Read → SendMessage の順序
9. **不明点・判断に迷う点はチームリーダーに質問する**

### 緊急通知パターン

以下の場合は該当エージェントまたは全員に即座に通知:

- **data-critic**: 数値の重大な矛盾を発見 → 該当エージェントに再調査を即依頼
- **demand-analyst**: 市場規模と需要の不整合を発見 → market-size-analyst に確認依頼
- **regulatory-researcher**: 参入を阻む致命的規制を発見 → 全員に通知
- **trend-researcher**: タイミングの致命的リスクを発見 → 全員に通知

テンプレート:
```
[全員へ] ⚠️ 緊急: {問題の概要}
理由: {具体的理由}
→ {対応すべきエージェント}: {具体的なアクション}を実施してください。
```

### チームリーダーへの質問パターン

エージェントが判断に迷った場合、チームリーダーに質問する:

```
[チームリーダーへ] ❓ 判断を仰ぎたい点があります:
質問: {具体的な質問}
選択肢A: {案A}
選択肢B: {案B}
推奨: {推奨案とその理由}
→ ユーザーへの確認が必要であれば、お願いします。
```

チームリーダーは内容に応じて自分で判断するか、AskUserQuestion でユーザーに確認する。

---

## 再調査プロトコル

### トリガー条件

data-critic が以下のいずれかを判定した場合、再調査を実施:

1. **独立推計の乖離率 50% 超**（Gate 1/2）
   → 関連エージェントに再調査指示
   → 具体的に「どの数字が乖離しているか」を明示

2. **出典なしデータが全体の 30% 超**（Gate 1/2）
   → 該当エージェントにソース付きで再調査指示

3. **定量 vs 定性の重大な不整合**（Gate 2）
   → demand-analyst に追加調査指示
   → 例:「成長市場なのに不満が見つからない → 本当に需要があるか再調査」

4. **フレームワーク間の致命的矛盾**（Gate 2）
   → 矛盾の解消に必要なエージェントに追加調査指示

### 再調査の手順

1. data-critic がトリガー条件に該当すると判定
2. data-critic がチームリーダーに報告（具体的な再調査指示付き）
3. チームリーダーが該当エージェントに再調査を SendMessage で指示
4. 再調査結果は同じファイルを更新（上書き）
5. data-critic が再度検証

### 再調査の制限

- 再調査は**最大2ラウンドまで**
- 3回やっても改善しない場合は「データ不足により信頼度 Low」と正直にレポートに明記
- 無限ループを防ぐため、2回目の再調査後は data-critic の判定が最終
- チームリーダーは再調査の発生をユーザーに報告する（「データの乖離が大きいため追加調査を実施しています」）

---

## データ不足時のフォールバック戦略

### Tier 1: 直接データあり（理想）
- 対象市場の市場レポートが存在
- 通常のフローで進行

### Tier 2: 類似市場からの類推
- 直接データがない場合、最も近い上位カテゴリまたは類似市場のデータを使用
- 「フィットネスアプリ」のデータがなければ「ヘルスケアアプリ」から推計
- 類推であることを明記し、信頼度を自動的に Medium 以下に設定

### Tier 3: ボトムアップのみ
- 市場レポートが一切存在しない場合
- ボトムアップ算出のみで進行
- トップダウンは「データなし」と正直に記載
- 信頼度は自動的に Low に設定

### Tier 4: 市場未成立
- ボトムアップすら困難（前例がない新カテゴリ）
- Sequoia Arc「Future Vision」に分類
- TAM の代わりに「なぜこの市場が生まれるか」の論理を記述
- 信頼度は「推定」と明記

各エージェントはデータ不足を検知したらチームリーダーに「Tier {N} で進行します」と報告する。
チームリーダーはユーザーにフォールバック状況を共有する。

---

## data-critic 検証チェックリスト

### ソース検証（データトライアンギュレーション）

各数値に最低3ソースの裏付けを要求:
- ソース1: 市場レポート（Statista, IDC等）
- ソース2: ボトムアップ計算（ユーザー数 × 単価）
- ソース3: 競合の公開データから逆算（売上 ÷ 推定シェア）

- [ ] TAM/SAM/SOM に 3ソース以上の裏付け
- [ ] 各数値の出典URL が有効
- [ ] データの鮮度: 2年以内（急成長市場は1年以内）
- [ ] 「丸い数字」への警告（ちょうど$10B等は怪しい）

### 独立推計の一致度（調査者トライアンギュレーション）

4ソースでの交差検証:
- market-size-analyst（トップダウン）
- market-size-analyst（ボトムアップ）
- competitor-intelligence-analyst（逆算TAM）
- japan-market-specialist（日本市場独自推計）

乖離率の閾値:
- 乖離30%以内 → 信頼度 High
- 乖離30-50% → 信頼度 Medium（要追加調査）
- 乖離50%超 → 信頼度 Low（再調査必須）

### 投資シグナル整合性チェック

- [ ] 「成長市場」なのに投資が減少 → 要注意フラグ
- [ ] 「小さい市場」なのに投資が急増 → TAM過小評価の可能性
- [ ] EXIT事例なし + 投資件数激増 → バブルリスク

### 日本市場整合性チェック

- [ ] グローバルTAM × 日本比率 vs japan-market-specialist の独自推計
- [ ] 30%超の乖離 → 按分比率に問題あり

### 定量 vs 定性の整合性（方法論トライアンギュレーション）

- [ ] 「成長市場」なのにユーザーの不満が見つからない → 需要疑問フラグ
- [ ] 「小さい市場」なのに不満が大量 → TAM過小評価の可能性
- [ ] 「競合少ない」のにレビューで代替手段が多数言及 → 見えない競合

### フレームワーク間の矛盾（理論トライアンギュレーション）

- [ ] TAM は大きいが Porter's で参入障壁が極めて高い → SOM が取れない
- [ ] トレンドは上昇だが Sequoia Arc で "Future Vision" → タイミングリスク
- [ ] 需要は強いが規制が厳しい → コスト構造に影響

---

## 定量判断基準（Market Viability Quick Assessment）

| 指標 | Green (Go) | Yellow (要調査) | Red (再検討) |
|---|---|---|---|
| TAM | >$1B | $100M-$1B | <$100M |
| Market CAGR | >20% | 5-20% | <5% or 減少 |
| Y1到達可能ユーザー数 | >10,000 | 1,000-10,000 | <1,000 |
| 競争密度 (HHI) | <1,500 (分散) | 1,500-2,500 | >2,500 (寡占) |
| 粗利率ポテンシャル | >70% | 50-70% | <50% |
| CAC回収期間 | <12ヶ月 | 12-18ヶ月 | >18ヶ月 |
| LTV/CAC | >3:1 | 2-3:1 | <2:1 |

---

## MARKET_REPORT.md セクション別責任分担

| # | セクション | 担当 | ソースファイル |
|---|---|---|---|
| 1 | Executive Summary | チームリーダー | 全ファイル統合 |
| 2 | 市場規模（TAM/SAM/SOM） | market-size-analyst | market-size.md |
| 2.5 | 日本市場の独自分析 | japan-market-specialist | japan-market.md |
| 3 | 成長性分析 | trend-researcher | trends.md |
| 4 | ユーザー需要インサイト | demand-analyst | demand-insights.md |
| 5 | 規制・参入障壁 | regulatory-researcher | regulatory.md |
| 6 | 主要プレイヤー概観 | market-size-analyst | market-size.md |
| 6.5 | 競合インテリジェンス | competitor-intelligence-analyst | competitors.md |
| 7 | データ品質評価 | data-critic | critique.md |
| 8 | 参入タイミング評価 | trend-researcher | trends.md |
| 8.5 | 投資シグナル分析 | funding-signal-analyst | funding-signals.md |
| 9 | Devil's Advocate | data-critic | critique.md |
| 9.5 | ディスカッション経緯 | data-critic | critique.md |
| 10 | 最終判断の問い | チームリーダー | - |
| - | Market Viability Assessment | data-critic | critique.md |

テンプレートは [references/report-template.md](references/report-template.md) を参照。

---

## Step 4: ファイル書き込み検証（チームリーダー必須）

全エージェントのタスクが completed になった後、最終レポート作成の前に以下を検証する:

```bash
.claude/market-research/{date}_{project}/
├── market-size.md           <- market-size-analyst が書き込み
├── trends.md                <- trend-researcher が書き込み
├── competitors.md           <- competitor-intelligence-analyst が書き込み
├── funding-signals.md       <- funding-signal-analyst が書き込み
├── japan-market.md          <- japan-market-specialist が書き込み
├── demand-insights.md       <- demand-analyst が書き込み
├── regulatory.md            <- regulatory-researcher が書き込み
└── critique.md              <- data-critic が書き込み
```

検証手順:
1. Glob で全ファイルの存在を確認
2. 各ファイルを Read して空でないことを確認
3. 不足・空のファイルがあれば該当エージェントに再依頼
4. エージェントがシャットダウン済みの場合はフォールバック書き込み

## Step 5: 統合レポート作成

チームリーダーが全エージェントの出力ファイルを **Read で全文読み込み**、
MARKET_REPORT.md に統合する。テンプレートは [references/report-template.md](references/report-template.md) を参照。

**重要: MARKET_REPORT.md 自体も詳細に書く。**
各セクションは元ファイルの核心部分（算出ロジック、主要出典、交差検証結果）を保持する。
単なる数値コピーではなく、「なぜその数値なのか」が伝わる記述にする。

## Step 6: ユーザーへの最終報告

統合レポート完成後、チームリーダーは全ソースファイルを Read し、
**根拠と出典を含む詳細な最終レポート**をユーザーに直接提示する。

**重要: 数字だけの箇条書きは不十分。Gate 1 中間レポートと同様の詳細さで報告する。**

提示する最終レポートの構成:

```
## 最終レポート

### 1. Executive Summary
- 結論（参入タイミング評価）+ その根拠の要約
- TAM/SAM/SOM の主要数値 + 信頼度 + 算出方法の概要

### 2. 市場規模（TAM/SAM/SOM）
- 算出ロジック（トップダウン・ボトムアップ・逆算TAM の3方向比較）
- 乖離率と採用値の判断根拠
- レンジ幅と注意点

### 3. 競合インテリジェンス
- 直接競合プロファイル（売上・ユーザー数・強み・弱み）
- 逆算TAM と market-size-analyst TAM の比較結果
- 残存市場規模と充足率の意味

### 4. 投資シグナル
- VC投資トレンド（過去3年）
- 注目EXIT事例
- 市場温度評価（成長率 vs 投資の整合性）

### 5. 日本市場の独自分析
- 日本市場TAM（独自算出 vs グローバル按分の比較）
- 日本独自のトレンド
- 日本のアプリ市場特性

### 6. 成長性・トレンド
- CAGR 一覧（複数出典で交差検証）
- 成長ドライバー Top 3: 統計データ + 出典 + アプリへの示唆
- 参入タイミング評価: Sequoia Arc / Gartner / Bill Gross の各根拠

### 7. ユーザー需要インサイト
- 課題ランキング（深刻度 × 頻度）+ 各課題の証拠
- JTBD 構造: Functional / Social / Emotional Jobs
- 生の声の引用（実際のレビュー・SNS投稿）
- 定量データ（市場規模）と定性データ（ユーザーの声）の整合性

### 8. 競争環境
- Porter's Five Forces: 各スコア + 核心的根拠
- 主要プレイヤー: 売上・ユーザー数・強み・弱み（出典付き）

### 9. 規制・参入障壁
- 主要規制とその影響度（出典付き）
- 参入障壁スコアリング + 各障壁の具体的説明
- 規制変化のトレンドと対応コスト

### 10. データ品質・検証結果
- data-critic の検証サマリー
- 各データ項目の信頼度 + その理由
- フレームワーク間の矛盾があれば明記

### 11. Devil's Advocate
- この市場がダメな理由 Top 3: 各理由の根拠とシナリオ
- 矛盾リスト（要ユーザー判断）

### 12. ディスカッション経緯
- どこで合意し、どこで意見が分かれたか
- 主要な論点と解決プロセス

### 13. Market Viability Quick Assessment
- 各指標の値 + Green/Yellow/Red 判定 + 判定根拠

### 14. 主要リスクまとめ
- リスク × 深刻度 × 根拠 × 軽減策 の表形式
```

AskUserQuestion:
「市場調査レポートが完成しました。次のステップについて相談させてください。」
- 選択肢1: 「競合分析に進みたい」→ competitive-analysis スキルへ
- 選択肢2: 「ペルソナ作成に進みたい」→ persona-creation スキルへ
- 選択肢3: 「追加で深掘りしたい領域がある」→ 具体的な領域を聞いて追加調査
- 選択肢4: 「一旦ここまでで良い」→ レポートの保存場所を案内

## Step 7: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除

---

## 他スキルとの連携

### → competitive-analysis
- 主要プレイヤー名と概算シェア
- ユーザー需要インサイト（レビュー分析の起点）

### → business-model-canvas
- SAM（実際に狙える市場規模）
- 収益モデルの市場適合性ヒント

### ← → persona-creation（双方向）
- 出す: セグメント規模データ
- 受ける: ペルソナの解像度を SOM 精緻化に活用

### → user-voice-research
- demand-insights.md の「user-voice-research への申し送り」セクション
- 課題ランキング、JTBD 構造、深掘りすべきテーマ

### → pricing-strategy
- 市場相場価格帯
- 競合の課金モデル分布

---

## 参考フレームワーク

- TAM/SAM/SOM + PAM
- Porter's Five Forces（定量スコアリング）
- Sequoia Arc PMF Framework（Hair on Fire / Hard Fact / Future Vision）
- JTBD / Outcome-Driven Innovation
- Bill Gross タイミング研究（成功要因の42%）
- Gartner Hype Cycle
- Sean Ellis Test（40%閾値）
- Denzin の4種類のトライアンギュレーション

---

## Shell Scripts リファレンス

### init.sh - プロジェクト初期化

```bash
bash scripts/init.sh <project-name>

# 例
bash scripts/init.sh my-fitness-app
# -> .claude/market-research/2026-03-03_my-fitness-app/ を作成
```

### new-round.sh - 再調査ラウンド

```bash
bash scripts/new-round.sh <project-dir>

# 例
bash scripts/new-round.sh ~/.claude/market-research/2026-03-03_my-fitness-app
# -> 既存ファイルを .bak にリネームし、再調査用に準備
```
