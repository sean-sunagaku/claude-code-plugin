---
name: cruft-code-sweep
description: >
  コードベースの不要なフォールバック・互換性コード・デッドコードを
  3つの専門エージェント（scanner + historian + verifier）が協調して検出・安全性検証する監査スキル。
  scanner が自律探索で候補を発見し、historian が git 履歴から時間軸の文脈を付与し、
  verifier が「消してデグレしないか」を検証する。任意のリポジトリで実行可能。
  Use when: コードのクリーンアップをしたい、技術的負債を可視化したい、
  不要な互換性コードや deprecated コードを探したい、
  リリース前に dead code を確認したい。
  Triggers: "cruft", "code sweep", "dead code", "デッドコード", "不要なコード",
  "互換性コード", "fallback", "フォールバック", "deprecated", "技術的負債",
  "code audit", "コード監査", "cleanup", "クリーンアップ", "TODO整理"
---

# Cruft Code Sweep

3つの専門エージェントが協調して、不要コードの **発見** → **履歴調査** → **安全性検証** を行う。

## Agent Team 構成

| Agent | 役割 | 視点 |
|-------|------|------|
| **cruft-scanner** | コードベースを自律探索し、cruft 候補を発見する | 「これ不要では？」 |
| **codebase-historian** | git 履歴から各候補の時間軸の文脈を調査する | 「いつ・なぜ書かれた？今も必要？」 |
| **safety-verifier** | 各候補が本当に削除可能か検証する。デグレ防止 | 「消して本当に大丈夫？」 |

### 協調フロー

```
scanner: Phase 1 (プロジェクト理解) → Phase 2 (パターンスキャン) → Phase 3 (自律探索)
    ↓ 候補リストを historian に送信
historian: 各候補の git blame/log を調査し、時間軸の文脈を付与
    ↓ 履歴付き候補リストを verifier に送信
verifier: 各候補について依存関係・テスト・副作用を検証（履歴情報も加味）
    ↓ 検証結果を scanner に返信
scanner: 検証結果を統合してレポート生成 → Phase 4 (レポート出力)
```

## ワークフロー

### Step 1: チーム起動

TaskCreate で4つのタスクを作成:
1. cruft-scanner: プロジェクト理解 + パターンスキャン + 自律探索
2. codebase-historian: 候補の git 履歴調査（タスク1完了後）
3. safety-verifier: 候補の安全性検証（タスク2完了後）
4. レポート生成（タスク3完了後）

3つのエージェントを並列起動する:

```
Task(subagent_type="general-purpose", name="cruft-scanner", mode="bypassPermissions", run_in_background=true)
Task(subagent_type="general-purpose", name="codebase-historian", mode="bypassPermissions", run_in_background=true)
Task(subagent_type="general-purpose", name="safety-verifier", mode="bypassPermissions", run_in_background=true)
```

### Step 2: scanner のプロンプト

scanner には以下の内容をプロンプトとして渡す:

---

あなたは **cruft-scanner** です。コードベースの不要コードを自律的に探索してください。

#### Phase 1: プロジェクト理解

まずプロジェクト全体像を掴む:
- `Glob: **/package.json, **/tsconfig.json, **/app.config.*, **/eas.json`
- ルートの `package.json` を Read（dependencies, scripts）
- `CLAUDE.md` / `README.md` があれば Read
- 言語/フレームワーク、モノレポ構造、テストフレームワークを特定

dependencies から自動判定:
- `react-native` / `expo` → RN パターン有効化
- `firebase` → Firebase パターン有効化
- `express`, `fastify` 等 → Node.js パターン有効化

#### Phase 2: パターンスキャン

`{SKILL_DIR}/references/patterns.md` の P1〜P13 を Grep で検索。
Phase 1 で判定したフレームワーク固有パターン（`{SKILL_DIR}/references/framework-patterns.md`）も含める。

優先順位:
1. HIGH: @deprecated (P1), 空 catch (P2), コメントアウトコード (P3), DUMMY_/MOCK_ (P13)
2. MEDIUM: TODO/FIXME (P4), as any (P5), localhost (P6), env fallback (P7), Platform.OS web (P8)
3. LOW: @ts-ignore (P9), eslint-disable (P10), チケット付き TODO (P11)

各ヒットに対して:
1. Read: 前後 10〜20 行を読む
2. 呼び出し元チェック: Grep で参照数を確認
3. severity 調整: patterns.md のコンテキスト判定表に従う

#### Phase 3: 自律探索

定型パターンでは拾えない cruft を自分で探す:

**未使用 export**: `export function|const|class` を列挙 → 参照 0 件を特定
**設定の重複/矛盾**: config/, constants/ を Read → 同じ値の複数ハードコード
**到達不能コード**: 早期 return 後のコード、常に false の分岐
**過剰防御コード**: 型で保証済みの null チェック、二重バリデーション
**臭い検知**: ファイル名/関数名に old, legacy, temp, backup, workaround, compat

#### 候補リスト作成

全候補を以下の形式で整理し、codebase-historian に SendMessage で送る:

```
## 候補 N: [タイトル]
- ファイル: path/to/file.ts:行番号
- パターン: P1 / 探索で発見
- severity: HIGH / MEDIUM / LOW
- 内容: [1行説明]
- コードスニペット: [3〜5行]
- 呼び出し元: N 件
- 削除した場合の想定影響: [推測]
```

---

### Step 3: historian のプロンプト

historian には以下の内容をプロンプトとして渡す:

---

あなたは **codebase-historian** です。cruft-scanner が発見した候補について、git 履歴から時間軸の文脈を調査してください。

scanner から候補リストが SendMessage で届くまで待機してください（TaskList を定期チェック）。

#### 調査手順（各候補に対して）

**1. git blame で最終更新を特定**
- `git blame -L 行番号,+5 ファイルパス` で、該当コードの最終変更者・日時・コミットハッシュを取得
- 最終更新が **6ヶ月以上前** → cruft の可能性が上がる（staleness_score: HIGH）
- 最終更新が **1ヶ月以内** → 意図的に追加/維持されている可能性（staleness_score: LOW）

**2. コミットメッセージの文脈分析**
- `git log --oneline -5 -- ファイルパス` で直近の変更履歴を確認
- コミットメッセージに以下のキーワードがあれば記録:
  - `workaround`, `temporary`, `hack`, `quick fix`, `revert` → cruft の裏付け
  - `fix #123`, `closes #456` → 関連 issue/PR が close 済みか確認の手がかり
  - `migration`, `upgrade`, `compat` → 互換性コードの痕跡

**3. ファイルの変更頻度**
- `git log --oneline -- ファイルパス | wc -l` でファイル全体の変更回数を確認
- 変更回数が極端に少ない（1-2回）→ 作って放置された可能性
- 候補コードの行が最初のコミットから変更されていない → 初期実装のまま放置

**4. 周辺コードとの関係**
- 同じコミットで変更された他のファイルを `git show --stat コミットハッシュ` で確認
- 「一時対応で複数ファイルをまとめて変更」→ 他の変更は後でクリーンアップされたが、この候補だけ残った可能性

**5. 削除・復活の履歴**
- `git log -S "シンボル名" --oneline` で、候補のシンボルが過去に削除→復活していないか確認
- 一度削除されて復活したコード → 正当な理由がある可能性（慎重に扱う）

#### 調査結果の送信

各候補に時間軸の文脈を付与し、safety-verifier に SendMessage で送る:

```
## 候補 N: [タイトル]（scanner の元情報をそのまま含める）
### git 履歴調査
- 最終更新: YYYY-MM-DD（N ヶ月前）by [author]
- staleness_score: HIGH / MEDIUM / LOW
- コミットメッセージ: "[メッセージ抜粋]"
- 関連キーワード: workaround / temporary / fix #N / なし
- ファイル変更回数: N 回
- 候補行の変更回数: N 回（初回から変更なし / N回変更あり）
- 削除・復活: なし / あり（YYYY-MM-DD に削除 → YYYY-MM-DD に復活）
- 同一コミットの他ファイル: [ファイル一覧（あれば）]
- historian の所見: [1-2文の分析。例: "2年前の workaround コミットで追加され、以降変更なし。一時対応が残存した可能性が高い"]
```

---

### Step 4: verifier のプロンプト

verifier には以下の内容をプロンプトとして渡す:

---

あなたは **safety-verifier** です。cruft-scanner が発見した候補について、codebase-historian の git 履歴調査を加味しつつ「削除してデグレしないか」を検証してください。

historian から履歴付き候補リストが SendMessage で届くまで待機してください（TaskList を定期チェック）。

#### 検証手順（各候補に対して）

**1. 依存グラフの追跡**
- Grep で候補のシンボル名（関数名、変数名、クラス名）の全参照を検索
- import チェーンを辿る（A が B を import、B が C を import → C を消すと A にも影響）
- re-export / barrel export を見逃さない

**2. テストカバレッジの確認**
- 候補に対応するテストファイル（*.test.*, *.spec.*）が存在するか
- テストが候補のシンボルを直接参照しているか
- テストが候補の振る舞いに間接的に依存していないか

**3. ランタイム副作用の分析**
- グローバル変数の変更（window.X, globalThis.X）
- イベントリスナーの登録/解除
- モジュールのインポート時に実行される副作用（top-level await, polyfill 等）
- 環境変数の参照（削除すると undefined になる箇所はないか）

**4. 型への影響**
- TypeScript の型推論に影響するか（re-export された型、interface の extends）
- 削除すると型エラーが発生するか

**5. historian の履歴情報を加味した判定**

historian から提供された staleness_score やコミットメッセージの文脈を判定に活用する:
- staleness_score: HIGH + 参照 0 件 → SAFE の確度が上がる
- staleness_score: LOW（最近追加）→ 意図的な可能性を考慮
- コミットメッセージに `workaround` / `temporary` → cruft の裏付け
- 過去に削除→復活の履歴あり → KEEP の可能性を検討

**6. 判定**

各候補に以下の判定を付ける:

| 判定 | 意味 |
|------|------|
| **SAFE** | 削除しても問題なし。参照 0 件、副作用なし |
| **LIKELY_SAFE** | ほぼ安全だが、確認推奨。間接参照の可能性あり |
| **RISKY** | 削除するとデグレの可能性あり。具体的なリスクを明記 |
| **KEEP** | 削除不可。正当な理由がある（明記する） |

#### 検証結果の送信

検証結果を scanner に SendMessage で返す:

```
## 候補 N: [タイトル]
- 判定: SAFE / LIKELY_SAFE / RISKY / KEEP
- 参照数（実数）: N 件（内訳: 直接 N, re-export N, テスト N）
- テストカバレッジ: あり / なし / 間接的
- 副作用: なし / あり（具体的に）
- 型への影響: なし / あり（具体的に）
- デグレリスク: [具体的なシナリオ。なければ「なし」]
- 推奨アクション: [削除する / コメント改善 / リファクタ / 現状維持]
```

---

### Step 5: レポート生成

scanner が verifier の検証結果を受け取ったら、統合レポートを生成する。

出力先: `./cruft-code-sweep-report.md`

フォーマット: [references/report-template.md](references/report-template.md) に従う。

レポートには verifier の判定を含める:

| 項目 | 内容 |
|------|------|
| 候補ごとの severity | scanner の判定 |
| 安全性判定 | verifier の SAFE/LIKELY_SAFE/RISKY/KEEP |
| デグレリスク | verifier が特定した具体的リスク |
| 推奨アクション | 両者の分析を統合した最終推奨 |

### Step 6: クリーンアップ

レポート生成後:
1. 全エージェント（scanner, historian, verifier）に shutdown_request を送信
2. TeamDelete でチーム削除

## リファレンス

- [references/patterns.md](references/patterns.md) — P1〜P13 検出パターン詳細 + コンテキスト判定表
- [references/framework-patterns.md](references/framework-patterns.md) — RN/Firebase/Node.js/Python 固有パターン
- [references/report-template.md](references/report-template.md) — レポートフォーマット
