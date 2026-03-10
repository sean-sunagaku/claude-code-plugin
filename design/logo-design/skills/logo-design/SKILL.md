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
斜めの直線を多用          水平・垂直の線を基本にする
```

### ⚠️ 対称性・整列の必須ルール

**ロゴの幾何学的な対称性とズレは、ユーザーから明示的に指示されない限り、常に完璧に保つこと。**

これはロゴ品質の最も基本的な要件であり、対称性の崩れは即座に「素人感」「ダサさ」として知覚される。

#### 回転対称（N回対称）

同じ形を N 個配置する場合、**絶対に手動で座標計算しない**。
`<defs>` + `<use>` + `transform="rotate()"` で数学的に完璧な対称を保証する。

```xml
<!-- ❌ NG: 手動で3箇所の座標を計算 → 必ずズレる -->
<path d="M 40,28 A 32,32 0 0,1 88,48" stroke="#0D9488"/>
<path d="M 96,68 A 32,32 0 0,1 56,102" stroke="#14B8A6"/>
<path d="M 32,92 A 32,32 0 0,1 34,40" stroke="#0F766E"/>

<!-- ✅ 正解: 1つ定義して rotate で複製 → 完璧な3回対称 -->
<defs>
  <path id="arc" fill="none" stroke-width="10" stroke-linecap="round"
    d="M 44.5,36.2 A 34,34 0 0,1 94.8,49.6"/>
</defs>
<use href="#arc" stroke="#0D9488" transform="rotate(0, 64, 64)"/>
<use href="#arc" stroke="#14B8A6" transform="rotate(120, 64, 64)"/>
<use href="#arc" stroke="#0F766E" transform="rotate(240, 64, 64)"/>
```

#### 鏡面対称（左右・上下）

左右対称の要素は `scale(-1, 1)` + `translate` で反転コピーする。

```xml
<!-- ✅ 左右対称を保証 -->
<defs>
  <path id="half" d="M 64,20 C 80,30 90,50 90,64"/>
</defs>
<use href="#half" stroke="#0D9488"/>
<use href="#half" stroke="#0D9488" transform="scale(-1,1) translate(-128,0)"/>
```

#### 中心揃え

viewBox `0 0 128 128` の場合、中心は常に `(64, 64)`。
中心に配置する要素は `cx="64" cy="64"` を厳守。

#### 要素間の均等配置

等間隔配置は計算式で求め、目測で調整しない:
- **円周上の N 等分**: 角度 = `360° / N` ずつ回転
- **直線上の N 等分**: 間隔 = `全長 / (N - 1)`

### ⚠️ 線は滑らかに（SVG・Pencil共通）

**直線(line)ではなく曲線(path/Bezier)を使って滑らかに描く。**
直線の斜めstrokeはアンチエイリアスでギザつき・歪みが出やすい。
曲線で滑らかに描くことで、小サイズでも美しく見える。

```
❌ NG:   line要素の直線を組み合わせてアイコンを構成する
✅ 推奨: path + Bezier曲線（C / Q コマンド）で滑らかなカーブにする
✅ 推奨: stroke-linecap="round", stroke-linejoin="round" で端・角を丸める
✅ 代替: polygon / path の塗り面で表現する（面は歪みにくい）
✅ 検証: 必ず小サイズ（32px, 16px）で実際にレンダリングして歪みがないか確認
```

```xml
<!-- ❌ 直線の組み合わせ → 角がカクつく、小サイズで歪む -->
<line x1="70" y1="130" x2="36" y2="44" stroke="white" stroke-width="11"/>

<!-- ✅ Bezier曲線 → 滑らかで美しい -->
<path d="M70,130 C70,100 50,70 36,44" stroke="white" stroke-width="11"
      fill="none" stroke-linecap="round"/>
```

**各バリエーションのチェックリスト:**
- [ ] 1秒見ただけで「何を表しているか」がわかるか
- [ ] 16x16px に縮小しても形が認識できるか
- [ ] ブランドカラーのコントラストが十分に効いているか
- [ ] モノクロにしても成立するか
- [ ] 対称であるべき箇所が完璧に対称か（`rotate`/`scale` で保証されているか）
- [ ] 斜め線が歪んで見えないか（Pencilスクリーンショットで必ず確認）

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
