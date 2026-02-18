# Claude Code Plugin

![Skills](https://img.shields.io/badge/skills-15-blue) ![License](https://img.shields.io/badge/license-MIT-green)

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
| **ci-check** | `/ci-check` | .github/workflows/*.yml を自動解析し、CI 定義のチェックをローカル実行する汎用スキル。エラーがあれば修正する | `ci, lint, format, test, audit, automation` |
| **ui-verify** | `/ui-verify` | Chrome DevTools でフロントエンドの動作確認。起動中サーバーを自動検出し操作・デバッグ・パフォーマンス分析を実行 | `ui, testing, chrome-devtools, verification, e2e` |
| **spec-test** | `/spec-test` | 仕様駆動設計。仕様書からクラス責務を分析し、純粋関数を特定、テストファーストで単体テストを設計する | `spec, test, tdd, test-first, pure-function, design` |
| **database** | `/database` | Drizzle ORM を使ったデータベーススキーマの管理とマイグレーションガイド | `database, drizzle, orm, migration, sqlite` |
| **app-naming** | `/app-naming` | 5つの専門エージェント（ブランディング・商標・デジタルプレゼンス・国際展開・コンテキスト管理）がチームで相互フィードバックしながら議論し、最適なアプリ名を決定する | `naming, branding, trademark, app-name, agent-team, SEO, ASO` |
| **eas-deploy** | `/eas-deploy` | Expo (EAS) iOS/Android アプリのデプロイ自動化。App ID 登録、証明書・プロビジョニングプロファイル作成、EAS ビルド、TestFlight 配布、App Store 提出までを CLI から実行する | `eas, deploy` |

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

.github/workflows/*.yml を自動解析し、CI 定義のチェックをローカル実行する汎用スキル。エラーがあれば修正する

`.github/workflows/*.yml` を解析し、CI 定義のチェックをローカル実行する。

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

5つの専門エージェント（ブランディング・商標・デジタルプレゼンス・国際展開・コンテキスト管理）がチームで相互フィードバックしながら議論し、最適なアプリ名を決定する

5つの専門エージェントがチームで相互フィードバックしながら議論し、最適なアプリ名を決定する。

```
/app-naming
```

### eas-deploy

Expo (EAS) iOS/Android アプリのデプロイ自動化。App ID 登録、証明書・プロビジョニングプロファイル作成、EAS ビルド、TestFlight 配布、App Store 提出までを CLI から実行する

任意の Expo プロジェクトの iOS/Android デプロイを CLI から自動実行する。

```
/eas-deploy
```

## Beta Skills

> 以下のスキルは現在開発中です。動作やインターフェースが変更される可能性があります。

| Skill | Command | Description | Keywords |
|-------|---------|-------------|----------|
| **ui-review** | `/ui-review` | 5つの専門エージェント（UXデザイナー・ビジュアルデザイナー・アクセシビリティ専門家・モバイルUI専門家・コピーデザイナー）がチームでUIを添削・改善するスキル。Pencil(.pen)で画面デザインを作成・修正しながらリアルタイムで議論する | `ui, ux, design, review, accessibility, mobile, pencil, agent-team` |
| **logo-design** | `/logo-design` | 6つの専門エージェント（ブランド戦略・ロゴデザイン・カラー/タイポ・トレンド調査・競合分析・コンテキスト管理）がチームで相互フィードバックしながらロゴを作成・議論するスキル。Pencil(.pen)で複数バリエーションを作成しSVGアイコンも出力する | `logo, brand, design, icon, svg, agent-team, pencil` |
| **ci-fix** | `/ci-fix` | GitHub Actions の CI 失敗を自動検出・ログ取得・修正・再検証するスキル。gh コマンドで PR のチェック状況を監視し、失敗時はログを分析してコードを修正、push 後に再度 CI を確認するループを回す | `ci, github-actions, fix, gh, pull-request, automation` |
| **aso-optimize** | `/aso-optimize` | 4つの専門エージェントチームで App Store / Google Play のメタデータ（タイトル・サブタイトル・キーワード・説明文・宣伝テキスト・What's New）を最適化し、最終レポートを出力する。多言語対応 | `aso, optimize` |
| **skill-creator-team** | `/skill-creator-team` | 4つの専門エージェント（アーキテクト・リサーチャー・ライター・レビュアー）がチームで高品質なスキルを設計・作成する。skill-creator ベストプラクティスに準拠 | `skill, creator, team` |

### ui-review

5つの専門エージェント（UXデザイナー・ビジュアルデザイナー・アクセシビリティ専門家・モバイルUI専門家・コピーデザイナー）がチームでUIを添削・改善するスキル。Pencil(.pen)で画面デザインを作成・修正しながらリアルタイムで議論する

5つの専門エージェントが Pencil でデザインを見ながら議論し、UIを添削・改善する。

```
/ui-review
```

### logo-design

6つの専門エージェント（ブランド戦略・ロゴデザイン・カラー/タイポ・トレンド調査・競合分析・コンテキスト管理）がチームで相互フィードバックしながらロゴを作成・議論するスキル。Pencil(.pen)で複数バリエーションを作成しSVGアイコンも出力する

6つの専門エージェントがチームで相互フィードバックしながら議論し、Pencil でロゴを作成する。

```
/logo-design
```

### ci-fix

GitHub Actions の CI 失敗を自動検出・ログ取得・修正・再検証するスキル。gh コマンドで PR のチェック状況を監視し、失敗時はログを分析してコードを修正、push 後に再度 CI を確認するループを回す

CI 失敗の検出 → ログ取得 → 修正 → push → 再検証のループを自動実行する。

```
/ci-fix
```

### aso-optimize

4つの専門エージェントチームで App Store / Google Play のメタデータ（タイトル・サブタイトル・キーワード・説明文・宣伝テキスト・What's New）を最適化し、最終レポートを出力する。多言語対応

4つの専門エージェントがチームで議論・フィードバックし合い、App Store / Google Play 向けの最適なメタデータを作成する。

```
/aso-optimize
```

### skill-creator-team

4つの専門エージェント（アーキテクト・リサーチャー・ライター・レビュアー）がチームで高品質なスキルを設計・作成する。skill-creator ベストプラクティスに準拠

4つの専門エージェントがチームで議論し、高品質なスキルを作成する。

```
/skill-creator-team
```

## Internal Skills

> 以下は作者の内部リポジトリ向けスキルです。一般利用者向けではありません。

| Skill | Description |
|-------|-------------|
| **skill-publisher** | 作者のリポジトリ間でスキルを配置・登録するための内部ユーティリティ。一般利用者向けではありません。自分のプロジェクトにスキルを追加する際の構造化とmarketplace.json登録を自動化します |
| **marketplace-validate** | [Beta] claude-code-plugin リポジトリの marketplace 構造を検証し、エラーを自動修正する内部ユーティリティ。CI バリデーションと同等のチェックをローカルで実行し、missing plugin.json、未登録スキル、frontmatter 不備などを検出・修正する |

## Prerequisites

**Required** (all skills)

- **Claude Code** CLI
- **Git**

**Optional** (skill-specific)

- **Codex CLI** — multi-ai-review / plan-review
- **EAS CLI** — eas-deploy
- **gem** — eas-deploy
- **Gemini CLI** — multi-ai-review / plan-review
- **GitHub CLI (gh)** — ci-check / ci-fix / git-workflow
- **jq** — GitHub Actions / ci-fix / marketplace-validate / skill-publisher
- **lsof** — ui-verify
- **npm** — ci-check
- **pnpm** — ci-check / database / ui-verify
- **python** — ci-check
- **python3** — GitHub Actions
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
