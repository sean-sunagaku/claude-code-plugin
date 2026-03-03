# Hook 統合ガイド

## PostToolUse Hook でエージェント通信を自動ログ

### 仕組み

Claude Code の Hook 機能で `SendMessage` 呼び出し後にスクリプトを実行し、
エージェント間の全メッセージを自動的にファイルに記録する。

```
Agent A → SendMessage → PostToolUse hook 発火 → ログファイルに追記
```

### 最速セットアップ: agent-teams-log プラグイン

プラグインを有効化するだけで全チームの通信が自動ログされる:

```json
// ~/.claude/settings.json
{
  "enabledPlugins": {
    "agent-teams-log@sunagaku-marketplace": true
  }
}
```

これだけで PostToolUse hook が自動設定され、以下が有効になる:
- 全 SendMessage のログ記録
- チーム名・タイムスタンプ付きのディレクトリ自動作成
- discussion.md への時系列追記

### 手動設定（プラグインを使わない場合）

```json
// ~/.claude/settings.json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "SendMessage",
        "hooks": [
          {
            "type": "command",
            "command": "python3 \"/path/to/hook.py\""
          }
        ]
      }
    ]
  }
}
```

### Hook の入力データ（stdin JSON）

```json
{
  "session_id": "abc-123",
  "tool_input": {
    "type": "message",
    "recipient": "researcher",
    "content": "調査結果を共有します..."
  },
  "tool_response": {
    "routing": {
      "sender": "architect",
      "target": "@researcher"
    }
  },
  "cwd": "/Users/user/project"
}
```

### 重要な注意点

1. **PostToolUse はサブエージェントの SendMessage でも発火する**
2. `agent_id` は PostToolUse には含まれない（SubagentStop 専用）
3. 送信元の特定には `tool_response.routing.sender` を使う
4. ピアツーピア通信（エージェント間の直接メッセージ）も全てキャッチできる
5. Hook の失敗でエージェント動作を妨げないよう、必ず try/except で exit 0
6. broadcast の場合 `tool_input.type` が `"broadcast"` になり、`recipient` がない

### ログ出力先

```
{project}/.claude/agent-teams-log/
    {team-name}-{YYYYMMDD-HHMMSS}/
        discussion.md        <- 時系列のメッセージログ
        .session_id          <- セッション識別用
```

### ログフォーマット例

```markdown
### 💬 [14:30:15] `architect` → `researcher`
セグメント設計を完了しました。市場規模データを調査してください。

---

### 📢 [14:32:40] `researcher` → `all`
_type: broadcast_
市場リサーチ結果を全員に共有します。
{データ}

---
```

### リアルタイム監視

チーム実行中にログをリアルタイムで確認する:

```bash
# ターミナルで tail -f
tail -f .claude/agent-teams-log/*/discussion.md

# 特定のチームのログ
tail -f .claude/agent-teams-log/persona-creation-*/discussion.md
```

リーダーが介入すべきタイミングを判断するのに有用。

## Stop Hook（完了通知音）

エージェントの作業完了時に音で通知。長時間のチーム作業中に便利。

```json
// ~/.claude/settings.json の hooks に追加
{
  "Stop": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "afplay /System/Library/Sounds/Glass.aiff"
        }
      ]
    }
  ]
}
```

## SubagentStop Hook（エージェント完了検知）

サブエージェントの停止を検知する。`agent_id` が含まれるのはこの Hook のみ。

```json
{
  "SubagentStop": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "python3 \"/path/to/subagent-stop-hook.py\""
        }
      ]
    }
  ]
}
```

入力データ:
```json
{
  "session_id": "abc-123",
  "agent_id": "agent-uuid",
  "agent_name": "persona-architect",
  "cwd": "/Users/user/project"
}
```

**用途**: 全エージェント停止の検知、自動クリーンアップ、完了通知の自動化。

## Hook 設計のベストプラクティス

1. **常に exit 0**: Hook の失敗でエージェントの動作を妨げない
2. **軽量に**: Hook 内で重い処理をしない（ファイル追記のみが理想）
3. **べき等に**: 同じメッセージが 2 回来ても問題ないようにする
4. **ログはプロジェクト内に**: `.claude/agent-teams-log/` に出力（.gitignore 推奨）
