extends Node

## TEMPORARY DEBUG SCRIPT.
## Attach this script to a node in PlayState, run once, then remove it.

const OUTPUT_PATH:String = "res://_TEMP_StrumAnimationFrames.tres"
static var saved_this_run:bool = false

func _ready() -> void:
	await get_tree().process_frame
	_save_strum_frames_once()

func _save_strum_frames_once() -> void:
	if saved_this_run:
		return
	saved_this_run = true
	if FileAccess.file_exists(OUTPUT_PATH):
		print("TEMP: file already exists, not overwriting: %s" % OUTPUT_PATH)
		return
	if StrumGroup.strum_notes.is_empty():
		printerr("TEMP: no StrumNote was generated; nothing was saved.")
		return
	var strum:StrumNote = StrumGroup.strum_notes[0]
	if strum.sprite_frames == null:
		printerr("TEMP: the first StrumNote has no SpriteFrames.")
		return
	var error:Error = ResourceSaver.save(strum.sprite_frames, OUTPUT_PATH)
	if error == OK:
		print("TEMP: Strum SpriteFrames saved to %s" % OUTPUT_PATH)
	else:
		printerr("TEMP: failed to save Strum SpriteFrames: %s" % error)
