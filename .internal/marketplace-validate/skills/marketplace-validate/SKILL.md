---
name: marketplace-validate
description: >
  [Internal] claude-code-plugin リポジトリの marketplace 構造を検証し、
  エラーを自動修正するスキル。CI バリデーション (validate-marketplace.sh) と
  同等のチェックをローカルで実行し、missing plugin.json、未登録スキル、
  frontmatter 不備などを検出・修正する。
  Use when: marketplace を検証したい、CI が失敗した、バリデーションしたい、
  プラグイン構造をチェックしたい、plugin.json がない、publish 後の確認。
  Triggers: "validate", "バリデーション", "検証", "CI失敗", "CI fix",
  "marketplace check", "構造チェック", "plugin.json missing", "CI エラー"
---

# Marketplace Validate

claude-code-plugin リポジトリの構造を検証し、エラーを自動修正する。

## 対象リポジトリ

```
PLUGIN_REPO=/Users/babashunsuke/Desktop/claude-code-plugin
VALIDATE_SCRIPT=$PLUGIN_REPO/.github/scripts/validate-marketplace.sh
FIX_SCRIPT=scripts/fix-marketplace.sh
```

## チェック項目

| # | チェック | 対象 |
|---|---------|------|
| 1 | marketplace.json が valid JSON | `.claude-plugin/marketplace.json` |
| 2 | 必須フィールド (name, version, description, owner) | marketplace.json トップレベル |
| 3 | 各プラグインの skill ディレクトリが存在 | `<source>/skills/<name>/` |
| 4 | SKILL.md が存在し frontmatter に name/description がある | 各スキル |
| 5 | `.claude-plugin/plugin.json` が存在し name が一致 | 各スキル |
| 6 | agents/ の各 .md に name/description frontmatter がある | Agent Team 型スキル |
| 7 | references/ のファイルが SKILL.md から参照されている | 各スキル |
| 8 | ディスク上に存在するが marketplace.json に未登録のスキル | 全体 |

## ワークフロー

### Step 1: バリデーション実行

```bash
bash $PLUGIN_REPO/.github/scripts/validate-marketplace.sh
```

出力の `ERROR:` と `WARN:` を確認する。

### Step 2: 自動修正

エラーがあれば fix スクリプトを実行:

```bash
# dry-run で修正内容を確認
bash scripts/fix-marketplace.sh --dry-run

# 実際に修正
bash scripts/fix-marketplace.sh
```

fix スクリプトが自動修正するもの:
- **missing plugin.json**: `~/.claude/skills/<name>/` にあればコピー、なければ marketplace.json から生成
- **plugin.json name 不一致**: marketplace.json の name に合わせて修正
- **orphaned entries**: ディレクトリが存在しない marketplace.json エントリを削除
- **unregistered skills**: ディスク上にあるが未登録のスキルを報告（手動対応）

### Step 3: 再バリデーション

修正後に再度バリデーションを実行し、全て PASSED になることを確認:

```bash
bash $PLUGIN_REPO/.github/scripts/validate-marketplace.sh
```

### Step 4: コミット

修正ファイルを確認してコミット。

## 手動修正が必要なケース

fix スクリプトで自動修正できないもの:

| 問題 | 対応 |
|------|------|
| SKILL.md の frontmatter に name/description がない | SKILL.md を直接編集 |
| agents/*.md の frontmatter 不備 | 各エージェントファイルを直接編集 |
| references/ の未参照ファイル | SKILL.md に参照を追加するか、不要なら削除 |
| unregistered skills | marketplace.json に登録するか、不要なら削除 |

## publish-skill.sh 実行後の推奨

`skill-publisher` でスキルを配置した後は、必ずこのスキルで検証する:

```bash
# publish 後
bash scripts/fix-marketplace.sh --dry-run
bash $PLUGIN_REPO/.github/scripts/validate-marketplace.sh
```
