# Claude Code Plugin

![Skills](https://img.shields.io/badge/skills-45-blue) ![License](https://img.shields.io/badge/license-MIT-green)

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
| [Product](./product/) | 8 skills | プロダクトの企画・ユーザーリサーチ・ペルソナ設計・ジャーニーマップ作成 |
| [Planning](./planning/) | 6 skills | 機能検討・技術設計の議論・実装計画の策定 |
| [Design](./design/) | 6 skills | UI/UXデザイン・ロゴ作成・デザインバリエーション生成 |
| [Development](./development/) | 9 skills | CI/CD・データベース管理・Gitワークフロー・デバッグ・テスト・デプロイ |
| [Review](./review/) | 6 skills | コードレビュー・プランレビュー・UI検証・品質チェック |
| [Marketing](./marketing/) | 5 skills | アプリ名決定・ASO最適化・スクリーンショット作成・プレビュー動画生成 |
| [Agent Toolkit](./agent-toolkit/) | 4 skills | エージェントチームの構築・運用・ベストプラクティス |

## Hooks

> PostToolUse / PreToolUse 等のフックプラグイン。インストールすると自動的に有効化されます。

| Hook | Description | Event | Keywords |
|------|-------------|-------|----------|
| **agent-teams-log** | Agent Teams のチーム間通信ログを PostToolUse Hook で自動記録する | `PostToolUse` | `` |
| **task-granularity** | タスクの粒度を自動検証し、大きすぎるタスクを分割提案する Hook | `PreToolUse` | `` |
| **ui-quality-hooks** | UI コード変更時にアクセシビリティとレイアウト品質を自動チェックする Hook | `PostToolUse` | `` |

### agent-teams-log

Agent Teams のチーム間通信ログを PostToolUse Hook で自動記録する

### task-granularity

タスクの粒度を自動検証し、大きすぎるタスクを分割提案する Hook

### ui-quality-hooks

UI コード変更時にアクセシビリティとレイアウト品質を自動チェックする Hook

## Internal Skills

> 以下は作者の内部リポジトリ向けスキルです。一般利用者向けではありません。

| Skill | Description |
|-------|-------------|
| **skill-publisher** | 作者のリポジトリ間でスキルを配置・登録するための内部ユーティリティ。一般利用者向けではありません。自分のプロジェクトにスキルを追加する際の構造化とmarketplace.json登録を自動化します |
| **marketplace-validate** | claude-code-plugin リポジトリの marketplace 構造を検証し、エラーを自動修正する内部ユーティリティ |
| **hook-publisher** | Hook スクリプトを claude-code-plugin リポジトリの正しい構造に配置・登録するための内部ユーティリティ |

## Prerequisites

**Required** (all skills)

- **Claude Code** CLI
- **Git**

**Optional** (skill-specific)

- **CocoaPods** — eas-deploy
- **Codex CLI** — arch-review / multi-ai-review / plan-review
- **curl** — rn-debug
- **Docker** — ci-check
- **EAS CLI** — eas-deploy
- **ffmpeg** — app-store-preview-movie
- **ffprobe** — app-store-preview-movie
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
