#!/bin/bash
# ============================================================
# 仕様駆動設計 - 分析ワークフロー表示スクリプト
# ============================================================

set -e

print_steps() {
    cat << 'EOF'
============================================================
仕様駆動設計 - 分析ワークフロー
============================================================

【Step 1】ドメインモデル抽出
  □ 仕様書から名詞を抽出 → Entity/VO候補
  □ 識別子を持つか判定 → Entity
  □ 値で比較されるか判定 → Value Object
  □ 状態変化のトリガー → Domain Event
  → 出力: entities, value_objects, domain_events

【Step 2】クラス責務分析
  □ 各Entityに対応するServiceを特定
  □ 単一責任を1文で定義
  □ 公開メソッドを列挙
  □ 依存関係を特定（Interface）
  → 出力: classes

【Step 3】純粋関数抽出
  □ バリデーション関数を特定 (validate*, isValid*)
  □ 変換関数を特定 (format*, parse*, truncate*)
  □ 判定関数を特定 (is*, should*, can*)
  □ 選択・計算関数を特定 (select*, calculate*)
  □ 構築関数を特定 (build*, create*)
  → 出力: pure_functions

【Step 4】テストケース設計
  □ 各純粋関数の入力ドメインを分析
  □ 同値クラスを特定
  □ 境界値を特定
  □ エラーケースを列挙
  → 出力: test_cases

【Step 5】実装順序決定
  □ Layer 1: 純粋関数（依存なし）
  □ Layer 2: Value Objects
  □ Layer 3: Entities + Domain Services
  □ Layer 4: Application Services（モック使用）
  □ Layer 5: Infrastructure
  → 出力: implementation_order

EOF
}

print_patterns() {
    cat << 'EOF'
============================================================
テストパターン
============================================================

■ 純粋関数パターン

【validation】
  プレフィックス: validate, isValid
  シグネチャ: (input: T) => ValidationResult
  テストカテゴリ: valid_input, invalid_input, null, boundary

【format】
  プレフィックス: format, truncate, strip
  シグネチャ: (input: string, options?) => string
  テストカテゴリ: normal, empty, boundary_length

【parse】
  プレフィックス: parse, extract
  シグネチャ: (input: string) => T | null
  テストカテゴリ: valid_format, invalid_format, edge_cases

【predicate】
  プレフィックス: is, should, can, has
  シグネチャ: (input: T) => boolean
  テストカテゴリ: true_cases, false_cases

【select】
  プレフィックス: select, choose, pick
  シグネチャ: (candidates: T[], criteria: C) => T
  テストカテゴリ: single, multiple, empty, criteria_variations

【calculate】
  プレフィックス: calculate, compute, count
  シグネチャ: (inputs: T) => number
  テストカテゴリ: normal, zero, max, boundary

【build】
  プレフィックス: build, create, make, compose
  シグネチャ: (parts: P) => T
  テストカテゴリ: all_parts, optional_parts, invalid_parts

------------------------------------------------------------

■ クラステストパターン

【状態遷移テスト】
  観点: 初期状態 → メソッド実行 → 期待状態
  例: new User() → activate() → isActive === true

【不変条件テスト】
  観点: どの操作後も常に満たすべき制約
  例: balance >= 0（残高は常に0以上）

【境界条件テスト】
  観点: 状態の境界でのふるまい
  例: 在庫0の時の購入、上限到達時の追加

【依存モック】
  パターン: Repository, Gateway, Client, Provider
  方針: インターフェース経由で注入、テスト時にモック

------------------------------------------------------------

■ 保守性チェックリスト

【SOLID原則】
  □ S: 単一責任 - クラスの変更理由は1つか？
  □ O: 開放閉鎖 - 拡張に開き、修正に閉じているか？
  □ L: リスコフ - 派生クラスは基底クラスと置換可能か？
  □ I: インターフェース分離 - 不要なメソッドを強制していないか？
  □ D: 依存性逆転 - 具象ではなく抽象に依存しているか？

【テスタビリティ】
  □ 依存は注入可能か？（コンストラクタ or メソッド）
  □ 副作用は分離されているか？
  □ 時間・乱数は注入可能か？
  □ 外部APIはインターフェース経由か？

【可読性】
  □ メソッド名は振る舞いを表しているか？
  □ 1メソッド1責任か？
  □ ネストは3階層以内か？
  □ マジックナンバーは定数化されているか？

EOF
}

print_append_template() {
    cat << 'EOF'
============================================================
Planファイル追記テンプレート
============================================================

---

## 仕様駆動設計: <機能名>

### ドメインモデル

#### Entities

| Entity | 識別子 | 主要属性 | 振る舞い |
|--------|--------|---------|---------|
| <名前> | <ID> | <属性> | <メソッド> |

#### Value Objects

| VO | 属性 | 不変条件 |
|----|------|---------|
| <名前> | <属性> | <制約> |

#### Domain Events

| Event | トリガー | ペイロード |
|-------|---------|-----------|
| <名前> | <発火条件> | <データ> |

### クラス設計

#### 1. <ClassName>

**責任:** <単一責任を1文で>

| メソッド | 入力 | 出力 | 副作用 | 純粋? |
|---------|------|------|--------|-------|
| <名前> | <型> | <型> | <内容> | ✅/❌ |

**依存:** <インターフェース名>

### 純粋関数一覧 ⭐

| 関数 | カテゴリ | 入力 | 出力 | 場所 |
|------|---------|------|------|------|
| `<名前>` | <カテゴリ> | <型> | <型> | <ファイルパス> |

### 単体テスト設計 ⭐

#### 純粋関数テスト: `<関数名>`

| ID | カテゴリ | 入力 | 期待結果 | 説明 |
|----|---------|------|---------|------|
| EQ-01 | 同値 | <値> | <結果> | <説明> |
| BV-01 | 境界 | <値> | <結果> | <説明> |
| ERR-01 | エラー | <値> | <結果> | <説明> |

#### クラステスト: `<ClassName>`

| ID | メソッド | シナリオ | 事前条件 | 入力 | 期待結果 | モック |
|----|---------|---------|---------|------|---------|--------|
| C-01 | <メソッド> | <シナリオ> | <状態> | <値> | <結果> | <依存> |

**テスト観点:**
- 状態遷移: 初期状態 → メソッド実行 → 期待状態
- 不変条件: 常に満たすべき制約
- 境界条件: 状態の境界でのふるまい
- 異常系: 例外、エラーハンドリング

### テストファースト実装順序

1. [ ] Layer 1: 純粋関数 + test
2. [ ] Layer 2: ドメインサービス + test
3. [ ] Layer 3: インフラ層

EOF
}

print_usage() {
    cat << 'EOF'
Usage: analyze.sh [COMMAND]

Commands:
  --steps      分析ステップを表示
  --patterns   純粋関数パターンを表示
  --template   追記テンプレートを表示
  --all        すべて表示

実際の追記はClaudeがEditツールで既存Planファイルに行う
EOF
}

# Main
case "${1:-}" in
    --steps)
        print_steps
        ;;
    --patterns)
        print_patterns
        ;;
    --template)
        print_append_template
        ;;
    --all)
        print_steps
        print_patterns
        print_append_template
        ;;
    *)
        print_usage
        ;;
esac
