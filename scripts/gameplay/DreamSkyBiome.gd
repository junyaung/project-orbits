class_name DreamSkyBiome
extends Node2D
## Background for the biome after Upper Sky (~1500m+). Placeholder: only one
## source segment exists so far (map_dream sky_1.png), repeated with the same
## crossfade technique as Upper Sky until the user adds real A/B/C +
## transition variants (see tools/prep_dream_sky.py).
##
## Starts invisible (modulate.a = 0). update_state() fades it in over the
## 1200–1600m window, matching BiomeTransitionLayer and UpperSkyBiome so
## the three layers blend simultaneously rather than cutting.

const TILE_DIR:    String = "res://assets/backgrounds/dream_sky/"
const EDGE_SHADER: Shader = preload("res://assets/shaders/organic_edge_fade.gdshader")

const T_START  := 1200.0
const T_END    := 1600.0
## Must match BIOME_OVERLAP_PX in GameplayController — the overlap is the
## zone where both biomes are rendered and the shaders dissolve their edges.
const FADE_PX  := 1920.0

var _base:     Sprite2D
var _stars:    CPUParticles2D
var _stardust: CPUParticles2D


func setup(anchor_bottom_y: float) -> void:
	modulate.a = 0.0
	_build_base(anchor_bottom_y)
	_build_particles()


func _build_base(anchor_bottom_y: float) -> void:
	var total_h: float = _load_total_h()
	var top_world: float = anchor_bottom_y - total_h
	var r: float = 0.0
	var i: int = 0
	var last_sp: Sprite2D = null
	var last_h: float = 0.0
	while true:
		var path: String = "%stile_%d.png" % [TILE_DIR, i]
		if not ResourceLoader.exists(path):
			break
		var tex: Texture2D = load(path)
		if tex == null:
			break
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = false
		sp.position = Vector2(0.0, top_world + r)
		sp.z_index = -100
		add_child(sp)
		if i == 0:
			_base = sp
		last_sp = sp
		last_h = float(tex.get_height())
		r += last_h
		i += 1
	# The last tile is the BOTTOMMOST tile — its bottom edge extends into
	# Upper Sky territory (the overlap zone). Dissolve it so the seam vanishes.
	if last_sp != null:
		var mat := ShaderMaterial.new()
		mat.shader = EDGE_SHADER
		mat.set_shader_parameter("bottom_fade", minf(FADE_PX / last_h, 0.65))
		mat.set_shader_parameter("noise_amount", 0.06)
		mat.set_shader_parameter("noise_scale", 8.0)
		last_sp.material = mat


func _build_particles() -> void:
	# Fine star sparks — small, fast, cool white-lavender
	_stars = CPUParticles2D.new()
	_stars.emitting = true
	_stars.amount = 20
	_stars.lifetime = 5.0
	_stars.one_shot = false
	_stars.explosiveness = 0.0
	_stars.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_stars.emission_rect_extents = Vector2(540.0, 960.0)
	_stars.direction = Vector2(0.0, -1.0)
	_stars.spread = 40.0
	_stars.gravity = Vector2.ZERO
	_stars.initial_velocity_min = 4.0
	_stars.initial_velocity_max = 14.0
	_stars.scale_amount_min = 0.03
	_stars.scale_amount_max = 0.10
	_stars.color = Color(0.90, 0.85, 1.0, 0.55)
	_stars.z_index = -85
	add_child(_stars)

	# Slow lavender stardust wisps — large, low-alpha, drifting diagonally
	_stardust = CPUParticles2D.new()
	_stardust.emitting = true
	_stardust.amount = 8
	_stardust.lifetime = 9.0
	_stardust.one_shot = false
	_stardust.explosiveness = 0.0
	_stardust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_stardust.emission_rect_extents = Vector2(540.0, 960.0)
	_stardust.direction = Vector2(0.15, -1.0)
	_stardust.spread = 20.0
	_stardust.gravity = Vector2.ZERO
	_stardust.initial_velocity_min = 3.0
	_stardust.initial_velocity_max = 8.0
	_stardust.scale_amount_min = 0.25
	_stardust.scale_amount_max = 0.65
	_stardust.color = Color(0.62, 0.55, 0.88, 0.20)
	_stardust.z_index = -85
	add_child(_stardust)


func update_state(_delta: float, distance_m: float, cam_y: float) -> void:
	var raw_t := inverse_lerp(T_START, T_END, distance_m)
	var t := clampf(raw_t, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	modulate.a = t
	_stars.position = Vector2(540.0, cam_y)
	_stardust.position = Vector2(540.0, cam_y)


func _load_total_h() -> float:
	var f := FileAccess.open("%smeta.json" % TILE_DIR, FileAccess.READ)
	if f == null:
		return 15015.0   # fallback matching the current placeholder length
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and parsed.has("total_h"):
		return float(parsed["total_h"])
	return 15015.0
