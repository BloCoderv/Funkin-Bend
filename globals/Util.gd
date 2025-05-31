extends Node
class_name Util

const HEALTH_GAIN = 2
const HEALTH_LOSS = 4

const PIXEL_PER_MS = 0.45

const SING_ANIMS = ["singLEFT", "singDOWN", "singUP", "singRIGHT"]
const SING_ANIM_ID = "sing"

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
	print(ease)
	
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
	
	print(ease)
	
	match ease:
		"InOut": return Tween.EASE_IN_OUT
		"In": return Tween.EASE_IN
		"Out": return Tween.EASE_OUT
	return Tween.EASE_IN_OUT
