---
name: ui-flow-design
description: >
  機能要件から画面構成・ワイヤーフレームまでを段階的に落とし込む Agent Team スキル。
  design-discussion や feature-discussion の成果物を入力として、
  4ステップ（行動フロー → 情報洗い出し → 画面分割 → ワイヤーフレーム）で画面設計を行う。
  各ステップで user-liaison が AskUserQuestion でユーザーに確認を取り、
  フィードバックループで修正を回す。成果物は PlantUML Salt による視覚的なワイヤーフレーム。
  Use when: 機能から画面に落としたい、画面構成を考えたい、
  ワイヤーフレームを作りたい、画面設計をしたい、画面フローを整理したい。
  design-discussion の後に使うと効果的。
  Triggers: "画面構成", "画面設計", "ワイヤーフレーム", "画面に落とす",
  "ui flow design", "UIフロー設計", "wireframe", "画面を考えたい",
  "UIフロー", "画面遷移", "screen design", "画面フロー", "screen flow"
---

# Screen Flow - 機能 → 画面落とし込みスキル

## コンセプト

「機能ができた！でもどんな画面にすればいいかわからない」を解決する。
AI が全部決めるのではなく、**要所でユーザーに確認しながら一緒に詰めていく**。

## 入力

以下のいずれかを入力として受け取る：
- design-discussion の成果物（`.claude/design_discussion/sessions/<name>/`）
- feature-discussion の成果物
- ユーザーからの直接の機能説明（ある程度詳細なもの）

**入力の粒度**: 「タスクをカンバン形式で管理。ラベル・期限・担当者あり」程度の詳細さが必要。
曖昧な場合はステップ1の前に user-liaison が AskUserQuestion で補足質問する。

## 出力

```
.claude/ui_flow_design/sessions/<session-name>/
├── workflow-state.json           ← プロセス状態管理
├── 01_user-action-flow.md        ← ステップ1: 行動フロー（テキスト説明）
├── 01_state-diagram.puml         ← ステップ1: 状態遷移図（PlantUML）
├── 02_screen-info.md             ← ステップ2: 各画面の必要情報
├── 03_screen-division.md         ← ステップ3: 画面単位の分割（テキスト説明）
├── 03_screen-transition.puml     ← ステップ3: 画面遷移図（PlantUML）
├── 04_wireframes.md              ← ステップ4: ワイヤーフレーム説明
├── 04_wireframes.puml            ← ステップ4: Salt ワイヤーフレーム（PlantUML）
└── 05_final-spec.md              ← ステップ5: 最終仕様書（Single Source of Truth）
```

### ファイル分離ルール

- **PlantUML 図は `.puml` ファイルに切り出す**（Cursor でプレビュー可能にするため）
- `.md` には説明テキストと `.puml` への参照だけ書く
- `.md` 内に PlantUML コードブロックを埋め込まない

```markdown
<!-- .md での参照例 -->
状態遷移図は [01_state-diagram.puml](01_state-diagram.puml) を参照。
```

### 連動更新ルール

画面仕様を修正した場合、以下のファイルを **必ず連動して更新** する：
- `02_screen-info.md` のアスキーアートモック + テーブル
- `03_screen-division.md` の画面一覧テーブル
- `03_screen-transition.puml` の画面遷移図
- `04_wireframes.puml` の Salt ワイヤーフレーム
- `04_wireframes.md` の画面遷移テーブル + 備考欄
- 修正後 `plantuml -checkonly` でバリデーション

1つだけ更新して他を放置しない。validator エージェントがこの不整合を検出する。

### ワイヤーフレームの構成ルール

- `04_wireframes.puml`: 各画面の Salt ワイヤーフレーム（見た目のみ）
- `04_wireframes.md`: 画面一覧テーブル + **画面遷移テーブル** + 備考
- 遷移情報は `.puml` に入れない（Salt では矢印が描けない）。`.md` のテーブルで管理する
- 新しい画面が必要な操作（ポップアップ、ダイアログ等）が追加された場合、画面定義も追加する

## 実行モード

### A) ステップ単位の実行（推奨）

各ステップを1つずつ実行し、ユーザー確認を挟んで進める。
会話をまたいでも `workflow-state.json` で状態が引き継がれる。

```
/ui-flow-design step1    ← ステップ1を実行
  → 成果物を生成 → ユーザーに確認を求めて停止
  → ユーザーが OK or フィードバック

/ui-flow-design step2    ← ステップ2を実行（step1 完了が前提）
  → ...
```

### B) Agent Team モード

5つのエージェントが並列で動き、user-liaison 経由でユーザー確認を取りながら
ステップ1〜4を連続実行する。

---

## 4ステップのプロセス

各ステップは **同じループ構造** で動く。**前のステップが completed でないと次に進めない。**

```
┌──────────────────────────────┐
│ 1. workflow-state.json を読む │
│    → currentStep を確認       │
│ 2. 前ステップが completed?    │
│    → No: 前ステップに戻す    │
│ 3. 情報不足？→ ユーザーに質問 │
│ 4. 生成 → ファイル出力        │
│ 5. ユーザーに確認             │
│    → OK: status=completed     │
│    → 修正: status=needs_revision │
│      → 3 に戻る              │
│ 6. workflow-state.json を更新 │
│    → currentStep を +1        │
└──────────────────────────────┘
```

前のステップに **戻る** こともできる。成果物がファイルに残っているため、戻っても前の情報は消えない。

### ステップ1: ユーザー行動フロー生成
**出力**: `01_user-action-flow.md` + `01_state-diagram.puml`
**前提**: 入力ファイル（design-discussion 成果物 or 機能説明）

1. 入力ファイルを読み、情報が足りなければユーザーに質問する
2. ユーザーの行動フローを生成
3. 状態遷移図を `01_state-diagram.puml` に出力
4. 時系列フロー説明を `01_user-action-flow.md` に出力（.puml への参照を含める）
5. ユーザーに確認を求める（ファイルを直接編集して修正も可）
6. OK なら workflow-state.json を `completed` に更新して停止

### ステップ2: 各画面の必要情報洗い出し
**出力**: `02_screen-info.md`
**前提**: ステップ1 が completed

1. `01_user-action-flow.md` を読む
2. 各アクションに対して整理：表示情報 / インタラクション / ユーザー入力
3. 不足があればユーザーに質問する
4. ファイルに出力
5. ユーザーに確認を求めて停止

### ステップ3: 画面単位に分割
**出力**: `03_screen-division.md` + `03_screen-transition.puml`
**前提**: ステップ2 が completed

1. `01_user-action-flow.md` と `02_screen-info.md` を読む
2. 情報量と操作の切れ目で画面を区切る（「1画面1目的」が基本原則）
3. 画面遷移図を `03_screen-transition.puml` に出力
4. 画面分割の説明を `03_screen-division.md` に出力（.puml への参照を含める）
5. ユーザーに確認を求めて停止

### ステップ4: ワイヤーフレーム生成
**出力**: `04_wireframes.md` + `04_wireframes.puml`
**前提**: ステップ3 が completed

1. `03_screen-division.md` を読む
2. **plantuml-salt スキルを参照して正確な Salt 記法を使う**
3. 全画面の Salt ワイヤーフレームを `04_wireframes.puml` に出力
4. 各画面の説明を `04_wireframes.md` に出力（.puml への参照を含める）
5. ユーザーに確認を求めて停止

### ステップ5: 最終仕様書の出力
**出力**: `05_final-spec.md`
**前提**: ステップ4 が completed

ステップ1〜4の成果物を統合し、**実装に渡せる最終仕様書**を1ファイルにまとめる。
このファイルが画面設計の **Single Source of Truth** になる。
以降の仕様変更はこのファイルを修正し、必要に応じてステップ1〜4の成果物も更新する。

1. ステップ1〜4の全成果物を読む
2. 以下の構成で最終仕様書を生成：
   - 画面一覧（ID + 名前 + 概要）
   - 各画面の詳細（表示情報・操作・入力 + アスキーアートモック）
   - 画面遷移マップ（.puml への参照）
   - ワイヤーフレーム（.puml への参照）
   - 確定した方針・判断事項（workflow-state.json の decisions から）
3. ファイルに出力
4. ユーザーに最終確認を求めて停止

## エージェント構成

| エージェント | 役割 | ツール |
|---|---|---|
| **flow-architect** | 行動フロー設計、画面分割 | Read, Grep, Glob, SendMessage |
| **info-analyst** | 各画面の必要情報・入出力の洗い出し | Read, Grep, Glob, SendMessage |
| **wireframe-designer** | PlantUML Salt でラフ画面を構築 | Read, Write, Edit, Grep, Glob, SendMessage |
| **user-liaison** | ユーザーへの質問を一元管理 | Read, Grep, Glob, SendMessage, **AskUserQuestion** |
| **ux-critic** | フローや画面構成の問題点を指摘 | Read, Grep, Glob, SendMessage |
| **validator** | 各ステップの成果物を検証 | Read, Grep, Glob, **Bash**, SendMessage |

### 通信ルール

- **user-liaison だけが AskUserQuestion を持つ**
- 他のエージェントはユーザーに直接質問しない
- 「ユーザーに聞きたい」場合は SendMessage で user-liaison に依頼する
- user-liaison は複数エージェントからの質問を **整理してまとめて** ユーザーに提示する

### バリデーション

validator は各ステップの生成後に自動起動し、以下を検証する：
- `.puml` ファイルの構文チェック（`plantuml -checkonly` を Bash で実行）
- `workflow-state.json` の整合性（completed ステップの outputFile が存在するか）
- `.md` 内の `.puml` 参照が実在するファイルを指しているか
- 画面遷移図の画面IDが画面一覧に存在するか

問題があれば生成担当エージェントに SendMessage でフィードバックし、修正を依頼する。
ユーザーに確認を求める前に、validator が PASS していることが前提。

## ワークフロー状態管理

`workflow-state.json` でプロセスの状態を管理する：

```json
{
  "meta": {
    "app": "アプリ名",
    "sessionId": "セッションID",
    "createdAt": "日付",
    "updatedAt": "日付",
    "sourceFiles": ["入力ファイルのパス"]
  },
  "steps": [
    {
      "id": 1,
      "name": "ユーザー行動フロー生成",
      "status": "pending | in_progress | completed | needs_revision",
      "outputFile": "01_user-action-flow.md",
      "iterations": [
        {
          "round": 1,
          "generatedAt": "日付",
          "userFeedback": "ユーザーからのフィードバック or null",
          "approved": false
        }
      ]
    }
  ],
  "currentStep": 1,
  "decisions": []
}
```

- **currentStep**: 今どこにいるか
- **steps[].status**: 各ステップの状態
- **steps[].iterations**: 修正ループの履歴（フィードバック・承認フラグ）
- **decisions**: ステップ間で確定した判断事項

## 既存スキルとの連携

- **design-discussion** の成果物（1_clarification.md, 4_decision.md）を自動読み込み
- **feature-discussion** の成果物があれば参照
- **plantuml-salt** スキルをワイヤーフレーム生成時に参照
- ペルソナ・トンマナファイルがあれば自動で反映

## ディレクトリ構造

design-discussion と同じセッション構造を使う：

```
.claude/ui_flow_design/sessions/<session-name>/
```

セッション名は design-discussion と合わせると紐付けが明確になる。
