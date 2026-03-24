# ForEach + 動的配列の削除クラッシュ

## 問題

SwiftUI の `ForEach` で配列を表示し、ボタンで要素を削除すると `index out of range` でクラッシュする。

### 原因

1. **`ForEach(array.indices, id: \.self)`** — インデックスが ID として使われるため、要素を削除するとインデックスがずれて、SwiftUI の差分更新で古いインデックスを参照してクラッシュ
2. **`ForEach($array)` + 削除ボタン内でのインデックス参照** — ボタンのクロージャがキャプチャした `item` や `index` が、削除実行時には古い状態を指している可能性がある
3. **同一フレーム内でのフォーカス移動** — 削除と `@FocusState` の更新を同一フレームで行うと、SwiftUI の View 更新と競合する

## NG パターン

### パターン 1: indices ベースの ForEach

```swift
// ❌ CRASH — 削除でインデックスがずれる
ForEach(items.indices, id: \.self) { index in
    HStack {
        TextField("", text: $items[index])
        Button { items.remove(at: index) } label: { ... }
    }
}
```

### パターン 2: 削除前のインデックスでフォーカス先を参照

```swift
// ❌ CRASH — 削除前の index で items[index-1] にアクセス→配列が変わった後に不正参照
Button {
    let prevIndex = max(0, index - 1)
    let prevID = viewModel.items[prevIndex].id
    viewModel.items.removeAll { $0.id == item.id }
    focusedID = prevID  // ← 同一フレームで SwiftUI と競合
} label: { ... }
```

## OK パターン

### 安全な削除 + フォーカス移動

```swift
struct Item: Identifiable, Equatable {
    let id = UUID()
    var text: String
}

@FocusState private var focusedID: UUID?

ForEach($viewModel.items) { $item in
    HStack {
        TextField("", text: $item.text)
            .focused($focusedID, equals: item.id)

        if viewModel.items.count > 1 {
            Button {
                // 1. 削除前にフォーカス先を算出
                let targetID: UUID? = {
                    guard viewModel.items.count > 1,
                          let idx = viewModel.items.firstIndex(where: { $0.id == item.id }) else { return nil }
                    return idx > 0 ? viewModel.items[idx - 1].id : viewModel.items[idx + 1].id
                }()
                // 2. 削除実行
                viewModel.removeItem(id: item.id)
                // 3. フォーカス移動は次フレームで
                if let targetID {
                    DispatchQueue.main.async { focusedID = targetID }
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
        }
    }
}
```

## チェックリスト

- [ ] 配列要素は `Identifiable` プロトコルに準拠しているか
- [ ] `ForEach` は `id: \.self` ではなく `Identifiable` の `id` を使っているか
- [ ] 削除は `remove(at:)` ではなく `removeAll { $0.id == id }` で ID ベースか
- [ ] 削除後のフォーカス移動は `DispatchQueue.main.async` で遅延させているか
- [ ] 削除前にフォーカス先 ID を算出し、削除後にインデックスアクセスしていないか
