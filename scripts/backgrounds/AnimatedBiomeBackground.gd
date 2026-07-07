extends CanvasLayer
class_name AnimatedBiomeBackground
## A reusable "living painting" background for a 2D vertical mobile game.
##
## Makes a static watercolor background feel alive, entirely inside Godot, so it
## loops INFINITELY and SEAMLESSLY (no video, no visible loop seam):
##   1. a static base PNG fitted to the viewport
##   2. two optional overlay sprites that breathe / rotate / drift
##   3. three GPUParticles2D systems (dust / streaks / glow)
##   4. looping ping-pong Tweens for breathing, rotation, alpha pulse, drift
##   5. a soft full-screen tint wash per biome
##
## Ping-pong Tweens (A -> B -> A, sine ease) are seamless by construction, and
## GPUParticles2D are continuous, so the whole thing runs forever with no seam.
##
## Art direction: soft pastel watercolor storybook. Motion stays gentle - never
## aggressive, neon, cyberpunk, or chaotic - and never fights gameplay readability.
##
## Usage:
##   - Drop this scene behind your gameplay (it is a CanvasLayer at layer -10).
##   - Assign base_texture (+ optional overlays + particle textures) in the
##     Inspector, pick a biome_type, done.
##   - Switch biome live with set_biome(BiomeType.WORMHOLE_GARDEN).

enum BiomeType {
	DREAM_SKY,
	WORMHOLE_GARDEN,
	TACHYON_DRIFT,
	DARK_MATTER_REEF,
	ENTROPY_FIELD,
}

# ------------------------------------------------------------------ exports --
@export var biome_type: BiomeType = BiomeType.TACHYON_DRIFT
@export var base_texture: Texture2D
@export var overlay_texture_a: Texture2D
@export var overlay_texture_b: Texture2D
@export var particle_texture_dot: Texture2D
@export var particle_texture_streak: Texture2D
## Global multiplier on ALL motion (tween amplitudes + particle speed).
## 0.0 = completely still, 1.0 = tuned default, >1 = livelier.
@export var motion_intensity: float = 1.0
## Gentle vertical drift of the whole background, in pixels of peak travel.
## 0 = perfectly fixed to the screen. It ping-pongs, so it stays seamless;
## the base is fitted with a little overscan so edges never show.
@export var background_scroll_speed: float = 0.0
## CanvasLayer draw order. Keep negative so it renders behind gameplay + UI.
@export var background_layer: int = -10

# -------------------------------------------------------------- node handles --
@onready var background_root: Node2D = $BackgroundRoot
@onready var base_background: Sprite2D = $BackgroundRoot/BaseBackground
@onready var overlay_a: Sprite2D = $BackgroundRoot/OverlayLayerA
@onready var overlay_b: Sprite2D = $BackgroundRoot/OverlayLayerB
@onready var accent_container: Node2D = $BackgroundRoot/AccentContainer
@onready var slow_dust: GPUParticles2D = $BackgroundRoot/SlowDustParticles
@onready var fast_streak: GPUParticles2D = $BackgroundRoot/FastStreakParticles
@onready var glow: GPUParticles2D = $BackgroundRoot/GlowParticles
@onready var soft_tint: ColorRect = $BackgroundRoot/SoftTint
@onready var anim_player: AnimationPlayer = $BackgroundRoot/AnimationPlayer

# --------------------------------------------------------------- internal ---
var _viewport_size := Vector2(1080, 1920)
var _tweens: Array[Tween] = []
var _overlay_a_base_scale := Vector2.ONE
var _overlay_b_base_scale := Vector2.ONE
var _overlay_a_base_pos := Vector2.ZERO
var _overlay_b_base_pos := Vector2.ZERO
var _dot_tex: Texture2D
var _streak_tex: Texture2D

func _ready() -> void:
	layer = background_layer
	_viewport_size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(_on_viewport_resized)
	setup_background()
	setup_particles()
	apply_biome_preset()

# ============================================================================
# 1. BACKGROUND + FIT
# ============================================================================
func setup_background() -> void:
	_viewport_size = get_viewport().get_visible_rect().size

	# Base always shows (a little overscan leaves room for the optional drift).
	if base_texture:
		base_background.texture = base_texture
		base_background.visible = true
		fit_sprite_to_viewport(base_background, 1.05)
	else:
		base_background.visible = false
		push_warning("AnimatedBiomeBackground: base_texture is null - assign a PNG.")

	# Overlays are OPTIONAL. If a texture is missing, hide that node and move on.
	_setup_overlay(overlay_a, overlay_texture_a)
	_setup_overlay(overlay_b, overlay_texture_b)
	_overlay_a_base_scale = overlay_a.scale
	_overlay_b_base_scale = overlay_b.scale
	_overlay_a_base_pos = overlay_a.position
	_overlay_b_base_pos = overlay_b.position

	# Full-screen soft wash (slightly oversized so tiny drift never reveals a gap).
	soft_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	soft_tint.size = _viewport_size * 1.06
	soft_tint.position = -_viewport_size * 0.03
	soft_tint.color = Color(0, 0, 0, 0)   # set per biome in configure_*()

func _setup_overlay(ov: Sprite2D, tex: Texture2D) -> void:
	if tex:
		ov.texture = tex
		ov.visible = true
		# Extra overscan so a small rotation / scale / drift never shows the edge.
		fit_sprite_to_viewport(ov, 1.12)
	else:
		ov.visible = false

## Fit a sprite to COVER the viewport (fill it, preserving aspect ratio, cropping
## the overflow). `overscan` scales it a touch larger to hide edges during motion.
## This is the 9:16 mobile fit: it works for any texture size / aspect.
func fit_sprite_to_viewport(sprite: Sprite2D, overscan := 1.0) -> void:
	if sprite.texture == null:
		return
	var ts := sprite.texture.get_size()
	if ts.x <= 0.0 or ts.y <= 0.0:
		return
	var cover := maxf(_viewport_size.x / ts.x, _viewport_size.y / ts.y)
	sprite.centered = true
	sprite.scale = Vector2.ONE * cover * overscan
	sprite.position = _viewport_size * 0.5

func _on_viewport_resized() -> void:
	_viewport_size = get_viewport().get_visible_rect().size
	setup_background()
	setup_particles()
	set_biome(biome_type)   # rebuild motion for the new size

# ============================================================================
# 2. BIOME SELECTION
# ============================================================================
## Switch biome at runtime. Kills the old motion, reconfigures particles + tint,
## then rebuilds the seamless looping animation for the new biome.
func set_biome(new_biome: BiomeType) -> void:
	biome_type = new_biome
	_reset_motion()
	apply_biome_preset()

func apply_biome_preset() -> void:
	match biome_type:
		BiomeType.DREAM_SKY:        configure_dream_sky()
		BiomeType.WORMHOLE_GARDEN:  configure_wormhole_garden()
		BiomeType.TACHYON_DRIFT:    configure_tachyon_drift()
		BiomeType.DARK_MATTER_REEF: configure_dark_matter_reef()
		BiomeType.ENTROPY_FIELD:    configure_entropy_field()
	create_looping_animation()
	_start_scroll()

func _reset_motion() -> void:
	for t in _tweens:
		if t and t.is_valid():
			t.kill()
	_tweens.clear()
	background_root.position = Vector2.ZERO
	if overlay_a:
		overlay_a.rotation = 0.0
		overlay_a.scale = _overlay_a_base_scale
		overlay_a.position = _overlay_a_base_pos
		overlay_a.modulate.a = 1.0
	if overlay_b:
		overlay_b.rotation = 0.0
		overlay_b.scale = _overlay_b_base_scale
		overlay_b.position = _overlay_b_base_pos
		overlay_b.modulate.a = 1.0
	if soft_tint:
		soft_tint.modulate.a = 1.0

# ============================================================================
# 3. PARTICLES (shared setup + per-biome tuning)
# ============================================================================
func setup_particles() -> void:
	# Fall back to soft generated textures so it never looks like hard squares,
	# even before you assign your own watercolor particle art.
	_dot_tex = particle_texture_dot if particle_texture_dot else _make_soft_dot(64)
	_streak_tex = particle_texture_streak if particle_texture_streak else _make_soft_streak(120, 18)
	for p in [slow_dust, fast_streak, glow]:
		p.position = _viewport_size * 0.5
		p.one_shot = false
		p.explosiveness = 0.0
		p.randomness = 0.6
		# generous rect so streaks/dust are never culled at the edges
		p.visibility_rect = Rect2(-_viewport_size, _viewport_size * 3.0)

## Configure one particle system. `amount <= 0` disables that system entirely.
## Velocity is scaled by motion_intensity. Emission is a box covering the screen,
## so particles fill the whole background rather than spraying from one point.
func _config_particles(p: GPUParticles2D, amount: int, lifetime: float, dir: Vector3,
		spread: float, vmin: float, vmax: float, scale_min: float, scale_max: float,
		color: Color, tex: Texture2D, grav := Vector3.ZERO) -> void:
	if amount <= 0:
		p.emitting = false
		p.visible = false
		return
	p.visible = true
	p.amount = amount
	p.lifetime = lifetime
	p.preprocess = lifetime          # pre-warm: screen is already full at frame 0 (seamless)
	p.texture = tex
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(_viewport_size.x * 0.65, _viewport_size.y * 0.65, 1.0)
	m.direction = dir
	m.spread = spread
	m.gravity = grav
	m.initial_velocity_min = vmin * motion_intensity
	m.initial_velocity_max = vmax * motion_intensity
	m.scale_min = scale_min
	m.scale_max = scale_max
	m.color = color
	p.process_material = m
	p.emitting = true

# ---- per-biome particle + tint presets ------------------------------------
# All colors are soft and low-alpha to stay watercolor-friendly. Tweak freely.

func configure_dream_sky() -> void:
	soft_tint.color = Color(0.80, 0.85, 0.95, 0.05)                      # airy blue wash
	_config_particles(slow_dust, 30, 10.0, Vector3(0, -1, 0), 50.0, 3.0, 9.0, 0.12, 0.30, Color(1.0, 0.98, 0.95, 0.30), _dot_tex)
	_config_particles(glow, 20, 8.0, Vector3(0, -1, 0), 180.0, 2.0, 8.0, 0.14, 0.34, Color(1.0, 0.95, 0.85, 0.35), _dot_tex)
	_config_particles(fast_streak, 0, 1.0, Vector3.UP, 0, 0, 0, 0, 0, Color.WHITE, _dot_tex)

func configure_wormhole_garden() -> void:
	soft_tint.color = Color(0.62, 0.55, 0.75, 0.06)                      # faint lavender
	# small glowing dust floating gently upward
	_config_particles(slow_dust, 40, 9.0, Vector3(0, -1, 0), 40.0, 4.0, 12.0, 0.12, 0.30, Color(0.85, 0.80, 0.95, 0.35), _dot_tex, Vector3(0, -2, 0))
	# tiny soft glow dots, slow random drift (wide spread = drifts every direction)
	_config_particles(glow, 24, 7.0, Vector3(0, -1, 0), 180.0, 3.0, 10.0, 0.15, 0.35, Color(0.98, 0.88, 0.72, 0.40), _dot_tex)
	_config_particles(fast_streak, 0, 1.0, Vector3.UP, 0, 0, 0, 0, 0, Color.WHITE, _dot_tex)

func configure_tachyon_drift() -> void:
	soft_tint.color = Color(0.35, 0.65, 0.75, 0.05)                      # cool cyan shimmer base
	# subtle background dust drifting the same way as the streaks
	_config_particles(slow_dust, 30, 6.0, Vector3(0.6, -0.8, 0), 25.0, 10.0, 25.0, 0.10, 0.25, Color(0.70, 0.90, 0.95, 0.25), _dot_tex)
	# fast cyan streaks moving diagonally up-right: "space rushing past" (camera stays put)
	_config_particles(fast_streak, 60, 1.6, Vector3(0.55, -0.83, 0), 12.0, 480.0, 820.0, 0.22, 0.55, Color(0.60, 0.95, 0.98, 0.50), _streak_tex)
	# quick small glints riding along with them
	_config_particles(glow, 40, 2.2, Vector3(0.55, -0.83, 0), 18.0, 240.0, 440.0, 0.12, 0.30, Color(0.80, 0.98, 1.0, 0.45), _dot_tex)

func configure_dark_matter_reef() -> void:
	soft_tint.color = Color(0.10, 0.25, 0.28, 0.10)                      # deep teal gloom
	# tiny teal motes floating like an alien ecosystem
	_config_particles(slow_dust, 26, 10.0, Vector3(0, -1, 0), 60.0, 2.0, 8.0, 0.12, 0.28, Color(0.40, 0.75, 0.72, 0.30), _dot_tex)
	_config_particles(glow, 30, 8.0, Vector3(0, -1, 0), 180.0, 2.0, 7.0, 0.14, 0.34, Color(0.35, 0.85, 0.80, 0.40), _dot_tex)
	_config_particles(fast_streak, 0, 1.0, Vector3.UP, 0, 0, 0, 0, 0, Color.WHITE, _dot_tex)

func configure_entropy_field() -> void:
	soft_tint.color = Color(0.30, 0.28, 0.35, 0.08)                      # muted, melancholic
	# sparse, very slow fading dust
	_config_particles(slow_dust, 18, 12.0, Vector3(0, -1, 0), 50.0, 1.0, 5.0, 0.10, 0.24, Color(0.80, 0.78, 0.82, 0.18), _dot_tex)
	# faint, few flickering glints
	_config_particles(glow, 12, 9.0, Vector3(0, -1, 0), 180.0, 1.0, 4.0, 0.12, 0.28, Color(0.85, 0.80, 0.70, 0.22), _dot_tex)
	_config_particles(fast_streak, 0, 1.0, Vector3.UP, 0, 0, 0, 0, 0, Color.WHITE, _dot_tex)

# ============================================================================
# 4. LOOPING MOTION (seamless ping-pong Tweens)
# ============================================================================
## Builds the breathing / rotation / alpha-pulse / drift for the current biome.
## Every tween is a sine-eased ping-pong (A -> B -> A) on .set_loops(), so it is
## perfectly seamless and runs forever. Amplitudes scale with motion_intensity.
func create_looping_animation() -> void:
	match biome_type:
		BiomeType.DREAM_SKY:
			if overlay_a.visible: _pulse_scalar(overlay_a, "rotation", deg_to_rad(-1.0), deg_to_rad(1.0), 12.0)
			if overlay_b.visible: _pulse_scale(overlay_b, _overlay_b_base_scale, 0.99, 1.01, 8.0)

		BiomeType.WORMHOLE_GARDEN:
			# OverlayA rotates -1.5deg..+1.5deg over 8s; OverlayB breathes 0.985..1.015 over 6s
			if overlay_a.visible: _pulse_scalar(overlay_a, "rotation", deg_to_rad(-1.5), deg_to_rad(1.5), 8.0)
			if overlay_b.visible: _pulse_scale(overlay_b, _overlay_b_base_scale, 0.985, 1.015, 6.0)
			# a slow lateral mist drift
			if overlay_a.visible: _pulse_scalar(overlay_a, "position:x", _overlay_a_base_pos.x - 6.0, _overlay_a_base_pos.x + 6.0, 10.0)

		BiomeType.TACHYON_DRIFT:
			# overlay alpha pulse 0.75..0.95 over 3s + a whole-screen shimmer
			if overlay_a.visible: _pulse_scalar(overlay_a, "modulate:a", 0.75, 0.95, 3.0)
			_pulse_scalar(soft_tint, "modulate:a", 0.70, 1.00, 4.0)

		BiomeType.DARK_MATTER_REEF:
			# OverlayA sways x -8px..+8px over 7s; OverlayB alpha 0.6..0.85 over 5s
			if overlay_a.visible: _pulse_scalar(overlay_a, "position:x", _overlay_a_base_pos.x - 8.0, _overlay_a_base_pos.x + 8.0, 7.0)
			if overlay_b.visible: _pulse_scalar(overlay_b, "modulate:a", 0.60, 0.85, 5.0)

		BiomeType.ENTROPY_FIELD:
			# extremely subtle alpha breathing
			if overlay_a.visible: _pulse_scalar(overlay_a, "modulate:a", 0.90, 1.00, 6.0)
			if overlay_b.visible: _pulse_scalar(overlay_b, "modulate:a", 0.85, 0.97, 7.0)

## Ping-pong a scalar/indexed property (rotation, "modulate:a", "position:x", ...)
## between lo and hi over `cycle` seconds (full there-and-back), scaled by intensity.
func _pulse_scalar(obj: Object, prop: String, lo: float, hi: float, cycle: float) -> void:
	var mid := (lo + hi) * 0.5
	var half := (hi - lo) * 0.5 * motion_intensity
	var a := mid - half
	var b := mid + half
	obj.set_indexed(prop, a)
	var tw := create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(obj, prop, b, cycle * 0.5)
	tw.tween_property(obj, prop, a, cycle * 0.5)
	_tweens.append(tw)

## Ping-pong a sprite's scale between base*lo_factor and base*hi_factor (the
## "breathing" pulse), intensity applied to the deviation from 1.0.
func _pulse_scale(sprite: Sprite2D, base_scale: Vector2, lo_factor: float, hi_factor: float, cycle: float) -> void:
	var lo := 1.0 - (1.0 - lo_factor) * motion_intensity
	var hi := 1.0 + (hi_factor - 1.0) * motion_intensity
	sprite.scale = base_scale * lo
	var tw := create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(sprite, "scale", base_scale * hi, cycle * 0.5)
	tw.tween_property(sprite, "scale", base_scale * lo, cycle * 0.5)
	_tweens.append(tw)

## Optional gentle vertical drift of the whole background (seamless ping-pong).
## For LITERAL infinite scrolling you need a vertically-tiling texture; then move
## background_root.position.y by speed*delta in _process and wrap by texture height.
func _start_scroll() -> void:
	if background_scroll_speed <= 0.0:
		return
	var amp := background_scroll_speed
	background_root.position.y = -amp
	var tw := create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(background_root, "position:y", amp, 12.0)
	tw.tween_property(background_root, "position:y", -amp, 12.0)
	_tweens.append(tw)

# ============================================================================
# 5. FALLBACK SOFT TEXTURES (used only if you don't assign particle textures)
# ============================================================================
func _make_soft_dot(size: int) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - c, y + 0.5 - c).length() / (size * 0.5)
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, pow(a, 1.6)))
	return ImageTexture.create_from_image(img)

func _make_soft_streak(w: int, h: int) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var cx := w * 0.5
	var cy := h * 0.5
	for y in h:
		for x in w:
			var dx := absf(x + 0.5 - cx) / (w * 0.5)
			var dy := absf(y + 0.5 - cy) / (h * 0.5)
			var a := clampf(1.0 - dx, 0.0, 1.0) * clampf(1.0 - dy, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, pow(a, 1.3)))
	return ImageTexture.create_from_image(img)
