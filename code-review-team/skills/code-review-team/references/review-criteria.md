# Review Criteria Reference

## Severity Levels

| Level | 意味 | 対応 |
|-------|------|------|
| Critical | バグ、セキュリティ脆弱性、データ破損リスク | 即座に修正必須 |
| Warning | 設計問題、パフォーマンスリスク、ベストプラクティス違反 | 修正推奨 |
| Info | スタイル改善、リファクタリング提案、ドキュメント不足 | 任意 |

## Backend Review Criteria

### API Design
- RESTful 原則に従っているか
- HTTP メソッドの適切な使用（GET=読み取り, POST=作成, PUT=更新, DELETE=削除）
- ステータスコードの正確性（200, 201, 400, 401, 403, 404, 500）
- レスポンス形式の一貫性

### Database
- Drizzle ORM のパターン準拠
- schema.ts 変更時のマイグレーション生成（CLAUDE.md ルール）
- nullable/optional の型整合性チェーンl: schema → API → frontend
- N+1 クエリの回避

### Error Handling
- try-catch の適切な粒度
- エラーメッセージの情報量（デバッグに十分 / 本番で安全）
- 外部サービスエラーのハンドリング

## Frontend Review Criteria

### Component Design
- 単一責任の原則
- Props の最小化（必要なものだけ）
- 制御コンポーネント vs 非制御コンポーネント
- メモ化の必要性（useMemo, useCallback, React.memo）

### State Management
- 状態の最小化（派生状態は計算で得る）
- 状態の適切なスコープ（ローカル vs グローバル）
- 非同期状態の管理（loading, error, data）

### i18n Checklist
- ハードコード文字列なし
- ja.json と en.json の両方にキーが存在
- 動的値の国際化（数値フォーマット、日付フォーマット）
- キー名の一貫性（dot notation: `section.subsection.key`）

## Security Review Criteria

### OWASP Top 10 (Web)
1. Injection（SQL, Command, Path）
2. Broken Authentication
3. Sensitive Data Exposure
4. XXE
5. Broken Access Control
6. Security Misconfiguration
7. XSS
8. Insecure Deserialization
9. Using Components with Known Vulnerabilities
10. Insufficient Logging & Monitoring

### Code Patterns to Flag
- `eval()`, `Function()`, `new Function()`
- `dangerouslySetInnerHTML`
- `child_process.exec()` with user input
- Hardcoded secrets, API keys
- `sql.raw()` with string interpolation
- Missing CSRF protection
- Missing rate limiting on auth endpoints

## UX Review Criteria

### Interaction Design
- フィードバックの即時性（< 100ms for UI response）
- ローディング表示（> 300ms の処理）
- エラーリカバリ（ユーザーが次に何をすべきか明確）
- 操作の取り消し可能性

### Accessibility (WCAG 2.1 AA)
- カラーコントラスト比 4.5:1 以上
- フォーカス可視性
- スクリーンリーダー対応（aria-label, role）
- キーボードのみで操作可能

## Test Review Criteria

### Coverage
- 新規/変更ロジックにテストがあるか
- エッジケース（null, 空, 境界値）
- エラーパスのテスト
- 非同期処理のテスト

### Quality
- テスト名が「何をテストしているか」を表す
- AAA パターン（Arrange-Act-Assert）
- テストの独立性
- 適切なモック使用
