#!/usr/bin/env python3
"""Prepare Upper Sky biome assets for use in Godot.

1. Stitch A/B/C base backgrounds → assets/backgrounds/upper_sky_base.png
2. Key baked backgrounds from overlay, gimmick visuals, transition visual
3. Slice decor set into individual sprites
4. Output keyed/sliced assets to assets/sprites/biomes/upper_sky/

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
    """Flood-fill from borders to knock the neutral-gray checker background
    to alpha 0. Only removes pixels that are nearly neutral gray (R≈G≈B)
    — preserves warm cream / coloured watercolor content.
    Returns a new RGBA image."""
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()

    def is_checker(x, y):
        r, g, b, a = px[x, y]
        if a < ALPHA_T:
            return True
        avg = (r + g + b) // 3
        if avg < CHECKER_LO or avg > CHECKER_HI:
            return False
        # neutral = all channels within CHECKER_NEUTRAL_MAX_SAT of each other
        return (max(r, g, b) - min(r, g, b)) <= CHECKER_NEUTRAL_MAX_SAT

    bg = bytearray(w * h)
    stack = []

    def push(x, y):
        i = y * w + x
        if not bg[i] and is_checker(x, y):
            bg[i] = 1
            stack.append((x, y))

    for x in range(w):
        push(x, 0); push(x, h - 1)
    for y in range(h):
        push(0, y); push(w - 1, y)
    while stack:
        x, y = stack.pop()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                push(nx, ny)

    out = im.copy()
    pxo = out.load()
    for y in range(h):
        for x in range(w):
            if bg[y * w + x]:
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


# ─────────────────────────────────────── connected components ──

def find_components(im):
    """Find connected content regions. Returns list of (x0,y0,x1,y1) bboxes."""
    w, h = im.size
    px = im.load()
    visited = bytearray(w * h)
    components = []

    for sy in range(h):
        for sx in range(w):
            i = sy * w + sx
            if visited[i] or px[sx, sy][3] <= ALPHA_T:
                continue
            # BFS
            stack = [(sx, sy)]
            visited[i] = 1
            x0, y0, x1, y1 = sx, sy, sx, sy
            count = 0
            while stack:
                cx, cy = stack.pop()
                count += 1
                x0 = min(x0, cx); y0 = min(y0, cy)
                x1 = max(x1, cx); y1 = max(y1, cy)
                for nx, ny in ((cx+1,cy),(cx-1,cy),(cx,cy+1),(cx,cy-1)):
                    if 0 <= nx < w and 0 <= ny < h:
                        ni = ny * w + nx
                        if not visited[ni] and px[nx, ny][3] > ALPHA_T:
                            visited[ni] = 1
                            stack.append((nx, ny))
            if count >= MIN_AREA:
                bw = x1 - x0 + 1
                bh = y1 - y0 + 1
                if bw >= MIN_DIM and bh >= MIN_DIM:
                    components.append((x0, y0, x1, y1))

    return components


# ─────────────────────────────────────── main ──

def ensure_dirs():
    os.makedirs(OUT_SPRITES, exist_ok=True)
    os.makedirs(OUT_DECOR, exist_ok=True)


def stitch_base():
    """Stitch A/B/C base backgrounds into one tall PNG."""
    from tools_stitch_import import stitch as _stitch
    pass


def do_stitch():
    """Stitch A/B/C → upper_sky_base.png (reuse stitch_biome_bg logic inline)."""
    paths = [
        f"{SRC}/1_map_upper sky_A.png",
        f"{SRC}/1_map_upper sky_B.png",
        f"{SRC}/1_map_upper sky_C.png",
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
    print(f"  stitched A+B+C → {out_path}  {canvas.size}")
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


def slice_decor():
    """Slice decor set into individual sprites."""
    src_path = f"{SRC}/1_map_upper sky_decor set.png"
    im = Image.open(src_path)
    keyed = key_background(im)

    comps = find_components(keyed)
    # sort top-to-bottom, left-to-right
    comps.sort(key=lambda b: (b[1], b[0]))

    print(f"  decor set: found {len(comps)} components")

    # Save montage for inspection
    THUMB = 160
    cols = 6
    rows = (len(comps) + cols - 1) // cols
    montage = Image.new("RGBA", (cols * THUMB, rows * THUMB), (40, 40, 40, 255))

    for idx, (x0, y0, x1, y1) in enumerate(comps):
        crop = keyed.crop((max(0, x0 - PAD), max(0, y0 - PAD),
                           min(im.width, x1 + PAD + 1), min(im.height, y1 + PAD + 1)))
        out_path = f"{OUT_DECOR}/decor_{idx:02d}.png"
        crop.save(out_path)

        thumb = crop.copy()
        thumb.thumbnail((THUMB - 4, THUMB - 4), Image.LANCZOS)
        tx = (idx % cols) * THUMB + (THUMB - thumb.width) // 2
        ty = (idx // cols) * THUMB + (THUMB - thumb.height) // 2
        montage.paste(thumb, (tx, ty), thumb)

        # label
        try:
            draw = ImageDraw.Draw(montage)
            draw.text((tx + 2, ty + 2), str(idx), fill=(255, 255, 100, 255))
        except Exception:
            pass

    montage_path = f"{OUT_DECOR}/_montage.png"
    montage.save(montage_path)
    print(f"  decor montage → {montage_path}")
    return len(comps)


def main():
    ensure_dirs()
    print("=== Upper Sky asset prep ===")

    print("\n[1] Stitch A+B+C base backgrounds")
    do_stitch()

    print("\n[2] Key overlay effect")
    key_and_save("1_map_upper sky_overlay effect.png", "overlay.png")

    print("\n[3] Key gimmick visuals")
    key_and_save("1_map_upper sky_gimmick visual_gentle wind current lane.png", "wind_lane.png")
    key_and_save("1_map_upper sky_gimmick visual_perfect sling star trail cue.png", "sling_trail.png")

    print("\n[4] Key transition visual")
    key_and_save("1_map_upper sky_transition visual.png", "transition.png")

    print("\n[5] Slice decor set")
    n = slice_decor()

    print(f"\nDone. {n} decor sprites in {OUT_DECOR}/")
    print("Review decor/_montage.png to map indices → names.")


if __name__ == "__main__":
    main()
