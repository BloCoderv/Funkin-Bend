extends AnimatedSprite2D


func _ready() -> void:
	modulate.a = Preferences.splash_opacity
	Global.note_style.build_splash_sprite(self)
	animation_finished.connect(_on_splash_finished)

func _set_visual_scale(visual_scale: float) -> void:
	var strum_scale:float = get_parent().scale.x if get_parent() is StrumNote else 1.0
	scale = Vector2.ONE * (visual_scale / strum_scale)

func _set_visual_offset(offsets: Vector2) -> void:
	var strum_scale:float = get_parent().scale.x if get_parent() is StrumNote else 1.0
	position = offsets / strum_scale

func play_note_splash(direction:String) -> void:
	stop()
	_set_visual_scale(Global.note_style.get_splash_scale())
	_set_visual_offset(Global.note_style.get_splash_offsets())
	centered = true
	Global.note_style.build_splash_sprite(self)
	var direction_id := ["Left", "Down", "Up", "Right"].find(direction)
	var candidate_count: int = Global.note_style.get_splash_count(direction_id)
	if candidate_count > 0:
		play(Global.note_style.get_splash_animation(direction_id, randi_range(0, candidate_count - 1)))

func play_hold_cover_splash(direction:int) -> void:
	stop()
	_set_visual_scale(Global.note_style.get_hold_cover_scale())
	_set_visual_offset(Global.note_style.get_hold_cover_offsets())
	centered = true
	Global.note_style.build_hold_cover_sprite(self, direction)
	play(Global.hold_cover_animation(direction, "end"))

func _on_splash_finished() -> void: sprite_frames = null
