---
name: swiftui-ui-mockup
description: Design and build runnable iOS UI mockups in SwiftUI, including UI direction, multiple visual or interaction variants, realistic sample data, state switching, Xcode Previews, and Simulator validation. Use when the user wants to explore what an iOS screen should look like, compare SwiftUI UI ideas, create a clickable native prototype, validate an app flow before production implementation, or asks for a SwiftUI mock, iOS mockup, native prototype, 画面モック, UI案, SwiftUIで動くモック, or 実際に触れるiOSモック.
---

# SwiftUI UI Mockup

SwiftUIで「どんなUIにするか」の検討と、実際に操作できるネイティブモックの実装・表示確認までを行う。本番機能の完成ではなく、短い反復でUI判断を確定することを目的にする。

## 守備範囲

- UI構成、情報階層、導線、文言、主要操作を設計する。
- 迷いがある箇所は2〜3案を同じ条件で比較できるようにする。
- 実在感のあるサンプルデータと主要状態を用意する。
- Xcode Previewで静的な見た目を、Simulatorで操作・遷移・スクロールを確認する。
- 採用案と未決事項を短く残す。

認証、ネットワーク、永続化、分析、課金、通知配信などの本番基盤は実装しない。UI確認に必要な場合だけ、メモリ内のスタブで再現する。

## ワークフロー

### 1. プロジェクトと依頼を読む

質問する前に、既存の一次情報を確認する。

- `.xcodeproj` / `.xcworkspace`、scheme、deployment target
- 対象画面、共通コンポーネント、テーマ、Asset Catalog、フォント
- プロダクト資料、既存スクリーンショット、類似画面
- プロジェクト固有の検証手順と `AGENTS.md` / `CLAUDE.md`

情報が足りなくても安全な仮説で最初のモックを作れる場合は止まらない。プロダクト方向が大きく分岐する一点だけを質問し、それ以外は推奨案を明示して進める。

### 2. UIブリーフを決める

実装前に次を3〜8行でまとめる。

- この画面でユーザーが達成すること
- 最重要情報と主要アクション
- ナビゲーションまたは画面遷移
- 見た目の方向性
- 比較するUI案
- 検証する主要状態

UIの決め方は [references/ui-design.md](references/ui-design.md) を読む。

### 3. モックを本番コードから分離する

既存プロジェクトでは、そのプロジェクトの慣習を優先する。慣習がなければ次を基準にする。

```text
<App>/
└── Mockups/
    └── <FeatureName>/
        ├── <FeatureName>MockupView.swift
        ├── <FeatureName>MockupData.swift
        └── <FeatureName>MockupGallery.swift
```

- 本番の永続ストアやAPIを直接呼ばない。
- モック専用モデルは対象フォルダ内に閉じる。
- 本番ターゲットへの混入を避けたい場合は、Preview専用コードまたは独立したMockup targetを使う。
- 既存画面を再利用するときはprotocolやinitializerで依存を注入し、実サービスを起動しない。

プロジェクトがない場合は、最小のiOS Appプロジェクトを `prototypes/<feature-slug>/` に作り、単一schemeで起動できる状態にする。雛形が必要なら [assets/MockupGalleryView.swift](assets/MockupGalleryView.swift) をコピーして具体化する。

カレントディレクトリにiOSプロジェクトがあっても、依頼されたモックが別プロダクトなら既存アプリへ追加しない。「プロジェクトがない場合」と同様に独立した `prototypes/<feature-slug>/` を使い、既存アプリのテーマ、bundle ID、データ、schemeを流用しない。

実装パターンは [references/implementation.md](references/implementation.md) を読む。

### 4. 比較可能なSwiftUIモックを実装する

最低限、次を満たす。

- `#Preview` から対象画面を直接開ける。
- 主要ボタン、選択、入力、追加・削除、sheet、遷移など、判断対象の操作が動く。
- 表示文言は具体的にし、「サンプル」「Lorem ipsum」だけで済ませない。
- SF Symbolsと標準SwiftUIを優先し、プロジェクトのデザインシステムがあれば合わせる。
- タップ領域は原則44pt以上にする。
- 固定サイズ前提にせず、長文、Dynamic Type、キーボード、Safe Area、スクロールを考慮する。

比較対象がある場合は、gallery画面で次を切り替えられるようにする。

- `Variant`: レイアウト・コンポーネント・操作方式の案
- `Scenario`: 通常、空、少量、多量、長文、エラー、無効状態など
- 必要に応じてLight/Dark、文字サイズ、端末幅

見た目だけを変える案と、操作モデルが異なる案を混同しない。比較軸は一度に1〜2個に絞る。

### 5. Previewで目視検証する

SwiftUI UI変更は、ビルド成功だけで完了にしない。

1. 対象 `#Preview` をレンダリングする。
2. スクリーンショットを目視する。
3. 余白、整列、文字切れ、重なり、Safe Area、ボタンの強弱を確認する。
4. 問題を修正し、同じPreviewを再レンダリングする。

利用可能ならXcode Preview / RenderPreviewを使う。使えなければSimulatorで同等画面を開き、スクリーンショットを撮る。

### 6. Simulatorで操作検証する

対象schemeをビルド・起動し、ユーザーが判断する一連の操作を最後まで実行する。

- タップ、スクロール、入力、戻る、sheetの開閉
- VariantとScenarioの切り替え
- 空状態や長文状態への遷移
- 小さい端末幅または対象プロジェクトの基準端末

詳細は [references/verification.md](references/verification.md) を読む。操作自動化が使えない場合は、起動・スクリーンショット・確認できなかった操作を明記する。

### 7. UI判断を渡す

完了報告は簡潔にする。

- 作成した画面と動く操作
- 比較した案
- 推奨案と理由
- Preview / Simulatorで確認した端末・状態
- 未確認事項
- 作成・変更したファイル

本番実装へ進む許可は自動的に含まれない。モック承認後に別タスクとして扱う。

## 完了条件

- SwiftUIコードがビルドできる。
- 対象画面のPreviewを実際に確認している。
- 判断対象の操作をSimulatorで最後まで確認している。
- 少なくとも通常状態と1つの境界状態を確認している。
- 比較を依頼された場合、同じgallery内で案を切り替えられる。
- 本番データや外部サービスを変更していない。
- 推奨案、確認済み範囲、未確認範囲が報告されている。
