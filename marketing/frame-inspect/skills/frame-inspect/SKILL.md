---
name: frame-inspect
description: >
  動画・画像のフレーム抽出、Remotion レンダリング、仕様チェック、目視検証を行う汎用ビデオツールキット。
  ffmpeg / ffprobe / remotion still / remotion render を統一シェルスクリプト (video-tool.sh) で操作し、
  Read ツール（マルチモーダル対応）で実際の見た目を確認して品質レポートを出す。
  Use when: 動画のフレームを確認したい、レンダリング結果を検証したい、
  画像の品質を目視チェックしたい、Remotion プロジェクトを MP4 に出力したい、
  動画の仕様（解像度・fps・長さ）をチェックしたい。
  Triggers: "フレーム確認", "フレーム検証", "動画チェック", "frame inspect",
  "フレーム抽出", "動画の中身を見たい", "レンダリング確認", "動画検証",
  "MP4 確認", "動画のスクショ", "frame check", "動画を出力", "Remotion render",
  "動画レンダリング", "仕様チェック", "spec check", "video render"
---

# frame-inspect スキル

動画・画像のフレーム抽出、Remotion レンダリング、仕様チェック、目視検証の統合ツールキット。

## シェルスクリプト

`scripts/video-tool.sh` で全操作を統一的に実行できる:

```
TOOL={スキルディレクトリ}/scripts/video-tool.sh

$TOOL info   <video>                       # 動画情報を表示
$TOOL check  <video> --spec KEY=VAL ...    # 仕様チェック
$TOOL frames <video> <outdir> [--fps N]    # フレーム抽出
$TOOL still  <dir> <outdir> [--frame N]    # Remotion still
$TOOL render <dir> <output> [--comp ID]    # Remotion → MP4
$TOOL gif    <video> <output> [--fps N]    # GIF 作成
```

## Step 1: 入力の特定

ユーザーから以下を確認:

- **対象ファイル/ディレクトリ**: 動画ファイルのパス、または Remotion プロジェクトのディレクトリ
- **やりたいこと**: フレーム抽出 / レンダリング / 仕様チェック / 目視検証
- **確認したいポイント**（任意）: 特定のシーン、タイミング、品質基準など

## Step 2: 入力タイプの判定

| 入力 | 判定方法 | 使えるコマンド |
|------|---------|--------------|
| `.mp4` / `.mov` / `.webm` / `.avi` | 拡張子で判定 | `info`, `check`, `frames`, `gif` |
| `.png` / `.jpg` / `.jpeg` / `.gif` / `.webp` | 拡張子で判定 | Read で直接表示 |
| ディレクトリ + `package.json` に `remotion` | package.json を Read | `still`, `render` + 上記全て |
| ディレクトリ + 動画ファイル群 | ls で確認 | 各ファイルに対して上記 |

## Step 3: 操作の実行

### 3A: 動画情報の確認

```bash
$TOOL info {videoPath}
```

出力: 解像度、fps、長さ、コーデック、ファイルサイズ

### 3B: 仕様チェック（ffprobe ベース）

```bash
# App Store プレビュー動画の仕様チェック例
$TOOL check {videoPath} \
  --spec width=886 \
  --spec height=1920 \
  --spec fps=30 \
  --spec codec=h264 \
  --spec max_duration=25 \
  --spec max_size_mb=500

# 汎用的な仕様チェック
$TOOL check {videoPath} \
  --spec width=1920 \
  --spec height=1080 \
  --spec fps=60
```

チェック可能な項目:

| キー | 説明 | チェック方法 |
|------|------|------------|
| `width` | 横幅 (px) | 完全一致 |
| `height` | 縦幅 (px) | 完全一致 |
| `fps` | フレームレート | 完全一致 |
| `codec` | コーデック名 | 完全一致 (h264, hevc 等) |
| `max_duration` | 最大長さ (秒) | 以下 |
| `max_size_mb` | 最大サイズ (MB) | 以下 |

### 3C: フレーム抽出（動画 → PNG）

```bash
# 1秒に1枚（デフォルト）
$TOOL frames {videoPath} {outDir}

# 0.5秒に1枚
$TOOL frames {videoPath} {outDir} --fps 2

# サムネイル用（2秒に1枚）
$TOOL frames {videoPath} {outDir} --fps 0.5
```

### 3D: Remotion still（特定フレーム抽出）

```bash
# フレーム 0
$TOOL still {projectDir} {outDir} --frame 0

# フレーム 90（30fps なら 3秒目）
$TOOL still {projectDir} {outDir} --frame 90

# コンポジション ID を明示
$TOOL still {projectDir} {outDir} --frame 0 --comp MyComposition
```

### 3E: Remotion render（MP4 出力）

```bash
# 自動検出（Root.tsx から composition ID を取得）
$TOOL render {projectDir} out/preview.mp4

# コンポジション ID を明示
$TOOL render {projectDir} out/preview.mp4 --comp AppStorePreview
```

レンダリング後は自動的に `check` で仕様確認するのを推奨:

```bash
$TOOL render {projectDir} out/preview.mp4
$TOOL check out/preview.mp4 --spec width=886 --spec height=1920 --spec fps=30
```

### 3F: GIF 作成（プレビュー用）

```bash
# デフォルト（5fps, 幅320px）
$TOOL gif {videoPath} out/preview.gif

# 高品質（10fps）
$TOOL gif {videoPath} out/preview.gif --fps 10
```

## Step 4: 目視検証

抽出したフレーム画像を Read ツールで確認する。

```
Read: {outDir}/frame_001.png
Read: {outDir}/frame_005.png
Read: {outDir}/frame_010.png
```

### チェック項目

#### レイアウト
- テキストや要素が画面外にはみ出していないか
- 要素同士が不自然に重なっていないか
- 余白のバランスが適切か

#### テキスト
- 文字が読めるサイズか
- テキストと背景のコントラストが十分か
- 文字化けや欠けがないか

#### カラー・ビジュアル
- 意図した色が使われているか
- 背景が意図せず真っ白/真っ黒になっていないか
- 画像が正しく表示されているか（壊れ、欠け、歪みがないか）

#### アニメーション状態（動画の場合）
- シーン遷移が自然か（空白フレームがないか）
- アニメーションの途中状態が意図通りか

#### エンコード品質（MP4 の場合）
- 圧縮アーティファクト（ブロックノイズ）が目立たないか
- テキストがエンコードで潰れていないか
- 先頭・末尾に不要な空白フレームがないか

## Step 5: レポート出力

検証結果をユーザーに報告:

```markdown
## フレーム検証レポート

### 対象
- ファイル: {fileName}
- 種類: {MP4 / Remotion / 画像}
- 解像度: {width} x {height}
- fps: {fps}
- 長さ: {duration}（動画の場合）
- コーデック: {codec}
- サイズ: {size}MB

### 仕様チェック
| 項目 | 値 | 判定 |
|------|-----|------|
| 解像度 | {W}x{H} | OK/NG |
| fps | {fps} | OK/NG |
| 長さ | {duration}s | OK/NG |
| コーデック | {codec} | OK/NG |
| サイズ | {size}MB | OK/NG |

### フレーム検証結果

| フレーム | タイミング | 判定 | コメント |
|---------|-----------|------|---------|
| frame_001.png | 0:01 | OK | - |
| frame_003.png | 0:03 | NG | テキストが右端で切れている |
| frame_005.png | 0:05 | OK | トランジションがスムーズ |

### 問題点
1. **frame_003.png (0:03)**: テキストが画面右端で切れている
   - 推定原因: テキスト要素の x 座標が大きすぎる

### 良好な点
- 全体のカラーバランスが良い
- シーン遷移が滑らか
```

## シェルスクリプトなしで直接実行する場合

スクリプトが使えない環境では、以下のコマンドを直接実行:

### ffprobe（動画情報・仕様チェック）

```bash
# 基本情報
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,codec_name,duration \
  -show_entries format=duration,size \
  -of default=noprint_wrappers=1 input.mp4

# JSON 形式（パース用）
ffprobe -v quiet -print_format json -show_format -show_streams input.mp4
```

### ffmpeg（フレーム抽出）

```bash
# 等間隔フレーム抽出（1fps）
ffmpeg -i input.mp4 -vf "fps=1" out/frame_%03d.png -y

# 特定秒のフレーム
ffmpeg -i input.mp4 -ss 5.5 -frames:v 1 out/at_5s.png -y

# 特定フレーム番号（0-indexed）
ffmpeg -i input.mp4 -vf "select=eq(n\,60)" -frames:v 1 out/frame_060.png -y

# GIF 作成
ffmpeg -i input.mp4 -vf "fps=5,scale=320:-1:flags=lanczos" out/preview.gif -y

# 先頭 N 秒だけ切り出し
ffmpeg -i input.mp4 -t 5 -c copy out/first_5s.mp4 -y
```

### Remotion

```bash
# still（特定フレーム抽出）
cd {projectDir} && npx remotion still {compositionId} out/frame.png --frame=0

# render（MP4 出力）
cd {projectDir} && npx remotion render {compositionId} out/preview.mp4

# フレーム番号の計算（30fps）
# 1秒 = 30フレーム, 3秒 = 90, 5.5秒 = 165
```

## 典型的なワークフロー例

### Remotion プロジェクトの検証

```bash
# 1. MP4 にレンダリング
$TOOL render ./preview-video out/preview.mp4

# 2. 仕様チェック
$TOOL check out/preview.mp4 --spec width=886 --spec height=1920 --spec fps=30 --spec codec=h264 --spec max_duration=25

# 3. フレーム抽出
$TOOL frames out/preview.mp4 out/video-frames --fps 2

# 4. Read で目視確認
Read: out/video-frames/frame_001.png
Read: out/video-frames/frame_010.png
Read: out/video-frames/frame_020.png
```

### 既存 MP4 の品質チェック

```bash
# 1. 情報確認
$TOOL info input.mp4

# 2. フレーム抽出
$TOOL frames input.mp4 out/frames

# 3. Read で目視確認
Read: out/frames/frame_001.png
Read: out/frames/frame_005.png
```
