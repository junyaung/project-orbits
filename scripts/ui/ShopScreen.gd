extends Control
class_name ShopScreen
## Shop — a gentle "space travel supply shop" for cosmetics (handoff §7.2): tabs
## for Featured / Covers / Trails / Travelers, a soft featured banner, and a
## scrollable grid of watercolor item cards. No casino styling, no loud sales.

signal nav_selected(id: String)
signal close_pressed

const DESIGN := Vector2(1080, 1920)
const INK := Color(0.34, 0.29, 0.24)
const INK_SOFT := Color(0.55, 0.50, 0.44)

const UI := "res://assets/sprites/ui/"
const SHOP := UI + "shop/"
const CORE := UI + "core/"
const ICONS := UI + "icons/"
const CUR := UI + "currency/"
const CATS := "res://assets/sprites/cat/"

const TABS := ["Featured", "Covers", "Trails", "Travelers"]

# demo wallet
var coins := 4389
var gems := 360

var _coin_chip: CurrencyChip
var _gem_chip: CurrencyChip
var _current_tab := 0
var _tab_nodes: Array[NinePatchRect] = []
var _tab_labels: Array[Label] = []
var _content: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = DESIGN
	_build_background()
	_build_header()
	_build_tabs()
	_build_scroll()
	_build_bottom_nav()
	_show_tab(0)

# ---------------------------------------------------------------- background
func _build_background() -> void:
	var bg := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.24, 0.29, 0.46))
	grad.set_color(1, Color(0.42, 0.50, 0.66))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 8
	gt.height = 64
	bg.texture = gt
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

# ------------------------------------------------------------------- header
func _build_header() -> void:
	var plaque := NinePatchRect.new()
	plaque.texture = load(CORE + "plaque_title.png")
	plaque.patch_margin_left = 44
	plaque.patch_margin_right = 44
	plaque.patch_margin_top = 34
	plaque.patch_margin_bottom = 34
	plaque.size = Vector2(320, 116)
	plaque.position = Vector2((DESIGN.x - 320) * 0.5, 44)
	add_child(plaque)
	var title := Label.new()
	title.text = "Shop"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", INK)
	title.add_theme_font_size_override("font_size", 52)
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plaque.add_child(title)

	_coin_chip = CurrencyChip.new()
	_coin_chip.configure(CUR + "coin_star.png", coins, true)
	_coin_chip.position = Vector2(40, 66)
	add_child(_coin_chip)

	_gem_chip = CurrencyChip.new()
	_gem_chip.configure(CUR + "gem.png", gems, true)
	_gem_chip.chip_height = 74
	_gem_chip.position = Vector2(40, 156)
	add_child(_gem_chip)

	var close := TextureButton.new()
	close.texture_normal = load(CORE + "btn_close.png")
	close.ignore_texture_size = true
	close.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close.custom_minimum_size = Vector2(104, 104)
	close.size = close.custom_minimum_size
	close.position = Vector2(DESIGN.x - 40 - 104, 62)
	close.pressed.connect(func() -> void: close_pressed.emit())
	add_child(close)

# --------------------------------------------------------------------- tabs
func _build_tabs() -> void:
	var n := TABS.size()
	var margin := 36.0
	var gap := 16.0
	var tw: float = (DESIGN.x - margin * 2 - gap * (n - 1)) / float(n)
	for i in range(n):
		var np := NinePatchRect.new()
		np.texture = load(SHOP + "tab_normal.png")
		np.patch_margin_left = 30
		np.patch_margin_right = 30
		np.patch_margin_top = 20
		np.patch_margin_bottom = 20
		np.size = Vector2(tw, 84)
		np.position = Vector2(margin + i * (tw + gap), 250)
		add_child(np)
		_tab_nodes.append(np)

		var lbl := Label.new()
		lbl.text = TABS[i]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 30)
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		np.add_child(lbl)
		_tab_labels.append(lbl)

		var hit := Button.new()
		hit.flat = true
		hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var idx := i
		hit.pressed.connect(func() -> void: _show_tab(idx))
		np.add_child(hit)

# ------------------------------------------------------------------- scroll
func _build_scroll() -> void:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 358)
	scroll.size = Vector2(DESIGN.x, DESIGN.y - 358 - 176)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 26)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(_content)

func _show_tab(idx: int) -> void:
	_current_tab = idx
	for i in range(_tab_nodes.size()):
		var on: bool = (i == idx)
		_tab_nodes[i].texture = load(SHOP + ("tab_selected.png" if on else "tab_normal.png"))
		_tab_labels[i].add_theme_color_override("font_color", INK if on else INK_SOFT)
	_rebuild_content()

func _rebuild_content() -> void:
	for c in _content.get_children():
		c.queue_free()

	if _current_tab == 0:
		_add_featured_banner()

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	_content.add_child(grid)
	for item in _items_for_tab(_current_tab):
		var card := ShopItemCard.new()
		card.configure(item)
		card.action.connect(_on_item_action)
		grid.add_child(card)

func _add_featured_banner() -> void:
	var banner := NinePatchRect.new()
	banner.texture = load(SHOP + "featured_banner.png")
	banner.patch_margin_left = 50
	banner.patch_margin_right = 50
	banner.patch_margin_top = 50
	banner.patch_margin_bottom = 50
	banner.custom_minimum_size = Vector2(984, 300)
	_content.add_child(banner)

	var title := Label.new()
	title.text = "Stellar Explorer Bundle"
	title.add_theme_color_override("font_color", Color(0.99, 0.98, 0.94))
	title.add_theme_color_override("font_outline_color", Color(0.3, 0.34, 0.5, 0.7))
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_font_size_override("font_size", 46)
	title.position = Vector2(50, 44)
	title.size = Vector2(600, 56)
	banner.add_child(title)

	var sub := Label.new()
	sub.text = "Everything for your next orbit adventure"
	sub.add_theme_color_override("font_color", Color(0.95, 0.96, 0.99))
	sub.add_theme_font_size_override("font_size", 30)
	sub.position = Vector2(50, 112)
	sub.size = Vector2(560, 44)
	banner.add_child(sub)

	var price := Button.new()
	price.size = Vector2(240, 88)
	price.position = Vector2(50, 182)
	price.add_theme_stylebox_override("normal", _capsule(Color(1, 0.82, 0.78)))
	price.add_theme_stylebox_override("hover", _capsule(Color(1, 0.88, 0.84)))
	price.add_theme_stylebox_override("pressed", _capsule(Color(0.92, 0.74, 0.70)))
	_content.get_child(0).add_child(price)
	var plbl := Label.new()
	plbl.text = "$4.99"
	plbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plbl.add_theme_color_override("font_color", Color(0.6, 0.28, 0.24))
	plbl.add_theme_font_size_override("font_size", 40)
	plbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price.add_child(plbl)

	var best := TextureRect.new()
	best.texture = load(SHOP + "badge_bestvalue.png")
	best.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	best.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	best.custom_minimum_size = Vector2(220, 90)
	best.size = best.custom_minimum_size
	best.position = Vector2(984 - 240, 150)
	best.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(best)

func _items_for_tab(tab: int) -> Array:
	match tab:
		1:  # Covers (manhole skins)
			return [
				{"id": "cover_classic", "name": "Classic Cover", "preview": "res://assets/sprites/manhole/manhole_top.png", "state": "equipped"},
				{"id": "cover_blossom", "name": "Blossom Moon", "preview": SHOP + "manhole_frame.png", "price": 300, "currency": "gem", "state": "buy", "badge": "new"},
				{"id": "cover_meadow", "name": "Sunny Garden", "preview": "res://assets/sprites/planets/planet_meadow.png", "price": 250, "currency": "gem", "state": "buy"},
				{"id": "cover_cloud", "name": "Cloud Hatch", "preview": "res://assets/sprites/planets/planet_cloud.png", "price": 220, "currency": "gem", "state": "owned"},
			]
		2:  # Trails
			return [
				{"id": "trail_stardust", "name": "Stardust Path", "preview": UI + "decor/dust_trail.png", "price": 200, "currency": "gem", "state": "buy", "badge": "new"},
				{"id": "trail_comet", "name": "Comet Tail", "preview": UI + "decor/comet.png", "price": 180, "currency": "gem", "state": "buy"},
				{"id": "trail_petal", "name": "Petal Breeze", "preview": UI + "decor/flowers.png", "price": 150, "currency": "gem", "state": "owned"},
				{"id": "trail_glow", "name": "Star Glow", "preview": UI + "decor/star_glow.png", "price": 260, "currency": "gem", "state": "locked"},
			]
		3:  # Travelers (cat skins)
			return [
				{"id": "cat_mochi", "name": "Mochi", "preview": CATS + "cat_happy.png", "state": "equipped"},
				{"id": "cat_curious", "name": "Nova", "preview": CATS + "cat_curious.png", "price": 400, "currency": "gem", "state": "buy"},
				{"id": "cat_determined", "name": "Lumen", "preview": CATS + "cat_determined.png", "price": 500, "currency": "gem", "state": "buy", "badge": "new"},
				{"id": "cat_sleepy", "name": "Echo", "preview": CATS + "cat_sleepy.png", "price": 450, "currency": "gem", "state": "locked"},
			]
		_:  # Featured highlights
			return [
				{"id": "cover_blossom", "name": "Blossom Moon", "preview": SHOP + "manhole_frame.png", "price": 300, "currency": "gem", "state": "buy", "badge": "new"},
				{"id": "trail_stardust", "name": "Stardust Path", "preview": UI + "decor/dust_trail.png", "price": 200, "currency": "gem", "state": "buy", "badge": "new"},
				{"id": "cat_curious", "name": "Nova", "preview": CATS + "cat_curious.png", "price": 400, "currency": "gem", "state": "buy"},
				{"id": "coins_pack", "name": "Star Coin Bag", "preview": CUR + "coin_bag.png", "price": 500, "currency": "gem", "state": "buy"},
			]

func _on_item_action(id: String) -> void:
	# demo: nothing to persist yet; a real build would purchase/equip here.
	print("[shop] action on ", id)

func _capsule(tint: Color) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(CORE + "chip_capsule.png")
	sb.set_texture_margin_all(30)
	sb.modulate_color = tint
	return sb

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
	], 3, bar_h)
	nav.tab_selected.connect(func(id: String) -> void: nav_selected.emit(id))
	add_child(nav)
