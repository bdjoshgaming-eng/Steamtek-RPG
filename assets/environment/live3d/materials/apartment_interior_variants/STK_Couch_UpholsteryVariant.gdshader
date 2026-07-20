shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_color_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D metallic_roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D emission_texture : source_color, filter_linear_mipmap_anisotropic;
uniform vec3 upholstery_tint : source_color = vec3(0.08, 0.30, 0.31);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.92;
uniform float brightness : hint_range(0.5, 1.5) = 1.0;
uniform float roughness_offset : hint_range(-0.5, 0.5) = 0.0;
uniform float emission_strength : hint_range(0.0, 4.0) = 1.0;

void fragment() {
	vec4 albedo_sample = texture(base_color_texture, UV);
	vec3 metallic_roughness = texture(metallic_roughness_texture, UV).rgb;

	float metallic = metallic_roughness.b;
	float roughness = metallic_roughness.g;
	float red_dominance = albedo_sample.r - max(albedo_sample.g, albedo_sample.b);
	float saturation = max(albedo_sample.r, max(albedo_sample.g, albedo_sample.b)) - min(albedo_sample.r, min(albedo_sample.g, albedo_sample.b));
	float red_mask = smoothstep(0.025, 0.12, red_dominance);
	float saturated_mask = smoothstep(0.04, 0.18, saturation);
	float nonmetal_mask = 1.0 - smoothstep(0.15, 0.55, metallic);
	float upholstery_mask = red_mask * saturated_mask * nonmetal_mask;

	const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);
	float source_luminance = max(dot(albedo_sample.rgb, LUMA), 0.025);
	float tint_luminance = max(dot(upholstery_tint, LUMA), 0.025);
	vec3 recolored_upholstery = clamp(upholstery_tint * (source_luminance / tint_luminance) * brightness, vec3(0.0), vec3(1.0));

	float structural_floor = mix(0.82, 0.64, smoothstep(0.35, 0.75, metallic));
	float matte_roughness = max(roughness * 1.18, structural_floor);
	float upholstery_roughness = max(roughness, 0.84) + roughness_offset;
	metallic = mix(metallic, 0.0, upholstery_mask);

	ALBEDO = mix(albedo_sample.rgb, recolored_upholstery, upholstery_mask * tint_strength);
	METALLIC = metallic;
	ROUGHNESS = clamp(mix(matte_roughness, upholstery_roughness, upholstery_mask), 0.0, 1.0);
	SPECULAR = 0.18;
	EMISSION = texture(emission_texture, UV).rgb * emission_strength;
}
