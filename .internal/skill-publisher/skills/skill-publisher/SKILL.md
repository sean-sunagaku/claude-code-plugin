---
name: skill-publisher
description: >
  ~/.claude/skills/ や任意のパスにあるスキルを claude-code-plugin リポジトリの
  正しいディレクトリ構造 (<name>/skills/<name>/SKILL.md) にコピー・配置するスキル。
  スキルの構造検証、既存スキルとの重複チェック、配置後の確認も行う。
  Use when: スキルをプラグインリポジトリに公開したい、スキルを移動したい、
  スキルをパッケージ化したい、スキルを整理したい。
  Triggers: "スキルを公開", "プラグインに追加", "skill publish", "スキルを移動",
  "claude-code-plugin に追加", "スキルをコピー", "パッケージ化"
---

# Skill Publisher

スキルを claude-code-plugin リポジトリの正しい構造に配置する。

## 対象リポジトリ

```
PLUGIN_REPO=/Users/babashunsuke/Desktop/claude-code-plugin
```

## リポジトリ構成

```
claude-code-plugin/
├── <skill-name>/              # 公開用
│   ├── agents/                # サブエージェント定義（あれば）
│   │   └── <agent-name>.md
│   └── skills/<skill-name>/
│       ├── SKILL.md
│       ├── references/  (あれば)
│       ├── scripts/     (あれば)
│       └── assets/      (あれば)
├── .internal/                 # 内部用（自分のリポジトリ向け）
│   └── <skill-name>/
│       └── skills/<skill-name>/...
└── .claude-plugin/
    └── marketplace.json       # スキル登録設定（公開・内部どちらも登録が必要）
```

### agents/ について

- `agents/` は plugin root 直下に配置（`<skill-name>/agents/`）
- 各 `.md` ファイルは YAML frontmatter（`name`, `description`, `tools`, `model` 等）+ システムプロンプト
- プラグインインストール時に自動検出される（`plugin.json` への明示記載は不要）

## ワークフロー

### Step 1: ソーススキルの特定と配置先の確認

ユーザーに以下を確認:
- コピー元のスキルパス（例: `~/.claude/skills/app-naming/`）
- または `~/.claude/skills/` 内のスキル一覧から選択
- **配置先**: 公開用（ルート直下）か 内部用（`.internal/` 配下）か
- **ステータス**: `stable`（デフォルト）か `beta` か
- **agents/**: ソースに `agents/` ディレクトリがあるか確認

### Step 2: 構造検証

コピー前に検証する:

1. `SKILL.md` が存在するか
2. YAML frontmatter に `name` と `description` があるか
3. references/ 内のファイルが SKILL.md から参照されているか

検証スクリプト: `scripts/validate-skill.sh <skill-path>`

### Step 3: 重複チェック

PLUGIN_REPO に同名のスキルが既に存在するか確認。
存在する場合はユーザーに上書きするか確認。

### Step 4: コピー・配置

配置スクリプトを実行:

```bash
# 公開用（ルート直下に配置）
scripts/publish-skill.sh <source-path> [skill-name]

# Beta として公開
scripts/publish-skill.sh <source-path> [skill-name] --beta

# 内部用（.internal/ 配下に配置）
scripts/publish-skill.sh <source-path> [skill-name] --internal
```

- `source-path`: コピー元（SKILL.md があるディレクトリ）
- `skill-name`: 省略時は source-path のディレクトリ名を使用
- `--beta`: Beta スキルとして配置（description に `[Beta]` プレフィックス付与、`"status": "beta"` を設定）
- `--internal`: 内部用として `.internal/` 配下に配置

スクリプトが行うこと:
1. 正しいディレクトリ構造を作成しファイルをコピー
2. `agents/` があれば plugin root 直下にコピー
3. 不要ファイル（README.md, CHANGELOG.md 等）を除外
4. `.claude-plugin/marketplace.json` にスキルを自動登録
5. `--beta` の場合: description に `[Beta]` プレフィックス付与、`"status": "beta"` を設定

### Beta スキルのルール

- marketplace.json の `status` フィールドが `"beta"` であること
- description が `[Beta] ` で始まること（バリデーションで検証される）
- README 生成時に「Beta Skills」として独立セクションに表示される
- stable に昇格する際は `status` フィールド削除 + `[Beta]` プレフィックス除去

### Step 5: 配置確認

コピー後に構造を表示し、正しく配置されたか確認する。
marketplace.json の登録内容も表示して確認する。
