---
name: multi-ai-review
description: Codex、Gemini、Claudeの3つのAIに並列でコードレビューを依頼し、結果を統合レポートとして出力するスキル。複数AIの視点から包括的なレビューを得たいとき、「マルチAIレビュー」「3つのAIでレビュー」「Codex Gemini Claudeでレビュー」などと言及した時に使用。
---

# Multi-AI Review

Codex、Gemini、Claudeの3つのAIに並列でコードレビューを依頼し、統合レポートを生成する。

## 呼び出し方法

```
/multi-ai-review
```

ユーザーからの指示例:
- 「developまでの差分をレビューして」
- 「HEAD~5 の差分をマルチAIレビュー」
- 「src/app/page.tsx をレビューして」

## 実行手順（Claude Code が実行）

1. **レビュー対象を確認** - ユーザーに `--diff <branch>` か ファイル指定か確認
2. **3つの AI を並列実行** - スクリプトを Bash で実行
   ```bash
   .claude/skills/multi-ai-review/scripts/run-multi-ai-review.sh --diff <branch>
   ```
3. **結果を収集** - 3つの AI の出力を読み取り
4. **統合レポートを生成・保存** - `results/<timestamp>/report.md` に保存

## スクリプト一覧

| スクリプト | 説明 |
|-----------|------|
| `scripts/run-multi-ai-review.sh` | Codex + Gemini + Claude を並列実行（メイン） |
| `scripts/codex-review.sh` | Codex 単体でレビュー実行 |
| `scripts/gemini-review.sh` | Gemini 単体でレビュー実行 |
| `scripts/claude-review.sh` | Claude 単体でレビュー実行 |
| `scripts/add-to-gitignore.sh` | results/ を .gitignore に追加（任意） |

## 使い方

### 基本: ブランチ/コミットとの差分をレビュー

```bash
# developブランチとの差分をレビュー（3つの AI 並列）
.claude/skills/multi-ai-review/scripts/run-multi-ai-review.sh --diff develop

# 特定コミットとの差分
.claude/skills/multi-ai-review/scripts/run-multi-ai-review.sh --diff abc1234

# 直近5コミット
.claude/skills/multi-ai-review/scripts/run-multi-ai-review.sh --diff HEAD~5
```

### ファイルを直接指定

```bash
.claude/skills/multi-ai-review/scripts/run-multi-ai-review.sh src/app/page.tsx src/lib/utils.ts
```

### 単体で実行

```bash
# Codex のみ
.claude/skills/multi-ai-review/scripts/run-multi-ai-review.sh --codex-only --diff develop

# Gemini のみ
.claude/skills/multi-ai-review/scripts/run-multi-ai-review.sh --gemini-only --diff develop

# Claude のみ
.claude/skills/multi-ai-review/scripts/run-multi-ai-review.sh --claude-only --diff develop
```

### 特定の AI を除外

```bash
# Claude を除外（Codex + Gemini のみ）
.claude/skills/multi-ai-review/scripts/run-multi-ai-review.sh --no-claude --diff develop

# Codex を除外（Gemini + Claude のみ）
.claude/skills/multi-ai-review/scripts/run-multi-ai-review.sh --no-codex --diff develop
```

### レビュー結果のディレクトリ名を指定

```bash
.claude/skills/multi-ai-review/scripts/run-multi-ai-review.sh --diff develop --name my-feature-review
# → .claude/skills/multi-ai-review/results/20250127_130000_my-feature-review/ に出力
```

## コマンドオプション

| オプション | 説明 | 例 |
|-----------|------|-----|
| `-d, --diff REF` | 指定したコミット/ブランチとの差分 | `--diff develop` |
| `-c, --codex-only` | Codex のみ実行 | `--codex-only --diff develop` |
| `-m, --gemini-only` | Gemini のみ実行 | `--gemini-only --diff develop` |
| `-l, --claude-only` | Claude のみ実行 | `--claude-only --diff develop` |
| `--no-codex` | Codex を除外 | `--no-codex --diff develop` |
| `--no-gemini` | Gemini を除外 | `--no-gemini --diff develop` |
| `--no-claude` | Claude を除外 | `--no-claude --diff develop` |
| `-n, --name NAME` | ディレクトリ名を指定 | `--name my-feature` |
| `-h, --help` | ヘルプを表示 | |

### 環境変数

| 変数 | デフォルト | 説明 |
|------|-----------|------|
| `OUTPUT_DIR` | `results/$REVIEW_NAME` | 結果の出力先（完全パス指定時） |
| `WORK_DIR` | `$(pwd)` | 作業ディレクトリ |

## 出力先

結果は `.claude/skills/multi-ai-review/results/<YYYYMMDD_HHMMSS>/` に保存される。

```
.claude/skills/multi-ai-review/results/
└── 20250127_124500/
    ├── codex_review.md    # Codex の結果
    ├── gemini_review.md   # Gemini の結果
    ├── claude_review.md   # Claude の結果
    └── report.md          # 統合レポート（Claude Code が生成）
```

## 結果の確認

```bash
# 最新のレビュー結果ディレクトリを確認
ls -lt .claude/skills/multi-ai-review/results/ | head -5

# 結果を読み取り
cat .claude/skills/multi-ai-review/results/<timestamp>/codex_review.md
cat .claude/skills/multi-ai-review/results/<timestamp>/gemini_review.md
cat .claude/skills/multi-ai-review/results/<timestamp>/claude_review.md
```

## 統合レポートの生成

レビュー完了後、以下の形式で統合レポートを生成し、**必ずファイルに保存する**:

**出力先**: `.claude/skills/multi-ai-review/results/<timestamp>/report.md`

```markdown
# Multi-AI Code Review Report

## 概要
- **レビュー対象**: [ファイルリスト]
- **レビュー実行AI**: Codex, Gemini, Claude
- **レビュー日時**: [YYYY-MM-DD HH:MM]

---

## 評価サマリー

| AI | 総合評価 | 主な指摘 |
|----|---------|---------|
| Codex | [S/A/B/C/D] | [1行サマリー] |
| Gemini | [S/A/B/C/D] | [1行サマリー] |
| Claude | [S/A/B/C/D] | [1行サマリー] |

---

## AI間の比較分析

### 共通して指摘された問題点
[3つのAIが共通して指摘した問題]

### AI固有の視点
| AI | 独自の指摘・視点 |
|----|-----------------|
| Codex | [Codex独自の視点] |
| Gemini | [Gemini独自の視点] |
| Claude | [Claude独自の視点] |

### 改善提案の優先度（統合）
| 優先度 | 改善項目 | 指摘AI |
|--------|---------|--------|
| 高 | [項目] | Codex, Gemini, Claude |
| 中 | [項目] | Gemini, Claude |
| 低 | [項目] | Codex |

---

## 次のアクション
1. [最優先で対応すべき項目]
2. [次に対応すべき項目]
3. [余裕があれば対応する項目]
```

## トラブルシューティング

### Codex がパニックを起こす場合

Claude Code のサンドボックス環境で発生する場合がある。
Bash ツールで `dangerouslyDisableSandbox: true` を指定して実行。

### Gemini が認証エラーを出す場合

```bash
gemini auth login
```

### タイムアウトする場合

ファイル数を減らすか、重要なファイルのみに絞って実行（推奨: 20ファイル以下）。

## 注意事項

1. **並列実行**: Codex、Gemini、Claude はスクリプトで並列実行される
2. **認証**: Codex、Gemini、Claude CLI は事前にログイン済みであること

## .gitignore への追加（任意）

レビュー結果を Git 管理から除外したい場合:

```bash
.claude/skills/multi-ai-review/scripts/add-to-gitignore.sh
```
