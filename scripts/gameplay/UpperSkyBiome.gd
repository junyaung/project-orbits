class_name UpperSkyBiome
extends Node2D
## Layered visual system for the Upper Sky biome (0–300 m).
##
## Layers (z-order, back to front):
##   -100  base      — stitched A/B/C/D background (D = transition visual), world-space
##    -85  particles — sky dust + cloud mist CPUParticles
##    -80  gimmick   — wind-lane cue
##
## Overlay effect and decor set are intentionally not used — their watercolor
## content is cream/white, indistinguishable from the baked checker background
## at the pixel level, so no keying approach can separate them reliably.

# ── textures ──────────────────────────────────────────────────────────────────
const BG_TEX:   Texture2D = preload("res://assets/backgrounds/upper_sky_base.png")
const WIND_TEX: Texture2D = preload("res://assets/sprites/biomes/upper_sky/wind_lane.png")

# ── geometry constants ────────────────────────────────────────────────────────
const SCREEN_W:  float = 1080.0
const SCREEN_H:  float = 1920.0
const BIOME_END: float = 300.0   # biome ends at 300 m

# ── scene nodes ───────────────────────────────────────────────────────────────
var _base:      Sprite2D
var _wind_lane: Sprite2D
var _dust:      CPUParticles2D
var _mist:      CPUParticles2D

# ── state ─────────────────────────────────────────────────────────────────────
var _t:             float = 0.0
var _wind_visible:  bool  = false
var _wind_target_y: float = 0.0

# ─────────────────────────────────────────────────────────────────────────────

func setup(biome_base_y: float) -> void:
	_build_base(biome_base_y)
	_build_particles()
	_build_gimmicks()


## Call from GameplayController._process() each frame.
func update_state(delta: float, _distance_m: float, cam_y: float,
		_is_orbiting: bool, _orbit_ideal_frac: float) -> void:
	_t += delta
	_update_particles(cam_y)
	_animate_wind_lane(delta, cam_y)


## Show/hide wind-current-lane cue. world_y = midpoint between two planet Y positions.
func set_wind_lane(show: bool, world_y: float = 0.0) -> void:
	_wind_visible = show
	if show:
		_wind_target_y = world_y


# ─────────────────────────── builders ────────────────────────────────────────

func _build_base(biome_base_y: float) -> void:
	_base = Sprite2D.new()
	_base.texture = BG_TEX
	_base.centered = false
	_base.position = Vector2(0.0, biome_base_y - float(BG_TEX.get_height()))
	_base.z_index = -100
	add_child(_base)


func _build_particles() -> void:
	_dust = CPUParticles2D.new()
	_dust.emitting = true
	_dust.amount = 18
	_dust.lifetime = 6.0
	_dust.one_shot = false
	_dust.explosiveness = 0.0
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(540.0, 960.0)
	_dust.direction = Vector2(0.0, -1.0)
	_dust.spread = 60.0
	_dust.gravity = Vector2.ZERO
	_dust.initial_velocity_min = 8.0
	_dust.initial_velocity_max = 22.0
	_dust.scale_amount_min = 0.04
	_dust.scale_amount_max = 0.14
	_dust.color = Color(1.0, 0.98, 0.92, 0.18)
	_dust.z_index = -85
	add_child(_dust)

	_mist = CPUParticles2D.new()
	_mist.emitting = true
	_mist.amount = 5
	_mist.lifetime = 11.0
	_mist.one_shot = false
	_mist.explosiveness = 0.0
	_mist.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_mist.emission_rect_extents = Vector2(540.0, 960.0)
	_mist.direction = Vector2(1.0, 0.0)
	_mist.spread = 28.0
	_mist.gravity = Vector2.ZERO
	_mist.initial_velocity_min = 5.0
	_mist.initial_velocity_max = 11.0
	_mist.scale_amount_min = 0.35
	_mist.scale_amount_max = 0.85
	_mist.color = Color(0.94, 0.97, 1.0, 0.06)
	_mist.z_index = -85
	add_child(_mist)


func _build_gimmicks() -> void:
	_wind_lane = Sprite2D.new()
	_wind_lane.texture = WIND_TEX
	_wind_lane.centered = true
	var ws: float = SCREEN_W / float(WIND_TEX.get_width())
	_wind_lane.scale = Vector2(ws, ws)
	_wind_lane.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_wind_lane.z_index = -80
	add_child(_wind_lane)


# ─────────────────────────── animation helpers ───────────────────────────────

func _update_particles(cam_y: float) -> void:
	_dust.position = Vector2(540.0, cam_y)
	_mist.position = Vector2(540.0, cam_y)


func _animate_wind_lane(delta: float, cam_y: float) -> void:
	var target_alpha: float = 0.35 if _wind_visible else 0.0
	var cur_a: float = _wind_lane.modulate.a
	var speed: float = 2.5 if target_alpha > cur_a else 1.5
	_wind_lane.modulate.a = lerpf(cur_a, target_alpha, delta * speed)

	if _wind_lane.modulate.a > 0.01:
		var shimmer_y: float = sin(_t * 1.8) * 8.0
		var target_y: float = _wind_target_y if _wind_visible else cam_y - 350.0
		_wind_lane.position = Vector2(SCREEN_W * 0.5, target_y + shimmer_y)
