---
name: user-story-visualizer
description: >
  ユーザーストーリーを可視化する専門スキル。6つの専門エージェントチームで、
  ジャーニーマップの分析から Pencil (.pen) ビジュアル出力まで一気通貫で実行する。
  プロダクト情報とターゲットユーザーを入力し、認知→検討→初回利用→習慣化→推薦の
  5フェーズで行動・思考・感情・接点・機能・課題・機会・Devアクションを構造化し、
  Markdownドキュメントと Pencil ビジュアルジャーニーマップを出力する。
  離脱トリガー分析を強化し、ペインポイントと機会を視覚的に強調する。
  ペルソナファイルがあれば自動読み込み、なければ手動入力でも動作する。
  Use when: ジャーニーマップを可視化したい、ユーザー体験を図で表現したい、
  カスタマージャーニーをビジュアル化したい、離脱要因を分析したい、
  UXフローを .pen ファイルで出力したい。
  Triggers: "ジャーニー", "journey", "ジャーニーマップ", "journey map",
  "ユーザー体験", "user journey", "UXフロー", "体験設計",
  "カスタマージャーニー", "customer journey", "可視化", "visualize",
  "user story", "ユーザーストーリー", "離脱分析", "drop-off"
---

# User Story Visualizer Skill

6つの専門エージェントがチームで議論し、ユーザージャーニーマップを作成・可視化する。
ペルソナファイルがあれば自動連携するが、手動入力のみでも動作する独立スキル。
Markdown ドキュメントに加え、Pencil (.pen) によるビジュアルマップも出力する。

## ワークフロー

1. ユーザーからプロダクト情報とターゲットユーザーをヒアリング
2. Agent Team を作成し、6エージェントを並列起動
3. フレームワーク設計 → リサーチ → ジャーニー執筆 → クロス分析
4. Pencil ビジュアルマップ生成（journey-visualizer）
5. ジャーニーマップ + クロス分析 + 開発ロードマップ + .pen ファイルを出力

## 出力ディレクトリ構成

```
.claude/user-story-visualizer/{YYYY-MM-DD}_{project}/
├── context.md              <- プロダクト情報・ユーザータイプ一覧
├── log.md                  <- 議事録
├── research-data.md        <- タッチポイント・行動パターン・離脱トリガー調査
├── journeys/
│   ├── journey-01.md       <- ユーザータイプ1のジャーニーマップ（離脱トリガー含む）
│   ├── journey-02.md
│   └── ...
├── insights/
│   ├── cross-analysis.md   <- 全ジャーニー横断分析
│   └── dev-roadmap.md      <- 優先度付き開発ロードマップ
└── visuals/
    └── journey-map.pen     <- Pencil ビジュアルジャーニーマップ
```

## Step 1: ヒアリング

以下を確認する（不明ならユーザーに質問）:

- **プロダクト概要**: 何をするサービス/アプリか、コア機能
- **ターゲット市場**: 国・地域、言語、年齢層
- **ターゲットユーザータイプ**: 3〜5タイプを推奨。各タイプの特徴:
  - 名前（ラベル）
  - 年齢層
  - 職業
  - デジタルリテラシー（高/中/低）
  - 主な課題・目標
- **重視するフェーズ**: 全フェーズか、特定フェーズを深掘りするか
- **既存のペルソナファイル**: あれば自動読み込みする
- **離脱分析の重点**: どのフェーズの離脱を特に重視するか

### ペルソナファイル自動検出（オプション）

ペルソナファイルがある場合:
1. Glob で `~/.claude/persona-creation/*/personas/persona-*.md` を検索
2. 最新セッション（日付プレフィックス順）を選択
3. 各ペルソナファイルからユーザータイプ情報を抽出
4. ユーザーに確認: 「これらのペルソナをベースにジャーニーを作成しますか？」

## Step 2: チーム作成とエージェント起動

TeamCreate で `user-story-visualizer` チームを作成。以下6エージェントを **1つのメッセージで並列に** Task ツールで起動する。

| name | 役割 | 主な手段 |
|------|------|---------|
| `context-manager` | コンテキストファイル・議事録の管理 | Write/Edit |
| `journey-architect` | フレームワーク設計・品質管理・離脱トリガー分析 | 分析 |
| `ux-researcher` | タッチポイント・行動パターン・離脱トリガー調査 | WebSearch, Write |
| `journey-writer` | ジャーニーマップ執筆（離脱トリガーセクション含む） | Write/Edit |
| `insight-analyst` | クロス分析・開発ロードマップ | Write/Edit |
| `journey-visualizer` | Pencil ビジュアルジャーニーマップ生成 | Pencil MCP |

各エージェントは `agents/` ディレクトリにサブエージェントとして定義済み。

### タスク作成

TaskCreate で7つのタスクを作成:

1. context-manager: コンテキストファイルの初期作成
2. journey-architect: フレームワーク設計（`addBlockedBy: ["1"]`）
3. ux-researcher: タッチポイント・行動パターン・離脱トリガー調査（`addBlockedBy: ["1"]`）
4. journey-writer: ジャーニーマップ執筆（`addBlockedBy: ["2"]`）- フレームワーク確定後すぐに開始。リサーチデータは届き次第取り込む
5. insight-analyst: クロス分析・開発ロードマップ（`addBlockedBy: ["4"]`）- 全ジャーニー完成後に開始
6. journey-visualizer: Pencil ビジュアルマップ生成（`addBlockedBy: ["4"]`）- 全ジャーニー完成後に開始
7. 統合レポート + 最終確定（`addBlockedBy: ["1","2","3","4","5","6"]`）

### 起動設定

```
subagent_type: "context-manager"  # agents/ で定義済み
team_name: "user-story-visualizer"
mode: "bypassPermissions"
run_in_background: true
```

プロンプトに含める情報（全エージェント共通）:
- プロダクト概要、ターゲット市場、ユーザータイプ情報
- **ベースディレクトリの絶対パス**（⚠️必須）: `init.sh` が出力する絶対パスをそのまま使う
  - 例: `/Users/babashunsuke/Desktop/miravy/.claude/user-story-visualizer/2026-02-21_miravy/`
  - ⚠️ Write ツールは絶対パスのみ受け付ける。`.claude/...` のような相対パスは動作しない
- **ファイル書き込み注意**: 「init.sh はディレクトリのみ作成し、テンプレートファイルは作成しない。全てのファイルはあなたが Write ツールで新規作成する必要がある」と明記する
- **ジャーニーファイル命名規則**: journey-writer のプロンプトにファイル名を明示する（`journey-01.md`, `journey-02.md`, ... のゼロ埋め2桁。`journey-1.md` 形式は禁止）
- **journey-visualizer 向け**: `visuals/` ディレクトリの絶対パスと `.pen` ファイル名を指定する

## Step 3: エージェント間フィードバックループ

### フィードバックプロトコル（全エージェント共通ルール）

1. **自分の作業が完了したら即座に関連エージェントへ共有**
2. **実質的な内容のある返信のみ送る** - ACKメッセージは不要
3. **フィードバックを受けたら修正し、変更内容を共有する**
4. **待ちすぎない**: 2人以上から反応があれば次のフェーズに進んでよい
5. **全成果物は必ずファイルに書き出す** - Write → Read → SendMessage の順序厳守

### Round 1: フレームワーク設計 + リサーチ（並列進行）

```
[journey-architect]
  -> 全員に: 5フェーズ×8行のマッピングルール + 離脱トリガー分析フレームワーク
  -> journey-writer: 「このフレームワークに従って執筆してください」
  -> ux-researcher: 「各ユーザータイプのタッチポイントと離脱トリガーを調査してください」

[ux-researcher]
  -> journey-writer に: リサーチデータ（ファイル + 要約メッセージ）
  -> journey-architect に: タッチポイント・離脱トリガー調査結果

[context-manager]
  -> 全員に: context.md, log.md 作成完了通知
```

### Round 2: ジャーニー執筆（並列レビュー）

```
[journey-writer]
  -> 1体完成ごとに全員に共有
  -> journey-architect: フレームワーク準拠チェック依頼
  -> ux-researcher: リサーチデータ整合性チェック依頼

[journey-architect]
  -> 1体完成ごとにレビュー → journey-writer にフィードバック

[ux-researcher]
  -> タッチポイント整合性を確認 → journey-writer にフィードバック
```

### Round 3: クロス分析 + 開発ロードマップ + ビジュアル生成（並列）

```
[insight-analyst]
  -> 全ジャーニー読み込み → クロス分析 → 開発ロードマップ
  -> チームリーダーに完了報告

[journey-visualizer]
  -> 全ジャーニーファイルを読み込み → Pencil でビジュアルマップ生成
  -> チームリーダーに完了報告（.pen ファイルパスを添付）

[context-manager]
  -> log.md を最終更新
```

## Step 3.5: ファイル書き込み検証（チームリーダー必須）

全エージェントのタスクが completed になった後、最終レポート作成の**前に**ファイル存在を検証する。

```
user-story-visualizer/{date}_{project}/
├── context.md              <- context-manager
├── log.md                  <- context-manager
├── research-data.md        <- ux-researcher
├── journeys/
│   ├── journey-01.md       <- journey-writer（内容があること）
│   ├── journey-02.md
│   └── ...
├── insights/
│   ├── cross-analysis.md   <- insight-analyst
│   └── dev-roadmap.md      <- insight-analyst
└── visuals/
    └── journey-map.pen     <- journey-visualizer
```

**検証手順**:
1. Glob で `journeys/*.md` のファイル数を確認（ユーザータイプ数と一致するか）
2. 各ファイルを Read して、空でないことを確認
3. `visuals/journey-map.pen` の存在を確認
4. **不足・空のファイルがあった場合**: 該当エージェントに SendMessage で催促、応答なければフォールバック書き込み

## Step 4: 最終レポート出力

全ファイルが揃ったら `JOURNEY_REPORT.md` をプロジェクトルートに出力する。

レポートに含める:
- 作成したジャーニーマップの一覧と概要
- 各ジャーニーの要約（テーブル形式）
- 離脱トリガー分析のサマリー
- クロス分析のハイライト
- 開発ロードマップの優先度 P0 施策
- Pencil ビジュアルマップのパス（`visuals/journey-map.pen`）
- 各ファイルへのパスリンク

## Step 5: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除

---

## リファレンスファイル

- [references/journey-template.md](references/journey-template.md) - ジャーニーマップのテンプレート（8行×5フェーズ + 離脱トリガー分析）
- [references/pencil-layout-guide.md](references/pencil-layout-guide.md) - Pencil ビジュアルマップのレイアウトガイド

## Shell Scripts リファレンス

### init.sh - プロジェクト初期化

```bash
bash scripts/init.sh <project-name>

# 例
bash scripts/init.sh miravy
# -> .claude/user-story-visualizer/2026-02-21_miravy/ を作成（カレントディレクトリ直下）
# visuals/ ディレクトリも含めて作成される
```
