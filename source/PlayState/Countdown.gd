extends Timer

@onready var countdown = $"../UI/HUD/Countdown"

var counter:int = -1
func countdown_tick():
	counter += 1
	match counter:
		0: Audio.play(ResourceLoader.load(
				"res://assets/sounds/countdown/introTHREE.ogg", 
				"AudioStream", ResourceLoader.CACHE_MODE_IGNORE), 0.6, "Sfx")
		1: 
			Audio.play(ResourceLoader.load(
				"res://assets/sounds/countdown/introTWO.ogg", 
				"AudioStream", ResourceLoader.CACHE_MODE_IGNORE), 0.6, "Sfx")
			show_countdown(ResourceLoader.load(
				"res://assets/images/ui/intro/ready.png", 
				"AudioStream", ResourceLoader.CACHE_MODE_IGNORE))
		2: 
			Audio.play(ResourceLoader.load(
				"res://assets/sounds/countdown/introONE.ogg", 
				"AudioStream", ResourceLoader.CACHE_MODE_IGNORE), 0.6, "Sfx")
			show_countdown(ResourceLoader.load(
				"res://assets/images/ui/intro/set.png", 
				"AudioStream", ResourceLoader.CACHE_MODE_IGNORE))
		3: 
			Audio.play(ResourceLoader.load(
				"res://assets/sounds/countdown/introGO.ogg", 
				"AudioStream", ResourceLoader.CACHE_MODE_IGNORE), 0.6, "Sfx")
			show_countdown(ResourceLoader.load(
				"res://assets/images/ui/intro/go.png", 
				"AudioStream", ResourceLoader.CACHE_MODE_IGNORE))
		4: 
			stop()
			countdown.queue_free()
			get_parent().start_song() # PLAYSTATE

func show_countdown(texture:Texture2D):
	countdown.texture = texture
	var tw = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(countdown, "modulate:a", 0,
	Conductor.sec_per_beat).set_trans(Tween.TRANS_CUBIC).from(1)
