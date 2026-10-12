extends AnimatedSprite2D
class_name StrumNote


@onready var playstate:PlayState = get_tree().current_scene

var note_in_strum:Note = null
var splashes:AnimatedSprite2D = null
var hold_cover:AnimatedSprite2D = null
var data:int = 0
var direction:String = "left"
var opponent:bool = false
var downscroll:bool = false
var visual_state:String = "static"
var hold_cover_active:bool = false
var hold_cover_offset:Vector2 = Vector2.ZERO
var confirm_hold_timer:float = -1.0

const CONFIRM_HOLD_TIME:float = 0.15

func _ready() -> void:
	Global.note_style.build_strum_sprite(self, data)
	
	if opponent and !Preferences.opponent_notes:
		sprite_frames = null
		visible = false
	
	match data:
		1: direction = "down"
		2: direction = "up"
		3: direction = "right"
	
	if sprite_frames:
		animation_finished.connect(_on_animation_finished)
		play_static()
	
	if !opponent or (Preferences.opponent_splashes and Preferences.opponent_notes):
		splashes = Global.SPLASHES_SCENE.instantiate()
		add_child(splashes)
	
	hold_cover = AnimatedSprite2D.new()
	hold_cover.name = "holdCover"
	Global.note_style.build_hold_cover_sprite(hold_cover, data)
	hold_cover_offset = Global.note_style.get_hold_cover_offsets()
	hold_cover.top_level = true
	hold_cover.centered = true
	hold_cover.z_as_relative = false
	hold_cover.z_index = 100
	hold_cover.visible = false
	hold_cover.animation_finished.connect(_on_hold_cover_finished)
	add_child(hold_cover)
	hold_cover.global_position = global_position + hold_cover_offset

func _process(delta:float) -> void:
	if confirm_hold_timer < 0.0:
		return
	confirm_hold_timer += delta
	if confirm_hold_timer >= CONFIRM_HOLD_TIME:
		confirm_hold_timer = -1.0
		play_static()

func play_static() -> void:
	visual_state = "static"
	confirm_hold_timer = -1.0
	_play(direction + "Static")

func play_press() -> void:
	visual_state = "press"
	_play(direction + "Press")

func play_confirm(is_hold:bool = false) -> void:
	visual_state = "confirmHold" if is_hold else "confirm"
	confirm_hold_timer = 0.0 if opponent and !is_hold else -1.0
	_play(direction + ("ConfirmHold" if is_hold else "Confirm"))

func _on_animation_finished() -> void:
	if visual_state != "confirm":
		return
	if opponent:
		return
	if Input.is_action_pressed(Util.NOTE_ACTIONS[data]):
		play_press()
	else:
		play_static()

func _play(animation_key:String, restart:bool = false) -> void:
	# Sem Sprite, Foda-se!
	if !sprite_frames:
		return
	var animation_name: String = Global.note_style.get_strum_animation(animation_key)
	# Sem Animação, Foda-se
	if !sprite_frames.has_animation(animation_name):
		printerr("No animation called '%s'" % animation_name)
		return
	play(animation_name)

func start_hold_cover() -> void:
	if hold_cover == null or !hold_cover.sprite_frames:
		return
	hold_cover_active = true
	hold_cover.visible = true
	hold_cover.global_position = global_position + hold_cover_offset
	hold_cover.play(Global.hold_cover_animation(data, "start"))

func stop_hold_cover(play_end:bool = true) -> void:
	if hold_cover == null:
		return
	hold_cover_active = false
	if play_end and hold_cover.visible:
		hold_cover.play(Global.hold_cover_animation(data, "end"))
	else:
		hold_cover.stop()
		hold_cover.visible = false

func _on_hold_cover_finished() -> void:
	if !hold_cover_active:
		hold_cover.visible = false
		return
	if str(hold_cover.animation).ends_with("_start") \
	or str(hold_cover.animation).ends_with("_hold"):
		hold_cover.play(Global.hold_cover_animation(data, "hold"))

func splash_note() -> void:
	if splashes:
		splashes.play_note_splash(direction.capitalize())

func splash_hold_note() -> void:
	if splashes:
		splashes.play_hold_cover_splash(data)
