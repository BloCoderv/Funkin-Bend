extends Node2D
class_name PlayState

# PRELOAD
const SPLASHES_TEXTURE = preload("res://assets/images/ui/noteSplashes.tres")

# VOICES
@onready var voices_opponent = $VoicesOpponent
@onready var voices_player = $VoicesPlayer

# GROUPS
@onready var note_group = $UI/NoteGroup
@onready var strum_group = $UI/StrumGroup

var botplay:bool = false

func _ready():
	strum_group.generate_strums()
	
	var err:String = Song.load_song()
	if err: OS.alert(err, "SONG LOAD ERROR")
	
	for i in Song.song.keys():
		if i == "Inst": continue
		var child = find_child(i)
		child.stream = Song.song[i]
		child.play()
	Conductor.stream = Song.song["Inst"]
	Conductor.set_bpm(Song.bpm)
	Conductor.play()

func judge_note(diff) -> Dictionary:
	for i in Preferences.judge_window.keys():
		var window = Preferences.judge_window[i]
		if window > diff:
			var percent:float = 1.0
			match i:
				"good":
					percent = .67
				"bad": 
					percent = .34
			return {"name": i, "percent": percent}
	return {"name": "shit", "percent": 0.0}

func player_hit(note:Note):
	var strum = StrumGroup.player_strums[note.data]
	strum.play("confirm%s" % strum.data)
	
	note.was_hit = true
	if note.is_sustain: 
		note.is_holding = true
		note.self_modulate.a = 0.0
	else: NoteGroup.remove_note(note)
	# RATING
	var rating:Dictionary = judge_note(abs(Conductor.song_position - note.time))
	if rating["percent"] == 1:
		strum.splash_note()

func opponent_hit(note:Note):
	var strum = StrumGroup.player_strums[note.data]
	if Preferences.opponent_hit:
		strum.play("confirm%s" % strum.data)
	note.was_hit = true
	if note.is_sustain: 
		note.is_holding = true
		note.self_modulate.a = 0.0
	else: NoteGroup.remove_note(note)
	strum.splash_note()

func miss_note(note:Note, kill:bool = false):
	if kill:
		NoteGroup.remove_note(note)
