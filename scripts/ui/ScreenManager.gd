extends Control
class_name ScreenManager
## App entry point / router. Shows one meta screen at a time (Home, Star Path,
## Cat Log, Shop) and swaps between them on bottom-nav taps. Launch leaves the
## meta UI and enters the gameplay scene; the gameplay Result "Home" button
## brings the player back here.

const SCREENS := {
	"home": "res://scenes/ui/HomeScreen.tscn",
	"star_path": "res://scenes/ui/StarPathScreen.tscn",
	"cat": "res://scenes/ui/CatLogScreen.tscn",
	"shop": "res://scenes/ui/ShopScreen.tscn",
}
const GAMEPLAY := "res://scenes/gameplay/Gameplay.tscn"

var _current_id := ""
var _current: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	show_screen("home")

func show_screen(id: String) -> void:
	if id == _current_id:
		return
	if not SCREENS.has(id):
		return   # e.g. "settings" — no screen yet, stay put
	if _current:
		_current.queue_free()
	_current_id = id
	var scr: Control = load(String(SCREENS[id])).instantiate()
	scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scr)
	_current = scr
	_wire(scr)

func _wire(scr: Control) -> void:
	if scr.has_signal("nav_selected"):
		scr.nav_selected.connect(show_screen)
	if scr.has_signal("launch_pressed"):
		scr.launch_pressed.connect(_start_game)
	if scr.has_signal("close_pressed"):
		scr.close_pressed.connect(_go_home)
	if scr.has_signal("back_pressed"):
		scr.back_pressed.connect(_go_home)

func _go_home() -> void:
	show_screen("home")

func _start_game() -> void:
	get_tree().change_scene_to_file(GAMEPLAY)
