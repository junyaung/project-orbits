extends SceneTree
var _f := 0
var _s: Node
func _init() -> void:
	_s = load("res://scenes/ui/CatLogScreen.tscn").instantiate()
	get_root().add_child(_s)
func _process(_d: float) -> bool:
	_f += 1
	if _f == 8:
		for a in OS.get_cmdline_user_args():
			_s._select(a)   # optional: select a cat id before the shot
	elif _f >= 16:
		get_root().get_texture().get_image().save_png("user://catlog_shot.png")
		print("SAVED ", ProjectSettings.globalize_path("user://catlog_shot.png"))
		quit()
	return false
