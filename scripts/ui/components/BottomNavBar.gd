extends Control
class_name BottomNavBar
## Reusable bottom navigation. Configure with a list of tabs (id, icon, label),
## builds evenly-spaced icon+label buttons on a soft cream bar, and emits
## tab_selected(id) when a tab is tapped. The selected tab is highlighted.

signal tab_selected(id: String)

const INK := Color(0.36, 0.31, 0.26)
const INK_DIM := Color(0.55, 0.50, 0.44)
const GOLD := Color(0.95, 0.74, 0.32)
const BAR_BG := Color(0.98, 0.95, 0.88, 0.94)
const BAR_BORDER := Color(0.83, 0.74, 0.60)

var _tabs: Array = []           # [{id, icon, label}]
var _selected := 0
var _icon_nodes: Array[TextureRect] = []
var _label_nodes: Array[Label] = []
var _bar_height := 176.0

func configure(tabs: Array, selected := 0, bar_height := 176.0) -> void:
	_tabs = tabs
	_selected = selected
	_bar_height = bar_height

func _ready() -> void:
	# soft cream bar background
	var bar := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = BAR_BG
	sb.border_color = BAR_BORDER
	sb.set_border_width_all(3)
	sb.border_width_bottom = 0
	sb.set_corner_radius_all(38)
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	sb.shadow_color = Color(0.4, 0.42, 0.5, 0.16)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, -4)
	bar.add_theme_stylebox_override("panel", sb)
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bar)

	var n: int = _tabs.size()
	var tab_w: float = size.x / float(maxi(n, 1))
	for i in range(n):
		var t: Dictionary = _tabs[i]
		var col := Control.new()
		col.position = Vector2(tab_w * i, 0)
		col.size = Vector2(tab_w, _bar_height)
		add_child(col)

		var icon := TextureRect.new()
		icon.texture = load(String(t.get("icon", "")))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_h := 78.0
		icon.custom_minimum_size = Vector2(icon_h, icon_h)
		icon.position = Vector2((tab_w - icon_h) * 0.5, 26)
		col.add_child(icon)
		_icon_nodes.append(icon)

		var lbl := Label.new()
		lbl.text = String(t.get("label", ""))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 30)
		lbl.position = Vector2(0, 26 + icon_h + 4)
		lbl.size = Vector2(tab_w, 40)
		col.add_child(lbl)
		_label_nodes.append(lbl)

		var hit := Button.new()
		hit.flat = true
		hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var idx := i
		hit.pressed.connect(func() -> void: _on_tab(idx))
		col.add_child(hit)

	_refresh()

func _on_tab(idx: int) -> void:
	_selected = idx
	_refresh()
	tab_selected.emit(String(_tabs[idx].get("id", "")))

func select(idx: int) -> void:
	_selected = idx
	_refresh()

func _refresh() -> void:
	for i in range(_label_nodes.size()):
		var on: bool = (i == _selected)
		_label_nodes[i].add_theme_color_override("font_color", INK if on else INK_DIM)
		_icon_nodes[i].modulate = Color.WHITE if on else Color(1, 1, 1, 0.72)
		_icon_nodes[i].scale = Vector2(1.12, 1.12) if on else Vector2.ONE
		# keep the enlarged icon centered
		var icon := _icon_nodes[i]
		var base := 78.0
		var grown: float = base * (icon.scale.x)
		icon.pivot_offset = icon.custom_minimum_size * 0.5
