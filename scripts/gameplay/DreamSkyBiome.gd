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

const TILE_DIR:    String = "res://assets/backgrounds/2. dream sky/"
const EDGE_SHADER: Shader = preload("res://assets/shaders/organic_edge_fade.gdshader")

const T_START  := 1200.0
const T_END    := 1600.0
## Must match BIOME_OVERLAP_PX in GameplayController — the overlap is the
## zone where both biomes are rendered and the shaders dissolve their edges.
const FADE_PX  := 1920.0

var _base:        Sprite2D
var _stars:       CPUParticles2D
var _stardust:    CPUParticles2D
var _top_world_y: float = 0.0   # exposed to GameplayController for next-biome anchoring

## Fade-out window when Pastel Galaxy Garden takes over.
## DreamSky tiles now reach exactly 3000m; cross-fade over the final 400m so
## PastelGalaxy is fully in by the time DreamSky art runs out.
const T_FADE_OUT_START := 2720.0
const T_FADE_OUT_END   := 2980.0


func setup(anchor_bottom_y: float) -> void:
	modulate.a = 0.0
	_build_base(anchor_bottom_y)
	_build_particles()


func get_top_world_y() -> float:
	return _top_world_y


## Overlap band at each internal tile seam. Large enough that the CONTENT
## of the upper tile (clouds, mountains, terrain features) dissolves organically
## into the lower tile over a visible screen distance — not just hiding a 1px
## rendering gap, but actually cross-fading the art. ~600px ≈ 30% of the
## 1920px viewport, which gives enough room for the noise-distorted edge to
## look like drifting mist rather than a straight cut.
const SEAM_PX: float = 600.0

func _build_base(anchor_bottom_y: float) -> void:
	var total_h: float = _load_total_h()

	# Pre-load all tiles so we know the count before placing them (needed for
	# the z_index calculation that keeps upper tiles in front, AND to compute
	# the correct top_world offset below).
	var textures: Array[Texture2D] = []
	var idx: int = 0
	while true:
		var path: String = "%stile_%d.png" % [TILE_DIR, idx]
		if not ResourceLoader.exists(path):
			break
		var tex: Texture2D = load(path)
		if tex == null:
			break
		textures.append(tex)
		idx += 1

	var n: int = textures.size()

	# Each internal seam pulls a tile UP by SEAM_PX, shrinking the stack's total
	# visual height by (n-1)*SEAM_PX.  Compensate by raising top_world by the
	# same amount so the BOTTOM of the stack still lands at anchor_bottom_y.
	# Without this, dream sky would end (n-1)*SEAM_PX short of Upper Sky's top,
	# leaving a gap where only the plain background shows — the visible seam line.
	var seam_shrink: float = maxf(0.0, (n - 1) * SEAM_PX)
	var top_world: float = anchor_bottom_y - total_h + seam_shrink

	var r: float = 0.0
	var seam_offset: float = 0.0   # grows by SEAM_PX at each inter-tile boundary
	for i in n:
		var tex: Texture2D = textures[i]
		var h: float = float(tex.get_height())
		var is_first: bool = (i == 0)
		var is_last: bool  = (i == n - 1)

		# Accumulate the overlap shift: tile_1 pulls up by 1×SEAM_PX,
		# tile_2 by 2×SEAM_PX, tile_3 by 3×SEAM_PX, so every adjacent pair
		# overlaps by exactly SEAM_PX regardless of tile index.
		if not is_first:
			seam_offset += SEAM_PX

		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = false
		sp.position = Vector2(0.0, top_world + r - seam_offset)
		# Upper tiles must render IN FRONT of lower tiles so their bottom_fade
		# reveals the lower tile from behind (standard "over" composite).
		# We keep the bottommost tile at z=-100 (matching the old single value)
		# so its z-relationship with UpperSky tiles is unchanged.
		sp.z_index = -100 + (n - 1 - i)
		add_child(sp)

		if is_first:
			_base = sp

		# tile_0 (highest) fades its top edge into PastelGalaxy territory,
		# matching the BIOME_OVERLAP_PX window used for all biome handoffs.
		var top_fade: float = minf(FADE_PX / h, 0.65) if is_first else 0.0
		var bot_fade: float
		if is_last:
			bot_fade = minf(FADE_PX / h, 0.65)
		else:
			bot_fade = SEAM_PX / h

		var mat := ShaderMaterial.new()
		mat.shader = EDGE_SHADER
		mat.set_shader_parameter("top_fade",    top_fade)
		mat.set_shader_parameter("bottom_fade", bot_fade)
		var is_boundary: bool = is_first or is_last
		mat.set_shader_parameter("noise_amount", 0.06 if is_boundary else 0.10)
		mat.set_shader_parameter("noise_scale",  7.0  if is_boundary else 5.0)
		sp.material = mat

		r += h

	_top_world_y = top_world


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
	var fade_in := clampf(inverse_lerp(T_START, T_END, distance_m), 0.0, 1.0)
	fade_in = fade_in * fade_in * (3.0 - 2.0 * fade_in)
	var fade_out := clampf(inverse_lerp(T_FADE_OUT_START, T_FADE_OUT_END, distance_m), 0.0, 1.0)
	fade_out = fade_out * fade_out * (3.0 - 2.0 * fade_out)
	modulate.a = fade_in * (1.0 - fade_out)
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
