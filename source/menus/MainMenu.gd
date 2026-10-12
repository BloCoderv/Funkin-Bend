extends Control

var song_select:OptionButton
var difficulty_select:OptionButton
var mix_edit:LineEdit
var status:Label
var listening_action := ""
var key_buttons:Dictionary = {}

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var ui:VBoxContainer = $UI
	var title := Label.new()
	title.text = "FNF BEND"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	ui.add_child(title)

	var song_row := HBoxContainer.new()
	song_row.add_child(_label("Música", 100))
	song_select = OptionButton.new()
	song_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	song_select.item_selected.connect(_on_song_selected)
	song_row.add_child(song_select)
	ui.add_child(song_row)

	var mix_row := HBoxContainer.new()
	mix_row.add_child(_label("Mix", 100))
	mix_edit = LineEdit.new()
	mix_edit.placeholder_text = "vazio = música padrão"
	mix_edit.text = Song.song_mix
	mix_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mix_row.add_child(mix_edit)
	ui.add_child(mix_row)

	var difficulty_row := HBoxContainer.new()
	difficulty_row.add_child(_label("Dificuldade", 100))
	difficulty_select = OptionButton.new()
	difficulty_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	difficulty_row.add_child(difficulty_select)
	ui.add_child(difficulty_row)

	var play := Button.new()
	play.text = "Jogar"
	play.pressed.connect(_play)
	ui.add_child(play)

	var reset := Button.new()
	reset.text = "Restaurar teclas"
	reset.pressed.connect(_reset_keys)
	ui.add_child(reset)

	status = Label.new()
	status.text = "Selecione uma música e uma dificuldade"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(status)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui.add_child(scroll)
	var preferences_box := VBoxContainer.new()
	preferences_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(preferences_box)

	_add_section(preferences_box, "Controles")
	for i in Preferences.NOTE_ACTIONS.size():
		_add_keybind(preferences_box, Preferences.NOTE_ACTIONS[i], "Nota %d" % (i + 1))

	_add_section(preferences_box, "Gameplay")
	_add_bool(preferences_box, "hit_anim", "Animação ao acertar")
	_add_bool(preferences_box, "notes_behind_strum", "Notas atrás das setas")
	_add_bool(preferences_box, "funkinHoldAnimation", "Funkin Hold Style")
	_add_bool(preferences_box, "downscroll", "Downscroll")
	_add_bool(preferences_box, "middlescroll", "Middlescroll")
	_add_bool(preferences_box, "ghost_tapping", "Ghost tapping")
	_add_bool(preferences_box, "auto_pause", "Pausar ao perder foco")
	_add_int(preferences_box, "safe_offset", "Offset seguro", 0, 200, 1)
	_add_int(preferences_box, "popup_limit", "Limite de popups", 1, 30, 1)
	_add_int(preferences_box, "judge_window.sick", "Janela Sick", 1, 300, 1)
	_add_int(preferences_box, "judge_window.good", "Janela Good", 1, 300, 1)
	_add_int(preferences_box, "judge_window.bad", "Janela Bad", 1, 400, 1)

	_add_section(preferences_box, "Visuais")
	_add_bool(preferences_box, "opponent_notes", "Notas do oponente")
	_add_bool(preferences_box, "opponent_hit", "Animação do oponente")
	_add_bool(preferences_box, "opponent_splashes", "Splashes do oponente")
	_add_float(preferences_box, "strumline_bg", "Fundo das setas", 0.0, 1.0, 0.05)
	_add_float(preferences_box, "splash_opacity", "Opacidade dos splashes", 0.0, 1.0, 0.05)
	_add_float(preferences_box, "strums_opacity", "Opacidade das setas", 0.0, 1.0, 0.05)
	_add_float(preferences_box, "notes_opacity", "Opacidade das notas", 0.0, 1.0, 0.05)

	_add_section(preferences_box, "Offsets")
	_add_vector(preferences_box, "combo_offset", "Offset do combo")
	_add_vector(preferences_box, "rating_offset", "Offset do rating")

	_add_section(preferences_box, "Performance")
	_add_bool(preferences_box, "low_stages", "Estágios simplificados")
	_add_bool(preferences_box, "stages", "Carregar estágio")
	_add_bool(preferences_box, "characters", "Carregar personagens")

	_populate_songs()

func _label(text:String, width:float) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = width
	return label

func _add_section(parent:VBoxContainer, text:String) -> void:
	var label := Label.new()
	label.text = "\n" + text
	label.add_theme_font_size_override("font_size", 20)
	parent.add_child(label)

func _add_bool(parent:VBoxContainer, property_name:String, text:String) -> void:
	var check := CheckBox.new()
	check.text = text
	check.button_pressed = bool(Preferences.get(property_name))
	check.toggled.connect(func(value:bool): Preferences.set(property_name, value))
	parent.add_child(check)

func _add_float(parent:VBoxContainer, property_name:String, text:String, min_value:float, max_value:float, step:float) -> void:
	var row := HBoxContainer.new()
	row.add_child(_label(text, 220))
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.value = float(Preferences.get(property_name))
	spin.value_changed.connect(func(value:float): Preferences.set(property_name, value))
	row.add_child(spin)
	parent.add_child(row)

func _add_int(parent:VBoxContainer, property_name:String, text:String, min_value:int, max_value:int, step:int) -> void:
	var row := HBoxContainer.new()
	row.add_child(_label(text, 220))
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.value = _get_preference_value(property_name)
	spin.value_changed.connect(func(value:float): _set_preference_value(property_name, int(value)))
	row.add_child(spin)
	parent.add_child(row)

func _add_vector(parent:VBoxContainer, property_name:String, text:String) -> void:
	var current:Vector2 = Preferences.get(property_name)
	for axis in ["x", "y"]:
		var row := HBoxContainer.new()
		row.add_child(_label("%s %s" % [text, axis.to_upper()], 220))
		var spin := SpinBox.new()
		spin.min_value = -1000
		spin.max_value = 1000
		spin.step = 1
		spin.value = current.x if axis == "x" else current.y
		spin.value_changed.connect(_set_vector_value.bind(property_name, axis))
		row.add_child(spin)
		parent.add_child(row)

func _set_vector_value(value:float, property_name:String, axis:String) -> void:
	var current:Vector2 = Preferences.get(property_name)
	if axis == "x": current.x = value
	else: current.y = value
	Preferences.set(property_name, current)

func _get_preference_value(property_name:String):
	if property_name.begins_with("judge_window."):
		return Preferences.judge_window.get(property_name.get_slice(".", 1), 0)
	return Preferences.get(property_name)

func _set_preference_value(property_name:String, value) -> void:
	if property_name.begins_with("judge_window."):
		Preferences.judge_window[property_name.get_slice(".", 1)] = value
	else:
		Preferences.set(property_name, value)

func _add_keybind(parent:VBoxContainer, action:String, text:String) -> void:
	var row := HBoxContainer.new()
	row.add_child(_label(text, 220))
	var button := Button.new()
	button.pressed.connect(_listen_for_key.bind(action))
	key_buttons[action] = button
	row.add_child(button)
	parent.add_child(row)
	_update_key_labels()

func _populate_songs() -> void:
	song_select.clear()
	var ids := DirAccess.get_directories_at("res://assets/data/songs")
	ids.sort()
	for song_id in ids:
		if FileAccess.file_exists("res://assets/data/songs/%s/%s-metadata.json" % [song_id, song_id]):
				song_select.add_item(song_id)
				song_select.set_item_metadata(song_select.item_count - 1, song_id)
		if song_select.item_count == 0:
			song_select.add_item("test")
			song_select.set_item_metadata(0, "test")
		var selected_index := 0
		for i in song_select.item_count:
			if song_select.get_item_metadata(i) == Song.song_id:
				selected_index = i
				break
		song_select.select(selected_index)
	_refresh_difficulties()

func _on_song_selected(_index:int) -> void:
	_refresh_difficulties()

func _refresh_difficulties() -> void:
	difficulty_select.clear()
	var song_id:String = song_select.get_selected_metadata()
	var base := "res://assets/data/songs/%s/%s" % [song_id, song_id]
	var meta_path := base + "-metadata.json"
	var chart_path := base + "-chart.json"
	var data:SongData = SongData.from_fnf_json(meta_path, chart_path) if FileAccess.file_exists(chart_path) else null
	var difficulties:Array = []
	if data:
		for difficulty in data.charts.keys():
			if data.scroll_speed.has(difficulty):
				difficulties.append(str(difficulty))
	if difficulties.is_empty():
		difficulties = ["hard"]
	difficulties.sort()
	for difficulty in difficulties:
		difficulty_select.add_item(str(difficulty))
	var selected := difficulties.find(Song.difficulty)
	difficulty_select.select(maxi(selected, 0))

func _play() -> void:
	var song_id:String = song_select.get_selected_metadata()
	var difficulty:String = difficulty_select.get_item_text(difficulty_select.selected)
	var mix:String = mix_edit.text.strip_edges()
	var suffix := ("-" + mix) if mix != "" else ""
	var metadata_path := "res://assets/data/songs/%s/%s-metadata%s.json" % [song_id, song_id, suffix]
	var chart_path := "res://assets/data/songs/%s/%s-chart%s.json" % [song_id, song_id, suffix]
	if !FileAccess.file_exists(metadata_path) or !FileAccess.file_exists(chart_path):
		status.text = "Este mix não possui metadata/chart JSON"
		return
	Song.configure(song_id, mix, difficulty)
	var err = Global.change_scene("res://scenes/SpriteMapLoading.tscn")
	if err != OK:
		status.text = "Não foi possível abrir o carregamento"

func _listen_for_key(action:String) -> void:
	listening_action = action
	status.text = "Pressione uma tecla para %s" % action

func _unhandled_input(event:InputEvent) -> void:
	if listening_action == "" or !(event is InputEventKey) or !event.pressed or event.echo:
		return
	Preferences.set_keybind(listening_action, event)
	listening_action = ""
	status.text = "Tecla atualizada"
	_update_key_labels()
	get_viewport().set_input_as_handled()

func _reset_keys() -> void:
	Preferences.reset_keybinds()
	_update_key_labels()
	status.text = "Teclas restauradas"

func _update_key_labels() -> void:
	for action in key_buttons:
		var event:InputEvent = Preferences.get_keybind(action)
		key_buttons[action].text = event.as_text() if event else "Sem tecla"
