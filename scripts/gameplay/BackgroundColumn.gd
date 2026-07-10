class_name BackgroundColumn
extends Node2D
## One continuous seamless background column. 2752px tile images are stacked in
## world space and OVERLAP by SEAM_PX; each tile's bottom edge dissolves into the
## tile below via the organic_edge_fade shader, so the join between two different
## painted scenes reads as drifting mist rather than a hard seam. Because the
## overlap is shared, each image still ADVANCES 300m of new altitude (see the
## matching scale in GameplayController) -> clean 1500/3000/4500/6000m biomes.
##
## STREAMING: only the tiles whose world-Y intersects the camera (+ margin) exist
## as Sprite2Ds; the rest are freed. Textures are loaded on a BACKGROUND THREAD a
## few tiles ahead of time (see PRELOAD_MARGIN) so a tile scrolling into view
## never blocks the main thread on a multi-MB PNG decode.
##
## CROSSFADE POSITIONS: a position can hold MULTIPLE images (tile_<i>.png,
## tile_<i>_1.png, ...) that slowly dissolve between each other in a loop -- each
## weight ramps in over CF_FADE, holds CF_HOLD, ramps out over CF_FADE, and the
## next starts as it begins fading out (Chrono Sea uses this). The weights always
## sum to 1. It's ONE sprite whose crossfade_edge_fade shader MIXES the images by
## those weights into an opaque frame (stacking N alpha-animated sprites instead
## would go ~25% transparent mid-dissolve and bleed the tile below through).
## Register counts with set_crossfade().

const DIR := "res://assets/backgrounds/_column/"
const EDGE_SHADER: Shader = preload("res://assets/shaders/organic_edge_fade.gdshader")
const CROSSFADE_SHADER: Shader = preload("res://assets/shaders/crossfade_edge_fade.gdshader")

const TILE_H := 2752.0
const SEAM_PX := 600.0                    # overlap dissolved between adjacent tiles
const NET_ADVANCE := TILE_H - SEAM_PX      # 2152px -> one image = +300m of altitude
const HALF_SCREEN := 960.0
const MARGIN := 2752.0                     # keep ~1 extra tile live beyond each edge
const PRELOAD_MARGIN := 2752.0 * 3.0       # begin threaded-loading tiles this far out

## Crossfade timing (matches the user's prototype): fade in, hold, fade out; the
## next image begins fading in as this one begins fading out, so the stagger
## between images is fade + hold and the whole cycle is count * stagger.
const CF_FADE := 5.0
const CF_HOLD := 3.0
const CF_STAGGER := CF_FADE + CF_HOLD          # 8.0s between image starts
const CF_ON := CF_FADE + CF_HOLD + CF_FADE      # 13.0s an image is non-zero

var _n: int = 0
var _bottom_y: float = 0.0                 # world Y of tile_0's bottom edge
var _cf_count: Dictionary = {}             # index -> image count (>1 = crossfade)
var _active: Dictionary = {}               # index -> Node2D/Sprite2D (freed on exit)
var _cf_sprites: Dictionary = {}           # index -> Sprite2D (active crossfade tiles)
var _requested: Dictionary = {}            # path -> true (threaded load in flight)
var _t: float = 0.0                        # crossfade animation clock


func setup(bottom_world_y: float, tile_count: int) -> void:
	_bottom_y = bottom_world_y
	_n = tile_count


## Mark tile `index` as a crossfade position with `count` stacked images
## (tile_<index>.png plus tile_<index>_1.png .. tile_<index>_<count-1>.png).
func set_crossfade(index: int, count: int) -> void:
	_cf_count[index] = count


## World Y of tile i's TOP edge. tile_0's bottom sits at _bottom_y; each higher
## tile advances NET_ADVANCE further up and overlaps the one below by SEAM_PX.
func _tile_top_y(i: int) -> float:
	return _bottom_y - float(i) * NET_ADVANCE - TILE_H


func top_world_y() -> float:
	return _tile_top_y(_n - 1)


func _count(i: int) -> int:
	return _cf_count.get(i, 1)


func _path(i: int, k: int) -> String:
	return DIR + ("tile_%d.png" % i if k == 0 else "tile_%d_%d.png" % [i, k])


## Alpha of the k-th image of a `n`-image crossfade at the current time.
func _cf_alpha(k: int, n: int) -> float:
	var period: float = float(n) * CF_STAGGER
	var local: float = fmod(_t - float(k) * CF_STAGGER, period)
	if local < 0.0:
		local += period
	if local < CF_FADE:
		return local / CF_FADE
	if local < CF_FADE + CF_HOLD:
		return 1.0
	if local < CF_ON:
		return 1.0 - (local - CF_FADE - CF_HOLD) / CF_FADE
	return 0.0


func _process(delta: float) -> void:
	if _cf_sprites.is_empty():
		return
	_t += delta
	for i in _cf_sprites:
		var sp: Sprite2D = _cf_sprites[i]
		var n: int = _count(i)
		var mat: ShaderMaterial = sp.material
		mat.set_shader_parameter("w_a", _cf_alpha(0, n))
		mat.set_shader_parameter("w_b", _cf_alpha(1, n))
		mat.set_shader_parameter("w_c", _cf_alpha(2, n) if n >= 3 else 0.0)


func update_view(cam_y: float) -> void:
	var a_lo: float = cam_y - HALF_SCREEN - MARGIN          # active window
	var a_hi: float = cam_y + HALF_SCREEN + MARGIN
	var p_lo: float = cam_y - HALF_SCREEN - PRELOAD_MARGIN  # preload window (wider)
	var p_hi: float = cam_y + HALF_SCREEN + PRELOAD_MARGIN
	for i in _n:
		var yt: float = _tile_top_y(i)
		var yb: float = yt + TILE_H
		var cnt: int = _count(i)

		# Kick off / drop background loads for every image of this tile.
		var in_preload: bool = yb >= p_lo and yt <= p_hi
		for k in cnt:
			var path: String = _path(i, k)
			if in_preload:
				if not _requested.has(path):
					ResourceLoader.load_threaded_request(path)
					_requested[path] = true
			else:
				_requested.erase(path)

		# Instance / free based on the tighter active window.
		var on: bool = yb >= a_lo and yt <= a_hi
		if on and not _active.has(i):
			_instance(i, yt, cnt)
		elif not on and _active.has(i):
			_active[i].queue_free()
			_active.erase(i)
			_cf_sprites.erase(i)


func _instance(i: int, yt: float, cnt: int) -> void:
	var sp := Sprite2D.new()
	sp.centered = false
	sp.texture = _fetch(_path(i, 0))
	sp.position = Vector2(0.0, yt)
	# Upper tiles render IN FRONT so their bottom_fade reveals the tile below.
	sp.z_index = -90 + i
	var mat := ShaderMaterial.new()
	if cnt == 1:
		mat.shader = EDGE_SHADER
	else:
		# One sprite that MIXES the crossfade images by weight (see class doc).
		mat.shader = CROSSFADE_SHADER
		mat.set_shader_parameter("tex_b", _fetch(_path(i, 1)))
		mat.set_shader_parameter("tex_c", _fetch(_path(i, 2)) if cnt >= 3 else _fetch(_path(i, 1)))
		mat.set_shader_parameter("w_a", _cf_alpha(0, cnt))   # enter at the right phase
		mat.set_shader_parameter("w_b", _cf_alpha(1, cnt))
		mat.set_shader_parameter("w_c", _cf_alpha(2, cnt) if cnt >= 3 else 0.0)
		_cf_sprites[i] = sp
	mat.set_shader_parameter("top_fade",     0.0)
	mat.set_shader_parameter("bottom_fade",  SEAM_PX / TILE_H)
	mat.set_shader_parameter("noise_amount", 0.10)
	mat.set_shader_parameter("noise_scale",  5.0)
	sp.material = mat
	add_child(sp)
	_active[i] = sp


## Prefer the background-loaded texture; fall back to a synchronous load only if a
## tile entered the active window before its threaded load finished.
func _fetch(path: String) -> Texture2D:
	if _requested.has(path) and ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		return ResourceLoader.load_threaded_get(path)
	return load(path)


func active_count() -> int:
	return _active.size()
