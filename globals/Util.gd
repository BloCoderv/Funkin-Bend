extends Node
class_name Util

## >  -------  UTILITIES  -------  < ##


#region CONSTANTS

const ConstantsScript: Script = preload("res://source/util/Constants.gd")
const HEALTH_MAX: float = ConstantsScript.HEALTH_MAX
const HEALTH_STARTING: float = ConstantsScript.HEALTH_STARTING
const HEALTH_MIN: float = ConstantsScript.HEALTH_MIN
const HEALTH_SICK_BONUS: float = ConstantsScript.HEALTH_SICK_BONUS
const HEALTH_GOOD_BONUS: float = ConstantsScript.HEALTH_GOOD_BONUS
const HEALTH_BAD_BONUS: float = ConstantsScript.HEALTH_BAD_BONUS
const HEALTH_SHIT_BONUS: float = ConstantsScript.HEALTH_SHIT_BONUS
const HEALTH_HOLD_BONUS_PER_SECOND: float = ConstantsScript.HEALTH_HOLD_BONUS_PER_SECOND
const HEALTH_MISS_PENALTY: float = ConstantsScript.HEALTH_MISS_PENALTY
const HEALTH_GHOST_MISS_PENALTY: float = ConstantsScript.HEALTH_GHOST_MISS_PENALTY
const HEALTH_HOLD_DROP_PENALTY_PER_SECOND: float = ConstantsScript.HEALTH_HOLD_DROP_PENALTY_PER_SECOND
const HEALTH_HOLD_DROP_PENALTY_MAX: float = ConstantsScript.HEALTH_HOLD_DROP_PENALTY_MAX
const SCORE_GHOST_MISS_PENALTY: float = ConstantsScript.SCORE_GHOST_MISS_PENALTY
const SCORE_HOLD_BONUS_PER_SECOND: float = ConstantsScript.SCORE_HOLD_BONUS_PER_SECOND
const SCORE_HOLD_DROP_PENALTY_PER_SECOND: float = ConstantsScript.SCORE_HOLD_DROP_PENALTY_PER_SECOND
const HOLD_DROP_PENALTY_THRESHOLD_MS: float = ConstantsScript.HOLD_DROP_PENALTY_THRESHOLD_MS
const JUDGEMENT_BAD_COMBO_BREAK: bool = ConstantsScript.JUDGEMENT_BAD_COMBO_BREAK
const JUDGEMENT_SHIT_COMBO_BREAK: bool = ConstantsScript.JUDGEMENT_SHIT_COMBO_BREAK
const PIXEL_PER_MS: float = ConstantsScript.PIXEL_PER_MS
const NOTE_SAFE_ZONE: float = ConstantsScript.NOTE_SAFE_ZONE
const NOTE_INVALID_ZONE: float = ConstantsScript.NOTE_INVALID_ZONE
const NOTE_SPAWN_OFFSET: float = ConstantsScript.NOTE_SPAWN_OFFSET
const NOTE_ACTIONS: Array[String] = ConstantsScript.NOTE_ACTIONS
const STRUMLINE_NOTE_SIZE: float = ConstantsScript.STRUMLINE_NOTE_SIZE
const STRUMLINE_SEPARATION: float = ConstantsScript.STRUMLINE_SEPARATION
const STRUMLINE_DEFAULT_SCALE: float = ConstantsScript.STRUMLINE_DEFAULT_SCALE
const STRUMLINE_MARGIN: float = ConstantsScript.STRUMLINE_MARGIN
const STRUMLINE_MANIA: int = ConstantsScript.STRUMLINE_MANIA
const STRUMLINE_Y_MARGIN: float = ConstantsScript.STRUMLINE_Y_MARGIN
const MIDDLESCROLL_SCALE: float = ConstantsScript.MIDDLESCROLL_SCALE
const STRUMLINE_BACKGROUND_MARGIN: float = ConstantsScript.STRUMLINE_BACKGROUND_MARGIN
const SING_ANIMS: Array[String] = ConstantsScript.SING_ANIMS
const SING_ANIM_ID: String = ConstantsScript.SING_ANIM_ID
const SPLASHES_SCALE: float = ConstantsScript.SPLASHES_SCALE
const COLOR_HEALTH_RED: Color = ConstantsScript.COLOR_HEALTH_RED
const COLOR_HEALTH_GREEN: Color = ConstantsScript.COLOR_HEALTH_GREEN

#endregion

#region Functions

static func floor_decimals(val:float, decimals:int):
	var result:float = floor(val * pow(10, decimals)) / pow(10, decimals)
	if decimals < 1:
		return floor(val)
	if result == int(result):
		return int(result)
	return result

static func format_commas(num:int) -> String:
	var str = str(num)
	var result = ""
	var count = 0
	for i in range(str.length() - 1, -1, -1):
		result = str[i] + result
		count += 1
		if count % 3 == 0 and i != 0:
			result = "," + result
	return result

static func get_trans_from_flixel_ease(ease:String) -> Tween.TransitionType:
	for i in ease.length():
		if ease[i].to_upper() == ease[i]:
			ease = ease.substr(0, i)
			break
	
	match ease:
		"linear": return Tween.TRANS_LINEAR
		"sine": return Tween.TRANS_SINE
		"quad": return Tween.TRANS_QUAD
		"cube": return Tween.TRANS_CUBIC
		"quart": return Tween.TRANS_QUART
		"quint": return Tween.TRANS_QUINT
		"expo": return Tween.TRANS_EXPO
		"smooth": return Tween.TRANS_CUBIC
		"elastic": return Tween.TRANS_ELASTIC
	return Tween.TRANS_LINEAR

static func get_ease_from_flixel_ease(ease:String) -> Tween.EaseType:
	for i in ease.length():
		if ease[i].to_upper() == ease[i]:
			ease = ease.substr(i)
			break
	
	if ease.begins_with("Step"): ease = ease.substr(4)
	
	match ease:
		"InOut": return Tween.EASE_IN_OUT
		"In": return Tween.EASE_IN
		"Out": return Tween.EASE_OUT
	return Tween.EASE_IN_OUT

static func scale_image(image:Image, scale:float) -> Image:
	var img:Image = image.duplicate()
	img.convert(Image.FORMAT_RGBA8)
	var size = Vector2(
		img.get_width() * scale,
		img.get_height() * scale
	)
	img.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	return img

#endregion
