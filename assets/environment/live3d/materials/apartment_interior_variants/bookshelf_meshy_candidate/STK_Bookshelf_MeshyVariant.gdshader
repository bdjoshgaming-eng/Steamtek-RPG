shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_color_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D metallic_roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D emission_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D mask_frame_paint : hint_default_black, filter_linear_mipmap;
uniform sampler2D mask_shelf_paint : hint_default_black, filter_linear_mipmap;
uniform sampler2D mask_accent_powered : hint_default_black, filter_linear_mipmap;

uniform vec4 frame_tint : source_color = vec4(0.055, 0.10, 0.13, 1.0);
uniform vec4 shelf_tint : source_color = vec4(0.035, 0.055, 0.065, 1.0);
uniform vec4 accent_tint : source_color = vec4(0.02, 0.57, 0.68, 1.0);
uniform float frame_strength : hint_range(0.0, 1.0) = 0.0;
uniform float shelf_strength : hint_range(0.0, 1.0) = 0.0;
uniform float accent_strength : hint_range(0.0, 1.0) = 0.0;
uniform float frame_brightness : hint_range(0.5, 1.5) = 1.0;
uniform float shelf_brightness : hint_range(0.5, 1.5) = 1.0;
uniform float midtone_lift : hint_range(0.0, 1.0) = 0.10;
uniform float midtone_gamma : hint_range(0.5, 1.0) = 0.86;
uniform float roughness_gain : hint_range(0.5, 2.0) = 1.25;
uniform float locked_roughness_floor : hint_range(0.0, 1.0) = 0.80;
uniform float hardware_roughness_floor : hint_range(0.0, 1.0) = 0.60;
uniform float frame_roughness_floor : hint_range(0.0, 1.0) = 0.74;
uniform float shelf_roughness_floor : hint_range(0.0, 1.0) = 0.80;
uniform float frame_roughness_offset : hint_range(-0.2, 0.2) = 0.0;
uniform float shelf_roughness_offset : hint_range(-0.2, 0.2) = 0.0;
uniform float metallic_gain : hint_range(0.0, 1.5) = 1.0;
uniform float frame_metallic_offset : hint_range(-0.15, 0.15) = 0.0;
uniform float specular_level : hint_range(0.0, 1.0) = 0.18;
uniform float emission_strength : hint_range(0.0, 4.0) = 0.90;
uniform float emission_enabled : hint_range(0.0, 1.0) = 1.0;

vec3 recolor_preserving_luminance(vec3 source, vec3 tint, float brightness) {
	const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);
	float source_luminance = max(dot(source, LUMA), 0.018);
	float tint_luminance = max(dot(tint, LUMA), 0.018);
	return clamp(tint * (source_luminance / tint_luminance) * brightness, vec3(0.0), vec3(1.0));
}

void fragment() {
	vec4 source_base = texture(base_color_texture, UV);
	vec3 mr = texture(metallic_roughness_texture, UV).rgb;
	float frame_mask = texture(mask_frame_paint, UV).r;
	float shelf_mask = texture(mask_shelf_paint, UV).r;
	float accent_mask = texture(mask_accent_powered, UV).r;

	vec3 source_safe = max(source_base.rgb, vec3(0.0001));
	vec3 albedo = mix(source_base.rgb, pow(source_safe, vec3(midtone_gamma)), midtone_lift);
	vec3 frame_color = recolor_preserving_luminance(albedo, frame_tint.rgb, frame_brightness);
	albedo = mix(albedo, frame_color, frame_mask * frame_strength);
	vec3 shelf_color = recolor_preserving_luminance(albedo, shelf_tint.rgb, shelf_brightness);
	albedo = mix(albedo, shelf_color, shelf_mask * shelf_strength);
	vec3 accent_color = recolor_preserving_luminance(albedo, accent_tint.rgb, 1.0);
	albedo = mix(albedo, accent_color, accent_mask * accent_strength);

	float metallic = clamp(mr.b * metallic_gain, 0.0, 1.0);
	float frame_metallic = clamp(metallic + frame_metallic_offset, 0.0, 0.35);
	metallic = mix(metallic, frame_metallic, frame_mask);
	float locked_floor = mix(locked_roughness_floor, hardware_roughness_floor, step(0.46, metallic));
	float roughness_floor = mix(locked_floor, frame_roughness_floor + frame_roughness_offset, frame_mask);
	roughness_floor = mix(roughness_floor, shelf_roughness_floor + shelf_roughness_offset, shelf_mask);
	vec3 source_emission = texture(emission_texture, UV).rgb * accent_mask;
	float source_emission_level = max(source_emission.r, max(source_emission.g, source_emission.b));
	vec3 recolored_emission = accent_tint.rgb * source_emission_level;
	vec3 final_emission = mix(source_emission, recolored_emission, accent_mask * accent_strength);

	ALBEDO = albedo;
	METALLIC = metallic;
	ROUGHNESS = clamp(max(mr.g * roughness_gain, roughness_floor), 0.0, 1.0);
	SPECULAR = specular_level;
	EMISSION = final_emission * emission_strength * emission_enabled;
}
