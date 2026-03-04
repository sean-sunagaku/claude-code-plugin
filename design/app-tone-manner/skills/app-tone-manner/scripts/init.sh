#!/bin/bash
# app-tone-manner 初期化スクリプト
# 使い方: bash init.sh "{project-name}"

set -euo pipefail

PROJECT_NAME="${1:?Error: project name is required}"
DATE=$(date +%Y-%m-%d)
SAFE_NAME=$(echo "$PROJECT_NAME" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
BASE_DIR=".claude/app-tone-manner/${DATE}_${SAFE_NAME}"

if [ -d "$BASE_DIR" ]; then
  echo "Directory already exists: $BASE_DIR"
  echo "Resuming existing session."
  exit 0
fi

mkdir -p "$BASE_DIR/round-1"
mkdir -p "$BASE_DIR/references"

cat > "$BASE_DIR/context.md" << EOF
# ${PROJECT_NAME} - Tone & Manner Design Context

作成日: ${DATE}
プロジェクト: ${PROJECT_NAME}

## セッション履歴

### Session 1 (${DATE})
- ステータス: 開始
- フェーズ: 初期化完了

## ヒアリング結果

(ヒアリング後に記入)

## 蓄積された知見

(ラウンド進行後に追記)

## デザインテンション

(Phase 1 完了後に記入)
EOF

cat > "$BASE_DIR/round-1/context.md" << EOF
# Round 1 Context

ラウンド: 1
日付: ${DATE}
目的: 初回ブランド基盤設計 + ビジュアル言語化 + トーン・オブ・ボイス

## Phase 1: ブランド基盤設計
- [ ] brand-strategist: アーキタイプ・パーソナリティ・デザイン原則
- [ ] competitor-analyst: 競合トンマナ調査
- [ ] user-psychologist: ユーザー心理分析
- [ ] identity-critic: Gate 1 判定

## Phase 2: ビジュアル言語化
- [ ] color-expert: カラーパレット設計
- [ ] typography-director: フォント選定
- [ ] visual-style-architect: ビジュアルスタイル設計
- [ ] identity-critic: Gate 2 判定

## Phase 3: トーン・オブ・ボイス
- [ ] tone-of-voice-writer: コミュニケーションスタイル設計
- [ ] identity-critic: Gate 3 (Devil's Advocate) 判定
EOF

echo "Initialized: $BASE_DIR"
echo "Round 1 directory created: $BASE_DIR/round-1/"
echo "Context file created: $BASE_DIR/context.md"
