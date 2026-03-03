---
name: market-research
description: >
  5つの専門エージェント（市場規模分析・トレンド調査・ユーザー需要分析・規制調査・データ検証）が
  チームでアプリ/デジタルプロダクトの市場調査を実施するスキル。
  トライアンギュレーション（データ・方法論・調査者・理論の4種類）をワークフローに組み込み、
  確証バイアスを排除した信頼度付きレポートを出力する。
  Gate 1（中間検証）→ Gate 2（最終検証）の2段階ゲートで品質を担保。
  コンテキストファイルで過去のセッションを引き継げる。
  Use when: 市場調査をしたい、TAM/SAM/SOMを算出したい、市場の成長性を調べたい、
  参入タイミングを判断したい、競合市場を分析したい、規制リスクを調べたい。
  Triggers: "市場調査", "market research", "TAM", "SAM", "SOM", "市場規模",
  "市場分析", "market analysis", "参入", "market entry", "市場性",
  "market viability", "市場トレンド", "market trend"
---

# Market Research Skill

5つの専門エージェントがチームで市場調査を実施し、トライアンギュレーション検証済みの
信頼度付き市場レポートを出力する。

## ワークフロー概要

```
Step 1: ヒアリング（必須情報 + 調査深度の合意）
Step 2: チーム作成・エージェント起動
Step 3: Round 1 → Gate 1 → Round 2 → Gate 2
Step 4: ファイル検証
Step 5: 統合レポート作成
Step 6: ユーザーへの最終報告
Step 7: クリーンアップ
```

## コンテキストファイル構成

```
.claude/market-research/{YYYY-MM-DD}_{project}/
├── MARKET_REPORT.md         <- 統合レポート（後続スキルがまず読むファイル）
├── context.md               <- プロジェクト情報・セッション引き継ぎ用
├── market-size.md           <- TAM/SAM/SOM 詳細計算（両アプローチ）
├── trends.md                <- トレンド・成長率・ドライバー分析
├── demand-insights.md       <- ユーザー需要・課題・ペインポイント
├── regulatory.md            <- 規制・参入障壁
└── critique.md              <- データ検証・Devil's Advocate 結果
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

**「調査の進め方を確認させてください」**
- 選択肢1: 「途中で確認したい（推奨）」→ Gate 1 でユーザーチェックポイントを設ける
- 選択肢2: 「一気に最後まで」→ Gate 1 のユーザー確認をスキップ
- 選択肢3: 「重要な発見があれば都度教えて」→ Gate 1 + 各エージェントの重要発見時に報告

---

## Step 2: チーム作成とエージェント起動

TeamCreate で `market-research` チームを作成。

| name | 役割 | 主な手段 |
|------|------|---------|
| `market-size-analyst` | TAM/SAM/SOM算出、Porter's Five Forces | WebSearch, 数値計算 |
| `trend-researcher` | トレンド・タイミング調査、Sequoia Arc分類 | WebSearch |
| `demand-analyst` | ユーザー需要・課題調査（レビュー、SNS、JTBD） | WebSearch |
| `regulatory-researcher` | 規制・参入障壁・コンプライアンスコスト | WebSearch |
| `data-critic` | 検証・バイアス排除・Devil's Advocate | 分析・批判的思考 |

各エージェントは `agents/` ディレクトリにサブエージェントとして定義済み。

### タスク作成

TaskCreate で以下を作成:

```
1. market-size-analyst: TAM/SAM/SOM算出 + Porter's Five Forces
2. trend-researcher: トレンド・タイミング調査（1 と並列、互いの出力を見ない）
3. data-critic Gate 1: 中間検証（addBlockedBy: ["1", "2"]）
4. demand-analyst: ユーザー需要・課題調査（addBlockedBy: ["3"]）
5. regulatory-researcher: 規制・参入障壁調査（addBlockedBy: ["3"]）、4と並列
6. data-critic Gate 2: 最終検証（addBlockedBy: ["4", "5"]）
7. 統合レポート作成（addBlockedBy: ["6"]）
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
- **ベースディレクトリの絶対パス**（⚠️必須）: `init.sh` が出力する絶対パスをそのまま使う
  - 例: `/Users/babashunsuke/.claude/market-research/2026-03-03_my-app/`
  - ⚠️ Write ツールは絶対パスのみ受け付ける
- 「全ファイルは Write ツールで絶対パスに書き込むこと」を明記
- ユーザーが選んだ調査設定（中間確認あり/なし）

---

## Step 3: ラウンド進行（トライアンギュレーション統合型）

### Round 1: 独立並列調査（調査者トライアンギュレーション）

**重要**: market-size-analyst と trend-researcher は互いの出力を見ずに独立調査する。

```
[market-size-analyst]
  → TAM/SAM/SOM算出（トップダウン + ボトムアップ両方）
  → Porter's Five Forces 定量スコアリング
  → market-size.md に書き出し
  → 完了時メッセージを全員に送信

[trend-researcher]（並列）
  → CAGR調査（出典・調査年明記）
  → 成長ドライバー特定
  → Sequoia Arc 分類
  → Gartner Hype Cycle 位置付け
  → Bill Gross タイミング基準での評価
  → trends.md に書き出し
  → 完了時メッセージを全員に送信

※互いの出力を参照しない（調査者の独立性を保証）
```

### Gate 1: 中間検証（data-critic）

Round 1 完了後、Round 2 に進む前に data-critic が中間検証を実施:

```
[data-critic] Gate 1 中間検証
  ① market-size.md と trends.md を Read
  ② 独立推計の乖離率チェック（30%/50% 閾値）
  ③ ソース品質の簡易チェック（出典URL有無、丸い数字の検出）
  ④ 判定:
     PASS → Round 2 に進行可
     FAIL → 再調査指示を該当エージェントに送信
```

**ユーザーチェックポイント（調査設定が「途中で確認」の場合）:**

チームリーダーは Gate 1 PASS 後にユーザーに中間結果を提示:

提示内容:
- TAM/SAM/SOM の暫定値（レンジ）
- 参入タイミングの暫定評価
- data-critic の中間判定結果
- 主要な発見・懸念点

AskUserQuestion:
「Round 1（市場規模・トレンド）の暫定結果です。」
- 選択肢1: 「このまま進めて」→ Round 2 開始
- 選択肢2: 「方向修正したい」→ ユーザーのフィードバックを聞いて Round 2 の指示に反映
- 選択肢3: 「ここで止める」→ 暫定レポートを出力して終了

### Round 2: 定性調査 + 規制調査（方法論トライアンギュレーション）

Round 1 の定量調査に加え、定性・規制の多角化を行う。
Gate 1 の結果（特に data-critic からの注意点）を各エージェントに申し送る。

```
[demand-analyst]
  → App Store/Google Play レビュー分析
  → SNS・掲示板・Reddit・知恵袋の生の声収集
  → JTBD フレームワークでの需要構造化
  → 需要の強度評価（urgency / frequency / intensity）
  → demand-insights.md に書き出し
  → 完了時メッセージを全員に送信

[regulatory-researcher]（並列）
  → Phase 0 で規制重要度を事前判定（フル/標準/簡易/最小）
  → 対象カテゴリの主要規制
  → 地域別規制差異
  → 参入障壁の定量評価
  → 規制変化のトレンド
  → regulatory.md に書き出し
  → 完了時メッセージを全員に送信
```

### Gate 2: 最終検証（data-critic）

Round 2 完了後、全データの最終検証を実施:

```
[data-critic] Gate 2 最終検証（全チェックリスト実行）
  ① ソース検証（データトライアンギュレーション）
  ② 独立推計の一致度（調査者トライアンギュレーション）
  ③ 定量 vs 定性の整合性（方法論トライアンギュレーション）
  ④ フレームワーク間の矛盾（理論トライアンギュレーション）
  ⑤ Devil's Advocate（この市場がダメな理由 Top 3）
  ⑥ 信頼度スコア付与
  ⑦ 判定:
     PASS → レポート作成へ
     FAIL → 再調査指示を該当エージェントに送信
```

---

## フィードバックプロトコル（全エージェント共通ルール）

1. **自分の作業が完了したら即座に関連エージェントへ共有**（完了時メッセージテンプレートに従う）
2. **実質的な内容のある返信のみ送る** - 「了解しました」だけの ACK メッセージは不要
3. **data-critic の警告は最優先**: 問題発見次第すぐ該当エージェントに通知
4. **フィードバックを受けたら修正し、変更内容を共有する**
5. **全成果物は必ずファイルに書き出す** - Write → Read → SendMessage の順序
6. **不明点・判断に迷う点はチームリーダーに質問する** - チームリーダーが必要に応じてユーザーに確認

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

1. **独立推計の乖離率 50% 超**（Gate 1）
   → market-size-analyst と trend-researcher の両方に再調査指示
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

- [ ] market-size-analyst と trend-researcher の市場規模推定の乖離率
  - 乖離30%以内 → 信頼度 High
  - 乖離30-50% → 信頼度 Medium（要追加調査）
  - 乖離50%超 → 信頼度 Low（再調査必須）

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
| 3 | 成長性分析 | trend-researcher | trends.md |
| 4 | ユーザー需要インサイト | demand-analyst | demand-insights.md |
| 5 | 規制・参入障壁 | regulatory-researcher | regulatory.md |
| 6 | 主要プレイヤー概観 | market-size-analyst | market-size.md |
| 7 | データ品質評価 | data-critic | critique.md |
| 8 | 参入タイミング評価 | trend-researcher | trends.md |
| 9 | Devil's Advocate | data-critic | critique.md |
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

data-critic の検証結果を含め、全エージェントの出力を MARKET_REPORT.md に統合する。
テンプレートは [references/report-template.md](references/report-template.md) を参照。

## Step 6: ユーザーへの最終報告

統合レポート完成後、ユーザーに以下を提示:

1. **結論**: 参入タイミング評価（今すぐ / 1-2年後 / 3年以上後 / 参入見直し推奨）
2. **TAM/SAM/SOM サマリー**: 主要数値と信頼度
3. **最大リスク**: Devil's Advocate の Top 1
4. **Market Viability Quick Assessment**: Green/Yellow/Red の一覧
5. **次のアクション提案**: 後続スキルへの誘導（competitive-analysis, persona-creation 等）

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
