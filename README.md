# Claude Code Plugin

![Skills](https://img.shields.io/badge/skills-39-blue) ![License](https://img.shields.io/badge/license-MIT-green)

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

| Category | Skills | Description |
|----------|--------|-------------|
| [Product](./product/) | 7 skills | プロダクトの企画・ユーザーリサーチ・ペルソナ設計・ジャーニーマップ作成 |
| [Planning](./planning/) | 5 skills | 機能検討・技術設計の議論・実装計画の策定 |
| [Design](./design/) | 5 skills | UI/UXデザイン・ロゴ作成・デザインバリエーション生成 |
| [Development](./development/) | 7 skills | CI/CD・データベース管理・Gitワークフロー・デバッグ・テスト・デプロイ |
| [Review](./review/) | 5 skills | コードレビュー・プランレビュー・UI検証・品質チェック |
| [Marketing](./marketing/) | 5 skills | アプリ名決定・ASO最適化・スクリーンショット作成・プレビュー動画生成 |
| [Agent Toolkit](./agent-toolkit/) | 4 skills | エージェントチームの構築・運用・ベストプラクティス |

## Hooks

> PostToolUse / PreToolUse 等のフックプラグイン。インストールすると自動的に有効化されます。

| Hook | Description | Event | Keywords |
|------|-------------|-------|----------|
| **agent-teams-log** | Agent Teams の SendMessage を自動ログする PostToolUse hook。エージェント間の議論を .claude/agent-teams-log/ にリアルタイム記録する | `PostToolUse` | `agent-team, hook, logging, SendMessage, PostToolUse, discussion` |
| **task-granularity** | TaskCreate 時にタスクの粒度を自動チェックする PreToolUse hook。静的解析 + LLM（Haiku）のハイブリッド判定で、大きすぎるタスクの作成をブロックし分割案を提示する | `PreToolUse` | `task, granularity, hook, PreToolUse, TaskCreate, quality, haiku` |
| **ui-quality-hooks** | UI品質チェック PostToolUse Hook セット。Edit/Write時の静的パターン検出（createPortal漏れ、z-index競合）+ take_snapshot後のAI DOM分析 + list_console_messages後のAIコンソールエラー分類。claude -p (Haiku) で分析し additionalContext でフィードバック | `PostToolUse` | `ui, quality, hook, PostToolUse, createPortal, DOM, console, accessibility, claude-p, haiku` |

### agent-teams-log

Agent Teams の SendMessage を自動ログする PostToolUse hook。エージェント間の議論を .claude/agent-teams-log/ にリアルタイム記録する

### task-granularity

TaskCreate 時にタスクの粒度を自動チェックする PreToolUse hook。静的解析 + LLM（Haiku）のハイブリッド判定で、大きすぎるタスクの作成をブロックし分割案を提示する

### ui-quality-hooks

UI品質チェック PostToolUse Hook セット。Edit/Write時の静的パターン検出（createPortal漏れ、z-index競合）+ take_snapshot後のAI DOM分析 + list_console_messages後のAIコンソールエラー分類。claude -p (Haiku) で分析し additionalContext でフィードバック

## Internal Skills

> 以下は作者の内部リポジトリ向けスキルです。一般利用者向けではありません。

| Skill | Description |
|-------|-------------|
| **skill-publisher** | 作者のリポジトリ間でスキルを配置・登録するための内部ユーティリティ。一般利用者向けではありません。自分のプロジェクトにスキルを追加する際の構造化とmarketplace.json登録を自動化します |
| **marketplace-validate** | [Beta] claude-code-plugin リポジトリの marketplace 構造を検証し、エラーを自動修正する内部ユーティリティ。CI バリデーションと同等のチェックをローカルで実行し、missing plugin.json、未登録スキル、frontmatter 不備などを検出・修正する |
| **hook-publisher** | Hook スクリプトを claude-code-plugin リポジトリの正しい構造に配置・登録するための内部ユーティリティ。hook の構造検証、plugin.json 生成、marketplace.json 自動登録を行う |

## Prerequisites

**Required** (all skills)

- **Claude Code** CLI
- **Git**

**Optional** (skill-specific)

- **Codex CLI** — multi-ai-review / plan-review
- **curl** — rn-debug
- **Docker** — ci-check
- **EAS CLI** — eas-deploy
- **FFmpeg** — app-store-preview-movie / frame-inspect
- **gem** — eas-deploy
- **Gemini CLI** — multi-ai-review / plan-review
- **GitHub CLI (gh)** — ci-check / ci-fix / git-workflow
- **jq** — GitHub Actions / ci-fix / hook-publisher / marketplace-validate / skill-publisher
- **lsof** — ui-verify
- **npm** — ci-check / frame-inspect / long-run-implement / svg-to-png
- **npx** — frame-inspect / rn-debug
- **pnpm** — ci-check / database / ui-verify
- **python** — ci-check
- **python3** — GitHub Actions / hook-publisher
- **yarn** — ci-check

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
