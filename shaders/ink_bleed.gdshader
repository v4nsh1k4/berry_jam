shader_type canvas_item;
// Ink seeping in from the panel border. `damage` 0..1 sets how far it
// creeps; noise makes it blotchy. Transparent everywhere else.

uniform float damage : hint_range(0.0, 1.0) = 0.0;
uniform vec2 rect_size = vec2(1184.0, 528.0);
uniform vec4 ink_color : source_color = vec4(0.06, 0.05, 0.07, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x);
	float b = mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x);
	return mix(a, b, f.y);
}

void fragment() {
	if (damage <= 0.001) {
		discard;
	}
	vec2 px = UV * rect_size;
	float edge = min(min(px.x, rect_size.x - px.x), min(px.y, rect_size.y - px.y));
	// Ink and blots never reach further than ~90 * damage px from the edge
	// (reach <= 83 * damage): skip the noise everywhere else.
	if (edge > 92.0 * damage + 4.0) {
		discard;
	}
	float drift = TIME * 0.015;
	float n = noise(px / 42.0 + drift) * 0.65 + noise(px / 12.0 - drift) * 0.35;
	float reach = damage * 52.0 * n * n * 1.6;
	float m = 1.0 - smoothstep(reach - 2.0, reach + 1.5, edge);
	// Loose blots a little further in.
	float blot = step(0.92 - damage * 0.05, noise(px / 17.0 + 3.7)) * (1.0 - smoothstep(0.0, 90.0 * damage, edge));
	m = max(m, blot);
	COLOR = vec4(ink_color.rgb, ink_color.a * m);
}
