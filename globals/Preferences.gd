extends Node


## >  -------  USER PREFERENCES  -------  < ##

#region DEBUG

var godotClearColor:bool = true

#endregion

#region GAMEPLAY

var hit_anim:bool = true # GLOW ON HIT
var notes_behind_strum:bool = false
var sustain_behind_strum:bool = false

var strumline_bg:float = 0.0

var downscroll:bool = false
var middlescroll:bool = false

var ghost_tapping:bool = false

var auto_pause:bool = true

var judge_window:Dictionary = {"sick": 45, "good": 90, "bad": 135}

#endregion

#region VISUALS

# Notas sustain executam a animação de Hold do style Funkin. Se desativado, as animações e os splashes são ocultos.
# Substitue a variavel 'hold_splash_end' que foi deletada. Porém é incluso todas as animações relacionadas ao Hold.
var funkinHoldAnimation:bool = true

var opponent_notes:bool = true
var opponent_hit:bool = true # GLOW ON HIT
var opponent_splashes:bool = false # SPLASH ON HIT

var splash_opacity:float = 0.6
var strums_opacity:float = 1.0
var notes_opacity:float = 1.0

#endregion

#region OFFSETS

var combo_offset:Vector2 = Vector2.ZERO
var rating_offset:Vector2 = Vector2.ZERO

var safe_offset:float = 10.0 # Default: 10.0

#endregion

#region OPTIMIZATIONS

var low_stages:bool = true
var stages:bool = true

var characters:bool = true

var popup_limit:int = 5 # Default: 5

#endregion

const CONFIG_PATH := "user://settings.cfg"
const NOTE_ACTIONS := ["note0", "note1", "note2", "note3"]

func _ready() -> void:
	load_keybinds()

func set_keybind(action:String, event:InputEvent) -> void:
	if !NOTE_ACTIONS.has(action):
		return
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	save_keybinds()

func get_keybind(action:String) -> InputEvent:
	var events := InputMap.action_get_events(action)
	return events[0] if !events.is_empty() else null

func reset_keybinds() -> void:
	var defaults := [KEY_Z, KEY_X, KEY_COMMA, KEY_PERIOD]
	for i in NOTE_ACTIONS.size():
		var key := InputEventKey.new()
		key.physical_keycode = defaults[i]
		InputMap.action_erase_events(NOTE_ACTIONS[i])
		InputMap.action_add_event(NOTE_ACTIONS[i], key)
	save_keybinds()

func save_keybinds() -> void:
	var cfg := ConfigFile.new()
	for action in NOTE_ACTIONS:
		var event := get_keybind(action) as InputEventKey
		if event:
			cfg.set_value("controls", action, event.physical_keycode)
	cfg.save(CONFIG_PATH)

func load_keybinds() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	for action in NOTE_ACTIONS:
		var event = cfg.get_value("controls", action, null)
		if event is int and event > 0:
			var key := InputEventKey.new()
			key.physical_keycode = event
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, key)
