extends Control
class_name StarPathNode
## One upgrade node in the Star Path constellation: a watercolor star with a
## state (locked / available / unlocked / maxed), an upgrade icon on top, and a
## gold selection ring when picked. Emits selected(id) when tapped.

signal selected(id: String)

const SP := "res://assets/sprites/ui/star_path/"

const STATE_TEX := {
	"locked": "node_md_locked.png",
	"available": "node_md_available.png",
	"unlocked": "node_md_unlocked.png",
	"maxed": "node_maxed.png",
}

var id := ""
var _state := "locked"
var _diameter := 132.0
var _base: TextureRect
var _icon: TextureRect
var _ring: TextureRect

func configure(p_id: String, icon_path: String, state: String, diameter := 132.0) -> void:
	id = p_id
	_state = state
	_diameter = diameter
	custom_minimum_size = Vector2(diameter, diameter)
	size = custom_minimum_size
	if _base:
		_apply(icon_path)

var _icon_path := ""

func _ready() -> void:
	size = Vector2(_diameter, _diameter)

	_ring = TextureRect.new()
	_ring.texture = load(SP + "ring_gold.png")
	_ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ring.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ring.custom_minimum_size = Vector2(_diameter * 1.34, _diameter * 1.34)
	_ring.size = _ring.custom_minimum_size
	_ring.position = -(_ring.size - size) * 0.5
	_ring.visible = false
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ring)

	_base = TextureRect.new()
	_base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_base.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_base)

	_icon = TextureRect.new()
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var s := _diameter * 0.5
	_icon.custom_minimum_size = Vector2(s, s)
	_icon.size = _icon.custom_minimum_size
	_icon.position = (size - _icon.size) * 0.5
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)

	var hit := Button.new()
	hit.flat = true
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(func() -> void: selected.emit(id))
	add_child(hit)

	_apply(_icon_path)

func _apply(icon_path: String) -> void:
	_icon_path = icon_path
	if not _base:
		return
	var key: String = _state if STATE_TEX.has(_state) else "available"
	_base.texture = load(SP + String(STATE_TEX[key]))
	if icon_path != "":
		_icon.texture = load(icon_path)
	# locked upgrades read as dimmed; the icon stays faint so the shape hints
	_icon.modulate = Color(1, 1, 1, 0.55) if _state == "locked" else Color.WHITE

func set_state(state: String) -> void:
	_state = state
	_apply(_icon_path)

func set_selected(on: bool) -> void:
	if _ring:
		_ring.visible = on
		if on:
			_ring.pivot_offset = _ring.size * 0.5
			var tw := create_tween().set_loops()
			tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(_ring, "scale", Vector2(1.08, 1.08), 0.8)
			tw.tween_property(_ring, "scale", Vector2.ONE, 0.8)
