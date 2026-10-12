extends RefCounted
class_name PlayStateParams

## Parâmetros de uma execução de música.
var song_id: String = ""
var difficulty: String = "hard"
var variation: String = ""
var practice_mode: bool = false
var botplay: bool = false
var playback_rate: float = 1.0

func _init(
		p_song_id: String = "",
		p_difficulty: String = "hard",
		p_variation: String = "",
		p_practice_mode: bool = false,
		p_botplay: bool = false,
		p_playback_rate: float = 1.0
	) -> void:
	song_id = p_song_id
	difficulty = p_difficulty
	variation = p_variation
	practice_mode = p_practice_mode
	botplay = p_botplay
	playback_rate = maxf(p_playback_rate, 0.01)
