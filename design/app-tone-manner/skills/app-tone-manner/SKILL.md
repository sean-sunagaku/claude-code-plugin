---
name: app-tone-manner
description: >
  アプリのトーン&マナー（トンマナ）を8名のエージェントチームで設計するスキル。
  ブランドアーキタイプ・パーソナリティ定義から、カラー・タイポグラフィ・ビジュアルスタイル・
  トーン・オブ・ボイスまでを一貫設計し、Pencil (.pen) + Markdown で成果物を出力する。
  「デザインテンション」（矛盾ペア）を核に、AIっぽくない独自のブランドアイデンティティを生成する。
---

# App Tone & Manner Design Skill

version: 1.0.0

8名のエージェントがディスカッション形式でアプリのトーン&マナーを設計するスキル。
ブランド基盤（Phase 1）→ ビジュアル言語化（Phase 2）→ トーン・オブ・ボイス（Phase 3）の3フェーズで進行し、
各フェーズの Gate を identity-critic が運営する。

## ワークフロー概要

```
Step 1: ヒアリング（必須/任意の情報収集 + ペルソナ自動検索）
Step 2: チーム作成・エージェント起動
Step 3: ディスカッション型ラウンド進行
  Phase 1: ブランド基盤設計（並列） → Gate 1
  Phase 2: ビジュアル言語化（並列） → Gate 2
  Phase 3: トーン・オブ・ボイス → Gate 3（Devil's Advocate）
Step 4: ファイル書き込み検証
Step 5: Pencil 出力生成
Step 6: 統合レポート作成（TONE_MANNER_REPORT.md）
Step 7: ユーザーへの最終報告
Step 8: クリーンアップ（全エージェントシャットダウン）
```

---

## コンテキストファイル構成

```
.claude/app-tone-manner/{YYYY-MM-DD}_{project}/
├── context.md                      ← 全セッション引き継ぎファイル
├── TONE_MANNER_REPORT.md           ← 最終成果物（後続スキルが最初に読むファイル）
├── round-{N}/
│   ├── context.md                  ← このラウンドの目的・制約
│   ├── log.md                      ← 議事録（リーダーが記録）
│   ├── brand-foundation.md         ← ブランド基盤・パーソナリティ定義
│   ├── competitor-analysis.md      ← 競合トンマナ調査結果
│   ├── user-psychology.md          ← ユーザー心理分析
│   ├── color-palette.md            ← カラーパレット設計
│   ├── typography.md               ← タイポグラフィ設計
│   ├── visual-style.md             ← ビジュアルスタイル設計
│   ├── tone-of-voice.md            ← コミュニケーションスタイル
│   └── critique.md                 ← identity-critic の Gate 結果
└── references/
    ├── competitive-analysis.md     ← 競合調査（引き継ぎ用）
    └── inspiration-board.md        ← 参考事例整理
```

---

## Step 1: ヒアリング

### 必須情報（欠けたら質問）

| 項目 | 内容 |
|------|------|
| アプリ/サービス名 | プロダクトの名前 |
| アプリ概要 | 何をするアプリか（1〜3文） |
| ターゲットユーザー | 年齢層・性別・ライフスタイル・利用シーン |
| 競合/参考サービス | 3〜5個（URL または名前） |

### 任意情報（あれば精度向上）

| 項目 | 内容 |
|------|------|
| 好みのテイスト | 「ミニマル」「温かみのある」「高級感」等の方向性 |
| NGな色・スタイル | 絶対に避けたい要素 |
| 既存ブランドガイドライン | リブランディングの場合 |
| 調査設定 | 「途中確認あり（推奨）」「一気に最後まで」「重要な発見があれば都度」 |

### ペルソナの自動検索

ヒアリング完了後、以下のパスを Glob で検索してペルソナデータを取得する:

```
docs/personas/*.md
.claude/persona-creation/*/personas/*.md
```

見つかった場合: 全エージェントの起動プロンプトにペルソナ情報を組み込む。
見つからない場合: 「persona-creation スキルで先にペルソナを作成することを推奨しますが、ヒアリング情報で代替可能です」とユーザーに案内。

### product-context.md の自動読み込み

以下のパスを Glob で検索し、見つかれば読み込んでコンテキストに追加する:

```
.claude/product-discovery/*/product-context.md
```

### 初期化

ヒアリング完了後、初期化スクリプトを実行してプロジェクトディレクトリを作成:

```bash
bash /Users/babashunsuke/.claude/skills/app-tone-manner/scripts/init.sh "{project-name}"
```

---

## Step 2: チーム作成とエージェント起動

### エージェント構成（8名）

| name | 役割 | Phase | 起動タイミング |
|------|------|-------|------------|
| brand-strategist | アーキタイプ・パーソナリティ・デザイン原則 | Phase 1 | 初回起動 |
| competitor-analyst | 競合トンマナ調査・差別化機会 | Phase 1 | 初回起動 |
| user-psychologist | ペルソナ心理・知覚・感情分析 | Phase 1 | 初回起動 |
| color-expert | カラーパレット設計 | Phase 2 | Gate 1 PASS 後 |
| typography-director | フォント選定・ペアリング | Phase 2 | Gate 1 PASS 後 |
| visual-style-architect | 形状・影・スペーシング・モーション・アイコン | Phase 2 | Gate 1 PASS 後 |
| tone-of-voice-writer | UIコピー・コミュニケーションスタイル | Phase 3 | Gate 2 PASS 後 |
| identity-critic | ライブモデレーター + Gate運営 + Devil's Advocate | 全Phase | 初回起動 |

### タスク作成（Phase 1）

Phase 1 開始時に以下のタスクを作成:

```
Task A: brand-strategist — ブランド基盤設計（アーキタイプ、パーソナリティスコア、デザイン原則、デザインテンション）
Task B: competitor-analyst — 競合トンマナ調査（ビジュアル監査、差別化機会）
Task C: user-psychologist — ユーザー心理分析（ペルソナ×デザイン変数マッピング）
Task D: identity-critic — Phase 1 ライブモデレーション（矛盾検出、一貫性チェック）
```

Task A, B, C は並列起動。Task D は A, B, C と並走（blockなし）。

### エージェント起動プロンプトに含める情報

各エージェントの起動時に以下を送信する:

1. アプリ概要・ターゲット情報
2. ペルソナデータ（見つかった場合）
3. product-context.md の内容（見つかった場合）
4. 好みのテイスト・NG 要素（ある場合）
5. ベースディレクトリの絶対パス
6. ラウンド番号（round-1, round-2, ...）
7. 前ラウンドの context.md（round-2 以降）

**重要**: Phase 2 のタスクは Gate 1 PASS 後に作成する。Phase 3 のタスクは Gate 2 PASS 後に作成する。初回に全タスクを作成してはならない。

---

## Step 3: ディスカッション型ラウンド進行

### ディスカッションプロトコル

全エージェントが共通で使用するディスカッションの進め方。

#### 3ステップサイクル

```
1. 独立作業: 各エージェントが自分の専門領域で調査・分析を実施
2. 共有 + [CHALLENGE]/[DEFEND]: 結果を SendMessage で共有し、他エージェントが批判
3. 修正/追加調査: 批判を受けて修正、必要なら追加調査（最大2回）
```

#### [CHALLENGE] テンプレート

```
[CHALLENGE] → {対象エージェント名}
主張: {相手の主張を要約}
問題: {矛盾・疑問の具体的内容}
根拠: {自分のデータ/ロジック/ブランド原則}
提案: {修正案 or 追加調査すべき点}
```

#### [DEFEND] テンプレート

```
[DEFEND] ← {批判元エージェント名}
批判: {受けた批判を要約}
反論: {なぜ自分の提案が妥当か}
根拠: {データ/理論/ユーザー心理}
妥協案: {部分的に受け入れる場合の修正案}
```

#### 収束条件

- identity-critic が収束を判定する
- **収束の定義**: 2巡連続で新しい [CHALLENGE] が発生しない状態
- **再調査の制限**: 同一論点について最大2回まで
- **強制終了**: 3巡を超えても収束しない場合、identity-critic が論点を整理し多数決で決定

### Phase 1: ブランド基盤設計ディスカッション

**参加者**: brand-strategist, competitor-analyst, user-psychologist, identity-critic

**並列作業**:
- brand-strategist: ブランドアーキタイプ選定、Aaker パーソナリティスコア策定、デザイン原則提案、**デザインテンション**（矛盾ペア）の策定
- competitor-analyst: 競合3〜5社のビジュアル監査（色・フォント・レイアウト・トーン）、差別化機会の特定
- user-psychologist: ペルソナ属性→デザイン変数マッピング、年齢層・文化コンテキストの影響分析

**ディスカッションの焦点**:
- 「ブランド訴求」vs「ユーザー心理」vs「競合差別化」の3軸で議論
- brand-strategist のデザインテンションが user-psychologist のペルソナ分析と整合するか
- competitor-analyst の差別化提案がデザインテンションを支持するか

**必須出力**:
- ブランドアーキタイプ（主 + 副）
- Aaker パーソナリティスコア（5次元×10段階）
- デザイン原則（3〜5個、「形容詞: 実践での意味」形式）
- **デザインテンション**（例: "minimal but warm"）— これがPhase 2 の全判断の指針になる
- 競合ポジショニングマップ
- ペルソナ×デザイン変数の推奨マッピング

**成果物ファイル**:
- `round-{N}/brand-foundation.md` ← brand-strategist が執筆
- `round-{N}/competitor-analysis.md` ← competitor-analyst が執筆
- `round-{N}/user-psychology.md` ← user-psychologist が執筆

### Gate 1: 全員参加の合意形成

**運営者**: identity-critic

**PASS 基準**:
1. デザインテンションが明確に定義されている
2. 3エージェント全員がデザインテンションに合意している
3. アーキタイプとパーソナリティスコアに矛盾がない
4. 競合との差別化ポイントが具体的に特定されている
5. ペルソナ属性とデザイン方向性が整合している

**FAIL の場合**: 不一致の論点を特定し、追加ディスカッション（最大2巡）。それでも FAIL なら identity-critic が調停案を提示し、多数決で決定。

**Gate 1 中間レポート**: identity-critic が `round-{N}/critique.md` に以下を記録:
- PASS/FAIL の判定結果と根拠
- 各エージェントの提案の要約
- 合意事項と残存論点
- Phase 2 への引き継ぎ事項

**ユーザーチェックポイント（設定による）**:
調査設定が「途中確認あり」の場合、Gate 1 結果をユーザーに報告し、方向性の合意を得る。
「一気に最後まで」の場合はスキップ。

### Phase 2: ビジュアル言語化ディスカッション

**前提**: Gate 1 PASS が必須。Phase 1 の成果物を全エージェントに共有。

**タスク作成（Gate 1 PASS 後）**:
```
Task E: color-expert — カラーパレット設計（プライマリ/セカンダリ/アクセント/ニュートラル/セマンティック + ダークモード）
Task F: typography-director — タイポグラフィ設計（ディスプレイ/ボディ/日本語フォント + スケール）
Task G: visual-style-architect — ビジュアルスタイル設計（形状/影/スペーシング/アイコン/モーション/イラスト）
Task H: identity-critic — Phase 2 ライブモデレーション
```

**並列作業**:
- color-expert: デザインテンションに基づくカラーパレット設計、60-30-10 比率、WCAG アクセシビリティ確認
- typography-director: デザインテンションに基づくフォント選定、ペアリング、スケール設計
- visual-style-architect: UIスタイル、角丸、影、スペーシング、アイコン、モーション、イラストスタイル

**ディスカッションの焦点**:
- 3つのビジュアル要素（色・文字・形）がデザインテンションを一貫して体現しているか
- 例: デザインテンション "minimal but warm" なら、色は暖色系、フォントはクリーン、角丸は大きめ — 全てが同じ方向を向いているか
- 「AIっぽいデザイン」アンチパターンに該当していないか（→ references/anti-patterns.md 参照）

**必須出力**:
- 完全なカラーパレット（Primary, Secondary, Accent, Neutral, Semantic, Surface, On-colors）
- ダークモードパレット
- フォント選定（Display, Body, JP）とペアリング理由
- タイポグラフィスケール
- 角丸スタイル、影スタイル、スペーシング基本単位
- アイコンスタイル、イラストスタイル
- モーション/アニメーションスタイル

**成果物ファイル**:
- `round-{N}/color-palette.md` ← color-expert が執筆
- `round-{N}/typography.md` ← typography-director が執筆
- `round-{N}/visual-style.md` ← visual-style-architect が執筆

### Gate 2: ビジュアル一貫性確認

**運営者**: identity-critic

**PASS 基準**:
1. 全ビジュアル要素がデザインテンションを一貫して体現している
2. カラーパレットが WCAG AA 以上のコントラスト比を満たしている
3. フォントペアリングが適切なコントラストを持っている
4. ビジュアルスタイルが競合と明確に差別化されている
5. 「AIっぽいデザイン」アンチパターンに該当していない

**ユーザーチェックポイント（設定による）**:
調査設定が「途中確認あり」の場合、ビジュアル方向性をユーザーに報告し合意を得る。

### Phase 3: トーン・オブ・ボイス

**前提**: Gate 2 PASS が必須。Phase 1 + Phase 2 の成果物を tone-of-voice-writer に共有。

**タスク作成（Gate 2 PASS 後）**:
```
Task I: tone-of-voice-writer — トーン・オブ・ボイス設計
Task J: identity-critic — Gate 3 Devil's Advocate + 最終検証
```

**tone-of-voice-writer の作業**:
- ブランドボイスマトリクス（Formality / Humor / Enthusiasm / Respect / Complexity）のスコア設定
- UIコピーの具体例（ボタンラベル、エラーメッセージ、オンボーディング、成功メッセージ等）
- コミュニケーションスタイルガイド（やること/やらないこと）
- ブランドパーソナリティを言葉で体現する具体的なルール

**成果物ファイル**:
- `round-{N}/tone-of-voice.md` ← tone-of-voice-writer が執筆

### Gate 3: Devil's Advocate + 最終検証

**運営者**: identity-critic

**Devil's Advocate ラウンド**:
1. identity-critic が全エージェントに「このトンマナが機能しない理由を3つ挙げよ」と要求
2. 各エージェントが自分の専門領域から批判を提出
3. 批判を Fatal / Major / Minor の3段階で分類
4. Fatal 指摘は全て解消が必須。Major は対応策を明記。Minor は記録のみ可。

**独立検証**: identity-critic が WebSearch で以下を独自調査:
- デザインテンションと類似のブランド事例が既に存在しないか
- 選定したフォント・カラーが最新のトレンドと極端にズレていないか（ただしトレンド追従が目的ではない）
- 競合の最新ビジュアルアイデンティティに変更がないか

**PASS 基準**:
1. Devil's Advocate の Fatal 指摘が全て解消されている
2. 独立検証で致命的な問題が見つかっていない
3. Phase 1 〜 Phase 3 の全成果物が一貫している
4. 42個のデザイン変数が全て決定されている

---

## フィードバックプロトコル（全エージェント共通ルール）

1. **ACK返信は不要**: 「了解しました」「確認しました」等の単純な確認メッセージは送信しない
2. **返信する条件**: フィードバック、質問、修正結果、[CHALLENGE]、[DEFEND] がある場合のみ
3. **2人以上から反応があれば次へ進む**: 全員の返信を待たない
4. **ファイル書き込みは自分の担当ファイルのみ**: 他エージェントのファイルは編集しない
5. **絶対パスのみ使用**: Write/Edit ツールでは必ず絶対パスを使用する
6. **デザインテンションへの言及**: 提案には必ず「デザインテンション "{tension}" との整合性」を含める

---

## 再調査プロトコル

ディスカッション中に情報不足が判明した場合の手順:

1. 調査が必要なエージェントが identity-critic に再調査を申請
2. identity-critic が再調査の必要性を判断（必要なら承認、不要なら却下理由を説明）
3. 承認された場合、該当エージェントが WebSearch で追加調査（最大2回まで）
4. 追加情報を全エージェントに共有し、ディスカッション再開
5. 再調査2回目でも収束しない場合、現状の情報で最善の判断を行う

---

## Step 4: ファイル書き込み検証

Gate 3 PASS 後、最終レポート作成前に全ファイルの存在と内容を確認する。

### 確認対象ファイル

```
round-{N}/brand-foundation.md
round-{N}/competitor-analysis.md
round-{N}/user-psychology.md
round-{N}/color-palette.md
round-{N}/typography.md
round-{N}/visual-style.md
round-{N}/tone-of-voice.md
round-{N}/critique.md
```

### 確認手順

1. Glob でファイルの存在を確認
2. Read で各ファイルの内容を確認（空でないこと）
3. 欠けているファイルがあれば、担当エージェントに書き込みを依頼
4. エージェントが既にシャットダウン済みの場合、リーダーがフォールバック書き込みを実施

---

## Step 5: Pencil 出力生成

Phase 2 の成果物を Pencil (.pen) ファイルとして出力する。

### 出力内容

1. **カラーパレットボード**: Primary, Secondary, Accent, Neutral, Semantic の全色を視覚化
2. **フォント見本**: Display/Body/JP フォントのサンプルテキスト
3. **スタイルガイドサンプル**: ボタン、カード、入力フィールド等の基本コンポーネントスタイル

### 手順

1. リーダーが Pencil MCP ツールを使用して .pen ファイルを作成
2. get_guidelines で design-system のガイドラインを取得
3. get_style_guide_tags → get_style_guide でスタイルガイドを参照
4. batch_design で以下を作成:
   - カラースウォッチ（各色の hex 値ラベル付き）
   - タイポグラフィスケール見本
   - 基本UIコンポーネントのスタイルサンプル
5. get_screenshot で出力を視覚的に検証

---

## Step 6: 統合レポート作成

全フェーズの成果物を統合し、`TONE_MANNER_REPORT.md` を作成する。

### レポート構成

`references/report-template.md` のテンプレートに従って作成する。主要セクション:

1. **Executive Summary** — ブランドの一言定義 + デザインテンション
2. **ブランドパーソナリティ** — アーキタイプ、パーソナリティスコア、デザイン原則
3. **デザインテンション** — 矛盾ペアの定義と、それが全デザイン判断にどう影響するか
4. **カラーパレット** — Primary/Secondary/Accent/Neutral/Semantic + 用途 + ダークモード
5. **タイポグラフィ** — Display/Body/JP フォント + スケール + ペアリング理由
6. **ビジュアルスタイル** — 形状/影/スペーシング/アイコン/モーション/イラスト
7. **トーン・オブ・ボイス** — ボイスマトリクス + UIコピー例 + やること/やらないこと
8. **42 デザイン変数の全値** — 完全な変数テーブル
9. **競合差別化の根拠** — なぜこのトンマナが競合と異なるか
10. **Devil's Advocate 結果** — このトンマナが機能しない条件と対策
11. **ペルソナとの整合性** — 各ペルソナに対するデザインの適合度
12. **後続スキルへの引き継ぎ** — logo-design, ui-review, feature-discussion への申し送り

### 品質要件

- 全ての判断に根拠・出典を含む
- デザインテンションが全セクションで一貫している
- 42個のデザイン変数が全て値を持っている
- アンチパターンに該当する要素がない

---

## Step 7: ユーザーへの最終報告

レポート完成後、以下をユーザーに報告:

1. TONE_MANNER_REPORT.md の保存パス
2. Pencil ファイルの保存パス（生成した場合）
3. デザインテンションの要約
4. カラーパレットの主要色（hex値付き）
5. 選定フォント名
6. 後続スキルの推奨実行順序

---

## Step 8: クリーンアップ

1. 全エージェントに `shutdown_request` を送信
2. 全エージェントのシャットダウン完了を確認
3. context.md にセッション結果を追記（次回セッション用）

---

## 他スキルとの連携

### 入力として受け取るスキル

| スキル | 受け取る情報 | 検索パス |
|--------|-------------|---------|
| persona-creation | ペルソナデータ | `docs/personas/*.md`, `.claude/persona-creation/*/personas/*.md` |
| market-research | 市場データ・競合情報 | `.claude/market-research/*/MARKET_REPORT.md` |
| app-naming | アプリ名の方向性 | `.claude/app-naming/*/context.md` |
| product-discovery | プロダクトコンテキスト | `.claude/product-discovery/*/product-context.md` |

### 出力を渡すスキル

| スキル | 渡す情報 | 参照ファイル |
|--------|---------|-------------|
| logo-design | ブランドカラー・パーソナリティ・スタイル方針 | TONE_MANNER_REPORT.md |
| ui-review | トンマナガイドライン・ビジュアル評価基準 | TONE_MANNER_REPORT.md |
| feature-discussion | UIコンポーネントのトンマナ準拠チェック | TONE_MANNER_REPORT.md |
| aso-optimize | ストア説明文のトーン・オブ・ボイス | TONE_MANNER_REPORT.md §7 |
| frontend-design | デザインシステムの基盤 | TONE_MANNER_REPORT.md §4-6 |

---

## デザイン変数一覧（42変数）

全てのデザイン判断を構造化する42個の変数。各エージェントが担当する変数を以下に示す。
完全な定義は `references/design-variables.md` を参照。

### brand-strategist 担当（変数 1-7, 41）

| # | 変数名 | 説明 |
|---|--------|------|
| 1 | `brand_archetype` | 主要ユングアーキタイプ |
| 2 | `brand_archetype_secondary` | 副次アーキタイプ |
| 3 | `personality_sincerity` | Aaker 誠実性スコア (1-10) |
| 4 | `personality_excitement` | Aaker 刺激性スコア (1-10) |
| 5 | `personality_competence` | Aaker 能力スコア (1-10) |
| 6 | `personality_sophistication` | Aaker 洗練性スコア (1-10) |
| 7 | `personality_ruggedness` | Aaker 頑健性スコア (1-10) |
| 41 | `design_tension` | デザインテンション（矛盾ペア） |

### competitor-analyst 担当（補助的に貢献）

直接の変数担当はないが、全変数の判断に競合差別化の視点を提供する。

### user-psychologist 担当（変数 35, 38, 39, 40）

| # | 変数名 | 説明 |
|---|--------|------|
| 35 | `formality_level` | 全体のフォーマリティ (1-10) |
| 38 | `target_age_primary` | 主要ターゲット年齢層 |
| 39 | `cultural_context` | 主要文化コンテキスト |
| 40 | `accessibility_level` | アクセシビリティ基準 |

### color-expert 担当（変数 8-15）

| # | 変数名 | 説明 |
|---|--------|------|
| 8 | `color_primary` | メインブランドカラー |
| 9 | `color_secondary` | サポートカラー |
| 10 | `color_accent` | アクセントカラー |
| 11 | `color_harmony_type` | 色彩調和タイプ |
| 12 | `color_warmth` | パレットの暖かさ (1-10) |
| 13 | `color_saturation_level` | 彩度レベル |
| 14 | `neutral_tone` | ニュートラルトーン |
| 15 | `dark_mode_strategy` | ダークモード戦略 |

### typography-director 担当（変数 16-22）

| # | 変数名 | 説明 |
|---|--------|------|
| 16 | `font_display` | 見出しフォント |
| 17 | `font_body` | 本文フォント |
| 18 | `font_display_category` | 見出しフォント分類 |
| 19 | `font_body_category` | 本文フォント分類 |
| 20 | `font_jp_category` | 日本語フォントカテゴリ |
| 21 | `type_scale_ratio` | タイポグラフィスケール比 |
| 22 | `type_base_size` | ベースフォントサイズ |

### visual-style-architect 担当（変数 23-34, 42）

| # | 変数名 | 説明 |
|---|--------|------|
| 23 | `spacing_base_unit` | グリッド基本単位 |
| 24 | `spacing_density` | スペーシング密度 |
| 25 | `corner_radius_style` | 角丸スタイル |
| 26 | `shadow_style` | 影/エレベーションスタイル |
| 27 | `elevation_levels` | エレベーション段階数 |
| 28 | `icon_style` | アイコンスタイル |
| 29 | `icon_stroke_width` | アイコン線幅 |
| 30 | `animation_style` | モーションスタイル |
| 31 | `animation_duration_base` | ベーストランジション時間 |
| 32 | `illustration_style` | イラストスタイル |
| 33 | `visual_style` | 全体UIスタイル |
| 34 | `information_density` | 情報密度 |
| 42 | `photography_style` | 写真スタイル |

### tone-of-voice-writer 担当（変数 36, 37）

| # | 変数名 | 説明 |
|---|--------|------|
| 36 | `voice_humor` | ユーモアレベル (1-10) |
| 37 | `voice_enthusiasm` | エネルギーレベル (1-10) |

---

## AIっぽいデザインのアンチパターンリスト

完全なリストは `references/anti-patterns.md` を参照。以下は概要。

### 禁止フォント（ジェネリック AI デザインの象徴）
- Inter, Roboto, Arial, system-ui のみの組み合わせ
- Space Grotesk の過度な使用

### 禁止カラーパターン
- 紫→青のグラデーション + 白背景（AI スタートアップの典型）
- 無難な青一色（企業デフォルト）
- 等分配されたカラーパレット（コントラスト不足）

### 禁止レイアウトパターン
- Hero + Card Grid + CTA の定型3セクション構成
- 左テキスト + 右イメージの繰り返し
- 等間隔の余白配置（リズム不在）

### 差別化のチェックリスト
- [ ] デザインテンションが全判断に反映されている
- [ ] フォントに「キャラクター」がある（ジェネリックでない）
- [ ] 背景色が「白一択」でない
- [ ] カラーに明確なドミナント + シャープなアクセントがある
- [ ] 「この1つだけ覚えてもらいたい」ビジュアル要素が定義されている
