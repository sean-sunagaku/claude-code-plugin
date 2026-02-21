# Remotion シーンテンプレート集

## オープニングシーン（3秒 = 90フレーム）

```tsx
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

type IntroSceneProps = {
  appName: string;
  tagline: string;
  primaryColor: string;
  logoUrl?: string;
};

export const IntroScene: React.FC<IntroSceneProps> = ({
  appName,
  tagline,
  primaryColor,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // ロゴのスプリング登場
  const logoScale = spring({
    frame,
    fps,
    config: { damping: 20, stiffness: 200 },
    durationInFrames: 30,
  });

  // テキストのフェードイン
  const textOpacity = interpolate(frame, [20, 40], [0, 1], {
    extrapolateRight: "clamp",
    extrapolateLeft: "clamp",
  });

  // タグラインのスライドイン
  const taglineTranslateY = interpolate(frame, [30, 50], [20, 0], {
    extrapolateRight: "clamp",
    extrapolateLeft: "clamp",
  });

  return (
    <AbsoluteFill
      style={{
        backgroundColor: primaryColor,
        alignItems: "center",
        justifyContent: "center",
        gap: 24,
      }}
    >
      {/* アプリアイコン */}
      <div
        style={{
          width: 120,
          height: 120,
          borderRadius: 28,
          backgroundColor: "rgba(255,255,255,0.2)",
          transform: `scale(${logoScale})`,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <span style={{ fontSize: 60 }}>📱</span>
      </div>

      {/* アプリ名 */}
      <div
        style={{
          opacity: textOpacity,
          color: "#FFFFFF",
          fontSize: 56,
          fontWeight: "800",
          fontFamily: "sans-serif",
        }}
      >
        {appName}
      </div>

      {/* タグライン */}
      <div
        style={{
          opacity: textOpacity,
          color: "rgba(255,255,255,0.8)",
          fontSize: 32,
          fontWeight: "400",
          fontFamily: "sans-serif",
          transform: `translateY(${taglineTranslateY}px)`,
          textAlign: "center",
          padding: "0 60px",
        }}
      >
        {tagline}
      </div>
    </AbsoluteFill>
  );
};
```

---

## 機能紹介シーン（6秒 = 180フレーム）

```tsx
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

type FeatureSceneProps = {
  featureTitle: string;
  featureDescription: string;
  screenMockupColor?: string;
  accentColor: string;
  index: number;
};

export const FeatureScene: React.FC<FeatureSceneProps> = ({
  featureTitle,
  featureDescription,
  accentColor,
  index,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // 背景フェードイン
  const bgOpacity = interpolate(frame, [0, 15], [0, 1], {
    extrapolateRight: "clamp",
    extrapolateLeft: "clamp",
  });

  // スマホモックアップのスライドイン（右から）
  const mockupX = interpolate(frame, [10, 40], [200, 0], {
    extrapolateRight: "clamp",
    extrapolateLeft: "clamp",
  });

  // テキストのフェードイン
  const textOpacity = interpolate(frame, [30, 60], [0, 1], {
    extrapolateRight: "clamp",
    extrapolateLeft: "clamp",
  });

  // 機能番号のバッジ
  const badgeScale = spring({
    frame: frame - 15,
    fps,
    config: { damping: 15, stiffness: 180 },
    durationInFrames: 40,
  });

  return (
    <AbsoluteFill style={{ backgroundColor: "#F8F9FA", opacity: bgOpacity }}>
      {/* 上部テキストエリア（画面の 35%） */}
      <div
        style={{
          position: "absolute",
          top: 120,
          left: 0,
          right: 0,
          padding: "0 60px",
          opacity: textOpacity,
        }}
      >
        {/* 機能番号バッジ */}
        <div
          style={{
            display: "inline-flex",
            alignItems: "center",
            justifyContent: "center",
            width: 48,
            height: 48,
            borderRadius: 24,
            backgroundColor: accentColor,
            color: "#FFFFFF",
            fontSize: 24,
            fontWeight: "800",
            marginBottom: 20,
            transform: `scale(${badgeScale})`,
          }}
        >
          {index}
        </div>

        {/* 機能タイトル */}
        <div
          style={{
            color: "#1A1A2E",
            fontSize: 52,
            fontWeight: "800",
            fontFamily: "sans-serif",
            lineHeight: 1.2,
            marginBottom: 16,
          }}
        >
          {featureTitle}
        </div>

        {/* 機能説明 */}
        <div
          style={{
            color: "#6B7280",
            fontSize: 32,
            fontWeight: "400",
            fontFamily: "sans-serif",
            lineHeight: 1.4,
          }}
        >
          {featureDescription}
        </div>
      </div>

      {/* スマホモックアップエリア（画面の 60%） */}
      <div
        style={{
          position: "absolute",
          bottom: 100,
          left: "50%",
          transform: `translateX(calc(-50% + ${mockupX}px))`,
          width: 300,
          height: 600,
          backgroundColor: "#1A1A2E",
          borderRadius: 40,
          padding: 16,
          boxShadow: "0 20px 60px rgba(0,0,0,0.3)",
        }}
      >
        {/* スクリーン */}
        <div
          style={{
            width: "100%",
            height: "100%",
            backgroundColor: "#FFFFFF",
            borderRadius: 28,
            overflow: "hidden",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            backgroundColor: accentColor + "20",
          }}
        >
          <span style={{ fontSize: 80 }}>📱</span>
        </div>
      </div>
    </AbsoluteFill>
  );
};
```

---

## エンディングシーン（3秒 = 90フレーム）

```tsx
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

type OutroSceneProps = {
  appName: string;
  ctaText: string;
  primaryColor: string;
  ratingText?: string;
};

export const OutroScene: React.FC<OutroSceneProps> = ({
  appName,
  ctaText,
  primaryColor,
  ratingText = "★★★★★  4.8",
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // 全体のフェードイン
  const opacity = interpolate(frame, [0, 20], [0, 1], {
    extrapolateRight: "clamp",
    extrapolateLeft: "clamp",
  });

  // CTAボタンのスプリング
  const ctaScale = spring({
    frame: frame - 20,
    fps,
    config: { damping: 12, stiffness: 150 },
    durationInFrames: 50,
  });

  // レーティングのスライドイン（下から）
  const ratingY = interpolate(frame, [40, 60], [30, 0], {
    extrapolateRight: "clamp",
    extrapolateLeft: "clamp",
  });

  const ratingOpacity = interpolate(frame, [40, 60], [0, 1], {
    extrapolateRight: "clamp",
    extrapolateLeft: "clamp",
  });

  return (
    <AbsoluteFill
      style={{
        backgroundColor: primaryColor,
        alignItems: "center",
        justifyContent: "center",
        gap: 40,
        opacity,
      }}
    >
      {/* アプリ名 */}
      <div
        style={{
          color: "#FFFFFF",
          fontSize: 64,
          fontWeight: "900",
          fontFamily: "sans-serif",
        }}
      >
        {appName}
      </div>

      {/* レーティング */}
      <div
        style={{
          color: "rgba(255,255,255,0.9)",
          fontSize: 36,
          fontWeight: "600",
          opacity: ratingOpacity,
          transform: `translateY(${ratingY}px)`,
        }}
      >
        {ratingText}
      </div>

      {/* CTAボタン */}
      <div
        style={{
          backgroundColor: "#FFFFFF",
          color: primaryColor,
          fontSize: 36,
          fontWeight: "800",
          padding: "20px 60px",
          borderRadius: 50,
          transform: `scale(${ctaScale})`,
          fontFamily: "sans-serif",
        }}
      >
        {ctaText}
      </div>

      {/* App Storeバッジ風テキスト */}
      <div
        style={{
          color: "rgba(255,255,255,0.7)",
          fontSize: 24,
          fontWeight: "400",
        }}
      >
        App Store で無料ダウンロード
      </div>
    </AbsoluteFill>
  );
};
```

---

## Root.tsx テンプレート（全シーン結合）

```tsx
import { Composition } from "remotion";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { slide } from "@remotion/transitions/slide";
import { IntroScene } from "./scenes/IntroScene";
import { FeatureScene } from "./scenes/FeatureScene";
import { OutroScene } from "./scenes/OutroScene";
import { useVideoConfig } from "remotion";

const TRANSITION_FRAMES = 20;

const AppPreviewVideo: React.FC<{
  appName: string;
  tagline: string;
  primaryColor: string;
  features: Array<{ title: string; description: string }>;
  ctaText: string;
}> = ({ appName, tagline, primaryColor, features, ctaText }) => {
  return (
    <TransitionSeries>
      {/* オープニング: 3秒 */}
      <TransitionSeries.Sequence durationInFrames={90 + TRANSITION_FRAMES}>
        <IntroScene
          appName={appName}
          tagline={tagline}
          primaryColor={primaryColor}
        />
      </TransitionSeries.Sequence>

      {/* 機能1: 6秒 */}
      <TransitionSeries.Transition
        presentation={slide({ direction: "from-right" })}
        timing={linearTiming({ durationInFrames: TRANSITION_FRAMES })}
      />
      <TransitionSeries.Sequence durationInFrames={180 + TRANSITION_FRAMES}>
        <FeatureScene
          featureTitle={features[0]?.title ?? "機能1"}
          featureDescription={features[0]?.description ?? ""}
          accentColor={primaryColor}
          index={1}
        />
      </TransitionSeries.Sequence>

      {/* 機能2: 6秒 */}
      <TransitionSeries.Transition
        presentation={slide({ direction: "from-right" })}
        timing={linearTiming({ durationInFrames: TRANSITION_FRAMES })}
      />
      <TransitionSeries.Sequence durationInFrames={180 + TRANSITION_FRAMES}>
        <FeatureScene
          featureTitle={features[1]?.title ?? "機能2"}
          featureDescription={features[1]?.description ?? ""}
          accentColor={primaryColor}
          index={2}
        />
      </TransitionSeries.Sequence>

      {/* 機能3: 6秒 */}
      <TransitionSeries.Transition
        presentation={fade()}
        timing={linearTiming({ durationInFrames: TRANSITION_FRAMES })}
      />
      <TransitionSeries.Sequence durationInFrames={180 + TRANSITION_FRAMES}>
        <FeatureScene
          featureTitle={features[2]?.title ?? "機能3"}
          featureDescription={features[2]?.description ?? ""}
          accentColor={primaryColor}
          index={3}
        />
      </TransitionSeries.Sequence>

      {/* エンディング: 9秒 */}
      <TransitionSeries.Transition
        presentation={fade()}
        timing={linearTiming({ durationInFrames: TRANSITION_FRAMES })}
      />
      <TransitionSeries.Sequence durationInFrames={270}>
        <OutroScene
          appName={appName}
          ctaText={ctaText}
          primaryColor={primaryColor}
        />
      </TransitionSeries.Sequence>
    </TransitionSeries>
  );
};

export const RemotionRoot = () => {
  return (
    <Composition
      id="AppStorePreview"
      component={AppPreviewVideo}
      durationInFrames={750}  // 25秒 × 30fps（App Store 最大 25 秒）
      fps={30}
      width={886}
      height={1920}
      defaultProps={{
        appName: "MyApp",
        tagline: "あなたの生活をもっと便利に",
        primaryColor: "#2563EB",
        features: [
          { title: "機能1", description: "説明1" },
          { title: "機能2", description: "説明2" },
          { title: "機能3", description: "説明3" },
        ],
        ctaText: "今すぐ始める",
      }}
    />
  );
};
```

---

## package.json テンプレート

```json
{
  "name": "app-store-preview",
  "version": "1.0.0",
  "scripts": {
    "start": "npx remotion studio",
    "build": "npx remotion render AppStorePreview out/preview.mp4",
    "build:15s": "npx remotion render AppStorePreview15 out/preview-15s.mp4"
  },
  "dependencies": {
    "remotion": "^4.0.0",
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "@remotion/transitions": "^4.0.0",
    "@remotion/cli": "^4.0.0"
  },
  "devDependencies": {
    "@types/react": "^18.0.0",
    "typescript": "^5.0.0"
  }
}
```
