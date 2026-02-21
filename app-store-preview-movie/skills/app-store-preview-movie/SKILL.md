---
name: app-store-preview-movie
description: >
  App Store プレビュー動画を Remotion (React) で生成する Agent Team スキル。
  video-director が構成を設計し、script-writer がナレーション台本を作成し、
  motion-designer が Remotion コードを実装し、preview-reviewer がコードレビューし、
  frame-inspector がレンダリング結果を目視検証する。
  Use when: App Store プレビュー動画を作りたい、アプリのプロモーション動画を作りたい、
  Remotion で動画を生成したい。
  Triggers: "プレビュー動画", "App Store 動画", "アプリ動画", "preview movie",
  "Remotion", "動画作成", "app preview"
---

# app-store-preview-movie スキル

## 委任必須ルール

リーダー（スキル実行者）は以下を **自分で行わない**:
- シーン構成設計 → **video-director に委任**
- 字幕・台本作成 → **script-writer に委任**
- Remotion コード実装 → **motion-designer に委任**
- コードレビュー・品質スコアリング → **preview-reviewer に委任**
- レンダリング結果の目視検証 → **frame-inspector に委任**

リーダーの役割は **ヒアリング・チーム管理・最終判断** のみ。

## Step 1: ヒアリング

以下を確認する（不明ならユーザーに質問）:

- **アプリ名**: App Store に表示されるアプリ名
- **カテゴリ**: 生産性、ライフスタイル、ヘルス等
- **主要機能**: 3〜5 個の機能とその説明
- **ターゲットユーザー**: 年齢層・利用シーン等
- **ブランドカラー**: メインカラー + 背景色
- **トーン**: プロフェッショナル / カジュアル / エモーショナル等
- **動画の長さ**: 15秒 or 25秒（Apple仕様上限: 25秒）
- **出力先ディレクトリ**: Remotion プロジェクトの配置先（絶対パス）
- **使用するスクリーンショット/素材パス**: 動画内で表示する画面キャプチャ（任意）

## Step 2: Remotion プロジェクト確認

出力先ディレクトリに既存の Remotion プロジェクトがあるか確認する。
なければ motion-designer が初期化する（package.json + remotion.config.ts）。

## Step 3: チーム作成とエージェント起動

TeamCreate で `app-store-preview-movie` チームを作成。
以下 5 エージェントを **1つのメッセージで並列に** Task ツールで起動する。

| name | 役割 | subagent_type |
|------|------|---------------|
| `video-director` | シーン構成・全体ディレクション | `app-store-preview-movie:video-director` |
| `motion-designer` | Remotion コード実装 | `app-store-preview-movie:motion-designer` |
| `script-writer` | 字幕・CTA テキスト作成 | `app-store-preview-movie:script-writer` |
| `preview-reviewer` | コードレビュー・品質スコアリング | `app-store-preview-movie:preview-reviewer` |
| `frame-inspector` | レンダリング結果の目視検証 | `app-store-preview-movie:frame-inspector` |

### タスク作成

TaskCreate で 6 つのタスクを作成:

1. **video-director**: ストーリーボード・シーン構成設計（依存なし）
2. **script-writer**: 字幕・ナレーション台本作成（依存なし）
3. **motion-designer**: Remotion コード実装（`addBlockedBy: ["1", "2"]`）
   - remotion-best-practices の関連ルールを Read で参照:
     - `/Users/babashunsuke/Desktop/miravy/.claude/skills/remotion-best-practices/rules/compositions.md`
     - `/Users/babashunsuke/Desktop/miravy/.claude/skills/remotion-best-practices/rules/animations.md`
     - `/Users/babashunsuke/Desktop/miravy/.claude/skills/remotion-best-practices/rules/transitions.md`
     - `/Users/babashunsuke/Desktop/miravy/.claude/skills/remotion-best-practices/rules/timing.md`
     - `/Users/babashunsuke/Desktop/miravy/.claude/skills/remotion-best-practices/rules/fonts.md`
4. **preview-reviewer**: コードレビュー + 品質スコアリング（`addBlockedBy: ["3"]`）
5. **frame-inspector**: レンダリング結果の目視検証（`addBlockedBy: ["3"]`）
6. **最終確認**: レンダリング + リーダー確認（`addBlockedBy: ["4", "5"]`）

### 起動設定（全エージェント共通）

```
subagent_type: "app-store-preview-movie:{role-name}"
team_name: "app-store-preview-movie"
mode: "bypassPermissions"
run_in_background: true
```

プロンプトに含める情報:
- ユーザーからヒアリングした全情報（省略厳禁）
- 出力先ディレクトリの **絶対パス**
- チームメンバー一覧と役割
- references/ ファイルの **絶対パス**
- remotion-best-practices のルールファイルの **絶対パス**
- 使用するスクリーンショットの **絶対パス**

## Step 4: フィードバックループ

### Round 1: 構成設計 + テキスト作成（並列）
- **video-director** がシーン構成・タイミング設計 → motion-designer と script-writer に共有
- **script-writer** が字幕テキスト作成 → motion-designer に共有

### Round 2: コード実装
- **motion-designer** が Remotion コード実装（video-director と script-writer の成果物を受けて）
- 実装完了後に preview-reviewer にレビュー依頼

### Round 3: コードレビュー + 静止フレーム検証（並列）
- **preview-reviewer** がコードレビュー + 品質スコアリング → motion-designer にフィードバック
- **frame-inspector** が `remotion still` でキーフレーム抽出 → Read で目視確認 → motion-designer に視覚的問題を報告

### Round 4: 修正 + 再検証
- **motion-designer** が両方のフィードバック反映
- **preview-reviewer** がコード再確認、**frame-inspector** が修正フレーム再検証

### Round 5: 動画レンダリング検証
- **frame-inspector** が `remotion render` で MP4 生成 → ffprobe で仕様チェック（解像度・fps・長さ・コーデック） → ffmpeg でフレーム抽出 → Read で目視確認
- 問題があれば motion-designer に報告 → 修正 → 再レンダリング

### Round 6: 最終確認
- **video-director** が最終報告をリーダーに送信

### 緊急通知パターン
- **preview-reviewer**: CSS transitions/animations 使用を検出 → motion-designer に即修正依頼
- **preview-reviewer**: 解像度・fps・長さの仕様違反を発見 → video-director + motion-designer に警告
- **preview-reviewer**: スクリーンショットが小さすぎる（幅がフレームの 50% 未満）→ motion-designer に拡大依頼
- **frame-inspector**: テキストが画面外にはみ出し / 要素が重なって読めない → motion-designer に即修正依頼
- **frame-inspector**: 背景が真っ白/真っ黒で抜けている → motion-designer に警告
- **script-writer**: Apple ガイドライン違反テキスト（価格表示等）を発見 → 全員に警告

## Step 5: 最終確認

リーダーが以下を確認:
- 品質スコアが 7/10 以上（preview-reviewer のレポート）
- TypeScript コンパイルエラーなし
- 全シーンにタイトルテキストが配置されている（Caption オーバーレイは使わない）
- スクリーンショットが十分なサイズで表示されている
- **動画レンダリング検証が合格**（frame-inspector のレポート）:
  - MP4 が正常に生成されている（`out/preview.mp4`）
  - ffprobe で仕様チェック済み: 886x1920, 30fps, 15-25秒, H.264
  - 動画フレームの目視確認で問題なし

## Step 6: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除

## 出力成果物

- Remotion プロジェクト一式（src/ ディレクトリ）
- 各シーンのコンポーネントファイル（.tsx）
- Root.tsx（コンポジション定義）
- シーンタイトルテキスト（日本語・英語）
- 品質レビューレポート（ビジュアル検証結果含む）

## アプリアイコンについて

- **MiravyLogo コンポーネント（CSS で円を描画）は使わない**: 色味が実際のアイコンと異なるため
- オープニング（IntroScene）とエンディング（OutroScene）には **実際のアプリアイコン画像**（`icon.png`）を使う
- `<Img src={staticFile("icon.png")} />` + `borderRadius` で角丸表示
- アイコン画像は `mobile/assets/icon.png` から `preview-video/public/icon.png` にコピーして使用
- SVG 版が必要な場合は `assets/logos/` ディレクトリに各種バリアントがある

## 字幕（Caption）について

- **Caption コンポーネントは使わない**: 画面下部の半透明オーバーレイ字幕は不要
- 字幕テキストはシーン内のタイトルエリアに直接配置する（`fontSize: 48`, `fontWeight: 800` 等）
- 画面下部を覆う黒帯（`rgba(0, 0, 0, 0.65)` 等）はスクリーンショットと被って見づらくなるため禁止
- script-writer が作成するテキストは、各シーンのタイトル部分に使用する

## スクリーンショット表示ガイドライン

PhoneMockup コンポーネントでスクリーンショットを表示する際のルール:

### PhoneMockup のスタイル

- **端末ベゼル（枠）は付けない**: 暗い枠や端末フレームは不要。スクリーンショットをそのまま表示する
- **boxShadow は付けない**: スクリーンショットの周りに影を付けない。背景と自然に馴染ませる
- **borderRadius + overflow: hidden のみ**: 角丸でクリッピングするだけのシンプルな表示
- 動画の背景色とスクリーンショットの境界が目立たないようにする

### サイズ基準

- **PhoneMockup ベースサイズ**: width=540px, height=1120px
- フレーム幅（886px）に対して **70〜75%** を占めるサイズにすること（`scale: 1.2` 推奨）
- 小さすぎるとアプリの画面が見づらく、App Store での訴求力が落ちる
- **PhoneMockup の scale は 1.2 を基準**（1.1〜1.3 の範囲で調整）

### 配置・レイアウトバランス

- **スクリーンショットは画面中央〜やや上** に配置する（`bottom: 120px` 程度）
- 画面下端に張り付けない（`bottom: 20px` 等は NG）
- タイトルテキストとスクリーンショットの間に **適切な余白**（60〜120px）を確保する
- Caption オーバーレイは使わないため、スクリーンショットの下部が隠れる心配はない
- **レンダリング後に必ずフレーム抽出して目視確認する**:
  - テキストとスクリーンショットの上下バランスは適切か
  - スクリーンショットが画面下部に偏りすぎていないか
  - タイトルテキストがスクリーンショットに被って読めなくなっていないか
  - 各シーンで配置の一貫性があるか

### NG 例
- `phoneWidth = 340px`（フレーム幅の 38%）→ **小さすぎる**
- `scale = 0.7` → **小さすぎて画面内容が読めない**
- `backgroundColor: "#1A1A2E"` のベゼル → **端末フレーム不要**
- `boxShadow: "0 24px 80px rgba(0,0,0,0.35)"` → **影が強すぎる**
- `bottom: 20` → **下に寄りすぎ、バランスが悪い**

### OK 例
- `scale = 1.2`（フレーム幅の 73%）→ **大きくて見やすい**
- `bottom: 120` → **中央寄り、バランス良い**
- `borderRadius: 44, overflow: "hidden"` のみ → **シンプルで良い**

## Remotion ベストプラクティス

motion-designer が実装時に参照:
`/Users/babashunsuke/Desktop/miravy/.claude/skills/remotion-best-practices/rules/`

## App Store プレビュー動画仕様

詳細は [references/app-store-video-specs.md](references/app-store-video-specs.md) を参照。
シーンテンプレートは [references/scene-templates.md](references/scene-templates.md) を参照。
