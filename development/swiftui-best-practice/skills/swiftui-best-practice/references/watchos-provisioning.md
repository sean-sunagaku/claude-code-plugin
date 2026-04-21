# iOS + watchOS Provisioning トラブルシューティング

App Group + watchOS + Apple Watch 実機配布で詰まる 7 つの罠（Provisioning 5 段 + Watch 本体設定 1 段 + Xcode ビルド設定 1 段）と、それぞれの診断・解決手順。

> ⚠️ **Watch に "Could not install at this time." が出たとき、§ 1〜§ 5 の Provisioning をすべて完璧に直しても、§ 6 (Watch 本体の Developer Mode) が OFF だと 100% Install 失敗する**。他を何回直しても変わらない時は必ず § 6 を確認すること。さらに § 6 も ON で「**整合性を確認できなかったので、Install できません**」エラーが出た場合は § 7 (`ENABLE_DEBUG_DYLIB: NO`) を設定する。

## 症状

以下のいずれかが出たら、このドキュメントの該当セクションへ:

| 症状 | 対応セクション |
|---|---|
| `app.focusone.widget` (explicit) 等が「自動生成で使われていない」 | § 1 Bundle ID 不整合 |
| iOS Widget / Watch App のビルドで `Embedded binary's bundle identifier is not prefixed with the parent app's bundle identifier.` | § 1 Bundle ID 不整合 |
| Profile に App Group entitlement が入っていない（`security cms -D` で空） | § 2 App Group Capability 未保存 |
| Web UI で Edit → Save したのに反映されない | § 2 App Group Capability 未保存 |
| Apple Watch に「This app could not be installed at this time.」 | § 3 Watch UDID 未登録 or § 4 / § 5 / **§ 6** |
| Profile の `ProvisionedDevices` に Apple Watch UDID が含まれない | § 3 Watch UDID 未登録 |
| Spaceship/fastlane で API 生成した Profile に capability が足りない | § 4 API 製 Profile の仕様 |
| xcodebuild は通るが埋め込まれた Profile が「iOS Team Provisioning Profile:...」（Xcode 自動生成版） | § 5 Automatic Signing 上書き |
| **§ 1〜§ 5 全部直したのに Watch に "Could not install at this time." が出る** | **§ 6 Watch 本体の Developer Mode OFF** |
| **Watch に「整合性を確認できなかったので、Install できませんでした」が出る** | **§ 7 Xcode 15+ Debug dylib (ENABLE_DEBUG_DYLIB)** |
| Watch App の bundle に `__preview.dylib` や `<App>.debug.dylib` が同梱され、code signing 整合性チェックを通らない | § 7 Xcode 15+ Debug dylib |

## § 0 前提

```bash
brew install fastlane ios-deploy
```

App Store Connect API Key を `~/.private_keys/AuthKey_<KEY_ID>.p8` に配置済み。
Team ID / Issuer ID / Key ID は App Store Connect → Users and Access → Integrations → App Store Connect API で取得。

Spaceship を呼ぶ Ruby は brew fastlane の gem 環境を借りる:

```bash
FASTLANE_LIBEXEC=$(brew --prefix fastlane)/libexec
export PATH="/opt/homebrew/opt/ruby/bin:$FASTLANE_LIBEXEC/bin:${HOME}/.local/share/fastlane/4.0.0/bin:$PATH"
export GEM_HOME="${HOME}/.local/share/fastlane/4.0.0"
export GEM_PATH="${HOME}/.local/share/fastlane/4.0.0:$FASTLANE_LIBEXEC"
```

## § 1 Bundle ID 不整合

### 原因

Apple は **embed する拡張（Widget / Watch App / Watch Widget）の Bundle ID が親 App の Bundle ID で始まること** を要求する。

OK な例（親 = `app.focusone.app`）:
- iOS Widget: `app.focusone.app.widget`
- Watch App: `app.focusone.app.watchkitapp`
- Watch Widget: `app.focusone.app.watchkitapp.widget`

NG な例（親と prefix が違う）:
- ✗ iOS Widget: `app.focusone.widget` ← 親 `app.focusone.app.` で始まっていない

このまま `xcodebuild` すると "Embedded binary's bundle identifier is not prefixed..." で失敗。

### 解決

`project.yml` で 4 ターゲット全部の `PRODUCT_BUNDLE_IDENTIFIER` を親 App の Bundle ID で prefix する:

```yaml
targets:
  TaskFlowMobile:
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: app.focusone.app
  TaskFlowWidgetExtension:
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: app.focusone.app.widget
  TaskFlowWatch:
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: app.focusone.app.watchkitapp
    info:
      path: TaskFlowWatch/App/Info.plist
      properties:
        WKCompanionAppBundleIdentifier: app.focusone.app  # 親 App を指す
  TaskFlowWatchWidgetExtension:
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: app.focusone.app.watchkitapp.widget
```

xcodegen 後にビルドで検証。

## § 2 App Group Capability 未保存

### 原因

Apple Developer Portal の App ID 詳細で:
- ✓ **App Groups** にチェック → Capability を「有効化」しただけ
- その後 **Configure** で Group を選ぶ必要がある
- さらに戻った画面で **Save** → **Modify App Capabilities ダイアログで Confirm** まで押さないと **保存されない**

「Configure を押して Continue まで行った」だけでは反映されない。**最後の Confirm がキー**。

### 診断

Profile が本当にリンクされているかは、その Profile の entitlement を見る:

```bash
security cms -D -i /path/to/profile.mobileprovision | \
  plutil -extract Entitlements xml1 -o - - | \
  grep -A 3 "application-groups"
```

期待する出力:

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.app.focusone.shared</string>
</array>
```

`<array>` が空なら未紐付け or Save 未完了。

もう 1 つの確認: App ID の Capabilities 画面で **App Groups 行の右側ボタン**:
- **Edit** → ✅ 保存済み
- **Configure** → ❌ 未保存（最初からやり直し）

### 解決

1. https://developer.apple.com/account/resources/identifiers/list
2. 4 つの App ID 全部で:
   1. Capabilities の **App Groups** にチェック
   2. 行の右の **Configure** → 対応 Group を選択 → **Continue**
   3. 画面右上の **Save** を押す
   4. **Modify App Capabilities** ダイアログで **Confirm**
   5. 画面が「保存しました」になる or Capabilities 画面に戻る
3. もう一度ページを開き直して、App Groups の右が **Edit** になっていることを確認

### CLI で API Key を使って BundleId + Capability を下準備

紐付け Save は CLI では不可（Apple の App Store Connect API に endpoint が無い）。だが BundleId 作成と APP_GROUPS Capability の **有効化** までは API で出来る。残りの紐付けだけ Web UI。

```ruby
require "spaceship"
Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
  key_id: ENV["APPLE_API_KEY_ID"],
  issuer_id: ENV["APPLE_API_ISSUER_ID"],
  filepath: ENV["APPLE_API_KEY_PATH"]
)

# Bundle ID 作成 or 確認
bid = Spaceship::ConnectAPI::BundleId.all(filter: { identifier: "app.focusone.app" }).first ||
      Spaceship::ConnectAPI::BundleId.create(
        name: "app focusone app",
        identifier: "app.focusone.app",
        platform: Spaceship::ConnectAPI::BundleIdPlatform::IOS
      )

# APP_GROUPS capability を有効化
caps = bid.get_capabilities  # includes 引数は現在の spaceship では NG
unless caps.any? { |c| c.capability_type == "APP_GROUPS" }
  Spaceship::ConnectAPI::BundleIdCapability.create(
    bundle_id_id: bid.id,
    capability_type: Spaceship::ConnectAPI::BundleIdCapability::Type::APP_GROUPS
  )
end
```

## § 3 Apple Watch UDID が未登録

### 原因

Apple は iPhone と Apple Watch を **別の device** として扱う。iPhone を登録してもペアリング済み Watch は自動登録されない。Watch UDID が Developer Portal に無いと、Profile の `ProvisionedDevices` に Watch UDID が入らず、Watch へのインストールが拒否される。

### 診断

Mac に iPhone を USB 接続した状態で:

```bash
ios-deploy -c -t 5
```

出力例:

```
[....] Found 00008030-001C65C90CFB402E ... a.k.a. 'iPhone ...' connected through USB.
[....] Found 00008310-00074C440E08A01E ... a.k.a. '...さんのApple Watch' connected through USB Companion proxy.
```

後者の 40 桁 UDID が Apple Watch。

API で現在登録されている device 一覧を見る:

```ruby
Spaceship::ConnectAPI::Device.all.each do |d|
  puts "#{d.name} class=#{d.device_class} udid=#{d.udid}"
end
```

`class=APPLE_WATCH` が無ければ未登録。

### 解決

```ruby
Spaceship::ConnectAPI::Device.create(
  name: "My Apple Watch",
  platform: Spaceship::ConnectAPI::BundleIdPlatform::IOS,
  udid: "00008310-00074C440E08A01E"
)
```

Apple 側が自動で `class=APPLE_WATCH` と判定する（UDID の形式から）。

## § 4 API 製 Profile に App Group entitlement が入らない

### 原因

**Spaceship / App Store Connect API の `POST /v1/profiles` で生成した Provisioning Profile は、App Group entitlement を含まない**（Apple サーバ側の仕様・未ドキュメント）。

Web UI 経由（https://developer.apple.com/account/resources/profiles/list から [+]）で生成した Profile だけが App Group entitlement を取り込む。API 製 Profile は Apple サーバ上の Profile データ自体が App Group なしの状態になっている（ダウンロードして confirm 可能）。

### 診断

API で作った Profile を Apple Developer Portal からクリックして **Download** → 中身を `security cms -D` で見る:

```bash
security cms -D -i ~/Downloads/MyAPIProfile.mobileprovision | \
  plutil -extract Entitlements xml1 -o - -
```

`application-groups` キーが無ければ API 製の限界。

### 解決

**Web UI で 4 つ Profile を生成・Download する。**

各 App ID で:

1. https://developer.apple.com/account/resources/profiles/list → **[+]**
2. **iOS App Development** → Continue
3. **App ID** 選択 → Continue
4. **Offline support = No** → Continue
5. **Certificate** にチェック → Continue
6. **Devices** で **Select All**（§ 3 で登録した Watch UDID も含まれることを確認）→ Continue
7. **Profile Name** 入力（例: `FocusOne iOS App Dev`）→ **Generate**
8. **Download**

4 つの App ID 分繰り返す。`~/Downloads/*.mobileprovision` に 4 ファイル入る。

### Mac cache へ配置

ダウンロードした Profile を Xcode が使う場所に配置する:

```bash
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
for src in $(ls -t ~/Downloads/FocusOne_*.mobileprovision); do
  uuid=$(security cms -D -i "$src" | plutil -extract UUID raw -)
  cp "$src" ~/Library/MobileDevice/Provisioning\ Profiles/"$uuid".mobileprovision
done
```

UUID 名で配置するのは Xcode のルックアップが UUID ファイル名を期待しているため。

## § 5 Xcode Automatic Signing が手動 Profile を上書き

### 原因

`xcodebuild ... -allowProvisioningUpdates` を付けると、Xcode は **Apple Developer Portal から自動で Team Provisioning Profile を fetch or 新規作成** する。これが Mac cache に手動配置した Profile を **上書き** し、さらに Apple サーバ側で **古い capability / device で再生成** してしまう。

結果として、埋め込まれる `embedded.mobileprovision` は「iOS Team Provisioning Profile: ...」という Xcode 自動版になり、App Group も Watch UDID も含まれないことがある。

### 診断

ビルドログに:

```
Provisioning Profile: "iOS Team Provisioning Profile: app.focusone.app.watchkitapp"
```

と出ていれば、Xcode が自動生成版を選んだ証拠（手動版の Profile Name は `FocusOne Watch App Dev` 等のはず）。

`.app/Watch/TaskFlowWatch.app/embedded.mobileprovision` を読んでも同じ。

### 解決

**Manual Signing に切り替え**、`PROVISIONING_PROFILE_SPECIFIER` で手動 Profile 名を明示する。

`project.yml`:

```yaml
targets:
  TaskFlowMobile:
    settings:
      base:
        CODE_SIGN_STYLE: Manual
        CODE_SIGN_IDENTITY: Apple Development
        PROVISIONING_PROFILE_SPECIFIER: FocusOne iOS App Dev
  TaskFlowWidgetExtension:
    settings:
      base:
        CODE_SIGN_STYLE: Manual
        CODE_SIGN_IDENTITY: Apple Development
        PROVISIONING_PROFILE_SPECIFIER: FocusOne iOS Widget Dev
  TaskFlowWatch:
    settings:
      base:
        CODE_SIGN_STYLE: Manual
        CODE_SIGN_IDENTITY: Apple Development
        PROVISIONING_PROFILE_SPECIFIER: FocusOne Watch App Dev
  TaskFlowWatchWidgetExtension:
    settings:
      base:
        CODE_SIGN_STYLE: Manual
        CODE_SIGN_IDENTITY: Apple Development
        PROVISIONING_PROFILE_SPECIFIER: FocusOne Watch Widget Dev
```

xcodegen 後に **`-allowProvisioningUpdates` を絶対に付けずに** ビルド:

```bash
xcodebuild -project ios/YourApp.xcodeproj -scheme YourApp \
  -destination "platform=iOS,id=<iPhone UDID>" \
  -derivedDataPath /tmp/DerivedData \
  build
```

ログで `Provisioning Profile: "FocusOne Watch App Dev"` が出れば正しく手動版が使われている。

## § 6 Apple Watch 本体の Developer Mode が OFF

### 原因

iOS 16 以降、開発アプリ（Provisioning Profile で署名した非 App Store アプリ）を実機にインストールするには **Developer Mode を ON にする必要がある**。iPhone と Apple Watch は**別々にこの設定を持つ**。

- iPhone の Developer Mode は、Xcode で一度実機ビルドを通すと自動で求められて ON になる
- **Apple Watch 側も同じように Developer Mode が必要**だが、iPhone の Watch アプリから設定する経路が無く、手動で Watch 本体を操作しないと ON にできない
- これを知らずに「iPhone は Developer Mode ON なのに Watch にインストールできない」と詰まるケースが多発

§ 1〜§ 5 の Provisioning を完璧に直しても、Watch 側の Developer Mode が OFF なら **iPhone の Watch アプリで "Install" を押した瞬間に "This app could not be installed at this time." が出る**。

### 診断

iPhone の Watch アプリ → My Watch → **一般** → **情報** → 下まで見ても Developer Mode の項目が **無い**（ここには出ない）。**Apple Watch 本体の設定を見るしかない**。

### 解決

**Apple Watch 本体で**:

1. Settings（設定）アプリを開く
2. **Privacy & Security（プライバシーとセキュリティ）**
3. 下にスクロール → **Developer Mode（デベロッパーモード）**
4. トグルを **ON**
5. **Apple Watch を再起動**（サイドボタン長押し → 電源オフ → 再度サイドボタン長押しで起動）
6. 再起動後、Developer Mode を有効化する最終確認が Watch 上に出るので **"Turn On"** をタップ

再起動後、iPhone の Watch アプリ → My Watch → 利用可能なアプリ → FocusOne の **「インストール」** を押すと通るはず。

### 補足: iPhone 側 Developer Mode の確認

- iPhone で **Settings** → **Privacy & Security** → **Developer Mode** が表示されているか
- 表示されないなら Mac で一度 Xcode から実機ビルドを通すと出現する
- iPhone 側はほぼ自動で ON になっているが、Watch 側は **完全に手動**

### それでも "Could not install at this time." が出る場合の追加切り分け

Watch 本体 Developer Mode を ON にしても失敗するときの順番チェック:

1. **Watch のストレージ**: Settings → General → Storage で 100MB 以上空きがあるか
2. **iPhone Watch アプリ完全再起動**: App Switcher から Watch アプリを上スワイプ kill → 再起動 → Install 再試行
3. **iPhone 側のアプリ完全削除 → 再インストール**: ホーム長押し → 削除 → Mac から再 install → Install 再試行
4. **ペアリング解除 → 再ペア**: 最終手段。iPhone Watch アプリ → Apple Watch → ペア解除。復元込みで 15〜30 分。これで Apple 側の Watch 管理情報がリセットされる

4 までやって直らなければ、Mac の Console.app で iPhone / Watch のログを取る:

1. Console.app 起動
2. 左サイドバーで iPhone または Apple Watch を選択
3. 検索バーに `install` と入れる
4. Install ボタンを押した瞬間の **赤い ERROR 行**を探す
5. エラー詳細（bundle id 不一致 / entitlement mismatch / profile not found 等）で原因確定

## § 7 Xcode 15+ Debug dylib が watchOS で integrity check を弾く

### 原因

Xcode 15+ は Debug ビルド時に **SwiftUI Preview 高速化のための `__preview.dylib` と `<App>.debug.dylib` を自動生成**する。これは iPhone では問題ないが、watchOS の実機インストール時に **code signing の整合性チェックを通らず** インストール拒否される。

具体的な症状:

- iPhone の Watch アプリで「インストール」を押す → **「整合性を確認できなかったので、Install できませんでした。」** と出る
- `.app/Watch/<WatchApp>.app/` 配下に `__preview.dylib` と `<WatchAppName>.debug.dylib` が存在する

これは Xcode 15+ の **SwiftUI Preview 高速化**（コード変更時に全体リビルドせず dylib だけ差し替える仕組み）の副作用で、watchOS のデバイス側セキュリティが dylib を別署名として扱い弾く。

### 診断

埋め込まれている dylib を確認:

```bash
ls /tmp/DerivedData/Build/Products/Debug-iphoneos/YourApp.app/Watch/YourWatchApp.app/ | grep -E "(\.debug\.dylib|__preview\.dylib)"
```

`__preview.dylib` や `*.debug.dylib` が出てくれば、それが原因で弾かれる可能性大。

### 解決

`project.yml` の **watchOS ターゲット 2 つ**（Watch App + Watch Widget Extension）に `ENABLE_DEBUG_DYLIB: NO` を追加:

```yaml
targets:
  TaskFlowWatch:
    settings:
      base:
        CODE_SIGN_STYLE: Manual
        CODE_SIGN_IDENTITY: Apple Development
        PROVISIONING_PROFILE_SPECIFIER: FocusOne Watch App Dev
        ENABLE_DEBUG_DYLIB: NO   # ← watchOS 実機で integrity check を通すために必須
  TaskFlowWatchWidgetExtension:
    settings:
      base:
        CODE_SIGN_STYLE: Manual
        CODE_SIGN_IDENTITY: Apple Development
        PROVISIONING_PROFILE_SPECIFIER: FocusOne Watch Widget Dev
        ENABLE_DEBUG_DYLIB: NO   # ← 同上
```

> 💡 iOS 側のターゲット（iOS App / iOS Widget）には **付けなくて良い**。iPhone では debug dylib が問題なく動くため、SwiftUI Preview 高速化のメリットを残しておける。

xcodegen → クリーンビルド → 再インストール:

```bash
cd ios && xcodegen generate && cd ..
xcodebuild -project ios/YourApp.xcodeproj -scheme YourApp \
  -destination "platform=iOS,id=<iPhone UDID>" \
  -derivedDataPath /tmp/DerivedData \
  clean build
xcrun devicectl device install app --device <iPhone UDID> \
  /tmp/DerivedData/Build/Products/Debug-iphoneos/YourApp.app
```

Watch App の `__preview.dylib` / `.debug.dylib` が消えたことを確認:

```bash
ls /tmp/DerivedData/Build/Products/Debug-iphoneos/YourApp.app/Watch/YourWatchApp.app/ | grep -E "(preview|debug\.dylib)"
# → 出力なし = OK
```

その後 iPhone の Watch アプリ → My Watch → 利用可能なアプリ → 「インストール」で通る。

### 副作用

- **SwiftUI Preview が watchOS 側だけ少し遅くなる**（コード変更時に部分リビルドではなく通常ビルドになる）
- ただし Xcode の Preview は iPhone 側で確認できるので実害はほぼ無い
- Release ビルドには **一切影響なし**（Release は元々 debug dylib を作らない）

### 関連する類似症状

- Watch App の内部構造を見たいときは `unzip` せずに `Finder で右クリック → パッケージの内容を表示` でも可
- `embeddedBinaryValidationUtility` のログがビルド出力に出て、そこで弾かれていることもある

## 検証チェックリスト

全ステップ完了後、以下を確認:

- [ ] 4 Profile の全てに App Group entitlement が含まれる
  ```bash
  for f in ~/Library/MobileDevice/Provisioning\ Profiles/FocusOne_*.mobileprovision; do
    security cms -D -i "$f" | plutil -extract Entitlements xml1 -o - - | grep -q "application-groups" && echo "✅ $f" || echo "❌ $f"
  done
  ```
- [ ] 4 Profile の全てに Apple Watch UDID が含まれる
  ```bash
  security cms -D -i <profile> | plutil -extract ProvisionedDevices xml1 -o - - | grep "00008310"
  ```
- [ ] 埋め込まれた `.app/Watch/*.app/embedded.mobileprovision` も同じ条件
- [ ] ビルドログの `Provisioning Profile:` 行が **全て `FocusOne` で始まる**（`iOS Team Provisioning Profile:` が無い）
- [ ] **Apple Watch 本体で Settings → Privacy & Security → Developer Mode が ON**（§ 6） ← 忘れがち
- [ ] **watchOS ターゲット 2 つで `ENABLE_DEBUG_DYLIB: NO` が設定されている**（§ 7）
  ```bash
  # .app 内の Watch 配下に __preview.dylib / .debug.dylib が無いこと
  ls YourApp.app/Watch/YourWatchApp.app/ | grep -E "(preview|debug\.dylib)"
  # → 出力なしで OK
  ```
- [ ] iPhone の Watch アプリ → 利用可能なアプリ → 対象アプリ → **インストール** が成功

## 全自動化は不可能な理由

App Group の紐付け **Save** は Web UI のみ。App Store Connect API に `/v1/appGroups` や bundle ID への group assignment endpoint が存在しないため、**Web UI の手動操作を自動化する手段が無い**（Chrome DevTools / AppleScript 等で代替する以外）。

そのため本ワークフローは「CLI で出来る所は CLI、出来ない所は最小限の Web UI 操作」というハイブリッドで組む。

## 参考コマンド集

```bash
# Profile の entitlement を human readable で表示
security cms -D -i <profile> | plutil -convert xml1 -o - -

# 埋め込まれている Profile を見る
UNZIP=/tmp/unzipped; rm -rf $UNZIP; mkdir $UNZIP
cp -R <YourApp.app>/Watch/<WatchApp.app>/embedded.mobileprovision $UNZIP/
security cms -D -i $UNZIP/embedded.mobileprovision

# Apple Developer Portal 上の全 Profile 名を CLI で列挙
ruby -e '
require "spaceship"
Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
  key_id: ENV["APPLE_API_KEY_ID"],
  issuer_id: ENV["APPLE_API_ISSUER_ID"],
  filepath: ENV["APPLE_API_KEY_PATH"]
)
Spaceship::ConnectAPI::Profile.all.each { |p| puts "#{p.name} #{p.profile_type}" }
'
```

## 関連ドキュメント

- SKILL.md の "Provisioning & Distribution" セクション
- ant リポジトリの `scripts/macos/provision-all.rb` — App Store Connect API で BundleId/Capability 操作する参考実装
- ant の `Makefile` `ios-provision-all` ターゲット
