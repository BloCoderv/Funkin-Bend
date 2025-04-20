extends Node2D
class_name PlayState

# CAMERAS
@onready var Cam_HUD:CanvasLayer = $UI
@onready var Camera:Camera2D = $Camera

## VOICES
@onready var voices_opponent = $VoicesOpponent
@onready var voices_player = $VoicesPlayer

## GROUPS
@onready var note_group = $UI/NoteGroup
@onready var strum_group = $UI/StrumGroup

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
@onready var countdown_timer = $CountdownTimer
@onready var score_txt = $UI/HUD/ScoreTxt

## GAMEPLAY
var botplay:bool = false
var song_started:bool = false

## CAMERA
var default_cam_zoom:float = 1

## PLAYER
var song_score:int = 0
var song_hits:int = 0
var song_misses:int = 0

## RATING
var rating_percent:float = 0.0
var total_notes_hit:float = 0.0
var total_played:int = 0

func _process(delta):
	update_icons_position()
	update_cameras_zoom(delta)

#region READY

func _ready():
	strum_group.generate_strums()
	
	var err:String = Song.load_song()
	if err: OS.alert(err, "SONG LOAD ERROR")
	
	# CHARACTERS
	characters["player"].load_character(Song.characters["player"], true)
	characters["opponent"].load_character(Song.characters["opponent"], false)
	
	# HEALTH
	health_bar.value = 50
	health_bar.position.y = Global.SCREEN_SIZE.y
	if !Preferences.downscroll: health_bar.position.y *= 0.89
	else: health_bar.position.y *= 0.11
	
	# ICONS
	health_icons["p1"].load_icon(characters["player"].data.health_icon)
	health_icons["p2"].load_icon(characters["opponent"].data.health_icon)
	
	# CONDUCTOR
	Conductor.stepHit.connect(step_hit)
	Conductor.beatHit.connect(beat_hit)
	Conductor.sectionHit.connect(section_hit)
	
	Conductor.stream = Song.song["Inst"]
	Conductor.set_bpm(Song.bpm)
	
	# COUNTDOWN TIMER
	countdown_timer.connect("timeout", countdown_tick)
	countdown_timer.wait_time = Conductor.step_per_beat
	countdown_timer.start()

var counter:int = -1
func countdown_tick():
	counter += 1
	match counter:
		0: print(3)
		1: print(2)
		2: print(1)
		3: print("GO!")
		4: 
			countdown_timer.stop()
			start_song()

func start_song():
	# VOICES
	for i in Song.song.keys():
		if i == "Inst": continue
		var child = find_child(i)
		child.stream = Song.song[i]
		child.play()
	
	# START SONG
	Conductor.play()
	song_started = true

#endregion

#region UPDATES

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
	mult = lerp(default_cam_zoom, Camera.zoom.x, exp(-delta * 3.125))
	Camera.zoom = Vector2(mult, mult)

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
	
	# SCORES
	song_hits += 1
	song_score += rating["score"]
	
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
	pass

func beat_hit(beat:int) -> void:
	health_icons["p1"].scale = Vector2(1.2, 1.2)
	health_icons["p2"].scale = Vector2(1.2, 1.2)

func section_hit(section:int) -> void:
	Cam_HUD.scale += Vector2(0.03, 0.03)
	Camera.zoom += Vector2(0.015, 0.015)

#endregion
