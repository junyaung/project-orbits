extends Control
class_name HomeScreen
## Home / Launch hub — a cozy watercolor launch base for the orbit cat adventure.
## Dedicated storybook background (starry sky + floating planets + meadow village),
## Mochi on the blue manhole cover as the hero, a compact Event card, Daily/Quests,
## a Star Path progress card, and the dominant Launch CTA. Text is Labels only.

signal launch_pressed
signal nav_selected(id: String)
signal settings_pressed
signal event_pressed

const DESIGN := Vector2(1080, 1920)
const INK := Color(0.34, 0.29, 0.24)
const INK_SOFT := Color(0.46, 0.41, 0.35)

const UI := "res://assets/sprites/ui/"
const CORE := UI + "core/"
const ICONS := UI + "icons/"
const CUR := UI + "currency/"
const HOME := UI + "home/"
const BG := "res://assets/backgrounds/home_hub.png"
const HERO := "res://assets/sprites/cat/cat_happy.png"

# demo/meta values (wire to save data later)
var star_coins := 12840
var star_gems := 685
var best_distance := 7852
var current_cat := "Mochi"

var _coin_chip: CurrencyChip
var _gem_chip: CurrencyChip

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = DESIGN
	_build_background()
	_build_top_bar()
	_build_event_card()
	_build_hero()
	_build_side_buttons()
	_build_upgrade_hint()
	_build_launch()
	_build_bottom_nav()

# ---------------------------------------------------------------- background
func _build_background() -> void:
	var bg := TextureRect.new()
	bg.texture = load(BG)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# very soft readability wash behind the top bar only (the art center is clean)
	var scrim := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.99, 0.98, 0.94, 0.42))
	grad.set_color(1, Color(0.99, 0.98, 0.94, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 8
	gt.height = 64
	scrim.texture = gt
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	scrim.size = Vector2(DESIGN.x, 340)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

# ------------------------------------------------------------------- top bar
func _build_top_bar() -> void:
	_coin_chip = CurrencyChip.new()
	_coin_chip.configure(CUR + "coin_star.png", star_coins, true)
	_coin_chip.position = Vector2(40, 84)
	add_child(_coin_chip)

	_gem_chip = CurrencyChip.new()
	_gem_chip.configure(CUR + "gem.png", star_gems, true)
	_gem_chip.position = Vector2(360, 84)
	add_child(_gem_chip)

	var settings := TextureButton.new()
	settings.texture_normal = load(CORE + "btn_settings.png")
	settings.ignore_texture_size = true
	settings.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	settings.custom_minimum_size = Vector2(112, 112)
	settings.size = settings.custom_minimum_size
	settings.position = Vector2(DESIGN.x - 40 - 112, 78)
	settings.pressed.connect(func() -> void: settings_pressed.emit())
	add_child(settings)

	var plaque := _make_plaque(Vector2(340, 116))
	plaque.position = Vector2((DESIGN.x - 340) * 0.5, 196)
	add_child(plaque)
	var best := Label.new()
	best.text = "Best  %s m" % _commas(best_distance)
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	best.add_theme_color_override("font_color", INK)
	best.add_theme_font_size_override("font_size", 44)
	best.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plaque.add_child(best)

# --------------------------------------------------------------- event card
func _build_event_card() -> void:
	var CW := 436.0
	var CH := 170.0
	var card := NinePatchRect.new()
	card.texture = load(CORE + "panel_small.png")
	card.patch_margin_left = 40
	card.patch_margin_right = 40
	card.patch_margin_top = 40
	card.patch_margin_bottom = 40
	card.size = Vector2(CW, CH)
	card.position = Vector2(40, 322)
	add_child(card)

	# banner thumbnail (clipped to a rounded-ish square)
	var clip := Control.new()
	clip.clip_contents = true
	clip.size = Vector2(132, 132)
	clip.position = Vector2(22, 19)
	card.add_child(clip)
	var thumb := TextureRect.new()
	thumb.texture = load(HOME + "event_banner.png")
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.size = Vector2(132, 132)
	clip.add_child(thumb)

	var title := Label.new()
	title.text = "Stardust Picnic"
	title.add_theme_color_override("font_color", INK)
	title.add_theme_font_size_override("font_size", 32)
	title.position = Vector2(170, 42)
	title.size = Vector2(250, 40)
	card.add_child(title)

	var timer := Label.new()
	timer.text = "⏱  6d 12h"
	timer.add_theme_color_override("font_color", INK_SOFT)
	timer.add_theme_font_size_override("font_size", 28)
	timer.position = Vector2(170, 92)
	timer.size = Vector2(240, 36)
	card.add_child(timer)

	# "Event" ribbon (its art carries the word)
	var ribbon := TextureRect.new()
	ribbon.texture = load(CUR + "ribbon_event.png")
	ribbon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ribbon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ribbon.custom_minimum_size = Vector2(150, 60)
	ribbon.size = ribbon.custom_minimum_size
	ribbon.position = Vector2(-10, -18)
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(ribbon)

	var hit := Button.new()
	hit.flat = true
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(func() -> void: event_pressed.emit())
	card.add_child(hit)

# --------------------------------------------------------------------- hero
func _build_hero() -> void:
	var center := Vector2(DESIGN.x * 0.5, 960)

	var glow := TextureRect.new()
	glow.texture = load("res://assets/sprites/vfx/sparkle.png")
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.modulate = Color(1, 1, 1, 0.45)
	glow.custom_minimum_size = Vector2(540, 540)
	glow.size = glow.custom_minimum_size
	glow.position = center - glow.size * 0.5
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var hero := TextureRect.new()
	hero.texture = load(HERO)
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var hw := 470.0
	hero.custom_minimum_size = Vector2(hw, hw)
	hero.size = hero.custom_minimum_size
	hero.position = center - Vector2(hw * 0.5, hw * 0.55)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hero)
	_bob(hero)

	var name_plaque := _make_plaque(Vector2(240, 90))
	name_plaque.position = Vector2((DESIGN.x - 240) * 0.5, center.y + 168)
	add_child(name_plaque)
	var name_lbl := Label.new()
	name_lbl.text = current_cat
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", INK)
	name_lbl.add_theme_font_size_override("font_size", 38)
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	name_plaque.add_child(name_lbl)

# ------------------------------------------------------------- side buttons
func _build_side_buttons() -> void:
	var daily := _icon_button(HOME + "daily.png", "Daily", true)
	daily.position = Vector2(52, 540)
	add_child(daily)
	var quests := _icon_button(HOME + "quests.png", "Quests", false)
	quests.position = Vector2(52, 716)
	add_child(quests)

# ------------------------------------------------------------ upgrade hint
func _build_upgrade_hint() -> void:
	var card := NinePatchRect.new()
	card.texture = load(CORE + "chip_capsule.png")
	card.patch_margin_left = 30
	card.patch_margin_right = 30
	card.patch_margin_top = 18
	card.patch_margin_bottom = 18
	card.size = Vector2(640, 100)
	card.position = Vector2((DESIGN.x - 640) * 0.5, 1352)
	add_child(card)

	var book := TextureRect.new()
	book.texture = load(HOME + "upgrade_book.png")
	book.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	book.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	book.custom_minimum_size = Vector2(78, 78)
	book.size = book.custom_minimum_size
	book.position = Vector2(20, 11)
	book.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(book)

	var lbl := Label.new()
	lbl.text = "Star Path upgrade ready"
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", INK_SOFT)
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.position = Vector2(112, 0)
	lbl.size = Vector2(480, 100)
	card.add_child(lbl)

	var dot := TextureRect.new()
	dot.texture = load(CORE + "dot_notify.png")
	dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dot.custom_minimum_size = Vector2(34, 34)
	dot.position = Vector2(596, 16)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(dot)

	var hit := Button.new()
	hit.flat = true
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(func() -> void: nav_selected.emit("star_path"))
	card.add_child(hit)

# ------------------------------------------------------------------ launch
func _build_launch() -> void:
	var launch := TextureButton.new()
	launch.texture_normal = load(CORE + "btn_launch_normal.png")
	launch.texture_pressed = load(CORE + "btn_launch_pressed.png")
	launch.texture_hover = load(CORE + "btn_launch_highlighted.png")
	launch.ignore_texture_size = true
	launch.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	var w := 680.0
	var h := 208.0
	launch.custom_minimum_size = Vector2(w, h)
	launch.size = Vector2(w, h)
	launch.position = Vector2((DESIGN.x - w) * 0.5, 1494)
	launch.pressed.connect(func() -> void: launch_pressed.emit())
	add_child(launch)
	_pulse(launch)

# -------------------------------------------------------------- bottom nav
func _build_bottom_nav() -> void:
	var nav := BottomNavBar.new()
	var bar_h := 176.0
	nav.size = Vector2(DESIGN.x, bar_h)
	nav.position = Vector2(0, DESIGN.y - bar_h)
	nav.configure([
		{"id": "home", "icon": ICONS + "nav_home.png", "label": "Home"},
		{"id": "star_path", "icon": ICONS + "nav_starpath.png", "label": "Star Path"},
		{"id": "cat", "icon": ICONS + "nav_cat.png", "label": "Cats"},
		{"id": "shop", "icon": ICONS + "nav_shop.png", "label": "Shop"},
		{"id": "settings", "icon": ICONS + "nav_settings.png", "label": "Settings"},
	], 0, bar_h)
	nav.tab_selected.connect(func(id: String) -> void: nav_selected.emit(id))
	add_child(nav)

# ------------------------------------------------------------------ helpers
func _make_plaque(sz: Vector2) -> NinePatchRect:
	var p := NinePatchRect.new()
	p.texture = load(CORE + "plaque_title.png")
	p.patch_margin_left = 44
	p.patch_margin_right = 44
	p.patch_margin_top = 34
	p.patch_margin_bottom = 34
	p.size = sz
	return p

func _icon_button(icon_path: String, label: String, notify: bool) -> Control:
	var root := Control.new()
	root.size = Vector2(132, 158)

	var bg := TextureRect.new()
	bg.texture = load(CORE + "btn_square_normal.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg.custom_minimum_size = Vector2(132, 132)
	bg.size = bg.custom_minimum_size
	root.add_child(bg)

	var icon := TextureRect.new()
	icon.texture = load(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(88, 88)
	icon.size = icon.custom_minimum_size
	icon.position = Vector2((132 - 88) * 0.5, (132 - 88) * 0.5)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(icon)

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", INK_SOFT)
	lbl.position = Vector2(-10, 134)
	lbl.size = Vector2(152, 30)
	root.add_child(lbl)

	if notify:
		var dot := TextureRect.new()
		dot.texture = load(CORE + "dot_notify.png")
		dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dot.custom_minimum_size = Vector2(34, 34)
		dot.size = dot.custom_minimum_size
		dot.position = Vector2(100, 4)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(dot)

	var hit := Button.new()
	hit.flat = true
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(hit)
	return root

func _bob(node: Control) -> void:
	var base := node.position
	var tw := create_tween().set_loops()
	tw.tween_property(node, "position", base + Vector2(0, -14), 1.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "position", base, 1.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _pulse(node: Control) -> void:
	node.pivot_offset = node.size * 0.5
	var tw := create_tween().set_loops()
	tw.tween_property(node, "scale", Vector2(1.04, 1.04), 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _commas(value: int) -> String:
	var s := str(absi(value))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return out
