extends Node2D
class_name PlayState


## SCREEN
@onready var Screen = $UI/ScreenEssentials

## CAMERAS
@onready var Cam_HUD:CanvasLayer = $UI
@onready var Camera:Camera2D = $Camera

## VOICES
@onready var voices_opponent = $VoicesOpponent
@onready var voices_player = $VoicesPlayer

## GROUPS
@onready var note_group:NoteGroup = $UI/NoteGroup
@onready var strum_group:StrumGroup = $UI/StrumGroup
@onready var popup_group:PopupGroup = $UI/PopupGroup

## HEALTH
@onready var health_bar = $UI/HUD/HealthBar
@onready var health_icons:Dictionary[String, HealthIcon] = {
	"p1": $UI/HUD/HealthBar/IconP1, # PLAYER
	"p2": $UI/HUD/HealthBar/IconP2 # OPPONENT
}

## SCRIPT
@onready var events_node:Node = $Events
var events:Dictionary[String, CustomScript] = {}

## CHARACTERS
@onready var characters:Dictionary[String, Character] = {
	"player": $Player,
	"gf": $Girlfriend,
	"opponent": $Opponent
}

## OTHER
@onready var countdown = $CountdownTimer
@onready var score_txt = $UI/HUD/ScoreTxt

## STAGE
var stage:Stage = null

## GAMEPLAY
var botplay:bool = false
var song_started:bool = false
var gf_speed:float = 1.0

## CAMERA
var default_cam_zoom:float = 1.0
var cam_target:Vector2 = Vector2.ZERO
var cam_zoom:float = 1.0
var camera_speed:float = 1.0

## PLAYER
var song_score:int = 0
var song_hits:int = 0
var song_misses:int = 0
var combo:int = 0

## RATING
var rating_percent:float = 0.0
var total_notes_hit:float = 0.0
var total_played:int = 0


func _physics_process(delta):
	# CAMERAS
	update_camera_position(delta)
	
	# EVENTS
	_event_process()

func _process(delta):
	# ICONS
	update_icons_position()
	
	# CAMERAS
	update_cameras_zoom(delta)

#region READY

func _ready() -> void:
	# STRUMS
	strum_group.generate_strums()
	
	# SONG
	var err:String = Song.load_song()
	if err: OS.alert(err, "SONG LOAD ERROR")
	
	# EVENTS
	load_events()
	
	# LOADING CHARACTERS
	for char in characters:
		if Song.characters.has(char):
			characters[char].load_character(
				Song.characters[char],
				false if char == "opponent" else true)
	characters["gf"].load_character(Song.characters["girlfriend"], false)
	
	# HEALTH
	health_bar.value = 50
	health_bar.position.y = Global.SCREEN_SIZE.y
	if !Preferences.downscroll: health_bar.position.y *= 0.89
	else: health_bar.position.y *= 0.11
	
	# ICONS
	health_icons["p1"].load_icon(characters["player"].data.health_icon)
	health_icons["p2"].load_icon(characters["opponent"].data.health_icon)
	
	# SETUPS
	setup_camera()
	setup_stage()
	
	# HITS CONNECT
	Conductor.step_hit.connect(step_hit)
	Conductor.beat_hit.connect(beat_hit)
	Conductor.measure_hit.connect(measure_hit)
	
	# INSTRUMENTAL
	Conductor.set_bpm(Song.bpm)
	Conductor.stream = Song.song["Inst"]
	Conductor.bus = "Inst"
	Conductor.song_position = -Conductor.sec_per_beat * 1000 * 5
	
	# TRANSITION OUT
	Screen.transition_out()
	
	# COUNTDOWN
	countdown.wait_time = Conductor.sec_per_beat
	countdown.start()

func start_song() -> void:
	# VOICES
	for i in Song.song.keys():
		if i == "Inst": continue
		var child = find_child(i)
		child.stream = Song.song[i]
		child.play()
	
	# START SONG
	Conductor.play()
	song_started = true

func setup_camera() -> void:
	Camera.zoom = Vector2(default_cam_zoom, default_cam_zoom)
	
	for ev in Song.chart_events["Funkin"]:
		if ev[1] != "FocusCamera": continue
		
		# SET CAMERA WITHOUT LERP
		ev[2]["ease"] = "INSTANT"
		execute_funkin_event("FocusCamera", ev[2])
		
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

func update_icons_position():
	health_icons["p1"].position.x = (
		health_bar.bar_middle +
		(150 * health_icons["p1"].scale.x - 150) / 2 - 26)
	health_icons["p2"].position.x = (
		health_bar.bar_middle -
		(150 * health_icons["p2"].scale.x) / 2 - 26 * 2)

func update_cameras_zoom(delta:float):
	var mult:float = lerp(1.0, Cam_HUD.scale.x, exp(-delta * 3.125))
	Cam_HUD.scale = Vector2(mult, mult)
	Cam_HUD.offset.x = Global.SCREEN_SIZE.x * (1.0 - mult) / 2
	Cam_HUD.offset.y = Global.SCREEN_SIZE.y * (1.0 - mult) / 2
	mult = lerp(cam_zoom, Camera.zoom.x, exp(-delta * 3.125))
	Camera.zoom = Vector2(mult, mult)

func update_camera_position(delta):
	Camera.position = \
	lerp(Camera.position, cam_target, 0.04 * camera_speed)

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
	
	var strum:StrumNote = StrumGroup.player_strums[note.strum_data]
	strum.note_was_hit = true
	
	if Preferences.hit_anim: strum.play_anim("confirm")
	
	note.was_hit = true
	if note.is_sustain: 
		note.is_holding = true
		note.self_modulate.a = 0.0
	else: NoteGroup.remove_note(note)
	
	# RATING
	var rating:Dictionary = judge_note(abs(Conductor.song_position - note.time))
	if rating["percent"] == 1:
		strum.splash_note()
	total_notes_hit += rating["percent"]
	total_played += 1
	
	popup_group.popup_rating(rating["name"])
	
	# HEALTH
	health_bar.value += Util.HEALTH_GAIN
	
	# SCORES
	song_hits += 1
	song_score += rating["score"]
	
	combo += 1
	popup_group.popup_combo(combo)
	
	characters["player"].is_holding = true
	player_sing(note.strum_data, note.is_sustain)
	
	update_scores()

func opponent_hit(note:Note):
	var strum:StrumNote = StrumGroup.opponent_strums[note.strum_data]
	if Preferences.opponent_hit: strum.play_anim("confirm")
	
	note.was_hit = true
	
	if note.is_sustain:
		note.is_holding = true
		note.self_modulate.a = 0.0
	else: 
		NoteGroup.remove_note(note)
	
	strum.splash_note()
	
	opponent_sing(note.strum_data, note.is_sustain)

func miss_note(direction:int, note:Note = null, kill:bool = false):
	if !note or !note.is_sustain:
		health_bar.value -= Util.HEALTH_LOSS
		song_misses += 1
	elif note:
		health_bar.value -= int(note.length / 10)
		song_misses += 2
	
	# RATING
	if note:
		total_played += 1
		combo = 0
	song_score -= 10
	
	# CHAR
	characters["player"].play_anim(Util.SING_ANIMS[direction] + "miss")
	
	if kill: NoteGroup.remove_note(note)
	update_scores()

#endregion

#region SCORES

func update_scores():
	calculate_rating()
	var percent = Util.floor_decimals(rating_percent * 100, 2)
	
	var score = Util.format_commas(abs(song_score))
	# NEGATIVE SCORE
	if song_score < 0.0: score = "-" + score
	
	score_txt.text = "Score: {0}\nMisses: {1}\nAccuracy: {2}%".format(
		[score, song_misses, percent])
func calculate_rating():
	if total_played != 0:
		rating_percent = min(1, max(0, total_notes_hit / total_played))

#endregion

#region CONDUCTOR HITS

func step_hit(step:int) -> void:
	pass

func beat_hit(beat:int) -> void:
	character_bopper(beat)
	
	health_icons["p1"].scale = Vector2(1.2, 1.2)
	health_icons["p2"].scale = Vector2(1.2, 1.2)

func measure_hit(section:int) -> void:
	Cam_HUD.scale += Vector2(0.03, 0.03)
	Camera.zoom = \
	Vector2(cam_zoom, cam_zoom) + Vector2(0.015, 0.015)

func character_bopper(beat:int) -> void:
	for char in characters.keys():
		var character:Character = characters[char]
		
		if char == "gf":
			if beat % int(round(gf_speed * character.dance_beat_num))== 0 \
			and !character.animation.begins_with(Util.SING_ANIM_ID):
				character.dance()
			continue
		
		if beat % character.dance_beat_num == 0 \
		and !character.animation.begins_with(Util.SING_ANIM_ID):
			character.dance()

#endregion

#region EVENTS

func load_events() -> void:
	for ev in Song.chart_events["Funkin"]:
		if !events.has(ev[1]):
			if !FileAccess.file_exists("res://assets/events/%s.gd" % ev[1]):
				continue
			var scr:GDScript = load("res://assets/events/%s.gd" % ev[1])
			
			var node:Node = Node.new()
			events_node.add_child(node)
			node.set_script(scr)
			events[ev[1]] = node
	for ev in Song.chart_events["Psych"]:
		if !events.has(ev[1]):
			if !FileAccess.file_exists("res://assets/events/%s.gd" % ev[1]):
				continue
			var scr:GDScript = load("res://assets/events/%s.gd" % ev[1])
			
			var node:Node = Node.new()
			events_node.add_child(node)
			node.set_script(scr)
			events[ev[1]] = node

func _event_process():
	for ev in Song.chart_events["Funkin"]:
		if ev[0] > Conductor.song_position: break
		execute_funkin_event(ev[1], ev[2])
		Song.chart_events["Funkin"].erase(ev)
	
	for ev in Song.chart_events["Psych"]:
		if ev[0] > Conductor.song_position: break
		execute_psych_event(ev[1], ev[2], ev[3])
		Song.chart_events["Psych"].erase(ev)

func execute_funkin_event(event:String, values):
	if events.has(event) and events[event].has_method("_on_event"):
		events[event]._on_event(values)

func execute_psych_event(event:String, value1, value2):
	if events.has(event) and events[event].has_method("_on_event"):
		events[event]._on_event(value1, value2)

#endregion

#region CHARACTERS

func player_sing(data:int, is_sustain:bool):
	var anim:String = Util.SING_ANIMS[data]
	characters["player"].hold_time = 0.0
	characters["player"].play_anim(anim, true)

func opponent_sing(data:int, is_sustain:bool):
	var anim:String = Util.SING_ANIMS[data]
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
	
	if !lerp: Camera.position = cam_target

func tween_camera_zoom(zoom:float, duration:float, ease:String, direct:bool = false):
	var tw:Tween = \
	create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).\
	set_ease( Util.get_ease_from_flixel_ease(ease) ).\
	set_trans( Util.get_trans_from_flixel_ease(ease) ).\
	set_parallel(true)
	
	var z:float = zoom * (1.0 if direct else default_cam_zoom)
	
	if duration > 0.0:
		tw.tween_property(Camera, "zoom", Vector2(z, z), duration)
		tw.tween_property(self, "cam_zoom", z, duration)
	else:
		Camera.zoom = Vector2(z, z)
		cam_zoom = z

#endregion
