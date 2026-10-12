extends Node2D

const UPDATE_INTERVAL: float = 0.25
const MARGIN: Vector2 = Vector2(20.0, 20.0)
const FONT_SIZE: int = 16
const TEXT_COLOR: Color = Color.WHITE
const BACKGROUND_COLOR: Color = Color(0.0, 0.0, 0.0, 0.50)
const BORDER_RADIUS: int = 8

var _time_until_update: float = 0.0
var _fps_text: String = "FPS: 0"
var _font: Font
var rect:StyleBoxFlat

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	top_level = true
	z_index = 4096
	_font = ThemeDB.fallback_font
	
	rect = StyleBoxFlat.new()
	rect.bg_color = BACKGROUND_COLOR
	rect.corner_radius_top_left = BORDER_RADIUS
	rect.corner_radius_top_right = BORDER_RADIUS
	rect.corner_radius_bottom_left = BORDER_RADIUS
	rect.corner_radius_bottom_right = BORDER_RADIUS
	
	queue_redraw()


var toggle:bool = false
func _physics_process(delta: float) -> void:
	queue_redraw()
	if Input.is_action_just_pressed("toggle_fps"): toggle = !toggle

func _process(delta: float) -> void:
	_time_until_update -= delta
	if _time_until_update > 0.0:
		return
	_time_until_update = UPDATE_INTERVAL
	_fps_text = "FPS: %d" % Engine.get_frames_per_second()

func _draw() -> void:
	if _font == null or !toggle:
		return

	var canvas_inverse := get_viewport().get_canvas_transform().affine_inverse()

	draw_set_transform(
		canvas_inverse.origin,
		canvas_inverse.get_rotation(),
		canvas_inverse.get_scale()
	)

	var rect := Rect2(Vector2(8, 8), Vector2(100, 30))

	draw_rect(rect, Color(0, 0, 0, 0.65))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(16, 29),
		"FPS: %d" % Engine.get_frames_per_second(),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color.WHITE
	)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	#var screen_position = MARGIN
	#
	#var canvas_inverse = get_viewport().get_canvas_transform().affine_inverse() * screen_position
	#draw_set_transform(
		#canvas_inverse.origin,
		#canvas_inverse.get_rotation(),
		#canvas_inverse.get_scale()
	#)
	#
	#var draw_position = canvas_position - Vector2(8.0, 8.0)
	#var text_size = _font.get_string_size(_fps_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	#var background_rect = Rect2(draw_position, text_size + Vector2(8.0, 8.0))
#
	#draw_style_box(rect, background_rect)
	#draw_string(_font, draw_position + Vector2(4.0, 22.0), _fps_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT_COLOR)
