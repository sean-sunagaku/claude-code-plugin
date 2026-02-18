#!/bin/bash
# logo-design: プロジェクト初期化
# Usage: bash scripts/init.sh <project-name>
#
# 例: bash scripts/init.sh miravy
#     → .claude/logo-design/2026-02-18_miravy/ を作成

set -euo pipefail

PROJECT_NAME="${1:?Usage: bash scripts/init.sh <project-name>}"
DATE=$(date +%Y-%m-%d)
BASE_DIR="${HOME}/.claude/logo-design"
PROJECT_DIR="${BASE_DIR}/${DATE}_${PROJECT_NAME}"

if [ -d "$PROJECT_DIR" ]; then
  echo "⚠ Already exists: ${PROJECT_DIR}"
  echo "  Use new-step.sh to add a new step."
  exit 1
fi

# ディレクトリ構造作成
mkdir -p "${PROJECT_DIR}/step-01/logos"

# 全体 context.md テンプレート
cat > "${PROJECT_DIR}/context.md" << 'CONTEXT_EOF'
# Logo Design Context

## ブランド情報
- アプリ名:
- 概要:
- ターゲット:
- カラー:
- 用途: アプリアイコン / ブランドロゴ / 両方
- タグライン:

## 制約・好み
- 好みの方向性:
- 避けたいスタイル:
- 好きなロゴの例:
- 競合/同業他社:

## 過去のラウンドで学んだこと
（各ステップ終了後に追記）

## ステップ履歴
| Step | 目的 | 日時 | 結果 |
|------|------|------|------|
| step-01 | 初回デザイン提案 | - | 進行中 |
CONTEXT_EOF

# step-01 context.md テンプレート
cat > "${PROJECT_DIR}/step-01/context.md" << 'STEP_CONTEXT_EOF'
# Step-01 コンテキスト

## このステップの目的
初回デザイン提案 - 3〜5バリエーションを作成し方向性を決める

## 探求する方向性
（エージェントの提案を受けて記入）

## 制約
（あれば記入）

## ファイル構成
step-01/
├── context.md   ← このファイル
├── log.md       ← 議事録
└── logos/       ← 生成したロゴ（SVG等）
STEP_CONTEXT_EOF

# step-01 log.md テンプレート
cat > "${PROJECT_DIR}/step-01/log.md" << 'LOG_EOF'
# Step-01 議事録

## セッション情報
- 日時:
- 参加エージェント: brand-strategist, competitive-analyst, trend-researcher, logo-designer, color-type-expert, context-manager

## タイムライン

### セッション開始
- ヒアリング完了
- ブランド情報:

---

（以降はエージェントの議論を時系列で記録）
LOG_EOF

# SUMMARY.md テンプレート
cat > "${PROJECT_DIR}/SUMMARY.md" << 'SUMMARY_EOF'
# Logo Design Summary

## プロジェクト概要

## ステップ別サマリー

### Step-01
- 目的:
- 結果:
- 学んだこと:

## 最終決定案

## 次回への引き継ぎ
SUMMARY_EOF

# アイコン単体テンプレート（左側アイコンのみ / ワードマークなし）
cat > "${PROJECT_DIR}/step-01/logos/icon-template.svg" << 'ICON_EOF'
<!--
  Logo Icon Template - アイコン単体版（ワードマークなし）
  用途: App Store アイコン、favicon など
  サイズ: 512x512 推奨
  背景: ダークグリーングラデーション（デフォルト）/ ライトグレー (#F5F7F3) に変更可

  使い方:
  1. このファイルをコピーして v1-icon.svg などにリネーム
  2. <path>, <circle>, <polygon> 等でシンボルを描く
  3. 背景色を好みで変更する
  4. viewBox="0 0 512 512" のまま使用（ブラウザが自動スケール）
-->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#1A6B4A"/>
      <stop offset="100%" stop-color="#0A3D29"/>
    </linearGradient>
  </defs>

  <!-- 背景（角丸は App Store アイコン用に OS 側でマスクされる） -->
  <rect width="512" height="512" rx="112" fill="url(#bg)"/>

  <!--
    ここにシンボルを描く
    推奨: stroke-width は 24px 以上（小サイズで潰れないように）
    推奨カラー:
      - 最良の未来: #2B8A63 (緑) または白 #FFFFFF
      - 最悪の未来: #F2853A (オレンジ)
      - 背景: #1A6B4A → #0A3D29 グラデーション

    例: 2つの円が重なるデザイン（V2 Duality）
  -->
  <g style="isolation: isolate">
    <circle cx="196" cy="256" r="140" fill="#2B8A63"/>
    <circle cx="316" cy="256" r="140" fill="#F2853A" style="mix-blend-mode: screen"/>
  </g>

</svg>
ICON_EOF

# ロゴ全体テンプレート（アイコン + ワードマーク / 横並び）
cat > "${PROJECT_DIR}/step-01/logos/logo-template.svg" << 'LOGO_EOF'
<!--
  Logo Full Template - アイコン + ワードマーク横並び版
  viewBox: 480x160
  左140x140: アイコンエリア
  右: テキストエリア
-->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 480 160" width="480" height="160">
  <!-- アイコン背景 -->
  <rect x="0" y="10" width="140" height="140" rx="30" fill="#1A6B4A"/>

  <!--
    ここにシンボルを描く（x:0〜140, y:10〜150 の範囲内）
  -->

  <!-- ワードマーク -->
  <text x="160" y="95"
    font-family="'Helvetica Neue', Arial, sans-serif"
    font-weight="800" font-size="52" fill="#111827" letter-spacing="-1">
    AppName
  </text>
  <!-- サブタイトル（必要なら） -->
  <text x="162" y="121"
    font-family="'Helvetica Neue', Arial, sans-serif"
    font-weight="400" font-size="12" fill="#9CA3AF" letter-spacing="1.5">
    tagline here
  </text>
</svg>
LOGO_EOF

echo "✓ Created: ${PROJECT_DIR}"
echo "  ├── context.md"
echo "  ├── SUMMARY.md"
echo "  └── step-01/"
echo "      ├── context.md"
echo "      ├── log.md"
echo "      └── logos/"
echo "          ├── icon-template.svg  ← アイコン単体テンプレート"
echo "          └── logo-template.svg  ← アイコン+ワードマークテンプレート"
echo ""
echo "Next: Edit context.md with brand info, then start the agent team."
