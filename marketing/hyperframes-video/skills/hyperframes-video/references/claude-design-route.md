# Claude Design ルート

ビジュアルの方向性がまだ無いとき、Claude Design に第一稿を作らせて
Claude Code で仕上げる。**Design が初号編集、Code が編集室**という分担になる。

Claude Design が強いのは、ブランドの見た目（配色・書体・トーン）を素材から起こすことと、
シーンごとのレイアウトと文言。弱いのは通し再生を見ながらの詰め — そこは Claude Code が引き取る。

## 2つのルートの選び方

Claude Design から HyperFrames へは2経路ある。**先にどちらか決める。**
指示ファイルが別で、書き方のルールも違う。混ぜると精度が落ちる。

| | Download-ZIP | Send to HyperFrames |
|---|---|---|
| 受け取る形 | 複数ファイルの ZIP（`index.html` / `preview.html` / `README.md` / `DESIGN.md`） | 単一の自己完結 HTML |
| 渡り方 | 自分で ZIP をダウンロード | HeyGen がその HTML を取得 |
| アセット | 相対パスで隣のファイルを参照してよい | すべて `data:` URI か公開 URL。相対パスは届かない |
| 次の工程 | ローカルで仕上げ、CLI で render | HyperFrames 上で強化（SE・BGM）、クラウドで render |
| 費用 | ローカル完結 | import は無料、強化は有料 |

**このリポジトリの既定は Download-ZIP。** Claude Code で仕上げて `npx hyperframes render` する
前提と噛み合う。Send-to は HeyGen アカウントと有料ステップが要る。

## Download-ZIP の手順

### 1. 指示ファイルを入手する

[`docs/guides/claude-design-hyperframes.md`](https://github.com/heygen-com/hyperframes/blob/main/docs/guides/claude-design-hyperframes.md)
を GitHub の download ボタンで保存する。

### 2. claude.ai/design で新規チャットを開く

### 3. ファイルを添付して、作りたいものを書く

**URL を貼らずにファイルを添付する。** 添付なら細部が保たれるが、
URL 経由だとルールの取りこぼしが増えると公式が明言している。

一緒に渡すもの:

- アプリのスクリーンショット（`simulator-screenshots` の出力）
- ロゴ・アイコン
- 配色と書体（`app-tone-manner` の成果物があればそれ）
- 実際の数値・機能名・コピー（作らせない。こちらで用意する）

依頼文には尺・比率・訴求を明記する。ブリーフが薄いと Claude Design は
質問を1つ返してくるので、そこで答えれば進む。

### 4. ZIP を受け取る

`index.html` / `preview.html` / `README.md` / `DESIGN.md` が入っている。
テンプレート先行の作りなので、`npx hyperframes lint` がエラー0で通る状態で届く。

### 5. Claude Code で仕上げる

```bash
npx hyperframes skills update   # 未導入なら
npx hyperframes lint            # まずエラー0を確認
npx hyperframes preview         # 通しで見る
```

ここからが Claude Code の仕事。**作り直さない。** やるのは詰めだけ:

| 見て気づくこと | 手当て |
|---|---|
| 動きが硬い / 緩い | イージングの差し替え（`power3.out` → `expo.out` など） |
| 要素の出方が散らかる | スタガーの間隔調整（0.12 → 0.08） |
| そのシーンが間延びする | `data-duration` を詰める。後続の `data-start` と root の `data-duration` も連動して直す |
| シーンが静止画に見える | シーン中の継続的な動きを足す（カウンター、ゆっくりズーム、グロウの明滅） |
| 場面転換の強弱が単調 | シェーダートランジションの位置と種類を変える |

尺を変えたら **シーンは隙間なく端から端まで**という契約を必ず維持する
（[composition-contract.md](composition-contract.md) 参照）。

### 6. Step 4 の検証ゲートへ

`lint` → `inspect` → `snapshot` → `render`。ルート A と同じ。

## Send to HyperFrames を選ぶ場合

指示ファイルが別。
[`docs/guides/claude-design-send-to-hyperframes.md`](https://github.com/heygen-com/hyperframes/blob/main/docs/guides/claude-design-send-to-hyperframes.md)
を添付する。ZIP 版の指示ファイルを使うと精度が落ちる。

守ること:

- 出力は **1枚の HTML**。CSS も含めて全部その中
- フォントは `@font-face` に base64 の `data:` URI で埋める。
  Google Fonts の `<link>` は使わない（読み込まれず system font に落ちてブランドが消える）
- 画像・ロゴも `data:` URI。大きすぎるものだけ公開 URL
- 署名付き URL、期限切れするホスト、相対パスは使わない — レンダリング時に 404 になる
- ランタイム（HyperFrames / GSAP / シェーダー）だけは CDN 参照のまま。inline しない
- ローダーで包まれた成果物は import が弾く。実 DOM に中身がある生の HTML を送る

## どちらのルートでも守ること

- **実物を使う。** プレースホルダ画像、ロレム・イプサム、それらしい数値は入れない
- **具体を薄めない。** 実際の指標（例: 特定の処理件数）を「高速」のような一般語に
  言い換えない。機能名も固有名のまま残す
- **無い事実を足さない。** ブランドが出していないコピーや数字を作らない

ここは Claude Design 側にも明示的に指示する。放っておくと、
それらしく埋めてしまうことがある。
