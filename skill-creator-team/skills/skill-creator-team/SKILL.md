---
name: skill-creator-team
description: >
  4つの専門エージェントチームで高品質なスキルを設計・作成するスキル。
  アーキテクト、ドメインリサーチャー、スキルライター、品質レビュアーが
  議論・フィードバックし合い、ベストプラクティスに準拠したスキルを生成する。
  既存の skill-creator のリファレンスと既存スキルのパターンを直接参照して品質を担保する。
  Use when: 新しいスキルを作りたい、スキルを高品質に作成したい、
  チームでスキルを設計したい、既存スキルを改善したい。
  Triggers: "スキル作成", "スキルを作りたい", "skill create", "新しいスキル",
  "create skill", "スキル設計", "skill design", "高品質スキル",
  "チームでスキル", "スキル改善", "skill improve"
---

# Skill Creator Team

4つの専門エージェントがチームで議論し、高品質なスキルを作成する。

## 外部リファレンス（直接読み込み）

以下のファイルはコピーではなく、実ファイルを直接 Read して参照する。

### skill-creator ベストプラクティス
```
SKILL_CREATOR_BASE=/Users/babashunsuke/.claude/plugins/cache/anthropic-agent-skills/example-skills/1ed29a03dc85/skills/skill-creator
```

- **ワークフローパターン**: `${SKILL_CREATOR_BASE}/references/workflows.md`
- **出力パターン**: `${SKILL_CREATOR_BASE}/references/output-patterns.md`
- **初期化スクリプト**: `${SKILL_CREATOR_BASE}/scripts/init_skill.py`
- **バリデーション**: `${SKILL_CREATOR_BASE}/scripts/quick_validate.py`
- **パッケージング**: `${SKILL_CREATOR_BASE}/scripts/package_skill.py`

### 既存スキル（パターン参照用）
```
LOCAL_SKILLS=~/.claude/skills/
PLUGIN_SKILLS=~/.claude/plugins/marketplaces/sunagaku-marketplace/
```

エージェントはこれらのパスから既存スキルの構造やエージェント定義を Read して参考にする。

## ワークフロー

1. ユーザーからスキル要件をヒアリング
2. Agent Team を作成し、4エージェントを並列起動
3. 2〜3ラウンドの設計・議論・フィードバック
4. スキルファイル一式を `~/.claude/skills/{skill-name}/` に出力
5. バリデーション実行

## Step 1: ヒアリング

以下を確認する（不明ならユーザーに質問）:

- **スキルの目的**: 何を自動化・支援するスキルか
- **トリガー**: どんな言葉でスキルが起動すべきか
- **Agent Team 構成**: チームエージェント型か、単体スキルか
- **参考にすべき既存スキル**: 似たパターンの既存スキルがあるか
- **出力物**: レポート、コード、設定ファイル等

## Step 2: チーム作成とエージェント起動

TeamCreate で `skill-creator-team` チームを作成。以下4エージェントを **1つのメッセージで並列に** Task ツールで起動する。

| name | 役割 | 主な手段 |
|------|------|---------|
| `skill-architect` | 構造設計・要件分析・既存パターン分析 | Read, Glob |
| `domain-researcher` | 対象ドメインのベストプラクティス調査 | WebSearch |
| `skill-writer` | SKILL.md・エージェント定義・リファレンス作成 | Read, Write |
| `quality-reviewer` | 品質レビュー・ベストプラクティス準拠チェック | Read, Glob |

各エージェントは `agents/` ディレクトリにサブエージェントとして定義済み。

### タスク作成

TaskCreate で5つのタスクを作成:

1. skill-architect: 構造設計（既存スキル分析含む）
2. domain-researcher: 対象ドメインの調査
3. skill-writer: スキルファイル一式の作成（タスク1,2完了後）
4. quality-reviewer: 品質レビュー（タスク3完了後）
5. 最終出力: バリデーション + パッケージング（タスク4完了後）

依存関係:
- タスク3: `addBlockedBy: ["1","2"]`
- タスク4: `addBlockedBy: ["3"]`
- タスク5: `addBlockedBy: ["4"]`

### 起動設定

```
subagent_type: "skill-architect"
team_name: "skill-creator-team"
mode: "bypassPermissions"
run_in_background: true
```

## Step 3: 議論の進行

```
Round 1: architect が構造設計 + researcher がドメイン調査 → writer にインプット
Round 2: writer がファイル作成 → reviewer がレビュー → フィードバック
Round 3: writer が修正 → reviewer が最終チェック → 完成
```

## Step 4: バリデーションと出力

1. `quick_validate.py` でスキル検証
2. 問題があれば writer が修正
3. 検証通過後、ユーザーに完成を報告
4. 必要なら `publish-skill.sh` でプラグインリポジトリに配置

## Step 5: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全員シャットダウン後に `TeamDelete` でチーム削除
