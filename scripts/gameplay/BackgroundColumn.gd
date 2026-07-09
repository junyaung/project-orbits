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
## never blocks the main thread on a multi-MB PNG decode -- that synchronous load
## was causing a periodic frame hitch ("glitchy flight") as the cat climbed.

const DIR := "res://assets/backgrounds/_column/"
const EDGE_SHADER: Shader = preload("res://assets/shaders/organic_edge_fade.gdshader")

const TILE_H := 2752.0
const SEAM_PX := 600.0                    # overlap dissolved between adjacent tiles
const NET_ADVANCE := TILE_H - SEAM_PX      # 2152px -> one image = +300m of altitude
const HALF_SCREEN := 960.0
const MARGIN := 2752.0                     # keep ~1 extra tile live beyond each edge
const PRELOAD_MARGIN := 2752.0 * 3.0       # begin threaded-loading tiles this far out

var _n: int = 0
var _bottom_y: float = 0.0                 # world Y of tile_0's bottom edge
var _active: Dictionary = {}               # index -> Sprite2D
var _requested: Dictionary = {}            # index -> true (threaded load in flight)


func setup(bottom_world_y: float, tile_count: int) -> void:
	_bottom_y = bottom_world_y
	_n = tile_count


## World Y of tile i's TOP edge. tile_0's bottom sits at _bottom_y; each higher
## tile advances NET_ADVANCE further up and overlaps the one below by SEAM_PX.
func _tile_top_y(i: int) -> float:
	return _bottom_y - float(i) * NET_ADVANCE - TILE_H


func top_world_y() -> float:
	return _tile_top_y(_n - 1)


func update_view(cam_y: float) -> void:
	var a_lo: float = cam_y - HALF_SCREEN - MARGIN          # active window
	var a_hi: float = cam_y + HALF_SCREEN + MARGIN
	var p_lo: float = cam_y - HALF_SCREEN - PRELOAD_MARGIN  # preload window (wider)
	var p_hi: float = cam_y + HALF_SCREEN + PRELOAD_MARGIN
	for i in _n:
		var yt: float = _tile_top_y(i)
		var yb: float = yt + TILE_H
		var path: String = DIR + "tile_%d.png" % i

		# Kick off a background load once the tile is within the preload window,
		# so its texture is decoded/uploaded before it needs to be shown.
		if yb >= p_lo and yt <= p_hi:
			if not _requested.has(i):
				ResourceLoader.load_threaded_request(path)
				_requested[i] = true
		else:
			_requested.erase(i)

		# Instance / free based on the tighter active window.
		var on: bool = yb >= a_lo and yt <= a_hi
		if on and not _active.has(i):
			var sp := Sprite2D.new()
			sp.centered = false
			sp.texture = _fetch(i, path)
			sp.position = Vector2(0.0, yt)
			# Upper tiles render IN FRONT so their bottom_fade reveals the tile
			# below; tile_0 dissolves down over Upper Sky sitting behind it.
			sp.z_index = -90 + i
			var mat := ShaderMaterial.new()
			mat.shader = EDGE_SHADER
			mat.set_shader_parameter("top_fade",     0.0)
			mat.set_shader_parameter("bottom_fade",  SEAM_PX / TILE_H)
			mat.set_shader_parameter("noise_amount", 0.10)
			mat.set_shader_parameter("noise_scale",  5.0)
			sp.material = mat
			add_child(sp)
			_active[i] = sp
		elif not on and _active.has(i):
			_active[i].queue_free()
			_active.erase(i)


## Prefer the background-loaded texture; fall back to a synchronous load only if
## a tile somehow entered the active window before its threaded load finished
## (shouldn't happen given PRELOAD_MARGIN, but keep it safe).
func _fetch(i: int, path: String) -> Texture2D:
	if _requested.has(i) and ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		return ResourceLoader.load_threaded_get(path)
	return load(path)


func active_count() -> int:
	return _active.size()
