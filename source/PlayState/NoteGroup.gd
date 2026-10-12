extends Node
class_name NoteGroup

const NOTE_SCENE: PackedScene = preload("res://scenes/notes/Note.tscn")
const SPAWN_TIME_OFFSET: float = 2000.0
const PIXEL_PER_MS: float = Util.PIXEL_PER_MS

@onready var playstate: PlayState = get_tree().current_scene as PlayState
static var notes: Array[Note] = []
static var _chart_data: Array[Array] = []
static var _next_spawn_index: int = 0
static var _note_pool: Array[Note] = []
static var invalid_offset: float = 0.0
static var safe_offset: float = 0.0
var _player_ref: Character = null
var _opponent_ref: Character = null

func _ready() -> void:
	if playstate != null:
		_player_ref = playstate.characters.get("player") as Character
		_opponent_ref = playstate.characters.get("opponent") as Character

## Prepara os dados uma vez; as instâncias só são obtidas quando entram na janela.
static func load_notes() -> void:
	_chart_data.clear()
	_next_spawn_index = 0
	var times: Dictionary = {}
	for raw_note: Array in Song.chart_notes:
		if raw_note.size() < 3:
			continue
		var note_time: float = float(raw_note[0])
		var note_data: int = int(raw_note[1])
		var key: int = int(note_time)
		var used_data: Array = times.get(key, []) as Array
		if note_data in used_data:
			continue
		used_data.append(note_data)
		times[key] = used_data
		_chart_data.append([note_time, note_data, maxf(float(raw_note[2]), 0.0)])
	_chart_data.sort_custom(_sort_chart_notes)

static func _sort_chart_notes(first: Array, second: Array) -> bool:
	return float(first[0]) < float(second[0])

static func _acquire_note() -> Note:
	var note: Note = null
	if !_note_pool.is_empty():
		note = _note_pool.pop_back()
	else:
		note = NOTE_SCENE.instantiate() as Note
	note.pooled = false
	note.visible = true
	return note

static func _release_note(note: Note) -> void:
	if note == null or note.pooled:
		return
	note.pooled = true
	note.visible = false
	note.was_hit = false
	note.can_hit = false
	note.too_late = false
	note.is_holding = false
	note.hold_started_at = -1.0
	note.hold_drop_handled = false
	note.hold_score_remainder = 0.0
	if note.get_parent() != null:
		note.get_parent().remove_child(note)
	_note_pool.append(note)

static func remove_note(note: Note) -> void:
	if note == null or note.pooled:
		return
	if note.data < StrumGroup.strum_notes.size() and StrumGroup.strum_notes[note.data].note_in_strum == note:
		StrumGroup.strum_notes[note.data].note_in_strum = null
	notes.erase(note)
	_release_note(note)

static func invalidate_note(note: Note) -> void:
	note.too_late = true
	note.can_hit = false
	note.self_modulate.a = 0.5

static func check_sustain_hit(note: Note, p_state: PlayState) -> void:
	if note != null and note.is_sustain and note.was_hit and !note.hold_drop_handled:
		p_state.drop_hold(note, maxf(note.time + note.full_length - Conductor.song_position, 0.0))

static func get_sustain_height(length: float) -> float:
	return maxf(length, 0.0) * PIXEL_PER_MS * Song.scroll_speed

static func sustain_hold_loop(strum: StrumNote) -> void:
	if strum.sprite_frames == null:
		return
	var hold_anim_name: String = "confirmHold" + strum.direction
	strum.play_confirm(strum.sprite_frames.has_animation(hold_anim_name))

func handle_press(direction: int) -> void:
	if direction < 0 or direction >= StrumGroup.player_strums.size():
		return
	var target: Note = null
	for note: Note in notes:
		if !is_instance_valid(note) or !note.must_press or note.strum_data != direction or note.was_hit or note.too_late:
			continue
		var diff: float = Conductor.song_position - note.time
		if absf(diff) > safe_offset:
			continue
		if target == null or note.time < target.time:
			target = note
	if target != null:
		target.can_hit = true
		playstate.player_hit(target)
		StrumGroup.player_strums[direction].play_confirm()
	else:
		StrumGroup.player_strums[direction].play_press()
		if !Preferences.ghost_tapping:
			playstate.miss_note(direction)

func handle_release(direction: int) -> void:
	if direction < 0 or direction >= StrumGroup.player_strums.size():
		return
	StrumGroup.player_strums[direction].play_static()
	playstate.player_release(direction)

func _process(delta: float) -> void:
	var song_pos: float = Conductor.song_position
	spawn_notes_of(song_pos)
	var index: int = notes.size() - 1
	while index >= 0:
		var note: Note = notes[index]
		if !is_instance_valid(note):
			index -= 1
			continue
		var strum_notes_ref: Array[StrumNote] = StrumGroup.strum_notes
		if note.data < 0 or note.data >= strum_notes_ref.size():
			remove_note(note)
			index -= 1
			continue
		var strum: StrumNote = strum_notes_ref[note.data]
		var diff: float = song_pos - note.time
		var end_time: float = note.time + note.full_length
		if note.is_sustain and note.was_hit:
			note.change_sustain_height(get_sustain_height(end_time - song_pos))
			note.position.y = strum.position.y + note.pivot.y
		else:
			var y_pos: float = diff * PIXEL_PER_MS * Song.scroll_speed
			if !strum.downscroll:
				y_pos *= -1.0
			note.position.y = strum.position.y + y_pos + note.pivot.y
			if note.is_sustain:
				note.change_sustain_height(get_sustain_height(note.full_length))
		note.position.x = strum.position.x + note.pivot.x
		note.rotation = strum.rotation
		note.modulate.a = strum.modulate.a

		if note.must_press:
			if playstate.botplay:
				if !note.was_hit and song_pos >= note.time:
					note.can_hit = true
					playstate.player_hit(note)
				if note.was_hit and note.is_sustain:
					_process_hold(note, strum, delta, true)
				elif note.was_hit:
					remove_note(note)
					index -= 1
					continue
			else:
				note.can_hit = !note.was_hit and diff > -safe_offset and diff < safe_offset
				if note.can_hit and (strum.note_in_strum == null or strum.note_in_strum.was_hit or strum.note_in_strum.too_late or strum.note_in_strum.time > note.time):
					strum.note_in_strum = note
				if note.was_hit and note.is_sustain:
					_process_hold(note, strum, delta, false)
				elif note.was_hit:
					remove_note(note)
					index -= 1
					continue
				elif diff > invalid_offset and !note.too_late:
					playstate.miss_note(note.strum_data, note)
					invalidate_note(note)
					if !note.is_sustain:
						remove_note(note)
						index -= 1
						continue
		else:
			if !note.was_hit and song_pos >= note.time:
				note.can_hit = true
				playstate.opponent_hit(note)
			if note.was_hit and note.is_sustain:
				_process_hold(note, strum, delta, true)
			elif note.was_hit:
				remove_note(note)
				index -= 1
				continue

		if note.is_sustain and song_pos >= end_time:
			if note.must_press and _player_ref != null:
				_player_ref.is_holding = false
				_player_ref.hold_time = 0.0
			if !note.must_press and _opponent_ref != null:
				_opponent_ref.is_holding = false
				_opponent_ref.hold_time = 0.0
			strum.stop_hold_cover(true)
			strum.play_static()
			if note.must_press and note.was_hit and Preferences.funkinHoldAnimation and Preferences.opponent_splashes:
				strum.splash_hold_note()
			remove_note(note)
		index -= 1

func _process_hold(note: Note, strum: StrumNote, delta: float, automatic: bool) -> void:
	var remaining: float = maxf(note.time + note.full_length - Conductor.song_position, 0.0)
	if remaining <= 0.0:
		return
	var held: bool = automatic or Input.is_action_pressed(Util.NOTE_ACTIONS[note.strum_data])
	if !held:
		playstate.drop_hold(note, remaining)
		note.is_holding = false
		strum.stop_hold_cover(false)
		if note.must_press:
			playstate.player_release(note.strum_data)
		strum.play_static()
		remove_note(note)
		return
	note.is_holding = true
	if _player_ref != null and note.must_press:
		_player_ref.hold_time = 0.0
		_player_ref.is_holding = true
	if _opponent_ref != null and !note.must_press:
		_opponent_ref.hold_time = 0.0
		_opponent_ref.is_holding = true
	if Preferences.hit_anim or (automatic and Preferences.opponent_hit):
		sustain_hold_loop(strum)
	if note.must_press:
		playstate.hold_note_tick(note, delta)

func spawn_notes_of(song_pos: float) -> void:
	# O ponteiro só avança; o chart já está ordenado e não é varrido por frame.
	while _next_spawn_index < _chart_data.size():
		var raw_note: Array = _chart_data[_next_spawn_index]
		var note_time: float = float(raw_note[0])
		if note_time - song_pos > SPAWN_TIME_OFFSET:
			break
		_next_spawn_index += 1
		var note_data: int = int(raw_note[1])
		if note_data >= StrumGroup.strum_notes.size():
			continue
		var note: Note = _acquire_note()
		note.time = note_time
		note.data = note_data
		note.length = float(raw_note[2])
		note.full_length = note.length
		note.strum_data = note_data % 4
		note.is_sustain = note.length > 0.0
		note.must_press = note_data < 4
		note.was_hit = false
		note.can_hit = false
		note.too_late = false
		note.is_holding = false
		note.hold_started_at = -1.0
		note.hold_drop_handled = false
		note.hold_score_remainder = 0.0
		note.z_index = 4 if Preferences.notes_behind_strum else 5
		note.modulate.a = Preferences.notes_opacity
		note.self_modulate.a = 1.0
		var strum: StrumNote = StrumGroup.strum_notes[note_data]
		note.position.y = -note.texture_size.y if strum.downscroll else Global.SCREEN_SIZE.y
		add_child(note)
		note.configure_visuals()
		notes.append(note)

func clear_notes() -> void:
	for note: Note in notes.duplicate():
		_release_note(note)
	notes.clear()
	_chart_data.clear()
	_next_spawn_index = 0
	for child: Node in get_children():
		if child is Note:
			_release_note(child as Note)
