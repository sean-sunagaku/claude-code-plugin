# lt-ios-launch

50分のライブ登壇で、小さなローカルiOSアプリを要件確定から
Simulator・販促素材・プライバシー確認まで完走するための軽量Pluginです。

## Install

```bash
claude plugin marketplace add sean-sunagaku/claude-code-plugin --scope user
claude plugin marketplace update sunagaku-marketplace
claude plugin install lt-ios-launch@sunagaku-marketplace --scope user
```

実行中のClaude Codeでは `/reload-plugins` を実行するか、新しいセッションを
開始してください。

## Skills

- `lt-sprint-orchestrator`: 50分・3レーンの進行とフォールバック
- `product-sparring-lite`: 7分の壁打ちとスコープ固定
- `ios-design-handoff`: Claude DesignからSwiftUIへの実装仕様化
- `launch-lp-lite`: ローカル完結の体験型LP
- `aso-copy-lite`: 日本語App Storeメタデータ
- `simulator-screenshots`: Simulator実画面とストアカード
- `promo-video-lite`: 実スクショから15秒動画
- `ios-privacy-scan`: 通信・権限・依存・保存の静的検査

Claudeアプリへ個別に入れる `.skill` 配布物は、このPluginとは別系統です。
