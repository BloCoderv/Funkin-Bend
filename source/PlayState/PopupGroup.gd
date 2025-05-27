extends Node
class_name PopupGroup


# ASSET PRELOAD
const POPUPS = preload("res://assets/images/ui/popup/popups.tres")
const COMBO_NUMS = preload("res://assets/images/ui/popup/combo_nums.tres")


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


func popup_rating(rat:String):
	if !Preferences.popup_limit:
		return
	
	# IMAGE
	var rat_image:Texture2D = null
	if POPUPS.has_animation(rat):
		rat_image = POPUPS.get_frame_texture(rat, 0)
	else:
		printerr("Rating not exists")
		return
	
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
		Conductor.sec_per_beat)
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
			Conductor.sec_per_beat * 2)
		combo_node.set_meta("tween", tw)

func get_combo_number(num:String) -> Texture2D:
	var combo_num = null
	if COMBO_NUMS.has_animation(str(num)):
		combo_num = COMBO_NUMS.get_frame_texture(str(num), 0)
	else:
		printerr("Combo number not exists - " + str(num))
	return combo_num
