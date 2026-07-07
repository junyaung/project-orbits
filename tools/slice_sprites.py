#!/usr/bin/env python3
"""Slice ORBITS concept sheets into individual game sprites.
White background is keyed out to transparency via border flood-fill,
then the result is auto-cropped to content bounds.
Pure PIL (no numpy)."""
import os
from collections import deque
from PIL import Image

SRC = "/Users/junyaung/project-orbit/images"
DST = "/Users/junyaung/project-orbit/assets/sprites"

WHITE_T = 238  # channel value above which a pixel counts as "white background"


def key_white(im):
    """Flood-fill near-white background from the borders -> alpha 0.
    Then erode a 1px white fringe adjacent to transparency."""
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    bg = bytearray(w * h)  # 1 == background/transparent

    def is_white(x, y):
        r, g, b, a = px[x, y]
        return a > 0 and r >= WHITE_T and g >= WHITE_T and b >= WHITE_T

    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if not bg[y * w + x] and is_white(x, y):
                bg[y * w + x] = 1
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if not bg[y * w + x] and is_white(x, y):
                bg[y * w + x] = 1
                q.append((x, y))
    while q:
        x, y = q.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not bg[ny * w + nx] and is_white(nx, ny):
                bg[ny * w + nx] = 1
                q.append((nx, ny))

    # apply transparency
    for y in range(h):
        for x in range(w):
            if bg[y * w + x]:
                r, g, b, _ = px[x, y]
                px[x, y] = (r, g, b, 0)

    # erode 1px very-white fringe next to transparency (kills halo)
    fringe = []
    for y in range(h):
        for x in range(w):
            if bg[y * w + x]:
                continue
            r, g, b, a = px[x, y]
            if r >= 245 and g >= 245 and b >= 245:
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and bg[ny * w + nx]:
                        fringe.append((x, y))
                        break
    for x, y in fringe:
        r, g, b, a = px[x, y]
        px[x, y] = (r, g, b, 90)
    return im


def autocrop(im, pad=6):
    bbox = im.getbbox()
    if not bbox:
        return im
    l, t, r, b = bbox
    l = max(0, l - pad); t = max(0, t - pad)
    r = min(im.width, r + pad); b = min(im.height, b + pad)
    return im.crop((l, t, r, b))


def extract(sheet, box, out, subdir):
    im = Image.open(os.path.join(SRC, sheet)).convert("RGBA")
    crop = im.crop(box)
    crop = key_white(crop)
    crop = autocrop(crop)
    d = os.path.join(DST, subdir)
    os.makedirs(d, exist_ok=True)
    path = os.path.join(d, out)
    crop.save(path)
    print(f"  {out:28s} {crop.size} <- {sheet}{box}")


def main():
    # ---- CAT (cat.png 921x1152, cat sitting on manhole cover) ----
    print("cat:")
    extract("cat.png", (40, 40, 320, 360), "cat_idle.png", "cat")          # r1c1 calm
    extract("cat.png", (330, 40, 610, 360), "cat_curious.png", "cat")      # r1c2 curious
    extract("cat.png", (600, 40, 900, 360), "cat_determined.png", "cat")   # r1c3 grumpy/focused
    extract("cat.png", (40, 470, 320, 800), "cat_happy.png", "cat")        # r2c1 open mouth
    extract("cat.png", (330, 470, 610, 800), "cat_sleepy.png", "cat")      # r2c2 sleeping
    extract("cat.png", (600, 470, 900, 800), "cat_cheer.png", "cat")       # r2c3 arms up

    # ---- MANHOLE (manhole.png 921x1152) top-down clean cover ----
    print("manhole:")
    extract("manhole.png", (330, 30, 600, 320), "manhole_top.png", "manhole")

    # ---- PLANETS (planets.png 1408x768, 3x3 grid) ----
    # NOTE: meadow/dune boxes are tuned to the *true* content bounds (verified
    # via a white-gap row/col scan) - do not shrink them back toward the
    # original guesses, that reintroduces clipped edges / baked-in captions.
    print("planets:")
    extract("planets.png", (219, 34, 439, 246), "planet_meadow.png", "planets")   # r1c1
    extract("planets.png", (595, 40, 835, 250), "planet_cloud.png", "planets")    # r1c2
    extract("planets.png", (965, 40, 1215, 250), "planet_ruin.png", "planets")    # r1c3
    extract("planets.png", (200, 530, 460, 725), "planet_dune.png", "planets")    # r3c1 (label excluded)
    extract("planets.png", (600, 548, 835, 742), "planet_overheat.png", "planets")# r3c2 (label excluded)

    # ---- HAZARDS (obstacles.png 1408x768) ----
    print("hazards:")
    extract("obstacles.png", (70, 80, 270, 300), "drift_rock.png", "hazards")
    extract("obstacles.png", (490, 80, 700, 300), "spiky_urchin.png", "hazards")
    extract("obstacles.png", (720, 80, 930, 300), "electric_jelly.png", "hazards")
    extract("obstacles.png", (975, 70, 1180, 300), "meteor.png", "hazards")

    # ---- COLLECTIBLES (obstacles.png bottom row) ----
    print("collectibles:")
    extract("obstacles.png", (70, 470, 250, 650), "star_coin.png", "collectibles")
    extract("obstacles.png", (450, 470, 600, 650), "shield.png", "collectibles")

    # ---- VFX (VFX.png 1408x768) ----
    print("vfx:")
    extract("VFX.png", (100, 40, 300, 220), "sparkle.png", "vfx")
    extract("VFX.png", (760, 40, 1010, 230), "launch_streak.png", "vfx")
    extract("VFX.png", (110, 322, 300, 486), "steam_puff.png", "vfx")
    extract("VFX.png", (1130, 330, 1310, 510), "twinkle_star.png", "vfx")

    print("done.")


if __name__ == "__main__":
    main()
