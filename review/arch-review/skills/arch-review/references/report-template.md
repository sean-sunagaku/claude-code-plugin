# Architecture Review - {project-name}

Date: {YYYY-MM-DD}
Project: `{project-dir}`
Analyzed by: arch-review (Claude x5 + Codex x1)

---

## Executive Summary

{全体的な健全性の評価（1-2段落）}

**最も注意すべき点:**
1. {最重要事項}
2. {2番目}
3. {3番目}

---

## Critical Findings

> 放置すると重大な障害・セキュリティインシデント・データ損失に直結するリスク

- [ ] **[{観点}] {タイトル}** - {説明} (`{file}:{line}`)
  - 影響範囲: {影響}
  - 推奨対応: {対応}

---

## Warning Findings

> 中期的に問題化する可能性が高く、計画的な対応が必要

- [ ] **[{観点}] {タイトル}** - {説明} (`{file}:{line}`)
  - 影響範囲: {影響}
  - 推奨対応: {対応}

---

## Info Findings

> 現時点では問題ないが、拡張時や特定条件下で顕在化する可能性がある

- [ ] **[{観点}] {タイトル}** - {説明} (`{file}:{line}`)

---

## Cross-cutting Concerns

> 複数の観点にまたがる構造的な問題

### {問題タイトル}
- **関連観点**: {観点1}, {観点2}, ...
- **概要**: {問題の説明}
- **各観点からの分析**:
  - {観点1}: {その観点での解釈}
  - {観点2}: {その観点での解釈}
- **推奨対応**: {対応}

---

## Discussion Highlights

> エージェント間の議論で特に有意義だった論点

### {論点タイトル}
- **発端**: {誰が何を指摘したか}
- **反論/補足**: {どんな議論があったか}
- **結論**: {合意した内容}

---

## Codex Perspective

> Codex（異なるLLM）の独自の視点から得られた知見

- {Claude チームでは見落としていた指摘}
- {異なる解釈や優先度の提案}

---

## Recommended Actions

> 優先度順のアクションリスト

### Priority 1: Immediate（今すぐ対応）
1. {アクション} - {理由} - {対象ファイル}

### Priority 2: Short-term（1-2週間以内）
1. {アクション} - {理由} - {対象ファイル}

### Priority 3: Medium-term（計画的に対応）
1. {アクション} - {理由} - {対象ファイル}

---

## Appendix: Analysis Coverage

| 観点 | 分析者 | ファイル数 | findings |
|------|--------|-----------|----------|
| パフォーマンス + スケーラビリティ | perf-scale-analyst | {N} | {N} |
| 信頼性 + デグレ耐性 | reliability-analyst | {N} | {N} |
| セキュリティ | security-analyst | {N} | {N} |
| 運用 + DX | ops-dx-analyst | {N} | {N} |
| データ整合性 + 依存関係 | data-deps-analyst | {N} | {N} |
| クロスカットレビュー | codex-reviewer (Codex) | {N} | {N} |
