extends SceneTree
## Screenshots the Shop. Optional arg: a tab index to open before the shot.
var _f := 0
var _s: Node
var _tab := 0

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.is_valid_int():
			_tab = a.to_int()
	_s = load("res://scenes/ui/ShopScreen.tscn").instantiate()
	get_root().add_child(_s)

func _process(_d: float) -> bool:
	_f += 1
	if _f == 8 and _tab != 0:
		_s._show_tab(_tab)
	elif _f >= 16:
		get_root().get_texture().get_image().save_png("user://shop_shot_%d.png" % _tab)
		print("SAVED ", ProjectSettings.globalize_path("user://shop_shot_%d.png" % _tab))
		quit()
	return false
