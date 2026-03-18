---
name: swiftui-best-practice
description: >
  SwiftUI のレイアウト落とし穴・ベストプラクティス・非推奨パターンのガイド。
  コード生成・修正時に既知のレイアウトバグを防ぎ、正しいパターンを適用する。
  Use when: SwiftUI のコードを書く・修正するとき。
  レイアウト崩れを修正するとき。safeAreaInset や ViewThatFits を使うとき。
  マルチデバイス対応するとき。
  Triggers: "SwiftUI", "layout", "safeAreaInset", "ViewThatFits",
  "GeometryReader", "レイアウト", "崩れ", "表示バグ", "iPhone SE"
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
