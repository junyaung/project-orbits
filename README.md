# ORBITS — Cat & Manhole (Godot 4.7 prototype)

> *"An ordinary stray cat rides a manhole cover all the way into space."*

A cozy watercolor one-touch orbital slingshot. Hold to orbit a planet, release to
sling along the tangent toward the next one. Don't overheat, don't hit the rocks.

Built from the two design docs in this folder (`orbits_cat_manhole_production_bible_final_kr.pdf`,
`orbiting cat_godot_mvp_setup_guide_kr.pdf`) and the concept art in `images/`.

## Play

Open the project in **Godot 4.7** and press ▶ (main scene is `scenes/gameplay/Gameplay.tscn`),
or from the command line:

```
"/path/to/Godot" --path .
```

- **Hold** (mouse / touch / Space) — orbit the nearest planet. The white arrow shows your launch direction.
- **Release** — sling off along the tangent.
- Grab **star coins** for score and **shields** for one-hit protection.
- The **heat bar** fills while you orbit — linger too long and the planet overheats (fail). Flying cools it down.
- Avoid **drift rocks** and **meteors**. Fall back to Earth or drift off-screen and the run ends.
- On the result card, hit **Retry**.

Dev aid: launch with `++ --autoplay` to let the cat sling itself (used for automated testing).

## How the sprites were made

The concept sheets in `images/` are multi-item reference pages on white backgrounds.
`tools/slice_sprites.py` (pure PIL) crops each item, flood-fills the white background to
transparency, erodes the halo, and auto-crops — writing game-ready PNGs into
`assets/sprites/`. Re-run with `python3 tools/slice_sprites.py`.

## Structure

```
scenes/gameplay/Gameplay.tscn      main scene (Node2D + GameplayController.gd)
scripts/
  gameplay/GameplayController.gd   world build, hold→orbit→release physics, heat, spawning, fail/retry
  gameplay/Planet.gd               orbit radius, dotted ring, heat tint + steam
  gameplay/Pickup.gd               star / shield
  gameplay/Hazard.gd               drift rock / meteor
  actors/CatVehicle.gd             cat-on-cover, expression swaps, squash & tilt
  ui/GameplayHUD.gd                stars, distance, heat bar, warning, result card
assets/sprites/                    sliced, transparent game sprites
tools/slice_sprites.py             concept-sheet -> sprite slicer
```

## MVP checklist (from the bible) — all met

- [x] Cat + manhole clearly readable in a portrait screen
- [x] hold / release / orbit / launch loop understandable in seconds
- [x] Multiple planet types (meadow, cloud, ruin, dune, overheat), 2 hazards, star + shield
- [x] Heat system visualized (bar + warm planet tint + steam + warning banner)
- [x] Result screen with distance / stars / perfect slings + instant Retry
- [x] Endless procedural planets so a run lasts well past 30s
