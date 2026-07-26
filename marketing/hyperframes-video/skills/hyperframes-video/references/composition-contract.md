# composition の構造契約

HyperFrames が MP4 に焼けるのは、この契約を満たした HTML だけ。
`npx hyperframes lint` はここを検査している。

## 最小構成

```html
<div id="stage"
     data-composition-id="main"
     data-width="1080"
     data-height="1920"
     data-duration="12">

  <section class="scene clip" data-start="0" data-duration="4">
    <div class="scene-content">
      <h1 id="hook">見出し</h1>
    </div>
  </section>

  <section class="scene clip" data-start="4" data-duration="4">
    <div class="scene-content">
      <img id="shot" src="assets/play.png" alt="">
    </div>
  </section>

  <section class="scene clip" data-start="8" data-duration="4">
    <div class="scene-content">
      <p id="cta">CTA</p>
    </div>
  </section>

  <script src="https://cdn.jsdelivr.net/npm/gsap@3/dist/gsap.min.js"></script>
  <script>
    const tl = gsap.timeline({ paused: true });
    tl.from("#hook", { opacity: 0, y: 40, duration: 0.8 }, 0);
    tl.from("#shot", { opacity: 0, scale: 0.94, duration: 0.9 }, 4);
    tl.from("#cta",  { opacity: 0, y: 24, duration: 0.7 }, 8);

    window.__timelines = window.__timelines || {};
    window.__timelines.main = tl;
  </script>
</div>
```

## root に必須の属性

| 属性 | 要件 |
|------|------|
| `data-composition-id` | composition の識別子。timeline のキーと**完全一致**させる |
| `data-width` / `data-height` | 数値。単位なし |
| `data-duration` | 数値（秒）。全体の尺 |
| `data-start` | 開始位置。通常 `0` |
| `data-fps` | 任意。省略時は render 側の `--fps` に従う |

数値であることが条件。`"1080px"` のような文字列は弾かれる。

## シーンに必須の属性

| 属性 | 要件 |
|------|------|
| `data-start` | そのシーンの開始秒 |
| `data-duration` | そのシーンの長さ（秒） |
| `data-track-index` | 任意。メディアの重ね順を制御するとき |

**シーンは隙間なく端から端まで並べる。** 合計が root の `data-duration` と一致すること。
`0-4`, `4-8`, `8-12` のように前のシーンの終端が次の始端になる。
`0-4`, `5-9` のような空白は不正。

## timeline の登録

```js
window.__timelines["<data-composition-id と同じ値>"] = tl;
```

3つの条件を満たすこと:

1. **paused** — `gsap.timeline({ paused: true })`。再生を駆動するのはレンダラー側
2. **同期的に構築** — 読み込み時に組み上がっていること。`await` や `setTimeout` の中で
   組むと、レンダラーが seek する時点で存在せず空フレームになる
3. **seek 可能** — GSAP の他に CSS Animation / WAAPI / Lottie / Three.js も使えるが、
   いずれも「任意の時刻へ seek して同じ絵になる」ことが条件

`play()`、`requestAnimationFrame` による自前ループ、`Date.now()` に依存した演出は
すべて決定論を壊す。時間は必ずタイムラインの座標で表現する。

## 尺とシーン数の目安

| 種類 | 解像度 | 尺 | シーン数 |
|------|--------|-----|----------|
| SNS リール | 1080×1920 (9:16) | 10〜15秒 | 5〜7 |
| ローンチ告知 | 1920×1080 (16:9) | 8〜25秒 | 5〜10 |
| 機能説明 | 1920×1080 (16:9) | 30〜60秒 | 10〜18 |
| シネマティック | 1920×1080 (16:9) | 45〜90秒 | 7〜12 |

シーンが少なすぎると間延びし、多すぎると1シーンあたりが読めない尺になる。
1シーンは最低でも 1.5 秒、テキストを読ませるなら 2.5 秒以上。

## アセットの扱い

- ローカルプロジェクト（CLI で render する）なら相対パスで参照してよい
- フォントは `@font-face` で読み込む。ブランド書体を使わないと見た目が崩れる
- 外部 CDN は render 時に取得される。取得できない URL は空フレームになる
- 署名付き URL や期限切れするホストは使わない

## よくある失敗

| 症状 | 原因 |
|------|------|
| 全フレームが空 | timeline が非同期に構築されている / composition id が不一致 |
| 冒頭だけ正しく以降が静止 | `paused: true` を付けていない |
| シーンが飛ぶ | `data-start` と `data-duration` に隙間がある |
| 文字が切れる | `inspect` を回していない。CSS のはみ出し |
| 書体が違う | `@font-face` の読み込み前にフレームが撮られている |
