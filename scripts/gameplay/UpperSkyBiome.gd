class_name UpperSkyBiome
extends Node2D
## Layered visual system for the Upper Sky biome (0–300 m).
##
## Layers (z-order, back to front):
##   -100  base      — stitched A/B/C background, world-space
##    -95  decor     — pre-placed cloud/sparkle sprites at screen edges
##    -90  overlay   — atmospheric mist sheet, drift + alpha breathing
##    -88  transition — magical overlay, fades in at 90% biome progress
##    -85  particles — sky dust + cloud mist CPUParticles
##    -80  gimmick   — wind-lane cue + sling-trail cue

# ── textures ──────────────────────────────────────────────────────────────────
const BG_TEX:    Texture2D = preload("res://assets/backgrounds/upper_sky_base.png")
const OV_TEX:    Texture2D = preload("res://assets/sprites/biomes/upper_sky/overlay.png")
const WIND_TEX:  Texture2D = preload("res://assets/sprites/biomes/upper_sky/wind_lane.png")
const TRAIL_TEX: Texture2D = preload("res://assets/sprites/biomes/upper_sky/sling_trail.png")
const TRANS_TEX: Texture2D = preload("res://assets/sprites/biomes/upper_sky/transition.png")

const DECOR_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/biomes/upper_sky/decor/decor_00.png"),
	preload("res://assets/sprites/biomes/upper_sky/decor/decor_01.png"),
	preload("res://assets/sprites/biomes/upper_sky/decor/decor_02.png"),
	preload("res://assets/sprites/biomes/upper_sky/decor/decor_03.png"),
	preload("res://assets/sprites/biomes/upper_sky/decor/decor_04.png"),
	preload("res://assets/sprites/biomes/upper_sky/decor/decor_05.png"),
	preload("res://assets/sprites/biomes/upper_sky/decor/decor_06.png"),
	preload("res://assets/sprites/biomes/upper_sky/decor/decor_07.png"),
	preload("res://assets/sprites/biomes/upper_sky/decor/decor_08.png"),
	preload("res://assets/sprites/biomes/upper_sky/decor/decor_09.png"),
	preload("res://assets/sprites/biomes/upper_sky/decor/decor_10.png"),
	preload("res://assets/sprites/biomes/upper_sky/decor/decor_11.png"),
]

# ── geometry constants ────────────────────────────────────────────────────────
const SCREEN_W:   float = 1080.0
const SCREEN_H:   float = 1920.0
const PIX_PER_M:  float = 10.0
const BIOME_END:  float = 300.0
const SRC_W:      float = 1536.0
const SHEET_SCALE: float = SCREEN_W / SRC_W   # ≈ 0.703

# Overlay alpha target per phase (0 = 0–33%, 1 = 33–66%, 2 = 66–90%, 3 = 90–100%)
const OV_ALPHA: Array[float] = [0.20, 0.28, 0.35, 0.38]

# ── scene nodes ───────────────────────────────────────────────────────────────
var _base:        Sprite2D
var _overlay:     Sprite2D
var _transition:  Sprite2D
var _wind_lane:   Sprite2D
var _sling_trail: Sprite2D
var _dust:        CPUParticles2D
var _mist:        CPUParticles2D
var _decor_nodes: Array[Sprite2D] = []

# ── state ─────────────────────────────────────────────────────────────────────
var _biome_base_y:  float = 0.0
var _t:             float = 0.0
var _wind_visible:  bool  = false
var _wind_target_y: float = 0.0

# ── overlay precomputed height ────────────────────────────────────────────────
var _ov_h: float = 0.0
var _tr_h: float = 0.0   # transition sprite height at game scale

# ─────────────────────────────────────────────────────────────────────────────

func setup(biome_base_y: float) -> void:
	_biome_base_y = biome_base_y
	_ov_h = float(OV_TEX.get_height()) * SHEET_SCALE
	var tr_scale: float = SCREEN_W / float(TRANS_TEX.get_width())
	_tr_h = float(TRANS_TEX.get_height()) * tr_scale
	_build_base()
	# NOTE: overlay, decor, transition, and sling_trail assets have baked-in
	# checker backgrounds that cannot be reliably keyed (cream art ≈ checker).
	# They need re-export with real alpha transparency before being enabled here.
	# _build_overlay()
	# _build_transition()
	# _build_decor()
	_build_particles()
	_build_gimmicks()   # wind_lane is clean (8% checker); sling_trail disabled below


## Call from GameplayController._process() each frame.
## orbit_ideal_frac: 0.0 = bad launch angle, 1.0 = ideal upward sling.
func update_state(delta: float, distance_m: float, cam_y: float,
		is_orbiting: bool, orbit_ideal_frac: float) -> void:
	_t += delta
	var progress: float = clampf(distance_m / BIOME_END, 0.0, 1.0)
	if _overlay != null:
		_animate_overlay(delta, progress, cam_y)
	if _transition != null:
		_animate_transition(delta, progress, cam_y)
	if _decor_nodes.size() > 0:
		_animate_decor(delta)
	_update_particles(cam_y)
	if _sling_trail != null:
		_animate_sling_trail(delta, is_orbiting, orbit_ideal_frac, cam_y)
	_animate_wind_lane(delta, cam_y)


## Show/hide wind-current-lane cue. world_y = midpoint between two planet Y positions.
func set_wind_lane(show: bool, world_y: float = 0.0) -> void:
	_wind_visible = show
	if show:
		_wind_target_y = world_y


# ─────────────────────────── builders ────────────────────────────────────────

func _build_base() -> void:
	_base = Sprite2D.new()
	_base.texture = BG_TEX
	_base.centered = false
	_base.position = Vector2(0.0, _biome_base_y - float(BG_TEX.get_height()))
	_base.z_index = -100
	add_child(_base)


func _build_overlay() -> void:
	_overlay = Sprite2D.new()
	_overlay.texture = OV_TEX
	_overlay.centered = false
	_overlay.scale = Vector2(SHEET_SCALE, SHEET_SCALE)
	_overlay.position = Vector2(0.0, _biome_base_y - _ov_h * 0.5)
	_overlay.modulate = Color(1.0, 1.0, 1.0, OV_ALPHA[0])
	_overlay.z_index = -90
	add_child(_overlay)


func _build_transition() -> void:
	_transition = Sprite2D.new()
	_transition.texture = TRANS_TEX
	_transition.centered = false
	var ts: float = SCREEN_W / float(TRANS_TEX.get_width())
	_transition.scale = Vector2(ts, ts)
	_transition.position = Vector2(0.0, _biome_base_y - 2700.0 - _tr_h)
	_transition.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_transition.z_index = -88
	add_child(_transition)


func _build_decor() -> void:
	const N_DECOR: int = 36
	var biome_h: float = BIOME_END * PIX_PER_M

	for i: int in N_DECOR:
		var idx: int = randi() % DECOR_TEXTURES.size()
		var tex: Texture2D = DECOR_TEXTURES[idx]
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = false
		sp.scale = Vector2(SHEET_SCALE, SHEET_SCALE)

		var dw: float = float(tex.get_width()) * SHEET_SCALE
		var dh: float = float(tex.get_height()) * SHEET_SCALE

		# place at left or right edge, away from center gameplay lane
		var x: float
		if randf() < 0.5:
			x = randf_range(-dw * 0.25, 240.0 - dw * 0.5)
		else:
			x = randf_range(840.0, SCREEN_W - dw * 0.4)

		var frac: float = float(i) / float(N_DECOR)
		var slot_h: float = biome_h / float(N_DECOR)
		var y: float = _biome_base_y - frac * biome_h - randf_range(0.0, slot_h) - dh * 0.5

		sp.position = Vector2(x, y)

		var base_alpha: float
		if dw > 500.0:
			base_alpha = randf_range(0.30, 0.55)
		elif dw > 250.0:
			base_alpha = randf_range(0.22, 0.45)
		else:
			base_alpha = randf_range(0.15, 0.32)

		sp.modulate = Color(1.0, 1.0, 1.0, base_alpha)
		sp.z_index = -95

		# per-sprite animation params stored in metadata
		sp.set_meta("base_alpha", base_alpha)
		sp.set_meta("drift_x", randf_range(-7.0, 7.0))
		sp.set_meta("drift_y", randf_range(-3.5, -0.8))
		sp.set_meta("twinkle_phase", randf_range(0.0, TAU))
		sp.set_meta("twinkle_speed", randf_range(0.25, 1.1))

		_decor_nodes.append(sp)
		add_child(sp)


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
	# sling_trail disabled — asset has baked checker background (needs re-export)


# ─────────────────────────── animation helpers ───────────────────────────────

func _phase(progress: float) -> int:
	if progress < 0.33:
		return 0
	elif progress < 0.66:
		return 1
	elif progress < 0.90:
		return 2
	return 3


func _animate_overlay(delta: float, progress: float, cam_y: float) -> void:
	var target_alpha: float = OV_ALPHA[_phase(progress)]
	var cur_alpha: float = _overlay.modulate.a
	var new_alpha: float = lerpf(cur_alpha, target_alpha, delta * 0.4)
	var breath: float = sin(_t * 0.9) * 0.05
	_overlay.modulate.a = clampf(new_alpha + breath, 0.10, 0.45)
	# subtle horizontal drift (±12 px) and vertical centering on camera
	var drift_x: float = sin(_t * 0.52) * 12.0
	_overlay.position = Vector2(drift_x, cam_y - _ov_h * 0.5)


func _animate_transition(delta: float, progress: float, cam_y: float) -> void:
	var target_a: float
	if progress < 0.85:
		target_a = 0.0
	else:
		target_a = remap(progress, 0.85, 1.0, 0.0, 0.90)
	_transition.modulate.a = lerpf(_transition.modulate.a, float(target_a), delta * 0.8)
	# keep transition screen-filling and centered on camera
	_transition.position = Vector2(0.0, cam_y - _tr_h * 0.5)


func _animate_decor(delta: float) -> void:
	for sp: Sprite2D in _decor_nodes:
		var drift_x: float = float(sp.get_meta("drift_x"))
		var drift_y: float = float(sp.get_meta("drift_y"))
		var twinkle_phase: float = float(sp.get_meta("twinkle_phase"))
		var twinkle_speed: float = float(sp.get_meta("twinkle_speed"))
		var base_alpha: float = float(sp.get_meta("base_alpha"))

		sp.position.x += drift_x * delta
		sp.position.y += drift_y * delta

		var tw: float = sin(_t * twinkle_speed + twinkle_phase) * 0.08
		sp.modulate.a = clampf(base_alpha + tw, 0.04, 0.85)


func _update_particles(cam_y: float) -> void:
	_dust.position = Vector2(540.0, cam_y)
	_mist.position = Vector2(540.0, cam_y)


func _animate_sling_trail(delta: float, is_orbiting: bool, ideal_frac: float, cam_y: float) -> void:
	var target_alpha: float
	if is_orbiting and ideal_frac > 0.55:
		target_alpha = remap(ideal_frac, 0.55, 1.0, 0.0, 0.55)
	else:
		target_alpha = 0.0

	var cur_a: float = _sling_trail.modulate.a
	var speed: float = 1.8 if target_alpha > cur_a else 2.8
	_sling_trail.modulate.a = lerpf(cur_a, target_alpha, delta * speed)

	if _sling_trail.modulate.a > 0.02:
		var pulse: float = 1.0 + sin(_t * 3.0) * 0.06
		var ss: float = (SCREEN_W / float(TRAIL_TEX.get_width())) * pulse
		_sling_trail.scale = Vector2(ss, ss)
		_sling_trail.position = Vector2(SCREEN_W * 0.5, cam_y - SCREEN_H * 0.30)


func _animate_wind_lane(delta: float, cam_y: float) -> void:
	var target_alpha: float = 0.35 if _wind_visible else 0.0
	var cur_a: float = _wind_lane.modulate.a
	var speed: float = 2.5 if target_alpha > cur_a else 1.5
	_wind_lane.modulate.a = lerpf(cur_a, target_alpha, delta * speed)

	if _wind_lane.modulate.a > 0.01:
		var shimmer_y: float = sin(_t * 1.8) * 8.0
		var target_y: float = _wind_target_y if _wind_visible else cam_y - 350.0
		_wind_lane.position = Vector2(SCREEN_W * 0.5, target_y + shimmer_y)
