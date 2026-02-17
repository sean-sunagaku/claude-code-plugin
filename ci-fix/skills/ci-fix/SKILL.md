---
name: ci-fix
description: >
  GitHub Actions の CI 失敗を検出・修正・再検証するスキル。
  gh コマンドで PR の CI 状態を確認し、失敗時はログを取得して原因を分析、
  コードを修正して push、CI が通るまでループする。
  Use when: CI が落ちた、CI を直したい、PR のチェックが失敗している、
  GitHub Actions のエラーを修正したい、CI を通したい。
  Triggers: "CI", "ci-fix", "CI落ちた", "CI失敗", "checks failed",
  "GitHub Actions", "workflow failed", "CI通して", "CI修正"
---

# CI Fix

CI 失敗の検出 → ログ取得 → 修正 → push → 再検証のループを自動実行する。

## Workflow

```
1. check-ci.sh で CI 状態を確認
2. 失敗あり → ログを分析して原因特定
3. コードを修正
4. commit & push
5. wait-ci.sh で CI 完了を待機
6. まだ失敗 → 1 に戻る
```

## Scripts

| Script | 用途 |
|---|---|
| `scripts/check-ci.sh [PR番号]` | CI 状態確認 + 失敗ログ取得 |
| `scripts/wait-ci.sh [PR番号] [最大秒数]` | CI 完了まで待機（デフォルト 300s） |

PR 番号省略時は現在のブランチの PR を自動検出する。

## Instructions

### Step 1: CI 状態確認

```bash
bash <skill-path>/scripts/check-ci.sh
```

出力の `RESULT:` 行で分岐:
- `all_passed` → 完了。ユーザーに報告して終了
- `pending` → `wait-ci.sh` で待機してから再度 `check-ci.sh`
- `failed` → Step 2 へ

### Step 2: ログ分析

`check-ci.sh` の出力に失敗ログが含まれる。ログが不十分な場合:

```bash
gh run view <run-id> --log-failed
```

エラーの種類を特定:
- **lint / format** → コード修正
- **test failure** → テストまたはソースコード修正
- **build error** → 依存関係やコンパイルエラー修正
- **structure validation** → 設定ファイルやディレクトリ構造の修正

### Step 3: 修正

分析結果に基づきコードを修正する。修正前に関連ファイルを読んで変更の影響を理解する。

### Step 4: commit & push

```bash
git add <修正ファイル>
git commit -m "fix: <修正内容の要約>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push
```

### Step 5: CI 再検証

```bash
bash <skill-path>/scripts/wait-ci.sh
```

- `all_passed` → 完了。ユーザーに報告
- `failed` → Step 1 に戻る（最大 3 回まで）
- `timeout` → `check-ci.sh` で現状を確認してユーザーに報告

### Retry 上限

修正→再検証のループは **最大 3 回** まで。3 回で解決しない場合はユーザーに状況を報告して判断を仰ぐ。
