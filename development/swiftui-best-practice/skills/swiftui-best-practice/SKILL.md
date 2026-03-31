---
name: swiftui-best-practice
description: >
  SwiftUI のレイアウト落とし穴・ベストプラクティス・非推奨パターンのガイド。
  コード生成・修正時に既知のレイアウトバグを防ぎ、正しいパターンを適用する。
  Use when: SwiftUI のコードを書く・修正するとき。
  レイアウト崩れを修正するとき。safeAreaInset や ViewThatFits を使うとき。
  マルチデバイス対応するとき。
  Triggers: "SwiftUI", "layout", "safeAreaInset", "ViewThatFits",
  "GeometryReader", "レイアウト", "崩れ", "表示バグ", "iPhone SE",
  "ATT", "ATTrackingManager", "requestTrackingAuthorization", "AdMob", "広告"
---

# SwiftUI Best Practices

## Critical Rules

### Layout pitfalls to avoid

Always check [references/layout-pitfalls.md](references/layout-pitfalls.md) for known SwiftUI layout issues. Key ones:

- `.frame(width:height:)` + `.safeAreaInset` -> use `.frame(maxWidth:maxHeight:)` instead
- `ViewThatFits` + `.frame(maxWidth: .infinity)` -> remove the frame from items inside ViewThatFits
- Fixed `contentFooterClearance` must match custom bottom bar height
- `.clipShape` / `.cornerRadius` must come directly after `.background` — `.padding` を間に挟むと角丸が見た目に反映されない

### Button hit area with `.buttonStyle(.plain)`

`.buttonStyle(.plain)` はテキスト/アイコン部分だけがクリック可能になり、`.frame()` で確保した余白はタップに反応しない。必ず `.contentShape(Rectangle())` を併用する。

```swift
// ❌ BAD — frame の余白部分がクリックできない
Button { action() } label: {
    Text("ボタン")
        .frame(maxWidth: .infinity)
        .frame(height: 48)
}
.buttonStyle(.plain)
.background(Color.green, in: RoundedRectangle(cornerRadius: 10))

// ✅ GOOD — frame 全体がクリック可能
Button { action() } label: {
    Text("ボタン")
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .contentShape(Rectangle())  // ← これが必須
}
.buttonStyle(.plain)
.background(Color.green, in: RoundedRectangle(cornerRadius: 10))
```

最小タップサイズは **44pt** (Apple HIG 推奨)。小さいアイコンボタンでも `.frame(width: 44, height: 44).contentShape(Rectangle())` で包む。

**丸ボタンの場合は `.contentShape(Circle())`** を使う:

```swift
// ❌ BAD — 丸い背景の外側も含めて四角にタップ判定される or アイコンだけしか反応しない
Button { action() } label: {
    Image(systemName: "plus")
        .frame(width: 52, height: 52)
}
.buttonStyle(.plain)
.background(Color.gray, in: Circle())

// ✅ GOOD — 丸い背景全体がタップ可能
Button { action() } label: {
    Image(systemName: "plus")
        .frame(width: 52, height: 52)
        .contentShape(Circle())  // ← 丸ボタンはこちら
}
.buttonStyle(.plain)
.background(Color.gray, in: Circle())
```

**`.background()` は label の外に置く**: `.background(in: Shape)` を label 内に入れると `contentShape` とバッティングして押せない領域ができる。`.buttonStyle(.plain)` の直後に `.background()` を付ける。

### ForEach + 動的配列の削除クラッシュ

`ForEach(array.indices, id: \.self)` や `ForEach($array)` で配列を表示し、ボタンで要素を削除すると **index out of range でクラッシュ** する。SwiftUI の差分更新と配列インデックスのタイミング不整合が原因。

詳細は [references/foreach-mutation.md](references/foreach-mutation.md) を参照。

```swift
// ❌ BAD — 削除時にインデックスがずれてクラッシュ
ForEach(items.indices, id: \.self) { index in
    HStack {
        TextField("", text: $items[index])
        Button { items.remove(at: index) } label: { Image(systemName: "xmark") }
    }
}

// ❌ STILL BAD — Identifiable でも削除アクション内でキャプチャした item が古い
ForEach($viewModel.items) { $item in
    Button {
        let idx = viewModel.items.firstIndex(where: { $0.id == item.id }) ?? 0
        let prevID = viewModel.items[max(0, idx - 1)].id  // ← 削除前のインデックスで参照→クラッシュ
        viewModel.items.removeAll { $0.id == item.id }
        focusedID = prevID
    } label: { Image(systemName: "xmark") }
}

// ✅ GOOD — 削除前に次のフォーカス先を安全に算出し、DispatchQueue で遅延実行
ForEach($viewModel.items) { $item in
    Button {
        let targetID: UUID? = {
            guard viewModel.items.count > 1,
                  let idx = viewModel.items.firstIndex(where: { $0.id == item.id }) else { return nil }
            return idx > 0 ? viewModel.items[idx - 1].id : viewModel.items[idx + 1].id
        }()
        viewModel.removeItem(id: item.id)
        if let targetID {
            DispatchQueue.main.async { focusedID = targetID }
        }
    } label: { Image(systemName: "xmark") }
}
```

**要点:**
- 配列要素は必ず `Identifiable` にする（`id: \.self` は NG）
- 削除は ID ベースで行う（`removeAll { $0.id == id }`）
- 削除後のフォーカス移動は `DispatchQueue.main.async` で1フレーム遅延させる
- 削除前にフォーカス先 ID を算出し、削除後にインデックスを参照しない

### @FocusState の所有権と .sheet の制約

`@FocusState` は **宣言した View と同じビュー階層** のフォーカスしか制御できない。`.sheet` は独立したビュー階層を作るため、親 View の `@FocusState` を sheet 内で使っても動かない。

詳細は [references/focusstate-ownership.md](references/focusstate-ownership.md) を参照。

```swift
// ❌ BAD — 親の @FocusState を sheet 内で使う → フォーカスが当たらない
struct ParentView: View {
    @FocusState private var focusedID: UUID?
    @State private var items: [Item] = [...]

    var body: some View {
        Button("Show") { showSheet = true }
        .sheet(isPresented: $showSheet) {
            ForEach($items) { $item in
                TextField("", text: $item.text)
                    .focused($focusedID, equals: item.id) // ← 動かない
            }
        }
    }
}

// ✅ GOOD — sheet 内のビューが自身の @FocusState を持つ
struct ItemListView: View {
    @Binding var items: [Item]
    @FocusState private var focusedID: UUID?  // ← ここで宣言

    var body: some View {
        ForEach($items) { $item in
            TextField("", text: $item.text)
                .focused($focusedID, equals: item.id) // ← 正常に動く
        }
    }
}

// 親は ItemListView を sheet に渡すだけ
.sheet(isPresented: $showSheet) {
    ItemListView(items: $items)
}
```

**要点:**
- `@FocusState` は使用する TextField と同じ View struct 内で宣言する
- `.sheet` / `.fullScreenCover` 内で使うなら、専用の子 View struct に切り出す
- 関数パラメータとして `FocusState<T>.Binding` を渡しても動かない

### ATT (App Tracking Transparency) の呼び出しタイミング

`ATTrackingManager.requestTrackingAuthorization()` は `.onAppear` ではなく **`scenePhase == .active` のタイミング**で呼ぶ。`.onAppear` で呼ぶと iPadOS（MultiScene）でダイアログが表示されずリジェクトされる。

詳細は [references/att-scene-phase.md](references/att-scene-phase.md) を参照。

```swift
// ❌ BAD — .onAppear で ATT → iPadOS でダイアログが出ない
.onAppear {
    Task { await ATTrackingManager.requestTrackingAuthorization() }
}

// ✅ GOOD — scenePhase == .active で ATT
.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .active {
        Task { await AdService.shared.requestTrackingAndInitialize() }
    }
}
```

### Adaptive multi-device layout

See [references/adaptive-layout.md](references/adaptive-layout.md) for breakpoint patterns and responsive design best practices.

## Workflow

When writing or modifying SwiftUI layout code:

1. Check for `.frame(width:height:)` that may block `.safeAreaInset` or `.overlay` propagation
2. Never put `.frame(maxWidth: .infinity)` on items inside `ViewThatFits` — it defeats intrinsic sizing
3. When using `GeometryReader`, prefer `.frame(maxWidth:maxHeight:)` over fixed `.frame(width:height:)` for child views
4. Custom bottom bars with `.safeAreaInset(edge: .bottom)` require matching scroll content padding
5. Test on smallest target device (iPhone SE 667pt) to catch overflow early
6. Visual modifiers (`.background`, `.clipShape`, `.overlay`, `.shadow`) must be grouped together — `.padding` between `.background` and `.clipShape` breaks visible rounding
7. `.buttonStyle(.plain)` を使うときは、label 内の最外 `.frame()` の直後に `.contentShape(Rectangle())` を付ける — これがないとテキスト部分しかクリックできない
8. ボタン・タップ可能要素の最小サイズは 44pt（Apple HIG）— アイコンが小さくても frame + contentShape で 44x44 を確保する
9. データを表示する UI を作るときは CRUD + 並び替えの 5 操作を全てカバーしているか確認する — 特に「編集」「削除」「並び替え」は漏れやすい
10. 操作動詞チェック: UI 要素に対してユーザーがしたい操作を動詞で列挙し、全て実装されているか確認する
11. アフォーダンスチェック: 操作手段が初見ユーザーに発見可能か確認する — context menu やスワイプだけでは不十分、ボタンが見えている必要がある
12. `ForEach` で動的配列を表示するとき、要素は必ず `Identifiable` にする — `ForEach(array.indices, id: \.self)` + 要素削除は **確実にクラッシュ** する
13. 配列要素の削除後にフォーカス移動する場合は `DispatchQueue.main.async` で遅延させる — 同一フレーム内だと SwiftUI の差分更新と競合する
14. `@FocusState` は sheet 内で使うなら sheet のコンテンツ View 自体が所有すること — 親 View の `@FocusState` を sheet 越しに渡しても動かない
15. TextField 横の削除ボタンは `Button` ではなく `Image` + `.onTapGesture` を使う — `Button` タップはキーボードを一瞬閉じてしまう
16. `.onSubmit` もキーボードを一瞬閉じるため、連続フォーカス移動には `TextField(axis: .vertical)` + `onChange` で改行検知する方式を使う
17. `ATTrackingManager.requestTrackingAuthorization()` は `.onAppear` ではなく `scenePhase == .active` で呼ぶ — `.onAppear` では iPadOS でダイアログが表示されずリジェクトされる
18. AdMob 等の広告 SDK 初期化は ATT リクエスト完了後に行う — IDFA の取得状態が確定してからでないとパーソナライズ判定が正しくない

## Subagent: Hit Area Auditor

SwiftUI のボタンヒットエリア問題を自動検出するサブエージェント。
SwiftUI の View ファイルを作成・修正した後に起動して、漏れを防ぐ。

### 起動方法

```
Agent(
  subagent_type: "swiftui-best-practice:swiftui-hit-area-auditor",
  prompt: "以下のファイルを監査してください: {対象ファイルパス}"
)
```

### チェック内容

| ルール | 検出内容 |
|--------|---------|
| Rule 1 | `.buttonStyle(.plain)` の label 内に `.contentShape()` がない |
| Rule 2 | `.background()` が label 内にある（label 外に置くべき） |
| Rule 3 | ボタンの frame が 44pt 未満（Apple HIG 違反） |
| Rule 4 | 丸ボタン (`.background(in: Circle())`) に `.contentShape(Rectangle())` を使っている |

### 推奨タイミング

- SwiftUI View ファイルの新規作成後
- ボタンのレイアウト変更後
- コードレビュー時
