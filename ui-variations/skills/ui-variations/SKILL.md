---
name: ui-variations
description: >
  5つの異なるUIデザインバリエーションを並列エージェントチームで生成し、Pencil(.pen)で比較するスキル。
  各バリエーションに デザイナー + レビュアー + コピーライター の3人チーム（計15エージェント）。
  デザイナーが直接 Pencil に構築するため、5画面が同時並行で出来上がる。
  ユーザーの要件から自動で5つのスタイル方向を生成し、それぞれ独自のデザインを作成する。
  Use when: UIのバリエーションを比較したい、複数のデザイン案を出したい、
  デザインの方向性を探りたい、A/Bテスト用のデザインが欲しい。
  Triggers: "UIバリエーション", "デザイン比較", "デザイン案", "5案出して",
  "バリエーション", "デザインパターン", "UI variations", "design alternatives",
  "複数案", "A/Bテスト", "デザイン探索", "スタイル比較"
---

# UI Variations

5つの異なるスタイル方向で同一画面のUIバリエーションを**並列生成**し、Pencilで横並び比較する。
各 ui-designer が `mcp__pencil__batch_design` で直接構築するため、5画面が同時に出来上がる。

## アーキテクチャ

```
リーダー（あなた）
├── V1チーム: v1-designer + v1-reviewer + v1-copywriter
├── V2チーム: v2-designer + v2-reviewer + v2-copywriter
├── V3チーム: v3-designer + v3-reviewer + v3-copywriter
├── V4チーム: v4-designer + v4-reviewer + v4-copywriter
├── V5チーム: v5-designer + v5-reviewer + v5-copywriter
└── affordance-tester（全バリエーション横断で検証）

各 designer が直接 Pencil に書き込む（MCP ツールはサブエージェントでも使用可能）
affordance-tester は全5バリエーション完成後に初見視点で検証
リーダーは見守り + 最終比較レポート
```

## ワークフロー

1. ヒアリング（画面要件、プラットフォーム、ターゲット）
2. スタイル方向の決定（自動5スタイル生成）
3. Pencil キャンバス準備（5フレーム配置）← リーダーが実施
4. 5チーム並列起動（各3エージェント = 計15エージェント）
5. デザイン構築 + チーム内レビュー ← designer が直接 Pencil 操作
6. スクリーンショット取得 + 比較レポート生成
7. クリーンアップ

## Step 1: ヒアリング

以下を確認（不明ならユーザーに質問）:

- **画面**: どの画面を作るか（ログイン、ホーム、設定等）
- **機能要件**: 画面に必要な要素（ボタン、入力欄、リスト等）
- **プラットフォーム**: iOS / Web / 両方
- **ターゲット**: 年齢層、技術レベル
- **既存コード**: あればソースコードを読んで機能を把握
- **制約**: 必須の色、ブランド要件、既存デザインシステム
- **除外スタイル**: 使いたくないスタイル方向

## Step 2: スタイル方向の決定

[references/style-presets.md](references/style-presets.md) を参照し、12種のプリセットから5つを選択。
選択基準:
1. 5つが**明確に異なる**スタイル（似たもの同士を避ける）
2. ユーザーのターゲット・用途に**適合**するもの
3. ユーザーが除外指定したスタイルは**除外**

各スタイルについて以下を定義:
- コンセプト名（日英）
- カラーパレット（背景、プライマリ、テキスト、アクセント）
- フォントファミリーとウェイト
- レイアウト方針（余白、角丸、ボーダー）
- トーン（コピーの方向性）

## Step 3: Pencil キャンバス準備（リーダーが実施）

1. `get_editor_state` で現在のファイルを確認
2. `get_guidelines` でデザインガイドライン取得（topic: "design-system"）
3. `find_empty_space_on_canvas` で空き領域を特定
4. 5つのルートフレームを横並びに配置:

```
V1 (gap:100)  V2 (gap:100)  V3 (gap:100)  V4 (gap:100)  V5
393x852       393x852       393x852       393x852       393x852
```

各フレームの設定:
- width: 393, height: 852 (iPhone 15 Pro)
- clip: true
- layout: vertical
- name: "V{N}: {StyleName}"

**重要**: 各フレームのノードIDを記録する。designer に渡す情報として必須。

## Step 4: チーム作成と15エージェント起動

TeamCreate で `ui-variations` チームを作成。

### タスク作成

TaskCreate で以下を作成:

**バリエーションごと（x5）:**
- `V{N} デザイン構築` - ui-designer 担当
- `V{N} デザインレビュー` - design-reviewer 担当（デザイン構築に blockedBy）
- `V{N} コピー作成` - copy-writer 担当（デザイン構築に blockedBy）

**全体:**
- `V{N} アフォーダンス検証` x5 - affordance-tester 担当（各デザイン構築に blockedBy）
- `スクリーンショット取得 + 比較` - リーダー担当（全タスクに blockedBy）

### エージェント起動

**1つのメッセージで16エージェントを並列起動する。**

各バリエーションにつき3エージェント + 全体1エージェント:

```
subagent_type: "general-purpose"
team_name: "ui-variations"
name: "v{N}-designer" (or v{N}-reviewer, v{N}-copywriter)
model: "opus"
mode: "bypassPermissions"
run_in_background: true
```

**affordance-tester（1体、全バリエーション横断）:**
```
subagent_type: "general-purpose"
team_name: "ui-variations"
name: "affordance-tester"
model: "opus"
mode: "bypassPermissions"
run_in_background: true
```

**注意**: `subagent_type` は `"general-purpose"` を使用する（MCP ツールへのアクセスが必要なため）。
プロンプトに各エージェントの役割定義（agents/*.md の内容）を含める。

### プロンプトに含める情報

**ui-designer へ:**
- agents/ui-designer.md の全内容（役割・手順・Pencilルール）
- .pen ファイルパス（絶対パス）
- 割り当てフレームのノードID
- スタイル方向の詳細（カラーパレット、フォント、レイアウト方針）
- 画面の機能要件
- チーム内メンバー名: `v{N}-reviewer`, `v{N}-copywriter`
- 既存コードの要約（あれば）

**design-reviewer へ:**
- agents/design-reviewer.md の全内容
- .pen ファイルパス
- 割り当てフレームのノードID
- スタイル方向の概要
- チーム内メンバー名: `v{N}-designer`, `v{N}-copywriter`

**copy-writer へ:**
- agents/copy-writer.md の全内容
- .pen ファイルパス
- 割り当てフレームのノードID
- スタイル方向のトーン定義
- ターゲットユーザー情報
- 画面の機能要件
- チーム内メンバー名: `v{N}-designer`, `v{N}-reviewer`

**affordance-tester へ:**
- agents/affordance-tester.md の全内容
- .pen ファイルパス
- 全5フレームのノードID一覧
- 画面の機能要件
- ターゲットユーザー情報
- 全チームメンバー名: `v1-designer` 〜 `v5-designer`, `v1-copywriter` 〜 `v5-copywriter`

## Step 5: 進行管理

リーダーの役割:
- 基本は**見守り**。エージェントが自律的に作業
- designer が直接 Pencil に構築 → reviewer がスクショ確認 → copywriter がコピー提案
- 詰まったエージェントがいればアドバイス

### 並行編集の安全ルール

5つの designer が同じ .pen ファイルに同時書き込みする。競合を防ぐため:
- 各 designer は**自分の割り当てフレーム内のみ**操作する
- 他の V{N} フレームへの Insert/Update/Delete は禁止
- `document` への直接 Insert は禁止（リーダーのみ）
- reviewer/copywriter は読み取り専用（`get_screenshot`, `batch_get` のみ）、書き込みは designer が行う
- プロンプトに「あなたの担当フレームID: {nodeId}」を必ず明記する

チーム内フロー:
1. ui-designer が `mcp__pencil__batch_design` でデザイン構築
2. ui-designer が `mcp__pencil__get_screenshot` で確認
3. ui-designer が reviewer と copywriter に完成通知
4. design-reviewer が `mcp__pencil__get_screenshot` でレビュー → フィードバック
5. copy-writer が `mcp__pencil__get_screenshot` でデザイン確認 → コピー提案
6. ui-designer が修正 → 最終版をリーダーに報告

## Step 6: 比較レポート生成

全チーム完了後:

1. 5つのフレームの `get_screenshot` を取得
2. [references/comparison-template.md](references/comparison-template.md) のテンプレートで比較レポート作成
3. 比較マトリクス（スコア表）を生成
4. ベストチョイスと組み合わせ提案を含める
5. `UI_VARIATIONS_REPORT.md` として出力

### 比較マトリクス

| 観点 | V1 | V2 | V3 | V4 | V5 |
|------|-----|-----|-----|-----|-----|
| ビジュアル品質 | /10 | /10 | /10 | /10 | /10 |
| UX | /10 | /10 | /10 | /10 | /10 |
| アクセシビリティ | /10 | /10 | /10 | /10 | /10 |
| プラットフォーム準拠 | /10 | /10 | /10 | /10 | /10 |
| コピー品質 | /10 | /10 | /10 | /10 | /10 |
| 初見理解度（アフォーダンス） | /10 | /10 | /10 | /10 | /10 |
| **総合** | /60 | /60 | /60 | /60 | /60 |

## Step 7: クリーンアップ

1. 全15エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete`

## Pencil テクニカルノート

designer のプロンプトに必ず含める:

- テキストの色は `fill` プロパティ（`textColor` は無効）
- `justifyContent` は `space_between`（アンダースコア、ハイフンではない）
- `batch_design` は最大25操作/コール
- Insert は必ずバインディング名が必要: `foo=I("parent", {...})`
- Copy した子ノードの更新は `descendants` プロパティ経由
- 画像は `G()` 操作（AI生成 or stock）
- 画像は frame/rectangle に fill として適用（image ノード型は無い）
- `filePath` パラメータは毎回必ず指定する
