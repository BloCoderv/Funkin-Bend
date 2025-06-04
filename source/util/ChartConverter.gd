extends Control

@onready var type_option:OptionButton = $Type

@onready var path:Button = $Path

@onready var file_dialog:FileDialog = $FileDialog

@onready var mix:LineEdit = $Mix

@onready var info_label = $InfoLabel

@onready var convert_btn = $Convert

const PATH_PLACEHOLDER = "Data Path : "

var delete_files:bool = false

func _ready():
	info_label.modulate.a = 0.0

func convert_data():
	var type:String = type_option.get_item_text(type_option.selected)
	var dir_path:String = file_dialog.current_dir
	
	if type == "NEW":
		if mix.text != "":
			mix.text = "-" + mix.text
		
		var song = dir_path.get_file()
		
		var meta_path = dir_path.path_join(song + "-metadata%s.json" % mix.text)
		var chart_path = dir_path.path_join(song + "-chart%s.json" % mix.text)
		
		if !FileAccess.file_exists(meta_path) or \
		!FileAccess.file_exists(chart_path): 
			show_error("Metadata or Chart not exists")
			return
		
		var song_data:SongData = SongData.convert_to_bend(meta_path, chart_path)
		ResourceSaver.save(song_data, 
			dir_path.path_join("Data%s.tres" % mix.text))
		
		if delete_files:
			DirAccess.remove_absolute(meta_path)
			DirAccess.remove_absolute(chart_path)
		
		mix.text = mix.text.substr(1)
		
		success_msg()
	
	elif type == "PSYCH" or type == "OLD":
		var files = DirAccess.get_files_at(dir_path)
		var song = dir_path.get_file()
		var diffs:Array[String] = []
		var ev_path:String = ""
		
		for f in files:
			var d:String = f.get_basename().split("-")[-1]
			var file = dir_path.path_join(song + "-" + d + ".json")
			if FileAccess.file_exists(file):
				diffs.append(d)
		
		if diffs.size() == 0:
			show_error("There are no charts in the current directory")
			return
		
		if FileAccess.file_exists(dir_path.path_join("events.json")):
			ev_path = dir_path.path_join("events.json")
		
		var song_data:SongData = SongData.convert_to_bend_from_old(
			dir_path.path_join(song), diffs, ev_path)
		ResourceSaver.save(song_data, dir_path.path_join("Data.tres"))
		
		if delete_files:
			for i in files:
				DirAccess.remove_absolute(dir_path.path_join(i))
		
		success_msg()

func show_error(err:String):
	info_label.modulate.a = 1.0
	info_label.text = err
	
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(info_label, "modulate:a", 0.0, 2).set_delay(2)

func success_msg():
	info_label.modulate.a = 1.0
	info_label.text = "Success!"
	
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(info_label, "modulate:a", 0.0, 2).set_delay(2)

# PATH
func _path_pressed():
	file_dialog.show()
	path.text = PATH_PLACEHOLDER + "..."

# FILE DIALOG - PATH
func _on_file_dialog_confirmed():
	path.text = PATH_PLACEHOLDER + file_dialog.current_dir

func _on_file_dialog_canceled():
	path.text = PATH_PLACEHOLDER + file_dialog.current_dir

# DELETE FILES
func _on_del_files_toggled(toggled_on):
	delete_files = toggled_on

# ON CHART TYPE CHANGED
func _on_type_item_selected(index):
	if type_option.get_item_text(index) != "NEW":
		mix.visible = false
	else:
		mix.visible = true

# ON CONVERT PRESS
func _on_convert_pressed():
	convert_data()
