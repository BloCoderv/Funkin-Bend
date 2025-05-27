
shader_type canvas_item;

uniform float threshold:hint_range(0.0, 2.0) = 0.1;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	if (distance(color.rgb, vec3(1.0)) < threshold) {
		float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
		color.a = 1.0 - luminance;
		color.rgb -= luminance;
	}
	COLOR = color;
}
