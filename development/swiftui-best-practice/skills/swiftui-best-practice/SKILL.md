---
name: swiftui-best-practice
description: >
  SwiftUI のレイアウト落とし穴・ベストプラクティス・非推奨パターンと、
  iOS / watchOS アプリの実機配布 (Provisioning / App Group / Code Signing /
  Apple Watch Developer Mode / Xcode 15+ Debug dylib) トラブルシューティング
  のガイド。コード生成・修正時に既知のレイアウトバグを防ぎ、
  App Group + watchOS + Apple Watch の実機インストール失敗を
  7 段階フレームワークで診断・解消する。
  Use when: SwiftUI のコードを書く・修正するとき。
  レイアウト崩れを修正するとき。safeAreaInset や ViewThatFits を使うとき。
  マルチデバイス対応するとき。iOS + watchOS アプリの実機ビルド / 配布で
  provisioning / App Group / Manual Signing / Apple Watch の UDID / Xcode 自動署名の
  罠に詰まったとき。Apple Watch に "Could not install at this time" が出たとき。
  Triggers: "SwiftUI", "layout", "safeAreaInset", "ViewThatFits",
  "GeometryReader", "レイアウト", "崩れ", "表示バグ", "iPhone SE",
  "ATT", "ATTrackingManager", "requestTrackingAuthorization", "AdMob", "広告",
  "Provisioning Profile", "App Group", "Manual Signing", "Code Signing",
  "Apple Watch", "watchOS", "Install できない", "Could not install at this time",
  "Bundle ID 紐付け", "Xcode Automatic Signing", "embedded.mobileprovision",
  "Spaceship", "App Store Connect API", "WKCompanionAppBundleIdentifier",
  "Developer Mode", "Privacy & Security", "watchOS Developer Mode",
  "Apple Watch に App を入れられない",
  "整合性を確認できなかった", "integrity check", "ENABLE_DEBUG_DYLIB",
  "__preview.dylib", "debug.dylib", "Xcode 15 Preview", "SwiftUI Preview dylib",
  "ENABLE_PREVIEWS",
  "AppIntents", "AppShortcut", "AppShortcutsProvider", "AppEntity", "AppEnum",
  "Siri", "Siri に流れる", "Siri がリマインダーに流れる",
  "updateAppShortcutParameters", "Invalid parameter type", "Invalid Utterance",
  "applicationName", "CFBundleDisplayName", "CFBundleSpokenName",
  "TaskEntityQuery", "AppEntityQuery", "TimelineProvider", "recommendations",
  "WatchConnectivity", "WCSession", "updateApplicationContext", "sessionDidBecomeInactive",
  "iPhone と Watch でデータ共有", "App Group 共有できない",
  "scenePhase", "ポーリング", "watchOS バッテリー",
  "TextField 文字色 watchOS", "Picker 文字色 watchOS",
  "Single Size AppIcon", "watchOS AppIcon"
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

### AppIntents / Siri / AppShortcuts

`Siri がリマインダーに流れる` / `Invalid parameter type. AppEntity and AppEnum are the only allowed types` / `Invalid Utterance. Every App Shortcut utterance should have one '${applicationName}'` — AppShortcuts は仕様の制約が多く、これを踏まないように 5 段階で組む必要がある。

詳細は [references/appintents-siri.md](references/appintents-siri.md) を参照。要点だけ:

1. **`@Parameter` の `String` を utterance に埋め込めない** — `\(\.$xxx)` で参照できるのは `AppEntity` / `AppEnum` のみ。`String` パラメータは `requestValueDialog` で Siri に質問させ、utterance からは外す。
2. **全 utterance に `\(.applicationName)` 必須** — 1 つでも含まない utterance を書くと AppIntents metadata extractor が halt して全 utterance がインデックスされなくなる。
3. **`AppShortcutsProvider.updateAppShortcutParameters()` を起動時 + データ変更時に呼ぶ** — 呼ばないと phrase / display name 変更後も Siri が古い登録のままで「FocusOne にタスクを追加」が Reminder に流れる。
4. **`AppEntityQuery` は Widget snapshot を見ない** — snapshot は Widget 用に件数 cap されているので、4 件目以降のタスクが Siri から見えなくなる。専用の API 直叩きメソッドを Service に作って、AppEntityQuery から呼ぶ。並び順は App / Widget / Watch / Siri 全てで共通 resolver に統一する。
5. **`CFBundleDisplayName` + `CFBundleSpokenName` を Info.plist に設定** — `applicationName` は CFBundleDisplayName を指す。日本語ユーザー向けに英語名を使うなら CFBundleSpokenName でカナ読みも与える。

```swift
// 起動時 + refresh 後に呼ぶ
import AppIntents
.task { TaskFlowAppShortcuts.updateAppShortcutParameters() }

// AppEntityQuery は API 直叩き、共通 resolver で並び順統一
struct TaskEntityQuery: EntityStringQuery, EnumerableEntityQuery {
    func allEntities() async throws -> [TaskEntity] {
        let tasks = await TaskWidgetService().fetchTodayActiveTasks()  // snapshot 経由しない
        return tasks.map(TaskEntity.init(from:))
    }
}
```

### watchOS App アーキテクチャ

watchOS App + Widget Extension で踏みやすい罠 (TextField 色 / WatchConnectivity / scenePhase / `recommendations()`)。

詳細は [references/watchos-app-architecture.md](references/watchos-app-architecture.md) を参照。要点:

1. **TextField / Picker の文字色明示** — watchOS の TextField はデフォルトで白文字描画。白系背景の上に置くと見えなくなるので `.foregroundStyle(...)` + `.tint(...)` を明示する。
2. **`AppIntentTimelineProvider.recommendations()` watchOS で必須** — iOS は optional だが watchOS は required メソッド。実装漏れると "does not conform to protocol" エラー。
3. **iPhone ↔ Watch は WatchConnectivity で値だけ橋渡し** — App Group は別デバイスで共有不可。`WCSession.updateApplicationContext` で primitive を push、Watch 側 delegate で受け取って自分の App Group UserDefaults に保存。両側で `WCSession.delegate = self` + `activate()` 必須。
4. **delegate の `[String: Any]` は primitive 抜き出して MainActor へ** — Swift 6 strict concurrency で `[String: Any]` は非 Sendable。delegate スレッド上で `as? String` 等で抜き出してから MainActor closure に渡す。
5. **scenePhase で Watch 側ポーリング ON/OFF** — `.active` で `startPolling`、`.inactive` / `.background` で `stopPolling`。バッテリー配慮。`Task` ベースなら `pollingTask?.cancel()` で重複起動安全。
6. **App Group ID は `#if os(watchOS)` で OS 分岐** — iOS と watchOS で別 entitlement が必要だが、Shared コードは同じものを使えるよう `TaskWidgetSharedDefaults.appGroupID` を `#if os(watchOS)` で切り替える。
7. **AppIcon は Single Size モード (1024x1024 1 枚)** — Contents.json に `idiom: universal, platform: watchos, size: 1024x1024` 1 件だけ書けば Xcode が全サイズ展開する。

### iOS + watchOS Provisioning (App Group / Manual Signing)

**`Could not install at this time.` / 整合性を確認できなかった / Profile に App Group が入らない / Xcode Automatic Signing が手動 Profile を上書き** — これらは iOS + watchOS + App Group 構成で頻発する既知の罠。7 段階フレームワークで診断・解決する。

> ⚠️ **失敗時の順序**: § 1〜§ 5 (Provisioning) → § 6 (Watch 本体 Developer Mode) → § 7 (ENABLE_DEBUG_DYLIB)。エラー文言で分岐できる:
> - "Could not install at this time." → § 6 を疑う
> - "整合性を確認できなかったので、Install できませんでした" → § 7 を疑う

詳細は [references/watchos-provisioning.md](references/watchos-provisioning.md) を参照。要点だけ:

1. **Bundle ID 不整合** — embed 拡張 (Widget / Watch App / Watch Widget) の Bundle ID は **親 App Bundle ID の完全 prefix** である必要。`app.focusone.widget` は NG、`app.focusone.app.widget` が正。
2. **App Group Capability 未保存** — Apple Developer Portal の Configure → 選択 → Continue の後、**画面右上 Save + Confirm ダイアログ** まで押さないと反映されない。Capabilities 行の右が **Edit** なら ✅、**Configure** なら未保存。
3. **Apple Watch UDID 未登録** — iPhone と別 device 扱い。`ios-deploy -c -t 5` で USB Companion proxy 経由で取得 → Spaceship API で `class=APPLE_WATCH` として登録。
4. **API 製 Profile に App Group が入らない仕様** — `Spaceship::ConnectAPI::Profile.create` で生成した Profile は App Group entitlement を取り込まない（Apple サーバ側の制約）。**Web UI で 4 つ生成・Download** が必須。
5. **Xcode Automatic Signing が手動 Profile を上書き** — `-allowProvisioningUpdates` で Team Provisioning Profile を再 fetch → 手動版が消える。**`CODE_SIGN_STYLE: Manual` + `PROVISIONING_PROFILE_SPECIFIER` を 4 ターゲット全部で明示**、かつ `-allowProvisioningUpdates` を絶対に付けない。
6. **Apple Watch 本体の Developer Mode OFF** — iOS 16+ で開発 App をインストールするには Watch 側も **Settings → Privacy & Security → Developer Mode → ON → Watch 再起動** が必要。iPhone の Watch アプリには出てこないので **必ず Apple Watch 本体**で設定する。これを忘れると Provisioning が正しくても 100% "Could not install at this time." になる。
7. **Xcode 15+ Debug dylib が watchOS で integrity check を弾く** — Debug ビルド時に生成される `__preview.dylib` / `<App>.debug.dylib`（SwiftUI Preview 高速化用）が watchOS の code signing 整合性チェックを通らず **「整合性を確認できなかったので、Install できませんでした」** エラーになる。watchOS ターゲット 2 つに `ENABLE_DEBUG_DYLIB: NO` を追加して dylib 生成を無効化する（iOS 側は影響なし、watchOS Preview が少し遅くなるだけ）。

```yaml
# project.yml で各ターゲットの settings.base に追加
CODE_SIGN_STYLE: Manual
CODE_SIGN_IDENTITY: Apple Development
PROVISIONING_PROFILE_SPECIFIER: FocusOne Watch App Dev
ENABLE_DEBUG_DYLIB: NO  # ← watchOS ターゲットのみ (iOS 側には不要)
```

検証:

```bash
# Profile に App Group が含まれているか
security cms -D -i <profile.mobileprovision> | \
  plutil -extract Entitlements xml1 -o - - | grep application-groups

# Profile に Apple Watch UDID が含まれているか
security cms -D -i <profile.mobileprovision> | \
  plutil -extract ProvisionedDevices xml1 -o - - | grep <Watch UDID>

# 埋め込まれた Profile が手動版か自動生成版か
security cms -D -i <YourApp.app>/Watch/<WatchApp.app>/embedded.mobileprovision | \
  plutil -extract Name raw -
# 期待: "FocusOne Watch App Dev" などの手動版名
# NG:   "iOS Team Provisioning Profile: ..." (Xcode 自動版)
```

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
19. iOS + watchOS + App Group 構成では **Manual Signing + 手動 Web UI 生成 Profile** を使う — Automatic Signing と Spaceship API は App Group entitlement を取り込まず、Xcode が手動 Profile を上書きする
20. 埋め込み Extension (Widget / Watch App / Watch Widget) の Bundle ID は必ず親 App Bundle ID の **完全な prefix** で始める — `app.focusone.widget` は NG、`app.focusone.app.widget` が正
21. Apple Watch 実機配布前に `ios-deploy -c -t 5` で Watch UDID を取得し Developer Portal に登録する — iPhone とは別 device 扱いで自動登録されない
22. Profile 生成は Web UI でやる — API 経由 (Spaceship / App Store Connect API) で作った Profile には App Group entitlement が入らない (Apple の未ドキュメント仕様)
23. **Apple Watch 本体で Developer Mode を ON にする** — Settings → Privacy & Security → Developer Mode → ON → Watch 再起動。iPhone の Developer Mode は別物で、iPhone の Watch アプリにもこの設定は出てこない。これが OFF だと Provisioning を完璧に直しても "Could not install at this time." で 100% 失敗する
24. **watchOS ターゲットに `ENABLE_DEBUG_DYLIB: NO` を設定する** — Xcode 15+ は Debug ビルド時に `__preview.dylib` と `<App>.debug.dylib` を自動生成するが、これが watchOS の code signing 整合性チェックを通らず **「整合性を確認できなかったので、Install できませんでした」** で弾かれる。watchOS ターゲット 2 つ（Watch App + Watch Widget）に `ENABLE_DEBUG_DYLIB: NO` を追加すれば解消。iOS 側には不要
25. **Xcode 16+ では `ENABLE_PREVIEWS: NO` も併記する** — `ENABLE_DEBUG_DYLIB: NO` だけでは Xcode 16+ で再発するケースがあり、preview 機能自体を OFF にする必要がある。watchOS の SwiftUI Live Preview が使えなくなる副作用はあるが、実機/シミュレーターで確認すれば実害は小さい
26. **`AppShortcut.phrases` の `\(\.$xxx)` は AppEntity / AppEnum 限定** — `String` パラメータを utterance に埋め込むと "Invalid parameter type" でビルドが halt する。値を取りたいなら `requestValueDialog` で Siri に質問させ、utterance からは外す
27. **AppShortcut の utterance は全て `\(.applicationName)` を含む** — 1 つでも含まない utterance を書くと "Invalid Utterance" で全 utterance のインデックスが失われる。アプリ名抜きの短縮 phrase はユーザーが Shortcuts アプリで個別に設定する
28. **`AppShortcutsProvider.updateAppShortcutParameters()` を起動時 + データ変更時に呼ぶ** — 呼ばないと Siri index が古いままで、phrase 変更や CFBundleDisplayName 変更が反映されず Siri がアプリを認識せずデフォルトのリマインダーに流れる。`AppEntityQuery` の候補が変わるタイミング（タスク追加 / 完了など）にも呼ぶと UX が良くなる
29. **`AppEntityQuery` は Widget snapshot ではなく API 直叩きで取得する** — snapshot は Widget 用に件数 cap されているので Siri 候補も cap される。専用 fetch メソッドを Service に作り、共通 resolver で App / Widget / Watch / Siri の並び順を統一する
30. **iPhone ↔ Watch のデータ共有は WatchConnectivity で primitive を push する** — App Group は別デバイスで共有不可。`WCSession.updateApplicationContext` で値を push、両側で delegate + `activate()` 必須。delegate の `[String: Any]` は primitive を抜き出してから MainActor へ渡す（Swift 6 strict concurrency 対策）
31. **watchOS の TextField / Picker は `.foregroundStyle()` + `.tint()` で文字色を明示する** — デフォルトの白文字が白系背景の上で見えなくなる
32. **watchOS の `AppIntentTimelineProvider` には `recommendations()` を実装する** — iOS では optional だが watchOS では required。Smart Stack / 文字盤ギャラリーに出す候補を返す
33. **Watch アプリのポーリングは `scenePhase` で ON/OFF** — `.active` で `startPolling`、`.inactive` / `.background` で `stopPolling`。Task ベースなら `pollingTask?.cancel()` で重複起動安全に
34. **共有コードの App Group ID は `#if os(watchOS)` で OS 分岐** — iOS と watchOS で別 entitlement、同じコードで両方動かすため定数側で切り替える
35. **watchOS / iOS の AppIcon は Single Size モード (1024x1024 1 枚)** — Contents.json に `idiom: universal, platform: <ios|watchos>, size: 1024x1024` 1 件で Xcode が全サイズ展開してくれる

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
