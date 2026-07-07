extends Control
class_name CurrencyChip
## Reusable currency pill: capsule bg + icon + count label + optional plus button.
## Set properties, then add to the tree; it builds itself in _ready().
## Update the number later with set_count().

signal plus_pressed

const INK := Color(0.36, 0.31, 0.26)
const CAPSULE := "res://assets/sprites/ui/core/chip_capsule.png"
const PLUS := "res://assets/sprites/ui/core/btn_plus.png"

@export var icon_path := "res://assets/sprites/ui/currency/coin_star.png"
@export var count := 0
@export var show_plus := true
@export var chip_height := 74.0

var _count_label: Label
var _bg: NinePatchRect

func configure(p_icon: String, p_count: int, p_show_plus := true) -> void:
	icon_path = p_icon
	count = p_count
	show_plus = p_show_plus

func _ready() -> void:
	var icon_tex: Texture2D = load(icon_path)
	var plus_tex: Texture2D = load(PLUS)
	var icon_size := chip_height * 0.62
	var pad := chip_height * 0.34

	# background capsule (9-slice so it stretches cleanly to any width)
	_bg = NinePatchRect.new()
	_bg.texture = load(CAPSULE)
	_bg.patch_margin_left = 30
	_bg.patch_margin_right = 30
	_bg.patch_margin_top = 18
	_bg.patch_margin_bottom = 18
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	var icon := TextureRect.new()
	icon.texture = icon_tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.position = Vector2(pad * 0.5, (chip_height - icon_size) * 0.5)
	add_child(icon)

	_count_label = Label.new()
	_count_label.text = _format(count)
	_count_label.add_theme_color_override("font_color", INK)
	_count_label.add_theme_font_size_override("font_size", int(chip_height * 0.42))
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_count_label.position = Vector2(pad * 0.5 + icon_size + 10, 0)
	_count_label.size = Vector2(0, chip_height)
	add_child(_count_label)

	# width = icon + gap + text + (plus) + paddings; measured after label sizes
	await get_tree().process_frame
	var text_w: float = _count_label.get_minimum_size().x
	var plus_w := chip_height * 0.9 if show_plus else 0.0
	var total_w: float = pad * 0.5 + icon_size + 10 + text_w + 14 + plus_w + pad * 0.5
	custom_minimum_size = Vector2(total_w, chip_height)
	size = custom_minimum_size

	if show_plus:
		var plus := TextureButton.new()
		plus.texture_normal = plus_tex
		plus.ignore_texture_size = true
		plus.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		plus.custom_minimum_size = Vector2(chip_height * 0.82, chip_height * 0.82)
		plus.size = plus.custom_minimum_size
		plus.position = Vector2(total_w - plus_w - pad * 0.15, (chip_height - chip_height * 0.82) * 0.5)
		plus.pressed.connect(func() -> void: plus_pressed.emit())
		add_child(plus)

func set_count(value: int) -> void:
	count = value
	if _count_label:
		_count_label.text = _format(value)

func _format(value: int) -> String:
	# thousands separators, e.g. 12840 -> 12,840
	var s := str(absi(value))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if value < 0 else "") + out
