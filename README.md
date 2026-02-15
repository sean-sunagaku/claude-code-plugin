# Claude Code Plugin

Claude Code の開発ワークフローを強化するスキルプラグイン集。

## Install

```bash
claude plugin add github:sean-sunagaku/claude-code-plugin
```

Or use the slash command inside Claude Code:

```
/plugin marketplace add sean-sunagaku/claude-code-plugin
```

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| **multi-ai-review** | `/multi-ai-review` | Codex, Gemini, Claude の3つの AI で並列コードレビュー |
| **plan-review** | `/plan-review` | 3つの AI で Plan ファイルを並列レビュー |
| **agent-team** | `/agent-team` | マルチエージェントチームのオーケストレーション |
| **git-workflow** | `/git-workflow` | ブランチ作成 → コミット → PR 作成の自動化 |
| **ci-check** | `/ci-check` | lint / format / test / audit の一括実行と自動修正 |
| **ui-verify** | `/ui-verify` | Chrome DevTools でフロントエンドの動作確認 |
| **spec-test** | `/spec-test` | 仕様駆動設計とテストファースト単体テスト設計 |
| **database** | `/database` | Drizzle ORM スキーマ管理とマイグレーションガイド |
| **ui-ux-pro-max** | (auto) | UI/UX デザインインテリジェンス (67 styles, 96 palettes, 13 stacks) |

## Skill Details

### multi-ai-review

Codex, Gemini, Claude の3つの AI に並列でコードレビューを依頼し、統合レポートを生成。

```
/multi-ai-review --diff develop
```

### plan-review

実装計画 (Plan) の妥当性、抜け漏れ、リスクを3つの AI で分析。

```
/plan-review docs/plans/my-feature.md
```

### agent-team

複数エージェントを並列起動して、リサーチ・実装・テストを分担。

```
/agent-team
```

### git-workflow

Conventional Commits 形式のブランチ作成、コミット、PR 作成を自動化。

```
/git-workflow              # フルワークフロー (commit → push → PR)
/git-workflow branch feat/new-feature
/git-workflow commit
/git-workflow pr
```

### ci-check

全パッケージの lint, format check, test, audit を一括実行。エラーがあれば自動修正。

```
/ci-check
```

### ui-verify

Chrome DevTools MCP を使い、起動中のアプリを自動検出してブラウザテストを実行。

```
/ui-verify                      # git diff から自動判定
/ui-verify ログイン画面を確認    # 特定画面のテスト
```

### spec-test

仕様書からクラス責務を分析し、純粋関数を特定。テストファーストで単体テスト設計。

```
/spec-test docs/plans/my-feature.md
```

### database

Drizzle ORM を使ったスキーマ管理とマイグレーションのベストプラクティス。

### ui-ux-pro-max

67 スタイル、96 カラーパレット、57 フォントペアリング、25 チャートタイプ、13 技術スタックに対応した UI/UX デザインガイド。

## Prerequisites

- **Claude Code** CLI
- **Codex CLI** (multi-ai-review, plan-review で使用)
- **Gemini CLI** (multi-ai-review, plan-review で使用)
- **Python 3** (ui-ux-pro-max で使用)
- **Chrome DevTools MCP** (ui-verify で使用)
- **gh CLI** (git-workflow で使用)

## License

MIT
