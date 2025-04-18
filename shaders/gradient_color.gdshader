shader_type canvas_item;

uniform float alpha_force:hint_range(0.0, 2.0) = 1.0;
uniform float uv_position:hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (UV.y >= uv_position) {
		color.a -= alpha_force * (UV.y - uv_position);
	}
	COLOR = color;
}
