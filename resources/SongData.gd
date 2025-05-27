extends Resource
class_name SongData

@export var display_name:String = "" # Bopeebo

@export var bpm:float = 100.0
@export var scroll_speed:Dictionary = {}

@export var charts:Dictionary = {}
@export var events:Dictionary[String, Array] = {
	"Funkin": [],
	"Psych": []
}
@export var times:Array = []

@export var characters:Dictionary = {}
@export var stage:String = "mainStage"

@export var needs_voices:bool = true

static func convert_to_bend_from_old(
	path:String, difficulties:Array[String],
	events_path:String = ""
) -> SongData : # FNF 0.2.7 or Psych Engine
	var json = FileAccess.open(
		path + "-" + difficulties[0] + ".json", FileAccess.READ)
	var data = JSON.parse_string(json.get_as_text()) as Dictionary
	json.close()
	
	var res:SongData = SongData.new()
	if FileAccess.file_exists(path.get_base_dir() + "/Data.tres"):
		DirAccess.remove_absolute(path.get_base_dir() + "/Data.tres")
	
	res.display_name = data["song"]["song"]
	
	var gf:String = data["song"]["gfVersion"]
	
	res.characters = {
		"player": data["song"]["player1"],
		"girlfriend": gf if gf != "" else "gf",
		"opponent": data["song"]["player2"]
	}
	res.stage = data["song"]["stage"]
	res.bpm = data["song"]["bpm"]
	res.needs_voices = data["song"]["needsVoices"]
	
	for diff in difficulties:
		json = FileAccess.open(path + "-" + diff + ".json", FileAccess.READ)
		data = JSON.parse_string(json.get_as_text()) as Dictionary
		json.close()
		
		res.scroll_speed[diff] = data["song"]["speed"]
		res.times = []
		res.events["Funkin"] = []
		
		## CHART
		
		res.charts[diff] = []
		
		var count:int = 0
		for section in data["song"]["notes"]:
			var section_ms:float = (60.0 / res.bpm) * 4 * count * 1000
			
			if section.has("bpm") and section.has("changeBPM") \
			and section["changeBPM"]:
				res.times.append([section_ms, section["bpm"]])
			
			res.events["Funkin"].insert(count, [
				section_ms, "FocusCamera",
				(0 if section["mustHitSection"] else 1)
			])
			
			for note in section["sectionNotes"]:
				var n:Array = note
				if !section["mustHitSection"]:
					n[1] += 4 if n[1] < 4 else -4
				res.charts[diff].append(n)
			count += 1
		
	if !data["song"].has("events"): return
	
	## EVENTS
	
	if events_path:
		json = FileAccess.open(events_path, FileAccess.READ)
		data = JSON.parse_string(json.get_as_text()) as Dictionary
		json.close()
	
	for ev_time in data["song"]["events"]:
		for event in ev_time[1]:
			res.events["Psych"].append([
				ev_time[0], event[0], event[1], event[2]
				# TIME, EVENT, VALUE 1, VALUE 2
			])
	
	return res

static func convert_to_bend(
	meta_path:String, chart_path:String
) -> SongData : # FNF 0.3+                                                                                                                    
	var json = FileAccess.open(meta_path, FileAccess.READ)
	var meta = JSON.parse_string(json.get_as_text())
	json.close()
	
	json = FileAccess.open(chart_path, FileAccess.READ)
	var chart = JSON.parse_string(json.get_as_text())
	json.close()
	
	var res:SongData = SongData.new()
	
	res.display_name = meta["songName"]
	
	res.characters = meta["playData"]["characters"]
	res.bpm = meta["timeChanges"][0]["bpm"]
	res.scroll_speed = chart["scrollSpeed"]
	res.stage = meta["playData"]["stage"]
	
	res.events["Funkin"] = chart["events"]
	
	for diff in chart["notes"]:
		for note in chart["notes"][diff]:
			var values:Array = [note["t"], note["d"], 0.0]
			values[2] = 0.0 if !note.has("l") else note["l"]
			
			if !res.charts.has(diff):
				res.charts[diff] = []
			res.charts[diff].append(values)
	
	for change in meta["timeChanges"]:
		# TO ARRAY
		res.times.append([change["t"], change["bpm"]])
	
	return res
