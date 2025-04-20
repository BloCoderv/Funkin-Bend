extends Node2D
class_name PlayState

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

## GAMEPLAY
var botplay:bool = false
var song_started:bool = false

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
	Conductor.beatHit.connect(beat_hit)
	Conductor.stream = Song.song["Inst"]
	Conductor.set_bpm(Song.bpm)
	
	# COUNTDOWN TIMER
	countdown_timer.connect("timeout", countdown_tick)
	countdown_timer.wait_time = Conductor.step_per_beat
	countdown_timer.start()

func _process(delta):
	update_icons_position()

var counter:int = -1
func countdown_tick():
	counter += 1
	match counter:
		0: pass
		1: pass
		2: pass
		3: pass
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

func update_icons_position():
	health_icons["p1"].position.x = (
		health_bar.bar_middle +
		(150 * health_icons["p1"].scale.x - 150) / 2 - 26)
	health_icons["p2"].position.x = (
		health_bar.bar_middle -
		(150 * health_icons["p2"].scale.x) / 2 - 26 * 2)
	#health_icons["p1"].position.x = health_bar.bar_middle + 51
	#health_icons["p2"].position.x = health_bar.bar_middle - (51 + 150)

#region NOTES

func judge_note(diff) -> Dictionary:
	for i in Preferences.judge_window.keys():
		var window = Preferences.judge_window[i]
		if window > diff:
			var percent:float = 1.0
			match i:
				"good":
					percent = .67
				"bad": 
					percent = .34
			return {"name": i, "percent": percent}
	return {"name": "shit", "percent": 0.0}

func player_hit(note:Note):
	var strum = StrumGroup.player_strums[note.data]
	strum.play("confirm%s" % strum.data)
	
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

func opponent_hit(note:Note):
	var strum = StrumGroup.player_strums[note.data]
	if Preferences.opponent_hit:
		strum.play("confirm%s" % strum.data)
	note.was_hit = true
	if note.is_sustain: 
		note.is_holding = true
		note.self_modulate.a = 0.0
	else: NoteGroup.remove_note(note)
	strum.splash_note()

func miss_note(note:Note, kill:bool = false):
	if !note.is_sustain:
		health_bar.value -= Util.HEALTH_GAIN
	else:
		health_bar.value -= int(note.length / 10)
	
	if kill:
		NoteGroup.remove_note(note)

#endregion

func beat_hit(beat:int) -> void:
	if beat % 2 == 0:
		health_icons["p1"].scale = Vector2(1.2, 1.2)
		health_icons["p2"].scale = Vector2(1.2, 1.2)
