# ORBITS - Claude AI Game Development Handoff

**Date:** 2026-07-06  
**Purpose:** This document summarizes the full design, art direction, UI/UX, upgrade system, background system, and Godot implementation direction discussed for the game so Claude AI can continue development with minimal ambiguity.  
**Primary engine:** Godot 4.x  
**Primary target:** 2D vertical mobile game, portrait 9:16  
**Current status:** Core playable prototype scene is already working. The next work should focus on Home/meta UI, upgrade/equip/shop/character systems, biome backgrounds, animated background implementation, and polishing the result/death flow.

---

## 0. Executive Summary for Claude

The game is a **2D vertical mobile orbital slingshot game**. The player controls a small animal traveler, starting with a **cream-colored cat riding a blue manhole cover**, drifting through the sky and space by using planets' gravity.

The origin story is:

> A cat walks across a street and steps on a manhole cover. A sudden burst of water pressure launches the manhole cover into the sky, carrying the cat upward, eventually into space. The cat now rides the manhole cover from planet to planet using gravity slingshot mechanics.

The current gameplay prototype already exists: the player holds the screen to orbit around a planet and releases to launch toward the next planet. The game scrolls vertically upward. There are stars/coins, distance scoring, heat/overstay risk, hazards like meteors, and a result popup after death.

The final art direction is **soft pastel watercolor storybook space**:

- Pale sky-blue atmosphere
- Watercolor paper texture
- Soft rounded panels
- Cream-beige buttons
- Muted navy-gray text
- Gentle celestial backgrounds
- Dreamy but readable gameplay
- Cute but not childish
- Elegant, quiet, and memorable

The game should not look like a loud arcade game, neon sci-fi game, or aggressive mobile monetization product. It should feel like a gentle living watercolor illustration that slowly becomes stranger and more cosmic as the player travels farther.

The strongest identity hook is:

> **Small animal traveler + whimsical round object vehicle + soft sky/space + orbital drifting journey**

The first character is the cat, but future characters should include other animal travelers. Therefore UI labels should use **Travelers** or **Characters**, not Cats.

---

## 1. Current Core Gameplay Mechanic

### 1.1 Player action

The game is built around one-touch input:

1. When the player **holds** the screen, the character orbits around the nearest/captured planet.
2. When the player **releases**, the character launches in the tangent direction from the orbit.
3. The character flies until it enters another planet's gravitational capture range.
4. The player holds again to orbit and repeats.
5. The goal is to travel as far upward as possible.

### 1.2 Primary tension

The main decision is:

> Should I orbit one more moment to aim better, or release now before heat/danger builds?

The game should reward timing, rhythm, trajectory reading, and risk management.

### 1.3 Core variables

Recommended gameplay variables:

- `distance_m`: total vertical progress in meters
- `stars_collected`: run currency
- `perfect_slings`: count of well-timed launches
- `heat`: danger meter that rises while orbiting/overstaying
- `capture_radius`: distance at which a planet can capture the traveler
- `launch_speed`: velocity after release
- `gravity_strength`: pull around planet
- `biome_id`: current map/background biome

### 1.4 Hazards and rewards

Existing/desired elements:

- Stars/coins placed along paths
- Boost items
- Meteors/asteroids
- Heat/overheat risk
- Later biome-specific hazards

---

## 2. Narrative and World Identity

### 2.1 Starting synopsis

A small cat is walking normally when it steps onto a manhole cover. Suddenly, water pressure erupts from below, launching the cover into the air. The cat is carried upward, through the clouds, and eventually into space. The manhole cover becomes the cat's accidental vehicle.

The tone should be whimsical, poetic, and slightly absurd, not slapstick-heavy.

### 2.2 Long-term expansion

The cat is only the starting traveler. Later, add other animals and vehicles.

Recommended long-term identity:

> Small animal travelers riding strange round objects through sky and space.

Possible future travelers:

| Traveler | Vehicle | Suggested identity |
|---|---|---|
| Cat | Blue manhole cover | Balanced default |
| Bunny | Floating lunch tray | Slight launch bonus |
| Turtle | Bathtub lid | Shield/survival bonus |
| Fox | Red disc / paper fan | Star magnet bonus |
| Bird | Broken umbrella | Glide/capture bonus |
| Otter | Wooden basin | Cool drift bonus |
| Hamster | Bottle cap | Small hitbox / nimble feel |
| Raccoon | Trash can lid | Currency bonus |

At first, make Travelers cosmetic only or very small passive bonuses. Keep stats small, around 3-5%, so one Traveler does not dominate.

---

## 3. Art Direction Evolution and Final Direction

### 3.1 Earlier explored styles

The project explored several art directions:

- Crossy Road-inspired soft voxel
- Low-poly cosmic toybox
- Idle Tower Defense / Survivor.io-style mobile UI
- Don't Starve-inspired hand-drawn dark style
- Cute frog/sledding watercolor inspiration image
- Final shift to watercolor cat/manhole cover concept

The selected direction is the watercolor style inspired by a soft, hand-painted mobile video reference: simple character centered on a round vehicle, pale blue background, soft brush texture, minimal UI, dreamy and calming.

### 3.2 Final art direction name

Recommended internal name:

> **Watercolor Cosmic Drift**

Alternative branding phrase:

> **A living watercolor sky-space drift game**

### 3.3 Core art rules

Use these rules consistently:

- Soft pastel watercolor storybook style
- Gentle paper texture
- Muted navy-gray text
- Pale blue-gray panels
- Cream-beige capsule buttons
- Soft shadows, no hard black outlines
- Rounded forms
- No glossy plastic UI
- No harsh neon sci-fi UI
- No aggressive arcade color language
- Keep gameplay readable
- Center area may be lower contrast but should never become a blank vertical beam

### 3.4 Visual memory hook

Every major screen should reinforce at least one of these:

- Cat or animal traveler
- Blue manhole cover / round vehicle
- Pale sky or cosmic watercolor background
- Orbit/drift concept
- Soft celestial particles

---

## 4. Design Thinking Principles to Apply

A design-thinking summary was provided by the user and should guide all UI decisions. Core principles:

### 4.1 Communication over decoration

Do not ask only "does this look good?" Ask:

- Where does the player's eye go first?
- What is remembered after 3 seconds?
- Does the player know what to do next?
- Does the primary action stand out?

### 4.2 Perception gap

The UI should not require explanation. If a button/card needs verbal clarification, the hierarchy has failed.

Example: Upgrade cards must show what the upgrade does. A card titled only "Meadow Run" is not clear enough.

### 4.3 Emotional starting state

When a player dies and returns Home, they feel:

- Slightly disappointed
- Curious if they can improve
- Ready to retry if the UI encourages them

Therefore Home should not feel like a shop. It should feel like a calm launch hub that says:

> You can drift again, maybe farther this time.

### 4.4 Predictive empathy

Each screen should anticipate what the player wants next:

- After death: Retry / Home / upgrade hint
- On Home: Launch again or improve one thing
- On Upgrade: understand benefit and cost quickly
- On Equip: feel attached to Traveler/vehicle
- On Shop: browse gently, not feel pressured

### 4.5 Memory encoding

The player should remember the game as:

> The game where a small cat rides a manhole cover through beautiful strange space.

Do not dilute this identity with generic sci-fi UI.

### 4.6 Brand voice

ORBITS should speak softly, not aggressively.

Words that fit:

- Drift
- Launch
- Orbit
- Sky
- Soft landing
- One more orbit
- Farther today
- Traveler
- Little sky

Words to avoid:

- Kill streak
- Dominate
- Destroy
- Battle
- Hardcore
- Ultra mega
- Aggressive monetization language

Suggested brand line:

> **Little traveler. Big sky. One more orbit.**

For the current cat version:

> **Little cat. Big sky. One more orbit.**

---

## 5. Current Visual References and Assets

These are included in the attached asset folder.

### 5.1 Final cat concept reference

![Final cat concept](orbits_claude_handoff_assets/01_final_cat_concept_page.png)

Use this as the primary concept source for the cat + manhole cover identity.

### 5.2 Current result/death popup screenshot

![Current gameplay result popup](orbits_claude_handoff_assets/02_current_gameplay_result_popup.png)

Observed issue: the "new best" label previously overlapped with the flavor sentence. Best placement is directly above the distance value.

Correct result hierarchy:

```text
Cat sleeping on manhole cover
Splashdown
Short flavor sentence
new best badge
1831 m
star count / perfect count
Primary retry button
Secondary home button
```

### 5.3 Upgrade card issue

![Upgrade card issue](orbits_claude_handoff_assets/04_upgrade_card_issue.png)

The image generated with baked-in text "MEADOW RUN" is not ideal. Upgrade card images should be blank UI backgrounds with icons only. All text, level, cost, and effects should be Godot `Label` nodes.

### 5.4 Generated background examples

Dream Sky:

![Dream Sky](orbits_claude_handoff_assets/05_dream_sky_background.png)

Tachyon Drift:

![Tachyon Drift](orbits_claude_handoff_assets/06_tachyon_drift_background.png)

Dark Matter Reef:

![Dark Matter Reef](orbits_claude_handoff_assets/07_dark_matter_reef_background.png)

Wormhole Garden:

![Wormhole Garden](orbits_claude_handoff_assets/08_wormhole_garden_background.png)

Entropy Field:

![Entropy Field](orbits_claude_handoff_assets/09_entropy_field_background.png)

Final Dream Beyond current version:

![Final Dream Beyond](orbits_claude_handoff_assets/10_final_dream_beyond_background.png)

Note: Final Dream Beyond needs more iridescent aurora richness if used as a major final biome.

---

## 6. Result Popup / Death Screen Guidance

### 6.1 Current issue

The current result popup is close to the desired direction, but it must avoid overlapping text. The "new best" badge should not sit inside the flavor text.

### 6.2 Recommended layout

```text
[Cat sleeping on manhole cover]

Splashdown
Off into the quiet blue -
a new planet waits.

✦ new best ✦
1831 m

★ 51     ✧ 0 perfect

[Drift Again]
[Home] optional secondary
```

### 6.3 Style

- Panel: pale blue-gray rounded modal
- Button: cream-beige capsule
- Text: muted navy-gray
- New Best: small gold/cream pill badge
- Avoid red "game over"
- Failure should feel soft and encouraging

### 6.4 UX

Primary action: Retry / Drift Again  
Secondary action: Home  
Optional tertiary: Watch ad / revive, only later and not aggressive

---

## 7. Home / Meta UI System

The playable scene is mostly ready. Next, build the Home screen and meta UI.

### 7.1 Death -> Home flow

When the player dies:

```text
Gameplay death
-> Result popup
-> Player chooses Retry or Home
-> Home screen opens
-> Home shows current Traveler, currency, upgrade hints, Launch CTA
```

### 7.2 Home screen emotional goal

Home is not a store. It is a **quiet launch hub**.

The player should feel:

> I can try one more time. Maybe upgrade a little and drift farther.

### 7.3 Home visual hierarchy

1. Current selected Traveler on vehicle
2. Large Launch button
3. Upgrade available hint
4. Currency / best distance / progress
5. Bottom nav
6. Shop/equip/collection secondary elements

### 7.4 Recommended Home layout

```text
Top:
- Star currency chip
- Best distance chip or settings button

Center:
- Traveler preview floating on vehicle
- Soft sky/space backdrop
- Small progress card

Lower center:
- Large Launch button
- Small upgrade available badge

Bottom:
- Home / Upgrade / Equip / Travelers / Shop / Collection navigation
```

### 7.5 Bottom navigation labels

Use future-proof labels:

- Home
- Upgrade
- Equip
- Travelers
- Shop
- Collection

Do not use "Cats" because future characters will include other animals.

### 7.6 Required Home/meta UI scenes

Recommended Godot scene structure:

```text
HomeScreen.tscn
├── CanvasLayer
│   ├── Background
│   ├── TopBar
│   │   ├── StarChip
│   │   ├── BestDistanceChip
│   │   └── SettingsButton
│   ├── TravelerPreviewPanel
│   ├── ProgressCard
│   ├── LaunchButton
│   ├── UpgradeHintBadge
│   └── BottomNav
```

Other screens:

```text
UpgradeScreen.tscn
EquipScreen.tscn
TravelersScreen.tscn
ShopScreen.tscn
CollectionScreen.tscn
SettingsPopup.tscn
ResultPopup.tscn
PausePopup.tscn
```

---

## 8. UI Asset Generation Rules

### 8.1 Never bake dynamic text into sprites

All UI images should be blank panels/buttons/cards. Use Godot labels for:

- Title
- Level
- Cost
- Upgrade effect
- Button text
- Distance
- Stars
- Status labels

Reason: AI-generated text is hard to change and often inaccurate. Godot labels allow localization, balancing, and dynamic values.

### 8.2 Button states needed

Create sprites for:

- Normal
- Pressed
- Selected
- Disabled
- Locked
- Highlighted
- Warning
- Confirm

### 8.3 Card states needed

For upgrades/items/characters:

- Normal
- Selected
- Locked
- Owned
- Max level
- New
- Equipped

### 8.4 Style rules for all UI assets

- Pale blue-gray panels
- Cream-beige CTA buttons
- Muted navy-gray text
- Gold accents for currency/new best
- Soft rounded corners
- Subtle shadows
- No neon
- No glossy shop feel
- No red aggressive sale banners
- No clutter

---

## 9. Upgrade System

### 9.1 Do not use "Meadow Run" as final name

"Meadow Run" was used earlier and generated an upgrade card, but it is conceptually unclear. It sounds like a mode or level. Rename it to:

> **Meadow Drift**

This matches the game better because the player drifts/orbits rather than runs.

### 9.2 Upgrade categories

Recommended categories:

```text
Core
- Launch Power
- Gravity Grip
- Heat Capacity
- Cool Drift

Utility
- Star Magnet
- Shield Bubble

World Mastery
- Meadow Drift
- Galaxy Glide
- Kuiper Calm
- Oort Mist
- Void Sense
- Rift Balance
```

### 9.3 MVP upgrade list

Start with these 7 upgrades:

| Upgrade | Concept | Effect |
|---|---|---|
| Launch Power | Launch farther | Launch speed increase |
| Gravity Grip | Easier capture | Capture radius increase |
| Heat Capacity | Orbit longer | Heat max increase |
| Cool Drift | Cool down faster | Heat recovery increase |
| Star Magnet | Collect easier | Pickup radius increase |
| Shield Bubble | Mistake protection | Periodic / start shield |
| Meadow Drift | Meadow mastery | Meadow heat gain reduction |

### 9.4 Example upgrade values

Launch Power:

```text
Lv. 1: Launch speed +3%
Lv. 2: Launch speed +6%
Lv. 3: Launch speed +9%
```

Gravity Grip:

```text
Lv. 1: Gravity range +3%
Lv. 2: Gravity range +6%
Lv. 3: Gravity range +9%
```

Heat Capacity:

```text
Lv. 1: Heat capacity +5%
Lv. 2: Heat capacity +10%
Lv. 3: Heat capacity +15%
```

Cool Drift:

```text
Lv. 1: Heat recovery +5%
Lv. 2: Heat recovery +10%
Lv. 3: Heat recovery +15%
```

Star Magnet:

```text
Lv. 1: Pickup radius +8%
Lv. 2: Pickup radius +16%
Lv. 3: Pickup radius +24%
```

Meadow Drift:

```text
Lv. 1: Meadow heat gain -2%
Lv. 2: Meadow heat gain -4%
Lv. 3: Meadow heat gain -6%
Lv. 4: Meadow heat gain -8%
Lv. 5: Meadow heat gain -10%
Max: Meadow heat gain -15%
```

### 9.5 Upgrade card UI structure

Use this Godot structure:

```text
UpgradeCard.tscn
├── CardBackground
├── UpgradeIcon
├── TitleLabel          "MEADOW DRIFT"
├── LevelLabel          "Lv. 3"
├── EffectLabel         "Meadow heat -6%"
├── NextEffectLabel     "Next: -8%"
├── CostIcon
├── CostLabel           "124"
└── UpgradeButton
    └── ButtonLabel     "Upgrade"
```

### 9.6 Recommended display examples

Normal:

```text
MEADOW DRIFT
Lv. 3
Meadow heat -6%
[Upgrade] 124 ★
```

Selected:

```text
MEADOW DRIFT
Lv. 3 -> 4
Meadow heat -6%
Next: -8%
[Upgrade] 124 ★
```

Max:

```text
MEADOW DRIFT
MAX LEVEL
Meadow heat -15%
Mastered
```

Use `Mastered` or `Maxed`, not `Prepared`, if clarity is the priority.

---

## 10. Character / Traveler System

### 10.1 Naming

Use **Travelers** or **Characters**, not Cats.

Recommended UI labels:

- Travelers
- Character Card
- Traveler Preview
- Equip
- Current Loadout

### 10.2 Starting traveler

Default traveler:

```text
Cat + Blue Manhole Cover
```

### 10.3 Future traveler system

Implement data-driven traveler definitions:

```text
TravelerData
- id
- display_name
- sprite_idle
- sprite_launch
- sprite_surprised
- vehicle_id
- rarity
- owned
- equipped
- passive_type optional
- passive_value optional
```

### 10.4 Cosmetic vs stats

MVP: cosmetic only.  
Later: small passives, 3-5%, max.

---

## 11. Equip System

Equip should cover cosmetics and loadout:

- Traveler
- Vehicle / cover skin
- Trail effect
- Sparkle/impact effect

Recommended screen tabs:

```text
Travelers
Covers
Trails
Effects
```

But main bottom navigation can still show:

```text
Equip
```

Recommended data structure:

```text
LoadoutData
- traveler_id
- vehicle_skin_id
- trail_id
- effect_id
```

---

## 12. Shop System

The shop should feel like a gentle collection shop, not an aggressive monetization screen.

### 12.1 Shop categories

- Traveler skins
- Vehicle covers
- Trails
- Background themes
- Star packs later, optional

### 12.2 Shop rules

- No loud red sale banners
- No aggressive popups
- Avoid "limited mega deal" language
- Use soft ribbons, calm price chips, gold star currency

### 12.3 Shop item states

- Normal
- Selected
- Locked
- Owned
- Sold out
- Not enough stars

---

## 13. Biome / Map System

### 13.1 Backgrounds already generated or confirmed

Currently generated/visible map images:

1. Dream Sky / Upper Sky
2. Final Dream Beyond current version
3. Entropy Field
4. Tachyon Drift
5. Dark Matter Reef
6. Wormhole Garden

### 13.2 Maps needing recreation/reminder

The user explicitly wants to redo later:

- Pastel Galaxy Garden
- Kuiper Belt

### 13.3 Full biome candidate list

Recommended progression order:

```text
1. Dream Sky
2. Pastel Galaxy Garden
3. Kuiper Belt
4. Oort Cloud
5. Void Zone
6. Crystal Aurora Expanse
7. Entropy Field
8. Tachyon Drift
9. Dark Matter Reef
10. Wormhole Garden
11. Event Horizon Veil
12. Black Hole Cathedral
13. Quantum Foam Abyss
14. Dimensional Lattice
15. Time-Space Distortion / Rift Zone
16. Singularity Dream
17. Final Dream Beyond
```

### 13.4 Biome mood arc

The emotional progression should be:

```text
Bright sky -> beautiful galaxy -> cold outer space -> mysterious void -> dark cosmic phenomena -> dimensional surrealism -> transcendent final realm
```

### 13.5 Background format strategy

Do not rely on one static image endlessly repeating. There are two options:

#### Option A - Seamless tile
Good for simple sky/space gradients. Hard for AI to generate perfectly.

#### Option B - Segment system with crossfade
Recommended.

```text
BiomeSegment_A
-> 300-500px crossfade
BiomeSegment_B
-> transition segment
-> next biome
```

### 13.6 Background layering strategy

For each biome:

```text
BaseBackground PNG
OverlayLayerA PNG
OverlayLayerB PNG
Particles
Optional shader
```

This gives motion without relying on video loops.

---

## 14. Animated Background System in Godot

### 14.1 Why not use AI video loops for gameplay backgrounds

AI image-to-video tools such as Higgsfield/Kling often fail at true seamless looping. They produce first-to-last frame mismatch. Ping-pong looping can help for prototypes, but it reverses motion. The final gameplay background should be animated procedurally in Godot.

Use video only for:

- Title screen ambience
- Biome reveal
- Unlock cutscene
- Special portal moment

Do not rely on video loops for core gameplay background.

### 14.2 Recommended Godot scene

```text
AnimatedBiomeBackground.tscn
└── BackgroundRoot (Node2D)
    ├── BaseBackground (Sprite2D)
    ├── OverlayLayerA (Sprite2D)
    ├── OverlayLayerB (Sprite2D)
    ├── AccentContainer (Node2D)
    ├── SlowDustParticles (GPUParticles2D)
    ├── FastStreakParticles (GPUParticles2D)
    ├── GlowParticles (GPUParticles2D)
    ├── SoftTint (ColorRect or Sprite2D overlay, optional)
    └── AnimationPlayer
```

### 14.3 AnimatedBiomeBackground.gd requirements

Exported variables:

```gdscript
@export var biome_type: BiomeType
@export var base_texture: Texture2D
@export var overlay_texture_a: Texture2D
@export var overlay_texture_b: Texture2D
@export var particle_texture_dot: Texture2D
@export var particle_texture_streak: Texture2D
@export var motion_intensity: float = 1.0
@export var background_scroll_speed: float = 0.0
```

Biome enum:

```gdscript
enum BiomeType {
    DREAM_SKY,
    WORMHOLE_GARDEN,
    TACHYON_DRIFT,
    DARK_MATTER_REEF,
    ENTROPY_FIELD
}
```

Required functions:

```gdscript
setup_background()
fit_sprite_to_viewport(sprite: Sprite2D)
apply_biome_preset()
configure_wormhole_garden()
configure_tachyon_drift()
configure_dark_matter_reef()
configure_entropy_field()
setup_particles()
create_looping_animation()
set_biome(new_biome)
```

### 14.4 Biome-specific animation directions

#### Wormhole Garden

Desired motion:

- Spiral flower forms slowly rotate
- Tendrils sway gently
- Mist drifts slowly
- Tiny particles shimmer
- Motion feels magical, floral, subtle, cyclical

Suggested values:

```text
OverlayLayerA rotation: -1.5deg to +1.5deg over 8s loop
OverlayLayerB scale pulse: 0.985 to 1.015 over 6s loop
SlowDustParticles: low velocity, long lifetime
GlowParticles: tiny soft dots, low alpha
```

#### Tachyon Drift

Desired motion:

- Fast cyan streak particles diagonally across screen
- Small particles move quickly
- Subtle shimmer in light trails
- Forward drift sensation, but no camera movement

Suggested values:

```text
FastStreakParticles: high velocity, short lifetime
Direction: diagonal upward-right or upward-left
Amount: medium-high
Overlay alpha pulse: 0.75 to 0.95 over 3s loop
```

#### Dark Matter Reef

Desired motion:

- Reef-like shadow forms sway slowly
- Teal particles float
- Quiet alien ecosystem feeling

Suggested values:

```text
OverlayLayerA x drift: -8px to +8px over 7s
OverlayLayerB alpha: 0.6 to 0.85 over 5s
GlowParticles: teal dots, low speed, medium lifetime
```

#### Entropy Field

Desired motion:

- Fading dust drifts slowly
- Fragmented glow flickers gently
- Sparse and melancholic

Suggested values:

```text
SlowDustParticles: very low speed
GlowParticles: low amount, faint alpha
Overlay alpha pulse: extremely subtle
```

---

## 15. Godot Gameplay Scene Structure

Suggested main gameplay scenes:

```text
GameScene.tscn
├── AnimatedBiomeBackground
├── GameplayWorld (Node2D)
│   ├── Player / CatVehicle
│   ├── PlanetSpawner
│   ├── HazardSpawner
│   ├── CollectibleSpawner
│   └── Camera2D
├── GameplayHUD (CanvasLayer)
└── ResultPopup (CanvasLayer or Control)
```

### 15.1 CatVehicle scene

```text
CatVehicle.tscn
├── Node2D
├── Shadow (Sprite2D)
├── ManholeCover (Sprite2D)
├── CatBody (Sprite2D)
├── CatHead (Sprite2D)
├── CatFace (AnimatedSprite2D or Sprite2D)
├── Tail (Sprite2D)
├── LaunchTrailParticles (GPUParticles2D)
├── SparkleParticles (GPUParticles2D)
└── AnimationPlayer
```

### 15.2 Planet scene

```text
Planet.tscn
├── Area2D
├── SpriteBase (Sprite2D)
├── Face / StateOverlay optional
├── OrbitRing (Line2D or Sprite2D)
├── SteamParticles (GPUParticles2D)
├── CollisionShape2D
└── AnimationPlayer
```

### 15.3 HUD scene

```text
GameplayHUD.tscn
├── CanvasLayer
├── TopBar
│   ├── StarIcon
│   ├── StarLabel
│   ├── DistanceLabel
│   └── PauseButton
├── HeatBar (TextureProgressBar)
├── WarningBanner
└── TutorialLabel
```

---

## 16. Background Animation Implementation Prompt for Claude

Copy this section directly to Claude if asking it to implement the Godot background system.

```text
I am building a 2D vertical mobile game in Godot 4.x.

I already have painted static background images for different space biomes, such as:
- Wormhole Garden
- Tachyon Drift
- Dark Matter Reef
- Entropy Field
- Dream Sky

AI image-to-video tools do not loop seamlessly. I want to create animated living backgrounds directly inside Godot.

Goal:
Create a reusable Godot background system that makes a static watercolor background feel alive using:
1. A static base background PNG
2. Subtle moving overlay sprites
3. GPUParticles2D for drifting particles / streaks / dust
4. AnimationPlayer or Tween for slow breathing, rotation, alpha pulse, and drift
5. Optional shader distortion for very subtle atmospheric motion

The animation must be infinite and seamless because it is generated in Godot, not by playing a non-looping video.

Important art direction:
The game uses a soft pastel watercolor storybook art style.
The motion should feel like a living painting.
Do not make the motion aggressive, flashy, cyberpunk, neon, or chaotic.
The background should support gameplay readability.

Please implement this as a reusable scene:

Scene name:
AnimatedBiomeBackground.tscn

Recommended node structure:

AnimatedBiomeBackground (CanvasLayer or Node2D)
└── BackgroundRoot (Node2D)
    ├── BaseBackground (Sprite2D)
    ├── OverlayLayerA (Sprite2D)
    ├── OverlayLayerB (Sprite2D)
    ├── AccentContainer (Node2D)
    ├── SlowDustParticles (GPUParticles2D)
    ├── FastStreakParticles (GPUParticles2D)
    ├── GlowParticles (GPUParticles2D)
    ├── SoftTint (ColorRect or Sprite2D overlay, optional)
    └── AnimationPlayer

Script name:
AnimatedBiomeBackground.gd

Exported variables:
@export var biome_type: BiomeType
@export var base_texture: Texture2D
@export var overlay_texture_a: Texture2D
@export var overlay_texture_b: Texture2D
@export var particle_texture_dot: Texture2D
@export var particle_texture_streak: Texture2D
@export var motion_intensity: float = 1.0
@export var background_scroll_speed: float = 0.0

Biome enum:
enum BiomeType {
    DREAM_SKY,
    WORMHOLE_GARDEN,
    TACHYON_DRIFT,
    DARK_MATTER_REEF,
    ENTROPY_FIELD
}

Required helper functions:
- setup_background()
- fit_sprite_to_viewport(sprite: Sprite2D)
- apply_biome_preset()
- configure_wormhole_garden()
- configure_tachyon_drift()
- configure_dark_matter_reef()
- configure_entropy_field()
- setup_particles()
- create_looping_animation()
- set_biome(new_biome)

The system should work even if overlay textures are missing. If overlay_texture_a or overlay_texture_b is null, hide those Sprite2D nodes and continue.
The base background should always display.

For particles:
Use GPUParticles2D and ParticleProcessMaterial.
Use the exported particle textures.
Particles should be subtle and visually compatible with watercolor art.
Do not use harsh neon particles.
Use soft modulate colors and low alpha.

Prioritize:
1. Tachyon Drift - fast cyan streak particles, subtle forward drift, no camera movement.
2. Wormhole Garden - slow magical breathing, spiral rotation, mist drift, glowing particles.

Please make the script modular so I can add more biomes later.
```

---

## 17. Background Video / Higgsfield Notes

### 17.1 Aspect ratio

Use:

```text
9:16 vertical
1080 x 1920 or closest vertical resolution
```

### 17.2 Higgsfield/Kling prompt rules

Always include:

```text
Keep the camera completely locked.
Do not zoom, pan, tilt, rotate, or change composition.
Preserve the original watercolor art style.
Create a short seamless loop.
Do not create a beginning-to-end progression.
Do not build intensity over time.
The first and last frames should match naturally.
```

### 17.3 Loop problem discovered

AI video for Tachyon Drift did not loop because final frame had stronger cyan streaks and did not match first frame. A ping-pong loop was created as a prototype workaround, but final gameplay should use Godot procedural motion.

Included file:

```text
orbits_claude_handoff_assets/11_tachyon_pingpong_loop_preview.mp4
```

Use only as visual reference.

---

## 18. Prompt Library - UI Asset Generation

Use these with Nano Banana Pro or equivalent image generation tools.

### 18.1 Master UI Prompt

```text
Use the attached gameplay screenshot as the primary visual reference.

Design with a communication-first mindset, not decoration-first.

The UI should guide the player's eye clearly:
1. Main selected traveler riding the whimsical round vehicle
2. Primary Launch / Play button
3. Upgrade available or progress hint
4. Bottom navigation
5. Secondary actions such as Shop, Equip, Travelers, Collection, and Settings

Emotional context:
The player has just failed a run and returned Home.
The Home screen should feel calm, gentle, encouraging, and clear.
The player should feel: "I can try one more time, maybe go a little farther."

Memory hook:
Always preserve the identity of the game:
small animal traveler + whimsical round object vehicle + pale sky / soft space + gentle orbit journey.
The default starting character is a small cat riding a blue manhole cover.

Visual style:
soft pastel watercolor storybook UI, pale sky-blue tones, cream-beige buttons, pale blue-gray rounded panels, muted navy-gray text accents, soft shadows, thin gentle outlines, airy negative space, calm and elegant mobile game interface.

Avoid:
neon sci-fi UI, glossy plastic buttons, dark heavy panels, cluttered menus, aggressive arcade style, sharp black outlines, loud monetization banners, and anything that competes with the main Launch button.

Technical:
Create production-ready 2D UI sprite assets.
Use transparent background if possible.
If transparency is not possible, use pure white background.
Keep every asset isolated, centered, evenly spaced, and easy to slice.
Do not create a phone mockup.
Do not include unnecessary decorative clutter.
No readable text, no words, no numbers. Text will be added later in Godot.
```

### 18.2 Home UI asset board prompt

```text
Create a complete production-ready 2D UI asset board for the Home screen of a soft pastel watercolor mobile game.

Game context:
The player controls a small animal traveler riding a whimsical round object through the sky and space using orbital slingshot mechanics.
The default traveler is a cat on a blue manhole cover.
The player has just failed a run and returned Home.

Create these isolated UI assets:
1. Home main background panel
2. Traveler preview frame
3. Vehicle preview frame
4. Large Launch button - normal
5. Large Launch button - pressed
6. Large Launch button - highlighted
7. Upgrade available badge without text
8. Continue / Last Run card
9. Daily reward card
10. Mission card
11. Current progress card
12. Currency bar background
13. Star currency chip
14. Best distance chip
15. Bottom navigation bar background
16. Notification badge
17. Small soft tooltip bubble
18. Section header plaque
19. Empty rounded card - small
20. Empty rounded card - medium
21. Empty rounded card - large

No readable text, no words, no numbers.
The Launch button must visually dominate.
Secondary cards must not compete with Launch.
```

### 18.3 Upgrade UI prompt

```text
Create production-ready 2D UI sprites for an Upgrade screen in a soft pastel watercolor mobile game.

Design goal:
The Upgrade screen should feel like quiet preparation before the next launch.
The player should immediately understand: choose an upgrade, see its level, pay stars, and launch farther next time.

Create these isolated assets:
1. Upgrade card background - normal
2. Upgrade card background - selected with soft warm glow
3. Upgrade card background - max level
4. Upgrade card background - locked
5. Small upgrade illustration frame
6. Large selected upgrade detail panel
7. Cost chip background
8. Level badge background
9. Effect row background
10. Next effect row background
11. Upgrade button - normal
12. Upgrade button - pressed
13. Upgrade button - disabled
14. Max level button background
15. Selected highlight border
16. Soft star cost badge
17. Upgrade available notification badge
18. Category tab - normal
19. Category tab - selected
20. Empty upgrade card without text

Upgrade themes to visually support:
Launch Power, Gravity Grip, Heat Capacity, Cool Drift, Star Magnet, Shield Bubble, Meadow Drift.

No readable text, no words, no numbers.
Text and numbers will be added later in Godot.
```

---

## 19. Prompt Library - Backgrounds to Recreate Later

### 19.1 Pastel Galaxy Garden - needs redo

```text
Use the attached gameplay screenshot as the main visual style reference.

Create a production-ready 2D vertical mobile game background segment for an endless upward-scrolling game.

Theme:
Pastel Galaxy Garden.

Art direction:
soft pastel watercolor storybook style, dreamy, magical, elegant, airy, and serene.
Show a beautiful painted galaxy with lavender nebula clouds, dusty pink cosmic mist, pale sky-blue haze, soft gold star dust, and gentle swirling watercolor textures.
The galaxy should feel poetic, soft, and inviting, not intense or flashy.

Composition requirements:
- 1080 x 1920 vertical mobile background.
- Designed for an upward-scrolling Godot game.
- The image should work as a scrolling background segment that can crossfade into the next segment.
- Keep the top and bottom edges soft, atmospheric, and low-detail so they can blend naturally with other backgrounds.
- Do not create a blank vertical strip, spotlight column, beam-like gap, or empty corridor in the middle.
- The center should remain readable for gameplay, but it must still contain soft watercolor nebula texture, faint stars, mist, and natural visual continuity.
- Use lower contrast in the center, not empty space.
- Distribute nebula, star dust, and mist naturally across the full canvas, with slightly richer detail near the edges and corners.
- Avoid hard borders, sharp shapes, and obvious repeated landmarks.

Important:
Background only. No UI. No text. No characters. No coins. No planets. No hazards. No foreground gameplay objects.
No neon sci-fi look. No realistic astronomy rendering. No dark heavy contrast.
```

### 19.2 Kuiper Belt - needs redo

```text
Use the attached gameplay screenshot as the main visual style reference.

Create a production-ready 2D vertical mobile game background segment for an endless upward-scrolling game.

Theme:
Kuiper Belt.

Art direction:
soft pastel watercolor storybook style, quiet outer space, cold, distant, elegant, and lonely-but-beautiful.
Show a sparse outer solar system region with pale icy dust, silver-blue watercolor haze, faint lavender shadows, tiny distant stars, and soft drifting particulate texture.
The scene should feel like the traveler has moved far from the warm sky into a colder and quieter region of space.

Color palette:
icy blue, pale lavender, silver-gray, muted indigo, cold cream highlights.

Composition requirements:
- 1080 x 1920 vertical mobile background.
- Designed for upward scrolling in Godot.
- Top and bottom edges should stay soft and blendable for crossfade transitions.
- Do not create a blank vertical strip, spotlight column, beam-like gap, or empty corridor in the middle.
- The center should remain readable but still include gentle icy haze, faint dust, subtle stars, and watercolor texture.
- Use sparse detail across the full canvas.
- Slightly richer icy dust and faint particulate texture can appear near the edges and far background.
- Avoid large unique objects that make the background feel like a single static illustration.

Important:
Background only. No UI. No text. No characters. No coins. No planets. No hazards. No foreground gameplay objects.
No aggressive sci-fi energy. No realistic asteroid field. No cluttered star field.
```

---

## 20. Immediate Development Checklist for Claude

### Phase 1 - Clean prototype architecture

- Ensure gameplay scene is modular
- Separate player, planet, hazard, collectible, background, HUD
- Keep UI dynamic through Godot labels
- Do not bake important text into images

### Phase 2 - Result popup and Home flow

- Fix result popup layout
- Move `new best` badge above distance
- Add Home button
- Implement Death -> Result -> Home / Retry flow

### Phase 3 - Home screen

- Build HomeScreen.tscn
- Add Launch CTA
- Add selected Traveler preview
- Add currency chips
- Add bottom nav
- Add upgrade hint

### Phase 4 - Upgrade system

- Implement UpgradeData resources or dictionary
- Add seven MVP upgrades
- Apply upgrade effects to gameplay variables
- Save upgrade levels

### Phase 5 - Travelers and Equip

- Build data-driven Traveler system
- Rename UI from Cats to Travelers/Characters
- Add Equip screen with loadout
- Keep future animal expansion in mind

### Phase 6 - Animated backgrounds

- Implement AnimatedBiomeBackground.tscn
- Use base PNG + particles + overlays
- Start with Tachyon Drift and Wormhole Garden
- Do not use AI video loops as final gameplay solution

### Phase 7 - Biome progression

- Add distance-based biome changes
- Use crossfade transitions between background segments
- Track current biome
- Later add biome-specific hazards and planets

---

## 21. Save Data Requirements

Recommended save data:

```json
{
  "stars_total": 0,
  "best_distance": 0,
  "selected_traveler_id": "cat_default",
  "selected_vehicle_skin_id": "manhole_blue_default",
  "selected_trail_id": "trail_default",
  "selected_effect_id": "effect_default",
  "upgrade_levels": {
    "launch_power": 0,
    "gravity_grip": 0,
    "heat_capacity": 0,
    "cool_drift": 0,
    "star_magnet": 0,
    "shield_bubble": 0,
    "meadow_drift": 0
  },
  "owned_travelers": ["cat_default"],
  "owned_vehicle_skins": ["manhole_blue_default"],
  "owned_trails": ["trail_default"],
  "unlocked_biomes": ["dream_sky"]
}
```

---

## 22. Final North Star

This game should feel like:

> A small animal traveler quietly drifting through a living watercolor universe, using gravity to leap from one strange planet to the next.

It should not feel like:

- A loud arcade game
- A generic space runner
- A neon sci-fi tunnel
- A shop-first mobile game
- A purely cosmetic image project

The visual, UX, and gameplay should all support one emotional loop:

```text
Fail softly -> feel encouraged -> upgrade or equip -> launch again -> reach a stranger and more beautiful biome -> remember the journey
```

---

## 23. Notes to Claude

When implementing, prioritize clarity and modularity over overengineering.

The user's prototype is already working, so do not restart from scratch unless necessary. Improve the existing project by adding:

1. Home/meta UI
2. Upgrade system
3. Traveler/equip system
4. Animated background system
5. Biome progression
6. Result popup polish

Keep all art and UI consistent with the included references.

Most important instruction:

> Do not rely on non-looping AI videos for gameplay backgrounds. Use Godot procedural particles/overlays/animations so motion is truly seamless.
