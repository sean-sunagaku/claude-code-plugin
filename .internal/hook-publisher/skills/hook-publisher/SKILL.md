---
name: hook-publisher
description: >
  Hook スクリプトを claude-code-plugin リポジトリの正しい構造に配置するスキル。
  hook の構造検証、既存 hook との重複チェック、plugin.json 生成、marketplace.json 登録を行う。
  Use when: hook をプラグインリポジトリに公開したい、hook を移動したい、hook をパッケージ化したい。
  Triggers: "hook を公開", "hook publish", "hook をプラグインに追加",
  "PostToolUse hook を配置", "hook をコピー", "hook publisher"
---

# Hook Publisher

Hook スクリプトを claude-code-plugin リポジトリの正しい構造に配置する。

## 対象リポジトリ

```
PLUGIN_REPO=/Users/babashunsuke/Desktop/claude-code-plugin
```

## リポジトリ構成（Hook プラグイン）

```
claude-code-plugin/
├── <hook-plugin-name>/        # 公開用
│   ├── hooks/
│   │   └── <hook-name>/
│   │       ├── hook.py (or hook.sh)
│   │       └── test.py (or test.sh)
│   └── plugin.json            # hook 設定 + メタデータ
├── .internal/                 # 内部用
│   └── <hook-plugin-name>/
│       ├── hooks/...
│       └── plugin.json
└── .claude-plugin/
    └── marketplace.json
```

### plugin.json の構成

Hook プラグインの plugin.json には hook の登録設定を含める:

```json
{
  "name": "<hook-plugin-name>",
  "version": "<version>",
  "description": "...",
  "hooks": {
    "<HookEvent>": [
      {
        "matcher": "<ToolName>",
        "hooks": [
          {
            "type": "command",
            "command": "python3 \"$HOME/.claude/plugins/cache/<marketplace>/<hook-plugin-name>/<version>/hooks/<hook-name>/hook.py\""
          }
        ]
      }
    ]
  }
}
```

HookEvent: `PreToolUse`, `PostToolUse`, `Stop` など。

### ポータブルな command パスのルール

**重要**: hook の command は**プロジェクトの cwd から相対パス**で実行される。
プラグインのキャッシュディレクトリは自動解決されないため、以下のルールに従うこと:

1. **`$HOME` を使う** - ユーザー間でポータブルにするため絶対パスの先頭は `$HOME` にする
2. **キャッシュパスの構造**: `$HOME/.claude/plugins/cache/<marketplace>/<plugin-name>/<version>/hooks/<hook-name>/hook.py`
3. **バージョンはハードコード OK** - plugin.json はバージョンごとにパッケージされるため、version 部分はそのバージョンの値を直接書く
4. **marketplace 名を含める** - 例: `sunagaku-marketplace`

例（sunagaku-marketplace の agent-teams-log v1.0.0）:
```
python3 "$HOME/.claude/plugins/cache/sunagaku-marketplace/agent-teams-log/1.0.0/hooks/log-agent-messages/hook.py"
```

**NG パターン（プロジェクトローカル依存）**:
```
python3 .claude/hooks/log-agent-messages/hook.py
```
→ プロジェクトにファイルがないと動かない。プラグインのインストールだけで完結しない。

## ワークフロー

### Step 1: ソース hook の特定と配置先の確認

ユーザーに以下を確認:
- コピー元の hook パス（例: `.claude/hooks/log-agent-messages/`）
- hook イベント（PostToolUse, PreToolUse, Stop 等）
- matcher（SendMessage 等。空文字なら全ツール対象）
- 実行コマンド（`python3 .claude/hooks/<name>/hook.py` 等）
- **配置先**: 公開用（ルート直下）か 内部用（`.internal/` 配下）か

### Step 2: 構造検証

検証スクリプト: `scripts/validate-hook.sh <hook-path>`

検証内容:
1. hook スクリプト（hook.py or hook.sh）が存在するか
2. テスト（test.py or test.sh）が存在するか
3. スクリプトに構文エラーがないか

### Step 3: 重複チェック

PLUGIN_REPO に同名の hook プラグインが既に存在するか確認。
存在する場合はユーザーに上書きするか確認。

### Step 4: コピー・配置

配置スクリプトを実行:

```bash
# 公開用
scripts/publish-hook.sh <source-path> <plugin-name> <hook-event> <matcher> <command>

# 内部用
scripts/publish-hook.sh <source-path> <plugin-name> <hook-event> <matcher> <command> --internal
```

- `source-path`: コピー元（hook.py があるディレクトリ）
- `plugin-name`: プラグイン名（例: agent-teams-log）
- `hook-event`: PostToolUse, PreToolUse, Stop 等
- `matcher`: ツール名マッチャー（例: SendMessage）。空文字なら全ツール対象
- `command`: 実行コマンド（`$HOME` ベースのキャッシュパスを使う。上記「ポータブルな command パスのルール」参照）
- `--internal`: .internal/ 配下に配置

スクリプトが行うこと:
1. 正しいディレクトリ構造を作成しファイルをコピー
2. plugin.json を生成（hook 設定含む）
3. marketplace.json にプラグインを登録

### Step 5: 配置確認

コピー後に構造を表示し、正しく配置されたか確認する。
marketplace.json の登録内容も表示して確認する。
