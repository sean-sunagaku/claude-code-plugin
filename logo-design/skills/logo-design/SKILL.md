---
name: logo-design
description: >
  6つの専門エージェント（ブランド戦略・ロゴデザイン・カラー/タイポ・トレンド調査・競合分析・コンテキスト管理）が
  チームで議論しながらロゴを作成・改善するスキル。
  エージェント間の相互フィードバックで質を高め、コンテキストファイルで次回セッションに引き継ぐ。
  Pencil(.pen)で複数バリエーションを作成し、SVGアイコンと議事録も出力する。
  アプリアイコン、ブランドロゴ、ワードマーク等に対応。
  Use when: ロゴを作りたい、アプリアイコンを作りたい、ブランドロゴをデザインしたい、
  ロゴを変更したい、アイコンを作り直したい。
  Triggers: "ロゴ", "logo", "アイコン作成", "アプリアイコン", "ブランドロゴ",
  "ロゴデザイン", "シンボルマーク", "ワードマーク", "icon design",
  "ロゴ作成", "ロゴ変更", "アイコン変更"
---

# Logo Design Skill

6つの専門エージェントがチームで相互フィードバックしながら議論し、Pencil でロゴを作成する。
コンテキストファイルで過去の学びを蓄積し、次のロゴ改善ラウンドに引き継ぐ。

## ワークフロー

1. ユーザーからブランド情報をヒアリング
2. Agent Team を作成し、6エージェントを並列起動
3. コンテキストファイル作成 → コンセプト策定 → 相互フィードバック → デザイン提案
4. Pencil で 3〜5 バリエーションを作成
5. SVG アイコン出力
6. 議事録（全体 + ステップ別）と最終レポートを MD で出力

## コンテキストファイル構成

各セッションで以下のファイルを作成・管理する:

```
.claude/logo-design/{YYYY-MM-DD}_{project}/
├── context.md              ← 全体コンテキスト（ブランド情報・学びの蓄積）
├── SUMMARY.md              ← 全ステップを横断するサマリー
└── step-{N}/               ← N は 01, 02, 03... の2桁ゼロ埋め
    ├── context.md          ← このステップの目的・制約・方針
    ├── log.md              ← このステップの議事録（時系列・決定事項）
    └── logos/              ← このステップで生成したロゴファイル（SVG等）
```

これにより:
- 次回ロゴ改善時に `context.md` を読めばすぐにコンテキストを復元できる
- 各ステップの `log.md` で「なぜその方向性を選んだか」を追跡できる
- `step-N/logos/` に SVG を保存すればステップごとの成果物が管理できる

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

TeamCreate で `logo-design` チームを作成。以下6エージェントを **1つのメッセージで並列に** Task ツールで起動する。

| name | 役割 | 主な手段 |
|------|------|---------|
| `context-manager` | コンテキストファイル・議事録の作成と管理 | Write/Edit |
| `brand-strategist` | コンセプト方向性を3〜5パターン提案 | ブランド分析 |
| `logo-designer` | 形状・構図・シンボルの具体的設計 | デザイン提案 |
| `color-type-expert` | カラーパレット・フォント設計 | 配色理論 |
| `trend-researcher` | 業界トレンド・文化的配慮の調査 | WebSearch |
| `competitive-analyst` | 競合ロゴ調査・差別化戦略 | WebSearch |

### タスク作成

TaskCreate で8つのタスクを作成:

1. context-manager: コンテキストファイルとステップ議事録の初期作成
2. brand-strategist: コンセプト方向性の策定（タスク1完了後: `addBlockedBy: ["1"]`）
3. competitive-analyst: 競合ロゴ調査
4. trend-researcher: トレンド・文化調査
5. logo-designer: デザイン案の作成（タスク2,3,4のフィードバックを反映: `addBlockedBy: ["2","3","4"]`）
6. color-type-expert: カラー・タイポグラフィ設計（タスク2完了後: `addBlockedBy: ["2"]`）
7. Pencil でデザイン制作: タスク2〜6完了後（`addBlockedBy: ["2","3","4","5","6"]`）
8. 議事録完成 + 統合レポート + SVG出力: タスク7完了後（`addBlockedBy: ["7"]`）

### 起動設定

```
subagent_type: "context-manager"   # agents/ で定義済みのサブエージェント名
team_name: "logo-design"
model: "opus"
mode: "bypassPermissions"
run_in_background: true
```

プロンプトに含める情報（全エージェント共通）:
- アプリ/サービス名、概要、ターゲット
- ロゴの用途（アイコン/ブランドロゴ/両方）
- ユーザーの好み・制約
- コンテキストファイルパス: `.claude/logo-design/{date}_{project}/`（context-manager に伝える）
- 既存の context.md がある場合はその内容も含める（前回の学びを引き継ぐ）

## Step 3: エージェント間フィードバックループ

エージェント同士が**能動的に**コミュニケーションし、複数ラウンドで相互フィードバックを行う。
リーダーは基本見守り。ユーザーの意見があればエージェントに中継する。

### フィードバックプロトコル（全エージェント共通ルール）

1. **自分の作業が終わったら即座に全員へ共有**: SendMessage で brand-strategist, logo-designer, color-type-expert, trend-researcher, competitive-analyst の全員に送る
2. **他のエージェントから受け取ったメッセージには必ず返信する**: 同意・反論・質問いずれかを必ず送る（無視禁止）
3. **フィードバックを受けたら自分の提案を修正する**: 修正後に修正内容を送信元に報告する
4. **能動的に意見を求める**: 自分の専門外の視点は積極的に他エージェントに質問する

### Round 1: リサーチとコンセプト策定（並列進行）

```
[brand-strategist]
  → 全員に: 3〜5のコンセプト方向性を送信し「このうちどれが最も差別化できるか？」と質問

[competitive-analyst]
  → brand-strategistに: 競合調査結果 + 「コンセプトXは競合Yに似すぎている」などの具体的フィードバック
  → logo-designerに: 「この色域/形状は競合と被っている」という事前警告

[trend-researcher]
  → brand-strategistに: トレンド調査結果 + 各コンセプトへのトレンド適合度
  → color-type-expertに: 「現在のトレンドカラーはこれ」という情報提供

[brand-strategist（受信後）]
  → 全員に: competitive-analyst・trend-researcher のフィードバックを反映した修正版コンセプトを送信
```

### Round 2: デザイン案とカラー設計（相互連携）

```
[logo-designer]
  → 全員に: 3〜5のデザイン案を詳細に提案し「各案の懸念点を教えて」と依頼

[color-type-expert]
  → logo-designerに: 「案Aにはこのカラーパレットが最適、案Bには...」と案ごとに具体的な色提案
  → 「このカラーでアクセシビリティ基準を満たすか？」と自己確認結果を共有

[trend-researcher]
  → logo-designerに: 各案のトレンド適合度フィードバック（◎/○/△/×）
  → 「案Cはトレンドから外れている、こう修正すれば...」という具体的改善案

[competitive-analyst]
  → logo-designerに: 「案Bは競合Xに類似している」「案Dは差別化できている」と具体的評価
  → brand-strategistに: 「このデザインでブランドコンセプトが伝わるか？」と確認

[logo-designer（受信後）]
  → 全員に: フィードバックを反映した修正案 + 「修正ポイントはここ、まだ懸念があれば指摘を」
```

### Round 3: 最終評価とスコアリング

```
全エージェント → 全員に: 最終案（1〜2案に絞る）を以下のフォーマットでスコアリング

  推奨案: [案名]
  スコア: ブランド一致度/差別化度/トレンド適合/実装可能性 = 各5点満点
  総合: XX/20点
  推奨理由: [簡潔に]
  懸念点: [あれば]

最高スコアの案 or 複数エージェントが推す案をリーダーが採用
```

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

### ⚠️ Pencil batch_design の必須ルール

**フレームには必ず `layout: "none"` を指定すること。**

Pencil のフレームはデフォルトで Flexbox（自動レイアウト）モードになる。
この状態では子要素に `x`, `y` を指定しても**完全に無視される**。

```javascript
// ❌ 悪い例: x/y が無視される
I(document, {type:"frame", x:100, y:200, width:500, height:400})

// ✅ 正しい例: layout:"none" で絶対座標配置モードになる
I(document, {type:"frame", x:100, y:200, width:500, height:400, layout:"none", placeholder:true})
```

**適用対象**: 絶対位置を使う全フレーム（セクションフレーム、各カード、アイコンコンテナすべて）

### ロゴ品質ガイドライン

**よいロゴの条件（メリハリを出す）:**

```
❌ 避けること              ✅ やること
─────────────────────────────────────────
細い線を多用              太いストローク（strokeWidth 10px以上）
似た色のみで単調          ブランドカラー間の明度・彩度のコントラストを強く出す
要素を詰め込む            1アイコン = 1アイデアに絞る
複雑な形状                シンプルな幾何学形状（円・Y字・M字等）
```

**各バリエーションのチェックリスト:**
- [ ] 1秒見ただけで「何を表しているか」がわかるか
- [ ] 16x16px に縮小しても形が認識できるか
- [ ] グリーンとオレンジのコントラストが十分に効いているか
- [ ] モノクロにしても成立するか

## Step 5: SVG アイコン出力

最終決定したロゴのSVGコードを生成:

1. Pencil のデザインを基に SVG コードを手書きで生成
2. フルカラー版とモノクロ版の2種類
3. ステップフォルダに保存: `.claude/logo-design/{date}_{project}/step-{N}/logos/`
4. プロジェクト内にも保存（例: `assets/logos/logo-final.svg`）
5. viewBox と path を最適化（不要な属性を削除）

## Step 6: 議事録と最終レポート出力

### 議事録（context-manager が担当）

- **全体ログ**: `.claude/logo-design/{date}_{project}/SUMMARY.md` を更新
- **ステップログ**: `.claude/logo-design/{date}_{project}/step-{N}/log.md` を完成させる
- **次回引き継ぎ**: 全体 `context.md` の「過去のラウンドで学んだこと」に追記

### 最終レポート

テンプレートは [references/report-template.md](references/report-template.md) を参照。

出力先: プロジェクトルートに `LOGO_DESIGN_REPORT.md`

レポートには以下を含む:
- 採用した最終案とその理由
- 各エージェントのスコアリング結果
- 次のステップへの推奨事項

## Step 7: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除

---

## Shell Scripts リファレンス

スキルと同梱の scripts を使うと、コンテキストファイルの初期化・管理が簡単になる。

### init.sh - プロジェクト初期化

```bash
bash scripts/init.sh <project-name>

# 例
bash scripts/init.sh miravy
# → .claude/logo-design/2026-02-18_miravy/ を作成
```

作成されるファイル:
```
.claude/logo-design/{date}_{project}/
├── context.md              ← ブランド情報を記入する
├── SUMMARY.md
└── step-01/
    ├── context.md
    ├── log.md
    └── logos/
        ├── icon-template.svg   ← アイコン単体テンプレート (512x512)
        └── logo-template.svg   ← アイコン+ワードマーク テンプレート
```

### new-step.sh - 新ステップ作成

```bash
bash scripts/new-step.sh <project-dir>

# 例
bash scripts/new-step.sh ~/.claude/logo-design/2026-02-18_miravy
# → step-02/ を作成
```

### status.sh - 進捗確認

```bash
# 全プロジェクト表示
bash scripts/status.sh

# 特定プロジェクト
bash scripts/status.sh ~/.claude/logo-design/2026-02-18_miravy
```

### finalize.sh - 最終仕上げ

```bash
bash scripts/finalize.sh <project-dir> <step-number> [logo-indices...]

# 例: step-02 の v1, v3 を final/ に
bash scripts/finalize.sh ~/.claude/logo-design/2026-02-18_miravy 02 1 3

# 例: step-02 の全SVGを final/ に
bash scripts/finalize.sh ~/.claude/logo-design/2026-02-18_miravy 02
```

出力:
```
final/
├── icons/    ← アイコン単体 SVG (App Store 用)
├── logos/    ← フルロゴ SVG (アイコン+ワードマーク)
└── report.md ← 最終レポートテンプレート
```
