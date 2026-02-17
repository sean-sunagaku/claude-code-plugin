# Claude Code Plugin

{{BADGES}}

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

{{SKILLS_TABLE}}

## Skill Details

{{SKILL_DETAILS}}

{{BETA_SECTION}}

{{INTERNAL_SECTION}}

## Prerequisites

{{PREREQUISITES}}

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
