# Claude Code Plugin

![Skills](https://img.shields.io/badge/skills-26-blue) ![License](https://img.shields.io/badge/license-MIT-green)

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
| **agent-team-guide** | `/agent-team-guide` | Agent Teams スキルを設計・構築するためのベストプラクティスガイド。サブエージェント定義、SendMessage 通信プロトコル、タスク依存管理、PostToolUse Hook ログ、MCP ツール統合、コンテキストファイル設計を網羅。7つの実績あるチームスキルから抽出したパターン集 | `agent, team, guide, best-practice, SendMessage, task-management` |
| **user-journey** | `/user-journey` | ユーザージャーニーマップを5つの専門エージェントチームで作成するスキル。認知から推薦まで5フェーズで行動・思考・感情・接点・機能・課題・機会・Devアクションを構造化しMarkdownで出力する | `user, journey` |
| **team-plan** | `/team-plan` | 実装前にTask(Explore)エージェントを並列起動してコードベースを多角調査し、Plan Modeで実装計画を立ててからユーザー承認を経て実装する | `team, plan` |
| **subagent-best-practices** | `/subagent-best-practices` |  Claude Code の SubAgent（agents/*.md）を正しく定義するためのベストプラクティスガイド。 YAML frontmatter、ツール選択、3-Phase 構造、コンテキスト受け渡し、アンチパターンを網羅。 Use when: agents/*.md を書く、SubAgent 定義を改善する、エージェントの動作が想定外、 コンテキストが渡らない、ツール選択に迷う。 Triggers: "subagent", "agent definition", "agents/*.md", "エージェント定義", "サブエージェント", "3-Phase", "context passing", "コンテキスト渡し", "tool selection", "ツール選択", "subagent_type", "bypassPermissions" | `subagent, best, practices` |
| **team-implement** | `/team-implement` |  承認済みの実装計画（Plan）を Agent Team で並列に実装するスキル。 Plan をタスクに分割 → 依存関係を設定 → Wave ごとに並列エージェントを起動 → 完了を待って次の Wave → 最後にビルド＆テスト検証。 team-plan スキル（調査→計画）の後に使う「実装実行フェーズ」。 | `team, implement` |

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

### agent-team-guide

Agent Teams スキルを設計・構築するためのベストプラクティスガイド。サブエージェント定義、SendMessage 通信プロトコル、タスク依存管理、PostToolUse Hook ログ、MCP ツール統合、コンテキストファイル設計を網羅。7つの実績あるチームスキルから抽出したパターン集

7つの実績あるチームスキルから抽出した Agent Teams 設計パターン集。

```
/agent-team-guide
```

### user-journey

ユーザージャーニーマップを5つの専門エージェントチームで作成するスキル。認知から推薦まで5フェーズで行動・思考・感情・接点・機能・課題・機会・Devアクションを構造化しMarkdownで出力する

5つの専門エージェントがチームで議論し、ユーザージャーニーマップを作成する。

```
/user-journey
```

### team-plan

実装前にTask(Explore)エージェントを並列起動してコードベースを多角調査し、Plan Modeで実装計画を立ててからユーザー承認を経て実装する

実装タスクを受け取ったとき、**まず並列に Explore エージェントでコードベースを調査**し、

```
/team-plan
```

### subagent-best-practices

 Claude Code の SubAgent（agents/*.md）を正しく定義するためのベストプラクティスガイド。 YAML frontmatter、ツール選択、3-Phase 構造、コンテキスト受け渡し、アンチパターンを網羅。 Use when: agents/*.md を書く、SubAgent 定義を改善する、エージェントの動作が想定外、 コンテキストが渡らない、ツール選択に迷う。 Triggers: "subagent", "agent definition", "agents/*.md", "エージェント定義", "サブエージェント", "3-Phase", "context passing", "コンテキスト渡し", "tool selection", "ツール選択", "subagent_type", "bypassPermissions"

Claude Code の `agents/*.md` ファイルで SubAgent を正しく定義するための実践ガイド。

```
/subagent-best-practices
```

### team-implement

 承認済みの実装計画（Plan）を Agent Team で並列に実装するスキル。 Plan をタスクに分割 → 依存関係を設定 → Wave ごとに並列エージェントを起動 → 完了を待って次の Wave → 最後にビルド＆テスト検証。 team-plan スキル（調査→計画）の後に使う「実装実行フェーズ」。

承認済みの実装計画を **Agent Team (TeamCreate + TaskCreate) で並列に実装**するスキル。

```
/team-implement
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
| **ui-variations** | `/ui-variations` | 5つの異なるUIデザインバリエーションを並列エージェントチームで生成し、Pencilで比較するスキル。各デザイナーがMCP経由でPencilに直接構築。3人チーム x5の並列実行。 | `ui, design, variations, pencil, agent-team, parallel, mcp` |
| **persona-creation** | `/persona-creation` | 5つの専門エージェント（ペルソナ設計・ユーザーリサーチ・ナラティブ執筆・バイアスレビュー・コンテキスト管理）がチームでUX/マーケティング向けユーザーペルソナを作成するスキル。セグメント設計からプロファイル執筆・多様性レビューまでを議論・作成しMarkdownで出力する | `persona, ux, marketing, user-research, agent-team, bias-review, segmentation` |
| **screenshot-creator** | `/screenshot-creator` | 5つの専門エージェント（クリエイティブディレクター・スクリーンショットデザイナー・コピーライター・仕様バリデーター・品質レビュアー）がチームで App Store / Google Play 用プロモーションスクリーンショットを Pencil (.pen) で生成するスキル | `screenshot, app-store, pencil, agent-team, promotion` |
| **app-store-preview-movie** | `/app-store-preview-movie` | 5つの専門エージェント（ビデオディレクター・モーションデザイナー・スクリプトライター・プレビューレビュアー・フレームインスペクター）がチームで App Store プレビュー動画を Remotion (React) で生成・検証するスキル | `app-store, preview, video, remotion, agent-team, animation` |
| **frame-inspect** | `/frame-inspect` | 動画・画像のフレーム抽出、Remotion レンダリング、仕様チェック、目視検証を行う汎用ビデオツールキット。統一シェルスクリプト (video-tool.sh) で操作 | `video, frame, ffmpeg, ffprobe, remotion, render, inspection, quality, spec-check` |
| **domain-expertise-extractor** | `/domain-expertise-extractor` | 4つの専門エージェント（ドメインリサーチャー・パターンアナリスト・ナレッジライター・品質チェッカー）がチームでデジタルプロダクト系ドメインの暗黙知を抽出・言語化・構造化し、他のSkillで使えるエージェント定義と評価基準を生成するスキル | `domain, expertise, extractor` |

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

### ui-variations

5つの異なるUIデザインバリエーションを並列エージェントチームで生成し、Pencilで比較するスキル。各デザイナーがMCP経由でPencilに直接構築。3人チーム x5の並列実行。

5つの異なるスタイル方向で同一画面のUIバリエーションを**並列生成**し、Pencilで横並び比較する。

```
/ui-variations
```

### persona-creation

5つの専門エージェント（ペルソナ設計・ユーザーリサーチ・ナラティブ執筆・バイアスレビュー・コンテキスト管理）がチームでUX/マーケティング向けユーザーペルソナを作成するスキル。セグメント設計からプロファイル執筆・多様性レビューまでを議論・作成しMarkdownで出力する

5つの専門エージェントがチームで議論し、UX/マーケティング向けのユーザーペルソナを作成する。

```
/persona-creation
```

### screenshot-creator

5つの専門エージェント（クリエイティブディレクター・スクリーンショットデザイナー・コピーライター・仕様バリデーター・品質レビュアー）がチームで App Store / Google Play 用プロモーションスクリーンショットを Pencil (.pen) で生成するスキル

```
/screenshot-creator
```

### app-store-preview-movie

5つの専門エージェント（ビデオディレクター・モーションデザイナー・スクリプトライター・プレビューレビュアー・フレームインスペクター）がチームで App Store プレビュー動画を Remotion (React) で生成・検証するスキル

```
/app-store-preview-movie
```

### frame-inspect

動画・画像のフレーム抽出、Remotion レンダリング、仕様チェック、目視検証を行う汎用ビデオツールキット。統一シェルスクリプト (video-tool.sh) で操作

動画・画像のフレーム抽出、Remotion レンダリング、仕様チェック、目視検証の統合ツールキット。

```
/frame-inspect
```

### domain-expertise-extractor

4つの専門エージェント（ドメインリサーチャー・パターンアナリスト・ナレッジライター・品質チェッカー）がチームでデジタルプロダクト系ドメインの暗黙知を抽出・言語化・構造化し、他のSkillで使えるエージェント定義と評価基準を生成するスキル

4つの専門エージェントが連携して、デジタルプロダクト系ドメインの暗黙知を抽出・構造化する。

```
/domain-expertise-extractor
```

## Hooks

> PostToolUse / PreToolUse 等のフックプラグイン。インストールすると自動的に有効化されます。

| Hook | Description | Event | Keywords |
|------|-------------|-------|----------|
| **agent-teams-log** | Agent Teams の SendMessage を自動ログする PostToolUse hook。エージェント間の議論を .claude/agent-teams-log/ にリアルタイム記録する | `PostToolUse` | `agent-team, hook, logging, SendMessage, PostToolUse, discussion` |

### agent-teams-log

Agent Teams の SendMessage を自動ログする PostToolUse hook。エージェント間の議論を .claude/agent-teams-log/ にリアルタイム記録する

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
- **Docker** — ci-check
- **EAS CLI** — eas-deploy
- **ffmpeg** — app-store-preview-movie / frame-inspect
- **gem** — eas-deploy
- **Gemini CLI** — multi-ai-review / plan-review
- **GitHub CLI (gh)** — ci-check / ci-fix / git-workflow
- **jq** — GitHub Actions / ci-fix / hook-publisher / marketplace-validate / skill-publisher
- **lsof** — ui-verify
- **Node.js** — svg-to-png
- **npm** — ci-check / frame-inspect / svg-to-png
- **npx** — frame-inspect
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
