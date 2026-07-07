extends Node2D
class_name Hazard
## Drifting obstacle: "rock" slowly floats; "meteor" streaks with a tail.
## Visual scale is authored on the $Sprite node in each Hazard_<Kind>.tscn.
## `radius` (collision) is independently exported per scene so resizing the
## sprite doesn't silently change the hitbox.

@export var radius := 50.0

@onready var sprite: Sprite2D = $Sprite

# The meteor art travels head-first toward the lower-left, with its flame tail
# baked in pointing upper-right. This is the direction of motion drawn into the
# sprite (from tail to head), used to align the sprite with its drift vector.
const METEOR_ART_ANGLE := deg_to_rad(135.0)

var kind := "rock"
var drift := Vector2.ZERO
var spin := 0.0
var _t := 0.0

func setup(_kind: String) -> void:
	kind = _kind
	match kind:
		"rock":
			# gentle float only - slow enough it can't wander onto a nearby orbit ring
			drift = Vector2(randf_range(-7, 7), randf_range(-5, 5))
			spin = randf_range(-0.4, 0.4)
		"meteor":
			drift = Vector2(randf_range(-70, 70), randf_range(60, 120))
			# rotate so the baked-in flame tail trails the actual fall direction
			sprite.rotation = drift.angle() - METEOR_ART_ANGLE
		"jelly":
			drift = Vector2(randf_range(-24, 24), randf_range(-20, 20))

func _process(delta: float) -> void:
	_t += delta
	position += drift * delta
	if kind == "rock":
		sprite.rotation += spin * delta
	elif kind == "jelly":
		sprite.position.y = sin(_t * 3.0) * 6.0
