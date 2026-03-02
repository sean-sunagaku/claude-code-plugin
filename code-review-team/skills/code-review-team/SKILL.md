---
name: code-review-team
description: >
  5つの専門エージェント（backend-reviewer, frontend-reviewer, test-reviewer,
  security-reviewer, ux-reviewer）がチームでコードレビューするスキル。
  git diff ベースで変更ファイルを検出し、各専門家が並列でレビューして
  統合レポート（Markdown）を docs/reviews/ に出力する。
  Use when: コードレビューしたい、変更をレビュー、レビューチーム、
  チームレビュー、実装をチェック、品質チェック。
  Triggers: "レビュー", "review", "コードレビュー", "code review",
  "チームレビュー", "team review", "変更をチェック", "品質チェック"
---

# Code Review Team

5つの専門エージェントが並列でコードレビューし、統合レポートを生成する。

## レビュアー構成

| name | 役割 | 主な観点 |
|------|------|---------|
| `backend-reviewer` | サーバーサイド専門 | API設計, DB, パフォーマンス |
| `frontend-reviewer` | フロントエンド専門 | React/Next.js, i18n, 型安全性 |
| `test-reviewer` | テスト・ビルド専門 | カバレッジ, 型チェック, テスト実行 |
| `security-reviewer` | セキュリティ専門 | OWASP, インジェクション, 認証 |
| `ux-reviewer` | UX・アクセシビリティ専門 | ユーザーフロー, a11y, i18n整合 |

各エージェントは `agents/` ディレクトリにサブエージェントとして定義済み。
レビュー基準の詳細は `references/review-criteria.md` を参照。

## ワークフロー

### Step 1: レビュー対象の特定

ユーザーに確認する情報:
- **比較対象**: ブランチ名 or コミット（デフォルト: `main`）
- **スコープ**: 全変更 or 特定パッケージ

```bash
# 変更ファイル一覧を取得
git diff --name-only <base>...HEAD

# パッケージ別に分類
# packages/server/** → backend-reviewer, security-reviewer, test-reviewer
# packages/web/**    → frontend-reviewer, ux-reviewer, test-reviewer
# packages/shared/** → backend-reviewer, frontend-reviewer, test-reviewer
```

### Step 2: チーム作成とタスク割り当て

TeamCreate で `code-review-team` チームを作成。

TaskCreate で5つのタスクを作成（全て並列実行可能）:

1. **backend-reviewer**: サーバー側変更のレビュー
2. **frontend-reviewer**: フロントエンド変更のレビュー
3. **test-reviewer**: テストカバレッジ・ビルド検証
4. **security-reviewer**: セキュリティ脆弱性スキャン
5. **ux-reviewer**: UX・a11y・i18n レビュー

各タスクの description に以下を含める:
- 変更ファイル一覧（担当分）
- 比較対象ブランチ/コミット
- git diff の内容（主要部分）

### Step 3: エージェント起動

5つのエージェントを **1つのメッセージで並列に** Task ツールで起動する。

```
subagent_type: "code-review-team:backend-reviewer"
team_name: "code-review-team"
mode: "bypassPermissions"
run_in_background: true
model: opus
```

各エージェントのプロンプトには以下を含める:
- チーム名とタスクID
- レビュー対象ファイル一覧
- git diff の内容
- `references/review-criteria.md` の参照指示

### Step 4: レビュー結果の収集

全エージェントの完了を待ち、SendMessage で受信したレビュー結果を収集する。

### Step 5: 統合レポートの生成

以下の形式で統合レポートを作成し、`docs/reviews/` に保存する:

```markdown
# Code Review Report

## 概要
- **レビュー日時**: YYYY-MM-DD HH:MM
- **対象ブランチ**: <branch> vs <base>
- **変更ファイル数**: N files
- **レビュアー**: backend, frontend, test, security, ux

## 総合評価

| レビュアー | 評価 | Critical | Warning | Info |
|-----------|------|----------|---------|------|
| Backend   | A    | 0        | 2       | 1    |
| Frontend  | B    | 1        | 3       | 2    |
| Test      | A    | 0        | 1       | 0    |
| Security  | A    | 0        | 0       | 1    |
| UX        | B    | 0        | 2       | 3    |

評価基準: S(完璧) A(軽微な問題のみ) B(要修正あり) C(重大な問題) D(リジェクト)

## Critical Issues (修正必須)
[全レビュアーの Critical を集約]

## Warning Issues (修正推奨)
[全レビュアーの Warning を集約]

## Info (提案・改善)
[全レビュアーの Info を集約]

## 各レビュアーの詳細レポート
### Backend Review
[backend-reviewer の全文]

### Frontend Review
[frontend-reviewer の全文]

### Test & Build Review
[test-reviewer の全文]

### Security Review
[security-reviewer の全文]

### UX Review
[ux-reviewer の全文]

## 次のアクション
1. [Critical を最優先で修正]
2. [Warning を順次修正]
3. [Info は時間があれば対応]
```

### Step 6: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除
3. レポートのパスをユーザーに報告
