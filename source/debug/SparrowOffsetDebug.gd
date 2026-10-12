extends Node2D

# lint:ignore res_path
const ATLAS_PATH:String = "res://assets/shared/images/holdCoverPurple"
const FRAME_NAMES:Array[String] = [
	"holdCoverStartPurple0001",
	"holdCoverPurple0001",
	"holdCoverPurple0002",
	"holdCoverEndPurple0001",
	"holdCoverEndPurple0002",
	"holdCoverEndPurple0005"
]
const COLUMNS:int = 3
const SCALE_FACTOR:float = 0.35
const CARD_ORIGIN:Vector2 = Vector2(40, 40)
const CARD_STEP:Vector2 = Vector2(180, 170)

var frame_textures:Array[Texture2D] = []

func _ready() -> void:
	var atlas_frames:Dictionary = XML.get_atlas_frames(ATLAS_PATH)
	for frame_name:String in FRAME_NAMES:
		var texture:Texture2D = atlas_frames.get(frame_name) as Texture2D
		if texture == null:
			continue
		if texture.get_size() != Vector2(300, 400):
			push_error("SparrowOffsetDebug: tamanho logico inesperado em %s: %s" % [frame_name, texture.get_size()])
		frame_textures.append(texture)
		var sprite:Sprite2D = Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.scale = Vector2.ONE * SCALE_FACTOR
		sprite.position = _card_origin(frame_textures.size() - 1)
		add_child(sprite)
		var label:Label = Label.new()
		label.text = frame_name
		label.position = sprite.position + Vector2(0, -28)
		add_child(label)
	queue_redraw()

func _card_origin(index:int) -> Vector2:
	return CARD_ORIGIN + Vector2(index % COLUMNS, index / COLUMNS) * CARD_STEP

func _draw() -> void:
	for index:int in range(frame_textures.size()):
		var texture:Texture2D = frame_textures[index]
		var origin:Vector2 = _card_origin(index)
		var frame_size:Vector2 = texture.get_size() * SCALE_FACTOR
		draw_rect(Rect2(origin, frame_size), Color(0.2, 0.8, 1.0, 0.9), false, 2.0)
		draw_line(
			origin + Vector2(frame_size.x * 0.5, 0.0),
			origin + Vector2(frame_size.x * 0.5, frame_size.y),
			Color(1.0, 0.3, 0.3, 0.8), 1.0)
		draw_line(
			origin + Vector2(0.0, frame_size.y * 0.5),
			origin + Vector2(frame_size.x, frame_size.y * 0.5),
			Color(1.0, 0.3, 0.3, 0.8), 1.0)
