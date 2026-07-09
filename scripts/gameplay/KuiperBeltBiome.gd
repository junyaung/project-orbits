class_name KuiperBeltBiome
extends Node2D
## Background for the Kuiper Belt biome (4500–6000+ m).
## Fades in as Pastel Galaxy Garden fades out, using the same seam-stitched
## tile system as the other biomes.

const TILE_DIR:    String = "res://assets/backgrounds/4. kuiper belt/"
const EDGE_SHADER: Shader = preload("res://assets/shaders/organic_edge_fade.gdshader")

## Cross-fade with PastelGalaxy over 4240–4500m (inside the 4224-4512m both-cover
## band of the 4800px overlap); fully in as Pastel tiles end.
const T_START  := 4240.0
const T_END    := 4500.0
const FADE_PX  := 1920.0
const SEAM_PX: float = 600.0

var _top_world_y: float = 0.0


func setup(anchor_bottom_y: float) -> void:
	modulate.a = 0.0
	_build_base(anchor_bottom_y)


func get_top_world_y() -> float:
	return _top_world_y


func _build_base(anchor_bottom_y: float) -> void:
	var total_h: float = _load_total_h()

	var textures: Array[Texture2D] = []
	var idx: int = 0
	while true:
		var path: String = TILE_DIR + "tile_%d.png" % idx
		if not ResourceLoader.exists(path):
			break
		var tex: Texture2D = load(path)
		if tex == null:
			break
		textures.append(tex)
		idx += 1

	var n: int = textures.size()
	var seam_shrink: float = maxf(0.0, (n - 1) * SEAM_PX)
	var top_world: float = anchor_bottom_y - total_h + seam_shrink

	var r: float = 0.0
	var seam_offset: float = 0.0

	for i in n:
		var is_first: bool = (i == 0)
		var is_last:  bool = (i == n - 1)

		if not is_first:
			seam_offset += SEAM_PX

		var tex: Texture2D = textures[i]
		var h: float = float(tex.get_height())

		var sp := Sprite2D.new()
		sp.centered = false
		sp.texture = tex
		sp.position = Vector2(0.0, top_world + r - seam_offset)
		sp.z_index = -100 + (n - 1 - i)
		add_child(sp)
		_apply_fade_shader(sp, h, is_first, is_last)

		r += h

	_top_world_y = top_world


func _apply_fade_shader(sp: Sprite2D, h: float, is_first: bool, is_last: bool) -> void:
	var top_fade: float = minf(FADE_PX / h, 0.65) if is_first else 0.0
	var bot_fade: float = SEAM_PX / h if not is_last else minf(FADE_PX / h, 0.65)
	var is_boundary: bool = is_first or is_last
	var mat := ShaderMaterial.new()
	mat.shader = EDGE_SHADER
	mat.set_shader_parameter("top_fade",     top_fade)
	mat.set_shader_parameter("bottom_fade",  bot_fade)
	mat.set_shader_parameter("noise_amount", 0.06 if is_boundary else 0.10)
	mat.set_shader_parameter("noise_scale",  7.0  if is_boundary else 5.0)
	sp.material = mat


func update_state(_delta: float, distance_m: float, _cam_y: float) -> void:
	var t := clampf(inverse_lerp(T_START, T_END, distance_m), 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	modulate.a = t


func _load_total_h() -> float:
	var f := FileAccess.open(TILE_DIR + "meta.json", FileAccess.READ)
	if f == null:
		return 22016.0
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and parsed.has("total_h"):
		return float(parsed["total_h"])
	return 22016.0
