extends SceneTree
## Force the reskinned Splashdown result card and screenshot it.
var _f := 0
var _root_node: Node

func _init() -> void:
	_root_node = load("res://scenes/gameplay/Gameplay.tscn").instantiate()
	get_root().add_child(_root_node)

func _process(_d: float) -> bool:
	_f += 1
	if _f == 10:
		_root_node.hud.hide_start_now()
		_root_node.hud.show_result(2431, 12, 3, 2590, "planet")
	elif _f == 60:
		var img := get_root().get_texture().get_image()
		img.save_png("user://hud_result_card.png")
		print("SAVED ", ProjectSettings.globalize_path("user://hud_result_card.png"))
		quit()
	return false
