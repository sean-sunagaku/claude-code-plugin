#!/usr/bin/env python3
"""
Simulator Chrome Bar Remover

iOS/Android シミュレーターのスクリーンショットから
macOS ウィンドウのタイトルバー（"iPhone 16 Pro / iOS 18.6" 等）を自動検出して除去する。

検出方法: シミュレーターのスクショは alpha チャンネル付き PNG で、
タイトルバー部分は不透明、その下（デバイスベゼルとの隙間）は透明になっている。
中央列を走査して最初の alpha=0 ピクセルを見つけることでバーの高さを特定する。
"""

import sys
import argparse
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow が必要です。 pip install Pillow で入れてください。")
    sys.exit(1)


def find_chrome_height(img: Image.Image) -> int:
    """画像中央列を走査して、alpha=0 になる最初の行 = chrome bar の下端を返す"""
    cx = img.width // 2
    for y in range(img.height):
        _, _, _, a = img.getpixel((cx, y))
        if a == 0:
            return y
    return 0


def crop_image(input_path: Path, output_path: Path) -> dict:
    """1枚の画像から chrome bar を除去して保存する。結果情報を dict で返す。"""
    img = Image.open(input_path)
    if img.mode != "RGBA":
        img = img.convert("RGBA")

    chrome_h = find_chrome_height(img)
    if chrome_h == 0:
        return {"status": "skip", "file": input_path.name, "reason": "chrome bar not detected"}

    cropped = img.crop((0, chrome_h, img.width, img.height))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    cropped.save(output_path)

    return {
        "status": "ok",
        "file": input_path.name,
        "output": str(output_path),
        "removed_px": chrome_h,
        "original_size": f"{img.width}x{img.height}",
        "cropped_size": f"{cropped.width}x{cropped.height}",
    }


def main():
    parser = argparse.ArgumentParser(
        description="Simulator のタイトルバーを除去する"
    )
    parser.add_argument("inputs", nargs="+", help="入力 PNG ファイル")
    parser.add_argument(
        "-o", "--output-dir",
        help="出力ディレクトリ（省略時は元ファイルと同じ場所に _cropped サフィックス）",
    )
    parser.add_argument(
        "-s", "--suffix",
        default="_cropped",
        help="出力ファイル名のサフィックス（デフォルト: _cropped）",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="サフィックスなしで元ファイルを上書き",
    )
    args = parser.parse_args()

    results = []
    for input_str in args.inputs:
        input_path = Path(input_str)
        if not input_path.exists():
            results.append({"status": "skip", "file": input_str, "reason": "not found"})
            continue

        if args.overwrite:
            output_path = input_path
        elif args.output_dir:
            output_path = Path(args.output_dir) / input_path.name
        else:
            output_path = input_path.with_stem(input_path.stem + args.suffix)

        result = crop_image(input_path, output_path)
        results.append(result)

    for r in results:
        if r["status"] == "ok":
            print(f"OK: {r['file']} -> {r['output']}  (removed {r['removed_px']}px, {r['cropped_size']})")
        else:
            print(f"SKIP: {r['file']} ({r['reason']})")

    ok_count = sum(1 for r in results if r["status"] == "ok")
    print(f"\nDone! {ok_count}/{len(results)} files processed.")


if __name__ == "__main__":
    main()
