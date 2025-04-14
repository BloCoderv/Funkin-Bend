extends Node
class_name NoteGroup

const NOTE_SCENE = preload("res://scenes/objects/Note.tscn")

@onready var playstate:PlayState = get_tree().current_scene

static var notes:Array[Note] = [] # NOTES IN SCREEN
static var unspawn_notes:Array[Note] = [] # NOTE DATA

static var invalid_offset:float = 0.0
static var note_song_offset:float = 0.0
static var safe_offset:float = 0.0
const SPAWN_TIME_OFFSET = 2000

static func load_notes():
	for note in Song.chart_notes:
		var new:Note = NOTE_SCENE.instantiate()
		new.time = note["t"]
		new.data = note["d"]
		new.strum_data = note["d"]
		if note.has("l"): new.length = note["l"]
		if note["d"] > 3: 
			new.must_press = false
			new.strum_data -= 4
		new.scale = StrumGroup.strum_notes[new.data].scale
		new.position.y = 720
		unspawn_notes.append(new)

static func remove_note(note:Note):
	notes.erase(note)
	note.queue_free()

func spawn_notes_of(timeMS:float):
	for note in unspawn_notes:
		var n_time = SPAWN_TIME_OFFSET
		if(Song.scroll_speed < 1): n_time /= Song.song_speed
		if !(note.time - Conductor.song_position < n_time): break
		# INSTANTIATE
		add_child(note)
		notes.append(note)
		unspawn_notes.erase(note)

func _physics_process(delta):
	spawn_notes_of(Conductor.song_position)
	
	for note in notes:
		var note_strum:StrumNote = StrumGroup.strum_notes[note.data]
		
		# VELOCITY
		var note_song_pos = .45 * (Conductor.song_position - note.time)
		note_song_pos *= Song.scroll_speed
		if !note_strum.downscroll: note_song_pos *= -1
		note.position.y = note_strum.position.y + note_song_pos + note.pivot.y
		
		note.position.x = note_strum.position.x + note.pivot.x
		note.rotation = note_strum.rotation
		note.modulate.a = note_strum.modulate.a
		
		if note.position.y - (note.pivot.y * 2) <= 0:
			kill_note(note)
			continue
		
		if note.too_late: continue
		
		if Conductor.song_position - note.time > invalid_offset:
			if note.must_press and !playstate.botplay:
				playstate.miss_note(note)
			invalidate_note(note)
		
		if note.must_press and !playstate.botplay:
			if (
				!note.was_hit
				and note.time > Conductor.song_position - safe_offset 
				and note.time < Conductor.song_position + safe_offset
			):
				note.can_hit = true
				if (
					!note_strum.note_in_strum 
					or note_strum.note_in_strum.time > note.time
					or note_strum.note_in_strum.was_hit
				):
					note_strum.note_in_strum = note
			else: 
				note.can_hit = false
		elif !playstate.botplay:
			if Conductor.song_position >= note.time:
				playstate.opponent_hit(note)
				note_strum.reset_time = Conductor.step_per_beat * .75
				if !Preferences.opponent_hit: note_strum.reset_time = 0
		else:
			if Conductor.song_position >= note.time:
				playstate.player_hit(note)
				note_strum.reset_time = Conductor.step_per_beat * .75

static func kill_note(note:Note):
	notes.erase(note)
	note.queue_free()
static func invalidate_note(note:Note):
	note.too_late = true
	note.can_hit = false
	note.self_modulate.a = 0.5
