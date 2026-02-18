---
name: ci-check
description: >
  .github/workflows/*.yml を自動解析し、CI で定義されたチェックをローカル実行する汎用スキル。
  lint・fmt・test・build・audit 等に限定せず、ワークフローの run ステップを抽出して実行する。
  エラーがあれば修正し、再実行して確認する。
  Use when: CI を通したい、lint/test を実行したい、CI チェックしたい、
  ワークフローをローカルで試したい。
  Triggers: "CI", "ci-check", "lint", "test", "format", "fmt", "audit",
  "チェック", "検証", "CI 通して", "テスト実行", "ビルド確認"
---

# CI Check

`.github/workflows/*.yml` を解析し、CI 定義のチェックをローカル実行する。

## ワークフロー

### Step 1: CI 定義の確認

```bash
# 実行可能なステップを一覧表示
scripts/run.sh --list
```

`--list` で以下を表示:
- **RUN**: ローカル実行可能なステップ（`run:` コマンド）
- **SKIP**: ローカル実行不可（GitHub Actions、deploy、secrets 依存）

### Step 2: 実行

```bash
# 全ワークフローを実行
scripts/run.sh

# 特定のワークフローのみ
scripts/run.sh validate.yml

# dry-run（コマンド確認のみ）
scripts/run.sh --dry-run
```

スクリプトが自動で行うこと:
- `.github/workflows/*.yml` の `run:` ステップを抽出
- `working-directory:` を尊重して実行ディレクトリを切り替え
- deploy/secrets 依存/GitHub Actions (`uses:`) を自動スキップ
- 各ステップの pass/fail を表示

### Step 3: エラー修正

失敗したステップがあれば:

1. エラー出力を分析して原因を特定
2. ソースコードを修正
3. 失敗したステップだけ再実行して確認

### Step 4: 全体再検証

```bash
scripts/run.sh
```

## スキップされるステップ

以下のパターンを含む `run:` コマンドは自動スキップ:

| パターン | 理由 |
|----------|------|
| `deploy`, `firebase`, `aws`, `gcloud` | デプロイ系 |
| `docker push` | レジストリ操作 |
| `secrets.`, `GITHUB_TOKEN`, `GCP_SA_KEY` | シークレット依存 |
| `gh pr`, `gh issue` | GitHub API 操作 |
| `uses:` (GitHub Actions) | ローカル実行不可 |

## Claude が直接ワークフローを読む場合

スクリプトで対応できない複雑なケース（matrix、env 変数、条件分岐など）は、
`.github/workflows/*.yml` を直接 Read して判断する:

1. `Glob` で `.github/workflows/*.yml` を検索
2. 各ファイルを `Read` して jobs/steps を確認
3. `run:` ステップの内容と `working-directory` を把握
4. ローカルで実行可能なコマンドを `Bash` で実行
5. `if:` 条件や `matrix` がある場合は適切に展開

### 判断基準

- **実行する**: `npm run`, `pnpm run`, `yarn`, `bash`, `chmod +x && ./script.sh`, `python`
- **スキップ**: `uses:` (Actions), secrets 参照, deploy/push 系, `gh` CLI (API操作)
- **確認する**: `env:` にローカルで設定可能な値があるか、`if:` 条件を満たすか
