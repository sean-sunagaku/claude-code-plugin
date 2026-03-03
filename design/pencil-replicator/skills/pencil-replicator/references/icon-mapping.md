# lucide-react → Pencil icon_font 変換マッピング

screen-analyzer, design-builder が共通で参照するアイコン名変換ルール。

---

## 変換ルール

### 基本変換: PascalCase → kebab-case

lucide-react はコンポーネント名が PascalCase、Pencil の `iconFontName` は kebab-case。

```
MessageSquare → message-square
LayoutGrid   → layout-grid
ChevronDown  → chevron-down
ArrowRight   → arrow-right
FileText     → file-text
BarChart3    → bar-chart-3
```

### 変換手順

1. PascalCase を分割: `MessageSquare` → `["Message", "Square"]`
2. 各パーツを小文字化: `["message", "square"]`
3. ハイフンで連結: `message-square`
4. 末尾の数字はそのまま: `BarChart3` → `bar-chart-3`

---

## 既知の非互換アイコン名

以下のアイコンは単純な PascalCase → kebab-case 変換では正しい名前にならない。

| lucide-react (Chrome) | 単純変換結果 | Pencil icon_font (正しい名前) | 備考 |
|---|---|---|---|
| `Layout` | `layout` | `layout-grid` | `layout` は lucide に存在しない |

---

## 注意事項

- このリストは実際の構築で発見された非互換のみを記録している
- 新しい非互換が見つかった場合はこのファイルに追記する
- screen-analyzer は chrome-analysis.md に書き出す前にこのリストを確認する
- design-builder はアイコンが表示されない場合にこのリストを確認する

---

## screen-analyzer への指示

Chrome の DOM/a11y ツリーでアイコンを検出した場合:

1. SVG の class 名やコンポーネント名から lucide-react の名前を特定
2. PascalCase → kebab-case に変換
3. 上記の「既知の非互換アイコン名」テーブルと照合
4. chrome-analysis.md には **Pencil 形式（kebab-case）** で記載:
   ```markdown
   - アイコン: iconFontFamily="lucide", iconFontName="layout-grid"
     (Chrome 原値: LayoutGrid コンポーネント)
   ```
