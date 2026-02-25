# Dead Code Detection Patterns

## Pattern Reference

各パターンの詳細定義、grep コマンド例、コンテキスト判定基準を記載する。

---

## HIGH severity パターン

### P1: @deprecated アノテーション

**意味**: 非推奨マークが付いているが関数・クラスがまだ存在している状態。

**grep**:
```bash
grep -rn "@deprecated" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" \
  --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build \
  --exclude="*.d.ts" {TARGET_DIR}
```

**コンテキスト判定**:
- 関数本体が 1〜3 行で新 API へのデリゲートのみ → **削除推奨 (HIGH)**
- 関数本体に複雑なロジックあり → **移行計画を確認 (MEDIUM)**
- 呼び出し元が 0 件 → **安全に削除可能 (HIGH)**
- 呼び出し元が多数 → **段階的移行中の可能性 (MEDIUM)**

**実例** (miravy):
```ts
/** @deprecated Use canUse() instead */
export function canUseToday(user: UserProfile): boolean {
  return canUse(user); // 1行デリゲートのみ → 削除推奨
}
```

---

### P2: 空の catch ブロック（エラー握り潰し）

**意味**: 例外を捕捉するが何も処理しないか、コメントのみのブロック。

**grep** (空 catch を検出):
```bash
grep -rn -E -A5 "\} catch\b|\} catch \(" \
  --include="*.ts" --include="*.tsx" --include="*.js" \
  --exclude-dir=node_modules {TARGET_DIR}
```

**コンテキスト判定**:
- `catch { }` または `catch(e) { }` → **HIGH**
- `catch { // ignore }` や `catch { // noop }` (理由なし) → **HIGH**
- `catch { // Ignore duplicate emulator connection during hot reload }` (理由あり) → **MEDIUM**
- `catch(e) { console.log(...); }` → **LOW** (ログあり、ただし握り潰しに近い)
- `catch(e) { throw new Error(...); }` → **フラグなし** (正当なラッパー)

**正当なパターン例** (miravy):
```ts
try {
  connectAuthEmulator(auth, `http://${emulatorHost}:9099`, { disableWarnings: true });
} catch {
  // Ignore duplicate emulator connection errors during hot reload.
}
// → 理由コメントあり → MEDIUM に降格
```

---

### P3: コメントアウトされたコードブロック

**意味**: 削除すべきコードがコメントとして残っている状態。

**grep** (コメント行にコードキーワード):
```bash
grep -Ern "^\s*\/\/\s*(const|let|var|function|return|import|export|if|for|while|class)\s" \
  --include="*.ts" --include="*.tsx" --include="*.js" \
  --exclude-dir=node_modules {TARGET_DIR}
```

**コンテキスト判定**:
- 3行以上連続するコメントアウトコード → **HIGH**
- 1〜2行のコメントアウト → **MEDIUM** (意図的な無効化の可能性)
- コメント直前に `// TODO: restore when ...` がある → **MEDIUM** (意図的)
- テスト設定ファイル内 → **LOW** (デバッグ用無効化の可能性)

---

## MEDIUM severity パターン

### P4: チケット参照なし TODO/FIXME/HACK

**意味**: 技術的負債のマーカーだが、チケット/担当者/期限の参照がない。

**grep** (チケット参照なし):
```bash
grep -Ern "//\s*(TODO|FIXME|HACK|XXX)\b" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" \
  --exclude-dir=node_modules {TARGET_DIR}
```

**grep** (チケット参照あり - LOW に分類):
```bash
grep -Ern "//\s*(TODO|FIXME)\s*[A-Z][A-Z]*-[0-9]" \
  --include="*.ts" --include="*.tsx" --include="*.js" \
  --exclude-dir=node_modules {TARGET_DIR}
```

**コンテキスト判定**:
- `// TODO: fix this` (参照なし) → **MEDIUM**
- `// TODO(JIRA-123): fix when dep updated` → **LOW**
- `// HACK:` → **MEDIUM** (意図的な技術的負債の明示)
- `// FIXME:` → **MEDIUM** (バグ認識済みだが未修正)

---

### P5: `as any` 型アサーション（TypeScript）

**意味**: TypeScript の型システムを完全に無効化するキャスト。

**grep**:
```bash
grep -rn "\bas any\b" \
  --include="*.ts" --include="*.tsx" \
  --exclude="*.d.ts" \
  --exclude-dir=node_modules {TARGET_DIR}
```

**コンテキスト判定**:
- `(FirebaseAuth as any).getReactNativePersistence` (外部ライブラリ型不足) → **MEDIUM** (ライブラリ更新で解消可能)
- `(Constants.expoConfig?.extra as any)?.revenueCatApiKeyIOS` (設定オブジェクト) → **MEDIUM**
- `someVar as any as SomeType` (二重キャスト) → **HIGH** (型安全性が完全に失われる)
- `.d.ts` ファイル内 → **フラグなし** (型定義ファイルでは許容)

---

### P6: ハードコード localhost（テストコード外）

**意味**: 本番環境では動作しないハードコードされた開発用 URL。

**grep**:
```bash
grep -rn -E "http://localhost|http://127\.0\.0\.1" \
  --include="*.ts" --include="*.tsx" --include="*.js" \
  --exclude="*.test.*" --exclude="*.spec.*" \
  --exclude-dir=node_modules \
  --exclude-dir=__tests__ {TARGET_DIR}
```

**コンテキスト判定**:
- `connectAuthEmulator(auth, "http://127.0.0.1:9099")` (emulator 設定) → **INFO** (emulator ファイル内なら許容)
- `process.env.API_URL || "http://localhost:3000"` (フォールバック) → **HIGH** (本番で localhost が使われる)
- `fetch("http://localhost:8080/api/...")` (ハードコード) → **HIGH**

---

### P7: 環境変数のリテラルフォールバック

**意味**: 環境変数が未設定時にリテラル値にフォールバックする。本番設定漏れのリスク。

**grep**:
```bash
grep -rn "process\.env\.[A-Z_]* ||" \
  --include="*.ts" --include="*.tsx" --include="*.js" \
  --exclude-dir=node_modules {TARGET_DIR}
```

**コンテキスト判定**:
- `process.env.EXPO_PUBLIC_FIREBASE_EMULATOR_HOST || "127.0.0.1"` (emulator 専用ファイル) → **INFO**
- `process.env.API_BASE_URL || "https://api.example.com"` (本番 URL フォールバック) → **MEDIUM** (設定が必須かどうか確認)
- `process.env.SECRET_KEY || "dev-only-secret"` (シークレット系) → **HIGH** (本番で dev シークレットが使われる)

---

### P8: React Native web Platform 分岐

**意味**: Pure native アプリで web プラットフォームのブランチが存在する。

**grep**:
```bash
grep -rn "Platform\.OS\s*===\s*['\"]web['\"]" \
  --include="*.ts" --include="*.tsx" \
  --exclude-dir=node_modules {TARGET_DIR}
```

**コンテキスト判定**:
- Expo Router アプリで `Platform.OS === 'web'` → **MEDIUM** (Web サポートが明示されていなければ到達不能)
- `app.config.ts` に `web` platform の記述あり → **フラグなし** (Expo Web 対応プロジェクト)

---

## LOW severity パターン

### P9: @ts-ignore / @ts-expect-error

**意味**: TypeScript のエラーを強制的に抑制するコメント。

**grep**:
```bash
grep -rn -E "@ts-ignore|@ts-expect-error" \
  --include="*.ts" --include="*.tsx" \
  --exclude-dir=node_modules {TARGET_DIR}
```

**注意**: `@ts-expect-error` は意図的な型エラーを示すため、`@ts-ignore` より許容度が高い。
理由コメントがあれば acceptable。

---

### P10: eslint-disable コメント

**grep**:
```bash
grep -rn "eslint-disable" \
  --include="*.ts" --include="*.tsx" --include="*.js" \
  --exclude-dir=node_modules {TARGET_DIR}
```

理由コメントなしの `// eslint-disable-next-line no-console` は技術的負債の蓄積。

---

### P13: DUMMY_/MOCK_/FAKE_ プレフィックス変数（テスト値の本番残存）

**意味**: テスト・開発用のダミー値がテストファイル外に残っている状態。`DUMMY_FIREBASE_CONFIG` のようなパターンが本番コードに混入するリスク。

**grep**:
```bash
grep -Ern "\b(DUMMY_|MOCK_|FAKE_|TEST_)[A-Z_]*\s*=" \
  --include="*.ts" --include="*.tsx" --include="*.js" \
  --exclude-dir=node_modules \
  --exclude="*.test.*" --exclude="*.spec.*" \
  --exclude-dir=__tests__ {TARGET_DIR}
```

**コンテキスト判定**:
- テストファイル外で `DUMMY_` 等のプレフィックス変数が定義されている → **MEDIUM**
- `process.env.X ?? DUMMY_CONFIG` のようにフォールバックとして使われている → **HIGH**（本番で意図しない値が使われる）
- `__mocks__/` や `fixtures/` 内 → **誤検知**（テスト専用ディレクトリ）

---

## False Positive 除外ルール

### 常に除外するパス
```
node_modules/
.cache/
dist/
build/
.expo/
*.test.ts
*.test.tsx
*.spec.ts
*.spec.tsx
**/__tests__/**
*.d.ts (P1以外)
*.generated.ts
```

### コンテキストによる降格ルール

| パターン | 降格条件 | 降格後 |
|---------|---------|--------|
| catch {} | 理由コメント（`// Ignore because...`）あり | HIGH → MEDIUM |
| catch {} | console.log あり | HIGH → LOW |
| as any | .d.ts 内、または interop ファイル | MEDIUM → INFO |
| process.env fallback | emulator/dev 専用ファイル内 | MEDIUM → INFO |
| TODO/FIXME | チケット番号あり | MEDIUM → LOW |
| localhost | emulator 設定ファイル内 | MEDIUM → INFO |
