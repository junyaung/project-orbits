extends SceneTree
## Verify the stitched Upper Sky -> Dream Sky background scrolling with an
## autoplay run: capture at the very start (Upper Sky), then again after
## climbing (seam + Dream Sky should be in view).
var _f := 0

func _init() -> void:
	get_root().add_child(load("res://scenes/gameplay/Gameplay.tscn").instantiate())

func _shot(n: String) -> void:
	get_root().get_texture().get_image().save_png("user://%s.png" % n)
	print("SAVED ", ProjectSettings.globalize_path("user://%s.png" % n))

func _process(_d: float) -> bool:
	_f += 1
	if _f == 10:
		_shot("sky_start")
	elif _f == 300:
		_shot("sky_climbed_300")
	elif _f == 700:
		_shot("sky_climbed_700")
		quit()
	return false
