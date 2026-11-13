shader_type canvas_item;

uniform sampler2D pattern : source_color, repeat_enable;
uniform float texture_size = 16.0;

void fragment() {
	vec2 pixel_uv = UV * texture_size;
	COLOR = texture(pattern, fract(pixel_uv));
}
