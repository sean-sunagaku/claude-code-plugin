# watchOS App アーキテクチャの落とし穴

watchOS App + Widget Extension を SwiftUI で書くときに踏みやすい罠と対処。
Provisioning は [watchos-provisioning.md](watchos-provisioning.md) を参照。

## 症状 → セクション

| 症状 | 対応セクション |
|---|---|
| Watch アプリで TextField や Picker の文字が見えない（白背景に白文字） | § 1 watchOS の TextField 文字色 |
| watchOS Widget Extension のビルドで `Type does not conform to protocol 'AppIntentTimelineProvider'` | § 2 recommendations() 必須 |
| iPhone と Watch でデータ共有したいが App Group が使えない | § 3 WatchConnectivity 設定共有 |
| Watch アプリのバッテリー消費が激しい | § 4 scenePhase でポーリング ON/OFF |
| `[String: Any]` を MainActor へ渡そうとして `sending` 警告 | § 5 WatchConnectivity delegate の Sendable 対策 |
| iOS と watchOS で同じコードを共有したいが App Group ID が違う | § 6 OS 別 App Group の `#if os(watchOS)` 分岐 |
| watchOS の AppIcon を全サイズ用意するのが大変 | § 7 Single Size AppIcon |
| Profile を CLI 自動生成すると同名で重複エラー | § 8 同名 Profile delete → create |

## § 1 watchOS の TextField / Picker は文字色を明示する

### 原因

watchOS のデフォルトテーマは Dark Mode 寄りで、`TextField` / `Picker` のテキストは **白文字** で描画される。アプリの背景色を明示的に明るい色（白系）にすると **文字と背景が同化して見えなくなる**。

### NG

```swift
TextField("タイトル", text: $title)
    .padding(8)
    .background(TaskPalette.paperRaised)   // ← 白い背景
    .clipShape(RoundedRectangle(cornerRadius: 10))
// → 白背景に白文字で何も見えない
```

### 対処

`.foregroundStyle()` と `.tint()` を **必ず明示** する:

```swift
TextField("タイトル", text: $title)
    .foregroundStyle(TaskPalette.ink)   // 入力テキスト本体の色
    .tint(TaskPalette.ink)              // カーソル / 選択ハイライトの色
    .padding(8)
    .background(TaskPalette.paperRaised)
    .clipShape(RoundedRectangle(cornerRadius: 10))
```

`Picker` も同様。`.pickerStyle(.navigationLink)` の場合は label の色も明示する:

```swift
Picker(selection: $status) {
    ForEach(options, id: \.value) { Text($0.label).tag($0.value).foregroundStyle(TaskPalette.ink) }
} label: {
    Text("ステータス").foregroundStyle(TaskPalette.inkMute)
}
.pickerStyle(.navigationLink)
.tint(TaskPalette.ink)
```

## § 2 watchOS の `AppIntentTimelineProvider` は `recommendations()` 必須

### 原因

iOS の `AppIntentTimelineProvider` では `recommendations()` メソッドが optional（default 実装あり）。一方 **watchOS では required**。実装漏れると以下のビルドエラー:

```
Type 'XYZProvider' does not conform to protocol 'AppIntentTimelineProvider'
note: protocol requires function 'recommendations()' with type '() -> [AppIntentRecommendation<Self.Intent>]'
```

### 対処

watchOS Widget Provider に `recommendations()` を実装。Smart Stack / 文字盤ギャラリーに出す候補を返す:

```swift
struct TaskFlowWatchProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> Entry { ... }
    func snapshot(for configuration: MyIntent, in context: Context) async -> Entry { ... }
    func timeline(for configuration: MyIntent, in context: Context) async -> Timeline<Entry> { ... }

    // ← watchOS で必須
    func recommendations() -> [AppIntentRecommendation<MyIntent>] {
        [
            AppIntentRecommendation(
                intent: MyIntent(),
                description: "最上位タスク"
            )
        ]
    }
}
```

> 💡 iOS Widget でも実装しておくと iOS 18+ の Smart Stack 対応になるので無害。

## § 3 iPhone ↔ Watch は App Group 共有不可、WatchConnectivity で値だけ橋渡し

### 原因

iPhone と Apple Watch は **物理的に別デバイス**。同じ Apple ID / Team ID でも App Group の UserDefaults / SQLite を共有できない（同じファイルシステムを見ていないため）。Watch アプリで API 設定（Server URL / API Key 等）を持ちたい場合、何らかの方法で iPhone から Watch へ転送する必要がある。

### 対処

**WatchConnectivity** で値を push する:

iPhone 側:

```swift
import WatchConnectivity

@MainActor
final class PhoneWatchSyncClient: NSObject, ObservableObject {
    static let shared = PhoneWatchSyncClient()

    private let session: WCSession?
    private override init() {
        session = WCSession.isSupported() ? WCSession.default : nil
        super.init()
        session?.delegate = self
        session?.activate()
    }

    func push(baseURL: String, apiKey: String) {
        guard let session else { return }
        let context: [String: Any] = ["baseURL": baseURL, "apiKey": apiKey]
        try? session.updateApplicationContext(context)
        if session.isReachable {
            session.sendMessage(context, replyHandler: nil) { _ in }
        }
    }
}

extension PhoneWatchSyncClient: WCSessionDelegate {
    nonisolated func session(_ s: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {}
    nonisolated func sessionDidBecomeInactive(_ s: WCSession) {}
    nonisolated func sessionDidDeactivate(_ s: WCSession) { WCSession.default.activate() }
    nonisolated func session(_ s: WCSession, didReceiveMessage message: [String: Any]) {
        // Watch からの「最新 push して」リクエスト
        Task { @MainActor in self.push(baseURL: ..., apiKey: ...) }
    }
}
```

Watch 側:

```swift
@MainActor
final class WatchPhoneSyncClient: NSObject, ObservableObject {
    static let shared = WatchPhoneSyncClient()

    @Published private(set) var isConfigured: Bool = false
    private let store: SharedTaskConfigurationStore
    private let session: WCSession?

    private init(store: SharedTaskConfigurationStore = .widgetShared) {
        self.store = store
        self.isConfigured = store.load() != nil
        session = WCSession.isSupported() ? WCSession.default : nil
        super.init()
        session?.delegate = self
        session?.activate()
    }
}

extension WatchPhoneSyncClient: WCSessionDelegate {
    nonisolated func session(_ s: WCSession, didReceiveApplicationContext context: [String: Any]) {
        // § 5 を参照: Sendable 対策で primitive だけ抜き出して MainActor へ
        let baseURL = context["baseURL"] as? String
        let apiKey = context["apiKey"] as? String
        Task { @MainActor in
            self.applyConfigurationValues(baseURL: baseURL, apiKey: apiKey)
        }
    }
}
```

iPhone 側 / Watch 側 **両方で `WCSession.default.delegate = self` + `activate()` 必須**。片方だけだと届かない。

## § 4 scenePhase で Watch のポーリング ON/OFF

### 原因

Watch アプリでフォアグラウンド中にデータをポーリングする場合、background や inactive になった後もポーリングを続けると **バッテリー消費が大きくなる**。

### 対処

`@Environment(\.scenePhase)` で監視し、active で開始 / background で停止:

```swift
@main
struct TaskFlowWatchApp: App {
    @StateObject private var refresh = WatchTaskRefreshService.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(refresh)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task { await refresh.refresh() }
                refresh.startPolling(interval: 300)   // 5 分間隔
            case .inactive, .background:
                refresh.stopPolling()
            @unknown default:
                break
            }
        }
    }
}
```

`Task` ベースのポーリング実装は **重複起動安全** にする:

```swift
private var pollingTask: Task<Void, Never>?

func startPolling(interval: TimeInterval = 300) {
    pollingTask?.cancel()   // 古いタスクを必ず止める
    pollingTask = Task { [weak self] in
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(interval))
            if Task.isCancelled { break }
            await self?.refresh()
        }
    }
}

func stopPolling() {
    pollingTask?.cancel()
    pollingTask = nil
}
```

## § 5 WatchConnectivity delegate の `[String: Any]` Sendable 対策

### 原因

Swift 6 strict concurrency では `[String: Any]` は **非 Sendable**。delegate の closure 内で `Task { @MainActor in self.apply(context) }` のように `[String: Any]` を直接 MainActor へ渡すと:

```
sending 'context' risks causing data races
```

### 対処

delegate スレッド上で **必要な primitive だけ取り出して** から MainActor へ渡す:

```swift
nonisolated func session(_ s: WCSession, didReceiveApplicationContext context: [String: Any]) {
    // ❌ Task { @MainActor in self.apply(context: context) }
    // ✅ primitive だけ抜き出す
    let baseURL = context["baseURL"] as? String
    let apiKey = context["apiKey"] as? String
    Task { @MainActor in
        self.applyConfigurationValues(baseURL: baseURL, apiKey: apiKey)
    }
}

@MainActor
private func applyConfigurationValues(baseURL: String?, apiKey: String?) {
    guard let baseURL, let apiKey else { return }
    ...
}
```

`String?` は Sendable なので警告なし。

## § 6 OS 別 App Group ID は `#if os(watchOS)` で分岐

### 原因

iOS と watchOS で **App Group ID は別物にする必要がある**（Apple Developer Portal でも別 entitlement）。にもかかわらず同じ Shared コードを使いたい。

### 対処

定数定義側で OS 分岐:

```swift
// TaskFlowShared/WidgetSupport/TaskWidgetConstants.swift
enum TaskWidgetSharedDefaults {
    #if os(watchOS)
    static let appGroupID = "group.app.focusone.watch"
    #else
    static let appGroupID = "group.app.focusone.shared"
    #endif

    static func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}
```

`SharedTaskConfigurationStore` 等は `TaskWidgetSharedDefaults.makeDefaults()` を経由するので、コード上は分岐を意識せず両 OS で動く。

## § 7 watchOS の AppIcon は Single Size モードで 1 枚

### 原因

watchOS の AppIcon を従来のサイズ別個別 PNG（24x24, 27.5x27.5, ..., 108x108, 1024x1024）で揃えるのは大量で大変。

### 対処

**Single Size mode**（Xcode 14+ / watchOS 11+）を使う。`Contents.json` に `1024x1024` 1 件だけ書けば、Xcode が全サイズに自動展開する:

```json
{
  "images": [
    {
      "filename": "AppIcon.png",
      "idiom": "universal",
      "platform": "watchos",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

`AppIcon.png` を `1024x1024` の 1 枚だけ用意して同じディレクトリに置く。

> 💡 iOS の AppIcon も同じく Single Size モードが使える (`platform: ios`)。

## § 8 Spaceship で Profile 作成時の重複エラー

### 原因

`Spaceship::ConnectAPI::Profile.create` で同名 Profile を再生成しようとすると 409 エラー:

```
Multiple profiles found with the name 'FocusOne iOS App Dev'.
Please remove the duplicate profiles and try again.
```

### 対処

create 前に同名 Profile を全部 delete してから create:

```ruby
def recreate_profile(profile_name, bundle_id, cert_ids, device_ids)
  Spaceship::ConnectAPI::Profile.all.each do |p|
    if p.name == profile_name
      puts "  - deleting old profile '#{p.name}'"
      p.delete!
    end
  end

  Spaceship::ConnectAPI::Profile.create(
    name: profile_name,
    profile_type: Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_DEVELOPMENT,
    bundle_id_id: bundle_id.id,
    certificate_ids: cert_ids,
    device_ids: device_ids
  )
end
```

ただし **API 製 Profile は App Group entitlement を含まない**（[watchos-provisioning.md § 4](watchos-provisioning.md) 参照）ので、自動化スクリプト側で生成しても結局 Web UI で作り直しになる。
API は **BundleId + Capability の有効化までの下準備** に留めて、最終 Profile は Web UI で手動生成するのが現実解。

## まとめ: watchOS アーキテクチャ チェックリスト

新規に watchOS App / Widget Extension を作るときの順序:

1. **TextField / Picker** に `.foregroundStyle()` + `.tint()` を明示したか
2. Widget Provider が `AppIntentTimelineProvider` の場合、**`recommendations()` を実装**したか
3. iPhone と Watch でデータ共有が必要なら、**WatchConnectivity** で iPhone 側 Sender + Watch 側 Receiver を両方実装したか
4. delegate の `[String: Any]` は **primitive だけ抜き出して** MainActor へ渡しているか
5. ポーリング系は **scenePhase で active 時のみ動かす**（background で停止）になっているか
6. App Group ID を **`#if os(watchOS)` で OS 分岐**したか
7. AppIcon は **Single Size モード** で 1024x1024 1 枚にまとめたか
8. Profile 自動化は **「BundleId + Capability 下準備」までで止め**、Profile 生成は Web UI 手動か

## 関連

- [watchos-provisioning.md](watchos-provisioning.md) — Provisioning / Manual Signing / ENABLE_DEBUG_DYLIB
- [appintents-siri.md](appintents-siri.md) — AppShortcuts / Siri index 更新
- SKILL.md の "watchOS Architecture" セクション
