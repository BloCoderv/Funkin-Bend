extends AnimatedSprite2D
class_name StrumNote

@onready var playstate:PlayState = get_tree().current_scene

var note_in_strum:Note = null
var splash:AnimatedSprite2D = null

var data:int = 0

var opponent:bool = false
var downscroll:bool = false

var reset_time:float = 0.0 # RETURN TO 'STATIC' ANIMATION

func _ready():
	play("strum%s" % data)
	if !opponent or Preferences.opponent_splashes:
		splash_setup()

func splash_setup():
	splash = AnimatedSprite2D.new()
	splash.sprite_frames = playstate.SPLASHES_TEXTURE
	splash.modulate.a = Preferences.splash_opacity
	splash.visible = false
	splash.animation_finished.connect(
		func():
			splash.visible = false
	)
	splash.scale = Vector2(1.3, 1.3)
	add_child(splash)

func _process(delta):
	if reset_time > 0:
		reset_time -= delta
		if reset_time <= 0:
			reset_time = 0.0
			play("strum%s" % data)

func _input(event):
	if opponent or playstate.botplay: return
	
	if Input.is_action_just_pressed("note%s" % data):
		if note_in_strum:
			playstate.player_hit(note_in_strum)
		else:
			play("press%s" % data)
	if Input.is_action_just_released("note%s" % data):
		play("strum%s" % data)
		if note_in_strum:
			NoteGroup.check_sustain_hit(note_in_strum, get_tree().current_scene)

func splash_note():
	if !splash: return
	
	splash.visible = true
	var color = "purple"
	var id = randi_range(1, 2)
	match data:
		1: color = "blue"
		2: color = "green"
		3: color = "red"
	splash.play("note impact {0} {1}".format([ id, color ]))
