extends Node2D
## Full-screen overlay that hides the Upper Sky → Dream Sky seam.
## Lives in world-space (child of `world`), but follows the camera each frame
## so its ColorRects always cover the viewport.
##
## Driven by GameplayController._process() via update(delta, distance_m, cam_y).
## Does nothing until the transition window begins.

const SCREEN_W := 1080.0
const SCREEN_H := 1920.0

## Transition window (meters). Chosen so Dream Sky is already at ~37% alpha
## when the camera first physically reveals its tiles at ~1365 m.
const T_START  := 1200.0
const T_END    := 1600.0

const UPPER_COLOR := Color(0.78, 0.90, 1.00)
const DREAM_COLOR := Color(0.62, 0.55, 0.88)

var _tint: ColorRect   # continuous color-mood blend; stays after transition
var _veil: ColorRect   # lavender mist peak; sine-bell at the seam, then gone
var _time: float = 0.0


func _ready() -> void:
	# Color-mood tint (behind veil)
	_tint = ColorRect.new()
	_tint.size = Vector2(SCREEN_W, SCREEN_H)
	_tint.color = Color(UPPER_COLOR.r, UPPER_COLOR.g, UPPER_COLOR.b, 0.0)
	_tint.z_index = -72
	add_child(_tint)

	# Lavender transition veil
	_veil = ColorRect.new()
	_veil.size = Vector2(SCREEN_W, SCREEN_H)
	_veil.color = Color(0.76, 0.72, 0.95, 0.0)
	_veil.z_index = -71
	add_child(_veil)


func update(delta: float, distance_m: float, cam_y: float) -> void:
	_time += delta
	var raw_t := inverse_lerp(T_START, T_END, distance_m)
	var t := clampf(raw_t, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)   # smoothstep

	var top_y := cam_y - SCREEN_H * 0.5
	_tint.position = Vector2(0.0, top_y)
	# Veil breathes gently; offset resets to zero outside the active window
	var veil_drift := sin(_time * 0.4) * 5.0 * sin(t * PI)
	_veil.position = Vector2(0.0, top_y + veil_drift)

	# Veil: sine-bell peaking at the midpoint of the transition
	_veil.modulate.a = sin(t * PI) * 0.28

	# Tint: fades from sky-blue toward lavender; stays at 0.22 once in Dream Sky
	var blend := UPPER_COLOR.lerp(DREAM_COLOR, t)
	_tint.color = Color(blend.r, blend.g, blend.b, t * 0.22)
