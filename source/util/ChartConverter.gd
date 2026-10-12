extends Control


@onready var path:Button = $Path
@onready var mix:LineEdit = $Mix

@onready var file_dialog:FileDialog = $FileDialog

@onready var info_label:Label = $InfoLabel
@onready var animation:AnimationPlayer = $Animation

@onready var convert_btn:Button = $Convert

const PATH_PLACEHOLDER = "Data Path | "

var delete_files:bool = false

func convert_data():
	var dir_path:String = file_dialog.current_dir
	if mix.text != "":
		mix.text = "-" + mix.text
	var song = dir_path.get_file()
	var meta_path = dir_path.path_join(song + "-metadata%s.json" % mix.text)
	var chart_path = dir_path.path_join(song + "-chart%s.json" % mix.text)
	if !FileAccess.file_exists(meta_path) or !FileAccess.file_exists(chart_path):
		show_error("Metadata or Chart not exists")
		return
	var song_data:SongData = SongData.from_fnf_json(meta_path, chart_path)
	if song_data == null:
		push_error("Chart JSON could not be parsed")
		return
	print("JSON FNF válido: %s" % song_data.display_name)
	mix.text = mix.text.substr(1)
	success_msg()

func show_error(err:String):
	info_label.modulate.a = 1.0
	info_label.text = err
	animation.play("InfoFadeOut")

func success_msg():
	info_label.modulate.a = 1.0
	info_label.text = "Success!"
	animation.play("InfoFadeOut")

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

# ON CONVERT PRESS
func _on_convert_pressed():
	convert_data()
