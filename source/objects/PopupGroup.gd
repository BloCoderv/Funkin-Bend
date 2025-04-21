extends Node
class_name PopupGroup

@onready var combo_nums = $ComboNums
@onready var ratings = $Ratings

func _process(delta):
	for rat in ratings.get_children():
		var vel:Vector2 = rat.get_meta("velocity")
		var acc:Vector2 = rat.get_meta("acceleration")
		vel += acc * delta
		rat.position += vel * delta
		rat.set_meta("velocity", vel)
	for combo in combo_nums.get_children():
		var vel:Vector2 = combo.get_meta("velocity")
		var acc:Vector2 = combo.get_meta("acceleration")
		vel += acc * delta
		combo.position += vel * delta
		combo.set_meta("velocity", vel)

var popup_cache:Dictionary = {}
func popup_rating(rat:String):
	if !Preferences.popup_limit:
		return
	
	# PATH
	var rat_image_path:String = "res://assets/images/ui/popup/%s.png" % rat
	if !FileAccess.file_exists(rat_image_path):
		OS.alert("rating image not exists", "POPUP RATING ERROR")
		return
	
	# IMAGE
	var rat_image:Texture2D = null
	if !popup_cache.has(rat):
		rat_image = ResourceLoader.load(
			rat_image_path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
		popup_cache[rat] = rat_image
	else:
		rat_image = popup_cache[rat]
	
	# RATING NODE
	var rating:TextureRect = TextureRect.new()
	
	if Preferences.popup_limit <= ratings.get_child_count() - 1:
		rating = ratings.get_child(ratings.get_child_count() - 1)
		rating.get_meta("tween").kill()
	else:
		rating = TextureRect.new()
		ratings.add_child(rating)
	
	rating.texture = rat_image
	rating.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rating.size = rating.texture.get_size() * Vector2(0.7, 0.7)
	
	rating.position.x = (Global.SCREEN_SIZE.x * 0.474) - rating.size.x / 2
	rating.position.y = (Global.SCREEN_SIZE.y * 0.45 - 60) - rating.size.y / 2
	
	rating.position += Preferences.rating_offset
	rating.modulate.a = 1 # RESET
	
	# METADATAS
	rating.set_meta(
		"velocity", -Vector2(randi_range(0, 10), randi_range(140, 175)))
	rating.set_meta("acceleration", Vector2(0, 550))
	
	# TWEEN
	var tw = create_tween().set_process_mode(
		Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(rating, "modulate:a", 0, 0.2).set_delay(
		Conductor.step_per_beat)
	rating.set_meta("tween", tw)

func popup_combo(combo:int):
	var temp_combo:String = str(combo).pad_zeros(3)
	
	for l in temp_combo.length():
		var combo_node:TextureRect = null
		
		# RECYCLING
		if l > combo_nums.get_child_count() - 1:
			combo_node = TextureRect.new()
			combo_nums.add_child(combo_node)
		else:
			combo_node = combo_nums.get_child(l)
			combo_node.get_meta("tween").kill()
		
		combo_node.texture = get_combo_number(temp_combo[l])
		combo_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		combo_node.size = combo_node.texture.get_size() * Vector2(0.6, 0.6)
		
		combo_node.position.x = (Global.SCREEN_SIZE.x * 0.507) + (50 * (l + 1)) - 90
		combo_node.position.y = (Global.SCREEN_SIZE.y * 0.44)

		combo_node.position += Preferences.combo_offset
		combo_node.modulate.a = 1
		
		combo_node.set_meta(
			"velocity", Vector2(randf_range(-5, 5), -randi_range(130, 150)))
		combo_node.set_meta("acceleration", Vector2(0, randi_range(250, 300)))
		
		# TWEEN
		var tw = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tw.tween_property(combo_node, "modulate:a", 0, 0.2).set_delay(
			Conductor.step_per_beat * 2)
		combo_node.set_meta("tween", tw)

func get_combo_number(num:String) -> Texture2D:
	var path:String = "res://assets/images/ui/popup/num%s.png" % num
	if !FileAccess.file_exists(path):
		OS.alert("combo num not exists", "GET COMBO NUMBER ERROR")
		return
	var combo_num = null
	if !popup_cache.has("combo_num_%s" % num):
		combo_num = load(path)
		popup_cache["combo_num_%s" % num] = combo_num
	else:
		combo_num = popup_cache["combo_num_%s" % num]
	return combo_num
