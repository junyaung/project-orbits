extends Node2D
class_name Planet
## A "small island of emotion". Owns its orbit radius, gravity capture radius,
## a dotted orbit ring, heat-reactive tint and overheat steam.
## Visual scale is authored on the $Sprite node in each Planet_<Kind>.tscn -
## resize it there. The authored scale is treated as the size at orbit_radius
## 180 (a mid-range reference); actual instances scale relative to that so
## the "bigger orbit = bigger planet" variety is preserved.

const REFERENCE_ORBIT_RADIUS := 180.0

@onready var sprite: Sprite2D = $Sprite

var kind := "meadow"
var orbit_radius := 200.0
var gravity_radius := 300.0
var visual_radius := 120.0
## Solid core: half the visual radius. Orbiting happens far outside this (at
## orbit_radius ~= 1.67x visual_radius), so correct play never touches it - it
## only stops the cat from flying straight through the planet's dead center.
var core_radius := 60.0

var ring: Node2D
var steam: CPUParticles2D
var _dots: Array[Polygon2D] = []
var _t := 0.0
var _active := false
var _heat := 0.0

func setup(_kind: String, orbit_r: float) -> void:
	kind = _kind
	orbit_radius = orbit_r
	visual_radius = orbit_r * 0.60
	gravity_radius = orbit_r + 120.0
	core_radius = visual_radius * 0.5

	sprite.scale = sprite.scale * (orbit_r / REFERENCE_ORBIT_RADIUS)

	# dotted orbit ring
	ring = Node2D.new()
	ring.z_index = -1
	add_child(ring)
	var count := int(max(24.0, orbit_radius / 9.0))
	for i in count:
		var a := TAU * float(i) / float(count)
		var dot := Polygon2D.new()
		dot.polygon = _circle(3.4, 8)
		dot.position = Vector2.from_angle(a) * orbit_radius
		dot.color = Color(0.42, 0.52, 0.66, 0.55)
		ring.add_child(dot)
		_dots.append(dot)
	ring.visible = false

	# overheat steam
	steam = CPUParticles2D.new()
	steam.texture = load("res://assets/sprites/vfx/steam_puff.png")
	steam.emitting = false
	steam.amount = 10
	steam.lifetime = 1.6
	steam.position = Vector2(0, -visual_radius * 0.7)
	steam.direction = Vector2(0, -1)
	steam.spread = 35.0
	steam.gravity = Vector2(0, -30)
	steam.initial_velocity_min = 20.0
	steam.initial_velocity_max = 45.0
	steam.scale_amount_min = 0.15
	steam.scale_amount_max = 0.32
	steam.color = Color(1, 1, 1, 0.5)
	add_child(steam)

func _circle(r: float, seg: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg:
		var a := TAU * float(i) / float(seg)
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	return pts

func _process(delta: float) -> void:
	_t += delta
	if _active:
		var pulse := 0.5 + 0.5 * sin(_t * 3.0)
		for d in _dots:
			d.color.a = lerp(0.35, 0.85, pulse)

func set_active(a: bool) -> void:
	if _active == a:
		return
	_active = a
	ring.visible = a

func set_heat_ratio(v: float) -> void:
	_heat = v
	# warm tint: white -> coral as it overheats
	var warm := Color(1.0, 0.62, 0.5)
	sprite.modulate = Color.WHITE.lerp(warm, clamp(v, 0.0, 1.0) * 0.85)
	steam.emitting = v > 0.7

func cool_visual() -> void:
	sprite.modulate = Color.WHITE
	steam.emitting = false
