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

## World scale. Background tiles are 2752px tall and OVERLAP by COLUMN_SEAM_PX for
## a cross-dissolve (the art isn't painted to tile, so a hard butt-join shows
## content seams). We scale by the NET advance (tile minus overlap) so each image
## still adds exactly 300m of new altitude: N images = N*300m, biomes land on a
## clean 1500/3000/4500/6000m grid, and the ~83m overlap dissolves seamlessly.
const TILE_PX := 2752.0
const TILE_METERS := 300.0
const COLUMN_SEAM_PX := 600.0                       # overlap blended between tiles
const NET_ADVANCE_PX := TILE_PX - COLUMN_SEAM_PX     # 2152 -> one image = +300m
const METERS_PER_PX := TILE_METERS / NET_ADVANCE_PX  # 0.139405...
const PX_PER_METER := NET_ADVANCE_PX / TILE_METERS   # 7.17333...

## Upper Sky difficulty zones (matches the biome's ~1500 m painted length).
## Each array is a value at the matching ZONE_BREAKS distance (meters);
## _zone_value() linearly interpolates between consecutive breakpoints, so
## difficulty ramps smoothly rather than jumping at the boundaries. Beyond
## the last breakpoint (past the biome, not yet built) values hold at the
## final entry.
##
##   0-300m    tutorial       — no hazards at all, planets close together
##   300-600m  get used to it — hazards ease in, spacing widens
##   600-900m  play zone      — normal difficulty
##   900-1200m floating asteroids — hazard density peaks, shields introduced
##   1200-1500m flying meteors — meteors mixed into hazards
##
## No "overheat" planet kind is ever spawned here (see _spawn_next's kinds
## list) - that gimmick is reserved for a later biome, not this friendly one.
const ZONE_BREAKS:         Array[float] = [0.0,   300.0, 600.0, 900.0,  1200.0, 1500.0]
## Vertical spacing between rows. Upper Sky is the friendly intro biome, so keep
## rows CLOSE and the max jump modest -- denser = more planets on screen and you
## can always reach the next one (the old 900-1920px max left near-empty stretches
## that could strand you). The min..max range keeps spacing randomized, not a grid.
const ZONE_GAP_MIN:        Array[float] = [380.0, 390.0, 400.0, 420.0,  440.0,  460.0]
const ZONE_GAP_MAX:        Array[float] = [540.0, 560.0, 580.0, 620.0,  660.0,  720.0]
const ZONE_HAZARD_CHANCE:  Array[float] = [0.0,   0.0,   0.30,  0.45,   0.55,   0.55]
const ZONE_METEOR_FRAC:    Array[float] = [0.0,   0.0,   0.0,   0.0,    0.0,    0.45]
const ZONE_SHIELD_CHANCE:  Array[float] = [0.0,   0.0,   0.0,   0.0,    0.22,   0.20]
const ZONE_HEAT_MULT:      Array[float] = [0.40,  0.55,  0.70,  0.85,   1.0,    1.0]
## Chance a "row" spawns two side-by-side planets (a left/right fork) instead of
## one. Kept LOW so most rows are a single planet at a randomized offset and a
## fork is an occasional treat -- high values made every row read as a coupled
## pair. A touch more forking in the early tutorial zone, tapering to ~18%.
const ZONE_BRANCH_CHANCE:  Array[float] = [0.28,  0.25,  0.22,  0.20,   0.18,   0.18]

## Orbit-radius range used for BOTH planets in a branching row. Slightly
## smaller than the single-row 155-205 range so a row of two comfortably
## fits the ~800px playable width. Note gravity radii ARE allowed to overlap
## here (see _physics_process's capture-lock comment) - once orbiting one,
## the player stays locked onto it regardless of the other branch's pull, so
## only visual ring overlap needs avoiding, not gravity-radius separation.
const BRANCH_ORBIT_R_MIN := 150.0
const BRANCH_ORBIT_R_MAX := 180.0
const BRANCH_HALF_SPREAD_MIN := 200.0
const BRANCH_HALF_SPREAD_MAX := 260.0

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

const UpperSkyBiomeScript        := preload("res://scripts/gameplay/UpperSkyBiome.gd")
const BackgroundColumnScript     := preload("res://scripts/gameplay/BackgroundColumn.gd")

## Number of 300m tiles in res://assets/backgrounds/_column/ (tile_0..N-1,
## bottom to top). 40 = DreamSky(5) + Pastel(5) + Kuiper(5) + Oort(5) +
## CrystalAurora(5) + VoidZone(5) + ForgottenRuins(5) + DarkMatterReef(5) =
## 12000m, covering 1500m to 13500m. Add 5 more per biome (A B C D transition)
## and bump.
const COLUMN_TILE_COUNT := 40

## DEV: jump straight to this altitude (meters) instead of playing from 0.
## Set to 0 for a normal run. Try 1200 to land directly in the meteor zone.
@export var dev_start_meters: float = 0.0

## DEV: free-fly map review. When true, the cat isn't played -- it just cruises
## straight up so you can inspect the whole background column without swinging
## through planets. Controls (keyboard, editor): UP = faster, DOWN = descend,
## SHIFT = turbo, no input = steady cruise. No planets/hazards/heat/game-over.
## Also togglable at runtime with the F key.
@export var dev_flythrough: bool = false
const FLY_SPEED := 1000.0   # px/sec full speed (~109 m/s at the 300m/tile scale)

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
var upper_sky:    Node2D
var background_column: Node2D

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
var shield_count := 0       # stacks: each hazard hit consumes one charge
var shields_collected := 0  # lifetime-per-run total (never decremented) for run logging
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
	elif not use_upper_sky_biome:
		_build_sky()   # fallback gradient; skipped when biome system is active
	world = Node2D.new()
	add_child(world)

	if use_upper_sky_biome and not use_video_background:
		upper_sky = UpperSkyBiomeScript.new()
		world.add_child(upper_sky)
		upper_sky.call("setup", CAT_START.y)

		# Everything above Upper Sky is now ONE continuous streamed column of
		# butt-joined 300m tiles (DreamSky -> Pastel -> Kuiper -> ...), color-
		# matched at every boundary. No alpha cross-fades between biomes; only
		# the tiles near the camera are instanced (see BackgroundColumn).
		background_column = BackgroundColumnScript.new()
		world.add_child(background_column)
		# Anchor the column's bottom (DreamSky's entry) at exactly 1500m so the
		# biome grid is clean, regardless of Upper Sky's (old-system) height. The
		# column's bottom tile dissolves down over Upper Sky's top behind it.
		var col_bottom_y: float = CAT_START.y - 1500.0 * PX_PER_METER
		background_column.call("setup", col_bottom_y, COLUMN_TILE_COUNT)

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
	add_child(hud)

	_seed_world()

	if dev_start_meters > 0.0:
		_dev_warp(dev_start_meters)

	# Launch begins the run immediately - no separate in-scene Start tap.
	started = true

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

## Linear interpolation across ZONE_BREAKS: find which pair of breakpoints
## dist_m falls between and blend the matching pair in `values`. Clamps to
## the first/last entry outside the table's range.
func _zone_value(dist_m: float, values: Array[float]) -> float:
	if dist_m <= ZONE_BREAKS[0]:
		return values[0]
	for i in range(1, ZONE_BREAKS.size()):
		if dist_m <= ZONE_BREAKS[i]:
			var t: float = (dist_m - ZONE_BREAKS[i - 1]) / (ZONE_BREAKS[i] - ZONE_BREAKS[i - 1])
			return lerpf(values[i - 1], values[i], t)
	return values[values.size() - 1]

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

## "overheat" is deliberately never in this pool - that gimmick belongs to a
## later, less beginner-friendly biome
const PLANET_KINDS := ["meadow", "cloud", "ruin", "dune", "cloud", "meadow"]

func _random_kind() -> String:
	return PLANET_KINDS[randi() % PLANET_KINDS.size()]

## Places the next row of planets ahead. Most rows in Upper Sky branch into
## TWO planets side by side rather than one, so whichever moment the player
## releases at, both a left and a right target are reachable - no single
## forced path, which keeps the biome feeling generous rather than a rail.
func _spawn_next() -> void:
	# distance (in meters) of the LAST placed row - the new one lands
	# further still, so zone lookups use this as "where we are now"
	var dist_here: float = (start_y - top_spawn_y) * METERS_PER_PX

	var gap_min: float = _zone_value(dist_here, ZONE_GAP_MIN)
	var gap_max: float = _zone_value(dist_here, ZONE_GAP_MAX)
	var y := top_spawn_y - randf_range(gap_min, gap_max)
	# coin-flip direction (not a deterministic zigzag) - only bias back toward
	# center once the chain drifts close to a screen edge
	var dir: float = 1.0 if randf() < 0.5 else -1.0
	if last_planet_x < 220.0:
		dir = 1.0
	elif last_planet_x > 860.0:
		dir = -1.0

	var prev_x := last_planet_x
	var prev_y := top_spawn_y

	var branch_chance: float = _zone_value(dist_here, ZONE_BRANCH_CHANCE)
	var did_branch := false
	if randf() < branch_chance:
		did_branch = _spawn_branch_row(dist_here, prev_x, prev_y, dir, y)
	if not did_branch:
		_spawn_single_row(dist_here, prev_x, prev_y, dir, y)

	# wind-lane cue: show between rows in the 100-200 m learning phase
	if upper_sky != null:
		if dist_here > 80.0 and dist_here < 220.0 and randf() < 0.40:
			upper_sky.call("set_wind_lane", true, (y + prev_y) * 0.5)
		elif dist_here >= 220.0:
			upper_sky.call("set_wind_lane", false, 0.0)

	# a later planet's ring may now overlap an earlier hazard - fix or drop those
	_reconcile_hazards()

## The original single-target row: one planet, offset from the previous one
## by dir * a random distance. Falls back here when the branch roll misses,
## or when _spawn_branch_row() can't fit two planets without edge-clamping
## them too close together.
func _spawn_single_row(dist_here: float, prev_x: float, prev_y: float, dir: float, y: float) -> void:
	var x: float = clamp(prev_x + dir * randf_range(90.0, 380.0), 140.0, 940.0)
	var orbit_r := randf_range(155.0, 205.0)
	_add_planet(_random_kind(), Vector2(x, y), orbit_r)
	top_spawn_y = y
	last_planet_x = x

	_add_stars_along(prev_x, prev_y, x, y)
	_maybe_add_hazard(dist_here, x, y, orbit_r)
	_maybe_add_shield(dist_here, x, y)

## Two planets side by side at (roughly) the same height - a real fork where
## either one is a valid next target, chosen purely by when the player
## releases while orbiting the previous planet. Their gravity radii CAN
## overlap (that's fine - _physics_process locks onto whichever one you're
## already orbiting, so proximity to the other never steals the hold); the
## spacing here only needs to keep the dotted orbit RINGS from visually
## overlapping. If a hazard rolls for this row, it's placed on only ONE
## side, so picking the other branch is always a way to dodge it entirely -
## the "generous" half of branching. Returns false (caller should fall back
## to a single planet) if the chain has drifted so close to an edge that
## both branches can't fit on-screen.
func _spawn_branch_row(dist_here: float, prev_x: float, prev_y: float, dir: float, y: float) -> bool:
	var orbit_l := randf_range(BRANCH_ORBIT_R_MIN, BRANCH_ORBIT_R_MAX)
	var orbit_r := randf_range(BRANCH_ORBIT_R_MIN, BRANCH_ORBIT_R_MAX)
	# ring radius == orbit_radius (Planet draws its dotted ring at that
	# distance) - require enough separation that the two rings don't touch
	var required_sep: float = orbit_l + orbit_r + 40.0
	var needed_half: float = required_sep * 0.5
	var half_spread: float = randf_range(maxf(needed_half, BRANCH_HALF_SPREAD_MIN), maxf(needed_half, BRANCH_HALF_SPREAD_MAX))

	# Center is clamped to a band narrow enough that, combined with
	# BRANCH_HALF_SPREAD_MAX, both branches ALWAYS fit inside [140, 940]
	# without needing to clamp x_l/x_r themselves - so this basically never
	# fails in practice (the x_r-x_l check below is just a safety net).
	var center: float = clamp(prev_x + dir * randf_range(60.0, 140.0), 140.0 + BRANCH_HALF_SPREAD_MAX, 940.0 - BRANCH_HALF_SPREAD_MAX)
	var x_l: float = clamp(center - half_spread, 140.0, 940.0)
	var x_r: float = clamp(center + half_spread, 140.0, 940.0)
	if x_r - x_l < required_sep:
		return false   # edge-clamped too close together - not worth the risk

	var y_l := y + randf_range(-40.0, 40.0)
	var y_r := y + randf_range(-40.0, 40.0)

	_add_planet(_random_kind(), Vector2(x_l, y_l), orbit_l)
	_add_planet(_random_kind(), Vector2(x_r, y_r), orbit_r)
	top_spawn_y = minf(y_l, y_r)
	last_planet_x = center

	_add_stars_along(prev_x, prev_y, x_l, y_l)
	_add_stars_along(prev_x, prev_y, x_r, y_r)

	# one hazard roll for the whole row, dropped onto only one branch - the
	# other branch is always a clean way to dodge it entirely
	var haz_chance: float = _zone_value(dist_here, ZONE_HAZARD_CHANCE)
	var hazard_on_left := randf() < 0.5
	var placed := false
	if randf() < haz_chance:
		if hazard_on_left:
			placed = _add_hazard_near(dist_here, x_l, y_l, orbit_l)
		else:
			placed = _add_hazard_near(dist_here, x_r, y_r, orbit_r)

	# if a hazard landed, put any shield on the OTHER branch (clear incentive);
	# otherwise just pick a side at random
	var shield_on_left: bool = (not hazard_on_left) if placed else (randf() < 0.5)
	if shield_on_left:
		_maybe_add_shield(dist_here, x_l, y_l)
	else:
		_maybe_add_shield(dist_here, x_r, y_r)
	return true

func _add_stars_along(prev_x: float, prev_y: float, x: float, y: float) -> void:
	var star_n := 1 + randi() % 2
	for i in star_n:
		var t := (float(i) + 1.0) / (float(star_n) + 1.0)
		var mid := Vector2(lerp(prev_x, x, t), lerp(prev_y, y, t))
		mid += Vector2(randf_range(-70, 70), randf_range(-40, 40))
		_add_pickup("star", _clear_of_planets(mid))

## Hazard density and composition follow the zone table: none in the 0-300m
## tutorial, easing in through 300-900m, peaking as "floating asteroids" at
## 900-1200m, then meteors mix in for 1200-1500m. Returns true if placed.
func _maybe_add_hazard(dist_here: float, x: float, y: float, orbit_r: float) -> bool:
	var haz_chance: float = _zone_value(dist_here, ZONE_HAZARD_CHANCE)
	if randf() < haz_chance:
		return _add_hazard_near(dist_here, x, y, orbit_r)
	return false

func _add_hazard_near(dist_here: float, x: float, y: float, orbit_r: float) -> bool:
	var meteor_frac: float = _zone_value(dist_here, ZONE_METEOR_FRAC)
	var hk: String = "meteor" if randf() < meteor_frac else "rock"
	var ang := randf_range(0.0, TAU)
	# spawn well OUTSIDE the ring - the min gap must exceed cat+rock radius,
	# or a hazard sitting on the orbit path is an unavoidable hit
	var clear_dist := orbit_r + randf_range(180.0, 340.0)
	var hp := Vector2(x, y) + Vector2.from_angle(ang) * clear_dist
	hp = _clear_of_orbit_rings(hp)   # also keep clear of every OTHER planet's ring
	hp.x = clamp(hp.x, 80.0, 1000.0)
	_add_hazard(hk, hp)
	return true

## Shields are introduced at 900m (floating asteroid zone) - none before.
func _maybe_add_shield(dist_here: float, x: float, y: float) -> bool:
	var shield_chance: float = _zone_value(dist_here, ZONE_SHIELD_CHANCE)
	if randf() < shield_chance:
		var sp := Vector2(clamp(x + randf_range(-120, 120), 120, 960), y - randf_range(60, 140))
		_add_pickup("shield", _clear_of_planets(sp))
		return true
	return false

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
	if dev_flythrough:
		if not paused:              # P freezes the fly-through dolly to study a frame
			_dev_fly(delta)
		return
	if not started or game_over or paused:
		return

	# While already orbiting, stay locked onto that SAME planet - only
	# _release() (letting go) should ever change which planet you're headed
	# to. Otherwise, if two planets' gravity radii ever came close together
	# (e.g. a branching row's two side-by-side options), re-picking the
	# nearest one every frame could silently swap current_planet mid-hold.
	var candidate: Planet = current_planet if is_orbiting else _nearest_planet()
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

	distance = max(distance, (start_y - cat.position.y) * METERS_PER_PX)
	hud.set_distance(distance)
	hud.set_heat(heat)

	_check_pickups()
	_check_hazards()
	_check_planet_core()
	_check_bounds()

	_spawn_ahead()
	_despawn_behind()
	_update_trajectory()

	# Camera follows in the SAME fixed step the cat moves in. Doing this in
	# _process instead made the camera lerp toward a stale cat position between
	# physics ticks and then snap when the cat advanced - the visible flight
	# jitter. Lockstep here keeps their relative offset stable and smooth.
	var target := Vector2(540, cat.position.y - CAM_LEAD)
	camera.position = camera.position.lerp(target, 0.12)

func _process(delta: float) -> void:
	# drift clouds (only exist when the painted sky is used, not the video bg)
	if clouds:
		for c in clouds.get_children():
			c.position.x += c.get_meta("spd", 8.0) * delta
			if c.position.x > SCREEN.x + 120:
				c.position.x = -120
				c.position.y = randf_range(120, SCREEN.y - 200)
	_update_target_indicator()
	# Biome cross-fades are driven by CAMERA altitude, not the `distance` score.
	# `distance` is max()-monotonic and LEAPS when the cat slingshots off a planet
	# (and never reverses). Feeding that jumpy value into a fixed-width smoothstep
	# window made the fade snap across in a single frame -> a hard biome cut
	# (seen ~4480m, right before a fade window's end). The camera position is
	# lerp-smoothed every frame (see below), so its altitude changes continuously
	# even through a slingshot; the backgrounds are painted at fixed world Y, so
	# tracking the camera is also the *correct* driver for a positional dissolve.
	var cam_alt: float = (start_y - camera.position.y) * METERS_PER_PX
	if upper_sky != null:
		# Subtract the biome node's own Y offset so particle emitters (which use
		# local coordinates) stay centred on the camera even when the background
		# has been slid via _dev_warp.  When offset is 0 this is a no-op.
		upper_sky.call("update_state", delta, cam_alt,
				camera.position.y - upper_sky.position.y, is_orbiting, 0.0)
	if background_column != null:
		# Stream tiles in/out around the camera. Subtract the column's own Y
		# offset so streaming stays correct after a _dev_warp slide.
		background_column.call("update_view", camera.position.y - background_column.position.y)

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

	# gentler heat build in the early zones so lingering to learn is forgiving
	var heat_mult: float = _zone_value(distance, ZONE_HEAT_MULT)
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
				shields_collected += 1
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

# ----------------------------------------------------------------- dev ----
## Dev keys: F toggles free-fly map review (see dev_flythrough); P pauses/resumes
## the run (same as the HUD pause button) so you can freeze the frame while testing.
func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match (event as InputEventKey).keycode:
		KEY_F:
			dev_flythrough = not dev_flythrough
			if dev_flythrough:
				hud.show_warning("DEV FLY  ·  UP/DOWN move  ·  SHIFT turbo  ·  F exit")
			elif hud.warning != null:
				hud.warning.visible = false
		KEY_P:
			_toggle_pause()


## Free-fly map review (see dev_flythrough). The cat is a passive camera dolly:
## it cruises straight up so the whole background column scrolls past for
## inspection, with no orbiting/heat/hazards/game-over. UP=faster, DOWN=descend,
## SHIFT=turbo, no input=steady cruise.
func _dev_fly(delta: float) -> void:
	# Gentle default cruise up so you can actually look at the art; hold UP to
	# move up faster, DOWN to descend, SHIFT for turbo on either.
	var v := 0.6                                   # idle: gentle cruise up
	if Input.is_action_pressed("ui_up"):
		v = 1.0
	elif Input.is_action_pressed("ui_down"):
		v = -1.0                                   # descend to re-check a band
	var spd := FLY_SPEED * v
	if Input.is_key_pressed(KEY_SHIFT):
		spd *= 2.5                                 # turbo
	# Up = negative Y. Don't fly below the start floor.
	cat.position.y = minf(cat.position.y - spd * delta, start_y)

	# Camera snaps to the cat (no lerp) so scrubbing feels immediate.
	camera.position = Vector2(540.0, cat.position.y - CAM_LEAD)

	# Keep the altitude readout live so you know where you are.
	distance = maxf(0.0, (start_y - cat.position.y) * METERS_PER_PX)
	hud.set_distance(distance)


## Warp to a target altitude without playing through the earlier zones.
##
## Rather than moving the cat to a large negative Y (which can cause rendering
## issues with the background tiles), we slide the painted biome backgrounds
## DOWN by `meters * 10` pixels so their correct visual band appears right in
## front of the camera at its normal start position.  start_y is offset by the
## same amount so all distance/zone calculations remain accurate.
func _dev_warp(meters: float) -> void:
	var offset := meters * PX_PER_METER

	# Slide backgrounds so the right altitude is visible at the normal camera Y.
	if upper_sky != null:
		upper_sky.position.y += offset
	if background_column != null:
		background_column.position.y += offset

	# Adjust start_y so distance reads correctly from the normal cat position.
	start_y = CAT_START.y + offset
	distance = meters

	# Re-seed planets: the initial _seed_world() ran with the old start_y, so
	# zone tables (hazards, gaps, meteors) were wrong. Clear and redo with the
	# adjusted start_y so the very first row uses 1200m parameters.
	for p in planets:
		if is_instance_valid(p): p.queue_free()
	planets.clear()
	for pk in pickups:
		if is_instance_valid(pk): pk.queue_free()
	pickups.clear()
	for hz in hazards:
		if is_instance_valid(hz): hz.queue_free()
	hazards.clear()
	top_spawn_y = FIRST_PLANET_Y
	last_planet_x = 540.0
	_add_planet("meadow", Vector2(540.0, FIRST_PLANET_Y), 200.0)
	for i in 8:
		_spawn_next()

# --------------------------------------------------------------- state ----
func _toggle_pause() -> void:
	if game_over:
		return
	paused = not paused
	hud.tutorial.visible = not paused
	for hz in hazards:
		hz.set_physics_process(not paused)   # hazards move on the physics clock now
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
	_log_run(reason)
	hud.show_result(d, stars, perfects, best, reason)

func _load_best() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://orbits.cfg") == OK:
		best = int(cfg.get_value("score", "best", 0))

func _save_best() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://orbits.cfg")   # keep other sections (stats)
	cfg.set_value("score", "best", best)
	cfg.save("user://orbits.cfg")

## ECONOMY DATA: append every completed run to user://run_log.jsonl (one JSON per
## line) and roll lifetime aggregates into user://orbits.cfg [stats]. Use these
## to size shop prices later -- e.g. "coins per 100m" tells you how fast a player
## earns, so an item costing N coins ≈ N / (coins-per-100m) * 100 metres of play.
## File lives in the app's user data dir (macOS: ~/Library/Application Support/
## Godot/app_userdata/ORBITS - Cat & Manhole/).
func _log_run(reason: String) -> void:
	var dist_m := int(distance)
	var rec := {
		"time":       Time.get_datetime_string_from_system(),
		"distance_m": dist_m,
		"biome":      _biome_at(dist_m),
		"coins":      stars,               # star pickups (never decremented)
		"shields":    shields_collected,   # lifetime collected this run
		"perfects":   perfects,
		"end":        reason,
	}
	var f := FileAccess.open("user://run_log.jsonl", FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open("user://run_log.jsonl", FileAccess.WRITE)
	else:
		f.seek_end()
	f.store_line(JSON.stringify(rec))
	f.close()

	# roll lifetime aggregates so pricing math needs no log parsing
	var cfg := ConfigFile.new()
	cfg.load("user://orbits.cfg")
	var runs := int(cfg.get_value("stats", "runs", 0)) + 1
	var tot_coins := int(cfg.get_value("stats", "total_coins", 0)) + stars
	var tot_shields := int(cfg.get_value("stats", "total_shields", 0)) + shields_collected
	var tot_m := int(cfg.get_value("stats", "total_meters", 0)) + dist_m
	cfg.set_value("stats", "runs", runs)
	cfg.set_value("stats", "total_coins", tot_coins)
	cfg.set_value("stats", "total_shields", tot_shields)
	cfg.set_value("stats", "total_meters", tot_m)
	cfg.save("user://orbits.cfg")

	# dev readout for economy tuning
	var coins_per_run := float(tot_coins) / float(runs)
	var coins_per_100m := float(tot_coins) / maxf(1.0, float(tot_m)) * 100.0
	print("[run] %dm  coins=%d shields=%d perfects=%d (%s)  |  lifetime: %d runs, %.1f coins/run, %.2f coins/100m" % [
		dist_m, stars, shields_collected, perfects, reason,
		runs, coins_per_run, coins_per_100m])

## Which biome a given altitude falls in (matches the 1500m-per-biome column).
func _biome_at(m: int) -> String:
	if m < 1500:  return "upper_sky"
	if m < 3000:  return "dream_sky"
	if m < 4500:  return "pastel_galaxy"
	if m < 6000:  return "kuiper_belt"
	if m < 7500:  return "oort_cloud"
	if m < 9000:  return "crystal_aurora"
	if m < 10500: return "void_zone"
	if m < 12000: return "forgotten_ruins"
	if m < 13500: return "dark_matter_reef"
	return "beyond"
