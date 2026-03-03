---
name: git-workflow
description: ブランチ作成、コミット、PR作成までのGitワークフローを支援する
disable-model-invocation: false
---

# Git Workflow Helper

ブランチ作成 → コミット → PR作成 までのGitワークフローを支援する。

## シェルスクリプト一覧

すべての操作は `.claude/skills/git-workflow/scripts/` のシェルスクリプトを使用すること。

| スクリプト | 用途 | 例 |
| --- | --- | --- |
| `full-workflow.sh` | commit → push → PR（フル） | `.claude/skills/git-workflow/scripts/full-workflow.sh "msg" "title" "body"` |
| `create-branch.sh` | ブランチ作成（develop から） | `.claude/skills/git-workflow/scripts/create-branch.sh feat/add-login` |
| `commit.sh` | コミット（Co-Author 付き） | `.claude/skills/git-workflow/scripts/commit.sh "feat(web): add login"` |
| `create-pr.sh` | PR作成（base: develop） | `.claude/skills/git-workflow/scripts/create-pr.sh "title" "body"` |

## Usage

```
/git-workflow <command> [options]
```

### Commands

| Command  | 説明                                     | 例                                        |
| -------- | ---------------------------------------- | ----------------------------------------- |
| (なし)   | **フルワークフロー**: commit → push → PR | `/git-workflow`                           |
| `branch` | 新しいブランチを作成                     | `/git-workflow branch feat/add-login`     |
| `commit` | ステージした変更をコミット               | `/git-workflow commit`                    |
| `pr`     | PRを作成                                 | `/git-workflow pr`                        |

---

## 0. Full Workflow - フルワークフロー（デフォルト）

引数なしで `/git-workflow` を実行した場合、以下を **ノンストップで自動実行** する:

### Instructions

1. `git status` で変更を確認
2. 変更があればステージング (`git add`)
3. コミットメッセージ、PRタイトル、PRボディを生成 **（必ず英語で生成すること）**
4. **`.claude/skills/git-workflow/scripts/full-workflow.sh` を実行**

```bash
# フルワークフロースクリプトを使用
.claude/skills/git-workflow/scripts/full-workflow.sh "<commit message>" "<pr title>" "<pr body>"
```

### Notes

- main/develop ブランチでは実行しない（スクリプトが警告を出す）
- ベースブランチは develop に固定
- Co-Authored-By は自動付与

---

## 1. Branch - ブランチ作成

### Instructions

1. ブランチ名を決定（タスク内容から提案）
2. **`.claude/skills/git-workflow/scripts/create-branch.sh` を実行**

```bash
# develop から新しいブランチを作成
.claude/skills/git-workflow/scripts/create-branch.sh <branch-name>
```

### Branch Naming Convention

```
<type>/<short-description>
```

| Type       | 用途               | 例                          |
| ---------- | ------------------ | --------------------------- |
| `feat`     | 新機能             | `feat/add-user-auth`        |
| `fix`      | バグ修正           | `fix/login-error`           |
| `refactor` | リファクタリング   | `refactor/api-structure`    |
| `docs`     | ドキュメント       | `docs/api-readme`           |
| `chore`    | 雑務・設定         | `chore/update-deps`         |
| `perf`     | パフォーマンス改善 | `perf/optimize-queries`     |

### Base Branch

- **develop**: 通常の開発ブランチのベース（スクリプトで固定）
- **main**: リリース用（直接ブランチを切らない）

---

## 2. Commit - コミット作成

### Instructions

1. `git status` でステージされた変更を確認
2. `git diff --cached` で変更内容を分析
3. 変更ファイルから適切な type と scope を決定
4. Conventional Commits 形式のメッセージを生成
5. **`.claude/skills/git-workflow/scripts/commit.sh` を実行**

```bash
# Co-Authored-By 付きでコミット
.claude/skills/git-workflow/scripts/commit.sh "<commit message>"
```

### Commit Message Format

```
<type>(<scope>): <subject>
```

### Types (必須)

| Type       | 説明               | 例                        |
| ---------- | ------------------ | ------------------------- |
| `feat`     | 新機能追加         | 新しいAPI、コンポーネント |
| `fix`      | バグ修正           | エラー修正、不具合対応    |
| `docs`     | ドキュメントのみ   | README、コメント          |
| `style`    | コードスタイル     | フォーマット、セミコロン  |
| `refactor` | リファクタリング   | 機能変更なしの改善        |
| `perf`     | パフォーマンス改善 | 速度向上、最適化          |
| `test`     | テスト             | テスト追加・修正          |
| `chore`    | 雑務               | ビルド、依存関係、設定    |
| `ci`       | CI/CD              | GitHub Actions等          |
| `revert`   | リバート           | 過去コミットの取消        |

### Scope (任意)

| Scope    | 対象              |
| -------- | ----------------- |
| `server` | packages/server   |
| `web`    | packages/web      |
| `shared` | packages/shared   |
| `db`     | データベース関連  |
| `api`    | APIエンドポイント |
| `ui`     | UIコンポーネント  |
| `config` | 設定ファイル      |

### File → Scope Mapping

| ファイルパス                     | Scope                   |
| -------------------------------- | ----------------------- |
| `packages/server/**`             | `server`                |
| `packages/web/**`                | `web`                   |
| `packages/shared/**`             | `shared`                |
| `**/db/**`, `*.db`               | `db`                    |
| `**/routes/**`, `**/api/**`      | `api`                   |
| `**/components/**`               | `ui`                    |
| `*.config.*`, `tsconfig.*`       | `config`                |
| `docs/**`, `*.md`                | (scopeなし、type: docs) |
| `**/*.test.*`, `**/__tests__/**` | (scopeなし、type: test) |

---

## 3. PR - Pull Request作成

### IMPORTANT: ベースブランチは必ず develop

**絶対に `--base main` を使わないこと。スクリプトが `develop` に固定する。**

### Instructions

1. 現在のブランチを確認（develop/main でないことを確認）
2. `git log` と `git diff develop...HEAD` で変更内容を分析
3. PRのタイトルとボディを生成 **（必ず英語で生成すること）**
4. **`.claude/skills/git-workflow/scripts/create-pr.sh` を実行**

```bash
# PR作成（push も含む、base は develop 固定）
.claude/skills/git-workflow/scripts/create-pr.sh "<title>" "<body>"
```

### PR Title Format

コミットメッセージと同様、Conventional Commits形式:
```
<type>(<scope>): <short description>
```

### PR Body Template

**IMPORTANT: All PR content (title, summary, test plan) MUST be written in English.**

```markdown
## Summary
- Brief description of changes (1-3 bullet points, in English)

## Test plan
- [ ] Test item 1
- [ ] Test item 2

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

---

## Commit Examples

### シンプルな機能追加

```bash
.claude/skills/git-workflow/scripts/commit.sh "feat(api): add user authentication endpoint"
```

### 複数変更を含む機能

```bash
.claude/skills/git-workflow/scripts/commit.sh "feat(web): add session management with SQLite

- Implement Drizzle ORM for database operations
- Add session CRUD endpoints
- Create sidebar component for session list"
```

### バグ修正

```bash
.claude/skills/git-workflow/scripts/commit.sh "fix(server): resolve streaming timeout issue

Fixes #42"
```
