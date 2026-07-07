extends SceneTree
## Capture the reskinned gameplay HUD.
##   no args   -> start overlay shot at frame 8
##   --autoplay -> in-run HUD shot at frame 70, result shot at frame 260
var _f := 0
var _auto := false

func _init() -> void:
	_auto = "--autoplay" in OS.get_cmdline_user_args()
	get_root().add_child(load("res://scenes/gameplay/Gameplay.tscn").instantiate())

func _shot(name: String) -> void:
	var img := get_root().get_texture().get_image()
	img.save_png("user://%s.png" % name)
	print("SAVED ", ProjectSettings.globalize_path("user://%s.png" % name))

func _process(_d: float) -> bool:
	_f += 1
	if not _auto:
		if _f == 8:
			_shot("hud_start"); quit()
	else:
		if _f == 70:
			_shot("hud_run")
		elif _f == 260:
			_shot("hud_result"); quit()
	return false
