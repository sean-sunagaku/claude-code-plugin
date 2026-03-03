# Framework-Specific Dead Code Patterns

汎用パターン ([patterns.md](patterns.md)) に加えて、フレームワーク固有のパターンを検出するための拡張パターン集。

---

## React Native / Expo

### RN-01: Hot Reload 用 already-initialized try/catch

**意味**: Firebase/SDK の二重初期化エラーを握り潰す開発時ワークアラウンド。

**grep**:
```bash
grep -rn -E "already.initialized|already-initialized" \
  --include="*.ts" --include="*.tsx" \
  --exclude-dir=node_modules {TARGET_DIR}
```

**判定**: このパターンは hot reload 対策として**有効**（削除不可）。
ただし理由コメントがない場合は MEDIUM（コメント追加を推奨）。

---

### RN-02: __DEV__ チェックなし Expo Go ワークアラウンド

**grep**:
```bash
grep -rn -E "__DEV__\s*&&|Constants\.isDevice" \
  --include="*.ts" --include="*.tsx" \
  --exclude-dir=node_modules {TARGET_DIR}
```

**判定**: `!Constants.isDevice` + `__DEV__` の組み合わせはシミュレータ限定コードの可能性。
dev-client 移行後は不要になることがある。

---

### RN-03: Android 向けのみの分岐（iOS専用アプリ）

**grep**:
```bash
grep -rn "Platform\.OS\s*===\s*['\"]android['\"]" \
  --include="*.ts" --include="*.tsx" \
  --exclude-dir=node_modules {TARGET_DIR}
```

**判定**: iOS 専用アプリで android 分岐が `null` や `undefined` を返す場合は到達不能コード。
eas.json の `platforms` 設定を確認して判断する。

---

### RN-04: 旧 StyleSheet API

**grep**:
```bash
grep -rn "StyleSheet\.flatten\b" \
  --include="*.ts" --include="*.tsx" \
  --exclude-dir=node_modules {TARGET_DIR}
```

---

## Firebase

### FB-01: Legacy Firestore API（v8 スタイル）

**意味**: Firestore v9 以降で非推奨になったチェーン API。

**grep**:
```bash
grep -rn -E "\.collection\(|\.doc\(|\.where\(|\.orderBy\(|\.limit\(|\.get\(\)" \
  --include="*.ts" --include="*.tsx" \
  --exclude-dir=node_modules {TARGET_DIR}
```

**判定**: `firebase/firestore` の v9 モジュラー API（`collection()`, `doc()`, `query()` 等）への移行推奨。
ただしクライアント SDK v8 と Firebase Admin SDK の構文が異なるため、ファイルパスで判断する。

---

### FB-02: Firebase Auth インポート混在

**意味**: `firebase/auth` と `@firebase/auth` を混在インポートすると auth state が壊れる。

**grep**:
```bash
grep -rn -E "from '@firebase/auth'|from \"@firebase/auth\"" \
  --include="*.ts" --include="*.tsx" \
  --exclude-dir=node_modules {TARGET_DIR}
```

**判定**: `@firebase/auth` のインポートがあれば **HIGH**（auth state 不具合の原因になる）。

---

### FB-03: Cloud Functions タイムアウトデフォルト値

**意味**: 画像生成等の長時間処理でデフォルト60秒のままになっている。

**grep**:
```bash
grep -rn -E "exports\.|onRequest|onCall" \
  --include="*.ts" \
  --exclude-dir=node_modules functions/src/ 2>/dev/null | \
  grep -vE "timeoutSeconds|runWith"
```

---

## Node.js

### NODE-01: CommonJS require() in ESM ファイル

**grep**:
```bash
grep -rn "require(['\"]" \
  --include="*.ts" --include="*.mjs" \
  --exclude-dir=node_modules {TARGET_DIR}
```

**判定**: TypeScript で `require()` が残っている場合は CommonJS 互換コードの混在の可能性。

---

### NODE-02: Deprecated Buffer コンストラクタ

**grep**:
```bash
grep -rn "new Buffer(" \
  --include="*.ts" --include="*.js" \
  --exclude-dir=node_modules {TARGET_DIR}
```

**判定**: `new Buffer()` は Node.js 6+ で非推奨。`Buffer.from()` / `Buffer.alloc()` に置き換える。

---

### NODE-03: Callback スタイル API（Promise 化推奨）

**grep**:
```bash
grep -rn -E "\.readFile\(.*function|\.writeFile\(.*function|\.exists\(.*function" \
  --include="*.ts" --include="*.js" \
  --exclude-dir=node_modules {TARGET_DIR}
```

---

## Python

### PY-01: パフォーマンスフォールバック（ujson/orjson）

```bash
grep -n -E "except.*ImportError|except ImportError" \
  --include="*.py" {TARGET_DIR}
```

---

### PY-02: Python バージョンチェック

```bash
grep -n "sys\.version_info" \
  --include="*.py" {TARGET_DIR}
```

**判定**: 最小サポートバージョン以下の分岐は削除可能。

---

## 使用方法

ユーザーが「React Native のパターンも含めて監査してほしい」と言った場合:
1. 汎用パターン（patterns.md の P1〜P12）を実行
2. このファイルの RN-01〜RN-04、FB-01〜FB-03 を追加で実行
3. 結果をマージしてレポートに出力
