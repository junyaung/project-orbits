extends SceneTree
## Standalone check of the Upper Sky sling-trail glow shader: force it fully
## visible and screenshot after a few frames of pulse animation.
var biome: Node2D
var _f := 0

func _init() -> void:
	var root := get_root()
	var cam := Camera2D.new()
	cam.position = Vector2(540, 960)
	root.add_child(cam)
	cam.make_current()

	var Script: GDScript = load("res://scripts/gameplay/UpperSkyBiome.gd")
	biome = Script.new()
	root.add_child(biome)
	biome.call("setup", 2050.0)

func _process(_d: float) -> bool:
	_f += 1
	# force sling trail fully visible via an ideal orbit state
	biome.call("update_state", 1.0 / 60.0, 50.0, 960.0, true, 1.0)
	if _f == 20:
		var img := get_root().get_texture().get_image()
		img.save_png("user://sling_trail_glow.png")
		print("SAVED ", ProjectSettings.globalize_path("user://sling_trail_glow.png"))
		quit()
	return false
