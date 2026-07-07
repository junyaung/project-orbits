extends Control
class_name ShopItemCard
## One cosmetic tile in the Shop: watercolor card frame, a preview image, a name,
## and an action row (price to buy, or an Owned / Equipped state). Emits
## action(id) when the button is pressed. Text is all Labels (never baked).

signal action(id: String)

const SHOP := "res://assets/sprites/ui/shop/"
const CUR := "res://assets/sprites/ui/currency/"
const INK := Color(0.34, 0.29, 0.24)

const FRAME := {
	"buy": "card_normal.png",
	"owned": "card_owned.png",
	"equipped": "card_equipped.png",
	"locked": "card_locked.png",
}

var id := ""
var _data := {}

func configure(data: Dictionary) -> void:
	# {id, name, preview, price, currency("gem"/"coin"), state, badge("new"/"")}
	id = String(data.get("id", ""))
	_data = data

func _ready() -> void:
	custom_minimum_size = Vector2(480, 320)
	size = custom_minimum_size
	var state := String(_data.get("state", "buy"))

	var frame := NinePatchRect.new()
	frame.texture = load(SHOP + String(FRAME.get(state, "card_normal.png")))
	frame.patch_margin_left = 34
	frame.patch_margin_right = 34
	frame.patch_margin_top = 34
	frame.patch_margin_bottom = 34
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	var preview := TextureRect.new()
	preview.texture = load(String(_data.get("preview", "")))
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(170, 140)
	preview.size = preview.custom_minimum_size
	preview.position = Vector2((480 - 170) * 0.5, 26)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if state == "locked":
		preview.modulate = Color(0.5, 0.5, 0.55, 0.85)
	add_child(preview)

	var name_lbl := Label.new()
	name_lbl.text = String(_data.get("name", ""))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", INK)
	name_lbl.add_theme_font_size_override("font_size", 34)
	name_lbl.position = Vector2(20, 180)
	name_lbl.size = Vector2(440, 44)
	add_child(name_lbl)

	# action row: price+buy, or a state label
	var btn := Button.new()
	btn.size = Vector2(300, 72)
	btn.position = Vector2((480 - 300) * 0.5, 236)
	var tint := Color(0.86, 0.90, 0.72)           # soft green buy
	if state == "owned":
		tint = Color(0.84, 0.86, 0.90)
	elif state == "equipped":
		tint = Color(0.74, 0.86, 0.96)
	elif state == "locked":
		tint = Color(0.82, 0.82, 0.84)
	btn.add_theme_stylebox_override("normal", _capsule(tint))
	btn.add_theme_stylebox_override("hover", _capsule(tint.lightened(0.06)))
	btn.add_theme_stylebox_override("pressed", _capsule(tint.darkened(0.10)))
	btn.add_theme_stylebox_override("disabled", _capsule(Color(0.82, 0.82, 0.84)))
	btn.disabled = state in ["owned", "equipped", "locked"]
	btn.pressed.connect(func() -> void: action.emit(id))
	add_child(btn)

	if state == "buy":
		var cur_icon := TextureRect.new()
		cur_icon.texture = load(CUR + ("gem.png" if _data.get("currency", "gem") == "gem" else "coin_star.png"))
		cur_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cur_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cur_icon.custom_minimum_size = Vector2(40, 40)
		cur_icon.size = cur_icon.custom_minimum_size
		cur_icon.position = Vector2(78, 17)
		cur_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(cur_icon)
		var price := Label.new()
		price.text = str(_data.get("price", 0))
		price.add_theme_color_override("font_color", Color(0.30, 0.40, 0.24))
		price.add_theme_font_size_override("font_size", 38)
		price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		price.position = Vector2(128, 0)
		price.size = Vector2(120, 74)
		price.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(price)
	else:
		var state_lbl := Label.new()
		state_lbl.text = {"owned": "Owned", "equipped": "Equipped", "locked": "Locked"}.get(state, "")
		state_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		state_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		state_lbl.add_theme_color_override("font_color", Color(0.42, 0.44, 0.5))
		state_lbl.add_theme_font_size_override("font_size", 34)
		state_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		state_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(state_lbl)

	# corner badge (e.g. NEW)
	var badge := String(_data.get("badge", ""))
	if badge == "new":
		var b := TextureRect.new()
		b.texture = load(SHOP + "badge_new.png")
		b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		b.custom_minimum_size = Vector2(96, 60)
		b.size = b.custom_minimum_size
		b.position = Vector2(-6, -6)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(b)

func _capsule(tint: Color) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://assets/sprites/ui/core/chip_capsule.png")
	sb.set_texture_margin_all(30)
	sb.modulate_color = tint
	return sb
