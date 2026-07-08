#!/usr/bin/env python3
"""Prepare the Dream Sky biome background (the biome after Upper Sky, ~1500m+).

Only ONE source segment exists so far (map_dream sky_1.png) - the user will
add A/B/C + transition variants later, matching Upper Sky's structure. For
now this just repeats that single segment with the same 300px crossfade
technique to cover a placeholder ~1500m of climb, sliced into GPU-safe
vertical tiles (same reasoning as Upper Sky: a single texture that tall
would exceed the GPU's max 2D texture size).

Unlike Upper Sky, there's no "footer" or "core_h" concept here - Dream Sky's
background abuts directly onto the TOP of Upper Sky's, so Godot just needs
this stitched image's total height to know how far up it reaches; it anchors
the BOTTOM edge at wherever Upper Sky's painted content ends (computed at
runtime from UpperSkyBiome.get_top_world_y()).

Usage:
    python3 tools/prep_dream_sky.py
"""
import os
import json
from PIL import Image

SRC = "assets/backgrounds"
TILE_DIR = "assets/backgrounds/dream_sky"

TARGET_M = 1500.0     # placeholder length until real A/B/C/transition segments exist
PX_PER_M = 10.0
WIDTH = 1080
OVERLAP = 300
MAX_TILE_H = 4096


def _load_scaled(name):
    im = Image.open(f"{SRC}/{name}").convert("RGBA")
    w, h = im.size
    return im.resize((WIDTH, int(round(h * WIDTH / float(w)))), Image.LANCZOS)


def do_stitch():
    """Repeat the single Dream Sky segment (crossfaded at each seam) until it
    covers TARGET_M, then slice into GPU-safe tiles under TILE_DIR."""
    seg = _load_scaled("map_dream sky_1.png")

    target_px = TARGET_M * PX_PER_M
    imgs = [seg]
    running = seg.height
    while running < target_px:
        imgs.append(seg)
        running += seg.height - OVERLAP

    total_h = sum(im.height for im in imgs) - OVERLAP * (len(imgs) - 1)
    canvas = Image.new("RGBA", (WIDTH, total_h), (0, 0, 0, 255))

    # paste bottom-to-top, same convention as Upper Sky's stitcher: imgs[0] is
    # the bottommost (closest to the seam with Upper Sky), later repeats
    # stack upward (climbing further reveals more repeats)
    paste_ys = [total_h - imgs[0].height]
    canvas.paste(imgs[0], (0, paste_ys[0]))

    for i in range(1, len(imgs)):
        prev, cur = imgs[i - 1], imgs[i]
        prev_y = paste_ys[i - 1]
        cur_y = prev_y - (cur.height - OVERLAP)
        paste_ys.append(cur_y)
        canvas.paste(cur, (0, cur_y))

        prev_band = prev.crop((0, 0, WIDTH, OVERLAP))
        cur_band = cur.crop((0, cur.height - OVERLAP, WIDTH, cur.height))

        row_vals = [int(round(255 * row / float(max(OVERLAP - 1, 1)))) for row in range(OVERLAP)]
        mask_data = []
        for v in row_vals:
            mask_data.extend([v] * WIDTH)
        mask = Image.new("L", (WIDTH, OVERLAP))
        mask.putdata(mask_data)

        band = Image.composite(prev_band, cur_band, mask)
        canvas.paste(band, (0, prev_y))

    os.makedirs(TILE_DIR, exist_ok=True)
    for f in os.listdir(TILE_DIR):
        if f.startswith("tile_") and f.endswith(".png"):
            os.remove(os.path.join(TILE_DIR, f))
    y = 0
    idx = 0
    while y < total_h:
        h = min(MAX_TILE_H, total_h - y)
        canvas.crop((0, y, WIDTH, y + h)).save(f"{TILE_DIR}/tile_{idx}.png")
        y += h
        idx += 1

    with open(f"{TILE_DIR}/meta.json", "w") as f:
        json.dump({"total_h": total_h, "tiles": idx}, f)

    print(f"  repeated segment x{len(imgs)} (single source, temporary)")
    print(f"  canvas {canvas.size} → {idx} tiles in {TILE_DIR}/")
    print(f"  total_h={total_h}  ->  {total_h / PX_PER_M:.0f} m of climb covered")
    return total_h


def main():
    print("=== Dream Sky asset prep (placeholder, single segment) ===")
    do_stitch()
    print("\nDone. Replace do_stitch()'s single segment with a randomized")
    print("A/B/C/transition picker (see prep_upper_sky.py) once those exist.")


if __name__ == "__main__":
    main()
