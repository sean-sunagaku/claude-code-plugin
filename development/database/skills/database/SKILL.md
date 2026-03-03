---
name: database
description: Drizzle ORM を使ったデータベーススキーマの管理とマイグレーションの実行方法
---

# Database Management (Drizzle ORM)

Drizzle ORM を使ったデータベーススキーマの管理とマイグレーションに関するガイド。

## 絶対に守るべきルール

### 禁止事項

1. **手動でマイグレーションSQLファイルを作成しない**
   - `drizzle/` ディレクトリに直接 `.sql` ファイルを作成してはいけない
   - 必ず `pnpm db:generate` で自動生成する

2. **手動でDBを直接操作しない**
   - `sqlite3` コマンドで直接 `ALTER TABLE` などを実行しない
   - 必ずマイグレーション経由で変更する

3. **`drizzle/meta/_journal.json` を手動で編集しない**
   - これは `drizzle-kit` が自動管理するファイル

### 必須事項

1. **スキーマ変更は必ず `schema.ts` から始める**
2. **マイグレーションは必ず `pnpm db:generate` で生成する**
3. **生成されたマイグレーションファイルは必ずコミットする**

---

## スキーマ変更の正しい手順

### Step 1: スキーマを編集

`packages/server/src/db/schema.ts` を編集する。

```typescript
// 例: sessions テーブルに新しいカラムを追加
export const sessions = sqliteTable('sessions', {
  id: text('id').primaryKey(),
  // ... 既存のカラム
  newColumn: text('new_column'),  // 追加
});
```

### Step 2: マイグレーションファイルを生成

```bash
cd packages/server
pnpm db:generate
```

これで `drizzle/XXXX_<random_name>.sql` が自動生成される。

### Step 3: マイグレーションを適用

開発環境では、サーバー起動時に自動適用される:

```bash
pnpm dev
```

または手動で適用:

```bash
pnpm db:migrate
```

### Step 4: 動作確認

サーバーを起動して、エラーがないことを確認。

---

## Project Structure

```
packages/server/
├── drizzle.config.ts      # Drizzle Kit 設定
├── drizzle/               # マイグレーションファイル (自動生成)
│   ├── 0000_init.sql
│   ├── 0001_xxx.sql
│   └── meta/              # マイグレーションメタデータ (自動管理)
│       ├── _journal.json
│       └── XXXX_snapshot.json
└── src/
    └── db/
        ├── schema.ts      # スキーマ定義 (これを編集)
        └── index.ts       # DB接続・マイグレーション実行
```

---

## Commands

すべてのコマンドは `packages/server` ディレクトリから実行する。

| コマンド | 説明 |
|---------|------|
| `pnpm db:generate` | スキーマからマイグレーションファイルを自動生成 |
| `pnpm db:migrate` | マイグレーションを適用 |
| `pnpm db:push` | スキーマを直接DBに反映 (開発用のみ) |
| `pnpm db:studio` | Drizzle Studio (DB GUI) を起動 |

---

## Runtime Migration

アプリケーション起動時に `initializeDatabase()` が呼ばれ、未適用のマイグレーションが自動実行される。

```typescript
// packages/server/src/db/index.ts
import { migrate } from 'drizzle-orm/better-sqlite3/migrator';

export function initializeDatabase(): void {
  migrate(db, { migrationsFolder: './drizzle' });
}
```

---

## Troubleshooting

### マイグレーションが適用されない

1. `drizzle/meta/_journal.json` にエントリがあるか確認
2. 手動でSQLファイルを作成していないか確認
3. DBを一度リセット: `rm .brandize/brandize.db && pnpm dev`

### DBをリセットしたい

```bash
rm packages/server/.brandize/brandize.db
pnpm dev  # 再起動で再作成
```

---

## 既存テーブル

| テーブル | 説明 | 主要カラム |
|---------|------|-----------|
| `projects` | プロジェクト管理 | id, name, description, working_dir |
| `sessions` | 会話セッション | id, project_id, title, type, topic |
| `messages` | メッセージ履歴 | id, session_id, role, content |
| `logos` | ロゴ生成履歴 | id, project_id, brand_name, svg |
| `worktrees` | Git worktree 管理 | id, project_id, branch_name, path |
| `project_configs` | プロジェクト設定 | id, project_id, brand_name, etc. |
