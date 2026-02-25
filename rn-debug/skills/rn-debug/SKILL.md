---
name: rn-debug
description: >
  React Native (Expo) アプリの総合デバッグスキル。
  再レンダリング調査、白い画面、ネイティブモジュールエラー、Firebase接続問題、
  API通信エラーなどのトラブルシューティングを体系的に行う。
  Use when: 「白い画面」「画面が表示されない」「エラーが出る」「動かない」
  「接続できない」「400エラー」「タイムアウト」「再レンダリング」「重い」
  「カクつく」などの不具合報告やデバッグ依頼があったとき。
  Also use when: 「デバッグして」「原因調べて」「なぜ動かない」
  「エミュレータで確認して」「デバッグログを仕込んで」などの依頼があったとき。
---

# React Native (Expo) 総合デバッグガイド

---

## Part 1: 不具合の切り分けフロー

```
白い画面 or エラー
  ├─ 1. Metro ログを確認（import エラー? ネイティブモジュール?）
  ├─ 2. 初期 loading 状態が解消されるか確認（Auth 等）
  ├─ 3. ネイティブモジュールの問題か確認（Expo Go vs dev-client）
  └─ 4. Provider のクラッシュを切り分け
```

---

## Part 2: 白い画面のチェックリスト

### Firebase Auth（Firebase 使用時）

#### インポート不整合
- `firebase/auth` と `@firebase/auth` を**混在させると** onAuthStateChanged が発火しない
- バンドラーが別モジュールとして扱うため
- 確認方法:
```bash
grep -rn "@firebase/" src/
grep -rn "\"firebase/" src/
```
- 全て `firebase/auth` 等に統一すること

#### React Native での Auth 初期化
- `getAuth()` ではなく `initializeAuth` + `getReactNativePersistence(AsyncStorage)` が必要
- これがないと auth state がメモリのみになり、リスナーが正しく動かない
- ホットリロード対策で try/catch → `getAuth()` フォールバック:
```typescript
function resolveAuth(): Auth {
  try {
    return initializeAuth(app, {
      persistence: getReactNativePersistence(ReactNativeAsyncStorage)
    });
  } catch {
    return getAuth(app); // ホットリロード時
  }
}
```

### ネイティブモジュールの問題

- `RCTEventEmitter` エラー → ネイティブモジュール未登録
- Expo Go ではカスタムネイティブモジュールが動かない（dev-client が必要）
- 代表的な要 dev-client パッケージ:
  - `react-native-purchases` (RevenueCat)
  - `expo-apple-authentication`
  - `react-native-maps`
  - カスタムネイティブモジュール全般
- `npx expo start --dev-client` で起動すること
- ネイティブモジュール追加後は `npx expo prebuild` → `npx expo run:ios` でリビルド

### Provider のクラッシュ

- Provider 内でエラーが起きると子コンポーネントが全て描画されない
- 切り分け: Provider を一時的にコメントアウトして描画されるか確認
- ErrorBoundary で囲んでエラーを可視化する

---

## Part 3: Firebase Emulator 接続

### ホストアドレス
- iOS シミュレータ → `127.0.0.1` を使う
- Android エミュレータ → `10.0.2.2` を使う
- **Metro の IP（例: 172.20.10.3）をエミュレータホストに使わない**
- エミュレータは `localhost` で動いており、上記アドレスでホストマシンに到達可能

### 接続確認コマンド
```bash
# エミュレータ Hub が動いているか
curl -s http://127.0.0.1:4400/emulators

# 各エミュレータの確認
curl -s http://127.0.0.1:9099/  # Auth
curl -s http://127.0.0.1:8080/  # Firestore
curl -s http://127.0.0.1:9199/  # Storage
```

### Firestore 安定化
- React Native では `experimentalForceLongPolling: true` を設定
- WebChannel が React Native 環境で不安定なため
```typescript
const db = initializeFirestore(app, { experimentalForceLongPolling: true });
```

---

## Part 4: iOS シミュレータの制限事項

| 機能 | シミュレータ | 実機 |
|---|---|---|
| Apple Sign-In | 不可 | 可 |
| プッシュ通知 | 不可 | 可 |
| In-App Purchase | StoreKit Config 必要 | 可 |
| カメラ | 不可 | 可 |
| NFC | 不可 | 可 |
| Storage ACL（エミュレータ） | 無視（動作は正常） | 正常 |

---

## Part 5: EAS ローカルビルドで .env が読めない（起動即クラッシュ）

### 症状
- `eas build --local` で作った IPA/APK が起動直後にクラッシュする
- クラッシュログに `FirebaseError: auth/invalid-api-key` や TurboModule 変換エラーが出る
- ビルドログの `extra.firebase` が `{}` (空) になっている

### 原因
`eas build --local` は一時ディレクトリ（`/var/folders/.../eas-build-local-nodejs/.../build/mobile`）にプロジェクトをコピーして実行する。`.env` は通常 `.gitignore` 対象なのでコピーに含まれず、`app.config.ts` 実行時に `process.env.EXPO_PUBLIC_*` が全て `undefined` になる。

### 確認方法
```bash
# ビルドログから extra の中身を確認
rg '"extra"' .tmp_eas_preview_build_*.log
# → "firebase": {} なら .env が読まれていない
```

### 対策 1: .easignore で .env を同梱する
`.easignore` は `.gitignore` と同じ書式だが、EAS ビルド専用のファイル除外設定。`.gitignore` で `.env` を除外していても、`.easignore` に `.env` を書かなければ EAS ビルドには含まれる。

**重要: `.easignore` はリポジトリルートに置く。** EAS はアップロード tarball をリポジトリルートから作成する（`project/mobile/...` の形で梱包）。`mobile/.easignore` に置いても無視される。

```
# リポジトリルート/.easignore の例
node_modules/
.git/
tmp/
ios/
android/

# macOS メタデータ / エディタ一時ファイル（必須）
**/._*
**/*.swp
**/*.swo

# .env を明示的に含める（最後に書く）
!<app-dir>/.env
```

**注意**:
- `.easignore` が存在しない場合は `.gitignore` がそのまま使われるため、`.env` が除外される
- `.easignore` を明示的に作成すること
- モノレポ構成（ルートに `<app-dir>/` がある場合）では `!<app-dir>/.env` のようにルートからの相対パスで指定する
- `**/._*` と `**/*.swp` を必ず除外する（後述 Part 6 参照）

### 対策 2: ビルドスクリプトで環境変数を export する
`.easignore` が使えない場合や確実性を上げたい場合:

```json
{
  "build:preview": "bash -lc 'set -a; [ -f .env ] && source .env; set +a; eas build --profile preview --platform ios --local'"
}
```

- `source .env` だけでは**シェル変数**止まりで子プロセス（eas build）に渡らない
- `set -a` で `source` した変数を自動的に **環境変数として export** する
- `set +a` で自動 export を解除

### 対策 3: firebase.ts で未設定時にダミー config でフォールバック
万が一 env が空のまま起動しても即クラッシュしないよう、`resolveFirebaseConfig()` でバリデーション → ダミー config フォールバック → `console.warn` で警告を出す防御コードを入れる。

---

## Part 6: EAS ビルドの PREPARE_PROJECT tar エラー

### 症状
- `eas build --local` の `PREPARE_PROJECT` フェーズで tar 展開エラーが出る
- `Failed to restore metadata: File exists` のようなメッセージ

### 原因
macOS のメタデータファイル（`._*`）やエディタの swap ファイル（`*.swp`）がプロジェクトに残っていると、EAS が作成する `project.tar.gz` に混入する。tar 展開時にメタデータファイルと本体ファイルが衝突してエラーになる。

例:
```
app/(tabs)/._layout.tsx.swp   ← これが混入
app/(tabs)/_layout.tsx         ← 本体と衝突
```

### 確認方法
```bash
# プロジェクト内の不要ファイルを検索
find . -name '._*' -o -name '*.swp' -o -name '*.swo' | head -20
```

### 対策
1. 不要ファイルを削除:
```bash
find . -name '._*' -delete
find . -name '*.swp' -delete
find . -name '*.swo' -delete
```

2. ルートの `.easignore` と `.gitignore` の両方に除外ルールを追加:
```
**/._*
**/*.swp
**/*.swo
```

---

## Part 7: MobileMCP でのデバッグ

シミュレータの動作確認に MobileMCP を活用する:
1. `mobile_take_screenshot` — 画面状態を視覚的に確認
2. `mobile_list_elements_on_screen` — 要素の座標・ラベルを取得
3. `mobile_click_on_screen_at_coordinates` — ボタンタップ等の操作
4. `mobile_type_keys` — テキスト入力
5. `mobile_swipe_on_screen` — スクロール操作

---

## Part 8: 再レンダリング調査

### ワークフロー

1. **対象特定**: ユーザーから対象コンポーネント/画面を聞く
2. **コード読解**: 対象ファイルと関連する hooks/context を読む
3. **ログ挿入**: 以下のパターンに従いデバッグログを挿入
4. **ドキュメント調査**: 不明点は Context7 で最新ドキュメントを確認
5. **原因分析**: ログ出力結果からユーザーと共に原因を特定
6. **修正提案**: 修正案を提示（ログは除去）

### ログ挿入パターン

#### コンポーネント再レンダリング検出
```tsx
// === DEBUG: レンダリング検出 ===
const renderCount = React.useRef(0);
renderCount.current += 1;
console.log(`[RENDER] ComponentName #${renderCount.current}`, { props });
```

#### Props/State 変化追跡
```tsx
// === DEBUG: Props変化追跡 ===
const prevProps = React.useRef(props);
React.useEffect(() => {
  const changed = Object.entries(props).filter(
    ([key, val]) => prevProps.current[key as keyof typeof props] !== val
  );
  if (changed.length > 0) {
    console.log('[PROPS CHANGED] ComponentName:', changed.map(([k]) => k));
  }
  prevProps.current = props;
});
```

#### useEffect 実行追跡
```tsx
React.useEffect(() => {
  console.log('[EFFECT] effectName fired', { dep1, dep2 });
  return () => console.log('[EFFECT CLEANUP] effectName');
}, [dep1, dep2]);
```

#### Context 伝播追跡
```tsx
const value = { key1, key2 };
console.log('[CONTEXT] ProviderName value identity changed?',
  Object.is(prevValue.current, value));
```

#### Firebase リスナー再登録検出
```tsx
React.useEffect(() => {
  console.log('[LISTENER] registering', collectionPath);
  const unsub = onSnapshot(query, (snap) => {
    console.log('[LISTENER] snapshot received', snap.size, 'docs');
  });
  return () => { console.log('[LISTENER] unsubscribing', collectionPath); unsub(); };
}, [deps]);
```

### ログの命名規則

| プレフィックス | 用途 |
|---|---|
| `[RENDER]` | コンポーネントレンダリング |
| `[PROPS CHANGED]` | props の変化 |
| `[STATE]` | state の変化 |
| `[EFFECT]` | useEffect 実行 |
| `[EFFECT CLEANUP]` | useEffect クリーンアップ |
| `[CONTEXT]` | Context value 変化 |
| `[LISTENER]` | リスナー登録/解除 |
| `[HOOK]` | カスタムフック呼び出し |
| `[MEMO]` | useMemo/useCallback の再計算 |

### ログ挿入時の注意
- `// === DEBUG:` で始めて `===` で終わるコメントで囲む（grep で一括除去可能）
- 本番コードへの影響を最小限にする（ロジック変更しない）

### ログ一括除去
```bash
grep -rn "// === DEBUG" src/ app/
```

### よくある再レンダリング原因
詳細は [references/rerender-causes.md](references/rerender-causes.md) を参照。
