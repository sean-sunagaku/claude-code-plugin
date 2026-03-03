---
name: competitive-analysis
description: >
  5つの専門エージェントがディスカッション型で競合のビジネスモデル・機能・価格・弱点を網羅的に分析し、
  差別化ポイントと参入戦略を導出するスキル。
  エージェント同士が対話・批判し合いながら調査し、ca-data-critic がライブモデレーターとして矛盾を検出・収束を判定する。
  Phase 1 で競合プロファイル・レビュー・機能をディスカッション型で調査し、
  Phase 2 でポジショニング戦略家が統合。
  Gate 1（中間合意形成）→ Gate 2（最終検証 + Independent Validation + Devil's Advocate）の2段階ゲートで品質を担保。
  Use when: 競合を分析したい、差別化ポイントを見つけたい、
  市場のプレイヤーを調べたい、ポジショニングを考えたい。
  Triggers: "競合分析", "competitive analysis", "競合調査", "差別化",
  "ポジショニング", "competitor", "競合", "市場プレイヤー",
  "ライバル調査", "competitive landscape"
---

# Competitive Analysis Skill

5つの専門エージェントがディスカッション型で競合環境を調査・分析し、差別化戦略を導出する。

エージェント同士が対話・批判し合いながら調査し、ca-data-critic がライブモデレーターとして
矛盾を検出・収束を判定する。独立並列調査では見つからない矛盾を、リアルタイムの対話で解消する。

**重要原則: 全ての成果物は日本語で作成する。**
レポートファイル、エージェント間のディスカッション、ユーザーへの報告、全て日本語で記述する。
出典URLや固有名詞（企業名・サービス名）は原語のままで良い。

## エージェント構成

| name | 役割 | Phase | 主な手段 |
|------|------|-------|---------|
| `ca-competitor-researcher` | 競合プロファイリング・情報収集 | 1 | WebSearch |
| `ca-review-analyst` | レビュー・評判分析 | 1 | WebSearch |
| `ca-feature-benchmarker` | 機能比較・価格ベンチマーク | 1 | WebSearch |
| `ca-data-critic` | ライブモデレーター + 検証ゲートキーパー | Phase 1 & 2 | 分析・批判的思考 |
| `ca-positioning-strategist` | ポジショニング・差別化戦略設計 | 2 | ディスカッション型統合 |

各エージェントは `.claude/agents/` ディレクトリにサブエージェントとして定義済み。

## ワークフロー概要

```
Step 1: ヒアリング（+ market-research 出力の有無を確認）
Step 2: プロジェクト初期化 → docs/competitive-analysis/YYYY-MM-DD_<project>/
Step 3: チーム作成 + タスク作成（7タスク）
Step 4: Phase 1 ディスカッション
  ├─ ca-competitor-researcher（並列）
  ├─ ca-review-analyst（並列）
  ├─ ca-feature-benchmarker（並列）
  └─ ca-data-critic（同時起動、ライブモデレート）
  → Gate 1（全員合意形成 + ユーザーチェックポイント）
Step 5: Phase 2 ディスカッション
  ├─ ca-positioning-strategist（新規参加）
  ├─ Phase 1 の3エージェント（継続参加）
  └─ ca-data-critic（ライブモデレート継続）
  → Gate 2（最終検証 + Independent Validation + Devil's Advocate）
Step 6: ファイル検証
Step 7: 統合レポート作成
Step 8: ユーザーへの最終報告
Step 9: クリーンアップ
```

---

## Step 1: ヒアリング

以下を確認する（不明ならユーザーに AskUserQuestion で質問）:

- **アプリカテゴリ**: 何のカテゴリか（例: フィットネス、家計管理、タスク管理）
- **ターゲットユーザー**: 誰向けか（例: 30代女性、個人事業主）
- **対象地域**: 日本 / 米国 / グローバル
- **知っている競合**: すでに把握している競合名（なくてもOK）
- **自社アプリ概要**: 何を作ろうとしているか（差別化分析に使用）
- **自社の差別化仮説**: 自分たちが考えている差別化ポイント（あれば。検証対象として使用）
- **market-research の出力**: あればパスを確認

### 調査設定（ユーザーに確認）

AskUserQuestion で以下を確認:

**「調査の進め方を確認させてください」**
- 選択肢1: 「途中で確認したい（推奨）」→ Gate 1 でユーザーチェックポイントを設ける
- 選択肢2: 「一気に最後まで」→ Gate 1 のユーザー確認をスキップ
- 選択肢3: 「重要な発見があれば都度教えて」→ Gate 1 + 各エージェントの重要発見時に報告

---

## Step 2: プロジェクト初期化

```bash
bash scripts/init.sh <project-name>
# -> docs/competitive-analysis/YYYY-MM-DD_<project>/ を作成
```

出力される絶対パスを控える。全エージェントのプロンプトに必ず渡す。

---

## Step 3: チーム作成とタスク割り当て

TeamCreate で `competitive-analysis` チームを作成。

TaskCreate で7つのタスクを作成:

```
1. ca-competitor-researcher: 競合プロファイリング（Phase 1、並列）
2. ca-review-analyst: レビュー・評判分析（Phase 1、並列）
3. ca-feature-benchmarker: 機能・価格ベンチマーク（Phase 1、並列）
4. ca-data-critic Phase 1 モデレーション: ディスカッションモデレート + Gate 1 合意形成
   （addBlockedBy は設定しない。Phase 1 エージェントと同時起動し、ライブモデレートする）
5. ca-positioning-strategist: ポジショニング・差別化戦略（Phase 2、addBlockedBy: ["4"]）
6. ca-data-critic Gate 2: 最終検証 + Independent Validation + Devil's Advocate（addBlockedBy: ["5"]）
7. 統合レポート作成（addBlockedBy: ["6"]）
```

---

## Step 4: Phase 1 ディスカッション（並列起動）

Phase 1 の3エージェント + ca-data-critic を **1つのメッセージで並列に** Agent ツールで起動する。

```
subagent_type: "ca-competitor-researcher"
team_name: "competitive-analysis"
mode: "bypassPermissions"
run_in_background: true
model: opus
```

各エージェントのプロンプトに含める情報:
- チーム名とタスクID
- アプリカテゴリ、ターゲット、地域
- 知っている競合名
- **ベースディレクトリの絶対パス**（init.sh の出力をそのまま使う）
- market-research の出力がある場合はその内容/パス
- **ファイル書き込み注意**: Write ツールは絶対パスのみ。相対パスは動作しない
- 「他エージェントと積極的にディスカッションすること」を明記

### Phase 1 ディスカッション軸

```
ca-competitor-researcher ↔ ca-review-analyst（競合の強み/弱みの一致度）
ca-competitor-researcher ↔ ca-feature-benchmarker（プロファイルと機能/価格の整合性）
ca-review-analyst ↔ ca-feature-benchmarker（ユーザー不満と機能空白の突き合わせ）
ca-data-critic がモデレーター（矛盾検出、議論促進、収束判定）
```

### Gate 1: 全員参加の合意形成

Phase 1 のディスカッションが収束した後、ca-data-critic が全員参加の合意形成をファシリテート:

```
1. ca-data-critic がディスカッション結果をサマリー化:
   - 合意した競合リスト・脅威レベル
   - 合意したコアペイン・不満Top5
   - 合意した機能の空白地帯
   - 未解決の矛盾

2. 各エージェントがサマリーを確認:
   - 合意: 「この発見で OK」
   - 異議: 「この点はまだ合意していない。理由: ...」

3. ca-data-critic が Gate 1 の最終判定（PASS / FAIL）
```

**ユーザーチェックポイント（調査設定が「途中で確認」の場合）:**

チームリーダーは Gate 1 PASS 後に、全ファイル（competitor-profiles.md, review-insights.md, feature-matrix.md）を **Read で全文読み込み**、根拠と出典を含む詳細な中間レポートをユーザーに提示する。

提示する中間レポートの構成:
```
## Phase 1 中間レポート

### 1. 競合マップ
- 直接競合（上位5社）と脅威レベル + 根拠
- 間接競合と脅威レベル
- 消えた競合と教訓

### 2. ユーザー不満分析
- 不満 Top5（出現頻度・深刻度・代表的な声）
- 競合が解決していないコアペイン

### 3. 機能ベンチマーク
- テーブルステークス機能（各競合の対応状況）
- 機能の空白地帯

### 4. 価格比較
- 価格帯分布
- 課金モデル傾向

### 5. ca-data-critic 検証結果
- ディスカッションの合意点・論点
- 信頼度スコア
- 総合判定（PASS/FAIL）
```

AskUserQuestion:
「Phase 1（競合プロファイル・レビュー・機能比較）の暫定結果です。」
- 選択肢1: 「このまま Phase 2（ポジショニング分析）に進んで」→ Phase 2 開始
- 選択肢2: 「方向修正したい」→ ユーザーのフィードバックを聞いて Phase 2 の指示に反映
- 選択肢3: 「ここで止める」→ 暫定レポートを出力して終了

---

## Step 5: Phase 2 ディスカッション

ca-positioning-strategist を起動。Phase 1 の全エージェントもディスカッションに継続参加する。

```
subagent_type: "ca-positioning-strategist"
team_name: "competitive-analysis"
mode: "bypassPermissions"
run_in_background: true
model: opus
```

プロンプトに追加で含める情報:
- Phase 1 の全出力ファイルパス（3ファイル）
- 自社アプリ概要と差別化仮説
- Phase 1 エージェントとのディスカッション継続の旨

### Phase 2 ディスカッション軸

```
ca-positioning-strategist ↔ ca-competitor-researcher（ポジショニングと競合プロファイルの整合性）
ca-positioning-strategist ↔ ca-review-analyst（差別化軸とコアペインの対応確認）
ca-positioning-strategist ↔ ca-feature-benchmarker（ERRC と機能空白地帯の整合性）
ca-data-critic がモデレーター継続
```

### Gate 2: 最終検証 + Independent Validation + Devil's Advocate

Phase 2 のディスカッション収束後、ca-data-critic が実行:

```
1. 全体合意形成（Gate 1 と同じ構造）
   - positioning.md の推奨差別化戦略に全員が合意

2. Independent Validation
   - ca-data-critic が positioning.md の推奨戦略を独自 WebSearch で検証
   - 「この差別化軸は本当に未開拓か」を独立検証

3. Devil's Advocate ラウンド
   - ca-data-critic が全エージェントに切り替えを宣言
   - 全エージェントが「この差別化戦略がダメな理由」を提出:
     [DEVILS_ADVOCATE]
     現在の合意: {合意内容}
     反論: {なぜダメか}
     根拠: {データ/ロジック}
     最悪シナリオ: {この反論が正しければ何が起きるか}
     深刻度: Fatal / Major / Minor

4. ca-data-critic が最終判定（PASS / FAIL）
```

---

## Step 6: ファイル書き込み検証

全エージェント完了後、以下のファイル存在を検証する:

```
{base_dir}/
├── competitor-profiles.md   <- ca-competitor-researcher
├── review-insights.md       <- ca-review-analyst
├── feature-matrix.md        <- ca-feature-benchmarker
├── positioning.md           <- ca-positioning-strategist
├── critique.md              <- ca-data-critic
└── context.md               <- チームリーダー（Step 7 で作成）
```

**検証手順**:
1. Glob でファイル一覧を確認
2. 各ファイルを Read して空でないことを確認
3. 不足・空のファイルがあった場合:
   - 該当エージェントに SendMessage で再書き込みを依頼
   - 応答なし/シャットダウン済みの場合: ディスカッションログから内容を抽出し、チームリーダー自身が Write で書き込む

---

## Step 7: 統合レポート作成

全ファイルを Read して統合レポートを作成する。

1. `references/report-template.md` を参照
2. 全エージェントの出力を統合して `COMPETITIVE_REPORT.md` を作成
3. `context.md` を作成（プロジェクト情報・入力値・セッション引き継ぎ用）

出力先: `{base_dir}/COMPETITIVE_REPORT.md`

---

## Step 8: ユーザーへの最終報告

統合レポート完成後、チームリーダーは全ソースファイルを Read し、
**根拠と出典を含む詳細な最終レポート**をユーザーに直接提示する。

提示する最終レポートの構成:
```
## 競合分析 最終レポート

### 1. Executive Summary
- 競合環境の要約
- 最大の差別化機会
- 推奨差別化戦略

### 2. 競合マップ
- 直接競合（出典付き）
- 間接競合
- 消えた競合と教訓

### 3. ユーザー不満分析
- 不満 Top5（代表的な声の引用）
- 競合が解決していないコアペイン

### 4. 機能・価格ベンチマーク
- 機能の空白地帯
- 価格帯分布

### 5. ポジショニング分析
- ポジショニングマップ（2軸）
- ERRC グリッド（根拠付き）

### 6. 差別化戦略オプション
- Option A/B/C の比較
- 推奨オプションと根拠

### 7. データ品質・検証結果
- Independent Validation の結果
- Devil's Advocate - この差別化がダメな理由 Top3
- 信頼度スコアサマリー

### 8. ディスカッション経緯
- どこで合意し、どこで意見が分かれたか

### 9. 次のステップ
```

AskUserQuestion:
「競合分析レポートが完成しました。次のステップについて相談させてください。」
- 選択肢1: 「ビジネスモデルキャンバスに進みたい」→ business-model-canvas スキルへ
- 選択肢2: 「ペルソナ作成に進みたい」→ persona-creation スキルへ
- 選択肢3: 「追加で深掘りしたい競合がある」→ 具体的な競合を聞いて追加調査
- 選択肢4: 「一旦ここまでで良い」→ レポートの保存場所を案内

---

## Step 9: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除
3. レポートのパスをユーザーに報告

---

## フィードバックプロトコル（全エージェント共通）

1. **ディスカッションプロトコルに従う**: 批判/防御テンプレートを使用して構造化された議論を行う
2. **自分の作業が完了したら即座に関連エージェントへ共有**
3. **他エージェントの発見を積極的に批判する**: 矛盾・疑問を見つけたら [CHALLENGE] テンプレートで指摘
4. **批判を受けたら必ず回答する**: [DEFEND] テンプレートで防御または修正
5. **実質的な内容のある返信のみ送る** - 「了解しました」だけの ACK メッセージは不要
6. **ca-data-critic の矛盾指摘・収束宣言は最優先**
7. **全成果物は必ずファイルに書き出す** - Write → Read → SendMessage の順序
8. **不明点・判断に迷う点はチームリーダーに質問する**

### ディスカッションプロトコル

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
→ ca-data-critic が「収束」を宣言し、Gate に進む
```

---

## 再調査プロトコル

### トリガー条件

ca-data-critic が以下のいずれかを判定した場合、再調査を実施:

1. **競合プロファイルが3社以下**（Gate 1）→ ca-competitor-researcher に追加調査指示
2. **レビューデータのソースが1サイトのみ**（Gate 1）→ ca-review-analyst に追加ソース調査指示
3. **機能比較が推測のみ**（Gate 1/2）→ ca-feature-benchmarker に実際の調査指示
4. **Cross-Source 整合性の重大な矛盾**（Gate 2）→ 該当エージェントに再調査指示

### 再調査の制限

- 再調査は**最大2ラウンドまで**
- 3回やっても改善しない場合は「データ不足により信頼度 Low」と正直にレポートに明記
- チームリーダーは再調査の発生をユーザーに報告する

---

## データ不足時のフォールバック戦略

### Tier 1: 直接データあり（理想）
- 対象カテゴリの競合が5社以上特定でき、レビューデータが豊富
- 通常のフローで進行

### Tier 2: 競合は少ないが調査は可能
- 競合が3-4社程度（ニッチ市場）
- 間接競合・代替手段を積極的に含める
- 「市場の飽和度が低い」として記録

### Tier 3: 新興カテゴリ
- 直接競合がほぼ存在しない
- 隣接カテゴリの競合分析と類推を組み合わせる
- 信頼度は自動的に Medium 以下に設定

各エージェントはデータ不足を検知したらチームリーダーに「Tier {N} で進行します」と報告する。

---

## 他スキルとの連携

### ← market-research
- 受ける: 主要プレイヤー名と概算シェア、ユーザー需要インサイト
- market-research の出力があれば `competitor-profiles.md` の起点として使用

### → business-model-canvas
- 差別化オプション Top3
- 推奨ポジションの根拠

### → pricing-strategy
- 競合の価格帯分布
- 機能 vs 価格マッピング

### ← → persona-creation（双方向）
- 出す: コアペイン・不満 Top5
- 受ける: ペルソナの解像度を差別化分析に活用

---

## Shell Scripts リファレンス

### init.sh - プロジェクト初期化

```bash
bash scripts/init.sh <project-name>

# 例
bash scripts/init.sh my-fitness-app
# -> docs/competitive-analysis/2026-03-03_my-fitness-app/ を作成
```

### new-round.sh - 再調査ラウンド

```bash
bash scripts/new-round.sh <project-dir>

# 例
bash scripts/new-round.sh docs/competitive-analysis/2026-03-03_my-fitness-app
# -> 既存ファイルを .bak にリネームし、再調査用に準備
```
