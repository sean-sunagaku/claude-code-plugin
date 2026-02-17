---
name: eas-deploy
description: >
  Expo (EAS) iOS/Android アプリのデプロイ自動化スキル。
  App ID 登録、証明書・プロビジョニングプロファイル作成、
  EAS ビルド、TestFlight 配布、App Store 提出までを CLI から実行する。
  任意の Expo プロジェクトで使える汎用スキル。
  Use when: App ID を登録したい、証明書を作りたい、Bundle ID を設定したい、
  EAS でビルドしたい、TestFlight に配布したい、App Store に提出したい。
  Triggers: "App ID", "Bundle ID", "証明書", "certificate", "provisioning",
  "プロビジョニング", "eas credentials", "eas build", "eas submit",
  "TestFlight", "App Store 提出", "署名", "signing"
---

# EAS Deploy

任意の Expo プロジェクトの iOS/Android デプロイを CLI から自動実行する。

## フロー

```
Step 1: 証明書・Bundle ID セットアップ  ← 実装済み
Step 2: EAS ビルド                       ← 実装済み
Step 3: TestFlight 配布                  ← 実装済み
Step 4: App Store 提出                   ← 実装済み
```

## 前提条件

```bash
eas whoami       # ログイン確認 (なければ: eas login)
eas --version    # CLI 確認 (なければ: npm install -g eas-cli)
```

---

## Step 1: 証明書・Bundle ID セットアップ

### スクリプト実行

```bash
# カレントディレクトリから eas.json を自動検出（推奨）
bash ~/.claude/skills/eas-deploy/scripts/setup-credentials.sh

# サブディレクトリ指定（相対パスで OK）
bash ~/.claude/skills/eas-deploy/scripts/setup-credentials.sh ./mobile

# Android の場合
bash ~/.claude/skills/eas-deploy/scripts/setup-credentials.sh ./mobile android
```

環境変数でオーバーライド可能:
```bash
BUNDLE_ID=com.example.app bash ~/.claude/skills/eas-deploy/scripts/setup-credentials.sh
EAS_PLATFORM=android bash ~/.claude/skills/eas-deploy/scripts/setup-credentials.sh
```

### 動作モード（自動判定）

スクリプトは stdin が対話可能かを `[ -t 0 ]` で自動判定する。

| モード | 判定条件 | 動作 |
|--------|----------|------|
| **対話** | ターミナルから直接実行 | チェック → 問題あれば自動修正 → `eas credentials` 実行 |
| **非対話** | Claude Code 等から実行 | チェック → 問題を一覧表示 → 実行すべきコマンドを出力 |

Claude Code から実行した場合、Apple ID 認証が必要な `eas credentials` は実行せず、
コピペ用のコマンドを提示する。ユーザーは自分のターミナルでそれを実行する。

### チェック項目

1. eas-cli インストール済みか
2. EAS ログイン済みか
3. bundleIdentifier を app.config.ts / app.json から自動取得（TS/JSON 両対応）
4. EAS プロジェクトがリンク済みか（`projectId` の有無）
5. 問題があれば修正方法を提示、対話モードなら `eas init` を自動実行

### 対話メニューの操作ガイド

`eas credentials` 実行後、以下の順に選択する:

| # | プロンプト | 選択 |
|---|-----------|------|
| 1 | Which build profile? | **production** |
| 2 | What do you want to do? | **Build Credentials** |
| 3 | Distribution Certificate | **Set up a new one** (または既存を選択) |
| 4 | Provisioning Profile | **Set up a new one** (または既存を選択) |

途中で Apple ID + 2FA コード (6桁) の入力が必要。

### 作成されるもの

- App ID (Bundle ID 登録)
- Distribution Certificate
- Provisioning Profile

### よくあるエラー

| エラー | 対処 |
|--------|------|
| `Apple ID authentication failed` | 2FA コード入力、または App-specific password 生成 |
| `Bundle ID already exists` | Apple Developer Portal で確認、別 ID に変更 |
| `Missing Apple Developer Program` | developer.apple.com で加入 (年99ドル) |

---

## Step 2: EAS ビルド

### ビルド前の必須設定

ビルド前に以下が設定されていることを確認し、なければ自動で追加する。

**eas.json** — `cli.appVersionSource` (将来必須):
```json
{
  "cli": {
    "appVersionSource": "remote"
  }
}
```

**app.config.ts** — `ios.infoPlist.ITSAppUsesNonExemptEncryption` (暗号化申告):
```typescript
ios: {
  infoPlist: {
    ITSAppUsesNonExemptEncryption: false
  }
}
```

これがないと毎回ビルド時に対話的に聞かれる。
独自暗号化を使っていない場合は `false` で OK（HTTPS は標準暗号扱い）。

### ビルド方法の選択

ユーザーにローカルビルドかクラウドビルドかを確認する。
**デフォルトはローカルビルドを推奨する。**

| 方式 | コマンド | 特徴 |
|------|----------|------|
| **ローカル（推奨）** | `eas build --local` | 無料、高速、Xcode 必須 |
| クラウド | `eas build` | Xcode 不要、EAS クレジット消費、アップロード時間あり |

#### ローカルビルド（推奨）

```bash
# App Store 用
eas build --platform ios --profile production --local

# 内部配布 (AdHoc)
eas build --platform ios --profile preview --local

# シミュレータ / dev-client
eas build --platform ios --profile development --local
```

前提条件:
- Xcode がインストール済み（`xcode-select -p` で確認）
- CocoaPods がインストール済み（`pod --version` で確認、なければ `sudo gem install cocoapods`）
- ビルド成果物（.ipa）はカレントディレクトリに出力される

#### クラウドビルド

```bash
eas build --platform ios --profile production
```

ビルドは EAS サーバー上で実行され、完了まで数分〜十数分かかる。
確認: `eas build:list --platform ios --limit 1`

### 対話メニューの操作ガイド

| # | プロンプト | 選択 |
|---|-----------|------|
| 1 | iOS app only uses standard/exempt encryption? | **yes** (HTTPS のみなら) |
| 2 | Do you want to log in to your Apple account? | **yes** |
| 3 | Distribution Certificate を再利用するか | **yes** (既存があれば再利用) |
| 4 | Generate a new Apple Provisioning Profile? | **yes** |

### よくあるビルドエラー

| エラー | 原因 | 対処 |
|--------|------|------|
| `Failed to restore metadata: File exists` + tar エラー | macOS メタデータ (`._*`) や vim スワップ (`.swp`) が git に入っている | `git rm --cached` で除外 + `.gitignore` に `._*` と `*.swp` を追加 |
| `cli.appVersionSource is not set` | eas.json に未設定 | `"appVersionSource": "remote"` を追加 |
| `ITSAppUsesNonExemptEncryption` を毎回聞かれる | app.config.ts に未設定 | `ios.infoPlist.ITSAppUsesNonExemptEncryption: false` を追加 |
| `Cannot automatically write to dynamic config` | app.config.ts は動的設定なので EAS が自動書き込みできない | 手動で app.config.ts に追記する（EAS のログに追加すべき JSON が表示される） |

**ビルド前チェック（自動で実行すべき）:**

```bash
# macOS メタデータが git に入っていないか確認
git ls-files | grep '/\._'
# .gitignore に ._* と *.swp が含まれているか確認
grep -q '._\*' .gitignore || echo '._*' >> .gitignore
grep -q '*.swp' .gitignore || echo '*.swp' >> .gitignore
```

---

## Step 3: TestFlight 配布

App Store Connect にビルドをアップロードし、TestFlight でテスターに配布する。

### 提出コマンド

```bash
# クラウドビルドの場合（最新ビルドを自動選択）
cd <project-dir> && eas submit --platform ios --latest

# クラウドビルドを手動選択
cd <project-dir> && eas submit --platform ios

# ローカルビルド (.ipa) の場合
cd <project-dir> && eas submit --platform ios --path ./build-xxxxx.ipa
```

### 実際のフロー

`eas submit --platform ios` を実行すると以下の順に進む:

```
1. What would you like to submit?
   → "Select a build from EAS" を選択

2. Which build would you like to submit?
   → 最新のビルド (数分前のもの等) を選択
   ※ "production" プロファイルのビルドが表示される

3. App Store Connect 確認
   → "Ensuring your app exists on App Store Connect" が自動実行
   → ascAppId を submit profile に設定済みならスキップ可

4. Apple ID ログイン
   → Apple ID を入力
   → セッションが残っていれば "Restoring session" で自動ログイン
   → Team / Provider が自動選択される

5. 初回のみ自動実行される処理:
   → Bundle identifier registered (App ID 登録)
   → TestFlight group created: "Team (Expo)"
   → TestFlight access enabled for: <Apple ID>

6. App Store Connect API Key
   → 既存の API Key があれば "Reuse this API Key?" → yes
   → なければ自動生成される
   → API Key が submit 用に割り当てられる

7. 提出サマリーが表示される:
   ASC App ID:                 <数字>
   App Store Connect API Key:  <Key Name / Key ID>
   Build:                      <Build ID / Date / Version / Build Number>

8. Submission スケジュール → 自動で開始
   → "Submitting your app to Apple App Store Connect: submission in progress"
   → 完了まで数分待つ
```

### 提出後の確認

```bash
# 提出状況の確認
eas submit:list --platform ios --limit 1
```

提出完了後、App Store Connect で処理されるまで数分〜数十分かかる。
処理が完了すると、TestFlight タブにビルドが表示される。

### TestFlight でテスターに配布

1. [App Store Connect](https://appstoreconnect.apple.com) にログイン
2. アプリ → TestFlight タブ
3. 「コンプライアンス情報」を入力（暗号化: いいえ）
4. 内部テスター: 自動で配布される（チームメンバー最大100人）
5. 外部テスター: グループ作成 → テスター追加 → Apple の審査後に配布

### submit profile で ascAppId を設定（2回目以降の高速化）

初回 submit 後、`eas.json` に `ascAppId` を追加するとログイン不要になる:

```json
{
  "submit": {
    "production": {
      "ios": {
        "ascAppId": "<ASC App ID の数字>"
      }
    }
  }
}
```

### よくあるエラー

| エラー | 原因 | 対処 |
|--------|------|------|
| `No builds found` | ビルドが完了していない | `eas build:list` で状態確認 |
| `Selected build uses "production" but submit profile missing` | eas.json に submit profile がない | 無視して OK（デフォルト production が使われる）、または `submit.production` を追加 |
| `App Store Connect API error` | API Key 未設定または権限不足 | App Store Connect で API Key を確認 |
| `Missing compliance` | 暗号化の申告が未完了 | `ITSAppUsesNonExemptEncryption: false` を app.config.ts に設定 |
| Apple ID ログインループ | セッション切れ | キャッシュ削除: `rm -rf ~/.app-store/auth/<apple-id>/` |

---

## Step 4: App Store 提出

TestFlight で動作確認が取れたら、App Store に審査提出する。

### 前提条件

App Store Connect で以下が設定済みであること:

- アプリ情報（名前、説明、キーワード、カテゴリ）
- スクリーンショット（6.7" と 5.5" が最低限必要）
- アプリアイコン（1024x1024）
- プライバシーポリシー URL
- サポート URL

### 審査提出手順

1. [App Store Connect](https://appstoreconnect.apple.com) にログイン
2. アプリ → 「App Store」タブ
3. 新しいバージョンを作成（または既存バージョンを編集）
4. TestFlight で確認済みのビルドを選択
5. アプリ情報・スクリーンショットを入力
6. 「審査に提出」をクリック

### 審査の目安

- 初回審査: 1〜3 日程度
- アップデート審査: 数時間〜1 日程度
- リジェクトされた場合: 理由を確認して修正 → 再提出

### よくあるリジェクト理由

| 理由 | 対処 |
|------|------|
| クラッシュ / バグ | TestFlight で十分テストしてから提出 |
| 不完全なメタデータ | スクリーンショット・説明文・プライバシーポリシーを全て埋める |
| ログイン必要だがテストアカウント未提供 | 審査メモにテストアカウント情報を記載 |
| 課金がある場合の説明不足 | サブスクリプション説明・利用規約を明記 |
