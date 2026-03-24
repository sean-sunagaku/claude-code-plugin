# @FocusState の所有権と .sheet の制約

## 問題

`@FocusState` を親 View で宣言し、`.sheet` 内の TextField で `.focused()` に渡しても、フォーカスが一切当たらない。

## 原因

`.sheet` / `.fullScreenCover` は **独立したビュー階層** を作成する。`@FocusState` は宣言された View のビュー階層内でしかフォーカスを制御できないため、親 View の `@FocusState` は sheet 内の TextField に到達しない。

### 試しても動かないパターン

| パターン | 結果 |
|---|---|
| 親の `@FocusState` を sheet 内で直接使用 | NG |
| `FocusState<T>.Binding` を関数パラメータで渡す | NG |
| `FocusState<T>.Binding` を子 View の `init` で渡す | NG |
| `DispatchQueue.main.async` で遅延させる | NG（根本原因が違う）|
| `DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)` | NG |

## 解決策: 子 View struct に切り出す

sheet のコンテンツとなる View struct を作成し、**その View 自体が `@FocusState` を所有する**。

```swift
// ✅ sheet 内のビューが @FocusState を直接所有
struct MemoItemListView: View {
    @Binding var items: [MemoItem]
    @FocusState private var focusedID: UUID?  // ← ここで宣言

    var body: some View {
        VStack {
            ForEach($items) { $item in
                TextField("", text: $item.text, axis: .vertical)
                    .focused($focusedID, equals: item.id)
                    .onChange(of: item.text) { _, newValue in
                        guard newValue.contains("\n") else { return }
                        item.text = newValue.replacingOccurrences(of: "\n", with: "")
                        // ... フォーカス移動ロジック
                        focusedID = nextItemID  // ← 正常に動く
                    }
            }
        }
    }
}

// 親は Binding だけ渡す
struct ParentView: View {
    @State private var items: [MemoItem] = [MemoItem(text: "")]

    var body: some View {
        Button("Edit") { showSheet = true }
        .sheet(isPresented: $showSheet) {
            MemoItemListView(items: $items)
        }
    }
}
```

## キーボード維持のベストプラクティス

### 削除ボタン: Button → onTapGesture

`Button` タップは SwiftUI が自動的に first responder を resign するため、キーボードが一瞬閉じる。

```swift
// ❌ Button → キーボードが一瞬閉じる
Button {
    deleteItem(id: item.id)
} label: {
    Image(systemName: "xmark.circle.fill")
}

// ✅ onTapGesture → キーボードが閉じない
Image(systemName: "xmark.circle.fill")
    .contentShape(Rectangle())
    .onTapGesture {
        deleteItem(id: item.id)
    }
```

### 次のフィールドへ移動: onSubmit → onChange 改行検知

`.onSubmit` も resign を発生させる。`axis: .vertical` の TextField で改行を検知する方式なら resign が発生しない。

```swift
// ❌ onSubmit → キーボードが一瞬閉じてから次にフォーカス
TextField("", text: $item.text)
    .onSubmit {
        focusedID = nextID  // キーボードが一瞬チラつく
    }

// ✅ axis: .vertical + onChange → キーボードが閉じない
TextField("", text: $item.text, axis: .vertical)
    .lineLimit(1 ... 1)
    .onChange(of: item.text) { _, newValue in
        guard newValue.contains("\n") else { return }
        item.text = newValue.replacingOccurrences(of: "\n", with: "")
        focusedID = nextID  // スムーズに移動
    }
```

## チェックリスト

- [ ] `@FocusState` は `.focused()` を使う TextField と同じ View struct 内で宣言されているか
- [ ] `.sheet` 内で使うなら、専用の子 View struct に切り出しているか
- [ ] `FocusState.Binding` を関数パラメータや init で渡していないか
- [ ] 削除ボタンは `Button` ではなく `onTapGesture` を使っているか
- [ ] 次フィールド移動は `.onSubmit` ではなく `onChange` + 改行検知を使っているか
