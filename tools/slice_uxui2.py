#!/usr/bin/env python3
"""Slice UXUI_2 (and UXUI_1) combined watercolor UI sheets into isolated sprites.

Sheets come in two background flavors:
  * transparent (checkerboard) - content = alpha above a threshold
  * solid near-white           - content = everything the border flood-fill can't reach

For each sheet we find connected components, drop tiny bits and baked text lines,
autocrop each sprite to its alpha bounds, and write index-numbered PNGs into a
staging folder. We also emit a labelled montage so a human can map index -> name.

Pure PIL, no numpy. Usage:
    python3 tools/slice_uxui2.py "assets/UXUI/UXUI_2/core UI kit.png" out/core_ui core
"""
import sys
import os
from array import array
from PIL import Image, ImageDraw, ImageFont

ALPHA_T = 28       # alpha above this counts as (potential) content
WHITE_T = 236      # r,g,b all >= this counts as near-white background
GRAY_SAT = 14      # max-min channel spread below this counts as neutral gray
GRAY_LO = 60       # neutral gray in [LO, HI] is checkerboard background
GRAY_HI = 214
MIN_AREA = 2000    # drop components with fewer content pixels than this
MIN_DIM = 26       # drop components thinner than this in either axis
PAD = 6            # transparent padding kept around each crop


def key_background(im):
    """Flood-fill the painted background (near-white and/or neutral-gray checker,
    or real transparency) inward from the borders and knock it to alpha 0.
    Returns (w, h, keyed RGBA image, mask bytearray of content)."""
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()

    # Sample the border to learn the painted background color(s). Sheets use a
    # 1-2 shade checker in some hue (neutral gray, or blue-gray on the shop
    # sheet); we key any pixel close to a dominant border color by tolerance.
    from collections import Counter
    border = Counter()
    for x in range(w):
        for dy in (0, 1, 2, h - 3, h - 2, h - 1):
            border[px[x, dy][:3]] += 1
    for y in range(h):
        for dx in (0, 1, 2, w - 3, w - 2, w - 1):
            border[px[dx, y][:3]] += 1
    total = sum(border.values())
    bg_colors = []
    acc = 0
    for col, n in border.most_common(8):
        bg_colors.append(col)
        acc += n
        if acc >= total * 0.72 or len(bg_colors) >= 4:
            break
    COLOR_TOL = 22  # per-channel max distance to a sampled bg color

    def near_bg_color(r, g, b):
        for cr, cg, cb in bg_colors:
            if abs(r - cr) <= COLOR_TOL and abs(g - cg) <= COLOR_TOL and abs(b - cb) <= COLOR_TOL:
                return True
        return False

    def is_bg(x, y):
        r, g, b, a = px[x, y]
        if a < ALPHA_T:
            return True
        if r >= WHITE_T and g >= WHITE_T and b >= WHITE_T:
            return True
        mx, mn = max(r, g, b), min(r, g, b)
        if (mx - mn) <= GRAY_SAT and GRAY_LO <= mx <= GRAY_HI:
            return True
        return near_bg_color(r, g, b)

    bg = bytearray(w * h)
    stack = []

    def push_border(x, y):
        i = y * w + x
        if not bg[i] and is_bg(x, y):
            bg[i] = 1
            stack.append((x, y))

    for x in range(w):
        push_border(x, 0); push_border(x, h - 1)
    for y in range(h):
        push_border(0, y); push_border(w - 1, y)
    while stack:
        x, y = stack.pop()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                i = ny * w + nx
                if not bg[i] and is_bg(nx, ny):
                    bg[i] = 1
                    stack.append((nx, ny))

    # apply transparency and build content mask
    mask = bytearray(w * h)
    for y in range(h):
        base = y * w
        for x in range(w):
            i = base + x
            if bg[i]:
                r, g, b, _ = px[x, y]
                px[x, y] = (r, g, b, 0)
            else:
                mask[i] = 1
    return w, h, im, mask


def components(w, h, mask):
    """4-connected component bounding boxes over the content mask."""
    labels = array('i', [0]) * (w * h)
    comps = []
    cur = 0
    for start in range(w * h):
        if not mask[start] or labels[start]:
            continue
        cur += 1
        sx, sy = start % w, start // w
        minx = maxx = sx
        miny = maxy = sy
        area = 0
        stack = [start]
        labels[start] = cur
        while stack:
            idx = stack.pop()
            x, y = idx % w, idx // w
            area += 1
            if x < minx: minx = x
            if x > maxx: maxx = x
            if y < miny: miny = y
            if y > maxy: maxy = y
            if x + 1 < w:
                n = idx + 1
                if mask[n] and not labels[n]:
                    labels[n] = cur; stack.append(n)
            if x - 1 >= 0:
                n = idx - 1
                if mask[n] and not labels[n]:
                    labels[n] = cur; stack.append(n)
            if y + 1 < h:
                n = idx + w
                if mask[n] and not labels[n]:
                    labels[n] = cur; stack.append(n)
            if y - 1 >= 0:
                n = idx - w
                if mask[n] and not labels[n]:
                    labels[n] = cur; stack.append(n)
        comps.append((minx, miny, maxx, maxy, area))
    return comps


def looks_like_text(bw, bh, area):
    fill = area / float(bw * bh)
    # short, wide, sparse -> baked section-title text line
    if bh < 52 and (bw / float(bh)) > 3.2 and fill < 0.38:
        return True
    return False


def reading_order(comps, row_tol=70):
    """Sort components top-to-bottom then left-to-right, banding into rows."""
    comps = sorted(comps, key=lambda c: c[1])
    rows = []
    for c in comps:
        cy = (c[1] + c[3]) // 2
        placed = False
        for row in rows:
            if abs(row[0] - cy) <= row_tol:
                row[1].append(c)
                row[0] = (row[0] * (len(row[1]) - 1) + cy) // len(row[1])
                placed = True
                break
        if not placed:
            rows.append([cy, [c]])
    rows.sort(key=lambda r: r[0])
    ordered = []
    for _, row in rows:
        ordered.extend(sorted(row, key=lambda c: c[0]))
    return ordered


def main():
    src, out_dir, prefix = sys.argv[1], sys.argv[2], sys.argv[3]
    os.makedirs(out_dir, exist_ok=True)
    im0 = Image.open(src).convert("RGBA")
    w, h, im, mask = key_background(im0)
    print(f"{os.path.basename(src)}  {w}x{h}")
    comps = components(w, h, mask)
    kept = []
    for (minx, miny, maxx, maxy, area) in comps:
        bw, bh = maxx - minx + 1, maxy - miny + 1
        if area < MIN_AREA or bw < MIN_DIM or bh < MIN_DIM:
            continue
        if looks_like_text(bw, bh, area):
            continue
        kept.append((minx, miny, maxx, maxy, area))
    kept = reading_order(kept)
    print(f"  {len(comps)} raw comps -> {len(kept)} sprites")

    crops = []
    for i, (minx, miny, maxx, maxy, area) in enumerate(kept):
        box = (max(0, minx - PAD), max(0, miny - PAD),
               min(w, maxx + 1 + PAD), min(h, maxy + 1 + PAD))
        crop = im.crop(box)
        crop = crop.crop(crop.getbbox())  # tighten to alpha
        crop.save(os.path.join(out_dir, f"{prefix}_{i:02d}.png"))
        crops.append(crop)

    make_montage(crops, prefix, os.path.join(out_dir, f"_montage_{prefix}.png"))


def make_montage(crops, prefix, path, cols=6, cell=200):
    rows = (len(crops) + cols - 1) // cols
    m = Image.new("RGBA", (cols * cell, rows * cell), (60, 60, 70, 255))
    d = ImageDraw.Draw(m)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 26)
    except Exception:
        font = ImageFont.load_default()
    for i, crop in enumerate(crops):
        cx = (i % cols) * cell
        cy = (i // cols) * cell
        c = crop.copy()
        c.thumbnail((cell - 30, cell - 46))
        m.paste(c, (cx + (cell - c.width) // 2, cy + 34 + (cell - 46 - c.height) // 2), c)
        d.text((cx + 6, cy + 4), f"{i:02d}", fill=(255, 220, 120, 255), font=font)
    m.save(path)
    print(f"  montage -> {path}")


if __name__ == "__main__":
    main()
