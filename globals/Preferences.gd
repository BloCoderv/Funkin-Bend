extends Node


## >  -------  USER PREFERENCES  -------  < ##


#region GAMEPLAY

var hit_anim:bool = true # GLOW ON HIT
var notes_behind_strum:bool = false
var sustain_behind_strum:bool = true

var hold_splash_end:bool = true

var strumline_bg:float = 0.5

## SCROLL
var downscroll:bool = false
var middlescroll:bool = true

var auto_pause:bool = false

var judge_window:Dictionary = {"sick": 45, "good": 90, "bad": 135}

#endregion

#region VISUALS

var opponent_notes:bool = false
var opponent_hit:bool = true # GLOW ON HIT
var opponent_splashes:bool = false # SPLASH ON HIT

## OPACITY
var splash_opacity:float = 0.6
var strums_opacity:float = 1.0
var notes_opacity:float = 1.0

#endregion

#region OFFSETS

var combo_offset:Vector2 = Vector2.ZERO
var rating_offset:Vector2 = Vector2.ZERO

var safe_offset:float = 10.0

#endregion

#region OPTIMIZATIONS

var low_stages:bool = true
var stages:bool = false

var characters:bool = true

var popup_limit:int = 1

#endregion
