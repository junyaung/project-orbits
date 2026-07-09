class_name UpperSkyBiome
extends Node2D
## Layered visual system for the Upper Sky biome (0–300 m).
##
## Layers (z-order, back to front):
##   -100  base      — randomized A/B/C + transition background covering the
##                     whole ~1500 m biome, sliced into vertical tiles
##                     (assets/backgrounds/upper_sky/tile_*.png) stacked in
##                     world space; a mirrored footer fills below the start line
##    -85  particles — sky dust + cloud mist CPUParticles
##    -80  gimmick   — wind-lane cue
##
## Overlay effect and decor set are intentionally not used — their watercolor
## content is cream/white, indistinguishable from the baked checker background
## at the pixel level, so no keying approach can separate them reliably.

# ── textures ──────────────────────────────────────────────────────────────────
const WIND_TEX:    Texture2D = preload("res://assets/sprites/biomes/upper_sky/wind_lane.png")
const EDGE_SHADER: Shader    = preload("res://assets/shaders/organic_edge_fade.gdshader")
const TILE_DIR: String = "res://assets/backgrounds/upper_sky/"

## Pixel height of the organic fade band at the top of the biome (where it meets
## Dream Sky). This should match BIOME_OVERLAP_PX in GameplayController so the
## faded zone exactly fills the overlap region.
const FADE_PX: float = 1920.0

# ── geometry constants ────────────────────────────────────────────────────────
const SCREEN_W:  float = 1080.0
const SCREEN_H:  float = 1920.0
const BIOME_END: float = 1500.0   # biome covers ~1500 m
const DEFAULT_CORE_H: float = 15015.0   # fallback if meta.json is missing
## Fade-out window, matching DreamSkyBiome and BiomeTransitionLayer so all
## three layers blend in sync (dream fades in, upper fades out, veil peaks).
const T_START: float = 1200.0
const T_END:   float = 1600.0

# ── scene nodes ───────────────────────────────────────────────────────────────
var _base:      Sprite2D
var _wind_lane: Sprite2D
var _dust:      CPUParticles2D
var _mist:      CPUParticles2D

# ── state ─────────────────────────────────────────────────────────────────────
var _t:             float = 0.0
var _wind_visible:  bool  = false
var _wind_target_y: float = 0.0
var _top_world_y:   float = 0.0   # world Y of the topmost painted row (see _build_base)

# ─────────────────────────────────────────────────────────────────────────────

func setup(biome_base_y: float) -> void:
	_build_base(biome_base_y)
	_build_particles()
	_build_gimmicks()


## Call from GameplayController._process() each frame.
func update_state(delta: float, distance_m: float, cam_y: float,
		_is_orbiting: bool, _orbit_ideal_frac: float) -> void:
	_t += delta
	# Upper Sky no longer cross-fades out: the continuous BackgroundColumn
	# butt-joins onto its opaque top edge, so Upper Sky stays fully visible for
	# its whole painted extent (fading it out just left gray below ~1500m).
	modulate.a = 1.0
	_update_particles(cam_y)
	_animate_wind_lane(delta, cam_y)


## Show/hide wind-current-lane cue. world_y = midpoint between two planet Y positions.
func set_wind_lane(show: bool, world_y: float = 0.0) -> void:
	_wind_visible = show
	if show:
		_wind_target_y = world_y


## World Y of the topmost painted row of this biome's background - the point
## where climbing further reveals nothing (currently: the plain gradient
## fallback). The next biome (Dream Sky) anchors its own bottom edge here so
## the two backgrounds abut with no gap.
func get_top_world_y() -> float:
	return _top_world_y


# ─────────────────────────── builders ────────────────────────────────────────

## Cross-dissolve band for the tile_2→tile_3 seam — the first internal seam the
## player encounters (~177m altitude). 600px ≈ 30% of the 1920px viewport, wide
## enough for cloud/sky art to dissolve as drifting mist rather than a hard cut.
## The footer constraint (tile stack must cover the game-start camera bottom at
## Y=3010) limits total seam shrinkage to 675px, so only this one seam is treated.
## tile_0/1 (1181m) and tile_1/2 (586m) remain hard cuts; they appear later when
## the player is more habituated, and the biome-transition veil at 1200m masks the
## tile_0/1 edge entirely.
const SEAM_PX: float = 600.0

## Stack tiles in world space. top_world is anchored to biome_base_y - core_h
## and does NOT change — DreamSky calls get_top_world_y() to place itself.
## tile_3 (and the tiny footer tile_4 behind it) are shifted up by SEAM_PX,
## overlapping tile_2. Tile_2's bottom_fade shader dissolves into tile_3,
## leaving the stack bottom at 3085 — 75px below the game-start camera edge.
func _build_base(biome_base_y: float) -> void:
	var core_h: float = _load_core_h()
	var top_world: float = biome_base_y - core_h

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
	var r: float = 0.0
	var seam_offset: float = 0.0   # accumulates only at the tile_2→3 boundary

	for i in n:
		var tex: Texture2D = textures[i]
		var h: float = float(tex.get_height())

		# Pull tile_3 (and all tiles below it) up by SEAM_PX so it overlaps tile_2.
		if i == 3:
			seam_offset += SEAM_PX

		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = false
		sp.position = Vector2(0.0, top_world + r - seam_offset)
		# Upper tiles render in front so their bottom_fade reveals the tile behind.
		sp.z_index = -100 + (n - 1 - i)
		add_child(sp)

		if i == 0:
			_base = sp

		if i == 0:
			# Topmost tile: OPAQUE top edge. The continuous BackgroundColumn now
			# butt-joins directly onto Upper Sky's top (color-matched), so this
			# tile must NOT fade to transparent there -- an old top_fade left a
			# transparent band that showed through as gray (~1500m). No fade.
			var mat := ShaderMaterial.new()
			mat.shader = EDGE_SHADER
			mat.set_shader_parameter("top_fade",     0.0)
			mat.set_shader_parameter("bottom_fade",  0.0)
			mat.set_shader_parameter("noise_amount", 0.0)
			mat.set_shader_parameter("noise_scale",  8.0)
			sp.material = mat
		elif i == 2:
			# tile_2: bottom edge dissolves into tile_3 over the 600px overlap band.
			var mat := ShaderMaterial.new()
			mat.shader = EDGE_SHADER
			mat.set_shader_parameter("top_fade",     0.0)
			mat.set_shader_parameter("bottom_fade",  SEAM_PX / h)
			mat.set_shader_parameter("noise_amount", 0.10)
			mat.set_shader_parameter("noise_scale",  5.0)
			sp.material = mat

		r += h

	_top_world_y = top_world


func _load_core_h() -> float:
	var f := FileAccess.open("%smeta.json" % TILE_DIR, FileAccess.READ)
	if f == null:
		return DEFAULT_CORE_H
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and parsed.has("core_h"):
		return float(parsed["core_h"])
	return DEFAULT_CORE_H


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
