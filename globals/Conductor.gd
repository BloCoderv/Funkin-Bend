extends AudioStreamPlayer

signal step_hit(step)
signal beat_hit(beat)
signal measure_hit(measure)

class BPMChangeTimes:
	var time:float = 0.0
	var step_time:int = 0
	var bpm:float = 100.0

var song_position:float = 0.0

var last_bpm_change:BPMChangeTimes = BPMChangeTimes.new()

var bpm:float = 100.0
var sec_per_beat:float = 60.0 / bpm
var beat_step:float = sec_per_beat / 4

var step:int = 0
var beat:int = 0
var measure:int = 0

func _physics_process(delta):
	if !playing: 
		if Conductor.song_position < 0:
			Conductor.song_position += delta * 1000
			last_bpm_change.bpm = bpm
		return
	
	var prev_step = step
	var prev_beat = beat
	var prev_section = measure
	
	song_position = get_playback_position() + AudioServer.get_time_since_last_mix()
	song_position -= AudioServer.get_output_latency()
	song_position *= 1000
	
	for time in Song.chart_times:
		if time[0] > song_position: break
		
		var bpm_change = BPMChangeTimes.new()
		bpm_change.time = time[0]
		bpm_change.step_time = time[1]
		bpm_change.bpm = time[2]
		
		set_bpm(bpm_change.bpm)
		last_bpm_change = bpm_change
	
	step = (
		last_bpm_change.step_time +
		floor(song_position - last_bpm_change.time) / (beat_step * 1000)
	)
	beat = floor(step / 4)
	measure = floor(step / 16)
	
	if prev_step != step:
		step_hit.emit(step)
	if prev_beat != beat:
		beat_hit.emit(beat)
	if prev_section != measure:
		measure_hit.emit(measure)

func set_bpm(new:float):
	bpm = new
	sec_per_beat = 60.0 / bpm
	beat_step = sec_per_beat / 4
