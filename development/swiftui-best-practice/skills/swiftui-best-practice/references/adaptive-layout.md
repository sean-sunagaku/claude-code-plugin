# SwiftUI Adaptive Multi-Device Layout

## Breakpoint Pattern (3-tier)

Define metrics based on screen size breakpoints:

```swift
struct ScreenMetrics {
    let size: CGSize

    var isCompactWidth: Bool { size.width < 390 }   // iPhone SE (375pt)
    var isCompactHeight: Bool { size.height < 760 }  // iPhone SE, older small
    var isVeryCompactHeight: Bool { size.height < 700 } // iPhone SE (667pt)
}
```

### Device reference sizes (points)
| Device | Width | Height | Compact? |
|--------|-------|--------|----------|
| iPhone SE 3rd gen | 375 | 667 | isCompactWidth + isVeryCompactHeight |
| iPhone 14 | 390 | 844 | none |
| iPhone 14 Pro | 393 | 852 | none |
| iPhone 15 Pro Max | 430 | 932 | none |
| iPhone 16 Pro Max | 430 | 932 | none |

## 3-tier Conditional Pattern

```swift
// Pattern: veryCompact ? small : (compact ? medium : large)
var spacing: CGFloat { isVeryCompactHeight ? 8 : (isCompactHeight ? 14 : 18) }
var fontSize: CGFloat { isVeryCompactHeight ? 22 : (isCompactWidth ? 28 : 30) }
```

## Adaptive Text Length

For constrained screens, shorten copy proportionally:

```swift
Text(metrics.isVeryCompactHeight
    ? "短い説明。"
    : (metrics.isCompactHeight
        ? "中くらいの説明テキスト。"
        : "フルサイズのデバイスに表示する詳しい説明テキスト。"))
```

For very compact screens, consider setting optional detail text to `nil`:
```swift
sectionHeader(
    title: "Title",
    detail: metrics.isVeryCompactHeight ? nil : "Detail text"
)
```

## ViewThatFits for Horizontal/Vertical Fallback

```swift
ViewThatFits(in: .horizontal) {
    HStack(spacing: 10) { items }  // Try horizontal first
    VStack(alignment: .leading, spacing: 10) { items }  // Fall back to vertical
}
```

Rules:
- Do NOT use `.frame(maxWidth: .infinity)` inside ViewThatFits
- Let items use intrinsic size for correct measurement
- Keep both variants with the same content, different layout only

## Environment-Based Metrics

Inject metrics via SwiftUI Environment for consistent access:

```swift
private struct ScreenMetricsKey: EnvironmentKey {
    static let defaultValue = ScreenMetrics()
}

extension EnvironmentValues {
    var screenMetrics: ScreenMetrics {
        get { self[ScreenMetricsKey.self] }
        set { self[ScreenMetricsKey.self] = newValue }
    }
}

// In root view:
GeometryReader { proxy in
    let metrics = ScreenMetrics(size: proxy.size)
    content.environment(\.screenMetrics, metrics)
}

// In any child view:
@Environment(\.screenMetrics) private var metrics
```
