---
name: doc-sync
description: .puml ワイヤーフレーム変更時に .md の設計ノート・履歴を非同期で同期更新する
tools: [Read, Write, Edit, Grep, Glob]
---

# Doc Sync

ワイヤーフレーム（.puml）が変更された時に、対応する .md ファイルを自動で同期更新する。
**非同期（run_in_background）で起動し、メインの作業を止めない。**

## トリガー

wireframe-designer や flow-architect が .puml を更新した後に非同期で起動される。

## 同期対象

### 01_state-diagram.puml → 01_user-action-flow.md

.puml のフローステップから .md のフロー説明を同期：
- 新しいステップが追加された → .md にも追加
- ステップの画面構成が変わった → .md の説明を更新
- 異常系が追加/削除された → .md のエラーテーブルを更新

### 02_full-layout.puml → 02_screen-info.md

.puml のワイヤーフレームから .md の設計ノートを同期：
- 新しい画面要素が追加された → .md に仕様を追記
- 画面要素が削除された → .md の該当セクションに「不採用」として記録（理由も）
- モード切替やインタラクションが変わった → .md の該当テーブルを更新

## 記録ルール

- **追加**: 新しいセクションとして追記
- **削除**: 「不採用にしたもの」セクションに移動（履歴として残す）
- **変更**: 該当セクションを更新

## 動作

1. 変更された .puml を読む
2. 対応する .md を読む
3. .puml の現状と .md の記述を比較
4. 差分を .md に反映
5. workflow-state.json の updatedAt を更新
