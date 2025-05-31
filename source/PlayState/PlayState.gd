extends Node2D
class_name PlayState


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

## CHARACTERS
@onready var characters:Dictionary[String, Character] = {
	"player": $Player,
	"gf": $Girlfriend,
	"opponent": $Opponent
}

## OTHER
@onready var countdown = $CountdownTimer
@onready var score_txt = $UI/HUD/ScoreTxt

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
	strum_group.generate_strums()
	
	var err:String = Song.load_song()
	if err: OS.alert(err, "SONG LOAD ERROR")
	
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
	
	# CAMERA
	setup_camera()
	
	# CONDUCTOR
	Conductor.stepHit.connect(step_hit)
	Conductor.beatHit.connect(beat_hit)
	Conductor.sectionHit.connect(section_hit)
	
	Conductor.set_bpm(Song.bpm)
	Conductor.stream = Song.song["Inst"]
	Conductor.bus = "Inst"
	Conductor.song_position = -Conductor.sec_per_beat * 1000 * 5
	
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
	var strum:StrumNote = StrumGroup.player_strums[note.data]
	strum.play_anim("confirm")
	
	note.was_hit = true
	if note.is_sustain: 
		note.is_holding = true
		note.self_modulate.a = 0.0
	else: NoteGroup.remove_note(note)
	
	# HEALTH
	health_bar.value += Util.HEALTH_GAIN
	
	# RATING
	var rating:Dictionary = judge_note(abs(Conductor.song_position - note.time))
	if rating["percent"] == 1:
		strum.splash_note()
	total_notes_hit += rating["percent"]
	total_played += 1
	
	popup_group.popup_rating(rating["name"])
	
	# SCORES
	song_hits += 1
	song_score += rating["score"]
	combo += 1
	
	popup_group.popup_combo(combo)
	
	player_sing(note.strum_data, note.is_sustain)
	
	update_scores()

func opponent_hit(note:Note):
	var strum:StrumNote = StrumGroup.player_strums[note.data]
	if Preferences.opponent_hit:
		strum.play_anim("confirm")
	note.was_hit = true
	if note.is_sustain:
		note.is_holding = true
		note.self_modulate.a = 0.0
	else: NoteGroup.remove_note(note)
	strum.splash_note()
	opponent_sing(note.strum_data, note.is_sustain)

func miss_note(direction:int, note:Note = null, kill:bool = false):
	if !note or !note.is_sustain:
		health_bar.value -= Util.HEALTH_LOSS
		song_misses += 1
	elif note:
		health_bar.value -= int(note.length / 10)
		song_misses += 2
	song_score -= 10
	
	# RATING
	total_played += 1
	combo = 0
	
	# CHAR
	characters["player"].play_anim(Util.SING_ANIMS[note.strum_data] + "miss")
	
	if kill: NoteGroup.remove_note(note)
	update_scores()

#endregion

#region SCORES

func update_scores():
	calculate_rating()
	var percent = Util.floor_decimals(rating_percent * 100, 2)
	score_txt.text = "Score: {0}\nMisses: {1}\nAccuracy: {2}%".format(
		[Util.format_commas(song_score), song_misses, percent])
func calculate_rating():
	if total_played != 0:
		rating_percent = min(1, max(0, total_notes_hit / total_played))

#endregion

#region CONDUCTOR HITS

func step_hit(step:int) -> void:
	health_icons["p1"].scale = Vector2(1.2, 1.2)
	health_icons["p2"].scale = Vector2(1.2, 1.2)
	
	character_bopper(step)

func beat_hit(beat:int) -> void:
	pass

func section_hit(section:int) -> void:
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
	match event:
		"FocusCamera":
			
			var char = ""
			match int(values["char"]):
				0: char = "player"
				1: char = "opponent"
				2: char = "gf"
			
			var pos = Vector2(0, 0)
			if values.has("x"):
				pos.x = values["x"]
			if values.has("y"):
				pos.y = values["y"]
			
			var lerp = true
			if values.has("ease"):
				lerp = (values["ease"] != "INSTANT")
			
			set_camera_target(char, pos, lerp)
		
		"ZoomCamera":
			
			var zoom:float = 1.0
			var duration:float = 4.0
			var ease:String = "linear"
			var direct:bool = false
			
			if !(values is Dictionary):
				duration *= Conductor.sec_per_beat
				tween_camera_zoom(values, duration, ease)
				return
			
			if values.has("zoom"):
				zoom = values["zoom"]
				
			if values.has("duration"):
				duration = values["duration"]
			
			if values.has("ease"):
				ease = values["ease"]
			
			if values.has("mode"):
				direct = (values["mode"] == "direct")
			
			duration *= Conductor.sec_per_beat
			
			tween_camera_zoom(zoom, duration, ease, direct)

func execute_psych_event(event:String, value1, value2):
	pass

#endregion

#region CHARACTERS

func player_sing(data:int, is_sustain:bool):
	var anim:String = Util.SING_ANIMS[data]
	characters["player"].hold_time = 0.0
	characters["player"].is_holding = true
	characters["player"].play_anim(anim)

func opponent_sing(data:int, is_sustain:bool):
	var anim:String = Util.SING_ANIMS[data]
	characters["opponent"].hold_time = 0.0
	characters["opponent"].play_anim(anim)
	
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
		cam_target = Vector2(mid_point.x - 100, mid_point.y - 100)
		cam_target.x -= character.data.camera_position.x - char_pos.x
		cam_target.y += character.data.camera_position.y + char_pos.y
		cam_target += pos
	elif character.is_girlfriend:
		cam_target = mid_point
		cam_target += character.data.camera_position
		cam_target += char_pos + pos
	else: # OPPONENT
		cam_target = Vector2(mid_point.x + 150, mid_point.y - 100)
		cam_target += character.data.camera_position
		cam_target += char_pos + pos
	
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
