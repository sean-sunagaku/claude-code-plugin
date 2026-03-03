# Cruft Code Sweep レポートテンプレート

## 使用ガイドライン

このテンプレートを使い、監査結果を一貫したフォーマットで出力する。
空の severity セクションは省略しても良い。

---

## テンプレート

```markdown
# Cruft Code Sweep レポート

**監査対象**: {TARGET_DIR}
**実行日時**: {DATE}
**対象言語**: {LANGUAGES}
**フレームワーク固有パターン**: {FRAMEWORK_PATTERNS_INCLUDED: yes/no}

## サマリー

| Severity | 件数 | 推定行数 |
|----------|------|---------|
| HIGH     | N    | 〜N行   |
| MEDIUM   | N    | 〜N行   |
| LOW      | N    | 〜N行   |
| **合計** | **N** | **〜N行** |

優先対応: [HIGH 件数が多い場合は具体的な優先項目を 1〜2 文で]

---

## HIGH（要対応）

### @deprecated 関数の残存 (P1)

- `mobile/src/hooks/useUsageLimit.ts:42`
  ```ts
  /** @deprecated Use canUse() instead */
  export function canUseToday(user: UserProfile): boolean {
    return canUse(user);
  }
  ```
  - 呼び出し元: 0件（grep で確認）
  - git 履歴: 2024-03-15 追加、以降変更なし（staleness: HIGH）
  - 安全性判定: SAFE（参照 0 件、副作用なし）
  - **推奨**: 関数を削除する（安全に削除可能）

### [パターン名] (P番号)

- `path/to/file.ts:行番号` - [1行説明]
  - git 履歴: [最終更新日、staleness_score]
  - 安全性判定: [SAFE / LIKELY_SAFE / RISKY / KEEP]
  - **推奨**: [具体的なアクション]

---

## MEDIUM（要確認）

### as any 型アサーション (P5)

- `mobile/src/services/firebase.ts:42`
  ```ts
  const getReactNativePersistence = (FirebaseAuth as any).getReactNativePersistence
  ```
  - 背景: firebase-js-sdk の型定義不足による回避策
  - **推奨**: firebase-js-sdk の最新バージョンで型が追加されているか確認

### 環境変数フォールバック (P7)

- `mobile/src/services/firebase.ts:83`
  ```ts
  const emulatorHost = process.env.EXPO_PUBLIC_FIREBASE_EMULATOR_HOST || "127.0.0.1"
  ```
  - 背景: emulator 設定専用コード（useEmulator フラグで保護済み）
  - **推奨**: 現状維持で可（emulator 専用コードのため）

---

## LOW（情報）

### eslint-disable コメント (P10)

- `mobile/src/services/firebase.ts:79`
  ```ts
  // eslint-disable-next-line no-var
  var __miravyFirebaseEmulatorConnected: boolean | undefined;
  ```
  - 背景: グローバル変数宣言のための必要な抑制
  - **推奨**: 理由コメントを追加して意図を明示

---

## 除外した項目（false positive）

以下は検出されたが、正当なコードと判断して除外した:

1. `firebase.ts` の hot-reload 用 try/catch × 3件
   - 理由: コメントで明示された hot reload 対策（emulator 接続の重複防止）

---

## 次のアクション

1. **今週**: HIGH 件数を対処
   - `canUseToday()` 関数の削除（呼び出し元 0件確認済み）
   
2. **次スプリント**: MEDIUM を確認・対処
   - firebase-js-sdk バージョンアップで `as any` が不要になるか確認
   
3. **定期メンテ**: LOW は次回リファクタリングタイミングで
   - eslint-disable コメントに理由コメントを追加
```

---

## 出力のコツ

- **コードスニペットは最小限**に（3〜5行程度）
- **推奨アクションは具体的**に（「確認してください」ではなく「削除する」「関数Xに置き換える」）
- **false positive を明示**することで信頼性が上がる
- **呼び出し元の件数**は grep で確認してから報告する
- **git 履歴情報**（最終更新日、staleness_score）を各候補に含める
- **安全性判定**（SAFE/LIKELY_SAFE/RISKY/KEEP）を明記し、判定根拠を簡潔に記載する
