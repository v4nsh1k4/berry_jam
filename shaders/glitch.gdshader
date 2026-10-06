shader_type canvas_item;
// Chapter 3 panel breakdown: horizontal bands of what is already drawn get
// torn sideways, a few blocks invert, a little static. Reads the screen
// behind it (hint_screen_texture), which the Compatibility renderer supports.
// `strength` 0..1; at 0 the panel is untouched.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453);
}

void fragment() {
	// New tear pattern a few times a second (stop-motion, like the ink).
	float step_t = floor(TIME * 7.0);
	float band = floor(SCREEN_UV.y * 48.0);
	float r = hash(vec2(band, step_t));
	vec2 uv = SCREEN_UV;
	float torn = step(1.0 - strength * 0.35, r);
	uv.x += torn * (hash(vec2(band + 3.0, step_t)) - 0.5) * 0.06 * strength;
	vec4 col = texture(screen_tex, uv);
	// A few blocks print in negative, in black and white only (inverting the
	// red player would make cyan, and red is the only colour allowed).
	vec2 block = floor(SCREEN_UV * vec2(24.0, 14.0));
	float inv = step(1.0 - strength * 0.035, hash(block + step_t));
	float luma = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	col.rgb = mix(col.rgb, vec3(1.0 - luma), inv);
	// Speckle of static.
	float speck = step(1.0 - strength * 0.03, hash(SCREEN_UV * 900.0 + step_t));
	col.rgb = mix(col.rgb, vec3(0.06, 0.05, 0.07), speck);
	COLOR = vec4(col.rgb, 1.0);
}
