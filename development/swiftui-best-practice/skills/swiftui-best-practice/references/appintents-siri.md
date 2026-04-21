# AppIntents / Siri / AppShortcuts の落とし穴

iOS 16+ の AppIntents + AppShortcuts で Siri 連携を作るときに踏みやすい罠と対処。

## 症状 → セクション

| 症状 | 対応セクション |
|---|---|
| `Invalid parameter type. AppEntity and AppEnum are the only allowed types for <param>` | § 1 phrase の String パラメータ禁止 |
| `Invalid Utterance. Every App Shortcut utterance should have one '${applicationName}' in it.` | § 2 utterance に applicationName 必須 |
| Siri に「FocusOne にタスクを追加」と言ってもリマインダーに流れる | § 3 Siri index 更新漏れ |
| Siri が `\(\.$task)` で 4 件目以降のタスクを認識しない | § 4 AppEntity 候補が snapshot cap |
| Siri がアプリを認識するが日本語発音で反応しない | § 5 CFBundleSpokenName 未設定 |

## § 1 phrase の `\(\.$param)` は AppEntity / AppEnum 限定

### 原因

`AppShortcut` の `phrases` 内で `\(\.$xxx)` で参照できる `@Parameter` は **`AppEntity` / `AppEnum` のみ**。`String` / `Int` 等のプリミティブ型を `\(\.$xxx)` で埋め込むとビルド時に AppIntents metadata extractor が halting error を出す。

```
appintentsmetadataprocessor: error: At least one halting error produced...
TaskFlowAppShortcuts.swift: error: Invalid parameter type. AppEntity and AppEnum are the only allowed types for taskTitle
```

### NG 例

```swift
struct AddTaskIntent: AppIntent {
    @Parameter(title: "タスク名")
    var taskTitle: String       // ← String
    ...
}

AppShortcut(
    intent: AddTaskIntent(),
    phrases: [
        "\(.applicationName) に \(\.$taskTitle) を追加"  // ❌ String を埋め込み
    ],
    ...
)
```

### 対処

**A. utterance から `\(\.$taskTitle)` を消す**（おすすめ）

```swift
@Parameter(
    title: "タスク名",
    requestValueDialog: IntentDialog("何を追加しますか？")  // Siri が音声で質問する
)
var taskTitle: String

AppShortcut(
    intent: AddTaskIntent(),
    phrases: [
        "\(.applicationName) にタスクを追加",   // ✅ taskTitle はダイアログで尋ねる
        "\(.applicationName) でタスクを追加",
        "Add a task in \(.applicationName)"
    ],
    ...
)
```

**B. AppEntity でラップする**（タスク選択など、対象が enumerable な場合）

```swift
struct TaskEntity: AppEntity, Identifiable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "タスク")
    static let defaultQuery = TaskEntityQuery()
    let id: String
    let title: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(title)") }
}

struct ToggleTaskCompletionIntent: AppIntent {
    @Parameter(title: "タスク")
    var task: TaskEntity?       // ✅ AppEntity
}

AppShortcut(
    intent: ToggleTaskCompletionIntent(),
    phrases: [
        "\(.applicationName) で \(\.$task) を完了"  // ✅ AppEntity なら埋め込める
    ]
)
```

## § 2 すべての utterance に `\(.applicationName)` 必須

### 原因

Apple の AppShortcut バリデーション仕様で、**`phrases` の各文字列に必ず `\(.applicationName)` が 1 回含まれていなければならない**。含まれない utterance を 1 つでも書くと、AppIntents metadata extractor が全 utterance の export を halt する。

```
error: Invalid Utterance. Every App Shortcut utterance should have one '${applicationName}' in it.
```

### NG 例

```swift
phrases: [
    "\(.applicationName) にタスクを追加",
    "タスクを追加"   // ❌ applicationName が無い → 全 utterance ごと弾かれる
]
```

### 対処

**全 utterance に `\(.applicationName)` を入れる**:

```swift
phrases: [
    "\(.applicationName) にタスクを追加",
    "\(.applicationName) でタスクを追加",
    "\(.applicationName) にやることを追加",
    "Add a task in \(.applicationName)",
    "Add a task to \(.applicationName)"
]
```

「アプリ名なしの短縮フレーズ」（例: 「タスクを追加」）を使いたい場合は、ユーザーが **Shortcuts アプリで手動でカスタムフレーズ登録** する必要がある（Apple 仕様の制約で AppShortcuts 単独では不可）。

## § 3 Siri index を強制更新する

### 原因

`AppShortcutsProvider.appShortcuts` の `phrases` や `CFBundleDisplayName` を変更しても、Siri が認識する index は **アプリを起動するか、明示で `updateAppShortcutParameters()` を呼ぶまで古いまま**。

具体的な症状:
- 新 phrase を追加してビルドした → Siri は依然として古い phrase で動く
- アプリ名を変更（CFBundleDisplayName: TaskFlow → FocusOne）した → Siri は依然として TaskFlow で認識
- 結果: 「FocusOne にタスクを追加」と言うと Siri が AppShortcut にマッチしないと判断 → **デフォルトのリマインダーに流れる**

### 対処

`AppShortcutsProvider.updateAppShortcutParameters()` を以下のタイミングで呼ぶ:

1. **アプリ起動時** （必須）

```swift
import AppIntents

@main
struct TaskFlowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // phrase / display name 変更後に Siri index を強制更新
                    TaskFlowAppShortcuts.updateAppShortcutParameters()
                }
        }
    }
}
```

2. **AppEntity の候補が変わったタイミング** （推奨）

```swift
// TaskAppModel.refresh() の最後に
TaskFlowAppShortcuts.updateAppShortcutParameters()
```

これで「タスク追加直後にそのタスクを Siri から完了」できるようになる。

### 確認

iPhone の **「ショートカット」アプリ** → **「App」** タブ → アプリ名を探す:
- 表示される → ✅ index 更新済み
- 表示されない → ❌ アプリを 1 度起動して 30 秒〜1 分待つ

## § 4 AppEntityQuery が Widget snapshot を見ると候補が cap される

### 原因

iOS Widget 用の snapshot store （`TaskWidgetSnapshotStore` 等）は表示用に **`maxVisibleTasks = 3`** で cap されている。`AppEntityQuery.allEntities()` で snapshot を読むと、Siri からも 3 件しか見えなくなり、4 件目以降のタスクを Siri から完了できない。

### NG 例

```swift
struct TaskEntityQuery: EntityStringQuery, EnumerableEntityQuery {
    func allEntities() async throws -> [TaskEntity] {
        let snapshot = TaskWidgetSnapshotStore.widgetShared.rawSnapshot()
        return (snapshot?.tasks ?? []).map { ... }   // ❌ 3 件 cap
    }
}
```

### 対処

**snapshot を経由せず、API から直接 fetch** する専用メソッドを Service に作る:

```swift
actor TaskWidgetService {
    /// Siri / AppIntents 専用。Widget snapshot の 3 件 cap を回避する。
    func fetchTodayActiveTasks(limit: Int = 10) async -> [TaskItem] {
        guard let configuration = configurationStore.load() else { return [] }
        do {
            let client = TaskAPIClient(configuration: configuration, session: session)
            let tasks = try await client.fetchTasks(statuses: ["today"])
            // 並び順は App / Widget / Watch と統一する共通 resolver を使う
            return TodayTaskResolver.activeTasks(from: tasks, limit: limit)
        } catch {
            return []
        }
    }
}

struct TaskEntityQuery: EntityStringQuery, EnumerableEntityQuery {
    func allEntities() async throws -> [TaskEntity] {
        let tasks = await TaskWidgetService().fetchTodayActiveTasks()
        return tasks.map(TaskEntity.init(from:))
    }
}
```

並び順は **App 表示 / Widget / Watch / Siri 全てで一致** させる。バラバラだと「Siri が言う『一番上』」と「App で見える『一番上』」が違って混乱する。**共通 resolver (TodayTaskResolver 等) に集約** する。

## § 5 CFBundleSpokenName で日本語発音を補助

### 原因

`AppShortcut.phrases` の `\(.applicationName)` は **CFBundleDisplayName**（ユーザー向け表示名）を指す。例えば英語名 `FocusOne` を CFBundleDisplayName にすると、Siri は "FocusOne" を英語発音 (`フォーカス・ワン`) で認識しようとする。日本語ユーザーが `フォーカスワン` と発音した場合、Siri が CFBundleDisplayName と一致と判断できないことがある。

### 対処

**`CFBundleSpokenName`** を Info.plist に追加して、発音辞書として日本語の読みを与える:

`project.yml`:

```yaml
TaskFlowMobile:
  info:
    path: TaskFlow/App/Info.plist
    properties:
      CFBundleDisplayName: FocusOne
      CFBundleSpokenName: フォーカスワン   # ← 日本語発音
      ...
```

Siri は CFBundleDisplayName と CFBundleSpokenName の **両方** を認識対象にする。「フォーカスワン にタスクを追加」とカナで発音しても Siri がアプリを特定できる。

> ⚠️ それでも Siri がリマインダーに流れる場合、ユーザーが Shortcuts アプリで **カスタムフレーズ** を録音すれば確実 (`タスクを追加` のように applicationName 抜きの短縮フレーズが使える)。

## まとめ: AppShortcut チェックリスト

新規に AppShortcut を追加するときの順序:

1. **`@Parameter`** が `AppEntity` / `AppEnum` か（String なら `\(\.$xxx)` を utterance から外す）
2. **全 phrase に `\(.applicationName)`** が含まれているか
3. **`AppShortcutsProvider.updateAppShortcutParameters()`** をアプリ起動時 + データ更新時に呼んでいるか
4. **`AppEntityQuery`** が Widget snapshot ではなく API 直叩きで全件取得しているか
5. **`CFBundleDisplayName` + `CFBundleSpokenName`** を Info.plist に設定しているか
6. **動作確認**: Shortcuts アプリ → App タブにアプリが出ているか、phrase が登録されているか

## 関連

- SKILL.md の "AppIntents / Siri" セクション
- AppIntent / AppShortcut / AppEntity の Apple Doc:
  - https://developer.apple.com/documentation/appintents/appshortcut
  - https://developer.apple.com/documentation/appintents/appshortcutsprovider
