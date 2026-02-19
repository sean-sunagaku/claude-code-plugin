---
name: svg-to-png
description: >
  Convert SVG files to high-quality PNG images with precise control over dimensions,
  background color, and CSS rendering (including mix-blend-mode, filters, gradients).
  Use this skill when the user wants to: (1) convert SVG to PNG, (2) generate app icons
  or splash screens from SVG source, (3) batch-generate multiple PNG sizes from a single SVG,
  (4) render SVG with advanced CSS features like mix-blend-mode or filters to PNG.
  Triggers: "SVG to PNG", "SVG変換", "PNG変換", "アイコン生成", "スプラッシュ生成",
  "app icon from SVG", "favicon generation", "splash screen generation".
---

# SVG to PNG Conversion

Convert SVG to high-quality PNG using sharp with automatic density calculation.

## Prerequisites

Ensure sharp is installed in the project (`npm install sharp`). Install it if missing before running the script.

## Script Location

`scripts/convert_svg.mjs` — the main conversion script.

## Single File Conversion

```bash
node scripts/convert_svg.mjs --input logo.svg --output logo.png --width 1024
node scripts/convert_svg.mjs --input logo.svg --width 512 --height 512 --background "#1a1a2e"
```

Arguments:
- `--input` / `-i` (required): Path to input SVG
- `--output` / `-o`: Output PNG path (defaults to `<input-name>.png`)
- `--width` / `-w`: Target width in pixels
- `--height` / `-h`: Target height in pixels
- `--background` / `-b`: Background color (hex or named). Default: `transparent`

## Preset Batch Conversion

Generate multiple PNGs from one SVG using built-in presets:

```bash
node scripts/convert_svg.mjs --input logo.svg --preset app-icon --output-dir ./icons
node scripts/convert_svg.mjs --input logo.svg --preset splash-portrait --output-dir ./splash
```

Arguments:
- `--preset` / `-p`: Preset name (see below)
- `--output-dir` / `-d`: Output directory (created automatically)

Available presets: `app-icon`, `splash-portrait`, `splash-icon`, `favicon`, `og-image`.
For preset details and sizes, see [references/presets.md](references/presets.md).

## Quality: How Density Works

sharp rasterises SVG at a given DPI (density). The script auto-calculates:

```
density = 72 * target_width / svg_viewbox_width
```

A 100-wide viewBox rendered at 1024px uses density 737, producing crisp output. No manual tuning needed.

## Important Notes

- **Default is transparent**: `--background` を指定しなければ背景は透明。SVG の背景色をそのまま活かせる。通常は背景色指定不要。
- **iOS app icons**: 例外的に不透明必須。`app-icon` プリセットは自動で白背景にフォールバック。
- **mix-blend-mode / CSS filters**: sharp (via librsvg) renders these correctly. Tested and confirmed.
- **Fonts**: Convert text to `<path>` outlines in the SVG to avoid font-not-found issues on other machines.
- **CSS variables (`var()`)**: Not supported by librsvg. Replace with literal values before conversion.
- **Expo splash**: Use `splash-icon` preset for the single image referenced by `splash.image` in app config.
