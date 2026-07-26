---
name: hyperframes-video
description: >
  HyperFrames (HTML + GSAP → MP4) でアプリのプロモ動画を決定論的に生成するスキル。
  HyperFrames 公式スキル（19本）を土台として前提にし、素材の橋渡し・検証ゲート・
  納品仕様・誇張表現の禁止という「公式が扱わない層」だけを担当する。
  SNS リール、LP ヒーロー動画、リリース告知、機能デモが対象。
  Use when: プロモ動画を作りたい、告知動画を作りたい、HTML から動画を作りたい、
  HyperFrames で動画を作りたい、リリース動画を作りたい、SNS 用の縦動画を作りたい。
  Triggers: "HyperFrames", "hyperframes", "プロモ動画", "告知動画", "宣伝動画",
  "HTML から動画", "html to video", "リリース動画", "SNS動画", "縦動画", "リール"
---

# hyperframes-video

HTML + CSS + 一時停止した GSAP タイムラインを、ヘッドレス Chrome の
フレーム seek で MP4 に焼く。同じ入力なら同じフレーム、同じ出力になる。

## このスキルが担当すること / しないこと

**担当する**（このリポジトリ固有の層）:

- 素材の橋渡し — Simulator 実画面、App Store スクショ、ロゴ、実データ
- 納品前の検証ゲート — 主観の「良さそう」で render を終わらせない
- 誇張表現の禁止 — 捏造したレビュー・評価・効能を動画に載せない
- 動画スキル3本の使い分け

**担当しない**（公式スキルに委ねる）:

シェーダートランジション、キャプション、モーション設計、カタログのブロック、
TTS、文字起こし、背景除去 — すべて公式スキルの方が詳しい。
自前で書き直さず `/hyperframes` ルーターに投げること。

## Step 0: 前提を満たす

```bash
node -v            # 22 以上
command -v ffmpeg  # 必須
npx hyperframes doctor
```

公式スキルを入れる（初回のみ。`init` 実行時にも自動で更新される）:

```bash
npx hyperframes skills update
```

導入後は `/hyperframes` が入口になる。作るものが決まっているなら
このスキルの Step 1〜4 で外枠を固め、実装の細部は `/hyperframes` に routing させる。

## Step 1: 何を作るか1行で確定する

先に決める。決まるまで HTML を書かない。

- 尺と比率 — 縦 1080×1920（SNS）か横 1920×1080（LP・告知）か
- シーン数 — [references/composition-contract.md](references/composition-contract.md) の目安表に従う
- 視聴後に何が起きてほしいか — 1つだけ

尺・比率・訴求の3つが埋まらないうちは、質問を1つだけして待つ。

## Step 2: 素材を集める

**実物を使う。** プレースホルダ画像、ロレム・イプサム、想像で書いた数値は使わない。

| 素材 | 取得元 |
|------|--------|
| アプリ実画面 | `simulator-screenshots` スキル、または実機キャプチャ |
| ストア用の加工済み画像 | `screenshot-creator` スキル |
| ロゴ・アイコン | `pencil-app-icon` スキル、または既存アセット |
| 配色・書体 | `app-tone-manner` スキルの成果物 |

素材が足りないまま進めない。足りない素材は先に作る。

## Step 3: composition を作る（2つの入口）

### ルート A: Claude Code で書き起こす

素材と構成が既に固まっていて、ブランドの見た目も決まっているとき。

```bash
npx hyperframes init <name> --example blank --resolution portrait
cd <name>
```

`--resolution` は `portrait`(1080×1920) / `landscape`(1920×1080) / `square`(1080×1080) /
`portrait-4k` / `landscape-4k` / `square-4k`。

### ルート B: Claude Design に第一稿を作らせる

ビジュアルの方向性が固まっていないとき、ブランド素材（スクショ・PDF・ブランドガイド）
から見た目を起こしてほしいとき。**Claude Design が第一稿、Claude Code が編集室**という分業になる。

手順とルート A/B の選び方は [references/claude-design-route.md](references/claude-design-route.md) に置いた。
要点だけ:

- 公式の指示ファイルを **添付**する（URL を貼るのではなく）
- 戻ってきた ZIP は `lint` を通る状態で届く。構造を直す作業は発生しない
- Claude Code 側の仕事は「作り直し」ではなく、通し再生を見ての詰め
  （イージング、スタガー、尺の微調整、シーン内の動きの追加、シェーダーの差し替え）

どちらのルートでも、以降の Step 4 の検証ゲートは同じように通す。

満たすべき構造契約は [references/composition-contract.md](references/composition-contract.md) に置いた。
特に外せないのは4点:

1. root に `data-composition-id` と **数値の** `data-width` / `data-height` / `data-duration`
2. 各シーンに `data-start` と `data-duration`、シーンは隙間なく端から端まで並べる
3. `window.__timelines["<id>"]` に **paused の GSAP タイムライン**を登録する
4. タイムラインは読み込み時に**同期的に**構築する。自前で `play()` を呼ばない

再生を駆動するのはフレームワーク側。ここを破ると決定論が壊れる。

## Step 4: 検証ゲート（すべて通すこと）

順番に実行する。失敗したら次に進まない。

```bash
npx hyperframes lint       # 構造の妥当性。エラー 0 が通過条件
npx hyperframes inspect    # テキストのはみ出し・見切れ・重なり、モーション意図の照合
npx hyperframes snapshot   # キーフレームを PNG 化して目視
npx hyperframes render --output renders/promo.mp4 --fps 30 --quality high
```

- `lint` のエラーが残ったまま render しない
- `inspect` はレイアウト崩れを機械的に検出する。目視の代わりではなく**目視の前段**
- `snapshot` で最低3点（冒頭・中盤・締め）を実際に開いて見る
- 納品用に厳密な再現性が要るときは `--docker` を付ける

主要フラグは [references/cli-playbook.md](references/cli-playbook.md) に一覧化した。

## Step 5: 納品

- 出力を `ffprobe` で確認 — 解像度・fps・尺・ピクセルフォーマットが指示通りか
- 音声は任意。SNS の自動再生は無音前提なので、無音でも成立する構成にする
- 同じ内容で複数バリエーションを出すなら `--variables` で1つの composition を使い回す

## やってはいけないこと

- 存在しないレビュー、評価、ダウンロード数、受賞歴を載せる
- 未配信のアプリを「配信中」と読める形で締める（デモへの招待に留める）
- 効能・診断・改善を示唆する（医療・健康系の表現）
- 実在しない機能を動かして見せる
- ブランドの固有名詞・実数値を、それらしい一般名詞にぼかす

事実として確認できないものは、動画に入れない。

## 使い分け

| 用途 | スキル |
|------|--------|
| SNS リール・LP ヒーロー・リリース告知 | **本スキル**（HyperFrames） |
| App Store 提出用プレビュー動画 | `app-store-preview-movie`（Remotion + エージェントチーム） |
| ライブ登壇の15秒即席動画 | `promo-video-lite`（ffmpeg のみ・プロジェクト初期化不要） |

Claude Design を第一稿に使うルートは Step 3 のルート B。
経路が2つ（Download-ZIP / Send to HyperFrames）あり、指示ファイルも守るルールも別なので、
着手前に [references/claude-design-route.md](references/claude-design-route.md) でどちらか決める。
