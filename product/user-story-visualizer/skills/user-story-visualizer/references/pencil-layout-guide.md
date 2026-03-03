# Pencil ジャーニーマップ構築ガイド

journey-visualizer エージェントが Pencil (.pen) でジャーニーマップを構築する際のリファレンス。

## レイアウト仕様

### フレームサイズ

| 対象 | 推奨サイズ |
|------|----------|
| メインフレーム（1タイプ） | 1600 × 1000 pt |
| メインフレーム（追加タイプ） | 高さ +900 pt / タイプ |
| フェーズヘッダー行 | 幅 fill_container × 高さ 60 pt |
| データ行（通常） | 幅 fill_container × 高さ 100 pt |
| データ行（テキスト多め） | 幅 fill_container × 高さ 140 pt |
| 行ラベル列（左端） | 幅 160 pt × 高さ（行高さに合わせる）|
| フェーズセル（1列） | 幅 288 pt（(1600-160)/5）|
| タイプ区切りラベル | 幅 fill_container × 高さ 48 pt |

### フォントサイズ

| 使用箇所 | サイズ | ウェイト |
|---------|--------|---------|
| フェーズヘッダー | 20 pt | Bold (700) |
| 行ラベル | 14 pt | SemiBold (600) |
| カード本文 | 12 pt | Regular (400) |
| 注釈・バッジ | 10 pt | Regular / Bold |

### 間隔

| 項目 | 値 |
|------|-----|
| 行間 gap | 2 pt |
| セル間 gap | 2 pt |
| セル内 padding | 12 pt |
| カード角丸 cornerRadius | 8 pt |
| タイトルエリアの下マージン | 16 pt |

---

## 色コードリファレンス

### フェーズカラー（背景 / アクセント）

| フェーズ | 背景色 | アクセント色 |
|---------|--------|------------|
| 認知 (Awareness) | `#EFF6FF` | `#3B82F6` |
| 検討 (Consideration) | `#F5F3FF` | `#8B5CF6` |
| 初回利用 (First Use) | `#FEFCE8` | `#EAB308` |
| 習慣化 (Habit) | `#F0FDF4` | `#22C55E` |
| 推薦/離脱 (Advocacy) | `#FFF7ED` | `#F97316` |

- ヘッダー行: アクセント色を背景に使用（白文字）
- データ行: 背景色をセルに使用

### 行ラベル色

| 使用箇所 | 色名 | Hex コード |
|---------|------|-----------|
| 行ラベル背景（暗） | Dark Gray | `#374151` |
| 行ラベル文字 | White | `#FFFFFF` |
| タイプ区切りラベル背景 | Slate | `#1F2937` |
| タイプ区切り見出し文字 | Light Gray | `#9CA3AF` |
| タイプ区切り名前文字 | White | `#FFFFFF` |

### 行（レイヤー）背景色

| 行 | 色名 | Hex コード |
|----|------|-----------|
| 行動 | White-ish | `#F9FAFB` |
| 思考 | Light Blue | `#EFF6FF` |
| 感情 | （感情スコアで動的変化） | 下記参照 |
| 接点 | Light Green | `#F0FDF4` |
| 利用機能 | Light Yellow | `#FEFCE8` |
| 課題 | Light Red | `#FFF1F2` |
| 機会 | Light Green | `#F0FDF4` |
| Devアクション | Light Purple | `#F5F3FF` |

### 感情スコア対応色（-2〜+2 スケール）

感情ワードをスコア（-2〜+2）に変換し、対応する色を使用する。

| スコア | 感情例 | 背景色 | 文字色 |
|--------|--------|--------|-------|
| +2（非常にポジティブ） | 喜び、感動、満足 | `#16A34A` | `#FFFFFF` |
| +1（ポジティブ） | 期待、嬉しい、安心 | `#86EFAC` | `#166534` |
| 0（中立） | 普通、平静、様子見 | `#9CA3AF` | `#1F2937` |
| -1（ネガティブ） | 不安、戸惑い、不満 | `#FCA5A5` | `#991B1B` |
| -2（非常にネガティブ） | ストレス、怒り、離脱 | `#DC2626` | `#FFFFFF` |

**感情スコア変換ルール**:
- ポジティブ系（安心、驚き→好感、期待、喜び、感動）→ +1〜+2
- ニュートラル系（普通、慎重、様子見）→ 0
- ネガティブ系（不安、戸惑い、不満、ストレス）→ -1〜-2
- 変化する感情（不安→期待）→ 変化後のスコアで色を決定
- **Peak-End Rule（Kahneman）**: 推薦フェーズ（最後）は必ず +1 以上

### 特殊ハイライト色

| 種別 | 背景色 | ボーダー色 | テキスト色 | ボーダー幅 | 説明 |
|------|--------|-----------|----------|-----------|------|
| ペインポイント | `#FEE2E2` | `#EF4444` | `#991B1B` | 2 pt | 課題セルで特に重大なもの |
| 機会 (Opportunity) | `#DCFCE7` | `#22C55E` | `#166534` | 2 pt | 機会セルで特に高インパクトなもの |
| 離脱トリガー | `#FEE2E2` | `#DC2626` | `#7F1D1D` | 2 pt | 離脱リスクが最も高いセル |
| Aha Moment | `#FEF9C3` | `#CA8A04` | `#713F12` | 2 pt | 価値実感ポイント |
| タッチポイント | `#E0E7FF` | `#6366F1` | `#312E81` | 2 pt | 重要な接点セル |

---

## batch_design 操作パターン集

### パターン 1: フェーズヘッダー行

```javascript
// ヘッダー行コンテナ
headerRow=I("matrixArea", {type: "frame", layout: "horizontal", width: "fill_container", height: 60, gap: 2})

// 行ラベルヘッダー（左端）- 幅160pt
rowLabel=I(headerRow, {type: "frame", width: 160, height: 60, fill: "#111827", justifyContent: "center", alignItems: "center"})
rowLabelText=I(rowLabel, {type: "text", content: "Phase / Layer", fontSize: 11, fontWeight: "700", fill: "#FFFFFF"})

// 認知フェーズヘッダー（アクセント色 #3B82F6）
ph1=I(headerRow, {type: "frame", layout: "vertical", width: 288, height: 60, fill: "#3B82F6", cornerRadius: 8, justifyContent: "center", alignItems: "center", gap: 2})
ph1t=I(ph1, {type: "text", content: "認知", fontSize: 20, fontWeight: "700", fill: "#FFFFFF"})
ph1s=I(ph1, {type: "text", content: "Awareness", fontSize: 10, fill: "#BFDBFE"})

// 検討フェーズヘッダー（アクセント色 #8B5CF6）
ph2=I(headerRow, {type: "frame", layout: "vertical", width: 288, height: 60, fill: "#8B5CF6", cornerRadius: 8, justifyContent: "center", alignItems: "center", gap: 2})
ph2t=I(ph2, {type: "text", content: "検討", fontSize: 20, fontWeight: "700", fill: "#FFFFFF"})
ph2s=I(ph2, {type: "text", content: "Consideration", fontSize: 10, fill: "#DDD6FE"})

// 初回利用（アクセント #EAB308）/ 習慣化（#22C55E）/ 推薦（#F97316）も同様のパターン
```

### パターン 2: 通常データ行

```javascript
// 行コンテナ
actionRow=I("matrixArea", {type: "frame", layout: "horizontal", width: "fill_container", height: 100, gap: 2})

// 行ラベル（幅160pt）
actionLabel=I(actionRow, {type: "frame", layout: "vertical", width: 160, height: 100, fill: "#374151", justifyContent: "center", alignItems: "center", padding: 12})
actionLabelJa=I(actionLabel, {type: "text", content: "行動", fontSize: 14, fontWeight: "600", fill: "#FFFFFF"})
actionLabelEn=I(actionLabel, {type: "text", content: "Action", fontSize: 10, fill: "#9CA3AF"})

// データセル（幅288pt固定）
cell1=I(actionRow, {type: "frame", layout: "vertical", width: 288, height: 100, fill: "#F9FAFB", cornerRadius: 8, padding: 12, gap: 4})
cell1Text=I(cell1, {type: "text", content: "{行動テキスト}", fontSize: 12, fill: "#374151"})
```

### パターン 3: 感情行（-2〜+2 スコアで色分け）

```javascript
emotionRow=I("matrixArea", {type: "frame", layout: "horizontal", width: "fill_container", height: 100, gap: 2})
emotionLabel=I(emotionRow, {type: "frame", layout: "vertical", width: 160, height: 100, fill: "#374151", justifyContent: "center", alignItems: "center", padding: 12})
emotionLabelJa=I(emotionLabel, {type: "text", content: "感情", fontSize: 14, fontWeight: "600", fill: "#FFFFFF"})
emotionLabelEn=I(emotionLabel, {type: "text", content: "Emotion", fontSize: 10, fill: "#9CA3AF"})

// スコア -1（ネガティブ）: #FCA5A5 背景, #991B1B 文字
eCell1=I(emotionRow, {type: "frame", layout: "vertical", width: 288, height: 100, fill: "#FCA5A5", cornerRadius: 8, padding: 12, justifyContent: "center", alignItems: "center"})
eCell1Text=I(eCell1, {type: "text", content: "不安", fontSize: 12, fontWeight: "600", fill: "#991B1B"})

// スコア +1（ポジティブ）: #86EFAC 背景, #166534 文字
eCell3=I(emotionRow, {type: "frame", layout: "vertical", width: 288, height: 100, fill: "#86EFAC", cornerRadius: 8, padding: 12, justifyContent: "center", alignItems: "center"})
eCell3Text=I(eCell3, {type: "text", content: "期待", fontSize: 12, fontWeight: "600", fill: "#166534"})
```

### パターン 4: 離脱トリガーハイライト

```javascript
// 離脱リスクセル: 背景 #FEE2E2, ボーダー #DC2626, テキスト #7F1D1D
dropoffCell=I(challengeRow, {type: "frame", layout: "vertical", width: 288, height: 100, fill: "#FEE2E2", cornerRadius: 8, padding: 12, gap: 4, borderWidth: 2, borderColor: "#DC2626"})
dropoffIcon=I(dropoffCell, {type: "text", content: "⚠ DROP-OFF RISK", fontSize: 9, fontWeight: "700", fill: "#DC2626"})
dropoffText=I(dropoffCell, {type: "text", content: "{離脱リスクの内容}", fontSize: 12, fill: "#7F1D1D"})
```

### パターン 5: Aha Moment ハイライト

```javascript
// Aha Moment セル: 背景 #FEF9C3, ボーダー #CA8A04, テキスト #713F12
ahaCell=I(actionRow, {type: "frame", layout: "vertical", width: 288, height: 100, fill: "#FEF9C3", cornerRadius: 8, padding: 12, gap: 4, borderWidth: 2, borderColor: "#CA8A04"})
ahaBadge=I(ahaCell, {type: "text", content: "★ AHA MOMENT", fontSize: 9, fontWeight: "700", fill: "#CA8A04"})
ahaText=I(ahaCell, {type: "text", content: "{Aha Momentの内容}", fontSize: 12, fill: "#713F12"})
```

### パターン 6: ユーザータイプ区切りバナー

```javascript
// タイプ区切りバナー（複数タイプの場合）
typeBanner=I("mainFrame", {type: "frame", layout: "horizontal", width: "fill_container", height: 48, fill: "#1F2937", padding: [0, 16, 0, 16], alignItems: "center", gap: 12})
typeIndex=I(typeBanner, {type: "text", content: "USER TYPE 2", fontSize: 10, fontWeight: "700", fill: "#9CA3AF"})
typeName=I(typeBanner, {type: "text", content: "{ユーザータイプ名}", fontSize: 16, fontWeight: "700", fill: "#FFFFFF"})
typeKeyword=I(typeBanner, {type: "text", content: '"{キーワード}"', fontSize: 12, fill: "#D1D5DB"})
```

---

## Pencil テクニカルルール（journey-visualizer 専用チェックリスト）

### 必須ルール
- [ ] テキストの色は `fill` プロパティ（`textColor` は無効）
- [ ] `justifyContent` は `space_between`（アンダースコア。ハイフン `-` ではない）
- [ ] `alignItems` は `center`
- [ ] `lineHeight` は日本語テキストに **使用禁止**（縦長になる）
- [ ] `\n` 改行も禁止 → 複数の短いテキストノードに分割
- [ ] Insert は必ずバインディング名が必要: `foo=I("parent", {...})`
- [ ] 1回の `batch_design` は最大25操作
- [ ] `filePath` パラメータは毎回必ず指定する

### よくあるミスと対処
| ミス | 正しい書き方 |
|------|------------|
| `justifyContent: "space-between"` | `justifyContent: "space_between"` |
| `textColor: "#111827"` | `fill: "#111827"` |
| `content: "行1\n行2"` | 2つのテキストノードに分割 |
| バインディング名なし: `I("parent", {...})` | `foo=I("parent", {...})` |
| `width: 200` on text node | テキストノードに width 指定しない |

---

## スクリーンショット確認チェックリスト

`mcp__pencil__get_screenshot` で以下を確認する:

1. [ ] フェーズヘッダーの5色が正しく表示されているか
2. [ ] 行ラベルのテキストが読みやすいか（サイズ、コントラスト）
3. [ ] 感情行の色グラデーションが感情の変化を表現しているか
4. [ ] ペインポイント・離脱トリガーのハイライトが目立つか
5. [ ] Aha Moment セルが識別しやすいか
6. [ ] セル内テキストが小さすぎないか（11pt以上を推奨）
7. [ ] 複数ユーザータイプの区切りが明確か
8. [ ] 全体のレイアウトが整列されているか
