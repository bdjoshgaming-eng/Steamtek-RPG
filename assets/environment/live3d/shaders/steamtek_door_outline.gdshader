shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_thickness : hint_range(0.005, 0.1) = 0.025;
uniform float pulse_speed : hint_range(0.2, 4.0) = 0.6;
uniform float pulse_min : hint_range(0.0, 1.0) = 0.08;
uniform float pulse_max : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec2 uv = UV;
	float dist_to_edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float frame = 1.0 - smoothstep(outline_thickness, outline_thickness * 1.6, dist_to_edge);
	float pulse = mix(pulse_min, pulse_max, (sin(TIME * pulse_speed * TAU) + 1.0) * 0.5);
	ALBEDO = outline_color.rgb * pulse;
	ALPHA = frame * outline_color.a;
}
