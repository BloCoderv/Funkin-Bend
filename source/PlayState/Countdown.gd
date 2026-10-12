extends Timer

@onready var countdown:Sprite2D = $"../UI/HUD/Countdown"
@onready var playstate:PlayState = get_parent()

var counter:int = 0
func countdown_tick() -> void:
	playstate.character_bopper(counter)
	var sound: AudioStream = Global.note_style.get_countdown_sound(counter)
	if sound != null:
		Audio.play(sound, 0.6, "Sfx")
	match counter:
		1, 2, 3:
			show_countdown(Global.note_style.get_countdown_texture(counter))
		4: 
			stop()
			countdown.texture = null
			counter = 0
			get_parent().start_song() # PLAYSTATE
	counter += 1

func show_countdown(texture:Texture2D):
	countdown.texture = texture
	var tw = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(countdown, "modulate:a", 0,
	Conductor.sec_per_beat).set_trans(Tween.TRANS_CUBIC).from(1)
