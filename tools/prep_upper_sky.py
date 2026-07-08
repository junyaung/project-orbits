#!/usr/bin/env python3
"""Prepare Upper Sky biome assets for use in Godot.

1. Stitch a randomized A/B/C + transition background tall enough to cover
   the whole ~1500 m biome, plus a mirrored footer below the start line.
   Sliced into <=4096px vertical tiles (a single texture that tall would
   exceed the GPU's max 2D texture size) → assets/backgrounds/upper_sky/
   tile_0.png .. tile_N.png + meta.json (holds the start-line row).
2. Key the wind-lane gimmick (still has a baked checker background)

Overlay effect, decor set, and the perfect-sling star-trail cue are NOT
processed here. Overlay/decor have watercolor content that's cream/white,
indistinguishable from the baked checker at the pixel level — no keying
approach can separate them reliably. The star-trail cue was dropped from
the biome entirely (removed feature, not an asset problem).

Usage:
    python3 tools/prep_upper_sky.py [--seed N]
"""
import os
import sys
import json
import random
from PIL import Image, ImageDraw, ImageFont
from array import array
from collections import Counter

SRC = "assets/backgrounds/1. upper sky"
OUT_BG = "assets/backgrounds"
OUT_SPRITES = "assets/sprites/biomes/upper_sky"
TILE_DIR = "assets/backgrounds/upper_sky"

ALPHA_T = 28
MIN_AREA = 1800
MIN_DIM = 24
PAD = 8
COLOR_TOL = 24

# Biome extent + stitch geometry.
TARGET_M = 1500.0     # painted background must cover this many meters
PX_PER_M = 10.0       # gameplay: distance_m = (start_y - cat.y) * 0.1
WIDTH = 1080
OVERLAP = 300         # vertical crossfade between segments
MAX_TILE_H = 4096     # keep each tile within the GPU max 2D texture size

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


def _load_scaled(name):
    """Load a source segment and scale it to WIDTH."""
    im = Image.open(f"{SRC}/{name}").convert("RGBA")
    w, h = im.size
    return im.resize((WIDTH, int(round(h * WIDTH / float(w)))), Image.LANCZOS)


def _pick_order(seg_cache, target_px):
    """Randomized sequence of segment keys, tall enough that the painted area
    above the start line reaches target_px. First segment is a plain A/B/C
    (the intro); transitions ('T') sprinkle in ~22% of the time, never twice
    in a row; the same segment never immediately repeats."""
    base = ["A", "B", "C"]
    order = []
    running = 0.0
    prev = None
    while running < target_px:
        if order and prev != "T" and random.random() < 0.16:
            k = "T"
        else:
            k = random.choice(base)
            while k == prev:
                k = random.choice(base)
        order.append(k)
        h = seg_cache[k].height
        running += h if len(order) == 1 else (h - OVERLAP)
        prev = k
    return order


def do_stitch(seed=None):
    """Stitch a randomized footer+segments background covering ~TARGET_M and
    slice it into GPU-safe vertical tiles under TILE_DIR.

    The footer is a vertically-flipped copy of the first segment, crossfaded
    onto its bottom edge exactly like every other seam, filling the area
    below the cat's start line so there's no empty gray gap. Writes
    meta.json holding core_h — the row (from the canvas TOP) where the
    bottom edge of the first real segment sits, i.e. the biome start line.
    Godot stacks the tiles so that row lines up with the cat's start Y."""
    if seed is not None:
        random.seed(seed)

    seg_cache = {
        "A": _load_scaled("1_map_upper sky_A.png"),
        "B": _load_scaled("1_map_upper sky_B.png"),
        "C": _load_scaled("1_map_upper sky_C.png"),
        "T": _load_scaled("1_map_upper sky_transition visual.png"),
    }

    order = _pick_order(seg_cache, TARGET_M * PX_PER_M)

    # footer (mirror of the first segment) + the segment sequence
    footer = seg_cache[order[0]].transpose(Image.FLIP_TOP_BOTTOM)
    imgs = [footer] + [seg_cache[k] for k in order]

    total_h = sum(im.height for im in imgs) - OVERLAP * (len(imgs) - 1)
    canvas = Image.new("RGBA", (WIDTH, total_h), (0, 0, 0, 255))

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

    core_h = paste_ys[1] + imgs[1].height   # bottom of first real segment = start line

    # slice top→bottom into GPU-safe tiles (pixel-aligned cuts, no seams)
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
        json.dump({"core_h": core_h, "total_h": total_h, "tiles": idx}, f)

    # drop the old single-file background if it lingers
    old = f"{OUT_BG}/upper_sky_base.png"
    if os.path.exists(old):
        os.remove(old)

    print(f"  segments ({len(order)}): {''.join(order)}")
    print(f"  canvas {canvas.size} → {idx} tiles in {TILE_DIR}/")
    print(f"  core_h={core_h}  →  {core_h / PX_PER_M:.0f} m painted above the start line")
    return core_h


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

    seed = None
    if "--seed" in sys.argv:
        seed = int(sys.argv[sys.argv.index("--seed") + 1])

    print(f"\n[1] Stitch randomized ~{TARGET_M:.0f} m background (seed={seed})")
    do_stitch(seed=seed)

    print("\n[2] Key wind-current-lane gimmick (baked checker bg)")
    key_and_save("1_map_upper sky_gimmick visual_gentle wind current lane.png", "wind_lane.png")

    print("\nDone. Overlay effect, decor set, and star-trail cue skipped.")


if __name__ == "__main__":
    main()
