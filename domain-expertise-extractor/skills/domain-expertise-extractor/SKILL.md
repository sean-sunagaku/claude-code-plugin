---
name: domain-expertise-extractor
description: >
  デジタルプロダクト系の専門領域（UI/UX, マーケティング, コピーライティング, ASO, グロース等）の
  暗黙知を抽出・言語化・構造化し、他のSkillで使えるエージェント定義と評価基準を生成するスキル。
  素人では判断できない「良い/悪い」の基準を、AI が専門家レベルで調査・分析・言語化し、
  再利用可能なドメインナレッジとして出力する。
  Use when: 評価基準を作りたい、ドメイン知識を抽出したい、専門家の視点を言語化したい、
  暗黙知を構造化したい、ベストプラクティスを整理したい。
  Triggers: "ドメイン知識", "専門知識", "評価基準", "domain expertise",
  "expertise extract", "知識抽出", "暗黙知", "ベストプラクティス抽出",
  "評価基準を作りたい", "専門家の視点", "ドメインナレッジ",
  "domain knowledge", "expertise builder"
---

# Domain Expertise Extractor

4つの専門エージェントが連携して、デジタルプロダクト系ドメインの暗黙知を抽出・構造化する。
出力は `~/.claude/domain-knowledge/{domain-name}/` に保存され、他スキルから再利用可能。

## ワークフロー概要

```
Phase 1: ヒアリング（ドメイン名 + 参考事例の受け取り）
Phase 2: 並列調査 Round 1（domain-researcher + pattern-analyst 同時起動）
Phase 3: 中間レビュー（ユーザーに原則・エージェント構成を提示・承認）
Phase 4: 知識生成 Round 2（knowledge-writer が統合・ファイル生成）
Phase 5: 品質検証 Round 3（quality-checker がサンプル評価 + 網羅性確認）
Phase 6: ドラフト提示・最終承認（ユーザーフィードバック対応）
Phase 7: マージ処理（既存ナレッジとの統合）
```

## Phase 1: ヒアリング

以下を受け取る（不明ならユーザーに確認）:
- **ドメイン名**: 専門領域の名前（例: "LP キャッチコピー", "モバイルUI ナビゲーション"）
- **参考事例**（省略可）: URL / スクリーンショットパス / テキスト説明の任意の組み合わせ

入力タイプの自動判定:
- `https?://` で始まる → WebFetch で内容取得
- `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp` で終わる → Read で画像分析
- それ以外 → テキスト説明として処理

## Phase 2: 並列調査（Round 1）

TeamCreate で `domain-expertise-extractor` チームを作成。以下を **1メッセージで並列起動**:

| name | 役割 | モデル | 主な手段 |
|------|------|--------|---------|
| `domain-researcher` | ドメインの深い専門知識調査 | opus | WebSearch, WebFetch |
| `pattern-analyst` | 参考事例のパターン抽出 | sonnet | Read, Glob, 分析 |

各エージェントは `agents/` ディレクトリの定義を参照。

### タスク作成

TaskCreate で以下を作成:
1. `domain-researcher`: 専門知識・定量基準・業界標準の調査
2. `pattern-analyst`: 参考事例のパターン抽出（事例なし時は researcher 完了後に抽出）
3. `knowledge-writer`: 統合・ファイル生成（`addBlockedBy: ["1","2"]`）
4. `quality-checker`: 品質検証（`addBlockedBy: ["3"]`）

### 起動設定

```
subagent_type: "domain-researcher"  # agents/ で定義済み
team_name: "domain-expertise-extractor"
mode: "bypassPermissions"
run_in_background: true
```

プロンプトに含める情報（全エージェント共通）:
- ドメイン名と参考事例（URL / 画像パス / テキスト）
- **出力先の絶対パス**: `~/.claude/` を展開した実パスを計算して渡す
  - 例: `/Users/{username}/.claude/domain-knowledge/lp-キャッチコピー/`
  - ⚠️ Write ツールは絶対パスのみ受け付ける
- 「全ファイルは Write ツールで絶対パスに書き込むこと」を明記

## Phase 3: 中間レビュー

researcher + analyst の結果を受け取った後、ユーザーに提示:
- 抽出した上位原則のリスト（3-5個）
- 各原則の具体基準ドラフト
- ドメインのサブ領域候補（スコープ調整用）
- **提案するエージェント構成**（何人の専門家をどの角度で生成するか）

AskUserQuestion で確認:
- 「この原則でカバーできていますか？追加すべき観点は？」
- 「このエージェント構成（X人: 役割A, 役割B...）で良いですか？」

フィードバックを knowledge-writer への指示に反映する。

## Phase 4: 知識生成（Round 2）

`knowledge-writer` に以下を指示:
- researcher + analyst の調査結果（ファイルパスで渡す）
- ユーザーが承認した原則リストとエージェント構成
- 出力先の絶対パス

出力ファイル一式:
```
~/.claude/domain-knowledge/{domain-name}/
├── README.md
├── evaluation-criteria.md
├── agents/
│   └── {role-N}.md（ユーザー承認の構成に従って生成）
└── references/
    └── research-notes.md
```

## Phase 5: 品質検証（Round 3）

`quality-checker` が以下を実施:
1. **サンプル評価実行**: 生成エージェント定義を使って別 Task でサンプルを評価
   - 事例あり → ユーザー事例を再利用
   - 事例なし → Web から適切サンプルを収集
2. **網羅性クロスチェック**: 業界標準との対比を Web 検索で確認
3. 問題があれば knowledge-writer にフィードバック → 修正ラウンド追加

## Phase 6: ドラフト提示・最終承認

完成したドラフト一式をユーザーに提示。フィードバックがあれば修正。
承認後に確定版として配置済みであることを確認。

## Phase 7: マージ処理（再実行時）

既存の `~/.claude/domain-knowledge/{domain-name}/` がある場合:
1. 既存知識を Read で読み込み
2. 新しい調査結果と比較
3. 矛盾がある場合は新しい情報を優先して更新
4. 既存にない情報は追加

## 出力先ディレクトリ管理

- ドメイン名変換: スペース→ハイフン、小文字化
  - 例: "LP キャッチコピー" → `lp-キャッチコピー`
- `~/.claude/domain-knowledge/` が存在しない場合は自動作成

## クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除
