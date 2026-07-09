#!/usr/bin/env python3
"""Fix a light->dark biome seam where a bright transitional tile clashes with a
dark next biome (e.g. Crystal Aurora's white misty top butting onto the Void).

The seam colour-correction in gen_column_tiles.py matches a tile's bottom to the
tile below's TOP. When that top is bright (a light biome fading out to white) but
the next biome is dark, the correction injects a bright band into the dark biome
-> a jarring white glow across the boundary (reported at ~9000m crystal->void).

Fix: fade the transitional tile's TOP multiplicatively toward the next biome's
dark ambient tone. Multiplicative tinting (out = px * lerp(1, target/255, a))
maps white -> the dark tone while preserving stars/cloud texture and relative
contrast, unlike a flat lerp which would dead-flatten the fade. Then regenerate
the next biome's entry tile onto the darkened top so the whole overlap stays dark.

Usage:
    python3 tools/fade_transitional_into_next.py \
        --tile 24 --span 1400 \
        --next-index 25 --next-src "assets/backgrounds/7.  void zone/7_void zone_A.png"
"""
import argparse
import os
from PIL import Image

import gen_column_tiles as g  # _standardize, _correct, COL_DIR, W, H


def _smoothstep(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


def _dark_ambient(src, frac=0.15):
    """The next biome's DARK ambient tone: mean of its darkest `frac` of rows.
    Using the darkest rows (not fixed margins) is robust to biomes whose bright
    misty part is at an edge (void = dark margins; dark-matter reef = light misty
    margins but a dark teal body) -- either way we fade toward the true dark tone."""
    col = Image.open(src).convert("RGB").resize((1, 200), Image.BOX)
    rows = sorted(col.getdata(), key=lambda c: sum(c))
    n = max(1, int(200 * frac))
    return tuple(sum(c[k] for c in rows[:n]) // n for k in range(3))


def _fade_top(tile_path, target, span):
    """Darken the BRIGHT haze in the top `span` rows toward `target`, leaving
    already-dark structure (coral, rock, void) intact -- a luminance cap, not a
    blanket multiply. Only pixels brighter than the target luminance are pulled
    down (row 0 = full strength, fading to 0 at `span`); the mistiest pixels are
    also tinted toward the target hue so they read as the biome's dark tone
    rather than flat grey. This is what lets it work on biomes whose fade band
    mixes light haze with dark coral (dark-matter reef), unlike a flat multiply
    which would crush the coral to near-black."""
    tl = (target[0] + target[1] + target[2]) / 3.0
    tr, tg, tb = target
    im = Image.open(tile_path).convert("RGB")
    px = im.load()
    for R in range(min(span, g.H)):
        a = 1.0 - _smoothstep(R / float(span))     # 1 at top -> 0 at span
        if a <= 0.0:
            continue
        for x in range(g.W):
            r, gg, b = px[x, R]
            lum = (r + gg + b) / 3.0
            if lum <= tl:                          # already dark enough: keep coral
                continue
            s = (lum + a * (tl - lum)) / lum       # scale bright lum toward target
            r2, g2, b2 = r * s, gg * s, b * s
            tint = a * 0.4 * min(1.0, (lum - tl) / (255.0 - tl))
            px[x, R] = (int(r2 + (tr - r2) * tint),
                        int(g2 + (tg - g2) * tint),
                        int(b2 + (tb - b2) * tint))
    im.save(tile_path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tile", type=int, required=True, help="transitional tile index to darken")
    ap.add_argument("--span", type=int, default=1400, help="rows from the top to fade")
    ap.add_argument("--next-index", type=int, required=True, help="entry tile of the next (dark) biome")
    ap.add_argument("--next-src", required=True, help="that biome's A/entry source PNG")
    ap.add_argument("--target", help="override dark tone as 'r,g,b' (else auto-sampled)")
    args = ap.parse_args()

    target = tuple(int(v) for v in args.target.split(",")) if args.target \
        else _dark_ambient(args.next_src)
    tile_path = os.path.join(g.COL_DIR, f"tile_{args.tile}.png")
    print(f"fading tile_{args.tile} top {args.span}px toward {target} (next-biome ambient)")
    _fade_top(tile_path, target, args.span)

    # regenerate the next biome's entry tile onto the now-dark transitional top
    below = Image.open(tile_path).convert("RGB")
    entry = g._standardize(args.next_src)
    entry, resid = g._correct(entry, below)
    out = os.path.join(g.COL_DIR, f"tile_{args.next_index}.png")
    entry.save(out)
    print(f"regenerated tile_{args.next_index} onto darkened top; seam residual {resid:.1f} RGB")


if __name__ == "__main__":
    main()
