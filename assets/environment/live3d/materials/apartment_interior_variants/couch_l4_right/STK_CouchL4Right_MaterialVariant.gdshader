shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_color_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D metallic_roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D emission_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D mask_cushion_leather : hint_default_black, filter_linear_mipmap;
uniform sampler2D mask_frame_paint : hint_default_black, filter_linear_mipmap;
uniform sampler2D mask_accent_metal : hint_default_black, filter_linear_mipmap;

uniform vec3 cushion_tint : source_color = vec3(0.28, 0.055, 0.065);
uniform vec3 frame_tint : source_color = vec3(0.055, 0.10, 0.13);
uniform vec3 accent_tint : source_color = vec3(0.45, 0.22, 0.09);

uniform float cushion_strength : hint_range(0.0, 1.0) = 0.0;
uniform float frame_strength : hint_range(0.0, 1.0) = 0.0;
uniform float accent_strength : hint_range(0.0, 1.0) = 0.0;
uniform float cushion_brightness : hint_range(0.5, 1.5) = 1.0;
uniform float frame_brightness : hint_range(0.5, 1.5) = 1.0;
uniform float accent_brightness : hint_range(0.5, 1.5) = 1.0;
uniform float cushion_roughness_offset : hint_range(-0.2, 0.2) = 0.0;
uniform float frame_roughness_offset : hint_range(-0.2, 0.2) = 0.0;
uniform float accent_roughness_offset : hint_range(-0.2, 0.2) = 0.0;
uniform float frame_metallic_offset : hint_range(-0.15, 0.15) = 0.0;
uniform float accent_metallic_offset : hint_range(-0.15, 0.15) = 0.0;

vec3 recolor_preserving_luminance(vec3 source, vec3 tint, float brightness) {
	const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);
	float source_luminance = max(dot(source, LUMA), 0.025);
	float tint_luminance = max(dot(tint, LUMA), 0.025);
	return clamp(tint * (source_luminance / tint_luminance) * brightness, vec3(0.0), vec3(1.0));
}

void fragment() {
	vec3 source_albedo = texture(base_color_texture, UV).rgb;
	vec3 packed_mr = texture(metallic_roughness_texture, UV).rgb;
	float source_roughness = packed_mr.g;
	float source_metallic = packed_mr.b;

	float cushion_mask = texture(mask_cushion_leather, UV).r;
	float frame_mask = texture(mask_frame_paint, UV).r;
	float accent_mask = texture(mask_accent_metal, UV).r;

	vec3 albedo = source_albedo;
	albedo = mix(albedo, recolor_preserving_luminance(albedo, cushion_tint, cushion_brightness), cushion_mask * cushion_strength);
	albedo = mix(albedo, recolor_preserving_luminance(albedo, frame_tint, frame_brightness), frame_mask * frame_strength);
	albedo = mix(albedo, recolor_preserving_luminance(albedo, accent_tint, accent_brightness), accent_mask * accent_strength);

	float structural_floor = mix(0.76, 0.62, smoothstep(0.35, 0.72, source_metallic));
	float roughness = max(source_roughness * 1.20, structural_floor);
	roughness = mix(roughness, max(source_roughness, 0.84) + cushion_roughness_offset, cushion_mask);
	roughness = mix(roughness, max(source_roughness, 0.74) + frame_roughness_offset, frame_mask);
	roughness = mix(roughness, max(source_roughness, 0.56) + accent_roughness_offset, accent_mask);

	float frame_metallic = clamp(source_metallic + frame_metallic_offset, 0.0, 0.30);
	float accent_metallic = clamp(max(source_metallic, 0.65) + accent_metallic_offset, 0.0, 1.0);
	float metallic = mix(source_metallic, 0.0, cushion_mask);
	metallic = mix(metallic, frame_metallic, frame_mask);
	metallic = mix(metallic, accent_metallic, accent_mask);

	ALBEDO = albedo;
	METALLIC = metallic;
	ROUGHNESS = clamp(roughness, 0.0, 1.0);
	SPECULAR = 0.18;
	EMISSION = texture(emission_texture, UV).rgb * 0.15;
}
