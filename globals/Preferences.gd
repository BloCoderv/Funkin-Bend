extends Node


var opponent_hit:bool = true # GLOW ON HIT
var opponent_splashes:bool = false # SPLASH ON HIT

var splashes:bool = true # SPLASH ON HIT

var downscroll:bool = true
var safe_offset:float = 10.0

var splash_opacity:float = 0.6

var notes_behind_strum:bool = false

# JUDGEMENTS
var judge_window:Dictionary = {"sick": 45, "good": 90, "bad": 135}
