---
name: competitive-analysis
description: >
  5つの専門エージェントが競合のビジネスモデル・機能・価格・弱点を網羅的に分析し、
  差別化ポイントと参入戦略を導出するスキル。
  「情報収集」「レビュー分析」「機能ベンチマーク」を独立並列で実施し、
  ポジショニング戦略家が統合、ブラインドレビュアーが検証する3ラウンド構成。
  Use when: 競合を分析したい、差別化ポイントを見つけたい、
  市場のプレイヤーを調べたい、ポジショニングを考えたい。
  Triggers: "競合分析", "competitive analysis", "競合調査", "差別化",
  "ポジショニング", "competitor", "競合", "市場プレイヤー",
  "ライバル調査", "competitive landscape"
---

# Competitive Analysis Skill

5つの専門エージェントが並列で競合環境を調査・分析し、差別化戦略を導出する。

## エージェント構成

| name | 役割 | Round | 主な手段 |
|------|------|-------|---------|
| `ca-competitor-researcher` | 競合プロファイリング・情報収集 | 1 | WebSearch |
| `ca-review-analyst` | レビュー・評判分析 | 1 | WebSearch |
| `ca-feature-benchmarker` | 機能比較・価格ベンチマーク | 1 | WebSearch |
| `ca-positioning-strategist` | ポジショニング・差別化戦略設計 | 2 | 分析 |
| `ca-blind-reviewer` | 独立検証・バイアス排除 | 3 | WebSearch + 批判的分析 |

各エージェントは `.claude/agents/` ディレクトリにサブエージェントとして定義済み。

## ワークフロー

### Step 1: ヒアリング

以下を確認する（不明ならユーザーに AskUserQuestion で質問）:

- **アプリカテゴリ**: 何のカテゴリか（例: フィットネス、家計管理、タスク管理）
- **ターゲットユーザー**: 誰向けか（例: 30代女性、個人事業主）
- **対象地域**: 日本 / 米国 / グローバル
- **知っている競合**: すでに把握している競合名（なくてもOK）
- **自社アプリ概要**: 何を作ろうとしているか（差別化分析に使用）
- **自社の差別化仮説**: 自分たちが考えている差別化ポイント（あれば。検証対象として使用）
- **market-research の出力**: あればパスを確認

### Step 2: プロジェクト初期化

```bash
bash scripts/init.sh <project-name>
# -> ~/.claude/competitive-analysis/YYYY-MM-DD_<project>/ を作成
```

出力される絶対パスを控える。全エージェントのプロンプトに必ず渡す。

### Step 3: チーム作成とタスク割り当て

TeamCreate で `competitive-analysis` チームを作成。

TaskCreate で5つのタスクを作成:

1. **ca-competitor-researcher**: 競合プロファイリング（Round 1、並列）
2. **ca-review-analyst**: レビュー・評判分析（Round 1、並列）
3. **ca-feature-benchmarker**: 機能・価格ベンチマーク（Round 1、並列）
4. **ca-positioning-strategist**: ポジショニング・差別化戦略（Round 2、`addBlockedBy: ["1","2","3"]`）
5. **ca-blind-reviewer**: 独立検証（Round 3、`addBlockedBy: ["4"]`）

### Step 4: Round 1 エージェント起動（並列）

3つのエージェントを **1つのメッセージで並列に** Agent ツールで起動する。

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

### Step 5: Round 1 完了待ち → Round 2 起動

Round 1 の3エージェント全員が完了を報告したら:

1. ファイル存在を検証（competitor-profiles.md, review-insights.md, feature-matrix.md）
2. 不足があればエージェントに再依頼、応答なければフォールバック書き込み
3. ca-positioning-strategist を起動

```
subagent_type: "ca-positioning-strategist"
team_name: "competitive-analysis"
mode: "bypassPermissions"
run_in_background: true
model: opus
```

プロンプトに追加で含める情報:
- Round 1 の全出力ファイルパス
- 自社アプリ概要と差別化仮説

### Step 6: Round 2 完了 → Round 3 起動

positioning-strategist が完了したら:

1. positioning.md のファイル存在を検証
2. ca-blind-reviewer を起動

```
subagent_type: "ca-blind-reviewer"
team_name: "competitive-analysis"
mode: "bypassPermissions"
run_in_background: true
model: opus
```

**重要**: blind-reviewer には Round 1-2 の「結論」を渡さない。
渡すのは:
- アプリカテゴリ、ターゲット、地域（基本情報のみ）
- ベースディレクトリパス
- 「他のエージェントの結論ファイルは Round 3 の突き合わせフェーズまで読まないこと」という指示

### Step 7: ファイル書き込み検証

全エージェント完了後、以下のファイル存在を検証する:

```
{base_dir}/
├── competitor-profiles.md   <- ca-competitor-researcher
├── review-insights.md       <- ca-review-analyst
├── feature-matrix.md        <- ca-feature-benchmarker
├── positioning.md           <- ca-positioning-strategist
├── critique.md              <- ca-blind-reviewer
└── context.md               <- チームリーダー（Step 8 で作成）
```

**検証手順**:
1. Glob でファイル一覧を確認
2. 各ファイルを Read して空でないことを確認
3. 不足・空のファイルがあった場合:
   - 該当エージェントに SendMessage で再書き込みを依頼
   - 応答なし/シャットダウン済みの場合: ディスカッションログから内容を抽出し、チームリーダー自身が Write で書き込む

### Step 8: 統合レポート作成

全ファイルを Read して統合レポートを作成する。

1. `references/report-template.md` を参照
2. 全エージェントの出力を統合して `COMPETITIVE_REPORT.md` を作成
3. `context.md` を作成（プロジェクト情報・入力値・セッション引き継ぎ用）

出力先: `{base_dir}/COMPETITIVE_REPORT.md`

### Step 9: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除
3. レポートのパスをユーザーに報告
4. レポートの要点をユーザーに提示（Executive Summary + 差別化オプション Top3）

---

## フィードバックプロトコル（全エージェント共通）

1. **作業完了したらチームリーダーに SendMessage で報告**
2. **「了解しました」だけのACK返信は不要** - 実質的な内容がある場合のみ返信
3. **全成果物は必ずファイルに書き出す** - Write → Read → SendMessage の順序厳守
4. **Write は絶対パスのみ** - 相対パスは動作しない

## Error Handling

- Round 1 のエージェント1つが失敗: 残り2つの結果で Round 2 に進む（ただしユーザーに警告）
- Round 2 が失敗: Round 1 の出力だけでレポートを作成（差別化戦略は簡易版）
- Round 3 が失敗: blind-reviewer なしでレポート作成（検証なしフラグを明記）
