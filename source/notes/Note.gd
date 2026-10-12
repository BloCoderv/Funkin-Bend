extends TextureRect
class_name Note

@onready var sustain: TextureRect = $Sustain
@onready var sustain_end: TextureRect = $Sustain_end

var strum_data: int = 0
var data: int = 0
var time: float = 0.0
var length: float = 0.0
var full_length: float = 0.0
var hold_started_at: float = -1.0
var hold_drop_handled: bool = false
var hold_score_remainder: float = 0.0
var must_press: bool = true
var was_hit: bool = false
var is_sustain: bool = false
var can_hit: bool = false
var too_late: bool = false
var is_holding: bool = false
var pooled: bool = false
var pivot: Vector2 = Vector2.ZERO
var texture_size: Vector2 = Vector2.ZERO
var end_tex: AtlasTexture = null

func _ready() -> void:
	configure_visuals()

## Reaplica os visuais depois de configurar uma nota reutilizada pelo pool.
func configure_visuals() -> void:
	Global.note_style.build_note_sprite(self, strum_data)
	if !Preferences.opponent_notes and data < StrumGroup.strum_notes.size() and StrumGroup.strum_notes[data].opponent:
		texture = null

	if texture != null:
		texture_size = size * scale
		pivot = -texture_size / 2.0 + Global.note_style.get_note_offsets()
	else:
		texture_size = Vector2.ZERO

	if is_sustain and texture != null:
		setup_sustain()
	else:
		sustain.hide()
		sustain_end.hide()

func setup_sustain() -> void:
	var textures: Array = Global.get_hold_textures(strum_data)
	if texture == null or textures.size() < 2 or textures[0] == null or textures[1] == null:
		sustain.hide()
		sustain_end.hide()
		return
	sustain.show()
	sustain_end.show()
	sustain.texture = textures[0] as Texture2D
	sustain.size.x = sustain.texture.get_size().x
	sustain.show_behind_parent = true
	var note_scale: float = maxf(absf(scale.x), 0.001)
	var hold_scale: float = Global.note_style.get_hold_note_scale()
	var hold_offset: Vector2 = Global.note_style.get_hold_note_offsets() / note_scale
	sustain.scale = Vector2.ONE * (hold_scale / note_scale)
	sustain.position = hold_offset

	if Preferences.sustain_behind_strum:
		sustain.z_index = -2
		sustain_end.z_index = -2

	end_tex = AtlasTexture.new()
	end_tex.atlas = textures[1] as Texture2D
	sustain_end.texture = end_tex
	sustain_end.scale = Vector2.ONE * (hold_scale / note_scale)
	sustain_end.position = hold_offset
	sustain_end.show_behind_parent = true
	change_sustain_height(NoteGroup.get_sustain_height(length))

func get_sustain_size() -> float:
	var end_height: float = Global.note_style.get_hold_note_end_height()
	return sustain.size.y + (end_height + end_tex.margin.position.y) if end_tex != null else sustain.size.y

func change_sustain_height(new_height: float) -> void:
	if !is_sustain or !is_instance_valid(sustain) or end_tex == null:
		return
	var new_size: float = maxf(new_height, 0.0)
	var note_scale: float = maxf(absf(scale.x), 0.001)
	var hold_scale: float = Global.note_style.get_hold_note_scale()
	var end_height: float = Global.note_style.get_hold_note_end_height()
	sustain.size.y = maxf(new_size - end_height, 0.0)
	end_tex.margin.position.y = minf(new_size - end_height, 0.0)
	var signed_scale: float = hold_scale / note_scale
	if data < StrumGroup.strum_notes.size() and StrumGroup.strum_notes[data].downscroll:
		sustain.scale.y = -signed_scale
		sustain_end.scale.y = -signed_scale
		sustain_end.position.y = -(sustain.size.y - sustain.position.y)
	else:
		sustain.scale.y = signed_scale
		sustain_end.scale.y = signed_scale
		sustain_end.position.y = sustain.size.y + sustain.position.y
