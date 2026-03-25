---
name: screenshot-creator
description: >
  App Store / Google Play 用のプロモーションスクリーンショットを Pencil (.pen) で生成する
  Agent Team スキル。creative-director が戦略を立て、screenshot-designer が Pencil で
  デザインを構築し、copy-writer がコピーを提供し、spec-validator が技術仕様を数値検証し、
  quality-reviewer が最終品質を確認する。5エージェント体制で高品質なスクリーンショットを生成。
  Use when: App Store スクリーンショットを作りたい、プロモーション画像を作成したい、
  スクショのデザインをしたい。
  Triggers: "スクリーンショット作成", "App Store 画像", "プロモーションスクショ",
  "screenshot creator", "スクショ作って", "App Store 素材"
---

# screenshot-creator スキル

## Step 1: ヒアリング

以下を確認する（不明ならユーザーに質問）:

- **アプリ名**: App Store に表示されるアプリ名
- **カテゴリ**: 生産性、ライフスタイル、ヘルス等
- **主要機能**: 3〜5 個の機能とその説明
- **ターゲットユーザー**: 年齢層・利用シーン等
- **ブランドカラー**: メインカラー（任意。指定なければ creative-director が提案）
- **トーン**: プロフェッショナル / カジュアル / エモーショナル等
- **スクリーンショット枚数**: 1〜10 枚（推奨 5〜6 枚）
- **実スクリーンショット**: アプリの実際のキャプチャ画像のパス（任意。あれば UIモックアップに使用）
- **.pen ファイルパス**: 任意。指定なければ新規作成
- **デバイスサイズ**: iPhone 6.5" / 6.7" / 6.9" / iPad Pro 13"（デフォルト: iPhone 6.5" = 1284×2778px）
- **CaptionArea 構成**: 2行（ヘッドライン+サブ1行）or 3行（ヘッドライン+サブ2行）。ユーザーに確認

## 実スクリーンショットの使用（任意）

ユーザーがアプリの実際のスクリーンショット（PNG/JPG）を提供した場合:

1. **画像パスを確認**: スクリーンショットの絶対パスを把握
2. **.pen ファイルを保存済みにする**: 新規ドキュメント（`new`）では相対パスが解決できないため、
   `mcp__pencil__open_document` で既存ファイルを開くか、保存先を確定させる
3. **screenshot-designer に画像パスを伝える**: 各スクリーンに対応する画像ファイルを指定
4. **image fill で配置**（絶対パス・相対パス両対応）:
   ```javascript
   // 絶対パスで配置（.pen が未保存でも動作する - 推奨）
   mockup=I(mockupArea, {type: "frame", width: 320, height: 520,
     fill: {type: "image", url: "/Users/xxx/project/screenshots/top.png", mode: "fill"},
     cornerRadius: [40, 40, 40, 40]})

   // 相対パスで配置（.pen ファイルが保存済みの場合のみ）
   mockup=I(mockupArea, {type: "frame", width: 320, height: 520,
     fill: {type: "image", url: "./screenshots/top.png", mode: "fill"},
     cornerRadius: [40, 40, 40, 40]})
   ```
   - `mode: "fill"` - フレームを埋めるように配置（推奨）
   - `mode: "fit"` - フレーム内に収まるように配置
   - `mode: "stretch"` - 引き伸ばし（非推奨）
   - **絶対パス推奨**: .pen ファイルが未保存（`new`）でも確実に動作する

> **注意**: `G()` 操作（AI生成/Stock画像）と image fill（ローカルファイル）は使い分ける。
> 実スクリーンショットがある場合は image fill を優先使用する。

### シミュレーター画像の前処理（重要）

iOS シミュレーターのスクリーンショットには macOS のタイトルバー・ツールバーが含まれることがある。
PhoneMockup に配置する前に**必ずシミュレーター枠を除去**すること。

**除去手順（リーダーが実行）:**
```python
# Python (PIL) でシミュレーター枠を自動除去
from PIL import Image

img = Image.open("screenshot.png")
w, h = img.size

# シミュレーター chrome を検出: 上部の連続する灰色行(RGB 20-80)を除去
crop_top = 0
found_black = False
for y in range(min(100, h)):
    pixels = [img.getpixel((x, y))[:3] for x in range(w//4, 3*w//4, 8)]
    avg = sum(sum(p)/3 for p in pixels) / len(pixels)
    if avg < 5:
        found_black = True
    elif found_black and 15 < avg < 90:
        crop_top = y + 1  # ツールバー行
    elif found_black and avg >= 90:
        break
    elif not found_black and avg > 15:
        crop_top = y + 1  # タイトルバー行

cropped = img.crop((0, crop_top, w, h))
cropped.save("screenshot_clean.png")
```

- シミュレーター枠が残ると PhoneMockup 内に「iPhone 16 Pro」テキストが表示されてしまう
- 除去後の画像パスを screenshot-designer に伝えること

## Step 2: チーム作成とエージェント起動

TeamCreate で `screenshot-creator` チームを作成。
以下 5 エージェントを **1つのメッセージで並列に** Task ツールで起動する。

| name | 役割 | 主な手段 |
|------|------|---------|
| `creative-director` | 戦略立案・ディレクション | WebSearch（MCP不使用） |
| `screenshot-designer` | Pencil でビジュアル構築 | Pencil MCP (batch_design, get_screenshot) |
| `copy-writer` | キャッチコピー・説明文 | WebSearch |
| `quality-reviewer` | 品質レビュー・スコアリング | Pencil MCP (get_screenshot, batch_get) |
| `spec-validator` | 技術仕様の数値検証 | Pencil MCP (batch_get, snapshot_layout, get_screenshot) |

### タスク作成

TaskCreate で 6 つのタスクを作成:

1. creative-director: スクリーンショット構成計画・スタイル決定（依存なし）
2. copy-writer: 各スクリーンのコピー作成（依存なし）
3. screenshot-designer: Pencil でデザイン構築（`addBlockedBy: ["1", "2"]`）
4. spec-validator: 技術仕様バリデーション（`addBlockedBy: ["3"]`）
5. quality-reviewer: 品質レビュー + スコアリング（`addBlockedBy: ["3"]`）
6. 最終確認: リーダーが最終確認（`addBlockedBy: ["4", "5"]`）

> **Note**: spec-validator（技術検証）と quality-reviewer（デザイン評価）は **並列実行** される。
> spec-validator は数値ベースの仕様違反を検出し、quality-reviewer は主観的なデザイン品質を評価する。
> 両者の結果が揃ってから最終確認に進む。

### 起動設定

**MCP ツール使用エージェント（screenshot-designer, quality-reviewer, spec-validator）:**
```
subagent_type: "general-purpose"
team_name: "screenshot-creator"
mode: "bypassPermissions"
run_in_background: true
```
プロンプトに `agents/screenshot-designer.md`（または `quality-reviewer.md` / `spec-validator.md`）の内容を全文含めること。

**MCP ツール不使用エージェント（creative-director, copy-writer）:**
```
subagent_type: "screenshot-creator:{role-name}"
team_name: "screenshot-creator"
mode: "bypassPermissions"
run_in_background: true
```

**全エージェント共通でプロンプトに含める情報:**
- ユーザーからヒアリングした全情報（省略厳禁）
- .pen ファイルパス
- チームメンバー一覧と役割
- references/ ファイルのパス（絶対パス）

## Step 3: フィードバックループ

### コピー作成フロー（チーム議論 → ユーザー確認）

コピーは **チーム内で十分に議論・検討してから** ユーザーに提案する。
いきなりユーザーに聞くのではなく、エージェント間で案を練り上げた上で選択肢を提示する。

**Phase 1: チーム内ブレスト（エージェント間 SendMessage）**
1. **copy-writer** がアプリの機能・ターゲットを分析し、各スクリーンのコピー案を **2〜3パターン** 作成
2. **creative-director** がブランド戦略・トーン・構成の観点からコピー案にフィードバック
3. **quality-reviewer** が簡潔さ・インパクト・ベネフィット訴求の観点でコピー案を評価
4. copy-writer がフィードバックを反映し、**最終候補2案** に絞り込む

**Phase 2: ユーザー確認（リーダー経由）**
- copy-writer が最終候補をリーダーに送信
- リーダーが `AskUserQuestion` でユーザーに選択肢を提示:
  - コピーの方向性（A案 vs B案）
  - トーンの好み（カジュアル / フォーマル / エモーショナル）
  - 特定の表現の好み（例: 「"書くだけ" vs "入力するだけ"」）
- ユーザー回答をリーダー → copy-writer に伝達

**Phase 3: 確定・配置**
- copy-writer がユーザー回答を反映した最終コピーを screenshot-designer に送信
- screenshot-designer が CaptionArea に 3 ノード構成で配置

**フロー図:**
```
copy-writer ←→ creative-director ←→ quality-reviewer  （Phase 1: チーム議論）
       ↓
copy-writer → リーダー → AskUserQuestion → ユーザー     （Phase 2: ユーザー確認）
       ↓
copy-writer → screenshot-designer                        （Phase 3: 確定・配置）
```

**copy-writer が自律的に判断してよい項目:**
- 文字数の調整（ガイドライン内であれば）
- 句読点の配置
- ヘッドラインとサブテキストの分割位置

### Round 1: 構成計画 + コピー作成（並列）
- creative-director がスクショ構成計画を作成 → screenshot-designer と copy-writer に共有
- copy-writer が各スクリーンのコピー案を作成 → creative-director・quality-reviewer と議論 → **最終候補をリーダー経由でユーザーに確認** → screenshot-designer に共有

### Round 2: デザイン構築
- screenshot-designer が Pencil でデザイン構築
- 完成後、spec-validator と quality-reviewer に**同時に**検証依頼

### Round 3: 技術検証 + 品質レビュー（並列）
- **spec-validator**: フレームサイズ・モックアップ面積比・画像fill・セーフエリア・テキストサイズ・コントラスト比・統一性・**カラーパターン・アクセントバー不在・サブテキスト視認性**を数値検証
  - FAIL 項目は U() 修正コード付きで screenshot-designer にフィードバック
  - **テキスト検証項目**: CaptionArea 内のテキストノード数が3以下か / `alignItems: "center"` か / `textAlign: "center"` か / headline の fontSize ≥ 30 か
- **quality-reviewer**: ビジュアル品質・**コピー品質（簡潔さ・ベネフィット訴求）**・構成を主観評価し 10 点満点でスコアリング
  - 必須修正事項と推奨改善事項を screenshot-designer にフィードバック
  - **コピー検証項目**: 1スクリーンあたり3ノード以下か / 機能説明ではなくベネフィットか / 読みやすさ・インパクト / チーム議論を経た最終案か

### Round 4: 修正 + 再検証
- screenshot-designer が spec-validator と quality-reviewer のフィードバックを反映
- spec-validator: FAIL 項目のみ再検証 → 全 PASS で合格
- quality-reviewer: 修正箇所を再確認 → 7/10 以上で合格
- creative-director が最終報告をリーダーに送信

### 緊急通知パターン
- **spec-validator**: フレームサイズ不一致・モックアップ面積比 40% 未満を検出 → screenshot-designer に即修正依頼
- **spec-validator**: テキスト3行以上・中央揃え未設定を検出 → screenshot-designer に即修正依頼
- **quality-reviewer**: コントラスト比不足・セーフエリア侵害を検出 → screenshot-designer に即修正依頼
- **quality-reviewer**: コピーが長文・機能説明的 → copy-writer に短縮・リライト依頼
- **copy-writer**: Apple ガイドライン違反のテキスト（価格表示等）を発見 → 全員に警告
- **screenshot-designer**: .pen ファイルの破損・競合を検知 → 全員に中断連絡

## Step 4: 最終確認

リーダーが以下を確認:
- **spec-validator**: 全 10 項目が PASS（FAIL なし）（フレームサイズ・モックアップ面積比・画像fill・セーフエリア・テキストサイズ・コントラスト比・統一性・テキスト行数・テキスト配置）
- **quality-reviewer**: 品質スコアが 7/10 以上
- 全スクリーンショットに日本語・英語コピーが設定されている
- .pen ファイルが正常に保存されている

## Step 5: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除

## Step 6: エクスポート

最終確認後、以下の手順で PNG エクスポートする。

> **⚠ 重要: `export_nodes` のデフォルト scale は 2（@2x）。App Store には @3x が必要。`scale: 3` を必ず指定すること。**
> scale: 2 だと 856×1852px になり、App Store に提出できない。

### 6-1. フレームに `clip: true` を設定

PhoneMockup のドロップシャドウがフレーム外にはみ出し、エクスポート画像のサイズがフレームサイズより大きくなる。
エクスポート前に**必ず**全フレームに `clip: true` を設定する:

```javascript
U("frame1Id", {clip: true})
U("frame2Id", {clip: true})
U("frame3Id", {clip: true})
```

### 6-2. フレーム情報を取得（リネーム用マッピング）

`batch_get` で全フレームの ID と name を取得する:

```
mcp__pencil__batch_get:
  filePath: "path/to/file.pen"
  patterns: [{"type": "frame", "name": "SS"}]
  searchDepth: 1
```

結果から `id:name` マッピングを作成する:
```
b4SOM:SS01_Hero dBSNw:SS03_Result SM4Ui:SS04_Template
dhs8L:SS01_Hero_EN WG7lQ:SS03_Result_EN eE2yT:SS04_Template_EN
...
```

### 6-3. 言語別にエクスポート（scale: 3 必須）

`export_nodes` を言語グループごとに呼び出す。**scale: 3 を必ず指定**:

```
mcp__pencil__export_nodes:
  filePath: "path/to/file.pen"
  outputDir: "/tmp/pencil-export"
  nodeIds: ["b4SOM", "dBSNw", "SM4Ui", ...]
  format: "png"
  scale: 3          ← 必須！デフォルトの 2 では App Store サイズにならない
```

### 6-4. リネーム・整理・検証スクリプトを実行

`export_nodes` はノード ID をファイル名にする（例: `b4SOM.png`）。
付属スクリプトでフレーム名にリネームし、言語別フォルダに整理し、サイズを検証する:

```bash
scripts/export-screenshots.sh /tmp/pencil-export ./exported \
  b4SOM:SS01_Hero dBSNw:SS03_Result SM4Ui:SS04_Template \
  dhs8L:SS01_Hero_EN WG7lQ:SS03_Result_EN eE2yT:SS04_Template_EN \
  mKJ5F:SS01_Hero_ZH BEODM:SS03_Result_ZH rwu06:SS04_Template_ZH \
  sKzRu:SS01_Hero_KO HYsfY:SS03_Result_KO 0utRp:SS04_Template_KO
```

スクリプトの動作:
1. **リネーム**: ノードID.png → フレーム名.png（例: `b4SOM.png` → `SS01_Hero.png`）
2. **言語振り分け**: サフィックスで自動判定（`_EN` → `EN/`、`_ZH` → `ZH/`、`_KO` → `KO/`、なし → `JP/`）
3. **サイズ検証**: 全ファイルが App Store 要求サイズ（1284×2778 等）と一致するか検証
4. **サマリー出力**: PASS / FAIL / MISSING をレポート

出力ディレクトリ構造:
```
exported/
  JP/SS01_Hero.png
  JP/SS03_Result.png
  JP/SS04_Template.png
  EN/SS01_Hero.png
  EN/SS03_Result.png
  ...
```

### App Store 要求サイズ一覧

| フレームサイズ | @3x エクスポート | App Store サイズ |
|---|---|---|
| 428 × 926 pt | **1284 × 2778 px** | iPhone 6.5" ✓ |
| 430 × 932 pt | 1290 × 2796 px | iPhone 6.7" ✓ |
| 440 × 956 pt | 1320 × 2868 px | iPhone 6.9" ✓ |

> **clip: true を忘れるとシャドウ分だけ画像が大きくなり、App Store に提出できない。**
> **scale: 3 を忘れると @2x（856×1852px）になり、App Store に提出できない。**

## Step 7: 多言語対応（任意）

App Store は言語ごとに異なるスクリーンショットを登録できる。
日本語版を作成後、**C()（コピー）操作でフレームを複製し、CaptionArea のテキストのみ差し替える**ことで効率的に多言語版を作成できる。

### 対応言語の確認

ユーザーに対応言語を確認する。一般的な構成:
- **日本語**（メイン）
- **英語**（グローバル）
- **中国語（簡体）**
- **韓国語**

### 多言語フレームの作成手順

**1. 日本語版フレームを C() で複製:**
```javascript
// 英語版（y を下にずらして配置）
en_hero=C("ja_heroFrameId", document, {
  name: "SS01_Hero_EN",
  x: 0, y: 960,
  placeholder: true,
  descendants: {
    "captionAreaId/headlineId": {content: "Set Your Packing List"},
    "captionAreaId/subtextId": {content: "Never forget your things"}
  }
})
```

- `placeholder: true` でコピーし、テキスト差し替え後に `U(id, {placeholder: false})` で解除
- `descendants` で CaptionArea 内のテキストノードのみ差し替え（PhoneMockup の画像はそのまま）
- 言語ごとに y 座標をずらして整列配置（例: JA=0, EN=960, ZH=1920, KO=2880）

**2. 全言語を一括でコピー:**

1回の `batch_design` で全言語×全スクリーンを同時にコピーできる（最大25操作/回）。
3画面×3言語 = 9操作なら1回で完了。

**3. placeholder 解除:**
```javascript
U("en_heroId", {placeholder: false})
U("en_resultId", {placeholder: false})
// ...全フレーム
```

**4. get_screenshot で各言語を目視確認**

### 翻訳ガイドライン

- **ヘッドライン**: 短く、その言語で自然な表現にする（直訳NG）
- **サブテキスト**: ベネフィットを伝える自然な表現
- **文字数**: 言語によって文字幅が異なるため、CaptionArea に収まることを確認
  - 英語: 日本語より長くなりがち → 短い単語を選ぶ
  - 中国語: 日本語と近い文字数
  - 韓国語: 日本語よりやや長い

### PhoneMockup 内のアプリ画面について

- **基本**: 日本語版のスクリーンショット画像をそのまま使用（アプリ内UIは日本語のまま）
- **理想**: 各言語のローカライズ済みアプリ画面のスクリーンショットを用意して差し替え
- ユーザーに確認: 「アプリ内画面も各言語版がありますか？」

### 命名規則

フレーム名に言語サフィックスを付ける:
- `SS01_Hero` → `SS01_Hero_EN`, `SS01_Hero_ZH`, `SS01_Hero_KO`
- `SS03_Result` → `SS03_Result_EN`, `SS03_Result_ZH`, `SS03_Result_KO`

### エクスポート

言語ごとにフォルダを分けてエクスポートする:
```
product/screenShot/export/ja/  ← 日本語版
product/screenShot/export/en/  ← 英語版
product/screenShot/export/zh/  ← 中国語版
product/screenShot/export/ko/  ← 韓国語版
```

## 出力成果物

- Pencil .pen ファイル（全言語×全スクリーンショット）
- **PNG エクスポート画像**（App Store 要求サイズ一致を sips で確認済み、言語別フォルダ）
- 各スクリーンショットのノードID一覧
- コピーテキスト一覧（全対応言語）
- 技術仕様バリデーションレポート（spec-validator: 10項目 PASS/WARN/FAIL）
- 品質レビュースコア（quality-reviewer: 10点満点）

## PhoneMockup レイアウトガイドライン

### アスペクト比の一致（重要）

PhoneMockup フレームのアスペクト比は、**実際のスクリーンショット画像の比率と一致**させること。
比率がズレると `fill` モードで画像の上下・左右がクリップされ、アプリ画面の一部が見切れる。

**手順:**
1. 実スクリーンショット画像のサイズを `sips -g pixelWidth -g pixelHeight <image>` で確認
2. 画像の比率（width / height）を算出
3. PhoneMockup のサイズを画像比率に合わせて設定
4. MockupArea の高さ内に収まることを確認

| 項目 | 値 |
|------|-----|
| **推奨 PhoneMockup サイズ** | **320 × 640**（比率 0.50、一般的なシミュレータスクショに対応） |
| iPhone 標準比率 | 約 0.46（390 / 844） |
| シミュレータスクショ比率 | 約 0.50（864 / 1723） |
| NG 例 | 350 × 600（比率 0.58 → 上下が大きくクリップ） |
| NG 例 | 300 × 660（比率 0.45 → 画像比率 0.50 と不一致で左右クリップ） |

### CaptionArea とのバランス

フレーム全体内での推奨配分:

**iPhone 6.5"（デフォルト: 428 × 926 pt）:**

| エリア | 2行構成 | 3行構成 | 備考 |
|--------|---------|---------|------|
| CaptionArea | 130pt | 160pt | padding: [30, 24, 12, 24] |
| MockupArea | 残り（796pt） | 残り（766pt） | PhoneMockup + 余白 |

**MockupArea の背景色は CaptionArea と同じ `#F2F7F5` に統一すること。**
別の色（例: #E8EFED）を使うと色の境目が目立ち、デザインが分断される。

> **原則**: CaptionArea を小さく、PhoneMockup を大きくして、アプリ画面をできるだけ多く見せる。

### CaptionArea テキストガイドライン

テキストは**短く、中央揃え**で配置する。**2行構成 or 3行構成**をユーザーに確認する。

**構成A（2ノード — 推奨）:**
- **ヘッドライン（1行）**: 短いキャッチコピー（fontSize 32, fontWeight 700）
- **サブテキスト（1行）**: 短い補足（fontSize 18）

**構成B（3ノード）:**
- **ヘッドライン（1行）**: 短いキャッチコピー（fontSize 32, fontWeight 700）
- **サブテキスト1（1行）**: 補足説明の前半（fontSize 18）
- **サブテキスト2（1行）**: 補足説明の後半（fontSize 18）

**CaptionArea カラーパターン（2種類）:**

| パターン | 背景 | ヘッドライン | サブテキスト | ロゴ |
|---------|------|-----------|-----------|-----|
| **ライト（推奨）** | `#F2F7F5` | `#1A1A1A` | `#4A5A54` | `rgba(0,0,0,0.2)` |
| **ダーク** | `#2D6B5E` | `#FFFFFF` | `#FFFFFF` | `rgba(255,255,255,0.5)` |

- **ライトパターンを推奨** — 背景がアプリ画面と馴染み、テキストの視認性が高い
- ダークパターンはコントラスト不足でサブテキストが見えにくくなるリスクがある
- 全スクリーンで同一パターンに統一すること（混在NG）

**ルール:**
- テキストノードは最大3つまで（ヘッドライン + サブテキスト2行）
- 4行以上のテキストは禁止（長文は読まれない）
- CaptionArea は `alignItems: "center"`, `justifyContent: "center"` で中央配置
- テキストノードは `textAlign: "center"` で中央揃え
- `\n` 改行は使わない（縦長になるため）— 行を分けるには別テキストノードにする
- **サブテキストの横幅に注意** — 1行あたり約12文字以内なら1行でOK。それ以上は2行に分割する。横に長いテキストは読みにくく、中央揃えのバランスも崩れる
- **サブテキストは fontSize 18 を使う** — fontSize 16 では小さすぎて視認性が低い。色は上記カラーパターン表に従う
- **ノード追加時の順序に注意** — `I()` で CaptionArea にテキストノードを追加すると末尾（logo・accent の後）に配置される。必ず `M()` で正しい位置（headline の直後）に移動すること
- **CaptionArea にアクセントバー（装飾線）を入れない** — 小さなフレーム（例: 40×3px）がCaptionAreaの高さからはみ出し、スマホモックアップの上端に緑色の線として表示されてしまう。ライトパターンでは不要

**コピーの書き方:**
- 機能説明ではなく「ユーザーが得られるベネフィット」を書く
- **ヘッドラインに句読点（「、」「。」）は使わない** — 読点で区切るパターンは避ける（例: NG「悩みを、書くだけ。」→ OK「悩みを書くだけ」）
- ヘッドラインは動詞で終わる短い文（例: 「悩みを書くだけ」「未来を見てみよう」）
- サブテキストは短い2行で補足（例: 「テキストを入力して」「ボタンを押すだけでOK」）

**各エージェントの責務:**

| エージェント | テキストに関する責務 |
|---|---|
| **copy-writer** | ヘッドライン + サブテキスト2行のコピーを作成。短く・ベネフィット重視・中央揃えで映える文を提供 |
| **screenshot-designer** | copy-writer のコピーを CaptionArea に 3 ノード構成で配置。fontSize・fill・textAlign を設定 |
| **spec-validator** | テキストノード数 ≤ 3 / `alignItems: "center"` / `textAlign: "center"` / headline fontSize ≥ 30 を数値検証 |
| **quality-reviewer** | コピーの簡潔さ・インパクト・ベネフィット訴求・全スクリーン間の一貫性を主観評価 |

**CaptionArea ノード構成例（2行構成 — 推奨）:**
```javascript
captionArea=I(frame, {type: "frame", layout: "vertical", alignItems: "center",
  justifyContent: "center", gap: 6, height: 130, padding: [30, 24, 12, 24], fill: "#F2F7F5"})
headline=I(captionArea, {type: "text", content: "持ち物メモをセット",
  fontSize: 32, fontWeight: "700", textAlign: "center", fill: "#1A1A1A"})
sub1=I(captionArea, {type: "text", content: "忘れ物はもうしない",
  fontSize: 18, textAlign: "center", fill: "#4A5A54"})
```

**CaptionArea ノード構成例（3行構成）:**
```javascript
captionArea=I(frame, {type: "frame", layout: "vertical", alignItems: "center",
  justifyContent: "center", gap: 6, height: 160, padding: [40, 24, 12, 24], fill: "#F2F7F5"})
headline=I(captionArea, {type: "text", content: "悩みを書くだけ",
  fontSize: 32, fontWeight: "700", textAlign: "center", fill: "#1A1A1A"})
sub1=I(captionArea, {type: "text", content: "テキストを入力して",
  fontSize: 18, textAlign: "center", fill: "#4A5A54"})
sub2=I(captionArea, {type: "text", content: "ボタンを押すだけでOK",
  fontSize: 18, textAlign: "center", fill: "#4A5A54"})
```

### クリップ・見切れの禁止ルール

以下は**絶対に守る**こと:

- **PhoneMockup の端が途中で切れてはいけない** — フレームの角丸（cornerRadius）が完全に表示されること
- **アプリ画面の上端（ステータスバー）が見切れてはいけない** — 画面上部が表示されないと「実際のアプリ体験」が伝わらない
- **アプリ画面の左右が切れてはいけない** — image fill の比率不一致で横がクリップされる問題に注意
- **モックアップがフレーム外にはみ出してはいけない** — MockupArea 内に完全に収まること（`snapshot_layout` で `problems` が空であることを確認）
- **image fill の `mode: "fill"` 使用時は、画像の実際の比率と PhoneMockup の比率を一致させる**

**検証手順:**
1. `snapshot_layout` で PhoneMockup の `problems` フィールドを確認 → 空であること
2. `get_screenshot` で PhoneMockup の角丸が完全に表示されていることを目視確認
3. アプリ画面のステータスバー・左右端が切れていないことを目視確認

> これらは spec-validator の検証項目にも含まれる。FAIL 時は screenshot-designer に即修正を依頼する。

## App Store スクリーンショット仕様

詳細は [references/app-store-screenshot-specs.md](references/app-store-screenshot-specs.md) を参照。
