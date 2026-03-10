---
name: arch-review
description: >
  コードベースのアーキテクチャを 6 つの専門エージェントチーム（Claude 5体 + Codex 1体）で
  多角的に分析し、リスク・デグレしやすい箇所・改善ポイントを洗い出すスキル。
  パフォーマンス、スケーラビリティ、信頼性、セキュリティ、運用、DX、データ整合性、依存関係の
  8 観点を 5 グループに分担し、さらに Codex がクロスカットレビュアーとして横断分析する。
  エージェント同士が反論・補足・自由な議論を行い、合意形成した結果をレポートとして出力する。
  どのプロジェクトでも使える汎用スキル。
  Use when: アーキテクチャを分析したい、リファクタリング前にリスクを把握したい、
  デグレしやすい箇所を知りたい、コードの健全性を確認したい、大きめの実装前に注意点を洗い出したい、
  技術的負債を可視化したい、コードベースの品質を監査したい。
  Triggers: "arch review", "アーキテクチャ分析", "アーキテクチャレビュー",
  "リスク分析", "コード監査", "codebase audit", "技術的負債",
  "デグレしやすい", "architecture analysis", "risk analysis",
  "コードの健全性", "品質チェック", "実装前の確認"
---

# Architecture Review

6 つの専門エージェントがコードベースを多角的に分析し、議論を通じてリスクと改善点を洗い出す。

## ワークフロー概要

```
Step 1: ヒアリング（対象ディレクトリ・重点観点の確認）
Step 2: コードベース偵察（リーダーがプロジェクト構造を把握）
Step 3: チーム起動 & 並列分析（Round 1 - 6体が独立に分析）
Step 4: クロスレビュー議論（Round 2-3 - 反論・補足・合意形成）
Step 5: レポート統合 & 出力
Step 6: クリーンアップ
```

## Step 1: ヒアリング

以下を確認する（不明ならユーザーに質問）:

- **分析対象**: プロジェクトディレクトリ（デフォルト: cwd）
- **重点観点**: 特に気になる領域があるか（なければ全観点でフル分析）
- **スコープ**: 全体分析か、特定ディレクトリ/モジュールに絞るか

## Step 2: コードベース偵察

リーダー（メインの Claude）がプロジェクト構造を走査する:

1. `ls` でトップレベル構造を確認
2. `package.json`, `tsconfig.json`, `Cargo.toml`, `go.mod` 等の設定ファイルを Read
3. 主要なエントリポイントやディレクトリ構成を把握
4. 以下の「プロジェクトコンテキスト」をテキストとしてまとめる:

```
プロジェクトコンテキスト:
- プロジェクト名: {name}
- 言語/フレームワーク: {tech stack}
- ディレクトリ構成: {tree overview}
- 主要エントリポイント: {paths}
- 設定ファイル: {paths}
- テストの有無: {yes/no, framework}
- 特記事項: {CLAUDE.md や README から得た情報}
```

## Step 3: チーム起動 & 並列分析（Round 1）

TeamCreate で `arch-review` チームを作成。6 体のエージェントを **1 つのメッセージで並列に** TaskCreate で起動する。

### エージェント構成

| # | name | 担当 | subagent_type | 分析対象 |
|---|------|------|---------------|----------|
| 1 | `perf-scale-analyst` | パフォーマンス + スケーラビリティ | `arch-review:perf-scale-analyst` | ボトルネック、レイテンシ、密結合、スケール限界 |
| 2 | `reliability-analyst` | 信頼性 + デグレ耐性 | `arch-review:reliability-analyst` | テスト不足、型安全性、壊れやすい箇所、エラーハンドリング |
| 3 | `security-analyst` | セキュリティ | `arch-review:security-analyst` | インジェクション、認証/認可、機密情報、入力検証 |
| 4 | `ops-dx-analyst` | 運用 + DX | `arch-review:ops-dx-analyst` | ログ、可観測性、デバッグ性、コード規約、命名 |
| 5 | `data-deps-analyst` | データ整合性 + 依存関係 | `arch-review:data-deps-analyst` | 状態管理、キャッシュ、ライブラリ版管理、EOL 依存 |
| 6 | `codex-reviewer` | クロスカットレビュー | `general-purpose` | Codex CLI で横断分析、見落とし検出 |

### タスク作成

TaskCreate で 8 つのタスクを作成:

1. `perf-scale-analyst`: パフォーマンス + スケーラビリティ分析（依存なし）
2. `reliability-analyst`: 信頼性 + デグレ耐性分析（依存なし）
3. `security-analyst`: セキュリティ分析（依存なし）
4. `ops-dx-analyst`: 運用 + DX 分析（依存なし）
5. `data-deps-analyst`: データ整合性 + 依存関係分析（依存なし）
6. `codex-reviewer`: Codex によるクロスカット分析（依存なし）
7. クロスレビュー議論: 全エージェントの findings を共有し議論（`addBlockedBy: ["1","2","3","4","5","6"]`）
8. 最終レポート統合: リーダーが統合レポートを作成（`addBlockedBy: ["7"]`）

### 起動設定（Agent 1-5）

```
subagent_type: "arch-review:{role-name}"
team_name: "arch-review"
mode: "bypassPermissions"
run_in_background: true
```

### 起動設定（Agent 6: Codex）

```
subagent_type: "general-purpose"
team_name: "arch-review"
mode: "bypassPermissions"
run_in_background: true
```

### プロンプトに含める情報（全エージェント共通）

- Step 2 で作成したプロジェクトコンテキスト全文
- 分析対象ディレクトリの絶対パス
- ユーザーが指定した重点観点（あれば）
- findings の出力先パス: `{project-dir}/docs/.arch-review-workspace/{role-name}-findings.md`
- 「findings は必ず Write ツールで絶対パスに書き込むこと」を明記

## Step 4: クロスレビュー議論（Round 2-3）

全エージェントの Round 1 分析が完了したら、クロスレビューを開始する。

### Round 2: クロスレビュー

各エージェントに他の全 findings ファイルのパスを SendMessage で通知し、以下を指示:

1. 他のエージェントの findings を Read で読む
2. 自分の観点から **反論・補足・相互作用の指摘** を行う
3. 具体例:
   - perf-scale:「この密結合はスケーラビリティの問題」→ reliability:「テスト不足でデグレリスクも高い」
   - security:「入力検証なし」→ data-deps:「状態管理にも波及する」
   - codex-reviewer: Claude 5 体の findings にない観点を指摘
4. フィードバックは SendMessage で直接相手に送る
5. 重要な発見は自分の findings ファイルに追記する

### Round 3: 収束

1. 反論への再反論、優先度の議論
2. 重要度（Critical / Warning / Info）の合意形成
3. 矛盾する指摘があれば議論して解決
4. Codex 独自の指摘について Claude エージェントが検証・議論
5. 各エージェントが最終版の findings を Write で更新

### 議論のルール

- **ACK 返信不要**: 「了解しました」だけのメッセージは送らない
- **実質的な内容のみ**: 相手の次アクションに繋がるフィードバックのみ送る
- **待ちすぎない**: 2 人以上から反応があれば次に進む
- **自由に議論**: 反論・再反論・補足・質問、何でもOK。深い議論を推奨

## Step 5: レポート統合 & 出力

全エージェントの議論が収束したら、リーダーが統合レポートを作成する。

1. 全 findings ファイルを Read
2. レポートテンプレート [references/report-template.md](references/report-template.md) に従ってレポートを生成
3. 重要度順（Critical → Warning → Info）にソート
4. `docs/arch-review-YYYY-MM-DD.md` に Write で保存
5. ワークスペースの一時ファイルを削除: `rm -rf docs/.arch-review-workspace/`
6. 端末に Executive Summary と Critical findings を表示

## Step 6: クリーンアップ

1. 全エージェントに `shutdown_request` を SendMessage で送信
2. 全員シャットダウン後に `TeamDelete` で `arch-review` チームを削除
