extends SceneTree
## Headless-ish capture: load HomeScreen, let it render a few frames, save a PNG.
## Run: Godot --path <proj> -s res://tools/capture_home.gd

var _frames := 0
var _out := "user://home_shot.png"

func _init() -> void:
	var home: Control = load("res://scenes/ui/HomeScreen.tscn").instantiate()
	get_root().add_child(home)

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames >= 12:
		var img := get_root().get_texture().get_image()
		img.save_png(_out)
		var path := ProjectSettings.globalize_path(_out)
		print("SAVED ", path)
		quit()
	return false
