extends CanvasLayer
class_name VideoBiomeBackground
## Full-screen looping VIDEO background, rendered behind gameplay.
##
## Godot 4 only plays Ogg Theora (.ogv) video - not MP4. Feed it a .ogv that
## already loops seamlessly (make one with the crossfade recipe in
## tools/make_seamless_loop.sh). Because the file itself loops, VideoStreamPlayer's
## `loop` produces no visible seam.
##
## This is the heavier alternative to AnimatedBiomeBackground (video decode costs
## more on mobile, and Theora is lossier than the source PNG). Use one or the other.

@export var video_stream: VideoStream
@export var background_layer: int = -10

@onready var player: VideoStreamPlayer = $VideoStreamPlayer

func _ready() -> void:
	layer = background_layer
	if video_stream:
		player.stream = video_stream
	player.expand = true      # stretch to the control rect (video is 9:16, so no distortion)
	player.loop = true        # seamless: the .ogv's last frame ~= its first frame
	_fit()
	get_viewport().size_changed.connect(_fit)
	if not player.is_playing():
		player.play()
	# Fallback for any build/format that ignores `loop`: restart on finish.
	if not player.finished.is_connected(_on_finished):
		player.finished.connect(_on_finished)

func _on_finished() -> void:
	player.play()

## Fit the player to the viewport. The bundled clip is 1080x1920 (9:16), matching
## the mobile viewport, so a straight stretch keeps the aspect ratio. For a clip
## of a different aspect, letterboxing/cropping would need extra handling.
func _fit() -> void:
	var vp := get_viewport().get_visible_rect().size
	player.position = Vector2.ZERO
	player.size = vp
