# dist — `.skill` バンドル

Claude Code のプラグインとしてではなく、**Claude Design / claude.ai の Skills にそのままアップロードできる形式**で配布するためのディレクトリ。

`.skill` は ZIP アーカイブで、中身は次の構造になっている。

```
<skill-name>/
├── SKILL.md
└── references/
    └── ...
```

## インストール手順（Claude Design / claude.ai）

1. このディレクトリの `.skill` ファイルをダウンロードする
   （例: https://github.com/sean-sunagaku/claude-code-plugin/raw/main/dist/ios-hig-prototype.skill ）
2. claude.ai の **Settings → Capabilities → Skills** を開く
3. **Upload skill** から `.skill` ファイルを選択する
4. 会話で該当スキルが自動的に呼び出されるようになる

> Claude Code で使う場合は `.skill` は不要。マーケットプレイス経由でインストールする。
>
> ```bash
> claude plugin add github:sean-sunagaku/claude-code-plugin
> ```

## 収録スキル

| ファイル | 説明 |
|---------|------|
| `ios-hig-prototype.skill` | Apple HIG 準拠の iOS アプリ UI を、単一 HTML の動くインタラクティブプロトタイプとして生成 |

## 再生成

SKILL.md や references/ を更新したら `.skill` も作り直す（中身は ZIP なので自動追従しない）。

```bash
.github/scripts/package-skill.sh design/ios-hig-prototype/skills/ios-hig-prototype
```

出力先を変える場合は第 2 引数を渡す。リポジトリ内の全スキルをまとめてパッケージするには `--all` を使う（`.internal/` 配下は作者用のため対象外）。

```bash
.github/scripts/package-skill.sh --all dist
```

## バリデーション仕様

パッケージ前に frontmatter を Anthropic Agent Skills 仕様で検証する。

- 許可キー: `name` / `description` / `license` / `allowed-tools` / `metadata` / `compatibility`
- `name`: kebab-case、64 文字以内、ディレクトリ名と一致
- `description`: 1024 文字以内、山括弧（`<` `>`）を含まない

## パッケージ時の自動変換

Claude Code では有効だが `.skill` 仕様には存在しない要素は、**パッケージ時だけ**変換する。
リポジトリ内の SKILL.md は一切変更しないので、Claude Code 側の挙動はそのまま維持される。

| 対象 | 変換内容 | 影響 |
|------|---------|------|
| `disable-model-invocation` / `model` / `context` / `agent` | `.skill` から除去 | claude.ai 側では自動呼び出し制御やモデル指定が効かない |
| 1024 文字を超える `description` | `Triggers:` の末尾から順に削って収める（要約や書き換えはしない） | claude.ai 側で末尾の trigger 語による発火がなくなる |

変換が発生した場合は実行時に `WARN` として出力される。

