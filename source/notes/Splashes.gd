extends AnimatedSprite2D


func _ready() -> void:
	modulate.a = Preferences.splash_opacity
	scale = Vector2(Util.SPLASHES_SCALE, Util.SPLASHES_SCALE)
	animation_finished.connect(_on_splash_finished)

func play_note_splash(direction:String) -> void:
	stop()
	sprite_frames = Global.SPLASHES_TEXTURE
	var id = randi_range(1, 2)
	play("noteImpact{0}{1}".format([ direction, id ]))

func play_hold_cover_splash(direction:int) -> void:
	stop()
	sprite_frames = Global.HOLD_COVER_TEXTURE
	var color:String = "Purple"
	match direction:
		# 0: color = "Purple"
		1: color = "Blue"
		2: color = "Green"
		3: color = "Red"
	play("holdCoverEnd" + color)

func _on_splash_finished() -> void: sprite_frames = null
