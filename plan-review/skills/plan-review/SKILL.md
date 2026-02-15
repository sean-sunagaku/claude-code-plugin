---
name: plan-review
description: Codex、Gemini、Claude の3つの AI で Plan ファイルを並列レビュー。実装計画の妥当性、抜け漏れ、リスクを分析する。Plan 作成後に呼び出す。
---

# Plan Review

Codex、Gemini、Claude を使って Plan ファイルを並列レビューし、実装前に計画の品質を確認する。

## 呼び出し方法

```
/plan-review <plan_file_path>
```

または Plan モード終了直後に:

```
/plan-review
```
（直前に作成した Plan ファイルを自動検出）

## 実行手順（Claude Code が実行）

1. **Plan ファイルを特定**
   - 引数でパスが指定されていればそれを使用
   - 指定がなければ `docs/plans/` から最新のファイルを使用

2. **Codex + Gemini を並列実行**
   ```bash
   .claude/skills/plan-review/scripts/run-plan-review.sh <plan_file>
   ```

3. **Claude レビューを並列実行**
   - Task ツールで Claude サブエージェントを起動
   - 結果を `results/<timestamp>/claude_review.md` に保存

4. **結果を読み取り・統合レポート生成**
   - 3つの AI のレビュー結果を読み取り
   - 統合レポートを `results/<timestamp>/report.md` に保存
   - ユーザーに結果を報告

## スクリプト一覧

| スクリプト | 説明 |
|-----------|------|
| `scripts/run-plan-review.sh` | Codex + Gemini を並列実行（メイン） |
| `scripts/codex-plan-review.sh` | Codex 単体で Plan レビュー |
| `scripts/gemini-plan-review.sh` | Gemini 単体で Plan レビュー |

## Claude レビュー（Task ツール使用）

Claude Code の Task ツールでサブエージェントを起動:

```
Task tool パラメータ:
- subagent_type: "general-purpose"
- prompt: |
    以下の実装計画（Plan）をレビューしてください。

    対象ファイル: <plan_file_path>

    ## レビュー観点

    ### 1. 実装計画の妥当性
    - 要件に対して計画が適切か
    - 技術選定は妥当か
    - アーキテクチャ設計に問題はないか

    ### 2. 抜け漏れ
    - 考慮すべきエッジケースはないか
    - エラーハンドリングは考慮されているか
    - テスト計画は十分か

    ### 3. リスク
    - 実装上のリスクはないか
    - パフォーマンスへの影響はないか
    - セキュリティ上の懸念はないか

    ### 4. 改善提案
    - より良いアプローチはないか
    - 既存コードとの整合性は取れているか

    ## 出力形式

    ### 計画の妥当性
    [評価とコメント]

    ### 抜け漏れ・懸念点
    - [項目1]: 説明

    ### リスク
    - [リスク1]: 説明と対策案

    ### 改善提案
    - [提案1]: 説明

    ### 総合評価
    [S/A/B/C/D の5段階評価と理由]
```

**重要**: Task ツールの結果を `claude_review.md` に Write ツールで保存すること。

## コマンドオプション

| オプション | 説明 | 例 |
|-----------|------|-----|
| `-c, --codex-only` | Codex のみ実行 | `--codex-only plan.md` |
| `-g, --gemini-only` | Gemini のみ実行 | `--gemini-only plan.md` |
| `-n, --name NAME` | ディレクトリ名を指定 | `--name my-feature` |
| `-h, --help` | ヘルプを表示 | |

## 出力先

```
.claude/skills/plan-review/results/
└── 20250205_120000/
    ├── codex_review.md   # Codex のレビュー結果
    ├── gemini_review.md  # Gemini のレビュー結果
    ├── claude_review.md  # Claude のレビュー結果（Claude Code が生成）
    └── report.md         # 統合レポート（Claude Code が生成）
```

## レビュー観点

3つの AI は以下の観点で Plan をレビューする:

### 1. 実装計画の妥当性
- 要件に対して計画が適切か
- 技術選定は妥当か
- アーキテクチャ設計に問題はないか

### 2. 抜け漏れ
- 考慮すべきエッジケースはないか
- エラーハンドリングは考慮されているか
- テスト計画は十分か

### 3. リスク
- 実装上のリスクはないか
- パフォーマンスへの影響はないか
- セキュリティ上の懸念はないか

### 4. 改善提案
- より良いアプローチはないか
- 既存コードとの整合性は取れているか

## 統合レポートの生成

Claude Code が以下の形式で統合レポートを生成し、**必ずファイルに保存する**:

**出力先**: `.claude/skills/plan-review/results/<timestamp>/report.md`

```markdown
# Plan Review Report

## 概要
- **対象 Plan**: [ファイルパス]
- **レビュー AI**: Codex, Gemini, Claude
- **日時**: [YYYY-MM-DD HH:MM]

## 評価サマリー

| AI | 総合評価 | 主な指摘 |
|----|---------|---------|
| Codex | [S/A/B/C/D] | [1行サマリー] |
| Gemini | [S/A/B/C/D] | [1行サマリー] |
| Claude | [S/A/B/C/D] | [1行サマリー] |

## 共通して指摘された懸念点
[3つの AI が共通して指摘した問題]

## AI 固有の視点

| AI | 独自の指摘 |
|----|-----------|
| Codex | [Codex 独自の視点] |
| Gemini | [Gemini 独自の視点] |
| Claude | [Claude 独自の視点] |

## 改善提案の優先度（統合）

| 優先度 | 改善項目 | 指摘 AI |
|--------|---------|--------|
| 高 | [項目] | Codex, Gemini, Claude |
| 中 | [項目] | Gemini, Claude |
| 低 | [項目] | Codex |

## 推奨アクション
1. [最優先で対応すべき項目]
2. [次に対応すべき項目]
3. [余裕があれば対応する項目]
```

## 使用例

```bash
# 基本: Plan ファイルを3つの AI でレビュー
/plan-review docs/plans/my-feature.md

# Codex + Gemini のみ（スクリプト直接実行）
.claude/skills/plan-review/scripts/run-plan-review.sh docs/plans/my-feature.md

# Codex のみ
.claude/skills/plan-review/scripts/run-plan-review.sh --codex-only docs/plans/my-feature.md

# Gemini のみ
.claude/skills/plan-review/scripts/run-plan-review.sh --gemini-only docs/plans/my-feature.md
```

## 注意事項

1. **並列実行**: Codex と Gemini はスクリプトで並列実行、Claude は Task ツールで実行
2. **認証**: Codex、Gemini は事前にログイン済みであること
3. **結果保存**: Claude レビュー結果は Write ツールでファイル保存が必要
4. results/ は .gitignore に追加済み
