---
name: ci-check
description: 全パッケージの lint・fmt・test・audit を実行し、エラーがあれば修正する
disable-model-invocation: false
---

# Check Runner (Lint / Format / Test)

全パッケージの lint、フォーマットチェック、テスト、セキュリティ監査を一括実行し、問題があれば修正する。

## Instructions

1. **まず `.claude/scripts/ci-check.sh` を実行**して全チェックを一括実行
2. エラーがあれば内容を分析し、修正を実施する
3. 修正後、再度スクリプトを実行して問題が解消されたことを確認する

---

## Quick Start

```bash
.claude/skills/ci-check/scripts/run.sh
```

これで全パッケージの lint / fmt:check / test を一括実行できる。

---

## Commands

すべてのコマンドはプロジェクトルートからの相対パスで実行する。

### 1. Lint

```bash
cd packages/web && pnpm run lint
cd packages/server && pnpm run lint
cd packages/shared && pnpm run lint
```

| Package  | Tool                       |
| -------- | -------------------------- |
| `web`    | `next lint` (ESLint)       |
| `server` | `tsc --noEmit` (TypeCheck) |
| `shared` | `tsc --noEmit` (TypeCheck) |

### 2. Format Check

```bash
cd packages/web && pnpm run fmt:check
cd packages/server && pnpm run fmt:check
cd packages/shared && pnpm run fmt:check
```

違反がある場合の自動修正:

```bash
cd packages/<package> && pnpm run fmt
```

- `fmt` = `prettier --write .`（ファイル直接書き換え）
- `fmt:check` = `prettier --check .`（チェックのみ）
- web パッケージは `prettier-plugin-tailwindcss` を使用

### 3. Test

```bash
cd packages/server && pnpm run test
```

- テストは `packages/server` のみ（Vitest）
- テストファイル: `packages/server/src/__tests__/**/*.test.ts`
- カバレッジ: `pnpm run test:coverage`

### 4. Audit

```bash
cd packages/web && pnpm audit --audit-level=moderate
cd packages/server && pnpm audit --audit-level=moderate
```

- `--audit-level=moderate` で moderate 以上の脆弱性を検出
- 直接依存のバージョンアップで解決できない場合は `pnpm.overrides` で対応
- overrides は対象パッケージの `package.json` の `pnpm.overrides` に記述

---

## Execution Flow

1. **並列実行**: 3 パッケージの lint + fmt:check + test + audit を同時に実行
2. **結果確認**: 各チェックの pass/fail を確認
3. **修正**:
   - **Lint エラー**: 型定義・ESLint ルール違反を修正（web は `next lint --fix` 可）
   - **Format 違反**: `pnpm run fmt` で自動修正
   - **Test 失敗**: エラーメッセージを分析し、テストコードまたはソースコードを修正
4. **再検証**: 修正後に該当チェックを再実行して確認
