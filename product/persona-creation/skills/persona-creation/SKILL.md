---
name: persona-creation
description: >
  UX/マーケティング向けのユーザーペルソナを、5つの専門エージェントチームで作成するスキル。
  ペルソナ設計、ユーザーリサーチ、ナラティブ執筆、バイアスレビュー、コンテキスト管理の
  5観点からペルソナを議論・作成し、Markdownドキュメントとして出力する。
  コンテキストファイルで過去のセッションを引き継げる。
  Use when: ユーザーペルソナを作りたい、ターゲットユーザーを定義したい、
  ペルソナシートを作成したい、UXリサーチ用のペルソナが必要、
  マーケティング用のターゲット分析をしたい。
  Triggers: "ペルソナ", "persona", "ターゲットユーザー", "target user",
  "ユーザー像", "ユーザー定義", "user profile", "ペルソナシート",
  "ターゲット分析", "ユーザーセグメント", "customer profile"
---

# Persona Creation Skill

5つの専門エージェントがチームで議論し、UX/マーケティング向けのユーザーペルソナを作成する。
コンテキストファイルで過去のセッションを引き継ぎ、反復的にペルソナを改善できる。

## ワークフロー

1. ユーザーからプロダクト情報をヒアリング
2. Agent Team を作成し、5エージェントを並列起動
3. リサーチ → ペルソナ設計 → 執筆 → バイアスレビュー → 最終化
4. ペルソナドキュメント + 最終レポートを MD で出力

## コンテキストファイル構成

```
.claude/persona-creation/{YYYY-MM-DD}_{project}/
├── context.md              <- 全体コンテキスト（プロダクト情報・学びの蓄積）
├── SUMMARY.md              <- 全ラウンドを横断するサマリー
├── personas/
│   ├── persona-01.md       <- ペルソナプロファイル
│   ├── persona-02.md
│   └── ...
└── round-{N}/
    ├── context.md          <- このラウンドの目的・制約
    ├── log.md              <- このラウンドの議事録
    └── segments.md         <- ユーザーセグメントと評価結果
```

## Step 1: ヒアリング

以下を確認する（不明ならユーザーに質問）:

- **プロダクト概要**: 何をするサービス/アプリか、コア機能
- **ターゲット市場**: 国・地域、言語、年齢層
- **既存ユーザー情報**: 分析データ、インタビュー結果があれば
- **ペルソナの用途**: UXデザイン / マーケティング / プロダクト開発 / 投資家向け
- **作成したいペルソナの数**: 3〜5体を推奨
- **重視する属性**: デモグラフィック / 行動パターン / 心理特性 / 課題
- **既知のセグメント**: すでに想定しているユーザー層があれば

## Step 2: チーム作成とエージェント起動

TeamCreate で `persona-creation` チームを作成。以下5エージェントを **1つのメッセージで並列に** Task ツールで起動する。

| name | 役割 | 主な手段 |
|------|------|---------|
| `persona-architect` | ペルソナ設計・セグメント定義・フレームワーク策定 | 分析 |
| `user-researcher` | 市場調査・ユーザー行動リサーチ・データ裏付け | WebSearch |
| `persona-writer` | ペルソナナラティブ・プロファイル執筆 | Write/Edit |
| `bias-reviewer` | バイアス・ステレオタイプ・多様性チェック | 分析 |
| `context-manager` | コンテキストファイル・議事録の管理 | Write/Edit |

各エージェントは `agents/` ディレクトリにサブエージェントとして定義済み。

### タスク作成

TaskCreate で6つのタスクを作成:

1. context-manager: コンテキストファイルの初期作成
2. persona-architect: セグメント設計・ペルソナフレームワーク策定（`addBlockedBy: ["1"]`）
3. user-researcher: 市場・ユーザー行動リサーチ（`addBlockedBy: ["1"]`）- リサーチ結果を `round-01/research-data.md` に書き出すこと。Phase 2 でセグメント別データを persona-writer に提供
4. persona-writer: ペルソナプロファイル執筆（`addBlockedBy: ["2"]`）- セグメント確定後すぐに執筆開始。リサーチデータは届き次第取り込む
5. bias-reviewer: バイアス・多様性レビュー（`addBlockedBy: ["1"]`）- セグメント設計を即レビュー + 各ペルソナを完成次第レビュー（ストリーミング）
6. 統合レポート + 最終ペルソナ確定（`addBlockedBy: ["1","2","3","4","5"]`）

### 起動設定

```
subagent_type: "persona-architect"  # agents/ で定義済み
team_name: "persona-creation"
mode: "bypassPermissions"
run_in_background: true
```

プロンプトに含める情報（全エージェント共通）:
- プロダクト概要、ターゲット市場、ペルソナの用途
- **ベースディレクトリの絶対パス**（⚠️必須）: `init.sh` が出力する絶対パスをそのまま使う
  - 例: `/Users/babashunsuke/.claude/persona-creation/2026-02-21_miravy/`
  - ⚠️ Write ツールは絶対パスのみ受け付ける。`.claude/...` のような相対パスは動作しない
  - 全エージェントのプロンプトに「ファイル書き込み時はこの絶対パスをベースにしてください」と明記する
- 既存の context.md がある場合はその内容も含める
- **ファイル書き込み注意**: 「init.sh はディレクトリのみ作成し、テンプレートファイルは作成しない。全てのファイルはあなたが Write ツールで新規作成する必要がある」と明記する
- **ペルソナファイル命名規則**: persona-writer のプロンプトにファイル名を明示する（`persona-01.md`, `persona-02.md`, ... のゼロ埋め2桁。`persona-1.md` 形式は禁止）

## Step 3: エージェント間フィードバックループ

### フィードバックプロトコル（全エージェント共通ルール）

1. **自分の作業が完了したら即座に関連エージェントへ共有**
2. **実質的な内容のある返信のみ送る** - 「了解しました」「ありがとうございます」だけのACKメッセージは不要。フィードバック・質問・修正報告など、相手の次のアクションに繋がる内容がある場合のみ返信する
3. **バイアス問題は即座に警告**: bias-reviewer は問題発見次第すぐ全員に通知
4. **フィードバックを受けたら修正し、変更内容を共有する**
5. **待ちすぎない**: フィードバックを全員から集める必要はない。2人以上から反応があれば次のフェーズに進んでよい
6. **全成果物は必ずファイルに書き出す** - SendMessage だけで完了としない。Write ツールでファイルに書き込み → Read ツールで検証 → その後に SendMessage で報告

### 緊急通知パターン（即座に全員へ共有すべき事項）

- **bias-reviewer**: ステレオタイプ・差別的表現を発見 → 該当ペルソナの修正を即依頼
- **user-researcher**: セグメント仮説を否定するデータを発見 → persona-architect に再設計を依頼
- **persona-architect**: セグメント間の重大な重複を発見 → 全員に統合/分割の提案
- **context-manager**: ファイル書き込みの競合を検知 → 該当エージェントに待機を依頼

```
[全員へ] ⚠️ 緊急: {問題の概要}
理由: {具体的理由}
→ {対応すべきエージェント}: {具体的なアクション}を実施してください。
→ context-manager: この問題をログに記録してください。
```

### Round 1: セグメント設計とリサーチ（並列進行）

```
[persona-architect]
  -> 全員に: ユーザーセグメント案（3〜5セグメント）を送信
  -> user-researcher: 「各セグメントの市場規模やトレンドを調査してください」

[user-researcher]
  -> persona-architect に: リサーチ結果・データ裏付け
  -> 全員に: 市場トレンド・ユーザー行動データ（ファイル出力 + 要約メッセージ）

[bias-reviewer]
  -> persona-architect に: セグメント設計のバイアスチェック結果（即座に）
```

### Round 2: ペルソナ執筆（並列レビュー）

```
[persona-writer]
  -> セグメント確定後すぐに執筆開始（リサーチデータは届き次第取り込み）
  -> 1体完成ごとに全員に共有

[user-researcher]
  -> persona-writer に: セグメント別の詳細データをプロアクティブに提供

[bias-reviewer]
  -> 1体完成ごとにストリーミングレビュー → persona-writer にフィードバック

[persona-architect]
  -> 1体完成ごとにフレームワーク準拠チェック → persona-writer にフィードバック
```

### Round 3: 最終チェックと多様性レビュー

```
[bias-reviewer]
  -> 全員に: 最終多様性レビュー結果（全ペルソナ横断）

[user-researcher]
  -> 全ペルソナのデータ整合性を最終チェック

[persona-architect]
  -> 全ペルソナの一貫性・フレームワーク準拠を最終チェック

context-manager -> 全員に: SUMMARY.md 作成完了を通知
```

## Step 3.5: ファイル書き込み検証（チームリーダー必須）

全エージェントのタスクが completed になった後、最終レポート作成の**前に**以下のファイル存在を検証する。テンプレートのままや空のファイルは「書き込み失敗」と判断する。

```bash
# 検証対象ファイル（全て実体があること）
.claude/persona-creation/{date}_{project}/
├── context.md              <- context-manager が書き込み
├── SUMMARY.md              <- context-manager が書き込み
├── personas/
│   ├── persona-01.md       <- persona-writer が書き込み（内容があること）
│   ├── persona-02.md
│   └── ...
└── round-01/
    ├── context.md          <- context-manager が書き込み
    ├── log.md              <- context-manager が書き込み
    ├── segments.md         <- persona-architect が書き込み
    ├── research-data.md    <- user-researcher が書き込み
    └── bias-review.md      <- bias-reviewer が書き込み
```

**検証手順**:
1. Glob で `personas/*.md` のファイル数を確認（期待するペルソナ数と一致するか）
2. 各ファイルを Read して、テンプレートのまま・空でないことを確認
3. **不足・空のファイルがあった場合**:
   - まず該当エージェントに SendMessage で「Write ツールでファイルに書き込んでください」と依頼
   - **エージェントが応答しない、またはシャットダウン済みの場合**: ディスカッションログからエージェントの SendMessage 内容を抽出し、オーケストレーター自身が Write ツールで書き込む（フォールバック書き込み）
4. 全ファイルの実体を確認できたら Step 4 に進む

**フォールバック書き込みの手順**（エージェントがファイルを書けなかった場合）:
1. ディスカッションログ（`.claude/agent-teams-log/{session}/discussion.md`）を Read
2. 各エージェントの SendMessage 内容からペルソナ本文・セグメント設計・リサーチデータ・レビュー結果を抽出
3. 適切なパスに Write で書き込み
4. Read で書き込み結果を検証

## Step 4: 最終レポート出力

全報告が揃ったら統合レポートを MD で出力する。テンプレートは [references/report-template.md](references/report-template.md) を参照。
ペルソナプロファイルのテンプレートは [references/persona-template.md](references/persona-template.md) を参照。

出力先: プロジェクトルートに `PERSONAS_REPORT.md`

レポートに含める:
- 作成したペルソナの一覧と概要
- 各ペルソナの詳細プロファイルへのリンク
- セグメント設計の根拠
- リサーチデータの裏付け
- バイアスレビュー結果
- ペルソナの活用方法の提案

## Step 5: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除

---

## Shell Scripts リファレンス

### init.sh - プロジェクト初期化

```bash
bash scripts/init.sh <project-name>

# 例
bash scripts/init.sh miravy
# -> .claude/persona-creation/2026-02-20_miravy/ を作成
```

### new-round.sh - 新ラウンド作成

```bash
bash scripts/new-round.sh <project-dir>

# 例
bash scripts/new-round.sh ~/.claude/persona-creation/2026-02-20_miravy
# -> round-02/ を作成
```
