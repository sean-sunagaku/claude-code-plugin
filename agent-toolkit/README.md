# Agent Toolkit

エージェントチームの構築・運用・ベストプラクティス

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| **agent-team** | `/agent-team` | Multi-agent team orchestration for parallel task execution, research, and implementation |
| **skill-creator-team** [Beta] | `/skill-creator-team` | 4つの専門エージェント（アーキテクト・リサーチャー・ライター・レビュアー）がチームで高品質なスキルを設計・作成する。skill-creator ベストプラクティスに準拠 |
| **agent-team-guide** | `/agent-team-guide` | Agent Teams スキルを設計・構築するためのベストプラクティスガイド。サブエージェント定義、SendMessage 通信プロトコル、タスク依存管理、PostToolUse Hook ログ、MCP ツール統合、コンテキストファイル設計を網羅。7つの実績あるチームスキルから抽出したパターン集 |
| **subagent-best-practices** | `/subagent-best-practices` |  Claude Code の SubAgent（agents/*.md）を正しく定義するためのベストプラクティスガイド。 YAML frontmatter、ツール選択、3-Phase 構造、コンテキスト受け渡し、アンチパターンを網羅。 Use when: agents/*.md を書く、SubAgent 定義を改善する、エージェントの動作が想定外、 コンテキストが渡らない、ツール選択に迷う。 Triggers: "subagent", "agent definition", "agents/*.md", "エージェント定義", "サブエージェント", "3-Phase", "context passing", "コンテキスト渡し", "tool selection", "ツール選択", "subagent_type", "bypassPermissions" |

### agent-team

Multi-agent team orchestration for parallel task execution, research, and implementation

Orchestrate multi-agent teams to decompose complex tasks, select optimal sub-agents, and execute work in parallel.

```
/agent-team
```

### skill-creator-team [Beta]

4つの専門エージェント（アーキテクト・リサーチャー・ライター・レビュアー）がチームで高品質なスキルを設計・作成する。skill-creator ベストプラクティスに準拠

4つの専門エージェントがチームで議論し、高品質なスキルを作成する。

```
/skill-creator-team
```

### agent-team-guide

Agent Teams スキルを設計・構築するためのベストプラクティスガイド。サブエージェント定義、SendMessage 通信プロトコル、タスク依存管理、PostToolUse Hook ログ、MCP ツール統合、コンテキストファイル設計を網羅。7つの実績あるチームスキルから抽出したパターン集

7つの実績あるチームスキルから抽出した Agent Teams 設計パターン集。

```
/agent-team-guide
```

### subagent-best-practices

 Claude Code の SubAgent（agents/*.md）を正しく定義するためのベストプラクティスガイド。 YAML frontmatter、ツール選択、3-Phase 構造、コンテキスト受け渡し、アンチパターンを網羅。 Use when: agents/*.md を書く、SubAgent 定義を改善する、エージェントの動作が想定外、 コンテキストが渡らない、ツール選択に迷う。 Triggers: "subagent", "agent definition", "agents/*.md", "エージェント定義", "サブエージェント", "3-Phase", "context passing", "コンテキスト渡し", "tool selection", "ツール選択", "subagent_type", "bypassPermissions"

Claude Code の `agents/*.md` ファイルで SubAgent を正しく定義するための実践ガイド。

```
/subagent-best-practices
```

---

[< Back to top](../README.md)
