#!/usr/bin/env python3
"""Agent Teams SendMessage auto-logger.

Claude Code の PostToolUse hook として登録し、
エージェント間の SendMessage を自動的にファイルに記録する。
エージェントのプロンプトに依存せず、hook で技術的に強制するアプローチ。

ディレクトリ構成:
    .claude/agent-teams-log/
        ui-review-20260220-125730/
            discussion.md
            .session_id

Hook input (JSON via stdin):
    .session_id                    - セッション固有 ID
    .tool_input                    - SendMessage の引数 (type, recipient, content)
    .tool_response.routing.sender  - 送信元エージェント名
    .tool_response.routing.target  - 送信先（@付き）
    .cwd                           - プロジェクトディレクトリ

注意:
    - PostToolUse の JSON には agent_id が含まれない（SubagentStop 専用）
    - 送信元の特定には tool_response.routing.sender を使う
    - routing がない場合（shutdown_response 等）は "leader" にフォールバック
    - どのステップで失敗しても exit 0 で終了する（エージェント動作を妨げない）
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Final

TEAMS_DIR: Final[Path] = Path.home() / ".claude" / "teams"
LOGS_DIR_NAME: Final[str] = "agent-teams-log"

# メッセージタイプ → アイコン
# ログを流し読みするとき、種類が一目でわかるようにする
TYPE_ICONS: Final[dict[str, str]] = {
    "broadcast": "📢",        # 全員向けアナウンス
    "shutdown_request": "🔴",  # リーダーからの終了指示
}
DEFAULT_ICON: Final[str] = "💬"  # 通常メッセージ（エージェント間の議論）


@dataclass(frozen=True)
class Message:
    """SendMessage hook から抽出したメッセージ情報。"""

    type: str
    content: str
    sender: str
    recipient: str
    project_dir: Path
    session_id: str


def parse_input(raw: str) -> Message | None:
    """stdin の JSON を解析して Message に変換する。

    フォールバック優先順位:
        sender:    routing.sender → agent_id → "leader"
        recipient: routing.target(@除去) → tool_input.recipient → "all"

    不正な JSON や空メッセージの場合は None を返す。
    """
    try:
        data = json.loads(raw)
    except (json.JSONDecodeError, TypeError):
        return None

    tool_input: dict = data.get("tool_input", {})
    routing: dict = data.get("tool_response", {}).get("routing", {})

    content = tool_input.get("content", "")
    if not content:
        return None

    msg_type = tool_input.get("type", "message")

    # shutdown_response は routing がなくチーム特定不可。記録する意味も薄いのでスキップ
    if msg_type == "shutdown_response":
        return None

    sender = (
        routing.get("sender")
        or data.get("agent_id")
        or "leader"
    )

    raw_target = routing.get("target") or tool_input.get("recipient") or "all"
    recipient = raw_target.lstrip("@")

    return Message(
        type=msg_type,
        content=content,
        sender=sender,
        recipient=recipient,
        project_dir=Path(data.get("cwd", ".")),
        session_id=data.get("session_id", "unknown"),
    )


def detect_team_name(sender: str, recipient: str) -> str:
    """アクティブなチーム名を検出する。

    ~/.claude/teams/{team-name}/config.json を走査し、
    sender または recipient のエージェント名をメンバーに持つチームを探す。

    sender → recipient の順で検索する。
    sender が "leader" の場合（リーダーからの shutdown 等）、
    recipient でマッチさせることで正しいチームに振り分ける。

    チームが1つしかなければそれを使う（検索不要で高速）。
    見つからない場合は "unknown-team" にフォールバック。
    """
    if not TEAMS_DIR.is_dir():
        return "unknown-team"

    teams: list[str] = [
        d.name
        for d in TEAMS_DIR.iterdir()
        if d.is_dir() and (d / "config.json").exists()
    ]

    if not teams:
        return "unknown-team"

    if len(teams) == 1:
        return teams[0]

    # 複数チーム → sender、次に recipient でメンバーマッチ
    skip = {"leader", "team-lead", "all"}
    for name in (sender, recipient):
        if name in skip:
            continue
        for team in teams:
            config_path = TEAMS_DIR / team / "config.json"
            try:
                config = json.loads(config_path.read_text())
                members = [m.get("name") for m in config.get("members", [])]
                if name in members:
                    return team
            except (json.JSONDecodeError, OSError):
                continue

    return "unknown-team"


def resolve_log_path(
    project_dir: Path, team_name: str, session_id: str
) -> Path:
    """セッションに対応するログファイルパスを解決する。

    {project}/.claude/agent-teams-log/{team}-{YYYYMMDD-HHMMSS}/ のフラット構成。
    同一セッション（session_id が同じ）なら既存ディレクトリを再利用し、
    新しいセッションなら新規ディレクトリを作成する。

    .session_id ファイルで同一セッション判定。
    """
    logs_dir = project_dir / ".claude" / LOGS_DIR_NAME
    logs_dir.mkdir(parents=True, exist_ok=True)

    # ログディレクトリが git に追跡されないよう .gitignore を配置
    gitignore = logs_dir / ".gitignore"
    if not gitignore.exists():
        gitignore.write_text("# Auto-generated: keep agent team logs out of git\n*\n!.gitignore\n")

    # 既存セッションを探す（session_id が同じなら team_name が違っても再利用）
    for d in sorted(logs_dir.iterdir()):
        if not d.is_dir():
            continue
        sid_file = d / ".session_id"
        if sid_file.exists() and sid_file.read_text().strip() == session_id:
            return d / "discussion.md"

    # 新規ディレクトリを作成
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    session_dir = logs_dir / f"{team_name}-{timestamp}"
    session_dir.mkdir(parents=True, exist_ok=True)
    (session_dir / ".session_id").write_text(session_id)

    return session_dir / "discussion.md"


def ensure_header(log_file: Path, team_name: str, project_dir: Path) -> None:
    """ログファイルが新規の場合にヘッダーを書き込む。

    既にファイルが存在する場合はスキップ（ヘッダーの重複防止）。
    チーム名とセッション開始時刻をヘッダーに含め、
    どのセッションのログか特定できるようにする。
    """
    if log_file.exists():
        return

    started_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    header = f"""# Agent Team Discussion Log

| Key | Value |
|-----|-------|
| Team | `{team_name}` |
| Started | {started_at} |
| Project | `{project_dir}` |

> Auto-generated by PostToolUse hook on SendMessage.
> Monitor this file to follow agent discussions in real-time.

---
"""
    log_file.write_text(header)


def append_entry(log_file: Path, msg: Message) -> None:
    """ログファイルにメッセージエントリを追記する。

    Markdown 形式で書き出す。VSCode のプレビューで見やすくするため
    ### 見出し + コードスパンでエージェント名を表示。
    "message" タイプ以外は _type: xxx_ ラベルを付けて種類を明示。
    """
    icon = TYPE_ICONS.get(msg.type, DEFAULT_ICON)
    timestamp = datetime.now().strftime("%H:%M:%S")

    lines = [
        "",
        f"### {icon} [{timestamp}] `{msg.sender}` → `{msg.recipient}`",
    ]
    if msg.type != "message":
        lines.append(f"_type: {msg.type}_")
    lines += ["", msg.content, "", "---"]

    with log_file.open("a") as f:
        f.write("\n".join(lines) + "\n")


def main() -> None:
    raw = sys.stdin.read()

    msg = parse_input(raw)
    if msg is None:
        return

    team_name = detect_team_name(msg.sender, msg.recipient)
    log_file = resolve_log_path(msg.project_dir, team_name, msg.session_id)
    ensure_header(log_file, team_name, msg.project_dir)
    append_entry(log_file, msg)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        # hook の失敗でエージェント動作を妨げない
        pass
