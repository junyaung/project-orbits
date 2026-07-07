extends SceneTree
var _f := 0
func _init() -> void:
	get_root().add_child(load("res://scenes/ui/StarPathScreen.tscn").instantiate())
func _process(_d: float) -> bool:
	_f += 1
	if _f >= 14:
		get_root().get_texture().get_image().save_png("user://starpath_shot.png")
		print("SAVED ", ProjectSettings.globalize_path("user://starpath_shot.png"))
		quit()
	return false
