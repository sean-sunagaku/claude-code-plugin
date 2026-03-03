# Development

CI/CD・データベース管理・Gitワークフロー・デバッグ・テスト・デプロイ

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| **git-workflow** | `/git-workflow` | ブランチ作成、Conventional Commits コミット、PR 作成までの Git ワークフローを自動化 |
| **ci-check** | `/ci-check` | .github/workflows/*.yml を自動解析し、CI 定義のチェックをローカル実行する汎用スキル。エラーがあれば修正する |
| **spec-test** | `/spec-test` | 仕様駆動設計。仕様書からクラス責務を分析し、純粋関数を特定、テストファーストで単体テストを設計する |
| **database** | `/database` | Drizzle ORM を使ったデータベーススキーマの管理とマイグレーションガイド |
| **eas-deploy** | `/eas-deploy` | Expo (EAS) iOS/Android アプリのデプロイ自動化。App ID 登録、証明書・プロビジョニングプロファイル作成、EAS ビルド、TestFlight 配布、App Store 提出までを CLI から実行する |
| **ci-fix** [Beta] | `/ci-fix` | GitHub Actions の CI 失敗を自動検出・ログ取得・修正・再検証するスキル。gh コマンドで PR のチェック状況を監視し、失敗時はログを分析してコードを修正、push 後に再度 CI を確認するループを回す |
| **rn-debug** | `/rn-debug` |  React Native (Expo) アプリの総合デバッグスキル。 再レンダリング調査、白い画面、ネイティブモジュールエラー、Firebase接続問題、 API通信エラーなどのトラブルシューティングを体系的に行う。 Use when: 「白い画面」「画面が表示されない」「エラーが出る」「動かない」 「接続できない」「400エラー」「タイムアウト」「再レンダリング」「重い」 「カクつく」などの不具合報告やデバッグ依頼があったとき。 Also use when: 「デバッグして」「原因調べて」「なぜ動かない」 「エミュレータで確認して」「デバッグログを仕込んで」などの依頼があったとき。 ├─ 1. Metro ログを確認（import エラー? ネイティブモジュール?） ├─ 2. 初期 loading 状態が解消されるか確認（Auth 等） ├─ 3. ネイティブモジュールの問題か確認（Expo Go vs dev-client） └─ 4. Provider のクラッシュを切り分け |

### git-workflow

ブランチ作成、Conventional Commits コミット、PR 作成までの Git ワークフローを自動化

ブランチ作成 → コミット → PR作成 までのGitワークフローを支援する。

```
/git-workflow
```

### ci-check

.github/workflows/*.yml を自動解析し、CI 定義のチェックをローカル実行する汎用スキル。エラーがあれば修正する

`.github/workflows/*.yml` を解析し、CI 定義のチェックをローカル実行する。

```
/ci-check
```

### spec-test

仕様駆動設計。仕様書からクラス責務を分析し、純粋関数を特定、テストファーストで単体テストを設計する

仕様書を受け取り、**テストファースト**でクラス設計と単体テストを設計し、**既存のPlanドキュメントに自動追記**するスキル。

```
/spec-test
```

### database

Drizzle ORM を使ったデータベーススキーマの管理とマイグレーションガイド

Drizzle ORM を使ったデータベーススキーマの管理とマイグレーションに関するガイド。

```
/database
```

### eas-deploy

Expo (EAS) iOS/Android アプリのデプロイ自動化。App ID 登録、証明書・プロビジョニングプロファイル作成、EAS ビルド、TestFlight 配布、App Store 提出までを CLI から実行する

任意の Expo プロジェクトの iOS/Android デプロイを CLI から自動実行する。

```
/eas-deploy
```

### ci-fix [Beta]

GitHub Actions の CI 失敗を自動検出・ログ取得・修正・再検証するスキル。gh コマンドで PR のチェック状況を監視し、失敗時はログを分析してコードを修正、push 後に再度 CI を確認するループを回す

CI 失敗の検出 → ログ取得 → 修正 → push → 再検証のループを自動実行する。

```
/ci-fix
```

### rn-debug

 React Native (Expo) アプリの総合デバッグスキル。 再レンダリング調査、白い画面、ネイティブモジュールエラー、Firebase接続問題、 API通信エラーなどのトラブルシューティングを体系的に行う。 Use when: 「白い画面」「画面が表示されない」「エラーが出る」「動かない」 「接続できない」「400エラー」「タイムアウト」「再レンダリング」「重い」 「カクつく」などの不具合報告やデバッグ依頼があったとき。 Also use when: 「デバッグして」「原因調べて」「なぜ動かない」 「エミュレータで確認して」「デバッグログを仕込んで」などの依頼があったとき。 ├─ 1. Metro ログを確認（import エラー? ネイティブモジュール?） ├─ 2. 初期 loading 状態が解消されるか確認（Auth 等） ├─ 3. ネイティブモジュールの問題か確認（Expo Go vs dev-client） └─ 4. Provider のクラッシュを切り分け

---

```
/rn-debug
```

---

[< Back to top](../README.md)
