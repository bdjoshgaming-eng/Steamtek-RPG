shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_color_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D metallic_roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D emission_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D mask_bedding_main : hint_default_black, filter_linear_mipmap;
uniform sampler2D mask_bedding_secondary : hint_default_black, filter_linear_mipmap;
uniform sampler2D mask_frame_paint : hint_default_black, filter_linear_mipmap;
uniform sampler2D mask_accent_powered : hint_default_black, filter_linear_mipmap;
uniform sampler2D mask_copper_locked : hint_default_black, filter_linear_mipmap;
uniform sampler2D mask_structural_locked : hint_default_black, filter_linear_mipmap;

uniform vec3 bedding_main_tint : source_color = vec3(0.30, 0.08, 0.12);
uniform vec3 bedding_secondary_tint : source_color = vec3(0.38, 0.36, 0.36);
uniform vec3 frame_paint_tint : source_color = vec3(0.08, 0.15, 0.19);
uniform vec3 accent_powered_tint : source_color = vec3(0.02, 0.57, 0.68);

uniform float bedding_main_strength : hint_range(0.0, 1.0) = 0.0;
uniform float bedding_secondary_strength : hint_range(0.0, 1.0) = 0.0;
uniform float frame_paint_strength : hint_range(0.0, 1.0) = 0.0;
uniform float accent_powered_strength : hint_range(0.0, 1.0) = 0.0;
uniform float bedding_main_brightness : hint_range(0.5, 1.5) = 1.0;
uniform float bedding_secondary_brightness : hint_range(0.5, 1.5) = 1.0;
uniform float frame_paint_brightness : hint_range(0.5, 1.5) = 1.0;
uniform float bedding_main_roughness_offset : hint_range(-0.2, 0.2) = 0.0;
uniform float bedding_secondary_roughness_offset : hint_range(-0.2, 0.2) = 0.0;
uniform float frame_paint_roughness_offset : hint_range(-0.2, 0.2) = 0.0;
uniform float frame_paint_metallic_offset : hint_range(-0.15, 0.15) = 0.0;
uniform float emission_strength : hint_range(0.0, 4.0) = 1.25;
uniform float emission_enabled : hint_range(0.0, 1.0) = 1.0;

vec3 recolor_preserving_luminance(vec3 source, vec3 tint, float brightness) {
	const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);
	float source_luminance = max(dot(source, LUMA), 0.025);
	float tint_luminance = max(dot(tint, LUMA), 0.025);
	return clamp(tint * (source_luminance / tint_luminance) * brightness, vec3(0.0), vec3(1.0));
}

void fragment() {
	vec4 base_sample = texture(base_color_texture, UV);
	vec3 packed_mr = texture(metallic_roughness_texture, UV).rgb;
	float source_roughness = packed_mr.g;
	float source_metallic = packed_mr.b;

	float main_mask = texture(mask_bedding_main, UV).r;
	float secondary_mask = texture(mask_bedding_secondary, UV).r;
	float frame_mask = texture(mask_frame_paint, UV).r;
	float accent_mask = texture(mask_accent_powered, UV).r;
	float copper_mask = texture(mask_copper_locked, UV).r;
	float structural_mask = texture(mask_structural_locked, UV).r;

	vec3 albedo = base_sample.rgb;
	albedo = mix(albedo, recolor_preserving_luminance(albedo, bedding_main_tint, bedding_main_brightness), main_mask * bedding_main_strength);
	albedo = mix(albedo, recolor_preserving_luminance(albedo, bedding_secondary_tint, bedding_secondary_brightness), secondary_mask * bedding_secondary_strength);
	albedo = mix(albedo, recolor_preserving_luminance(albedo, frame_paint_tint, frame_paint_brightness), frame_mask * frame_paint_strength);
	albedo = mix(albedo, recolor_preserving_luminance(albedo, accent_powered_tint, 1.0), accent_mask * accent_powered_strength);

	float roughness = source_roughness;
	roughness = mix(roughness, max(roughness, 0.90) + bedding_main_roughness_offset, main_mask);
	roughness = mix(roughness, max(roughness, 0.88) + bedding_secondary_roughness_offset, secondary_mask);
	roughness = mix(roughness, max(roughness, 0.75) + frame_paint_roughness_offset, frame_mask);
	roughness = mix(roughness, max(roughness, 0.68), structural_mask);
	roughness = mix(roughness, max(roughness, 0.58), copper_mask);
	roughness = mix(roughness, max(roughness, 0.65), accent_mask);

	float fabric_mask = max(main_mask, secondary_mask);
	float frame_metallic = clamp(source_metallic + frame_paint_metallic_offset, 0.0, 0.35);
	float metallic = mix(source_metallic, 0.0, fabric_mask);
	metallic = mix(metallic, frame_metallic, frame_mask);
	vec3 source_emission = texture(emission_texture, UV).rgb * 24.0;
	float source_emission_level = max(source_emission.r, max(source_emission.g, source_emission.b));
	float powered_level = max(source_emission_level, accent_mask);
	vec3 recolored_emission = accent_powered_tint * powered_level;
	vec3 final_emission = mix(source_emission, recolored_emission, accent_mask * accent_powered_strength);

	ALBEDO = albedo;
	METALLIC = metallic;
	ROUGHNESS = clamp(roughness, 0.0, 1.0);
	SPECULAR = 0.20;
	EMISSION = final_emission * emission_strength * emission_enabled;
}
