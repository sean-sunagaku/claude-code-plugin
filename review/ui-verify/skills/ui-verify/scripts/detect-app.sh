#!/bin/bash
# 起動中のフロントエンドアプリを検出してURLを返す

set -e

# ポート定義
DEFAULT_WEB_PORT=2626
WORKTREE_PORTS=(2628 2630 2632 2634)

# 関数: ポートが使用中かチェック
check_port() {
    lsof -i ":$1" -P -n 2>/dev/null | grep -q LISTEN
}

# 関数: .env.local からポートを取得
get_env_port() {
    local env_file="packages/web/.env.local"
    if [[ -f "$env_file" ]]; then
        grep -E "^(NEXT_PUBLIC_)?PORT=" "$env_file" 2>/dev/null | head -1 | cut -d'=' -f2
    fi
}

# メイン検出ロジック
detect_url() {
    # 1. .env.local のポート設定を確認
    local env_port
    env_port=$(get_env_port)
    if [[ -n "$env_port" ]] && check_port "$env_port"; then
        echo "http://localhost:$env_port"
        return 0
    fi

    # 2. デフォルトポートを確認
    if check_port "$DEFAULT_WEB_PORT"; then
        echo "http://localhost:$DEFAULT_WEB_PORT"
        return 0
    fi

    # 3. Worktree ポートを確認
    for port in "${WORKTREE_PORTS[@]}"; do
        if check_port "$port"; then
            echo "http://localhost:$port"
            return 0
        fi
    done

    # 4. 見つからない場合
    echo "ERROR: No running app detected on ports 2626-2635"
    echo "Please run 'pnpm dev' to start the development server"
    return 1
}

# 実行
detect_url
