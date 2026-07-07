extends Control
class_name StarPathScreen
## Star Path — a cozy constellation upgrade tree. Four branches (Flight, Survival,
## Stars, Worlds) of watercolor star nodes radiate from a central cat node, joined
## by dotted paths. Selecting a node fills the bottom detail card; Upgrade spends
## gems. Readable and gentle, not a hardcore RPG tree (handoff §7.1).

signal nav_selected(id: String)
signal back_pressed

const DESIGN := Vector2(1080, 1920)
const INK := Color(0.30, 0.33, 0.44)
const INK_SOFT := Color(0.60, 0.64, 0.75)
const GOLD := Color(0.96, 0.80, 0.42)

const UI := "res://assets/sprites/ui/"
const SP := UI + "star_path/"
const CORE := UI + "core/"
const ICONS := UI + "icons/"
const CUR := UI + "currency/"

const BRANCHES := {
	"flight":   {"label": "Flight",   "dir": Vector2(-0.685, -0.728), "tint": Color(0.78, 0.74, 0.95)},
	"survival": {"label": "Survival", "dir": Vector2(0.685, -0.728),  "tint": Color(0.78, 0.90, 0.74)},
	"stars":    {"label": "Stars",    "dir": Vector2(-0.84, 0.543),   "tint": Color(0.74, 0.84, 0.96)},
	"worlds":   {"label": "Worlds",   "dir": Vector2(0.84, 0.543),    "tint": Color(0.92, 0.84, 0.70)},
}
const TIER_DIST := [200.0, 350.0, 500.0]
var _center := Vector2(540, 800)

# demo meta value
var gems := 2450

var _nodes := {}          # id -> data dict
var _links := []          # [[Vector2, Vector2], ...] for the dotted paths
var _selected_id := ""
var _gem_chip: CurrencyChip
var _draw_layer: Control

# detail card widgets
var _d_icon: TextureRect
var _d_name: Label
var _d_level: Label
var _d_effect: Label
var _d_cost: Label
var _d_btn: Button
var _d_btn_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = DESIGN
	_build_background()
	_build_header()
	_build_tree()
	_build_detail_card()
	_build_bottom_nav()
	_select("launch_power")

# ---------------------------------------------------------------- background
func _build_background() -> void:
	var bg := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.16, 0.19, 0.34))
	grad.set_color(1, Color(0.30, 0.34, 0.50))
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

	# scattered star sparkles
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var spark: Texture2D = load("res://assets/sprites/ui/decor/star_glow.png")
	for i in range(22):
		var s := TextureRect.new()
		s.texture = spark
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var sz := rng.randf_range(12, 30)
		s.custom_minimum_size = Vector2(sz, sz)
		s.size = s.custom_minimum_size
		s.position = Vector2(rng.randf_range(20, DESIGN.x - 20), rng.randf_range(300, 1290))
		s.modulate = Color(1, 1, 0.95, rng.randf_range(0.3, 0.75))
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(s)

# ------------------------------------------------------------------- header
func _build_header() -> void:
	var plaque := NinePatchRect.new()
	plaque.texture = load(CORE + "plaque_title.png")
	plaque.patch_margin_left = 44
	plaque.patch_margin_right = 44
	plaque.patch_margin_top = 34
	plaque.patch_margin_bottom = 34
	plaque.size = Vector2(420, 120)
	plaque.position = Vector2((DESIGN.x - 420) * 0.5, 150)
	add_child(plaque)
	var title := Label.new()
	title.text = "Star Path"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.34, 0.29, 0.24))
	title.add_theme_font_size_override("font_size", 52)
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plaque.add_child(title)

	_gem_chip = CurrencyChip.new()
	_gem_chip.configure(CUR + "gem.png", gems, true)
	_gem_chip.position = Vector2(40, 168)
	add_child(_gem_chip)

	# back button, top-right
	var back := TextureButton.new()
	back.texture_normal = load(CORE + "btn_back.png")
	back.ignore_texture_size = true
	back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	back.custom_minimum_size = Vector2(104, 104)
	back.size = back.custom_minimum_size
	back.position = Vector2(DESIGN.x - 40 - 104, 168)
	back.pressed.connect(func() -> void: back_pressed.emit())
	add_child(back)

# --------------------------------------------------------------------- tree
func _tree_data() -> Array:
	# [id, branch, name, icon, effect(with %d for value), level, max, cost]
	return [
		["launch_power", "flight", "Comet Boost", ICONS + "icon_rocket.png", "Increase launch speed by %d%%.", 1, 5, 450],
		["gravity_grip", "flight", "Gravity Grip", ICONS + "icon_magnet.png", "Capture planets from %d%% farther.", 0, 5, 300],
		["perfect_sling", "flight", "Perfect Sling", ICONS + "icon_star_glow.png", "Widen the perfect-release window.", 0, 3, 600],
		["heat_capacity", "survival", "Heat Capacity", ICONS + "icon_heat.png", "Raise the overheat limit by %d%%.", 0, 5, 400],
		["cool_drift", "survival", "Cool Drift", ICONS + "icon_cloud.png", "Cool down %d%% faster while drifting.", 0, 5, 350],
		["shield_bubble", "survival", "Shield Bubble", ICONS + "icon_shield_star.png", "Begin each run with a shield.", 0, 3, 800],
		["star_magnet", "stars", "Star Magnet", ICONS + "icon_magnet.png", "Pull in stars from %d%% farther.", 0, 5, 300],
		["bonus_star", "stars", "Bonus Star", ICONS + "icon_star_glow.png", "Each star is worth +%d.", 0, 5, 350],
		["lucky_drift", "stars", "Lucky Drift", ICONS + "icon_gift.png", "Chance of a bonus star shower.", 0, 3, 700],
		["meadow_drift", "worlds", "Meadow Drift", ICONS + "icon_worlds.png", "Better control in the meadow sky.", 1, 3, 500],
		["tachyon_flow", "worlds", "Tachyon Flow", ICONS + "icon_upgrade.png", "Steadier drift through Tachyon.", 0, 3, 900],
		["wormhole_balance", "worlds", "Wormhole Balance", ICONS + "icon_paw_shield.png", "Stability inside wormholes.", 0, 3, 1200],
	]

func _build_tree() -> void:
	# dashed connection layer sits behind the nodes
	_draw_layer = _ConnDraw.new()
	_draw_layer.owner_screen = self
	_draw_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_draw_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_draw_layer)

	# central hub node (blue manhole cover = brand motif)
	var central := TextureRect.new()
	central.texture = load(SP + "node_central_manhole.png")
	central.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	central.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	central.custom_minimum_size = Vector2(150, 150)
	central.size = central.custom_minimum_size
	central.position = _center - central.size * 0.5
	central.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# group nodes per branch to lay out tiers along the branch direction
	var per_branch := {}
	for row in _tree_data():
		var b: String = row[1]
		if not per_branch.has(b):
			per_branch[b] = []
		per_branch[b].append(row)

	for b in per_branch.keys():
		var dir: Vector2 = BRANCHES[b]["dir"]
		var rows: Array = per_branch[b]
		var prev := _center
		var positions := []
		for i in range(rows.size()):
			var row: Array = rows[i]
			var pos: Vector2 = _center + dir * TIER_DIST[i]
			positions.append(pos)
			_links.append([prev, pos])
			prev = pos
			_add_node(row, pos, i)
		_add_branch_label(b, positions)

	add_child(central)   # central drawn above the links
	_draw_layer.queue_redraw()

func _add_node(row: Array, pos: Vector2, tier: int) -> void:
	var id: String = row[0]
	var level: int = row[5]
	var maxl: int = row[6]
	var state := _state_for(id, level, maxl, tier, row[1])
	var data := {
		"id": id, "branch": row[1], "name": row[2], "icon": row[3],
		"effect": row[4], "level": level, "max": maxl, "cost": row[7],
		"state": state, "pos": pos, "node": null,
	}
	var node := StarPathNode.new()
	node.configure(id, row[3], state, 128.0)
	node.position = pos - Vector2(64, 64)
	node.selected.connect(_select)
	add_child(node)
	data["node"] = node
	_nodes[id] = data

func _state_for(id: String, level: int, maxl: int, tier: int, _branch: String) -> String:
	if level >= maxl and level > 0:
		return "maxed"
	if level > 0:
		return "unlocked"
	# tier 0 is always reachable; deeper tiers unlock behind earlier progress.
	# MVP: tiers 0-1 available, tier 2 locked until you invest.
	return "available" if tier <= 1 else "locked"

func _add_branch_label(b: String, positions: Array) -> void:
	var avg := Vector2.ZERO
	for p in positions:
		avg += p
	avg /= float(positions.size())
	var up: bool = BRANCHES[b]["dir"].y < 0.0
	var plaque := NinePatchRect.new()
	plaque.texture = load(SP + "branch_title_plaque.png")
	plaque.patch_margin_left = 40
	plaque.patch_margin_right = 40
	plaque.patch_margin_top = 22
	plaque.patch_margin_bottom = 22
	plaque.modulate = BRANCHES[b]["tint"]
	var w := 210.0
	plaque.size = Vector2(w, 66)
	var last_y: float = positions[positions.size() - 1].y
	var y: float = (last_y - 96.0) if up else (last_y + 70.0)
	plaque.position = Vector2(clampf(avg.x - w * 0.5, 20, DESIGN.x - w - 20), y)
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plaque)
	var lbl := Label.new()
	lbl.text = String(BRANCHES[b]["label"])
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(0.30, 0.28, 0.26))
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plaque.add_child(lbl)

# ---------------------------------------------------------------- detail card
func _build_detail_card() -> void:
	var CW := 1000.0
	var CH := 340.0
	var card := NinePatchRect.new()
	card.texture = load(SP + "detail_panel.png")
	card.patch_margin_left = 50
	card.patch_margin_right = 50
	card.patch_margin_top = 50
	card.patch_margin_bottom = 50
	card.size = Vector2(CW, CH)
	card.position = Vector2((DESIGN.x - CW) * 0.5, 1360)
	add_child(card)

	# upgrade icon in a frame, left
	var frame := TextureRect.new()
	frame.texture = load(SP + "upgrade_icon_frame.png")
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.custom_minimum_size = Vector2(180, 180)
	frame.size = frame.custom_minimum_size
	frame.position = Vector2(50, 80)
	card.add_child(frame)
	_d_icon = TextureRect.new()
	_d_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_d_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_d_icon.custom_minimum_size = Vector2(100, 100)
	_d_icon.size = _d_icon.custom_minimum_size
	_d_icon.position = Vector2(40, 40)
	frame.add_child(_d_icon)

	_d_name = Label.new()
	_d_name.add_theme_color_override("font_color", Color(0.30, 0.28, 0.26))
	_d_name.add_theme_font_size_override("font_size", 46)
	_d_name.position = Vector2(260, 70)
	_d_name.size = Vector2(500, 56)
	card.add_child(_d_name)

	_d_level = Label.new()
	_d_level.add_theme_color_override("font_color", INK_SOFT)
	_d_level.add_theme_font_size_override("font_size", 34)
	_d_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_d_level.position = Vector2(560, 78)
	_d_level.size = Vector2(390, 44)
	card.add_child(_d_level)

	_d_effect = Label.new()
	_d_effect.add_theme_color_override("font_color", Color(0.40, 0.42, 0.5))
	_d_effect.add_theme_font_size_override("font_size", 34)
	_d_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_effect.position = Vector2(260, 138)
	_d_effect.size = Vector2(690, 90)
	card.add_child(_d_effect)

	# cost chip (gem + number)
	var cost_gem := TextureRect.new()
	cost_gem.texture = load(CUR + "gem.png")
	cost_gem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cost_gem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cost_gem.custom_minimum_size = Vector2(52, 52)
	cost_gem.size = cost_gem.custom_minimum_size
	cost_gem.position = Vector2(268, 244)
	card.add_child(cost_gem)
	_d_cost = Label.new()
	_d_cost.add_theme_color_override("font_color", Color(0.72, 0.54, 0.24))
	_d_cost.add_theme_font_size_override("font_size", 40)
	_d_cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_d_cost.position = Vector2(330, 240)
	_d_cost.size = Vector2(200, 60)
	card.add_child(_d_cost)

	# upgrade button, right
	# blank cream capsule tinted green (the sheet's Upgrade sprite has baked text,
	# which would clash with our dynamic Upgrade/Maxed/Locked label).
	_d_btn = Button.new()
	_d_btn.size = Vector2(360, 108)
	_d_btn.position = Vector2(CW - 360 - 50, 216)
	_d_btn.add_theme_stylebox_override("normal", _tex_style(CORE + "chip_capsule.png", Color(0.73, 0.87, 0.66)))
	_d_btn.add_theme_stylebox_override("hover", _tex_style(CORE + "chip_capsule.png", Color(0.80, 0.92, 0.72)))
	_d_btn.add_theme_stylebox_override("pressed", _tex_style(CORE + "chip_capsule.png", Color(0.63, 0.77, 0.57)))
	_d_btn.add_theme_stylebox_override("disabled", _tex_style(CORE + "chip_capsule.png", Color(0.80, 0.80, 0.82)))
	_d_btn.pressed.connect(_on_upgrade)
	card.add_child(_d_btn)
	_d_btn_label = Label.new()
	_d_btn_label.text = "Upgrade"
	_d_btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_d_btn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_d_btn_label.add_theme_color_override("font_color", Color(0.26, 0.38, 0.22))
	_d_btn_label.add_theme_font_size_override("font_size", 42)
	_d_btn_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_d_btn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_d_btn.add_child(_d_btn_label)

func _tex_style(path: String, tint := Color.WHITE) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(path)
	sb.set_texture_margin_all(40)
	sb.modulate_color = tint
	return sb

# ------------------------------------------------------------- interactions
func _select(id: String) -> void:
	if not _nodes.has(id):
		return
	if _selected_id != "" and _nodes.has(_selected_id):
		_nodes[_selected_id]["node"].set_selected(false)
	_selected_id = id
	var d: Dictionary = _nodes[id]
	d["node"].set_selected(true)
	_d_icon.texture = load(String(d["icon"]))
	_d_name.text = String(d["name"])
	var lvl: int = d["level"]
	var maxl: int = d["max"]
	_d_level.text = "Lv %d / %d" % [lvl, maxl]
	var eff: String = String(d["effect"])
	_d_effect.text = (eff % ((lvl + 1) * 12)) if eff.contains("%d") else eff
	var state: String = d["state"]
	if state == "maxed":
		_d_cost.text = "MAX"
		_set_upgrade_enabled(false, "Maxed")
	elif state == "locked":
		_d_cost.text = "Locked"
		_set_upgrade_enabled(false, "Locked")
	else:
		_d_cost.text = str(d["cost"])
		_set_upgrade_enabled(gems >= int(d["cost"]), "Upgrade")

func _set_upgrade_enabled(on: bool, label: String) -> void:
	_d_btn.disabled = not on
	_d_btn_label.text = label
	_d_btn_label.modulate.a = 1.0 if on else 0.7

func _on_upgrade() -> void:
	var d: Dictionary = _nodes[_selected_id]
	var cost: int = d["cost"]
	if d["state"] in ["maxed", "locked"] or gems < cost:
		return
	gems -= cost
	_gem_chip.set_count(gems)
	d["level"] = int(d["level"]) + 1
	d["cost"] = int(round(cost * 1.6))
	if int(d["level"]) >= int(d["max"]):
		d["state"] = "maxed"
	else:
		d["state"] = "unlocked"
	d["node"].set_state(d["state"])
	_select(_selected_id)   # refresh card

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
	], 1, bar_h)
	nav.tab_selected.connect(func(id: String) -> void: nav_selected.emit(id))
	add_child(nav)

# --- inner draw helper for the dotted constellation paths -------------------
class _ConnDraw extends Control:
	var owner_screen: StarPathScreen
	func _draw() -> void:
		if owner_screen == null:
			return
		for link in owner_screen._links:
			draw_dashed_line(link[0], link[1], Color(1, 1, 1, 0.34), 4.0, 14.0)
