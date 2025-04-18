extends AudioStreamPlayer

signal beatHit(beat)
signal sectionHit(section)

var song_position:float = 0.0

var bpm:float = 100.0
var sec_per_beat:float = 60.0 / bpm
var step_per_beat:float = sec_per_beat / 4

var beat:int = 0
var section:int = 0

func set_bpm(new:float):
	bpm = new
	sec_per_beat = 60.0 / bpm
	step_per_beat = sec_per_beat / 4

func _physics_process(delta):
	if playing:
		var prev_beat = beat
		var prev_section = section
		
		song_position = get_playback_position() + AudioServer.get_time_since_last_mix()
		song_position -= AudioServer.get_output_latency()
		
		beat = floor(song_position / sec_per_beat)
		section = floor(beat / 4)
		
		song_position *= 1000 # TO MS
		
		if prev_beat != beat:
			beatHit.emit(beat)
		if prev_section != section:
			sectionHit.emit(section)
