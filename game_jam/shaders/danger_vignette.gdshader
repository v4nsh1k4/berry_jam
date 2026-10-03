shader_type canvas_item;
// Red vignette for Crawler danger: only the outer edge of the screen, never
// a full tint. `strength` 0..1, `pulse` 0..1 (heartbeat).

uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(0.784, 0.063, 0.18, 1.0);

void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.0, 1.25);
	float edge = smoothstep(0.42, 0.72, length(p));
	float a = edge * strength * (0.6 + 0.4 * pulse) * 0.42;
	COLOR = vec4(tint.rgb, a);
}
