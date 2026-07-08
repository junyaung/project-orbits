extends CanvasLayer
class_name GameplayHUD
## Screen-fixed HUD: stars (top-left), distance (top-center), pause (top-right),
## heat bar, overheat warning banner, tutorial hint, and the result card.
## Follows the bible: big readable numbers, corners for HUD, calm result card.

signal retry_pressed
signal pause_pressed
signal home_pressed

const INK := Color(0.30, 0.36, 0.46)
const HUD := "res://assets/sprites/ui/hud/"
const CORE := "res://assets/sprites/ui/core/"
const POPUP := "res://assets/sprites/ui/popup/"

var distance_label: Label
var star_label: Label
var heat_fill: ColorRect
var heat_bg: Control
var warning: Control
var warning_label: Label
var tutorial: Label
var result_panel: Control
var result_cat: TextureRect
var result_line: Label
var result_distance: Label
var result_sub: Label
var result_best: Panel
var indicator: Node2D
var _ind_dot: Polygon2D
var _ind_t := 0.0
var shield_hud: TextureRect
var shield_count_label: Label
var _reveal_group: Array[Control] = []
var _cat_bob: Tween
var _screen := Vector2(1080, 1920)
var _tut_shown := true

func _ready() -> void:
	layer = 10
	_screen = get_viewport().get_visible_rect().size
	_build()

func _ninepatch(path: String, l := 30, r := 30, t := 22, b := 22) -> NinePatchRect:
	var np := NinePatchRect.new()
	np.texture = load(path)
	np.patch_margin_left = l
	np.patch_margin_right = r
	np.patch_margin_top = t
	np.patch_margin_bottom = b
	np.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return np

func _capsule_style(tint := Color.WHITE, margin := 34) -> StyleBoxTexture:
	# 9-sliced blank watercolor capsule usable as a Button background (keeps the
	# Label). Tint distinguishes normal/hover/pressed without baked text.
	var sb := StyleBoxTexture.new()
	sb.texture = load(CORE + "chip_capsule.png")
	sb.set_texture_margin_all(margin)
	sb.modulate_color = tint
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	return sb

func _build() -> void:
	var W := _screen.x

	# --- distance (top center, big) ---
	# The hero number must win the eye first. It sits on a soft watercolor plaque
	# (matching the meta screens) so it reads clearly over any scrolling planet,
	# with a faint paper outline for extra separation.
	var dist_plaque := _ninepatch(CORE + "plaque_title_large.png", 90, 90, 40, 40)
	dist_plaque.size = Vector2(560, 150)
	dist_plaque.position = Vector2((W - 560) * 0.5, 66)
	add_child(dist_plaque)

	distance_label = Label.new()
	distance_label.text = "0m"
	distance_label.add_theme_font_size_override("font_size", 84)
	distance_label.add_theme_color_override("font_color", INK)
	distance_label.add_theme_color_override("font_outline_color", Color(0.99, 0.98, 0.94, 0.6))
	distance_label.add_theme_constant_override("outline_size", 6)
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	distance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	distance_label.position = Vector2((W - 560) * 0.5, 66)
	distance_label.size = Vector2(560, 150)
	add_child(distance_label)

	# --- star counter (top left) ---
	# Blank 9-sliced capsule (safe to stretch - no art baked into the middle,
	# unlike the old star_counter_chip.png, whose baked star sat partly in
	# the stretchable band and got visibly squished at this chip's size) +
	# a separate, aspect-preserved star icon + the count label on top.
	const STAR_CHIP_W := 176.0
	const STAR_CHIP_H := 84.0
	var star_chip := _ninepatch(CORE + "chip_capsule.png", 30, 30, 18, 18)
	star_chip.size = Vector2(STAR_CHIP_W, STAR_CHIP_H)
	star_chip.position = Vector2(40, 78)
	add_child(star_chip)

	var star_icon := TextureRect.new()
	star_icon.texture = load("res://assets/sprites/ui/currency/coin_star.png")
	star_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var star_icon_size := STAR_CHIP_H * 0.62
	star_icon.custom_minimum_size = Vector2(star_icon_size, star_icon_size)
	star_icon.size = star_icon.custom_minimum_size
	star_icon.position = Vector2(40 + (STAR_CHIP_H - star_icon_size) * 0.5, 78 + (STAR_CHIP_H - star_icon_size) * 0.5)
	add_child(star_icon)

	star_label = Label.new()
	star_label.text = "0"
	star_label.add_theme_font_size_override("font_size", 44)
	star_label.add_theme_color_override("font_color", INK)
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	star_label.position = Vector2(40 + star_icon_size, 78)
	star_label.size = Vector2(STAR_CHIP_W - star_icon_size - 20, STAR_CHIP_H)
	add_child(star_label)

	# --- pause button (top right) ---
	# The circle variant's cream/tan stitched border matches the rest of the
	# HUD (plaques, star chip); the square variant's blue-gray border stood
	# out and read as dirty/mismatched against everything else.
	var pause_btn := TextureButton.new()
	pause_btn.texture_normal = load(HUD + "btn_pause_circle.png")
	pause_btn.ignore_texture_size = true
	pause_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	pause_btn.custom_minimum_size = Vector2(96, 96)
	pause_btn.size = Vector2(96, 96)
	pause_btn.position = Vector2(W - 128, 72)
	pause_btn.pressed.connect(func(): pause_pressed.emit())
	add_child(pause_btn)

	# --- heat bar (under distance) ---
	# Watercolor pill frame with a rounded fill clipped inside; colour warms as
	# the planet overheats (calm gold -> coral -> warm red), never harsh.
	var HB_W := W - 340.0
	var heat_frame := _ninepatch("res://assets/sprites/ui/currency/progress_frame.png", 30, 30, 18, 18)
	heat_frame.size = Vector2(HB_W, 40)
	heat_bg = heat_frame
	heat_bg.position = Vector2(170, 236)
	add_child(heat_bg)

	heat_fill = ColorRect.new()
	heat_fill.color = Color(0.98, 0.82, 0.36)
	var clip := Control.new()
	clip.clip_contents = true
	clip.size = Vector2(HB_W - 16, 22)
	clip.position = Vector2(8, 9)
	heat_bg.add_child(clip)
	clip.add_child(heat_fill)
	heat_fill.size = Vector2(0, clip.size.y)
	heat_fill.position = Vector2.ZERO
	_heat_clip = clip

	# --- warning banner ---
	# Uses the red watercolor overheat ribbon from the HUD sheet, soft not harsh.
	warning = _ninepatch(HUD + "overheat_banner.png", 60, 60, 24, 24)
	warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warning.size = Vector2(560, 96)
	warning.position = Vector2((W - 560) * 0.5, 290)
	warning.visible = false
	add_child(warning)
	warning_label = Label.new()
	warning_label.text = "Planet overheating!"
	warning_label.add_theme_font_size_override("font_size", 38)
	warning_label.add_theme_color_override("font_color", Color(0.99, 0.96, 0.92))
	warning_label.add_theme_color_override("font_outline_color", Color(0.55, 0.2, 0.15, 0.7))
	warning_label.add_theme_constant_override("outline_size", 5)
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	warning_label.size = warning.size
	warning.add_child(warning_label)

	# --- tutorial hint (bottom) ---
	tutorial = Label.new()
	tutorial.text = "Hold to orbit   ·   Release to launch"
	tutorial.add_theme_font_size_override("font_size", 40)
	tutorial.add_theme_color_override("font_color", INK)
	tutorial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial.size = Vector2(W, 60)
	tutorial.position = Vector2(0, _screen.y - 220)
	tutorial.visible = false
	add_child(tutorial)

	# --- result card (hidden) ---
	_build_result_card()

	# Launch begins the run immediately - no in-scene Start overlay.
	tutorial.visible = true

	# --- off-screen next-planet indicator ---
	_build_indicator()

	# --- shield status (top-left, below the star count) ---
	_build_shield_hud()

var _heat_clip: Control

func _build_result_card() -> void:
	# Eye-order by design: the sleeping cat (safe, an emotional anchor) reads
	# first, then the hero distance, then the small stats, then the one clear
	# action. The card should leave the player feeling "lonely-but-safe, gentle"
	# rather than punished - a quiet pause, not a game-over slam.
	var W := _screen.x
	var CW := 760.0
	var CH := 1058.0
	result_panel = _ninepatch(CORE + "panel_large.png", 60, 60, 60, 60)
	result_panel.size = Vector2(CW, CH)
	result_panel.position = Vector2((W - CW) * 0.5, (_screen.y - CH) * 0.5)
	result_panel.visible = false
	result_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(result_panel)

	# resting cat (memory hook + reassurance)
	result_cat = TextureRect.new()
	result_cat.texture = load("res://assets/sprites/cat/cat_sleepy.png")
	result_cat.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_cat.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result_cat.size = Vector2(300, 220)
	result_cat.position = Vector2((CW - 300) * 0.5, 40)
	result_panel.add_child(result_cat)

	var title := Label.new()
	title.text = "Splashdown"
	title.add_theme_font_size_override("font_size", 66)
	title.add_theme_color_override("font_color", INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(CW, 84)
	title.position = Vector2(0, 268)
	result_panel.add_child(title)

	# gentle poetic line - conveys the cause AND the walk-away emotion (2 lines)
	result_line = Label.new()
	result_line.add_theme_font_size_override("font_size", 34)
	result_line.add_theme_color_override("font_color", Color(0.42, 0.48, 0.58))
	result_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_line.size = Vector2(CW - 120, 96)
	result_line.position = Vector2(60, 356)
	result_panel.add_child(result_line)

	# NEW BEST - a thin gold pill badge, only when earned, sat just above the
	# hero distance. Small warm reward beat; ~28% the size of the distance number.
	var BADGE_W := 280.0
	var BADGE_H := 56.0
	result_best = Panel.new()
	var badge_sb := StyleBoxFlat.new()
	badge_sb.bg_color = Color(0.99, 0.95, 0.82, 0.9)          # very light cream-gold
	badge_sb.set_corner_radius_all(int(BADGE_H * 0.5))          # full pill
	badge_sb.border_color = Color(0.86, 0.72, 0.42, 0.55)       # faint gold
	badge_sb.set_border_width_all(1)
	result_best.add_theme_stylebox_override("panel", badge_sb)
	result_best.size = Vector2(BADGE_W, BADGE_H)
	result_best.position = Vector2((CW - BADGE_W) * 0.5, 468)
	result_best.visible = false
	result_panel.add_child(result_best)

	var badge_label := Label.new()
	badge_label.text = "✦  NEW BEST  ✦"
	badge_label.add_theme_font_size_override("font_size", 24)   # ~28% of the 84px distance
	badge_label.add_theme_color_override("font_color", Color(0.72, 0.54, 0.24))  # muted amber
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.size = Vector2(BADGE_W, BADGE_H)
	result_best.add_child(badge_label)

	# hero distance
	result_distance = Label.new()
	result_distance.add_theme_font_size_override("font_size", 84)
	result_distance.add_theme_color_override("font_color", INK)
	result_distance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_distance.size = Vector2(CW, 100)
	result_distance.position = Vector2(0, 540)
	result_panel.add_child(result_distance)

	# small muted stats row
	result_sub = Label.new()
	result_sub.add_theme_font_size_override("font_size", 36)
	result_sub.add_theme_color_override("font_color", Color(0.5, 0.56, 0.64))
	result_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_sub.size = Vector2(CW, 50)
	result_sub.position = Vector2(0, 654)
	result_panel.add_child(result_sub)

	# the one clear, inviting action (bible: retry is biggest & easiest)
	var retry := Button.new()
	retry.text = "Drift Again"
	retry.add_theme_font_size_override("font_size", 54)
	retry.add_theme_color_override("font_color", Color(0.4, 0.28, 0.2))
	retry.size = Vector2(480, 132)
	retry.position = Vector2((CW - 480) * 0.5, 750)
	retry.add_theme_stylebox_override("normal", _capsule_style(Color(1, 1, 1)))
	retry.add_theme_stylebox_override("hover", _capsule_style(Color(1, 0.99, 0.94)))
	retry.add_theme_stylebox_override("pressed", _capsule_style(Color(0.88, 0.84, 0.76)))
	retry.pressed.connect(func(): retry_pressed.emit())
	result_panel.add_child(retry)

	# secondary: back to the Home hub
	var home := Button.new()
	home.text = "Home"
	home.add_theme_font_size_override("font_size", 40)
	home.add_theme_color_override("font_color", Color(0.42, 0.48, 0.58))
	home.size = Vector2(300, 84)
	home.position = Vector2((CW - 300) * 0.5, 928)
	home.add_theme_stylebox_override("normal", _capsule_style(Color(0.86, 0.90, 0.96)))
	home.add_theme_stylebox_override("hover", _capsule_style(Color(0.92, 0.95, 0.99)))
	home.add_theme_stylebox_override("pressed", _capsule_style(Color(0.76, 0.82, 0.90)))
	home.pressed.connect(func(): home_pressed.emit())
	result_panel.add_child(home)

	_reveal_group = [result_cat, title, result_line, result_distance, result_sub, retry, home]

func _poly_circle(r: float, seg: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg:
		var a := TAU * float(i) / float(seg)
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	return pts

func _build_indicator() -> void:
	# A soft cream "look here" chip: a planet-colored dot inside a paper disc,
	# with a chevron pointing toward the off-screen planet. Calm, not alarming -
	# it only answers "which way do I sling?"
	indicator = Node2D.new()
	indicator.z_index = 6
	indicator.visible = false
	add_child(indicator)

	var chevron := Polygon2D.new()   # drawn first so the disc sits over its base
	chevron.polygon = PackedVector2Array([Vector2(54, 0), Vector2(34, -16), Vector2(34, 16)])
	chevron.color = Color(0.40, 0.50, 0.63, 0.95)
	indicator.add_child(chevron)

	var ring := Polygon2D.new()
	ring.polygon = _poly_circle(35.0, 28)
	ring.color = Color(0.42, 0.52, 0.64, 0.5)
	indicator.add_child(ring)

	var disc := Polygon2D.new()
	disc.polygon = _poly_circle(30.0, 28)
	disc.color = Color(0.98, 0.97, 0.92, 0.97)
	indicator.add_child(disc)

	_ind_dot = Polygon2D.new()
	_ind_dot.polygon = _poly_circle(14.0, 22)
	_ind_dot.color = Color(0.6, 0.72, 0.5)
	indicator.add_child(_ind_dot)

func set_planet_indicator(show_it: bool, pos := Vector2.ZERO, angle := 0.0, col := Color.WHITE) -> void:
	if not indicator:
		return
	indicator.visible = show_it
	if show_it:
		indicator.position = pos
		indicator.rotation = angle
		_ind_dot.color = col

func _process(delta: float) -> void:
	# gentle breathing so the indicator reads as "look here" without shouting
	if indicator and indicator.visible:
		_ind_t += delta
		indicator.scale = Vector2.ONE * (1.0 + sin(_ind_t * 3.2) * 0.07)

## Shield HUD icon: sits in the left status column under the star count, using
## the same sprite as the pickup so the player links "I grabbed that bubble" to
## "I'm protected." Only visible while at least one shield is held (no clutter
## otherwise). A small count badge shows how many hits are still banked, so a
## stacked pickup reads as "I can take 2 more hits", not just "I'm protected".
func _build_shield_hud() -> void:
	shield_hud = TextureRect.new()
	shield_hud.texture = load("res://assets/sprites/collectibles/shield.png")
	shield_hud.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shield_hud.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shield_hud.size = Vector2(70, 70)
	shield_hud.position = Vector2(48, 184)
	shield_hud.visible = false
	add_child(shield_hud)

	shield_count_label = Label.new()
	shield_count_label.add_theme_font_size_override("font_size", 32)
	shield_count_label.add_theme_color_override("font_color", INK)
	shield_count_label.add_theme_color_override("font_outline_color", Color(0.99, 0.98, 0.94, 0.9))
	shield_count_label.add_theme_constant_override("outline_size", 6)
	shield_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shield_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shield_count_label.position = shield_hud.position + Vector2(38, 40)
	shield_count_label.size = Vector2(40, 40)
	shield_count_label.visible = false
	add_child(shield_count_label)

## Reflect the current shield charge count in the HUD. 0 hides the icon
## (with a pop + fade so "shield broke" reads clearly); any positive count
## shows the icon with that number of remaining hits, bump-pulsing on change.
func set_shield_count(n: int) -> void:
	if not shield_hud:
		return
	shield_hud.pivot_offset = shield_hud.size * 0.5
	if n <= 0:
		shield_count_label.visible = false
		if shield_hud.visible:
			# pop + fade out so "shield broke" reads, then reset for next time
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(shield_hud, "scale", Vector2(1.4, 1.4), 0.16)
			tw.tween_property(shield_hud, "modulate:a", 0.0, 0.16)
			tw.chain().tween_callback(func():
				shield_hud.visible = false
				shield_hud.scale = Vector2.ONE
				shield_hud.modulate.a = 1.0)
		return

	shield_count_label.text = str(n)
	shield_count_label.visible = true

	if not shield_hud.visible:
		shield_hud.visible = true
		shield_hud.modulate.a = 1.0
		shield_hud.scale = Vector2(0.5, 0.5)
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(shield_hud, "scale", Vector2.ONE, 0.25)
	else:
		# already visible: a quick bump-pulse acknowledges the count changing
		# (gained another charge, or spent one absorbing a hit)
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(shield_hud, "scale", Vector2(1.15, 1.15), 0.10)
		tw.tween_property(shield_hud, "scale", Vector2.ONE, 0.14)

func set_distance(v: float) -> void:
	distance_label.text = str(int(v)) + "m"

func set_stars(n: int) -> void:
	star_label.text = str(n)

func set_heat(v: float) -> void:
	v = clamp(v, 0.0, 1.0)
	if _heat_clip:
		heat_fill.size = Vector2(_heat_clip.size.x * v, _heat_clip.size.y)
	if v < 0.45:
		heat_fill.color = Color(0.98, 0.82, 0.36)      # calm yellow
	elif v < 0.78:
		heat_fill.color = Color(0.97, 0.62, 0.42)      # peach / coral
	else:
		heat_fill.color = Color(0.93, 0.38, 0.32)      # warm red
	if v > 0.78:
		show_warning("Planet overheating!")
	else:
		warning.visible = false

func show_warning(text: String) -> void:
	if warning.visible and warning_label.text == text:
		return
	warning_label.text = text
	warning.visible = true
	warning.scale = Vector2(0.94, 0.94)
	warning.pivot_offset = warning.size * 0.5
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(warning, "scale", Vector2.ONE, 0.18)

func hide_tutorial() -> void:
	if not _tut_shown:
		return
	_tut_shown = false
	var tw := create_tween()
	tw.tween_property(tutorial, "modulate:a", 0.0, 0.5)

## Map the blunt failure cause to a gentle line that still tells the player
## what happened, but lands the game's "lonely-but-safe, poetic" feeling and
## leaves a small story to resolve (memory encoding).
func _poetic_line(reason: String) -> String:
	var r := reason.to_lower()
	if "overheat" in r:
		return "The little planet needed to cool down.\nRest here a while."
	elif "planet" in r or "tumble" in r or "crash" in r:
		return "Straight through the middle!\nPlanets are for orbiting, little one."
	elif "meteor" in r or "rock" in r or "bump" in r:
		return "Space is big and bumpy.\nThe cat is only a little surprised."
	elif "space" in r or "drift" in r:
		return "Off into the quiet blue —\na new planet waits."
	elif "earth" in r or "fell" in r or "fall" in r:
		return "Back to the ground, for now.\nThe sky will still be there tomorrow."
	return "The cat drifts on,\ndreaming of the next planet."

func show_result(distance: int, stars: int, perfects: int, best: int, reason: String) -> void:
	warning.visible = false
	var is_best := distance >= best and distance > 0

	result_line.text = _poetic_line(reason)
	result_distance.text = "%d m" % distance
	result_sub.text = "★ %d      ✧ %d perfect" % [stars, perfects]
	result_best.visible = is_best

	result_panel.visible = true
	result_panel.scale = Vector2(0.88, 0.88)
	result_panel.pivot_offset = result_panel.size * 0.5
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(result_panel, "scale", Vector2.ONE, 0.30)

	# staggered reveal - the whole thing feels composed, not dumped on screen
	for i in _reveal_group.size():
		var node := _reveal_group[i]
		var base_y := node.position.y
		node.modulate.a = 0.0
		node.position.y = base_y + 14.0
		var t := create_tween()
		t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_interval(0.12 + i * 0.07)
		t.set_parallel(true)
		t.tween_property(node, "modulate:a", 1.0, 0.28)
		t.tween_property(node, "position:y", base_y, 0.28)

	# the resting cat breathes - a small sign of life = reassurance.
	# Uses the known card-relative base Y (40) so it doesn't fight the reveal.
	if _cat_bob:
		_cat_bob.kill()
	var cat_base := 40.0
	_cat_bob = create_tween().set_loops()
	_cat_bob.tween_interval(0.7)
	_cat_bob.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cat_bob.tween_property(result_cat, "position:y", cat_base + 8.0, 1.4)
	_cat_bob.tween_property(result_cat, "position:y", cat_base, 1.4)

	if is_best:
		result_best.pivot_offset = result_best.size * 0.5
		var bt := create_tween()
		bt.tween_interval(0.55)
		bt.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		bt.tween_property(result_best, "scale", Vector2(1.12, 1.12), 0.18)
		bt.tween_property(result_best, "scale", Vector2.ONE, 0.16)
