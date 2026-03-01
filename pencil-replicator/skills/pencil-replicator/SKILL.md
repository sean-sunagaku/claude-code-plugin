---
name: pencil-replicator
description: >
  Chrome で表示中の Web 画面を Pencil (.pen) ファイルに高精度で再現する Agent Team スキル。
  3つの専門エージェント（screen-analyzer, design-builder, quality-reviewer）が
  分析→構築→品質検証のサイクルを回し、忠実な画面再現を実現する。
  Use when: Pencil で再現して、画面を Pencil に写して、Chrome を Pencil にコピー、
  pencil-replicate、デザインをキャプチャ、UI を Pencil に
---

# pencil-replicator

Chrome で表示中の Web 画面を Pencil (.pen) ファイルに高精度で再現する Agent Team スキル。

## 概要

このスキルは 3 つの専門エージェントが連携して動作する:

```
screen-analyzer  →  (chrome-analysis.md)  →  design-builder
                                                    ↕  (フィードバックループ)
                                              quality-reviewer
```

| エージェント | 役割 | MCP |
|---|---|---|
| screen-analyzer | Chrome 画面の構造・スタイル・テキストを徹底分析 | Chrome DevTools |
| design-builder | 分析結果に基づいて .pen ファイルを構築 | Pencil |
| quality-reviewer | Chrome vs Pencil の差分検出と修正指示 | Chrome DevTools + Pencil |

**精度目標**: quality-reviewer の 10点満点スコアが 7点以上（「見分けがつかない」レベル）

---

## Step 1: ヒアリング

ユーザーに以下を確認する:

1. **対象 URL**: Chrome で開いている画面の URL（例: `localhost:2626`）
2. **.pen ファイル**: 既存ファイルへの追加 か 新規作成 か
   - 既存ファイルの場合: ファイルパスを確認
   - 新規作成の場合: `new` を使用
3. **対象セクション**: 画面全体 か 特定のセクションのみか

確認できたら Step 2 へ。

---

## Step 2: リーダー（自分）の準備

ToolSearch で Pencil MCP をロードしてから以下を実行:

```
ToolSearch(query: "+pencil get_editor_state")
ToolSearch(query: "+pencil open_document")
ToolSearch(query: "+pencil get_style_guide_tags")
ToolSearch(query: "+pencil batch_get")
ToolSearch(query: "+pencil get_guidelines")
```

### 2-1. .pen ファイルの準備

```
# 新規作成の場合
mcp__pencil__open_document(filePathOrNew: "new")

# 既存ファイルを開く場合
mcp__pencil__open_document(filePathOrNew: "{ユーザー指定のパス}")

# 現在の状態確認
mcp__pencil__get_editor_state(include_schema: true)
```

### 2-2. スタイルガイドの取得・適用

```
mcp__pencil__get_style_guide_tags()
# → 適切なタグを選択（例: "web-app", "dashboard", "saas"）
mcp__pencil__get_style_guide(tags: ["web-app", ...])
```

### 2-3. コンポーネント一覧の取得

```
mcp__pencil__batch_get(
  patterns: [{"reusable": true}],
  readDepth: 2,
  searchDepth: 3
)
```

### 2-4. コンテキストファイルの書き出し

以下の情報を `.claude/pencil-replicator/pencil-context.md` に書き出す:

```markdown
# Pencil コンテキスト

## .pen ファイル情報
- パス: {path}
- ドキュメントID: {id}

## スタイルガイド
{get_style_guide の結果の主要情報}

## デザインシステムコンポーネント
{batch_get で取得したコンポーネント一覧（name, nodeId）}

## ガイドライン
{get_guidelines(topic: "web-app") の主要ルール}
```

### 2-5. 進捗ファイルの初期化

`.claude/pencil-replicator/progress.md` を作成する。Compaction 後もこのファイルを読めば現在地がわかるようにする。

```markdown
# 進捗状況

## 基本情報
- 対象 URL: {URL}
- .pen ファイル: {path}
- スクリーン ID: (未作成)

## セクション進捗
(画面分析後に更新)

## 既知の問題
(なし)
```

---

## Step 3: 複雑度の判定とモード選択

画面の複雑度に応じて作業モードを選択する:

| 複雑度 | 目安 | モード | 説明 |
|--------|------|--------|------|
| シンプル | 要素 20 個以下 | **直接作業** | team-lead が直接 Chrome 分析 + Pencil 構築 |
| 中程度 | 20-50 個 | **screen-analyzer + 直接構築** | 分析のみ screen-analyzer に委任 |
| 複雑 | 50 個以上 | **フルチーム** | 3エージェント全員起動 |

### 直接作業モード（シンプルな画面）

team-lead が自ら Chrome DevTools で分析し、Pencil で構築する。
agents/screen-analyzer.md と agents/design-builder.md の手順を参照しながら作業する。

```
1. ToolSearch で Chrome DevTools + Pencil MCP をロード
2. Chrome DevTools で画面のスクリーンショットを取得（参照画像として保持）
3. chrome-devtools で画面分析 → chrome-analysis.md に書き出し
4. UI要素インベントリ: スクリーンショットを見ながら全要素が分析に含まれているか確認
5. Pencil で構築（5-10 ops ずつ + Pencil スクショ確認）
6. 【必須】各セクション完成後に Chrome スクショ vs Pencil スクショの直接比較
   - 要素の過不足チェック（Chrome にあって Pencil にない要素はないか）
   - テキスト内容の一致チェック（原文をそのまま使っているか）
   - レイアウト・色・サイズの目視比較
7. 差異があれば即座に修正してから次のセクションへ
8. progress.md を随時更新
9. 全セクション完成後に全体スクショ比較で最終レビュー
```

**重要**: chrome-analysis.md はあくまで数値参考。Chrome 実画面との目視比較が最終的な品質保証。
分析ファイルだけを見て構築すると、分析漏れがそのまま再現漏れになる。

### フルチームモード（複雑な画面）

Step 4 に進む。

---

## Step 4: チーム作成とエージェント起動

### 4-1. チーム作成

```
TeamCreate(team_name: "pencil-replicator", description: "Chrome 画面を Pencil に再現するチーム")
```

### 4-2. タスク作成（依存関係あり）

```
TaskCreate("Chrome 画面分析", description: "Chrome DevTools で画面を徹底分析し chrome-analysis.md を生成")
# → Task ID: A

TaskCreate("Pencil 構造構築", description: "chrome-analysis.md を読んで .pen ファイルを構築", blockedBy: [A])
# → Task ID: B

TaskCreate("品質レビュー", description: "Chrome vs Pencil の差分検出・修正指示", blockedBy: [B])
# → Task ID: C
```

### 4-3. エージェント起動（逐次起動を推奨）

**重要**: 各エージェントは `subagent_type: "general-purpose"` で起動する（MCP ツールへのアクセスに必要）。起動時に agents/*.md の内容をプロンプトに含める。

**起動順序（逐次）**: screen-analyzer → 完了確認 → design-builder → 完了確認 → quality-reviewer

逐次起動のメリット:
- 各エージェントの成果物を team-lead が中間確認できる
- 依存関係の待機中にコンテキストを消費しない
- 不要なエージェントを起動しなくて済む

#### screen-analyzer の起動

```
Agent(
  subagent_type: "general-purpose",
  team_name: "pencil-replicator",
  name: "screen-analyzer",
  model: "opus",
  run_in_background: true,
  prompt: """
あなたは screen-analyzer です。pencil-replicator チームの一員として画面分析を担当します。

## あなたの役割とシステムプロンプト

{Read("~/.claude/skills/pencil-replicator/agents/screen-analyzer.md") の内容をここに貼り付ける}

## CSS → Pencil 変換マッピング

{Read("~/.claude/skills/pencil-replicator/references/css-mapping.md") の主要部分}

## 今回の作業

- 対象 URL: {URL}
- コンテキストファイル: .claude/pencil-replicator/
- チームメンバー: screen-analyzer（自分）, design-builder, quality-reviewer, team-lead

TaskList で自分のタスクを確認し、作業を開始してください。
"""
)
```

#### design-builder の起動

```
Agent(
  subagent_type: "general-purpose",
  team_name: "pencil-replicator",
  name: "design-builder",
  model: "opus",
  run_in_background: true,
  prompt: """
あなたは design-builder です。pencil-replicator チームの一員として Pencil 構築を担当します。

## あなたの役割とシステムプロンプト

{Read("~/.claude/skills/pencil-replicator/agents/design-builder.md") の内容をここに貼り付ける}

## CSS → Pencil 変換マッピング

{Read("~/.claude/skills/pencil-replicator/references/css-mapping.md") の主要部分}

## 今回の作業

- .pen ファイルパス: {path}
- コンテキストファイル: .claude/pencil-replicator/
- チームメンバー: screen-analyzer, design-builder（自分）, quality-reviewer, team-lead

TaskList で自分のタスクを確認し、blockedBy が解消されるまで待機してから作業を開始してください。
"""
)
```

#### quality-reviewer の起動

```
Agent(
  subagent_type: "general-purpose",
  team_name: "pencil-replicator",
  name: "quality-reviewer",
  model: "opus",
  run_in_background: true,
  prompt: """
あなたは quality-reviewer です。pencil-replicator チームの一員として品質検証を担当します。

## あなたの役割とシステムプロンプト

{Read("~/.claude/skills/pencil-replicator/agents/quality-reviewer.md") の内容をここに貼り付ける}

## レビューレポートテンプレート

{Read("~/.claude/skills/pencil-replicator/references/report-template.md") の内容}

## 今回の作業

- 対象 URL: {URL}
- .pen ファイルパス: {path}
- コンテキストファイル: .claude/pencil-replicator/
- チームメンバー: screen-analyzer, design-builder, quality-reviewer（自分）, team-lead

TaskList で自分のタスクを確認し、blockedBy が解消されるまで待機してから作業を開始してください。
"""
)
```

---

## Step 5: フィードバックループの監視

エージェントが自律的に作業する間、リーダーは以下を行う:

### 正常フロー

```
screen-analyzer:   Chrome 画面分析 → chrome-analysis.md 書き出し → design-builder に通知
design-builder:    chrome-analysis.md 読み込み → .pen 構築 → quality-reviewer に通知
quality-reviewer:  Chrome vs Pencil 比較 → スコアリング
  ├─ 7点以上: PASS → team-lead に報告
  └─ 6点以下: FAIL → design-builder に具体的な修正指示
       └─ design-builder: 修正 → quality-reviewer に再レビュー依頼（最大2往復）
```

### 介入すべきタイミング

以下の状況では team-lead が介入する:

- 同じ修正を 3 回以上繰り返している
- quality-reviewer の指摘が「もう少し大きく」など曖昧で design-builder が困っている
- MCP ツールのエラーが 2 回以上連続している
- 3 往復しても PASS が出ない

### 介入方法

```
SendMessage(type: "message", recipient: "{エージェント名}", content: "{具体的な指示}")
```

---

## Step 6: 最終確認（Chrome 実画面 vs Pencil 直接比較）

quality-reviewer から PASS 報告を受けたら（またはフルチームモードを使わない場合も）、
**必ず Chrome の実画面と Pencil のスクリーンショットを並べて目視確認する**。

```
# 1. Chrome で対象ページを表示
mcp__chrome-devtools__list_pages()
mcp__chrome-devtools__take_screenshot()  → Chrome 実画面

# 2. Pencil のスクリーンショットを取得
mcp__pencil__get_screenshot(nodeId: "{スクリーンのルートノードID}")  → Pencil 再現結果

# 3. 以下の7観点で比較
```

### 比較チェックリスト

| # | チェック項目 | 確認内容 |
|---|------------|---------|
| 1 | 要素の過不足 | Chrome にある全ての UI 要素が Pencil にも存在するか（逆も確認） |
| 2 | テキスト一致 | テキストが Chrome の原文と完全一致するか（言語・内容） |
| 3 | レイアウト | 要素の配置順序・方向・間隔が一致しているか |
| 4 | 色 | 背景色・テキスト色・ボーダー色が視覚的に同一か |
| 5 | タイポグラフィ | フォントサイズ・ウェイトが一致しているか |
| 6 | アイコン・装飾 | アイコンの種類・位置、角丸・シャドウが一致しているか |
| 7 | 全体印象 | ぱっと見で同じ画面に見えるか |

**差異が見つかった場合**:
1. 差異を特定（何が、どう違うか）
2. batch_design で修正
3. 再度スクリーンショット比較
4. 差異がなくなるまで繰り返す

2つの画像を見比べて **要素の過不足がなく、テキストが一致し、レイアウトが同等** であれば完了。

---

## Step 7: クリーンアップ

```
# 各エージェントにシャットダウン依頼
SendMessage(type: "shutdown_request", recipient: "screen-analyzer", content: "作業完了、シャットダウンをお願いします")
SendMessage(type: "shutdown_request", recipient: "design-builder", content: "作業完了、シャットダウンをお願いします")
SendMessage(type: "shutdown_request", recipient: "quality-reviewer", content: "作業完了、シャットダウンをお願いします")

# チーム削除
TeamDelete(name: "pencil-replicator")
```

---

## よくある問題と対処法

### MCP ツールが見つからない

各エージェントは `ToolSearch` で MCP ツールをロードする手順を持っている。ToolSearch の結果でツールが返ってこない場合は、Chrome/Pencil アプリが起動しているか確認する。

### screen-analyzer の分析が粗い

`evaluate_script` を使った JavaScript の実行結果が不完全な場合、より深い depth やより広い要素選択で再分析を依頼する。

### design-builder の構築が遅い

セクション数が多い場合、画面を上から下に 3 分割して段階的に構築するよう指示する。

### quality-reviewer のスコアが低い

chrome-analysis.md の CSS 値と Pencil のノード値を突き合わせて、どのプロパティがずれているか特定してから修正指示を出す。

### Compaction が走った場合

progress.md を読めば現在地がわかる。以下の手順で再開:

1. `.claude/pencil-replicator/progress.md` を読む
2. 「IN_PROGRESS」のセクションから作業を再開
3. 必要に応じてエージェントを再起動（完了済みセクションはスキップ）

### Pencil 既知の制限

以下は実際の構築で判明した制限。詳細は `references/css-mapping.md` のセクション 12 を参照。

- **linear-gradient()**: CSS 構文を `fill` にそのまま渡すと透明になる → Pencil 構造化構文 `{type: "gradient", gradientType: "linear", rotation: N, colors: [{color, position}]}` を使う
- **layout プロパティが Insert 時に消える**: `I()` で `layout: "horizontal"` を指定しても**サイレントに除外される**。`justifyContent`、`alignItems` も同様。**必ず `I()` の後に `U()` で再設定し、`batch_get` で保存を確認する**
- **icon_font の width/height がデフォルト 0**: `I()` で指定しても 0 になる場合がある → `U()` で明示的に再設定
- **textDecoration 非対応**: `"line-through"` 等は Pencil 非対応（サイレント除外）→ 完了状態はグレーテキスト色 + 緑チェックアイコンで代替表現
- **HTML エンティティがそのまま表示される**: `&quot;` `&amp;` がリテラル表示される → テキスト content にはシングルクォートや実文字を使う（`"Do Now"` → `'Do Now'`）
- **absolute positioning 不可**: `position: "absolute"`, `right`, `bottom` は動作しない。x/y は flexbox layout 内では無視される → FAB 等のフローティング要素は「親を `layout: "vertical"` + `alignItems: "center"` にして最後の子要素にする」パターンで対応
- **fill_container が alignItems: "center" を override しない**: 親が `alignItems: "center"` の場合、子の `width: "fill_container"` だけでは横幅が伸びない → `alignSelf: "stretch"` を併用する
- **flexWrap**: 動作が不安定 → 明示的に Row 1, Row 2 に分割する
- **batch_get の結果**: 大量データの場合ファイルに保存される → 必要な部分だけ抽出して使う

### テキスト内容の取得ルール

**Chrome の表示テキストを推測で書かない。必ず以下のいずれかから取得する:**

1. **Chrome 実画面**（最優先）: DevTools や Claude in Chrome でテキストを直接コピー
2. **i18n ファイル**（Chrome 非接続時）: アプリの `messages/ja.json` 等のローカライゼーションファイルから正確なキーと値を取得
3. **ソースコード**（上記が不可能な場合）: コンポーネントの `t("key")` 呼び出しから i18n キーを特定し、翻訳ファイルと照合

**よくある失敗パターン**:
- 英語テキストを使ったが実際のアプリは日本語だった（"In Progress" → 正しくは "実行中"）
- ステータス名を推測で書いたが DB に保存された実際の名前と異なっていた
- プレースホルダーテキストを創作したが i18n に定義された正式なテキストがあった

---

## 参照ファイル

- `agents/screen-analyzer.md`: 画面分析エージェントの詳細定義
- `agents/design-builder.md`: Pencil 構築エージェントの詳細定義
- `agents/quality-reviewer.md`: 品質検証エージェントの詳細定義
- `references/css-mapping.md`: CSS → Pencil プロパティ変換マッピング
- `references/icon-mapping.md`: lucide-react → Pencil icon_font 変換マッピング
- `references/report-template.md`: quality-reviewer レビューレポートテンプレート
