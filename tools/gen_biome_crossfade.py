#!/usr/bin/env python3
"""Generate a column biome that may have crossfade positions (generalises
gen_chrono_sea.py). Auto-detects each position's images from the folder:

  position P (P in A B C D)  ->  <prefix>_P.png            (single)
                             or  <prefix>_P1.png,_P2.png.. (crossfade)
  top position               ->  <prefix>_transition.png OR _transitional.png

Each image's bottom is colour-matched onto the position-below's top; when the
below is a crossfade, the target is the AVERAGE of its images' tops (the seam
meets a blend). Output: tile_<i>.png + tile_<i>_<k>.png. Prints the crossfade
registrations to add to GameplayController (set_crossfade(index, count)).

Run from repo root:
  PYTHONPATH=tools python3 tools/gen_biome_crossfade.py \
      "assets/backgrounds/14. supernova remnant bloom" "14_supernova remnant bloom" 60
"""
import os
import sys
from PIL import Image
import gen_column_tiles as g  # _standardize, _correct, COL_DIR, W, H


def _avg(imgs):
    if len(imgs) == 1:
        return imgs[0]
    n = len(imgs)
    px = [im.load() for im in imgs]
    out = Image.new("RGB", (g.W, g.H)); op = out.load()
    for y in range(g.H):
        for x in range(g.W):
            r = gg = b = 0
            for p in px:
                pr, pg, pb = p[x, y]; r += pr; gg += pg; b += pb
            op[x, y] = (r // n, gg // n, b // n)
    return out


def _variants(biome_dir, prefix, label):
    """Return the source paths for a position, bottom->top, or [] if none."""
    single = f"{biome_dir}/{prefix}_{label}.png"
    if os.path.exists(single):
        return [single]
    cf = []
    k = 1
    while os.path.exists(f"{biome_dir}/{prefix}_{label}{k}.png"):
        cf.append(f"{biome_dir}/{prefix}_{label}{k}.png"); k += 1
    return cf


def main():
    biome_dir, prefix, start = sys.argv[1], sys.argv[2], int(sys.argv[3])
    positions = []
    for label in ["A", "B", "C", "D"]:
        v = _variants(biome_dir, prefix, label)
        if v:
            positions.append((label, v))
    for t in ["transition", "transitional"]:
        v = _variants(biome_dir, prefix, t)
        if v:
            positions.append((t, v)); break

    if not positions:
        raise SystemExit(f"no positions found in {biome_dir}")

    print(f"=== {prefix}: tiles {start}-{start+len(positions)-1} ===")
    below = Image.open(f"{g.COL_DIR}/tile_{start-1}.png").convert("RGB")
    idx = start
    crossfades = []
    for label, srcs in positions:
        corrected = []
        for k, src in enumerate(srcs):
            tile, resid = g._correct(g._standardize(src), below)
            name = f"tile_{idx}.png" if k == 0 else f"tile_{idx}_{k}.png"
            tile.save(f"{g.COL_DIR}/{name}")
            corrected.append(tile)
            print(f"  {name:16s} <- {os.path.basename(src):40s} residual {resid:.1f}")
        if len(srcs) > 1:
            crossfades.append((idx, len(srcs)))
        below = _avg(corrected)
        idx += 1
    print(f"Done. tiles {start}-{idx-1}. COLUMN_TILE_COUNT += {len(positions)}.")
    if crossfades:
        print("Register crossfades in GameplayController:")
        for i, c in crossfades:
            print(f'  background_column.call("set_crossfade", {i}, {c})')


if __name__ == "__main__":
    main()
