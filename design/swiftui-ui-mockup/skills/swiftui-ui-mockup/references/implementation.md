# SwiftUIモック実装パターン

## モック状態を閉じ込める

UI確認に必要な状態はViewまたは小さな `@Observable` / `ObservableObject` に置く。永続化しない。

```swift
enum MockupVariant: String, CaseIterable, Identifiable {
    case cards = "カード"
    case timeline = "タイムライン"
    var id: Self { self }
}

enum MockupScenario: String, CaseIterable, Identifiable {
    case standard = "通常"
    case empty = "空"
    case longContent = "長文"
    var id: Self { self }
}
```

## Galleryを入口にする

Galleryは画面上部またはtoolbarの `Picker` でVariantとScenarioを切り替える。各案を別schemeに分けず、一回の起動で比較できるようにする。

```swift
struct FeatureMockupGallery: View {
    @State private var variant: MockupVariant = .cards
    @State private var scenario: MockupScenario = .standard

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu("モック設定") {
                            Picker("UI案", selection: $variant) {
                                ForEach(MockupVariant.allCases) { Text($0.rawValue).tag($0) }
                            }
                            Picker("状態", selection: $scenario) {
                                ForEach(MockupScenario.allCases) { Text($0.rawValue).tag($0) }
                            }
                        }
                    }
                }
        }
    }
}
```

## Previewを分ける

Gallery用Previewに加え、採用候補の主要状態を個別Previewにする。Preview名に案と状態を書く。

```swift
#Preview("Cards / Standard") {
    FeatureMockupView(variant: .cards, scenario: .standard)
}

#Preview("Cards / Empty") {
    FeatureMockupView(variant: .cards, scenario: .empty)
}
```

## 本番コンポーネントを再利用する

再利用するViewが実サービスに依存する場合、次の順で依存を小さくする。

1. 値とclosureをinitializerで渡す
2. 小さなprotocolを定義し、メモリ実装を渡す
3. Preview用environment valueを渡す

モックのためだけに本番アーキテクチャを大改修しない。

## 操作を実装する

見た目の判断に関係する操作だけを本物にする。

- 追加: メモリ配列へappend
- 削除: IDでremove
- 並べ替え: 配列をmove
- 入力: `@State` / `@Binding`
- 保存: sheetを閉じ、画面状態へ反映
- エラー: Scenario切替またはスタブの結果で表示

ネットワーク待機は短い `Task.sleep` で見た目だけ再現してよいが、実APIは呼ばない。

## アクセシビリティ

- アイコンのみのButtonへ `accessibilityLabel`
- 状態を示す要素へ `accessibilityValue`
- UIテストが必要ならモック専用の安定した `accessibilityIdentifier`
- `.buttonStyle(.plain)` 使用時は `contentShape` と44pt以上の領域を確保
