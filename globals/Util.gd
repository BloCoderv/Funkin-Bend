extends Node
class_name Util

const HEALTH_GAIN = 2
const HEALTH_LOSS = 4

const PIXEL_PER_MS = 0.45

static func floor_decimals(val:float, decimals:int) -> float:
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
