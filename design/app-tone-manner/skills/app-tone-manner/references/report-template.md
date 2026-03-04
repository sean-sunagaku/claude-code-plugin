# TONE_MANNER_REPORT.md テンプレート

以下のテンプレートに従って最終レポートを作成する。
`{...}` 部分を実際の値で置き換えること。

---

```markdown
# {アプリ名} - Tone & Manner Report

作成日: {YYYY-MM-DD}
バージョン: 1.0

---

## 1. Executive Summary

**ブランドの一言定義**: {1文でブランドを表現}

**デザインテンション**: "{矛盾ペア}" — {なぜこの矛盾ペアがこのブランドに適切かの説明}

**主要キーワード**: {形容詞3-5個}

---

## 2. ブランドパーソナリティ

### アーキタイプ

| 種別 | アーキタイプ | 理由 |
|------|------------|------|
| 主要 | {archetype} | {選定理由} |
| 副次 | {archetype} | {選定理由} |

### Aaker パーソナリティスコア

| 次元 | スコア (1-10) | 根拠 |
|------|-------------|------|
| Sincerity (誠実性) | {score} | {根拠} |
| Excitement (刺激性) | {score} | {根拠} |
| Competence (能力) | {score} | {根拠} |
| Sophistication (洗練性) | {score} | {根拠} |
| Ruggedness (頑健性) | {score} | {根拠} |

### デザイン原則

{3-5個の原則。形式: "形容詞: 実践での意味"}

1. **{形容詞}**: {実践での意味}
2. **{形容詞}**: {実践での意味}
3. **{形容詞}**: {実践での意味}

---

## 3. デザインテンション

**テンション**: "{矛盾ペア}"

### 全デザイン判断への影響

| 判断領域 | テンションの影響 |
|---------|---------------|
| カラー | {テンションがカラー選定にどう影響するか} |
| タイポグラフィ | {テンションがフォント選定にどう影響するか} |
| ビジュアルスタイル | {テンションがUI要素にどう影響するか} |
| トーン・オブ・ボイス | {テンションがコピーにどう影響するか} |

---

## 4. カラーパレット

### メインパレット

| 用途 | 色名 | Hex | 使用場面 |
|------|------|-----|---------|
| Primary | {名前} | {#hex} | {用途} |
| Secondary | {名前} | {#hex} | {用途} |
| Accent | {名前} | {#hex} | {用途} |

### ニュートラルパレット

| 用途 | Hex | 使用場面 |
|------|-----|---------|
| Background | {#hex} | {用途} |
| Surface | {#hex} | {用途} |
| Border | {#hex} | {用途} |
| Text Primary | {#hex} | {用途} |
| Text Secondary | {#hex} | {用途} |
| Text Muted | {#hex} | {用途} |

### セマンティックカラー

| 意味 | Hex | 使用場面 |
|------|-----|---------|
| Success | {#hex} | {用途} |
| Warning | {#hex} | {用途} |
| Error | {#hex} | {用途} |
| Info | {#hex} | {用途} |

### ダークモード

| 用途 | Light Mode | Dark Mode | 注意点 |
|------|-----------|-----------|-------|
| Background | {#hex} | {#hex} | {注意点} |
| Surface | {#hex} | {#hex} | |
| Primary | {#hex} | {#hex} | {彩度調整等} |
| Text Primary | {#hex} | {#hex} | |

### カラー設計の根拠

- **調和タイプ**: {harmony_type} — {理由}
- **暖かさ**: {warmth}/10 — {理由}
- **彩度**: {saturation_level} — {理由}
- **ニュートラルトーン**: {neutral_tone} — {理由}
- **WCAG 適合**: {level} — テキストコントラスト比 {ratio}:1 以上

---

## 5. タイポグラフィ

### フォント選定

| 用途 | フォント名 | 分類 | 選定理由 |
|------|-----------|------|---------|
| Display (見出し) | {font_display} | {category} | {理由} |
| Body (本文) | {font_body} | {category} | {理由} |
| 日本語 | {font_jp} | {category} | {理由} |

### ペアリング理由

{なぜこの組み合わせがデザインテンションを体現するか}

### タイポグラフィスケール

- **ベースサイズ**: {type_base_size}px
- **スケール比**: {type_scale_ratio}

| レベル | サイズ (px) | 用途 |
|--------|-----------|------|
| Caption | {size} | 補助テキスト |
| Body Small | {size} | 小さい本文 |
| Body | {size} | 本文 |
| Subtitle | {size} | サブタイトル |
| Title | {size} | タイトル |
| Heading | {size} | 見出し |
| Display | {size} | ヒーローテキスト |

### ウェイトシステム

| 用途 | ウェイト | 適用場面 |
|------|---------|---------|
| Light | 300 | {場面} |
| Regular | 400 | {場面} |
| Medium | 500 | {場面} |
| Semibold | 600 | {場面} |
| Bold | 700 | {場面} |

---

## 6. ビジュアルスタイル

### 全体UIスタイル

**スタイル**: {visual_style} — {選定理由}

### 形状 (Shape)

- **角丸スタイル**: {corner_radius_style} — {理由}
- **ボタン角丸**: {value}px
- **カード角丸**: {value}px
- **インプット角丸**: {value}px

### 影 / エレベーション

- **影スタイル**: {shadow_style} — {理由}
- **エレベーション段階**: {elevation_levels}段階

| レベル | CSS Shadow | 用途 |
|--------|-----------|------|
| Level 0 | none | コンテンツ面 |
| Level 1 | {value} | カード |
| Level 2 | {value} | ドロップダウン |
| Level 3 | {value} | モーダル |

### スペーシング

- **基本単位**: {spacing_base_unit}
- **密度**: {spacing_density}

| トークン名 | 値 | 用途 |
|-----------|---|------|
| xs | {value} | {用途} |
| sm | {value} | {用途} |
| md | {value} | {用途} |
| lg | {value} | {用途} |
| xl | {value} | {用途} |
| 2xl | {value} | {用途} |

### アイコン

- **スタイル**: {icon_style}
- **ストローク幅**: {icon_stroke_width}px
- **推奨アイコンセット**: {推奨セット名}

### モーション / アニメーション

- **スタイル**: {animation_style} — {理由}
- **ベース時間**: {animation_duration_base}ms

| アクション | 時間 | イージング | 用途 |
|-----------|------|---------|------|
| ホバー | {time} | {easing} | ボタン、カード |
| 表示 | {time} | {easing} | モーダル、ドロワー |
| フィードバック | {time} | {easing} | 成功/エラー通知 |

### イラスト / 画像

- **イラストスタイル**: {illustration_style} — {理由}
- **写真スタイル**: {photography_style} — {理由}
- **情報密度**: {information_density}

---

## 7. トーン・オブ・ボイス

### ボイスマトリクス

| 次元 | スコア | 説明 |
|------|-------|------|
| Formality | {score}/10 | {説明} |
| Humor | {score}/10 | {説明} |
| Enthusiasm | {score}/10 | {説明} |
| Respect | {value} | {説明} |
| Complexity | {value} | {説明} |

### UIコピーの具体例

#### ボタンラベル

| 場面 | OK | NG |
|------|----|----|
| 新規登録 | {例} | {例} |
| 購入/申込 | {例} | {例} |
| キャンセル | {例} | {例} |

#### エラーメッセージ

| 場面 | OK | NG |
|------|----|----|
| 入力エラー | {例} | {例} |
| ネットワークエラー | {例} | {例} |
| 認証エラー | {例} | {例} |

#### 成功メッセージ

| 場面 | OK | NG |
|------|----|----|
| 保存完了 | {例} | {例} |
| 登録完了 | {例} | {例} |

#### オンボーディング

| ステップ | コピー例 |
|---------|---------|
| ウェルカム | {例} |
| 機能紹介 | {例} |
| 完了 | {例} |

### コミュニケーションスタイルガイド

**やること (Do)**:
- {具体的なルール}
- {具体的なルール}
- {具体的なルール}

**やらないこと (Don't)**:
- {具体的なルール}
- {具体的なルール}
- {具体的なルール}

---

## 8. デザイン変数一覧（42変数）

| # | 変数名 | 値 | 担当 |
|---|--------|---|------|
| 1 | brand_archetype | {value} | brand-strategist |
| 2 | brand_archetype_secondary | {value} | brand-strategist |
| 3 | personality_sincerity | {value} | brand-strategist |
| 4 | personality_excitement | {value} | brand-strategist |
| 5 | personality_competence | {value} | brand-strategist |
| 6 | personality_sophistication | {value} | brand-strategist |
| 7 | personality_ruggedness | {value} | brand-strategist |
| 8 | color_primary | {value} | color-expert |
| 9 | color_secondary | {value} | color-expert |
| 10 | color_accent | {value} | color-expert |
| 11 | color_harmony_type | {value} | color-expert |
| 12 | color_warmth | {value} | color-expert |
| 13 | color_saturation_level | {value} | color-expert |
| 14 | neutral_tone | {value} | color-expert |
| 15 | dark_mode_strategy | {value} | color-expert |
| 16 | font_display | {value} | typography-director |
| 17 | font_body | {value} | typography-director |
| 18 | font_display_category | {value} | typography-director |
| 19 | font_body_category | {value} | typography-director |
| 20 | font_jp_category | {value} | typography-director |
| 21 | type_scale_ratio | {value} | typography-director |
| 22 | type_base_size | {value} | typography-director |
| 23 | spacing_base_unit | {value} | visual-style-architect |
| 24 | spacing_density | {value} | visual-style-architect |
| 25 | corner_radius_style | {value} | visual-style-architect |
| 26 | shadow_style | {value} | visual-style-architect |
| 27 | elevation_levels | {value} | visual-style-architect |
| 28 | icon_style | {value} | visual-style-architect |
| 29 | icon_stroke_width | {value} | visual-style-architect |
| 30 | animation_style | {value} | visual-style-architect |
| 31 | animation_duration_base | {value} | visual-style-architect |
| 32 | illustration_style | {value} | visual-style-architect |
| 33 | visual_style | {value} | visual-style-architect |
| 34 | information_density | {value} | visual-style-architect |
| 35 | formality_level | {value} | user-psychologist |
| 36 | voice_humor | {value} | tone-of-voice-writer |
| 37 | voice_enthusiasm | {value} | tone-of-voice-writer |
| 38 | target_age_primary | {value} | user-psychologist |
| 39 | cultural_context | {value} | user-psychologist |
| 40 | accessibility_level | {value} | user-psychologist |
| 41 | design_tension | {value} | brand-strategist |
| 42 | photography_style | {value} | visual-style-architect |

---

## 9. 競合差別化の根拠

### 競合比較マトリクス

| 要素 | {自社} | {競合A} | {競合B} | {競合C} |
|------|--------|---------|---------|---------|
| Primary Color | {hex} | {hex} | {hex} | {hex} |
| Font Style | {font} | {font} | {font} | {font} |
| 全体印象 | {impression} | {impression} | {impression} | {impression} |
| 差別化ポイント | - | {point} | {point} | {point} |

### 差別化の根拠

{なぜこのトンマナが競合と明確に異なるかの説明}

---

## 10. Devil's Advocate 結果

### Fatal 指摘（全て解消済み）

| 指摘 | 対策 |
|------|------|
| {指摘内容} | {対策} |

### Major 指摘

| 指摘 | 対策 |
|------|------|
| {指摘内容} | {対策} |

### Minor 指摘（記録）

| 指摘 | 備考 |
|------|------|
| {指摘内容} | {備考} |

---

## 11. ペルソナとの整合性

{各ペルソナに対するデザインの適合度}

| ペルソナ | 適合度 | 根拠 | 注意点 |
|---------|--------|------|-------|
| {ペルソナ名} | {高/中/低} | {根拠} | {注意点} |

---

## 12. 後続スキルへの引き継ぎ

### logo-design への申し送り

- ブランドカラー: {hex values}
- パーソナリティキーワード: {keywords}
- デザインテンション: {tension}
- 推奨ロゴスタイル: {recommendation}

### ui-review への申し送り

- トンマナガイドライン: このレポート全体
- 重点チェック項目: {items}
- アンチパターンリスト: {reference}

### feature-discussion への申し送り

- UI コンポーネントのスタイル基準: §6
- コピーのスタイル基準: §7
- デザイントークン: §8

### aso-optimize への申し送り

- ストア説明文のトーン: §7 参照
- ブランドキーワード: {keywords}
```
