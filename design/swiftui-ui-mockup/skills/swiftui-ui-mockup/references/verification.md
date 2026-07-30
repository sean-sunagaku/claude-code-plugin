# Preview・Simulator検証

## 検証順序

1. 対象schemeとPreviewを特定する。
2. Xcode Preview / RenderPreviewで採用候補をレンダリングする。
3. スクリーンショットでレイアウトを確認する。
4. Simulatorへビルド・インストール・起動する。
5. 判断対象の操作を一連で実行する。
6. 境界状態へ切り替えて再確認する。

## Previewで見る項目

- 上下左右の余白
- タイトル、本文、補助文の視覚階層
- 文字切れ、意図しない折返し、重なり
- Safe Area、navigation bar、tab bar、keyboardとの干渉
- CTAの位置とスクロール時の挙動
- Light/Darkでのコントラスト

## Simulatorで見る項目

- 全タップ対象が反応する
- 戻る、閉じる、キャンセルが成立する
- sheetとkeyboardの表示・非表示
- 縦スクロールと独自gestureが競合しない
- 追加・編集・削除後に画面が破綻しない
- 空状態から復帰できる
- 小さい端末幅でも主要操作へ到達できる

## コマンドラインの代替

専用Xcodeツールが使えない場合は、プロジェクトに合う値へ置き換えて確認する。

```bash
xcodebuild \
  -project App.xcodeproj \
  -scheme App \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

起動後のスクリーンショット:

```bash
xcrun simctl io booted screenshot /tmp/swiftui-mockup.png
```

コマンドだけでPreviewの代替と断定しない。Previewをレンダリングできなかった場合は、その事実とSimulatorで代替した範囲を報告する。
