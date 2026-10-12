extends Resource
class_name SongData

@export var display_name:String = "" # Bopeebo

@export var bpm:float = 100.0
@export var scroll_speed:Dictionary = {}

@export var charts:Dictionary = {}
@export var events:Dictionary[String, Array] = {
	"Funkin": [],
	"Bend": []
}
@export var times:Array = []

@export var characters:Dictionary = {}
@export var stage:String = "mainStage"
@export var note_style:String = "funkin"

@export var needs_voices:bool = true

static func from_fnf_json(meta_path:String, chart_path:String) -> SongData:
	var meta_file := FileAccess.open(meta_path, FileAccess.READ)
	var chart_file := FileAccess.open(chart_path, FileAccess.READ)
	if meta_file == null or chart_file == null:
		return null
	var meta = JSON.parse_string(meta_file.get_as_text())
	var chart = JSON.parse_string(chart_file.get_as_text())
	if !(meta is Dictionary) or !(chart is Dictionary):
		return null
	var play_data:Dictionary = meta.get("playData", {})
	var result := SongData.new()
	result.display_name = str(meta.get("songName", meta_path.get_file().get_basename()))
	result.characters = play_data.get("characters", {})
	result.stage = str(play_data.get("stage", "mainStage"))
	result.note_style = str(play_data.get("noteStyle", "funkin")).to_lower()
	var changes:Array = meta.get("timeChanges", [])
	if !changes.is_empty():
		result.bpm = float(changes[0].get("bpm", 100.0))
	for change in changes:
		result.times.append([float(change.get("t", 0.0)), int(round(float(change.get("b", 4.0)) * 4.0)), float(change.get("bpm", result.bpm))])
	var raw_scroll_speed = chart.get("scrollSpeed", {})
	result.scroll_speed = {}
	if typeof(raw_scroll_speed) == TYPE_DICTIONARY:
		for speed_name in raw_scroll_speed.keys():
			result.scroll_speed[str(speed_name).to_lower()] = float(raw_scroll_speed[speed_name])
	elif typeof(raw_scroll_speed) in [TYPE_FLOAT, TYPE_INT]:
		# Keep support for charts that intentionally publish one global speed.
		result.scroll_speed["hard"] = float(raw_scroll_speed)
	for event in chart.get("events", []):
		result.events["Funkin"].append([event.get("t", 0.0), event.get("e", ""), event.get("v", {})])
	for difficulty in chart.get("notes", {}):
		var difficulty_name := str(difficulty).to_lower()
		result.charts[difficulty_name] = []
		for note in chart["notes"][difficulty]:
			result.charts[difficulty_name].append([float(note.get("t", 0.0)), int(note.get("d", 0)), float(note.get("l", 0.0))])
	return result
