# ATT (App Tracking Transparency) は scenePhase == .active で呼ぶ

## Severity: High — iPadOS で ATT ダイアログが表示されず App Store リジェクトされる

## Problem

`ATTrackingManager.requestTrackingAuthorization()` はアプリが完全に `.active` 状態でないとダイアログを表示せずサイレントに失敗する（エラーも返さない）。

`.onAppear` で呼ぶと、iPhone ではたまたま動くが **iPadOS（特に `UIApplicationSupportsMultipleScenes: true`）ではシーンのライフサイクルが複雑なため、`.onAppear` 時点でまだ `.active` でないことがある**。

## Bad:

```swift
// ❌ .onAppear で ATT を呼ぶ — iPadOS でダイアログが出ない
var body: some Scene {
    WindowGroup {
        ContentView()
            .onAppear {
                Task {
                    await ATTrackingManager.requestTrackingAuthorization()
                    await MobileAds.shared.start()
                }
            }
    }
}
```

## Good:

```swift
// ✅ scenePhase == .active を確認してから ATT を呼ぶ
@Environment(\.scenePhase) private var scenePhase

var body: some Scene {
    WindowGroup {
        ContentView()
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await AdService.shared.requestTrackingAndInitialize()
                    }
                }
            }
    }
}
```

## AdService の実装パターン

```swift
@MainActor
final class AdService {
    static let shared = AdService()

    private var hasStartedATTFlow = false
    private var hasRequestedATT = false
    private var hasStartedSDK = false

    private init() {}

    func requestTrackingAndInitialize() async {
        guard !hasStartedATTFlow else { return }
        hasStartedATTFlow = true

        // 1. ATT リクエスト（active 状態で呼ばれることが保証されている）
        let status = ATTrackingManager.trackingAuthorizationStatus
        if status == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }

        // 2. ATT の結果に関わらず SDK を初期化
        guard !hasStartedSDK else { return }
        hasStartedSDK = true
        await MobileAds.shared.start()
    }
}
```

## なぜ iPhone では動いて iPad ではダメだったか

| 端末 | `.onAppear` 時の状態 | ATT ダイアログ |
|------|---------------------|----------------|
| iPhone | ほぼ `.active` | 表示される（たまたま動く） |
| iPad (MultiScene) | `.inactive` の場合あり | **表示されない** |

iPad は `UIApplicationSupportsMultipleScenes: true` の場合、Scene のライフサイクルが iPhone より複雑。`.onAppear` はビューツリーへのアタッチ通知であり、シーンの active 状態とは無関係。

## Key Points

- ATT リクエストは **必ず `scenePhase == .active` のタイミング** で呼ぶ
- `.onAppear` / `init()` / `application(_:didFinishLaunchingWithOptions:)` では呼ばない
- `hasStartedATTFlow` フラグで `.active` が複数回来ても1回しか呼ばないようにする
- ATT の結果を待ってから AdMob SDK を `start()` する（パーソナライズ判定に IDFA が必要）
- Apple の実機レビューは **iPad Air** で行われることがある — iPhone だけでテストしない
