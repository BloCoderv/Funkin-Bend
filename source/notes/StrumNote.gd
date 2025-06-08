extends AnimatedSprite2D
class_name StrumNote

@onready var playstate:PlayState = get_tree().current_scene

var note_in_strum:Note = null
var splashes:AnimatedSprite2D = null

var data:int = 0
var direction:String = "Left"

var opponent:bool = false
var downscroll:bool = false

var reset_time:float = 0.0 # RETURN TO 'STATIC' ANIMATION

func _ready():
	# TEXTURE
	sprite_frames = Global.STRUM_NOTES
	
	match data:
		1: direction = "Down"
		2: direction = "Up"
		3: direction = "Right"
	
	play_anim("static")
	
	if !opponent or (Preferences.opponent_splashes
	and Preferences.opponent_notes):
		splashes = Global.SPLASHES_SCENE.instantiate()
		add_child(splashes)

func _process(delta):
	if reset_time > 0:
		reset_time -= delta
		if reset_time <= 0:
			reset_time = 0.0
			play_anim("static")

# PLAYER STUFF
var note_was_hit:bool = false
func _unhandled_input(event):
	if event == InputEventMouse \
	or opponent or playstate.botplay: return
	
	if Input.is_action_just_pressed("note%s" % data):
		if note_in_strum: playstate.player_hit(note_in_strum)
		else: 
			if !Preferences.ghost_tapping: playstate.miss_note(data)
			play_anim("press")
	if Input.is_action_just_released("note%s" % data):
		play_anim("static")
		
		if note_was_hit:
			note_was_hit = false
			playstate.characters["player"].hold_time = 0.0
			playstate.characters["player"].is_holding = false
		
		if note_in_strum and note_in_strum.is_sustain:
			NoteGroup.check_sustain_hit(note_in_strum, get_tree().current_scene)

func play_anim(anim:String):
	if !sprite_frames: return
	
	var anim_to_play:String = anim + direction
	if sprite_frames.has_animation(anim_to_play):
		play(anim_to_play)

func splash_note():
	if splashes:
		splashes.play_note_splash(direction)

func splash_hold_note():
	if splashes:
		splashes.play_hold_cover_splash(data)
