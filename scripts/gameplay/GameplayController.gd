extends Node2D
## ORBITS — playable prototype controller.
## Cat rides a manhole cover, holds to orbit a planet, releases along the
## tangent to sling toward the next. Heat rises while orbiting; procedural
## planets scroll endlessly; stars score, hazards end the run.

const SCREEN := Vector2(1080, 1920)
const LAUNCH_SPEED := 620.0
const ORBIT_ANG_SPEED := 2.3
const HEAT_GAIN := 0.34
const HEAT_COOL := 0.14
const CAT_START := Vector2(540, 2050)
const CAM_LEAD := 400.0   # how far ahead (up) the camera sits; keeps the cat low so you see what's coming
const FIRST_PLANET_Y := 1250.0
# Planet-to-planet vertical spacing (center to center). A planet is ~216 wide,
# so the minimum leaves room for ~2 planets between them; the maximum is a full
# screen height, so the next planet is at most one screen away.
const MIN_PLANET_GAP := 640.0
const MAX_PLANET_GAP := 1920.0
## Learning phase: for the first TUTORIAL_DIST meters difficulty ramps up from
## easy (close planets, no hazards, gentle heat) to full. Gives new players room
## to learn hold/orbit/release before the game gets demanding.
const TUTORIAL_DIST := 1000.0

const CAT_SCENE := preload("res://scenes/actors/CatVehicle.tscn")
const PLANET_SCENES := {
	"meadow":   preload("res://scenes/gameplay/planets/Planet_Meadow.tscn"),
	"cloud":    preload("res://scenes/gameplay/planets/Planet_Cloud.tscn"),
	"ruin":     preload("res://scenes/gameplay/planets/Planet_Ruin.tscn"),
	"dune":     preload("res://scenes/gameplay/planets/Planet_Dune.tscn"),
	"overheat": preload("res://scenes/gameplay/planets/Planet_Overheat.tscn"),
}
const HAZARD_SCENES := {
	"rock":   preload("res://scenes/gameplay/hazards/Hazard_Rock.tscn"),
	"meteor": preload("res://scenes/gameplay/hazards/Hazard_Meteor.tscn"),
	"jelly":  preload("res://scenes/gameplay/hazards/Hazard_Jelly.tscn"),
}
const PICKUP_SCENES := {
	"star":   preload("res://scenes/gameplay/pickups/Pickup_Star.tscn"),
	"shield": preload("res://scenes/gameplay/pickups/Pickup_Shield.tscn"),
}
const PLANET_COLORS := {
	"meadow":   Color(0.56, 0.72, 0.45),
	"cloud":    Color(0.72, 0.83, 0.93),
	"ruin":     Color(0.72, 0.68, 0.82),
	"dune":     Color(0.86, 0.76, 0.56),
	"overheat": Color(0.95, 0.60, 0.50),
}

const UpperSkyBiomeScript := preload("res://scripts/gameplay/UpperSkyBiome.gd")

## Test toggle: use the looping Tachyon Drift video as the backdrop instead of
## the painted gradient sky. The video is verified working; back on the painted
## sky for now. Flip to true to use the Tachyon Drift video again.
@export var use_video_background := false
const VIDEO_BG := preload("res://scenes/backgrounds/VideoBiomeBackground.tscn")

## Upper Sky biome visual system (layered background, overlay, decor, particles,
## gimmick cues). Replaces the single stitched-sky sprite with a full layered
## system per the biome brief. Set false to fall back to the plain gradient.
@export var use_upper_sky_biome := true

var cat: CatVehicle
var camera: Camera2D
var hud: GameplayHUD
var world: Node2D
var clouds: Node2D
var traj: Line2D
var traj_arrow: Polygon2D
var upper_sky: Node2D

var planets: Array[Planet] = []
var pickups: Array[Pickup] = []
var hazards: Array[Hazard] = []

var is_orbiting := false
var current_planet: Planet = null
var orbit_angle := 0.0
var orbit_dir := 1.0
var cur_radius := 0.0
var velocity := Vector2(0, -300)

var heat := 0.0
var distance := 0.0
var stars := 0
var perfects := 0
var shield_count := 0   # stacks: each hazard hit consumes one charge
var best := 0

var started := false
var game_over := false
var paused := false

var start_y := CAT_START.y
var top_spawn_y := 0.0
var last_planet_x := 540.0

# ---------------------------------------------------------------- setup ----
var autoplay := false

func _ready() -> void:
	randomize()
	autoplay = "--autoplay" in OS.get_cmdline_user_args()
	_load_best()
	if use_video_background:
		add_child(VIDEO_BG.instantiate())   # looping video backdrop (layer -10)
	else:
		_build_sky()
	world = Node2D.new()
	add_child(world)

	if use_upper_sky_biome and not use_video_background:
		upper_sky = UpperSkyBiomeScript.new()
		world.add_child(upper_sky)
		upper_sky.call("setup", CAT_START.y)

	cat = CAT_SCENE.instantiate()
	cat.position = CAT_START
	cat.z_index = 20
	world.add_child(cat)

	_build_trajectory()

	camera = Camera2D.new()
	camera.position = Vector2(540, CAT_START.y - CAM_LEAD)
	world.add_child(camera)
	camera.make_current()

	hud = GameplayHUD.new()
	hud.retry_pressed.connect(func(): get_tree().reload_current_scene())
	hud.home_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/Main.tscn"))
	hud.pause_pressed.connect(_toggle_pause)
	hud.start_pressed.connect(_begin)
	add_child(hud)

	_seed_world()

	if autoplay:
		started = true
		hud.hide_start_now()
	else:
		hud.set_start_best(best)

func _begin() -> void:
	started = true
	hud.begin_run()

func _build_sky() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)

	var grad := Gradient.new()
	grad.set_color(0, Color(0.70, 0.83, 0.92))   # sky blue (top / space edge)
	grad.set_color(1, Color(0.95, 0.96, 0.92))   # cream (bottom / ground)
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = int(SCREEN.x)
	gt.height = int(SCREEN.y)
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	var tr := TextureRect.new()
	tr.texture = gt
	tr.size = SCREEN
	layer.add_child(tr)

	# drifting soft clouds (screen space, gentle life)
	clouds = Node2D.new()
	layer.add_child(clouds)
	for i in 7:
		var c := _make_cloud()
		c.position = Vector2(randf_range(0, SCREEN.x), randf_range(120, SCREEN.y - 200))
		c.set_meta("spd", randf_range(6.0, 16.0))
		clouds.add_child(c)


func _make_cloud() -> Node2D:
	var n := Node2D.new()
	var col := Color(1, 1, 1, 0.45)
	var lumps := [Vector2(0, 0), Vector2(-60, 12), Vector2(60, 14), Vector2(-24, -18), Vector2(28, -14)]
	for l in lumps:
		var p := Polygon2D.new()
		var rx := randf_range(48, 78)
		p.polygon = _ellipse(rx, rx * 0.62, 16)
		p.position = l
		p.color = col
		n.add_child(p)
	return n

func _build_trajectory() -> void:
	traj = Line2D.new()
	traj.width = 8.0
	traj.default_color = Color(1, 1, 1, 0.8)
	traj.joint_mode = Line2D.LINE_JOINT_ROUND
	traj.begin_cap_mode = Line2D.LINE_CAP_ROUND
	traj.end_cap_mode = Line2D.LINE_CAP_ROUND
	traj.antialiased = true
	traj.z_index = 8
	traj.visible = false
	world.add_child(traj)

	traj_arrow = Polygon2D.new()
	traj_arrow.polygon = PackedVector2Array([Vector2(0, -16), Vector2(24, 0), Vector2(0, 16)])
	traj_arrow.color = Color(1, 1, 1, 0.9)
	traj_arrow.z_index = 8
	traj_arrow.visible = false
	world.add_child(traj_arrow)

func _ellipse(rx: float, ry: float, seg: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg:
		var a := TAU * float(i) / float(seg)
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts

# ------------------------------------------------------------- spawning ----
func _seed_world() -> void:
	# first planet directly ahead, with a runway below so the player has time
	# to read the situation and prepare their first orbit
	_add_planet("meadow", Vector2(540, FIRST_PLANET_Y), 200.0)
	top_spawn_y = FIRST_PLANET_Y
	last_planet_x = 540.0
	for i in 6:
		_spawn_next()

func _add_planet(kind: String, pos: Vector2, orbit_r: float) -> Planet:
	var p: Planet = PLANET_SCENES[kind].instantiate()
	p.position = pos
	world.add_child(p)
	p.setup(kind, orbit_r)
	planets.append(p)
	return p

func _spawn_next() -> void:
	# 0 at the start of the run, 1 once we pass the tutorial distance
	var ramp: float = clampf((start_y - top_spawn_y) * 0.1 / TUTORIAL_DIST, 0.0, 1.0)
	# planets start close together (easy slings), widening to the full range later
	var gap_max: float = lerpf(860.0, MAX_PLANET_GAP, ramp)
	var y := top_spawn_y - randf_range(MIN_PLANET_GAP, gap_max)
	# coin-flip direction (not a deterministic zigzag) - only bias back toward
	# center once a planet drifts close to a screen edge
	var dir: float = 1.0 if randf() < 0.5 else -1.0
	if last_planet_x < 220.0:
		dir = 1.0
	elif last_planet_x > 860.0:
		dir = -1.0
	var x: float = clamp(last_planet_x + dir * randf_range(90.0, 380.0), 140.0, 940.0)
	var kinds := ["meadow", "cloud", "ruin", "dune", "cloud", "meadow"]
	var kind: String = kinds[randi() % kinds.size()]
	var orbit_r := randf_range(155.0, 205.0)

	var prev_x := last_planet_x
	var prev_y := top_spawn_y
	_add_planet(kind, Vector2(x, y), orbit_r)
	top_spawn_y = y
	last_planet_x = x

	# stars along the arc between the two planets, nudged clear of any planet
	var star_n := 1 + randi() % 2
	for i in star_n:
		var t := (float(i) + 1.0) / (float(star_n) + 1.0)
		var mid := Vector2(lerp(prev_x, x, t), lerp(prev_y, y, t))
		mid += Vector2(randf_range(-70, 70), randf_range(-40, 40))
		_add_pickup("star", _clear_of_planets(mid))

	# hazards ramp in over the tutorial: none at the very start, up to full
	# density by TUTORIAL_DIST. Only gentle rocks during the tutorial - meteors
	# (fast) hold off until the player has the basics.
	var haz_chance: float = lerpf(0.0, 0.55, ramp)
	if randf() < haz_chance:
		var hk: String = "rock"
		if ramp >= 1.0 and randf() >= 0.6:
			hk = "meteor"
		var ang := randf_range(0.0, TAU)
		# spawn well OUTSIDE the ring - the min gap must exceed cat+rock radius,
		# or a hazard sitting on the orbit path is an unavoidable hit
		var clear_dist := orbit_r + randf_range(180.0, 340.0)
		var hp := Vector2(x, y) + Vector2.from_angle(ang) * clear_dist
		hp = _clear_of_orbit_rings(hp)   # also keep clear of every OTHER planet's ring
		hp.x = clamp(hp.x, 80.0, 1000.0)
		_add_hazard(hk, hp)

	# rare shield pickup
	if randf() < 0.16:
		var sp := Vector2(clamp(x + randf_range(-120, 120), 120, 960), y - randf_range(60, 140))
		_add_pickup("shield", _clear_of_planets(sp))

	# wind-lane cue: show between planet pairs in the 100-200 m learning phase
	if upper_sky != null:
		var dist_here: float = (start_y - y) * 0.1
		if dist_here > 80.0 and dist_here < 220.0 and randf() < 0.40:
			upper_sky.call("set_wind_lane", true, (y + prev_y) * 0.5)
		elif dist_here >= 220.0:
			upper_sky.call("set_wind_lane", false, 0.0)

	# a later planet's ring may now overlap an earlier hazard - fix or drop those
	_reconcile_hazards()

## Keep a hazard away from EVERY planet's dotted orbit ring. A hazard within a
## band around the ring (where the orbiting cat travels) would be a guaranteed
## hit, so push it outward past the band. Band = cat radius + hazard radius +
## margin, so neither the cat's nor the rock's edge touches the orbit path.
func _clear_of_orbit_rings(pos: Vector2) -> Vector2:
	var band := _ring_band()
	for _pass in 4:
		var moved := false
		for p in planets:
			var to := pos - p.global_position
			var d := to.length()
			if absf(d - p.orbit_radius) < band:
				if d < 0.001:
					to = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
				pos = p.global_position + to.normalized() * (p.orbit_radius + band)
				moved = true
		if not moved:
			break
	return pos

func _ring_band() -> float:
	const HAZARD_R := 54.0
	return cat.hit_radius + HAZARD_R + 45.0

## True if pos is outside every planet's orbit-ring danger band.
func _ring_clear(pos: Vector2) -> bool:
	var band := _ring_band()
	for p in planets:
		if absf(pos.distance_to(p.global_position) - p.orbit_radius) < band - 1.0:
			return false
	return true

## Re-clear every existing hazard against every ring (planets spawned after a
## hazard can land their ring on it). If a hazard can't be nudged clear
## (planets too tightly packed), drop it rather than leave a guaranteed hit.
func _reconcile_hazards() -> void:
	for i in range(hazards.size() - 1, -1, -1):
		var hz := hazards[i]
		if not is_instance_valid(hz):
			hazards.remove_at(i)
			continue
		var fixed := _clear_of_orbit_rings(hz.position)
		if _ring_clear(fixed):
			hz.position = fixed
		else:
			hazards.remove_at(i)
			hz.queue_free()

## Push a pickup position outward until it no longer overlaps any planet disk,
## keeping a clean margin beyond the planet's edge. A few passes handle the
## case where escaping one planet pushes into a neighbour.
func _clear_of_planets(pos: Vector2) -> Vector2:
	const MARGIN := 60.0
	for _pass in 4:
		var moved := false
		for p in planets:
			var to := pos - p.global_position
			var min_d := p.visual_radius + MARGIN
			var d := to.length()
			if d < min_d:
				if d < 0.001:
					to = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
				pos = p.global_position + to.normalized() * min_d
				moved = true
		if not moved:
			break
	return pos

func _add_pickup(kind: String, pos: Vector2) -> void:
	var pk: Pickup = PICKUP_SCENES[kind].instantiate()
	pk.position = pos
	pk.z_index = 4
	world.add_child(pk)
	pk.setup(kind)
	pickups.append(pk)

func _add_hazard(kind: String, pos: Vector2) -> void:
	var hz: Hazard = HAZARD_SCENES[kind].instantiate()
	hz.position = pos
	hz.z_index = 6
	world.add_child(hz)
	hz.setup(kind)
	hazards.append(hz)

# ---------------------------------------------------------------- loop ----
func _physics_process(delta: float) -> void:
	if not started or game_over or paused:
		return

	var candidate := _nearest_planet()
	var holding := Input.is_action_pressed("orbit_hold")
	if autoplay:  # gated self-test: orbit until warm, then fling onward
		holding = candidate != null and heat < 0.6

	if holding and candidate != null:
		_orbit(candidate, delta)
	else:
		if is_orbiting:
			_release()
		_fly(delta)

	heat = max(0.0, heat - HEAT_COOL * delta)

	distance = max(distance, (start_y - cat.position.y) * 0.1)
	hud.set_distance(distance)
	hud.set_heat(heat)

	_check_pickups()
	_check_hazards()
	_check_planet_core()
	_check_bounds()

	_spawn_ahead()
	_despawn_behind()
	_update_trajectory()

func _process(delta: float) -> void:
	# camera follow (cat sits in the lower third, space ahead)
	var target := Vector2(540, cat.position.y - CAM_LEAD)
	camera.position = camera.position.lerp(target, 0.12)
	# drift clouds (only exist when the painted sky is used, not the video bg)
	if clouds:
		for c in clouds.get_children():
			c.position.x += c.get_meta("spd", 8.0) * delta
			if c.position.x > SCREEN.x + 120:
				c.position.x = -120
				c.position.y = randf_range(120, SCREEN.y - 200)
	_update_target_indicator()
	if upper_sky != null:
		upper_sky.call("update_state", delta, distance, camera.position.y, is_orbiting, 0.0)

# ---- off-screen "next planet" indicator ----
func _next_target() -> Planet:
	# nearest planet ahead (above the cat) that isn't the one being orbited
	var best_p: Planet = null
	var best_d := INF
	for p in planets:
		if p == current_planet:
			continue
		if p.global_position.y < cat.position.y - 40.0:
			var d := cat.position.distance_to(p.global_position)
			if d < best_d:
				best_d = d
				best_p = p
	return best_p

func _update_target_indicator() -> void:
	if not started or game_over:
		hud.set_planet_indicator(false)
		return
	var target := _next_target()
	if target == null:
		hud.set_planet_indicator(false)
		return
	var center := SCREEN * 0.5
	var tscreen := target.global_position - camera.global_position + center
	var r := target.visual_radius
	# on-screen (even partly) -> no indicator needed
	if tscreen.x > -r and tscreen.x < SCREEN.x + r and tscreen.y > -r and tscreen.y < SCREEN.y + r:
		hud.set_planet_indicator(false)
		return
	var col: Color = PLANET_COLORS.get(target.kind, Color(0.6, 0.72, 0.5))
	hud.set_planet_indicator(true, _edge_point(tscreen, center), (tscreen - center).angle(), col)

func _edge_point(t: Vector2, c: Vector2) -> Vector2:
	# where the ray from screen center to the target meets the inset HUD frame
	# (top inset is larger to clear the distance number and heat bar)
	var d := t - c
	if d.length() < 1.0:
		return c
	d = d.normalized()
	var pad_l := 80.0
	var pad_r := SCREEN.x - 80.0
	var pad_t := 300.0
	var pad_b := SCREEN.y - 100.0
	var tmin := INF
	if d.x > 0.001:
		tmin = min(tmin, (pad_r - c.x) / d.x)
	elif d.x < -0.001:
		tmin = min(tmin, (pad_l - c.x) / d.x)
	if d.y > 0.001:
		tmin = min(tmin, (pad_b - c.y) / d.y)
	elif d.y < -0.001:
		tmin = min(tmin, (pad_t - c.y) / d.y)
	return c + d * tmin

func _nearest_planet() -> Planet:
	var best_p: Planet = null
	var best_d := INF
	for p in planets:
		var d := cat.position.distance_to(p.global_position)
		if d <= p.gravity_radius and d < best_d:
			best_d = d
			best_p = p
	return best_p

func _orbit(p: Planet, delta: float) -> void:
	if current_planet != p:
		if current_planet:
			current_planet.set_active(false)
		current_planet = p
		p.set_active(true)
		var to := cat.position - p.global_position
		cur_radius = to.length()
		orbit_angle = to.angle()
		var cross := to.x * velocity.y - to.y * velocity.x
		orbit_dir = 1.0 if cross >= 0.0 else -1.0
		_burst(cat.position, "sparkle", Color(0.7, 0.85, 1.0), 8, 90, 0.5)
		hud.hide_tutorial()
	is_orbiting = true

	orbit_angle += orbit_dir * ORBIT_ANG_SPEED * delta
	cur_radius = lerp(cur_radius, p.orbit_radius, 0.18)
	cat.position = p.global_position + Vector2.from_angle(orbit_angle) * cur_radius
	var tangent := Vector2.from_angle(orbit_angle + orbit_dir * PI * 0.5)
	velocity = tangent * LAUNCH_SPEED

	# gentler heat build during the tutorial so lingering to learn is forgiving
	var heat_mult: float = lerpf(0.5, 1.0, clampf(distance / TUTORIAL_DIST, 0.0, 1.0))
	heat = min(1.0, heat + HEAT_GAIN * heat_mult * delta)
	p.set_heat_ratio(heat)
	cat.play_orbit_tilt(orbit_dir)

func _release() -> void:
	is_orbiting = false
	if current_planet:
		current_planet.set_active(false)
		current_planet.cool_visual()
	cat.play_launch(velocity.normalized())
	_burst(cat.position, "sparkle", Color(0.75, 0.88, 1.0), 10, 140, 0.5)
	# perfect sling: cool release aimed generally forward/upward
	if velocity.y < -150.0 and heat < 0.55:
		perfects += 1
		_burst(cat.position, "twinkle", Color(1.0, 0.86, 0.5), 12, 170, 0.7)
	current_planet = null

func _fly(delta: float) -> void:
	cat.position += velocity * delta
	if not is_orbiting:
		cat.play_idle()

# ---------------------------------------------------------- collisions ----
func _check_pickups() -> void:
	for pk in pickups:
		if not is_instance_valid(pk) or not pk.alive:
			continue
		if cat.position.distance_to(pk.position) < cat.hit_radius + pk.radius:
			if pk.kind == "star":
				stars += 1
				hud.set_stars(stars)
				cat.pop()
				_burst(pk.position, "twinkle", Color(1.0, 0.85, 0.45), 10, 130, 0.6)
			else:
				shield_count += 1
				cat.set_shield(true)
				hud.set_shield_count(shield_count)
				_burst(pk.position, "sparkle", Color(0.7, 0.9, 1.0), 12, 120, 0.6)
			pk.collect()

func _check_hazards() -> void:
	for hz in hazards:
		if not is_instance_valid(hz):
			continue
		if cat.position.distance_to(hz.position) < cat.hit_radius * 0.85 + hz.radius:
			if shield_count > 0:
				shield_count -= 1
				hud.set_shield_count(shield_count)
				if shield_count == 0:
					cat.set_shield(false)
				_burst(cat.position, "sparkle", Color(0.7, 0.9, 1.0), 16, 180, 0.6)
				hazards.erase(hz)
				hz.queue_free()
			else:
				var what: String = "a drift rock" if hz.kind == "rock" else "a meteor"
				_fail("Bumped into %s" % what)
			return

func _check_planet_core() -> void:
	# You can graze a planet's edges, but flying through its dead center is a
	# crash. The planet you're actively orbiting is exempt (you sit outside it).
	for p in planets:
		if is_orbiting and p == current_planet:
			continue
		if cat.position.distance_to(p.global_position) < p.core_radius:
			_fail("Tumbled into a planet")
			return

func _check_bounds() -> void:
	if cat.position.x < -170 or cat.position.x > SCREEN.x + 170:
		_fail("Drifted off into open space")
	elif cat.position.y > start_y + 520:
		_fail("Fell back down to Earth")
	elif heat >= 1.0:
		_fail("The planet overheated")

# ----------------------------------------------------------- streaming ----
func _spawn_ahead() -> void:
	while top_spawn_y > cat.position.y - 2400.0:
		_spawn_next()

func _despawn_behind() -> void:
	var limit := cat.position.y + 1500.0
	for i in range(planets.size() - 1, -1, -1):
		var p := planets[i]
		if not is_instance_valid(p):
			planets.remove_at(i)
		elif p.position.y > limit:
			planets.remove_at(i)
			p.queue_free()
	for i in range(pickups.size() - 1, -1, -1):
		var pk := pickups[i]
		if not is_instance_valid(pk):
			pickups.remove_at(i)
		elif pk.position.y > limit:
			pickups.remove_at(i)
			pk.queue_free()
	for i in range(hazards.size() - 1, -1, -1):
		var hz := hazards[i]
		if not is_instance_valid(hz):
			hazards.remove_at(i)
		elif hz.position.y > limit:
			hazards.remove_at(i)
			hz.queue_free()

func _update_trajectory() -> void:
	if is_orbiting:
		var dir := velocity.normalized()
		var start := cat.position + dir * 78.0
		var end := start + dir * 430.0
		traj.points = PackedVector2Array([start, end])
		traj.visible = true
		traj_arrow.visible = true
		traj_arrow.position = end
		traj_arrow.rotation = dir.angle()
	else:
		traj.visible = false
		traj_arrow.visible = false

# --------------------------------------------------------------- juice ----
func _burst(pos: Vector2, tex_key: String, col: Color, amount: int, speed: float, life: float) -> void:
	var tex_path: String = {
		"sparkle": "res://assets/sprites/vfx/sparkle.png",
		"twinkle": "res://assets/sprites/vfx/twinkle_star.png",
		"steam":   "res://assets/sprites/vfx/steam_puff.png",
	}.get(tex_key, "res://assets/sprites/vfx/sparkle.png")
	var pt := CPUParticles2D.new()
	pt.texture = load(tex_path)
	pt.position = pos
	pt.z_index = 15
	pt.emitting = true
	pt.one_shot = true
	pt.explosiveness = 1.0
	pt.amount = amount
	pt.lifetime = life
	pt.direction = Vector2(0, -1)
	pt.spread = 180.0
	pt.gravity = Vector2.ZERO
	pt.initial_velocity_min = speed * 0.4
	pt.initial_velocity_max = speed
	pt.scale_amount_min = 0.15
	pt.scale_amount_max = 0.4
	pt.color = col
	world.add_child(pt)
	get_tree().create_timer(life + 0.4).timeout.connect(func():
		if is_instance_valid(pt):
			pt.queue_free())

# --------------------------------------------------------------- state ----
func _toggle_pause() -> void:
	if game_over:
		return
	paused = not paused
	hud.tutorial.visible = not paused
	if paused:
		hud.show_warning("Paused")
	else:
		hud.warning.visible = false

func _fail(reason: String) -> void:
	if game_over:
		return
	game_over = true
	is_orbiting = false
	if autoplay:
		print("[autoplay] FAIL: '%s'  distance=%dm stars=%d perfects=%d" % [reason, int(distance), stars, perfects])
	traj.visible = false
	traj_arrow.visible = false
	cat.play_launch(Vector2(randf_range(-1, 1), 1).normalized())
	# manhole spins off screen
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(cat, "rotation", cat.rotation + TAU * 1.5, 0.9)
	var d := int(distance)
	if d > best:
		best = d
		_save_best()
	hud.show_result(d, stars, perfects, best, reason)

func _load_best() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://orbits.cfg") == OK:
		best = int(cfg.get_value("score", "best", 0))

func _save_best() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", best)
	cfg.save("user://orbits.cfg")
