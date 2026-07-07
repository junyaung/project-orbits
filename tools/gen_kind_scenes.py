#!/usr/bin/env python3
"""Generate one small .tscn per kind for CatVehicle/Planet/Hazard/Pickup.
Each has a real Sprite2D child seeded at today's current in-game scale, so
opening it in the editor shows exactly what's in the game right now - open
the file, drag the Sprite's scale, save, done."""
import os
from PIL import Image

ROOT = "/Users/junyaung/project-orbit"
SPRITES = "assets/sprites"


def size(rel):
    return Image.open(os.path.join(ROOT, SPRITES, rel)).size


def write(path, content):
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w") as f:
        f.write(content)
    print("wrote", path)


def actor_scene(uid, script_path, tex_path, scale, extra_root_props="", extra_sprite_props=""):
    return f'''[gd_scene load_steps=3 format=3 uid="uid://{uid}"]

[ext_resource type="Script" path="res://{script_path}" id="1_script"]
[ext_resource type="Texture2D" path="res://{tex_path}" id="2_tex"]

[node name="Root" type="Node2D"]
script = ExtResource("1_script")
{extra_root_props}
[node name="Sprite" type="Sprite2D" parent="."]
scale = Vector2({scale:.4f}, {scale:.4f})
texture = ExtResource("2_tex")
{extra_sprite_props}'''


# ---------------------------------------------------------------- CAT ----
write("scenes/actors/CatVehicle.tscn", actor_scene(
    "cvcat00000000000001", "scripts/actors/CatVehicle.gd",
    "assets/sprites/cat/cat_idle.png", 1.0,
    extra_root_props="hit_radius = 60.0\n",
))

# -------------------------------------------------------------- PLANETS --
ORBIT_R = 180.0
for kind in ["meadow", "cloud", "ruin", "dune", "overheat"]:
    w, h = size(f"planets/planet_{kind}.png")
    s = (ORBIT_R * 1.2) / w
    write(f"scenes/gameplay/planets/Planet_{kind.capitalize()}.tscn", actor_scene(
        f"plnt{kind[:4]}0000000001", "scripts/gameplay/Planet.gd",
        f"assets/sprites/planets/planet_{kind}.png", s,
    ))

# -------------------------------------------------------------- HAZARDS --
HAZARDS = {
    "rock": ("hazards/drift_rock.png", 108.0),
    "urchin": ("hazards/spiky_urchin.png", 108.0),
    "jelly": ("hazards/electric_jelly.png", 108.0),
    "meteor": ("hazards/meteor.png", 120.0),
}
for kind, (rel, target) in HAZARDS.items():
    w, h = size(rel)
    s = target / w
    write(f"scenes/gameplay/hazards/Hazard_{kind.capitalize()}.tscn", actor_scene(
        f"hzrd{kind[:4]}0000000001", "scripts/gameplay/Hazard.gd",
        f"assets/sprites/{rel}", s,
        extra_root_props=f"radius = {target * 0.40:.2f}\n",
    ))

# -------------------------------------------------------------- PICKUPS --
PICKUPS = {
    "star": ("collectibles/star_coin.png", 74.0),
    "shield": ("collectibles/shield.png", 84.0),
}
for kind, (rel, target) in PICKUPS.items():
    w, h = size(rel)
    s = target / w
    write(f"scenes/gameplay/pickups/Pickup_{kind.capitalize()}.tscn", actor_scene(
        f"pkup{kind[:4]}0000000001", "scripts/gameplay/Pickup.gd",
        f"assets/sprites/{rel}", s,
        extra_root_props=f"radius = {target * 0.5:.2f}\n",
    ))

print("done.")
