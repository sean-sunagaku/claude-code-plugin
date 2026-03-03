# CSS → Pencil 完全マッピング

screen-analyzer, design-builder, quality-reviewer が共通で参照する変換ルール。

---

## 1. レイアウト

### Flexbox / Grid → Pencil layout

| CSS | Pencil プロパティ | 備考 |
|-----|-----------------|------|
| `display: flex; flex-direction: column` | `layout: "vertical"` | |
| `display: flex; flex-direction: row` | `layout: "horizontal"` | |
| `display: grid` | `layout: "horizontal"` + 固定幅カラムで代替 | grid は直接対応なし |
| `display: block` | layout 省略（デフォルト） | |
| `flex: 1` / `width: 100%` | `width: "fill_container"` | 親が horizontal/vertical の場合 |
| `width: auto` / `width: fit-content` | `width: "fit_content"` | |
| `height: 100%` | `height: "fill_container"` | |
| `min-height: Npx` | `height: "fit_content(N)"` | 最小 N だが中身で伸びる |
| `width: Npx`（固定） | `width: N` | 数値 |
| `height: Npx`（固定） | `height: N` | 数値 |
| `flex-shrink: 0` | width/height を固定数値で指定 | |

### Alignment

| CSS | Pencil プロパティ | 備考 |
|-----|-----------------|------|
| `justify-content: flex-start` | `justifyContent: "start"` | |
| `justify-content: flex-end` | `justifyContent: "end"` | |
| `justify-content: center` | `justifyContent: "center"` | |
| `justify-content: space-between` | `justifyContent: "space_between"` | **アンダースコア** |
| `justify-content: space-around` | `justifyContent: "space_around"` | |
| `justify-content: space-evenly` | `justifyContent: "space_evenly"` | |
| `align-items: flex-start` | `alignItems: "start"` | |
| `align-items: flex-end` | `alignItems: "end"` | |
| `align-items: center` | `alignItems: "center"` | |
| `align-items: stretch` | `alignItems: "stretch"` | |
| `align-self: flex-start` | `alignSelf: "start"` | 子ノードに指定 |
| `align-self: center` | `alignSelf: "center"` | |
| `align-self: flex-end` | `alignSelf: "end"` | |

---

## 2. スペーシング

| CSS | Pencil プロパティ | 備考 |
|-----|-----------------|------|
| `gap: Npx` | `gap: N` | |
| `column-gap: Npx` | `gap: N`（horizontal layout） | |
| `row-gap: Npx` | `gap: N`（vertical layout） | |
| `padding: Npx` | `padding: N` | 4辺均一 |
| `padding: TopBottom LeftRight px` | `padding: [TopBottom, LeftRight]` | 2値 |
| `padding: Top Right Bottom Left px` | `padding: [Top, Right, Bottom, Left]` | 4値 |
| `margin` | Pencil に `margin` なし → 親の padding/gap で代替 | |

---

## 3. 色・背景

| CSS | Pencil プロパティ | 備考 |
|-----|-----------------|------|
| `background-color: #hex` | `fill: "#hex"` | フレーム/矩形の背景 |
| `background-color: var(--bg)` | `fill: "$--background"` | デザイントークン推奨 |
| `color: #hex`（テキスト） | `fill: "#hex"` | **テキストも `fill` を使う** |
| `color: var(--fg)` | `fill: "$--foreground"` | |
| `opacity: 0.5` | `opacity: 0.5` | |
| `background: linear-gradient(...)` | 下記「グラデーション変換」参照 | **CSS 構文そのままは不可** |
| `background-image: url(...)` | G() 操作で stock/AI 画像を適用 | |
| `background: transparent` | `fill` プロパティ省略 | |

### グラデーション変換（重要）

**CSS の `linear-gradient()` を Pencil の `fill` にそのまま渡すと表示されない。**
Pencil 専用の構造化グラデーション構文に変換すること。

#### Pencil gradient 構文（検証済み・推奨）

```javascript
fill: {
  type: "gradient",
  gradientType: "linear",
  rotation: 135,
  colors: [
    { color: "#0ea5e9", position: 0 },
    { color: "#2563eb", position: 1 }
  ]
}
```

#### CSS angle → Pencil rotation 変換

| CSS | Pencil rotation |
|-----|----------------|
| `to bottom` | `180` |
| `to right` | `90` |
| `to bottom right` / `135deg` | `135` |
| `to top` | `0` |
| `to left` | `270` |
| `{X}deg` | `X`（そのまま） |

#### 変換例

```
CSS:  background: linear-gradient(135deg, #0ea5e9, #2563eb)
Pencil: fill: {type: "gradient", gradientType: "linear", rotation: 135, colors: [{color: "#0ea5e9", position: 0}, {color: "#2563eb", position: 1}]}

CSS:  background: linear-gradient(to bottom, #ffffff, #f3f4f6)
Pencil: fill: {type: "gradient", gradientType: "linear", rotation: 180, colors: [{color: "#ffffff", position: 0}, {color: "#f3f4f6", position: 1}]}
```

#### screen-analyzer への指示

chrome-analysis.md にグラデーション値を書く際は Pencil 構文に変換済みで記載:

```markdown
- **Pencil fill**: {type: "gradient", gradientType: "linear", rotation: 135, colors: [{color: "#0ea5e9", position: 0}, {color: "#2563eb", position: 1}]}
- **CSS 原値**: linear-gradient(135deg, #0ea5e9, #2563eb)
```

### デザイントークン（$-- プレフィックス）

| トークン | 用途 |
|---------|------|
| `$--background` | ページ背景 |
| `$--foreground` | プライマリテキスト |
| `$--muted-foreground` | セカンダリテキスト・プレースホルダー |
| `$--card` | カード背景 |
| `$--border` | ボーダー・区切り線 |
| `$--primary` | プライマリアクション・ブランドカラー |
| `$--secondary` | セカンダリ要素 |
| `$--destructive` | 削除・危険アクション |
| `$--color-success` | 成功状態背景 |
| `$--color-success-foreground` | 成功状態テキスト |
| `$--color-warning` | 警告状態背景 |
| `$--color-error` | エラー状態背景 |
| `$--color-info` | 情報状態背景 |
| `$--font-primary` | 見出し・ラベル・ナビゲーション |
| `$--font-secondary` | 本文・説明・インプット |
| `$--radius-none` | テーブル・シャープなコンテナ |
| `$--radius-m` | カード・モーダル |
| `$--radius-pill` | ボタン・インプット・バッジ |

---

## 4. タイポグラフィ

| CSS | Pencil プロパティ | 備考 |
|-----|-----------------|------|
| `font-size: Npx` | `fontSize: N` | |
| `font-weight: N` | `fontWeight: "N"` | **文字列で指定** |
| `font-family: "..."` | `fontFamily: "..."` or `fontFamily: "$--font-primary"` | |
| `line-height: Npx` | `lineHeight: N/fontSize` | **px→比率に変換必須**。例: fontSize=72, lineHeight=79.2px → `lineHeight: 1.1`（79.2/72）。比率 > 3 は変換漏れの可能性大 |
| `letter-spacing: Npx` | `letterSpacing: N` | |
| `text-align: left` | `textAlign: "left"` | |
| `text-align: center` | `textAlign: "center"` | |
| `text-align: right` | `textAlign: "right"` | |
| `text-transform: uppercase` | `textTransform: "uppercase"` | |
| `text-decoration: underline` | `textDecoration: "underline"` | |
| `white-space: nowrap` | `textWrap: false` | |
| `overflow: hidden; text-overflow: ellipsis` | `textTruncate: true` | |

---

## 5. ボーダー・角丸

| CSS | Pencil プロパティ | 備考 |
|-----|-----------------|------|
| `border-radius: Npx` | `cornerRadius: N` | 4辺均一 |
| `border-radius: N1 N2 N3 N4 px` | `cornerRadius: [N1, N2, N3, N4]` | TL, TR, BR, BL |
| `border-radius: 9999px` (pill) | `cornerRadius: "$--radius-pill"` | |
| `border: 1px solid #hex` | `stroke: {align: "inside", fill: "#hex", thickness: 1}` | |
| `border-bottom: 1px solid #hex` | `stroke: {align: "inside", fill: "#hex", thickness: {bottom: 1}}` | |
| `border-top: 1px solid #hex` | `stroke: {align: "inside", fill: "#hex", thickness: {top: 1}}` | |
| `border-left: 1px solid` | `stroke: {align: "inside", fill: "#hex", thickness: {left: 1}}` | |
| `border: none` | stroke プロパティ省略 | |

---

## 6. シャドウ

| CSS | Pencil プロパティ | 備考 |
|-----|-----------------|------|
| `box-shadow: 0 1px 3px rgba(0,0,0,0.1)` | `shadow: {x: 0, y: 1, blur: 3, color: "rgba(0,0,0,0.1)"}` | |
| `box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1)` | `shadow: {x: 0, y: 4, blur: 6, spread: -1, color: "rgba(0,0,0,0.1)"}` | |
| `box-shadow: inset ...` | `shadow: {inset: true, ...}` | |
| `box-shadow: none` | shadow プロパティ省略 | |

---

## 7. ポジショニング

| CSS | Pencil プロパティ | 備考 |
|-----|-----------------|------|
| `position: relative` | layout 内で自動配置 | |
| `position: absolute` | `x: N, y: N` + 親フレームに layout なし | |
| `position: fixed` | Pencil 非対応 → 構造で再現 | |
| `position: sticky` | Pencil 非対応 → 構造で再現 | |
| `overflow: hidden` | `clip: true` | |
| `overflow: visible` | `clip: false`（デフォルト） | |
| `overflow: scroll/auto` | `clip: true` + スクロールは表現不可 | |

---

## 8. 表示・非表示

| CSS | Pencil プロパティ | 備考 |
|-----|-----------------|------|
| `display: none` | `enabled: false` | |
| `visibility: hidden` | `opacity: 0` で代替 | |

---

## 9. 変形

| CSS | Pencil プロパティ | 備考 |
|-----|-----------------|------|
| `transform: rotate(Ndeg)` | `rotation: N` | |
| `transform: scale(N)` | Pencil 非対応 → サイズで代替 | |

---

## 10. Pencil 固有の特殊プロパティ

| プロパティ | 用途 |
|-----------|------|
| `placeholder: true` | 子コンテンツを受け入れるコンテナフレームのマーク |
| `slot: [...]` | コンポーネント内のスロット定義 |
| `reusable: true` | 再利用可能コンポーネント（デザインシステム） |
| `clip: true` | はみ出し非表示 |
| `enabled: false` | 要素を非表示 |
| `type: "ref", ref: "componentId"` | コンポーネントインスタンス挿入 |
| `descendants: {nodeId: {...}}` | ref インスタンスの子孫プロパティオーバーライド |
| `type: "icon_font"` | アイコン要素 |
| `iconFontFamily: "lucide"` | アイコンフォントファミリー |
| `iconFontName: "home"` | アイコン名 |

---

## 11. 数値変換ガイド

| Chrome CSS 値 | Pencil 変換 | 変換方法 |
|-------------|-----------|---------|
| `"24px"` | `24` | `parseInt()` |
| `"rgb(17, 24, 39)"` | `"#111827"` | rgbToHex() |
| `"rgba(0, 0, 0, 0.1)"` | `"rgba(0,0,0,0.1)"` | そのまま文字列 |
| `"bold"` / `"700"` | `"700"` | fontWeight は文字列 |
| `"normal"` / `"400"` | `"400"` | fontWeight は文字列 |
| `"flex"` + `"column"` | `layout: "vertical"` | 組み合わせ判定 |
| `"100%"` or `"flex: 1"` | `"fill_container"` | レイアウト内の 100% |
| `line-height: "79.2px"` (fontSize=72) | `lineHeight: 1.1` | **px値 / fontSize で比率に変換**。Pencil は lineHeight を倍率として解釈するため、px値をそのまま渡すとレイアウトが数十倍に膨らむ |

---

## 12. Pencil 既知の制限事項と回避策

実際の構築で判明した制限。design-builder は必ずこのリストを確認すること。

### layout プロパティは Insert 時に必ず指定する

```
# DO: Insert 時に layout を指定
row=I(parent, {type: "frame", layout: "horizontal", gap: 16})

# DON'T: 後から Update で layout を追加（反映されない場合がある）
row=I(parent, {type: "frame", gap: 16})
U(row, {layout: "horizontal"})  // ← 動作が不安定
```

**対策**: `layout` は必ず I() の nodeData に含める。

### flexWrap は信頼しない

Pencil の `flexWrap: "wrap"` は動作が不安定。カードグリッド等を作る場合は明示的に Row を分割する。

```
# DO: 明示的に Row を分ける
grid=I(parent, {type: "frame", layout: "vertical", gap: 16, name: "Card Grid"})
row1=I(grid, {type: "frame", layout: "horizontal", gap: 16, name: "Row 1"})
row2=I(grid, {type: "frame", layout: "horizontal", gap: 16, name: "Row 2"})
card1=I(row1, {type: "frame", ...})
card2=I(row1, {type: "frame", ...})
card3=I(row1, {type: "frame", ...})
card4=I(row2, {type: "frame", ...})

# DON'T: flexWrap に頼る
grid=I(parent, {type: "frame", layout: "horizontal", gap: 16, flexWrap: "wrap"})
// ← カードが折り返さない
```

### linear-gradient() は CSS 構文をそのまま使えない

上記「3. 色・背景 > グラデーション変換」セクションを参照。
`fill: "linear-gradient(135deg, #0ea5e9, #2563eb)"` → カードが透明になる。

### batch_get の結果が巨大になる場合がある

`patterns` 検索や `readDepth: 3` 以上で結果がファイルに保存される場合がある。
jq や python で必要なノードだけ抽出すること。

### snapshot_layout の depth 制限

`snapshot_layout` は深い階層まで到達しない場合がある。
代わりに `batch_get` + `nodeIds` で個別ノードのプロパティを確認する。
