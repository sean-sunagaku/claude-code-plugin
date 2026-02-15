---
name: ui-verify
description: フロントエンドの動作確認。起動中サーバーを自動検出し、Chrome DevTools で操作・デバッグ・パフォーマンス分析を実行。
context: fork
agent: general-purpose
model: sonnet
allowed-tools: mcp__chrome-devtools__*, Bash, Read, Glob, Grep
---

# UI Verify - 動作確認スキル

$ARGUMENTS

## 自動実行フロー

このスキルは以下の手順を**自動的に**実行する：

### 1. テスト対象の特定

引数なしで実行された場合、**直近の変更内容**からテスト対象を自動判定する：

1. `git diff --name-only HEAD` でワーキングツリーの変更ファイル一覧を取得
2. `git diff --name-only HEAD~5..HEAD` で直近5コミットの変更ファイル一覧を取得
3. `docs/plans/` 配下の Plan ファイルを読み、実装された機能の概要を把握
4. 変更されたフロントエンドファイル (`packages/web/`) を分析し、影響する画面・コンポーネントを特定
5. 変更されたバックエンドファイル (`packages/server/src/routes/`) から新規・変更APIエンドポイントを特定

**判定ロジック:**
- `packages/web/components/` の変更 → 該当コンポーネントが使われている画面を特定して操作テスト
- `packages/web/hooks/` の変更 → 該当 hook が使われている画面でデータ取得・更新をテスト
- `packages/server/src/routes/` の変更 → 該当APIのネットワークリクエストを確認
- `packages/web/messages/` の変更 → i18n テキストの表示確認

引数ありの場合はその指示に従う。

### 2. 起動中アプリの自動検出

```bash
# 検出スクリプトを実行してURLを取得
.claude/skills/ui-verify/scripts/detect-app.sh
```

スクリプトが返すURLを使用してブラウザで開く。

### 3. テスト実行

特定したテスト対象に対して、以下のパターンでテストを実行する：

#### パターン A: 画面表示テスト
1. 対象画面にナビゲート
2. `take_snapshot` で DOM 要素を確認
3. `take_screenshot` でビジュアル確認
4. 期待する要素が存在するか検証

#### パターン B: ユーザー操作テスト
1. ボタン/リンクのクリック、フォーム入力などの操作を実行
2. **注意**: ポップオーバーが閉じやすい場合は `evaluate_script` で直接DOM操作する
   ```js
   () => {
     const btns = document.querySelectorAll('button');
     for (const b of btns) { if (b.textContent.includes('対象テキスト')) { b.click(); return 'ok'; } }
     return 'not found';
   }
   ```
3. 操作後の状態変化を `take_snapshot` / `take_screenshot` で確認

#### パターン C: API連携テスト
1. 操作によって発火するAPIリクエストを `list_network_requests` で確認
2. `get_network_request` でリクエスト/レスポンス詳細を検証
3. ステータスコード、レスポンスボディの正しさを確認

#### パターン D: エラー確認
1. `list_console_messages` でエラー・警告を確認
2. 既知の問題を除外:
   - 404 (既存のリソース問題)
   - CSS preload warning (既存)
3. 新しいエラーがあれば報告

### 4. レポート出力

テスト結果を以下の形式で報告する：

```
## UI Verification Report

### テスト対象
- 変更の概要（Plan / git diff から）

### テスト結果
| テスト | 結果 | 詳細 |
|--------|------|------|
| 画面表示 | OK/NG | ... |
| 操作テスト | OK/NG | ... |
| API連携 | OK/NG | ... |
| エラー確認 | OK/NG | ... |

### スクリーンショット
（必要に応じて撮影済み）

### 発見した問題
- （あれば記載）
```

## ポート設定

| 環境 | Web (Next.js) | API (Hono) |
|------|---------------|------------|
| デフォルト | 2626 | 2627 |
| Worktree 1 | 2628 | 2629 |
| Worktree 2 | 2630 | 2631 |

## 利用可能な操作

### ブラウザ操作
- `click` - 要素クリック (uid で指定)
- `fill` - テキスト入力
- `fill_form` - フォーム入力
- `press_key` - キー入力 (Enter, Escape など)
- `hover` - ホバー
- `navigate_page` - URL に移動
- `wait_for` - テキスト出現を待機

### 状態確認
- `take_snapshot` - DOM スナップショット（要素の uid を取得）
- `take_screenshot` - スクリーンショット撮影
- `list_pages` - 開いているページ一覧

### デバッグ
- `list_console_messages` - コンソールログ一覧
- `get_console_message` - 特定のログ詳細
- `list_network_requests` - ネットワークリクエスト一覧
- `get_network_request` - 特定のリクエスト詳細
- `evaluate_script` - JavaScript 実行

### パフォーマンス
- `performance_start_trace` - トレース開始
- `performance_stop_trace` - トレース終了
- `performance_analyze_insight` - Core Web Vitals 分析

### エミュレーション
- `emulate` - ダークモード、ネットワーク速度、CPU スロットリング
- `resize_page` - ビューポートサイズ変更

## 重要なルール

- **example.com や仮のURLは絶対に使用しない**
- 必ず `detect-app.sh` でローカルアプリのURLを検出する
- アプリが起動していない場合はユーザーに `pnpm dev` の実行を促す
- テスト対象は git diff / Plan ファイルから動的に判断する
- 操作前に `take_snapshot` で要素の存在を確認する
- ポップオーバーが閉じやすい場合は `evaluate_script` で直接DOM操作する
- 操作後は結果を簡潔に報告する

## 使用例

```
/ui-verify                           # git diff / Plan から自動判定してテスト
/ui-verify ペルソナ作成を確認        # 特定機能のテスト
/ui-verify ブレスト画面を確認        # 特定画面のテスト
/ui-verify コンソールエラーを調査    # エラーログの調査
/ui-verify パフォーマンス計測        # Core Web Vitals の計測
```
