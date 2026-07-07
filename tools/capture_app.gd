extends SceneTree
## Drives the real app entry (Main.tscn / ScreenManager) to verify routing:
## Home on boot -> nav to Shop -> nav to Star Path -> Launch into gameplay.
var _f := 0

func _init() -> void:
	change_scene_to_file("res://scenes/ui/Main.tscn")

func _shot(n: String) -> void:
	get_root().get_texture().get_image().save_png("user://%s.png" % n)
	print("SAVED ", ProjectSettings.globalize_path("user://%s.png" % n))

func _process(_d: float) -> bool:
	_f += 1
	var cs := current_scene
	if _f == 16:
		_shot("app_home")
	elif _f == 22 and cs:
		cs.show_screen("shop")
	elif _f == 36:
		_shot("app_shop")
	elif _f == 42 and cs:
		cs.show_screen("star_path")
	elif _f == 56 and cs:
		cs._start_game()          # Launch -> gameplay scene change
	elif _f >= 120:
		_shot("app_game")         # should be the gameplay start overlay
		quit()
	return false
