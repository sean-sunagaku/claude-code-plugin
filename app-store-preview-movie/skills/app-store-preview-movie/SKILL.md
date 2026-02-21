---
name: app-store-preview-movie
description: >
  App Store プレビュー動画を Remotion (React) で生成する Agent Team スキル。
  video-director が構成を設計し、script-writer がナレーション台本を作成し、
  motion-designer が Remotion コードを実装し、preview-reviewer が最終品質を確認する。
  Use when: App Store プレビュー動画を作りたい、アプリのプロモーション動画を作りたい、
  Remotion で動画を生成したい。
  Triggers: "プレビュー動画", "App Store 動画", "アプリ動画", "preview movie",
  "Remotion", "動画作成", "app preview"
---

# app-store-preview-movie スキル

## Step 1: ヒアリング

以下を確認する（不明ならユーザーに質問）:

- **アプリ名**: App Store に表示されるアプリ名
- **カテゴリ**: 生産性、ライフスタイル、ヘルス等
- **主要機能**: 3〜5 個の機能とその説明
- **ターゲットユーザー**: 年齢層・利用シーン等
- **ブランドカラー**: メインカラー + 背景色
- **トーン**: プロフェッショナル / カジュアル / エモーショナル等
- **動画の長さ**: 15秒 or 25秒（Apple仕様上限: 25秒）
- **出力先ディレクトリ**: Remotion プロジェクトの配置先
- **使用するスクリーンショット/素材パス**: 動画内で表示する画面キャプチャ（任意）

## Step 2: Remotion プロジェクト確認

出力先ディレクトリに既存の Remotion プロジェクトがあるか確認する。
なければ motion-designer が初期化する（package.json + remotion.config.ts）。

## Step 3: チーム作成とエージェント起動

TeamCreate で `app-store-preview-movie` チームを作成。
以下 4 エージェントを **1つのメッセージで並列に** Task ツールで起動する。

| name | 役割 | 主な手段 |
|------|------|---------|
| `video-director` | シーン構成・全体ディレクション | Read, WebSearch |
| `motion-designer` | Remotion コード実装 | Write, Edit, Bash |
| `script-writer` | 字幕・CTA テキスト作成 | WebSearch |
| `preview-reviewer` | コードレビュー・仕様チェック | Read, Bash, Grep |

### タスク作成

TaskCreate で 5 つのタスクを作成:

1. video-director: ストーリーボード・シーン構成設計（依存なし）
2. script-writer: 字幕・ナレーション台本作成（依存なし）
3. motion-designer: Remotion コード実装（`addBlockedBy: ["1", "2"]`）
   - remotion-best-practices の関連ルールを Read で参照:
     - `/Users/babashunsuke/Desktop/miravy/.claude/skills/remotion-best-practices/rules/compositions.md`
     - `/Users/babashunsuke/Desktop/miravy/.claude/skills/remotion-best-practices/rules/animations.md`
     - `/Users/babashunsuke/Desktop/miravy/.claude/skills/remotion-best-practices/rules/transitions.md`
     - `/Users/babashunsuke/Desktop/miravy/.claude/skills/remotion-best-practices/rules/timing.md`
     - `/Users/babashunsuke/Desktop/miravy/.claude/skills/remotion-best-practices/rules/fonts.md`
4. preview-reviewer: コードレビュー + 品質スコアリング（`addBlockedBy: ["3"]`）
5. 最終確認: レンダリング + リーダー確認（`addBlockedBy: ["4"]`）

### 起動設定（全エージェント共通）

```
subagent_type: "app-store-preview-movie:{role-name}"
team_name: "app-store-preview-movie"
mode: "bypassPermissions"
run_in_background: true
```

プロンプトに含める情報:
- ユーザーからヒアリングした全情報（省略厳禁）
- 出力先ディレクトリの絶対パス
- チームメンバー一覧と役割
- references/ ファイルのパス
- remotion-best-practices のルールファイルパス

## Step 4: フィードバックループ

### Round 1: 構成設計 + テキスト作成（並列）
- video-director がシーン構成・タイミング設計 → motion-designer と script-writer に共有
- script-writer が字幕テキスト作成 → motion-designer に共有

### Round 2: コード実装 + レビュー
- motion-designer が Remotion コード実装 → preview-reviewer にレビュー依頼
- preview-reviewer がコードレビュー + スコアリング → motion-designer にフィードバック

### Round 3: 修正 + 最終確認
- motion-designer がフィードバック反映 → preview-reviewer が再確認
- video-director が最終報告をリーダーに送信

### 緊急通知パターン
- **preview-reviewer**: CSS transitions/animations 使用を検出 → motion-designer に即修正依頼
- **preview-reviewer**: 解像度・fps・長さの仕様違反を発見 → video-director + motion-designer に警告
- **script-writer**: Apple ガイドライン違反テキスト（価格表示等）を発見 → 全員に警告

## Step 5: 最終確認

リーダーが以下を確認:
- 品質スコアが 7/10 以上
- TypeScript コンパイルエラーなし
- 全シーンに字幕が配置されている
- 動画仕様（解像度、長さ、fps）が Apple ガイドライン準拠

## Step 6: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除

## 出力成果物

- Remotion プロジェクト一式（src/ ディレクトリ）
- 各シーンのコンポーネントファイル（.tsx）
- Root.tsx（コンポジション定義）
- ナレーション台本（日本語・英語）
- 品質レビューレポート

## Remotion ベストプラクティス

motion-designer が実装時に参照:
`/Users/babashunsuke/Desktop/miravy/.claude/skills/remotion-best-practices/rules/`

## App Store プレビュー動画仕様

詳細は [references/app-store-video-specs.md](references/app-store-video-specs.md) を参照。
シーンテンプレートは [references/scene-templates.md](references/scene-templates.md) を参照。
