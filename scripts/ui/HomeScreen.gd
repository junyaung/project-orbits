extends Control
class_name HomeScreen
## Home / Launch hub. Cozy watercolor launch lobby built from the sliced UXUI_2
## sprite kit. Launch is the strongest CTA; the biome background is muted for
## readability. Text is added here with Labels (never baked into sprites).
##
## Layout is authored at the 1080x1920 design resolution; the project's
## canvas_items / expand stretch handles real device sizes.

signal launch_pressed
signal nav_selected(id: String)
signal settings_pressed

const DESIGN := Vector2(1080, 1920)
const INK := Color(0.34, 0.29, 0.24)
const INK_SOFT := Color(0.46, 0.41, 0.35)
const GOLD := Color(0.93, 0.72, 0.30)

const UI := "res://assets/sprites/ui/"
const CORE := UI + "core/"
const ICONS := UI + "icons/"
const CUR := UI + "currency/"
const BG := "res://assets/backgrounds/home_dream_sky.png"
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
	add_child(bg)

	# mute the biome (handoff: soften saturation/contrast behind UI)
	var mute := ColorRect.new()
	mute.color = Color(0.98, 0.96, 0.90, 0.12)
	mute.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mute.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mute)

	# top scrim for legibility behind the chips/plaque
	var scrim := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.80, 0.87, 0.93, 0.55))
	grad.set_color(1, Color(0.80, 0.87, 0.93, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 8
	gt.height = 64
	scrim.texture = gt
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	scrim.position = Vector2.ZERO
	scrim.size = Vector2(DESIGN.x, 440)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

# ------------------------------------------------------------------- top bar
func _build_top_bar() -> void:
	_coin_chip = CurrencyChip.new()
	_coin_chip.configure(CUR + "coin_star.png", star_coins, true)
	_coin_chip.position = Vector2(40, 92)
	add_child(_coin_chip)

	_gem_chip = CurrencyChip.new()
	_gem_chip.configure(CUR + "gem.png", star_gems, true)
	_gem_chip.position = Vector2(360, 92)
	add_child(_gem_chip)

	# settings, top-right
	var settings := TextureButton.new()
	settings.texture_normal = load(CORE + "btn_settings.png")
	settings.ignore_texture_size = true
	settings.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	settings.custom_minimum_size = Vector2(112, 112)
	settings.size = settings.custom_minimum_size
	settings.position = Vector2(DESIGN.x - 40 - 112, 84)
	settings.pressed.connect(func() -> void: settings_pressed.emit())
	add_child(settings)

	# best distance plaque, centered below chips
	var plaque := _make_plaque(Vector2(340, 118))
	plaque.position = Vector2((DESIGN.x - 340) * 0.5, 210)
	add_child(plaque)

	var best := Label.new()
	best.text = "Best  %s m" % _commas(best_distance)
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	best.add_theme_color_override("font_color", INK)
	best.add_theme_font_size_override("font_size", 44)
	best.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plaque.add_child(best)

# --------------------------------------------------------------------- hero
func _build_hero() -> void:
	var center := Vector2(DESIGN.x * 0.5, 860)

	# soft orbit ring behind the cat
	var ring := Line2D.new()
	ring.width = 5.0
	ring.default_color = Color(1, 1, 1, 0.35)
	ring.closed = true
	ring.antialiased = true
	var rx := 330.0
	var ry := 150.0
	for i in range(72):
		var a := TAU * float(i) / 72.0
		ring.add_point(center + Vector2(cos(a) * rx, sin(a) * ry))
	add_child(ring)

	# glow puff behind hero
	var glow := TextureRect.new()
	glow.texture = load("res://assets/sprites/vfx/sparkle.png")
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.modulate = Color(1, 1, 1, 0.5)
	glow.custom_minimum_size = Vector2(560, 560)
	glow.size = glow.custom_minimum_size
	glow.position = center - glow.size * 0.5
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var hero := TextureRect.new()
	hero.texture = load(HERO)
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var hw := 500.0
	hero.custom_minimum_size = Vector2(hw, hw)
	hero.size = hero.custom_minimum_size
	hero.position = center - Vector2(hw * 0.5, hw * 0.55)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hero)
	_bob(hero)

	# selected cat name plaque under the hero
	var name_plaque := _make_plaque(Vector2(240, 90))
	name_plaque.position = Vector2((DESIGN.x - 240) * 0.5, center.y + 180)
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
	var daily := _icon_button(ICONS + "nav_cat.png", "Daily", true)
	daily.position = Vector2(40, 720)
	add_child(daily)
	var quests := _icon_button(ICONS + "nav_starpath.png", "Quests", false)
	quests.position = Vector2(40, 900)
	add_child(quests)

# ------------------------------------------------------------ upgrade hint
func _build_upgrade_hint() -> void:
	var card := NinePatchRect.new()
	card.texture = load(CORE + "chip_capsule.png")
	card.patch_margin_left = 30
	card.patch_margin_right = 30
	card.patch_margin_top = 18
	card.patch_margin_bottom = 18
	card.size = Vector2(640, 92)
	card.position = Vector2((DESIGN.x - 640) * 0.5, 1360)
	add_child(card)

	var star := TextureRect.new()
	star.texture = load(ICONS + "nav_starpath.png")
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.custom_minimum_size = Vector2(64, 64)
	star.position = Vector2(24, 14)
	card.add_child(star)

	var lbl := Label.new()
	lbl.text = "Star Path upgrade ready"
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", INK_SOFT)
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.position = Vector2(104, 0)
	lbl.size = Vector2(500, 92)
	card.add_child(lbl)

	var dot := TextureRect.new()
	dot.texture = load(CORE + "dot_notify.png")
	dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dot.custom_minimum_size = Vector2(34, 34)
	dot.position = Vector2(596, 14)
	card.add_child(dot)

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
	launch.position = Vector2((DESIGN.x - w) * 0.5, 1500)
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
	icon.custom_minimum_size = Vector2(78, 78)
	icon.size = icon.custom_minimum_size
	icon.position = Vector2((132 - 78) * 0.5, (132 - 78) * 0.5)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(icon)

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", INK_SOFT)
	lbl.position = Vector2(0, 132)
	lbl.size = Vector2(132, 30)
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
