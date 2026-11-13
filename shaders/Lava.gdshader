shader_type canvas_item;

uniform vec4 color1 : source_color = vec4(1.0, 0.3, 0.1, 1.0);
uniform vec4 color2 : source_color = vec4(0.2, 0.0, 0.3, 1.0);

uniform float speed = 0.5;
uniform float scale = 4.0;
uniform float threshold = 0.2;

void fragment() {
	vec2 uv = UV * scale;

	float t = TIME * speed;

	float blob1 = sin(uv.x + t) + cos(uv.y - t);
	float blob2 = sin(uv.x * 1.7 - t * 1.3) + cos(uv.y * 1.4 + t);
	float blob3 = sin(length(uv - vec2(sin(t), cos(t))) * 3.0);

	float field = (blob1 + blob2 + blob3) / 3.0;

	float lava = smoothstep(threshold, threshold + 0.3, field);

	COLOR = mix(color2, color1, lava);
}
