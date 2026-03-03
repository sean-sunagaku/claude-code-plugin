---
name: skill-publisher
description: >
  ~/.claude/skills/ や任意のパスにあるスキルを claude-code-plugin リポジトリの
  正しいディレクトリ構造 (<category>/<name>/skills/<name>/SKILL.md) にコピー・配置するスキル。
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
├── <category>/                # カテゴリ別ディレクトリ
│   └── <skill-name>/         # 公開用
│       ├── .claude-plugin/
│       │   └── plugin.json   # プラグインメタデータ（CI 必須）
│       ├── agents/            # サブエージェント定義（あれば）
│       │   └── <agent-name>.md
│       └── skills/<skill-name>/
│           ├── SKILL.md
│           ├── references/  (あれば)
│           ├── scripts/     (あれば)
│           └── assets/      (あれば)
├── .internal/                 # 内部用（自分のリポジトリ向け）
│   └── <skill-name>/
│       ├── .claude-plugin/
│       │   └── plugin.json    # CI 必須
│       └── skills/<skill-name>/...
└── .claude-plugin/
    └── marketplace.json       # スキル登録設定（公開・内部どちらも登録が必要）
```

### カテゴリ一覧

| カテゴリ | 内容 |
|---------|------|
| `product` | プロダクト企画・ユーザーリサーチ |
| `planning` | 機能検討・技術設計・実装計画 |
| `design` | UI/UXデザイン・ロゴ作成 |
| `development` | CI/CD・DB・Git・デバッグ・テスト |
| `review` | コードレビュー・品質チェック |
| `marketing` | アプリ名・ASO・スクリーンショット |
| `agent-toolkit` | エージェントチーム構築・運用 |

### agents/ について

- `agents/` は plugin root 直下に配置（`<skill-name>/agents/`）
- 各 `.md` ファイルは YAML frontmatter（`name`, `description`, `tools`, `model` 等）+ システムプロンプト
- プラグインインストール時に自動検出される（`plugin.json` への明示記載は不要）

## ワークフロー

### Step 1: ソーススキルの特定と配置先の確認

ユーザーに以下を確認:
- コピー元のスキルパス（例: `~/.claude/skills/app-naming/`）
- または `~/.claude/skills/` 内のスキル一覧から選択
- **カテゴリ**: 公開用の場合、どのカテゴリに配置するか（product, planning, design, development, review, marketing, agent-toolkit）
- **配置先**: 公開用（カテゴリ配下）か 内部用（`.internal/` 配下）か
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
# 公開用（カテゴリ配下に配置）
scripts/publish-skill.sh <source-path> [skill-name] --category <category>

# Beta として公開
scripts/publish-skill.sh <source-path> [skill-name] --category <category> --beta

# 内部用（.internal/ 配下に配置）
scripts/publish-skill.sh <source-path> [skill-name] --internal
```

- `source-path`: コピー元（SKILL.md があるディレクトリ）
- `skill-name`: 省略時は source-path のディレクトリ名を使用
- `--category`: カテゴリ名（公開用は必須。product, planning, design, development, review, marketing, agent-toolkit）
- `--beta`: Beta スキルとして配置（description に `[Beta]` プレフィックス付与）
- `--internal`: 内部用として `.internal/` 配下に配置（カテゴリ不要）

スクリプトが行うこと:
1. 正しいディレクトリ構造を作成しファイルをコピー
2. `agents/` があれば plugin root 直下にコピー
3. `.claude-plugin/plugin.json` があればコピー、**なければ SKILL.md から自動生成**（CI 必須）
4. 不要ファイル（README.md, CHANGELOG.md 等）を除外
5. `.claude-plugin/marketplace.json` にスキルを自動登録
6. `--beta` の場合: description に `[Beta]` プレフィックス付与

### marketplace.json 登録時の自動処理

- **description 要約**: SKILL.md の description から `Use when:` / `Triggers:` 以降を自動カットし、要約版を登録
- **version 自動取得**: `.claude-plugin/plugin.json` の version を使用（なければ `1.0.0`）
- SKILL.md の description はフル版のまま維持（Claude のスキルマッチングに使用）

### Beta スキルのルール

- description が `[Beta] ` で始まること（バリデーションで検証される）
- marketplace.json スキーマは `name, source, description, version, author, keywords` のみ許可（`"status"` 等の追加フィールドは不可）
- stable に昇格する際は `[Beta]` プレフィックスを除去

### Step 5: 配置確認

コピー後に構造を表示し、正しく配置されたか確認する。
marketplace.json の登録内容も表示して確認する。
