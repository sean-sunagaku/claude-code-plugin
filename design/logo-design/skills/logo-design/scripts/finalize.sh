#!/bin/bash
# logo-design: 最終仕上げディレクトリ作成 + SVGコピー
# Usage: bash scripts/finalize.sh <project-dir> <step-number> [logo-indices...]
#
# 例: bash scripts/finalize.sh ~/.claude/logo-design/2026-02-18_miravy 02 1 3
#     → step-02 の v1, v3 を final/ にコピーしてレポートテンプレート生成

set -euo pipefail

PROJECT_DIR="${1:?Usage: bash scripts/finalize.sh <project-dir> <step-number> [logo-indices...]}"
STEP_NUM="${2:?Specify step number (e.g., 02)}"
shift 2
INDICES=("$@")

STEP_DIR="${PROJECT_DIR}/step-${STEP_NUM}"
FINAL_DIR="${PROJECT_DIR}/final"

if [ ! -d "$STEP_DIR" ]; then
  echo "✗ Step directory not found: ${STEP_DIR}"
  exit 1
fi

mkdir -p "${FINAL_DIR}/icons"   # アイコン単体 (512x512)
mkdir -p "${FINAL_DIR}/logos"   # フルロゴ (アイコン+ワードマーク)

if [ ${#INDICES[@]} -eq 0 ]; then
  # インデックス指定なし → step-N/logos/ の全SVGをコピー
  echo "Copying all SVGs from step-${STEP_NUM}/logos/..."
  cp "${STEP_DIR}/logos/"*.svg "${FINAL_DIR}/logos/" 2>/dev/null || echo "  (no SVGs found)"
else
  # 指定インデックスのみコピー
  for idx in "${INDICES[@]}"; do
    # v{idx}-*.svg をコピー（アイコンもロゴも）
    for pattern in "v${idx}-*.svg" "icon-v${idx}-*.svg"; do
      files=$(ls "${STEP_DIR}/logos/"${pattern} 2>/dev/null || true)
      if [ -n "$files" ]; then
        # icon- 付きはアイコンフォルダへ、それ以外はロゴフォルダへ
        for f in $files; do
          base=$(basename "$f")
          if [[ "$base" == icon-* ]]; then
            cp "$f" "${FINAL_DIR}/icons/"
            echo "  ✓ Copied to icons/: ${base}"
          else
            cp "$f" "${FINAL_DIR}/logos/"
            echo "  ✓ Copied to logos/: ${base}"
          fi
        done
      fi
    done
  done
fi

# レポートテンプレート
if [ ! -f "${FINAL_DIR}/report.md" ]; then
  TOTAL_STEPS=$(ls -d "${PROJECT_DIR}"/step-* 2>/dev/null | wc -l | tr -d ' ')

  cat > "${FINAL_DIR}/report.md" << REPORT_EOF
# ロゴデザイン最終レポート

## 概要

| 項目 | 内容 |
|------|------|
| プロジェクト | $(basename "$PROJECT_DIR") |
| 作成日 | $(date +%Y-%m-%d) |
| ステップ数 | ${TOTAL_STEPS} |
| 採用ステップ | step-${STEP_NUM} |

## ステップ別サマリー

<!-- 各ステップで何を試して何を学んだかを記述 -->

## 最終決定案

| ファイル | 用途 | 説明 |
|---------|------|------|
| icons/  | App Store アイコン | アイコン単体 (512x512) |
| logos/  | ブランドロゴ | アイコン + ワードマーク |

## カラーパレット

| 用途 | HEX | 役割 |
|------|-----|------|
| プライマリ | #XXXXXX | |
| セカンダリ | #XXXXXX | |
| 背景（ライト） | #XXXXXX | |
| 背景（ダーク） | #XXXXXX | |

## タイポグラフィ

| 要素 | フォント | ウェイト | サイズ |
|------|---------|---------|-------|
| ブランド名 | | | |
| サブタイトル | | | |

## 使用ガイドライン

| 状況 | 使用ファイル |
|------|-------------|
| App Store アイコン | icons/icon-*.svg |
| 明るい背景のロゴ | logos/logo-light-*.svg |
| 暗い背景のロゴ | logos/logo-dark-*.svg |
| 1色印刷 | logos/logo-mono-*.svg |

## 却下された案とその理由

<!-- 将来のリデザイン時の参考に -->

## 納品ファイル一覧

### アイコン単体
$(ls "${FINAL_DIR}/icons/"*.svg 2>/dev/null | while read f; do echo "- [ ] $(basename $f)"; done || echo "- (なし)")

### フルロゴ
$(ls "${FINAL_DIR}/logos/"*.svg 2>/dev/null | while read f; do echo "- [ ] $(basename $f)"; done || echo "- (なし)")
REPORT_EOF

  echo ""
  echo "  ✓ report.md テンプレートを作成"
fi

echo ""
echo "✓ Finalized: ${FINAL_DIR}"
echo "  ├── icons/   (アイコン単体)"
ls "${FINAL_DIR}/icons/"*.svg 2>/dev/null | while read f; do echo "  │   $(basename $f)"; done || true
echo "  ├── logos/   (フルロゴ)"
ls "${FINAL_DIR}/logos/"*.svg 2>/dev/null | while read f; do echo "  │   $(basename $f)"; done || true
echo "  └── report.md"
