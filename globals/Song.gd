extends Node

var song:Dictionary[String, AudioStream] = {} # Inst, VoicesPlayer, VoicesOpponent

var song_name:String = ""

var song_id:String = "lit-up" # CAN CHANGE
var song_mix:String = "bf" # CAN CHANGE

var stage:String = "mainStage"

var scroll_speed:float = 0.0 # 1.0
var bpm:float = 0.0 # 100.0
var difficulty:String = "hard" # CAN CHANGE

var chart_times:Array = []
var chart_notes:Array = []
var chart_events:Dictionary[String, Array] = {
	"Funkin": [],
	"Psych": []
}

var characters:Dictionary = {}

var dual_voices:bool = true

func load_song() -> String: # -> ERROR
	var mix:String = ""
	if song_mix != "":
		mix = "-" + song_mix
	
	var data_path = "res://assets/data/songs/{0}/Data{1}.tres".format(
		[ song_id, mix ])
	var audio_path = "res://assets/songs/%s" % song_id
	
	if !FileAccess.file_exists(data_path): return "Song data not exists"
	
	var data:SongData = ResourceLoader.load(
		data_path, "Resource", ResourceLoader.CACHE_MODE_IGNORE)
	
	bpm = data.bpm
	characters = data.characters
	stage = data.stage
	song_name = data.display_name
	chart_times = data.times
	chart_events = data.events
	
	if !data.scroll_speed.has(difficulty): 
		return "There is no chart for the current difficulty"
	scroll_speed = data.scroll_speed[difficulty]
	
	if !data.charts.has(difficulty):
		return "There is no chart for the current difficulty"
	chart_notes = data.charts[difficulty]
	
	# SETUP
	
	NoteGroup.invalid_offset = max(
		Conductor.beat_step * 1000, 350 / scroll_speed)
	NoteGroup.load_notes()
	NoteGroup.safe_offset = (Preferences.safe_offset / 60) * 1000
	
	# AUDIO
	
	var v_player = audio_path.path_join(
		"Voices-{0}{1}.ogg".format([ characters["player"], mix ]))
	var v_opp = audio_path.path_join(
		"Voices-{0}{1}.ogg".format([ characters["opponent"], mix ]))
	
	var voices = audio_path.path_join("Voices.ogg")
	var inst = audio_path.path_join("Inst%s.ogg" % mix)
	
	if !FileAccess.file_exists(inst): return "Inst not exists"
	song["Inst"] = load(inst)
	
	var voices_exists:bool = FileAccess.file_exists(v_player) \
		and FileAccess.file_exists(v_opp)
	
	if !voices_exists and FileAccess.file_exists(voices):
		song["VoicesPlayer"] = load(voices)
		dual_voices = false
		return ""
	elif voices_exists:
		song["VoicesPlayer"] = load(v_player)
		song["VoicesOpponent"] = load(v_opp)
		return ""
	else: 
		return "Voices not exists"
	
	return ""
