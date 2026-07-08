class_name DreamSkyBiome
extends Node2D
## Background for the biome after Upper Sky (~1500m+). Placeholder: only one
## source segment exists so far (map_dream sky_1.png), repeated with the same
## crossfade technique as Upper Sky until the user adds real A/B/C +
## transition variants (see tools/prep_dream_sky.py).
##
## Unlike Upper Sky, this biome has no "footer" or cat-start anchor of its
## own - it just abuts directly onto the top of whatever comes before it.
## setup() takes that anchor Y (Upper Sky's get_top_world_y()) and stacks
## tiles upward from there, so the two backgrounds meet with no seam/gap.

const TILE_DIR: String = "res://assets/backgrounds/dream_sky/"

var _base: Sprite2D

func setup(anchor_bottom_y: float) -> void:
	_build_base(anchor_bottom_y)


func _build_base(anchor_bottom_y: float) -> void:
	var total_h: float = _load_total_h()
	var top_world: float = anchor_bottom_y - total_h
	var r: float = 0.0
	var i: int = 0
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
		r += float(tex.get_height())
		i += 1


func _load_total_h() -> float:
	var f := FileAccess.open("%smeta.json" % TILE_DIR, FileAccess.READ)
	if f == null:
		return 15015.0   # fallback matching the current placeholder length
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and parsed.has("total_h"):
		return float(parsed["total_h"])
	return 15015.0
