shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_color_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D mask_frame_paint : hint_default_black, filter_linear_mipmap;
uniform sampler2D mask_shelf_paint : hint_default_black, filter_linear_mipmap;
uniform sampler2D mask_accent_powered : hint_default_black, filter_linear_mipmap;

uniform vec4 frame_tint : source_color = vec4(0.055, 0.10, 0.13, 1.0);
uniform vec4 shelf_tint : source_color = vec4(0.035, 0.055, 0.065, 1.0);
uniform vec4 accent_tint : source_color = vec4(0.02, 0.57, 0.68, 1.0);
uniform float frame_strength : hint_range(0.0, 1.0) = 0.0;
uniform float shelf_strength : hint_range(0.0, 1.0) = 0.0;
uniform float accent_strength : hint_range(0.0, 1.0) = 1.0;
uniform float frame_brightness : hint_range(0.5, 1.5) = 1.0;
uniform float shelf_brightness : hint_range(0.5, 1.5) = 1.0;
uniform float frame_roughness_offset : hint_range(-0.2, 0.2) = 0.0;
uniform float shelf_roughness_offset : hint_range(-0.2, 0.2) = 0.0;
uniform float frame_metallic_offset : hint_range(-0.15, 0.15) = 0.0;
uniform float emission_strength : hint_range(0.0, 4.0) = 1.10;
uniform float emission_enabled : hint_range(0.0, 1.0) = 1.0;

vec3 recolor_preserving_luminance(vec3 source, vec3 tint, float brightness) {
	const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);
	float source_luminance = max(dot(source, LUMA), 0.025);
	float tint_luminance = max(dot(tint, LUMA), 0.025);
	return clamp(tint * (source_luminance / tint_luminance) * brightness, vec3(0.0), vec3(1.0));
}

void fragment() {
	vec3 albedo = texture(base_color_texture, UV).rgb;
	float frame_mask = texture(mask_frame_paint, UV).r;
	float shelf_mask = texture(mask_shelf_paint, UV).r;
	float accent_mask = texture(mask_accent_powered, UV).r;

	vec3 frame_color = recolor_preserving_luminance(albedo, frame_tint.rgb, frame_brightness);
	albedo = mix(albedo, frame_color, frame_mask * frame_strength);
	vec3 shelf_color = recolor_preserving_luminance(albedo, shelf_tint.rgb, shelf_brightness);
	albedo = mix(albedo, shelf_color, shelf_mask * shelf_strength);
	vec3 accent_color = recolor_preserving_luminance(albedo, accent_tint.rgb, 1.0);
	albedo = mix(albedo, accent_color, accent_mask * accent_strength);

	float roughness = mix(0.74, 0.68 + frame_roughness_offset, frame_mask);
	roughness = mix(roughness, 0.76 + shelf_roughness_offset, shelf_mask);
	float metallic = mix(0.08, clamp(0.18 + frame_metallic_offset, 0.0, 0.35), frame_mask);

	ALBEDO = albedo;
	ROUGHNESS = clamp(roughness, 0.0, 1.0);
	METALLIC = metallic;
	SPECULAR = 0.20;
	EMISSION = accent_tint.rgb * accent_mask * emission_strength * emission_enabled;
}
