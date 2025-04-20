extends Node

var song:Dictionary[String, AudioStream] = {} # INST, VOICES
var song_id:String = "bopeebo" # CAN CHANGE
var song_name:String = "" # bopeebo
var stage:String = "mainStage" # CAN CHANGE

var scroll_speed:float = 0.0 # 1.0
var bpm:float = 0.0 # 100.0
var difficulty:String = "nightmare" # CAN CHANGE

var chart_notes:Array = []
var chart_events:Array = []

var characters:Dictionary = {}

func load_song() -> String:
	var path:String = "res://assets/data/songs/{0}/{0}".format([ song_id ])

	var metadata_file:String = "-metadata-erect.json"
	var chart_file:String = "-chart-erect.json"
	var voices_file:String = "-erect.ogg" # "-erect.ogg"
	var inst_file:String = "Inst-erect.ogg"
	
	if !FileAccess.file_exists( # IF METADATA FILE AND CHART FILE EXISTS
	path + metadata_file) or !FileAccess.file_exists(
	path + chart_file): return "load song err: metadata or chart not found #001" # ELSE
	
	## METADATA
	var json = FileAccess.open(path + metadata_file, FileAccess.READ)
	var metadata = JSON.parse_string(json.get_as_text())
	json.close()
	if !metadata is Dictionary: return "load song err: metadata file json parse error"
	
	## CHART
	json = FileAccess.open(path + chart_file, FileAccess.READ)
	var chart = JSON.parse_string(json.get_as_text())
	json.close()
	if !chart is Dictionary: return "load song err: chart file json parse error"
	
	## METADATA SETUP
	characters = metadata["playData"]["characters"]
	stage = metadata["playData"]["stage"]
	song_name = metadata["songName"]
	bpm = metadata["timeChanges"][0]["bpm"]
	
	## CHART SETUP
	if !chart["notes"].has(
	difficulty) or !chart["scrollSpeed"].has(
	difficulty): return "load song err: not found difficulty"
	
	chart_notes = chart["notes"][difficulty]
	chart_events = chart["events"]
	scroll_speed = chart["scrollSpeed"][difficulty]
	
	NoteGroup.invalid_offset = max(
	Conductor.step_per_beat * 1000, 350 / scroll_speed)
	NoteGroup.load_notes()
	NoteGroup.safe_offset = (Preferences.safe_offset / 60) * 1000
	
	## SONG
	var path_song:String = "res://assets/songs/%s/" % song_id
	
	var voices_player:String = "Voices-%s" % characters["player"]
	var voices_opponent:String = "Voices-%s" % characters["opponent"]
	voices_player += voices_file
	voices_opponent += voices_file
	
	if !FileAccess.file_exists( # IF VOICES EXISTS
	path_song + voices_player) or !FileAccess.file_exists(
	path_song + voices_opponent): return "load song err: voices missing"
	
	song["VoicesPlayer"] = load(path_song + voices_player)
	song["VoicesOpponent"] = load(path_song + voices_opponent)
	song["Inst"] = load(path_song + inst_file)
	
	return ""
