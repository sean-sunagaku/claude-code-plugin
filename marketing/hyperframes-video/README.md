# hyperframes-video

[HyperFrames](https://github.com/heygen-com/hyperframes)（HeyGen 製 OSS / MIT）で、
アプリのプロモ動画を **HTML から決定論的に** MP4 化するための Plugin です。

HyperFrames 自体の使い方は公式スキル（19本）が既に網羅しているため、
この Plugin はそれを **土台として前提**にし、重複しない部分だけを担当します。

- 素材の橋渡し（Simulator スクショ・App Store スクショ・ロゴ・実データ）
- 納品前の検証ゲート（`lint` → `inspect` → `snapshot` → `render`）
- Claude Design を第一稿に使うルートの選択（Download-ZIP / Send to HyperFrames）
- 誇張表現の禁止ルール（レビュー・評価・効能の捏造防止）
- 既存の動画スキル 3 本の使い分け

## Install

```bash
claude plugin marketplace add sean-sunagaku/claude-code-plugin --scope user
claude plugin marketplace update sunagaku-marketplace
claude plugin install hyperframes-video@sunagaku-marketplace --scope user
```

## Skills

- `hyperframes-video`: HyperFrames でプロモ動画を作る（素材整理 → composition 実装 → 検証 → render）

## 前提

- Node.js 22 以上 / FFmpeg
- 初回のみ `npx hyperframes skills update` で公式スキルを導入

## 使い分け

| 用途 | スキル | 手段 |
|------|--------|------|
| SNS リール・LP ヒーロー・リリース告知 | **`hyperframes-video`**（本 Plugin） | HyperFrames (HTML + GSAP) |
| App Store 提出用プレビュー動画 | `app-store-preview-movie` | Remotion + 5エージェントチーム |
| ライブ登壇の15秒即席動画 | `promo-video-lite` (lt-ios-launch) | ffmpeg のみ・初期化不要 |

## Claude Design を第一稿に使う

composition を書き起こす代わりに、Claude Design に第一稿を作らせて
Claude Code で仕上げるルートもスキル内に含めています（Step 3 ルート B）。

経路は2つあり、添付する公式指示ファイルも守るルールも異なります。

| | Download-ZIP（既定） | Send to HyperFrames |
|---|---|---|
| 受け取る形 | 複数ファイルの ZIP | 単一の自己完結 HTML |
| 次工程 | ローカルで仕上げ、CLI で render | HyperFrames 上で強化、クラウドで render |
| 指示ファイル | [claude-design-hyperframes.md](https://github.com/heygen-com/hyperframes/blob/main/docs/guides/claude-design-hyperframes.md) | [claude-design-send-to-hyperframes.md](https://github.com/heygen-com/hyperframes/blob/main/docs/guides/claude-design-send-to-hyperframes.md) |

選び方と手順は `references/claude-design-route.md` にあります。
