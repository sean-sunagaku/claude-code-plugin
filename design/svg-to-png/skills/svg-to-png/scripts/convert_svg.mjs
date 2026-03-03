#!/usr/bin/env node

/**
 * SVG to PNG converter using sharp.
 * Supports density-based high-quality rendering, presets, and batch output.
 *
 * Usage:
 *   node convert_svg.mjs --input logo.svg --output logo.png --width 1024
 *   node convert_svg.mjs --input logo.svg --preset app-icon --output-dir ./icons
 *   node convert_svg.mjs --input logo.svg --width 512 --height 512 --background "#1a1a2e"
 */

import { readFile, writeFile, mkdir } from "node:fs/promises";
import { resolve, dirname, basename, extname, join } from "node:path";
import { parseArgs } from "node:util";

// ---------------------------------------------------------------------------
// Presets
// ---------------------------------------------------------------------------
const PRESETS = {
  "app-icon": [
    { name: "icon-1024.png", width: 1024, height: 1024 },
    { name: "icon-512.png", width: 512, height: 512 },
    { name: "icon-256.png", width: 256, height: 256 },
    { name: "icon-192.png", width: 192, height: 192 },
    { name: "icon-180.png", width: 180, height: 180 },
    { name: "icon-167.png", width: 167, height: 167 },
    { name: "icon-152.png", width: 152, height: 152 },
    { name: "icon-120.png", width: 120, height: 120 },
    { name: "icon-76.png", width: 76, height: 76 },
  ],
  "splash-portrait": [
    { name: "splash-1284x2778.png", width: 1284, height: 2778 },
    { name: "splash-1170x2532.png", width: 1170, height: 2532 },
    { name: "splash-1125x2436.png", width: 1125, height: 2436 },
    { name: "splash-1080x1920.png", width: 1080, height: 1920 },
    { name: "splash-750x1334.png", width: 750, height: 1334 },
  ],
  "splash-icon": [
    { name: "splash-icon.png", width: 1024, height: 1024 },
  ],
  favicon: [
    { name: "favicon-48.png", width: 48, height: 48 },
    { name: "favicon-96.png", width: 96, height: 96 },
    { name: "favicon-192.png", width: 192, height: 192 },
    { name: "favicon-512.png", width: 512, height: 512 },
  ],
  "og-image": [
    { name: "og-image.png", width: 1200, height: 630 },
  ],
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function parseSvgViewBox(svgBuffer) {
  const svgStr = svgBuffer.toString("utf-8");
  // Try viewBox first
  const vbMatch = svgStr.match(/viewBox\s*=\s*["']([^"']+)["']/);
  if (vbMatch) {
    const parts = vbMatch[1].trim().split(/[\s,]+/).map(Number);
    if (parts.length === 4) return { width: parts[2], height: parts[3] };
  }
  // Fallback to width/height attributes
  const wMatch = svgStr.match(/<svg[^>]*\bwidth\s*=\s*["'](\d+(?:\.\d+)?)/);
  const hMatch = svgStr.match(/<svg[^>]*\bheight\s*=\s*["'](\d+(?:\.\d+)?)/);
  if (wMatch && hMatch) {
    return { width: parseFloat(wMatch[1]), height: parseFloat(hMatch[1]) };
  }
  return null;
}

async function convertSvgToPng(sharpMod, svgBuffer, { width, height, background }) {
  const viewBox = parseSvgViewBox(svgBuffer);
  const svgWidth = viewBox ? viewBox.width : 100;

  // Calculate density for high-quality rasterisation
  const targetWidth = width || (height && viewBox ? Math.round(height * viewBox.width / viewBox.height) : svgWidth);
  const density = Math.max(72, Math.round(72 * targetWidth / svgWidth));

  let pipeline = sharpMod(svgBuffer, { density });

  if (width || height) {
    pipeline = pipeline.resize({
      width: width || undefined,
      height: height || undefined,
      fit: "contain",
      background: background || { r: 0, g: 0, b: 0, alpha: 0 },
    });
  }

  if (background && background !== "transparent") {
    pipeline = pipeline.flatten({ background });
  }

  return pipeline.png().toBuffer();
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const { values } = parseArgs({
    options: {
      input: { type: "string", short: "i" },
      output: { type: "string", short: "o" },
      width: { type: "string", short: "w" },
      height: { type: "string", short: "h" },
      background: { type: "string", short: "b", default: "transparent" },
      preset: { type: "string", short: "p" },
      "output-dir": { type: "string", short: "d" },
    },
    strict: true,
  });

  if (!values.input) {
    console.error("Error: --input is required");
    process.exit(1);
  }

  // Dynamically import sharp — try cwd's node_modules first, then global
  let sharp;
  try {
    sharp = (await import("sharp")).default;
  } catch {
    try {
      const { createRequire } = await import("node:module");
      const require = createRequire(resolve(process.cwd(), "package.json"));
      sharp = require("sharp");
    } catch {
      console.error("Error: sharp is not installed. Run: npm install sharp");
      process.exit(1);
    }
  }

  const inputPath = resolve(values.input);
  const svgBuffer = await readFile(inputPath);

  const width = values.width ? parseInt(values.width, 10) : undefined;
  const height = values.height ? parseInt(values.height, 10) : undefined;
  const background = values.background;

  // --- Preset mode ---
  if (values.preset) {
    const presetName = values.preset;
    const entries = PRESETS[presetName];
    if (!entries) {
      console.error(`Unknown preset: ${presetName}. Available: ${Object.keys(PRESETS).join(", ")}`);
      process.exit(1);
    }

    const outDir = resolve(values["output-dir"] || ".");
    await mkdir(outDir, { recursive: true });

    for (const entry of entries) {
      const bg = presetName === "app-icon" && background === "transparent" ? "#ffffff" : background;
      const buf = await convertSvgToPng(sharp, svgBuffer, {
        width: entry.width,
        height: entry.height,
        background: bg === "transparent" ? undefined : bg,
      });
      const outPath = join(outDir, entry.name);
      await writeFile(outPath, buf);
      console.log(`  ${entry.name} (${entry.width}x${entry.height})`);
    }
    console.log(`Done. ${entries.length} files written to ${outDir}`);
    return;
  }

  // --- Single file mode ---
  const pngBuf = await convertSvgToPng(sharp, svgBuffer, {
    width,
    height,
    background: background === "transparent" ? undefined : background,
  });

  const outputPath = resolve(
    values.output ||
    basename(inputPath, extname(inputPath)) + ".png"
  );
  await mkdir(dirname(outputPath), { recursive: true });
  await writeFile(outputPath, pngBuf);
  console.log(`Done. ${outputPath} (${width || "auto"}x${height || "auto"})`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
