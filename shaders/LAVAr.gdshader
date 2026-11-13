
shader_type canvas_item;

uniform vec2 origin = vec2(0.0, 0.0);

uniform float speed : hint_range(0.0, 5.0) = 0.5;
uniform float scale : hint_range(0.1, 20.0) = 4.0;

uniform float surface_height : hint_range(0.0, 1.0) = 0.35;
uniform float wave_strength : hint_range(0.0, 0.2) = 0.035;
uniform float wave_frequency : hint_range(0.1, 30.0) = 6.0;
uniform float wave_detail : hint_range(0.0, 1.0) = 0.35;

uniform float noise_scale : hint_range(0.1, 20.0) = 5.0;
uniform float noise_strength : hint_range(0.0, 0.2) = 0.035;

uniform float edge_softness : hint_range(0.001, 0.1) = 0.008;

uniform vec4 lava_color : source_color = vec4(0.9, 0.08, 0.01, 1.0);
uniform vec4 hot_color : source_color = vec4(1.0, 0.55, 0.02, 1.0);
uniform vec4 dark_color : source_color = vec4(0.12, 0.008, 0.0, 1.0);

uniform float hot_threshold : hint_range(0.0, 1.0) = 0.65;
uniform float hot_strength : hint_range(0.0, 2.0) = 0.5;

float hash(vec2 p) {
	return fract(
		sin(dot(p, vec2(127.1, 311.7))) *
		43758.5453
	);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	f = f * f * (3.0 - 2.0 * f);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(
		mix(a, b, f.x),
		mix(c, d, f.x),
		f.y
	);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;

	for (int i = 0; i < 5; i++) {
		value += noise(p) * amplitude;
		p *= 2.0;
		amplitude *= 0.5;
	}

	return value;
}

void fragment() {
	float time = TIME * speed;

	vec2 uv = UV;

	vec2 lava_position = (uv + origin) * scale;

	lava_position += vec2(
		time * 0.35,
		time * 0.18
	);

	float large_noise = fbm(lava_position);

	float detail_noise = fbm(
		lava_position * 2.0 -
		vec2(time * 0.25, time * 0.15)
	);

	float lava_noise = mix(
		large_noise,
		detail_noise,
		0.25
	);

	// Ruido independiente para deformar la superficie.
	float edge_noise = fbm(
		(uv + origin) * noise_scale +
		vec2(
			time * 0.2,
			-time * 0.1
		)
	);

	edge_noise = (edge_noise - 0.5) * noise_strength;

	// Primera onda.
	float wave_1 = sin(
		(uv.x + origin.x) * wave_frequency +
		time * 1.7 +
		large_noise * 2.5
	);

	// Segunda onda más pequeña.
	float wave_2 = sin(
		(uv.x + origin.x) *
		wave_frequency *
		1.73 -
		time * 1.25 +
		detail_noise * 3.0
	);

	// Combinar ondas.
	float wave = mix(
		wave_1,
		wave_2,
		wave_detail
	);

	wave *= wave_strength;

	// Posición final de la superficie.
	float surface = surface_height;
	surface += wave;
	surface += edge_noise;

	// Borde limpio pero ligeramente suavizado.
	float alpha = smoothstep(
		surface - edge_softness,
		surface + edge_softness,
		uv.y
	);

	// Color base de la lava.
	vec3 color = mix(
		dark_color.rgb,
		lava_color.rgb,
		lava_noise
	);

	// Partes calientes.
	float hot = smoothstep(
		hot_threshold,
		1.0,
		lava_noise
	);

	color = mix(
		color,
		hot_color.rgb,
		hot * hot_strength
	);

	COLOR = vec4(
		color,
		alpha
	);
}
