shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

uniform vec4 rain_color : source_color = vec4(0.4, 0.55, 0.7, 0.35);
uniform float streak_speed : hint_range(0.5, 4.0) = 1.8;
uniform float streak_density : hint_range(4.0, 40.0) = 18.0;
uniform float streak_thickness : hint_range(0.01, 0.15) = 0.04;
uniform float drip_speed : hint_range(0.1, 2.0) = 0.6;
uniform float drip_density : hint_range(2.0, 12.0) = 5.0;
uniform float lightning_boost : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float rain_streak(vec2 uv, float time) {
	float col_id = floor(uv.x * streak_density);
	float offset = hash(vec2(col_id, 0.0));
	float speed_var = 0.7 + offset * 0.6;
	float x_center = (col_id + 0.5) / streak_density;
	float x_dist = abs(uv.x - x_center) * streak_density;
	float x_mask = smoothstep(streak_thickness, 0.0, x_dist);
	float y = fract(uv.y - time * streak_speed * speed_var + offset * 10.0);
	float streak = x_mask * smoothstep(0.0, 0.15, y) * smoothstep(0.6, 0.15, y);
	return streak;
}

float rain_drip(vec2 uv, float time) {
	float col_id = floor(uv.x * drip_density);
	float offset = hash(vec2(col_id, 42.0));
	float x_center = (col_id + 0.3 + offset * 0.4) / drip_density;
	float x_dist = abs(uv.x - x_center) * drip_density;
	float x_mask = smoothstep(0.08, 0.0, x_dist);
	float y = fract(uv.y - time * drip_speed * (0.8 + offset * 0.4) + offset * 5.0);
	float drip = x_mask * smoothstep(0.0, 0.05, y) * smoothstep(0.25, 0.05, y);
	return drip * 0.6;
}

void fragment() {
	vec2 uv = UV;
	float time = TIME;
	float streaks = rain_streak(uv, time);
	streaks += rain_streak(uv * vec2(1.3, 0.9) + vec2(0.37, 0.0), time * 0.85) * 0.5;
	float drips = rain_drip(uv, time);
	float combined = clamp(streaks + drips, 0.0, 1.0);
	float brightness = 1.0 + lightning_boost * 3.0;
	ALBEDO = rain_color.rgb * combined * brightness;
	ALPHA = combined * rain_color.a * brightness;
}
