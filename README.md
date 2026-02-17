# Claude Code Plugin

![Skills](https://img.shields.io/badge/skills-9-blue) ![License](https://img.shields.io/badge/license-MIT-green)

Claude Code の開発ワークフローを強化するスキルプラグイン集。

## Install

```bash
claude plugin add github:sean-sunagaku/claude-code-plugin
```

Or use the slash command inside Claude Code:

```
/plugin marketplace add sean-sunagaku/claude-code-plugin
```

## Quick Start

インストール後、Claude Code で `/` を入力するとスキル一覧が表示されます。

```
# 例: Git ワークフローを実行
/git-workflow

# 例: 3つの AI でコードレビュー
/multi-ai-review

# 例: マルチエージェントでタスク実行
/agent-team
```

> 一部のスキルは外部ツール（Codex CLI, Gemini CLI 等）が必要です。
> 詳しくは [Prerequisites](#prerequisites) を参照してください。

## Skills

| Skill | Command | Description | Keywords |
|-------|---------|-------------|----------|
| **multi-ai-review** | `/multi-ai-review` | Codex, Gemini, Claude の3つの AI に並列でコードレビューを依頼し、統合レポートを生成する | `code-review, multi-ai, codex, gemini, claude, parallel` |
| **plan-review** | `/plan-review` | Codex, Gemini, Claude の3つの AI で Plan ファイルを並列レビュー。実装計画の妥当性、抜け漏れ、リスクを分析する | `plan-review, multi-ai, architecture, risk-analysis` |
| **agent-team** | `/agent-team` | Multi-agent team orchestration for parallel task execution, research, and implementation | `agent, team, parallel, orchestration, swarm` |
| **git-workflow** | `/git-workflow` | ブランチ作成、Conventional Commits コミット、PR 作成までの Git ワークフローを自動化 | `git, workflow, commit, pull-request, conventional-commits` |
| **ci-check** | `/ci-check` | 全パッケージの lint, format, test, audit を一括実行し、エラーがあれば修正する | `ci, lint, format, test, audit, automation` |
| **ui-verify** | `/ui-verify` | Chrome DevTools でフロントエンドの動作確認。起動中サーバーを自動検出し操作・デバッグ・パフォーマンス分析を実行 | `ui, testing, chrome-devtools, verification, e2e` |
| **spec-test** | `/spec-test` | 仕様駆動設計。仕様書からクラス責務を分析し、純粋関数を特定、テストファーストで単体テストを設計する | `spec, test, tdd, test-first, pure-function, design` |
| **database** | `/database` | Drizzle ORM を使ったデータベーススキーマの管理とマイグレーションガイド | `database, drizzle, orm, migration, sqlite` |
| **app-naming** | `/app-naming` | 4つの専門エージェント（ブランディング・商標・デジタルプレゼンス・国際展開）がチームで議論し、最適なアプリ名・サービス名を決定する | `naming, branding, trademark, app-name, agent-team, SEO, ASO` |

## Skill Details

### multi-ai-review

Codex, Gemini, Claude の3つの AI に並列でコードレビューを依頼し、統合レポートを生成する

Codex、Gemini、Claudeの3つのAIに並列でコードレビューを依頼し、統合レポートを生成する。

```
/multi-ai-review
```

### plan-review

Codex, Gemini, Claude の3つの AI で Plan ファイルを並列レビュー。実装計画の妥当性、抜け漏れ、リスクを分析する

Codex、Gemini、Claude を使って Plan ファイルを並列レビューし、実装前に計画の品質を確認する。

```
/plan-review
```

### agent-team

Multi-agent team orchestration for parallel task execution, research, and implementation

Orchestrate multi-agent teams to decompose complex tasks, select optimal sub-agents, and execute work in parallel.

```
/agent-team
```

### git-workflow

ブランチ作成、Conventional Commits コミット、PR 作成までの Git ワークフローを自動化

ブランチ作成 → コミット → PR作成 までのGitワークフローを支援する。

```
/git-workflow
```

### ci-check

全パッケージの lint, format, test, audit を一括実行し、エラーがあれば修正する

全パッケージの lint、フォーマットチェック、テスト、セキュリティ監査を一括実行し、問題があれば修正する。

```
/ci-check
```

### ui-verify

Chrome DevTools でフロントエンドの動作確認。起動中サーバーを自動検出し操作・デバッグ・パフォーマンス分析を実行

$ARGUMENTS

```
/ui-verify
```

### spec-test

仕様駆動設計。仕様書からクラス責務を分析し、純粋関数を特定、テストファーストで単体テストを設計する

仕様書を受け取り、**テストファースト**でクラス設計と単体テストを設計し、**既存のPlanドキュメントに自動追記**するスキル。

```
/spec-test
```

### database

Drizzle ORM を使ったデータベーススキーマの管理とマイグレーションガイド

Drizzle ORM を使ったデータベーススキーマの管理とマイグレーションに関するガイド。

```
/database
```

### app-naming

4つの専門エージェント（ブランディング・商標・デジタルプレゼンス・国際展開）がチームで議論し、最適なアプリ名・サービス名を決定する

4つの専門エージェントがチームで議論・フィードバックし合い、最適なアプリ名を決定する。

```
/app-naming
```

## Internal Skills

> 以下は作者の内部リポジトリ向けスキルです。一般利用者向けではありません。

| Skill | Description |
|-------|-------------|
| **skill-publisher** | 作者のリポジトリ間でスキルを配置・登録するための内部ユーティリティ。一般利用者向けではありません。自分のプロジェクトにスキルを追加する際の構造化とmarketplace.json登録を自動化します |

## Prerequisites

**Required** (all skills)

- **Claude Code** CLI
- **Git**

**Optional** (skill-specific)

- **Codex CLI** — multi-ai-review / plan-review
- **Gemini CLI** — multi-ai-review / plan-review
- **GitHub CLI (gh)** — git-workflow
- **jq** — GitHub Actions / skill-publisher
- **lsof** — ui-verify
- **pnpm** — ci-check / database / ui-verify
- **python3** — GitHub Actions

## FAQ

<details>
<summary><strong>Q: スキルが見つからない / コマンドが動かない</strong></summary>

プラグインが正しくインストールされているか確認してください:

```bash
claude plugin list
```

表示されない場合は再インストールしてください:

```bash
claude plugin add github:sean-sunagaku/claude-code-plugin
```

</details>

<details>
<summary><strong>Q: Codex CLI / Gemini CLI が見つからないと言われる</strong></summary>

`multi-ai-review` と `plan-review` は外部 AI CLI を使用します。

```bash
# Codex CLI のインストール
npm install -g @openai/codex

# Gemini CLI のインストール
npm install -g @anthropic-ai/gemini-cli
```

いずれかの CLI がない場合、そのレビューはスキップされます。

</details>

<details>
<summary><strong>Q: pnpm / gh が必要と言われる</strong></summary>

一部のスキルはプロジェクト固有のツールに依存しています:

- `ci-check` → **pnpm** が必要（`npm install -g pnpm`）
- `git-workflow` → **gh** が必要（`brew install gh` / [GitHub CLI](https://cli.github.com/)）

</details>

<details>
<summary><strong>Q: 特定のスキルだけ使いたい</strong></summary>

すべてのスキルは独立しています。必要なスキルのコマンドをそのまま実行してください。
使わないスキルの依存ツールをインストールする必要はありません。

</details>

## License

MIT

---

> This README is auto-generated from `.claude-plugin/marketplace.json` and each skill's `SKILL.md`.
> Do not edit manually. Run `.github/scripts/generate-readme.sh` to update.
