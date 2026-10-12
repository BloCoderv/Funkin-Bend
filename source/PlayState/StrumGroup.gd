extends Node
class_name StrumGroup

const STRUM_NOTE_SCENE = preload("res://scenes/notes/StrumNote.tscn")

const SIZE: float = Util.STRUMLINE_NOTE_SIZE
const SEPARATION: float = Util.STRUMLINE_SEPARATION
const SCALE: float = Util.STRUMLINE_DEFAULT_SCALE
const MARGIN: float = Util.STRUMLINE_MARGIN
const MANIA: int = Util.STRUMLINE_MANIA

static var strum_notes:Array[StrumNote] = []
static var opponent_strums:Array[StrumNote] = []
static var player_strums:Array[StrumNote] = []

func generate_strums() -> void:
	var separation:float = (SIZE + SEPARATION) * SCALE
	
	## PLAYER
	var x:int = int( Global.SCREEN_SIZE.x - MARGIN - (separation * MANIA) )
	
	if Preferences.middlescroll:
		x = int( (Global.SCREEN_SIZE.x / 2) - (separation * (MANIA + 1)) / 2 )
		x += int( separation / 2 )
	
	var strum_y: float = Util.STRUMLINE_Y_MARGIN
	if Preferences.downscroll: strum_y = Global.SCREEN_SIZE.y - Util.STRUMLINE_Y_MARGIN
	
	generate_new_strum(Vector2(x, strum_y), false)
	
	## OPPONENT
	var margin:float = MARGIN
	
	if Preferences.middlescroll:
		var sep:float = (SEPARATION + SIZE) * 0.5
		margin = (x / 2) - (sep * (MANIA + 1)) / 2
	
	generate_new_strum(Vector2(margin , strum_y), true)
	
	# STRUMLINE BG
	if Preferences.strumline_bg == 0.0: return
	
	var strum_bg:ColorRect = ColorRect.new()
	add_child(strum_bg)
	strum_bg.name = "StrumLine Background"
	strum_bg.color = Color.BLACK
	strum_bg.color.a = Preferences.strumline_bg
	
	strum_bg.position.x = int(x - separation / 2.0)
	strum_bg.size.x = int(separation * (MANIA + 1))
	strum_bg.position.x -= Util.STRUMLINE_BACKGROUND_MARGIN / 2.0
	strum_bg.size.x += Util.STRUMLINE_BACKGROUND_MARGIN
	
	strum_bg.size.y = Global.SCREEN_SIZE.y

func generate_new_strum(
offset:Vector2, opponent:bool, mania:int = 3) -> void:
	for strum in range(mania + 1):
		var new:StrumNote = STRUM_NOTE_SCENE.instantiate()
		
		new.position = offset
		new.data = strum
		var style_scale: float = Global.note_style.get_strumline_scale()
		new.scale = Vector2.ONE * style_scale
		new.position += Global.note_style.get_strumline_offsets()
		new.downscroll = Preferences.downscroll
		new.opponent = opponent
		new.z_index = 4 if !Preferences.notes_behind_strum else 5
		new.self_modulate.a = Preferences.strums_opacity
		
		# WITHOUT OPPONENT NOTES
		if new.opponent and !Preferences.opponent_notes:
			new.visible = false
			new.sprite_frames = null
		
		# MIDDLESCROLL
		if new.opponent and Preferences.middlescroll:
			new.scale = Vector2.ONE * Util.MIDDLESCROLL_SCALE
		
		var separation:float = (SIZE + SEPARATION) * new.scale.x
		new.position.x += strum * separation
		
		# INSTANTIATE
		add_child(new)
		strum_notes.append(new)
		if !opponent: player_strums.append(new)
		else: opponent_strums.append(new)

static func clear_strumlines() -> void:
	for strum in strum_notes: 
		if is_instance_valid(strum):
			strum.note_in_strum = null
			strum.queue_free()
	strum_notes = []
	opponent_strums = []
	player_strums = []
