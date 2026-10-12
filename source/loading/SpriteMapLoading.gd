extends Control
class_name SpriteMapLoading

const PLAY_STATE_SCENE:String = "res://scenes/PlayState.tscn"
const MAIN_MENU_SCENE:String = "res://scenes/MainMenu.tscn"

@onready var status:Label = $Center/Panel/Status
@onready var progress:ProgressBar = $Center/Panel/Progress

var maps:Array[SpriteMap] = []

func _ready() -> void:
	call_deferred("_prepare_play_state")

func _prepare_play_state() -> void:
	var error := Song.load_song()
	if error:
		push_error("SONG LOAD ERROR: %s" % error)
		Global.change_scene(MAIN_MENU_SCENE)
		return

	var character_names:Array[String] = []
	for character_name in Song.characters.values():
		var name := str(character_name)
		if !character_names.has(name):
			character_names.append(name)

	var girlfriend_name := str(Song.characters["girlfriend"])
	if !character_names.has(girlfriend_name):
		character_names.append(girlfriend_name)

	for index in range(character_names.size()):
		var data:CharacterData = _load_character_data(character_names[index])
		if data == null or data.sprite_map_path.is_empty():
			continue
		var map := SpriteMap.new()
		add_child(map)
		map.configure(data.sprite_map_path, data.sprite_map_animations)
		maps.append(map)

	progress.max_value = maxi(1, maps.size())
	for index in range(maps.size()):
		var map:SpriteMap = maps[index]
		status.text = "Preparando sprites {0}/{1}".format([index + 1, maps.size()])
		progress.value = index
		map.bake_progress.connect(func(value:float):
			progress.value = float(index) + value)
		await map.prepare()
		progress.value = index + 1

	status.text = "Sprites prontos"
	await get_tree().process_frame
	Global.change_scene(PLAY_STATE_SCENE)

func _load_character_data(character_name:String) -> CharacterData:
	return CharacterData.load_character_data(character_name)
