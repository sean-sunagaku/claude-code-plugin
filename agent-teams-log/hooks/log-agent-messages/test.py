#!/usr/bin/env python3
"""Tests for hook.py.

Run: python3 .claude/hooks/log-agent-messages/test.py
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Final

SCRIPT_DIR: Final[Path] = Path(__file__).resolve().parent
HOOK: Final[Path] = SCRIPT_DIR / "hook.py"
TEAMS_DIR: Final[Path] = Path.home() / ".claude" / "teams"


@dataclass
class TestRunner:
    test_dir: Path = field(default_factory=lambda: Path(tempfile.mkdtemp()))
    passed: int = 0
    failed: int = 0
    mock_teams: list[str] = field(default_factory=list)

    # --- Helpers ---

    def reset_log(self) -> None:
        log_dir = self.test_dir / ".claude" / "agent-teams-log"
        if log_dir.exists():
            shutil.rmtree(log_dir)

    def find_log(self) -> Path | None:
        """agent-teams-log 配下の discussion.md を探す。"""
        log_dir = self.test_dir / ".claude" / "agent-teams-log"
        files = list(log_dir.rglob("discussion.md")) if log_dir.exists() else []
        return files[0] if files else None

    def find_log_for_team(self, team: str) -> Path | None:
        """特定チームの discussion.md を探す（フラット: {team}-{timestamp}/）。"""
        log_dir = self.test_dir / ".claude" / "agent-teams-log"
        if not log_dir.exists():
            return None
        for d in log_dir.iterdir():
            if d.is_dir() and d.name.startswith(f"{team}-"):
                md = d / "discussion.md"
                if md.exists():
                    return md
        return None

    def count_logs(self, pattern: str = "") -> int:
        """discussion.md の数を数える。pattern があればディレクトリ名でフィルタ。"""
        log_dir = self.test_dir / ".claude" / "agent-teams-log"
        if not log_dir.exists():
            return 0
        count = 0
        for d in log_dir.iterdir():
            if d.is_dir() and (not pattern or pattern in d.name):
                if (d / "discussion.md").exists():
                    count += 1
        return count

    def run_hook(self, json_input: str) -> None:
        subprocess.run(
            ["python3", str(HOOK)],
            input=json_input,
            capture_output=True,
            text=True,
        )

    def assert_contains(self, label: str, pattern: str, file: Path | None) -> None:
        if file and file.exists() and pattern in file.read_text():
            print(f"  ✅ {label}")
            self.passed += 1
        else:
            print(f"  ❌ {label} — not found: {pattern}")
            self.failed += 1

    def assert_not_contains(self, label: str, pattern: str, file: Path | None) -> None:
        if not file or not file.exists() or pattern not in file.read_text():
            print(f"  ✅ {label}")
            self.passed += 1
        else:
            print(f"  ❌ {label} — should NOT match: {pattern}")
            self.failed += 1

    def assert_file_missing(self, label: str) -> None:
        if self.count_logs() == 0:
            print(f"  ✅ {label}")
            self.passed += 1
        else:
            print(f"  ❌ {label} — file should not exist")
            self.failed += 1

    # --- Fixtures ---

    def make_json(
        self,
        sender: str,
        target: str,
        content: str,
        msg_type: str = "message",
        session: str = "session-default",
    ) -> str:
        return json.dumps({
            "session_id": session,
            "cwd": str(self.test_dir),
            "hook_event_name": "PostToolUse",
            "tool_name": "SendMessage",
            "tool_input": {
                "type": msg_type,
                "recipient": target,
                "content": content,
                "summary": "test summary",
            },
            "tool_response": {
                "success": True,
                "message": "Message sent",
                "routing": {
                    "sender": sender,
                    "senderColor": "blue",
                    "target": f"@{target}",
                    "targetColor": "red",
                    "summary": "test summary",
                    "content": content,
                },
            },
        })

    def make_json_no_routing(
        self,
        content: str,
        msg_type: str,
        session: str = "session-default",
    ) -> str:
        return json.dumps({
            "session_id": session,
            "cwd": str(self.test_dir),
            "tool_input": {
                "type": msg_type,
                "request_id": "shutdown-123@agent-a",
                "approve": True,
                "content": content,
            },
            "tool_response": {
                "success": True,
                "message": "Shutdown approved.",
                "request_id": "shutdown-123@agent-a",
            },
        })

    # --- Mock teams ---

    def setup_mock_team(self, team_name: str, *members: str) -> None:
        team_dir = TEAMS_DIR / team_name
        team_dir.mkdir(parents=True, exist_ok=True)
        config = {
            "members": [
                {"agentId": f"{m}@{team_name}", "name": m} for m in members
            ]
        }
        (team_dir / "config.json").write_text(json.dumps(config))
        self.mock_teams.append(team_name)

    def cleanup_mock_teams(self) -> None:
        for team in self.mock_teams:
            team_dir = TEAMS_DIR / team
            if team_dir.exists():
                shutil.rmtree(team_dir)
        self.mock_teams.clear()

    def cleanup(self) -> None:
        self.cleanup_mock_teams()
        if self.test_dir.exists():
            shutil.rmtree(self.test_dir)


# --- Test cases ---


def test_normal_message(t: TestRunner) -> None:
    print("=== Test 1: Normal peer-to-peer message ===")
    t.reset_log()
    t.run_hook(t.make_json("agent-x", "team-lead", "Hello from agent-x. Testing sender identification."))
    f = t.find_log()

    t.assert_contains("sender is agent-x", "agent-x", f)
    t.assert_contains("recipient is team-lead", "team-lead", f)
    t.assert_contains("message icon", "💬", f)
    t.assert_contains("content logged", "Testing sender", f)
    t.assert_not_contains("no type label for message", "_type: message_", f)


def test_broadcast(t: TestRunner) -> None:
    print("\n=== Test 2: Broadcast message ===")
    t.reset_log()
    t.run_hook(t.make_json("leader", "all", "Round 1 complete. Moving to Round 2.", "broadcast"))
    f = t.find_log()

    t.assert_contains("broadcast icon", "📢", f)
    t.assert_contains("sender is leader", "leader", f)
    t.assert_contains("recipient is all", "all", f)
    t.assert_contains("type label shown", "_type: broadcast_", f)
    t.assert_contains("content logged", "Round 1 complete", f)


def test_shutdown_request(t: TestRunner) -> None:
    print("\n=== Test 3: Shutdown request ===")
    t.reset_log()
    t.run_hook(t.make_json("team-lead", "designer", "Task complete, wrapping up", "shutdown_request"))
    f = t.find_log()

    t.assert_contains("shutdown icon", "🔴", f)
    t.assert_contains("type label", "_type: shutdown_request_", f)
    t.assert_contains("sender is team-lead", "team-lead", f)
    t.assert_contains("recipient is designer", "designer", f)


def test_shutdown_response_skipped(t: TestRunner) -> None:
    print("\n=== Test 4: Shutdown response → skip ===")
    t.reset_log()
    t.run_hook(t.make_json_no_routing("Task complete. Shutting down.", "shutdown_response"))
    t.assert_file_missing("shutdown_response skipped")


def test_peer_to_peer(t: TestRunner) -> None:
    print("\n=== Test 5: Peer-to-peer (designer → reviewer) ===")
    t.reset_log()
    t.run_hook(t.make_json("designer", "reviewer", "Please check my card-based layout proposal."))
    f = t.find_log()

    t.assert_contains("sender is designer", "designer", f)
    t.assert_contains("recipient is reviewer", "reviewer", f)
    t.assert_contains("content logged", "card-based layout", f)


def test_empty_content_skip(t: TestRunner) -> None:
    print("\n=== Test 6: Empty content → skip ===")
    t.reset_log()
    t.run_hook(t.make_json("agent-a", "team-lead", ""))
    t.assert_file_missing("empty content skipped")


def test_invalid_json(t: TestRunner) -> None:
    print("\n=== Test 7: Invalid JSON → graceful exit ===")
    result = subprocess.run(
        ["python3", str(HOOK)],
        input="not-json",
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        print("  ✅ invalid JSON handled gracefully")
        t.passed += 1
    else:
        print("  ❌ script crashed on invalid JSON")
        t.failed += 1


def test_header_once(t: TestRunner) -> None:
    print("\n=== Test 8: Header created only once ===")
    t.reset_log()
    t.run_hook(t.make_json("a", "x", "msg 1"))
    t.run_hook(t.make_json("b", "x", "msg 2"))
    f = t.find_log()

    if f and f.exists():
        count = f.read_text().count("# Agent Team Discussion Log")
        if count == 1:
            print("  ✅ header appears exactly once")
            t.passed += 1
        else:
            print(f"  ❌ header appears {count} times (expected 1)")
            t.failed += 1
    else:
        print("  ❌ log file not found")
        t.failed += 1

    t.assert_contains("first message", "msg 1", f)
    t.assert_contains("second message", "msg 2", f)


def test_japanese_content(t: TestRunner) -> None:
    print("\n=== Test 9: Japanese content ===")
    t.reset_log()
    t.run_hook(t.make_json("ux-designer", "team-lead", "ナビゲーションが3タップは深すぎます。"))
    f = t.find_log()

    t.assert_contains("japanese content", "ナビゲーション", f)
    t.assert_contains("sender", "ux-designer", f)


def test_team_detection_single(t: TestRunner) -> None:
    print("\n=== Test 10: Team detection (single team) ===")
    t.reset_log()
    t.setup_mock_team("_test-single-team", "designer", "reviewer")

    t.run_hook(t.make_json("designer", "reviewer", "Hello from single team test."))
    f = t.find_log_for_team("_test-single-team")

    t.assert_contains("team name in header", "_test-single-team", f)
    t.assert_contains("content logged", "single team test", f)
    t.cleanup_mock_teams()


def test_team_detection_by_member(t: TestRunner) -> None:
    print("\n=== Test 11: Team detection (multiple teams, match by member) ===")
    t.reset_log()
    t.setup_mock_team("_test-team-111", "alpha", "beta")
    t.setup_mock_team("_test-team-222", "gamma", "delta")

    t.run_hook(t.make_json("gamma", "delta", "Hello from team 222."))
    f = t.find_log_for_team("_test-team-222")

    t.assert_contains("correct team detected", "_test-team-222", f)
    t.assert_contains("content logged", "team 222", f)
    t.cleanup_mock_teams()


def test_header_contains_metadata(t: TestRunner) -> None:
    print("\n=== Test 12: Header contains team metadata ===")
    t.reset_log()
    t.setup_mock_team("_test-meta-team", "agent-a")

    t.run_hook(t.make_json("agent-a", "team-lead", "Metadata test."))
    f = t.find_log_for_team("_test-meta-team")

    t.assert_contains("team name in table", "_test-meta-team", f)
    t.assert_contains("project dir in table", str(t.test_dir), f)
    t.assert_contains("Started label", "Started", f)
    t.cleanup_mock_teams()


def test_session_directory_reuse(t: TestRunner) -> None:
    print("\n=== Test 13: Same session_id reuses same directory ===")
    t.reset_log()
    sid = f"session-reuse-test-{os.getpid()}"
    t.run_hook(t.make_json("a", "b", "msg 1", session=sid))
    t.run_hook(t.make_json("b", "a", "msg 2", session=sid))

    count = t.count_logs()
    if count == 1:
        print("  ✅ single discussion.md for same session")
        t.passed += 1
    else:
        print(f"  ❌ expected 1 discussion.md, found {count}")
        t.failed += 1

    f = t.find_log()
    t.assert_contains("first message", "msg 1", f)
    t.assert_contains("second message", "msg 2", f)


def test_flat_directory_structure(t: TestRunner) -> None:
    print("\n=== Test 14: Flat directory structure ({team}-{timestamp}/) ===")
    t.reset_log()
    t.setup_mock_team("_test-flat", "agent-a")

    t.run_hook(t.make_json("agent-a", "team-lead", "flat structure test"))

    log_dir = t.test_dir / ".claude" / "agent-teams-log"
    import re

    dirs = [d.name for d in log_dir.iterdir() if d.is_dir() and d.name.startswith("_test-flat-")]
    if dirs and re.match(r"^_test-flat-\d{8}-\d{6}$", dirs[0]):
        print("  ✅ directory follows {team}-{YYYYMMDD-HHMMSS} pattern")
        t.passed += 1
    else:
        print(f"  ❌ unexpected directory name: {dirs}")
        t.failed += 1

    t.cleanup_mock_teams()


def test_session_id_file_created(t: TestRunner) -> None:
    print("\n=== Test 15: .session_id file is created ===")
    t.reset_log()
    sid = f"session-check-{os.getpid()}"
    t.run_hook(t.make_json("a", "b", "test", session=sid))

    log_dir = t.test_dir / ".claude" / "agent-teams-log"
    session_files = list(log_dir.rglob(".session_id"))
    if session_files and session_files[0].read_text().strip() == sid:
        print("  ✅ .session_id contains correct session ID")
        t.passed += 1
    else:
        print("  ❌ .session_id missing or wrong content")
        t.failed += 1


def test_gitignore_created(t: TestRunner) -> None:
    print("\n=== Test 16: .gitignore created in agent-teams-log ===")
    t.reset_log()
    t.run_hook(t.make_json("a", "b", "gitignore test"))

    gitignore = t.test_dir / ".claude" / "agent-teams-log" / ".gitignore"
    if gitignore.exists():
        content = gitignore.read_text()
        if "*" in content and "!.gitignore" in content:
            print("  ✅ .gitignore created with correct content")
            t.passed += 1
        else:
            print(f"  ❌ .gitignore content unexpected: {content!r}")
            t.failed += 1
    else:
        print("  ❌ .gitignore not created")
        t.failed += 1


def test_gitignore_not_overwritten(t: TestRunner) -> None:
    print("\n=== Test 17: .gitignore not overwritten on second run ===")
    t.reset_log()
    t.run_hook(t.make_json("a", "b", "first run"))

    gitignore = t.test_dir / ".claude" / "agent-teams-log" / ".gitignore"
    gitignore.write_text("# custom\n*\n")

    t.run_hook(t.make_json("a", "b", "second run"))
    if gitignore.read_text() == "# custom\n*\n":
        print("  ✅ existing .gitignore preserved")
        t.passed += 1
    else:
        print("  ❌ .gitignore was overwritten")
        t.failed += 1


def test_shutdown_recipient_team_match(t: TestRunner) -> None:
    print("\n=== Test 18: Shutdown from leader matches team via recipient ===")
    t.reset_log()
    t.setup_mock_team("_test-shutdown", "designer", "reviewer")
    t.setup_mock_team("_test-other", "alpha", "beta")

    t.run_hook(t.make_json("leader", "designer", "Task complete", "shutdown_request", "sid-shutdown"))
    f = t.find_log_for_team("_test-shutdown")

    t.assert_contains("matched via recipient", "designer", f)
    t.cleanup_mock_teams()


def test_leader_same_session_merges(t: TestRunner) -> None:
    print("\n=== Test 19: Leader message merges into existing session (different team_name) ===")
    t.reset_log()
    sid = f"session-merge-{os.getpid()}"
    t.setup_mock_team("_test-chat", "alice", "bob")

    # Agent sends first (detected as _test-chat)
    t.run_hook(t.make_json("alice", "bob", "Hello from alice", session=sid))
    count_before = t.count_logs()

    # Leader sends with team-lead sender (may detect different team_name)
    t.run_hook(t.make_json("team-lead", "bob", "Please respond to alice", session=sid))
    count_after = t.count_logs()

    if count_before == 1 and count_after == 1:
        print("  ✅ leader message merged into existing session dir")
        t.passed += 1
    else:
        print(f"  ❌ expected 1 dir, got {count_before} then {count_after}")
        t.failed += 1

    f = t.find_log()
    t.assert_contains("alice message", "Hello from alice", f)
    t.assert_contains("leader message", "Please respond to alice", f)
    t.cleanup_mock_teams()


# --- Run ---

def main() -> None:
    t = TestRunner()

    try:
        test_normal_message(t)
        test_broadcast(t)
        test_shutdown_request(t)
        test_shutdown_response_skipped(t)
        test_peer_to_peer(t)
        test_empty_content_skip(t)
        test_invalid_json(t)
        test_header_once(t)
        test_japanese_content(t)
        test_team_detection_single(t)
        test_team_detection_by_member(t)
        test_header_contains_metadata(t)
        test_session_directory_reuse(t)
        test_flat_directory_structure(t)
        test_session_id_file_created(t)
        test_gitignore_created(t)
        test_gitignore_not_overwritten(t)
        test_shutdown_recipient_team_match(t)
        test_leader_same_session_merges(t)
    finally:
        t.cleanup()

    print(f"\n{'=' * 32}")
    print(f"Results: {t.passed} passed, {t.failed} failed")
    print(f"{'=' * 32}")

    raise SystemExit(0 if t.failed == 0 else 1)


if __name__ == "__main__":
    main()
