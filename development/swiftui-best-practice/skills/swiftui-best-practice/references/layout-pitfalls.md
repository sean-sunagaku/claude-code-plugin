# SwiftUI Layout Pitfalls

## 1. `.frame(width:height:)` blocks `.safeAreaInset`

**Severity:** High — causes UI elements (tab bars, toolbars) to be completely invisible

**Problem:** Using `.frame(width: proxy.size.width, height: proxy.size.height)` inside a `GeometryReader` then chaining `.safeAreaInset(edge: .bottom)` causes the inset view to be pushed off-screen. The fixed frame consumes the entire GeometryReader space, leaving no room for the safeAreaInset content.

**Bad:**
```swift
GeometryReader { proxy in
    ZStack { content }
        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        .safeAreaInset(edge: .bottom) { CustomTabBar() }
}
```

**Good:**
```swift
GeometryReader { proxy in
    ZStack { content }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .safeAreaInset(edge: .bottom) { CustomTabBar() }
}
```

**Why:** `.frame(maxWidth:maxHeight:)` allows the layout system to propose a smaller size to the content when safeAreaInset needs space for the bottom bar. A fixed `.frame(width:height:)` forces the content to exactly that size regardless.

---

## 2. `ViewThatFits` + `.frame(maxWidth: .infinity)` anti-pattern

**Severity:** Medium — causes ViewThatFits to always pick the wrong variant

**Problem:** Adding `.frame(maxWidth: .infinity)` to items inside `ViewThatFits` forces every variant to claim the full available width. `ViewThatFits` measures each variant's ideal size to decide which one fits — if all variants report the same (full) width, it can't distinguish between them and always picks the last/vertical fallback.

**Bad:**
```swift
ViewThatFits(in: .horizontal) {
    HStack {
        PillA().frame(maxWidth: .infinity)
        PillB().frame(maxWidth: .infinity)
    }
    VStack {
        PillA().frame(maxWidth: .infinity)
        PillB().frame(maxWidth: .infinity)
    }
}
```

**Good:**
```swift
ViewThatFits(in: .horizontal) {
    HStack(spacing: 10) {
        PillA()
        PillB()
    }
    VStack(alignment: .leading, spacing: 10) {
        PillA()
        PillB()
    }
}
```

**Why:** `ViewThatFits` relies on intrinsic content size to measure each candidate. `.frame(maxWidth: .infinity)` overrides the intrinsic size, making measurement unreliable.

---

## 3. Custom bottom bar clearance mismatch

**Severity:** Medium — causes bottom content to be hidden behind the bar

**Problem:** When using `.safeAreaInset(edge: .bottom)` with a custom bottom bar, the safe area inset may not always propagate correctly through intermediate views (especially with `.frame()` or `GeometryReader`). If the ScrollView content doesn't have enough bottom padding, the last items will be hidden behind the bar.

**Fix:** Add explicit bottom padding to ScrollView content that matches or exceeds the bottom bar height:
```swift
// If bottom bar is ~56pt on compact devices:
ScrollView {
    content
        .padding(.bottom, 56 + baseBottomPadding)
}
```

---

## 4. GeometryReader size includes safe area

**Severity:** Low — causes unexpected layout on devices with notches/home indicators

**Note:** `GeometryReader`'s `proxy.size` may or may not include safe area insets depending on where it's placed in the view hierarchy. If the GeometryReader is at the root level, `proxy.size` includes the full screen. If it's inside a `NavigationStack` or after `.ignoresSafeArea()`, the size changes.

**Best practice:** Always use `proxy.safeAreaInsets` alongside `proxy.size` for calculations that depend on usable space.
