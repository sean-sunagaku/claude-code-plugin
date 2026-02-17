---
name: logo-design
description: >
  5つの専門エージェント（ブランド戦略・ロゴデザイン・カラー/タイポ・トレンド調査・競合分析）が
  チームでロゴを作成・議論するスキル。
  Pencil(.pen)で複数バリエーションを作成し、SVGアイコンも出力する。
  アプリアイコン、ブランドロゴ、ワードマーク等に対応。
  Use when: ロゴを作りたい、アプリアイコンを作りたい、ブランドロゴをデザインしたい、
  ロゴを変更したい、アイコンを作り直したい。
  Triggers: "ロゴ", "logo", "アイコン作成", "アプリアイコン", "ブランドロゴ",
  "ロゴデザイン", "シンボルマーク", "ワードマーク", "icon design",
  "ロゴ作成", "ロゴ変更", "アイコン変更"
---

# Logo Design Skill

5つの専門エージェントがチームで議論し、Pencil でロゴを作成する。

## ワークフロー

1. ユーザーからブランド情報をヒアリング
2. Agent Team を作成し、5エージェントを並列起動
3. コンセプト策定 → デザイン提案 → 議論・ブラッシュアップ
4. Pencil で 3〜5 バリエーションを作成
5. SVG アイコンも出力
6. 最終レポートを MD で出力

## Step 1: ヒアリング

以下を確認する（不明ならユーザーに質問）:

- **アプリ/サービス名**: ロゴに含める名前
- **概要**: 何をするサービスか
- **ターゲット**: 年齢層、地域、技術レベル
- **ロゴの用途**: アプリアイコン / ブランドロゴ / 両方
- **好みの方向性**: ミニマル / ポップ / プロフェッショナル / 指定なし
- **好きなロゴの例**: あれば参考として
- **避けたいスタイル**: あれば
- **色の希望**: あれば（ブランドカラー等）
- **競合/同業他社**: 知っていれば

## Step 2: チーム作成とエージェント起動

TeamCreate で `logo-design` チームを作成。以下5エージェントを **1つのメッセージで並列に** Task ツールで起動する。

| name | 役割 | 主な手段 |
|------|------|---------|
| `brand-strategist` | コンセプト方向性を3〜5パターン提案 | ブランド分析 |
| `logo-designer` | 形状・構図・シンボルの具体的設計 | デザイン提案 |
| `color-type-expert` | カラーパレット・フォント設計 | 配色理論 |
| `trend-researcher` | 業界トレンド・文化的配慮の調査 | WebSearch |
| `competitive-analyst` | 競合ロゴ調査・差別化戦略 | WebSearch |

### タスク作成

TaskCreate で7つのタスクを作成:

1. brand-strategist: コンセプト方向性の策定
2. competitive-analyst: 競合ロゴ調査
3. trend-researcher: トレンド・文化調査
4. logo-designer: デザイン案の作成（タスク1,2,3のフィードバックを反映）
5. color-type-expert: カラー・タイポグラフィ設計
6. Pencil でデザイン制作: タスク1〜5完了後（`addBlockedBy: ["1","2","3","4","5"]`）
7. 統合レポート + SVG出力: タスク6完了後（`addBlockedBy: ["6"]`）

### 起動設定

```
subagent_type: "brand-strategist"  # agents/ で定義済みのサブエージェント名
team_name: "logo-design"
model: "opus"
mode: "bypassPermissions"
run_in_background: true
```

プロンプトに含める情報:
- アプリ/サービス名、概要、ターゲット
- ロゴの用途（アイコン/ブランドロゴ/両方）
- ユーザーの好み・制約

## Step 3: 議論の進行

```
Round 1: brand-strategist がコンセプト提案 + competitive-analyst & trend-researcher が調査
       → 全員でコンセプトの方向性を議論
Round 2: logo-designer がデザイン案作成 + color-type-expert がカラー/タイポ設計
       → 全員でデザイン案をレビュー・修正
Round 3: 最終案を絞り込み、各観点からスコアリング
```

リーダーは基本見守り。ユーザーの意見があればエージェントに中継する。

## Step 4: Pencil でデザイン制作

エージェントの最終提案に基づき、リーダーが Pencil で制作:

1. `get_style_guide_tags` → `get_style_guide` でスタイル参考を取得
2. `find_empty_space_on_canvas` でキャンバス配置を計画
3. 3〜5バリエーションを `batch_design` で作成:
   - 各バリエーションを横に並べて配置（比較しやすく）
   - フルサイズ版 + アプリアイコン版を両方作成
   - 明るい背景版 + 暗い背景版
4. `get_screenshot` で各バリエーションを確認
5. エージェントに結果を共有して最終確認

## Step 5: SVG アイコン出力

最終決定したロゴのSVGコードを生成:

1. Pencil のデザインを基に SVG コードを手書きで生成
2. フルカラー版とモノクロ版の2種類
3. プロジェクト内に保存（例: `assets/logo.svg`, `assets/logo-mono.svg`）
4. viewBox と path を最適化（不要な属性を削除）

## Step 6: 最終レポート出力

テンプレートは [references/report-template.md](references/report-template.md) を参照。

出力先: プロジェクトルートに `LOGO_DESIGN_REPORT.md`

## Step 7: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除
