# CLI プレイブック

`npx hyperframes <command>`。グローバル導入は `npm install -g hyperframes`。
CLI はエージェント向けが既定で、フラグ指定・パース可能な出力になっている。
多くのコマンドが `--json` を受け、`_meta` にバージョン情報が入る。

ここに載せたのは公式ドキュメントで確認したフラグのみ。
載っていないオプションは `npx hyperframes <command> --help` で確認すること。

## 環境確認

```bash
npx hyperframes doctor    # 不足している依存を検出
npx hyperframes info      # バージョンと環境
```

Node.js 22 以上と FFmpeg が必須。

## 公式スキルの導入・更新

```bash
npx hyperframes skills update          # コアセットを導入/更新（推奨）
npx hyperframes skills check           # 古い/不足があれば非ゼロ終了
npx hyperframes skills update <name>   # 個別のワークフロースキルを追加
```

導入後は `/hyperframes` がルーター。実装の細部はこれに routing させる。

`npx hyperframes init` も実行時にコアセットを更新する（`--skip-skills` で無効化）。

## プロジェクト作成

```bash
npx hyperframes init my-video --example blank --resolution portrait
```

| フラグ | 内容 |
|--------|------|
| `--example, -e` | `blank` / `warm-grain` / `play-mode` / `swiss-grid` / `vignelli` |
| `--resolution` | `landscape`(1920×1080) / `portrait`(1080×1920) / `square`(1080×1080) / それぞれの `-4k` |
| `--video, -V` | 動画ファイルを同梱（自動で文字起こしされる） |
| `--audio, -a` | 音声ファイルを同梱（同上） |
| `--tailwind` | Tailwind v4 ブラウザランタイムを注入 |
| `--skip-skills` | 公式スキルの導入をスキップ |
| `--skip-transcribe` | 自動文字起こしをスキップ |
| `--non-interactive` | 対話を止め `--example` を必須にする |

非対話モードでは `--example` が必須。

## 確認・検証

```bash
npx hyperframes lint            # 構造の妥当性。エラー0が render の前提
npx hyperframes inspect         # はみ出し・見切れ・重なり + モーション意図の照合
npx hyperframes snapshot        # キーフレームを PNG 化
npx hyperframes preview         # ブラウザでライブプレビュー（--port で変更）
npx hyperframes compositions    # 尺・解像度・要素数の一覧（--json 可）
```

`lint` は構造、`inspect` はレンダリング結果のレイアウトを見る。役割が違うので両方通す。

## レンダリング

```bash
npx hyperframes render --output renders/promo.mp4 --fps 30 --quality high
npx hyperframes render --docker --output renders/promo.mp4     # 決定論的
npx hyperframes render -c compositions/intro.html -o intro.mp4  # 別ファイル指定
npx hyperframes render --format webm --output overlay.webm      # 透過付き
```

| フラグ | 値 | 既定 |
|--------|-----|------|
| `--output` | パス | `renders/<name>.mp4` |
| `--composition, -c` | パス | `index.html` |
| `--format` | `mp4` / `webm` / `mov` / `gif` / `png-sequence` | `mp4` |
| `--fps` | 1〜240、または `30000/1001` のような有理数 | `30` |
| `--quality` | `draft` / `standard` / `high` | `standard` |
| `--crf` | 0〜51（小さいほど高品質） | — |
| `--video-bitrate` | `10M` / `5000k` | — |
| `--resolution` | `portrait` / `landscape` / `square` / 各 `-4k` | — |
| `--workers` | 1〜24 または `auto` | `auto`（CPU数−2） |
| `--docker` | — | off |
| `--gpu` | — | off |
| `--variables` | JSON オブジェクト | — |
| `--variables-file` | パス | — |
| `--strict-variables` | 未宣言・型不一致で失敗させる | off |
| `--quiet` | — | off |

`--crf` と `--video-bitrate` は排他。WebM / MOV は透過を保持する。

### パラメータ化

root に `data-composition-variables` を宣言しておくと、
1つの composition を差し替えレンダリングできる。

```bash
npx hyperframes render --variables '{"title":"新機能","theme":"dark"}' -o ja.mp4
```

composition 側は `window.__hyperframes.getVariables()` で受け取る。
宣言済みの既定値に `--variables` がマージされる。

## 素材づくり

```bash
npx hyperframes catalog --type block --tag social   # ブロック一覧
npx hyperframes add <name>                          # ブロック/コンポーネント追加
npx hyperframes tts "テキスト" --voice jf_alpha -o narration.wav
npx hyperframes transcribe narration.wav --language ja
npx hyperframes remove-background clip.mp4 -o cut.webm
```

- `tts` はローカル実行（Kokoro-82M）。API キー不要。日本語ボイスは `j` 始まり
- `transcribe` は whisper.cpp。`.srt` / `.vtt` / OpenAI JSON の取り込みも可
- `remove-background` は初回にモデル（約168MB）をダウンロードする

## 出力の最終確認

```bash
ffprobe -v error -show_entries stream=width,height,r_frame_rate,pix_fmt,duration \
  -of default=noprint_wrappers=1 renders/promo.mp4
```

解像度・fps・尺・ピクセルフォーマットを指示と突き合わせる。
