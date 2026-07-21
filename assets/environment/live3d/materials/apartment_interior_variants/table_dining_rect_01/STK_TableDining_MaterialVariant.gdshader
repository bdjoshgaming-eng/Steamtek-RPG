shader_type spatial;
render_mode depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_color_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D metallic_roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D emission_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D mask_tabletop : hint_default_black, filter_linear_mipmap;
uniform sampler2D mask_frame_paint : hint_default_black, filter_linear_mipmap;
uniform sampler2D mask_accent_metal : hint_default_black, filter_linear_mipmap;
uniform sampler2D mask_emission_cyan : hint_default_black, filter_linear_mipmap;
uniform sampler2D mask_emission_magenta : hint_default_black, filter_linear_mipmap;

uniform vec4 tabletop_tint : source_color = vec4(0.10, 0.14, 0.18, 1.0);
uniform float tabletop_strength : hint_range(0.0, 1.0) = 0.0;
uniform float tabletop_brightness : hint_range(0.5, 1.5) = 1.0;
uniform float tabletop_roughness_offset : hint_range(-0.2, 0.2) = 0.0;
uniform float tabletop_metallic_offset : hint_range(-0.15, 0.15) = 0.0;

uniform vec4 frame_tint : source_color = vec4(0.055, 0.10, 0.13, 1.0);
uniform float frame_strength : hint_range(0.0, 1.0) = 0.0;
uniform float frame_brightness : hint_range(0.5, 1.5) = 1.0;
uniform float frame_roughness_offset : hint_range(-0.2, 0.2) = 0.0;
uniform float frame_metallic_offset : hint_range(-0.15, 0.15) = 0.0;

uniform vec4 accent_metal_tint : source_color = vec4(0.45, 0.22, 0.09, 1.0);
uniform float accent_metal_strength : hint_range(0.0, 1.0) = 0.0;
uniform float accent_metal_brightness : hint_range(0.5, 1.5) = 1.0;
uniform float accent_metal_roughness_offset : hint_range(-0.2, 0.2) = 0.0;
uniform float accent_metal_metallic_offset : hint_range(-0.15, 0.15) = 0.0;

uniform vec4 accent_cyan_tint : source_color = vec4(0.02, 0.57, 0.68, 1.0);
uniform float emission_cyan_strength : hint_range(0.0, 4.0) = 0.90;
uniform float emission_cyan_enabled : hint_range(0.0, 1.0) = 1.0;
uniform vec4 accent_magenta_tint : source_color = vec4(0.72, 0.07, 0.43, 1.0);
uniform float emission_magenta_strength : hint_range(0.0, 4.0) = 0.55;
uniform float emission_magenta_enabled : hint_range(0.0, 1.0) = 1.0;

uniform float roughness_gain : hint_range(0.75, 1.5) = 1.25;
uniform float locked_roughness_floor : hint_range(0.0, 1.0) = 0.64;
uniform float tabletop_roughness_floor : hint_range(0.0, 1.0) = 0.76;
uniform float frame_roughness_floor : hint_range(0.0, 1.0) = 0.70;
uniform float accent_metal_roughness_floor : hint_range(0.0, 1.0) = 0.54;

vec3 recolor_preserving_luminance(vec3 source, vec3 tint, float brightness) {
	const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);
	float source_luminance = max(dot(source, LUMA), 0.02);
	float tint_luminance = max(dot(tint, LUMA), 0.02);
	return clamp(tint * (source_luminance / tint_luminance) * brightness, vec3(0.0), vec3(1.0));
}

void fragment() {
	vec4 base_sample = texture(base_color_texture, UV);
	vec3 packed_mr = texture(metallic_roughness_texture, UV).rgb;
	vec3 source_emission = texture(emission_texture, UV).rgb;
	float tabletop_mask = texture(mask_tabletop, UV).r;
	float frame_mask = texture(mask_frame_paint, UV).r;
	float accent_metal_mask = texture(mask_accent_metal, UV).r;
	float cyan_mask = texture(mask_emission_cyan, UV).r;
	float magenta_mask = texture(mask_emission_magenta, UV).r;

	vec3 albedo = base_sample.rgb;
	vec3 tabletop_color = recolor_preserving_luminance(albedo, tabletop_tint.rgb, tabletop_brightness);
	albedo = mix(albedo, tabletop_color, tabletop_mask * tabletop_strength);
	vec3 frame_color = recolor_preserving_luminance(albedo, frame_tint.rgb, frame_brightness);
	albedo = mix(albedo, frame_color, frame_mask * frame_strength);
	vec3 metal_color = recolor_preserving_luminance(albedo, accent_metal_tint.rgb, accent_metal_brightness);
	albedo = mix(albedo, metal_color, accent_metal_mask * accent_metal_strength);

	float roughness = max(packed_mr.g * roughness_gain, locked_roughness_floor);
	roughness = mix(roughness, max(packed_mr.g * roughness_gain, tabletop_roughness_floor + tabletop_roughness_offset), tabletop_mask);
	roughness = mix(roughness, max(packed_mr.g * roughness_gain, frame_roughness_floor + frame_roughness_offset), frame_mask);
	roughness = mix(roughness, max(packed_mr.g * roughness_gain, accent_metal_roughness_floor + accent_metal_roughness_offset), accent_metal_mask);

	float metallic = min(packed_mr.b * 0.80, 0.72);
	metallic = mix(metallic, clamp(min(packed_mr.b * 0.65, 0.30) + tabletop_metallic_offset, 0.0, 0.40), tabletop_mask);
	metallic = mix(metallic, clamp(min(packed_mr.b * 0.75, 0.42) + frame_metallic_offset, 0.0, 0.50), frame_mask);
	metallic = mix(metallic, clamp(max(packed_mr.b * 0.85, 0.48) + accent_metal_metallic_offset, 0.20, 0.82), accent_metal_mask);

	float emission_luminance = dot(source_emission, vec3(0.2126, 0.7152, 0.0722));
	vec3 emission = accent_cyan_tint.rgb * emission_luminance * cyan_mask * emission_cyan_strength * emission_cyan_enabled;
	emission += accent_magenta_tint.rgb * emission_luminance * magenta_mask * emission_magenta_strength * emission_magenta_enabled;

	ALBEDO = albedo;
	ROUGHNESS = clamp(roughness, 0.0, 1.0);
	METALLIC = clamp(metallic, 0.0, 1.0);
	SPECULAR = 0.18;
	EMISSION = emission;
}
