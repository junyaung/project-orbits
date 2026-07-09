#!/usr/bin/env python3
"""Generate continuous-column background tiles for one biome (append per biome).

Reconstructs the pipeline documented for the continuous streamed column (the
approach that superseded per-biome crossfades). Each biome contributes 5 source
images (bottom->top: A B C D transitional); each becomes ONE 1536x2752 tile in
assets/backgrounds/_column/ (tile_0..N-1, bottom->top). The runtime
(BackgroundColumn.gd) overlaps adjacent tiles by SEAM_PX and dissolves the
bottom edge with the organic_edge_fade shader -- so for the dissolve to be
invisible, each tile's bottom must color-MATCH the top of the tile below it.

We only APPEND: tiles below --start-index are already generated & committed and
are never touched. The first new tile is colour-corrected toward the existing
tile_(start-1).png; each subsequent tile toward the tile we just produced.

Correction (per the documented spec):
  * standardize every source to 1536x2752 (LANCZOS)
  * the bottom SEAM_PX rows of a tile share world-space with the top SEAM_PX
    rows of the tile below -> shift them onto that tile's per-row colour profile
  * profiles are smoothed with a 121-row moving average (raw per-row sampling
    causes visible horizontal streak banding)
  * full correction across the seam, then smoothstep-taper to zero by CORR_PX up
Acceptance: boundary mean diff should end <= ~4 RGB (printed per tile).

Usage:
    python3 tools/gen_column_tiles.py "assets/backgrounds/6. crystal aurora expanse" \
        --start-index 20 --prefix "6_crystal aurora expanse"
"""
import argparse
import glob
import os
from PIL import Image

COL_DIR = "assets/backgrounds/_column"
W, H = 1536, 2752
SEAM_PX = 600          # overlap dissolved between adjacent tiles (matches runtime)
CORR_PX = 1200         # rows over which the colour shift tapers back to zero
SMOOTH = 121           # moving-average window for the per-row target profile
# bottom->top order of the 5 source variants within a biome folder
SUFFIXES = ["A", "B", "C", "D", "transitional"]


def _smoothstep(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


def _row_profile(im):
    """Per-row mean RGB (length H) via a box downscale to width 1."""
    col = im.resize((1, H), Image.BOX)
    return list(col.getdata())  # H tuples (r,g,b)


def _moving_avg(prof, win=SMOOTH):
    n = len(prof)
    half = win // 2
    out = []
    for i in range(n):
        lo, hi = max(0, i - half), min(n, i + half + 1)
        seg = prof[lo:hi]
        k = len(seg)
        out.append(tuple(sum(p[c] for p in seg) / k for c in range(3)))
    return out


def _standardize(path):
    im = Image.open(path).convert("RGB")
    if im.size != (W, H):
        im = im.resize((W, H), Image.LANCZOS)
    return im


def _correct(tile, below):
    """Shift tile's bottom rows onto `below`'s top rows. Returns (tile, diff)."""
    tgt = _moving_avg(_row_profile(below))      # below row j
    cur = _moving_avg(_row_profile(tile))       # tile row (H-SEAM+j)
    # delta[j] for j in 0..SEAM-1: below row j vs tile row (H-SEAM+j)
    delta = [tuple(tgt[j][c] - cur[H - SEAM_PX + j][c] for c in range(3))
             for j in range(SEAM_PX)]

    px = tile.load()
    for R in range(H - CORR_PX, H):
        dist = (H - 1) - R                      # 0 at very bottom
        if dist < SEAM_PX:
            d = delta[R - (H - SEAM_PX)]
            taper = 1.0
        else:
            d = delta[0]
            taper = 1.0 - _smoothstep((dist - SEAM_PX) / float(CORR_PX - SEAM_PX))
        dr = int(round(d[0] * taper)); dg = int(round(d[1] * taper)); db = int(round(d[2] * taper))
        if dr == 0 and dg == 0 and db == 0:
            continue
        for x in range(W):
            r, g, b = px[x, R]
            px[x, R] = (min(255, max(0, r + dr)),
                        min(255, max(0, g + dg)),
                        min(255, max(0, b + db)))

    # seam residual: the OVERLAP rows must match -- tile row (H-SEAM+j) shares
    # world space with below row j (NOT tile's bottom edge vs below's top edge,
    # which are SEAM_PX apart). Report mean over the overlap.
    pt, pb = _row_profile(tile), _row_profile(below)
    resid = [max(abs(pt[H - SEAM_PX + j][c] - pb[j][c]) for c in range(3))
             for j in range(SEAM_PX)]
    return tile, sum(resid) / SEAM_PX


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("biome_dir")
    ap.add_argument("--start-index", type=int, required=True)
    ap.add_argument("--prefix", required=True,
                    help="filename stem, e.g. '6_crystal aurora expanse'")
    args = ap.parse_args()

    # Use whichever canonical variants exist (bottom->top). Most biomes are the
    # full A B C D transitional (5 tiles); some drop in without a transitional
    # (4 tiles) -- the last variant present just becomes the biome's top.
    srcs = []
    for suf in SUFFIXES:
        matches = glob.glob(os.path.join(args.biome_dir, f"{args.prefix}_{suf}.png"))
        if matches:
            srcs.append(matches[0])
    if not srcs:
        raise SystemExit(f"no source variants ({'/'.join(SUFFIXES)}) found in {args.biome_dir}")
    print(f"  {len(srcs)} variants: {', '.join(os.path.basename(s) for s in srcs)}")

    idx = args.start_index
    below_path = os.path.join(COL_DIR, f"tile_{idx - 1}.png")
    if not os.path.exists(below_path):
        raise SystemExit(f"reference tile below not found: {below_path}")
    below = Image.open(below_path).convert("RGB")

    print(f"=== column tiles for {args.prefix}: tile_{idx}..tile_{idx + 4} ===")
    for src in srcs:
        tile = _standardize(src)
        tile, diff = _correct(tile, below)
        out = os.path.join(COL_DIR, f"tile_{idx}.png")
        tile.save(out)
        print(f"  tile_{idx}  <- {os.path.basename(src):40s}  seam residual {diff:.1f} RGB")
        below = tile
        idx += 1
    print("Done. Import in Godot, bump COLUMN_TILE_COUNT, fly through (F) to check.")


if __name__ == "__main__":
    main()
