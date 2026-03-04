# デザイン変数一覧（42変数）

トーン&マナー設計で決定すべき全42変数の完全定義。
各変数は担当エージェントによって値が設定され、TONE_MANNER_REPORT.md に最終値が記載される。

---

## ブランドパーソナリティ変数（1-7）

担当: brand-strategist

| # | 変数名 | 説明 | 型 | 範囲/選択肢 |
|---|--------|------|----|------------|
| 1 | `brand_archetype` | 主要ユングアーキタイプ | enum | Innocent, Everyman, Hero, Outlaw, Explorer, Creator, Ruler, Magician, Lover, Caregiver, Jester, Sage |
| 2 | `brand_archetype_secondary` | 副次アーキタイプ（ブレンド用） | enum | 同上 |
| 3 | `personality_sincerity` | Aaker 誠実性スコア | scale | 1-10 |
| 4 | `personality_excitement` | Aaker 刺激性スコア | scale | 1-10 |
| 5 | `personality_competence` | Aaker 能力スコア | scale | 1-10 |
| 6 | `personality_sophistication` | Aaker 洗練性スコア | scale | 1-10 |
| 7 | `personality_ruggedness` | Aaker 頑健性スコア | scale | 1-10 |

### アーキタイプとビジュアルの対応表

| アーキタイプ | 核心欲求 | ビジュアルスタイル | カラーファミリー | タイポグラフィ |
|------------|---------|-----------------|---------------|------------|
| Innocent | 安全 | 明るく、シンプル | パステル、白、空色 | 丸みのあるサンセリフ |
| Everyman | 所属 | 温かく、親しみやすい | アーストーン、暖色ニュートラル | ヒューマニストサンセリフ |
| Hero | 達成 | 力強く、ダイナミック | 赤、紺、黒 | 太いサンセリフ、コンデンスド |
| Outlaw | 解放 | エッジの効いた、型破り | 黒、赤、ダーク | ディスプレイ、ディストレスト |
| Explorer | 自由 | 開放的、自然的 | 緑、アース、オーシャン | ジオメトリックサンセリフ |
| Creator | 革新 | 創造的、表現的 | 多彩/ビビッド | ディスプレイ、アーティスティック |
| Ruler | 支配 | 構造的、格式高い | 黒、紫、ゴールド | セリフ、細身、エレガント |
| Magician | 変容 | 神秘的、変容的 | 紫、深い青、ゴールド | スタイライズドセリフ |
| Lover | 親密 | 感覚的、温かい | 赤、ピンク、バーガンディ | スクリプト、エレガントセリフ |
| Caregiver | 奉仕 | 優しく、穏やか | 青、緑、ソフトトーン | 丸みサンセリフ、ヒューマニスト |
| Jester | 楽しみ | 楽しく、カラフル | 明るい多色 | 丸い、バウンシーなディスプレイ |
| Sage | 理解 | クリーン、知的 | 青、グレー、白 | クラシックセリフ、クリーンサンセリフ |

---

## カラー変数（8-15）

担当: color-expert

| # | 変数名 | 説明 | 型 | 範囲/選択肢 |
|---|--------|------|----|------------|
| 8 | `color_primary` | メインブランドカラー | hex | 任意の有効な hex 値 |
| 9 | `color_secondary` | サポートカラー | hex | 任意の有効な hex 値 |
| 10 | `color_accent` | ハイライト/CTAカラー | hex | 任意の有効な hex 値 |
| 11 | `color_harmony_type` | 色彩調和戦略 | enum | complementary, analogous, triadic, split-complementary, monochromatic |
| 12 | `color_warmth` | パレット全体の暖かさ | scale | 1 (非常にクール) - 10 (非常にウォーム) |
| 13 | `color_saturation_level` | パレットの彩度 | enum | muted, medium, vivid |
| 14 | `neutral_tone` | ベースニュートラルの温度感 | enum | cool-gray, true-gray, warm-gray, beige |
| 15 | `dark_mode_strategy` | ダークモードアプローチ | enum | inverted, redesigned, auto-adaptive |

### カラー比率: 60-30-10 ルール

- **60% ドミナント**: 通常ニュートラル/背景色
- **30% セカンダリ**: カード、ナビゲーション、サポート面
- **10% アクセント**: CTA、ハイライト、キーインタラクション

### カラーハーモニー早見表

| ハーモニー | 説明 | ムード |
|-----------|------|------|
| Complementary | 色相環の反対色 | ハイコントラスト、エネルギッシュ |
| Analogous | 色相環の隣接3色 | 調和的、落ち着いた |
| Triadic | 120度間隔の3色 | バランスの取れた活気 |
| Split-Complementary | 基本色 + 補色の両隣 | コントラストありつつ柔和 |
| Monochromatic | 単色の彩度/明度変化 | エレガント、統一的 |

---

## タイポグラフィ変数（16-22）

担当: typography-director

| # | 変数名 | 説明 | 型 | 範囲/選択肢 |
|---|--------|------|----|------------|
| 16 | `font_display` | 見出し/タイトルフォント | string | フォントファミリー名 |
| 17 | `font_body` | 本文テキストフォント | string | フォントファミリー名 |
| 18 | `font_display_category` | 見出しフォント分類 | enum | serif, sans-serif, slab, display, script, monospace |
| 19 | `font_body_category` | 本文フォント分類 | enum | serif, sans-serif, slab, monospace |
| 20 | `font_jp_category` | 日本語フォントカテゴリ | enum | gothic, mincho, maru-gothic, custom |
| 21 | `type_scale_ratio` | タイポグラフィスケール倍率 | enum | minor-second (1.067), major-second (1.125), minor-third (1.2), major-third (1.25), perfect-fourth (1.333), golden (1.618) |
| 22 | `type_base_size` | ベースフォントサイズ (px) | number | 14-18 |

### フォント分類とパーソナリティ

| カテゴリ | パーソナリティ | ユースケース |
|---------|-------------|-----------|
| Serif | 伝統的、信頼感、エレガント | エディトリアル、高級、金融 |
| Sans-Serif | モダン、クリーン、アクセシブル | テック、SaaS、ヘルスケア |
| Slab Serif | 安定感、力強い、モダン | メディア、マーケティング |
| Monospace | 技術的、精密 | 開発ツール、フィンテック |
| Script | 個人的、エレガント | ファッション、ビューティー |
| Display | ユニーク、大胆 | 見出し限定、特別なブランディング |

### 日本語フォントカテゴリ

| カテゴリ | 対応する欧文 | パーソナリティ | ユースケース |
|---------|------------|-------------|-----------|
| Gothic (ゴシック) | Sans-serif | モダン、クリーン | UI テキスト、Web本文 |
| Mincho (明朝) | Serif | 伝統的、フォーマル | エディトリアル、高級 |
| Maru Gothic (丸ゴシック) | Rounded sans | 親しみやすい、温かい | 子供向け、カジュアル |
| Custom | - | ブランド固有 | 特別なブランディング |

---

## ビジュアルスタイル変数（23-34, 42）

担当: visual-style-architect

| # | 変数名 | 説明 | 型 | 範囲/選択肢 |
|---|--------|------|----|------------|
| 23 | `spacing_base_unit` | グリッド基本単位 | enum | 4px, 8px |
| 24 | `spacing_density` | 全体のスペーシング密度 | enum | compact, default, comfortable |
| 25 | `corner_radius_style` | グローバル角丸スタイル | enum | sharp (0), subtle (2-4), medium (6-8), large (12-16), extra-large (20-28), pill (9999) |
| 26 | `shadow_style` | 影/エレベーションアプローチ | enum | none (flat), subtle, medium, deep, colored |
| 27 | `elevation_levels` | エレベーション段階数 | number | 0-5 |
| 28 | `icon_style` | アイコンのビジュアルスタイル | enum | outlined, filled, duotone, flat, illustrative |
| 29 | `icon_stroke_width` | アイコンの線の太さ | number | 1-3 (px) |
| 30 | `animation_style` | モーションのパーソナリティ | enum | none, snappy, smooth, bouncy, gentle |
| 31 | `animation_duration_base` | ベーストランジション時間 (ms) | number | 0-700 |
| 32 | `illustration_style` | イラストアプローチ | enum | flat-vector, isometric, 3d, hand-drawn, abstract-geometric, character, line-art, none |
| 33 | `visual_style` | 全体UIスタイルアプローチ | enum | minimalist, material, flat, glassmorphism, neomorphism, neobrutalism, corporate-clean, skeuomorphic |
| 34 | `information_density` | コンテンツ密度レベル | enum | sparse, moderate, dense |
| 42 | `photography_style` | 写真の扱い方 | enum | none, editorial, lifestyle, abstract, product, illustration-hybrid |

### 角丸パーソナリティスケール

| 角丸 | 値 (px) | パーソナリティ |
|------|---------|-------------|
| Sharp | 0 | テクニカル、ブルータリスト、精密 |
| Subtle | 2-4 | プロフェッショナル、フォーマル |
| Medium | 6-8 | バランス、モダン、標準 |
| Large | 12-16 | フレンドリー、親しみやすい |
| Extra-large | 20-28 | プレイフル、柔らかい |
| Pill | 9999 | オーガニック、楽しい、カジュアル |

### モーションパーソナリティ

| スタイル | イージング | 時間 | パーソナリティ |
|---------|---------|------|-------------|
| Snappy | ease-out, spring (高剛性) | 100-200ms | 効率的、プロフェッショナル |
| Smooth | ease-in-out | 200-400ms | 洗練、落ち着き |
| Bouncy | spring (低減衰) | 300-600ms | プレイフル、若々しい |
| Gentle | ease-out (遅) | 400-700ms | リラックス、ラグジュアリー |
| None | - | 0ms | 実用的、データ重視 |

---

## ユーザーコンテキスト変数（35, 38-40）

担当: user-psychologist

| # | 変数名 | 説明 | 型 | 範囲/選択肢 |
|---|--------|------|----|------------|
| 35 | `formality_level` | 全体のフォーマリティ | scale | 1 (非常にカジュアル) - 10 (非常にフォーマル) |
| 38 | `target_age_primary` | 主要ターゲット年齢層 | enum | gen-z, millennial, gen-x, boomer, universal |
| 39 | `cultural_context` | 主要文化コンテキスト | enum | global, western, east-asian, japanese, etc. |
| 40 | `accessibility_level` | アクセシビリティ基準 | enum | wcag-aa, wcag-aaa |

### 年齢層別デザイン傾向

| 年齢層 | ビジュアル傾向 | 重要考慮点 |
|--------|-------------|----------|
| Gen Z (18-27) | 大胆な色、ダイナミック、ダークモード | モバイルファースト、動画ネイティブ |
| Millennial (28-43) | クリーン、パーソナル、ストーリーテリング | クロスデバイス、価値観ブランディング |
| Gen X (44-59) | 明確な階層、機能美 | デスクトップ重視、ディテール志向 |
| Boomer (60+) | ハイコントラスト、大きい文字 | アクセシビリティ最優先、予測可能なナビ |
| Universal | バランス、アクセシブル | 全年齢対応、プログレッシブ開示 |

---

## トーン・オブ・ボイス変数（36-37）

担当: tone-of-voice-writer

| # | 変数名 | 説明 | 型 | 範囲/選択肢 |
|---|--------|------|----|------------|
| 36 | `voice_humor` | UIコピーのユーモアレベル | scale | 1 (シリアス) - 10 (プレイフル) |
| 37 | `voice_enthusiasm` | UIコピーのエネルギーレベル | scale | 1 (控えめ) - 10 (熱狂的) |

### ブランドボイスマトリクス（追加次元）

tone-of-voice-writer は変数 36-37 に加え、以下のマトリクス次元も設定する（レポートに記載）:

| 次元 | スペクトル |
|------|---------|
| Formality | カジュアル ←→ フォーマル (= 変数 35 と連動) |
| Humor | シリアス ←→ プレイフル (= 変数 36) |
| Enthusiasm | 控えめ ←→ 熱狂的 (= 変数 37) |
| Respect | 型破り ←→ 礼儀正しい |
| Complexity | シンプル ←→ テクニカル |

---

## デザインテンション変数（41）

担当: brand-strategist（全エージェントが参照）

| # | 変数名 | 説明 | 型 | 例 |
|---|--------|------|----|---|
| 41 | `design_tension` | 意図的な矛盾ペア（ブランドの独自性の源泉） | string | "minimal but warm", "bold but refined", "technical but human" |

### デザインテンションの例と効果

| テンション | 効果 |
|-----------|------|
| "Minimal but warm" | クリーンなレイアウト + 暖色パレット + 大きめ角丸 |
| "Professional but playful" | 構造的グリッド + バウンシーなマイクロインタラクション |
| "Bold but refined" | 強いカラーコントラスト + エレガントなタイポグラフィ |
| "Technical but human" | モノスペース要素 + オーガニックなイラスト |
| "Luxurious but accessible" | プレミアム美学 + 大きいサイズ + ハイコントラスト |
| "Traditional but innovative" | セリフタイポグラフィ + モダンレイアウト + アニメーション |

デザインテンションが「AIっぽいデザイン」を防ぐ最も重要な要素。矛盾ペアが意図的な判断を強制し、安易なデフォルトへの逃げを防ぐ。
