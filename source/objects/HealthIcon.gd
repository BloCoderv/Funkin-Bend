extends TextureRect
class_name HealthIcon

var icon:Texture2D = null:
	set(v):
		icon = v
		_on_change_icon()

var frames:int = 2 # DEFAULT ICON FRAME

func _ready():
	_on_change_icon()

func load_icon(icon_id:String):
	var icon_path = "res://assets/images/icons/icon-%s.png" % icon_id
	if FileAccess.file_exists(icon_path):
		icon = load(icon_path)
	else:
		icon = Global.ICON_NONE

func change_frame(frame:int):
	texture.position.x = texture.size.x * frame

func _on_change_icon():
	if !icon: return
	
	var tex:AtlasTexture = AtlasTexture.new()
	tex.atlas = icon
	tex.region.size.x = icon.get_size().x / frames
	texture = tex
	position.y = -icon.get_size().y / 2
	pivot_offset.y = icon.get_size().y / 2
	if !flip_h: pivot_offset.x = icon.get_size().x * .30
	else: pivot_offset.x = icon.get_size().x * .20
	
	icon = null

func _process(delta):
	var mult:float = lerp(1.0, scale.x, exp(-delta * 9))
	scale = Vector2(mult, mult)
