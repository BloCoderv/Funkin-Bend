extends Node
class_name NoteGroup


const SPAWN_TIME_OFFSET = 2000

const NOTE_SCENE = preload("res://scenes/objects/Note.tscn")

@onready var playstate:PlayState = get_tree().current_scene

static var notes:Array[Note] = [] # NOTES IN SCREEN
static var unspawn_notes:Array[Note] = [] # NOTE DATA

static var invalid_offset:float = 0.0
static var note_song_offset:float = 0.0
static var safe_offset:float = 0.0
static var strum_anim_time:float = 0.0

static func load_notes():
	for note in Song.chart_notes:
		var new:Note = NOTE_SCENE.instantiate()
		
		new.time = note[0]
		new.data = note[1]
		new.length = note[2]
		new.full_length = new.length
		
		new.strum_data = int(note[1]) % 4
		
		# ORDER
		new.z_index = 4 if Preferences.notes_behind_strum else 5
		
		if new.length > 0.0:
			new.is_sustain = true
		
		if new.data > 3: new.must_press = false
		
		unspawn_notes.append(new)

static func remove_note(note:Note):
	notes.erase(note)
	note.queue_free()

static func invalidate_note(note:Note):
	note.too_late = true
	note.can_hit = false
	note.self_modulate.a = 0.5

#region Sustain Functions
static func check_sustain_hit(note:Note, playstate:PlayState):
	if note and note.is_sustain and note.was_hit and note.length > 10: 
		playstate.miss_note(note.strum_data, note, true)

static func get_sustain_height(length:float) -> float:
	return length * Util.PIXEL_PER_MS * Song.scroll_speed

static func sustain_hold_loop(strum:StrumNote, char:Character):
	if strum.animation != "confirm" + strum.direction:
		strum.animation = "confirm" + strum.direction
	strum.frame = 0 if strum.frame else 1
#endregion

func spawn_notes_of(timeMS:float):
	for note in unspawn_notes:
		var n_time = SPAWN_TIME_OFFSET
		
		if(Song.scroll_speed < 1): n_time /= Song.song_speed
		if !(note.time - Conductor.song_position < n_time): break
		
		# INSTANTIATE
		
		if StrumGroup.strum_notes[note.data].downscroll:
			note.position.y = -note.texture.get_size().y * 0.7
		else:
			note.position.y = Global.SCREEN_SIZE.y
		
		add_child(note)
		notes.append(note)
		unspawn_notes.erase(note)

func _physics_process(delta):
	# SPAWN
	spawn_notes_of(Conductor.song_position)
	
	var delta_ms:float = delta * 1000
	
	if Preferences.opponent_hit:
		strum_anim_time = Conductor.beat_step * 1.75
	else: strum_anim_time = 0.001
	
	for note in notes:
		var note_strum:StrumNote = StrumGroup.strum_notes[note.data]
		var note_length:float = (note.time + note.full_length) - Conductor.song_position
		
		# VELOCITY
		if !note.is_sustain or (note.is_sustain and !note.is_holding):
			var note_song_pos = Util.PIXEL_PER_MS * (
				Conductor.song_position - note.time)
			note_song_pos *= Song.scroll_speed
			if !note_strum.downscroll: note_song_pos *= -1
			note.position.y = note_strum.position.y + note_song_pos + note.pivot.y
		else:
			note.position.y = note_strum.position.y + note.pivot.y
		
		note.position.x = note_strum.position.x + note.pivot.x
		note.rotation = note_strum.rotation
		note.modulate.a = note_strum.modulate.a
		
		var sus_k_offset = 0 if !note.sustain else note.sustain.size.y
		var downscroll_kill = note.position.y - sus_k_offset >= 720
		var upscroll_kill = note.position.y - (note.pivot.y * 2) + sus_k_offset <= 0
		if (note_strum.downscroll
		and downscroll_kill) or (
			!note_strum.downscroll
		and upscroll_kill):
			if note.must_press and !note.too_late:
				playstate.miss_note(note.strum_data, note, true)
			else:
				remove_note(note)
			continue
		
		if note.too_late: continue
		
		if Conductor.song_position - note.time > invalid_offset:
			if note.must_press and !playstate.botplay and (
			!note.is_sustain or !note.was_hit):
				playstate.miss_note(note.strum_data, note)
				note.too_late = true
				if note_strum.note_in_strum == note:
					note_strum.note_in_strum = null
				invalidate_note(note)
		
		## PLAYER STUFF
		if note.must_press and !playstate.botplay:
			if (
				!note.was_hit
				and !note.too_late
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
			
			# OFFSET SUSTAIN
			if Conductor.song_position >= note.time and (
			!note.is_holding and !note.too_late):
				note.length = note_length
			
			if note.was_hit and note.is_sustain and note.is_holding and !note.too_late:
				if note.length > 10:
					note.length = note_length
					playstate.characters["player"].hold_time = 0.0
					sustain_hold_loop(note_strum, playstate.characters["player"])
				else:
					remove_note(note)
					continue
		## OPPONENT STUFF
		elif !playstate.botplay:
			if Conductor.song_position >= note.time and !note.was_hit:
				note.length = note_length
				playstate.opponent_hit(note)
				# OPPONENT HIT ANIMATION TIME
				if !note.is_sustain: note_strum.reset_time = strum_anim_time
			if note.was_hit and note.is_sustain:
				if note.length > 10:
					note.length = note_length
					playstate.characters["opponent"].hold_time = 0.0
					if Preferences.opponent_hit:
						sustain_hold_loop(note_strum, playstate.characters["opponent"])
				else:
					note_strum.reset_time = strum_anim_time
					remove_note(note)
					continue
		## BOTPLAY STUFF
		else:
			if Conductor.song_position >= note.time:
				note.length = note_length
				playstate.player_hit(note)
				if !note.is_sustain: note_strum.reset_time = strum_anim_time
			if note.was_hit and note.is_sustain:
				if note.length > 10:
					note.length = note_length
					playstate.characters["player"].hold_time = 0.0
					sustain_hold_loop(note_strum, playstate.characters["player"])
				else:
					note_strum.reset_time = strum_anim_time
					remove_note(note)
					continue
		
		# SUSTAIN LENGTH
		if note.is_sustain:
			note.change_sustain_height(
				get_sustain_height(note.length)
			)
