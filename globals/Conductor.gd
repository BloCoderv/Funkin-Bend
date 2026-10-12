extends AudioStreamPlayer

signal step_hit(step: int)
signal beat_hit(beat: int)
signal measure_hit(measure: int)

class BPMChangeTimes:
	var time: float = 0.0
	var step_time: int = 0
	var bpm: float = 100.0

var song_position: float = 0.0
var last_bpm_change: BPMChangeTimes = BPMChangeTimes.new()
var _bpm_change_index: int = -1
var bpm: float = 100.0
var sec_per_beat: float = 60.0 / bpm
var beat_step: float = sec_per_beat / 4.0
var step: int = 0
var beat: int = 0
var measure: int = 0

func _physics_process(delta: float) -> void:
	if !playing:
		if song_position < 0.0:
			# Antes do áudio existir não há relógio externo; o delta só cobre o pré-roll.
			song_position += delta * 1000.0
		return

	var previous_step: int = step
	var previous_beat: int = beat
	var previous_measure: int = measure
	# A posição vem do áudio para evitar deriva quando um frame demora mais que o normal.
	song_position = (get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()) * 1000.0
	_update_bpm_change()
	step = last_bpm_change.step_time + int(floor((song_position - last_bpm_change.time) / (beat_step * 1000.0)))
	beat = int(floor(step / 4.0))
	measure = int(floor(step / 16.0))

	if previous_step != step:
		step_hit.emit(step)
	if previous_beat != beat:
		beat_hit.emit(beat)
	if previous_measure != measure:
		measure_hit.emit(measure)

## Reinicia o cursor de BPM quando uma música começa ou é reiniciada.
func reset_timing() -> void:
	_bpm_change_index = -1
	last_bpm_change.time = 0.0
	last_bpm_change.step_time = 0
	last_bpm_change.bpm = bpm
	step = 0
	beat = 0
	measure = 0

func _update_bpm_change() -> void:
	while _bpm_change_index + 1 < Song.chart_times.size():
		var next_change: Array = Song.chart_times[_bpm_change_index + 1] as Array
		if float(next_change[0]) > song_position:
			break
		_bpm_change_index += 1
		last_bpm_change.time = float(next_change[0])
		last_bpm_change.step_time = int(next_change[1])
		last_bpm_change.bpm = float(next_change[2])
		set_bpm(last_bpm_change.bpm)

func set_bpm(new_bpm: float) -> void:
	bpm = maxf(new_bpm, 0.001)
	sec_per_beat = 60.0 / bpm
	beat_step = sec_per_beat / 4.0
