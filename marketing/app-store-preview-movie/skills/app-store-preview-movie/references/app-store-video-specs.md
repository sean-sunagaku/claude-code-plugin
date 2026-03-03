# App Store / Google Play プレビュー動画仕様

## App Store プレビュー動画仕様（Apple）

### 基本要件

| 項目 | 仕様 |
|---|---|
| 長さ | **15〜25秒**（最大25秒） |
| フォーマット | .mov, .m4v, .mp4 |
| 最大ファイルサイズ | 500MB |
| 枚数 | 最大 3 本 |

### 動画コーデック

| 項目 | 仕様 |
|---|---|
| 映像コーデック | H.264 または ProRes 422 (HQ only) |
| フレームレート | 最大 30fps |
| ビットレート（H.264） | 10〜12 Mbps 推奨 |

### 音声コーデック

| 項目 | 仕様 |
|---|---|
| 音声コーデック | AAC |
| チャンネル | ステレオ |
| ビットレート | 256 kbps |
| サンプルレート | 44.1 kHz または 48 kHz |

### 解像度（iPhone）

| デバイス | 解像度 | アスペクト比 |
|---|---|---|
| iPhone 6.9" (iPhone 16 Pro Max) | 886 × 1920 | 9:19.5 |
| iPhone 6.7" (iPhone 15 Plus) | 886 × 1920 | 9:19.5 |
| iPhone 6.5" (iPhone 11 Pro Max) | 886 × 1920 | 9:19.5 |
| iPhone 5.5" (iPhone 8 Plus) | 900 × 1600 | 9:16 |

> 注: 最も大きいサイズ（886×1920）を提出すれば小さいサイズにも使用可能

### 解像度（iPad）

| デバイス | 解像度 |
|---|---|
| iPad Pro 13" | 1200 × 1600 |
| iPad Pro 12.9" | 1200 × 1600 |

### コンテンツガイドライン

- **アプリの実際の体験**を表示すること（フェイクUI・架空シナリオ禁止）
- 最初の数秒が最重要（ユーザーはスキップする）
- テキスト・グラフィックスで機能説明を補足してよい
- **ナレーションはデフォルトミュート**（字幕推奨）
- Apple のハードウェア・UI フレームを使用可能
- 価格や購入特典の宣伝禁止
- 成人向けコンテンツ禁止

### Remotion での実装解像度

| 用途 | width × height | fps |
|---|---|---|
| iPhone 縦向き（主流） | 886 × 1920 | 30 |
| iPhone 横向き | 1920 × 886 | 30 |
| iPad 縦向き | 1200 × 1600 | 30 |

---

## Google Play プレビュー動画仕様

### 基本要件

| 項目 | 仕様 |
|---|---|
| 長さ | 30秒〜2分 |
| フォーマット | YouTube URL を使用（直接アップロード不可） |
| 解像度 | 1080p 以上推奨 |
| アスペクト比 | 16:9 （横向きのみ） |

> Google Play は YouTube の動画URLを使うため、Remotion で作成後 YouTube にアップロードする

---

## Remotion プロジェクト構造

### 推奨ディレクトリ構造

```
{project-name}/
├── src/
│   ├── Root.tsx           # コンポジション定義
│   ├── index.ts           # エントリーポイント
│   ├── scenes/
│   │   ├── IntroScene.tsx     # オープニング
│   │   ├── Feature1Scene.tsx  # 機能1
│   │   ├── Feature2Scene.tsx  # 機能2
│   │   ├── Feature3Scene.tsx  # 機能3
│   │   └── OutroScene.tsx     # エンディング
│   ├── components/
│   │   ├── PhoneMockup.tsx    # デバイスフレーム
│   │   ├── Caption.tsx        # 字幕コンポーネント
│   │   ├── AnimatedText.tsx   # テキストアニメーション
│   │   └── Background.tsx     # 背景コンポーネント
│   └── constants/
│       ├── timing.ts          # タイミング定数
│       └── colors.ts          # カラー定数
├── package.json
└── remotion.config.ts
```

### Root.tsx テンプレート（25秒・30fps = 750フレーム）

```tsx
import { Composition } from "remotion";
import { AppPreview } from "./AppPreview";

export const RemotionRoot = () => {
  return (
    <Composition
      id="AppStorePreview"
      component={AppPreview}
      durationInFrames={750}  // 25秒 × 30fps（App Store 最大 25 秒）
      fps={30}
      width={886}
      height={1920}
      defaultProps={{
        appName: "MyApp",
        primaryColor: "#2563EB",
      }}
    />
  );
};
```

---

## 動画構成テンプレート

### 25秒動画（750フレーム・30fps）※ App Store 最大長

```
フレーム 0   〜 90   ( 0〜3秒)  : オープニング - アプリロゴ + キャッチコピー
フレーム 90  〜 270  ( 3〜9秒)  : 機能1 - 画面遷移アニメーション
フレーム 270 〜 450  ( 9〜15秒) : 機能2 - 操作デモ
フレーム 450 〜 600  (15〜20秒) : 機能3 - 結果表示
フレーム 600 〜 690  (20〜23秒) : ベネフィット訴求
フレーム 690 〜 750  (23〜25秒) : エンディング - CTA + ダウンロード誘導
```

### 15秒動画（450フレーム・30fps）

```
フレーム 0   〜 60   ( 0〜2秒)  : オープニング
フレーム 60  〜 180  ( 2〜6秒)  : 機能1
フレーム 180 〜 300  ( 6〜10秒) : 機能2
フレーム 300 〜 390  (10〜13秒) : ベネフィット
フレーム 390 〜 450  (13〜15秒) : エンディング
```

---

## Remotion アニメーションのベストプラクティス

### 必須ルール

1. **全アニメーションは `useCurrentFrame()` で制御**
   - CSS transitions / animations は禁止（レンダリング時に動かない）
   - Tailwind animation クラスは禁止

2. **秒数で考えて fps で掛け算**
   ```tsx
   const { fps } = useVideoConfig();
   const fadeIn = interpolate(frame, [0, 2 * fps], [0, 1], {
     extrapolateRight: "clamp",
   });
   ```

3. **常に `premountFor` を設定**
   ```tsx
   <Sequence from={60} durationInFrames={120} premountFor={30}>
     <Scene />
   </Sequence>
   ```

### トランジションパターン

```tsx
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { slide } from "@remotion/transitions/slide";

<TransitionSeries>
  <TransitionSeries.Sequence durationInFrames={270}>
    <Feature1Scene />
  </TransitionSeries.Sequence>
  <TransitionSeries.Transition
    presentation={slide({ direction: "from-right" })}
    timing={linearTiming({ durationInFrames: 20 })}
  />
  <TransitionSeries.Sequence durationInFrames={270}>
    <Feature2Scene />
  </TransitionSeries.Sequence>
</TransitionSeries>
```

### スプリングアニメーション

```tsx
import { spring, useCurrentFrame, useVideoConfig } from "remotion";

const frame = useCurrentFrame();
const { fps } = useVideoConfig();

// UI要素のスナッピーな登場
const scale = spring({
  frame,
  fps,
  config: { damping: 20, stiffness: 200 },  // snappy
});

// テキストのスムーズな登場
const opacity = spring({
  frame,
  fps,
  config: { damping: 200 },  // smooth, no bounce
});
```

---

## 字幕（キャプション）実装

### 基本的な字幕コンポーネント

```tsx
type CaptionProps = {
  text: string;
  startFrame: number;
  endFrame: number;
  position?: "top" | "bottom" | "center";
};

export const Caption: React.FC<CaptionProps> = ({
  text, startFrame, endFrame, position = "bottom"
}) => {
  const frame = useCurrentFrame();

  if (frame < startFrame || frame > endFrame) return null;

  const opacity = interpolate(
    frame,
    [startFrame, startFrame + 10, endFrame - 10, endFrame],
    [0, 1, 1, 0],
    { extrapolateRight: "clamp", extrapolateLeft: "clamp" }
  );

  return (
    <AbsoluteFill style={{ justifyContent: "flex-end", padding: 60 }}>
      <div style={{
        opacity,
        backgroundColor: "rgba(0,0,0,0.7)",
        color: "#FFFFFF",
        fontSize: 36,
        fontWeight: "bold",
        padding: "12px 24px",
        borderRadius: 8,
        textAlign: "center",
      }}>
        {text}
      </div>
    </AbsoluteFill>
  );
};
```

---

## Apple 審査基準

### プレビュー動画の拒否理由

1. アプリ外のコンテンツを表示（フェイクUI）
2. 動画内での価格・特典の言及
3. 解像度・長さの仕様違反
4. 他アプリの UI やブランドの使用
5. ナレーションで成人向けコンテンツ

### 高評価プレビューの特徴

- 最初の 3 秒で価値を伝える
- 実際のタップ・スワイプ操作を見せる
- デバイスフレーム（iPhone モックアップ）を使用
- 字幕（英語・日本語）で説明補足
- 音楽は著作権フリーのみ使用
