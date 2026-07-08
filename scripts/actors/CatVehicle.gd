extends Node2D
class_name CatVehicle
## The cat riding a manhole cover. A single composite sprite whose texture
## swaps per emotional state (idle / orbit / launch / happy). Faithful to the
## production bible: small, round, low-saturation, gentle animation only.
## Visual scale is authored on the $Sprite node in CatVehicle.tscn - resize
## it there and this script will respect whatever scale you set.

@export var hit_radius := 60.0   # collision radius of the whole vehicle, independent of sprite scale

@onready var sprite: Sprite2D = $Sprite

var tex := {}
var shield_aura: Node2D
var _base_scale := Vector2.ONE
var _state := "idle"
var _time := 0.0
var _target_tilt := 0.0
var _shield_on := false
var _scale_tween: Tween   # single owner of sprite.scale, so reactions don't fight

func _ready() -> void:
	tex = {
		"idle":   load("res://assets/sprites/cat/cat_idle.png"),
		"orbit":  load("res://assets/sprites/cat/cat_determined.png"),
		"launch": load("res://assets/sprites/cat/cat_curious.png"),
		"happy":  load("res://assets/sprites/cat/cat_cheer.png"),
		"sleepy": load("res://assets/sprites/cat/cat_sleepy.png"),
	}
	_base_scale = sprite.scale
	sprite.z_index = 1
	_build_shield_aura()
	set_state("idle")

# A soft protective bubble drawn around the whole vehicle. Shown only while the
# player holds a shield, so absorbing a hit reads clearly instead of "the hazard
# vanished for no reason."
func _build_shield_aura() -> void:
	shield_aura = Node2D.new()
	shield_aura.z_index = 3
	shield_aura.visible = false
	add_child(shield_aura)
	var fill := Polygon2D.new()
	fill.polygon = _circle_pts(120.0, 40)
	fill.color = Color(0.62, 0.86, 1.0, 0.12)
	shield_aura.add_child(fill)
	var ring := Line2D.new()
	ring.points = _circle_pts(120.0, 48)
	ring.width = 5.0
	ring.default_color = Color(0.74, 0.93, 1.0, 0.6)
	ring.antialiased = true
	shield_aura.add_child(ring)

func _circle_pts(r: float, seg: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg + 1:   # +1 closes the loop
		var a := TAU * float(i) / float(seg)
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	return pts

## Toggle the shield bubble. Call with true when a shield is picked up, false
## when it breaks.
func set_shield(on: bool) -> void:
	_shield_on = on
	shield_aura.visible = on
	if on:
		shield_aura.scale = Vector2(0.7, 0.7)
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(shield_aura, "scale", Vector2.ONE, 0.22)

func _process(delta: float) -> void:
	_time += delta
	# gentle idle bob (a small vertical offset only - never touches scale)
	var bob := sin(_time * 2.4) * 3.0
	sprite.position.y = bob
	# smooth tilt toward target (orbit lean)
	sprite.rotation = lerp_angle(sprite.rotation, _target_tilt, 0.12)
	# shield shimmer: gentle alpha pulse while active
	if _shield_on:
		shield_aura.modulate.a = 0.75 + 0.25 * sin(_time * 3.0)

## Start a fresh scale reaction, cancelling any in-flight one. Without this,
## a star pop landing mid-launch (or two stars in one frame) leaves several
## tweens driving sprite.scale at once, so the cat visibly swells/jitters.
func _begin_scale_anim() -> Tween:
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	sprite.scale = _base_scale
	_scale_tween = create_tween()
	return _scale_tween

func set_state(s: String) -> void:
	if _state == s:
		return
	_state = s
	if tex.has(s):
		sprite.texture = tex[s]

func play_idle() -> void:
	set_state("idle")
	_target_tilt = 0.0

func play_orbit_tilt(direction_sign: float) -> void:
	set_state("orbit")
	_target_tilt = direction_sign * deg_to_rad(9.0)

func play_launch(launch_dir: Vector2) -> void:
	set_state("launch")
	_target_tilt = launch_dir.angle() + PI * 0.5
	# squash & stretch reaction, relative to the authored base scale
	var tw := _begin_scale_anim()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "scale", _base_scale * Vector2(1.14, 0.88), 0.06)
	tw.tween_property(sprite, "scale", _base_scale, 0.16)

func play_happy() -> void:
	set_state("happy")

func pop() -> void:
	var tw := _begin_scale_anim()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "scale", _base_scale * 1.12, 0.08)
	tw.tween_property(sprite, "scale", _base_scale, 0.12)
