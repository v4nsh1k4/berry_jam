shader_type canvas_item;
// Off-white paper with a rotated halftone dot screen that darkens toward
// the bottom and the corners. Cheap enough for web (Compatibility).

uniform vec4 paper_color : source_color = vec4(0.94, 0.91, 0.84, 1.0);
uniform vec4 ink_color : source_color = vec4(0.06, 0.05, 0.07, 1.0);
uniform vec2 rect_size = vec2(1184.0, 528.0);
uniform float dot_spacing = 7.0;
uniform float shade_top = 0.04;
uniform float shade_bottom = 0.22;

void fragment() {
	vec2 px = UV * rect_size;
	vec2 r = mat2(vec2(0.7071, -0.7071), vec2(0.7071, 0.7071)) * px;
	vec2 cell = fract(r / dot_spacing) - 0.5;
	float shade = mix(shade_top, shade_bottom, UV.y);
	shade += smoothstep(0.35, 0.75, distance(UV, vec2(0.5))) * 0.3;
	float radius = sqrt(clamp(shade, 0.0, 1.0)) * 0.56;
	float dot_mask = 1.0 - smoothstep(radius - 0.08, radius + 0.08, length(cell));
	COLOR = mix(paper_color, ink_color, dot_mask * 0.6);
}
