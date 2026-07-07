#!/usr/bin/env python3
"""Generate scenes/gameplay/ArtStage.tscn: every game sprite as a real,
manually-scalable Sprite2D, seeded at its CURRENT in-game scale, plus
reference guides (orbit ring, screen-bounds frame) so resizing has context.
Open this scene in the Godot editor, drag/scale nodes to taste, save,
then tell Claude — the new Transform > Scale values get read back into
the gameplay scripts.
"""
import os
from PIL import Image

ROOT = "/Users/junyaung/project-orbit"
SPRITES = os.path.join(ROOT, "assets/sprites")


def size(rel):
    return Image.open(os.path.join(SPRITES, rel)).size


# ---- current in-game scale, replicated from the gameplay scripts ----
ORBIT_R = 180.0  # representative Planet.orbit_radius (range is 155-205)

PLANETS = ["meadow", "cloud", "ruin", "dune", "overheat"]
planet_scale = {}
for k in PLANETS:
    w, h = size(f"planets/planet_{k}.png")
    target_diam = ORBIT_R * 1.2  # Planet.gd: visual_radius = orbit_radius*0.6, diameter = *1.2
    s = target_diam / w
    planet_scale[k] = s

CATS = ["cat_idle", "cat_determined", "cat_cheer"]
cat_scale = 1.0  # CatVehicle.gd currently applies no scale (native pixel size)

HAZARDS = {"drift_rock": 108.0, "spiky_urchin": 108.0, "electric_jelly": 108.0, "meteor": 120.0}
hazard_scale = {}
for k, target in HAZARDS.items():
    w, h = size(f"hazards/{k}.png")
    hazard_scale[k] = target / w

PICKUPS = {"star_coin": 74.0, "shield": 84.0}
pickup_scale = {}
for k, target in PICKUPS.items():
    w, h = size(f"collectibles/{k}.png")
    pickup_scale[k] = target / w

# ---- layout (portrait canvas, taller than one screen so all rows fit) ----
PLANET_ROW_Y = 260.0
PLANET_XS = [108.0, 324.0, 540.0, 756.0, 972.0]
CAT_ROW_Y = 820.0
CAT_XS = [270.0, 540.0, 810.0]
HAZARD_ROW_Y = 1280.0
HAZARD_XS = [140.0, 380.0, 620.0, 860.0]
PICKUP_ROW_Y = 1650.0
PICKUP_XS = [400.0, 680.0]

lines = []
ext = []
nodes = []
res_id = 0


def add_ext(path):
    global res_id
    res_id += 1
    rid = f"tex_{res_id}"
    ext.append(f'[ext_resource type="Texture2D" path="res://{path}" id="{rid}"]')
    return rid


def circle_points(r, seg=48):
    import math
    return ", ".join(f"Vector2({r*math.cos(2*math.pi*i/seg):.2f}, {r*math.sin(2*math.pi*i/seg):.2f})" for i in range(seg))


def dashed_circle_dots(r, count=28):
    """Return child-node text for a ring of small dot Polygon2Ds (matches Planet.gd's orbit ring style)."""
    import math
    out = []
    for i in range(count):
        a = 2 * math.pi * i / count
        x, y = r * math.cos(a), r * math.sin(a)
        out.append(f'''
[node name="Dot{i}" type="Polygon2D" parent="{{parent}}"]
position = Vector2({x:.2f}, {y:.2f})
color = Color(0.42, 0.52, 0.66, 0.55)
polygon = PackedVector2Array(3.4, 0, -1.7, 2.94, -1.7, -2.94)
''')
    return out


def sprite_node(name, parent, tex_rid, pos, scale, label_below=None):
    n = [f'''
[node name="{name}" type="Sprite2D" parent="{parent}"]
position = Vector2({pos[0]:.1f}, {pos[1]:.1f})
scale = Vector2({scale:.4f}, {scale:.4f})
texture = ExtResource("{tex_rid}")
''']
    if label_below:
        n.append(f'''
[node name="{name}Label" type="Label" parent="{parent}"]
offset_left = {pos[0]-90:.1f}
offset_top = {pos[1]+120:.1f}
offset_right = {pos[0]+90:.1f}
offset_bottom = {pos[1]+160:.1f}
theme_override_font_sizes/font_size = 26
horizontal_alignment = 1
text = "{label_below}"
''')
    return "".join(n)


# ---- assemble ----
body = []

# screen-bounds frame: shows exactly one 1080x1920 game screen for scale context
body.append('''
[node name="ScreenFrame" type="Line2D" parent="."]
points = PackedVector2Array(0, 0, 1080, 0, 1080, 1920, 0, 1920, 0, 0)
width = 4.0
default_color = Color(0.55, 0.62, 0.72, 0.55)
''')
body.append('''
[node name="ScreenFrameLabel" type="Label" parent="."]
offset_left = 16
offset_top = 16
offset_right = 400
offset_bottom = 56
theme_override_font_sizes/font_size = 26
text = "1080 x 1920 game screen bounds"
''')

# planets + their orbit-ring guide (radius 180, matching Planet.gd)
for k, x in zip(PLANETS, PLANET_XS):
    rid = add_ext(f"assets/sprites/planets/planet_{k}.png")
    group = f"Planet_{k}"
    body.append(f'''
[node name="{group}" type="Node2D" parent="."]
position = Vector2({x:.1f}, {PLANET_ROW_Y:.1f})
''')
    for dot in dashed_circle_dots(ORBIT_R, 28):
        body.append(dot.format(parent=f"{group}"))
    body.append(sprite_node("Sprite", f"{group}", rid, (0, 0), planet_scale[k], label_below=f"{k} (orbit ring r=180)"))

# cat samples
for k, x in zip(CATS, CAT_XS):
    rid = add_ext(f"assets/sprites/cat/{k}.png")
    body.append(sprite_node(f"Cat_{k}", ".", rid, (x, CAT_ROW_Y), cat_scale, label_below=k))

# hazards
for k, x in zip(HAZARDS.keys(), HAZARD_XS):
    rid = add_ext(f"assets/sprites/hazards/{k}.png")
    body.append(sprite_node(f"Hazard_{k}", ".", rid, (x, HAZARD_ROW_Y), hazard_scale[k], label_below=k))

# pickups
for k, x in zip(PICKUPS.keys(), PICKUP_XS):
    rid = add_ext(f"assets/sprites/collectibles/{k}.png")
    body.append(sprite_node(f"Pickup_{k}", ".", rid, (x, PICKUP_ROW_Y), pickup_scale[k], label_below=k))

load_steps = len(ext) + 1
header = f'[gd_scene load_steps={load_steps} format=3 uid="uid://c0rb1tsartstage00"]\n'
out = header + "\n" + "\n".join(ext) + "\n\n[node name=\"ArtStage\" type=\"Node2D\"]\n" + "".join(body)

with open(os.path.join(ROOT, "scenes/gameplay/ArtStage.tscn"), "w") as f:
    f.write(out)

print("Wrote scenes/gameplay/ArtStage.tscn")
print("\nCurrent scale reference (for reading back later):")
print("planet_scale =", {k: round(v, 4) for k, v in planet_scale.items()})
print("cat_scale =", cat_scale)
print("hazard_scale =", {k: round(v, 4) for k, v in hazard_scale.items()})
print("pickup_scale =", {k: round(v, 4) for k, v in pickup_scale.items()})
