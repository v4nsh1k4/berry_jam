shader_type canvas_item;
// Ink blob wipe: a noisy-edged circle plus flung droplets that grow from
// `center` as `progress` goes 0 -> 1. At 1 the screen is fully covered.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center = vec2(0.5, 0.5);
uniform vec2 rect_size = vec2(1280.0, 720.0);
uniform vec4 ink_color : source_color = vec4(0.06, 0.05, 0.07, 1.0);
uniform float seed = 0.0;

float hash(float n) {
	return fract(sin(n * 12.9898 + seed * 78.233) * 43758.5453);
}

// Smooth noise that wraps every `period` units, so the blob edge has no seam.
float periodic_noise(float x, float period) {
	float i = floor(x);
	float f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(hash(mod(i, period)), hash(mod(i + 1.0, period)), f);
}

void fragment() {
	float aspect = rect_size.x / rect_size.y;
	vec2 p = (UV - center) * vec2(aspect, 1.0);
	float d = length(p);
	float a = (atan(p.y, p.x) + PI) / TAU;
	float n = 0.65 * periodic_noise(a * 11.0, 11.0) + 0.35 * periodic_noise(a * 23.0, 23.0);

	float r = progress * 2.7;
	float edge = r * (0.8 + 0.35 * n);
	float aa = 0.004;
	float m = 1.0 - smoothstep(edge - aa, edge + aa, d);

	for (int i = 0; i < 12; i++) {
		float fi = float(i);
		float ang = hash(fi) * TAU;
		vec2 dir = vec2(cos(ang), sin(ang));
		float dist = (0.55 + hash(fi + 1.7) * 0.8) * r;
		float size = (0.015 + hash(fi + 3.1) * 0.05) * smoothstep(0.0, 0.3, progress);
		float drop = 1.0 - smoothstep(size - aa, size + aa, length(p - dir * dist));
		m = max(m, drop);
	}
	COLOR = vec4(ink_color.rgb, ink_color.a * m);
}
