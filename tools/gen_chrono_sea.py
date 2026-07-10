#!/usr/bin/env python3
"""Generate the Chrono Sea biome (biome 13) for the continuous column.

Chrono Sea keeps the normal 5-position / 1500m shape (A B C D transition,
bottom->top, one position = 300m), but three positions hold MULTIPLE images that
crossfade at runtime (the slow staggered dissolve the user prototyped):
  A = A1,A2   C = C1,C2,C3   D = D1,D2   (B and transition are single)

Seam colour-correction (same as gen_column_tiles): every image's BOTTOM is
corrected onto the position-below's TOP so the 600px edge dissolve is invisible
no matter which image is showing. When the position below is itself a crossfade,
the target is the AVERAGE of that position's images' tops (the crossfade shows a
blend of them, so the average is what the seam actually meets).

Output naming in res://assets/backgrounds/_column/:
  single position  -> tile_<idx>.png
  crossfade position -> tile_<idx>.png, tile_<idx>_1.png, tile_<idx>_2.png ...
(BackgroundColumn loads tile_<idx>.png plus tile_<idx>_<k>.png per its crossfade
count for that index.)

Run from repo root:  PYTHONPATH=tools python3 tools/gen_chrono_sea.py
"""
import os
from PIL import Image
import gen_column_tiles as g  # _standardize, _correct, COL_DIR, W, H

SRC = "assets/backgrounds/13. chrono sea"
START = 55  # entropy field ends at tile_54 (its transitional)

# (position label, [source variant suffixes bottom->top]) -- bottom to top
POSITIONS = [
    ("A",          ["A1", "A2"]),
    ("B",          ["B"]),
    ("C",          ["C1", "C2", "C3"]),
    ("D",          ["D1", "D2"]),
    ("transition", ["transition"]),
]


def _avg(imgs):
    """Pixel-mean of equal-size RGB images (only the top rows matter to _correct)."""
    if len(imgs) == 1:
        return imgs[0]
    acc = [0] * (g.W * 3)
    px = [im.load() for im in imgs]
    out = Image.new("RGB", (g.W, g.H))
    op = out.load()
    n = len(imgs)
    for y in range(g.H):
        for x in range(g.W):
            r = gg = b = 0
            for p in px:
                pr, pg, pb = p[x, y]
                r += pr; gg += pg; b += pb
            op[x, y] = (r // n, gg // n, b // n)
    return out


def main():
    print("=== Chrono Sea (biome 13) ===")
    below = Image.open(f"{g.COL_DIR}/tile_{START-1}.png").convert("RGB")  # entropy top
    idx = START
    for label, sufs in POSITIONS:
        corrected = []
        for k, suf in enumerate(sufs):
            src = f"{SRC}/13_chrono sea_{suf}.png"
            if not os.path.exists(src):
                raise SystemExit(f"missing {src}")
            tile, resid = g._correct(g._standardize(src), below)
            name = f"tile_{idx}.png" if k == 0 else f"tile_{idx}_{k}.png"
            tile.save(f"{g.COL_DIR}/{name}")
            corrected.append(tile)
            print(f"  {name:16s} <- {suf:12s} seam residual {resid:.1f} RGB")
        # this position's top becomes the reference for the position above;
        # a crossfade position shows a blend, so use the average of its images.
        below = _avg(corrected)
        idx += 1
    n_cf = sum(1 for _, s in POSITIONS if len(s) > 1)
    print(f"Done. {len(POSITIONS)} positions (tiles {START}-{idx-1}), "
          f"{n_cf} crossfade. Register crossfade counts in GameplayController.")


if __name__ == "__main__":
    main()
