extends Control
class_name CatCard
## One cat tile in the Cat Log grid: watercolor card frame, a cat portrait (a dark
## silhouette when still locked), a name, and a state badge (equipped / new).
## A gold glow marks the selected card. Emits selected(id) when tapped.

signal selected(id: String)

const TRAV := "res://assets/sprites/ui/traveler/"
const INK := Color(0.34, 0.29, 0.24)

const FRAME := {
	"equipped": "card_owned.png",
	"rescued": "card_normal.png",
	"new": "card_new.png",
	"locked": "card_locked.png",
}

var id := ""
var _data := {}
var _glow: Panel

func configure(data: Dictionary) -> void:
	# {id, name, sprite, state}
	id = String(data.get("id", ""))
	_data = data

func _ready() -> void:
	custom_minimum_size = Vector2(230, 262)
	size = custom_minimum_size
	var state := String(_data.get("state", "rescued"))
	var locked := state == "locked"

	# clean gold selection border (the traveler selected_glow sprite has baked text)
	_glow = Panel.new()
	var gsb := StyleBoxFlat.new()
	gsb.bg_color = Color(1, 1, 1, 0)
	gsb.set_corner_radius_all(30)
	gsb.border_color = Color(0.96, 0.78, 0.36)
	gsb.set_border_width_all(6)
	gsb.shadow_color = Color(0.96, 0.80, 0.42, 0.35)
	gsb.shadow_size = 10
	_glow.add_theme_stylebox_override("panel", gsb)
	_glow.size = Vector2(238, 238)
	_glow.position = Vector2(-4, -4)
	_glow.visible = false
	_glow.z_index = 1
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glow)

	var frame := NinePatchRect.new()
	frame.texture = load(TRAV + String(FRAME.get(state, "card_normal.png")))
	frame.patch_margin_left = 30
	frame.patch_margin_right = 30
	frame.patch_margin_top = 30
	frame.patch_margin_bottom = 30
	frame.size = Vector2(230, 230)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	var portrait := TextureRect.new()
	portrait.texture = load(String(_data.get("sprite", "")))
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(150, 140)
	portrait.size = portrait.custom_minimum_size
	portrait.position = Vector2((230 - 150) * 0.5, 26)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if locked:
		portrait.modulate = Color(0.16, 0.16, 0.22, 0.9)   # dark silhouette
	add_child(portrait)

	var name_lbl := Label.new()
	name_lbl.text = "???" if locked else String(_data.get("name", ""))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", INK if not locked else Color(0.5, 0.48, 0.5))
	name_lbl.add_theme_font_size_override("font_size", 32)
	name_lbl.position = Vector2(10, 172)
	name_lbl.size = Vector2(210, 40)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_lbl)

	if state == "equipped":
		_corner_badge("badge_current.png")
	# "new" state already shows its red dot via the card_new frame

	var hit := Button.new()
	hit.flat = true
	hit.size = Vector2(230, 230)
	hit.pressed.connect(func() -> void: selected.emit(id))
	add_child(hit)

func _corner_badge(tex: String, is_ribbon := false) -> void:
	var b := TextureRect.new()
	b.texture = load(TRAV + tex)
	b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(96, 60) if is_ribbon else Vector2(66, 66)
	b.size = b.custom_minimum_size
	b.position = Vector2(230 - b.size.x - 8, 6)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(b)

func set_selected(on: bool) -> void:
	if _glow:
		_glow.visible = on
