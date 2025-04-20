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
	# DIRECTION
	match data:
		# 0: "Left"
		1: direction = "Down"
		2: direction = "Up"
		3: direction = "Right"
	play_anim("static")
	
	if !opponent or Preferences.opponent_splashes:
		splashes_setup()

func splashes_setup():
	splashes = AnimatedSprite2D.new()
	splashes.sprite_frames = Global.SPLASHES_TEXTURE
	splashes.modulate.a = Preferences.splash_opacity
	splashes.visible = false
	splashes.animation_finished.connect(
		func():
			splashes.visible = false
	)
	splashes.scale = Vector2(1.3, 1.3)
	add_child(splashes)

func _process(delta):
	if reset_time > 0:
		reset_time -= delta
		if reset_time <= 0:
			reset_time = 0.0
			play_anim("static")

# PLAYER STUFF
func _input(event):
	if opponent or playstate.botplay: return
	
	if Input.is_action_just_pressed("note%s" % data):
		if note_in_strum:
			playstate.player_hit(note_in_strum)
		else:
			play_anim("press")
	if Input.is_action_just_released("note%s" % data):
		play_anim("static")
		if note_in_strum:
			NoteGroup.check_sustain_hit(note_in_strum, get_tree().current_scene)

func play_anim(anim:String):
	var anim_to_play:String = anim + direction
	if sprite_frames.has_animation(anim_to_play):
		play(anim_to_play)

func splash_note():
	if !splashes: return
	
	splashes.visible = true
	var id = randi_range(1, 2)
	splashes.play("noteImpact{0}{1}".format([ direction, id ]))

func splash_hold_note():
	pass
