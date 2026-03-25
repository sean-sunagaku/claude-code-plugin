---
name: arch-design
description: >
  仕様書・要件定義からソフトウェアアーキテクチャを設計するスキル。
  5人の専門エージェント（Architecture Lead・Module Designer・Dependency Analyst・
  Platform Expert・Devil's Advocate）が協議しながら、
  モジュール分割・依存関係・データフロー・インターフェース設計を行う。
  成果物は構造化されたアーキテクチャ設計書（Markdown）。
  Use when: 仕様書からどう設計するか迷っている時、モジュール分割の方針を決めたい時、
  技術スタックに合ったアーキテクチャパターンを選びたい時、
  設計書を作成したい時。
  Triggers: "アーキテクチャ設計", "arch design", "仕様書から設計",
  "モジュール分割", "設計書を作りたい", "アーキテクチャを考えて",
  "コンポーネント設計", "依存関係を設計", "どう設計する",
  "design the architecture", "design from spec"
allowed-tools: "Read, Write, Edit, Glob, Grep, Bash, Task, SendMessage, AskUserQuestion, TeamCreate, TeamDelete, Agent"
---

# Arch Design - アーキテクチャ設計スキル

5つの専門エージェントが**仕様書・要件定義からソフトウェアアーキテクチャを協議設計**するスキル。
Facilitator（この SKILL.md 自身）がオーケストレーションし、
各エージェントが専門観点で設計を議論・反論・合意形成する。

## スキルのフォーカス（CRITICAL）

このスキルは **仕様書・要件定義 → アーキテクチャ設計** に特化している。

- **対象**: モジュール分割、依存関係設計、データフロー、インターフェース定義、パターン選択
- **対象外**: 詳細な実装コード（それは team-plan/team-implement へ）、UI/UX デザイン
- **入力**: 仕様書・要件定義・既存コードベース（任意）
- **成果物**: アーキテクチャ設計書（MD）、モジュール構成図、依存関係図、ADR

## チーム構成

| ロール | ファイル | 専門領域 |
|--------|---------|---------|
| **Facilitator** | この SKILL.md | 設計進行・合意形成・設計書出力 |
| **Architecture Lead** | `agents/architecture-lead.md` | 全体方針・パターン選択・トレードオフ判断 |
| **Module Designer** | `agents/module-designer.md` | モジュール分割・凝集度・SRP・インターフェース設計 |
| **Dependency Analyst** | `agents/dependency-analyst.md` | 依存関係・結合度・循環依存・依存方向制御 |
| **Platform Expert** | `agents/platform-expert.md` | 技術スタック固有パターン・フレームワーク制約 |
| **Devil's Advocate** | `agents/devils-advocate.md` | 過剰設計・YAGNI違反・将来負債の指摘 |

## コア原則

1. **仕様ドリブン** - 設計は常に仕様・要件に根ざす。推測で設計しない
2. **トレードオフを明示** - 「最善」はない。利点・欠点を等価に扱う
3. **YAGNI/KISS 優先** - 今必要なものだけを設計する。将来への対応は慎重に
4. **ユーザー主導の進行** - ステップ完了時に自動で次のステップに進まない。必ずユーザーが成果物をレビュー・承認してから次へ進む。特に Step 2（パターン選定）は比較結果のレビューとパターン選択がなければ Step 3 に進めない
5. **依存方向を制御** - 循環依存・意図しない結合は設計段階で排除
6. **プラットフォーム現実** - 理想論より、採用スタックの慣習・制約に従う

## ワークフロー概要

```
Step 1: 仕様・コンテキストの把握
  担当: Facilitator + Architecture Lead
  目的: 要件・制約・既存コードを理解し、設計の範囲を確定

    ↓

Step 2: アーキテクチャ案の網羅的列挙・比較・選定
  担当: Architecture Lead + Platform Expert + Devil's Advocate
  フロー:
    2a. 10個の候補案を網羅的に列挙（マイナーな案も含む）
    2b. 全案を多軸スコアリングで比較表を作成
    2c. Top 2-3 案に絞り込み・詳細議論
    2d. AskUserQuestion でユーザーにパターン選択を確認 → 1案確定
    ※ ユーザーが Step 2 の成果物をレビュー・承認するまで Step 3 に進まない

    ↓ ユーザー承認後

Step 3: モジュール設計・依存関係定義
  担当: Module Designer + Dependency Analyst + Devil's Advocate
  目的: モジュール境界・インターフェース・依存方向を確定

    ↓

Step 4: 設計書出力・ユーザー承認
  担当: Architecture Lead + Facilitator（ユーザー承認）
  目的: 最終設計書を生成し、ADR とともにユーザーに提示
```

各ステップの詳細は `references/step_details.md` を参照。

## セッション開始

設計セッション開始時、以下を実行:

1. **仕様書・ドキュメントを読み込み**（`docs/`, `spec/`, `.claude/` 配下の MD を Glob で検索）
2. **既存コードの構造を把握**（コードベースがあれば Glob/Read でプロジェクト構造を確認）
3. **Phase A: 事前ヒアリング**（下記参照）— AskUserQuestion で大枠の設計方針を確認
4. **セッション名（design-slug）を生成**:
   - 設計テーマを英語の kebab-case スラッグに変換
   - 日本語の場合は英訳してからスラッグ化
5. **セッションディレクトリを Bash スクリプトで一括作成**:
   ```bash
   SESSION_DIR=".claude/arch-design/sessions/<design-slug>"
   mkdir -p "$SESSION_DIR/step1-context"
   ```
   - `step1-context/` のみサブディレクトリとして作成（複数エージェントのフィードバックを格納）
   - **Step 2〜4 の成果物はサブディレクトリを作成せず、セッションルートに `step2-*.md`, `step3-*.md`, `step4-*.md` として配置する**
6. `session.json` を作成（下記テンプレート）— Phase A の回答を `designPolicy` に記録
7. `design_log.md` を作成（インデックス兼進捗管理）
8. **設計深さモードを自動判定**:
   - Light: 単一モジュール・明確な要件・小規模変更
   - Standard: 複数モジュール・新機能追加（デフォルト）
   - Deep: システム全体設計・アーキテクチャ変更・複数チーム横断
9. **Agent Team を作成（TeamCreate — CRITICAL）**:
   ```
   TeamCreate:
     team_name: "arch-design-<design-slug>"
     description: "<設計テーマ>のアーキテクチャ設計チーム"
   ```
   - **必ず TeamCreate を先に実行してからエージェントを起動する**
   - TeamCreate なしで Agent を起動すると SendMessage（broadcast）が機能しない
10. **エージェントを Agent ツールで起動**（team_name パラメータ必須）:
   ```
   Agent:
     name: "architecture-lead"
     team_name: "arch-design-<design-slug>"
     subagent_type: "general-purpose"
     prompt: "<タスク指示 + Phase A の回答 + 設計方針>"
     run_in_background: true
   ```
   - 5エージェント全てに `team_name` を指定して起動する
   - `run_in_background: true` で並列起動
   - 各エージェントのプロンプトには Phase A の回答を含める
   - エージェント定義（`agents/*.md`）の内容をプロンプトに含めるか、参照パスを指示する
11. Step 1 を開始

### Phase A: 事前ヒアリング（Step 1 開始前・CRITICAL）

**エージェント起動前に**、AskUserQuestion でアプリの性質から推測できる大枠の設計方針を確認する。
エージェントが議論を始めてから方針転換すると手戻りが大きいため、事前に確定させる。

仕様書・技術スタックの情報を読み込んだ上で、以下の観点から質問を構成する。

#### 必ず聞く質問（プラットフォーム問わず）

アプリの「本質」に関わる質問。フレームワーク選定は Step 2 で行うため、ここでは聞かない。

| 観点 | 質問例 | なぜ事前に聞くか |
|------|--------|----------------|
| **アプリの核心的価値** | このアプリで一番大事にしたい体験は？ 何を「絶対に守りたい」か？ | 設計判断の優先順位（速度 vs 安全性 vs 柔軟性）に直結 |
| **ユーザーとの関係** | 自分専用？ 少数に配布？ 不特定多数にリリース？ | 抽象化レベル・エラーハンドリング・セキュリティの粒度に影響 |
| **設計哲学** | シンプル最優先（動くものを最速で）？ 堅牢性重視（テスト・型安全）？ 拡張性重視（将来の機能追加に備える）？ | 全モジュール設計・依存方向・ファイル数に影響 |
| **変化の予測** | 将来追加しそうな機能は？ 変わらない部分は？ | モジュール境界の置き方（変化する部分を隔離する設計）に影響 |

#### 状況に応じて聞く質問（自動判断）

仕様書を読んだ上で、アーキテクチャ判断に影響する「プロダクトレベルの意思決定」を追加質問する。
**フレームワーク固有の質問（状態管理ライブラリ、CSS手法等）は Step 2 で決めるためここでは聞かない。**

| 観点 | 条件（いつ聞くか） | 質問例 | なぜ事前に聞くか |
|------|-------------------|--------|----------------|
| **データの性質** | データ永続化が必要な場合 | データはローカルだけ？ サーバーと同期？ オフラインでも使える必要がある？ | オフライン対応の有無でアーキテクチャが根本的に変わる |
| **リアルタイム性** | 複数デバイス・ユーザーがある場合 | リアルタイム同期は必要？ 遅延はどこまで許容？ | イベント駆動設計の要否に影響 |
| **パフォーマンス制約** | 重い処理がある場合 | 大量データ処理がある？ 60fps 維持が必要？ | 非同期設計・キャッシュ戦略に影響 |
| **セキュリティ要件** | ユーザーデータを扱う場合 | 認証は必要？ 個人情報を扱う？ | 認証層・暗号化・アクセス制御の設計に影響 |
| **スケール見通し** | 成長する可能性がある場合 | ユーザー数 100人？ 10万人？ データ量は？ | マイクロサービス vs モノリスの判断に影響 |
| **リリース頻度** | チーム開発の場合 | 週1リリース？ 月1？ CI/CD は？ | モジュール独立性・テスト戦略に影響 |

#### 質問しない項目

- 仕様書・ADR に既に明記されている項目
- 技術スタックから一意に決まる項目（例: Flutter なら Dart）
- 「どちらでもアーキテクチャに影響しない」項目

**質問の構成ルール**:
- AskUserQuestion で **2〜4 問**にまとめる（多すぎると回答コストが高い）
- 各質問に**推奨オプション**を含める（ユーザーが迷わないように）
- 「必ず聞く」3問 + 「技術スタックに応じて」0〜1問 = 計 3〜4 問が目安

**Phase A の回答は session.json に記録し、全エージェントのプロンプトに含める。**

### Phase B: 議論中の随時確認（各 Step 内）

エージェントが議論中に「ユーザーの判断が必要」と判断した場合:
1. エージェント → Facilitator に `[ASK_USER_REQUEST]` を送信
2. Facilitator が AskUserQuestion でユーザーに確認
3. 回答を全エージェントに broadcast で共有

### 初期 JSON テンプレート

```json
{
  "sessionId": "<design-slug>",
  "topic": "<設計テーマ>",
  "status": "in_progress",
  "mode": "<light|standard|deep>",
  "currentStep": 1,
  "createdAt": "<ISO8601>",
  "updatedAt": "<ISO8601>",
  "techStack": null,
  "designPolicy": {
    "uiFramework": null,
    "dataStorage": null,
    "settingsManagement": null,
    "testingPolicy": null,
    "teamSize": null,
    "minTarget": null
  },
  "steps": {
    "1_context": false,
    "2_pattern": false,
    "3_modules": false,
    "4_output": false
  },
  "selectedPattern": null,
  "modules": []
}
```

## セッション管理コマンド

| 発言 | アクション |
|------|----------|
| 「アーキテクチャ設計：〇〇」 | 新規セッション作成、Step 1 開始 |
| 「次のステップ」「進めて」 | 現在のステップを完了し次へ |
| 「戻って」「前のステップ」 | 前のステップに戻る |
| 「今どこ？」「進捗は？」 | 現在のステップと完了状況を表示 |
| 「もっと議論して」 | 現在のステップで追加の議論ラウンドを実行 |
| 「悪魔の代弁者を呼んで」 | Devil's Advocate による追加批判セッション |
| 「設計書を出して」 | 現在の設計状態から設計書ドラフトを生成 |
| 「ADR を出して」 | Architecture Decision Record を生成 |
| 「一覧」「セッション一覧」 | 過去のセッション一覧を表示 |
| 「再開：〇〇」 | 指定セッションを再開 |

## 進行時の表示フォーマット

各ステップ開始時:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[アーキテクチャ設計] <設計テーマ>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
現在: Step <N>/4 - <ステップ名>
進捗: [████░░░░░░] 40%
モード: <Light|Standard|Deep>
担当: <リードエージェント> + <サブエージェント>

エージェントチームが議論中...
```

議論結果提示時:
```
━━━━ チーム議論結果 ━━━━

合意: [全員が同意した設計方針]
対立: [論点と各エージェントの立場]
懸念: [Devil's Advocate が指摘したリスク]

どう判断しますか？
```

ステップ完了時:
```
Step <N> 完了: <ステップ名>
   → <簡潔なサマリー>
   → 議論ラウンド: <N>回
   → 確定事項: <N>件

次へ進みますか？（「次へ」で続行）
```

## セッション完了条件

全ステップが `true` の場合:
```json
{
  "status": "completed",
  "completedAt": "<ISO8601>",
  "selectedPattern": "<採用パターン名>",
  "steps": {
    "1_context": true,
    "2_pattern": true,
    "3_modules": true,
    "4_output": true
  }
}
```

**生成物（ファイル構成）**:

```
.claude/arch-design/sessions/<design-slug>/
├── session.json                    # セッション進捗管理
├── design_log.md                   # インデックス（進捗管理）
│
├── step1-context/                  # Step 1 成果物（唯一のサブディレクトリ）
│   ├── README.md                   # 機能要件・非機能要件・制約・設計キーポイント
│   ├── module-designer-feedback.md
│   ├── dependency-analyst-feedback.md
│   ├── devils-advocate-feedback.md
│   └── platform-expert-feedback.md
│
├── step2-patterns.md               # Step 2: 10案列挙・比較表・スコアリング
├── step2-scoring-rationale.md      # Step 2: スコア根拠・エージェント間合意
├── step2-selected-pattern.md       # Step 2: 確定パターン・ADR・棄却理由
│
├── step3-module-design.md          # Step 3: モジュール一覧・依存グラフ・インターフェース
├── step3-devils-advocate-review.md # Step 3: YAGNI 批判・過剰分割チェック
│
└── step4-architecture.md           # Step 4: 最終アーキテクチャ設計書（ADR 含む）
```

**ファイル出力ルール（CRITICAL）**:
- **Step 1 のみ `step1-context/` サブディレクトリを使用**（複数エージェントのフィードバックを格納するため）
- **Step 2〜4 はサブディレクトリを一切作成しない**。セッションルートに `step2-*.md`, `step3-*.md`, `step4-*.md` として配置
- `patterns/`, `diagrams/` 等のサブディレクトリも作成禁止。パターン詳細は `step2-patterns.md` 内のセクションとして記述
- エージェントが成果物を書き出す際は、**必ず上記のファイルパスに従う**。独自のディレクトリやファイルを追加しない

## 既存スキルとの連携

```
[仕様策定] user-journey / feature-discussion
    ↓
[アーキテクチャ設計] arch-design ← このスキル
    ↓
[技術的意思決定] design-discussion（実装アプローチの比較）
    ↓
[実装計画] team-plan
    ↓
[実装] team-implement
```

## リファレンスインデックス

| ファイル | 内容 |
|---------|------|
| `references/step_details.md` | Step 1-4 の詳細フロー（担当・目的・完了条件） |
| `references/architecture_patterns.md` | アーキテクチャパターン集（MVVM/Clean/Hexagonal/TCA 等） |
| `references/module_design_principles.md` | モジュール設計原則（凝集度・結合度・SOLID・パッケージ原則） |
| `references/output_templates.md` | 設計書テンプレート（モジュール図・ADR・依存関係図） |
| `references/spec_to_architecture.md` | 仕様書→設計の変換手法（C4 Model・DDD・Event Storming・Contract-First） |
| `references/design_checklist.md` | 設計チェックリスト（SOLID・状態管理・YAGNI・プラットフォーム別QR） |
