extends Control

func _ready() -> void:
	var result:Dictionary = Global.last_result
	$UI/Title.text = "Resultado"
	$UI/Info.text = "{0}\nScore: {1}\nMisses: {2}\nAccuracy: {3}%".format([
		result.get("song", "Song"),
		result.get("score", 0),
		result.get("misses", 0),
		snappedf(result.get("accuracy", 0.0), 0.01)
	])

func _on_again_pressed() -> void:
	Global.change_scene("res://scenes/SpriteMapLoading.tscn")

func _on_menu_pressed() -> void:
	Global.change_scene("res://scenes/MainMenu.tscn")
