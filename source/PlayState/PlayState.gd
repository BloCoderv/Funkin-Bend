extends Node2D
class_name PlayState

## SCREEN
@onready var Screen: Control = $UI/ScreenEssentials

## CAMERAS
@onready var Cam_HUD:CanvasLayer = $UI
@onready var camera: Camera2D = $Camera

## VOICES
@onready var voices_opponent: AudioStreamPlayer = $VoicesOpponent
@onready var voices_player: AudioStreamPlayer = $VoicesPlayer

## GROUPS
@onready var note_group:NoteGroup = $UI/NoteGroup
@onready var strum_group:StrumGroup = $UI/StrumGroup
@onready var popup_group:PopupGroup = $UI/PopupGroup

## HEALTH
@onready var health_bar: HealthBar = $UI/HUD/HealthBar
@onready var health_bar_bg: TextureRect = $UI/HUD/HealthBarBG
@onready var health_icons:Dictionary[String, HealthIcon] = {
	"p1": $UI/HUD/HealthBar/IconP1, # PLAYER
	"p2": $UI/HUD/HealthBar/IconP2 # OPPONENT
}

@onready var events_node:Node = $Events
var events: Dictionary[String, Node] = {}

## CHARACTERS
@onready var characters:Dictionary[String, Character] = {
	"player": $Player,
	"gf": $Girlfriend,
	"opponent": $Opponent
}

## OTHER
@onready var countdown: Timer = $CountdownTimer
@onready var score_txt: Label = $UI/HUD/ScoreTxt

## STAGE
var stage:Stage = null

## GAMEPLAY
var params: PlayStateParams = PlayStateParams.new()
var botplay: bool = false
var song_started: bool = false
var gf_speed: float = 1.0

## CAMERAS
var default_cam_zoom:float = 1.0
var cam_target:Vector2 = Vector2.ZERO
var cam_zoom:float = 1.0
var camera_speed:float = 1.0

var camera_zoom_intensity:float = 1.015
var hud_camera_zoom_intensity:float = 0.015 * 2.0

var camera_zoom_rate:int = 4

## PLAYER
var song_score:int = 0
var song_hits:int = 0
var song_misses:int = 0
var combo:int = 0
var health:float = Util.HEALTH_STARTING:
	set(v):
		health = clampf(v, Util.HEALTH_MIN, Util.HEALTH_MAX)

## RATING
var rating_percent:float = 100.0
var total_notes_hit:float = 0.0
var total_played:int = 0


#region READY

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# SONG
	var err:String = Song.load_song()
	if err:
		push_error("SONG LOAD ERROR: %s" % err)
		Global.change_scene("res://scenes/MainMenu.tscn")
		return
	params = PlayStateParams.new(Song.song_id, Song.difficulty, Song.song_mix, false, botplay, 1.0)
	
	# STRUMS
	strum_group.generate_strums()
	
	# EVENTS
	load_events()
	
	# LOADING CHARACTERS
	for char in characters:
		if Song.characters.has(char):
			characters[char].load_character(
				Song.characters[char],
				false if char == "opponent" else true)
	characters["gf"].load_character(Song.characters["girlfriend"], false)
	# The loading scene and the play state share this short-lived cache. The
	# character nodes now own the data they need, so release the staging refs.
	CharacterData.clear_runtime_cache()
	
	# HEALTH BAR
	health_bar_bg.position.y = Global.SCREEN_SIZE.y
	
	if !Preferences.downscroll: health_bar_bg.position.y *= 0.89
	else: health_bar_bg.position.y *= 0.11
	
	health_bar.position.y = health_bar_bg.position.y + 4
	
	# SCORE
	score_txt.position.y = health_bar_bg.position.y + 40
	
	# ICONS
	health_icons["p1"].load_icon(characters["player"].data.health_icon)
	health_icons["p2"].load_icon(characters["opponent"].data.health_icon)
	
	# SETUPS
	setup_camera()
	setup_stage()
	
	# HITS CONNECT
	connect_conductor_signals()
	
	# INSTRUMENTAL
	Conductor.set_bpm(Song.bpm)
	Conductor.reset_timing()
	Conductor.stream = Song.song["Inst"]
	Conductor.bus = "Inst"
	Conductor.song_position = -Conductor.sec_per_beat * 1000 * 5
	
	# TRANSITION OUT
	Screen.transition_out()
	
	# COUNTDOWN
	countdown.start(Conductor.sec_per_beat)

func start_song() -> void:
	# Os dois players são cacheados pela cena; não há busca de nós no loop da música.
	voices_player.stream = Song.song.get("VoicesPlayer") as AudioStream
	voices_opponent.stream = Song.song.get("VoicesOpponent") as AudioStream
	if voices_player.stream != null:
		voices_player.play()
	if voices_opponent.stream != null:
		voices_opponent.play()
	
	# START SONG
	Conductor.play()
	song_started = true

func setup_camera() -> void:
	camera.zoom = Vector2(default_cam_zoom, default_cam_zoom)
	
	for ev in Song.chart_events["Funkin"]:
		if ev[1] != "FocusCamera": continue
		
		# SET CAMERA WITHOUT LERP
		var focus_values = ev[2]
		if focus_values is Dictionary:
			focus_values = focus_values.duplicate()
			focus_values["ease"] = "INSTANT"
		else:
			focus_values = {"char": focus_values, "ease": "INSTANT"}
		execute_funkin_event("FocusCamera", focus_values)
		
		break

func setup_stage() -> void:
	var stage_path = "res://assets/stages/%s.tscn" % Song.stage
	if !FileAccess.file_exists(stage_path) \
	or !Preferences.stages:
		if Preferences.stages:
			print_debug("%s not exists - Without Stage" % Song.stage)
		stage = Stage.new()
		add_child(stage)
	else:
		stage = ResourceLoader.load(
			stage_path,
			"PackedScene",
			ResourceLoader.CACHE_MODE_IGNORE
		).instantiate()
		add_child(stage)
	
	stage.z_index = -1
	default_cam_zoom = stage.camera_zoom
	
	for char in stage.characters.keys():
		if !characters.has(char):
			print_debug("%s not exists" % char)
			continue
		
		for v in stage.characters[char].keys():
			characters[char].set(v, stage.characters[char][v])
		
		characters[char].position.x -= characters[char].get_mid_point().x
		characters[char].position.y -= characters[char].get_mid_point().y * 2.0
		
		characters[char].dance()
	
	for opt in stage.optimizations.keys():
		if stage.get_child_count() <= opt:
			if Preferences.stages:
				print_debug("Child: %s not exists" % opt)
			continue
		
		for v in stage.optimizations[opt].keys():
			stage.get_child(opt).set(v, stage.optimizations[opt][v])

#endregion

#region PROCESS

func _physics_process(delta):
	if get_tree().paused:
		return
	# CAMERA POSITION
	camera.position = \
	lerp(camera.position, cam_target, 0.04 * camera_speed)
	
	# EVENTS
	_event_process()
	
	# HEALTH BAR LERP
	health_bar.value = lerp(health_bar.value, health * 50, 0.15)

	cam_zoom = camera.zoom.x

func _process(delta):
	if get_tree().paused:
		return
	if !botplay:
		var player_is_holding:bool = false
		for direction: int in range(4):
			if Input.is_action_pressed(Util.NOTE_ACTIONS[direction]):
				player_is_holding = true
				break
		characters["player"].is_holding = player_is_holding
	
	# ICONS
	update_icons_position()
	
	# CAMERAS
	update_cameras_zoom(delta)

func update_icons_position():
	health_icons["p1"].position.x = (
		(health_bar.size.x * 
		(remap(health_bar.value * 0.02, 0, 2, 100, 0) * 0.01) - 26))
	health_icons["p2"].position.x = (
		(health_bar.size.x * (remap(health_bar.value * 0.02, 0, 2, 100, 0) * 0.01))
		- ((health_icons["p2"].size.x) - 26))

func update_cameras_zoom(delta:float):
	var mult:float = lerp(1.0, Cam_HUD.scale.x, exp(-delta * 3.125))
	Cam_HUD.scale = Vector2(mult, mult)
	Cam_HUD.offset.x = Global.SCREEN_SIZE.x * (1.0 - mult) / 2
	Cam_HUD.offset.y = Global.SCREEN_SIZE.y * (1.0 - mult) / 2
	mult = lerp(cam_zoom, camera.zoom.x, exp(-delta * 3.125))
	camera.zoom = Vector2(mult, mult)

#endregion

#region INPUT

func _unhandled_input(event:InputEvent) -> void:
	if botplay:
		return
	for direction:int in range(4):
		var action: String = Util.NOTE_ACTIONS[direction]
		if event.is_action_pressed(action) \
		and !(event is InputEventKey and event.echo):
			note_group.handle_press(direction)
		if event.is_action_released(action):
			note_group.handle_release(direction)

#endregion

#region NOTES

func judge_note(diff) -> Dictionary:
	for i in Preferences.judge_window.keys():
		var window = Preferences.judge_window[i]
		if window > diff:
			# SICK
			var percent:float = 1.0
			var score:int = 350
			match i:
				"good":
					percent = .67
					score = 200
				"bad":
					score = 100
					percent = .34
			return {"name": i, "percent": percent, "score": score}
	# SHIT
	return {"name": "shit", "percent": 0.0, "score": 50}

func player_hit(note:Note):
	if note == null or note.was_hit or note.too_late or !note.can_hit:
		return
	
	var strum:StrumNote = StrumGroup.player_strums[note.strum_data]
	strum.play_confirm(note.is_sustain)
	if note.is_sustain:
		strum.start_hold_cover()
	
	note.was_hit = true
	if note.is_sustain:
		note.is_holding = true
		note.hold_started_at = Conductor.song_position
		note.texture = null
	else:
		NoteGroup.remove_note(note)
	
	# RATING
	var rating:Dictionary = judge_note(abs(Conductor.song_position - note.time))
	if rating["percent"] == 1:
		strum.splash_note()
	total_notes_hit += rating["percent"]
	total_played += 1
	
	popup_group.popup_rating(rating["name"])
	
	# HEALTH
	var health_bonus:float = Util.HEALTH_SICK_BONUS
	match rating["name"]:
		"good": health_bonus = Util.HEALTH_GOOD_BONUS
		"bad": health_bonus = Util.HEALTH_BAD_BONUS
		"shit": health_bonus = Util.HEALTH_SHIT_BONUS
	health += health_bonus
	
	# SCORES
	song_hits += 1
	song_score += rating["score"]
	
	if rating["name"] == "bad" and Util.JUDGEMENT_BAD_COMBO_BREAK \
	or rating["name"] == "shit" and Util.JUDGEMENT_SHIT_COMBO_BREAK:
		combo = 0
	else:
		combo += 1
	popup_group.popup_combo(combo)
	
	characters["player"].is_holding = !botplay
	player_sing(note.strum_data, note.is_sustain)
	
	update_scores()

func opponent_hit(note:Note):
	var strum:StrumNote = StrumGroup.opponent_strums[note.strum_data]
	if Preferences.opponent_hit: strum.play_confirm(note.is_sustain)
	if note.is_sustain:
		strum.start_hold_cover()
	
	note.was_hit = true
	
	if note.is_sustain:
		note.is_holding = true
		note.texture = null
	else:
		NoteGroup.remove_note(note)
	characters["opponent"].is_holding = note.is_sustain
	
	strum.splash_note()
	
	opponent_sing(note.strum_data, note.is_sustain)

func miss_note(direction:int, note:Note = null, kill:bool = false):
	health += Util.HEALTH_GHOST_MISS_PENALTY if note == null else Util.HEALTH_MISS_PENALTY
	song_misses += 1
	
	# RATING
	if note:
		total_played += 1
		combo = 0
	song_score -= 10
	
	# CHAR
	characters["player"].play_anim(Util.SING_ANIMS[direction] + "miss")
	
	if kill: NoteGroup.remove_note(note)
	update_scores()

func drop_hold(note:Note, remaining_ms:float) -> void:
	if note == null or note.hold_drop_handled:
		return
	note.hold_drop_handled = true
	characters["player"].is_holding = false
	characters["player"].hold_time = 0.0
	remaining_ms = maxf(remaining_ms, 0.0)
	# The base game only penalizes a meaningful amount of sustain that was dropped.
	if remaining_ms > Util.HOLD_DROP_PENALTY_THRESHOLD_MS:
		health += clampf(
			remaining_ms / 1000.0 * Util.HEALTH_HOLD_DROP_PENALTY_PER_SECOND,
			-Util.HEALTH_HOLD_DROP_PENALTY_MAX,
			0.0)
		song_score += int(remaining_ms / 1000.0 * Util.SCORE_HOLD_DROP_PENALTY_PER_SECOND)
		combo = 0
		characters["player"].play_anim(Util.SING_ANIMS[note.strum_data] + "miss")
		update_scores()

func hold_note_tick(note:Note, delta:float) -> void:
	if note == null or !note.was_hit or note.hold_drop_handled:
		return
	# FNF awards sustain value continuously instead of treating the tail as
	# another hit. Keep fractional points so frame rate does not change score.
	note.hold_score_remainder += delta * Util.SCORE_HOLD_BONUS_PER_SECOND
	var points:int = int(note.hold_score_remainder)
	if points > 0:
		note.hold_score_remainder -= points
		song_score += points
	health += delta * Util.HEALTH_HOLD_BONUS_PER_SECOND

#endregion

#region SCORES

func update_scores():
	calculate_rating()
	var percent = Util.floor_decimals(calculate_rating() * 100, 2)
	
	var score = Util.format_commas(abs(song_score))
	# NEGATIVE SCORE
	if song_score < 0.0: score = "-" + score
	
	score_txt.text = "Score: {0}    Misses: {1}    Accuracy: {2}%".format(
		[score, song_misses, percent])
func calculate_rating():
	if total_played != 0:
		rating_percent = min(1, max(0, total_notes_hit / total_played))
	return rating_percent

#endregion

#region CONDUCTOR HITS

func step_hit(step:int) -> void:
	character_bopper(step)

func beat_hit(beat:int) -> void:
	health_icons["p1"].scale = Vector2(1.2, 1.2)
	health_icons["p2"].scale = Vector2(1.2, 1.2)
	
	if camera_zoom_rate > 0 \
	and beat % camera_zoom_rate == 0 \
	and camera.zoom.x < 1.35 * default_cam_zoom:
		Cam_HUD.scale += Vector2(
			hud_camera_zoom_intensity, hud_camera_zoom_intensity
		)
		camera.zoom = Vector2(
			camera_zoom_intensity, camera_zoom_intensity
		)

func measure_hit(section:int) -> void:
	pass

func character_bopper(step:int) -> void:
	for char in characters.keys():
		var character:Character = characters[char]
		var dance_every:float = character.data.dance_every
		if char == "gf":
			dance_every *= gf_speed
		var dance_every_steps:float = dance_every * 4.0
		if dance_every > 0.0 \
		and is_zero_approx(fmod(float(step), dance_every_steps)):
			character.dance()

#endregion

#region EVENTS

var funkin_events: Array = []
var bend_events: Array = []
var _funkin_event_index: int = 0
var _bend_event_index: int = 0

func load_events() -> void:
	var has_no_script:Array = []
	
	# CLEAR
	for child in events_node.get_children():
		child.queue_free()
	events = {}
	
	funkin_events = Song.chart_events["Funkin"].duplicate()
	bend_events = Song.chart_events["Bend"].duplicate()
	funkin_events.sort_custom(_sort_events)
	bend_events.sort_custom(_sort_events)
	_funkin_event_index = 0
	_bend_event_index = 0
	
	# FUNKIN EVENTS
	for ev in funkin_events:
		var event_name: String = str(ev[1])
		var event_script_path: String = "res://assets/events/%s.gd" % event_name
		if !events.has(event_name):
			if !FileAccess.file_exists(event_script_path):
				# Prevents showing this alert more than once
				if event_name not in has_no_script:
					OS.alert("%s has no script" % event_name, "Warning!")
					has_no_script.append(event_name)
				continue
			var scr: GDScript = ResourceLoader.load(event_script_path) as GDScript
			var node:Node = Node.new()
			events_node.add_child(node)
			node.set_script(scr)
			events[event_name] = node

	has_no_script = []
	
	# BEND EVENTS
	for ev in bend_events:
		var event_name: String = str(ev[1])
		var event_script_path: String = "res://assets/events/%s.gd" % event_name
		if !events.has(event_name):
			if !FileAccess.file_exists(event_script_path):
				if event_name not in has_no_script:
					OS.alert("%s has no script" % event_name, "Warning!")
					has_no_script.append(event_name)
				continue
			var scr: GDScript = ResourceLoader.load(event_script_path) as GDScript
			var node:Node = Node.new()
			events_node.add_child(node)
			node.set_script(scr)
			events[event_name] = node

static func _sort_events(first: Array, second: Array) -> bool:
	return float(first[0]) < float(second[0])

func _event_process():
	while _funkin_event_index < funkin_events.size():
		var funkin_event: Array = funkin_events[_funkin_event_index] as Array
		if float(funkin_event[0]) > Conductor.song_position:
			break
		execute_funkin_event(str(funkin_event[1]), funkin_event[2])
		_funkin_event_index += 1
	while _bend_event_index < bend_events.size():
		var bend_event: Array = bend_events[_bend_event_index] as Array
		if float(bend_event[0]) > Conductor.song_position:
			break
		execute_bend_event(str(bend_event[1]), bend_event[2], bend_event[3])
		_bend_event_index += 1

func execute_funkin_event(event:String, values):
	if events.has(event) and events[event].has_method("_on_event"):
		events[event]._on_event(values)

func execute_bend_event(event:String, value1, value2):
	if events.has(event) and events[event].has_method("_on_event"):
		events[event]._on_event(value1, value2)

#endregion

#region CHARACTERS

func player_sing(data:int, is_sustain:bool):
	characters["player"].begin_sing(data)

func player_release(data:int) -> void:
	characters["player"].end_sing(data)

func opponent_sing(data:int, is_sustain:bool):
	var anim:String = Util.SING_ANIMS[data]
	if !is_sustain:
		characters["opponent"].is_holding = false
	characters["opponent"].hold_time = 0.0
	characters["opponent"].play_anim(anim, true)
	
#endregion

#region CAMERAS

func set_camera_target(char:String, pos:Vector2 = Vector2.ZERO, lerp:bool = true):
	var character:Character = null
	var mid_point:Vector2 = Vector2.ZERO
	var char_pos:Vector2 = Vector2.ZERO
	
	if char != "":
		if !characters.has(char): 
			printerr("%s not exists" % char)
			return
		
		character = characters[char]
		if character == null: return
		
		mid_point = character.get_mid_point()
		char_pos = character.position
	
	if character == null:
		cam_target = pos
	
	elif character.is_player:
		
		cam_target = mid_point - Vector2(100, 100)
		cam_target.x -= character.data.camera_position.x - char_pos.x
		cam_target.x -= character.camera_offset.x
		cam_target.y += character.data.camera_position.y + char_pos.y
		cam_target.y += character.camera_offset.y
		
	else:
		cam_target = mid_point
		
		# IF OPPONENT
		if !character.is_girlfriend:
			cam_target = Vector2(mid_point.x + 150, mid_point.y - 100)
		
		cam_target += character.data.camera_position
		cam_target += char_pos + pos + character.camera_offset
	
	if !lerp: camera.position = cam_target

var tweenCameraZoom:Tween = null

func tween_camera_zoom(zoom:float, duration:float, ev_ease:String, direct:bool = false):
	var tw:Tween = \
	create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).\
	set_ease( Util.get_ease_from_flixel_ease(ev_ease) ).\
	set_trans( Util.get_trans_from_flixel_ease(ev_ease) )

	if tweenCameraZoom != null: tweenCameraZoom.kill()

	tweenCameraZoom = tw
	
	var z:float = zoom * (1.0 if direct else default_cam_zoom)
	
	if duration > 0.0:
		tweenCameraZoom.tween_property(camera, "zoom", Vector2(z, z), duration)
	else:
		camera.zoom = Vector2(z, z)

#endregion

#region OTHER

func _input(_event):
	if Input.is_action_just_pressed("reset"):
		restart_song()
	elif Input.is_action_just_pressed("return_to_menu"):
		return_to_menu()

func reset_vars() -> void:
	health = Util.HEALTH_STARTING
	combo = 0
	song_score = 0
	song_misses = 0
	song_hits = 0
	
	rating_percent = 100.0
	total_notes_hit = 0.0
	total_played = 0
	
	song_started = false

func cleanup_song_state() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	countdown.stop()
	note_group.clear_notes()
	StrumGroup.clear_strumlines()
	Conductor.stop()
	Audio.stop_all()
	voices_player.stop()
	voices_opponent.stop()
	if tweenCameraZoom != null:
		tweenCameraZoom.kill()
		tweenCameraZoom = null
	if Conductor.step_hit.is_connected(step_hit):
		Conductor.step_hit.disconnect(step_hit)
	if Conductor.beat_hit.is_connected(beat_hit):
		Conductor.beat_hit.disconnect(beat_hit)
	if Conductor.measure_hit.is_connected(measure_hit):
		Conductor.measure_hit.disconnect(measure_hit)
	if Conductor.finished.is_connected(end_song):
		Conductor.finished.disconnect(end_song)
	song_started = false

func connect_conductor_signals() -> void:
	if !Conductor.step_hit.is_connected(step_hit):
		Conductor.step_hit.connect(step_hit)
	if !Conductor.beat_hit.is_connected(beat_hit):
		Conductor.beat_hit.connect(beat_hit)
	if !Conductor.measure_hit.is_connected(measure_hit):
		Conductor.measure_hit.connect(measure_hit)
	if !Conductor.finished.is_connected(end_song):
		Conductor.finished.connect(end_song)

func restart_song() -> void:
	cleanup_song_state()
	connect_conductor_signals()
	
	Conductor.set_bpm(Song.bpm)
	Conductor.reset_timing()
	Conductor.song_position = -Conductor.sec_per_beat * 1000 * 5
	NoteGroup.load_notes()
	
	strum_group.generate_strums()
	
	# EVENTS
	load_events()
	
	# HEALTH BAR
	health_bar_bg.position.y = Global.SCREEN_SIZE.y
	
	if !Preferences.downscroll: health_bar_bg.position.y *= 0.89
	else: health_bar_bg.position.y *= 0.11
	
	health_bar.position.y = health_bar_bg.position.y + 4
	
	# SCORE
	score_txt.position.y = health_bar_bg.position.y + 40
	
	# ICONS
	health_icons["p1"].load_icon(characters["player"].data.health_icon)
	health_icons["p2"].load_icon(characters["opponent"].data.health_icon)
	
	# RESET
	reset_vars()
	
	update_scores()
	setup_camera()
	
	if stage != null: stage.queue_free()
	setup_stage()
	
	countdown.start(Conductor.sec_per_beat)

func return_to_menu() -> void:
	cleanup_song_state()
	Global.change_scene("res://scenes/MainMenu.tscn")

func end_song() -> void:
	if !song_started:
		return
	song_started = false
	Global.last_result = {
		"song": Song.song_name,
		"score": song_score,
		"misses": song_misses,
		"accuracy": calculate_rating() * 100.0
	}
	cleanup_song_state()
	Global.change_scene("res://scenes/Results.tscn")

func _exit_tree() -> void:
	cleanup_song_state()

#endregion
