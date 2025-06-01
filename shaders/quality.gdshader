shader_type canvas_item;

uniform sampler2D screen_TEXTURE : hint_screen_texture;
uniform float quality : hint_range(1.0, 16.0) = 1.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 size = vec2(1280.0 / quality, 720.0 / quality);
	uv = floor(uv * size) / size;
	COLOR = texture(screen_TEXTURE, uv);
}
