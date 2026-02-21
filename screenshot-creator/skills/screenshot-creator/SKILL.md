---
name: screenshot-creator
description: >
  App Store / Google Play 用のプロモーションスクリーンショットを Pencil (.pen) で生成する
  Agent Team スキル。creative-director が戦略を立て、screenshot-designer が Pencil で
  デザインを構築し、copy-writer がコピーを提供し、quality-reviewer が最終品質を確認する。
  Use when: App Store スクリーンショットを作りたい、プロモーション画像を作成したい、
  スクショのデザインをしたい。
  Triggers: "スクリーンショット作成", "App Store 画像", "プロモーションスクショ",
  "screenshot creator", "スクショ作って", "App Store 素材"
---

# screenshot-creator スキル

## Step 1: ヒアリング

以下を確認する（不明ならユーザーに質問）:

- **アプリ名**: App Store に表示されるアプリ名
- **カテゴリ**: 生産性、ライフスタイル、ヘルス等
- **主要機能**: 3〜5 個の機能とその説明
- **ターゲットユーザー**: 年齢層・利用シーン等
- **ブランドカラー**: メインカラー（任意。指定なければ creative-director が提案）
- **トーン**: プロフェッショナル / カジュアル / エモーショナル等
- **スクリーンショット枚数**: 1〜10 枚（推奨 5〜6 枚）
- **.pen ファイルパス**: 任意。指定なければ新規作成

## Step 2: チーム作成とエージェント起動

TeamCreate で `screenshot-creator` チームを作成。
以下 4 エージェントを **1つのメッセージで並列に** Task ツールで起動する。

| name | 役割 | 主な手段 |
|------|------|---------|
| `creative-director` | 戦略立案・ディレクション | WebSearch（MCP不使用） |
| `screenshot-designer` | Pencil でビジュアル構築 | Pencil MCP (batch_design, get_screenshot) |
| `copy-writer` | キャッチコピー・説明文 | WebSearch |
| `quality-reviewer` | 品質レビュー・スコアリング | Pencil MCP (get_screenshot, batch_get) |

### タスク作成

TaskCreate で 5 つのタスクを作成:

1. creative-director: スクリーンショット構成計画・スタイル決定（依存なし）
2. copy-writer: 各スクリーンのコピー作成（依存なし）
3. screenshot-designer: Pencil でデザイン構築（`addBlockedBy: ["1", "2"]`）
4. quality-reviewer: 品質レビュー + スコアリング（`addBlockedBy: ["3"]`）
5. 最終確認: リーダーが最終確認（`addBlockedBy: ["4"]`）

### 起動設定

**MCP ツール使用エージェント（screenshot-designer, quality-reviewer）:**
```
subagent_type: "general-purpose"
team_name: "screenshot-creator"
mode: "bypassPermissions"
run_in_background: true
```
プロンプトに `agents/screenshot-designer.md`（または `quality-reviewer.md`）の内容を全文含めること。

**MCP ツール不使用エージェント（creative-director, copy-writer）:**
```
subagent_type: "screenshot-creator:{role-name}"
team_name: "screenshot-creator"
mode: "bypassPermissions"
run_in_background: true
```

**全エージェント共通でプロンプトに含める情報:**
- ユーザーからヒアリングした全情報（省略厳禁）
- .pen ファイルパス
- チームメンバー一覧と役割
- references/ ファイルのパス（絶対パス）

## Step 3: フィードバックループ

### Round 1: 構成計画 + コピー作成（並列）
- creative-director がスクショ構成計画を作成 → screenshot-designer と copy-writer に共有
- copy-writer が各スクリーンのコピーを作成 → screenshot-designer に共有

### Round 2: デザイン構築 + レビュー
- screenshot-designer が Pencil でデザイン構築 → quality-reviewer にレビュー依頼
- quality-reviewer がスコアリング → screenshot-designer にフィードバック

### Round 3: 修正 + 最終確認
- screenshot-designer がフィードバック反映 → quality-reviewer が再確認
- creative-director が最終報告をリーダーに送信

### 緊急通知パターン
- **quality-reviewer**: コントラスト比不足・セーフエリア侵害を検出 → screenshot-designer に即修正依頼
- **copy-writer**: Apple ガイドライン違反のテキスト（価格表示等）を発見 → 全員に警告
- **screenshot-designer**: .pen ファイルの破損・競合を検知 → 全員に中断連絡

## Step 4: 最終確認

リーダーが以下を確認:
- 品質スコアが 7/10 以上
- 全スクリーンショットに日本語・英語コピーが設定されている
- .pen ファイルが正常に保存されている

## Step 5: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除

## 出力成果物

- Pencil .pen ファイル（スクリーンショット全枚数）
- 各スクリーンショットのノードID一覧
- コピーテキスト一覧（日本語・英語）
- 品質レビュースコア（10点満点）

## App Store スクリーンショット仕様

詳細は [references/app-store-screenshot-specs.md](references/app-store-screenshot-specs.md) を参照。
