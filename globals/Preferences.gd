extends Node


#region GAMEPLAY

var opponent_hit:bool = true # GLOW ON HIT
var opponent_splashes:bool = false # SPLASH ON HIT

var splashes:bool = false # SPLASH ON HIT
var hit_anim:bool = true # GLOW ON HIT

var downscroll:bool = false
var safe_offset:float = 10.0

var splash_opacity:float = 0.6

var notes_behind_strum:bool = false

var popup_limit:int = 1

#endregion

#region OFFSETS

var combo_offset:Vector2 = Vector2.ZERO
var rating_offset:Vector2 = Vector2.ZERO

#endregion

#region OPTIMIZATIONS

var low_stages:bool = true
var stages:bool = false

var characters:bool = true

#endregion

var auto_pause:bool = false

var judge_window:Dictionary = {"sick": 45, "good": 90, "bad": 135}
