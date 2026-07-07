extends Control
class_name CatLogScreen
## Cat Log — the rescued-cat collection/dex (handoff §8.6). A large preview of the
## selected cat (portrait, origin biome, personality, rescue story, equip) sits
## above a grid of cat cards. Warm and collectible, never gacha-flashy.

signal nav_selected(id: String)
signal back_pressed

const DESIGN := Vector2(1080, 1920)
const INK := Color(0.34, 0.29, 0.24)
const INK_SOFT := Color(0.52, 0.47, 0.42)

const UI := "res://assets/sprites/ui/"
const TRAV := UI + "traveler/"
const CORE := UI + "core/"
const ICONS := UI + "icons/"
const CATS := "res://assets/sprites/cat/"

var _cats := []
var _selected_id := ""
var _cards := {}          # id -> CatCard

# preview widgets
var _p_portrait: TextureRect
var _p_name: Label
var _p_biome: Label
var _p_personality: Label
var _p_story: Label
var _p_btn: Button
var _p_btn_label: Label
var _equipped_id := "mochi"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = DESIGN
	_cats = _roster()
	_build_background()
	_build_header()
	_build_preview()
	_build_grid()
	_build_bottom_nav()
	_select("mochi")

func _roster() -> Array:
	# [id, name, biome, personality, story, sprite, state]
	return [
		["mochi", "Mochi", "Dream Sky", "Curious", "Found napping on the very first cloud, ready for the sky.", CATS + "cat_happy.png", "equipped"],
		["nova", "Nova", "Pastel Galaxy Garden", "Elegant", "Drifted in quietly on a long trail of stardust.", CATS + "cat_curious.png", "rescued"],
		["lumen", "Lumen", "Tachyon Drift", "Energetic", "Zipped past in a burst of light and doubled back to say hi.", CATS + "cat_cheer.png", "rescued"],
		["bloom", "Bloom", "Wormhole Garden", "Dreamy", "Playing among the spiral flowers when you found her.", CATS + "cat_determined.png", "rescued"],
		["kumo", "Kumo", "Kuiper Belt", "Quiet", "Waiting patiently beside the icy star-rocks.", CATS + "cat_idle.png", "new"],
		["vanta", "Vanta", "Void Zone", "Shy", "Two soft glowing eyes in the quiet dark.", CATS + "cat_sleepy.png", "locked"],
		["echo", "Echo", "Entropy Field", "Sleepy", "Yawning gently among the fading cosmic dust.", CATS + "cat_sleepy.png", "locked"],
		["singa", "Singa", "Singularity Dream", "Mysterious", "Watching a floating gravity bubble drift by.", CATS + "cat_curious.png", "locked"],
	]

# ---------------------------------------------------------------- background
func _build_background() -> void:
	var bg := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.90, 0.90, 0.96))
	grad.set_color(1, Color(0.97, 0.94, 0.90))
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
	plaque.size = Vector2(360, 116)
	plaque.position = Vector2((DESIGN.x - 360) * 0.5, 44)
	add_child(plaque)
	var title := Label.new()
	title.text = "Cat Log"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", INK)
	title.add_theme_font_size_override("font_size", 52)
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plaque.add_child(title)

	# rescued progress plaque, top-left
	var rescued := 0
	for c in _cats:
		if c[6] != "locked":
			rescued += 1
	var chip := NinePatchRect.new()
	chip.texture = load(CORE + "chip_capsule.png")
	chip.patch_margin_left = 30
	chip.patch_margin_right = 30
	chip.patch_margin_top = 18
	chip.patch_margin_bottom = 18
	chip.size = Vector2(220, 72)
	chip.position = Vector2(40, 66)
	add_child(chip)
	var paw := TextureRect.new()
	paw.texture = load(TRAV + "badge_paw.png")
	paw.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paw.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	paw.custom_minimum_size = Vector2(46, 46)
	paw.size = paw.custom_minimum_size
	paw.position = Vector2(20, 13)
	chip.add_child(paw)
	var pl := Label.new()
	pl.text = "%d / %d" % [rescued, _cats.size()]
	pl.add_theme_color_override("font_color", INK)
	pl.add_theme_font_size_override("font_size", 36)
	pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pl.position = Vector2(78, 0)
	pl.size = Vector2(130, 72)
	chip.add_child(pl)

	# filter, top-right
	var filt := TextureButton.new()
	filt.texture_normal = load(CORE + "btn_filter.png")
	filt.ignore_texture_size = true
	filt.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	filt.custom_minimum_size = Vector2(96, 96)
	filt.size = filt.custom_minimum_size
	filt.position = Vector2(DESIGN.x - 40 - 96, 62)
	add_child(filt)

# ------------------------------------------------------------------ preview
func _build_preview() -> void:
	var PW := 1000.0
	var PH := 560.0
	var panel := NinePatchRect.new()
	panel.texture = load(TRAV + "preview_panel.png")
	panel.patch_margin_left = 60
	panel.patch_margin_right = 60
	panel.patch_margin_top = 70
	panel.patch_margin_bottom = 60
	panel.size = Vector2(PW, PH)
	panel.position = Vector2((DESIGN.x - PW) * 0.5, 176)
	add_child(panel)

	# portrait framed, left
	var frame := TextureRect.new()
	frame.texture = load(TRAV + "portrait_frame.png")
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.custom_minimum_size = Vector2(330, 330)
	frame.size = frame.custom_minimum_size
	frame.position = Vector2(50, 120)
	panel.add_child(frame)
	_p_portrait = TextureRect.new()
	_p_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_p_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_p_portrait.custom_minimum_size = Vector2(230, 230)
	_p_portrait.size = _p_portrait.custom_minimum_size
	_p_portrait.position = Vector2(50, 50)
	frame.add_child(_p_portrait)

	var right_x := 430.0
	_p_name = Label.new()
	_p_name.add_theme_color_override("font_color", INK)
	_p_name.add_theme_font_size_override("font_size", 60)
	_p_name.position = Vector2(right_x, 110)
	_p_name.size = Vector2(520, 70)
	panel.add_child(_p_name)

	# biome badge (tiny planet + text)
	var planet := TextureRect.new()
	planet.texture = load(TRAV + "planet.png")
	planet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	planet.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	planet.custom_minimum_size = Vector2(44, 44)
	planet.size = planet.custom_minimum_size
	planet.position = Vector2(right_x, 196)
	panel.add_child(planet)
	_p_biome = Label.new()
	_p_biome.add_theme_color_override("font_color", INK_SOFT)
	_p_biome.add_theme_font_size_override("font_size", 32)
	_p_biome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_p_biome.position = Vector2(right_x + 56, 192)
	_p_biome.size = Vector2(460, 44)
	panel.add_child(_p_biome)

	_p_personality = Label.new()
	_p_personality.add_theme_color_override("font_color", Color(0.55, 0.5, 0.66))
	_p_personality.add_theme_font_size_override("font_size", 30)
	_p_personality.position = Vector2(right_x, 250)
	_p_personality.size = Vector2(460, 40)
	panel.add_child(_p_personality)

	# rescue story on a soft panel
	var story_bg := NinePatchRect.new()
	story_bg.texture = load(TRAV + "story_panel.png")
	story_bg.patch_margin_left = 40
	story_bg.patch_margin_right = 40
	story_bg.patch_margin_top = 40
	story_bg.patch_margin_bottom = 40
	story_bg.size = Vector2(500, 130)
	story_bg.position = Vector2(right_x - 10, 300)
	panel.add_child(story_bg)
	_p_story = Label.new()
	_p_story.add_theme_color_override("font_color", Color(0.45, 0.42, 0.5))
	_p_story.add_theme_font_size_override("font_size", 28)
	_p_story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_p_story.position = Vector2(40, 24)
	_p_story.size = Vector2(430, 90)
	story_bg.add_child(_p_story)

	# equip button
	_p_btn = Button.new()
	_p_btn.size = Vector2(300, 96)
	_p_btn.position = Vector2(right_x + 90, 444)
	_p_btn.add_theme_stylebox_override("normal", _capsule(Color(0.74, 0.86, 0.96)))
	_p_btn.add_theme_stylebox_override("hover", _capsule(Color(0.82, 0.91, 0.99)))
	_p_btn.add_theme_stylebox_override("pressed", _capsule(Color(0.64, 0.78, 0.90)))
	_p_btn.add_theme_stylebox_override("disabled", _capsule(Color(0.84, 0.84, 0.86)))
	_p_btn.pressed.connect(_on_equip)
	panel.add_child(_p_btn)
	_p_btn_label = Label.new()
	_p_btn_label.text = "Equip"
	_p_btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p_btn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_p_btn_label.add_theme_color_override("font_color", Color(0.24, 0.34, 0.46))
	_p_btn_label.add_theme_font_size_override("font_size", 40)
	_p_btn_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_p_btn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_p_btn.add_child(_p_btn_label)

# --------------------------------------------------------------------- grid
func _build_grid() -> void:
	var cols := 4
	var cw := 230.0
	var gap := 20.0
	var total := cols * cw + (cols - 1) * gap
	var ox := (DESIGN.x - total) * 0.5
	var oy := 792.0
	for i in range(_cats.size()):
		var c: Array = _cats[i]
		var card := CatCard.new()
		card.configure({"id": c[0], "name": c[1], "sprite": c[5], "state": c[6]})
		var col := i % cols
		var row := i / cols
		card.position = Vector2(ox + col * (cw + gap), oy + row * (262 + gap))
		card.selected.connect(_select)
		add_child(card)
		_cards[c[0]] = card

# ------------------------------------------------------------- interactions
func _select(id: String) -> void:
	var data: Array = []
	for c in _cats:
		if c[0] == id:
			data = c
			break
	if data.is_empty():
		return
	if _selected_id != "" and _cards.has(_selected_id):
		_cards[_selected_id].set_selected(false)
	_selected_id = id
	if _cards.has(id):
		_cards[id].set_selected(true)

	var locked: bool = data[6] == "locked"
	_p_portrait.texture = load(String(data[5]))
	_p_portrait.modulate = Color(0.16, 0.16, 0.22, 0.9) if locked else Color.WHITE
	_p_name.text = "???" if locked else String(data[1])
	_p_biome.text = String(data[2])
	_p_personality.text = "" if locked else ("“%s”" % String(data[3]))
	_p_story.text = ("This cat is still waiting to be found." if locked else String(data[4]))
	_refresh_equip(id, data[6])

func _refresh_equip(id: String, state: String) -> void:
	if state == "locked":
		_p_btn.disabled = true
		_p_btn_label.text = "Locked"
	elif id == _equipped_id:
		_p_btn.disabled = true
		_p_btn_label.text = "Equipped"
	else:
		_p_btn.disabled = false
		_p_btn_label.text = "Equip"

func _on_equip() -> void:
	if _selected_id == "" or _selected_id == _equipped_id:
		return
	# move the equipped marker
	var old := _equipped_id
	_equipped_id = _selected_id
	for c in _cats:
		if c[0] == old and c[6] == "equipped":
			c[6] = "rescued"
		if c[0] == _selected_id and c[6] != "locked":
			c[6] = "equipped"
	_refresh_equip(_selected_id, "equipped")
	print("[cat_log] equipped ", _selected_id)

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
	], 2, bar_h)
	nav.tab_selected.connect(func(id: String) -> void: nav_selected.emit(id))
	add_child(nav)
