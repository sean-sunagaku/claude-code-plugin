# Review

コードレビュー・プランレビュー・UI検証・品質チェック

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| **multi-ai-review** | `/multi-ai-review` | Codex, Gemini, Claude の3つの AI に並列でコードレビューを依頼し、統合レポートを生成する |
| **plan-review** | `/plan-review` | Codex, Gemini, Claude の3つの AI で Plan ファイルを並列レビュー。実装計画の妥当性、抜け漏れ、リスクを分析する |
| **ui-verify** | `/ui-verify` | Chrome DevTools でフロントエンドの動作確認。起動中サーバーを自動検出し操作・デバッグ・パフォーマンス分析を実行 |
| **cruft-code-sweep** | `/cruft-code-sweep` |  コードベースの不要なフォールバック・互換性コード・デッドコードを 3つの専門エージェント（scanner + historian + verifier）が協調して検出・安全性検証する監査スキル。 scanner が自律探索で候補を発見し、historian が git 履歴から時間軸の文脈を付与し、 |
| **code-review-team** | `/code-review-team` | 5つの専門エージェント（backend-reviewer, frontend-reviewer, test-reviewer, security-reviewer, ux-reviewer）がチームでコードレビューし、統合レポートを出力するスキル。git diff ベースで変更ファイルを検出し並列レビュー |

### multi-ai-review

Codex, Gemini, Claude の3つの AI に並列でコードレビューを依頼し、統合レポートを生成する

Codex、Gemini、Claudeの3つのAIに並列でコードレビューを依頼し、統合レポートを生成する。

```
/multi-ai-review
```

### plan-review

Codex, Gemini, Claude の3つの AI で Plan ファイルを並列レビュー。実装計画の妥当性、抜け漏れ、リスクを分析する

Codex、Gemini、Claude を使って Plan ファイルを並列レビューし、実装前に計画の品質を確認する。

```
/plan-review
```

### ui-verify

Chrome DevTools でフロントエンドの動作確認。起動中サーバーを自動検出し操作・デバッグ・パフォーマンス分析を実行

$ARGUMENTS

```
/ui-verify
```

### cruft-code-sweep

 コードベースの不要なフォールバック・互換性コード・デッドコードを 3つの専門エージェント（scanner + historian + verifier）が協調して検出・安全性検証する監査スキル。 scanner が自律探索で候補を発見し、historian が git 履歴から時間軸の文脈を付与し、

3つの専門エージェントが協調して、不要コードの **発見** → **履歴調査** → **安全性検証** を行う。

```
/cruft-code-sweep
```

### code-review-team

5つの専門エージェント（backend-reviewer, frontend-reviewer, test-reviewer, security-reviewer, ux-reviewer）がチームでコードレビューし、統合レポートを出力するスキル。git diff ベースで変更ファイルを検出し並列レビュー

5つの専門エージェントが並列でコードレビューし、統合レポートを生成する。

```
/code-review-team
```

---

[< Back to top](../README.md)
