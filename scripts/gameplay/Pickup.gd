extends Node2D
class_name Pickup
## Floating collectible: "star" (score) or "shield" (one-hit protection).
## Visual scale is authored on the $Sprite node in each Pickup_<Kind>.tscn.
## `radius` (collision) is independently exported so resizing the sprite
## doesn't silently change the hitbox.

@export var radius := 40.0

@onready var sprite: Sprite2D = $Sprite

var kind := "star"
var alive := true
var _t := 0.0
var _base_y := 0.0

func setup(_kind: String) -> void:
	kind = _kind
	_t = randf() * TAU

func _ready() -> void:
	_base_y = position.y

func _process(delta: float) -> void:
	_t += delta
	sprite.position.y = sin(_t * 2.2) * 5.0
	sprite.rotation = sin(_t * 1.3) * 0.12

func collect() -> void:
	alive = false
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", sprite.scale * 1.8, 0.18)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(queue_free)
