#!/usr/bin/env python3
"""Prepare Upper Sky biome assets for use in Godot.

1. Stitch A/B/C/D (D = transition visual) base backgrounds →
   assets/backgrounds/upper_sky_base.png
2. Key the wind-lane gimmick (still has a baked checker background)

Overlay effect, decor set, and the perfect-sling star-trail cue are NOT
processed here. Overlay/decor have watercolor content that's cream/white,
indistinguishable from the baked checker at the pixel level — no keying
approach can separate them reliably. The star-trail cue was dropped from
the biome entirely (removed feature, not an asset problem).

Usage:
    python3 tools/prep_upper_sky.py
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont
from array import array
from collections import Counter

SRC = "assets/backgrounds/1. upper sky"
OUT_BG = "assets/backgrounds"
OUT_SPRITES = "assets/sprites/biomes/upper_sky"
OUT_DECOR = "assets/sprites/biomes/upper_sky/decor"

ALPHA_T = 28
MIN_AREA = 1800
MIN_DIM = 24
PAD = 8
COLOR_TOL = 24

# Checker-specific keying: neutral-gray checker squares used in transparent
# asset sheets. These are purely neutral (R≈G≈B) in the mid-gray range.
CHECKER_NEUTRAL_MAX_SAT = 10   # max R-B spread to be "neutral gray"
CHECKER_LO = 185               # min brightness to be checker
CHECKER_HI = 248               # max brightness (also catches near-white bg)


# ─────────────────────────────────────── background keying ──

def key_checker_background(im):
    """Remove neutral-gray checker background from transparent asset sheets.

    Uses global pixel-by-pixel removal (NOT border flood-fill) so that checker
    squares enclosed inside art outlines are also removed. Only pixels that are
    nearly neutral gray (R≈G≈B, value CHECKER_LO–CHECKER_HI) are zeroed;
    warm cream / coloured watercolor content is preserved.
    Returns a new RGBA image."""
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    out = im.copy()
    pxo = out.load()

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < ALPHA_T:
                pxo[x, y] = (0, 0, 0, 0)
                continue
            avg = (r + g + b) // 3
            if avg < CHECKER_LO or avg > CHECKER_HI:
                continue
            if (max(r, g, b) - min(r, g, b)) <= CHECKER_NEUTRAL_MAX_SAT:
                pxo[x, y] = (0, 0, 0, 0)
    return out


def key_background(im):
    """Alias — use checker keying for all upper sky transparent assets."""
    return key_checker_background(im)


def autocrop(im, pad=PAD):
    """Crop to content bounding box with padding."""
    w, h = im.size
    px = im.load()
    x0, y0, x1, y1 = w, h, 0, 0
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > ALPHA_T:
                x0 = min(x0, x); y0 = min(y0, y)
                x1 = max(x1, x); y1 = max(y1, y)
    if x0 > x1:
        return None
    x0 = max(0, x0 - pad); y0 = max(0, y0 - pad)
    x1 = min(w - 1, x1 + pad); y1 = min(h - 1, y1 + pad)
    return im.crop((x0, y0, x1 + 1, y1 + 1))


# ─────────────────────────────────────── main ──

def ensure_dirs():
    os.makedirs(OUT_SPRITES, exist_ok=True)


def do_stitch():
    """Stitch A/B/C/D → upper_sky_base.png (D = transition visual, same
    aspect ratio as A/B/C at half resolution)."""
    paths = [
        f"{SRC}/1_map_upper sky_A.png",
        f"{SRC}/1_map_upper sky_B.png",
        f"{SRC}/1_map_upper sky_C.png",
        f"{SRC}/1_map_upper sky_transition visual.png",
    ]
    out_path = f"{OUT_BG}/upper_sky_base.png"
    overlap = 300
    width = 1080

    imgs = []
    for p in paths:
        im = Image.open(p).convert("RGBA")
        w, h = im.size
        scale = width / float(w)
        im = im.resize((width, int(round(h * scale))), Image.LANCZOS)
        imgs.append(im)

    total_h = sum(im.height for im in imgs) - overlap * (len(imgs) - 1)
    canvas = Image.new("RGBA", (width, total_h), (0, 0, 0, 255))

    paste_ys = [total_h - imgs[0].height]
    canvas.paste(imgs[0], (0, paste_ys[0]))

    for i in range(1, len(imgs)):
        prev, cur = imgs[i - 1], imgs[i]
        prev_y = paste_ys[i - 1]
        cur_y = prev_y - (cur.height - overlap)
        paste_ys.append(cur_y)
        canvas.paste(cur, (0, cur_y))

        prev_band = prev.crop((0, 0, width, overlap))
        cur_band = cur.crop((0, cur.height - overlap, width, cur.height))

        row_vals = [int(round(255 * row / float(max(overlap - 1, 1)))) for row in range(overlap)]
        mask_data = []
        for v in row_vals:
            mask_data.extend([v] * width)
        mask = Image.new("L", (width, overlap))
        mask.putdata(mask_data)

        band = Image.composite(prev_band, cur_band, mask)
        canvas.paste(band, (0, prev_y))

    canvas.save(out_path)
    print(f"  stitched A+B+C+D → {out_path}  {canvas.size}")
    return paste_ys


def key_and_save(src_name, out_name):
    """Key a single image and save it."""
    src_path = f"{SRC}/{src_name}"
    out_path = f"{OUT_SPRITES}/{out_name}"
    im = Image.open(src_path)
    keyed = key_background(im)
    cropped = autocrop(keyed)
    if cropped is None:
        print(f"  WARNING: {src_name} → nothing found after keying, saving full image")
        cropped = keyed
    cropped.save(out_path)
    print(f"  keyed {src_name} → {out_path}  {cropped.size}")
    return cropped


def main():
    ensure_dirs()
    print("=== Upper Sky asset prep ===")

    print("\n[1] Stitch A+B+C+D (transition) base backgrounds")
    do_stitch()

    print("\n[2] Key wind-current-lane gimmick (baked checker bg)")
    key_and_save("1_map_upper sky_gimmick visual_gentle wind current lane.png", "wind_lane.png")

    print("\nDone. Overlay effect, decor set, and star-trail cue skipped.")


if __name__ == "__main__":
    main()
