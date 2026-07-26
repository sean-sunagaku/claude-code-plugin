# HIG コンポーネント実装仕様

iOS 純正の見た目を再現するための、コンポーネント別の実装基準。

## ナビゲーションバー

- Large Title（34px/bold）がスクロールで通常タイトル（17px/semibold）に縮むアニメーション
- 戻るボタンは `‹` + 前画面名（tintColor）
- スクロール量に応じて下端に区切り線（0.5px, `rgba(60,60,67,0.29)`）をフェードイン
- 背景は半透明 + `backdrop-filter: blur(20px)`

```css
.nav-bar {
  position: sticky;
  top: 0;
  background: rgba(249, 249, 249, 0.94);
  backdrop-filter: saturate(180%) blur(20px);
}
```

## タブバー

- 高さ 49px + セーフエリア分の下余白（ホームインジケーター領域 34px）
- 半透明 + `backdrop-filter: blur`
- アイコン（25px 相当のインライン SVG）+ ラベル（10px）
- 選択中は tintColor、非選択は `#8E8E93`
- 上端に 0.5px の区切り線

## リスト（Inset Grouped）

- 角丸 10px、左右インセット 16px
- セル高さ 44px 以上（タップターゲット最小 44 × 44px）
- セパレーターは左インセット 16px（セル先頭からではなくテキスト開始位置に揃える）
- 遷移するセルは右端に `›` シェブロン（`#C7C7CC`）
- セクションヘッダーは 13px、`#6D6D72`、大文字寄りの字間、上下 8px

## ボタン

| スタイル | 見た目 |
|---------|--------|
| Filled | 背景 tintColor、文字白、角丸 12px、高さ 50px |
| Tinted | 背景 tintColor 15% 透過、文字 tintColor、角丸 12px |
| Plain | 背景なし、文字 tintColor |

押下時は `opacity: 0.4` → 復帰。`:active` で即時反映し、離したら 0.2 秒で戻す。

```css
.btn:active { opacity: 0.4; transition: opacity 0s; }
.btn { transition: opacity 0.2s; }
```

## スイッチ

- 51 × 31px、角丸 15.5px
- OFF: `#E9E9EA` / ON: `#34C759`（またはアプリの tintColor）
- ノブは 27px の白丸 + `box-shadow: 0 3px 8px rgba(0,0,0,0.15)`
- 0.25 秒でスライド

## セグメンテッドコントロール

- 背景 `rgba(118,118,128,0.12)`、角丸 9px、高さ 32px
- 選択中セグメントは白背景 + `box-shadow: 0 3px 8px rgba(0,0,0,0.12)`、角丸 7px
- 選択インジケーターはスライドして移動

## 検索バー

- 背景 `rgba(118,118,128,0.12)`、角丸 10px、高さ 36px
- 左に虫眼鏡アイコン（`#8E8E93`）、プレースホルダーも `#8E8E93`
- フォーカス時は右に「キャンセル」ボタンがスライドイン

## モーダル / シート

- 下からスライドアップ（0.4 秒、`cubic-bezier(0.32, 0.72, 0, 1)`）
- 上部に角丸 20px、上端中央にグラバー（36 × 5px、`rgba(60,60,67,0.3)`、角丸 2.5px）
- 背景をディム（`rgba(0,0,0,0.4)`）
- グラバーの下方向スワイプまたは背景タップで閉じる

## アラート

- 幅 270px、角丸 14px、中央配置
- 背景 `rgba(242,242,242,0.82)` + `backdrop-filter: blur(20px)`
- タイトル 17px/semibold、メッセージ 13px、中央揃え
- ボタンは 0.5px の区切り線で分割、44px 高さ、tintColor
- 破壊的操作は `#FF3B30`、デフォルトボタンは semibold
- 出現時 `scale(1.15) → 1` + フェード（0.25 秒）

## アクションシート

- 画面下部、左右インセット 8px、角丸 14px
- 選択肢グループと「キャンセル」ボタンを 8px 空けて分離
- 各項目 57px 高さ、20px、tintColor

## アニメーション・操作感

**画面遷移（プッシュ）**

- 新画面が右から入る、前画面は左に 30% 分だけ移動しつつ暗くなる
- `cubic-bezier(0.25, 0.1, 0.25, 1)`、約 0.35 秒

```css
.screen { transition: transform 0.35s cubic-bezier(0.25, 0.1, 0.25, 1); }
```

**スクロール**

```css
.scroll { overflow-y: auto; -webkit-overflow-scrolling: touch; }
```

**アクセシビリティ**

```css
@media (prefers-reduced-motion: reduce) {
  * { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; }
}
```

## アイコン

外部アイコンフォント・画像は使わず、SF Symbols 風のインライン SVG を定義する。

- `viewBox="0 0 24 24"`、`fill="currentColor"` または `stroke="currentColor"` で色を継承させる
- ストローク幅は 1.5〜2（SF Symbols の Regular ウェイト相当）
- 線端・角は `stroke-linecap="round"`、`stroke-linejoin="round"`
- `<symbol>` + `<use>` で 1 回定義して使い回す

## ダークモード（要望がある場合）

| 用途 | Light | Dark |
|------|-------|------|
| 背景（grouped） | `#F2F2F7` | `#000000` |
| カード / セル | `#FFFFFF` | `#1C1C1E` |
| 第 2 背景 | `#FFFFFF` | `#2C2C2E` |
| primary テキスト | `#000000` | `#FFFFFF` |
| secondary テキスト | `rgba(60,60,67,0.6)` | `rgba(235,235,245,0.6)` |
| 区切り線 | `rgba(60,60,67,0.29)` | `rgba(84,84,88,0.65)` |

CSS 変数で定義し、`@media (prefers-color-scheme: dark)` と、プロトタイプ内のトグルの両方で切り替えられるようにする。
