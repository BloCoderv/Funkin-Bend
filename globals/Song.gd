extends Node

var song:Dictionary[String, AudioStream] = {} # Inst, VoicesPlayer, VoicesOpponent

var song_name:String = ""

var song_id:String = "dadbattle"
var song_mix:String = ""
var difficulty:String = "hard"

var stage:String = "mainStage"

var scroll_speed:float = 0.0 # 1.0
var bpm:float = 0.0 # 100.0

var chart_times:Array = []
var chart_notes:Array = []

var chart_events:Dictionary[String, Array] = {
	"Funkin": [],
	"Bend": []
}

var characters:Dictionary = {}

func configure(new_song_id:String, new_mix:String = "", new_difficulty:String = "hard") -> void:
	song_id = new_song_id.strip_edges()
	song_mix = new_mix.strip_edges().trim_prefix("-")
	difficulty = new_difficulty.strip_edges().to_lower()

func load_song() -> String: # -> ERROR
	song.clear()
	var mix:String = ""
	if song_mix != "":
		mix = "-" + song_mix
	
	var metadata_path := "res://assets/data/songs/%s/%s-metadata%s.json" % [song_id, song_id, mix]
	var chart_path := "res://assets/data/songs/%s/%s-chart%s.json" % [song_id, song_id, mix]
	var audio_path = "res://assets/songs/%s" % song_id
	
	if !FileAccess.file_exists(metadata_path) or !FileAccess.file_exists(chart_path):
		return "FNF metadata or chart not found"
	var data:SongData = SongData.from_fnf_json(metadata_path, chart_path)
	if data == null: return "Could not load song data"
	
	bpm = data.bpm
	# Funkin metadata stores non-character values such as altInstrumentals in
	# playData.characters. Keep only the three slots the play state can load.
	characters = {}
	for slot in ["player", "opponent", "girlfriend"]:
		var character_id = data.characters.get(slot)
		if character_id is String and !character_id.is_empty():
			characters[slot] = character_id
	for required in ["player", "opponent", "girlfriend"]:
		if !characters.has(required):
			return "Song data missing character: %s" % required
	stage = data.stage
	Global.load_note_style(data.note_style)
	song_name = data.display_name
	chart_times = data.times.duplicate()
	chart_times.sort_custom(_sort_timing)
	chart_events = data.events
	
	if !data.charts.has(difficulty):
		return "There is no chart for the current difficulty"
	if !data.scroll_speed.has(difficulty):
		return "scrollSpeed has no value for difficulty: %s" % difficulty
	scroll_speed = float(data.scroll_speed[difficulty])
	if scroll_speed <= 0.0:
		return "Song has an invalid scroll speed"

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
	if song["Inst"] == null: return "Could not load instrumental"
	
	var voices_exists:bool = FileAccess.file_exists(v_player) \
		and FileAccess.file_exists(v_opp)
	
	if !voices_exists and FileAccess.file_exists(voices):
		song["VoicesPlayer"] = load(voices)
		return ""
	elif voices_exists:
		song["VoicesPlayer"] = load(v_player)
		song["VoicesOpponent"] = load(v_opp)
		return ""
	else: 
		return "Voices not exists"

static func _sort_timing(first: Array, second: Array) -> bool:
	return float(first[0]) < float(second[0])
