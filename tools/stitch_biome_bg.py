#!/usr/bin/env python3
"""Stitch vertical biome background segments into one tall scrolling texture.

Follows the handoff's background rule (§5.3): vertical segments, soft
blendable top/bottom edges, crossfade 300-500px overlap between segments, no
blank strip at the seam. Segments are listed bottom-to-top (first = lowest
altitude = where the player starts; later segments are revealed by climbing).

Usage:
    python3 tools/stitch_biome_bg.py OUT.png SEG1.png SEG2.png [...] [--overlap N] [--width N]
"""
import sys
from PIL import Image


def stitch(paths, out_path, overlap=420, width=1080):
    imgs = []
    for p in paths:
        im = Image.open(p).convert("RGBA")
        w, h = im.size
        scale = width / float(w)
        im = im.resize((width, int(round(h * scale))), Image.LANCZOS)
        imgs.append(im)

    total_h = sum(im.height for im in imgs) - overlap * (len(imgs) - 1)
    canvas = Image.new("RGBA", (width, total_h), (0, 0, 0, 255))

    # Place bottom-to-top; track each image's canvas paste-y (top-left corner).
    paste_ys = [total_h - imgs[0].height]
    canvas.paste(imgs[0], (0, paste_ys[0]))

    for i in range(1, len(imgs)):
        prev, cur = imgs[i - 1], imgs[i]
        prev_y = paste_ys[i - 1]
        cur_y = prev_y - (cur.height - overlap)
        paste_ys.append(cur_y)
        canvas.paste(cur, (0, cur_y))

        # Seam band = canvas rows [prev_y, prev_y+overlap): prev's own TOP
        # `overlap` rows == cur's own BOTTOM `overlap` rows (verified: cur_y +
        # cur.height - overlap == prev_y).
        prev_band = prev.crop((0, 0, width, overlap))
        cur_band = cur.crop((0, cur.height - overlap, width, cur.height))

        # Gradient mask: row 0 (canvas top of band, nearest cur's bulk above)
        # -> cur; row overlap-1 (canvas bottom of band, nearest prev's bulk
        # below) -> prev. Image.composite(im1, im2, mask): mask=255 -> im1.
        row_vals = [int(round(255 * row / float(max(overlap - 1, 1)))) for row in range(overlap)]
        mask_data = []
        for v in row_vals:
            mask_data.extend([v] * width)
        mask = Image.new("L", (width, overlap))
        mask.putdata(mask_data)

        band = Image.composite(prev_band, cur_band, mask)
        canvas.paste(band, (0, prev_y))

    canvas.save(out_path)
    print(f"stitched {len(paths)} segments -> {out_path}  {canvas.size}")


if __name__ == "__main__":
    args = sys.argv[1:]
    overlap = 420
    width = 1080
    if "--overlap" in args:
        i = args.index("--overlap")
        overlap = int(args[i + 1])
        del args[i:i + 2]
    if "--width" in args:
        i = args.index("--width")
        width = int(args[i + 1])
        del args[i:i + 2]
    out, *segs = args
    stitch(segs, out, overlap=overlap, width=width)
